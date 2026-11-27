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
	ROLE_ZOMBIE = 14,
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
	var/starting_page
	var/page_request = 0

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
		"1017" = 100, // CHANNEL_WEATHER
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

	var/action_buttons_screen_locs = list()

	var/list/character_data = list()
	var/list/player_data = list()
	var/list/value_cache = list()
	var/list/randomise = list()
	var/list/recently_updated_keys = list()
	var/list/datum/preference_middleware/middleware = list()
	var/atom/movable/screen/map_view/char_preview/character_preview_view
	var/tainted_character_profiles = FALSE
	var/list/slot_names = list()

/datum/preferences/New(client/C)
	parent = C
	max_gear_slots = CONFIG_GET(number/max_loadout_points)
	randomise = get_default_randomization()
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

/datum/preferences/proc/get_job_preference_column(datum/job/job, level)
	var/static/alist/department_columns = alist(
		JOBCAT_SUPPORT = "support",
		JOBCAT_MEDSCI = "medsci",
		JOBCAT_ENGSEC = "engsec",
		JOBCAT_KARMA = "karma",
	)
	var/static/alist/level_columns = alist(
		JP_HIGH = "high",
		JP_MEDIUM = "med",
		JP_LOW = "low",
	)
	var/department = department_columns[job.department_flag]
	if(department)
		return "job_[department]_[level_columns[level]]"

/datum/preferences/proc/set_job_preference_level(datum/job/job, level)
	if(!get_job_preference_column(job, JP_LOW))
		return FALSE

	if(level == JP_HIGH)
		for(var/department in list("support", "medsci", "engsec", "karma"))
			vars["job_[department]_med"] |= vars["job_[department]_high"]
			vars["job_[department]_high"] = 0

	if(level && (job.flag & JOB_FLAGS_EXCLUSIVE) && job.department_flag == JOBCAT_SUPPORT)
		job_support_low &= ~JOB_FLAGS_EXCLUSIVE

	for(var/job_level in list(JP_HIGH, JP_MEDIUM, JP_LOW))
		vars[get_job_preference_column(job, job_level)] &= ~job.flag

	if(level)
		vars[get_job_preference_column(job, level)] |= job.flag

	return TRUE

/datum/preferences/proc/get_job_preference_level(datum/job/job)
	for(var/level in list(JP_HIGH, JP_MEDIUM, JP_LOW))
		var/column = get_job_preference_column(job, level)
		if(column && (vars[column] & job.flag))
			return level

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

/datum/preferences/proc/GetJobDepartment(datum/job/job, level)
	var/column = job && level && get_job_preference_column(job, JP_HIGH + 1 - level)
	return column ? vars[column] : 0

/datum/preferences/proc/check_any_job()
	return(job_support_high || job_support_med || job_support_low || job_medsci_high || job_medsci_med || job_medsci_low || job_engsec_high || job_engsec_med || job_engsec_low || job_karma_high || job_karma_med || job_karma_low)

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
