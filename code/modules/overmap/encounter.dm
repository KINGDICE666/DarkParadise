#define OVERMAP_NEIGHBOR_RANGE 24
#define OVERMAP_CONTACT_RANGE 64
#define OVERMAP_DRIFTER_RANGE 20
#define OVERMAP_BUBBLE_SIZE 96
#define OVERMAP_BUBBLE_MARGIN 16
#define OVERMAP_BUBBLE_TIMEOUT (1 MINUTES)
#define OVERMAP_EJECT_CLEARANCE 3
#define OVERMAP_SHIP_DOCK_RANGE 3
#define OVERMAP_SHIP_DOCK_ALIGN 20
#define OVERMAP_SHIP_DOCK_SPEED (2 / (1 SECONDS))
#define OVERMAP_SHIP_UNDOCK_PUSH (1 / (1 SECONDS))
#define OVERMAP_SHIP_DOCK_SHAKE_TIME 3
#define OVERMAP_SHIP_AUTODOCK_RANGE 1
#define OVERMAP_SHIP_AUTODOCK_ALIGN 10
#define OVERMAP_SHIP_AUTODOCK_SPEED (1 / (1 SECONDS))
#define OVERMAP_SHIP_REDOCK_COOLDOWN (5 SECONDS)
#define OVERMAP_SHIP_DOCK_SHAKE_STRENGTH 1
#define OVERMAP_SHOVE_CLEARANCE 4
#define OVERMAP_SHOVE_HURT_SPEED 4
#define OVERMAP_SHOVE_MAX_DAMAGE 25
#define OVERMAP_SHOVE_HURT_COOLDOWN (2 SECONDS)
#define OVERMAP_BOARD_REACH 1
#define OVERMAP_BOARD_SIDE 0.3
#define OVERMAP_BOARD_DOOR_BIAS 0.5
#define OVERMAP_HULL_SIGHT_SECTORS 8
#define OVERMAP_HULL_SIGHT_DISTANCE 6
#define OVERMAP_HULL_SIGHT_NEAR_RANGE 10
#define OVERMAP_HULL_SIGHT_REFRESH (3 SECONDS)
#define OVERMAP_CLING_SPEED 5
#define OVERMAP_CLING_SPEED_MAGBOOTS 10
#define OVERMAP_RADAR_DOCK_RANGE 64

/obj/overmap/entity/proc/map_hull(keep_center = FALSE)
	unwatch_hull()
	hull_dirty = FALSE
	hull_sight_cache = null
	hull_turfs = list()
	hull_watch = list()
	var/min_x = world.maxx
	var/max_x = 1
	var/min_y = world.maxy
	var/max_y = 1
	for(var/turf/hull_turf as anything in shuttle.return_turfs())
		if(!shuttle.shuttle_areas[get_area(hull_turf)])
			continue
		hull_watch += hull_turf
		RegisterSignal(hull_turf, COMSIG_TURF_CHANGE, PROC_REF(on_hull_turf_changed))
		if(isspaceturf(hull_turf))
			continue
		hull_turfs[hull_turf] = TRUE
		min_x = min(min_x, hull_turf.x)
		max_x = max(max_x, hull_turf.x)
		min_y = min(min_y, hull_turf.y)
		max_y = max(max_y, hull_turf.y)
	if(!keep_center)
		hull_center_x = (min_x + max_x) / 2
		hull_center_y = (min_y + max_y) / 2
	hull_edge = list()
	var/spread = 0
	for(var/turf/hull_turf as anything in hull_turfs)
		spread += (hull_turf.x - hull_center_x) ** 2 + (hull_turf.y - hull_center_y) ** 2
		for(var/direction in GLOB.cardinal)
			if(!hull_turfs[get_step(hull_turf, direction)])
				hull_edge[hull_turf] = TRUE
				break
	hull_inertia = max(spread / max(length(hull_turfs), 1), 1)
	hull_z = shuttle.z
	hull_collars = list()
	for(var/obj/machinery/door/airlock/external/docking/door as anything in overmap_shuttle?.shuttle_collars())
		var/turf/door_turf = get_turf(door)
		for(var/direction in GLOB.cardinal)
			var/turf/outside = get_step(door_turf, direction)
			if(outside && !hull_turfs[outside])
				hull_collars += list(list(door_turf, outside, dir2angle(direction)))
				break
	var/list/radar_tiles = list()
	for(var/turf/hull_turf as anything in hull_turfs)
		radar_tiles += (hull_turf.x - hull_center_x) * 2
		radar_tiles += (hull_turf.y - hull_center_y) * 2
	var/list/radar_collars = list()
	for(var/list/collar as anything in hull_collars)
		var/turf/door_turf = collar[1]
		radar_collars += (door_turf.x - hull_center_x) * 2
		radar_collars += (door_turf.y - hull_center_y) * 2
	radar_shape = list("tiles" = radar_tiles, "collars" = radar_collars)
	hull_radius = sqrt(max(abs(min_x - hull_center_x), abs(max_x - hull_center_x)) ** 2 + max(abs(min_y - hull_center_y), abs(max_y - hull_center_y)) ** 2) + 1
	var/obj/docking_port/stationary/transit/pad = shuttle.get_docked()
	flight_bounds = (istype(pad) && hyperspace_reservation_bounds(pad.reserved_area)) || list(1, 1, world.maxx, world.maxy)
	SSovermap.flight_reservations -= flight_reservation
	flight_reservation = null
	if(istype(pad) && pad.reserved_area)
		flight_reservation = pad.reserved_area
		SSovermap.flight_reservations[flight_reservation] = src

/obj/overmap/entity/proc/on_hull_turf_changed()
	SIGNAL_HANDLER
	hull_dirty = TRUE

/obj/overmap/entity/proc/unwatch_hull()
	for(var/turf/watched as anything in hull_watch)
		UnregisterSignal(watched, COMSIG_TURF_CHANGE)
	hull_watch = null

/obj/overmap/entity/proc/remap_hull()
	map_hull(keep_center = TRUE)
	for(var/obj/overmap/entity/other as anything in SSovermap.flying_vessels)
		if(other.neighbor_proxies[src])
			qdel(other.neighbor_proxies[src])
			other.neighbor_proxies -= src
	for(var/datum/overmap_bubble/bubble as anything in SSovermap.bubbles)
		if(bubble.ship_proxies[src])
			qdel(bubble.ship_proxies[src])
			bubble.ship_proxies -= src

/obj/overmap/entity/proc/clear_encounter_visuals()
	unwatch_hull()
	undock_ship()
	QDEL_NULL(terrain_view)
	for(var/obj/overmap/entity/guest as anything in docked_guests.Copy())
		guest.undock_ship()
	QDEL_LIST_ASSOC_VAL(neighbor_proxies)
	QDEL_LIST_ASSOC_VAL(drifter_mirrors)
	nearby_ships = list()
	for(var/obj/overmap/entity/other as anything in SSovermap.flying_vessels)
		other.nearby_ships -= src
		if(other.neighbor_proxies[src])
			qdel(other.neighbor_proxies[src])
			other.neighbor_proxies -= src
	for(var/datum/overmap_bubble/bubble as anything in SSovermap.bubbles)
		bubble.ships -= src
		if(bubble.ship_proxies[src])
			qdel(bubble.ship_proxies[src])
			bubble.ship_proxies -= src
	SSovermap.flight_reservations -= flight_reservation
	flight_reservation = null
	hull_turfs = null
	hull_edge = null
	hull_sight_cache = null
	hull_collars = null
	radar_shape = null
	flight_bounds = null

/obj/overmap/entity/proc/get_facing()
	return flight?.facing || 0

/obj/overmap/entity/proc/get_world_x()
	var/turf/here = get_overmap_turf()
	return (here.x + position[1]) * OVERMAP_TILE_SPAN * (sector?.tile_travel || 1)

