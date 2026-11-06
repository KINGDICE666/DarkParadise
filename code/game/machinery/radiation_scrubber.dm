#define SCRUBBER_MIN_FLOW 1
#define SCRUBBER_MAX_FLOW 5
/// Рад в секунду на единицу потока, умножается на рейтинг манипулятора
#define SCRUBBER_PURGE_PER_FLOW 3
/// Потеря крови в секунду: это значение, умноженное на квадрат потока
#define SCRUBBER_BLOOD_LOSS_FACTOR 0.1
/// Выше этого потока сердце начинает страдать
#define SCRUBBER_SAFE_FLOW 3
#define SCRUBBER_STRESS_PER_FLOW 2
#define SCRUBBER_STRESS_RECOVERY 5
#define SCRUBBER_MAX_STRESS 100
#define SCRUBBER_HISTORY_LENGTH 60
#define SCRUBBER_CHELATOR_BOOST 1.5
#define SCRUBBER_INJECTION_PER_SECOND 0.25
#define SCRUBBER_TUBE_ATTACH_TIME (3 SECONDS)
#define SCRUBBER_TUBE_RIP_DAMAGE 10
#define SCRUBBER_TUBE_RIP_BLEED 15
#define SCRUBBER_FAKE_READING_FACTOR 2

/// Выводит радионуклиды из крови подключённого пациента в картридж фильтра.
/// Чем выше поток, тем тяжелее пациенту, а фильтр превращается в горячие отходы, с которыми надо что-то делать.
/obj/machinery/radiation_scrubber
	name = "radiation scrubber"
	desc = "Установка лучевой очистки: прогоняет кровь пациента через фильтр и вытягивает из неё радиацию. Подключается перетаскиванием на пациента. Отработавший фильтр сам становится радиоактивным."
	icon = 'icons/obj/machines/radiation.dmi'
	icon_state = "scrubber"
	density = TRUE
	idle_power_usage = 50
	active_power_usage = 1500
	rad_insulation = RAD_EXTREME_INSULATION
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	interaction_flags_mouse_drop = NEED_HANDS
	var/mob/living/carbon/human/patient
	var/obj/item/radiation_filter/filter
	var/obj/item/reagent_containers/beaker
	var/datum/beam/tube
	var/flow_rate = SCRUBBER_SAFE_FLOW
	var/active = FALSE
	/// Останавливает насос раньше, чем он убьёт пациента
	var/safety = TRUE
	var/inject_beaker = FALSE
	/// Нагрузка на сердце пациента, до SCRUBBER_MAX_STRESS
	var/stress = 0
	var/purge_multiplier = 1
	var/list/dose_history
	/// На сколько взломанная установка занижает дозу
	var/fake_reading_offset = 0

/obj/machinery/radiation_scrubber/get_ru_names()
	return alist(
		NOMINATIVE = "установка лучевой очистки",
		GENITIVE = "установки лучевой очистки",
		DATIVE = "установке лучевой очистки",
		ACCUSATIVE = "установку лучевой очистки",
		INSTRUMENTAL = "установкой лучевой очистки",
		PREPOSITIONAL = "установке лучевой очистки",
	)

