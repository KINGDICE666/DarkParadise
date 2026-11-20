#define PVE_FLOW_OBSTACLE_COST 8
#define PVE_FLOW_WALL_COST 16
#define PVE_FLOW_CROWD_PENALTY 2
#define PVE_FLOW_BLOCKED -1

/datum/pve_flow_field
	var/z
	var/min_x
	var/min_y
	var/width
	var/height
	var/list/turfs
	var/list/static_blocked
	var/list/distances

/datum/pve_flow_field/New(turf/bottom_left, turf/top_right)
	z = bottom_left.z
	min_x = bottom_left.x
	min_y = bottom_left.y
	width = top_right.x - min_x + 1
	height = top_right.y - min_y + 1
	turfs = new /list(width * height)
	static_blocked = new /list(width * height)
	for(var/turf/tile as anything in block(bottom_left, top_right))
		var/index = turf_index(tile)
		turfs[index] = tile
		static_blocked[index] = tile.density

/datum/pve_flow_field/Destroy(force)
	turfs = null
	static_blocked = null
	distances = null
	return ..()

/datum/pve_flow_field/proc/turf_index(turf/tile)
	if(tile.z != z)
		return 0
	var/local_x = tile.x - min_x
	var/local_y = tile.y - min_y
	if(local_x < 0 || local_y < 0 || local_x >= width || local_y >= height)
		return 0
	return local_x + local_y * width + 1

/datum/pve_flow_field/proc/turf_cost(turf/tile)
	if(tile.density)
		return istype(tile, /turf/simulated/wall/indestructible) ? PVE_FLOW_BLOCKED : PVE_FLOW_WALL_COST
	for(var/obj/thing in tile)
		if(!thing.density || istype(thing, /obj/structure/pve_core))
			continue
		if(thing.resistance_flags & INDESTRUCTIBLE)
			return PVE_FLOW_BLOCKED
		return PVE_FLOW_OBSTACLE_COST
	return 0

/datum/pve_flow_field/proc/update(list/atom/sources)
	var/size = width * height
	var/list/new_distances = new /list(size)
	var/list/costs = new /list(size)
	var/list/buckets = list(list())
	for(var/atom/source as anything in sources)
		var/index = turf_index(get_turf(source))
		if(!index || static_blocked[index])
			continue
		new_distances[index] = 0
		buckets[1] += index
	var/current = 0
	while(current < length(buckets))
		var/list/bucket = buckets[current + 1]
		for(var/index in bucket)
			if(new_distances[index] != current)
				continue
			var/local_x = (index - 1) % width
			for(var/direction in GLOB.cardinal)
				var/neighbour
				switch(direction)
					if(NORTH)
						neighbour = index + width
						if(neighbour > size)
							continue
					if(SOUTH)
						neighbour = index - width
						if(neighbour < 1)
							continue
					if(EAST)
						if(local_x == width - 1)
							continue
						neighbour = index + 1
					if(WEST)
						if(local_x == 0)
							continue
						neighbour = index - 1
				if(static_blocked[neighbour])
					continue
				var/cost = costs[neighbour]
				if(isnull(cost))
					cost = turf_cost(turfs[neighbour])
					costs[neighbour] = cost
				if(cost == PVE_FLOW_BLOCKED)
					continue
				var/distance = current + 1 + cost
				var/known = new_distances[neighbour]
				if(!isnull(known) && known <= distance)
					continue
				new_distances[neighbour] = distance
				while(length(buckets) <= distance)
					buckets += list(list())
				buckets[distance + 1] += neighbour
		current++
	distances = new_distances

/datum/pve_flow_field/proc/distance_at(turf/tile)
	var/index = turf_index(tile)
	if(!index || !distances)
		return null
	return distances[index]

/datum/pve_flow_field/proc/next_step(atom/movable/walker)
	var/turf/here = get_turf(walker)
	var/best_distance = distance_at(here)
	if(isnull(best_distance))
		return null
	var/turf/best_turf
	for(var/direction in GLOB.alldirs)
		var/turf/candidate = get_step(here, direction)
		var/distance = distance_at(candidate)
		if(isnull(distance))
			continue
		if(ISDIAGONALDIR(direction))
			var/turf/side_a = get_step(here, direction & (NORTH|SOUTH))
			var/turf/side_b = get_step(here, direction & (EAST|WEST))
			if(isnull(distance_at(side_a)) || isnull(distance_at(side_b)) || turf_cost(side_a) || turf_cost(side_b))
				continue
		if(locate(/mob/living/simple_animal/hostile/pve) in candidate)
			distance += PVE_FLOW_CROWD_PENALTY
		if(distance < best_distance)
			best_distance = distance
			best_turf = candidate
	return best_turf

/datum/move_loop/has_target/dist_bound/move_to/pve_flow

/datum/move_loop/has_target/dist_bound/move_to/pve_flow/get_next_step()
	var/datum/pve_flow_field/field = extra_info
	return field?.next_step(moving) || get_step_to(moving, target)

#undef PVE_FLOW_OBSTACLE_COST
#undef PVE_FLOW_WALL_COST
#undef PVE_FLOW_CROWD_PENALTY
#undef PVE_FLOW_BLOCKED
