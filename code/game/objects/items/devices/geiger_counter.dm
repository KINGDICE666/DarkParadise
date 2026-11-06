#define GEIGER_HISTORY_LENGTH 60
#define GEIGER_RATE_SMOOTHING 0.35
#define GEIGER_DEFAULT_BEEP_LEVEL 30
#define GEIGER_MAX_BEEP_LEVEL 5000
#define GEIGER_BEEP_COOLDOWN (3 SECONDS)
#define GEIGER_MOUNT_TIME (2 SECONDS)
#define GEIGER_WALL_OFFSET 26

GLOBAL_LIST_EMPTY(geiger_counters)

// DISCLAIMER: I know nothing about how real-life Geiger counters work. This will not be realistic. ~Xhuis
/// Счётчик, дозиметр и настенный датчик в одном приборе: носится с собой, копит дозу, а прикрученный к стене следит за отсеком
/obj/item/geiger_counter
	name = "geiger counter"
	desc = "Прибор радиационного контроля. Показывает силу излучения и направление на источник, копит полученную дозу и пищит при заданном уровне. Вблизи проверяет заражение людей и предметов, а ещё его можно прикрутить к стене."
	icon = 'icons/obj/devices/scanner.dmi'
	icon_state = "geiger_off"
	item_state = "multitool"
	//worn_icon_state = "geiger_counter"
	//lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	//righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	item_flags = NOBLUDGEON
	materials = list(MAT_METAL = 500, MAT_GLASS = 500)

	var/scanning = FALSE
	var/mounted = FALSE
	var/last_perceived_radiation_danger = null
	/// Сглаженная мощность в радах в минуту
	var/rads_per_minute = 0
	/// Самая высокая мощность с последнего сброса
	var/peak_rate = 0
	/// Вся доза с последнего сброса, в радах
	var/total_rads = 0
	/// Что пришло с последней обработки
	var/pending_rads = 0
	var/strongest_pulse = 0
	var/turf/strongest_source
	/// Угол от севера по часовой стрелке до направления, откуда идёт радиация
	var/bearing
	var/list/history
	/// С какой мощности прибор пищит, 0 выключает писк
	var/beep_level = GEIGER_DEFAULT_BEEP_LEVEL
	COOLDOWN_DECLARE(beep_cooldown)

/obj/item/geiger_counter/get_ru_names()
	return alist(
		NOMINATIVE = "счётчик Гейгера",
		GENITIVE = "счётчика Гейгера",
		DATIVE = "счётчику Гейгера",
		ACCUSATIVE = "счётчик Гейгера",
		INSTRUMENTAL = "счётчиком Гейгера",
		PREPOSITIONAL = "счётчике Гейгера",
	)

/obj/item/geiger_counter/Initialize(mapload)
	. = ..()
	history = new /list(GEIGER_HISTORY_LENGTH)
	for(var/index in 1 to GEIGER_HISTORY_LENGTH)
		history[index] = 0

	GLOB.geiger_counters += src
	RegisterSignal(src, COMSIG_RADIATION_DETECTED, PROC_REF(on_radiation_detected))

/obj/item/geiger_counter/Destroy()
	GLOB.geiger_counters -= src
	STOP_PROCESSING(SSobj, src)
	strongest_source = null
	return ..()

/obj/item/geiger_counter/examine(mob/user)
	. = ..()
	if(mounted)
		. += span_notice("Закреплён на стене. Снимается <b>отвёрткой</b>.")
	else
		. += span_notice("Можно закрепить на <b>стене</b>, чтобы следить за отсеком.")

	if(!scanning)
		return

	. += span_notice("Накопленная доза: <b>[round(total_rads)] рад</b>.")
	if(rads_per_minute >= 1)
		. += span_warning("Текущая мощность: <b>[round(rads_per_minute)] рад/мин</b>.")

/obj/item/geiger_counter/update_icon_state()
	if(mounted)
		icon = 'icons/obj/machines/radiation.dmi'
		icon_state = "geiger_wall"
		return ..()

	icon = initial(icon)
	if(!scanning)
		icon_state = "geiger_off"
		return ..()

	icon_state = last_perceived_radiation_danger ? "geiger_on_[last_perceived_radiation_danger + 1]" : "geiger_on_1"
	return ..()

/obj/item/geiger_counter/update_overlays()
	. = ..()
	if(!mounted || !scanning)
		return

	var/screen = "geiger_wall_[last_perceived_radiation_danger || 0]"
	. += screen
	. += emissive_appearance(icon, screen, src)

