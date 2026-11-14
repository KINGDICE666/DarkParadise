/datum/overmap_bubble/proc/navigation_density()
	if(navigation_density_busy)
		UNTIL(!navigation_density_busy || QDELETED(src))
	if(QDELETED(src))
		return null
	if(navigation_density_cache && world.time < navigation_density_until)
		return navigation_density_cache
	navigation_density_busy = TRUE
	var/width = bounds[3] - bounds[1] + 1
	var/height = bounds[4] - bounds[2] + 1
	var/stride = width + 1
	var/list/prefix = new /list(stride * (height + 1))
	for(var/row in 1 to height)
		var/sum = 0
		for(var/column in 1 to width)
			var/turf/spot = locate(bounds[1] + column - 1, bounds[2] + row - 1, bubble_z)
			sum += !!blocks_navigation(spot)
			prefix[row * stride + column + 1] = sum + (prefix[(row - 1) * stride + column + 1] || 0)
		CHECK_TICK
		if(QDELETED(src))
			navigation_density_busy = FALSE
			return null
	navigation_density_cache = list(width, height, bounds[1], bounds[2], prefix)
	navigation_density_until = world.time + (2 SECONDS)
	navigation_density_busy = FALSE
	return navigation_density_cache

/proc/overmap_nav_heap_push(list/heap, list/item)
	heap += list(item)
	var/index = length(heap)
	while(index > 1)
		var/parent = FLOOR(index / 2, 1)
		var/list/above = heap[parent]
		if(above[4] <= item[4])
			break
		heap[index] = above
		index = parent
	heap[index] = item

/proc/overmap_nav_heap_pop(list/heap)
	. = heap[1]
	var/list/item = heap[length(heap)]
	heap.len--
	if(!length(heap))
		return
	var/index = 1
	while(index * 2 <= length(heap))
		var/child = index * 2
		var/list/next = heap[child]
		if(child < length(heap))
			var/list/right = heap[child + 1]
			if(right[4] < next[4])
				child++
				next = right
		if(next[4] >= item[4])
			break
		heap[index] = next
		index = child
	heap[index] = item

/datum/overmap_navigation_grid
	var/datum/overmap_navigation/navigation
	var/revision
	var/datum/overmap_bubble/space
	var/list/density
	var/obj/overmap/entity/vessel
	var/fixed_heading
	var/list/footprints
	var/list/boxes
	var/list/limits
	var/list/finish
	var/list/escape_box
	var/step = 2

/datum/overmap_navigation_grid/New(datum/overmap_navigation/owner, datum/overmap_bubble/host_space, list/obstacles, list/world_limits, list/goal, list/escape_box)
	navigation = owner
	revision = owner.revision
	space = host_space
	boxes = obstacles
	limits = world_limits
	finish = goal
	src.escape_box = escape_box
	density = space.navigation_density()
	if(QDELETED(owner) || revision != owner.revision || QDELETED(owner.flight) || QDELETED(owner.flight.parent) || QDELETED(space))
		density = null
		return
	vessel = owner.flight.parent
	fixed_heading = owner.flight.navigation_facing
	footprints = new /list(360 / OVERMAP_NAVIGATION_HEADING_STEP)

/datum/overmap_navigation_grid/Destroy()
	navigation = null
	space = null
	vessel = null
	return ..()

/datum/overmap_navigation_grid/proc/footprint(heading)
	if(!isnull(fixed_heading))
		heading = fixed_heading
	var/index = round(SIMPLIFY_DEGREES(heading) / OVERMAP_NAVIGATION_HEADING_STEP)
	if(index < 0)
		index += length(footprints)
	index = index % length(footprints) + 1
	if(footprints[index])
		return footprints[index]
	heading = (index - 1) * OVERMAP_NAVIGATION_HEADING_STEP
	var/min_x = INFINITY
	var/min_y = INFINITY
	var/max_x = -INFINITY
	var/max_y = -INFINITY
	for(var/turf/tile as anything in vessel.hull_turfs)
		var/dx = tile.x - vessel.hull_center_x
		var/dy = tile.y - vessel.hull_center_y
		var/x = dx * cos(heading) + dy * sin(heading)
		var/y = dy * cos(heading) - dx * sin(heading)
		min_x = min(min_x, x)
		max_x = max(max_x, x)
		min_y = min(min_y, y)
		max_y = max(max_y, y)
	if(min_x == INFINITY)
		min_x = min_y = -vessel.hull_radius
		max_x = max_y = vessel.hull_radius
	var/pad = 0.49 * (abs(cos(heading)) + abs(sin(heading))) + 0.49
	footprints[index] = list(min_x - pad, min_y - pad, max_x + pad, max_y + pad)
	return footprints[index]

/datum/overmap_navigation_grid/proc/point_clear(list/point, heading)
	if(!density || QDELETED(space))
		return FALSE
	if(!overmap_nav_inside(point, limits) || !overmap_nav_clear(point, point, boxes))
		return FALSE
	var/list/local = space.to_bubble(point[1], point[2])
	var/list/footprint = footprint(heading)
	var/low_x = max(1, CEILING(local[1] + footprint[1], 1) - density[3] + 1)
	var/low_y = max(1, CEILING(local[2] + footprint[2], 1) - density[4] + 1)
	var/high_x = min(density[1], FLOOR(local[1] + footprint[3], 1) - density[3] + 1)
	var/high_y = min(density[2], FLOOR(local[2] + footprint[4], 1) - density[4] + 1)
	if(low_x > high_x || low_y > high_y)
		return TRUE
	var/list/prefix = density[5]
	var/stride = density[1] + 1
	return !(prefix[high_y * stride + high_x + 1] - prefix[(low_y - 1) * stride + high_x + 1] - prefix[high_y * stride + low_x] + prefix[(low_y - 1) * stride + low_x])

