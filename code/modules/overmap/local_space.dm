#define OVERMAP_RADAR_TERRAIN_RANGE 40
#define OVERMAP_TERRAIN_VIEW_RANGE 14
#define OVERMAP_LOCAL_ARRIVAL_MARGIN 12
#define OVERMAP_TERRAIN_SEAM_SCALE 1.03

/datum/terrain_view
	var/obj/overmap/entity/vessel
	var/datum/overmap_bubble/local_space
	var/turf/viewer_turf
	var/list/obj/effect/abstract/hull_proxy_tile/tiles = list()
	var/last_x
	var/last_y
	var/last_facing

/datum/terrain_view/New(obj/overmap/entity/vessel, datum/overmap_bubble/local_space)
	src.vessel = vessel
	src.local_space = local_space
	viewer_turf = locate(round(vessel.hull_center_x), round(vessel.hull_center_y), vessel.hull_z)
	addtimer(CALLBACK(src, PROC_REF(refresh_light_copies)), 1 SECONDS, TIMER_LOOP|TIMER_DELETE_ME)

/datum/terrain_view/Destroy(force)
	QDEL_LIST_ASSOC_VAL(tiles)
	vessel = null
	local_space = null
	viewer_turf = null
	return ..()

/datum/terrain_view/proc/refresh_light_copies()
	for(var/turf/shown as anything in tiles)
		var/obj/effect/abstract/hull_proxy_tile/tile = tiles[shown]
		tile.copy_light()

/datum/terrain_view/proc/update(elapsed)
	var/list/spot = local_space.to_bubble(vessel.get_world_x(), vessel.get_world_y())
	var/facing = vessel.get_facing()
	if(spot[1] == last_x && spot[2] == last_y && facing == last_facing)
		return
	last_x = spot[1]
	last_y = spot[2]
	last_facing = facing
	var/matrix/turned = matrix()
	turned.Scale(OVERMAP_TERRAIN_SEAM_SCALE)
	turned.Turn(-facing)
	var/cos_facing = cos(facing)
	var/sin_facing = sin(facing)
	var/radius = round(vessel.hull_radius + OVERMAP_TERRAIN_VIEW_RANGE)
	var/center_x = round(spot[1], 1)
	var/center_y = round(spot[2], 1)
	var/list/wanted = list()
	for(var/turf/shown as anything in block(max(center_x - radius, 1), max(center_y - radius, 1), local_space.bubble_z, min(center_x + radius, world.maxx), min(center_y + radius, world.maxy), local_space.bubble_z))
		if(isspaceturf(shown) && !(locate(/obj/structure) in shown))
			continue
		var/delta_x = shown.x - spot[1]
		var/delta_y = shown.y - spot[2]
		var/hull_x = vessel.hull_center_x + delta_x * cos_facing - delta_y * sin_facing
		var/hull_y = vessel.hull_center_y + delta_x * sin_facing + delta_y * cos_facing
		if(vessel.hull_turfs[locate(FLOOR(hull_x + 0.5, 1), FLOOR(hull_y + 0.5, 1), vessel.hull_z)])
			continue
		wanted[shown] = TRUE
		var/obj/effect/abstract/hull_proxy_tile/tile = tiles[shown]
		if(!tile)
			tile = new(null)
			tile.hull_turf = shown
			tile.vis_contents += shown
			tile.setup_shading(viewer_turf)
			tiles[shown] = tile
		tile.glide(hull_x, hull_y, vessel.hull_z, turned, vessel.flight_bounds, elapsed)
	for(var/turf/shown as anything in tiles)
		if(!wanted[shown])
			qdel(tiles[shown])
			tiles -= shown

/obj/overmap/entity/proc/update_terrain_view(elapsed)
	if(!local_space)
		QDEL_NULL(terrain_view)
		return
	if(terrain_view?.local_space != local_space)
		QDEL_NULL(terrain_view)
		terrain_view = new(src, local_space)
	terrain_view.update(elapsed)