/obj/item/geiger_counter/attack_self(mob/user)
	ui_interact(user)

/obj/item/geiger_counter/attack_hand(mob/user, pickupfireoverride = FALSE)
	if(!mounted)
		return ..()

	add_fingerprint(user)
	ui_interact(user)

/obj/item/geiger_counter/attack_ai(mob/user)
	if(mounted)
		ui_interact(user)

/obj/item/geiger_counter/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .

	if(iswallturf(interacting_with))
		mount_on_wall(interacting_with, user)
		return ITEM_INTERACT_SUCCESS

	if(!CAN_IRRADIATE(interacting_with))
		return NONE

	user.visible_message(
		span_notice("[DECLENT_RU_CAP(user, NOMINATIVE)] проверя[PLUR_ET_YUT(user)] [interacting_with.declent_ru(ACCUSATIVE)] [declent_ru(INSTRUMENTAL)]."),
		span_notice("Вы проверяете [interacting_with.declent_ru(ACCUSATIVE)] [declent_ru(INSTRUMENTAL)]..."),
	)
	addtimer(CALLBACK(src, PROC_REF(scan), interacting_with, user), 2 SECONDS, TIMER_UNIQUE)
	return ITEM_INTERACT_SUCCESS

/obj/item/geiger_counter/proc/scan(atom/target, mob/user)
	if(QDELETED(target) || QDELETED(user))
		return

	if(SEND_SIGNAL(target, COMSIG_GEIGER_COUNTER_SCAN, user, src) & COMSIG_GEIGER_COUNTER_SCAN_SUCCESSFUL)
		return

	to_chat(user, span_notice("[icon2html(src, user)] Радиоактивного заражения не обнаружено."))

/obj/item/geiger_counter/proc/mount_on_wall(turf/wall, mob/living/user)
	var/direction = get_dir(user, wall)
	if(!(direction in GLOB.cardinal))
		balloon_alert(user, "встаньте лицом к стене!")
		return

	var/turf/user_turf = get_turf(user)
	if(check_wall_item(user_turf, direction))
		balloon_alert(user, "здесь уже что-то есть!")
		return

	if(!do_after(user, GEIGER_MOUNT_TIME, wall) || !user.drop_transfer_item_to_loc(src, user_turf))
		return

	setDir(direction)
	set_pixel_offsets_from_dir(GEIGER_WALL_OFFSET, -GEIGER_WALL_OFFSET, GEIGER_WALL_OFFSET, -GEIGER_WALL_OFFSET)
	set_mounted(TRUE)
	set_scanning(TRUE)
	balloon_alert(user, "закреплён")

/obj/item/geiger_counter/proc/set_mounted(new_mounted)
	mounted = new_mounted
	anchored = mounted
	w_class = mounted ? WEIGHT_CLASS_BULKY : initial(w_class)
	update_appearance()

/obj/item/geiger_counter/screwdriver_act(mob/living/user, obj/item/tool)
	if(!mounted)
		return FALSE

	. = TRUE
	if(!tool.use_tool(src, user, GEIGER_MOUNT_TIME, volume = tool.tool_volume))
		return

	setDir(SOUTH)
	set_pixel_offsets_from_dir()
	set_mounted(FALSE)
	user.put_in_hands(src, ignore_anim = FALSE)
	balloon_alert(user, "снят")

/obj/item/geiger_counter/proc/set_scanning(new_scanning)
	if(scanning == new_scanning)
		return

	scanning = new_scanning
	if(scanning)
		AddComponent(/datum/component/geiger_sound)
		START_PROCESSING(SSobj, src)
	else
		qdel(GetComponent(/datum/component/geiger_sound))
		STOP_PROCESSING(SSobj, src)
		rads_per_minute = 0
		pending_rads = 0
		strongest_pulse = 0
		strongest_source = null
		bearing = null
		last_perceived_radiation_danger = null

	update_appearance()

/obj/item/geiger_counter/proc/on_radiation_detected(datum/source, rads, turf/source_turf)
	SIGNAL_HANDLER

	if(emagged)
		return

	total_rads += rads
	pending_rads += rads
	if(rads >= strongest_pulse)
		strongest_pulse = rads
		strongest_source = source_turf

	var/danger = get_perceived_radiation_danger(rads)
	addtimer(CALLBACK(src, PROC_REF(reset_perceived_danger)), TIME_WITHOUT_RADIATION_BEFORE_RESET, TIMER_UNIQUE | TIMER_OVERRIDE)
	if(danger == last_perceived_radiation_danger)
		return

	last_perceived_radiation_danger = danger
	update_appearance()

