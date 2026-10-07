/datum/preference/choiced/accessory/head_accessory
	savefile_key = "head_accessory_style_name"
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Аксессуары на голове"
	accessory_category = ACCESSORY_CATEGORY_HEAD_ACCESSORY
	relevant_bodyflag = HAS_HEAD_ACCESSORY

/datum/preference/choiced/accessory/head_accessory/get_accessory_list()
	return GLOB.head_accessory_styles_list

/datum/preference/choiced/accessory/head_accessory/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/list/valid_styles = list(none_value)
	for(var/style in GLOB.head_accessory_styles_list)
		var/datum/sprite_accessory/accessory = GLOB.head_accessory_styles_list[style]
		if(species_name in accessory.species_allowed)
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/head_accessory/create_random_value(datum/preferences/preferences)
	if(!has_relevant_feature(preferences))
		return none_value
	return random_head_accessory(preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/choiced/accessory/head_accessory/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	if(!(target.dna.species.bodyflags & HAS_HEAD_ACCESSORY))
		return
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.ha_style = value

/datum/preference/color/head_accessory_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "head_accessory_colour"
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE
	relevant_bodyflag = HAS_HEAD_ACCESSORY

/datum/preference/color/head_accessory_color/create_random_value(datum/preferences/preferences)
	return random_natural_colour()

/datum/preference/color/head_accessory_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	if(!(target.dna.species.bodyflags & HAS_HEAD_ACCESSORY))
		return
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.headacc_colour = value

/datum/preference/choiced/accessory/alt_head
	savefile_key = "alt_head_name"
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Тип головы"
	accessory_category = ACCESSORY_CATEGORY_ALT_HEAD
	relevant_bodyflag = HAS_ALT_HEADS

/datum/preference/choiced/accessory/alt_head/get_accessory_list()
	return GLOB.alt_heads_list

/datum/preference/choiced/accessory/alt_head/get_valid_choices(datum/preferences/preferences)
	if(preferences.organ_data[BODY_ZONE_HEAD] == PREF_ORGANSTATUS_CYBORG_ENG)
		return list(none_value)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/list/valid_heads = list(none_value)
	for(var/style in GLOB.alt_heads_list)
		var/datum/sprite_accessory/accessory = GLOB.alt_heads_list[style]
		if(species_name in accessory?.species_allowed)
			valid_heads |= style
	return valid_heads

/datum/preference/choiced/accessory/alt_head/create_random_value(datum/preferences/preferences)
	return none_value

/datum/preference/choiced/accessory/alt_head/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.alt_head = value

/datum/preference/choiced/accessory/marking
	abstract_type = /datum/preference/choiced/accessory/marking
	category = PREFERENCE_CATEGORY_FEATURES
	accessory_category = ACCESSORY_CATEGORY_MARKING
	var/marking_location

/datum/preference/choiced/accessory/marking/get_accessory_list()
	return GLOB.marking_styles_list

/datum/preference/choiced/accessory/marking/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/list/valid_markings = list(none_value)
	for(var/style in GLOB.marking_styles_list)
		var/datum/sprite_accessory/body_markings/marking = GLOB.marking_styles_list[style]
		if(marking.marking_location != marking_location || !(species_name in marking.species_allowed))
			continue
		if(is_marking_valid(marking, preferences))
			valid_markings |= style
	return valid_markings

/datum/preference/choiced/accessory/marking/proc/is_marking_valid(datum/sprite_accessory/body_markings/marking, datum/preferences/preferences)
	return TRUE

/datum/preference/choiced/accessory/marking/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.m_styles[marking_location] = (target.dna.species.bodyflags & relevant_bodyflag) ? value : none_value

/datum/preference/choiced/accessory/marking/head
	savefile_key = "head_marking_style"
	main_feature_name = "Отметки на голове"
	relevant_bodyflag = HAS_HEAD_MARKINGS
	marking_location = "head"

/datum/preference/choiced/accessory/marking/head/is_marking_valid(datum/sprite_accessory/body_markings/marking, datum/preferences/preferences)
	var/alt_head = preferences.read_preference(/datum/preference/choiced/accessory/alt_head)
	if(alt_head && alt_head != "None")
		if(!("All" in marking.heads_allowed) && !(alt_head in marking.heads_allowed))
			return FALSE
	else if(marking.heads_allowed && !("All" in marking.heads_allowed))
		return FALSE

	var/datum/robolimb/robohead = preferences.get_robohead()
	if(!robohead)
		return TRUE
	if(robohead.is_monitor)
		return FALSE
	return robohead.company in marking.models_allowed

/datum/preference/choiced/accessory/marking/head/create_random_value(datum/preferences/preferences)
	if(!has_relevant_feature(preferences))
		return none_value
	return random_marking_style("head", preferences.read_preference(/datum/preference/choiced/species), preferences.get_robohead(), null, preferences.read_preference(/datum/preference/choiced/accessory/alt_head))

/datum/preference/choiced/accessory/marking/body
	savefile_key = "body_marking_style"
	main_feature_name = "Отметки на теле"
	relevant_bodyflag = HAS_BODY_MARKINGS
	marking_location = "body"

/datum/preference/choiced/accessory/marking/body/is_marking_valid(datum/sprite_accessory/body_markings/marking, datum/preferences/preferences)
	if(!marking.pickable || marking.wizard_only)
		return FALSE
	return marking.unsuitable_gender != preferences.read_preference(/datum/preference/choiced/gender)

/datum/preference/choiced/accessory/marking/body/create_random_value(datum/preferences/preferences)
	if(!has_relevant_feature(preferences))
		return none_value
	return random_marking_style("body", preferences.read_preference(/datum/preference/choiced/species), gender = preferences.read_preference(/datum/preference/choiced/gender))

/datum/preference/choiced/accessory/marking/tail
	savefile_key = "tail_marking_style"
	main_feature_name = "Отметки на хвосте"
	relevant_bodyflag = HAS_TAIL_MARKINGS
	marking_location = "tail"

/datum/preference/choiced/accessory/marking/tail/is_marking_valid(datum/sprite_accessory/body_markings/marking, datum/preferences/preferences)
	var/body_accessory = preferences.read_preference(/datum/preference/choiced/accessory/body_accessory)
	if(!body_accessory || body_accessory == "None")
		return !marking.tails_allowed
	return marking.tails_allowed && (body_accessory in marking.tails_allowed)

/datum/preference/choiced/accessory/marking/tail/create_random_value(datum/preferences/preferences)
	if(!has_relevant_feature(preferences))
		return none_value
	var/body_accessory = preferences.read_preference(/datum/preference/choiced/accessory/body_accessory)
	return random_marking_style("tail", preferences.read_preference(/datum/preference/choiced/species), null, body_accessory == "None" ? null : body_accessory)

/datum/preference/color/marking
	abstract_type = /datum/preference/color/marking
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE
	var/marking_location

/datum/preference/color/marking/create_default_value()
	return "#000000"

/datum/preference/color/marking/create_random_value(datum/preferences/preferences)
	return random_natural_colour()

/datum/preference/color/marking/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.m_colours[marking_location] = (target.dna.species.bodyflags & relevant_bodyflag) ? value : "#000000"

/datum/preference/color/marking/head
	savefile_key = "head_marking_colour"
	relevant_bodyflag = HAS_HEAD_MARKINGS
	marking_location = "head"

/datum/preference/color/marking/body
	savefile_key = "body_marking_colour"
	relevant_bodyflag = HAS_BODY_MARKINGS
	marking_location = "body"

/datum/preference/color/marking/tail
	savefile_key = "tail_marking_colour"
	relevant_bodyflag = HAS_TAIL_MARKINGS
	marking_location = "tail"