/obj/overmap/entity/proc/get_world_y()
	var/turf/here = get_overmap_turf()
	return (here.y + position[2]) * OVERMAP_TILE_SPAN * (sector?.tile_travel || 1)

/obj/overmap/entity/proc/set_world_position(world_x, world_y)
	var/span = OVERMAP_TILE_SPAN * (sector?.tile_travel || 1)
	var/tile_x = round(world_x / span, 1)
	var/tile_y = round(world_y / span, 1)
	position = list(world_x / span - tile_x, world_y / span - tile_y)
	var/turf/here = get_overmap_turf()
	var/turf/tile = locate(tile_x, tile_y, here.z)
	if(tile && tile != loc)
		forceMove(tile)
		on_overmap_loc_changed()
	update_overmap_pixel()

/obj/overmap/entity/proc/total_mass()
	. = vessel_mass
	for(var/obj/overmap/entity/guest as anything in docked_guests)
		. += guest.vessel_mass

/obj/overmap/entity/proc/find_dock_pair(obj/overmap/entity/other, best_distance = OVERMAP_SHIP_DOCK_RANGE, max_misalign = OVERMAP_SHIP_DOCK_ALIGN)
	for(var/list/own as anything in hull_collars)
		var/turf/own_outside = own[2]
		var/list/outside_world = hull_to_world(own_outside.x, own_outside.y)
		for(var/list/theirs as anything in other.hull_collars)
			var/turf/their_door = theirs[1]
			var/list/door_world = other.hull_to_world(their_door.x, their_door.y)
			var/distance = sqrt((outside_world[1] - door_world[1]) ** 2 + (outside_world[2] - door_world[2]) ** 2)
			var/misalign = abs(closer_angle_difference(own[3] + get_facing(), theirs[3] + other.get_facing() + 180))
			if(distance <= best_distance && misalign <= max_misalign)
				best_distance = distance
				. = list(own, theirs)

/obj/overmap/entity/proc/dockable_ship()
	RETURN_TYPE(/obj/overmap/entity)
	if(docked_ship)
		return
	for(var/obj/overmap/entity/other as anything in nearby_ships)
		if(relative_speed(other) <= OVERMAP_SHIP_DOCK_SPEED && find_dock_pair(other))
			return other

/obj/overmap/entity/proc/dock_to_nearest_ship()
	if(docked_ship)
		return "Корабль уже пристыкован."
	var/obj/overmap/entity/other = dockable_ship()
	if(other)
		var/list/pair = find_dock_pair(other)
		dock_to_ship(other, pair[1], pair[2])
		return TRUE
	return "Рядом нет подходящего шлюза. Подведите стыковочный шлюз вплотную к шлюзу другого корабля и уравняйте скорость."

/obj/overmap/entity/proc/relative_speed(obj/overmap/entity/other)
	return sqrt((speed[1] - other.speed[1]) ** 2 + (speed[2] - other.speed[2]) ** 2) * OVERMAP_TILE_SPAN

/obj/overmap/entity/proc/try_autodock()
	if(docked_ship || length(docked_guests) || world.time < next_autodock)
		return
	var/list/station_pair = find_station_dock(OVERMAP_SHIP_AUTODOCK_RANGE, OVERMAP_SHIP_AUTODOCK_ALIGN)
	if(!station_pair)
		station_autodock_armed = TRUE
	else if(station_autodock_armed)
		dock_to_station(station_pair[1], station_pair[2])
		return
	for(var/obj/overmap/entity/other as anything in nearby_ships)
		if(other.docked_ship || relative_speed(other) > OVERMAP_SHIP_AUTODOCK_SPEED)
			continue
		if(flight.pilot && !other.flight.pilot)
			continue
		var/list/pair = find_dock_pair(other, OVERMAP_SHIP_AUTODOCK_RANGE, OVERMAP_SHIP_AUTODOCK_ALIGN)
		if(pair)
			dock_to_ship(other, pair[1], pair[2])
			return

/obj/overmap/entity/proc/station_dock_targets(reach)
	. = list()
	var/list/center = local_space.to_bubble(get_world_x(), get_world_y())
	for(var/obj/docking_port/stationary/pad as anything in SSshuttle.stationary)
		var/obj/machinery/door/airlock/external/docking/airlock = pad.dock_airlock
		if(!airlock || pad.z != local_space.bubble_z || abs(pad.x - center[1]) > reach || abs(pad.y - center[2]) > reach || pad.get_docked() || is_overmap_programmed_dock(pad.id))
			continue
		var/obj/overmap/entity/owner = SSovermap.shuttle_vessels[SSovermap.get_shuttle_at(airlock)]
		. += list(list(airlock, get_turf(pad), airlock.dir, pad, owner?.get_overmap_display_name() || airlock.get_helm_label()))
	var/list/seen_hosts = list()
	for(var/obj/docking_port/mobile/port as anything in SSshuttle.mobile)
		if(port == shuttle || port.mode != SHUTTLE_IDLE || port.z != local_space.bubble_z || abs(port.x - center[1]) > reach + max(port.width, port.height) || abs(port.y - center[2]) > reach + max(port.width, port.height))
			continue
		var/obj/overmap/entity/host = SSovermap.shuttle_vessels[port]
		var/obj/docking_port/stationary/port_pad = port.get_docked()
		if(!host?.overmap_shuttle || host.programmed || seen_hosts[host] || !port_pad || istype(port_pad, /obj/docking_port/stationary/transit))
			continue
		seen_hosts[host] = TRUE
		for(var/obj/machinery/door/airlock/external/docking/collar as anything in host.overmap_shuttle.shuttle_collars())
			if(collar.overmap_pad)
				continue
			for(var/direction in GLOB.cardinal)
				var/turf/outside = get_step(collar, direction)
				if(isspaceturf(outside) && !port.shuttle_areas[outside.loc])
					. += list(list(collar, outside, direction, null, host.get_overmap_display_name()))
					break

/obj/overmap/entity/proc/find_station_dock(best_distance = OVERMAP_SHIP_DOCK_RANGE, max_misalign = OVERMAP_SHIP_DOCK_ALIGN)
	if(!local_space || docked_ship || length(docked_guests) || !length(hull_collars))
		return
	if(sqrt(speed[1] ** 2 + speed[2] ** 2) * OVERMAP_TILE_SPAN > OVERMAP_SHIP_DOCK_SPEED)
		return
	for(var/list/target as anything in station_dock_targets(hull_radius + best_distance))
		var/turf/target_turf = target[2]
		var/list/target_world = local_space.to_world(target_turf.x, target_turf.y)
		for(var/list/own as anything in hull_collars)
			var/turf/door_turf = own[1]
			var/list/door_world = hull_to_world(door_turf.x, door_turf.y)
			var/distance = sqrt((door_world[1] - target_world[1]) ** 2 + (door_world[2] - target_world[2]) ** 2)
			var/misalign = abs(closer_angle_difference(own[3] + get_facing(), dir2angle(target[3]) + 180))
			if(distance <= best_distance && misalign <= max_misalign)
				best_distance = distance
				. = list(own, target)

/obj/overmap/entity/proc/dock_to_nearest_station()
	var/list/pair = find_station_dock()
	if(!pair)
		return "Рядом нет свободного стыковочного шлюза. Подведите свой шлюз вплотную к другому шлюзу и остановитесь."
	return dock_to_station(pair[1], pair[2])

