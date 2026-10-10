#define OVERMAP_RADAR_TERRAIN_RANGE 64
#define OVERMAP_RADAR_CHUNK 16
#define OVERMAP_RADAR_CHUNK_REFRESH (30 SECONDS)
#define OVERMAP_RADAR_WALL 1
#define OVERMAP_RADAR_FRAME 2
#define OVERMAP_RADAR_FLOOR 3
#define OVERMAP_RADAR_EXPIRY 4
#define OVERMAP_TERRAIN_VIEW_RANGE 14
#define OVERMAP_LOCAL_ARRIVAL_MARGIN 12
#define OVERMAP_LOCAL_ARRIVAL_TURN_STEP 15
#define OVERMAP_LOCAL_ARRIVAL_TURNS 12
#define OVERMAP_TERRAIN_SEAM_SCALE 1.03
#define OVERMAP_TERRAIN_SPARE_TILES 32
#define OVERMAP_TERRAIN_SIGHT_STEP 2

/datum/terrain_view
	var/obj/overmap/entity/vessel
	var/datum/overmap_bubble/local_space
	var/turf/viewer_turf
	var/list/obj/effect/abstract/hull_proxy_tile/tiles = list()
	var/list/obj/effect/abstract/hull_proxy_tile/carrier/carriers = list()
	var/list/turf/hidden = list()
	var/list/obj/effect/abstract/hull_proxy_tile/spare_tiles = list()
	var/last_x
	var/last_y
	var/last_facing
	var/next_refresh = 0
	var/turf/sight_eye
	var/list/turf/in_sight
	var/next_sight_refresh = 0

/datum/terrain_view/New(obj/overmap/entity/vessel, datum/overmap_bubble/local_space)
	src.vessel = vessel
	src.local_space = local_space
	viewer_turf = locate(round(vessel.hull_center_x), round(vessel.hull_center_y), vessel.hull_z)
	addtimer(CALLBACK(src, PROC_REF(refresh_light_copies)), 1 SECONDS, TIMER_LOOP|TIMER_DELETE_ME)

/datum/terrain_view/Destroy(force)
	QDEL_LIST_ASSOC_VAL(carriers)
	tiles.Cut()
	hidden.Cut()
	QDEL_LIST(spare_tiles)
	vessel = null
	local_space = null
	viewer_turf = null
	sight_eye = null
	in_sight = null
	return ..()

/datum/terrain_view/proc/refresh_light_copies()
	for(var/turf/shown as anything in tiles)
		var/obj/effect/abstract/hull_proxy_tile/tile = tiles[shown]
		tile.copy_light()