/obj/overmap/entity/proc/keep_inside_local_space()
	if(!local_space)
		return
	if(programmed_mission)
		local_space = null
		return
	var/list/spot = local_space.to_bubble(get_world_x(), get_world_y())
	var/list/bounds = local_space.bounds
	var/clamped_x = clamp(spot[1], bounds[1] + hull_radius, bounds[3] - hull_radius)
	var/clamped_y = clamp(spot[2], bounds[2] + hull_radius, bounds[4] - hull_radius)
	if(clamped_x == spot[1] && clamped_y == spot[2])
		return
	if(clamped_x != spot[1])
		speed[1] = 0
	if(clamped_y != spot[2])
		speed[2] = 0
	var/list/inside = local_space.to_world(clamped_x, clamped_y)
	set_world_position(inside[1], inside[2])

/obj/overmap/entity/proc/local_arrival_point(list/target, list/origin)
	var/datum/overmap_bubble/arrival_space = SSovermap.local_space_at(sector, target[1], target[2])
	if(!arrival_space)
		return target
	var/list/bounds = arrival_space.bounds
	var/half_size = min(bounds[3] - bounds[1], bounds[4] - bounds[2]) / 2 - OVERMAP_LOCAL_ARRIVAL_MARGIN - hull_radius
	var/list/center = arrival_space.to_world(arrival_space.center_x, arrival_space.center_y)
	var/approach_x = origin[1] - center[1]
	var/approach_y = origin[2] - center[2]
	var/approach_length = sqrt(approach_x ** 2 + approach_y ** 2)
	if(!approach_length)
		approach_y = 1
		approach_length = 1
	return list(center[1] + approach_x / approach_length * half_size, center[2] + approach_y / approach_length * half_size)

/datum/controller/subsystem/overmap/proc/local_space_at(datum/overmap_sector/sector, world_x, world_y)
	for(var/datum/overmap_bubble/bubble as anything in bubbles_by_z)
		if(bubble?.sector == sector && bubble.covers(bubble.to_bubble(world_x, world_y), 0))
			return bubble

/datum/controller/subsystem/overmap/proc/create_local_spaces()
	var/list/station_levels = levels_by_trait(STATION_LEVEL)
	if(!station_entity?.sector || !length(station_levels))
		return
	var/datum/overmap_bubble/station_space = new(station_entity.sector, station_entity.get_world_x(), station_entity.get_world_y(), 0, 0)
	station_space.fill_level(station_levels[1])

/obj/overmap/entity/proc/record_undock_origin()
	map_hull()
	undock_origin = list(hull_z, hull_center_x, hull_center_y, shuttle.dir)

/obj/overmap/entity/proc/place_at_undock_origin()
	var/list/origin = undock_origin
	undock_origin = null
	if(programmed_mission)
		return
	var/datum/overmap_bubble/origin_space = origin[1] <= length(SSovermap.bubbles_by_z) && SSovermap.bubbles_by_z[origin[1]]
	if(!origin_space || origin_space.sector != sector)
		return
	var/list/spot = origin_space.to_world(origin[2], origin[3])
	flight?.set_autopilot(FALSE)
	flight?.set_facing(dir2angle(origin[4]) - dir2angle(shuttle.dir))
	speed[1] = 0
	speed[2] = 0
	set_world_position(spot[1], spot[2])
	local_space = origin_space

/obj/overmap/entity/proc/radar_terrain()
	if(!local_space)
		return null
	var/list/spot = local_space.to_bubble(get_world_x(), get_world_y())
	var/spot_x = round(spot[1], 1)
	var/spot_y = round(spot[2], 1)
	var/list/cells = list()
	for(var/turf/nearby as anything in block(max(spot_x - OVERMAP_RADAR_TERRAIN_RANGE, 1), max(spot_y - OVERMAP_RADAR_TERRAIN_RANGE, 1), local_space.bubble_z, min(spot_x + OVERMAP_RADAR_TERRAIN_RANGE, world.maxx), min(spot_y + OVERMAP_RADAR_TERRAIN_RANGE, world.maxy), local_space.bubble_z))
		if(!nearby.is_blocked_turf(exclude_mobs = TRUE))
			continue
		cells += (nearby.x - spot[1]) * 2
		cells += (nearby.y - spot[2]) * 2
	return list("x" = get_world_x(), "y" = get_world_y(), "cells" = cells)

#undef OVERMAP_RADAR_TERRAIN_RANGE
#undef OVERMAP_TERRAIN_VIEW_RANGE
#undef OVERMAP_LOCAL_ARRIVAL_MARGIN
#undef OVERMAP_TERRAIN_SEAM_SCALE
