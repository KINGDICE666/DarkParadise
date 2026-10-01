/datum/component/overmap_flight
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/burn_delay = 1 SECONDS
	var/last_burn = 0
	var/engines_state = TRUE
	var/held_brake = FALSE
	var/thrust_limit = 1
	var/autopilot = FALSE
	var/autopilot_x
	var/autopilot_y
	var/facing = 0
	var/angular_velocity = 0
	var/mob/living/pilot
	var/obj/machinery/computer/helm/pilot_helm

	var/cruise_speed = OVERMAP_FROM_DISPLAY(OVERMAP_CRUISE_DEFAULT)

/datum/component/overmap_flight/Initialize()
	if(!istype(parent, /obj/overmap/entity))
		return COMPONENT_INCOMPATIBLE
	if(istype(parent, /obj/overmap/entity/pod))
		cruise_speed = OVERMAP_FROM_DISPLAY(OVERMAP_POD_CRUISE)

/datum/component/overmap_flight/RegisterWithParent()
	var/obj/overmap/entity/token = parent
	token.flight = src
	SSovermap?.flights |= src

/datum/component/overmap_flight/UnregisterFromParent()
	release_pilot()
	var/obj/overmap/entity/token = parent
	if(token.flight == src)
		token.flight = null
	SSovermap?.flights -= src

/datum/component/overmap_flight/proc/token()
	RETURN_TYPE(/obj/overmap/entity)
	return parent

/datum/component/overmap_flight/proc/needs_physics()
	var/obj/overmap/entity/vessel = parent
	if(held_brake || autopilot || pilot)
		return TRUE
	return vessel.movable && !vessel.halted && vessel.is_moving()

/datum/component/overmap_flight/proc/process_tick(elapsed)
	var/obj/overmap/entity/vessel = parent
	if(QDELETED(vessel) || vessel.docked_ship)
		return
	if(vessel.is_jumping())
		vessel.process_jump()
		return
	var/turn_input = 0
	if(pilot)
		turn_input = process_pilot(elapsed)
	spin(turn_input, elapsed)
	if(!needs_physics())
		return
	if(held_brake)
		brake(elapsed)
	process_autopilot(elapsed)
	if(autopilot)
		if(vessel.is_moving())
			steer_towards(delta_to_angle(vessel.speed[1], vessel.speed[2]), elapsed)
		enforce_cruise_speed(elapsed)
	vessel.process_movement(elapsed)

/datum/component/overmap_flight/proc/get_turn_rate()
	var/obj/overmap/entity/vessel = parent
	if(!engines_state || !can_steer())
		return 0
	var/thrust = get_total_thrust()
	if(thrust <= 0)
		return 0
	return clamp(thrust / max(vessel.total_mass(), 1) * OVERMAP_TURN_RATE_PER_THRUST, OVERMAP_TURN_RATE_MIN, OVERMAP_TURN_RATE_MAX)

/datum/component/overmap_flight/proc/set_facing(new_facing)
	facing = SIMPLIFY_DEGREES(new_facing)

/datum/component/overmap_flight/proc/spin(turn_input, elapsed)
	if(!turn_input && !angular_velocity)
		return
	var/turn_rate = get_turn_rate()
	var/target = turn_input * turn_rate
	var/spin_step = turn_rate * elapsed / OVERMAP_SPIN_UP_TIME
	if(angular_velocity > target)
		angular_velocity = max(angular_velocity - spin_step, target)
	else
		angular_velocity = min(angular_velocity + spin_step, target)
	if(angular_velocity)
		set_facing(facing + angular_velocity * elapsed)

/datum/component/overmap_flight/proc/steer_towards(target_angle, elapsed)
	var/max_turn = get_turn_rate() * elapsed
	var/difference = closer_angle_difference(facing, target_angle)
	if(!max_turn || abs(difference) < 1)
		return
	angular_velocity = 0
	set_facing(facing + clamp(difference, -max_turn, max_turn))

