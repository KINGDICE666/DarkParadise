#define OVERMAP_NEIGHBOR_RANGE 24
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

/obj/overmap/entity/proc/map_hull()
	hull_turfs = list()
	var/min_x = world.maxx
	var/max_x = 1
	var/min_y = world.maxy
	var/max_y = 1
	for(var/turf/hull_turf as anything in shuttle.return_turfs())
		if(!shuttle.shuttle_areas[get_area(hull_turf)])
			continue
		hull_turfs[hull_turf] = TRUE
		min_x = min(min_x, hull_turf.x)
		max_x = max(max_x, hull_turf.x)
		min_y = min(min_y, hull_turf.y)
		max_y = max(max_y, hull_turf.y)
	hull_center_x = (min_x + max_x) / 2
	hull_center_y = (min_y + max_y) / 2
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
	hull_radius = sqrt((max_x - min_x) ** 2 + (max_y - min_y) ** 2) / 2 + 1
	var/obj/docking_port/stationary/transit/pad = shuttle.get_docked()
	flight_bounds = (istype(pad) && hyperspace_reservation_bounds(pad.reserved_area)) || list(1, 1, world.maxx, world.maxy)
	if(istype(pad) && pad.reserved_area)
		flight_reservation = pad.reserved_area
		SSovermap.flight_reservations[flight_reservation] = src

/obj/overmap/entity/proc/clear_encounter_visuals()
	undock_ship()
	QDEL_NULL(terrain_view)
	for(var/obj/overmap/entity/guest as anything in docked_guests.Copy())
		guest.undock_ship()
	QDEL_LIST_ASSOC_VAL(neighbor_proxies)
	QDEL_LIST_ASSOC_VAL(drifter_mirrors)
	SSovermap.flight_reservations -= flight_reservation
	flight_reservation = null
	hull_turfs = null
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

/obj/overmap/entity/proc/dock_to_nearest_ship()
	if(docked_ship)
		return "Корабль уже пристыкован."
	for(var/obj/overmap/entity/other as anything in neighbor_proxies)
		if(relative_speed(other) > OVERMAP_SHIP_DOCK_SPEED)
			continue
		var/list/pair = find_dock_pair(other)
		if(pair)
			dock_to_ship(other, pair[1], pair[2])
			return TRUE
	return "Рядом нет подходящего шлюза. Подведите стыковочный шлюз вплотную к шлюзу другого корабля и уравняйте скорость."

/obj/overmap/entity/proc/relative_speed(obj/overmap/entity/other)
	return sqrt((speed[1] - other.speed[1]) ** 2 + (speed[2] - other.speed[2]) ** 2) * OVERMAP_TILE_SPAN

/obj/overmap/entity/proc/try_autodock()
	if(docked_ship || length(docked_guests) || world.time < next_autodock)
		return
	for(var/obj/overmap/entity/other as anything in neighbor_proxies)
		if(other.docked_ship || relative_speed(other) > OVERMAP_SHIP_AUTODOCK_SPEED)
			continue
		if(flight.pilot && !other.flight.pilot)
			continue
		var/list/pair = find_dock_pair(other, OVERMAP_SHIP_AUTODOCK_RANGE, OVERMAP_SHIP_AUTODOCK_ALIGN)
		if(pair)
			dock_to_ship(other, pair[1], pair[2])
			return

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

/obj/overmap/entity/proc/world_to_hull(world_x, world_y)
	var/delta_x = world_x - get_world_x()
	var/delta_y = world_y - get_world_y()
	var/facing = get_facing()
	return list(hull_center_x + delta_x * cos(facing) - delta_y * sin(facing), hull_center_y + delta_x * sin(facing) + delta_y * cos(facing))

/obj/overmap/entity/proc/hull_to_world(hull_x, hull_y)
	var/local_x = hull_x - hull_center_x
	var/local_y = hull_y - hull_center_y
	var/facing = get_facing()
	return list(get_world_x() + local_x * cos(facing) + local_y * sin(facing), get_world_y() - local_x * sin(facing) + local_y * cos(facing))

