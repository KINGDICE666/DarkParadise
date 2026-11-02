/datum/preference_middleware/legacy_toggles

/datum/preference_middleware/legacy_toggles/get_constant_data()
	var/list/category_names = list()
	for(var/category_name in GLOB.preference_toggle_groups)
		category_names["[GLOB.preference_toggle_groups[category_name]]"] = category_name

	var/list/toggles = list()
	for(var/toggle_type in GLOB.preference_toggles)
		var/datum/preference_toggle/toggle = GLOB.preference_toggles[toggle_type]
		if(toggle.preftoggle_toggle == PREFTOGGLE_SPECIAL)
			continue
		toggles[get_toggle_key(toggle_type)] = list(
			"name" = toggle.name,
			"description" = toggle.description,
			"category" = category_names["[toggle.preftoggle_category]"],
		)

	return toggles

/datum/preference_middleware/legacy_toggles/get_character_preferences(mob/user)
	if(preferences.current_window == PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return

	var/list/new_game_preferences = list()
	for(var/toggle_type in GLOB.preference_toggles)
		var/datum/preference_toggle/toggle = GLOB.preference_toggles[toggle_type]
		if(toggle.preftoggle_toggle == PREFTOGGLE_SPECIAL || !toggle.is_available(preferences.parent))
			continue
		new_game_preferences[get_toggle_key(toggle_type)] = toggle.is_enabled(preferences)

	return list(PREFERENCE_CATEGORY_GAME_PREFERENCES = new_game_preferences)

/datum/preference_middleware/legacy_toggles/pre_set_preference(mob/user, preference, value)
	var/datum/preference_toggle/toggle = get_toggle_by_key(preference)
	if(isnull(toggle))
		return FALSE

	if(toggle.preftoggle_toggle != PREFTOGGLE_SPECIAL && toggle.is_available(preferences.parent) && toggle.is_enabled(preferences) != !!value)
		toggle.set_toggles(preferences.parent)

	return TRUE

/datum/preference_middleware/legacy_toggles/proc/get_toggle_key(toggle_type)
	return copytext("[toggle_type]", length("[/datum/preference_toggle]") + 2)

/datum/preference_middleware/legacy_toggles/proc/get_toggle_by_key(key)
	var/static/list/toggles_by_key
	if(isnull(toggles_by_key))
		toggles_by_key = list()
		for(var/toggle_type in GLOB.preference_toggles)
			toggles_by_key[get_toggle_key(toggle_type)] = GLOB.preference_toggles[toggle_type]
	return toggles_by_key[key]
