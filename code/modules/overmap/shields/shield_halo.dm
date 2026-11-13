#define SHIELD_HALO_INNER_ALPHA 90
#define SHIELD_HALO_OUTER_ALPHA 40
#define SHIELD_HALO_FLASH_ALPHA 200
#define SHIELD_HALO_REFRESH (10 SECONDS)
#define SHIELD_HALO_FLASH_COOLDOWN (1 SECONDS)

/obj/effect/abstract/ship_shield_halo
	name = "shield"
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	color = "#5fb8ff"
	alpha = 0
	anchored = TRUE
	simulated = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_ALPHA | KEEP_APART
	var/base_alpha = SHIELD_HALO_INNER_ALPHA

/obj/effect/abstract/ship_shield_halo/Initialize(mapload)
	. = ..()
	SET_PLANE_IMPLICIT(src, ABOVE_LIGHTING_PLANE)

/obj/overmap/entity
	var/list/obj/effect/abstract/ship_shield_halo/shield_halo_tiles
	var/shield_halo_key
	var/shield_halo_fraction = -1
	var/shield_halo_refresh_at = 0
	var/list/station_halo_cache
	var/shield_halo_flash_at = 0

/obj/overmap/entity/Destroy()
	QDEL_LIST(shield_halo_tiles)
	return ..()

/obj/overmap/entity/proc/shield_halo_hull()
	if(shuttle)
		return shuttle.overmap_collect_hull(get_turf(shuttle))
	if(src != SSovermap.station_entity)
		return null
	if(!station_halo_cache)
		station_halo_cache = list()
		for(var/area/place as anything in SSmapping.existing_station_areas)
			for(var/turf/spot in place)
				if(isspaceturf(spot))
					continue
				for(var/direction in GLOB.alldirs)
					if(isspaceturf(get_step(spot, direction)))
						station_halo_cache += spot
						break
			CHECK_TICK
	return station_halo_cache

/obj/overmap/entity/proc/shield_halo_key()
	if(shuttle)
		var/turf/anchor = get_turf(shuttle)
		return "[anchor?.x]:[anchor?.y]:[anchor?.z]:[hull_version]"
	return src == SSovermap.station_entity ? "station" : null

/obj/overmap/entity/proc/build_shield_halo()
	var/key = shield_halo_key
	var/list/hull = shield_halo_hull()
	if(!length(hull) || QDELETED(src) || key != shield_halo_key)
		return
	var/list/inside = list()
	for(var/turf/spot as anything in hull)
		inside[spot] = TRUE
	var/list/ring = list()
	var/reach = shuttle ? 2 : 1
	for(var/turf/spot as anything in hull)
		for(var/turf/near as anything in RANGE_TURFS(reach, spot))
			if(inside[near] || !isspaceturf(near))
				continue
			var/distance = get_dist(spot, near)
			if(!ring[near] || ring[near] > distance)
				ring[near] = distance
		CHECK_TICK
	if(QDELETED(src) || key != shield_halo_key)
		return
	QDEL_LIST(shield_halo_tiles)
	shield_halo_tiles = list()
	for(var/turf/spot as anything in ring)
		var/obj/effect/abstract/ship_shield_halo/tile = new(spot)
		tile.base_alpha = ring[spot] <= 1 ? SHIELD_HALO_INNER_ALPHA : SHIELD_HALO_OUTER_ALPHA
		shield_halo_tiles += tile

/obj/overmap/entity/proc/update_shield_halo()
	var/fraction = shield_fraction()
	var/key = fraction > 0 ? shield_halo_key() : null
	if(key != shield_halo_key)
		shield_halo_key = key
		shield_halo_fraction = -1
		QDEL_LIST(shield_halo_tiles)
		if(key)
			INVOKE_ASYNC(src, PROC_REF(build_shield_halo))
	if(!length(shield_halo_tiles) || (abs(fraction - shield_halo_fraction) < 0.05 && world.time < shield_halo_refresh_at))
		return
	shield_halo_fraction = fraction
	shield_halo_refresh_at = world.time + SHIELD_HALO_REFRESH
	var/strength = 0.35 + fraction * 0.65
	for(var/obj/effect/abstract/ship_shield_halo/tile as anything in shield_halo_tiles)
		animate(tile, alpha = isspaceturf(tile.loc) ? tile.base_alpha * strength : 0, time = 1 SECONDS)

/obj/overmap/entity/proc/flash_shield_halo()
	if(world.time < shield_halo_flash_at)
		return
	shield_halo_flash_at = world.time + SHIELD_HALO_FLASH_COOLDOWN
	for(var/obj/effect/abstract/ship_shield_halo/tile as anything in shield_halo_tiles)
		var/resting = tile.alpha
		animate(tile, alpha = SHIELD_HALO_FLASH_ALPHA, time = 0.1 SECONDS)
		animate(alpha = resting, time = 0.6 SECONDS)

#undef SHIELD_HALO_INNER_ALPHA
#undef SHIELD_HALO_OUTER_ALPHA
#undef SHIELD_HALO_FLASH_ALPHA
#undef SHIELD_HALO_REFRESH
#undef SHIELD_HALO_FLASH_COOLDOWN