/datum/component/overmap_flight/proc/take_pilot(mob/living/new_pilot, obj/machinery/computer/helm/helm)
	release_pilot()
	pilot = new_pilot
	pilot_helm = helm
	autopilot = FALSE
	held_brake = FALSE
	engines_state = TRUE
	SEND_SIGNAL(parent, COMSIG_OVERMAP_MANUAL_CONTROL)
	RegisterSignal(pilot, COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, PROC_REF(block_pilot_walk))
	RegisterSignals(pilot, list(COMSIG_KB_MOB_DROPITEM_DOWN, COMSIG_KB_HUMAN_QUICKEQUIP_DOWN), PROC_REF(block_pilot_hotkey))
	RegisterSignal(pilot, COMSIG_QDELETING, PROC_REF(release_pilot))
	RegisterSignal(pilot_helm, COMSIG_QDELETING, PROC_REF(release_pilot))

/datum/component/overmap_flight/proc/release_pilot()
	SIGNAL_HANDLER
	if(pilot)
		UnregisterSignal(pilot, list(COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, COMSIG_KB_MOB_DROPITEM_DOWN, COMSIG_KB_HUMAN_QUICKEQUIP_DOWN, COMSIG_QDELETING))
	if(pilot_helm)
		UnregisterSignal(pilot_helm, COMSIG_QDELETING)
	pilot = null
	pilot_helm = null

/datum/component/overmap_flight/proc/block_pilot_walk()
	SIGNAL_HANDLER
	return COMSIG_MOB_CLIENT_BLOCK_PRE_LIVING_MOVE

/datum/component/overmap_flight/proc/block_pilot_hotkey()
	SIGNAL_HANDLER
	return COMSIG_KB_ACTIVATED

/datum/component/overmap_flight/proc/pilot_can_fly()
	var/obj/overmap/entity/vessel = parent
	if(!pilot.client || pilot.incapacitated() || !pilot_helm.can_pilot(pilot))
		return FALSE
	if(pilot_helm.stat & (NOPOWER|BROKEN))
		return FALSE
	if(vessel.is_overmap_jammed() || vessel.is_programmed_locked())
		return FALSE
	return can_steer()

/datum/component/overmap_flight/proc/process_pilot(elapsed)
	if(!pilot_can_fly())
		to_chat(pilot, span_warning("Вы отпускаете штурвал."))
		release_pilot()
		return 0
	var/list/keys = pilot.client.keys_held
	if(keys["Space"])
		brake(elapsed)
	var/direction = pilot.client.intended_direction
	var/forward = !!(direction & NORTH) - !!(direction & SOUTH)
	var/sideways = (!!(direction & EAST) - !!(direction & WEST)) * OVERMAP_STRAFE_THRUST
	if(forward || sideways)
		push(forward * sin(facing) + sideways * cos(facing), forward * cos(facing) - sideways * sin(facing), elapsed)
	return !!keys["E"] - !!keys["Q"]

/datum/component/overmap_flight/proc/thrust_step(elapsed)
	return get_total_thrust() / inertial_mass() / burn_delay * elapsed

/datum/component/overmap_flight/proc/push(direction_x, direction_y, elapsed)
	var/obj/overmap/entity/vessel = parent
	if(!engines_state || !can_steer())
		return
	if(world.time >= last_burn + burn_delay)
		last_burn = world.time
		apply_thrust()
	var/step = thrust_step(elapsed)
	vessel.speed[1] += step * direction_x
	vessel.speed[2] += step * direction_y
	var/current = sqrt(vessel.speed[1] ** 2 + vessel.speed[2] ** 2)
	if(current > vessel.max_speed)
		vessel.speed[1] *= vessel.max_speed / current
		vessel.speed[2] *= vessel.max_speed / current
	vessel.refresh_heading_overlay()

