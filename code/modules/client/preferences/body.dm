#define SKIN_TONE_MINIMUM -185
#define SKIN_TONE_MAXIMUM 34

/datum/preference/numeric/skin_tone
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "skin_tone"
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE
	minimum = SKIN_TONE_MINIMUM
	maximum = SKIN_TONE_MAXIMUM

/datum/preference/numeric/skin_tone/has_relevant_feature(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	return !!(species.bodyflags & (HAS_SKIN_TONE|HAS_ICON_SKIN_TONE))

/datum/preference/numeric/skin_tone/get_valid_range(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	if(species.bodyflags & HAS_ICON_SKIN_TONE)
		return list(1, max(1, length(species.icon_skin_tones)))
	return list(minimum, maximum)

/datum/preference/numeric/skin_tone/create_default_value()
	return 0

/datum/preference/numeric/skin_tone/create_informed_default_value(datum/preferences/preferences)
	if(!preferences || !has_relevant_feature(preferences))
		return 0
	var/datum/species/species = preferences.get_species_prototype()
	if(species.bodyflags & HAS_ICON_SKIN_TONE)
		return 1
	return 0

/datum/preference/numeric/skin_tone/create_random_value(datum/preferences/preferences)
	if(!has_relevant_feature(preferences))
		return 0
	return random_skin_tone(preferences.read_preference(/datum/preference/choiced/species))

/datum/preference/numeric/skin_tone/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.s_tone = value

/datum/preference/numeric/skin_tone/compile_constant_data()
	var/list/data = ..()
	var/list/tone_names = list()
	for(var/species_name in GLOB.all_species)
		var/datum/species/species = GLOB.all_species[species_name]
		if(length(species.icon_skin_tones))
			var/list/names = list()
			for(var/tone in species.icon_skin_tones)
				names += species.icon_skin_tones[tone]
			tone_names[species_name] = names
	data["icon_tone_names"] = tone_names
	return data

/datum/preference/color/skin_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "skin_colour"
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/skin_color/has_relevant_feature(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	if(species.bodyflags & HAS_SKIN_COLOR)
		return TRUE
	return (species.bodyflags & HAS_BODYACC_COLOR) && length(GLOB.body_accessory_by_species[species.name])

/datum/preference/color/skin_color/create_default_value()
	return "#000000"

/datum/preference/color/skin_color/create_random_value(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	if((species.bodyflags & HAS_SKIN_COLOR) && !(species.bodyflags & HAS_ICON_SKIN_TONE))
		return random_natural_colour()
	return create_default_value()

/datum/preference/color/skin_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.skin_colour = value

/datum/preference/color/eye_color
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "eye_colour"
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_APPEARANCE

/datum/preference/color/eye_color/create_random_value(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	if(species.bodyflags & ALL_RPARTS)
		return "#000000"
	return random_natural_colour()

/datum/preference/color/eye_color/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.change_eye_color(value)
	target.original_eye_color = value

/datum/preference/choiced/accessory/body_accessory
	savefile_key = "body_accessory"
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Хвост"
	accessory_category = ACCESSORY_CATEGORY_BODY_ACCESSORY

/datum/preference/choiced/accessory/body_accessory/get_accessory_list()
	return GLOB.body_accessory_by_name

/datum/preference/choiced/accessory/body_accessory/has_relevant_feature(datum/preferences/preferences)
	return length(get_valid_choices(preferences)) > 1

/datum/preference/choiced/accessory/body_accessory/get_valid_choices(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	var/list/valid_accessories = list()
	if(species.optional_body_accessory)
		valid_accessories += none_value
	for(var/accessory_name in GLOB.body_accessory_by_name)
		var/datum/body_accessory/accessory = GLOB.body_accessory_by_name[accessory_name]
		if(istype(accessory) && (species.name in accessory.allowed_species))
			valid_accessories |= accessory_name
	if(!length(valid_accessories))
		valid_accessories += none_value
	return valid_accessories

/datum/preference/choiced/accessory/body_accessory/create_random_value(datum/preferences/preferences)
	var/datum/species/species = preferences.get_species_prototype()
	if(!length(GLOB.body_accessory_by_species[species.name]))
		return none_value
	return random_body_accessory(species.name, species.optional_body_accessory) || none_value

/datum/preference/choiced/accessory/body_accessory/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	target.body_accessory = GLOB.body_accessory_by_name[value]

#undef SKIN_TONE_MINIMUM
#undef SKIN_TONE_MAXIMUM
