GLOBAL_LIST_EMPTY(preferences_datums)
GLOBAL_PROTECT(preferences_datums) // These feel like something that shouldnt be fucked with

GLOBAL_LIST_INIT(special_role_times, list(//minimum age (in days) for accounts to play these roles
	ROLE_PAI = 0,
	ROLE_THUNDERDOME = 0,
	ROLE_POSIBRAIN = 0,
	ROLE_GUARDIAN = 0,
	ROLE_TRAITOR = 7,
	ROLE_MALF_AI = 7,
	ROLE_ESCAPING_PRISONER = 7,
	ROLE_THIEF = 7,
	ROLE_CHANGELING = 14,
	ROLE_SHADOWLING = 14,
	ROLE_WIZARD = 14,
	ROLE_REV = 14,
	ROLE_VAMPIRE = 14,
	ROLE_BLOB = 14,
	ROLE_REVENANT = 14,
	ROLE_OPERATIVE = 21,
	ROLE_CULTIST = 21,
	ROLE_CLOCKER = 21,
	ROLE_RAIDER = 21,
	ROLE_ALIEN = 21,
	ROLE_DEMON = 21,
	ROLE_SENTIENT = 21,
	ROLE_ELITE = 21,
//	ROLE_GANG = 21,
	ROLE_BORER = 21,
	ROLE_NINJA = 21,
	ROLE_GSPIDER = 21,
	ROLE_ABDUCTOR = 30,
	ROLE_DEVIL = 14,
	ROLE_BINGLE = 14,
))

GLOBAL_LIST_INIT(zoom_modes, list(SCALING_METHOD_DISTORT = "Метод ближайшего соседа", SCALING_METHOD_BLUR = "Билейная интерполяция", SCALING_METHOD_NORMAL = "Поточечная выборка"))

/proc/player_old_enough_antag(client/C, role, req_job_rank)
	if(available_in_days_antag(C, role))
		return FALSE	//available_in_days>0 = still some days required = player not old enough
	if(role_available_in_playtime(C, role))
		return FALSE	//available_in_playtime>0 = still some more playtime required = they are not eligible
	if(!req_job_rank)
		return TRUE
	var/datum/job/job = SSjobs.GetJob(req_job_rank)
	if(!job)
		stack_trace("Invalid job title: [req_job_rank]")
		return FALSE
	if(job.available_in_playtime(C))
		return TRUE

/proc/available_in_days_antag(client/C, role)
	if(!C)
		return 0
	if(!role)
		return 0
	if(!CONFIG_GET(flag/use_age_restriction_for_antags))
		return 0
	if(!isnum(C.player_age))
		return 0 //This is only a number if the db connection is established, otherwise it is text: "Requires database", meaning these restrictions cannot be enforced
	var/minimal_player_age_antag = GLOB.special_role_times[num2text(role)]
	if(!isnum(minimal_player_age_antag))
		return 0

	return max(0, minimal_player_age_antag - C.player_age)

/proc/check_client_age(client/C, days) // If days isn't provided, returns the age of the client. If it is provided, it returns the days until the player_age is equal to or greater than the days variable
	if(!days)
		return C.player_age
	else
		return max(0, days - C.player_age)

/// Checks whether a role should be disabled due to a mutually exclusive role selection
/// Civilian/Prisoner/Investor — only one can be selected, the others are disabled
/proc/is_job_title_muted(job_support_low, job_title)
	var/any_mutual_role_selected = job_support_low & (JOB_FLAG_CIVILIAN | JOB_FLAG_PRISONER | JOB_FLAG_INVESTOR)
	if(!any_mutual_role_selected)
		return FALSE

	// If a special role is selected, disable everything except the selected one
	if(job_support_low & JOB_FLAG_CIVILIAN)
		return job_title != JOB_TITLE_CIVILIAN
	if(job_support_low & JOB_FLAG_PRISONER)
		return job_title != JOB_TITLE_PRISONER
	if(job_support_low & JOB_FLAG_INVESTOR)
		return job_title != JOB_TITLE_INVESTOR
	return FALSE


#define MAX_SAVE_SLOTS 30 // Save slots for regular players
#define MAX_SAVE_SLOTS_MEMBER 30 // Save slots for BYOND members


