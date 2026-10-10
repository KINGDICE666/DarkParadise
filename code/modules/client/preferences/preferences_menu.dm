#define PREVIEW_REDISPLAY_DELAY (2 TICKS)

/datum/preferences/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	character_preview_view = create_character_preview_view(user)
	ui = new(user, src, "PreferencesMenu")
	ui.set_autoupdate(FALSE)
	ui.open()
	character_preview_view.display_to(user, ui.window)

/datum/preferences/ui_state(mob/user)
	return GLOB.always_state

/datum/preferences/ui_status(mob/user, datum/ui_state/state)
	return user.client == parent ? UI_INTERACTIVE : UI_CLOSE

/datum/preferences/ui_data(mob/user)
	var/list/data = list()

	if(tainted_character_profiles)
		data["character_profiles"] = create_character_profiles()
		tainted_character_profiles = FALSE

	data["character_preferences"] = compile_character_preferences(user)
	data["active_slot"] = default_slot
	data["saved"] = saved

	for(var/datum/preference_middleware/preference_middleware as anything in middleware)
		data += preference_middleware.get_ui_data(user)

	return data

/datum/preferences/ui_static_data(mob/user)
	var/list/data = list()

	data["character_profiles"] = create_character_profiles()
	data["character_preview_view"] = character_preview_view.assigned_map
	data["window"] = current_window
	data["content_unlocked"] = unlock_content
	data["max_save_slots"] = max_save_slots

	for(var/datum/preference_middleware/preference_middleware as anything in middleware)
		data += preference_middleware.get_ui_static_data(user)

	return data

/datum/preferences/ui_assets(mob/user)
	var/list/assets = list(
		get_asset_datum(/datum/asset/spritesheet_batched/sprite_accessories),
		get_asset_datum(/datum/asset/spritesheet_batched/species),
		get_asset_datum(/datum/asset/json/preferences),
	)

	for(var/datum/preference_middleware/preference_middleware as anything in middleware)
		assets += preference_middleware.get_ui_assets()

	return assets

/datum/preferences/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("jobs_act")
			. = job_menu.ui_act(params["action"], params["params"] || list(), ui, state)
			character_preview_view?.update_body()
			return
		if("loadout_act")
			if(!loadout)
				loadout = new
			. = loadout.ui_act(params["action"], params["params"] || list(), ui, state)
			character_preview_view?.update_body()
			return
		if("change_slot")
			save_character(parent)
			switch_to_slot(params["slot"])
			return TRUE
		if("remove_current_slot")
			remove_current_slot()
			return TRUE
		if("show_preview")
			character_preview_view.hide_from(usr)
			addtimer(CALLBACK(character_preview_view, TYPE_PROC_REF(/atom/movable/screen/map_view, display_to), usr), PREVIEW_REDISPLAY_DELAY)
			return FALSE
		if("rotate")
			character_preview_view.dir = turn(character_preview_view.dir, -90)
			return TRUE
		if("toggle_job_clothes")
			character_preview_view.show_job_clothes = !character_preview_view.show_job_clothes
			character_preview_view.update_body()
			return TRUE
		if("save")
			save_preferences(parent)
			save_character(parent)
			return TRUE
		if("reload")
			load_preferences(parent)
			load_character(parent)
			character_preview_view.update_body()
			update_static_data(usr, ui)
			return TRUE
		if("set_preference")
			var/requested_preference_key = params["preference"]
			var/value = params["value"]

			for(var/datum/preference_middleware/preference_middleware as anything in middleware)
				if(preference_middleware.pre_set_preference(usr, requested_preference_key, value))
					return TRUE

			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if(isnull(requested_preference))
				return FALSE

			if(!update_preference(requested_preference, value))
				return FALSE

			if(istype(requested_preference, /datum/preference/name))
				tainted_character_profiles = TRUE

			for(var/datum/preference_middleware/preference_middleware as anything in middleware)
				preference_middleware.post_set_preference(usr, requested_preference_key, value)
			return TRUE
		if("set_color_preference")
			var/requested_preference_key = params["preference"]
			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if(!istype(requested_preference, /datum/preference/color))
				return FALSE

			var/default_value = read_preference(requested_preference.type)
			var/new_color = tgui_input_color(usr, "Выберите новый цвет", "Цвет", default_value || COLOR_WHITE)
			if(!new_color)
				return FALSE

			return update_preference(requested_preference, new_color)

	for(var/datum/preference_middleware/preference_middleware as anything in middleware)
		var/delegation = preference_middleware.action_delegations[action]
		if(!isnull(delegation))
			return call(preference_middleware, delegation)(params, usr)

	return FALSE

