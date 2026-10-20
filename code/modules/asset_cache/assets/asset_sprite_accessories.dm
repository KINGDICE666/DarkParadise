#define ACCESSORY_PREVIEW_CROP_X1 9
#define ACCESSORY_PREVIEW_CROP_Y1 17
#define ACCESSORY_PREVIEW_CROP_X2 24
#define ACCESSORY_PREVIEW_CROP_Y2 32
#define ACCESSORY_PREVIEW_LEGS_X1 10
#define ACCESSORY_PREVIEW_LEGS_Y1 1
#define ACCESSORY_PREVIEW_LEGS_X2 22
#define ACCESSORY_PREVIEW_LEGS_Y2 13
#define ACCESSORY_PREVIEW_TORSO_X1 9
#define ACCESSORY_PREVIEW_TORSO_Y1 9
#define ACCESSORY_PREVIEW_TORSO_X2 23
#define ACCESSORY_PREVIEW_TORSO_Y2 23
#define ACCESSORY_PREVIEW_COLOR COLOR_DARK_BROWN
#define ACCESSORY_PREVIEW_SKIN_COLOR "#b07d5c"
#define ACCESSORY_PREVIEW_GRADIENT_HAIR "Long Hair"

/datum/asset/spritesheet_batched/sprite_accessories
	name = "sprite_accessories"
	ignore_dir_errors = TRUE
	var/list/preview_keys = list()

/datum/asset/spritesheet_batched/sprite_accessories/create_spritesheets()
	for(var/category in list(ACCESSORY_CATEGORY_HAIR, ACCESSORY_CATEGORY_FACIAL_HAIR, ACCESSORY_CATEGORY_HEAD_ACCESSORY, ACCESSORY_CATEGORY_HAIR_GRADIENT, ACCESSORY_CATEGORY_MARKING, ACCESSORY_CATEGORY_ALT_HEAD, ACCESSORY_CATEGORY_BODY_ACCESSORY, ACCESSORY_CATEGORY_UNDERWEAR, ACCESSORY_CATEGORY_UNDERSHIRT, ACCESSORY_CATEGORY_SOCKS))
		for(var/style in get_style_list(category))
			insert_preview(category, style, build_preview(category, style))

/datum/asset/spritesheet_batched/sprite_accessories/proc/get_style_list(category)
	switch(category)
		if(ACCESSORY_CATEGORY_HAIR)
			return SSaccessories.hairstyles_list
		if(ACCESSORY_CATEGORY_FACIAL_HAIR)
			return SSaccessories.facial_hairstyles_list
		if(ACCESSORY_CATEGORY_HEAD_ACCESSORY)
			return SSaccessories.head_accessory_list
		if(ACCESSORY_CATEGORY_HAIR_GRADIENT)
			return SSaccessories.hair_gradients_list
		if(ACCESSORY_CATEGORY_MARKING)
			return SSaccessories.body_markings_list
		if(ACCESSORY_CATEGORY_ALT_HEAD)
			return SSaccessories.alt_heads_list
		if(ACCESSORY_CATEGORY_BODY_ACCESSORY)
			return GLOB.body_accessory_by_name
		if(ACCESSORY_CATEGORY_UNDERWEAR)
			return SSaccessories.underwear_list
		if(ACCESSORY_CATEGORY_UNDERSHIRT)
			return SSaccessories.undershirt_list
		if(ACCESSORY_CATEGORY_SOCKS)
			return SSaccessories.socks_list
	return list()

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_preview(category, style_name)
	var/accessory = get_style_list(category)[style_name]
	switch(category)
		if(ACCESSORY_CATEGORY_HAIR, ACCESSORY_CATEGORY_FACIAL_HAIR, ACCESSORY_CATEGORY_HEAD_ACCESSORY)
			return build_head_preview(accessory)
		if(ACCESSORY_CATEGORY_HAIR_GRADIENT)
			return build_gradient_preview(accessory)
		if(ACCESSORY_CATEGORY_MARKING)
			var/datum/sprite_accessory/body_markings/marking = accessory
			return marking?.marking_location == "head" ? build_head_preview(marking) : build_body_preview(marking)
		if(ACCESSORY_CATEGORY_ALT_HEAD)
			return build_alt_head_preview(accessory)
		if(ACCESSORY_CATEGORY_BODY_ACCESSORY)
			return build_body_accessory_preview(accessory)
		if(ACCESSORY_CATEGORY_UNDERWEAR)
			return crop_to_legs(build_undergarment_preview(accessory, "uw"))
		if(ACCESSORY_CATEGORY_UNDERSHIRT)
			return crop_to_torso(build_undergarment_preview(accessory, "us"))
		if(ACCESSORY_CATEGORY_SOCKS)
			return crop_to_legs(build_undergarment_preview(accessory, "sk"))

