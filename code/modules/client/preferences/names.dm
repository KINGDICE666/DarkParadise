/datum/preference/name
	abstract_type = /datum/preference/name
	category = "names"
	priority = PREFERENCE_PRIORITY_NAMES
	savefile_identifier = PREFERENCE_CHARACTER
	var/explanation
	var/group
	var/allow_numbers = FALSE

/datum/preference/name/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return

/datum/preference/name/deserialize(input, datum/preferences/preferences)
	return reject_bad_name("[input]", allow_numbers)

/datum/preference/name/serialize(input)
	return reject_bad_name(input, allow_numbers)

/datum/preference/name/is_valid(value, datum/preferences/preferences)
	return istext(value) && !isnull(reject_bad_name(value, allow_numbers))

/datum/preference/name/real_name
	explanation = "Имя"
	group = "_real_name"
	savefile_key = "real_name"
	allow_numbers = TRUE

/datum/preference/name/real_name/create_informed_default_value(datum/preferences/preferences)
	if(!preferences)
		return random_name(MALE)
	return random_name(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/name/real_name/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	if(preferences.read_preference(/datum/preference/toggle/random_name))
		value = random_name(target.gender, target.dna.species.name)

	if(CONFIG_GET(flag/humans_need_surnames))
		var/first_space = findtext(value, " ")
		if(!first_space)
			value += " [target.gender == FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names_male)]"
		else if(first_space == length(value))
			value += "[target.gender == FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names_male)]"

	target.real_name = value
	target.dna.real_name = value
	target.name = value

/datum/preference/toggle/random_name
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "name_is_always_random"
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	default_value = FALSE
	can_randomize = FALSE

/datum/preference/toggle/random_name/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return
