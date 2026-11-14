/datum/component/overmap_flight
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/burn_delay = 1 SECONDS
	var/engines_state = TRUE
	var/held_brake = FALSE
	var/thrust_limit = 1
	var/autopilot = FALSE
	var/autopilot_x
	var/autopilot_y
	var/facing = 0
	var/angular_velocity = 0
	var/mob/pilot
	var/obj/machinery/computer/helm/pilot_helm
	var/pilot_turn = 0
	var/engine_thrust = 0
	var/engine_torque = 0
	var/list/thrusting_engines = list()
	var/burn_sides = NONE
	var/burn_turn = 0
	var/was_burning = FALSE
	var/next_jolt = 0
	var/next_idle_thrust_refresh = 0
	var/fixed_facing = FALSE
	var/max_turn_rate = OVERMAP_TURN_RATE_MAX
	var/auto_brake = FALSE
	var/autopilot_turns = TRUE

	var/autopilot_status = ""
	var/cruise_speed = OVERMAP_FROM_DISPLAY(OVERMAP_CRUISE_DEFAULT)
	var/datum/overmap_navigation/navigation
	var/navigation_world_x
	var/navigation_world_y
	var/navigation_facing
	var/obj/overmap/entity/navigation_host
	var/obj/overmap/entity/navigation_target
	var/navigation_arrival_range = OVERMAP_AUTOPILOT_ARRIVE_RANGE
	var/navigation_ignore_collisions = FALSE
	var/navigation_known_obstacles_only = TRUE
	var/navigation_pass_through = FALSE
	var/list/navigation_next_point
	var/navigation_rails = FALSE
	var/rail_speed = 0
	var/drift_assist = TRUE
	var/heading_hold
	var/precision = FALSE
	var/bow_angle = 0
	var/burn_main = NONE
	var/burn_main_force = 0

/datum/component/overmap_flight/Initialize(fixed_facing = FALSE)
	if(!istype(parent, /obj/overmap/entity))
		return COMPONENT_INCOMPATIBLE
	src.fixed_facing = fixed_facing
	if(istype(parent, /obj/overmap/entity/pod))
		cruise_speed = OVERMAP_FROM_DISPLAY(OVERMAP_POD_CRUISE)

/datum/component/overmap_flight/RegisterWithParent()
	var/obj/overmap/entity/token = parent
	token.flight = src
	SSovermap?.flights |= src

/datum/component/overmap_flight/UnregisterFromParent()
	QDEL_NULL(navigation)
	navigation_target = null
	navigation_host = null
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
	if(QDELETED(vessel) || vessel.formation_transfer || vessel.docked_ship || vessel.docking_approach?.aligning)
		return
	if(vessel.overmap_pod)
		var/obj/overmap/entity/pod/pod_vessel = vessel
		var/mob/living/seat_pilot = pod_vessel.pod?.pilot
		if(pod_vessel.is_physically_docked() || pod_vessel.overmap_pod.is_undocking())
			if(pilot)
				release_pilot()
			stop_burn()
			return
		if(!pod_vessel.in_free_flight())
			if(pilot)
				release_pilot()
		else if(seat_pilot?.client && !seat_pilot.incapacitated() && pilot != seat_pilot)
			take_pilot(seat_pilot, pod_vessel.pod.overmap_helm)
	if(vessel.relay_jump_from)
		stop_burn()
		angular_velocity = 0
		return
	if(!was_burning && !angular_velocity && isnull(heading_hold) && !needs_physics() && !vessel.is_moving())
		if(world.time >= next_idle_thrust_refresh)
			next_idle_thrust_refresh = world.time + OVERMAP_SLOW_TICK
			refresh_thrust()
		return
	refresh_thrust()
	burn_sides = NONE
	burn_main = NONE
	burn_main_force = 0
	burn_turn = 0
	var/manual_drive = FALSE
	if(pilot)
		manual_drive = process_pilot(elapsed)
	var/aim
	if(autopilot && needs_physics())
		aim = navigation_rails ? process_rail(elapsed) : process_autopilot(elapsed)
		if(!autopilot_turns)
			aim = null
	if(isnull(aim) && !pilot_turn)
		aim = held_heading()
	if(!isnull(aim))
		steer_towards(aim, elapsed)
	else if(pilot_turn)
		change_spin(pilot_turn * max_turn_rate, elapsed)
	else
		change_spin(0, elapsed)
	if(!autopilot && !manual_drive)
		apply_drag(elapsed)
	if(needs_physics())
		if(held_brake || (!manual_drive && !autopilot && (vessel.shuttle || vessel.overmap_pod || fixed_facing || auto_brake) && drift_assist))
			brake(elapsed)
		if(navigation_speed_limited() && (!vessel.overmap_pod || (engines_state && engine_thrust)))
			enforce_cruise_speed(elapsed)
			var/current = vessel.get_speed()
			var/limit = OVERMAP_FROM_DISPLAY(OVERMAP_PROGRAMMED_CRUISE)
			if(current > limit)
				vessel.speed[1] *= limit / current
				vessel.speed[2] *= limit / current
		vessel.process_movement(elapsed)
	update_burn(elapsed)