/obj/overmap/entity/proc/dock_to_station(list/own, list/target)
	var/turf/door_turf = own[1]
	var/obj/machinery/door/airlock/external/docking/collar = locate() in door_turf
	if(!collar)
		return "Стыковочный шлюз корабля не найден."
	shuttle.overmap_collar = collar
	var/obj/machinery/door/airlock/external/docking/airlock = target[1]
	var/obj/docking_port/stationary/pad = target[4]
	var/old_dir = airlock.dir
	if(!pad)
		pad = new /obj/docking_port/stationary/overmap(target[2])
		pad.setDir(target[3])
		airlock.setDir(target[3])
		pad.dock_airlock = airlock
		airlock.overmap_pad = pad
		airlock.owns_overmap_pad = TRUE
		airlock.sync_dock_label()
	var/can_status = shuttle.canDock(pad)
	if(can_status != SHUTTLE_CAN_DOCK)
		station_autodock_armed = FALSE
		if(!target[4])
			qdel(pad, TRUE)
			airlock.setDir(old_dir)
		return dock_fail_text(can_status)
	speed[1] = 0
	speed[2] = 0
	flight.angular_velocity = 0
	flight.release_pilot()
	flight.set_autopilot(FALSE)
	selected_dock_id = pad.id
	station_autodock_armed = FALSE
	play_shuttle_sound('sound/effects/clang.ogg')
	shake_shuttle(OVERMAP_SHIP_DOCK_SHAKE_TIME, OVERMAP_SHIP_DOCK_SHAKE_STRENGTH)
	announce_sensor_event("Стыковка: [get_overmap_display_name()] → [target[5]]", "dock")
	INVOKE_ASYNC(src, PROC_REF(finish_station_dock), pad)
	return TRUE

/obj/overmap/entity/proc/finish_station_dock(obj/docking_port/stationary/pad)
	if(shuttle.dock(pad) != DOCKING_SUCCESS)
		shuttle_visible_message(span_warning("Захваты стыковочного шлюза не сработали."))

/obj/overmap/entity/proc/radar_station_docks()
	. = list()
	if(!local_space)
		return
	for(var/list/target as anything in station_dock_targets(OVERMAP_RADAR_DOCK_RANGE))
		var/obj/machinery/door/airlock/external/docking/airlock = target[1]
		. += airlock.x * 2
		. += airlock.y * 2

/obj/overmap/entity/proc/dock_to_ship(obj/overmap/entity/host, list/own, list/theirs)
	var/new_facing = SIMPLIFY_DEGREES(theirs[3] + host.get_facing() + 180 - own[3])
	flight.angular_velocity = 0
	flight.set_facing(new_facing)
	var/turf/own_outside = own[2]
	var/turf/their_door = theirs[1]
	var/list/door_world = host.hull_to_world(their_door.x, their_door.y)
	var/local_x = own_outside.x - hull_center_x
	var/local_y = own_outside.y - hull_center_y
	var/world_x = door_world[1] - (local_x * cos(new_facing) + local_y * sin(new_facing))
	var/world_y = door_world[2] - (local_y * cos(new_facing) - local_x * sin(new_facing))
	set_world_position(world_x, world_y)
	remember_pose()
	var/list/in_host = host.world_to_hull(world_x, world_y)
	docked_ship = host
	dock_hull_x = in_host[1]
	dock_hull_y = in_host[2]
	dock_facing_offset = new_facing - host.get_facing()
	dock_collar_angle = own[3]
	host.docked_guests += src
	speed[1] = host.speed[1]
	speed[2] = host.speed[2]
	dock_seals += new /obj/effect/abstract/dock_seal(own_outside)
	dock_seals += new /obj/effect/abstract/dock_seal(theirs[2])
	flight.release_pilot()
	flight.set_autopilot(FALSE)
	for(var/obj/overmap/entity/joined as anything in list(src, host))
		joined.play_shuttle_sound('sound/effects/clang.ogg')
		joined.shake_shuttle(OVERMAP_SHIP_DOCK_SHAKE_TIME, OVERMAP_SHIP_DOCK_SHAKE_STRENGTH)
	announce_sensor_event("Стыковка: [get_overmap_display_name()] → [host.get_overmap_display_name()]", "dock")

/obj/overmap/entity/proc/undock_ship()
	var/obj/overmap/entity/host = docked_ship
	if(!host)
		return
	host.docked_guests -= src
	docked_ship = null
	next_autodock = world.time + OVERMAP_SHIP_REDOCK_COOLDOWN
	host.next_autodock = next_autodock
	QDEL_LIST(dock_seals)
	var/push_angle = dock_collar_angle + get_facing()
	speed[1] -= sin(push_angle) * OVERMAP_SHIP_UNDOCK_PUSH / OVERMAP_TILE_SPAN
	speed[2] -= cos(push_angle) * OVERMAP_SHIP_UNDOCK_PUSH / OVERMAP_TILE_SPAN
	announce_sensor_event("Расстыковка: [get_overmap_display_name()] ← [host.get_overmap_display_name()]", "undock")

/obj/overmap/entity/proc/follow_host()
	if(!(docked_ship in SSovermap.flying_vessels))
		undock_ship()
		return
	var/list/spot = docked_ship.hull_to_world(dock_hull_x, dock_hull_y)
	flight.set_facing(docked_ship.get_facing() + dock_facing_offset)
	set_world_position(spot[1], spot[2])
	speed[1] = docked_ship.speed[1]
	speed[2] = docked_ship.speed[2]

/obj/effect/abstract/dock_seal
	name = "dock seal"
	simulated = FALSE

/obj/effect/abstract/dock_seal/Initialize(mapload)
	. = ..()
	recalculate_atmos_connectivity()

/obj/effect/abstract/dock_seal/Destroy()
	var/turf/sealed = loc
	. = ..()
	sealed?.recalculate_atmos_connectivity()

/obj/effect/abstract/dock_seal/CanAtmosPass(direction)
	return FALSE

/obj/overmap/entity/proc/world_to_hull(world_x, world_y, origin_x = get_world_x(), origin_y = get_world_y(), facing = get_facing())
	var/delta_x = world_x - origin_x
	var/delta_y = world_y - origin_y
	return list(hull_center_x + delta_x * cos(facing) - delta_y * sin(facing), hull_center_y + delta_x * sin(facing) + delta_y * cos(facing))

/obj/overmap/entity/proc/hull_to_world(hull_x, hull_y, origin_x = get_world_x(), origin_y = get_world_y(), facing = get_facing())
	var/local_x = hull_x - hull_center_x
	var/local_y = hull_y - hull_center_y
	return list(origin_x + local_x * cos(facing) + local_y * sin(facing), origin_y - local_x * sin(facing) + local_y * cos(facing))

/obj/overmap/entity/proc/hull_turf_at(world_x, world_y, origin_x = get_world_x(), origin_y = get_world_y(), facing = get_facing())
	var/list/spot = world_to_hull(world_x, world_y, origin_x, origin_y, facing)
	var/turf/hull_turf = locate(FLOOR(spot[1] + 0.5, 1), FLOOR(spot[2] + 0.5, 1), hull_z)
	return hull_turfs[hull_turf] ? hull_turf : null

/obj/overmap/entity/proc/hull_sight_toward(world_x, world_y, exact = FALSE)
	var/list/hull_point = world_to_hull(world_x, world_y)
	var/distance = hull_radius + OVERMAP_HULL_SIGHT_DISTANCE
	if(exact && sqrt((hull_point[1] - hull_center_x) ** 2 + (hull_point[2] - hull_center_y) ** 2) <= distance)
		var/turf/viewer = locate(clamp(FLOOR(hull_point[1] + 0.5, 1), flight_bounds[1], flight_bounds[3]), clamp(FLOOR(hull_point[2] + 0.5, 1), flight_bounds[2], flight_bounds[4]), hull_z)
		return hull_seen_from(viewer, OVERMAP_HULL_SIGHT_NEAR_RANGE)
	var/sector = round(SIMPLIFY_DEGREES(delta_to_angle(hull_point[1] - hull_center_x, hull_point[2] - hull_center_y) + 360) / (360 / OVERMAP_HULL_SIGHT_SECTORS)) % OVERMAP_HULL_SIGHT_SECTORS
	LAZYINITLIST(hull_sight_cache)
	var/list/cached = hull_sight_cache["[sector]"]
	if(cached && world.time < cached[1])
		return cached[2]
	var/angle = sector * (360 / OVERMAP_HULL_SIGHT_SECTORS)
	var/turf/eye = locate(clamp(round(hull_center_x + distance * sin(angle), 1), flight_bounds[1], flight_bounds[3]), clamp(round(hull_center_y + distance * cos(angle), 1), flight_bounds[2], flight_bounds[4]), hull_z)
	var/list/turf/sighted = hull_seen_from(eye, CEILING(distance + hull_radius, 1))
	hull_sight_cache["[sector]"] = list(world.time + OVERMAP_HULL_SIGHT_REFRESH, sighted)
	return sighted

