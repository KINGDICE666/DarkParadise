/datum/preference_middleware/species

/datum/preference_middleware/species/get_ui_assets()
	return list(get_asset_datum(/datum/asset/spritesheet_batched/species))

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
		insert_icon(sanitize_css_class_name("[species.type]"), dummy_icon)

		qdel(dummy)
