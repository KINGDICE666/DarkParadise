/datum/component/overmap_flight/proc/navigation_speed_limited()
	return autopilot

/datum/component/overmap_flight/proc/clear_navigation()
	navigation?.reset()
	navigation_world_x = null
	navigation_world_y = null
	navigation_facing = null
	navigation_host = null
	navigation_arrival_range = OVERMAP_AUTOPILOT_ARRIVE_RANGE
	navigation_ignore_collisions = FALSE
	navigation_known_obstacles_only = TRUE
	navigation_pass_through = FALSE
	navigation_next_point = null
	navigation_rails = FALSE
	rail_speed = 0

/datum/component/overmap_flight/proc/navigate_world(world_x, world_y, heading, obj/overmap/entity/host, arrival_range = OVERMAP_AUTOPILOT_ARRIVE_RANGE, ignore_collisions = FALSE, known_obstacles_only = TRUE, pass_through = FALSE, list/next_point, rails = FALSE)
	if(!autopilot)
		release_pilot()
		held_brake = FALSE
		engines_state = TRUE
		autopilot = TRUE
	navigation_world_x = world_x
	navigation_world_y = world_y
	navigation_facing = heading
	navigation_host = host
	navigation_arrival_range = arrival_range
	navigation_ignore_collisions = ignore_collisions
	navigation_known_obstacles_only = known_obstacles_only
	navigation_pass_through = pass_through
	navigation_next_point = next_point
	navigation_rails = rails
	var/obj/overmap/entity/vessel = parent
	if(vessel.sector)
		var/span = OVERMAP_TILE_SPAN * vessel.sector.tile_travel
		autopilot_x = world_x / span - vessel.sector.origin_x + 1
		autopilot_y = world_y / span - vessel.sector.origin_y + 1

/datum/component/overmap_flight/proc/process_navigation(elapsed)
	var/obj/overmap/entity/vessel = parent
	if(held_brake || !can_steer() || !vessel.sector)
		return
	var/goal_x = navigation_world_x
	var/goal_y = navigation_world_y
	if(isnull(goal_x) || isnull(goal_y))
		if(!QDELETED(navigation_target) && navigation_target.sector == vessel.sector && isturf(navigation_target.loc))
			var/dx = vessel.get_world_x() - navigation_target.get_world_x()
			var/dy = vessel.get_world_y() - navigation_target.get_world_y()
			var/distance = sqrt(dx ** 2 + dy ** 2)
			var/standoff = vessel.hull_radius + navigation_target.hull_radius + 12
			goal_x = navigation_target.get_world_x() + (distance ? dx / distance : 0) * standoff
			goal_y = navigation_target.get_world_y() + (distance ? dy / distance : 1) * standoff
			var/list/extent = navigation_target.physical_space?.navigation_extent
			if(extent)
				var/margin = vessel.hull_radius + 4
				goal_x = clamp(vessel.get_world_x(), extent[1] - margin, extent[3] + margin)
				goal_y = clamp(vessel.get_world_y(), extent[2] - margin, extent[4] + margin)
		else
			if(isnull(autopilot_x) || isnull(autopilot_y))
				brake(elapsed)
				return
			var/span = OVERMAP_TILE_SPAN * vessel.sector.tile_travel
			goal_x = (vessel.sector.origin_x + autopilot_x - 1) * span
			goal_y = (vessel.sector.origin_y + autopilot_y - 1) * span
	if(!navigation)
		navigation = new(src)
	var/list/waypoint = navigation.waypoint(goal_x, goal_y, navigation_host)
	if(!waypoint)
		autopilot_status = navigation.planning ? "Прокладывает маршрут" : "Проход перекрыт: ожидание"
		brake(elapsed)
		return
	var/dx = waypoint[1] - vessel.get_world_x()
	var/dy = waypoint[2] - vessel.get_world_y()
	var/distance = sqrt(dx ** 2 + dy ** 2)
	var/final_leg = abs(waypoint[1] - goal_x) + abs(waypoint[2] - goal_y) < 0.1
	var/arrival_range = navigation_arrival_range
	var/passed = navigation_next_point && distance <= arrival_range * OVERMAP_AUTOPILOT_PASS_SLACK && dx * (goal_x - navigation_next_point[1]) + dy * (goal_y - navigation_next_point[2]) >= 0
	if(final_leg && navigation_pass_through && (distance <= arrival_range || passed))
		finish_navigation()
		return
	if(final_leg && distance <= arrival_range && vessel.get_speed() * OVERMAP_TILE_SPAN <= OVERMAP_AUTOPILOT_ARRIVE_SPEED)
		if(!isnull(navigation_facing) && abs(closer_angle_difference(facing, navigation_facing)) > 2)
			brake(elapsed)
			return navigation_facing
		finish_navigation()
		return
	var/accel = engine_thrust / inertial_mass() / burn_delay * OVERMAP_TILE_SPAN * OVERMAP_AUTOPILOT_ACCEL_MARGIN
	var/safe_speed = sqrt(2 * accel * (max(distance - 0.5, 0) + navigation_carry(final_leg, goal_x, goal_y)))
	var/wanted_speed = min(get_effective_cruise() * OVERMAP_TILE_SPAN, safe_speed)
	var/lateral = distance ? abs(vessel.speed[1] * dy - vessel.speed[2] * dx) / distance * OVERMAP_TILE_SPAN : 0
	if(lateral)
		wanted_speed = min(wanted_speed, accel * distance / lateral)
	var/hold_orientation = !isnull(navigation_facing) && distance <= max(64, vessel.hull_radius * 4)
	var/list/host_region = navigation_host?.physical_space?.region
	if(!isnull(navigation_facing) && host_region)
		var/gap_x = max(host_region[1] - vessel.get_world_x(), vessel.get_world_x() - host_region[3], 0)
		var/gap_y = max(host_region[2] - vessel.get_world_y(), vessel.get_world_y() - host_region[4], 0)
		hold_orientation ||= max(gap_x, gap_y) <= max(64, vessel.hull_radius * 4)
	if(!isnull(navigation_facing))
		var/heading_error = abs(closer_angle_difference(facing, hold_orientation ? navigation_facing : delta_to_angle(dx, dy)))
		wanted_speed *= max(0, cos(heading_error)) ** 2
	var/aim = match_navigation_velocity(distance ? dx / distance * wanted_speed : 0, distance ? dy / distance * wanted_speed : 0, elapsed)
	autopilot_status = navigation.force_passage ? "Аварийный проход без коллизии" : (length(navigation.path) > 1 ? "Обходит препятствие" : "Идёт к цели")
	if(hold_orientation)
		return navigation_facing
	if(!isnull(navigation_facing) && distance > max(arrival_range * 2, 3))
		return delta_to_angle(dx, dy)
	return final_leg && !isnull(navigation_facing) ? navigation_facing : aim

