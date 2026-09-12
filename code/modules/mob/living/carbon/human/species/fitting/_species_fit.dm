#define FIT_SKIP "fit_skip"
#define FIT_DEFAULT_SIZE 32

GLOBAL_LIST_EMPTY(species_fits)

/proc/get_species_fit(fit_type)
	RETURN_TYPE(/datum/species_fit)
	if(!ispath(fit_type, /datum/species_fit))
		return null
	var/datum/species_fit/fit = GLOB.species_fits[fit_type]
	if(!fit)
		fit = new fit_type
		GLOB.species_fits[fit_type] = fit
	return fit

/datum/species_fit
	var/reference_sheet = 'icons/mob/human_races/r_human.dmi'
	var/target_sheet
	var/list/trunk_states = list("torso_m", "groin_m")
	var/list/limb_states = list("l_arm", "r_arm", "l_hand", "r_hand", "l_leg", "r_leg", "l_foot", "r_foot")
	var/list/head_states = list("head_m")
	var/list/steps = list(
		/datum/fit_step/mark_bare_skin,
		/datum/fit_step/warp,
		/datum/fit_step/edge_repair,
		/datum/fit_step/vertical_warp,
		/datum/fit_step/cover_skin,
		/datum/fit_step/keep_solid,
		/datum/fit_step/trim,
	)
	var/list/manual_sheets
	var/list/blocked_sheets
	var/list/item_overrides
	var/width = FIT_DEFAULT_SIZE
	var/height = FIT_DEFAULT_SIZE
	var/list/reference_trunk_masks
	var/list/reference_body_masks
	var/list/target_trunk_masks
	var/list/target_body_masks
	var/list/warp_maps
	var/list/row_maps
	var/list/shrunk_masks
	var/list/step_instances
	var/list/icon_cache
	var/built = FALSE

/datum/species_fit/New()
	icon_cache = list()
	step_instances = list()
	for(var/step_type in steps)
		step_instances += new step_type

/datum/species_fit/proc/build()
	if(built)
		return
	built = TRUE
	reference_trunk_masks = list()
	reference_body_masks = list()
	target_trunk_masks = list()
	target_body_masks = list()
	warp_maps = list()
	row_maps = list()
	shrunk_masks = list()
	for(var/fit_dir in GLOB.cardinal)
		var/key = "[fit_dir]"
		reference_trunk_masks[key] = build_mask(reference_sheet, trunk_states, fit_dir)
		reference_body_masks[key] = build_mask(reference_sheet, trunk_states + limb_states, fit_dir)
		target_trunk_masks[key] = build_mask(target_sheet, trunk_states, fit_dir)
		target_body_masks[key] = build_mask(target_sheet, trunk_states + limb_states, fit_dir)
		warp_maps[key] = build_warp_map(fit_dir)
		row_maps[key] = build_row_map(fit_dir)
		shrunk_masks[key] = build_shrunk_mask(fit_dir)

/datum/species_fit/proc/build_mask(sheet, list/state_names, fit_dir)
	var/list/mask = new(width * height)
	for(var/state_name in state_names)
		if(!icon_exists(sheet, state_name))
			continue
		var/icon/frame = icon(sheet, state_name, fit_dir)
		for(var/y in 1 to height)
			var/row_offset = width * (y - 1)
			for(var/x in 1 to width)
				if(!isnull(frame.GetPixel(x, y)))
					mask[row_offset + x] = TRUE
	return mask

/datum/species_fit/proc/build_warp_map(fit_dir)
	var/key = "[fit_dir]"
	var/list/reference_trunk = reference_trunk_masks[key]
	var/list/reference_body = reference_body_masks[key]
	var/list/target_trunk = target_trunk_masks[key]
	var/list/target_body = target_body_masks[key]
	var/list/map = new(width * height)
	for(var/y in 1 to height)
		var/row_offset = width * (y - 1)
		var/list/trunk_columns = list()
		var/list/body_columns = list()
		for(var/x in 1 to width)
			if(reference_trunk[row_offset + x])
				trunk_columns += x
			if(reference_body[row_offset + x])
				body_columns += x
		for(var/x in 1 to width)
			var/index = row_offset + x
			if(target_trunk[index] && length(trunk_columns))
				map[index] = nearest_line(trunk_columns, x)
			else if(target_body[index] && length(body_columns))
				map[index] = nearest_line(body_columns, x)
			else
				map[index] = x
	return map