/datum/asset/spritesheet_batched/sprite_accessories/proc/get_preview_key(category, style_name)
	var/list/category_keys = preview_keys[category]
	return category_keys?[style_name]

/datum/asset/spritesheet_batched/sprite_accessories/proc/insert_preview(category, style_name, datum/universal_icon/preview)
	if(!preview)
		return
	var/list/category_keys = preview_keys[category]
	if(!category_keys)
		category_keys = list()
		preview_keys[category] = category_keys
	var/key = "[category]_[length(category_keys)]"
	category_keys[style_name] = key
	insert_icon(key, preview)

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_head_preview(datum/sprite_accessory/accessory)
	var/datum/universal_icon/preview = build_species_head(accessory?.species_allowed)
	var/datum/universal_icon/layer = build_accessory_layer(accessory)
	if(layer)
		preview.blend_icon(layer, ICON_OVERLAY)
	return crop_to_head(preview)

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_gradient_preview(datum/sprite_accessory/gradient/gradient)
	var/datum/sprite_accessory/hair/reference = SSaccessories.hairstyles_list[ACCESSORY_PREVIEW_GRADIENT_HAIR]
	var/datum/universal_icon/preview = build_species_head(list(SPECIES_HUMAN))
	var/datum/universal_icon/hair = build_accessory_layer(reference)
	if(!hair)
		return crop_to_head(preview)

	preview.blend_icon(hair, ICON_OVERLAY)
	if(gradient && icon_exists(gradient.icon, gradient.icon_state))
		var/datum/universal_icon/tint = uni_icon(gradient.icon, "full")
		tint.blend_icon(uni_icon(gradient.icon, gradient.icon_state), ICON_AND)
		tint.blend_icon(uni_icon(reference.icon, "[reference.icon_state]_s"), ICON_AND)
		preview.blend_icon(tint, ICON_OVERLAY)
	return crop_to_head(preview)

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_body_preview(datum/sprite_accessory/accessory)
	var/datum/universal_icon/preview = build_naked_body()
	var/datum/universal_icon/layer = build_accessory_layer(accessory)
	if(layer)
		preview.blend_icon(layer, ICON_OVERLAY)
	return preview

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_alt_head_preview(datum/sprite_accessory/alt_heads/alt_head)
	var/datum/universal_icon/preview = build_species_head(alt_head?.species_allowed, alt_head?.icon_state || "head")
	return crop_to_head(preview)

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_body_accessory_preview(datum/body_accessory/accessory)
	var/datum/universal_icon/preview = build_naked_body(WEST)
	if(!accessory || !icon_exists(accessory.icon, accessory.icon_state))
		return preview
	var/datum/universal_icon/layer = uni_icon(accessory.icon, accessory.icon_state, WEST)
	if(!isnull(accessory.blend_mode))
		layer.blend_color(ACCESSORY_PREVIEW_SKIN_COLOR, accessory.blend_mode)
	preview.blend_icon(layer, ICON_OVERLAY)
	return preview

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_undergarment_preview(datum/sprite_accessory/accessory, prefix)
	var/datum/universal_icon/preview = build_naked_body()
	var/state = "[prefix]_[accessory?.icon_state]_s"
	if(accessory && icon_exists(accessory.icon, state))
		preview.blend_icon(uni_icon(accessory.icon, state), ICON_OVERLAY)
	return preview

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_accessory_layer(datum/sprite_accessory/accessory)
	var/state = "[accessory?.icon_state]_s"
	if(!accessory || !icon_exists(accessory.icon, state))
		return
	var/datum/universal_icon/layer = uni_icon(accessory.icon, state)
	if(accessory.do_colouration)
		layer.blend_color(ACCESSORY_PREVIEW_COLOR, ICON_MULTIPLY)
	return layer

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_naked_body(facing = SOUTH)
	var/static/list/body_states = list("torso_m", "groin_m", "head_m", "l_arm", "r_arm", "l_hand", "r_hand", "l_leg", "r_leg", "l_foot", "r_foot")
	var/datum/species/human = GLOB.all_species[SPECIES_HUMAN]
	var/datum/universal_icon/body = uni_icon(human.icobase, body_states[1], facing)
	for(var/state in body_states.Copy(2))
		body.blend_icon(uni_icon(human.icobase, state, facing), ICON_OVERLAY)
	return body

