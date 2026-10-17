/datum/preference/name
	abstract_type = /datum/preference/name
	category = "names"
	priority = PREFERENCE_PRIORITY_NAMES
	savefile_identifier = PREFERENCE_CHARACTER
	should_update_preview = FALSE
	var/explanation
	var/group
	var/allow_numbers = FALSE
	var/relevant_job

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
	if(CONFIG_GET(flag/humans_need_surnames))
		var/first_space = findtext(value, " ")
		if(!first_space)
			value += " [target.gender == FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names_male)]"
		else if(first_space == length(value))
			value += "[target.gender == FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names_male)]"

	target.real_name = value
	target.dna.real_name = value
	target.name = value

/datum/preference/name/clown
	explanation = "Имя клоуна"
	group = "fun"
	savefile_key = "clown_name"
	relevant_job = JOB_TITLE_CLOWN

/datum/preference/name/clown/create_default_value()
	return pick(GLOB.clown_names)

/datum/preference/name/mime
	explanation = "Имя мима"
	group = "fun"
	savefile_key = "mime_name"
	relevant_job = JOB_TITLE_MIME

/datum/preference/name/mime/create_default_value()
	return pick(GLOB.mime_names)

/datum/preference/name/cyborg
	explanation = "Имя киборга"
	group = "silicons"
	savefile_key = "cyborg_name"
	allow_numbers = TRUE
	can_randomize = FALSE
	relevant_job = JOB_TITLE_CYBORG

/datum/preference/name/cyborg/create_default_value()
	return DEFAULT_CYBORG_NAME

/datum/preference/name/ai
	explanation = "Имя ИИ"
	group = "silicons"
	savefile_key = "ai_name"
	allow_numbers = TRUE
	relevant_job = JOB_TITLE_AI

/datum/preference/name/ai/create_default_value()
	return pick(GLOB.ai_names)

/datum/preference/name/religion
	explanation = "Название религии"
	group = "religion"
	savefile_key = "religion_name"
	allow_numbers = TRUE

/datum/preference/name/religion/create_default_value()
	return DEFAULT_RELIGION_NAME

/datum/preference/name/deity
	explanation = "Имя божества"
	group = "religion"
	savefile_key = "deity_name"
	allow_numbers = TRUE
	can_randomize = FALSE

/datum/preference/name/deity/create_default_value()
	return DEFAULT_DEITY_NAME
