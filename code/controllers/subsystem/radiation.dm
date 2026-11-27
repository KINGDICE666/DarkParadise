SUBSYSTEM_DEF(radiation)
	name = "Radiation"
	ss_flags = SS_BACKGROUND | SS_NO_INIT
	wait = 0.5 SECONDS
	/// Тайлы с необработанным импульсом и его сила. Импульсы с одного тайла складываются.
	/// Do not interact with this directly, use `radiation_pulse` instead.
	var/list/processing = list()
	/// Что дало последний импульс тайла в очереди, для логов
	var/list/source_names = list()
	/// Атомы, которые узнают о каждом дошедшем импульсе, см. [/datum/controller/subsystem/radiation/proc/add_listener]
	var/list/atom/listeners = list()
	/// Отделы, в которых сейчас объявлена эвакуация
	var/list/evacuating = list()
	COOLDOWN_DECLARE(evacuation_cooldown)

/datum/controller/subsystem/radiation/fire(resumed)
	while(length(processing))
		var/turf/source_turf = processing[length(processing)]
		var/rads = processing[source_turf]
		var/source_name = source_names[source_turf]
		processing.len--
		source_names -= source_turf

		pulse(source_turf, rads, source_name)

		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/radiation/stat_entry(msg)
	msg = "Pulses:[length(processing)]|Listeners:[length(listeners)]"
	return ..()

/// Атом начинает получать COMSIG_RADIATION_DETECTED, что бы это ни было и где бы ни находилось.
/datum/controller/subsystem/radiation/proc/add_listener(atom/listener)
	listeners |= listener
	RegisterSignal(listener, COMSIG_QDELETING, PROC_REF(remove_listener), override = TRUE)

/datum/controller/subsystem/radiation/proc/remove_listener(atom/listener)
	SIGNAL_HANDLER

	listeners -= listener
	UnregisterSignal(listener, COMSIG_QDELETING)

/datum/controller/subsystem/radiation/proc/pulse(turf/source_turf, rads, source_name)
	var/list/insulation_cache = list()
	var/source_x = source_turf.x
	var/source_y = source_turf.y
	var/source_z = source_turf.z
	var/max_range = min(CEILING(sqrt(rads / RAD_MINIMUM_DOSE), 1), RAD_MAXIMUM_RANGE)

	for(var/mob/living/carbon/human/human as anything in GLOB.human_list)
		var/turf/target_turf = get_turf(human)
		if(target_turf?.z != source_z || abs(target_turf.x - source_x) > max_range || abs(target_turf.y - source_y) > max_range)
			continue

		if(human.stat == DEAD || HAS_TRAIT(human, TRAIT_RADIMMUNE))
			continue

		var/dose = get_dose_at(source_turf, target_turf, rads, insulation_cache)
		if(human.loc != target_turf)
			dose *= get_containment_insulation(human)

		if(dose >= RAD_MINIMUM_DOSE)
			expose(human, dose, source_name)

	for(var/atom/listener as anything in listeners)
		var/turf/listener_turf = get_turf(listener)
		if(listener_turf?.z != source_z || abs(listener_turf.x - source_x) > max_range || abs(listener_turf.y - source_y) > max_range)
			continue

		var/dose = get_dose_at(source_turf, listener_turf, rads, insulation_cache) * get_containment_insulation(listener)
		if(dose >= RAD_MINIMUM_DOSE)
			SEND_SIGNAL(listener, COMSIG_RADIATION_DETECTED, dose, source_turf)

	if(rads >= RAD_ITEM_MINIMUM_DOSE)
		contaminate_items(source_turf, rads, insulation_cache)

/// Загрязняет только сильный импульс и только вблизи. Поэтому не приходится перебирать все предметы в комнате.
/datum/controller/subsystem/radiation/proc/contaminate_items(turf/source_turf, rads, list/insulation_cache)
	var/item_range = min(CEILING(sqrt(rads / RAD_ITEM_MINIMUM_DOSE), 1), RAD_ITEM_MAXIMUM_RANGE)
	for(var/turf/item_turf as anything in RANGE_TURFS(item_range, source_turf))
		var/dose = -1
		for(var/obj/item/item in item_turf)
			if(dose < 0)
				dose = get_dose_at(source_turf, item_turf, rads, insulation_cache)
			if(dose < RAD_ITEM_MINIMUM_DOSE)
				break
			contaminate(item, dose)

