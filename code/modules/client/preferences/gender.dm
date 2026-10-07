/datum/preference/choiced/gender
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "gender"
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	priority = PREFERENCE_PRIORITY_GENDER

/datum/preference/choiced/gender/init_possible_values()
	return list(MALE, FEMALE, PLURAL)

/datum/preference/choiced/gender/get_valid_choices(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	if(species.has_gender)
		return list(MALE, FEMALE)
	return get_choices()

/datum/preference/choiced/gender/create_default_value()
	return pick(MALE, FEMALE)

/datum/preference/choiced/gender/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.change_gender(value)

/datum/preference/choiced/gender/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		MALE = PREF_GENDER_MALE,
		FEMALE = PREF_GENDER_FEMALE,
		PLURAL = PREF_GENDER_PLURAL,
	)
	return data