/datum/preferences/ui_close(mob/user)
	save_character(parent)
	save_preferences(parent)
	QDEL_NULL(character_preview_view)

/datum/preferences/proc/open_window(mob/user, window)
	if(SSatoms.initialized != INITIALIZATION_INNEW_REGULAR)
		to_chat(user, span_warning("Сервер ещё загружается, подождите немного."))
		return
	current_window = window
	update_static_data(user)
	ui_interact(user)

/datum/preferences/proc/create_character_preview_view(mob/user)
	character_preview_view = new(null, null, src)
	character_preview_view.generate_view("character_preview_[UID()]_map")
	character_preview_view.update_body()
	return character_preview_view

/datum/preferences/proc/compile_character_preferences(mob/user)
	var/list/preferences = list()
	var/list/valid_choices = list()
	var/list/valid_ranges = list()

	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(!preference.is_accessible(src))
			continue

		var/value = read_preference(preference.type)
		LAZYINITLIST(preferences[preference.category])
		preferences[preference.category][preference.savefile_key] = preference.compile_ui_data(user, value)

		if(istype(preference, /datum/preference/choiced))
			var/datum/preference/choiced/choiced_preference = preference
			valid_choices[preference.savefile_key] = choiced_preference.get_valid_choices(src)
		else if(istype(preference, /datum/preference/numeric))
			var/datum/preference/numeric/numeric_preference = preference
			valid_ranges[preference.savefile_key] = numeric_preference.get_valid_range(src)

	for(var/datum/preference_middleware/preference_middleware as anything in middleware)
		var/list/append_character_preferences = preference_middleware.get_character_preferences(user)
		if(isnull(append_character_preferences))
			continue
		for(var/category in append_character_preferences)
			if(category in preferences)
				preferences[category] += append_character_preferences[category]
			else
				preferences[category] = append_character_preferences[category]

	preferences["valid_choices"] = valid_choices
	preferences["valid_ranges"] = valid_ranges
	return preferences

/datum/preferences/proc/apply_all_client_preferences()
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier != PREFERENCE_PLAYER)
			continue
		value_cache -= preference.type
		preference.apply_to_client(parent, read_preference(preference.type))

/datum/preferences/proc/clear_character_cache()
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier == PREFERENCE_CHARACTER)
			value_cache -= preference.type

/datum/preferences/proc/sync_save_data(savefile_identifier)
	var/list/save_data = get_save_data_for_savefile_identifier(savefile_identifier)
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier == savefile_identifier)
			save_data[preference.savefile_key] = preference.serialize(read_preference(preference.type))

/datum/preferences/proc/sanitize_character_preferences()
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier != PREFERENCE_CHARACTER || !(preference.type in value_cache))
			continue
		if(preference.is_valid(value_cache[preference.type], src))
			continue
		value_cache[preference.type] = preference.create_informed_default_value(src)
		recently_updated_keys |= preference.type

/datum/preferences/proc/randomise_appearance_prefs(randomize_species = FALSE)
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(!preference.is_randomizable())
			continue
		if(!preference.randomize_by_default && !(randomize_species && istype(preference, /datum/preference/choiced/species)))
			continue
		write_preference(preference, preference.create_random_value(src))
		recently_updated_keys |= preference.type
	sanitize_character_preferences()

