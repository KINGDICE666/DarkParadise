#define HULL_PROXY_SEAM_SCALE 1.03
#define HULL_PROXY_SHADING_SCALE 1.3
#define HULL_PROXY_LIGHT_COPY_INTERVAL (1 SECONDS)
#define HULL_PROXY_LIGHT_LAYER (LIGHTING_PRIMARY_LAYER + 1)
#define HULL_PROXY_SHADE_LAYER (FLOOR_EMISSIVE_START_LAYER - 0.01)
#define HULL_PROXY_GLOW_MIN_RANGE 3
#define HULL_PROXY_GLOW_MAX_RANGE 8
#define HULL_PROXY_GLOW_POWER 0.6
#define HULL_PROXY_GLOW_COLOR "#cfe0ff"

/datum/hull_proxy
	var/obj/overmap/entity/vessel
	var/list/obj/effect/abstract/hull_proxy_tile/carrier/carriers = list()
	var/center_x
	var/center_y
	var/proxy_z
	var/heading
	var/obj/effect/abstract/hull_proxy_glow/glow

/obj/effect/abstract/hull_proxy_tile
	name = "hull proxy tile"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	simulated = FALSE
	animate_movement = NO_STEPS
	vis_flags = VIS_HIDE
	var/base_x = 0
	var/base_y = 0
	var/turf/hull_turf
	var/obj/effect/abstract/hull_proxy_tile/carrier/carrier
	var/obj/effect/abstract/hull_proxy_light/light_mask
	var/obj/effect/abstract/hull_proxy_shade/shade
	var/copied_light_state
	var/list/copied_light_color
	var/corner_mask

/obj/effect/abstract/hull_proxy_tile/carrier
	name = "hull proxy carrier"
	var/chunk_key
	var/list/obj/effect/abstract/hull_proxy_tile/members = list()

/obj/effect/abstract/hull_proxy_light
	name = "hull proxy light"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	simulated = FALSE
	plane = LIGHTING_PLANE
	layer = HULL_PROXY_LIGHT_LAYER
	appearance_flags = RESET_COLOR | RESET_ALPHA

/obj/effect/abstract/hull_proxy_glow
	name = "hull glow"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	simulated = FALSE
	light_color = HULL_PROXY_GLOW_COLOR
	light_power = HULL_PROXY_GLOW_POWER

/obj/effect/abstract/hull_proxy_shade
	name = "hull proxy shade"
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	simulated = FALSE
	plane = EMISSIVE_PLANE
	layer = HULL_PROXY_SHADE_LAYER
	appearance_flags = RESET_COLOR | RESET_ALPHA

/datum/hull_proxy/New(obj/overmap/entity/vessel, turf/viewer_turf, glowing = FALSE)
	src.vessel = vessel
	if(glowing)
		glow = new(null)
		refresh_glow()
	var/list/chunks = list()
	for(var/turf/hull_turf as anything in vessel.hull_turfs)
		var/chunk_x = round(hull_turf.x / OVERMAP_MIRROR_CHUNK) * OVERMAP_MIRROR_CHUNK + 1
		var/chunk_y = round(hull_turf.y / OVERMAP_MIRROR_CHUNK) * OVERMAP_MIRROR_CHUNK + 1
		var/key = "[chunk_x]_[chunk_y]"
		var/obj/effect/abstract/hull_proxy_tile/carrier/carrier = chunks[key]
		if(!carrier)
			carrier = new(null)
			carrier.base_x = (chunk_x - vessel.hull_center_x) * ICON_SIZE_X
			carrier.base_y = (chunk_y - vessel.hull_center_y) * ICON_SIZE_Y
			chunks[key] = carrier
			carriers += carrier
		var/obj/effect/abstract/hull_proxy_tile/tile = new(null)
		tile.base_x = (hull_turf.x - chunk_x) * ICON_SIZE_X
		tile.base_y = (hull_turf.y - chunk_y) * ICON_SIZE_Y
		tile.hull_turf = hull_turf
		tile.vis_contents += hull_turf
		tile.setup_shading(viewer_turf)
		carrier.add_member(tile)
	RegisterSignal(vessel, COMSIG_QDELETING, PROC_REF(on_vessel_deleted))
	addtimer(CALLBACK(src, PROC_REF(refresh_light_copies)), HULL_PROXY_LIGHT_COPY_INTERVAL, TIMER_LOOP|TIMER_DELETE_ME)

