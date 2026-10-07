/datum/preference/numeric/age
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "age"
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	minimum = 1
	maximum = 1000

/datum/preference/numeric/age/get_valid_range(datum/preferences/preferences)
	var/list/age_limits = get_age_limits(preferences.get_species_prototype(), list(SPECIES_AGE_MIN, SPECIES_AGE_MAX))
	return list(age_limits[SPECIES_AGE_MIN], age_limits[SPECIES_AGE_MAX])

/datum/preference/numeric/age/create_default_value()
	return AGE_SHEET[JOB_MIN_AGE_COMMAND]

/datum/preference/numeric/age/create_informed_default_value(datum/preferences/preferences)
	if(!preferences)
		return create_default_value()
	return get_rand_age(preferences.get_species_prototype())

/datum/preference/numeric/age/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.age = value