/datum/preferences/proc/apply_prefs_to(mob/living/carbon/human/character, icon_updates = TRUE)
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier != PREFERENCE_CHARACTER)
			continue
		preference.apply_to_human(character, read_preference(preference.type), src)

	apply_organ_data(character)
	apply_disabilities(character)

	character.dna.species.handle_dna(character)
	if(character.dna.dirtySE)
		character.dna.UpdateSE()
	character.dna.ready_dna(character, flatten_SE = FALSE)
	character.sync_organ_dna(assimilate = 1)
	character.UpdateAppearance()

	if(icon_updates)
		character.regenerate_icons()

/datum/preferences/proc/apply_organ_data(mob/living/carbon/human/character)
	for(var/name in organ_data)
		var/status = organ_data[name]
		var/obj/item/organ/external/bodypart = character.bodyparts_by_name[name]
		if(bodypart)
			if(status == PREF_ORGANSTATUS_AMPUTATED_ENG)
				qdel(bodypart.remove(character))
			else if(status == PREF_ORGANSTATUS_CYBORG_ENG)
				if(rlimb_data[name])
					bodypart.robotize(company = rlimb_data[name], convert_all = FALSE)
				else
					bodypart.robotize()
			continue
		var/obj/item/organ/internal/organ = character.internal_organs_slot[name]
		if(organ && status == PREF_ORGANSTATUS_CYBERNETIC_ENG)
			organ.robotize()

/datum/preferences/proc/get_highest_priority_job()
	RETURN_TYPE(/datum/job)
	if(job_support_low & JOB_FLAG_CIVILIAN)
		return SSjobs.GetJob(JOB_TITLE_CIVILIAN)
	if(job_support_low & JOB_FLAG_PRISONER)
		return SSjobs.GetJob(JOB_TITLE_PRISONER)
	for(var/datum/job/job as anything in SSjobs.occupations)
		if(GetJobDepartment(job, 1) & job.flag)
			return job

/datum/preferences/proc/render_new_preview_appearance(mob/living/carbon/human/dummy/mannequin, show_job_clothes = TRUE)
	apply_prefs_to(mannequin, FALSE)
	var/datum/job/preview_job = get_highest_priority_job()
	if(show_job_clothes && preview_job?.outfit)
		mannequin.equipOutfit(preview_job.outfit, visualsOnly = TRUE)
	mannequin.regenerate_icons()
	return mannequin.appearance

/datum/preferences/proc/create_character_profiles()
	var/list/profiles = list()
	for(var/index in 1 to max_save_slots)
		if(index == default_slot)
			profiles += read_preference(/datum/preference/name/real_name)
			continue
		profiles += slot_names["[index]"]
	return profiles

/datum/preferences/proc/switch_to_slot(new_slot)
	new_slot = sanitize_integer(text2num("[new_slot]"), 1, max_save_slots, default_slot)
	if(!load_character(parent, new_slot))
		default_slot = new_slot
		character_data = list()
		clear_character_cache()
		randomise_appearance_prefs()
		save_character(parent)

	for(var/datum/preference_middleware/preference_middleware as anything in middleware)
		preference_middleware.on_new_character(usr)

	character_preview_view?.update_body()
	tainted_character_profiles = TRUE

/datum/preferences/proc/remove_current_slot()
	if(!clear_character_slot(parent))
		return
	character_data = list()
	clear_character_cache()
	randomise_appearance_prefs()
	character_preview_view?.update_body()
	tainted_character_profiles = TRUE

/atom/movable/screen/map_view/char_preview
	name = "character_preview"
	var/mob/living/carbon/human/dummy/body
	var/datum/preferences/preferences
	var/show_job_clothes = TRUE

/atom/movable/screen/map_view/char_preview/Initialize(mapload, datum/hud/hud_owner, datum/preferences/preferences)
	. = ..()
	src.preferences = preferences

/atom/movable/screen/map_view/char_preview/Destroy()
	QDEL_NULL(body)
	preferences?.character_preview_view = null
	preferences = null
	return ..()

/atom/movable/screen/map_view/char_preview/proc/update_body()
	QDEL_NULL(body)
	body = new
	appearance = preferences.render_new_preview_appearance(body, show_job_clothes)

#undef PREVIEW_REDISPLAY_DELAY
