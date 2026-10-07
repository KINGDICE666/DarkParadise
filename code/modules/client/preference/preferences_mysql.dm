GLOBAL_LIST_INIT(player_preference_columns, list(
	"ooccolor",
	"UI_style",
	"UI_style_color",
	"UI_style_alpha",
	"clientfps",
	"atklog",
	"parallax",
	"viewrange",
	"ghost_darkness_level",
	"screentip_mode",
	"screentip_color",
	"achivements_sound",
	"zoom",
	"zoom_mode",
))

GLOBAL_LIST_INIT(character_preference_columns, list(
	"OOC_Notes",
	"real_name",
	"name_is_always_random",
	"gender",
	"age",
	"species",
	"language",
	"hair_colour",
	"secondary_hair_colour",
	"facial_hair_colour",
	"secondary_facial_hair_colour",
	"skin_tone",
	"skin_colour",
	"marking_colours",
	"head_accessory_colour",
	"hair_style_name",
	"facial_style_name",
	"marking_styles",
	"head_accessory_style_name",
	"alt_head_name",
	"eye_colour",
	"underwear",
	"underwear_color",
	"undershirt",
	"undershirt_color",
	"backbag",
	"b_type",
	"alternate_option",
	"flavor_text",
	"med_record",
	"sec_record",
	"gen_record",
	"exploit_record",
	"nanotrasen_relation",
	"speciesprefs",
	"socks",
	"body_accessory",
	"autohiss",
	"hair_gradient",
	"hair_gradient_offset",
	"hair_gradient_colour",
	"hair_gradient_alpha",
	"uplink_pref",
	"tts_seed",
	"can_be_antagonist",
	"exoframe_type",
))

GLOBAL_LIST_INIT(character_job_columns, list(
	"job_support_high",
	"job_support_med",
	"job_support_low",
	"job_medsci_high",
	"job_medsci_med",
	"job_medsci_low",
	"job_engsec_high",
	"job_engsec_med",
	"job_engsec_low",
	"job_karma_high",
	"job_karma_med",
	"job_karma_low",
))

GLOBAL_LIST_INIT(marking_locations, list("head", "body", "tail"))

/proc/decode_preferences_json(raw)
	if(!istext(raw) || !length(raw))
		return list()
	var/list/decoded
	try
		decoded = json_decode(raw)
	catch
		return list()
	return islist(decoded) ? decoded : list()

/proc/select_query_row(datum/db_query/query, list/columns)
	var/list/row = list()
	for(var/index in 1 to length(columns))
		row[columns[index]] = query.item[index]
	return row

/proc/unpack_character_columns(list/row)
	var/list/data = decode_preferences_json(row["preferences"])
	for(var/column in GLOB.character_preference_columns)
		if(!isnull(row[column]))
			data[column] = row[column]

	var/list/marking_styles = params2list(data["marking_styles"])
	var/list/marking_colours = params2list(data["marking_colours"])
	for(var/location in GLOB.marking_locations)
		if(marking_styles[location])
			data["[location]_marking_style"] = marking_styles[location]
		if(marking_colours[location])
			data["[location]_marking_colour"] = marking_colours[location]
	data -= list("marking_styles", "marking_colours")

	var/list/gradient_offset = splittext(data["hair_gradient_offset"], ",")
	if(length(gradient_offset) == 2)
		data["hair_gradient_offset_x"] = text2num(gradient_offset[1])
		data["hair_gradient_offset_y"] = text2num(gradient_offset[2])
	data -= "hair_gradient_offset"
	return data

/proc/pack_character_columns(list/character_data)
	var/list/data = character_data.Copy()
	var/list/marking_styles = list()
	var/list/marking_colours = list()
	for(var/location in GLOB.marking_locations)
		marking_styles[location] = data["[location]_marking_style"] || "None"
		marking_colours[location] = data["[location]_marking_colour"] || "#000000"
		data -= list("[location]_marking_style", "[location]_marking_colour")
	data["marking_styles"] = list2params(marking_styles)
	data["marking_colours"] = list2params(marking_colours)

	data["hair_gradient_offset"] = "[data["hair_gradient_offset_x"] || 0],[data["hair_gradient_offset_y"] || 0]"
	data -= list("hair_gradient_offset_x", "hair_gradient_offset_y")

	var/list/columns = list()
	for(var/column in GLOB.character_preference_columns)
		columns[column] = isnull(data[column]) ? "" : data[column]
	columns["preferences"] = json_encode(data - GLOB.character_preference_columns)
	return columns

