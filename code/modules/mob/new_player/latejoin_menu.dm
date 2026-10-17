#define RANDOM_JOB_CHOICE "Random"

GLOBAL_DATUM_INIT(latejoin_menu, /datum/latejoin_menu, new)

/datum/latejoin_menu

/datum/latejoin_menu/ui_interact(mob/new_player/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "JobSelection", "Выбор должности")
		ui.open()

/datum/latejoin_menu/ui_state(mob/user)
	return GLOB.new_player_state

/datum/latejoin_menu/ui_static_data(mob/new_player/user)
	var/list/departments = list()
	var/list/department_jobs_by_name = get_departments(user)
	for(var/department_name in department_jobs_by_name)
		var/list/department_jobs = list()
		var/list/department_info = get_department_info(department_name)
		for(var/datum/job/job as anything in department_jobs_by_name[department_name])
			department_jobs[job.title] = list(
				"name" = get_job_title_ru(job.title),
				"command" = (job.title in GLOB.command_positions) || job.head_position,
				"description" = job.supervisors ? "Подчиняется: [job.supervisors]." : null,
			)
		departments[department_info["name"]] = list(
			"color" = department_info["color"],
			"jobs" = department_jobs,
		)

	return list("departments_static" = departments)

/datum/latejoin_menu/ui_data(mob/new_player/user)
	var/list/departments = list()
	var/list/data = list(
		"round_duration" = DisplayTimeText(ROUND_TIME, round_seconds_to = 1),
		"departments" = departments,
	)

	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		data["shuttle_status"] = "Экипаж объекта был эвакуирован."
	else if(SSshuttle.emergency?.mode == SHUTTLE_CALL || EMERGENCY_AT_LEAST_DOCKED)
		data["shuttle_status"] = "В настоящее время экипаж объекта проходит процедуру эвакуации."

	var/list/department_jobs_by_name = get_departments(user)
	for(var/department_name in department_jobs_by_name)
		var/list/department_jobs = list()
		var/list/department_data = list(
			"jobs" = department_jobs,
			"open_slots" = 0,
		)
		departments[get_department_info(department_name)["name"]] = department_data

		for(var/datum/job/job as anything in department_jobs_by_name[department_name])
			department_jobs[job.title] = list(
				"prioritized" = (job in SSjobs.prioritized_jobs),
				"used_slots" = job.current_positions,
				"open_slots" = job.total_positions < 0 ? "∞" : job.total_positions,
				"unavailable_reason" = get_unavailable_reason(user, job),
			)

			if(job.total_positions < 0)
				department_data["open_slots"] = "∞"
			else if(department_data["open_slots"] != "∞")
				department_data["open_slots"] += max(0, job.total_positions - job.current_positions)

	return data

/datum/latejoin_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/new_player/owner = ui.user
	if(!istype(owner) || !owner.client)
		return TRUE

	switch(action)
		if("select_job")
			var/rank = params["job"]
			if(rank == RANDOM_JOB_CHOICE)
				rank = "RandomJob"
			else if(!SSjobs.GetJob(rank))
				return TRUE
			owner.late_join_as(rank)
			return TRUE

/datum/latejoin_menu/proc/get_unavailable_reason(mob/new_player/user, datum/job/job)
	var/reason = user.get_job_unavailable_reason(job.title)
	if(reason)
		return reason
	if(job.barred_by_disability(user.client))
		return "Недоступно с инвалидностью персонажа"
	if(!job.character_old_enough(user.client))
		return "Персонаж слишком молод"
	if(!job.check_custom_requirements(user.client))
		return "Нужно достижение «Опора проекта»"

/datum/latejoin_menu/proc/get_departments(mob/new_player/user)
	var/list/departments = list()
	var/can_admin_jobs = check_rights_for(user.client, R_ADMIN)
	for(var/datum/job/job as anything in SSjobs.occupations)
		if(job.admin_only && !can_admin_jobs)
			continue
		var/department = job.department || STATION_DEPARTMENT_OTHER
		LAZYADD(departments[department], job)
		if(department != STATION_DEPARTMENT_COMMAND && (job.title in GLOB.command_positions))
			LAZYADD(departments[STATION_DEPARTMENT_COMMAND], job)

	var/list/sorted_departments = list()
	for(var/department in get_department_order())
		if(departments[department])
			sorted_departments[department] = departments[department]
	return sorted_departments

/datum/latejoin_menu/proc/get_department_order()
	var/static/list/department_order = list(
		STATION_DEPARTMENT_COMMAND,
		STATION_DEPARTMENT_SECURITY,
		STATION_DEPARTMENT_ENGINEERING,
		STATION_DEPARTMENT_MEDICAL,
		STATION_DEPARTMENT_SCIENCE,
		STATION_DEPARTMENT_SUPPLY,
		STATION_DEPARTMENT_SERVICE,
		STATION_DEPARTMENT_LEGAL,
		STATION_DEPARTMENT_SILICON,
		STATION_DEPARTMENT_CIVILIAN,
		STATION_DEPARTMENT_OTHER,
	)
	return department_order

/datum/latejoin_menu/proc/get_department_info(department)
	var/static/list/department_info = list(
		STATION_DEPARTMENT_COMMAND = list("name" = STATION_DEPARTMENT_RU_COMMAND, "color" = "#6681a5"),
		STATION_DEPARTMENT_SECURITY = list("name" = STATION_DEPARTMENT_RU_SECURITY, "color" = "#d46a78"),
		STATION_DEPARTMENT_ENGINEERING = list("name" = STATION_DEPARTMENT_RU_ENGINEERING, "color" = "#dfb567"),
		STATION_DEPARTMENT_MEDICAL = list("name" = STATION_DEPARTMENT_RU_MEDICAL, "color" = "#65b2bd"),
		STATION_DEPARTMENT_SCIENCE = list("name" = STATION_DEPARTMENT_RU_SCIENCE, "color" = "#c973c9"),
		STATION_DEPARTMENT_SUPPLY = list("name" = STATION_DEPARTMENT_RU_SUPPLY, "color" = "#cf9c6c"),
		STATION_DEPARTMENT_SERVICE = list("name" = STATION_DEPARTMENT_RU_SERVICE, "color" = "#7cc46a"),
		STATION_DEPARTMENT_LEGAL = list("name" = STATION_DEPARTMENT_RU_LEGAL, "color" = "#9b87d6"),
		STATION_DEPARTMENT_SILICON = list("name" = STATION_DEPARTMENT_RU_SILICON, "color" = "#5dbda0"),
		STATION_DEPARTMENT_CIVILIAN = list("name" = STATION_DEPARTMENT_RU_CIVILIAN, "color" = "#9689db"),
		STATION_DEPARTMENT_OTHER = list("name" = STATION_DEPARTMENT_RU_OTHER, "color" = "#a0a0a0"),
	)
	return department_info[department]

#undef RANDOM_JOB_CHOICE