/datum/species_fit/proc/build_row_map(fit_dir)
	var/key = "[fit_dir]"
	var/list/reference_trunk = reference_trunk_masks[key]
	var/list/reference_body = reference_body_masks[key]
	var/list/target_trunk = target_trunk_masks[key]
	var/list/target_body = target_body_masks[key]
	var/list/map = new(width * height)
	for(var/x in 1 to width)
		var/list/trunk_rows = list()
		var/list/body_rows = list()
		for(var/y in 1 to height)
			var/index = width * (y - 1) + x
			if(reference_trunk[index])
				trunk_rows += y
			if(reference_body[index])
				body_rows += y
		for(var/y in 1 to height)
			var/index = width * (y - 1) + x
			var/list/rows = target_trunk[index] ? trunk_rows : (target_body[index] ? body_rows : null)
			if(!length(rows) || (y >= rows[1] && y <= rows[length(rows)]))
				continue
			map[index] = nearest_line(rows, y)
	return map

/datum/species_fit/proc/build_shrunk_mask(fit_dir)
	var/list/reference_full = build_mask(reference_sheet, trunk_states + limb_states + head_states, fit_dir)
	var/list/target_full = build_mask(target_sheet, trunk_states + limb_states + head_states, fit_dir)
	var/list/mask = new(width * height)
	for(var/index in 1 to width * height)
		mask[index] = reference_full[index] && !target_full[index]
	return mask

/datum/species_fit/proc/nearest_line(list/lines, line)
	var/best = line
	var/best_distance = INFINITY
	for(var/candidate in lines)
		var/distance = abs(candidate - line)
		if(distance < best_distance)
			best = candidate
			best_distance = distance
	return best

/proc/get_fitted_worn_icon(datum/species/wearer_species, obj/item/clothing_item, sheet, state_name)
	RETURN_TYPE(/icon)
	if(!wearer_species || wearer_species.worn_sheets?[sheet])
		return null
	var/datum/species_fit/species_fit = get_species_fit(wearer_species.fit_profile)
	return species_fit?.fit_worn_icon(clothing_item, sheet, state_name)

/proc/worn_preview_icon(datum/species/preview_species, sheet, state_name)
	RETURN_TYPE(/icon)
	var/icon/fitted = get_fitted_worn_icon(preview_species, null, sheet, state_name)
	if(fitted)
		return new /icon(fitted)
	return new /icon(preview_species?.worn_sheets?[sheet] || sheet, state_name)

/proc/get_worn_icon_source(mob/living/carbon/human/wearer, obj/item/clothing_item, sheet, state_name)
	var/datum/species/wearer_species = wearer.dna?.species
	if(clothing_item.sprite_sheets?[wearer_species?.name])
		return "sprite_sheets"
	if(wearer_species?.worn_sheets?[sheet])
		return "worn_sheets"
	var/datum/species_fit/species_fit = get_species_fit(wearer_species?.fit_profile)
	return species_fit ? species_fit.describe_source(clothing_item, sheet, state_name) : "vanilla"

/datum/species_fit/proc/describe_source(obj/item/clothing_item, sheet, state_name)
	var/override_sheet = get_item_override(clothing_item)
	if(override_sheet == FIT_SKIP)
		return "override skip"
	if(override_sheet)
		return "override sheet"
	if(sheet in blocked_sheets)
		return "blocked"
	var/manual_sheet = manual_sheets?[sheet]
	if(manual_sheet && icon_exists(manual_sheet, state_name))
		return "manual patch"
	return fit_worn_icon(clothing_item, sheet, state_name) ? "generated" : "vanilla"