/obj/machinery/radiation_scrubber/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/radiation_scrubber(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stock_parts/capacitor(null)
	component_parts += new /obj/item/stack/cable_coil(null, 1)
	RefreshParts()
	dose_history = list()
	filter = new(src)
	update_appearance()

/obj/machinery/radiation_scrubber/Destroy()
	detach_patient()
	QDEL_NULL(filter)
	QDEL_NULL(beaker)
	return ..()

/obj/machinery/radiation_scrubber/RefreshParts()
	var/manipulator_rating = 0
	var/manipulators = 0
	for(var/obj/item/stock_parts/manipulator/manipulator in component_parts)
		manipulator_rating += manipulator.rating
		manipulators++
	purge_multiplier = manipulators ? manipulator_rating / manipulators : 1

/obj/machinery/radiation_scrubber/on_deconstruction()
	filter?.forceMove(loc)
	filter = null
	beaker?.forceMove(loc)
	beaker = null
	return ..()

/obj/machinery/radiation_scrubber/update_icon_state()
	icon_state = active && !(stat & (BROKEN|NOPOWER)) ? "scrubber_on" : "scrubber"
	return ..()

/obj/machinery/radiation_scrubber/update_overlays()
	. = ..()
	if(stat & (BROKEN|NOPOWER))
		return

	if(filter?.is_hot())
		. += "scrubber_hot"
		. += emissive_appearance(icon, "scrubber_hot", src)

/obj/machinery/radiation_scrubber/power_change(forced = FALSE)
	. = ..()
	update_appearance()

/obj/machinery/radiation_scrubber/examine(mob/user)
	. = ..()
	if(patient)
		. += span_notice("К установке подключён пациент: [patient.get_visible_name()].")
	. += span_notice(filter ? "Насыщение фильтра: <b>[filter.get_saturation_percent()]%</b>." : "Фильтр не установлен.")

/obj/machinery/radiation_scrubber/mouse_drop_dragged(atom/over_object, mob/user, src_location, over_location, params)
	if(user.incapacitated() || !ishuman(user) || !ishuman(over_object))
		return

	add_fingerprint(user)
	if(patient)
		balloon_alert(user, "уже подключён пациент!")
		return

	if(get_dist(src, over_object) > 1)
		balloon_alert(user, "слишком далеко!")
		return

	var/mob/living/carbon/human/target = over_object
	if(HAS_TRAIT(target, TRAIT_NO_BLOOD))
		balloon_alert(user, "у пациента нет крови!")
		return

	user.visible_message(
		span_notice("[DECLENT_RU_CAP(user, NOMINATIVE)] начина[PLUR_ET_YUT(user)] подключать [target.declent_ru(ACCUSATIVE)] к [declent_ru(DATIVE)]."),
		span_notice("Вы начинаете подключать [target.declent_ru(ACCUSATIVE)] к [declent_ru(DATIVE)]."),
	)
	if(!do_after(user, SCRUBBER_TUBE_ATTACH_TIME, target) || patient || get_dist(src, target) > 1)
		return

	attach_patient(target)

/obj/machinery/radiation_scrubber/proc/attach_patient(mob/living/carbon/human/target)
	patient = target
	dose_history = list()
	stress = 0
	fake_reading_offset = 0
	tube = Beam(target, icon_state = "medbeam", beam_type = /obj/effect/ebeam/medical)
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(on_patient_deleted))
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(check_tube))
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)