/obj/overmap/entity/proc/hull_seen_from(turf/eye, range)
	. = list()
	FOR_DVIEW(var/turf/seen, range, eye, 0)
		if(hull_turfs[seen])
			.[seen] = TRUE
	FOR_DVIEW_END

/obj/overmap/entity/proc/quarter_turns()
	return round(get_facing() / 90, 1) * 90

/obj/overmap/entity/proc/show_neighbors(list/flying, elapsed, watched)
	var/list/seen = list()
	var/list/nearby = list()
	for(var/obj/overmap/entity/other as anything in flying)
		if(other == src || other.sector != sector)
			continue
		var/list/spot = world_to_hull(other.get_world_x(), other.get_world_y())
		var/distance = sqrt((spot[1] - hull_center_x) ** 2 + (spot[2] - hull_center_y) ** 2) - hull_radius - other.hull_radius
		if(distance > OVERMAP_CONTACT_RANGE)
			continue
		nearby[other] = TRUE
		if(!watched || distance > OVERMAP_NEIGHBOR_RANGE)
			continue
		seen[other] = TRUE
		var/datum/hull_proxy/proxy = neighbor_proxies[other]
		if(QDELETED(proxy))
			proxy = new(other, locate(round(hull_center_x), round(hull_center_y), hull_z))
			neighbor_proxies[other] = proxy
		proxy.place(spot[1], spot[2], hull_z, other.get_facing() - get_facing(), flight_bounds, elapsed)
		proxy.refresh_sight(list(list(get_world_x(), get_world_y())))
	for(var/obj/overmap/entity/other as anything in neighbor_proxies)
		if(!seen[other])
			qdel(neighbor_proxies[other])
			neighbor_proxies -= other
	nearby_ships = nearby

/obj/overmap/entity/proc/radar_contacts()
	. = list(list("id" = UID(), "x" = 0, "y" = 0, "rot" = 0, "own" = TRUE))
	for(var/obj/overmap/entity/other as anything in nearby_ships)
		var/list/spot = world_to_hull(other.get_world_x(), other.get_world_y())
		var/closing = ((speed[1] - other.speed[1]) * (other.get_world_x() - get_world_x()) + (speed[2] - other.speed[2]) * (other.get_world_y() - get_world_y()))
		var/distance = sqrt((other.get_world_x() - get_world_x()) ** 2 + (other.get_world_y() - get_world_y()) ** 2)
		. += list(list(
			"id" = other.UID(),
			"name" = other.get_overmap_display_name(),
			"x" = round(spot[1] - hull_center_x, 0.1),
			"y" = round(spot[2] - hull_center_y, 0.1),
			"rot" = round(other.get_facing() - get_facing(), 1),
			"distance" = round(distance, 1),
			"closing" = distance ? round(closing / distance * OVERMAP_TILE_SPAN * (1 SECONDS), 0.1) : 0,
			"docked" = other.docked_ship == src || docked_ship == other,
		))

/obj/overmap/entity/proc/radar_drifters()
	. = list()
	for(var/atom/movable/drifter as anything in drifter_mirrors)
		var/obj/effect/abstract/hull_proxy_tile/mirror = drifter_mirrors[drifter]
		. += list(list(round(mirror.x + mirror.pixel_x / ICON_SIZE_X - hull_center_x, 0.1), round(mirror.y + mirror.pixel_y / ICON_SIZE_Y - hull_center_y, 0.1)))

/obj/overmap/entity/proc/radar_engines()
	. = list()
	for(var/obj/machinery/ship_engine/engine as anything in engines)
		if(engine.omnidirectional || engine.z != hull_z)
			continue
		. += list(list(engine.x - hull_center_x, engine.y - hull_center_y, engine.dir, engine.firing))

/obj/overmap/entity/proc/radar_shapes()
	. = list()
	.[UID()] = radar_shape
	for(var/obj/overmap/entity/other as anything in nearby_ships)
		.[other.UID()] = other.radar_shape

/obj/overmap/entity/proc/push_radar()
	for(var/obj/machinery/computer/helm/helm as anything in helms)
		for(var/datum/tgui/ui as anything in helm.open_uis)
			ui.send_update(list("radar" = radar_contacts(), "radar_drifters" = radar_drifters(), "radar_engines" = radar_engines(), "facing" = round(get_facing()), "radar_world" = list(get_world_x(), get_world_y())))

/obj/overmap/entity/proc/show_drifters(list/bubbles, elapsed)
	var/list/seen = list()
	var/matrix/turned = matrix()
	turned.Turn(-get_facing())
	for(var/datum/overmap_bubble/bubble as anything in bubbles)
		if(bubble.sector != sector)
			continue
		for(var/atom/movable/drifter as anything in bubble.drifters)
			var/list/drifter_world = bubble.to_world(drifter.x, drifter.y)
			var/list/spot = world_to_hull(drifter_world[1], drifter_world[2])
			if(sqrt((spot[1] - hull_center_x) ** 2 + (spot[2] - hull_center_y) ** 2) > hull_radius + OVERMAP_DRIFTER_RANGE)
				continue
			seen[drifter] = TRUE
			var/obj/effect/abstract/hull_proxy_tile/mirror = drifter_mirrors[drifter]
			if(!mirror)
				mirror = new(null)
				mirror.vis_contents += drifter
				drifter_mirrors[drifter] = mirror
			mirror.glide(spot[1], spot[2], hull_z, turned, flight_bounds, elapsed)
	for(var/atom/movable/drifter as anything in drifter_mirrors)
		if(!seen[drifter])
			qdel(drifter_mirrors[drifter])
			drifter_mirrors -= drifter

/obj/overmap/entity/proc/foreign_hull_at(turf/exit_turf)
	var/list/exit_world = hull_to_world(exit_turf.x, exit_turf.y)
	for(var/obj/overmap/entity/other as anything in SSovermap.flying_vessels)
		if(other == src || other.sector != sector)
			continue
		var/turf/hull_turf = other.hull_turf_at(exit_world[1], exit_world[2])
		if(hull_turf)
			return list(other, hull_turf)

/obj/overmap/entity/proc/eject_to_bubble(atom/movable/thing, turf/exit_turf)
	var/obj/projectile/bullet = thing
	var/list/foreign = foreign_hull_at(exit_turf)
	var/turf/foreign_turf = foreign?[2]
	if(foreign_turf && !foreign_turf.is_blocked_turf(exclude_mobs = TRUE))
		var/obj/overmap/entity/other = foreign[1]
		cross_frame_with_pull(thing, foreign_turf)
		if(istype(bullet))
			bullet.cross_frames(get_facing() - other.get_facing())
		else
			thing.setDir(turn(thing.dir || SOUTH, other.quarter_turns() - quarter_turns()))
		return TRUE
	var/list/exit_world = hull_to_world(exit_turf.x, exit_turf.y)
	var/datum/overmap_bubble/bubble = SSovermap.find_bubble(sector, exit_world[1], exit_world[2]) || SSovermap.create_bubble(sector, exit_world[1], exit_world[2], speed[1], speed[2])
	var/turf/landing = bubble?.turf_at(exit_world[1], exit_world[2])
	if(!landing)
		return FALSE
	if(istype(bullet))
		if(landing.is_blocked_turf())
			bump_into_hull(bullet, landing)
			return TRUE
		bullet.forceMove(landing)
		bullet.cross_frames(get_facing())
		return TRUE
	var/drift_dir = turn(thing.dir || SOUTH, -quarter_turns())
	for(var/step in 1 to OVERMAP_EJECT_CLEARANCE)
		if(!bubble.hull_under(landing))
			break
		landing = get_step(landing, drift_dir) || landing
	cross_frame_with_pull(thing, landing)
	thing.setDir(drift_dir)
	thing.newtonian_move(drift_dir)
	return TRUE