/datum/asset/spritesheet_batched/sprite_accessories/proc/build_species_head(list/species_allowed, head_state = "head")
	var/species_name = SPECIES_HUMAN
	if(length(species_allowed) && !(SPECIES_HUMAN in species_allowed))
		species_name = species_allowed[1]
	var/datum/species/species = GLOB.all_species[species_name] || GLOB.all_species[SPECIES_HUMAN]
	var/state = "[head_state]_m"
	if(!icon_exists(species.icobase, state))
		species = GLOB.all_species[SPECIES_HUMAN]
		state = "head_m"
	return uni_icon(species.icobase, state)

/datum/asset/spritesheet_batched/sprite_accessories/proc/crop_to_head(datum/universal_icon/preview)
	preview.crop(ACCESSORY_PREVIEW_CROP_X1, ACCESSORY_PREVIEW_CROP_Y1, ACCESSORY_PREVIEW_CROP_X2, ACCESSORY_PREVIEW_CROP_Y2)
	preview.scale(ICON_SIZE_X, ICON_SIZE_Y)
	return preview

/datum/asset/spritesheet_batched/sprite_accessories/proc/crop_to_legs(datum/universal_icon/preview)
	preview.crop(ACCESSORY_PREVIEW_LEGS_X1, ACCESSORY_PREVIEW_LEGS_Y1, ACCESSORY_PREVIEW_LEGS_X2, ACCESSORY_PREVIEW_LEGS_Y2)
	preview.scale(ICON_SIZE_X, ICON_SIZE_Y)
	return preview

/datum/asset/spritesheet_batched/sprite_accessories/proc/crop_to_torso(datum/universal_icon/preview)
	preview.crop(ACCESSORY_PREVIEW_TORSO_X1, ACCESSORY_PREVIEW_TORSO_Y1, ACCESSORY_PREVIEW_TORSO_X2, ACCESSORY_PREVIEW_TORSO_Y2)
	preview.scale(ICON_SIZE_X, ICON_SIZE_Y)
	return preview

#undef ACCESSORY_PREVIEW_CROP_X1
#undef ACCESSORY_PREVIEW_CROP_Y1
#undef ACCESSORY_PREVIEW_CROP_X2
#undef ACCESSORY_PREVIEW_CROP_Y2
#undef ACCESSORY_PREVIEW_LEGS_X1
#undef ACCESSORY_PREVIEW_LEGS_Y1
#undef ACCESSORY_PREVIEW_LEGS_X2
#undef ACCESSORY_PREVIEW_LEGS_Y2
#undef ACCESSORY_PREVIEW_TORSO_X1
#undef ACCESSORY_PREVIEW_TORSO_Y1
#undef ACCESSORY_PREVIEW_TORSO_X2
#undef ACCESSORY_PREVIEW_TORSO_Y2
#undef ACCESSORY_PREVIEW_COLOR
#undef ACCESSORY_PREVIEW_SKIN_COLOR
#undef ACCESSORY_PREVIEW_GRADIENT_HAIR
