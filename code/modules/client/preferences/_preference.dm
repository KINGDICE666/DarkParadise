GLOBAL_LIST_INIT(preference_entries, init_preference_entries())
GLOBAL_LIST_INIT(preference_entries_by_key, init_preference_entries_by_key())

/proc/init_preference_entries()
	var/list/output = list()
	for(var/datum/preference/preference_type as anything in valid_subtypesof(/datum/preference))
		output[preference_type] = new preference_type
	return output

/proc/init_preference_entries_by_key()
	var/list/output = list()
	for(var/datum/preference/preference_type as anything in valid_subtypesof(/datum/preference))
		output[preference_type::savefile_key] = GLOB.preference_entries[preference_type]
	return output

/proc/get_preferences_in_priority_order()
	var/list/preferences[MAX_PREFERENCE_PRIORITY]

	for(var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		LAZYADD(preferences[preference.priority], preference)

	var/list/flattened = list()
	for(var/index in 1 to MAX_PREFERENCE_PRIORITY)
		if(preferences[index])
			flattened += preferences[index]
	return flattened

/datum/preference
	abstract_type = /datum/preference
	var/savefile_key
	var/category = "misc"
	var/savefile_identifier
	var/priority = PREFERENCE_PRIORITY_DEFAULT
	var/can_randomize = TRUE
	var/randomize_by_default = TRUE
	var/relevant_bodyflag
	var/should_update_preview = TRUE

/datum/preference/deserialize(input, datum/preferences/preferences)
	CRASH("`deserialize()` was not implemented on [type]!")

/datum/preference/serialize(input)
	return input

/datum/preference/proc/create_default_value()
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("`create_default_value()` was not implemented on [type]!")

/datum/preference/proc/create_informed_default_value(datum/preferences/preferences)
	return create_default_value()

/datum/preference/proc/create_random_value(datum/preferences/preferences)
	return create_informed_default_value(preferences)

/datum/preference/proc/is_randomizable()
	SHOULD_NOT_OVERRIDE(TRUE)
	return savefile_identifier == PREFERENCE_CHARACTER && can_randomize

/datum/preference/proc/read(list/save_data, datum/preferences/preferences)
	SHOULD_NOT_OVERRIDE(TRUE)
	var/value = save_data?[savefile_key]
	if(isnull(value))
		return null
	return deserialize(value, preferences)

/datum/preference/proc/write(list/save_data, value, datum/preferences/preferences)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(!is_valid(value, preferences))
		return FALSE
	if(!isnull(save_data))
		save_data[savefile_key] = serialize(value)
	post_write(value, preferences)
	return TRUE

/datum/preference/proc/post_write(value, datum/preferences/preferences)
	SHOULD_CALL_PARENT(TRUE)
	return

/datum/preference/proc/apply_to_client(client/client, value)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	return

/datum/preference/proc/apply_to_client_updated(client/client, value)
	SHOULD_NOT_SLEEP(TRUE)
	apply_to_client(client, value)

/datum/preference/proc/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("`apply_to_human()` was not implemented for [type]!")

/datum/preference/proc/is_valid(value, datum/preferences/preferences)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(FALSE)
	CRASH("`is_valid()` was not implemented for [type]!")

/datum/preference/proc/compile_ui_data(mob/user, value)
	SHOULD_NOT_SLEEP(TRUE)
	return serialize(value)

/datum/preference/proc/compile_constant_data()
	SHOULD_NOT_SLEEP(TRUE)
	return null

/datum/preference/proc/has_relevant_feature(datum/preferences/preferences)
	if(isnull(relevant_bodyflag))
		return TRUE
	var/datum/species/species = preferences.get_species_prototype()
	return !!(species.bodyflags & relevant_bodyflag)

/datum/preference/proc/is_accessible(datum/preferences/preferences)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_NOT_SLEEP(TRUE)
	if(!has_relevant_feature(preferences))
		return FALSE
	if(!should_show_on_page(preferences.current_window))
		return FALSE
	return TRUE

/datum/preference/proc/should_show_on_page(preference_tab)
	var/is_on_character_page = preference_tab == PREFERENCE_TAB_CHARACTER_PREFERENCES
	var/is_character_preference = savefile_identifier == PREFERENCE_CHARACTER
	return is_on_character_page == is_character_preference

/datum/preferences/proc/get_save_data_for_savefile_identifier(savefile_identifier)
	RETURN_TYPE(/list)
	switch(savefile_identifier)
		if(PREFERENCE_CHARACTER)
			return character_data
		if(PREFERENCE_PLAYER)
			return player_data
	CRASH("Unknown savefile identifier [savefile_identifier]")

/datum/preferences/proc/read_preference(preference_type)
	var/datum/preference/preference_entry = GLOB.preference_entries[preference_type]
	if(isnull(preference_entry))
		CRASH("Preference type `[preference_type]` is invalid!")

	if(preference_type in value_cache)
		return value_cache[preference_type]

	var/value = preference_entry.read(get_save_data_for_savefile_identifier(preference_entry.savefile_identifier), src)
	if(isnull(value))
		value = preference_entry.create_informed_default_value(src)
		if(write_preference(preference_entry, value))
			return value
		CRASH("Couldn't write the default value for [preference_type] (received [value])")
	value_cache[preference_type] = value
	return value

/datum/preferences/proc/write_preference(datum/preference/preference, preference_value)
	var/save_data = get_save_data_for_savefile_identifier(preference.savefile_identifier)
	var/new_value = preference.deserialize(preference_value, src)
	var/success = preference.write(save_data, new_value, src)
	if(success)
		value_cache[preference.type] = new_value
	return success

/datum/preferences/proc/update_preference(datum/preference/preference, preference_value)
	if(!preference.is_accessible(src))
		return FALSE

	var/new_value = preference.deserialize(preference_value, src)
	var/success = preference.write(null, new_value, src)
	if(!success)
		return FALSE

	recently_updated_keys |= preference.type
	value_cache[preference.type] = new_value

	if(preference.savefile_identifier == PREFERENCE_PLAYER)
		preference.apply_to_client_updated(parent, read_preference(preference.type))
		return TRUE

	sanitize_character_preferences()
	if(preference.should_update_preview)
		character_preview_view?.update_body()

	return TRUE

/datum/preferences/proc/get_species_prototype()
	RETURN_TYPE(/datum/species)
	return GLOB.all_species[read_preference(/datum/preference/choiced/species)]

/datum/preference/choiced
	abstract_type = /datum/preference/choiced
	var/should_generate_icons = FALSE
	var/list/cached_values
	var/main_feature_name

/datum/preference/choiced/proc/get_choices()
	SHOULD_NOT_OVERRIDE(TRUE)
	if(isnull(cached_values))
		cached_values = init_possible_values()
		ASSERT(length(cached_values))
	return cached_values

/datum/preference/choiced/proc/get_choices_serialized()
	SHOULD_NOT_OVERRIDE(TRUE)
	var/list/serialized_choices = list()
	for(var/choice in get_choices())
		serialized_choices += serialize(choice)
	return serialized_choices

/datum/preference/choiced/proc/init_possible_values()
	CRASH("`init_possible_values()` was not implemented for [type]!")

/datum/preference/choiced/proc/get_valid_choices(datum/preferences/preferences)
	return get_choices()

/datum/preference/choiced/proc/icon_for(value)
	SHOULD_CALL_PARENT(FALSE)
	SHOULD_NOT_SLEEP(TRUE)
	CRASH("`icon_for()` was not implemented for [type], even though should_generate_icons = TRUE!")

/datum/preference/choiced/is_valid(value, datum/preferences/preferences)
	return value in (preferences ? get_valid_choices(preferences) : get_choices())

/datum/preference/choiced/deserialize(input, datum/preferences/preferences)
	return sanitize_inlist(input, preferences ? get_valid_choices(preferences) : get_choices(), create_informed_default_value(preferences))

/datum/preference/choiced/create_default_value()
	return pick(get_choices())

/datum/preference/choiced/create_informed_default_value(datum/preferences/preferences)
	var/value = create_default_value()
	if(!preferences)
		return value
	var/list/valid_choices = get_valid_choices(preferences)
	if(value in valid_choices)
		return value
	return length(valid_choices) ? valid_choices[1] : value

/datum/preference/choiced/compile_constant_data()
	var/list/data = list()
	var/list/choices = list()
	for(var/choice in get_choices())
		choices += choice
	data["choices"] = choices

	if(should_generate_icons)
		var/list/icons = list()
		for(var/choice in choices)
			icons[choice] = get_spritesheet_key(choice)
		data["icons"] = icons

	if(!isnull(main_feature_name))
		data["name"] = main_feature_name

	return data

/datum/preference/color
	abstract_type = /datum/preference/color

/datum/preference/color/deserialize(input, datum/preferences/preferences)
	return sanitize_hexcolor(input, default = create_default_value())

/datum/preference/color/create_default_value()
	return rand_hex_color()

/datum/preference/color/serialize(input)
	return sanitize_hexcolor(input)

/datum/preference/color/is_valid(value, datum/preferences/preferences)
	return istext(value) && sanitize_hexcolor(value) == value

/datum/preference/numeric
	abstract_type = /datum/preference/numeric
	var/minimum
	var/maximum
	var/step = 1

/datum/preference/numeric/proc/get_valid_range(datum/preferences/preferences)
	return list(minimum, maximum)

/datum/preference/numeric/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	var/list/range = preferences ? get_valid_range(preferences) : list(minimum, maximum)
	return sanitize_float(input, range[1], range[2], step, create_informed_default_value(preferences))

/datum/preference/numeric/serialize(input)
	return sanitize_float(input, minimum, maximum, step, create_default_value())

/datum/preference/numeric/create_default_value()
	return rand(minimum, maximum)

/datum/preference/numeric/is_valid(value, datum/preferences/preferences)
	var/list/range = preferences ? get_valid_range(preferences) : list(minimum, maximum)
	return isnum(value) && value >= round(range[1], step) && value <= round(range[2], step)

/datum/preference/numeric/compile_constant_data()
	return list(
		"minimum" = minimum,
		"maximum" = maximum,
		"step" = step,
	)

/datum/preference/toggle
	abstract_type = /datum/preference/toggle
	var/default_value = TRUE

/datum/preference/toggle/create_default_value()
	return default_value

/datum/preference/toggle/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return !!input

/datum/preference/toggle/is_valid(value, datum/preferences/preferences)
	return value == TRUE || value == FALSE

/datum/preference/text
	abstract_type = /datum/preference/text
	var/maximum_value_length = 256
	var/should_strip_html = TRUE

/datum/preference/text/deserialize(input, datum/preferences/preferences)
	return should_strip_html ? STRIP_HTML_SIMPLE(input, maximum_value_length) : copytext(input, 1, maximum_value_length)

/datum/preference/text/create_default_value()
	return ""

/datum/preference/text/is_valid(value, datum/preferences/preferences)
	return istext(value) && length(value) < maximum_value_length

/datum/preference/text/compile_constant_data()
	return list("maximum_length" = maximum_value_length)
