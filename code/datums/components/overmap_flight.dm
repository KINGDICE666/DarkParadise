/datum/component/overmap_flight
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/burn_delay = 1 SECONDS
	var/last_burn = 0
	var/engines_state = TRUE
	var/held_brake = FALSE
	var/dampeners = TRUE
	var/thrust_limit = 1
	var/autopilot = FALSE
	var/autopilot_x
	var/autopilot_y
	var/facing = 0
	var/angular_velocity = 0
	var/mob/living/pilot
	var/obj/machinery/computer/helm/pilot_helm
	var/pilot_turn = 0
	var/thrust_north = 0
	var/thrust_east = 0
	var/thrust_south = 0
	var/thrust_west = 0
	var/torque_left = 0
	var/torque_right = 0
	var/omni_thrust = FALSE
	var/list/engine_torques = list()
	var/burn_sides = NONE
	var/burn_turn = 0
	var/was_burning = FALSE
	var/next_jolt = 0

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
	stop_burn()
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
		stop_burn()
		vessel.process_jump()
		return
	refresh_thrust()
	burn_sides = NONE
	burn_turn = 0
	var/manual_drive = FALSE
	if(pilot)
		manual_drive = process_pilot(elapsed)
	var/aim
	if(autopilot && needs_physics())
		aim = process_autopilot(elapsed)
	if(isnull(aim))
		change_spin(pilot_turn * OVERMAP_TURN_RATE_MAX, elapsed)
	else
		steer_towards(aim - main_axis_angle(), elapsed)
	if(needs_physics())
		if(held_brake || (dampeners && !manual_drive && !autopilot && vessel.shuttle))
			brake(elapsed)
		if(autopilot)
			enforce_cruise_speed(elapsed)
		vessel.process_movement(elapsed)
	update_burn()

/datum/component/overmap_flight/proc/refresh_thrust()
	var/obj/overmap/entity/vessel = parent
	thrust_north = 0
	thrust_east = 0
	thrust_south = 0
	thrust_west = 0
	torque_left = 0
	torque_right = 0
	engine_torques.Cut()
	omni_thrust = !vessel.hull_turfs || !!vessel.programmed_mission
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		var/thrust = engine.get_thrust()
		if(!thrust)
			continue
		if(omni_thrust || engine.omnidirectional)
			thrust_north += thrust
			thrust_east += thrust
			thrust_south += thrust
			thrust_west += thrust
			var/arm = max(vessel.hull_radius / 2, 1)
			torque_left += thrust * arm
			torque_right += thrust * arm
			continue
		var/push = REVERSE_DIR(engine.dir)
		switch(push)
			if(NORTH)
				thrust_north += thrust
			if(EAST)
				thrust_east += thrust
			if(SOUTH)
				thrust_south += thrust
			if(WEST)
				thrust_west += thrust
		var/turf/engine_turf = get_turf(engine)
		var/arm_x = engine_turf.x - vessel.hull_center_x
		var/arm_y = engine_turf.y - vessel.hull_center_y
		var/torque = thrust * (arm_x * (!!(push & NORTH) - !!(push & SOUTH)) - arm_y * (!!(push & EAST) - !!(push & WEST)))
		engine_torques[engine] = torque
		if(torque > 0)
			torque_left += torque
		else
			torque_right -= torque

/datum/component/overmap_flight/proc/strongest_thrust()
	return max(thrust_north, thrust_east, thrust_south, thrust_west)

/datum/component/overmap_flight/proc/main_axis_angle()
	var/strongest = strongest_thrust()
	if(thrust_north == strongest)
		return 0
	if(thrust_east == strongest)
		return 90
	if(thrust_south == strongest)
		return 180
	return 270

/datum/component/overmap_flight/proc/side_thrust(side)
	switch(side)
		if(NORTH)
			return thrust_north
		if(EAST)
			return thrust_east
		if(SOUTH)
			return thrust_south
		if(WEST)
			return thrust_west
	return 0