/datum/overmap_bubble
	var/datum/turf_reservation/reservation
	var/datum/overmap_sector/sector
	var/origin_x
	var/origin_y
	var/speed_x
	var/speed_y
	var/start_time
	var/center_x
	var/center_y
	var/bubble_z
	var/list/bounds
	var/area/space/overmap_bubble/bubble_area
	var/list/datum/hull_proxy/ship_proxies = list()
	var/list/obj/overmap/entity/ships = list()
	var/list/terrain_chunks = list()
	var/list/atom/movable/drifters = list()
	var/last_occupied
	var/static_level = FALSE
	var/list/radar_chunks = list()
	var/list/clingers = list()
	var/obj/overmap/entity/anchor

/datum/overmap_bubble/New(datum/overmap_sector/sector, origin_x, origin_y, speed_x, speed_y)
	src.sector = sector
	src.origin_x = origin_x
	src.origin_y = origin_y
	src.speed_x = speed_x
	src.speed_y = speed_y
	start_time = world.time
	last_occupied = world.time
	SSovermap.bubbles += src

/datum/overmap_bubble/proc/fill_reservation(datum/turf_reservation/reservation)
	src.reservation = reservation
	var/turf/bottom_left = reservation.bottom_left_turfs[1]
	var/turf/top_right = reservation.top_right_turfs[1]
	bounds = list(bottom_left.x, bottom_left.y, top_right.x, top_right.y)
	center_x = (bottom_left.x + top_right.x) / 2
	center_y = (bottom_left.y + top_right.y) / 2
	bubble_z = bottom_left.z
	for(var/turf/spot as anything in reservation.reserved_turfs)
		var/area/old_area = spot.loc
		LISTASSERTLEN(old_area.turfs_to_uncontain_by_zlevel, bubble_z, list())
		old_area.turfs_to_uncontain_by_zlevel[bubble_z] += spot
	bubble_area = new
	bubble_area.contents = reservation.reserved_turfs
	LISTASSERTLEN(bubble_area.turfs_by_zlevel, bubble_z, list())
	bubble_area.turfs_by_zlevel[bubble_z] = reservation.reserved_turfs.Copy()
	SSovermap.bubbles_by_reservation[reservation] = src

/datum/overmap_bubble/proc/fill_level(level)
	static_level = TRUE
	bubble_z = level
	bounds = list(1 + TRANSITIONEDGE, 1 + TRANSITIONEDGE, world.maxx - TRANSITIONEDGE, world.maxy - TRANSITIONEDGE)
	center_x = round(world.maxx / 2)
	center_y = round(world.maxy / 2)
	if(length(SSovermap.bubbles_by_z) < level)
		SSovermap.bubbles_by_z.len = level
	SSovermap.bubbles_by_z[level] = src

/datum/overmap_bubble/Destroy(force)
	SSovermap.bubbles -= src
	SSovermap.bubbles_by_reservation -= reservation
	if(static_level)
		SSovermap.bubbles_by_z[bubble_z] = null
	QDEL_LIST_ASSOC_VAL(ship_proxies)
	ships.Cut()
	terrain_chunks.Cut()
	clingers.Cut()
	for(var/atom/movable/drifter as anything in drifters.Copy())
		remove_drifter(drifter)
	reservation?.Release()
	reservation = null
	bubble_area = null
	sector = null
	var/obj/overmap/entity/station/ship/station_ship = anchor
	if(istype(station_ship) && station_ship.home_space == src)
		station_ship.home_space = null
	anchor = null
	return ..()

/datum/overmap_bubble/proc/drift_x()
	if(anchor)
		return anchor.get_world_x() - origin_x
	return speed_x * OVERMAP_TILE_SPAN * (world.time - start_time)

/datum/overmap_bubble/proc/drift_y()
	if(anchor)
		return anchor.get_world_y() - origin_y
	return speed_y * OVERMAP_TILE_SPAN * (world.time - start_time)

/datum/overmap_bubble/proc/drift_velocity()
	if(anchor)
		return anchor.speed
	return list(speed_x, speed_y)

/datum/overmap_bubble/proc/to_bubble(world_x, world_y)
	return list(center_x + world_x - origin_x - drift_x(), center_y + world_y - origin_y - drift_y())

/datum/overmap_bubble/proc/to_world(bubble_x, bubble_y)
	return list(bubble_x - center_x + origin_x + drift_x(), bubble_y - center_y + origin_y + drift_y())

/datum/overmap_bubble/proc/covers(list/spot, margin)
	return spot[1] >= bounds[1] - margin && spot[1] <= bounds[3] + margin && spot[2] >= bounds[2] - margin && spot[2] <= bounds[4] + margin

/datum/overmap_bubble/proc/turf_at(world_x, world_y)
	var/list/spot = to_bubble(world_x, world_y)
	if(!covers(spot, 0))
		return null
	return locate(CEILING(spot[1] - 0.5, 1), CEILING(spot[2] - 0.5, 1), bubble_z)

/datum/overmap_bubble/proc/hull_under(turf/spot)
	var/list/spot_world = to_world(spot.x, spot.y)
	for(var/obj/overmap/entity/vessel as anything in ships)
		var/turf/hull_turf = vessel.hull_turf_at(spot_world[1], spot_world[2])
		if(hull_turf)
			return list(vessel, hull_turf)

/datum/overmap_bubble/proc/process_bubble(list/flying, elapsed, list/eyes)
	var/list/seen = list()
	var/list/drawn = list()
	for(var/obj/overmap/entity/vessel as anything in flying)
		if(vessel.sector != sector)
			continue
		var/list/spot = to_bubble(vessel.get_world_x(), vessel.get_world_y())
		if(!covers(spot, vessel.hull_radius))
			continue
		seen[vessel] = TRUE
		if(!watched_near(spot, vessel.hull_radius + OVERMAP_NEIGHBOR_RANGE, eyes))
			continue
		drawn[vessel] = TRUE
		var/datum/hull_proxy/proxy = ship_proxies[vessel]
		if(QDELETED(proxy))
			proxy = new(vessel, locate(round(center_x), round(center_y), bubble_z), TRUE)
			ship_proxies[vessel] = proxy
		proxy.place(spot[1], spot[2], bubble_z, vessel.get_facing(), bounds, elapsed)
		var/list/viewer_points = list()
		var/reach = vessel.hull_radius + OVERMAP_NEIGHBOR_RANGE
		for(var/turf/eye as anything in eyes)
			if(eye.z == bubble_z && abs(eye.x - spot[1]) <= reach && abs(eye.y - spot[2]) <= reach)
				viewer_points += list(to_world(eye.x, eye.y))
		proxy.refresh_sight(viewer_points, TRUE)
	for(var/obj/overmap/entity/vessel as anything in ship_proxies)
		if(!drawn[vessel])
			qdel(ship_proxies[vessel])
			ship_proxies -= vessel
	ships = seen
	if(static_level && !length(ships))
		clingers.Cut()
		for(var/atom/movable/drifter as anything in drifters.Copy())
			remove_drifter(drifter)
		return
	carry_clingers()
	for(var/obj/overmap/entity/vessel as anything in ships)
		sweep_hull(vessel)
		grab_hull(vessel)
	for(var/atom/movable/drifter as anything in drifters.Copy())
		try_board(drifter)
	if(length(drifters))
		last_occupied = world.time