/obj/machinery/radiation_scrubber/proc/detach_patient()
	if(!patient)
		return

	UnregisterSignal(patient, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	patient = null
	QDEL_NULL(tube)
	set_active(FALSE)

/obj/machinery/radiation_scrubber/proc/on_patient_deleted(datum/source)
	SIGNAL_HANDLER

	detach_patient()

/obj/machinery/radiation_scrubber/proc/check_tube(datum/source)
	SIGNAL_HANDLER

	if(!patient || get_dist(src, patient) <= 1)
		return

	var/mob/living/carbon/human/victim = patient
	detach_patient()
	victim.visible_message(
		span_danger("Трубка [declent_ru(GENITIVE)] вырывается из руки [victim.declent_ru(GENITIVE)]!"),
		span_userdanger("Трубка [declent_ru(GENITIVE)] вырывается из вашей руки!"),
	)
	victim.apply_damage(SCRUBBER_TUBE_RIP_DAMAGE, BRUTE, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
	victim.bleed(SCRUBBER_TUBE_RIP_BLEED)

/obj/machinery/radiation_scrubber/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	check_tube()

/obj/machinery/radiation_scrubber/proc/set_active(new_active)
	active = new_active
	update_use_power(active ? ACTIVE_POWER_USE : IDLE_POWER_USE)
	update_appearance()

/obj/machinery/radiation_scrubber/proc/stop_pump(reason)
	set_active(FALSE)
	playsound(src, 'sound/machines/twobeep.ogg', 40, TRUE)
	atom_say(reason)

/obj/machinery/radiation_scrubber/process(seconds_per_tick)
	if(!patient)
		return

	if(active)
		run_pump(seconds_per_tick)
	else
		stress = max(stress - SCRUBBER_STRESS_RECOVERY * seconds_per_tick, 0)

	dose_history += round(get_displayed_dose())
	if(length(dose_history) > SCRUBBER_HISTORY_LENGTH)
		dose_history.Cut(1, 2)

/obj/machinery/radiation_scrubber/proc/run_pump(seconds_per_tick)
	if(stat & (BROKEN|NOPOWER))
		set_active(FALSE)
		return

	if(patient.stat == DEAD)
		stop_pump("Пациент мёртв. Насос остановлен.")
		return

	if(!filter)
		stop_pump("Фильтр не установлен.")
		return

	if(safety && !emagged && patient.blood_volume < BLOOD_VOLUME_SAFE)
		stop_pump("Низкий объём крови. Насос остановлен.")
		return

	var/purge = flow_rate * SCRUBBER_PURGE_PER_FLOW * purge_multiplier * seconds_per_tick
	if(beaker && inject_beaker && beaker.reagents.total_volume)
		if(beaker.reagents.has_reagent("pen_acid") || beaker.reagents.has_reagent("potass_iodide"))
			purge *= SCRUBBER_CHELATOR_BOOST
		beaker.reagents.trans_to(patient, SCRUBBER_INJECTION_PER_SECOND * seconds_per_tick)

	if(emagged)
		var/backflow = min(purge, filter.saturation)
		filter.adjust_saturation(-backflow)
		patient.adjust_radiation_dose(backflow)
		fake_reading_offset += backflow * SCRUBBER_FAKE_READING_FACTOR
	else
		var/purged = min(purge, patient.get_radiation_dose(), filter.capacity - filter.saturation)
		patient.adjust_radiation_dose(-purged)
		filter.adjust_saturation(purged)

		if(filter.saturation >= filter.capacity)
			stop_pump("Фильтр насыщен. Замените картридж.")
			update_appearance(UPDATE_OVERLAYS)
			return

		if(patient.get_radiation_dose() <= 0)
			stop_pump("Очистка завершена.")
			return

	update_appearance(UPDATE_OVERLAYS)
	patient.AdjustBlood(-SCRUBBER_BLOOD_LOSS_FACTOR * flow_rate * flow_rate * seconds_per_tick)
	update_stress(seconds_per_tick)

/obj/machinery/radiation_scrubber/proc/update_stress(seconds_per_tick)
	if(flow_rate <= SCRUBBER_SAFE_FLOW)
		stress = max(stress - SCRUBBER_STRESS_RECOVERY * seconds_per_tick, 0)
		return

	stress = min(stress + (flow_rate - SCRUBBER_SAFE_FLOW) * SCRUBBER_STRESS_PER_FLOW * seconds_per_tick, SCRUBBER_MAX_STRESS)
	if(stress < SCRUBBER_MAX_STRESS)
		return

	if(safety && !emagged)
		flow_rate = SCRUBBER_SAFE_FLOW
		stop_pump("Перегрузка сердца. Поток снижен, насос остановлен.")
		return

	stress = 0
	patient.set_heartattack(TRUE)
	stop_pump("ОСТАНОВКА СЕРДЦА!")

/// Взломанная установка показывает падение дозы, пока закачивает содержимое фильтра обратно в пациента
/obj/machinery/radiation_scrubber/proc/get_displayed_dose()
	var/dose = patient?.get_radiation_dose() || 0
	return emagged ? max(dose - fake_reading_offset, 0) : dose

/obj/machinery/radiation_scrubber/attack_hand(mob/user)
	if(..())
		return TRUE

	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/radiation_scrubber/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/radiation_scrubber/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.a_intent == INTENT_HARM)
		return NONE

	if(istype(tool, /obj/item/radiation_filter))
		if(filter)
			balloon_alert(user, "фильтр уже стоит!")
			return ITEM_INTERACT_BLOCKING
		if(!user.drop_transfer_item_to_loc(tool, src))
			return ITEM_INTERACT_BLOCKING
		filter = tool
		update_appearance(UPDATE_OVERLAYS)
		balloon_alert(user, "фильтр установлен")
		return ITEM_INTERACT_SUCCESS

	if(is_reagent_container(tool) && tool.is_open_container())
		if(beaker)
			balloon_alert(user, "ёмкость уже стоит!")
			return ITEM_INTERACT_BLOCKING
		if(!user.drop_transfer_item_to_loc(tool, src))
			return ITEM_INTERACT_BLOCKING
		beaker = tool
		balloon_alert(user, "ёмкость установлена")
		return ITEM_INTERACT_SUCCESS

	return NONE

/obj/machinery/radiation_scrubber/wrench_act(mob/living/user, obj/item/tool)
	. = TRUE
	default_unfasten_wrench(user, tool)

/obj/machinery/radiation_scrubber/screwdriver_act(mob/living/user, obj/item/tool)
	. = TRUE
	default_deconstruction_screwdriver(user, "scrubber", "scrubber", tool)

/obj/machinery/radiation_scrubber/crowbar_act(mob/living/user, obj/item/tool)
	. = TRUE
	default_deconstruction_crowbar(user, tool)

/obj/machinery/radiation_scrubber/emag_act(mob/user)
	if(emagged)
		return FALSE

	emagged = TRUE
	playsound(src, 'sound/machines/twobeep.ogg', 40, TRUE)
	balloon_alert(user, "насос перенастроен")
	return TRUE

/obj/machinery/radiation_scrubber/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/radiation_scrubber/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RadiationScrubber", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/radiation_scrubber/ui_data(mob/user)
	var/list/data = list()
	data["active"] = active
	data["powered"] = !(stat & (BROKEN|NOPOWER))
	data["flow_rate"] = flow_rate
	data["min_flow"] = SCRUBBER_MIN_FLOW
	data["max_flow"] = SCRUBBER_MAX_FLOW
	data["safe_flow"] = SCRUBBER_SAFE_FLOW
	data["safety"] = safety
	data["inject_beaker"] = inject_beaker
	data["stress"] = round(stress)
	data["max_stress"] = SCRUBBER_MAX_STRESS
	data["purge_rate"] = round(flow_rate * SCRUBBER_PURGE_PER_FLOW * purge_multiplier, 0.1)
	data["blood_loss"] = round(SCRUBBER_BLOOD_LOSS_FACTOR * flow_rate * flow_rate, 0.1)
	data["history"] = dose_history

	data["patient"] = null
	if(patient)
		var/displayed_dose = get_displayed_dose()
		data["patient"] = list(
			"name" = patient.get_visible_name(),
			"dose" = round(displayed_dose),
			"stage" = RADIATION_STAGE_FOR_DOSE(displayed_dose),
			"blood" = round(patient.blood_volume),
			"blood_safe" = BLOOD_VOLUME_SAFE,
			"blood_normal" = BLOOD_VOLUME_NORMAL,
			"health" = round(patient.health),
			"max_health" = patient.maxHealth,
			"dead" = patient.stat == DEAD,
		)

	data["filter"] = null
	if(filter)
		data["filter"] = list(
			"saturation" = round(filter.saturation),
			"capacity" = filter.capacity,
		)

	data["beaker"] = null
	if(beaker)
		var/list/contents = list()
		for(var/datum/reagent/reagent as anything in beaker.reagents.reagent_list)
			contents += list(list("name" = reagent.name, "volume" = round(reagent.volume, 0.1), "chelator" = reagent.id == "pen_acid" || reagent.id == "potass_iodide"))
		data["beaker"] = list(
			"volume" = round(beaker.reagents.total_volume, 0.1),
			"maximum" = beaker.reagents.maximum_volume,
			"contents" = contents,
		)
	return data

/obj/machinery/radiation_scrubber/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	add_fingerprint(ui.user)
	switch(action)
		if("toggle_pump")
			if(active)
				set_active(FALSE)
			else if(patient && filter && !(stat & (BROKEN|NOPOWER)))
				set_active(TRUE)
		if("set_flow")
			flow_rate = clamp(round(text2num(params["value"])), SCRUBBER_MIN_FLOW, SCRUBBER_MAX_FLOW)
		if("toggle_safety")
			safety = !safety
		if("toggle_injection")
			inject_beaker = !inject_beaker
		if("detach")
			if(!patient)
				return
			detach_patient()
		if("eject_filter")
			if(!filter)
				return
			set_active(FALSE)
			filter.forceMove(loc)
			ui.user.put_in_hands(filter, ignore_anim = FALSE)
			filter = null
			update_appearance(UPDATE_OVERLAYS)
		if("eject_beaker")
			if(!beaker)
				return
			beaker.forceMove(loc)
			ui.user.put_in_hands(beaker, ignore_anim = FALSE)
			beaker = null
		else
			return

	return TRUE

#define FILTER_DECAY_FACTOR 0.002
#define FILTER_PULSE_COOLDOWN (5 SECONDS)
#define FILTER_RADS_FACTOR 0.02
#define FILTER_HOT_FRACTION 0.5
#define FILTER_MINIMUM_SATURATION 1

/// Держит то, что вывели из пациентов. Радиоактивен, пока не распадётся, мытьё не поможет.
/obj/item/radiation_filter
	name = "radiation filter cartridge"
	desc = "Сменный картридж установки лучевой очистки. Насыщенный фильтр сильно излучает и сам остывает только со временем: храните его в радиационном ящике."
	icon = 'icons/obj/machines/radiation.dmi'
	icon_state = "filter"
	materials = list(MAT_METAL = 500, MAT_GLASS = 500)
	var/saturation = 0
	var/capacity = 800
	COOLDOWN_DECLARE(pulse_cooldown)

/obj/item/radiation_filter/get_ru_names()
	return alist(
		NOMINATIVE = "картридж лучевого фильтра",
		GENITIVE = "картриджа лучевого фильтра",
		DATIVE = "картриджу лучевого фильтра",
		ACCUSATIVE = "картридж лучевого фильтра",
		INSTRUMENTAL = "картриджем лучевого фильтра",
		PREPOSITIONAL = "картридже лучевого фильтра",
	)

/obj/item/radiation_filter/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/radiation_filter/examine(mob/user)
	. = ..()
	. += span_notice("Насыщение: <b>[get_saturation_percent()]%</b>.")

/obj/item/radiation_filter/update_icon_state()
	icon_state = is_hot() ? "filter_hot" : "filter"
	return ..()

/obj/item/radiation_filter/proc/is_hot()
	return saturation >= capacity * FILTER_HOT_FRACTION

/obj/item/radiation_filter/proc/get_saturation_percent()
	return round(saturation / capacity * 100)

/obj/item/radiation_filter/proc/adjust_saturation(amount)
	var/was_saturated = saturation > 0
	saturation = clamp(saturation + amount, 0, capacity)
	if(saturation < FILTER_MINIMUM_SATURATION)
		saturation = 0

	if(!was_saturated && saturation)
		START_PROCESSING(SSobj, src)
	else if(was_saturated && !saturation)
		STOP_PROCESSING(SSobj, src)

	update_appearance(UPDATE_ICON_STATE)

/obj/item/radiation_filter/process(seconds_per_tick)
	adjust_saturation(-saturation * FILTER_DECAY_FACTOR * seconds_per_tick)
	if(!COOLDOWN_FINISHED(src, pulse_cooldown))
		return

	COOLDOWN_START(src, pulse_cooldown, FILTER_PULSE_COOLDOWN)
	radiation_pulse(src, saturation * FILTER_RADS_FACTOR)

#undef FILTER_DECAY_FACTOR
#undef FILTER_PULSE_COOLDOWN
#undef FILTER_RADS_FACTOR
#undef FILTER_HOT_FRACTION
#undef FILTER_MINIMUM_SATURATION

#undef SCRUBBER_MIN_FLOW
#undef SCRUBBER_MAX_FLOW
#undef SCRUBBER_PURGE_PER_FLOW
#undef SCRUBBER_BLOOD_LOSS_FACTOR
#undef SCRUBBER_SAFE_FLOW
#undef SCRUBBER_STRESS_PER_FLOW
#undef SCRUBBER_STRESS_RECOVERY
#undef SCRUBBER_MAX_STRESS
#undef SCRUBBER_HISTORY_LENGTH
#undef SCRUBBER_CHELATOR_BOOST
#undef SCRUBBER_INJECTION_PER_SECOND
#undef SCRUBBER_TUBE_ATTACH_TIME
#undef SCRUBBER_TUBE_RIP_DAMAGE
#undef SCRUBBER_TUBE_RIP_BLEED
#undef SCRUBBER_FAKE_READING_FACTOR