/// Возвращает то, что осталось от импульса на целевом тайле
/datum/controller/subsystem/radiation/proc/get_dose_at(turf/source_turf, turf/target_turf, rads, list/insulation_cache)
	var/source_x = source_turf.x
	var/source_y = source_turf.y
	var/delta_x = target_turf.x - source_x
	var/delta_y = target_turf.y - source_y

	. = rads / max(delta_x * delta_x + delta_y * delta_y, 1)
	if(. < RAD_MINIMUM_DOSE)
		return 0

	var/steps = max(abs(delta_x), abs(delta_y))
	var/x_step = steps ? delta_x / steps : 0
	var/y_step = steps ? delta_y / steps : 0
	for(var/step in 1 to steps)
		var/turf/turf_in_between = locate(round(source_x + x_step * step + 0.5), round(source_y + y_step * step + 0.5), source_turf.z)
		var/insulation = insulation_cache[turf_in_between]
		if(isnull(insulation))
			insulation = turf_in_between.rad_insulation
			for(var/atom/on_turf as anything in turf_in_between.contents)
				insulation *= on_turf.rad_insulation
			insulation_cache[turf_in_between] = insulation

		. *= insulation
		if(. < RAD_MINIMUM_DOSE)
			return 0

/// Выдаёт человеку внешнюю дозу с учётом одежды. Всё, что одежда остановила, остаётся на ней.
/datum/controller/subsystem/radiation/proc/expose(mob/living/carbon/human/human, dose, source_name)
	var/protection = human.get_radiation_protection()
	if(protection && dose * protection >= RAD_ITEM_MINIMUM_DOSE)
		contaminate(human.wear_suit, dose * protection)
		contaminate(human.head, dose * protection)

	dose *= 1 - protection
	if(HAS_TRAIT(human, TRAIT_RADIATION_RESISTANT))
		dose *= RAD_RESISTANCE_FACTOR

	if(dose < RAD_MINIMUM_DOSE)
		return

	var/was_sick = HAS_TRAIT(human, TRAIT_IRRADIATED)
	human.adjust_radiation_dose(dose)
	if(dose >= RAD_NOTICEABLE_DOSE)
		var/datum/component/radiation_sickness/sickness = human.GetComponent(/datum/component/radiation_sickness)
		sickness?.notify_exposure()

	if(source_name && !was_sick && HAS_TRAIT(human, TRAIT_IRRADIATED))
		human.investigate_log("was irradiated by [source_name].", INVESTIGATE_RADIATION)

/datum/controller/subsystem/radiation/proc/contaminate(obj/item/item, dose)
	if(!istype(item) || HAS_TRAIT(item, TRAIT_RADIATION_EMITTER))
		return

	var/datum/component/irradiated/contamination = item.GetComponent(/datum/component/irradiated) || item.AddComponent(/datum/component/irradiated)
	contamination.adjust_contamination(dose)

/// Пытается облучить цель без учёта расстояния и стен. Ограничена только внутриигровыми средствами вроде защитной одежды.
/datum/controller/subsystem/radiation/proc/irradiate(atom/target, dose)
	if(!can_irradiate_basic(target))
		return FALSE

	if(ishuman(target))
		expose(target, dose)
	else
		contaminate(target, dose)

	return TRUE

/// Returns whether or not the target can be irradiated by any means.
/// Does not check for clothing.
/datum/controller/subsystem/radiation/proc/can_irradiate_basic(atom/target)
	if(!CAN_IRRADIATE(target))
		return FALSE

	if(HAS_TRAIT(target, TRAIT_RADIMMUNE))
		return FALSE

	return TRUE

/// Возвращает, полностью ли человек укрыт защитной одеждой.
/datum/controller/subsystem/radiation/proc/wearing_rad_protected_clothing(mob/living/carbon/human/human)
	return human.get_radiation_protection() >= RAD_PROTECTION_SEALED