/datum/terrain_view/proc/update(elapsed)
	var/list/spot = local_space.to_bubble(vessel.get_world_x(), vessel.get_world_y())
	var/facing = vessel.get_facing()
	var/moved = spot[1] != last_x || spot[2] != last_y || facing != last_facing
	if(!moved && world.time < next_refresh)
		return
	next_refresh = world.time + OVERMAP_SLOW_TICK
	var/turned_changed = facing != last_facing
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
	var/hull_reach = (vessel.hull_radius + 1) ** 2
	var/turf/eye = locate(center_x, center_y, local_space.bubble_z)
	if(world.time >= next_sight_refresh || !eye || !sight_eye || get_dist(eye, sight_eye) >= OVERMAP_TERRAIN_SIGHT_STEP)
		sight_eye = eye
		next_sight_refresh = world.time + OVERMAP_SLOW_TICK
		in_sight = null
		if(eye)
			in_sight = list()
			FOR_DVIEW(var/turf/seen, radius, eye, 0)
				in_sight[seen] = TRUE
			FOR_DVIEW_END
	var/list/wanted = list()
	var/list/turf/fresh = list()
	for(var/chunk_x in max(round((center_x - radius) / OVERMAP_RADAR_CHUNK), 0) to round(min(center_x + radius, world.maxx) / OVERMAP_RADAR_CHUNK))
		for(var/chunk_y in max(round((center_y - radius) / OVERMAP_RADAR_CHUNK), 0) to round(min(center_y + radius, world.maxy) / OVERMAP_RADAR_CHUNK))
			var/list/chunk = local_space.terrain_chunk(chunk_x, chunk_y)
			for(var/index in 2 to length(chunk))
				var/turf/shown = chunk[index]
				if(abs(shown.x - center_x) > radius || abs(shown.y - center_y) > radius)
					continue
				var/obj/effect/abstract/hull_proxy_tile/tile = tiles[shown]
				var/delta_x = shown.x - spot[1]
				var/delta_y = shown.y - spot[2]
				var/distance_squared = delta_x * delta_x + delta_y * delta_y
				var/under_hull = FALSE
				if(distance_squared <= hull_reach)
					var/hull_x = vessel.hull_center_x + delta_x * cos_facing - delta_y * sin_facing
					var/hull_y = vessel.hull_center_y + delta_x * sin_facing + delta_y * cos_facing
					under_hull = !!vessel.hull_turfs[locate(FLOOR(hull_x + 0.5, 1), FLOOR(hull_y + 0.5, 1), vessel.hull_z)]
				if(under_hull)
					if(tile)
						wanted[shown] = TRUE
						if(!hidden[shown])
							hidden[shown] = TRUE
							tile.carrier.vis_contents -= tile
					continue
				wanted[shown] = TRUE
				var/out_of_sight = in_sight && !in_sight[shown]
				if(!tile)
					fresh[shown] = out_of_sight
					continue
				if(tile.occluded != !!out_of_sight)
					tile.set_occluded(out_of_sight)
				var/time = elapsed
				if(hidden[shown])
					hidden -= shown
					tile.carrier.vis_contents += tile
					time = 0
				else if(!turned_changed)
					continue
				tile.shift(tile.base_x * cos_facing - tile.base_y * sin_facing, tile.base_x * sin_facing + tile.base_y * cos_facing, turned, time)
	for(var/turf/shown as anything in tiles)
		if(wanted[shown])
			continue
		var/obj/effect/abstract/hull_proxy_tile/tile = tiles[shown]
		var/obj/effect/abstract/hull_proxy_tile/carrier/carrier = tile.carrier
		carrier.remove_member(tile)
		tiles -= shown
		hidden -= shown
		if(length(spare_tiles) < OVERMAP_TERRAIN_SPARE_TILES)
			spare_tiles += tile
		else
			qdel(tile)
		if(!length(carrier.members))
			carriers -= carrier.chunk_key
			qdel(carrier)
	for(var/turf/shown as anything in fresh)
		var/obj/effect/abstract/hull_proxy_tile/tile = add_tile(shown)
		tile.set_occluded(fresh[shown])
		tile.shift(tile.base_x * cos_facing - tile.base_y * sin_facing, tile.base_x * sin_facing + tile.base_y * cos_facing, turned, 0)
	for(var/key in carriers)
		var/obj/effect/abstract/hull_proxy_tile/carrier/carrier = carriers[key]
		if(!moved && carrier.loc)
			continue
		var/delta_x = carrier.base_x - spot[1]
		var/delta_y = carrier.base_y - spot[2]
		carrier.glide(vessel.hull_center_x + delta_x * cos_facing - delta_y * sin_facing, vessel.hull_center_y + delta_x * sin_facing + delta_y * cos_facing, vessel.hull_z, null, vessel.flight_bounds, elapsed)

/datum/terrain_view/proc/add_tile(turf/shown)
	var/chunk_x = round(shown.x / OVERMAP_MIRROR_CHUNK) * OVERMAP_MIRROR_CHUNK + 1
	var/chunk_y = round(shown.y / OVERMAP_MIRROR_CHUNK) * OVERMAP_MIRROR_CHUNK + 1
	var/key = "[chunk_x]_[chunk_y]"
	var/obj/effect/abstract/hull_proxy_tile/carrier/carrier = carriers[key]
	if(!carrier)
		carrier = new(null)
		carrier.chunk_key = key
		carrier.base_x = chunk_x
		carrier.base_y = chunk_y
		carriers[key] = carrier
	var/obj/effect/abstract/hull_proxy_tile/tile = pop(spare_tiles)
	if(tile)
		animate(tile)
		tile.set_occluded(FALSE)
		tile.vis_contents.Cut()
	else
		tile = new(null)
	tile.base_x = (shown.x - chunk_x) * ICON_SIZE_X
	tile.base_y = (shown.y - chunk_y) * ICON_SIZE_Y
	tile.hull_turf = shown
	tile.vis_contents += shown
	tile.setup_shading(viewer_turf)
	tiles[shown] = tile
	carrier.add_member(tile)
	return tile

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
		enter_local_space()
		return
	if(programmed_mission)
		local_space = null
		return
	var/list/spot = local_space.to_bubble(get_world_x(), get_world_y())
	if(local_space.anchor)
		if(local_space.sector != sector || !local_space.covers(spot, -hull_radius))
			local_space = null
		return
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

/obj/overmap/entity/proc/enter_local_space()
	if(programmed_mission || is_jumping())
		return
	var/datum/overmap_bubble/entered = SSovermap.local_space_at(sector, get_world_x(), get_world_y(), src)
	if(!entered || !entered.covers(entered.to_bubble(get_world_x(), get_world_y()), -hull_radius))
		return
	local_space = entered
	var/list/goal = flight?.autopilot_goal
	if(flight?.autopilot && !(goal && entered.covers(entered.to_bubble(goal[1], goal[2]), 0)))
		flight.set_autopilot(FALSE)

