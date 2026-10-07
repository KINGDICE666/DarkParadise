/datum/preference_middleware/modules
	action_delegations = list(
		"open_tts_explorer" = PROC_REF(open_tts_explorer),
		"open_volume_mixer" = PROC_REF(open_volume_mixer),
		"randomize_character" = PROC_REF(randomize_character),
		"randomize_preference" = PROC_REF(randomize_preference),
	)
	var/datum/ui_module/tts_seeds_explorer/tts_explorer

/datum/preference_middleware/modules/Destroy()
	QDEL_NULL(tts_explorer)
	return ..()

/datum/preference_middleware/modules/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	if(!preferences.loadout)
		preferences.loadout = new
	var/datum/tts_seed/seed = SStts.tts_seeds[preferences.read_preference(/datum/preference/tts_seed)]
	return list(
		"jobs_page" = preferences.job_menu.ui_data(user),
		"loadout_page" = preferences.loadout.ui_data(user),
		"tts_seed" = seed?.name,
		"tts_enabled" = CONFIG_GET(flag/tts_enabled),
		"appearance_banned" = appearance_isbanned(user),
	)

/datum/preference_middleware/modules/get_ui_static_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	if(!preferences.loadout)
		preferences.loadout = new
	return list("loadout_static" = preferences.loadout.ui_static_data(user))

/datum/preference_middleware/modules/get_ui_assets()
	return list(get_asset_datum(/datum/asset/spritesheet_batched/sprite_accessories))

/datum/preference_middleware/modules/proc/open_tts_explorer(list/params, mob/user)
	if(!tts_explorer)
		tts_explorer = new
	tts_explorer.ui_interact(user)
	return FALSE

/datum/preference_middleware/modules/proc/open_volume_mixer(list/params, mob/user)
	user.client?.volume_mixer()
	return FALSE

/datum/preference_middleware/modules/proc/randomize_character(list/params, mob/user)
	if(appearance_isbanned(user))
		return FALSE
	preferences.randomise_appearance_prefs()
	preferences.character_preview_view?.update_body()
	preferences.tainted_character_profiles = TRUE
	return TRUE

/datum/preference_middleware/modules/proc/randomize_preference(list/params, mob/user)
	var/datum/preference/preference = GLOB.preference_entries_by_key[params["preference"]]
	if(!preference?.is_randomizable() || appearance_isbanned(user))
		return FALSE
	if(!preferences.update_preference(preference, preference.create_random_value(preferences)))
		return FALSE
	if(istype(preference, /datum/preference/name))
		preferences.tainted_character_profiles = TRUE
	return TRUE
