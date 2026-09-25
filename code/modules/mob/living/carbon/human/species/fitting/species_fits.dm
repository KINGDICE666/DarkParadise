/datum/species_fit/swine
	target_sheet = 'icons/mob/human_races/r_swine.dmi'
	pixel_map = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-trottine.json'
	blocked_sheets = list(
		DEFAULT_ICON_WEAR_MASK,
		'icons/goonstation/mob/clothing/mask.dmi',
	)

/datum/species_fit/vox
	target_sheet = 'icons/mob/human_races/vox/r_vox.dmi'
	bare_parts = list(list("l_hand", "r_hand"), list("l_foot", "r_foot"))

/datum/species_fit/drask
	target_sheet = 'icons/mob/human_races/r_drask.dmi'
	bare_parts = list(list("l_hand", "r_hand"), list("l_foot", "r_foot"))

/datum/species_fit/unathi
	target_sheet = 'icons/mob/human_races/r_lizard.dmi'
	bare_parts = list(list("l_foot", "r_foot"))

/datum/species_fit/golem
	target_sheet = 'icons/mob/human_races/r_golem.dmi'

/datum/species_fit/skrell
	target_sheet = 'icons/mob/human_races/r_skrell.dmi'

/datum/species_fit/slime
	target_sheet = 'icons/mob/human_races/r_slime.dmi'

/datum/species_fit/shadow
	target_sheet = 'icons/mob/human_races/r_shadow.dmi'

/datum/species_fit/abductor
	target_sheet = 'icons/mob/human_races/r_abductor.dmi'

/datum/species_fit/resomi
	target_sheet = 'icons/mob/human_races/r_resomi.dmi'
	pixel_map = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi.json'
	headwear_hides_hair = TRUE
	sheet_pixel_maps = list(
		DEFAULT_ICON_JUMPSUIT = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/uniform.json',
		DEFAULT_ICON_OUTER_SUIT = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/suit.json',
		DEFAULT_ICON_HEAD = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/head.json',
		DEFAULT_ICON_WEAR_MASK = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/mask.json',
		DEFAULT_ICON_GLASSES = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/eyes.json',
		DEFAULT_ICON_LEFT_EAR = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/ears.json',
		DEFAULT_ICON_GLOVES = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/hands.json',
		DEFAULT_ICON_SHOES = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/feet.json',
		DEFAULT_ICON_BACK = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/back.json',
		DEFAULT_ICON_BELT = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/belt.json',
		DEFAULT_ICON_SUITSTORE = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/belt.json',
		DEFAULT_ICON_NECK = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/neck.json',
		DEFAULT_ICON_COLLAR = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/neck.json',
		DEFAULT_ICON_ACCESSORY = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/ties.json',
		'icons/mob/clothing/underwear.dmi' = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/uniform.json',
	)
	slot_pixel_maps = list(
		ITEM_SLOT_CLOTH_INNER_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/uniform.json',
		ITEM_SLOT_CLOTH_OUTER_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/suit.json',
		ITEM_SLOT_HEAD_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/head.json',
		ITEM_SLOT_MASK_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/mask.json',
		ITEM_SLOT_EYES_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/eyes.json',
		ITEM_SLOT_EAR_LEFT_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/ears.json',
		ITEM_SLOT_EAR_RIGHT_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/ears.json',
		ITEM_SLOT_GLOVES_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/hands.json',
		ITEM_SLOT_FEET_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/feet.json',
		ITEM_SLOT_BACK_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/back.json',
		ITEM_SLOT_BELT_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/belt.json',
		ITEM_SLOT_SUITSTORE_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/belt.json',
		ITEM_SLOT_NECK_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/neck.json',
		ITEM_SLOT_COLLAR_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/neck.json',
		ITEM_SLOT_ACCESSORY_STRING = 'code/modules/mob/living/carbon/human/species/fitting/maps/human-to-resomi/ties.json',
	)
	steps = list(
		/datum/fit_step/pixel_map,
		/datum/fit_step/cover_parts,
		/datum/fit_step/cover_parts/extremities,
	)
	slot_steps = list(
		ITEM_SLOT_HEAD_STRING = list(/datum/fit_step/head_offset),
		ITEM_SLOT_FEET_STRING = list(/datum/fit_step/foot_fit),
	)