/datum/component/overmap_flight/proc/side_accel(thrust)
	return round(OVERMAP_DISPLAY_SPEED(thrust / inertial_mass()), 0.01)

/datum/component/overmap_flight/proc/angular_accel(torque)
	var/obj/overmap/entity/vessel = parent
	return torque * OVERMAP_TORQUE_SCALE / (max(vessel.total_mass(), 1) * vessel.hull_inertia)

/datum/component/overmap_flight/proc/flip_time()
	var/accel = angular_accel(min(torque_left, torque_right))
	if(!accel)
		return 0
	return max(2 * sqrt(180 / accel), 180 / OVERMAP_TURN_RATE_MAX)

/datum/component/overmap_flight/proc/set_facing(new_facing)
	facing = SIMPLIFY_DEGREES(new_facing)
	if(facing < 0)
		facing += 360

/datum/component/overmap_flight/proc/change_spin(wanted, elapsed)
	if(!wanted && !angular_velocity)
		return
	if(wanted != angular_velocity && engines_state && can_steer())
		var/turning = wanted > angular_velocity ? 1 : -1
		var/spin_step = angular_accel(turning > 0 ? torque_right : torque_left) * elapsed
		if(spin_step > 0)
			burn_turn = turning
			if(turning > 0)
				angular_velocity = min(angular_velocity + spin_step, wanted)
			else
				angular_velocity = max(angular_velocity - spin_step, wanted)
	if(angular_velocity)
		set_facing(facing + angular_velocity * elapsed)

/datum/component/overmap_flight/proc/steer_towards(target_angle, elapsed)
	var/difference = closer_angle_difference(facing, target_angle)
	var/braking = angular_accel(min(torque_left, torque_right)) || angular_accel(max(torque_left, torque_right))
	var/wanted = 0
	if(abs(difference) >= 1)
		wanted = sign(difference) * min(OVERMAP_TURN_RATE_MAX, sqrt(2 * braking * abs(difference)))
	change_spin(wanted, elapsed)

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
	pilot_turn = 0

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
		return FALSE
	var/list/keys = pilot.client.keys_held
	pilot_turn = !!keys["E"] - !!keys["Q"]
	if(keys["Space"])
		brake(elapsed)
		return TRUE
	var/direction = pilot.client.intended_direction
	var/forward = !!(direction & NORTH) - !!(direction & SOUTH)
	var/sideways = !!(direction & EAST) - !!(direction & WEST)
	if(!forward && !sideways)
		return FALSE
	push_local(sideways, forward, elapsed)
	return TRUE

/datum/component/overmap_flight/proc/thrust_step(elapsed)
	return strongest_thrust() / inertial_mass() / burn_delay * elapsed

/datum/component/overmap_flight/proc/push(direction_x, direction_y, elapsed)
	push_local(direction_x * cos(facing) - direction_y * sin(facing), direction_x * sin(facing) + direction_y * cos(facing), elapsed)

/datum/component/overmap_flight/proc/push_local(local_x, local_y, elapsed)
	var/obj/overmap/entity/vessel = parent
	if(!engines_state || !can_steer())
		return
	var/side_x = local_x > 0 ? EAST : WEST
	var/side_y = local_y > 0 ? NORTH : SOUTH
	var/scale = elapsed / inertial_mass() / burn_delay
	var/accel_x = local_x * side_thrust(side_x) * scale
	var/accel_y = local_y * side_thrust(side_y) * scale
	if(accel_x)
		burn_sides |= side_x
	if(accel_y)
		burn_sides |= side_y
	if(!accel_x && !accel_y)
		return
	var/before = sqrt(vessel.speed[1] ** 2 + vessel.speed[2] ** 2)
	vessel.speed[1] += accel_x * cos(facing) + accel_y * sin(facing)
	vessel.speed[2] += accel_y * cos(facing) - accel_x * sin(facing)
	var/limit = min(vessel.max_speed, max(top_speed(), before))
	var/current = sqrt(vessel.speed[1] ** 2 + vessel.speed[2] ** 2)
	if(current > limit)
		vessel.speed[1] *= limit / current
		vessel.speed[2] *= limit / current
	vessel.refresh_heading_overlay()

