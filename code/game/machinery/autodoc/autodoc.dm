#define AUTODOC_FUEL "synthflesh"
#define AUTODOC_PAINKILLER "hydrocodone"
/// Сколько обезболивающего вводится за раз
#define AUTODOC_PAINKILLER_DOSE 3
/// Объём бака на один уровень каждой матрицы
#define AUTODOC_TANK_PER_BIN_RATING 100
/// Сколько органов помещается в лоток
#define AUTODOC_TRAY_SIZE 6
/// Шанс срыва инвазивной процедуры при базовом сканере
#define AUTODOC_FAILURE_BASE 60
/// Шанс срыва лечения органа при базовом сканере
#define AUTODOC_FAILURE_DELICATE 90
/// Шанс срыва любой инвазивной процедуры при лучшем сканере
#define AUTODOC_FAILURE_UPGRADED 20
/// Максимальный уровень стандартных деталей
#define AUTODOC_MAX_PART_RATING 4
/// Брут на конечность при срыве или прерывании процедуры
#define AUTODOC_HARM_LIMB 8
/// Урон органу при срыве или прерывании процедуры
#define AUTODOC_HARM_ORGAN 5
/// Во сколько раз срыв после емага больнее обычного
#define AUTODOC_EMAG_HARM_MULTIPLIER 2
/// Предел длительности одной процедуры после емага
#define AUTODOC_EMAG_MAX_DURATION (20 SECONDS)
/// Размер уменьшенного спрайта пациента в окне капсулы
#define AUTODOC_PATIENT_ICON_SIZE 16
/// Шанс рабочего звука манипуляторов за такт
#define AUTODOC_WORK_SOUND_CHANCE 30
/// Шанс, что орган в лотке пропустит такт порчи. 75 означает порчу в 4 раза медленнее.
#define AUTODOC_ORGAN_PRESERVE_CHANCE 75

/obj/machinery/autodoc
	name = "AutoDOCtor 3000"
	desc = "Автоматический хирургический комплекс. Лечит, извлекает и заменяет органы без участия врача, расходуя синт-плоть, но нуждается в операторе снаружи. Без улучшений часто ошибается."
	icon = 'icons/obj/machines/autodoc.dmi'
	icon_state = "autodoc_open"
	density = TRUE
	anchored = TRUE
	interaction_flags_mouse_drop = NEED_DEXTERITY
	idle_power_usage = 400
	active_power_usage = 6000
	light_color = LIGHT_COLOR_CYAN
	light_power = 0.5
	req_access = list(ACCESS_MEDICAL)
	var/mob/living/carbon/human/occupant
	var/patient_icon
	var/list/datum/autodoc_order/queue = list()
	var/list/obj/item/organ/internal/organ_tray = list()
	var/list/obj/item/disk/autodoc_module/installed_modules = list()
	var/datum/looping_sound/autodoc_scan/soundloop
	var/running = FALSE
	var/playing_work_sound = FALSE
	var/auto_eject = FALSE
	var/mode = AUTODOC_MODE_MEDIUM
	var/speed_mod = 1
	var/cost_mod = 1
	var/scanner_rating = 1

/obj/machinery/autodoc/get_ru_names()
	return alist(
		NOMINATIVE = "AutoDOCtor 3000",
		GENITIVE = "AutoDOCtor 3000",
		DATIVE = "AutoDOCtor 3000",
		ACCUSATIVE = "AutoDOCtor 3000",
		INSTRUMENTAL = "AutoDOCtor 3000",
		PREPOSITIONAL = "AutoDOCtor 3000",
	)

/obj/machinery/autodoc/Initialize(mapload)
	. = ..()
	soundloop = new(src)
	create_reagents(AUTODOC_TANK_PER_BIN_RATING)
	reagents.set_reacting(FALSE)
	component_parts = list()
	component_parts += new /obj/item/circuitboard/autodoc(null)
	component_parts += new /obj/item/stock_parts/matter_bin(null)
	component_parts += new /obj/item/stock_parts/matter_bin(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)
	component_parts += new /obj/item/stock_parts/scanning_module(null)
	component_parts += new /obj/item/stack/sheet/glass(null, 2)
	component_parts += new /obj/item/stack/sheet/plasteel(null, 2)
	component_parts += new /obj/item/stack/cable_coil(null, 2)
	RefreshParts()

/obj/machinery/autodoc/Destroy()
	go_out()
	for(var/obj/item/organ/internal/organ as anything in organ_tray)
		organ.forceMove(loc)
	for(var/obj/item/disk/autodoc_module/module as anything in installed_modules)
		module.forceMove(loc)
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/autodoc/RefreshParts()
	var/bin_rating = 0
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		bin_rating += bin.rating
	var/manipulator_rating = 0
	var/manipulator_count = 0
	for(var/obj/item/stock_parts/manipulator/manipulator in component_parts)
		manipulator_rating += manipulator.rating
		manipulator_count++
	var/laser_rating = 1
	for(var/obj/item/stock_parts/micro_laser/laser in component_parts)
		laser_rating = laser.rating
	scanner_rating = 1
	for(var/obj/item/stock_parts/scanning_module/scanner in component_parts)
		scanner_rating = scanner.rating

	speed_mod = 1 + (manipulator_rating / max(manipulator_count, 1) - 1) / 3
	cost_mod = 1 - (laser_rating - 1) * 0.1

	reagents.maximum_volume = bin_rating * AUTODOC_TANK_PER_BIN_RATING
	var/excess = reagents.total_volume - reagents.maximum_volume
	if(excess > 0)
		reagents.remove_any(excess)