/datum/component/overmap_flight/proc/apply_drag(elapsed)
	var/obj/overmap/entity/vessel = parent
	if(vessel.overmap_pod && (!engines_state || !engine_thrust))
		return

	var/drag = 1 / (1 + OVERMAP_DRIFT_DAMPING * elapsed)
	angular_velocity *= drag
	if(abs(angular_velocity) < OVERMAP_SPIN_EPSILON)
		angular_velocity = 0
	if(!vessel.is_moving())
		return
	vessel.speed[1] *= drag
	vessel.speed[2] *= drag
	if(abs(vessel.speed[1]) < OVERMAP_SPEED_EPSILON && abs(vessel.speed[2]) < OVERMAP_SPEED_EPSILON)
		vessel.speed[1] = 0
		vessel.speed[2] = 0

/datum/component/overmap_flight/proc/refresh_thrust()
	var/obj/overmap/entity/vessel = parent
	engine_thrust = 0
	engine_torque = 0
	thrusting_engines.Cut()
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		if(engine == vessel.virtual_engine && !vessel.admin_virtual_engine)
			continue
		var/thrust = engine.get_thrust()
		if(!thrust)
			continue
		engine_thrust += thrust
		engine_torque += thrust * max(vessel.hull_radius / 2, 1)
		thrusting_engines += engine
	bow_angle = vessel.marked_bow()

/datum/component/overmap_flight/proc/side_accel(thrust)
	return round(OVERMAP_DISPLAY_SPEED(thrust / inertial_mass()), 0.01)

/datum/component/overmap_flight/proc/angular_accel(torque)
	var/obj/overmap/entity/vessel = parent
	return torque * OVERMAP_TORQUE_SCALE / (max(vessel.total_mass(), 1) * vessel.hull_inertia)

/datum/component/overmap_flight/proc/set_facing(new_facing)
	facing = SIMPLIFY_DEGREES(new_facing)
	if(facing < 0)
		facing += 360

/datum/component/overmap_flight/proc/change_spin(wanted, elapsed)
	if(fixed_facing || (!wanted && !angular_velocity))
		return
	if(wanted != angular_velocity && engines_state && can_steer())
		var/turning = wanted > angular_velocity ? 1 : -1
		var/spin_step = angular_accel(engine_torque) * elapsed
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
	var/braking = angular_accel(engine_torque)
	var/wanted = 0
	if(abs(difference) >= 1)
		wanted = sign(difference) * min(max_turn_rate, sqrt(2 * braking * abs(difference)))
	change_spin(wanted, elapsed)

/datum/component/overmap_flight/proc/take_pilot(mob/new_pilot, obj/machinery/computer/helm/helm)
	release_pilot()
	pilot = new_pilot
	pilot_helm = helm
	RegisterSignals(pilot, list(COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, COMSIG_MOB_CLIENT_PRE_NON_LIVING_MOVE), PROC_REF(block_pilot_walk))
	RegisterSignals(pilot, list(COMSIG_KB_MOB_DROPITEM_DOWN, COMSIG_KB_HUMAN_QUICKEQUIP_DOWN), PROC_REF(block_pilot_hotkey))
	RegisterSignal(pilot, COMSIG_QDELETING, PROC_REF(release_pilot))
	RegisterSignal(pilot_helm, COMSIG_QDELETING, PROC_REF(release_pilot))