/datum/preferences/proc/load_preferences(client/C)
	if(C.launcher_state == LAUNCHER_PENDING)
		return FALSE

	var/static/list/base_columns = list(
		"be_role",
		"default_slot",
		"toggles",
		"toggles_2",
		"toggles_3",
		"sound",
		"volume_mixer",
		"lastchangelog",
		"exp",
		"fuid",
		"discord_id",
		"discord_name",
		"keybindings",
		"preferences",
	)
	var/list/columns = base_columns + GLOB.player_preference_columns
	var/datum/db_query/query = SSdbcore.NewQuery("SELECT [jointext(columns, ", ")] FROM [format_table_name("player")] WHERE ckey=:ckey", list(
		"ckey" = C.account_ckey
	))

	if(!query.warn_execute())
		qdel(query)
		return

	var/list/row = list()
	if(query.NextRow())
		row = select_query_row(query, columns)
	qdel(query)

	be_special = params2list(row["be_role"])
	default_slot = text2num(row["default_slot"])
	toggles = text2num(row["toggles"])
	toggles2 = text2num(row["toggles_2"])
	toggles3 = text2num(row["toggles_3"])
	sound = text2num(row["sound"])
	volume_mixer = deserialize_volume_mixer(row["volume_mixer"])
	lastchangelog = row["lastchangelog"]
	exp = row["exp"]
	fuid = text2num(row["fuid"])
	discord_id = row["discord_id"]
	discord_name = row["discord_name"]
	keybindings = init_keybindings(raw = row["keybindings"])

	player_data = decode_preferences_json(row["preferences"])
	for(var/column in GLOB.player_preference_columns)
		if(!isnull(row[column]))
			player_data[column] = row[column]

	default_slot = sanitize_integer(default_slot, 1, max_save_slots, initial(default_slot))
	toggles = sanitize_integer(toggles, 0, TOGGLES_TOTAL, initial(toggles))
	toggles2 = sanitize_integer(toggles2, 0, TOGGLES_2_TOTAL, initial(toggles2))
	toggles3 = sanitize_integer(toggles3, 0, TOGGLES_3_TOTAL, initial(toggles3))
	sound = sanitize_integer(sound, 0, 65535, initial(sound))
	lastchangelog = sanitize_text(lastchangelog, initial(lastchangelog))
	exp = sanitize_text(exp, initial(exp))
	fuid = sanitize_integer(fuid, 0, 10000000, initial(fuid))
	discord_id = sanitize_text(discord_id, initial(discord_id))
	discord_name = sanitize_text(discord_name, initial(discord_name))

	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier != PREFERENCE_PLAYER)
			continue
		value_cache -= preference.type
		read_preference(preference.type)

	apply_all_client_preferences()
	load_character_names(C)
	return TRUE

/datum/preferences/proc/save_preferences(client/C)
	if(C.launcher_state == LAUNCHER_PENDING)
		return

	for(var/role in be_special)
		if(!(role in GLOB.special_roles))
			stack_trace("[C.key] had a malformed role entry: '[role]'. Removing!")
			be_special -= role

	if(volume_mixer_saving)
		deltimer(volume_mixer_saving)
		volume_mixer_saving = null

	sync_save_data(PREFERENCE_PLAYER)
	recently_updated_keys.Cut()

	var/list/values = list(
		"be_role" = list2params(be_special),
		"default_slot" = default_slot,
		"toggles" = num2text(toggles, CEILING(log(10, (TOGGLES_TOTAL)), 1)),
		"toggles_2" = num2text(toggles2, CEILING(log(10, (TOGGLES_2_TOTAL)), 1)),
		"toggles_3" = num2text(toggles3, CEILING(log(10, (TOGGLES_3_TOTAL)), 1)),
		"sound" = sound,
		"volume_mixer" = serialize_volume_mixer(volume_mixer),
		"lastchangelog" = lastchangelog,
		"keybindings" = json_encode(keybindings_overrides),
		"preferences" = json_encode(player_data - GLOB.player_preference_columns),
	)
	for(var/column in GLOB.player_preference_columns)
		values[column] = player_data[column]

	var/list/assignments = list()
	for(var/column in values)
		assignments += "[column]=:[column]"
	values["ckey"] = C.account_ckey

	var/datum/db_query/query = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET [jointext(assignments, ", ")] WHERE ckey=:ckey", values)
	if(!query.warn_execute())
		qdel(query)
		return

	qdel(query)
	return 1