/obj/machinery/autodoc/power_change(forced = FALSE)
	..()
	if(stat & (BROKEN|NOPOWER))
		set_light_on(FALSE)
	else
		set_light(2, l_on = TRUE)
	update_beeping()
	update_icon(UPDATE_OVERLAYS)

/obj/machinery/autodoc/update_overlays()
	. = ..()
	if(patient_icon)
		. += mutable_appearance(patient_icon)
	if(occupant)
		. += emagged ? "glass_emag" : "glass"
	if(panel_open)
		. += "panel"
	if(stat & (BROKEN|NOPOWER))
		return
	if(running)
		. += emagged ? "arms_overdrive" : "arms"
	var/indicator = "indicator"
	if(running)
		indicator = "indicator_active"
	else if(occupant && length(queue))
		indicator = "indicator_alert"
	. += indicator
	. += emissive_appearance(icon, indicator, src)

/obj/machinery/autodoc/examine(mob/user)
	. = ..()
	. += span_notice("В баке [round(get_fuel(), 0.1)] из [reagents.maximum_volume] ед. синт-плоти. Заправляется из открытой ёмкости.")
	. += span_notice("В лотке [length(organ_tray)] из [AUTODOC_TRAY_SIZE] органов. Новый орган кладётся кликом.")
	if(occupant)
		. += span_notice("Внутри находится [occupant.name].")
	if(Adjacent(user))
		. += span_notice("Наведите курсор на гуманоида, зажмите <b>ЛКМ</b> и перетяните на [declent_ru(ACCUSATIVE)], чтобы поместить его внутрь.")

/obj/machinery/autodoc/proc/get_fuel()
	return reagents.get_reagent_amount(AUTODOC_FUEL)

/obj/machinery/autodoc/proc/get_mode_settings()
	var/static/list/mode_settings = list(
		AUTODOC_MODE_SLOW = list("duration" = 1.2, "risk" = 0.75),
		AUTODOC_MODE_MEDIUM = list("duration" = 0.8, "risk" = 1),
		AUTODOC_MODE_FAST = list("duration" = 0.48, "risk" = 1.25),
		AUTODOC_MODE_OVERDRIVE = list("duration" = 0.24, "risk" = 1),
	)
	return mode_settings[mode]

/obj/machinery/autodoc/proc/get_failure_chance(datum/autodoc_procedure/procedure)
	if(emagged)
		return 100
	if(procedure && !procedure.invasive)
		return 0
	var/base_chance = procedure?.delicate ? AUTODOC_FAILURE_DELICATE : AUTODOC_FAILURE_BASE
	var/upgrade_progress = clamp((scanner_rating - 1) / (AUTODOC_MAX_PART_RATING - 1), 0, 1)
	var/chance = base_chance + (AUTODOC_FAILURE_UPGRADED - base_chance) * upgrade_progress
	var/list/settings = get_mode_settings()
	return clamp(chance * settings["risk"], 0, 100)

/obj/machinery/autodoc/proc/get_order_duration(datum/autodoc_procedure/procedure, obj/item/organ/organ)
	var/list/settings = get_mode_settings()
	return procedure.get_duration(organ) * settings["duration"] / speed_mod

/obj/machinery/autodoc/proc/get_order_cost(datum/autodoc_procedure/procedure, obj/item/organ/organ)
	return round(procedure.get_cost(organ) * cost_mod, 0.1)

/obj/machinery/autodoc/proc/update_patient_icon()
	patient_icon = null
	if(!occupant)
		return
	var/static/list/window_offsets = list(
		"[SOUTH]" = list(8, 8),
		"[NORTH]" = list(8, 12),
		"[EAST]" = list(11, 13),
		"[WEST]" = list(5, 13),
	)
	var/list/offset = window_offsets["[dir]"]
	var/icon/flat = getFlatIcon(occupant, SOUTH)
	if(dir == EAST)
		flat.Turn(90)
	else if(dir == WEST)
		flat.Turn(-90)
	flat.Scale(AUTODOC_PATIENT_ICON_SIZE, AUTODOC_PATIENT_ICON_SIZE)
	flat.Crop(1 - offset[1], 1 - offset[2], world.icon_size - offset[1], world.icon_size - offset[2])
	flat.Blend(icon(icon, "window_mask", dir), ICON_MULTIPLY)
	patient_icon = fcopy_rsc(flat)