/obj/overmap/entity/proc/local_arrival_point(list/target, list/origin)
	var/datum/overmap_bubble/arrival_space = SSovermap.local_space_at(sector, target[1], target[2], src)
	if(!arrival_space)
		return target
	var/list/bounds = arrival_space.bounds
	var/half_width = (bounds[3] - bounds[1]) / 2 - OVERMAP_LOCAL_ARRIVAL_MARGIN - hull_radius
	var/half_height = (bounds[4] - bounds[2]) / 2 - OVERMAP_LOCAL_ARRIVAL_MARGIN - hull_radius
	var/list/center = arrival_space.to_world(arrival_space.center_x, arrival_space.center_y)
	var/approach_angle = delta_to_angle(origin[1] - center[1], origin[2] - center[2])
	var/list/fallback
	for(var/turn_step in 0 to OVERMAP_LOCAL_ARRIVAL_TURNS)
		for(var/side in (turn_step ? list(1, -1) : list(1)))
			var/angle = approach_angle + side * turn_step * OVERMAP_LOCAL_ARRIVAL_TURN_STEP
			var/dir_x = sin(angle)
			var/dir_y = cos(angle)
			var/reach = min(dir_x ? half_width / abs(dir_x) : INFINITY, dir_y ? half_height / abs(dir_y) : INFINITY)
			var/list/spot = list(center[1] + dir_x * reach, center[2] + dir_y * reach)
			if(local_arrival_clear(arrival_space, spot))
				return spot
			fallback ||= spot
	return fallback

/obj/overmap/entity/proc/local_arrival_clear(datum/overmap_bubble/arrival_space, list/spot)
	if(!length(hull_turfs))
		return !arrival_space.solid_turf_at(spot[1], spot[2])
	var/facing = get_facing()
	for(var/turf/hull_turf as anything in hull_turfs)
		var/list/hull_world = hull_to_world(hull_turf.x, hull_turf.y, spot[1], spot[2], facing)
		if(arrival_space.solid_turf_at(hull_world[1], hull_world[2]))
			return FALSE
	return TRUE

/datum/controller/subsystem/overmap/proc/local_space_at(datum/overmap_sector/sector, world_x, world_y, obj/overmap/entity/asker, margin = 0)
	for(var/datum/overmap_bubble/bubble as anything in bubbles_by_z)
		if(bubble?.sector == sector && (!bubble.anchor || bubble.anchor != asker) && bubble.covers(bubble.to_bubble(world_x, world_y), margin))
			return bubble

/datum/controller/subsystem/overmap/proc/create_local_spaces()
	var/list/station_levels = levels_by_trait(STATION_LEVEL)
	if(!station_entity?.sector || !length(station_levels) || SSmapping.is_planetary())
		return
	var/datum/overmap_bubble/station_space = new(station_entity.sector, station_entity.get_world_x(), station_entity.get_world_y(), 0, 0)
	station_space.fill_level(station_levels[1])
	var/obj/overmap/entity/station/ship/station_ship = station_entity
	if(istype(station_ship))
		station_space.anchor = station_ship
		station_ship.home_space = station_space

/obj/overmap/entity/proc/record_undock_origin()
	map_hull()
	undock_origin = list(hull_z, hull_center_x, hull_center_y, shuttle.overmap_origin()[2])

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
	flight?.set_facing(dir2angle(origin[4]) - dir2angle(shuttle.overmap_origin()[2]))
	speed[1] = 0
	speed[2] = 0
	set_world_position(spot[1], spot[2])
	local_space = origin_space

/obj/overmap/entity/proc/radar_terrain()
	if(!local_space)
		return null
	var/list/spot = local_space.to_bubble(get_world_x(), get_world_y())
	var/list/walls = list()
	var/list/frames = list()
	var/list/floors = list()
	var/first_x = max(round((spot[1] - OVERMAP_RADAR_TERRAIN_RANGE) / OVERMAP_RADAR_CHUNK), 0)
	var/last_x = round(min(spot[1] + OVERMAP_RADAR_TERRAIN_RANGE, world.maxx) / OVERMAP_RADAR_CHUNK)
	var/first_y = max(round((spot[2] - OVERMAP_RADAR_TERRAIN_RANGE) / OVERMAP_RADAR_CHUNK), 0)
	var/last_y = round(min(spot[2] + OVERMAP_RADAR_TERRAIN_RANGE, world.maxy) / OVERMAP_RADAR_CHUNK)
	for(var/chunk_x in first_x to last_x)
		for(var/chunk_y in first_y to last_y)
			var/list/chunk = local_space.radar_chunk(chunk_x, chunk_y)
			walls += chunk[OVERMAP_RADAR_WALL]
			frames += chunk[OVERMAP_RADAR_FRAME]
			floors += chunk[OVERMAP_RADAR_FLOOR]
	var/list/anchor = local_space.to_world(0, 0)
	return list("x" = anchor[1], "y" = anchor[2], "walls" = walls, "frames" = frames, "floors" = floors, "docks" = radar_station_docks())