/datum/component/overmap_flight/proc/brake(elapsed)
	var/obj/overmap/entity/vessel = parent
	var/current = sqrt(vessel.speed[1] ** 2 + vessel.speed[2] ** 2)
	var/step = thrust_step(elapsed)
	if(!current || !step)
		return
	var/power = min(current / step, 1)
	push(-vessel.speed[1] / current * power, -vessel.speed[2] / current * power, elapsed)

/datum/component/overmap_flight/proc/get_total_thrust()
	. = 0
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		. += engine.get_thrust()

/datum/component/overmap_flight/proc/inertial_mass()
	var/obj/overmap/entity/vessel = parent
	return max(vessel.total_mass(), 1) * OVERMAP_MASS_INERTIA

/datum/component/overmap_flight/proc/get_acceleration()
	return round(get_total_thrust() / inertial_mass(), OVERMAP_MOVE_RESOLUTION)

/datum/component/overmap_flight/proc/has_working_engines()
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		if(engine.can_burn())
			return TRUE
	return FALSE

/datum/component/overmap_flight/proc/can_steer()
	var/obj/overmap/entity/vessel = parent
	return (vessel.status == OVERMAP_STATUS_OVERMAP || vessel.status == OVERMAP_STATUS_TRANSIT) && !vessel.halted && isturf(vessel.loc)

/datum/component/overmap_flight/proc/set_held_brake(enabled)
	if(!can_steer())
		return FALSE
	autopilot = FALSE
	if(enabled)
		SEND_SIGNAL(parent, COMSIG_OVERMAP_MANUAL_CONTROL)
		engines_state = TRUE
		held_brake = TRUE
	else
		held_brake = FALSE
	return TRUE

/datum/component/overmap_flight/proc/cut_engines()
	held_brake = FALSE
	engines_state = !engines_state
	return TRUE

/datum/component/overmap_flight/proc/apply_thrust()
	. = 0
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		. += engine.apply_thrust()

/datum/component/overmap_flight/proc/enforce_cruise_speed(elapsed)
	var/obj/overmap/entity/vessel = parent
	var/current = vessel.get_speed()
	if(current <= get_effective_cruise() || current <= 0)
		return
	var/delta = thrust_step(elapsed)
	if(delta <= 0)
		return
	var/excess = current - get_effective_cruise()
	var/new_speed = (delta >= excess) ? get_effective_cruise() : (current - delta)
	var/scale = new_speed / current
	vessel.speed[1] *= scale
	vessel.speed[2] *= scale
	vessel.refresh_heading_overlay()

/datum/component/overmap_flight/proc/get_brake_distance()
	var/obj/overmap/entity/vessel = parent
	var/accel = get_acceleration()
	var/current = vessel.get_speed()
	if(!accel || current < vessel.min_speed || !burn_delay)
		return 0
	var/accel_per_ds = accel / burn_delay
	if(accel_per_ds <= 0)
		return 0
	return (current * current) / (2 * accel_per_ds) + 0.2

/datum/component/overmap_flight/proc/set_autopilot(enabled, dest_x, dest_y)
	var/obj/overmap/entity/vessel = parent
	var/was_on = autopilot
	autopilot = enabled
	if(was_on && !autopilot)
		SEND_SIGNAL(vessel, COMSIG_OVERMAP_MANUAL_CONTROL)
	if(autopilot)
		release_pilot()
		held_brake = FALSE
		engines_state = TRUE
	if(!isnull(dest_x))
		autopilot_x = dest_x
	if(!isnull(dest_y))
		autopilot_y = dest_y
	if(vessel.sector)
		if(!isnull(autopilot_x))
			autopilot_x = clamp(round(autopilot_x), 1, vessel.sector.size)
		if(!isnull(autopilot_y))
			autopilot_y = clamp(round(autopilot_y), 1, vessel.sector.size)
	if(autopilot && (isnull(autopilot_x) || isnull(autopilot_y)))
		autopilot = FALSE