/datum/hull_proxy/Destroy(force)
	QDEL_LIST(carriers)
	QDEL_NULL(glow)
	vessel = null
	return ..()

/obj/effect/abstract/hull_proxy_tile/Destroy()
	vis_contents.Cut()
	QDEL_NULL(light_mask)
	QDEL_NULL(shade)
	hull_turf = null
	carrier = null
	copied_light_color = null
	corner_mask = null
	return ..()

/obj/effect/abstract/hull_proxy_tile/carrier/Destroy()
	QDEL_LIST(members)
	return ..()

/obj/effect/abstract/hull_proxy_tile/carrier/proc/add_member(obj/effect/abstract/hull_proxy_tile/tile)
	tile.vis_flags = NONE
	tile.carrier = src
	members += tile
	vis_contents += tile

/obj/effect/abstract/hull_proxy_tile/carrier/proc/remove_member(obj/effect/abstract/hull_proxy_tile/tile)
	members -= tile
	vis_contents -= tile
	tile.carrier = null

/datum/hull_proxy/proc/on_vessel_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/hull_proxy/proc/place(new_center_x, new_center_y, new_z, new_heading, list/bounds, time)
	if(new_center_x == center_x && new_center_y == center_y && new_z == proxy_z && new_heading == heading)
		return
	var/matrix/turned
	if(new_heading != heading || new_z != proxy_z)
		turned = matrix()
		turned.Scale(HULL_PROXY_SEAM_SCALE)
		turned.Turn(new_heading)
	if(new_z != proxy_z)
		time = 0
	center_x = new_center_x
	center_y = new_center_y
	proxy_z = new_z
	heading = new_heading
	var/cos_heading = cos(heading)
	var/sin_heading = sin(heading)
	for(var/obj/effect/abstract/hull_proxy_tile/carrier/carrier as anything in carriers)
		carrier.glide(center_x + (carrier.base_x * cos_heading + carrier.base_y * sin_heading) / ICON_SIZE_X, center_y + (carrier.base_y * cos_heading - carrier.base_x * sin_heading) / ICON_SIZE_Y, proxy_z, null, bounds, time)
		if(!turned)
			continue
		for(var/obj/effect/abstract/hull_proxy_tile/tile as anything in carrier.members)
			tile.shift(tile.base_x * cos_heading + tile.base_y * sin_heading, tile.base_y * cos_heading - tile.base_x * sin_heading, turned, time)
	var/turf/glow_turf = glow && locate(clamp(round(center_x, 1), bounds[1], bounds[3]), clamp(round(center_y, 1), bounds[2], bounds[4]), proxy_z)
	if(glow_turf && glow.loc != glow_turf)
		glow.forceMove(glow_turf)

/obj/effect/abstract/hull_proxy_tile/proc/glide(visual_x, visual_y, target_z, matrix/new_transform, list/bounds, time)
	var/anchor_x = clamp(round(visual_x, 1), bounds[1], bounds[3])
	var/anchor_y = clamp(round(visual_y, 1), bounds[2], bounds[4])
	var/turf/anchor = loc
	if(!anchor || anchor.z != target_z || abs(anchor.x - anchor_x) > 1 || abs(anchor.y - anchor_y) > 1)
		var/turf/new_anchor = locate(anchor_x, anchor_y, target_z)
		if(anchor?.z == target_z)
			pixel_x += (anchor.x - new_anchor.x) * ICON_SIZE_X
			pixel_y += (anchor.y - new_anchor.y) * ICON_SIZE_Y
		else
			time = 0
		forceMove(new_anchor)
		anchor = new_anchor
	shift((visual_x - anchor.x) * ICON_SIZE_X, (visual_y - anchor.y) * ICON_SIZE_Y, new_transform, time)