/datum/preferences
	var/client/parent
	var/default_slot = 1				//Holder so it doesn't default to slot 1, rather the last one used
	var/max_save_slots = MAX_SAVE_SLOTS
	var/max_gear_slots = 0

	//non-preference stuff
	var/warns = 0
	var/last_ip
	var/last_id

	//game-preferences
	var/lastchangelog = "1"				//Saved changlog timestamp (unix epoch) to detect if there was a change. Dont set this to 0 unless you want the last changelog date to be 4x longer than the expected lifespan of the universe.
	var/exp
	var/list/be_special = list()				//Special role selection
	var/toggles = TOGGLES_DEFAULT
	var/toggles2 = TOGGLES_2_DEFAULT // Created because 1 column has a bitflag limit of 24 (BYOND limitation not MySQL)
	var/toggles3 = TOGGLES_3_DEFAULT
	var/sound = SOUND_DEFAULT
	var/fuid							// forum userid

	var/spawnpoint = "Arrivals Shuttle" //where this character will spawn (0-2).

	/// Custom emote text ("name" = "emote text")
	var/list/custom_emotes = list()

		//Jobs, uses bitflags
	var/job_support_high = 0
	var/job_support_med = 0
	var/job_support_low = 0

	var/job_medsci_high = 0
	var/job_medsci_med = 0
	var/job_medsci_low = 0

	var/job_engsec_high = 0
	var/job_engsec_med = 0
	var/job_engsec_low = 0

	var/job_karma_high = 0
	var/job_karma_med = 0
	var/job_karma_low = 0

	// maps each organ to either null(intact), "cyborg" or "amputated"
	// will probably not be able to do this for head and torso ;)
	var/list/organ_data = list()
	var/list/rlimb_data = list()

	var/list/player_alt_titles = new()		// the default name of a job like "Medical Doctor"
	var/disabilities = 0

	var/current_window = PREFERENCE_TAB_CHARACTER_PREFERENCES

	var/saved = FALSE // Indicates whether the character comes from the database or not

	/// Volume mixer, indexed by channel as TEXT (numerical indexes will not work). Volume goes from 0 to 100.
	var/list/volume_mixer = list(
		"1016" = 100, // CHANNEL_GENERAL
		"1024" = 100, // CHANNEL_LOBBYMUSIC
		"1023" = 100, // CHANNEL_ADMIN
		"1022" = 100, // CHANNEL_VOX
		"1021" = 100, // CHANNEL_JUKEBOX
		"1020" = 100, // CHANNEL_HEARTBEAT
		"1019" = 100, // CHANNEL_BUZZ
		"1018" = 100, // CHANNEL_AMBIENCE
		"1014" = 50, // CHANNEL_TTS_LOCAL
		"1013" = 20, // CHANNEL_TTS_RADIO
		"1012" = 50, // CHANNEL_RADIO_NOISE
		"1011" = 100, // CHANNEL_BOSS_MUSIC
		"1010" = 100, // CHANNEL_INTERACTION_SOUNDS
		"1009" = 40, // CHANNEL_ANNOUNCER
	)
	/// The volume mixer save timer handle. Used to debounce the DB call to save, to avoid spamming.
	var/volume_mixer_saving = null

	// BYOND membership
	var/unlock_content = 0

	//Gear stuff
	var/list/loadout_gear = list()
	var/list/tgui_loadout_gear = list()
	var/list/choosen_gears = list()

	var/discord_id = null
	var/discord_name = null

	/// Active keybinds (currently useable by the mob/client)
	var/list/datum/keybindings = list()
	/// Keybinding overrides ("name" => ["key"...])
	var/list/keybindings_overrides = null

	/// Minigames notification about their end, start and etc.
	var/minigames_notifications = TRUE

	///TRUE when a player declines to be included for the selection process of game mode antagonists.
	var/skip_antag = FALSE

	var/datum/ui_module/loadout/loadout
	var/datum/ui_module/job_preferences/job_menu

	var/action_buttons_screen_locs = list()

	var/list/character_data = list()
	var/list/player_data = list()
	var/list/value_cache = list()
	var/list/recently_updated_keys = list()
	var/list/datum/preference_middleware/middleware = list()
	var/atom/movable/screen/map_view/char_preview/character_preview_view
	var/tainted_character_profiles = FALSE
	var/list/slot_names = list()

/datum/preferences/New(client/C)
	parent = C
	max_gear_slots = CONFIG_GET(number/max_loadout_points)
	job_menu = new()
	for(var/middleware_type in subtypesof(/datum/preference_middleware))
		middleware += new middleware_type(src)

	var/loaded_preferences_successfully = FALSE
	if(istype(C))
		if(!is_guest_key(C.key))
			unlock_content = C.IsByondMember()
			if(unlock_content)
				max_save_slots = MAX_SAVE_SLOTS_MEMBER

		loaded_preferences_successfully = load_preferences(C) // Do not call this with no client/C, it generates a runtime / SQL error
		if(loaded_preferences_successfully && load_character(C))
			return
	//we couldn't load character data so just randomize the character appearance + name
	randomise_appearance_prefs()
	if(!SSdbcore.IsConnected())
		init_keybindings() //we want default keybinds, even if DB is not connected
		return
	if(istype(C))
		if(!loaded_preferences_successfully)
			save_preferences(C) // Do not call this with no client/C, it generates a runtime / SQL error
		save_character(C)		// Do not call this with no client/C, it generates a runtime / SQL error

