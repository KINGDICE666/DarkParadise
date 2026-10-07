/datum/preference_middleware/legacy_toggles
	action_delegations = list(
		"toggle_legacy" = PROC_REF(toggle_legacy),
	)

/datum/preference_middleware/legacy_toggles/get_constant_data()
	var/list/categories = list()
	for(var/category_name in GLOB.preference_toggle_groups)
		categories += list(list(
			"id" = GLOB.preference_toggle_groups[category_name],
			"name" = category_name,
		))
	return list("categories" = categories)

/datum/preference_middleware/legacy_toggles/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_GAME_PREFERENCES)
		return list()

	var/list/toggles = list()
	for(var/toggle_type in GLOB.preference_toggles)
		var/datum/preference_toggle/toggle = GLOB.preference_toggles[toggle_type]
		if(!toggle.is_available(preferences.parent))
			continue
		toggles += list(list(
			"key" = "[toggle_type]",
			"name" = toggle.name,
			"description" = toggle.description,
			"category" = toggle.preftoggle_category,
			"special" = toggle.preftoggle_toggle == PREFTOGGLE_SPECIAL,
			"enabled" = toggle.is_enabled(preferences),
		))
	return list("legacy_toggles" = toggles)

/datum/preference_middleware/legacy_toggles/proc/toggle_legacy(list/params, mob/user)
	var/datum/preference_toggle/toggle = GLOB.preference_toggles[text2path(params["key"])]
	if(!toggle?.is_available(preferences.parent))
		return FALSE
	toggle.set_toggles(preferences.parent)
	return TRUE