/obj/item/geiger_counter/proc/reset_perceived_danger()
	last_perceived_radiation_danger = null
	update_appearance()

/obj/item/geiger_counter/process(seconds_per_tick)
	rads_per_minute = LERP(rads_per_minute, pending_rads * 60 / seconds_per_tick, GEIGER_RATE_SMOOTHING)
	if(rads_per_minute < 0.1)
		rads_per_minute = 0

	peak_rate = max(peak_rate, rads_per_minute)
	history.Cut(1, 2)
	history += round(rads_per_minute, 0.1)

	if(!rads_per_minute)
		bearing = null
	else if(strongest_source)
		bearing = strongest_source == get_turf(src) ? null : round(get_angle(get_turf(src), strongest_source))

	pending_rads = 0
	strongest_pulse = 0
	strongest_source = null

	if(beep_level && rads_per_minute >= beep_level && COOLDOWN_FINISHED(src, beep_cooldown))
		COOLDOWN_START(src, beep_cooldown, GEIGER_BEEP_COOLDOWN)
		playsound(src, 'sound/machines/twobeep.ogg', 40, TRUE)

/obj/item/geiger_counter/emag_act(mob/user)
	if(emagged)
		return FALSE

	emagged = TRUE
	rads_per_minute = 0
	pending_rads = 0
	bearing = null
	last_perceived_radiation_danger = null
	update_appearance()
	playsound(src, 'sound/machines/twobeep.ogg', 40, TRUE)
	balloon_alert(user, "показания подменены")
	return TRUE

/// Строка для консоли радиационного контроля
/obj/item/geiger_counter/proc/get_monitor_entry()
	var/turf/our_turf = get_turf(src)
	var/mob/living/carbon/human/holder = get(src, /mob/living/carbon/human)
	return list(
		"uid" = UID(),
		"holder" = holder?.get_visible_name(),
		"mounted" = mounted,
		"area" = get_area_name(our_turf),
		"department" = get_radiation_department(get_area(our_turf)),
		"x" = our_turf.x,
		"y" = our_turf.y,
		"z" = our_turf.z,
		"rate" = round(rads_per_minute, 0.1),
		"total" = round(total_rads),
		"stage" = RADIATION_STAGE_FOR_DOSE(total_rads),
		"bearing" = bearing,
	)

/obj/item/geiger_counter/ui_state(mob/user)
	return GLOB.default_state

/obj/item/geiger_counter/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RadiationMeter", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/item/geiger_counter/ui_data(mob/user)
	var/turf/our_turf = get_turf(src)
	var/list/data = list()
	data["scanning"] = scanning
	data["mounted"] = mounted
	data["area"] = our_turf ? get_area_name(our_turf) : null
	data["rate"] = round(rads_per_minute, 0.1)
	data["peak"] = round(peak_rate, 0.1)
	data["total"] = round(total_rads)
	data["stage"] = RADIATION_STAGE_FOR_DOSE(total_rads)
	data["bearing"] = bearing
	data["history"] = history
	data["beep_level"] = beep_level
	data["max_beep_level"] = GEIGER_MAX_BEEP_LEVEL
	return data

/obj/item/geiger_counter/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	add_fingerprint(ui.user)
	switch(action)
		if("toggle_power")
			set_scanning(!scanning)
		if("set_beep_level")
			beep_level = clamp(round(text2num(params["value"])), 0, GEIGER_MAX_BEEP_LEVEL)
		if("reset_peak")
			peak_rate = rads_per_minute
		if("reset_dose")
			total_rads = 0
		else
			return

	return TRUE

/obj/item/geiger_counter/mounted
	icon = 'icons/obj/machines/radiation.dmi'
	icon_state = "geiger_wall"

MAPPING_DIRECTIONAL_HELPERS(/obj/item/geiger_counter/mounted, GEIGER_WALL_OFFSET, GEIGER_WALL_OFFSET)

/obj/item/geiger_counter/mounted/Initialize(mapload)
	. = ..()
	set_mounted(TRUE)
	set_scanning(TRUE)

#undef GEIGER_HISTORY_LENGTH
#undef GEIGER_RATE_SMOOTHING
#undef GEIGER_DEFAULT_BEEP_LEVEL
#undef GEIGER_MAX_BEEP_LEVEL
#undef GEIGER_BEEP_COOLDOWN
#undef GEIGER_MOUNT_TIME
#undef GEIGER_WALL_OFFSET