/datum/preferences/Destroy(force)
	QDEL_NULL(character_preview_view)
	QDEL_LIST(middleware)
	QDEL_NULL(job_menu)
	QDEL_NULL(loadout)
	value_cache = null
	parent = null
	return ..()

#undef MAX_SAVE_SLOTS
#undef MAX_SAVE_SLOTS_MEMBER

/datum/preferences/proc/get_gear_metadata(datum/gear/G)
	. = loadout_gear[G.index_name]
	if(!.)
		. = list()
		loadout_gear[G.index_name] = .

/datum/preferences/proc/get_tweak_metadata(datum/gear/G, datum/gear_tweak/tweak)
	var/list/metadata = get_gear_metadata(G)
	. = metadata["[tweak]"]
	if(!.)
		. = tweak.get_default()
		metadata["[tweak]"] = .

/datum/preferences/proc/set_tweak_metadata(datum/gear/G, datum/gear_tweak/tweak, new_metadata)
	var/list/metadata = get_gear_metadata(G)
	metadata["[tweak]"] = new_metadata
	tweak.update_gear_intro(new_metadata)

/datum/preferences/proc/SetChoices(mob/user)
	close_window(user, "preferences")
	job_menu.ui_interact(user)

/datum/preferences/proc/init_keybindings(overrides, raw)
	if(raw)
		try
			overrides = json_decode(raw)
		catch
			overrides = list()
	keybindings = list()
	keybindings_overrides = overrides
	for(var/datum/keybinding/keybinding as anything in GLOB.keybindings)
		var/list/keys = keybinding.classic_keys
		if(overrides?[keybinding.name])
			keys = overrides[keybinding.name]
		for(var/key in keys)
			LAZYADD(keybindings[key], keybinding)

	parent?.update_active_keybindings()
	return keybindings

/datum/preferences/proc/SetJobPreferenceLevel(datum/job/job, level)
	if(!job)
		return 0

	if(level == 1) // to high
		// remove any other job(s) set to high
		job_support_med |= job_support_high
		job_engsec_med |= job_engsec_high
		job_medsci_med |= job_medsci_high
		job_karma_med |= job_karma_high
		job_support_high = 0
		job_engsec_high = 0
		job_medsci_high = 0
		job_karma_high = 0

	if(job.department_flag == JOBCAT_SUPPORT)
		job_support_low &= ~job.flag
		job_support_med &= ~job.flag
		job_support_high &= ~job.flag

		switch(level)
			if(1)
				job_support_high |= job.flag
			if(2)
				job_support_med |= job.flag
			if(3)
				job_support_low |= job.flag

		return 1
	else if(job.department_flag == JOBCAT_ENGSEC)
		job_engsec_low &= ~job.flag
		job_engsec_med &= ~job.flag
		job_engsec_high &= ~job.flag

		switch(level)
			if(1)
				job_engsec_high |= job.flag
			if(2)
				job_engsec_med |= job.flag
			if(3)
				job_engsec_low |= job.flag

		return 1
	else if(job.department_flag == JOBCAT_MEDSCI)
		job_medsci_low &= ~job.flag
		job_medsci_med &= ~job.flag
		job_medsci_high &= ~job.flag

		switch(level)
			if(1)
				job_medsci_high |= job.flag
			if(2)
				job_medsci_med |= job.flag
			if(3)
				job_medsci_low |= job.flag

		return 1
	else if(job.department_flag == JOBCAT_KARMA)
		job_karma_low &= ~job.flag
		job_karma_med &= ~job.flag
		job_karma_high &= ~job.flag

		switch(level)
			if(1)
				job_karma_high |= job.flag
			if(2)
				job_karma_med |= job.flag
			if(3)
				job_karma_low |= job.flag

		return 1

	return 0

