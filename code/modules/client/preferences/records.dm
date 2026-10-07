/datum/preference/text/record
	abstract_type = /datum/preference/text/record
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE
	maximum_value_length = MAX_PAPER_MESSAGE_LEN

/datum/preference/text/record/flavor_text
	savefile_key = "flavor_text"

/datum/preference/text/record/flavor_text/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.flavor_text = value

/datum/preference/text/record/medical
	savefile_key = "med_record"

/datum/preference/text/record/medical/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.med_record = value

/datum/preference/text/record/security
	savefile_key = "sec_record"

/datum/preference/text/record/security/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.sec_record = value

/datum/preference/text/record/general
	savefile_key = "gen_record"

/datum/preference/text/record/general/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.gen_record = value

/datum/preference/text/record/exploitable
	savefile_key = "exploit_record"

/datum/preference/text/record/exploitable/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.exploit_record = value

/datum/preference/text/record/ooc_notes
	savefile_key = "OOC_Notes"

/datum/preference/text/record/ooc_notes/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	return
