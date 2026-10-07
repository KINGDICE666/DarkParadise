/datum/preference/choiced/language
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "language"
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE

/datum/preference/choiced/language/init_possible_values()
	var/list/values = list(LANGUAGE_NONE)
	for(var/language_name in GLOB.all_languages)
		var/datum/language/language = GLOB.all_languages[language_name]
		if((language.flags & UNIQUE) || !(language.flags & RESTRICTED))
			values |= language_name
	return values

/datum/preference/choiced/language/get_valid_choices(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	var/list/values = list(LANGUAGE_NONE)
	for(var/language_name in GLOB.all_languages)
		var/datum/language/language = GLOB.all_languages[language_name]
		if(language.flags & UNIQUE)
			if(language_name in species.secondary_langs)
				values |= language_name
		else if(!(language.flags & RESTRICTED))
			values |= language_name
	return values

/datum/preference/choiced/language/has_relevant_feature(datum/preferences/preferences)
	return preferences.read_preference(/datum/preference/choiced/species) != SPECIES_GREY

/datum/preference/choiced/language/create_default_value()
	return LANGUAGE_NONE

/datum/preference/choiced/language/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.add_language(value)

/datum/preference/choiced/autohiss
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "autohiss"
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE

/datum/preference/choiced/autohiss/init_possible_values()
	return list(AUTOHISS_OFF, AUTOHISS_BASIC, AUTOHISS_FULL)

/datum/preference/choiced/autohiss/has_relevant_feature(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	return !!species.autohiss_basic_map

/datum/preference/choiced/autohiss/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/autohiss/create_default_value()
	return AUTOHISS_FULL

/datum/preference/choiced/autohiss/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/choiced/autohiss/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		"[AUTOHISS_OFF]" = PREF_AUTOHISS_OFF,
		"[AUTOHISS_BASIC]" = PREF_AUTOHISS_BASIC,
		"[AUTOHISS_FULL]" = PREF_AUTOHISS_FULL,
	)
	return data

/datum/preference/choiced/blood_type
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "b_type"
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL

/datum/preference/choiced/blood_type/init_possible_values()
	return list("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-")

/datum/preference/choiced/blood_type/create_default_value()
	return pick(4;"O-", 36;"O+", 3;"A-", 28;"A+", 1;"B-", 20;"B+", 1;"AB-", 5;"AB+")

/datum/preference/choiced/blood_type/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.dna.blood_type = value

/datum/preference/choiced/nanotrasen_relation
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "nanotrasen_relation"
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE

/datum/preference/choiced/nanotrasen_relation/init_possible_values()
	return list(PREF_NTRELATION_LOYAL, PREF_NTRELATION_SUPPORTIVE, PREF_NTRELATION_NEUTRAL, PREF_NTRELATION_SCEPTICAL, PREF_NTRELATION_OPPOSED)

/datum/preference/choiced/nanotrasen_relation/create_default_value()
	return PREF_NTRELATION_NEUTRAL

/datum/preference/choiced/nanotrasen_relation/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/choiced/uplink_location
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "uplink_pref"
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/choiced/uplink_location/init_possible_values()
	return list(PREF_UPLINK_PDA, PREF_UPLINK_HEADSET)

/datum/preference/choiced/uplink_location/create_default_value()
	return PREF_UPLINK_PDA

/datum/preference/choiced/uplink_location/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/choiced/exoframe
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "exoframe_type"
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE

/datum/preference/choiced/exoframe/init_possible_values()
	return list(PREF_EXOFRAME_REINFORCED, PREF_EXOFRAME_INDUSTRIAL)

/datum/preference/choiced/exoframe/has_relevant_feature(datum/preferences/preferences)
	return preferences.read_preference(/datum/preference/choiced/species) == SPECIES_MACHINEPERSON

/datum/preference/choiced/exoframe/create_default_value()
	return PREF_EXOFRAME_REINFORCED

/datum/preference/choiced/exoframe/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/choiced/exoframe/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		PREF_EXOFRAME_REINFORCED = "Укреплённый каркас экзоскелета",
		PREF_EXOFRAME_INDUSTRIAL = "Промышленный каркас экзоскелета",
	)
	return data

/datum/preference/toggle/species_preference
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "speciesprefs"
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	default_value = FALSE
	can_randomize = FALSE

/datum/preference/toggle/species_preference/has_relevant_feature(datum/preferences/preferences)
	return (preferences.read_preference(/datum/preference/choiced/species) in list(SPECIES_VOX, SPECIES_GREY, SPECIES_WRYN))

/datum/preference/toggle/species_preference/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/toggle/species_preference/compile_constant_data()
	return list("labels" = list(
		SPECIES_VOX = "Большой баллон с азотом",
		SPECIES_GREY = "Дешифратор инопланетной речи",
		SPECIES_WRYN = "Телепатическая глухота",
	))

/datum/preference/toggle/can_be_antagonist
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "can_be_antagonist"
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/toggle/can_be_antagonist/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/choiced/alternate_option
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "alternate_option"
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/choiced/alternate_option/init_possible_values()
	return list(GET_RANDOM_JOB, BE_ASSISTANT, RETURN_TO_LOBBY)

/datum/preference/choiced/alternate_option/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/alternate_option/create_default_value()
	return RETURN_TO_LOBBY

/datum/preference/choiced/alternate_option/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/tts_seed
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "tts_seed"
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/tts_seed/deserialize(input, datum/preferences/preferences)
	return (input in SStts.tts_seeds) ? input : ""

/datum/preference/tts_seed/create_default_value()
	return ""

/datum/preference/tts_seed/is_valid(value, datum/preferences/preferences)
	return value == "" || (value in SStts.tts_seeds)

/datum/preference/tts_seed/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.tts_seed = value || null
	target.dna.tts_seed_dna = value || null
