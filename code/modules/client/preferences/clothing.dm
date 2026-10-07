/datum/preference/choiced/accessory/underwear
	savefile_key = "underwear"
	category = PREFERENCE_CATEGORY_CLOTHING
	main_feature_name = "Нижнее бельё"
	accessory_category = ACCESSORY_CATEGORY_UNDERWEAR
	none_value = "Nude"

/datum/preference/choiced/accessory/underwear/get_accessory_list()
	return GLOB.underwear_list

/datum/preference/choiced/accessory/underwear/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/list/valid_styles = list(none_value)
	for(var/style in GLOB.underwear_list)
		var/datum/sprite_accessory/accessory = GLOB.underwear_list[style]
		if(gender != accessory.unsuitable_gender && (species_name in accessory.species_allowed))
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/underwear/create_random_value(datum/preferences/preferences)
	return random_underwear(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/choiced/accessory/underwear/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.underwear = value

/datum/preference/color/underwear_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "underwear_color"
	randomize_by_default = FALSE
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/underwear_color/create_default_value()
	return "#ffffff"

/datum/preference/color/underwear_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.color_underwear = value

/datum/preference/choiced/accessory/undershirt
	savefile_key = "undershirt"
	category = PREFERENCE_CATEGORY_CLOTHING
	main_feature_name = "Нательная рубашка"
	accessory_category = ACCESSORY_CATEGORY_UNDERSHIRT
	none_value = "Nude"

/datum/preference/choiced/accessory/undershirt/get_accessory_list()
	return GLOB.undershirt_list

/datum/preference/choiced/accessory/undershirt/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/list/valid_styles = list(none_value)
	for(var/style in GLOB.undershirt_list)
		var/datum/sprite_accessory/accessory = GLOB.undershirt_list[style]
		if(gender == MALE && accessory.unsuitable_gender)
			continue
		if(species_name in accessory.species_allowed)
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/undershirt/create_random_value(datum/preferences/preferences)
	return random_undershirt(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/choiced/accessory/undershirt/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.undershirt = value

/datum/preference/color/undershirt_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "undershirt_color"
	randomize_by_default = FALSE
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/undershirt_color/create_default_value()
	return "#ffffff"

/datum/preference/color/undershirt_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.color_undershirt = value

/datum/preference/choiced/accessory/socks
	savefile_key = "socks"
	category = PREFERENCE_CATEGORY_CLOTHING
	main_feature_name = "Носки"
	accessory_category = ACCESSORY_CATEGORY_SOCKS
	none_value = "Nude"

/datum/preference/choiced/accessory/socks/get_accessory_list()
	return GLOB.socks_list

/datum/preference/choiced/accessory/socks/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/list/valid_styles = list(none_value)
	for(var/style in GLOB.socks_list)
		var/datum/sprite_accessory/accessory = GLOB.socks_list[style]
		if(gender != accessory.unsuitable_gender && (species_name in accessory.species_allowed))
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/socks/create_random_value(datum/preferences/preferences)
	return random_socks(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/choiced/accessory/socks/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.socks = value

/datum/preference/choiced/backpack
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "backbag"
	randomize_by_default = FALSE
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL

/datum/preference/choiced/backpack/init_possible_values()
	return GLOB.backbaglist.Copy()

/datum/preference/choiced/backpack/create_default_value()
	return GBACKPACK

/datum/preference/choiced/backpack/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.backbag = value
