/datum/preference_middleware/jobs
	action_delegations = list(
		"set_job_preference" = PROC_REF(set_job_preference),
		"set_job_title" = PROC_REF(set_job_title),
	)

/datum/preference_middleware/jobs/proc/set_job_preference(list/params, mob/user)
	var/level = params["level"]
	if(!isnull(level) && level != JP_LOW && level != JP_MEDIUM && level != JP_HIGH)
		return FALSE

	var/datum/job/job = SSjobs.GetJob(params["job"])
	if(!is_selectable(job) || get_restriction(user, job))
		return FALSE

	if(level && is_exclusive_job(job))
		level = JP_LOW

	if(!preferences.set_job_preference_level(job, level))
		return FALSE

	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/jobs/proc/set_job_title(list/params, mob/user)
	var/datum/job/job = SSjobs.GetJob(params["job"])
	if(!is_selectable(job) || !length(job.alt_titles))
		return FALSE

	var/list/choices = list(get_job_title_ru(job.title)) + job.alt_titles
	var/choice = tgui_input_list(user, "Выберите альтернативное название для должности \"[get_job_title_ru(job.title)]\".", "Альтернативные названия", choices)
	if(!choice)
		return FALSE

	preferences.SetPlayerAltTitle(job, job_title_ru_to_en(choice))
	return TRUE

/datum/preference_middleware/jobs/get_constant_data()
	var/static/list/department_names = list(
		STATION_DEPARTMENT_COMMAND = STATION_DEPARTMENT_RU_COMMAND,
		STATION_DEPARTMENT_MEDICAL = STATION_DEPARTMENT_RU_MEDICAL,
		STATION_DEPARTMENT_ENGINEERING = STATION_DEPARTMENT_RU_ENGINEERING,
		STATION_DEPARTMENT_SCIENCE = STATION_DEPARTMENT_RU_SCIENCE,
		STATION_DEPARTMENT_SECURITY = STATION_DEPARTMENT_RU_SECURITY,
		STATION_DEPARTMENT_SUPPLY = STATION_DEPARTMENT_RU_SUPPLY,
		STATION_DEPARTMENT_SERVICE = STATION_DEPARTMENT_RU_SERVICE,
		STATION_DEPARTMENT_LEGAL = STATION_DEPARTMENT_RU_LEGAL,
		STATION_DEPARTMENT_SILICON = STATION_DEPARTMENT_RU_SILICON,
		STATION_DEPARTMENT_CIVILIAN = STATION_DEPARTMENT_RU_CIVILIAN,
	)

	var/list/departments = list()
	var/list/jobs = list()

	for(var/datum/job/job as anything in SSjobs.occupations)
		if(!is_selectable(job) || !(job.department in department_names))
			continue

		if(isnull(departments[job.department]))
			departments[job.department] = list(
				"name" = department_names[job.department],
				"head" = null,
			)

		if(isnull(departments[job.department]["head"]) && (job.head_position || (job.title in GLOB.command_positions)))
			departments[job.department]["head"] = job.title

		jobs[job.title] = list(
			"name" = get_job_title_ru(job.title),
			"description" = job.supervisors ? "Подчиняется: [job.supervisors]." : null,
			"department" = job.department,
			"exclusive" = is_exclusive_job(job),
			"alt_titles" = length(job.alt_titles) > 0,
		)

	return list(
		"departments" = departments,
		"jobs" = jobs,
	)

/datum/preference_middleware/jobs/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	var/list/job_preferences = list()
	var/list/job_titles = list()
	var/list/job_restrictions = list()

	for(var/datum/job/job as anything in SSjobs.occupations)
		if(!is_selectable(job))
			continue

		var/priority = preferences.get_job_preference_level(job)
		if(priority)
			job_preferences[job.title] = priority

		var/alt_title = preferences.player_alt_titles[job.title]
		if(alt_title)
			job_titles[job.title] = get_job_title_ru(alt_title)

		var/restriction = get_character_restriction(user, job)
		if(restriction)
			job_restrictions[job.title] = restriction

	return list(
		"job_preferences" = job_preferences,
		"job_titles" = job_titles,
		"job_restrictions" = job_restrictions,
	)

/datum/preference_middleware/jobs/get_ui_static_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	var/list/job_bans = list()
	var/list/job_days_left = list()
	var/list/job_required_experience = list()

	for(var/datum/job/job as anything in SSjobs.occupations)
		if(!is_selectable(job))
			continue

		if(jobban_isbanned(user, job.title))
			job_bans += job.title
			continue

		var/required_playtime_remaining = job.available_in_playtime(user.client)
		if(required_playtime_remaining)
			job_required_experience[job.title] = list(
				"experience_type" = job.get_exp_req_type(),
				"required_playtime" = required_playtime_remaining,
			)
			continue

		if(!job.player_old_enough(user.client))
			job_days_left[job.title] = job.available_in_days(user.client)

	return list(
		"job_bans" = job_bans,
		"job_days_left" = job_days_left,
		"job_required_experience" = job_required_experience,
	)

/datum/preference_middleware/jobs/proc/is_selectable(datum/job/job)
	return job && !job.admin_only && !job.hidden_from_job_prefs

/datum/preference_middleware/jobs/proc/is_exclusive_job(datum/job/job)
	return job.department_flag == JOBCAT_SUPPORT && (job.flag & JOB_FLAGS_EXCLUSIVE)

/datum/preference_middleware/jobs/proc/get_restriction(mob/user, datum/job/job)
	if(jobban_isbanned(user, job.title) || job.available_in_playtime(user.client) || !job.player_old_enough(user.client))
		return TRUE
	return get_character_restriction(user, job)

/datum/preference_middleware/jobs/proc/get_character_restriction(mob/user, datum/job/job)
	var/client/user_client = user.client
	if(!job.can_novice_play(user_client))
		return "Только для новичков"
	if(job.barred_by_disability(user_client))
		return "Инвалидность"
	if(!job.character_old_enough(user_client))
		var/age_limit = get_age_limits(preferences.get_species_prototype(), job.min_age_type)
		return "Возраст от [age_limit] [declension_ru(age_limit, "года", "лет", "лет")]"
	if(!job.check_custom_requirements(user_client))
		return "Нужно достижение"