/datum/overmap_bubble/proc/terrain_chunk(chunk_x, chunk_y)
	var/key = "[chunk_x]_[chunk_y]"
	var/list/cached = terrain_chunks[key]
	if(cached && world.time < cached[1])
		return cached
	cached = list(world.time + OVERMAP_SLOW_TICK)
	var/turf/low = locate(max(chunk_x * OVERMAP_RADAR_CHUNK, 1), max(chunk_y * OVERMAP_RADAR_CHUNK, 1), bubble_z)
	var/turf/high = locate(min(chunk_x * OVERMAP_RADAR_CHUNK + OVERMAP_RADAR_CHUNK - 1, world.maxx), min(chunk_y * OVERMAP_RADAR_CHUNK + OVERMAP_RADAR_CHUNK - 1, world.maxy), bubble_z)
	for(var/turf/spot as anything in block(low, high))
		if(!isspaceturf(spot) || (locate(/obj/structure) in spot))
			cached += spot
	terrain_chunks[key] = cached
	return cached

/datum/overmap_bubble/proc/radar_chunk(chunk_x, chunk_y)
	var/key = "[chunk_x]_[chunk_y]"
	var/list/cached = radar_chunks[key]
	if(cached && world.time < cached[OVERMAP_RADAR_EXPIRY])
		return cached
	var/static/list/wall_types = typecacheof(list(/obj/structure/window, /obj/structure/falsewall, /obj/machinery/door/airlock, /obj/machinery/door/poddoor, /obj/machinery/door/window))
	var/static/list/frame_types = typecacheof(list(/obj/structure/lattice, /obj/structure/grille, /obj/machinery/power/solar, /obj/machinery/power/tracker))
	var/list/runs = list(list(), list(), list())
	var/low_x = max(chunk_x * OVERMAP_RADAR_CHUNK, 1)
	var/high_x = min(chunk_x * OVERMAP_RADAR_CHUNK + OVERMAP_RADAR_CHUNK - 1, world.maxx)
	for(var/row in max(chunk_y * OVERMAP_RADAR_CHUNK, 1) to min(chunk_y * OVERMAP_RADAR_CHUNK + OVERMAP_RADAR_CHUNK - 1, world.maxy))
		var/run_kind = 0
		var/run_start = 0
		for(var/column in low_x to high_x + 1)
			var/kind = 0
			if(column <= high_x)
				var/turf/spot = locate(column, row, bubble_z)
				if(!isspaceturf(spot))
					kind = spot.density ? OVERMAP_RADAR_WALL : OVERMAP_RADAR_FLOOR
				for(var/atom/movable/thing as anything in spot)
					if(wall_types[thing.type])
						kind = OVERMAP_RADAR_WALL
						break
					if(!kind && frame_types[thing.type])
						kind = OVERMAP_RADAR_FRAME
			if(kind == run_kind)
				continue
			if(run_kind)
				var/list/target = runs[run_kind]
				target += run_start
				target += row
				target += column - run_start
			run_kind = kind
			run_start = column
	runs += world.time + OVERMAP_RADAR_CHUNK_REFRESH
	radar_chunks[key] = runs
	return runs

#undef OVERMAP_RADAR_TERRAIN_RANGE
#undef OVERMAP_RADAR_CHUNK
#undef OVERMAP_RADAR_CHUNK_REFRESH
#undef OVERMAP_RADAR_WALL
#undef OVERMAP_RADAR_FRAME
#undef OVERMAP_RADAR_FLOOR
#undef OVERMAP_RADAR_EXPIRY
#undef OVERMAP_TERRAIN_VIEW_RANGE
#undef OVERMAP_LOCAL_ARRIVAL_MARGIN
#undef OVERMAP_LOCAL_ARRIVAL_TURN_STEP
#undef OVERMAP_LOCAL_ARRIVAL_TURNS
#undef OVERMAP_TERRAIN_SEAM_SCALE
#undef OVERMAP_TERRAIN_SPARE_TILES
#undef OVERMAP_TERRAIN_SIGHT_STEP