/datum/component/overmap_flight/proc/release_pilot()
	SIGNAL_HANDLER
	if(pilot)
		UnregisterSignal(pilot, list(COMSIG_MOB_CLIENT_PRE_LIVING_MOVE, COMSIG_MOB_CLIENT_PRE_NON_LIVING_MOVE, COMSIG_KB_MOB_DROPITEM_DOWN, COMSIG_KB_HUMAN_QUICKEQUIP_DOWN, COMSIG_QDELETING))
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
	if(!pilot.client || (isliving(pilot) && pilot.incapacitated()) || !pilot_helm.can_pilot(pilot))
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
	var/forward = (keys["W"] || keys["North"] ? 1 : 0) - (keys["S"] || keys["South"] ? 1 : 0)
	var/sideways = !!keys["D"] - !!keys["A"]
	pilot_turn = (keys["E"] || keys["East"] ? 1 : 0) - (keys["Q"] || keys["West"] ? 1 : 0)
	precision = !!keys["Shift"]
	var/control_scale = precision ? OVERMAP_PRECISION_SCALE : 1
	pilot_turn *= control_scale
	if(pilot_turn && isnum(heading_hold))
		heading_hold = null
	if(!forward && !sideways && !pilot_turn && !keys["Space"])
		return FALSE
	if(autopilot)
		set_autopilot(FALSE)
	held_brake = FALSE
	engines_state = TRUE
	if(keys["Space"])
		brake(elapsed)
		return TRUE
	if(!forward && !sideways)
		return FALSE
	if(forward && sideways)
		forward *= 0.7071
		sideways *= 0.7071
	var/list/local = bow_local(forward, sideways)
	push_local(local[1] * control_scale, local[2] * control_scale, elapsed)
	return TRUE

/datum/component/overmap_flight/proc/thrust_step(elapsed)
	return engine_thrust / inertial_mass() / burn_delay * elapsed

/datum/component/overmap_flight/proc/push(direction_x, direction_y, elapsed)
	push_local(direction_x * cos(facing) - direction_y * sin(facing), direction_x * sin(facing) + direction_y * cos(facing), elapsed)

/datum/component/overmap_flight/proc/push_local(local_x, local_y, elapsed)
	var/obj/overmap/entity/vessel = parent
	if(!engines_state || !can_steer())
		return
	var/side_x = local_x > 0 ? EAST : WEST
	var/side_y = local_y > 0 ? NORTH : SOUTH
	var/scale = elapsed / inertial_mass() / burn_delay
	var/accel_x = local_x * engine_thrust * scale
	var/accel_y = local_y * engine_thrust * scale
	if(accel_x)
		burn_sides |= side_x
		note_burn(side_x, abs(accel_x))
	if(accel_y)
		burn_sides |= side_y
		note_burn(side_y, abs(accel_y))
	if(!accel_x && !accel_y)
		return
	var/before = sqrt(vessel.speed[1] ** 2 + vessel.speed[2] ** 2)
	vessel.speed[1] += accel_x * cos(facing) + accel_y * sin(facing)
	vessel.speed[2] += accel_y * cos(facing) - accel_x * sin(facing)

	var/limit = min(vessel.max_speed, max(cruise_speed, before))
	var/current = sqrt(vessel.speed[1] ** 2 + vessel.speed[2] ** 2)
	if(current > limit)
		vessel.speed[1] *= limit / current
		vessel.speed[2] *= limit / current
	vessel.refresh_heading_overlay()

/datum/component/overmap_flight/proc/brake(elapsed)
	var/obj/overmap/entity/vessel = parent
	if(!vessel.is_moving() || !engines_state || !can_steer())
		return
	var/local_x = vessel.speed[1] * cos(facing) - vessel.speed[2] * sin(facing)
	var/local_y = vessel.speed[1] * sin(facing) + vessel.speed[2] * cos(facing)
	var/scale = OVERMAP_BRAKE_COEFFICIENT * elapsed / inertial_mass() / burn_delay
	var/side_x = local_x > 0 ? WEST : EAST
	var/side_y = local_y > 0 ? SOUTH : NORTH
	var/slow_x = min(abs(local_x), engine_thrust * scale)
	var/slow_y = min(abs(local_y), engine_thrust * scale)
	if(slow_x)
		burn_sides |= side_x
		note_burn(side_x, slow_x)
		local_x -= sign(local_x) * slow_x
	if(slow_y)
		burn_sides |= side_y
		note_burn(side_y, slow_y)
		local_y -= sign(local_y) * slow_y
	vessel.speed[1] = local_x * cos(facing) + local_y * sin(facing)
	vessel.speed[2] = local_y * cos(facing) - local_x * sin(facing)
	if(abs(vessel.speed[1]) < OVERMAP_SPEED_EPSILON && abs(vessel.speed[2]) < OVERMAP_SPEED_EPSILON)
		vessel.speed[1] = 0
		vessel.speed[2] = 0
	vessel.refresh_heading_overlay()

/datum/component/overmap_flight/proc/update_burn(elapsed = OVERMAP_FLIGHT_TICK)
	var/obj/overmap/entity/vessel = parent
	var/burning = burn_sides || burn_turn
	if(burning && !was_burning)
		jolt_crew()
	was_burning = burning
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		var/pushes = engine_pushes(engine)
		var/firing = pushes && engine.apply_thrust(elapsed) > 0
		engine.set_firing(firing, firing ? pushes : NONE)

