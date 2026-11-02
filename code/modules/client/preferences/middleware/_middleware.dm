/datum/preference_middleware
	var/datum/preferences/preferences
	var/key = null
	var/list/action_delegations = list()

/datum/preference_middleware/New(datum/preferences)
	src.preferences = preferences
	if(isnull(key))
		key = copytext("[type]", length("[parent_type]") + 2)

/datum/preference_middleware/Destroy()
	preferences = null
	return ..()

/datum/preference_middleware/proc/get_ui_data(mob/user)
	return list()

/datum/preference_middleware/proc/get_ui_static_data(mob/user)
	return list()

/datum/preference_middleware/proc/get_ui_assets()
	return list()

/datum/preference_middleware/proc/get_constant_data()
	return null

/datum/preference_middleware/proc/get_character_preferences(mob/user)
	return null

/datum/preference_middleware/proc/pre_set_preference(mob/user, preference, value)
	return FALSE

/datum/preference_middleware/proc/on_new_character(mob/user)
	return

/datum/preference_middleware/proc/post_set_preference(mob/user, preference, value)
	return