/obj/overmap/entity/proc/hull_turf_at(world_x, world_y)
	var/list/spot = world_to_hull(world_x, world_y)
	var/turf/hull_turf = locate(FLOOR(spot[1] + 0.5, 1), FLOOR(spot[2] + 0.5, 1), hull_z)
	return hull_turfs[hull_turf] ? hull_turf : null

/obj/overmap/entity/proc/quarter_turns()
	return round(get_facing() / 90, 1) * 90

/obj/overmap/entity/proc/show_neighbors(list/flying, elapsed)
	var/list/seen = list()
	for(var/obj/overmap/entity/other as anything in flying)
		if(other == src || other.sector != sector)
			continue
		var/list/spot = world_to_hull(other.get_world_x(), other.get_world_y())
		if(sqrt((spot[1] - hull_center_x) ** 2 + (spot[2] - hull_center_y) ** 2) > hull_radius + other.hull_radius + OVERMAP_NEIGHBOR_RANGE)
			continue
		seen[other] = TRUE
		var/datum/hull_proxy/proxy = neighbor_proxies[other]
		if(QDELETED(proxy))
			proxy = new(other, locate(round(hull_center_x), round(hull_center_y), hull_z))
			neighbor_proxies[other] = proxy
		proxy.place(spot[1], spot[2], hull_z, other.get_facing() - get_facing(), flight_bounds, elapsed)
	for(var/obj/overmap/entity/other as anything in neighbor_proxies)
		if(!seen[other])
			qdel(neighbor_proxies[other])
			neighbor_proxies -= other

/obj/overmap/entity/proc/radar_contacts()
	. = list(list("id" = UID(), "x" = 0, "y" = 0, "rot" = 0, "own" = TRUE))
	for(var/obj/overmap/entity/other as anything in neighbor_proxies)
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

/obj/overmap/entity/proc/radar_shapes()
	. = list()
	.[UID()] = radar_shape
	for(var/obj/overmap/entity/other as anything in neighbor_proxies)
		.[other.UID()] = other.radar_shape

/obj/overmap/entity/proc/push_radar()
	for(var/obj/machinery/computer/helm/helm as anything in helms)
		for(var/datum/tgui/ui as anything in helm.open_uis)
			ui.send_update(list("radar" = radar_contacts(), "radar_drifters" = radar_drifters(), "facing" = round(get_facing()), "radar_world" = list(get_world_x(), get_world_y())))

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
		thing.forceMove(foreign_turf)
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
	thing.forceMove(landing)
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
	var/list/atom/movable/drifters = list()
	var/last_occupied
	var/static_level = FALSE

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
	for(var/atom/movable/drifter as anything in drifters.Copy())
		remove_drifter(drifter)
	reservation?.Release()
	reservation = null
	bubble_area = null
	sector = null
	return ..()

/datum/overmap_bubble/proc/drift_x()
	return speed_x * OVERMAP_TILE_SPAN * (world.time - start_time)

/datum/overmap_bubble/proc/drift_y()
	return speed_y * OVERMAP_TILE_SPAN * (world.time - start_time)

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
	for(var/obj/overmap/entity/vessel as anything in ship_proxies)
		var/turf/hull_turf = vessel.hull_turf_at(spot_world[1], spot_world[2])
		if(hull_turf)
			return list(vessel, hull_turf)

/datum/overmap_bubble/proc/process_bubble(list/flying, elapsed)
	var/list/seen = list()
	for(var/obj/overmap/entity/vessel as anything in flying)
		if(vessel.sector != sector)
			continue
		var/list/spot = to_bubble(vessel.get_world_x(), vessel.get_world_y())
		if(!covers(spot, vessel.hull_radius))
			continue
		seen[vessel] = TRUE
		var/datum/hull_proxy/proxy = ship_proxies[vessel]
		if(QDELETED(proxy))
			proxy = new(vessel, locate(round(center_x), round(center_y), bubble_z))
			ship_proxies[vessel] = proxy
		proxy.place(spot[1], spot[2], bubble_z, vessel.get_facing(), bounds, elapsed)
	for(var/obj/overmap/entity/vessel as anything in ship_proxies)
		if(!seen[vessel])
			qdel(ship_proxies[vessel])
			ship_proxies -= vessel
	if(static_level && !length(ship_proxies))
		for(var/atom/movable/drifter as anything in drifters.Copy())
			remove_drifter(drifter)
		return
	for(var/atom/movable/drifter as anything in drifters.Copy())
		try_board(drifter)
	if(length(drifters))
		last_occupied = world.time