/datum/component/overmap_flight/proc/jolt_crew()
	var/obj/overmap/entity/vessel = parent
	if(!vessel.shuttle || world.time < next_jolt || side_accel(engine_thrust) < OVERMAP_JOLT_ACCEL)
		return
	next_jolt = world.time + OVERMAP_JOLT_COOLDOWN
	vessel.play_shuttle_sound(OVERMAP_JOLT_RUMBLE_SOUND, 50)
	for(var/area/place as anything in vessel.shuttle.shuttle_areas)
		for(var/mob/living/passenger in place)
			if(passenger.client && !passenger.buckled && !HAS_TRAIT(passenger, TRAIT_NEGATES_GRAVITY))
				shake_camera(passenger, OVERMAP_JOLT_SHAKE_TIME, 1)

/datum/component/overmap_flight/proc/engine_fires(obj/machinery/ship_engine/engine)
	return !!engine_pushes(engine)

/datum/component/overmap_flight/proc/engine_pushes(obj/machinery/ship_engine/engine)
	if(!(engine in thrusting_engines))
		return NONE
	var/push = burn_main || (burn_turn ? engine_turn_push(engine) : NONE)
	return push == REVERSE_DIR(engine.dir) ? push : NONE

/datum/component/overmap_flight/proc/stop_burn()
	var/obj/overmap/entity/vessel = parent
	burn_sides = NONE
	burn_main = NONE
	burn_main_force = 0
	burn_turn = 0
	was_burning = FALSE
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		engine.set_firing(FALSE)

/datum/component/overmap_flight/proc/get_total_thrust()
	var/total_thrust = 0
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		if(engine != vessel.virtual_engine || vessel.admin_virtual_engine)
			total_thrust += engine.get_thrust()
	return total_thrust

/datum/component/overmap_flight/proc/inertial_mass()
	var/obj/overmap/entity/vessel = parent
	return max(vessel.total_mass(), 1) * OVERMAP_MASS_INERTIA

/datum/component/overmap_flight/proc/get_acceleration()
	return round(engine_thrust / inertial_mass(), OVERMAP_MOVE_RESOLUTION)

/datum/component/overmap_flight/proc/has_working_engines()
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		if((engine != vessel.virtual_engine || vessel.admin_virtual_engine) && engine.can_burn())
			return TRUE
	return FALSE

/datum/component/overmap_flight/proc/can_steer()
	var/obj/overmap/entity/vessel = parent
	if(vessel.overmap_pod && !has_working_engines())
		return FALSE
	return (vessel.status == OVERMAP_STATUS_OVERMAP || vessel.status == OVERMAP_STATUS_TRANSIT) && !vessel.halted && isturf(vessel.loc)

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
	return brake_distance_to_speed(OVERMAP_FROM_DISPLAY(OVERMAP_HEADING_SPEED_MIN))

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
	return ((current * current) - (target_speed * target_speed)) / (2 * accel_per_ds * (vessel.sector?.tile_travel || 1))

/datum/component/overmap_flight/proc/set_autopilot(enabled, dest_x, dest_y, manual = TRUE)
	var/obj/overmap/entity/vessel = parent
	var/was_on = autopilot
	autopilot = enabled
	if(!enabled || !isnull(dest_x) || !isnull(dest_y))
		clear_navigation()
	if(was_on && !autopilot && manual)
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
			autopilot_x = clamp(autopilot_x, 1, vessel.sector.size)
		if(!isnull(autopilot_y))
			autopilot_y = clamp(autopilot_y, 1, vessel.sector.size)
	if(autopilot && (isnull(autopilot_x) || isnull(autopilot_y)))
		autopilot = FALSE
	if(!autopilot)
		autopilot_status = ""

/datum/component/overmap_flight/proc/process_autopilot(elapsed)
	return process_navigation(elapsed)

/datum/component/overmap_flight/proc/velocity_angle()
	var/obj/overmap/entity/vessel = parent
	if(!vessel.is_moving())
		return null
	return delta_to_angle(vessel.speed[1], vessel.speed[2])

/datum/component/overmap_flight/proc/get_effective_cruise()
	var/limit = cruise_speed
	if(navigation_speed_limited())
		limit = min(limit, OVERMAP_FROM_DISPLAY(OVERMAP_PROGRAMMED_CRUISE))

	return limit

/datum/component/overmap_flight/proc/notify_arrival()
	var/obj/overmap/entity/vessel = parent
	SEND_SIGNAL(vessel, COMSIG_OVERMAP_NAVIGATION_ARRIVED)