/datum/component/overmap_flight/proc/top_speed()
	var/obj/overmap/entity/vessel = parent
	if(!vessel.shuttle || omni_thrust)
		return vessel.max_speed
	return clamp(strongest_thrust() / inertial_mass() / burn_delay * OVERMAP_TOP_SPEED_TIME, OVERMAP_FROM_DISPLAY(OVERMAP_TOP_SPEED_MIN), OVERMAP_FROM_DISPLAY(OVERMAP_TOP_SPEED_MAX))

/datum/component/overmap_flight/proc/brake(elapsed)
	var/obj/overmap/entity/vessel = parent
	if(!vessel.is_moving() || !engines_state || !can_steer())
		return
	var/local_x = vessel.speed[1] * cos(facing) - vessel.speed[2] * sin(facing)
	var/local_y = vessel.speed[1] * sin(facing) + vessel.speed[2] * cos(facing)
	var/scale = OVERMAP_BRAKE_COEFFICIENT * elapsed / inertial_mass() / burn_delay
	var/side_x = local_x > 0 ? WEST : EAST
	var/side_y = local_y > 0 ? SOUTH : NORTH
	var/slow_x = min(abs(local_x), side_thrust(side_x) * scale)
	var/slow_y = min(abs(local_y), side_thrust(side_y) * scale)
	if(slow_x)
		burn_sides |= side_x
		local_x -= sign(local_x) * slow_x
	if(slow_y)
		burn_sides |= side_y
		local_y -= sign(local_y) * slow_y
	vessel.speed[1] = local_x * cos(facing) + local_y * sin(facing)
	vessel.speed[2] = local_y * cos(facing) - local_x * sin(facing)
	if(abs(vessel.speed[1]) < OVERMAP_MOVE_RESOLUTION * 0.01 && abs(vessel.speed[2]) < OVERMAP_MOVE_RESOLUTION * 0.01)
		vessel.speed[1] = 0
		vessel.speed[2] = 0
	vessel.refresh_heading_overlay()

/datum/component/overmap_flight/proc/update_burn()
	var/obj/overmap/entity/vessel = parent
	var/burning = burn_sides || burn_turn
	if(burning && !was_burning)
		jolt_crew()
	was_burning = burning
	var/drain = burning && world.time >= last_burn + burn_delay
	if(drain)
		last_burn = world.time
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		var/firing = engine_fires(engine)
		engine.set_firing(firing)
		if(firing && drain)
			engine.apply_thrust()

/datum/component/overmap_flight/proc/jolt_crew()
	var/obj/overmap/entity/vessel = parent
	if(!vessel.shuttle || world.time < next_jolt || side_accel(strongest_thrust()) < OVERMAP_JOLT_ACCEL)
		return
	next_jolt = world.time + OVERMAP_JOLT_COOLDOWN
	for(var/area/place as anything in vessel.shuttle.shuttle_areas)
		for(var/mob/living/passenger in place)
			if(passenger.client && !passenger.buckled && !HAS_TRAIT(passenger, TRAIT_NEGATES_GRAVITY))
				shake_camera(passenger, OVERMAP_JOLT_SHAKE_TIME, 1)

/datum/component/overmap_flight/proc/engine_fires(obj/machinery/ship_engine/engine)
	if(!burn_sides && !burn_turn)
		return FALSE
	if(!(engine in engine_torques))
		return omni_thrust || engine.omnidirectional
	if(REVERSE_DIR(engine.dir) & burn_sides)
		return TRUE
	return engine_torques[engine] * burn_turn < 0

/datum/component/overmap_flight/proc/stop_burn()
	var/obj/overmap/entity/vessel = parent
	burn_sides = NONE
	burn_turn = 0
	was_burning = FALSE
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		engine.set_firing(FALSE)