/datum/component/overmap_flight/proc/process_autopilot(elapsed)
	var/obj/overmap/entity/vessel = parent
	if(!autopilot || held_brake || (vessel.local_space && !vessel.programmed_mission))
		return
	if(isnull(autopilot_x) || isnull(autopilot_y))
		return
	var/turf/here = vessel.get_overmap_turf()
	if(!here || !can_steer())
		return
	var/turf/target = vessel.sector?.get_turf_at(autopilot_x, autopilot_y)
	if(!target || target.z != here.z)
		return
	if(here == target)
		arrive_autopilot()
		return
	var/dx = target.x - here.x
	var/dy = target.y - here.y
	var/distance = sqrt(dx * dx + dy * dy)
	if(distance <= 0)
		arrive_autopilot()
		return
	engines_state = TRUE
	var/current = vessel.get_speed()
	var/cruise = get_effective_cruise()
	if(cruise <= 0)
		cruise = max(cruise_speed, OVERMAP_FROM_DISPLAY(OVERMAP_PROGRAMMED_CRUISE))
	var/brake_dist = get_brake_distance()
	var/remaining = remaining_to_enter_turf(target)
	if(remaining > 0 && remaining <= brake_dist && current > vessel.min_speed)
		brake(elapsed)
		vessel.refresh_heading_overlay()
		return
	if(current > cruise * 1.02)
		brake(elapsed)
		vessel.refresh_heading_overlay()
		return
	if(current >= cruise * 0.98)
		var/sx = vessel.speed[1]
		var/sy = vessel.speed[2]
		var/align = (sx * dx + sy * dy) / (max(current, OVERMAP_MOVE_RESOLUTION) * distance)
		if(align > 0.97)
			vessel.refresh_heading_overlay()
			return
	push(dx / distance, dy / distance, elapsed)

/datum/component/overmap_flight/proc/arrive_autopilot()
	var/obj/overmap/entity/vessel = parent
	var/turf/target = vessel.sector?.get_turf_at(autopilot_x, autopilot_y)
	if(target && isturf(vessel.loc) && vessel.loc != target && target.z == vessel.z)
		vessel.forceMove(target)
		vessel.position = list(0, 0)
		vessel.update_overmap_pixel()
	vessel.speed[1] = 0
	vessel.speed[2] = 0
	autopilot = FALSE
	vessel.refresh_heading_overlay()
	notify_arrival()

/datum/component/overmap_flight/proc/get_effective_cruise()
	var/obj/overmap/entity/vessel = parent
	var/limit = cruise_speed
	if(vessel.programmed && vessel.is_programmed_locked())
		limit = min(limit, OVERMAP_FROM_DISPLAY(OVERMAP_PROGRAMMED_CRUISE))
	if(!vessel.programmed_mission)
		return limit
	if(vessel.overmap_hazard_immune)
		return limit
	var/safe = OVERMAP_FROM_DISPLAY(OVERMAP_HAZARD_SAFE_SPEED)
	var/remaining = remaining_to_hazard_on_course()
	if(remaining >= INFINITY)
		return limit
	var/need = brake_distance_to_speed(safe)
	if(need <= 0)
		if(remaining <= remaining_to_next_course_tile())
			limit = min(limit, safe)
		return limit
	if(remaining <= need)
		limit = min(limit, safe)
	return limit

/datum/component/overmap_flight/proc/brake_distance_to_speed(target_speed)
	var/obj/overmap/entity/vessel = parent
	var/current = vessel.get_speed()
	if(current <= target_speed)
		return 0
	var/accel = get_acceleration()
	if(!accel || !burn_delay)
		return 0
	var/accel_per_ds = accel / burn_delay
	if(accel_per_ds <= 0)
		return 0
	return ((current * current) - (target_speed * target_speed)) / (2 * accel_per_ds)

/datum/component/overmap_flight/proc/remaining_to_next_course_tile()
	var/obj/overmap/entity/vessel = parent
	var/turf/here = vessel.get_overmap_turf()
	var/turf/target = vessel.sector?.get_turf_at(autopilot_x, autopilot_y)
	if(!here || !target || here == target)
		return 0
	return remaining_to_tile_edge(sign(target.x - here.x), sign(target.y - here.y))