/obj/machinery/autodoc/proc/play_operation_sound(sound_file, volume = 35)
	if(sound_file)
		playsound(loc, sound_file, volume, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/machinery/autodoc/proc/has_module(module_id)
	for(var/obj/item/disk/autodoc_module/module as anything in installed_modules)
		if(module.module_id == module_id)
			return TRUE
	return FALSE

/obj/machinery/autodoc/proc/can_perform(datum/autodoc_procedure/procedure, obj/item/organ/organ)
	if(procedure.required_module && !has_module(procedure.required_module))
		return FALSE
	return procedure.is_needed(organ, src)

/obj/machinery/autodoc/proc/get_install_procedure(obj/item/organ/internal/organ)
	return GLOB.autodoc_procedures[istype(organ, /obj/item/organ/internal/cyberimp) ? "implant_install" : "organ_install"]

/obj/machinery/autodoc/proc/is_operating()
	if(running)
		return TRUE
	if(!length(queue))
		return FALSE
	var/datum/autodoc_order/first_order = queue[1]
	return first_order.paid

/obj/machinery/autodoc/proc/is_locked()
	return emagged && running && !(stat & (NOPOWER|BROKEN))

/obj/machinery/autodoc/proc/update_beeping()
	var/should_play = running && !(stat & (NOPOWER|BROKEN))
	if(should_play == playing_work_sound)
		return
	playing_work_sound = should_play
	if(should_play)
		soundloop?.start()
	else
		soundloop?.stop()

/obj/machinery/autodoc/proc/set_running(new_running)
	running = new_running
	update_use_power(running ? ACTIVE_POWER_USE : IDLE_POWER_USE)
	update_beeping()
	update_icon(UPDATE_OVERLAYS)
	SStgui.update_uis(src)

/obj/machinery/autodoc/process(seconds_per_tick)
	if(stat & (NOPOWER|BROKEN))
		return
	if(emagged && occupant)
		process_malfunction()
	if(!running)
		return
	if(!occupant || !length(queue))
		finish_program()
		return

	var/datum/autodoc_order/order = queue[1]
	var/obj/item/organ/organ = order.get_organ(occupant)
	if(!organ || !can_perform(order.procedure, organ))
		remove_order(order)
		stop_if_queue_empty()
		return
	if(emagged && prob(AUTODOC_WORK_SOUND_CHANCE))
		play_operation_sound('sound/weapons/circsawhit.ogg', 50)
	if(order.procedure.continuous && !emagged)
		process_regeneration(order, organ, seconds_per_tick)
		return
	if(!order.paid && !begin_order(order, organ))
		return

	order.elapsed += seconds_per_tick SECONDS
	if(order.elapsed >= order.duration)
		complete_order(order, organ)

/obj/machinery/autodoc/proc/process_malfunction()
	if(occupant.stat == DEAD)
		set_running(FALSE)
		go_out()
		return
	if(get_fuel() <= 0)
		if(running)
			halt_no_fuel()
		return
	add_all_orders()
	if(!length(queue))
		inflict_new_pathology()
		add_all_orders()
	if(length(queue) && !running)
		playsound(loc, 'sound/machines/door_locked.ogg', 50, TRUE)
		set_running(TRUE)
	else if(!length(queue) && running)
		set_running(FALSE)

/obj/machinery/autodoc/proc/inflict_new_pathology()
	var/list/organic_limbs = list()
	for(var/obj/item/organ/external/limb as anything in occupant.bodyparts)
		if(!limb.is_robotic())
			organic_limbs += limb
	if(length(organic_limbs))
		harm_organ(pick(organic_limbs))

/obj/machinery/autodoc/proc/process_regeneration(datum/autodoc_order/order, obj/item/organ/external/limb, seconds_per_tick)
	var/datum/autodoc_procedure/regeneration/procedure = order.procedure
	var/list/settings = get_mode_settings()
	var/damage_per_unit = AUTODOC_DAMAGE_PER_UNIT / cost_mod
	var/heal_budget = min(AUTODOC_REGENERATION_RATE * speed_mod / settings["duration"] * seconds_per_tick, get_fuel() * damage_per_unit)
	if(heal_budget <= 0)
		halt_no_fuel()
		return
	var/healed = procedure.regenerate(limb, heal_budget)
	if(healed <= 0)
		remove_order(order)
		return
	reagents.remove_reagent(AUTODOC_FUEL, healed / damage_per_unit)
	if(!procedure.is_needed(limb, src))
		remove_order(order)

/obj/machinery/autodoc/proc/begin_order(datum/autodoc_order/order, obj/item/organ/organ)
	order.cost = get_order_cost(order.procedure, organ)
	order.duration = get_order_duration(order.procedure, organ)
	if(emagged)
		order.cost = min(order.cost, get_fuel())
		order.duration = min(order.duration, AUTODOC_EMAG_MAX_DURATION)
	if(get_fuel() < order.cost)
		halt_no_fuel()
		return FALSE
	reagents.remove_reagent(AUTODOC_FUEL, order.cost)
	order.failure_chance = get_failure_chance(order.procedure)
	order.elapsed = 0
	order.paid = TRUE
	play_operation_sound(order.procedure.begin_sound)
	if(order.procedure.invasive)
		manage_pain(organ)
	return TRUE

/obj/machinery/autodoc/proc/manage_pain(obj/item/organ/organ)
	if(occupant.stat == DEAD || HAS_TRAIT(occupant, TRAIT_NO_PAIN))
		return
	if(emagged)
		occupant.custom_pain("Манипуляторы [declent_ru(GENITIVE)] вскрывают [organ.declent_ru(ACCUSATIVE)] наживую!")
		INVOKE_ASYNC(occupant, TYPE_PROC_REF(/mob, emote), "scream")
		return
	if(occupant.reagents.get_reagent_amount(AUTODOC_PAINKILLER) < AUTODOC_PAINKILLER_DOSE)
		occupant.reagents.add_reagent(AUTODOC_PAINKILLER, AUTODOC_PAINKILLER_DOSE)

/obj/machinery/autodoc/proc/complete_order(datum/autodoc_order/order, obj/item/organ/organ)
	if(prob(emagged ? get_failure_chance(order.procedure) : order.failure_chance))
		fail_order(order, organ)
		return
	order.procedure.perform(organ, src)
	play_operation_sound('sound/machines/autodoc_done.ogg', 40)
	remove_order(order)

/obj/machinery/autodoc/proc/fail_order(datum/autodoc_order/order, obj/item/organ/organ)
	harm_organ(organ)
	order.procedure.on_failure(organ)
	playsound(loc, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
	Shake(1, 0, 0.3 SECONDS)
	if(emagged)
		do_sparks(1, TRUE, src)
	else
		atom_say("Срыв процедуры: [order.procedure.name], [order.organ_name]. Процедура снята.")
	remove_order(order)
	stop_if_queue_empty()

/obj/machinery/autodoc/proc/harm_organ(obj/item/organ/organ)
	var/multiplier = emagged ? AUTODOC_EMAG_HARM_MULTIPLIER : 1
	if(!isexternalorgan(organ))
		organ.internal_receive_damage(AUTODOC_HARM_ORGAN * multiplier)
		return
	organ.owner?.apply_damage(AUTODOC_HARM_LIMB * multiplier, BRUTE, organ)

/obj/machinery/autodoc/proc/halt_no_fuel()
	playsound(loc, 'sound/machines/buzz-two.ogg', 40, TRUE)
	atom_say("Недостаточно синт-плоти. Программа приостановлена.")
	set_running(FALSE)

/obj/machinery/autodoc/proc/finish_program()
	set_running(FALSE)
	if(!occupant)
		return
	atom_say("Программа лечения завершена.")
	if(auto_eject)
		go_out()

/obj/machinery/autodoc/proc/remove_order(datum/autodoc_order/order)
	queue -= order
	qdel(order)
	SStgui.update_uis(src)

/obj/machinery/autodoc/proc/stop_if_queue_empty()
	if(running && !emagged && !length(queue))
		set_running(FALSE)

/obj/machinery/autodoc/proc/abort_order(datum/autodoc_order/order)
	var/obj/item/organ/organ = order.get_organ(occupant)
	if(organ && order.paid && order.procedure.invasive)
		harm_organ(organ)
		if(occupant)
			to_chat(occupant, span_userdanger("Манипуляторы [declent_ru(GENITIVE)] резко выходят из [organ.declent_ru(GENITIVE)]!"))
	remove_order(order)
	stop_if_queue_empty()

/obj/machinery/autodoc/proc/clear_queue()
	running = FALSE
	if(length(queue))
		abort_order(queue[1])
	QDEL_LIST(queue)
	set_running(FALSE)

/obj/machinery/autodoc/proc/add_order(datum/autodoc_procedure/procedure, obj/item/organ/organ)
	if(!can_perform(procedure, organ))
		return FALSE
	if(is_queued(procedure, organ))
		return FALSE
	queue += new /datum/autodoc_order(procedure, organ)
	return TRUE

/obj/machinery/autodoc/proc/get_patient_organs()
	return occupant.bodyparts + occupant.internal_organs

/obj/machinery/autodoc/proc/add_all_orders()
	var/list/organs = get_patient_organs()
	for(var/id in GLOB.autodoc_procedures)
		var/datum/autodoc_procedure/procedure = GLOB.autodoc_procedures[id]
		if(!procedure.auto_queue)
			continue
		for(var/obj/item/organ/organ as anything in organs)
			add_order(procedure, organ)

/obj/machinery/autodoc/proc/raise_order(datum/autodoc_order/order)
	var/index = queue.Find(order)
	if(index <= 1)
		return
	var/datum/autodoc_order/above = queue[index - 1]
	if(above.paid)
		return
	queue.Swap(index, index - 1)

/obj/machinery/autodoc/proc/start_program(mob/user)
	if(!occupant || !length(queue))
		return
	set_running(TRUE)
	add_attack_logs(user, occupant, "started autodoc program")

/obj/machinery/autodoc/proc/store_organ(obj/item/organ/internal/organ)
	if(length(organ_tray) >= AUTODOC_TRAY_SIZE)
		organ.forceMove(loc)
		return
	organ.forceMove(src)
	organ_tray += organ

/obj/machinery/autodoc/proc/go_out()
	if(!occupant)
		return
	playsound(loc, 'sound/machines/hiss.ogg', 30, TRUE)
	occupant.forceMove(loc)
	for(var/atom/movable/stray in contents - component_parts - organ_tray - installed_modules)
		stray.forceMove(loc)

/obj/machinery/autodoc/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone in organ_tray)
		organ_tray -= gone
		SStgui.update_uis(src)
		return
	if(gone in installed_modules)
		installed_modules -= gone
		SStgui.update_uis(src)
		return
	if(gone != occupant)
		return
	clear_queue()
	occupant = null
	update_patient_icon()
	update_icon(UPDATE_OVERLAYS)
	SStgui.update_uis(src)

/obj/machinery/autodoc/get_organ_preservation_chance()
	return AUTODOC_ORGAN_PRESERVE_CHANCE

/obj/machinery/autodoc/force_eject_occupant(mob/target)
	go_out()

/obj/machinery/autodoc/AllowDrop()
	return FALSE

/obj/machinery/autodoc/relaymove(mob/user)
	if(user.incapacitated())
		return
	if(is_locked())
		to_chat(user, span_userdanger("Крышка [declent_ru(GENITIVE)] заблокирована!"))
		return
	go_out()

/obj/machinery/autodoc/ex_act(severity, target)
	occupant?.ex_act(severity, target)
	return ..()

/obj/machinery/autodoc/emp_act(severity)
	if(!(stat & (BROKEN|NOPOWER)))
		go_out()
	return ..()

/obj/machinery/autodoc/emag_act(mob/user)
	if(emagged)
		return
	emagged = TRUE
	mode = AUTODOC_MODE_OVERDRIVE
	do_sparks(3, TRUE, src)
	playsound(src, SFX_SPARKS, 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	add_attack_logs(user, src, "emagged")
	if(user)
		balloon_alert(user, "протоколы безопасности отключены")
	if(occupant && !(stat & (NOPOWER|BROKEN)))
		process_malfunction()
	update_icon(UPDATE_OVERLAYS)
	SStgui.update_uis(src)

/obj/machinery/autodoc/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/autodoc/attack_ghost(mob/user)
	ui_interact(user)

/obj/machinery/autodoc/attack_hand(mob/user)
	if(stat & (NOPOWER|BROKEN))
		return
	if(..())
		return TRUE
	if(panel_open)
		balloon_alert(user, "техпанель открыта!")
		return
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/autodoc/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(exchange_parts(user, I))
		return ATTACK_CHAIN_PROCEED_SUCCESS
	if(is_reagent_container(I))
		add_fingerprint(user)
		refill_tank(I, user)
		return ATTACK_CHAIN_BLOCKED_ALL
	if(is_internal_organ(I))
		add_fingerprint(user)
		load_organ(I, user)
		return ATTACK_CHAIN_BLOCKED_ALL
	if(istype(I, /obj/item/disk/autodoc_module))
		add_fingerprint(user)
		load_module(I, user)
		return ATTACK_CHAIN_BLOCKED_ALL
	return ..()

/obj/machinery/autodoc/proc/refill_tank(obj/item/reagent_containers/container, mob/user)
	if(!container.is_open_container() && !container.is_drainable())
		balloon_alert(user, "ёмкость закрыта!")
		return
	if(!container.reagents.has_reagent(AUTODOC_FUEL))
		balloon_alert(user, "нет синт-плоти!")
		return
	if(reagents.total_volume >= reagents.maximum_volume)
		balloon_alert(user, "бак полон!")
		return
	var/transferred = container.reagents.trans_id_to(src, AUTODOC_FUEL, reagents.maximum_volume)
	playsound(loc, 'sound/effects/slosh.ogg', 25, TRUE)
	balloon_alert(user, "заправлено [round(transferred, 0.1)] ед")
	SStgui.update_uis(src)

/obj/machinery/autodoc/proc/load_organ(obj/item/organ/internal/organ, mob/user)
	if(is_internal_organ_brain(organ))
		balloon_alert(user, "мозг не подходит!")
		return
	if(length(organ_tray) >= AUTODOC_TRAY_SIZE)
		balloon_alert(user, "лоток полон!")
		return
	if(!user.drop_transfer_item_to_loc(organ, src))
		return
	organ_tray += organ
	balloon_alert(user, "орган в лотке")
	SStgui.update_uis(src)

/obj/machinery/autodoc/proc/load_module(obj/item/disk/autodoc_module/module, mob/user)
	if(has_module(module.module_id))
		balloon_alert(user, "модуль уже установлен!")
		return
	if(!user.drop_transfer_item_to_loc(module, src))
		return
	installed_modules += module
	playsound(loc, 'sound/machines/click.ogg', 30, TRUE)
	balloon_alert(user, "модуль установлен")
	SStgui.update_uis(src)

/obj/machinery/autodoc/grab_attack(mob/living/grabber, atom/movable/grabbed_thing)
	. = TRUE
	if(grabber.grab_state < GRAB_AGGRESSIVE || !ishuman(grabbed_thing))
		return .
	if(can_accept(grabbed_thing, grabber))
		INVOKE_ASYNC(src, PROC_REF(put_in), grabbed_thing, grabber)

/obj/machinery/autodoc/mouse_drop_receive(atom/movable/dropped, mob/user, params)
	if(!ishuman(dropped) || dropped.loc == user)
		return
	if(user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return
	if(get_dist(user, src) > 1 || get_dist(user, dropped) > 1)
		return
	if(!ishuman(user) && !isrobot(user))
		return
	if(!isturf(user.loc) || !isturf(dropped.loc))
		return
	if(can_accept(dropped, user))
		INVOKE_ASYNC(src, PROC_REF(put_in), dropped, user)

/obj/machinery/autodoc/proc/is_compatible(mob/living/carbon/human/patient)
	return !(ismachineperson(patient) || isplasmaman(patient) || isnucleation(patient) || isunathi(patient))

/obj/machinery/autodoc/proc/can_accept(mob/living/carbon/human/patient, mob/user)
	if(!is_compatible(patient))
		to_chat(patient, span_warning("Вы не совместимы с [declent_ru(INSTRUMENTAL)]: манипуляторы не рассчитаны на вашу физиологию."))
		if(patient != user)
			to_chat(user, span_warning("[patient] не совместим[GEND_A_O_Y(patient)] с [declent_ru(INSTRUMENTAL)]: манипуляторы не рассчитаны на такую физиологию."))
		balloon_alert(user, "физиология несовместима!")
		return FALSE
	if(panel_open)
		balloon_alert(user, "техпанель открыта!")
		return FALSE
	if(occupant)
		balloon_alert(user, "внутри кто-то есть!")
		return FALSE
	if(patient.buckled)
		return FALSE
	if(patient.abiotic())
		balloon_alert(user, "руки субъекта заняты!")
		return FALSE
	if(patient.has_buckled_mobs())
		to_chat(user, span_warning("[patient] не помест[PLUR_IT_YAT(patient)]ся в [declent_ru(ACCUSATIVE)], пока на [GEND_ON_IN_HIM(patient)] сидит слайм!"))
		return FALSE
	return TRUE

/obj/machinery/autodoc/proc/put_in(mob/living/carbon/human/patient, mob/user)
	if(patient == user)
		visible_message("[user] начина[PLUR_ET_YUT(user)] залезать в [declent_ru(ACCUSATIVE)].")
	else
		visible_message("[user] начина[PLUR_ET_YUT(user)] укладывать [patient] в [declent_ru(ACCUSATIVE)].")
	if(!do_after(user, 3 SECONDS, patient) || QDELETED(src) || !can_accept(patient, user))
		return
	accept_patient(patient)
	add_fingerprint(user)

/obj/machinery/autodoc/proc/accept_patient(mob/living/carbon/human/patient)
	patient.forceMove(src)
	occupant = patient
	update_patient_icon()
	update_icon(UPDATE_OVERLAYS)
	playsound(loc, 'sound/machines/door_close.ogg', 30, TRUE)
	to_chat(patient, span_boldnotice("Над вами смыкается крышка [declent_ru(GENITIVE)], и манипуляторы приходят в движение."))
	if(emagged && !(stat & (NOPOWER|BROKEN)))
		process_malfunction()
	SStgui.update_uis(src)

/obj/machinery/autodoc/crowbar_act(mob/user, obj/item/I)
	if(default_deconstruction_crowbar(user, I))
		return TRUE

/obj/machinery/autodoc/screwdriver_act(mob/user, obj/item/I)
	if(occupant)
		balloon_alert(user, "внутри кто-то есть!")
		return TRUE
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, I))
		update_icon(UPDATE_OVERLAYS)
		return TRUE

/obj/machinery/autodoc/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(occupant)
		balloon_alert(user, "внутри кто-то есть!")
		return
	if(panel_open)
		balloon_alert(user, "техпанель открыта!")
		return
	setDir(turn(dir, -90))

/obj/machinery/autodoc/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AutoDoc", "AutoDOCtor 3000")
		ui.open()

/obj/machinery/autodoc/ui_static_data(mob/user)
	var/static/list/body_icons
	if(!body_icons)
		body_icons = list()
		for(var/state in list("human", "head", "chest", "groin", "l_arm", "r_arm", "l_leg", "r_leg"))
			body_icons[state] = icon2base64(icon('icons/misc/autodoc.dmi', state))
	return list(
		"bodyIcons" = body_icons,
		"trayMax" = AUTODOC_TRAY_SIZE,
		"cyberMax" = CYBER_CAPACITY_MAX,
		"cyberBase" = CYBER_CAPACITY_BASE,
		"cyberChipBonus" = CYBER_CAPACITY_CHIP_BONUS,
	)

/obj/machinery/autodoc/ui_data(mob/user)
	var/list/settings = get_mode_settings()
	var/list/data = list(
		"fuel" = round(get_fuel(), 0.1),
		"maxFuel" = reagents.maximum_volume,
		"running" = running,
		"powered" = !(stat & (NOPOWER|BROKEN)),
		"autoEject" = auto_eject,
		"emagged" = emagged,
		"locked" = is_locked(),
		"operating" = is_operating(),
		"hasAccess" = emagged || allowed(user),
		"controlsLocked" = emagged || !allowed(user),
		"mode" = mode,
		"speedMod" = round(speed_mod / settings["duration"], 0.01),
		"costMod" = round(cost_mod, 0.01),
		"occupant" = null,
		"diagnosis" = list(),
		"warnings" = list(),
		"queue" = list(),
		"organs" = list(),
		"tray" = get_tray_data(),
		"modules" = get_modules_data(),
	)
	if(!occupant)
		return data

	data["occupant"] = list(
		"name" = occupant.name,
		"stat" = occupant.stat,
		"health" = occupant.health,
		"maxHealth" = occupant.maxHealth,
		"brute" = occupant.getBruteLoss(),
		"burn" = occupant.getFireLoss(),
		"tox" = occupant.getToxLoss(),
		"oxy" = occupant.getOxyLoss(),
		"failureChance" = round(get_failure_chance(), 1),
		"organFailureChance" = round(get_failure_chance(GLOB.autodoc_procedures["organ_damage"]), 1),
		"cyberCapacity" = occupant.cyber_capacity,
		"cyberLoad" = occupant.get_cyber_load(),
		"hasNeuroadapter" = !!occupant.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEUROADAPTER),
	)
	data["diagnosis"] = get_diagnosis()
	data["warnings"] = get_warnings()
	data["organs"] = get_organs_data()

	var/list/queue_data = list()
	for(var/datum/autodoc_order/order as anything in queue)
		var/obj/item/organ/organ = order.get_organ(occupant)
		if(organ && !can_perform(order.procedure, organ))
			organ = null
		queue_data += list(list(
			"uid" = order.UID(),
			"name" = order.procedure.name,
			"organ" = order.organ_name,
			"paid" = order.paid,
			"continuous" = order.procedure.continuous,
			"elapsed" = order.elapsed / (1 SECONDS),
			"duration" = (order.paid ? order.duration : (organ ? get_order_duration(order.procedure, organ) : 0)) / (1 SECONDS),
			"cost" = order.paid ? order.cost : (organ ? get_order_cost(order.procedure, organ) : 0),
		))
	data["queue"] = queue_data
	return data

