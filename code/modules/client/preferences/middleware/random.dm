/datum/preference_middleware/random
	action_delegations = list(
		"randomize_character" = PROC_REF(randomize_character),
		"set_random_preference" = PROC_REF(set_random_preference),
	)

/datum/preference_middleware/random/get_character_preferences(mob/user)
	return list("randomization" = preferences.randomise)

/datum/preference_middleware/random/get_constant_data()
	var/list/randomizable = list()

	for(var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		if(preference.is_randomizable())
			randomizable += preference.savefile_key

	return list("randomizable" = randomizable)

/datum/preference_middleware/random/proc/randomize_character(list/params, mob/user)
	if(appearance_isbanned(user))
		return FALSE

	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preferences.should_randomize(preference))
			preferences.write_preference(preference, preference.create_random_value(preferences))

	preferences.sanitize_character_preferences()
	preferences.character_preview_view?.update_body()
	preferences.tainted_character_profiles = TRUE
	return TRUE

/datum/preference_middleware/random/proc/set_random_preference(list/params, mob/user)
	var/requested_preference_key = params["preference"]
	var/value = params["value"]

	var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
	if(isnull(requested_preference) || !requested_preference.is_randomizable())
		return FALSE

	switch(value)
		if(RANDOM_ANTAG_ONLY, RANDOM_ENABLED)
			preferences.randomise[requested_preference_key] = value
		if(RANDOM_DISABLED)
			preferences.randomise -= requested_preference_key
		else
			return FALSE

	return TRUE

/datum/preferences/proc/should_randomize(datum/preference/preference, is_antag)
	if(!preference.is_randomizable())
		return FALSE

	var/requested_randomization = randomise[preference.savefile_key]
	if(istype(preference, /datum/preference/name))
		requested_randomization = read_preference(/datum/preference/choiced/random_name)

	switch(requested_randomization)
		if(RANDOM_ENABLED)
			return TRUE
		if(RANDOM_ANTAG_ONLY)
			return is_antag
	return FALSE

/datum/preferences/proc/get_default_randomization()
	var/list/default_randomization = list()

	for(var/preference_key in GLOB.preference_entries_by_key)
		var/datum/preference/preference = GLOB.preference_entries_by_key[preference_key]
		if(preference.is_randomizable() && preference.randomize_by_default)
			default_randomization[preference_key] = RANDOM_ENABLED

	return default_randomization

/datum/preferences/proc/apply_character_randomization_prefs(antag_override = FALSE)
	var/random_body = read_preference(/datum/preference/choiced/random_body)
	var/randomize_body = random_body == RANDOM_ENABLED || (random_body == RANDOM_ANTAG_ONLY && antag_override)

	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(!randomize_body && !istype(preference, /datum/preference/name))
			continue
		if(should_randomize(preference, antag_override))
			write_preference(preference, preference.create_random_value(src))

	sanitize_character_preferences()