/datum/component/overmap_flight/proc/get_total_thrust()
	. = 0
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		. += engine.get_thrust()

/datum/component/overmap_flight/proc/inertial_mass()
	var/obj/overmap/entity/vessel = parent
	return max(vessel.total_mass(), 1) * OVERMAP_MASS_INERTIA

/datum/component/overmap_flight/proc/get_acceleration()
	return round(strongest_thrust() / inertial_mass(), OVERMAP_MOVE_RESOLUTION)

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
	if(held_brake || (vessel.local_space && !vessel.programmed_mission))
		return
	if(isnull(autopilot_x) || isnull(autopilot_y))
		return
	var/turf/here = vessel.get_overmap_turf()
	if(!here || !can_steer())
		return
	var/turf/target = vessel.sector?.get_turf_at(autopilot_x, autopilot_y)
	if(!target || target.z != here.z)
		return
	if(vessel.free_flight_view && !vessel.programmed_mission)
		return fly_to(target, elapsed)
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
		return velocity_angle()
	if(current > cruise * 1.02)
		brake(elapsed)
		return velocity_angle()
	if(current >= cruise * 0.98)
		var/sx = vessel.speed[1]
		var/sy = vessel.speed[2]
		var/align = (sx * dx + sy * dy) / (max(current, OVERMAP_MOVE_RESOLUTION) * distance)
		if(align > 0.97)
			return velocity_angle()
	push(dx / distance, dy / distance, elapsed)
	var/aim = velocity_angle()
	return isnull(aim) ? delta_to_angle(dx, dy) : aim

/datum/component/overmap_flight/proc/velocity_angle()
	var/obj/overmap/entity/vessel = parent
	if(!vessel.is_moving())
		return null
	return delta_to_angle(vessel.speed[1], vessel.speed[2])

/datum/component/overmap_flight/proc/fly_to(turf/target, elapsed)
	var/obj/overmap/entity/vessel = parent
	var/span = OVERMAP_TILE_SPAN * vessel.sector.tile_travel
	var/offset_x = target.x * span - vessel.get_world_x()
	var/offset_y = target.y * span - vessel.get_world_y()
	var/distance = sqrt(offset_x ** 2 + offset_y ** 2)
	var/velocity_x = vessel.speed[1] * OVERMAP_TILE_SPAN
	var/velocity_y = vessel.speed[2] * OVERMAP_TILE_SPAN
	var/current = sqrt(velocity_x ** 2 + velocity_y ** 2)
	if(distance <= OVERMAP_AUTOPILOT_ARRIVE_RANGE && current <= OVERMAP_AUTOPILOT_ARRIVE_SPEED)
		vessel.speed[1] = 0
		vessel.speed[2] = 0
		autopilot = FALSE
		vessel.refresh_heading_overlay()
		notify_arrival()
		return
	engines_state = TRUE
	var/accel = get_acceleration() / burn_delay * OVERMAP_TILE_SPAN * OVERMAP_AUTOPILOT_ACCEL_MARGIN
	var/flip = flip_time()
	var/safe_speed = accel ? accel * (sqrt(flip ** 2 + 2 * distance / accel) - flip) : 0
	var/wanted_speed = min(min(get_effective_cruise(), top_speed()) * OVERMAP_TILE_SPAN, safe_speed)
	var/error_x = (distance ? offset_x / distance * wanted_speed : 0) - velocity_x
	var/error_y = (distance ? offset_y / distance * wanted_speed : 0) - velocity_y
	var/error = sqrt(error_x ** 2 + error_y ** 2)
	if(error < OVERMAP_AUTOPILOT_DEADBAND)
		return
	var/effort = accel ? min(1, error / (accel / OVERMAP_AUTOPILOT_ACCEL_MARGIN * elapsed)) : 1
	push(error_x / error * effort, error_y / error * effort, elapsed)
	if(error < OVERMAP_AUTOPILOT_TURN_ERROR)
		return
	return delta_to_angle(error_x, error_y)

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