/datum/preferences/proc/load_character(client/C, slot)
	if(C.launcher_state == LAUNCHER_PENDING)
		return FALSE

	saved = FALSE

	if(!slot)
		slot = default_slot
	slot = sanitize_integer(slot, 1, max_save_slots, initial(default_slot))
	if(slot != default_slot)
		default_slot = slot
		var/datum/db_query/firstquery = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET default_slot=:slot WHERE ckey=:ckey", list(
			"slot" = slot,
			"ckey" = C.account_ckey
		))
		if(!firstquery.warn_execute(async = FALSE))
			qdel(firstquery)
			return
		qdel(firstquery)

	if(!C)
		return TRUE

	var/static/list/var_columns = list(
		"player_alt_titles",
		"disabilities",
		"organ_data",
		"rlimb_data",
		"gear",
		"custom_emotes",
		"preferences",
	)
	var/list/columns = GLOB.character_preference_columns + GLOB.character_job_columns + var_columns
	var/datum/db_query/query = SSdbcore.NewQuery("SELECT [jointext(columns, ", ")] FROM [format_table_name("characters")] WHERE ckey=:ckey AND slot=:slot", list(
		"ckey" = C.account_ckey,
		"slot" = slot
	))
	if(!query.warn_execute(async = FALSE))
		qdel(query)
		return

	var/list/row = list()
	if(query.NextRow())
		row = select_query_row(query, columns)
		saved = TRUE
	qdel(query)

	character_data = unpack_character_columns(row)

	for(var/column in GLOB.character_job_columns)
		vars[column] = sanitize_integer(text2num(row[column]), 0, 65535, 0)
	disabilities = sanitize_integer(text2num(row["disabilities"]), 0, DISABILITY_MAX, initial(disabilities))
	player_alt_titles = params2list(row["player_alt_titles"])
	organ_data = params2list(row["organ_data"])
	rlimb_data = params2list(row["rlimb_data"])
	custom_emotes = init_custom_emotes(sanitize_json(row["custom_emotes"]) || list())

	loadout_gear.Cut()
	var/list/unformated_loadout_gear = params2list(row["gear"])
	for(var/gear in unformated_loadout_gear)
		loadout_gear[gear] = params2list(unformated_loadout_gear[gear])

	clear_character_cache()
	for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
		if(preference.savefile_identifier == PREFERENCE_CHARACTER)
			read_preference(preference.type)

	form_choosen_gears()
	return 1

/datum/preferences/proc/form_choosen_gears()
	choosen_gears.Cut()
	var/species_name = read_preference(/datum/preference/choiced/species)
	for(var/gear in loadout_gear)
		var/datum/gear/geartype = GLOB.gear_datums[gear]
		if(!istype(geartype))
			loadout_gear -= gear // Delete wrong/outdated data
			continue
		if(!geartype.can_select(cl = parent, species_name = species_name, silent = TRUE)) // all other checks, no jobs in prefs, be quiet
			loadout_gear -= gear
			continue
		var/datum/gear/new_gear = new geartype.type
		for(var/tweak in loadout_gear[gear])
			for(var/datum/gear_tweak/gear_tweak in new_gear.gear_tweaks)
				if(istype(gear_tweak, text2path(tweak)))
					set_tweak_metadata(new_gear, gear_tweak, loadout_gear[gear][tweak])
		choosen_gears[gear] = new_gear