/obj/machinery/autodoc/proc/is_queued(datum/autodoc_procedure/procedure, obj/item/organ/organ)
	for(var/datum/autodoc_order/order as anything in queue)
		if(order.targets(procedure, organ))
			return TRUE
	return FALSE

/obj/machinery/autodoc/proc/get_display_zone(obj/item/organ/organ)
	var/static/list/zone_groups = list(
		BODY_ZONE_PRECISE_EYES = BODY_ZONE_HEAD,
		BODY_ZONE_PRECISE_MOUTH = BODY_ZONE_HEAD,
		BODY_ZONE_PRECISE_L_HAND = BODY_ZONE_L_ARM,
		BODY_ZONE_PRECISE_R_HAND = BODY_ZONE_R_ARM,
		BODY_ZONE_PRECISE_L_FOOT = BODY_ZONE_L_LEG,
		BODY_ZONE_PRECISE_R_FOOT = BODY_ZONE_R_LEG,
	)
	var/obj/item/organ/external/limb = organ
	var/zone = isexternalorgan(organ) ? limb.limb_zone : organ.parent_organ_zone
	return zone_groups[zone] || zone

/obj/machinery/autodoc/proc/get_diagnosis()
	. = list()
	var/list/organs = get_patient_organs()
	for(var/id in GLOB.autodoc_procedures)
		var/datum/autodoc_procedure/procedure = GLOB.autodoc_procedures[id]
		if(!procedure.auto_queue)
			continue
		for(var/obj/item/organ/organ as anything in organs)
			if(!can_perform(procedure, organ))
				continue
			. += list(list(
				"id" = procedure.id,
				"name" = procedure.name,
				"organ" = organ.declent_ru(NOMINATIVE),
				"organUid" = organ.UID(),
				"zone" = get_display_zone(organ),
				"invasive" = procedure.invasive,
				"risk" = round(get_failure_chance(procedure), 1),
				"duration" = round(get_order_duration(procedure, organ) / (1 SECONDS)),
				"cost" = get_order_cost(procedure, organ),
				"queued" = is_queued(procedure, organ),
			))