/datum/preferences/proc/UpdateJobPreference(mob/user, role, desiredLvl)
	var/datum/job/job = SSjobs.GetJob(role)

	if(!job)
		SStgui.close_uis(job_menu)
		return

	if(!isnum(desiredLvl))
		to_chat(user, span_warning("UpdateJobPreference – выбранный уровень не был числом. Сообщите о баге!"))
		return

	if(role == JOB_TITLE_CIVILIAN || role == JOB_TITLE_PRISONER || role == JOB_TITLE_INVESTOR)
		if(job_support_low & job.flag)
			job_support_low &= ~job.flag
		else
			job_support_low |= job.flag
			job_support_low &= ~(JOB_FLAG_CIVILIAN | JOB_FLAG_PRISONER | JOB_FLAG_INVESTOR)
			job_support_low |= job.flag
		return 1

	SetJobPreferenceLevel(job, desiredLvl)

	return 1

/datum/preferences/proc/GetPlayerAltTitle(datum/job/job)
	return player_alt_titles.Find(job.title) > 0 \
		? player_alt_titles[job.title] \
		: get_job_title_ru(job.title)

/datum/preferences/proc/SetPlayerAltTitle(datum/job/job, new_title)
	// remove existing entry
	if(player_alt_titles.Find(job.title))
		player_alt_titles -= job.title
	// add one if it's not default
	if(job.title != new_title)
		player_alt_titles[job.title] = new_title

/datum/preferences/proc/SetJob(mob/user, role)
	var/datum/job/job = SSjobs.GetJob(role)
	if(!job)
		SStgui.close_uis(job_menu)
		return

	if(role == JOB_TITLE_CIVILIAN)
		if(job_support_low & job.flag)
			job_support_low &= ~job.flag
		else
			job_support_low |= job.flag
		SetChoices(user)
		return 1

	if(GetJobDepartment(job, 1) & job.flag)
		SetJobDepartment(job, 1)
	else if(GetJobDepartment(job, 2) & job.flag)
		SetJobDepartment(job, 2)
	else if(GetJobDepartment(job, 3) & job.flag)
		SetJobDepartment(job, 3)
	else//job = Never
		SetJobDepartment(job, 4)

	SetChoices(user)
	return 1

/**
 * Rebuilds the `loadout_gear` list of the [active_character], and returns the total end cost.
 *
 * Caches and cuts the existing [/datum/character_save/var/loadout_gear] list and remakes it, checking the `subtype_selection_cost` and overall cost validity of each item.
 *
 * If the item's [/datum/gear/var/subtype_selection_cost] is `FALSE`, any future items with the same [/datum/gear/var/main_typepath] will have their cost skipped.
 * If adding the item will take the total cost over the maximum, it won't be added to the list.
 *
 * Arguments:
 * * new_item - A new [/datum/gear] item to be added to the `loadout_gear` list.
 */
/datum/preferences/proc/build_loadout(datum/gear/new_item)
	var/total_cost = 0
	var/list/type_blacklist = list()
	var/list/loadout_cache = loadout_gear.Copy()
	loadout_gear.Cut()
	tgui_loadout_gear.Cut()
	choosen_gears.Cut()
	if(new_item)
		loadout_cache += "[new_item.index_name]"

	for(var/item in loadout_cache)
		var/datum/gear/gear = GLOB.gear_datums[item]
		if(!gear)
			continue
		var/added_cost = gear.cost
		if(!gear.subtype_cost_overlap) // If listings of the same subtype shouldn't have their cost added.
			if(gear.path in type_blacklist)
				added_cost = 0
			else
				type_blacklist += gear.path
		if((total_cost + added_cost) > max_gear_slots)
			continue // If the final cost is too high, don't add the item.
		var/item_cache = loadout_cache[item]
		loadout_gear[item] = item_cache ? item_cache : list()
		var/tgui_data = list()
		for(var/datum/gear_tweak/tweak in gear.gear_tweaks)
			var/text_path = "[tweak.type]"
			if(!(text_path in item_cache))
				continue
			var/params = item_cache[text_path]
			var/list/data =tweak?.get_tgui_data(params)
			if(!data)
				continue
			tgui_data[text_path] = data["display_param"]
			tgui_data["name"] = data["name"]
			tgui_data["icon"] = data["icon"]
			tgui_data["icon_file"] = data["icon_file"]
			tgui_data["icon_state"] = data["icon_state"]
		tgui_loadout_gear[gear] = tgui_data
		choosen_gears[item] = gear
		total_cost += added_cost
	return total_cost

/datum/preferences/proc/ResetJobs()
	job_support_high = 0
	job_support_med = 0
	job_support_low = 0

	job_medsci_high = 0
	job_medsci_med = 0
	job_medsci_low = 0

	job_engsec_high = 0
	job_engsec_med = 0
	job_engsec_low = 0

	job_karma_high = 0
	job_karma_med = 0
	job_karma_low = 0

