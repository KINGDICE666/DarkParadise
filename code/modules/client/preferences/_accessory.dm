/datum/preference/choiced/accessory
	abstract_type = /datum/preference/choiced/accessory
	savefile_identifier = PREFERENCE_CHARACTER
	priority = PREFERENCE_PRIORITY_APPEARANCE
	var/accessory_category
	var/none_value = "None"

/datum/preference/choiced/accessory/proc/get_accessory_list()
	RETURN_TYPE(/list)
	CRASH("`get_accessory_list()` was not implemented for [type]!")

/datum/preference/choiced/accessory/init_possible_values()
	var/list/values = assoc_to_keys(get_accessory_list())
	values |= none_value
	return values

/datum/preference/choiced/accessory/create_default_value()
	return none_value

/datum/preference/choiced/accessory/compile_constant_data()
	var/list/data = ..()
	var/datum/asset/spritesheet_batched/sprite_accessories/sheet = get_asset_datum(/datum/asset/spritesheet_batched/sprite_accessories)
	var/list/icons = list()
	for(var/choice in get_choices())
		icons[choice] = sheet.get_preview_key(accessory_category, choice)
	data["icons"] = icons
	data["icon_sheet"] = "[sheet.name][ICON_SIZE_X]x[ICON_SIZE_Y]"
	return data

/datum/preferences/proc/get_robohead()
	RETURN_TYPE(/datum/robolimb)
	var/datum/species/species = get_species_prototype()
	if(!(species.bodyflags & ALL_RPARTS))
		return
	return GLOB.all_robolimbs[rlimb_data["head"] || "Morpheus Cyberkinetics"]

/datum/preferences/proc/get_head_organ(mob/living/carbon/human/target)
	RETURN_TYPE(/obj/item/organ/external/head)
	return target.get_organ(BODY_ZONE_HEAD)