/obj/machinery/autodoc/proc/get_organs_data()
	. = list()
	var/datum/autodoc_procedure/organ_extract/procedure = GLOB.autodoc_procedures["organ_extract"]
	var/datum/autodoc_procedure/lobotomy/lobotomy = GLOB.autodoc_procedures["lobotomy"]
	for(var/obj/item/organ/internal/organ as anything in occupant.internal_organs)
		var/obj/item/organ/internal/cyberimp/implant = organ
		. += list(list(
			"uid" = organ.UID(),
			"name" = organ.declent_ru(NOMINATIVE),
			"zone" = get_display_zone(organ),
			"cyberCost" = istype(implant) ? implant.cyber_cost : null,
			"damage" = organ.damage,
			"maxDamage" = organ.max_damage,
			"dead" = organ.is_dead(),
			"canExtract" = can_perform(procedure, organ),
			"canLobotomy" = can_perform(lobotomy, organ),
			"lobotomyQueued" = is_queued(lobotomy, organ),
			"queued" = is_queued(procedure, organ),
			"risk" = round(get_failure_chance(procedure), 1),
			"duration" = round(get_order_duration(procedure, organ) / (1 SECONDS)),
			"cost" = get_order_cost(procedure, organ),
		))

/obj/machinery/autodoc/proc/get_tray_data()
	. = list()
	for(var/obj/item/organ/internal/organ as anything in organ_tray)
		var/datum/autodoc_procedure/organ_install/procedure = get_install_procedure(organ)
		var/obj/item/organ/internal/replaced = occupant?.get_organ_slot(organ.slot)
		var/obj/item/organ/internal/cyberimp/implant = organ
		var/obj/item/organ/internal/cyberimp/replaced_implant = replaced
		. += list(list(
			"uid" = organ.UID(),
			"name" = organ.declent_ru(NOMINATIVE),
			"cyberCost" = istype(implant) ? implant.cyber_cost : null,
			"cyberFreed" = istype(replaced_implant) ? replaced_implant.cyber_cost : 0,
			"overCapacity" = istype(implant) && occupant && implant.cyber_cost > occupant.get_free_cyber_capacity(implant.slot),
			"damage" = organ.damage,
			"maxDamage" = organ.max_damage,
			"dead" = organ.is_dead(),
			"canInstall" = can_perform(procedure, organ),
			"needsModule" = procedure.required_module && !has_module(procedure.required_module),
			"replaces" = replaced?.declent_ru(NOMINATIVE),
			"queued" = is_queued(procedure, organ),
			"risk" = round(get_failure_chance(procedure), 1),
			"duration" = round(get_order_duration(procedure, organ) / (1 SECONDS)),
			"cost" = get_order_cost(procedure, organ),
		))