/datum/overmap_navigation_grid/proc/segment_clear(list/start, list/end)
	if(!overmap_nav_clear(start, end, boxes))
		return FALSE
	var/dx = end[1] - start[1]
	var/dy = end[2] - start[2]
	var/count = max(1, CEILING(sqrt(dx ** 2 + dy ** 2) * 2, 1))
	var/heading = (dx || dy) ? delta_to_angle(dx, dy) : vessel.get_facing()
	for(var/index in 0 to count)
		if(!point_clear(list(start[1] + dx * index / count, start[2] + dy * index / count), heading))
			return FALSE
	return TRUE

/datum/overmap_navigation_grid/proc/nearest_clear(list/point, reach, heading)
	for(var/radius in 1 to reach)
		var/list/best
		var/best_distance = INFINITY
		for(var/offset_x in -radius to radius)
			for(var/offset_y in -radius to radius)
				if(max(abs(offset_x), abs(offset_y)) != radius)
					continue
				var/distance = offset_x ** 2 + offset_y ** 2
				if(distance >= best_distance)
					continue
				var/list/candidate = list(point[1] + offset_x, point[2] + offset_y)
				if(!point_clear(candidate, heading))
					continue
				best = candidate
				best_distance = distance
		if(best)
			return best
		CHECK_TICK
	return null

/datum/overmap_navigation_grid/proc/remaining(list/point, list/goal)
	if(!escape_box)
		return sqrt((point[1] - goal[1]) ** 2 + (point[2] - goal[2]) ** 2) / step
	return max(0, min(point[1] - escape_box[1], escape_box[3] - point[1], point[2] - escape_box[2], escape_box[4] - point[2])) / step

/datum/overmap_navigation_grid/proc/find_path(list/start)
	if(!density)
		return null
	var/list/goal = finish
	if(!escape_box)
		var/arrival_heading = delta_to_angle(goal[1] - start[1], goal[2] - start[2])
		if(!point_clear(goal, arrival_heading))
			goal = nearest_clear(goal, CEILING(vessel.hull_radius * 2, 1) + 8, arrival_heading)
			if(!goal)
				return null
	var/start_clear = point_clear(start, vessel.get_facing())
	if(start_clear && !escape_box && segment_clear(start, goal))
		return goal == finish ? list(finish) : list(goal, finish)
	var/list/origin = escape_box ? start : goal
	var/start_key = "start"
	var/list/heap = list()
	var/list/costs = list()
	var/list/parents = list()
	var/list/closed = list()
	var/list/stuck = list()
	if(!start_clear)
		stuck[start_key] = TRUE
	costs[start_key] = 0
	overmap_nav_heap_push(heap, list(start_key, round((start[1] - origin[1]) / step), round((start[2] - origin[2]) / step), 0, 0))
	var/visited = 0
	while(length(heap) && visited++ < 30000)
		var/list/node = overmap_nav_heap_pop(heap)
		var/key = node[1]
		if(closed[key])
			continue
		closed[key] = TRUE
		var/list/from = key == start_key ? start : list(origin[1] + node[2] * step, origin[2] + node[3] * step)
		if(key != start_key && !stuck[key] && (escape_box ? !overmap_nav_inside(from, escape_box) : !node[2] && !node[3]))
			var/list/path = list(from)
			while(key != start_key)
				var/list/previous = parents[key]
				key = previous[1]
				if(key != start_key)
					path.Insert(1, list(list(origin[1] + previous[2] * step, origin[2] + previous[3] * step)))
			var/list/result = list()
			var/list/anchor = start
			var/list/previous = path[1]
			for(var/index in 2 to length(path))
				var/list/point = path[index]
				if(!segment_clear(anchor, point))
					result += list(previous)
					anchor = previous
				previous = point
				CHECK_TICK
			result += list(previous)
			if(!escape_box && goal != finish)
				result += list(finish)
			return result
		for(var/direction in GLOB.alldirs)
			var/dx = (direction & EAST) ? 1 : ((direction & WEST) ? -1 : 0)
			var/dy = (direction & NORTH) ? 1 : ((direction & SOUTH) ? -1 : 0)
			var/x = node[2] + dx
			var/y = node[3] + dy
			var/next_key = "[x],[y]"
			if(closed[next_key])
				continue
			var/list/point = list(origin[1] + x * step, origin[2] + y * step)
			var/blocked = stuck[key] ? !point_clear(point, delta_to_angle(dx, dy)) : !segment_clear(from, point)
			var/cost = node[5] + ((dx && dy) ? 1.414214 : 1) * (blocked ? OVERMAP_NAVIGATION_STUCK_COST : 1)
			if(!isnull(costs[next_key]) && costs[next_key] <= cost)
				continue
			costs[next_key] = cost
			parents[next_key] = list(key, node[2], node[3])
			if(blocked)
				stuck[next_key] = TRUE
			else
				stuck -= next_key
			overmap_nav_heap_push(heap, list(next_key, x, y, cost + remaining(point, goal), cost))
		CHECK_TICK
		if(QDELETED(navigation) || revision != navigation.revision || QDELETED(space))
			return null
	return null
