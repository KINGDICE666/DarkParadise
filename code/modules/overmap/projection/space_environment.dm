#define SPACE_ENV_STAR_GAIN 0.9
#define SPACE_ENV_STAR_GLOW 0.28
#define SPACE_ENV_NEBULA_TINT 0.75
#define SPACE_ENV_NEBULA_GLOW 0.22

/atom/movable/screen/parallax_layer
	var/environment_key

/proc/overmap_body_influence(distance, core_radius, outer_radius)
	return clamp(1 - (distance - core_radius) / max(outer_radius - core_radius, 0.1), 0, 1)

/proc/overmap_space_color_matrix(darkness, brightness, list/tint_rgb, tint, list/glow_rgb)
	var/scale = (1 - darkness) * (1 + brightness * SPACE_ENV_STAR_GAIN)
	var/list/channels = list(1, 1, 1)
	for(var/index in 1 to 3)
		channels[index] = round(scale * ((1 - tint) + tint * (tint_rgb ? tint_rgb[index] * 2 : 1)), 0.02)
	var/list/glow = list(0, 0, 0)
	var/glow_alpha = 0
	for(var/index in 1 to 3)
		var/star_part = glow_rgb ? glow_rgb[index] * brightness * SPACE_ENV_STAR_GLOW : 0
		var/nebula_part = tint_rgb ? tint_rgb[index] * tint * SPACE_ENV_NEBULA_GLOW : 0
		glow[index] = round((1 - darkness) * (star_part + nebula_part), 0.01)
		glow_alpha = max(glow_alpha, glow[index])
	return list(channels[1], 0, 0, 0, 0, channels[2], 0, 0, 0, 0, channels[3], 0, 0, 0, 0, 1, glow[1], glow[2], glow[3], glow_alpha ? 1 : 0)

/datum/controller/subsystem/overmap/proc/space_environment(datum/overmap_sector/sector, world_x, world_y)
	var/span = OVERMAP_TILE_SPAN * (sector.tile_travel || 1)
	var/darkness = 0
	var/brightness = 0
	var/list/glow_rgb
	for(var/obj/overmap/celestial/body as anything in GLOB.overmap_celestials)
		if(body.sector != sector || !isturf(body.loc))
			continue
		var/distance = sqrt((world_x - body.x * span) ** 2 + (world_y - body.y * span) ** 2) / span
		var/influence = overmap_body_influence(distance, body.core_radius, body.gravity_radius)
		if(!influence)
			continue
		if(istype(body, /obj/overmap/celestial/black_hole))
			darkness = max(darkness, influence)
		else if(influence > brightness)
			brightness = influence
			glow_rgb = rgb2num(body.map_color || COLOR_WHITE)
			for(var/index in 1 to 3)
				glow_rgb[index] /= 255
	var/list/tint_rgb
	var/tint = 0
	var/turf/cell = sector.turf_at_world(world_x, world_y)
	if(cell)
		for(var/turf/near as anything in RANGE_TURFS(1, cell))
			for(var/obj/overmap/feature/hazard/nebula/field in near)
				if(field.sector != sector)
					continue
				var/strength = min(field.cloud_strength(world_x, world_y), 1) * SPACE_ENV_NEBULA_TINT
				if(strength <= tint)
					continue
				tint = strength
				tint_rgb = rgb2num(field.map_color)
				for(var/index in 1 to 3)
					tint_rgb[index] /= 255
	return overmap_space_color_matrix(darkness, brightness, tint_rgb, tint, glow_rgb)

/datum/controller/subsystem/overmap/proc/process_space_environment()
	for(var/client/viewer as anything in GLOB.clients)
		var/list/layers = viewer.parallax_rock?.parallax_layers
		if(!length(layers))
			continue
		var/turf/eye = get_turf(viewer.eye || viewer.mob)
		var/datum/owner = eye && frame_owner(eye)
		var/datum/overmap_sector/sector = owner && frame_sector(owner)
		var/list/glowing
		var/list/plain
		if(sector)
			var/list/point = frame_to_world(owner, eye)
			glowing = space_environment(sector, point[1], point[2])
			plain = glowing.Copy(1, 17) + list(0, 0, 0, 0)
		var/key = glowing ? jointext(glowing, ",") : ""
		for(var/atom/movable/screen/parallax_layer/layer as anything in layers)
			if(istype(layer, /atom/movable/screen/parallax_layer/planet) && sector)
				layer.SetInvisibility(sector == lavaland_planet?.sector ? INVISIBILITY_NONE : INVISIBILITY_ABSTRACT, id = layer.type)
			if(layer.environment_key == key)
				continue
			layer.environment_key = key
			layer.color = layer == layers[1] ? glowing : plain

#undef SPACE_ENV_STAR_GAIN
#undef SPACE_ENV_STAR_GLOW
#undef SPACE_ENV_NEBULA_TINT
#undef SPACE_ENV_NEBULA_GLOW
