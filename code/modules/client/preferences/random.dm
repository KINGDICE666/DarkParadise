/datum/preference/choiced/random_body
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_key = "random_body"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/random_body/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/choiced/random_body/init_possible_values()
	return list(RANDOM_ANTAG_ONLY, RANDOM_DISABLED, RANDOM_ENABLED)

/datum/preference/choiced/random_body/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/random_body/create_default_value()
	return RANDOM_DISABLED

/datum/preference/choiced/random_name
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_key = "random_name"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/random_name/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/choiced/random_name/init_possible_values()
	return list(RANDOM_ANTAG_ONLY, RANDOM_DISABLED, RANDOM_ENABLED)

/datum/preference/choiced/random_name/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/random_name/create_default_value()
	return RANDOM_DISABLED
