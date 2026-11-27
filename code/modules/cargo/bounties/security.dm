/datum/bounty/patrol
	name = "Патруль станции"
	description = "Проведите плановый патруль зоны \"%AREA_NAME%\". \
		Пройдите не менее %AREA_COVERAGE% м по этой зоне. \
		КПК будет сообщать вам о прогрессе."
	reward = CARGO_CRATE_VALUE * 5
	allow_duplicate = TRUE
	global_exempt = TRUE
	VAR_PRIVATE/datum/tracker
	VAR_FINAL/area/demanded_area
	VAR_FINAL/needed_coverage = -1
	VAR_FINAL/list/walked_turfs
	VAR_FINAL/alerted = 0

/datum/bounty/patrol/New()
	var/list/possible_areas = get_patrol_area_types() & GLOB.areas_by_type
	if(!length(possible_areas))
		return
	demanded_area = pick(possible_areas)

	var/total_coverage = 0
	for(var/turf/simulated/floor/walkable in GLOB.areas_by_type[demanded_area].get_turfs_from_all_zlevels())
		total_coverage += 1

	needed_coverage = round(total_coverage * rand(4, 8) * 0.1, 1)

	var/area_name = GLOB.areas_by_type[demanded_area].name
	name += ": [area_name]"
	description = replacetext(description, "%AREA_NAME%", area_name)
	description = replacetext(description, "%AREA_COVERAGE%", needed_coverage)
	reward *= (needed_coverage / 100)

/datum/bounty/patrol/Destroy(force)
	QDEL_NULL(tracker)
	return ..()

/datum/bounty/patrol/can_get()
	return needed_coverage >= 20

/datum/bounty/patrol/proc/get_patrol_area_types()
	return typecacheof(list(
		/area/station/commons,
		/area/station/hallway,
		/area/station/maintenance,
		/area/station/security/checkpoint,
		/area/station/security/prison,
		/area/station/service,
	))

/datum/bounty/patrol/proc/get_progress()
	var/progress = 0
	for(var/turf_id, count in walked_turfs)
		progress += count
	return progress

/datum/bounty/patrol/print_required()
	return "[get_progress()]/[needed_coverage] м"

/datum/bounty/patrol/can_claim()
	return get_progress() >= needed_coverage

/datum/bounty/patrol/on_selected(obj/item/card/id/id_card)
	start_tracking(id_card)

/datum/bounty/patrol/proc/start_tracking(obj/item/card/id/id_card)
	contribution |= get_account_from_card(id_card)
	tracker = AddComponent(/datum/component/connect_containers, id_card, list(COMSIG_MOVABLE_MOVED = PROC_REF(on_card_moved)))
	RegisterSignal(id_card, COMSIG_MOVABLE_MOVED, PROC_REF(on_card_moved))

/datum/bounty/patrol/on_reset(obj/item/card/id/id_card)
	stop_tracking(id_card)

/datum/bounty/patrol/proc/stop_tracking(obj/item/card/id/id_card)
	QDEL_NULL(tracker)
	UnregisterSignal(id_card, COMSIG_MOVABLE_MOVED)

/datum/bounty/patrol/proc/on_card_moved(atom/movable/moving, atom/old_loc, ...)
	SIGNAL_HANDLER

	var/turf/new_turf = get_turf(moving)
	if(!isfloorturf(new_turf) || new_turf == get_turf(old_loc) || new_turf.loc.type != demanded_area)
		return

	var/turf_id = "[new_turf.x],[new_turf.y],[new_turf.z]"
	if(LAZYACCESS(walked_turfs, turf_id) >= 3)
		return

	var/obj/item/card/id/id_card
	if(ismob(moving))
		var/mob/moving_mob = moving
		id_card = moving_mob.get_id_card()
	else if(is_id_card(moving))
		id_card = moving
	if(isnull(id_card))
		id_card = locate() in moving.get_all_contents()

	var/datum/money_account/account = id_card ? get_account_from_card(id_card) : null
	if(account?.civilian_bounty != src)
		return

	walked_turfs = walked_turfs || list()
	walked_turfs[turf_id] += 1
	var/progress = get_progress()
	if(alerted == 0)
		alerted = 1
		account.notify_pda_owner("<b>Патруль </b>\"Патруль начат. Пройдите [needed_coverage] м по зоне, чтобы его завершить.\" (Невозможно Ответить)")
		return

	var/progress_percent = progress / needed_coverage
	if(progress >= needed_coverage && alerted < 5)
		alerted = 5
		account.notify_pda_owner("<b>Патруль </b>\"Патруль завершён. Вернитесь к терминалу баунти за наградой.\" (Невозможно Ответить)")
		stop_tracking(id_card)
		return

	for(var/step in 2 to 4)
		var/threshold = (step - 1) * 0.25
		if(progress_percent >= threshold && alerted < step)
			alerted = step
			account.notify_pda_owner("<b>Патруль </b>\"Патруль выполнен на [threshold * 100]%.\" (Невозможно Ответить)")
			return

/datum/bounty/patrol/supply
	name = "Патруль снабжения"
	allow_duplicate = FALSE

/datum/bounty/patrol/supply/get_patrol_area_types()
	return typecacheof(list(/area/station/cargo))

/datum/bounty/patrol/medical
	name = "Патруль медбея"
	allow_duplicate = FALSE

/datum/bounty/patrol/medical/get_patrol_area_types()
	return typecacheof(list(/area/station/medical))

/datum/bounty/patrol/science
	name = "Патруль научного отдела"
	allow_duplicate = FALSE

/datum/bounty/patrol/science/get_patrol_area_types()
	return typecacheof(list(/area/station/science))

/datum/bounty/patrol/engineering
	name = "Патруль инженерного отдела"
	allow_duplicate = FALSE

/datum/bounty/patrol/engineering/get_patrol_area_types()
	return typecacheof(list(
		/area/station/engineering,
		/area/station/maintenance/electrical,
		/area/station/maintenance/engineering,
	))

/datum/bounty/item/contraband
	name = "Конфискованная контрабанда"
	description = "\"Синдикат\" постоянно пытается переманить экипаж станций \"Нанотрейзен\". Отправьте нам последнюю партию конфискованной контрабанды."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 5
	wanted_types = list(/obj/item = TRUE)

/datum/bounty/item/contraband/applies_to(obj/shipped)
	if(!..())
		return FALSE
	var/obj/item/shipped_item = shipped
	return findtext(shipped_item.origin_tech, "syndicate")