/obj/machinery/autodoc/proc/get_modules_data()
	. = list()
	for(var/obj/item/disk/autodoc_module/module_type as anything in subtypesof(/obj/item/disk/autodoc_module))
		var/obj/item/disk/autodoc_module/installed
		for(var/obj/item/disk/autodoc_module/module as anything in installed_modules)
			if(module.type == module_type)
				installed = module
				break
		. += list(list(
			"id" = module_type::module_id,
			"name" = module_type::display_name,
			"description" = module_type::description,
			"uid" = installed?.UID(),
		))

/obj/machinery/autodoc/proc/get_warnings()
	. = list()
	if(occupant.stat == DEAD)
		. += "Пациент мёртв: после лечения нужна реанимация."
	if(!has_module(AUTODOC_MODULE_ORGANS))
		for(var/obj/item/organ/internal/organ as anything in occupant.internal_organs)
			if(!organ.is_robotic() && (organ.damage > 0 || organ.is_dead()))
				. += "Повреждены органы: нужен модуль восстановления или хирург."
				break
	if(occupant.getToxLoss() > 0)
		. += "Токсины: нужен антитоксин или диализ."
	if(occupant.getOxyLoss() > 0)
		. += "Удушье: нужна кислородная терапия."
	if(occupant.getCloneLoss() > 0)
		. += "Клеточные повреждения: нужна криокамера."
	if(!HAS_TRAIT(occupant, TRAIT_NO_BLOOD) && occupant.blood_volume < BLOOD_VOLUME_SAFE)
		. += "Кровопотеря: нужно переливание."
	var/static/list/limb_zones = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	for(var/zone in limb_zones)
		if(!occupant.get_organ(zone))
			. += "Утрачена конечность: нужна реплантация."
			break
	for(var/obj/item/organ/external/limb as anything in occupant.bodyparts)
		if(limb.is_robotic() && (limb.brute_dam + limb.burn_dam) > 0)
			. += "Повреждены протезы: нужен ремонт."
			break

