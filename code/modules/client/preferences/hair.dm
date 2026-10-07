GLOBAL_LIST_INIT(species_with_hair_colour, list(SPECIES_HUMAN, SPECIES_UNATHI, SPECIES_TAJARAN, SPECIES_SKRELL, SPECIES_MACHINEPERSON, SPECIES_WRYN, SPECIES_VULPKANIN, SPECIES_VOX))

/datum/preference/choiced/accessory/hair
	savefile_key = "hair_style_name"
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Причёска"
	accessory_category = ACCESSORY_CATEGORY_HAIR
	none_value = "Bald"

/datum/preference/choiced/accessory/hair/get_accessory_list()
	return GLOB.hair_styles_public_list

/datum/preference/choiced/accessory/hair/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/datum/robolimb/robohead = preferences.get_robohead()
	var/list/valid_hairstyles = list(none_value)
	for(var/hairstyle in GLOB.hair_styles_public_list)
		var/datum/sprite_accessory/accessory = GLOB.hair_styles_public_list[hairstyle]
		if(robohead)
			if((species_name in accessory.species_allowed) && robohead.is_monitor && (!accessory.models_allowed || (robohead.company in accessory.models_allowed)))
				valid_hairstyles |= hairstyle
			else if(!robohead.is_monitor && (SPECIES_HUMAN in accessory.species_allowed))
				valid_hairstyles |= hairstyle
		else if(species_name in accessory.species_allowed)
			valid_hairstyles |= hairstyle
	return valid_hairstyles

/datum/preference/choiced/accessory/hair/create_random_value(datum/preferences/preferences)
	return random_hair_style(preferences.read_preference(/datum/preference/choiced/gender), preferences.get_species_prototype(), preferences.get_robohead())

/datum/preference/choiced/accessory/hair/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.h_style = value

/datum/preference/color/hair_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hair_colour"
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/hair_color/has_relevant_feature(datum/preferences/preferences)
	return (preferences.read_preference(/datum/preference/choiced/species) in GLOB.species_with_hair_colour)

/datum/preference/color/hair_color/create_random_value(datum/preferences/preferences)
	return random_hair_colour()

/datum/preference/color/hair_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.hair_colour = value

/datum/preference/color/secondary_hair_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "secondary_hair_colour"
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/secondary_hair_color/has_relevant_feature(datum/preferences/preferences)
	if(!(preferences.read_preference(/datum/preference/choiced/species) in GLOB.species_with_hair_colour))
		return FALSE
	var/datum/sprite_accessory/hair_style = GLOB.hair_styles_public_list[preferences.read_preference(/datum/preference/choiced/accessory/hair)]
	return hair_style?.secondary_theme && !hair_style.no_sec_colour

/datum/preference/color/secondary_hair_color/create_random_value(datum/preferences/preferences)
	return preferences.read_preference(/datum/preference/color/hair_color)

/datum/preference/color/secondary_hair_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.sec_hair_colour = value

/datum/preference/choiced/accessory/hair_gradient
	savefile_key = "hair_gradient"
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	main_feature_name = "Градиент причёски"
	accessory_category = ACCESSORY_CATEGORY_HAIR_GRADIENT

/datum/preference/choiced/accessory/hair_gradient/get_accessory_list()
	return GLOB.hair_gradients_list

/datum/preference/choiced/accessory/hair_gradient/create_random_value(datum/preferences/preferences)
	return none_value

/datum/preference/choiced/accessory/hair_gradient/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.h_grad_style = value

/datum/preference/color/hair_gradient_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hair_gradient_colour"
	randomize_by_default = FALSE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/hair_gradient_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.h_grad_colour = value

/datum/preference/numeric/hair_gradient_alpha
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hair_gradient_alpha"
	randomize_by_default = FALSE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE
	minimum = 0
	maximum = 255

/datum/preference/numeric/hair_gradient_alpha/create_default_value()
	return 200

/datum/preference/numeric/hair_gradient_alpha/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.h_grad_alpha = value

/datum/preference/numeric/hair_gradient_offset_x
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hair_gradient_offset_x"
	randomize_by_default = FALSE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE
	minimum = -16
	maximum = 16

/datum/preference/numeric/hair_gradient_offset_x/create_default_value()
	return 0

/datum/preference/numeric/hair_gradient_offset_x/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.h_grad_offset_x = value

/datum/preference/numeric/hair_gradient_offset_y
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hair_gradient_offset_y"
	randomize_by_default = FALSE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE
	minimum = -16
	maximum = 16

/datum/preference/numeric/hair_gradient_offset_y/create_default_value()
	return 0

/datum/preference/numeric/hair_gradient_offset_y/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.h_grad_offset_y = value

/datum/preference/choiced/accessory/facial_hair
	savefile_key = "facial_style_name"
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Лицевая растительность"
	accessory_category = ACCESSORY_CATEGORY_FACIAL_HAIR
	none_value = "Shaved"

/datum/preference/choiced/accessory/facial_hair/get_accessory_list()
	return GLOB.facial_hair_styles_list

/datum/preference/choiced/accessory/facial_hair/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/datum/robolimb/robohead = preferences.get_robohead()
	var/list/valid_styles = list(none_value)
	for(var/style in GLOB.facial_hair_styles_list)
		var/datum/sprite_accessory/accessory = GLOB.facial_hair_styles_list[style]
		if(accessory.wizard_only || gender == accessory.unsuitable_gender)
			continue
		if(robohead)
			if((species_name in accessory.species_allowed) && robohead.is_monitor && (!accessory.models_allowed || (robohead.company in accessory.models_allowed)))
				valid_styles |= style
			else if(!robohead.is_monitor && (SPECIES_HUMAN in accessory.species_allowed))
				valid_styles |= style
		else if(species_name in accessory.species_allowed)
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/facial_hair/create_random_value(datum/preferences/preferences)
	return random_facial_hair_style(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species), preferences.get_robohead())

/datum/preference/choiced/accessory/facial_hair/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.f_style = value

/datum/preference/color/facial_hair_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "facial_hair_colour"
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/facial_hair_color/has_relevant_feature(datum/preferences/preferences)
	return (preferences.read_preference(/datum/preference/choiced/species) in GLOB.species_with_hair_colour)

/datum/preference/color/facial_hair_color/create_random_value(datum/preferences/preferences)
	if(prob(75))
		return preferences.read_preference(/datum/preference/color/hair_color)
	return random_hair_colour()

/datum/preference/color/facial_hair_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.facial_colour = value

/datum/preference/color/secondary_facial_hair_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "secondary_facial_hair_colour"
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/secondary_facial_hair_color/has_relevant_feature(datum/preferences/preferences)
	if(!(preferences.read_preference(/datum/preference/choiced/species) in GLOB.species_with_hair_colour))
		return FALSE
	var/datum/sprite_accessory/facial_style = GLOB.facial_hair_styles_list[preferences.read_preference(/datum/preference/choiced/accessory/facial_hair)]
	return facial_style?.secondary_theme && !facial_style.no_sec_colour

/datum/preference/color/secondary_facial_hair_color/create_random_value(datum/preferences/preferences)
	return preferences.read_preference(/datum/preference/color/facial_hair_color)

/datum/preference/color/secondary_facial_hair_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/obj/item/organ/external/head/head = preferences.get_head_organ(target)
	head?.sec_facial_colour = value