/datum/preferences/proc/save_character(client/C)
	if(C.launcher_state == LAUNCHER_PENDING)
		return

	for(var/title in player_alt_titles)
		var/datum/job/job = SSjobs.GetJob(title)
		if(job && !(player_alt_titles[title] in job.alt_titles))
			stack_trace("[C.key] had a malformed job title entry: '[title]:[player_alt_titles[title]]'. Removing!")
			player_alt_titles -= title

	sync_save_data(PREFERENCE_CHARACTER)

	var/list/values = pack_character_columns(character_data)
	for(var/column in GLOB.character_job_columns)
		values[column] = vars[column]
	values["disabilities"] = disabilities
	values["player_alt_titles"] = length(player_alt_titles) ? list2params(player_alt_titles) : ""
	values["organ_data"] = length(organ_data) ? list2params(organ_data) : ""
	values["rlimb_data"] = length(rlimb_data) ? list2params(rlimb_data) : ""
	values["custom_emotes"] = json_encode(custom_emotes)

	var/list/savelist = list()
	for(var/gear in loadout_gear)
		savelist[gear] = list2params(loadout_gear[gear])
	values["gear"] = length(savelist) ? list2params(savelist) : ""

	var/datum/db_query/firstquery = SSdbcore.NewQuery("SELECT slot FROM [format_table_name("characters")] WHERE ckey=:ckey AND slot=:slot", list(
		"ckey" = C.account_ckey,
		"slot" = default_slot
	))
	if(!firstquery.warn_execute())
		qdel(firstquery)
		return
	var/exists = firstquery.NextRow()
	qdel(firstquery)

	var/datum/db_query/query
	if(exists)
		var/list/assignments = list()
		for(var/column in values)
			assignments += "[column]=:[column]"
		values["ckey"] = C.account_ckey
		values["slot"] = default_slot
		query = SSdbcore.NewQuery("UPDATE [format_table_name("characters")] SET [jointext(assignments, ", ")] WHERE ckey=:ckey AND slot=:slot", values)
	else
		values["ckey"] = C.account_ckey
		values["slot"] = default_slot
		var/list/parameters = list()
		for(var/column in values)
			parameters += ":[column]"
		query = SSdbcore.NewQuery("INSERT INTO [format_table_name("characters")] ([jointext(assoc_to_keys(values), ", ")]) VALUES ([jointext(parameters, ", ")])", values)

	if(!query.warn_execute())
		qdel(query)
		return

	qdel(query)
	recently_updated_keys.Cut()
	saved = TRUE
	slot_names["[default_slot]"] = character_data["real_name"]
	tainted_character_profiles = TRUE
	return 1

/datum/preferences/proc/load_random_character_slot(client/C)
	var/datum/db_query/query = SSdbcore.NewQuery("SELECT slot FROM [format_table_name("characters")] WHERE ckey=:ckey ORDER BY slot", list(
		"ckey" = C.account_ckey
	))
	var/list/saves = list()

	if(!query.warn_execute(async = FALSE)) // Dont async this. Youll make roundstart slow.
		qdel(query)
		return

	while(query.NextRow())
		saves += text2num(query.item[1])
	qdel(query)

	if(!length(saves))
		load_character(C)
		return 0
	load_character(C,pick(saves))
	return 1

/datum/preferences/proc/clear_character_slot(client/C)
	. = FALSE
	// Is there a character in that slot?
	var/datum/db_query/query = SSdbcore.NewQuery("SELECT slot FROM [format_table_name("characters")] WHERE ckey=:ckey AND slot=:slot", list(
		"ckey" = C.account_ckey,
		"slot" = default_slot
	))

	if(!query.warn_execute())
		qdel(query)
		return

	if(!query.NextRow())
		qdel(query)
		return

	qdel(query)

	var/datum/db_query/delete_query = SSdbcore.NewQuery("DELETE FROM [format_table_name("characters")] WHERE ckey=:ckey AND slot=:slot", list(
		"ckey" = C.account_ckey,
		"slot" = default_slot
	))

	if(!delete_query.warn_execute())
		qdel(delete_query)
		return

	qdel(delete_query)

	saved = FALSE
	slot_names -= "[default_slot]"
	tainted_character_profiles = TRUE
	return TRUE

/datum/preferences/proc/load_character_names(client/C)
	slot_names = list()
	var/datum/db_query/query = SSdbcore.NewQuery("SELECT slot, real_name FROM [format_table_name("characters")] WHERE ckey=:ckey ORDER BY slot", list(
		"ckey" = C.account_ckey
	))
	if(!query.warn_execute())
		qdel(query)
		return
	while(query.NextRow())
		slot_names["[query.item[1]]"] = query.item[2]
	qdel(query)

/**
 * Saves [/datum/preferences/proc/volume_mixer] for the current client.
 */
/datum/preferences/proc/save_volume_mixer()
	volume_mixer_saving = null
	//save_volume_mixer is called with a timer, the client may no longer be there.
	if(isnull(parent))
		return

	var/datum/db_query/update_query = SSdbcore.NewQuery(
		"UPDATE [format_table_name("player")] SET volume_mixer=:volume_mixer WHERE ckey=:ckey",
		list(
			"volume_mixer" = serialize_volume_mixer(volume_mixer),
			"ckey" = parent.account_ckey
		)
	)

	if(!update_query.warn_execute())
		qdel(update_query)
		return FALSE

	qdel(update_query)
	return TRUE

/datum/preferences/proc/init_custom_emotes(overrides)

	custom_emotes = overrides

	for(var/datum/keybinding/custom/custom_emote in GLOB.keybindings)
		var/emote_text = overrides && overrides[custom_emote.name]
		if(!emote_text)
			continue //we set anything without an override back to default, in case it isn't that
		custom_emotes[custom_emote.name] = emote_text

	return custom_emotes