/obj/machinery/autodoc/ui_act(action, list/params)
	if(..())
		return
	if(usr == occupant)
		return
	if(panel_open)
		balloon_alert(usr, "техпанель открыта!")
		return
	if(stat & (NOPOWER|BROKEN))
		return
	var/static/list/emag_allowed_actions = list("set_mode", "tray_eject")
	if(emagged && !(action in emag_allowed_actions) && (action != "eject" || is_locked()))
		playsound(loc, 'sound/machines/buzz-two.ogg', 40, TRUE)
		balloon_alert(usr, "управление заблокировано!")
		return
	if(!emagged && (action != "eject" || is_operating()) && !allowed(usr))
		playsound(loc, 'sound/machines/buzz-two.ogg', 40, TRUE)
		balloon_alert(usr, "доступ запрещён!")
		return

	. = TRUE
	switch(action)
		if("add_order")
			var/datum/autodoc_procedure/procedure = GLOB.autodoc_procedures[params["id"]]
			var/obj/item/organ/organ = locateUID(params["organUid"])
			if(!occupant || !procedure?.auto_queue || !istype(organ) || organ.owner != occupant)
				return FALSE
			add_order(procedure, organ)
		if("lobotomy")
			var/obj/item/organ/internal/organ = locateUID(params["uid"])
			if(!occupant || !is_internal_organ_brain(organ) || organ.owner != occupant)
				return FALSE
			if(add_order(GLOB.autodoc_procedures["lobotomy"], organ))
				add_attack_logs(usr, occupant, "queued autodoc lobotomy")
		if("add_all")
			if(!occupant)
				return FALSE
			add_all_orders()
		if("extract_organ")
			var/obj/item/organ/internal/organ = locateUID(params["uid"])
			if(!occupant || !is_internal_organ(organ) || organ.owner != occupant)
				return FALSE
			if(add_order(GLOB.autodoc_procedures["organ_extract"], organ))
				add_attack_logs(usr, occupant, "queued autodoc extraction of [organ]")
		if("install_organ")
			var/obj/item/organ/internal/organ = locateUID(params["uid"])
			if(!occupant || !(organ in organ_tray))
				return FALSE
			if(add_order(get_install_procedure(organ), organ))
				add_attack_logs(usr, occupant, "queued autodoc installation of [organ]")
		if("tray_eject")
			var/obj/item/organ/internal/organ = locateUID(params["uid"])
			if(!(organ in organ_tray))
				return FALSE
			organ.forceMove(loc)
		if("remove_order")
			var/datum/autodoc_order/order = locateUID(params["uid"])
			if(!(order in queue))
				return FALSE
			abort_order(order)
		if("raise_order")
			var/datum/autodoc_order/order = locateUID(params["uid"])
			if(!(order in queue))
				return FALSE
			raise_order(order)
		if("clear")
			clear_queue()
		if("start")
			start_program(usr)
		if("pause")
			set_running(FALSE)
		if("eject")
			go_out()
		if("toggle_auto_eject")
			auto_eject = !auto_eject
		if("set_mode")
			var/new_mode = params["mode"]
			var/static/list/normal_modes = list(AUTODOC_MODE_SLOW, AUTODOC_MODE_MEDIUM, AUTODOC_MODE_FAST)
			if(!(new_mode in normal_modes) && !(emagged && new_mode == AUTODOC_MODE_OVERDRIVE))
				return FALSE
			if(running)
				playsound(loc, 'sound/machines/buzz-two.ogg', 40, TRUE)
				balloon_alert(usr, "идёт работа!")
				return FALSE
			mode = new_mode
		if("eject_module")
			var/obj/item/disk/autodoc_module/module = locateUID(params["uid"])
			if(!(module in installed_modules))
				return FALSE
			module.forceMove(loc)
		else
			return FALSE
	add_fingerprint(usr)

#undef AUTODOC_FUEL
#undef AUTODOC_PAINKILLER
#undef AUTODOC_PAINKILLER_DOSE
#undef AUTODOC_TANK_PER_BIN_RATING
#undef AUTODOC_TRAY_SIZE
#undef AUTODOC_FAILURE_BASE
#undef AUTODOC_FAILURE_DELICATE
#undef AUTODOC_FAILURE_UPGRADED
#undef AUTODOC_MAX_PART_RATING
#undef AUTODOC_HARM_LIMB
#undef AUTODOC_HARM_ORGAN
#undef AUTODOC_EMAG_HARM_MULTIPLIER
#undef AUTODOC_EMAG_MAX_DURATION
#undef AUTODOC_PATIENT_ICON_SIZE
#undef AUTODOC_WORK_SOUND_CHANCE
#undef AUTODOC_ORGAN_PRESERVE_CHANCE