/datum/overmap_bubble/proc/watched_near(list/spot, reach, list/eyes)
	for(var/turf/eye as anything in eyes)
		if(eye.z == bubble_z && abs(eye.x - spot[1]) <= reach && abs(eye.y - spot[2]) <= reach)
			return TRUE
	return FALSE

/datum/overmap_bubble/proc/add_drifter(atom/movable/drifter)
	if(drifters[drifter])
		return
	drifters[drifter] = TRUE
	RegisterSignal(drifter, COMSIG_MOVABLE_SPACEMOVE, PROC_REF(on_drifter_spacemove))
	RegisterSignal(drifter, COMSIG_QDELETING, PROC_REF(on_drifter_deleted))

/datum/overmap_bubble/proc/remove_drifter(atom/movable/drifter)
	drifters -= drifter
	UnregisterSignal(drifter, list(COMSIG_MOVABLE_SPACEMOVE, COMSIG_QDELETING))

/datum/overmap_bubble/proc/on_drifter_deleted(atom/movable/drifter)
	SIGNAL_HANDLER
	remove_drifter(drifter)

/datum/overmap_bubble/proc/on_drifter_spacemove(atom/movable/drifter, movement_dir, continuous_move)
	SIGNAL_HANDLER
	for(var/turf/space/near in orange(1, drifter.loc))
		var/list/hull = hull_under(near)
		var/turf/hull_turf = hull?[2]
		if(hull_turf?.is_blocked_turf(exclude_mobs = TRUE))
			return COMSIG_MOVABLE_STOP_SPACEMOVE

/datum/overmap_bubble/proc/try_board(atom/movable/drifter, turf/approach)
	var/turf/spot = drifter.loc
	if(!isturf(spot))
		return FALSE
	var/list/hull = hull_under(spot)
	if(!hull)
		return FALSE
	var/obj/overmap/entity/vessel = hull[1]
	var/turf/hull_turf = hull[2]
	var/obj/projectile/bullet = drifter
	var/turf/entry = nearest_hull_edge(vessel, spot, TRUE, approach)
	if(!entry)
		if(!istype(bullet) && !hull_turf.is_blocked_turf(exclude_mobs = TRUE))
			shove_drifter(drifter, vessel)
		return FALSE
	var/board_dir = turn(drifter.dir || SOUTH, vessel.quarter_turns())
	cross_frame_with_pull(drifter, entry)
	if(istype(bullet))
		bullet.cross_frames(-vessel.get_facing())
	else
		drifter.setDir(board_dir)
	return TRUE

/datum/overmap_bubble/proc/nearest_hull_edge(obj/overmap/entity/vessel, turf/spot, open, turf/approach)
	var/list/spot_world = to_world(spot.x, spot.y)
	var/list/spot_hull = vessel.world_to_hull(spot_world[1], spot_world[2])
	var/list/approach_hull = spot_hull
	if(isturf(approach) && SSovermap.bubble_for_turf(approach) == src)
		var/list/approach_world = to_world(approach.x, approach.y)
		approach_hull = vessel.world_to_hull(approach_world[1], approach_world[2])
	var/base_x = FLOOR(spot_hull[1] + 0.5, 1)
	var/base_y = FLOOR(spot_hull[2] + 0.5, 1)
	var/turf/best
	var/best_score = INFINITY
	for(var/offset_x in -1 to 1)
		for(var/offset_y in -1 to 1)
			var/turf/candidate = locate(base_x + offset_x, base_y + offset_y, vessel.hull_z)
			if(!vessel.hull_edge[candidate])
				continue
			var/blocked = candidate.is_blocked_turf(exclude_mobs = TRUE)
			if(open ? blocked : !blocked)
				continue
			var/delta_x = spot_hull[1] - candidate.x
			var/delta_y = spot_hull[2] - candidate.y
			var/distance = sqrt(delta_x ** 2 + delta_y ** 2)
			if(distance > OVERMAP_BOARD_REACH)
				continue
			if(open && max(abs(delta_x), abs(delta_y)) > OVERMAP_TILE_EDGE)
				var/side_x = approach_hull[1] - candidate.x
				var/side_y = approach_hull[2] - candidate.y
				var/outside_x = abs(side_x) >= OVERMAP_BOARD_SIDE && !vessel.hull_turfs[locate(candidate.x + sign(side_x), candidate.y, vessel.hull_z)]
				var/outside_y = abs(side_y) >= OVERMAP_BOARD_SIDE && !vessel.hull_turfs[locate(candidate.x, candidate.y + sign(side_y), vessel.hull_z)]
				if(!outside_x && !outside_y)
					continue
			var/score = distance
			if(!open && (locate(/obj/machinery/door) in candidate))
				score -= OVERMAP_BOARD_DOOR_BIAS
			if(score < best_score)
				best_score = score
				best = candidate
	return best

/datum/overmap_bubble/proc/carry_clingers()
	for(var/mob/living/clinger as anything in clingers)
		var/list/hold = clingers[clinger]
		var/obj/overmap/entity/vessel = hold[1]
		if(QDELETED(clinger) || clinger.loc != hold[4] || !ships[vessel])
			continue
		var/list/spot_world = vessel.hull_to_world(hold[2], hold[3])
		var/turf/target = turf_at(spot_world[1], spot_world[2])
		if(!target || target == clinger.loc)
			continue
		var/list/hull = hull_under(target)
		var/turf/hull_turf = hull?[2]
		if(hull_turf?.is_blocked_turf(exclude_mobs = TRUE))
			continue
		cross_frame_with_pull(clinger, target)
	clingers.Cut()

/datum/overmap_bubble/proc/grab_hull(obj/overmap/entity/vessel)
	var/list/velocity = drift_velocity()
	var/relative_speed = sqrt((vessel.speed[1] - velocity[1]) ** 2 + (vessel.speed[2] - velocity[2]) ** 2) * OVERMAP_TILE_SPAN * (1 SECONDS)
	for(var/turf/hull_turf as anything in vessel.hull_edge)
		if(!hull_turf.is_blocked_turf(exclude_mobs = TRUE))
			continue
		for(var/direction in GLOB.cardinal)
			var/turf/outside = get_step(hull_turf, direction)
			if(!outside || vessel.hull_turfs[outside])
				continue
			var/list/spot_world = vessel.hull_to_world(outside.x, outside.y)
			var/turf/spot = turf_at(spot_world[1], spot_world[2])
			if(!isspaceturf(spot))
				continue
			for(var/mob/living/clinger in spot)
				if(clinger.anchored || clinger.buckled || clingers[clinger])
					continue
				if(relative_speed > (HAS_TRAIT(clinger, TRAIT_NEGATES_GRAVITY) ? OVERMAP_CLING_SPEED_MAGBOOTS : OVERMAP_CLING_SPEED))
					continue
				qdel(clinger.GetComponent(/datum/component/drift))
				add_drifter(clinger)
				clingers[clinger] = list(vessel, outside.x, outside.y, spot)