/datum/overmap_bubble/proc/add_drifter(atom/movable/drifter)
	if(drifters[drifter])
		return
	drifters[drifter] = TRUE
	RegisterSignal(drifter, COMSIG_MOVABLE_SPACEMOVE, PROC_REF(on_drifter_spacemove))

/datum/overmap_bubble/proc/remove_drifter(atom/movable/drifter)
	drifters -= drifter
	UnregisterSignal(drifter, COMSIG_MOVABLE_SPACEMOVE)

/datum/overmap_bubble/proc/on_drifter_spacemove(atom/movable/drifter, movement_dir, continuous_move)
	SIGNAL_HANDLER
	for(var/turf/space/near in orange(1, drifter.loc))
		var/list/hull = hull_under(near)
		var/turf/hull_turf = hull?[2]
		if(hull_turf?.is_blocked_turf(exclude_mobs = TRUE))
			return COMSIG_MOVABLE_STOP_SPACEMOVE

/datum/overmap_bubble/proc/try_board(atom/movable/drifter)
	var/turf/spot = drifter.loc
	if(!isturf(spot))
		return FALSE
	var/list/hull = hull_under(spot)
	if(!hull)
		return FALSE
	var/obj/overmap/entity/vessel = hull[1]
	var/turf/hull_turf = hull[2]
	if(hull_turf.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	var/board_dir = turn(drifter.dir || SOUTH, vessel.quarter_turns())
	drifter.forceMove(hull_turf)
	var/obj/projectile/bullet = drifter
	if(istype(bullet))
		bullet.cross_frames(-vessel.get_facing())
	else
		drifter.setDir(board_dir)
	return TRUE

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
	var/turf/hull_turf = hull?[2]
	if(!hull_turf?.is_blocked_turf(exclude_mobs = TRUE))
		return
	bump_into_hull(mover, hull_turf)
	return FALSE

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

/datum/controller/subsystem/overmap/proc/on_space_entered(turf/space/spot, atom/movable/arrived)
	if(!arrived.simulated || isobserver(arrived) || arrived.loc != spot)
		return
	var/datum/overmap_bubble/bubble = bubble_for_turf(spot)
	if(!bubble || (bubble.static_level && !length(bubble.ship_proxies)))
		return
	bubble.add_drifter(arrived)
	bubble.try_board(arrived)

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

/datum/controller/subsystem/overmap/proc/process_encounters(list/flying, elapsed)
	for(var/obj/overmap/entity/vessel as anything in flying)
		if(vessel.docked_ship)
			vessel.follow_host()
		else
			vessel.keep_inside_local_space()
	process_collisions(flying)
	for(var/obj/overmap/entity/vessel as anything in flying)
		vessel.show_neighbors(flying, elapsed)
		vessel.show_drifters(bubbles, elapsed)
		vessel.update_terrain_view(elapsed)
		vessel.try_autodock()
	for(var/datum/overmap_bubble/bubble as anything in bubbles)
		bubble.process_bubble(flying, elapsed)
	for(var/obj/overmap/entity/vessel as anything in flying)
		vessel.push_radar()

/datum/controller/subsystem/overmap/proc/expire_bubbles()
	prepare_bubble_space()
	for(var/datum/overmap_bubble/bubble as anything in bubbles.Copy())
		if(!bubble.static_level && !length(bubble.drifters) && world.time > bubble.last_occupied + OVERMAP_BUBBLE_TIMEOUT)
			qdel(bubble)

#undef OVERMAP_NEIGHBOR_RANGE
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
