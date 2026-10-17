/datum/preference/choiced/accessory/underwear
	savefile_key = "underwear"
	category = PREFERENCE_CATEGORY_CLOTHING
	main_feature_name = "Нижнее бельё"
	accessory_category = ACCESSORY_CATEGORY_UNDERWEAR
	none_value = "Nude"

/datum/preference/choiced/accessory/underwear/get_accessory_list()
	return SSaccessories.underwear_list

/datum/preference/choiced/accessory/underwear/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/list/valid_styles = list(none_value)
	for(var/style in SSaccessories.underwear_list)
		var/datum/sprite_accessory/accessory = SSaccessories.underwear_list[style]
		if((!accessory.gender || accessory.gender == gender) && (species_name in accessory.species_allowed))
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/underwear/create_random_value(datum/preferences/preferences)
	return random_underwear(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/choiced/accessory/underwear/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.underwear = value

/datum/preference/choiced/accessory/underwear/compile_constant_data()
	var/list/data = ..()
	data[SUPPLEMENTAL_FEATURE_KEY] = "underwear_color"
	return data

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
	return SSaccessories.undershirt_list

/datum/preference/choiced/accessory/undershirt/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/list/valid_styles = list(none_value)
	for(var/style in SSaccessories.undershirt_list)
		var/datum/sprite_accessory/accessory = SSaccessories.undershirt_list[style]
		if(accessory.gender && accessory.gender != gender)
			continue
		if(species_name in accessory.species_allowed)
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/undershirt/create_random_value(datum/preferences/preferences)
	return random_undershirt(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/choiced/accessory/undershirt/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.undershirt = value

/datum/preference/choiced/accessory/undershirt/compile_constant_data()
	var/list/data = ..()
	data[SUPPLEMENTAL_FEATURE_KEY] = "undershirt_color"
	return data

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
	return SSaccessories.socks_list

/datum/preference/choiced/accessory/socks/get_valid_choices(datum/preferences/preferences)
	var/species_name = preferences.read_preference(/datum/preference/choiced/species)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/list/valid_styles = list(none_value)
	for(var/style in SSaccessories.socks_list)
		var/datum/sprite_accessory/accessory = SSaccessories.socks_list[style]
		if((!accessory.gender || accessory.gender == gender) && (species_name in accessory.species_allowed))
			valid_styles |= style
	return valid_styles

/datum/preference/choiced/accessory/socks/create_random_value(datum/preferences/preferences)
	return random_socks(preferences.read_preference(/datum/preference/choiced/gender), preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/choiced/accessory/socks/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.socks = value

/datum/preference/choiced/backpack
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "backbag"
	main_feature_name = "Рюкзак"
	category = PREFERENCE_CATEGORY_CLOTHING
	should_generate_icons = TRUE
	randomize_by_default = FALSE

/datum/preference/choiced/backpack/init_possible_values()
	return GLOB.backbaglist.Copy()

/datum/preference/choiced/backpack/create_default_value()
	return GBACKPACK

/datum/preference/choiced/backpack/icon_for(value)
	switch(value)
		if(GBACKPACK)
			return /obj/item/storage/backpack
		if(GSATCHEL)
			return /obj/item/storage/backpack/satchel_norm
		if(GDUFFLEBAG)
			return /obj/item/storage/backpack/duffel
		if(LSATCHEL)
			return /obj/item/storage/backpack/satchel
		if(DBACKPACK)
			return /obj/item/storage/backpack/medic
		if(DSATCHEL)
			return /obj/item/storage/backpack/satchel_med
		if(DDUFFLEBAG)
			return /obj/item/storage/backpack/duffel/medical

/datum/preference/choiced/backpack/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		GBACKPACK = "Серый рюкзак",
		GSATCHEL = "Серая сумка",
		GDUFFLEBAG = "Серый вещмешок",
		LSATCHEL = "Кожаная сумка",
		DBACKPACK = "Рюкзак отдела",
		DSATCHEL = "Сумка отдела",
		DDUFFLEBAG = "Вещмешок отдела",
	)
	return data

/datum/preference/choiced/backpack/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.backbag = value
