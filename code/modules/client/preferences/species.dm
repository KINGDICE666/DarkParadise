/datum/preference/choiced/species
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "species"
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	priority = PREFERENCE_PRIORITY_SPECIES
	randomize_by_default = FALSE

/datum/preference/choiced/species/init_possible_values()
	return assoc_to_keys(GLOB.all_species)

/datum/preference/choiced/species/get_valid_choices(datum/preferences/preferences)
	if(!preferences.parent || check_rights_for(preferences.parent, R_ADMIN))
		return get_choices()
	var/list/values = list(SPECIES_HUMAN)
	for(var/species_name in CONFIG_GET(str_list/playable_species))
		if(GLOB.all_species[species_name])
			values |= species_name
	return values

/datum/preference/choiced/species/deserialize(input, datum/preferences/preferences)
	return sanitize_inlist(input, get_choices(), create_default_value())

/datum/preference/choiced/species/create_default_value()
	return SPECIES_HUMAN

/datum/preference/choiced/species/create_random_value(datum/preferences/preferences)
	return pick(get_valid_choices(preferences))

/datum/preference/choiced/species/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/datum/species/species = GLOB.all_species[value]
	target.set_species(species.type)

/datum/preference/choiced/species/compile_constant_data()
	var/list/data = list()
	for(var/species_name in get_choices())
		var/datum/species/species = GLOB.all_species[species_name]
		data[species_name] = list(
			"name" = species.name,
			"desc" = species.blurb,
			"icon" = sanitize_css_class_name(species_name),
			"has_gender" = species.has_gender,
		)
	return data

/datum/asset/spritesheet_batched/species
	name = "species"

/datum/asset/spritesheet_batched/species/create_spritesheets()
	for(var/species_name in GLOB.all_species)
		var/datum/species/species = GLOB.all_species[species_name]
		var/mob/living/carbon/human/dummy/dummy = new
		dummy.set_species(species.type)
		dummy.equipOutfit(/datum/outfit/job/assistant, visualsOnly = TRUE)
		dummy.regenerate_icons()

		var/datum/universal_icon/dummy_icon = get_flat_uni_icon(dummy)
		dummy_icon.scale(64, 64)
		dummy_icon.crop(15, 64 - 31, 15 + 31, 64)
		dummy_icon.scale(64, 64)
		insert_icon(sanitize_css_class_name(species_name), dummy_icon)

		qdel(dummy)