/datum/component/overmap_flight/proc/remaining_to_tile_edge(dir_x, dir_y)
	var/obj/overmap/entity/vessel = parent
	if(!dir_x && !dir_y)
		return 0
	var/best
	if(dir_x)
		best = (dir_x > 0 ? OVERMAP_TILE_EDGE : -OVERMAP_TILE_EDGE) - vessel.position[1]
	if(dir_y)
		var/need = (dir_y > 0 ? OVERMAP_TILE_EDGE : -OVERMAP_TILE_EDGE) - vessel.position[2]
		best = isnull(best) ? need : max(best, need)
	return max(best, 0)

/datum/component/overmap_flight/proc/remaining_to_enter_turf(turf/spot)
	var/obj/overmap/entity/vessel = parent
	var/turf/here = vessel.get_overmap_turf()
	if(!here || !spot || here.z != spot.z)
		return INFINITY
	if(here == spot)
		return 0
	var/steps = max(abs(spot.x - here.x), abs(spot.y - here.y))
	return remaining_to_tile_edge(sign(spot.x - here.x), sign(spot.y - here.y)) + (steps - 1)

/datum/component/overmap_flight/proc/remaining_to_hazard_on_course()
	var/obj/overmap/entity/vessel = parent
	var/turf/here = vessel.get_overmap_turf()
	if(!here || !vessel.sector)
		return INFINITY
	if(locate_hazard_on_turf(here))
		return 0
	if(!autopilot_x || !autopilot_y)
		return INFINITY
	var/turf/target = vessel.sector.get_turf_at(autopilot_x, autopilot_y)
	if(!target)
		return INFINITY
	var/tx = here.x
	var/ty = here.y
	var/first_dx = 0
	var/first_dy = 0
	var/steps = 0
	while(steps < 48 && (tx != target.x || ty != target.y))
		if(tx < target.x)
			tx++
			if(!steps)
				first_dx = 1
		else if(tx > target.x)
			tx--
			if(!steps)
				first_dx = -1
		if(ty < target.y)
			ty++
			if(!steps)
				first_dy = 1
		else if(ty > target.y)
			ty--
			if(!steps)
				first_dy = -1
		steps++
		var/turf/spot = locate(tx, ty, here.z)
		if(locate_hazard_on_turf(spot))
			return remaining_to_tile_edge(first_dx, first_dy) + (steps - 1)
	return INFINITY

/datum/component/overmap_flight/proc/locate_hazard_on_turf(turf/spot)
	if(!spot)
		return FALSE
	for(var/atom/thing as anything in spot.contents)
		if(istype(thing, /obj/overmap/feature/hazard))
			return TRUE
	return FALSE

/datum/component/overmap_flight/proc/notify_arrival()
	var/obj/overmap/entity/vessel = parent
	vessel.programmed_mission?.on_overmap_arrived()

/obj/overmap/entity/proc/get_total_thrust()
	return flight ? flight.get_total_thrust() : 0

/obj/overmap/entity/proc/get_acceleration()
	return flight ? flight.get_acceleration() : 0

/obj/overmap/entity/proc/has_working_engines()
	return !!flight?.has_working_engines()

/obj/overmap/entity/proc/can_steer()
	return !!flight?.can_steer()

/obj/overmap/entity/proc/set_held_brake(enabled)
	return flight?.set_held_brake(enabled)

/obj/overmap/entity/proc/cut_engines()
	return flight?.cut_engines()

/obj/overmap/entity/proc/get_effective_acceleration()
	return get_acceleration()

/obj/overmap/entity/proc/get_brake_distance()
	return flight ? flight.get_brake_distance() : 0

/obj/overmap/entity/proc/set_autopilot(enabled, dest_x, dest_y)
	flight?.set_autopilot(enabled, dest_x, dest_y)