/datum/component/overmap_flight/proc/match_navigation_velocity(wanted_x, wanted_y, elapsed)
	var/obj/overmap/entity/vessel = parent
	var/wanted_speed = sqrt(wanted_x ** 2 + wanted_y ** 2)
	var/limit = get_effective_cruise() * OVERMAP_TILE_SPAN
	if(wanted_speed > limit)
		wanted_x *= limit / wanted_speed
		wanted_y *= limit / wanted_speed
	var/error_x = wanted_x - vessel.speed[1] * OVERMAP_TILE_SPAN
	var/error_y = wanted_y - vessel.speed[2] * OVERMAP_TILE_SPAN
	var/error = sqrt(error_x ** 2 + error_y ** 2)
	if(error <= OVERMAP_AUTOPILOT_DEADBAND)
		return
	var/accel = engine_thrust / inertial_mass() / burn_delay * OVERMAP_TILE_SPAN
	var/effort = accel ? min(1, error / max(accel * elapsed, 0.001)) : 1
	push(error_x / error * effort, error_y / error * effort, elapsed)
	if(error > OVERMAP_AUTOPILOT_TURN_ERROR)
		return delta_to_angle(error_x, error_y)

/datum/component/overmap_flight/proc/navigation_carry(final_leg, goal_x, goal_y)
	var/obj/overmap/entity/vessel = parent
	var/list/here = list(vessel.get_world_x(), vessel.get_world_y())
	if(!final_leg)
		return navigation.corner_carry(here)
	if(!navigation_pass_through)
		return 0
	if(!navigation_next_point)
		return OVERMAP_AUTOPILOT_PASS_CARRY
	return overmap_corner_carry(here, list(goal_x, goal_y), navigation_next_point, sqrt((navigation_next_point[1] - goal_x) ** 2 + (navigation_next_point[2] - goal_y) ** 2))

/datum/component/overmap_flight/proc/finish_navigation()
	var/obj/overmap/entity/vessel = parent
	navigation.reset()
	if(navigation_pass_through)
		navigation_world_x = null
		navigation_world_y = null
		navigation_next_point = null
		autopilot_x = null
		autopilot_y = null
		notify_arrival()
		return
	vessel.speed[1] = 0
	vessel.speed[2] = 0
	rail_speed = 0
	if(!isnull(navigation_facing))
		set_facing(navigation_facing)
	angular_velocity = 0
	autopilot = FALSE
	vessel.refresh_heading_overlay()
	notify_arrival()

/datum/component/overmap_flight/proc/slow_rail(elapsed, accel)
	var/obj/overmap/entity/vessel = parent
	var/current = vessel.get_speed() * OVERMAP_TILE_SPAN
	rail_speed = max(0, min(rail_speed, current) - accel * elapsed)
	if(!current)
		return
	vessel.speed[1] *= rail_speed / current
	vessel.speed[2] *= rail_speed / current

/datum/component/overmap_flight/proc/process_rail(elapsed)
	var/obj/overmap/entity/vessel = parent
	var/cruise = get_effective_cruise() * OVERMAP_TILE_SPAN
	var/accel = cruise / OVERMAP_RAIL_RAMP_TIME
	if(isnull(navigation_world_x) || isnull(navigation_world_y) || !vessel.sector)
		slow_rail(elapsed, accel)
		return
	if(!navigation)
		navigation = new(src)
	var/list/waypoint = navigation.waypoint(navigation_world_x, navigation_world_y, navigation_host)
	if(!waypoint)
		autopilot_status = "Прокладывает маршрут"
		slow_rail(elapsed, accel)
		return
	var/dx = waypoint[1] - vessel.get_world_x()
	var/dy = waypoint[2] - vessel.get_world_y()
	var/distance = sqrt(dx ** 2 + dy ** 2)
	var/final_leg = abs(waypoint[1] - navigation_world_x) + abs(waypoint[2] - navigation_world_y) < 0.1
	if(final_leg && distance <= OVERMAP_RAIL_SNAP)
		finish_navigation()
		return
	if(!distance)
		return
	rail_speed = min(cruise, rail_speed + accel * elapsed, sqrt(2 * accel * (distance + navigation_carry(final_leg, navigation_world_x, navigation_world_y))))
	var/travel = min(distance, rail_speed * elapsed)
	vessel.speed[1] = dx / distance * travel / elapsed / OVERMAP_TILE_SPAN
	vessel.speed[2] = dy / distance * travel / elapsed / OVERMAP_TILE_SPAN
	burn_sides |= NORTH
	autopilot_status = "Идёт по маршруту"
	return delta_to_angle(dx, dy)