/obj/effect/abstract/hull_proxy_tile/proc/shift(offset_x, offset_y, matrix/new_transform, time)
	if(!time)
		pixel_x = offset_x
		pixel_y = offset_y
		if(new_transform)
			transform = new_transform
		return
	if(new_transform)
		animate(src, pixel_x = offset_x, pixel_y = offset_y, transform = new_transform, time = time)
		return
	animate(src, pixel_x = offset_x, pixel_y = offset_y, time = time)

/obj/effect/abstract/hull_proxy_tile/proc/setup_shading(turf/viewer_turf)
	var/matrix/shading_scale = matrix()
	shading_scale.Scale(HULL_PROXY_SHADING_SCALE)
	corner_mask = null
	if((hull_turf.smooth & SMOOTH_DIAGONAL_CORNERS) && length(hull_turf.underlays))
		corner_mask = filter(type = "alpha", icon = icon(hull_turf.icon, hull_turf.icon_state))
	if(!shade)
		shade = new(src)
		SET_PLANE_EXPLICIT(shade, EMISSIVE_PLANE, viewer_turf)
		shade.color = GLOB.em_block_color
		shade.transform = shading_scale
	shade.filters = corner_mask
	vis_contents += shade
	if(!hull_turf.lighting_object)
		QDEL_NULL(light_mask)
		return
	if(!light_mask)
		light_mask = new(src)
		SET_PLANE_EXPLICIT(light_mask, LIGHTING_PLANE, viewer_turf)
		light_mask.transform = shading_scale
	copied_light_state = null
	copied_light_color = null
	copy_light()
	vis_contents += light_mask

/obj/effect/abstract/hull_proxy_tile/proc/copy_light()
	var/atom/movable/lighting_object/source_light = hull_turf.lighting_object
	if(!light_mask || !source_light)
		return
	var/list/light_color = source_light.color
	if(copied_light_state == source_light.icon_state && copied_light_color ~= light_color)
		return
	copied_light_state = source_light.icon_state
	copied_light_color = light_color
	var/mutable_appearance/light_copy = new(source_light)
	light_copy.plane = light_mask.plane
	light_copy.layer = HULL_PROXY_LIGHT_LAYER
	light_copy.appearance_flags = RESET_COLOR | RESET_ALPHA
	light_copy.invisibility = 0
	light_copy.transform = light_mask.transform
	if(corner_mask)
		light_copy.filters = corner_mask
	light_mask.appearance = light_copy

/datum/hull_proxy/proc/refresh_light_copies()
	for(var/obj/effect/abstract/hull_proxy_tile/carrier/carrier as anything in carriers)
		for(var/obj/effect/abstract/hull_proxy_tile/tile as anything in carrier.members)
			tile.copy_light()
	refresh_glow()

/datum/hull_proxy/proc/refresh_glow()
	if(!glow)
		return
	var/lit = FALSE
	for(var/area/place as anything in vessel.shuttle?.shuttle_areas)
		if(place.powered(LIGHT))
			lit = TRUE
			break
	var/glow_range = lit ? clamp(round(vessel.hull_radius) + 2, HULL_PROXY_GLOW_MIN_RANGE, HULL_PROXY_GLOW_MAX_RANGE) : 0
	if(glow.light_range != glow_range)
		glow.set_light_range(glow_range)

#undef HULL_PROXY_SEAM_SCALE
#undef HULL_PROXY_SHADING_SCALE
#undef HULL_PROXY_LIGHT_COPY_INTERVAL
#undef HULL_PROXY_LIGHT_LAYER
#undef HULL_PROXY_SHADE_LAYER
#undef HULL_PROXY_GLOW_MIN_RANGE
#undef HULL_PROXY_GLOW_MAX_RANGE
#undef HULL_PROXY_GLOW_POWER
#undef HULL_PROXY_GLOW_COLOR