/datum/species_fit/proc/get_item_override(obj/item/clothing_item)
	if(!length(item_overrides) || !clothing_item)
		return null
	for(var/override_type in item_overrides)
		if(istype(clothing_item, override_type))
			return item_overrides[override_type]
	return null

/datum/species_fit/proc/fit_worn_icon(obj/item/clothing_item, sheet, state_name)
	if(!target_sheet || !state_name)
		return null
	if(!isfile(sheet))
		return null
	if(sheet in blocked_sheets)
		return null
	var/override_sheet = get_item_override(clothing_item)
	if(override_sheet == FIT_SKIP)
		return null
	if(override_sheet)
		return icon_exists(override_sheet, state_name) ? icon(override_sheet, state_name) : null
	var/cache_key = "[sheet]|[state_name]"
	var/cached = icon_cache[cache_key]
	if(cached)
		return cached == FIT_SKIP ? null : cached
	var/manual_sheet = manual_sheets?[sheet]
	var/icon/fitted
	if(manual_sheet && icon_exists(manual_sheet, state_name))
		fitted = icon(manual_sheet, state_name)
	else if(icon_exists(sheet, state_name))
		fitted = build_fitted_icon(sheet, state_name)
	icon_cache[cache_key] = fitted || FIT_SKIP
	return fitted

/datum/species_fit/proc/build_fitted_icon(sheet, state_name)
	build()
	var/icon/assembled = icon('icons/effects/effects.dmi', "nothing")
	var/fitted_anything = FALSE
	for(var/fit_dir in GLOB.cardinal)
		var/icon/frame = icon(sheet, state_name, fit_dir)
		if(frame.Width() != width || frame.Height() != height)
			return null
		var/datum/fit_context/context = new(src, fit_dir, read_frame(frame))
		for(var/datum/fit_step/step in step_instances)
			step.apply(context)
		if(context.changed())
			fitted_anything = TRUE
		assembled.Insert(write_frame(context.working), dir = fit_dir)
	return fitted_anything ? assembled : null

/datum/species_fit/proc/read_frame(icon/frame)
	var/list/pixels = new(width * height)
	for(var/y in 1 to height)
		var/row_offset = width * (y - 1)
		for(var/x in 1 to width)
			pixels[row_offset + x] = frame.GetPixel(x, y)
	return pixels

/datum/species_fit/proc/write_frame(list/pixels)
	var/icon/frame = icon('icons/effects/effects.dmi', "nothing")
	for(var/y in 1 to height)
		var/row_offset = width * (y - 1)
		for(var/x in 1 to width)
			var/pixel = pixels[row_offset + x]
			if(pixel)
				frame.DrawBox(pixel, x, y)
	return frame

/datum/fit_context
	var/datum/species_fit/profile
	var/fit_dir
	var/width
	var/height
	var/list/source
	var/list/working
	var/list/warp_map
	var/list/row_map
	var/list/dirty_rows

/datum/fit_context/New(datum/species_fit/profile, fit_dir, list/pixels)
	src.profile = profile
	src.fit_dir = fit_dir
	width = profile.width
	height = profile.height
	source = pixels
	working = pixels.Copy()
	warp_map = profile.warp_maps["[fit_dir]"]
	row_map = profile.row_maps["[fit_dir]"]

/datum/fit_context/proc/changed()
	for(var/index in 1 to length(working))
		if(working[index] != source[index])
			return TRUE
	return FALSE

/datum/fit_context/proc/reference_mask()
	return profile.reference_body_masks["[fit_dir]"]

/datum/fit_context/proc/target_mask()
	return profile.target_body_masks["[fit_dir]"]

/datum/fit_context/proc/shrunk_mask()
	return profile.shrunk_masks["[fit_dir]"]

#undef FIT_DEFAULT_SIZE