/datum/preferences/proc/GetJobDepartment(datum/job/job, level)
	if(!job || !level)	return 0
	switch(job.department_flag)
		if(JOBCAT_SUPPORT)
			switch(level)
				if(1)
					return job_support_high
				if(2)
					return job_support_med
				if(3)
					return job_support_low
		if(JOBCAT_MEDSCI)
			switch(level)
				if(1)
					return job_medsci_high
				if(2)
					return job_medsci_med
				if(3)
					return job_medsci_low
		if(JOBCAT_ENGSEC)
			switch(level)
				if(1)
					return job_engsec_high
				if(2)
					return job_engsec_med
				if(3)
					return job_engsec_low
		if(JOBCAT_KARMA)
			switch(level)
				if(1)
					return job_karma_high
				if(2)
					return job_karma_med
				if(3)
					return job_karma_low
	return 0

/datum/preferences/proc/SetJobDepartment(datum/job/job, level)
	if(!job || !level)	return 0
	switch(level)
		if(1)//Only one of these should ever be active at once so clear them all here
			job_support_high = 0
			job_medsci_high = 0
			job_engsec_high = 0
			job_karma_high = 0
			return 1
		if(2)//Set current highs to med, then reset them
			job_support_med |= job_support_high
			job_medsci_med |= job_medsci_high
			job_engsec_med |= job_engsec_high
			job_karma_med |= job_karma_high
			job_support_high = 0
			job_medsci_high = 0
			job_engsec_high = 0
			job_karma_high = 0

	switch(job.department_flag)
		if(JOBCAT_SUPPORT)
			switch(level)
				if(2)
					job_support_high = job.flag
					job_support_med &= ~job.flag
				if(3)
					job_support_med |= job.flag
					job_support_low &= ~job.flag
				else
					job_support_low |= job.flag
		if(JOBCAT_MEDSCI)
			switch(level)
				if(2)
					job_medsci_high = job.flag
					job_medsci_med &= ~job.flag
				if(3)
					job_medsci_med |= job.flag
					job_medsci_low &= ~job.flag
				else
					job_medsci_low |= job.flag
		if(JOBCAT_ENGSEC)
			switch(level)
				if(2)
					job_engsec_high = job.flag
					job_engsec_med &= ~job.flag
				if(3)
					job_engsec_med |= job.flag
					job_engsec_low &= ~job.flag
				else
					job_engsec_low |= job.flag
		if(JOBCAT_KARMA)
			switch(level)
				if(2)
					job_karma_high = job.flag
					job_karma_med &= ~job.flag
				if(3)
					job_karma_med |= job.flag
					job_karma_low &= ~job.flag
				else
					job_karma_low |= job.flag
	return 1

/datum/preferences/proc/check_any_job()
	return(job_support_high || job_support_med || job_support_low || job_medsci_high || job_medsci_med || job_medsci_low || job_engsec_high || job_engsec_med || job_engsec_low || job_karma_high || job_karma_med || job_karma_low)

// Used to display UI_theme in Russian
/datum/preferences/proc/ui_theme_to_russian(ui_theme)
	switch(ui_theme)
		if(UI_THEME_MIDNIGHT)
			return UI_THEME_MIDNIGHT_RUS
		if(UI_THEME_PLASMAFIRE)
			return UI_THEME_PLASMAFIRE_RUS
		if(UI_THEME_RETRO)
			return UI_THEME_RETRO_RUS
		if(UI_THEME_SLIMECORE)
			return UI_THEME_SLIMECORE_RUS
		if(UI_THEME_OPERATIVE)
			return UI_THEME_OPERATIVE_RUS
		if(UI_THEME_WHITE)
			return UI_THEME_WHITE_RUS
		if(UI_THEME_CLOCKWORK)
			return UI_THEME_CLOCKWORK_RUS

/// Get random charecter with can_be_antagonist on. If no such characters, don't change current.
/datum/preferences/proc/get_possible_antagonist()
	var/datum/db_query/query = SSdbcore.NewQuery("SELECT slot FROM [format_table_name("characters")] WHERE ckey=:ckey AND can_be_antagonist=:req_can_be_antagonist ORDER BY slot", list(
		"ckey" = parent.account_ckey,
		"req_can_be_antagonist" = 1,
	))

	if(!query.warn_execute(async = FALSE)) // Dont async this. Youll make roundstart slow.
		qdel(query)
		return

	var/list/saves = list()
	while(query.NextRow())
		saves += text2num(query.item[1])

	qdel(query)
	if(!length(saves))
		return

	load_character(parent, pick(saves))
	return