/datum/overmap_bubble/proc/sweep_hull(obj/overmap/entity/vessel)
	for(var/turf/hull_turf as anything in vessel.hull_edge)
		if(!hull_turf.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/list/spot_world = vessel.hull_to_world(hull_turf.x, hull_turf.y)
		var/turf/spot = turf_at(spot_world[1], spot_world[2])
		if(!isspaceturf(spot))
			continue
		for(var/atom/movable/thing in spot)
			if(thing.anchored || !thing.simulated || isobserver(thing))
				continue
			shove_drifter(thing, vessel)

/datum/overmap_bubble/proc/shove_drifter(atom/movable/drifter, obj/overmap/entity/vessel)
	var/list/velocity = drift_velocity()
	var/velocity_x = (vessel.speed[1] - velocity[1]) * OVERMAP_TILE_SPAN
	var/velocity_y = (vessel.speed[2] - velocity[2]) * OVERMAP_TILE_SPAN
	var/impact = sqrt(velocity_x ** 2 + velocity_y ** 2) * (1 SECONDS)
	var/preferred_dir
	if(impact >= 1)
		preferred_dir = angle2dir_cardinal(delta_to_angle(velocity_x, velocity_y))
	else
		var/list/drifter_world = to_world(drifter.x, drifter.y)
		preferred_dir = angle2dir_cardinal(delta_to_angle(drifter_world[1] - vessel.get_world_x(), drifter_world[2] - vessel.get_world_y()))
	var/push_dir
	var/turf/landing
	var/fewest_steps = CEILING(vessel.hull_radius * 2, 1) + 1
	for(var/direction in list(preferred_dir) + (GLOB.cardinal - preferred_dir))
		var/turf/cursor = drifter.loc
		for(var/step in 1 to fewest_steps - 1)
			cursor = get_step(cursor, direction)
			if(!cursor || !covers(list(cursor.x, cursor.y), 0))
				break
			if(hull_under(cursor))
				continue
			fewest_steps = step
			push_dir = direction
			landing = cursor
			break
		if(push_dir == preferred_dir && fewest_steps <= OVERMAP_SHOVE_CLEARANCE)
			break
	if(!landing)
		return
	drifter.forceMove(landing)
	drifter.newtonian_move(push_dir)
	if(!isliving(drifter) || impact < OVERMAP_SHOVE_HURT_SPEED || TIMER_COOLDOWN_RUNNING(drifter, COOLDOWN_OVERMAP_HULL_SHOVE))
		return
	var/mob/living/victim = drifter
	TIMER_COOLDOWN_START(victim, COOLDOWN_OVERMAP_HULL_SHOVE, OVERMAP_SHOVE_HURT_COOLDOWN)
	playsound(landing, 'sound/effects/bang.ogg', 50, TRUE)
	victim.Knockdown(2 SECONDS)
	victim.apply_damage(min(impact * 2, OVERMAP_SHOVE_MAX_DAMAGE), BRUTE)
	to_chat(victim, span_userdanger("Вас сбивает корпус корабля!"))

/proc/cross_frame_with_pull(atom/movable/mover, turf/destination)
	var/atom/movable/pulled = mover.pulling
	var/grip = mover.grab_state
	mover.forceMove(destination)
	if(QDELETED(pulled) || pulled.anchored || pulled.loc == destination)
		return
	pulled.forceMove(destination)
	INVOKE_ASYNC(mover, TYPE_PROC_REF(/atom/movable, start_pulling), pulled, grip, mover.pull_force, TRUE)

/datum/controller/subsystem/overmap/proc/frame_owner(turf/spot)
	return flight_reservations[SSmapping.used_turfs[spot]] || bubble_for_turf(spot)

/datum/controller/subsystem/overmap/proc/frame_sector(datum/owner)
	var/obj/overmap/entity/vessel = owner
	if(istype(vessel))
		return vessel.sector
	var/datum/overmap_bubble/bubble = owner
	return bubble.sector

/datum/controller/subsystem/overmap/proc/frame_to_world(datum/owner, turf/spot)
	var/obj/overmap/entity/vessel = owner
	if(istype(vessel))
		return vessel.hull_to_world(spot.x, spot.y)
	var/datum/overmap_bubble/bubble = owner
	return bubble.to_world(spot.x, spot.y)

/datum/controller/subsystem/overmap/proc/world_to_frame(datum/owner, world_x, world_y)
	var/obj/overmap/entity/vessel = owner
	if(!istype(vessel))
		var/datum/overmap_bubble/bubble = owner
		return bubble.turf_at(world_x, world_y)
	var/list/spot = vessel.world_to_hull(world_x, world_y)
	var/hull_x = FLOOR(spot[1] + 0.5, 1)
	var/hull_y = FLOOR(spot[2] + 0.5, 1)
	var/list/bounds = vessel.flight_bounds
	if(hull_x < bounds[1] || hull_x > bounds[3] || hull_y < bounds[2] || hull_y > bounds[4])
		return null
	return locate(hull_x, hull_y, vessel.hull_z)

/datum/controller/subsystem/overmap/proc/mirror_turf(turf/spot, turf/viewer_turf)
	var/datum/spot_owner = frame_owner(spot)
	var/datum/viewer_owner = frame_owner(viewer_turf)
	if(!spot_owner || !viewer_owner || spot_owner == viewer_owner || frame_sector(spot_owner) != frame_sector(viewer_owner))
		return null
	var/list/point = frame_to_world(spot_owner, spot)
	return world_to_frame(viewer_owner, point[1], point[2])

/datum/controller/subsystem/overmap/proc/mirror_target(atom/target, atom/viewer)
	if(!length(flying_vessels))
		return target
	var/turf/target_turf = get_turf(target)
	var/turf/viewer_turf = get_turf(viewer)
	if(!target_turf || !viewer_turf)
		return target
	return mirror_turf(target_turf, viewer_turf) || target

/datum/controller/subsystem/overmap/proc/mirror_explosion(datum/source, turf/epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, flame_range)
	SIGNAL_HANDLER
	if(mirroring_explosion || !length(flying_vessels) || !epicenter)
		return
	var/datum/origin = frame_owner(epicenter)
	if(!origin)
		return
	var/datum/overmap_sector/sector = frame_sector(origin)
	var/list/point = frame_to_world(origin, epicenter)
	var/reach = max(devastation_range, heavy_impact_range, light_impact_range, flame_range)
	var/list/datum/targets = list()
	for(var/obj/overmap/entity/vessel as anything in flying_vessels)
		if(vessel == origin || vessel.sector != sector)
			continue
		if(sqrt((vessel.get_world_x() - point[1]) ** 2 + (vessel.get_world_y() - point[2]) ** 2) <= vessel.hull_radius + reach)
			targets += vessel
	for(var/datum/overmap_bubble/bubble as anything in bubbles)
		if(bubble != origin && bubble.sector == sector && bubble.covers(bubble.to_bubble(point[1], point[2]), reach))
			targets += bubble
	mirroring_explosion = TRUE
	for(var/datum/target as anything in targets)
		var/turf/mirrored = world_to_frame(target, point[1], point[2])
		if(mirrored)
			explosion(mirrored, devastation_range, heavy_impact_range, light_impact_range, flash_range, adminlog = FALSE, flame_range = flame_range, smoke = FALSE, cause = "overmap explosion across hull")
	mirroring_explosion = FALSE

/datum/controller/subsystem/overmap/proc/radio_level(turf/position)
	if(!length(flying_vessels) || !station_sector)
		return position.z
	var/datum/owner = frame_owner(position)
	if(!owner || frame_sector(owner) != station_sector)
		return position.z
	station_radio_level ||= levels_by_trait(MAIN_STATION)[1]
	return station_radio_level

/proc/bump_into_hull(atom/movable/mover, turf/hull_turf)
	var/atom/blocker = hull_turf
	for(var/atom/movable/obstacle in hull_turf)
		if(obstacle.density)
			blocker = obstacle
			break
	mover.Bump(blocker)

/area/space/overmap_bubble
	name = "Open Space"
	area_flags = NONE

/turf/space/Enter(atom/movable/mover)
	. = ..()
	if(!. || !mover.simulated)
		return
	var/datum/overmap_bubble/bubble = SSovermap.bubble_for_turf(src)
	var/list/hull = bubble?.hull_under(src)
	if(!hull || bubble.nearest_hull_edge(hull[1], src, TRUE, mover.loc))
		return
	bump_into_hull(mover, bubble.nearest_hull_edge(hull[1], src, FALSE) || hull[2])
	return FALSE

/mob/dead/observer/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(length(SSovermap?.flying_vessels))
		SSovermap.cross_ghost_frame(src, movement_dir)

/datum/controller/subsystem/overmap/proc/cross_ghost_frame(mob/dead/observer/ghost, movement_dir)
	var/turf/spot = ghost.loc
	if(!isspaceturf(spot))
		return
	var/datum/overmap_bubble/bubble = bubble_for_turf(spot)
	if(bubble)
		var/list/hull = length(bubble.ships) && bubble.hull_under(spot)
		if(hull)
			ghost.abstract_move(hull[2])
		return
	var/obj/overmap/entity/vessel = flight_reservations[SSmapping.used_turfs[spot]]
	if(!vessel?.hull_turfs)
		return
	var/list/spot_world = vessel.hull_to_world(spot.x, spot.y)
	var/datum/overmap_bubble/outside = find_bubble(vessel.sector, spot_world[1], spot_world[2])
	var/turf/landing = outside?.turf_at(spot_world[1], spot_world[2])
	if(!landing)
		return
	var/exit_dir = turn(movement_dir || SOUTH, -vessel.quarter_turns())
	for(var/step in 1 to CEILING(vessel.hull_radius * 2, 1))
		if(!outside.hull_under(landing))
			ghost.abstract_move(landing)
			return
		landing = get_step(landing, exit_dir)
		if(!landing)
			return

/turf/space/transit/Enter(atom/movable/mover)
	. = ..()
	if(!. || !mover.simulated || !length(SSovermap.flying_vessels))
		return
	var/obj/overmap/entity/vessel = SSovermap.flight_reservations[SSmapping.used_turfs[src]]
	if(!vessel)
		return
	var/list/foreign = vessel.foreign_hull_at(src)
	var/turf/hull_turf = foreign?[2]
	if(!hull_turf?.is_blocked_turf(exclude_mobs = TRUE))
		return
	bump_into_hull(mover, hull_turf)
	return FALSE

/turf/space/Exited(atom/movable/gone, direction)
	. = ..()
	var/datum/overmap_bubble/bubble = SSovermap.bubble_for_turf(src)
	if(bubble?.drifters[gone] && SSovermap.bubble_for_turf(gone.loc) != bubble)
		bubble.remove_drifter(gone)

/datum/controller/subsystem/overmap/proc/bubble_for_turf(turf/spot)
	if(!isturf(spot))
		return null
	if(spot.z <= length(bubbles_by_z) && bubbles_by_z[spot.z])
		return bubbles_by_z[spot.z]
	return bubbles_by_reservation[SSmapping.used_turfs[spot]]

/datum/controller/subsystem/overmap/proc/on_space_entered(turf/space/spot, atom/movable/arrived, atom/old_loc)
	if(!arrived.simulated || isobserver(arrived) || arrived.loc != spot)
		return
	var/datum/overmap_bubble/bubble = bubble_for_turf(spot)
	if(!bubble || (bubble.static_level && !length(bubble.ships)))
		return
	bubble.add_drifter(arrived)
	bubble.try_board(arrived, old_loc)

/datum/controller/subsystem/overmap/proc/find_bubble(datum/overmap_sector/sector, world_x, world_y)
	for(var/datum/overmap_bubble/bubble as anything in bubbles)
		if(bubble.sector == sector && bubble.covers(bubble.to_bubble(world_x, world_y), -OVERMAP_BUBBLE_MARGIN))
			return bubble

/datum/controller/subsystem/overmap/proc/create_bubble(datum/overmap_sector/sector, world_x, world_y, speed_x, speed_y)
	if(!spare_bubble_space)
		return null
	var/datum/overmap_bubble/bubble = new(sector, world_x, world_y, speed_x, speed_y)
	bubble.fill_reservation(spare_bubble_space)
	spare_bubble_space = null
	return bubble

/datum/controller/subsystem/overmap/proc/prepare_bubble_space()
	if(spare_bubble_space || preparing_bubble_space || !length(flying_vessels))
		return
	preparing_bubble_space = TRUE
	INVOKE_ASYNC(src, PROC_REF(reserve_bubble_space))

/datum/controller/subsystem/overmap/proc/reserve_bubble_space()
	spare_bubble_space = SSmapping.request_turf_block_reservation(OVERMAP_BUBBLE_SIZE, OVERMAP_BUBBLE_SIZE)
	preparing_bubble_space = FALSE

/datum/controller/subsystem/overmap/proc/process_encounters(list/flying, elapsed, list/watched, list/eyes)
	for(var/obj/overmap/entity/vessel as anything in flying)
		if(vessel.docked_ship)
			vessel.follow_host()
		else
			vessel.keep_inside_local_space()
	for(var/obj/overmap/entity/vessel as anything in flying)
		if(vessel.hull_dirty)
			vessel.remap_hull()
	process_collisions(flying)
	for(var/obj/overmap/entity/vessel as anything in flying)
		var/is_watched = watched[vessel]
		vessel.show_neighbors(flying, elapsed, is_watched)
		if(is_watched)
			vessel.show_drifters(bubbles, elapsed)
			vessel.update_terrain_view(elapsed)
		else
			QDEL_LIST_ASSOC_VAL(vessel.drifter_mirrors)
			QDEL_NULL(vessel.terrain_view)
		vessel.try_autodock()
	for(var/datum/overmap_bubble/bubble as anything in bubbles)
		bubble.process_bubble(flying, elapsed, eyes)
	for(var/obj/overmap/entity/vessel as anything in flying)
		vessel.push_radar()

/datum/controller/subsystem/overmap/proc/expire_bubbles()
	prepare_bubble_space()
	for(var/datum/overmap_bubble/bubble as anything in bubbles.Copy())
		if(!bubble.static_level && !length(bubble.drifters) && world.time > bubble.last_occupied + OVERMAP_BUBBLE_TIMEOUT)
			qdel(bubble)

#undef OVERMAP_NEIGHBOR_RANGE
#undef OVERMAP_CONTACT_RANGE
#undef OVERMAP_DRIFTER_RANGE
#undef OVERMAP_BUBBLE_SIZE
#undef OVERMAP_BUBBLE_MARGIN
#undef OVERMAP_BUBBLE_TIMEOUT
#undef OVERMAP_EJECT_CLEARANCE
#undef OVERMAP_SHIP_DOCK_RANGE
#undef OVERMAP_SHIP_DOCK_ALIGN
#undef OVERMAP_SHIP_DOCK_SPEED
#undef OVERMAP_SHIP_UNDOCK_PUSH
#undef OVERMAP_SHIP_DOCK_SHAKE_TIME
#undef OVERMAP_SHIP_AUTODOCK_RANGE
#undef OVERMAP_SHIP_AUTODOCK_ALIGN
#undef OVERMAP_SHIP_AUTODOCK_SPEED
#undef OVERMAP_SHIP_REDOCK_COOLDOWN
#undef OVERMAP_SHIP_DOCK_SHAKE_STRENGTH
#undef OVERMAP_SHOVE_CLEARANCE
#undef OVERMAP_SHOVE_HURT_SPEED
#undef OVERMAP_SHOVE_MAX_DAMAGE
#undef OVERMAP_SHOVE_HURT_COOLDOWN
#undef OVERMAP_BOARD_REACH
#undef OVERMAP_BOARD_SIDE
#undef OVERMAP_BOARD_DOOR_BIAS
#undef OVERMAP_HULL_SIGHT_SECTORS
#undef OVERMAP_HULL_SIGHT_DISTANCE
#undef OVERMAP_HULL_SIGHT_NEAR_RANGE
#undef OVERMAP_HULL_SIGHT_REFRESH
#undef OVERMAP_CLING_SPEED
#undef OVERMAP_CLING_SPEED_MAGBOOTS
#undef OVERMAP_RADAR_DOCK_RANGE
