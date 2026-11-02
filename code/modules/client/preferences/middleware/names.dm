/datum/preference_middleware/names
	action_delegations = list(
		"randomize_name" = PROC_REF(randomize_name),
	)

/datum/preference_middleware/names/get_constant_data()
	var/list/types = list()

	for(var/preference_type in GLOB.preference_entries)
		var/datum/preference/name/name_preference = GLOB.preference_entries[preference_type]
		if(!istype(name_preference))
			continue

		types[name_preference.savefile_key] = list(
			"can_randomize" = name_preference.is_randomizable(),
			"explanation" = name_preference.explanation,
			"group" = name_preference.group,
		)

	return list("types" = types)

/datum/preference_middleware/names/get_ui_data(mob/user)
	return list("name_to_use" = get_name_to_use())

/datum/preference_middleware/names/proc/get_name_to_use()
	var/datum/job/highest_priority_job = preferences.get_highest_priority_job()

	for(var/preference_type in GLOB.preference_entries)
		var/datum/preference/name/name_preference = GLOB.preference_entries[preference_type]
		if(!istype(name_preference) || isnull(name_preference.relevant_job))
			continue

		if(highest_priority_job?.title == name_preference.relevant_job)
			return name_preference.savefile_key

	return "real_name"

/datum/preference_middleware/names/proc/randomize_name(list/params, mob/user)
	var/datum/preference/name/name_preference = GLOB.preference_entries_by_key[params["preference"]]
	if(!istype(name_preference))
		return FALSE

	if(!preferences.update_preference(name_preference, name_preference.create_random_value(preferences)))
		return FALSE

	preferences.tainted_character_profiles = TRUE
	return TRUE
