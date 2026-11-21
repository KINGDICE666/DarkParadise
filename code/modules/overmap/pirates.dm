#define PIRATE_AI_PATROL "patrol"
#define PIRATE_AI_HUNT "hunt"
#define PIRATE_AI_ATTACK "attack"
#define PIRATE_AI_RETREAT "retreat"
#define PIRATE_AI_ROAM "roam"
#define PIRATE_AI_ADRIFT "adrift"
#define PIRATE_AI_DERELICT "derelict"

#define PIRATE_ENGAGE_RANGE 40
#define PIRATE_FIRE_RANGE 90
#define PIRATE_VISUAL_RANGE 60
#define PIRATE_VISUAL_QUALITY 50
#define PIRATE_HUNT_QUALITY 25
#define PIRATE_FIRE_QUALITY 40
#define PIRATE_AIM_FLOOR 2
#define PIRATE_AIM_SPREAD 22
#define PIRATE_ORBIT_STEP 3
#define PIRATE_REPLOT_SHIFT 6
#define PIRATE_REPLOT_TURN 3
#define PIRATE_PATROL_RADIUS 4
#define PIRATE_PATROL_LEG_TIME (2 MINUTES)
#define PIRATE_SWEEP_INTERVAL (40 SECONDS)
#define PIRATE_SWEEP_TIME (8 SECONDS)
#define PIRATE_ROAM_TIME (8 MINUTES)
#define PIRATE_CALM_TIME (5 MINUTES)
#define PIRATE_THREAT_COOLDOWN (90 SECONDS)
#define PIRATE_RETREAT_CREW 0.5

/datum/component/pirate_ship_ai
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/state = PIRATE_AI_PATROL
	var/list/mob/living/simple_animal/hostile/crew = list()
	var/initial_crew = 0
	var/mob/living/simple_animal/hostile/pilot
	var/mob/living/simple_animal/hostile/radar_operator
	var/obj/machinery/computer/helm/helm
	var/obj/machinery/computer/sensors/sensor_console
	var/turf/helm_post
	var/turf/sensor_post
	var/target_uid
	var/relay_uid
	var/datum/overmap_sector/home_sector
	var/turf/home_turf
	var/list/patrol_point
	var/patrol_until = 0
	var/next_sweep = 0
	var/sweep_until = 0
	var/next_roam = 0
	var/calm_until = 0
	var/next_threat = 0
	var/orbit_angle = 0
	var/orbit_sign = 1
	var/attack_station = FALSE
	var/roaming = TRUE

/datum/component/pirate_ship_ai/Initialize(display_name)
	var/obj/overmap/entity/vessel = parent
	if(!istype(vessel) || !vessel.shuttle || !vessel.flight)
		return COMPONENT_INCOMPATIBLE
	vessel.apply_overmap_identity(display_name || vessel.name, "#c0392b", "shuttle_c", FALSE, FALSE, null, TRUE)
	vessel.hidden_from_contacts = FALSE
	orbit_sign = pick(-1, 1)
	next_roam = world.time + PIRATE_ROAM_TIME
	link_ship()

/datum/component/pirate_ship_ai/RegisterWithParent()
	START_PROCESSING(SSprocessing, src)

/datum/component/pirate_ship_ai/UnregisterFromParent()
	STOP_PROCESSING(SSprocessing, src)
	var/obj/overmap/entity/vessel = parent
	stand_down()
	vessel.sensor_pack?.release_lock()
	for(var/mob/living/simple_animal/hostile/crewman as anything in crew.Copy())
		forget_crewman(crewman)
	if(helm)
		UnregisterSignal(helm, COMSIG_QDELETING)
	if(sensor_console)
		UnregisterSignal(sensor_console, COMSIG_QDELETING)

/datum/component/pirate_ship_ai/Destroy(force)
	pilot = null
	radar_operator = null
	helm = null
	sensor_console = null
	home_sector = null
	return ..()

/datum/component/pirate_ship_ai/proc/link_ship()
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/computer/helm/console as anything in vessel.helms)
		if(!QDELETED(console))
			helm = console
			break
	for(var/obj/machinery/computer/sensors/console as anything in vessel.sensors)
		if(!QDELETED(console))
			sensor_console = console
			break
	if(helm)
		RegisterSignal(helm, COMSIG_QDELETING, PROC_REF(on_console_lost))
	if(sensor_console)
		RegisterSignal(sensor_console, COMSIG_QDELETING, PROC_REF(on_console_lost))
	for(var/area/place as anything in vessel.shuttle.shuttle_areas)
		for(var/mob/living/simple_animal/hostile/pirate/crewman in place)
			if(crewman.stat != DEAD)
				enlist(crewman)
	initial_crew = length(crew)

/datum/component/pirate_ship_ai/proc/post_for(obj/machinery/console)
	var/turf/fallback
	for(var/turf/simulated/floor/spot in orange(1, console))
		if(spot.is_blocked_turf(exclude_mobs = TRUE))
			continue
		if(locate(/obj/structure/chair) in spot)
			return spot
		fallback ||= spot
	return fallback

/datum/component/pirate_ship_ai/proc/enlist(mob/living/simple_animal/hostile/crewman)
	crew |= crewman
	RegisterSignals(crewman, list(COMSIG_QDELETING, COMSIG_MOB_DEATH), PROC_REF(on_crewman_lost))

/datum/component/pirate_ship_ai/proc/forget_crewman(mob/living/simple_animal/hostile/crewman)
	UnregisterSignal(crewman, list(COMSIG_QDELETING, COMSIG_MOB_DEATH))
	crew -= crewman
	crewman.wander = initial(crewman.wander)
	if(pilot == crewman)
		pilot = null
	if(radar_operator == crewman)
		radar_operator = null

/datum/component/pirate_ship_ai/proc/on_crewman_lost(mob/living/simple_animal/hostile/crewman)
	SIGNAL_HANDLER
	forget_crewman(crewman)

/datum/component/pirate_ship_ai/proc/on_console_lost(obj/machinery/console)
	SIGNAL_HANDLER
	if(console == helm)
		helm = null
	if(console == sensor_console)
		sensor_console = null

/datum/component/pirate_ship_ai/proc/console_ready(obj/machinery/console)
	return !QDELETED(console) && !(console.stat & (NOPOWER|BROKEN))

/datum/component/pirate_ship_ai/proc/at_post(mob/living/crewman, obj/machinery/console)
	return crewman && crewman.stat == CONSCIOUS && crewman.z == console.z && get_dist(crewman, console) <= 1

/datum/component/pirate_ship_ai/proc/pilot_ready()
	var/obj/overmap/entity/vessel = parent
	return console_ready(helm) && at_post(pilot, helm) && vessel.can_steer()

/datum/component/pirate_ship_ai/proc/radar_ready()
	return console_ready(sensor_console) && at_post(radar_operator, sensor_console)

/datum/component/pirate_ship_ai/proc/pick_crewman(turf/post, mob/living/simple_animal/hostile/exclude)
	var/mob/living/simple_animal/hostile/best
	var/best_distance = INFINITY
	for(var/mob/living/simple_animal/hostile/crewman as anything in crew)
		if(crewman == exclude || crewman.target || crewman.client || crewman.z != post.z)
			continue
		var/distance = get_dist(crewman, post)
		if(distance < best_distance)
			best = crewman
			best_distance = distance
	return best

/datum/component/pirate_ship_ai/proc/staff_posts()
	helm_post = helm ? post_for(helm) : null
	sensor_post = sensor_console ? post_for(sensor_console) : null
	if(helm_post && !(pilot in crew))
		pilot = pick_crewman(helm_post)
	if(sensor_post && length(crew) > 1 && !(radar_operator in crew))
		radar_operator = pick_crewman(sensor_post, pilot)
	for(var/mob/living/simple_animal/hostile/crewman as anything in crew)
		var/turf/post = crewman == pilot ? helm_post : (crewman == radar_operator ? sensor_post : null)
		crewman.wander = post ? FALSE : initial(crewman.wander)
		if(post && !crewman.client && !crewman.target && get_turf(crewman) != post)
			crewman.Goto(post, crewman.move_to_delay, 0)

/datum/component/pirate_ship_ai/proc/set_state(new_state)
	if(state == new_state)
		return
	state = new_state
	var/obj/overmap/entity/vessel = parent
	if(new_state != PIRATE_AI_ATTACK && vessel.flight)
		vessel.flight.heading_hold = null

/datum/component/pirate_ship_ai/proc/stand_down()
	var/obj/overmap/entity/vessel = parent
	var/datum/component/overmap_flight/flight = vessel.flight
	if(!flight)
		return
	if(flight.autopilot)
		flight.set_autopilot(FALSE, manual = FALSE)
	flight.heading_hold = null

/datum/component/pirate_ship_ai/proc/fly_to(goal_x, goal_y, heading)
	var/obj/overmap/entity/vessel = parent
	var/datum/component/overmap_flight/flight = vessel.flight
	if(flight.autopilot && !isnull(flight.navigation_world_x) && abs(flight.navigation_world_x - goal_x) + abs(flight.navigation_world_y - goal_y) < PIRATE_REPLOT_SHIFT)
		if(isnull(heading) == isnull(flight.navigation_facing) && (isnull(heading) || abs(closer_angle_difference(heading, flight.navigation_facing)) < PIRATE_REPLOT_TURN))
			return
	flight.navigate_world(goal_x, goal_y, heading, null, known_obstacles_only = FALSE)

/datum/component/pirate_ship_ai/proc/world_distance(obj/overmap/entity/other)
	var/obj/overmap/entity/vessel = parent
	return sqrt((other.get_world_x() - vessel.get_world_x()) ** 2 + (other.get_world_y() - vessel.get_world_y()) ** 2)

/datum/component/pirate_ship_ai/proc/valid_prey(obj/overmap/entity/contact)
	var/obj/overmap/entity/vessel = parent
	if(!istype(contact) || QDELETED(contact) || contact == vessel || contact.sector != vessel.sector || !isturf(contact.loc))
		return FALSE
	if(contact.GetComponent(/datum/component/pirate_ship_ai) || contact.is_jumping() || contact.docked_to || contact.is_physically_docked())
		return FALSE
	switch(contact.overmap_kind)
		if(OVERMAP_KIND_SHUTTLE, OVERMAP_KIND_POD)
			return TRUE
		if(OVERMAP_KIND_STATION)
			return attack_station
	return FALSE

/datum/component/pirate_ship_ai/proc/known_contacts()
	var/obj/overmap/entity/vessel = parent
	. = list()
	var/list/tracks = vessel.sensor_pack?.tracks
	if(radar_ready())
		for(var/uid in tracks)
			var/list/track = tracks[uid]
			if(track["source"] == "lost")
				continue
			var/obj/overmap/entity/contact = locateUID(uid)
			if(valid_prey(contact))
				.[contact] = track["quality"]
	for(var/obj/overmap/entity/contact in vessel.sector.objects)
		if(isnull(.[contact]) && valid_prey(contact) && world_distance(contact) <= PIRATE_VISUAL_RANGE)
			.[contact] = PIRATE_VISUAL_QUALITY

/datum/component/pirate_ship_ai/proc/pick_target(list/contacts)
	var/obj/overmap/entity/best
	var/best_score = -INFINITY
	for(var/obj/overmap/entity/contact as anything in contacts)
		if(contacts[contact] < PIRATE_HUNT_QUALITY)
			continue
		var/score = contacts[contact] - world_distance(contact) / 10
		if(score > best_score)
			best = contact
			best_score = score
	return best

/datum/component/pirate_ship_ai/proc/crippled()
	return length(crew) < initial_crew * PIRATE_RETREAT_CREW || !has_usable_guns()

/datum/component/pirate_ship_ai/proc/has_usable_guns()
	var/obj/overmap/entity/vessel = parent
	for(var/obj/machinery/ship_gun/gun in vessel.ship_weapons())
		if(gun.can_fire())
			return TRUE
	return FALSE

/datum/component/pirate_ship_ai/process(seconds_per_tick)
	var/obj/overmap/entity/vessel = parent
	if(!length(crew))
		if(state != PIRATE_AI_DERELICT)
			set_state(PIRATE_AI_DERELICT)
			stand_down()
			vessel.sensor_pack?.release_lock()
			vessel.set_long_sensors(FALSE)
		return
	staff_posts()
	if(vessel.is_jumping() || vessel.is_overmap_jammed() || !vessel.sector || !isturf(vessel.loc) || vessel.docked_to || vessel.docked_ship || !vessel.flight)
		return
	if(vessel.sector != home_sector)
		arrive_in_sector()
	var/list/contacts = known_contacts()
	var/obj/overmap/entity/target = locateUID(target_uid)
	if(!(target in contacts))
		target = null
	if(!pilot_ready())
		set_state(PIRATE_AI_ADRIFT)
		stand_down()
		run_sensors(target)
		return
	if(state == PIRATE_AI_RETREAT || state == PIRATE_AI_ROAM)
		run_sensors(null)
		head_for_relay()
		return
	if(target && crippled())
		start_relay_run(PIRATE_AI_RETREAT)
		return
	if(!target && world.time >= calm_until && !crippled())
		target = pick_target(contacts)
	target_uid = target?.UID()
	run_sensors(target)
	if(target)
		engage(target, contacts[target])
		return
	if(roaming && world.time >= next_roam)
		start_relay_run(PIRATE_AI_ROAM)
		return
	patrol()

/datum/component/pirate_ship_ai/proc/arrive_in_sector()
	var/obj/overmap/entity/vessel = parent
	if(home_sector && (state == PIRATE_AI_RETREAT || state == PIRATE_AI_ROAM))
		set_state(PIRATE_AI_PATROL)
	home_sector = vessel.sector
	home_turf = vessel.get_overmap_turf()
	patrol_point = null
	target_uid = null
	relay_uid = null
	next_roam = world.time + PIRATE_ROAM_TIME

/datum/component/pirate_ship_ai/proc/run_sensors(obj/overmap/entity/target)
	var/obj/overmap/entity/vessel = parent
	var/datum/component/overmap_sensors/sensors = vessel.sensor_pack
	if(!sensors || !radar_ready())
		return
	if(!vessel.short_sensors_on)
		vessel.set_short_sensors(TRUE)
	if(target)
		var/list/here = overmap_cell_point(vessel)
		var/list/there = overmap_cell_point(target)
		if(here && there)
			vessel.sensor_sector_bearing = overmap_bearing(there[1] - here[1], there[2] - here[2])
		if(!vessel.long_sensors_on)
			vessel.set_long_sensors(TRUE)
		var/uid = target.UID()
		if(sensors.locked_uid != uid && sensors.in_long_peel_range(target) && sensors.try_lock(uid) == TRUE)
			threaten(target)
		return
	sensors.release_lock()
	if(world.time >= next_sweep)
		next_sweep = world.time + PIRATE_SWEEP_INTERVAL
		sweep_until = world.time + PIRATE_SWEEP_TIME
		vessel.sensor_sector_bearing = null
	var/sweeping = world.time < sweep_until
	if(vessel.long_sensors_on != sweeping)
		vessel.set_long_sensors(sweeping)

/datum/component/pirate_ship_ai/proc/patrol()
	var/obj/overmap/entity/vessel = parent
	set_state(PIRATE_AI_PATROL)
	vessel.flight.heading_hold = null
	if(!patrol_point || world.time >= patrol_until || !vessel.flight.autopilot)
		var/turf/spot = vessel.sector.get_turf_near(home_turf || vessel.get_overmap_turf(), 1, PIRATE_PATROL_RADIUS)
		if(!spot)
			return
		var/span = OVERMAP_TILE_SPAN * vessel.sector.tile_travel
		patrol_point = list(spot.x * span, spot.y * span)
		patrol_until = world.time + PIRATE_PATROL_LEG_TIME
	fly_to(patrol_point[1], patrol_point[2], null)

/datum/component/pirate_ship_ai/proc/firing_facing(obj/overmap/entity/target)
	var/obj/overmap/entity/vessel = parent
	var/list/weights = list()
	for(var/obj/machinery/ship_gun/gun in vessel.ship_weapons())
		var/datum/component/ship_weapon/mount = gun.GetComponent(/datum/component/ship_weapon)
		if(mount && gun.can_fire())
			weights["[dir2angle(mount.mount_dir)]"] += 1
	var/mount_angle = 0
	var/best_weight = 0
	for(var/angle in weights)
		if(weights[angle] > best_weight)
			best_weight = weights[angle]
			mount_angle = text2num(angle)
	return SIMPLIFY_DEGREES(delta_to_angle(target.get_world_x() - vessel.get_world_x(), target.get_world_y() - vessel.get_world_y()) - mount_angle)

/datum/component/pirate_ship_ai/proc/engage(obj/overmap/entity/target, quality)
	var/obj/overmap/entity/vessel = parent
	var/distance = world_distance(target)
	var/offset_x = vessel.get_world_x() - target.get_world_x()
	var/offset_y = vessel.get_world_y() - target.get_world_y()
	if(distance > PIRATE_ENGAGE_RANGE * 2)
		set_state(PIRATE_AI_HUNT)
		fly_to(target.get_world_x() + offset_x / distance * PIRATE_ENGAGE_RANGE, target.get_world_y() + offset_y / distance * PIRATE_ENGAGE_RANGE, null)
		return
	if(state != PIRATE_AI_ATTACK)
		orbit_angle = delta_to_angle(offset_x, offset_y)
		set_state(PIRATE_AI_ATTACK)
		threaten(target)
	orbit_angle = SIMPLIFY_DEGREES(orbit_angle + PIRATE_ORBIT_STEP * orbit_sign)
	var/facing = firing_facing(target)
	fly_to(target.get_world_x() + sin(orbit_angle) * PIRATE_ENGAGE_RANGE, target.get_world_y() + cos(orbit_angle) * PIRATE_ENGAGE_RANGE, facing)
	vessel.flight.heading_hold = SIMPLIFY_DEGREES(facing + vessel.flight.current_bow())
	if(quality >= PIRATE_FIRE_QUALITY && distance <= PIRATE_FIRE_RANGE)
		fire_guns(target, quality)

/datum/component/pirate_ship_ai/proc/fire_guns(obj/overmap/entity/target, quality)
	var/obj/overmap/entity/vessel = parent
	var/spread = PIRATE_AIM_FLOOR + PIRATE_AIM_SPREAD * (100 - quality) / 100
	for(var/obj/machinery/ship_gun/gun in vessel.ship_weapons())
		if(!gun.can_fire())
			continue
		var/list/aim = helm.fire_solution(gun, target)
		if(!aim)
			continue
		var/aim_x = aim[1] + (rand() * 2 - 1) * spread
		var/aim_y = aim[2] + (rand() * 2 - 1) * spread
		if(SEND_SIGNAL(gun, COMSIG_OVERMAP_WEAPON_CAN_AIM, vessel, aim_x, aim_y))
			SEND_SIGNAL(gun, COMSIG_OVERMAP_WEAPON_FIRE, vessel, aim_x, aim_y, null)

/datum/component/pirate_ship_ai/proc/pick_relay(nearest)
	var/obj/overmap/entity/vessel = parent
	var/list/relays = list()
	var/obj/overmap/entity/hyperrelay/closest
	var/closest_distance = INFINITY
	for(var/obj/overmap/entity/hyperrelay/relay in vessel.sector.objects)
		if(QDELETED(relay) || QDELETED(relay.paired) || !relay.paired.sector)
			continue
		relays += relay
		var/distance = world_distance(relay)
		if(distance < closest_distance)
			closest = relay
			closest_distance = distance
	if(!length(relays))
		return null
	return nearest ? closest : pick(relays)

/datum/component/pirate_ship_ai/proc/start_relay_run(new_state)
	var/obj/overmap/entity/hyperrelay/relay = pick_relay(new_state == PIRATE_AI_RETREAT)
	if(new_state == PIRATE_AI_RETREAT)
		calm_until = world.time + PIRATE_CALM_TIME
		broadcast(pick(
			"Сегодня тебе повезло. Ещё увидимся.",
			"Отходим. Запомни наш курс — мы вернёмся.",
			"Ладно, живи. Пока.",
		))
	target_uid = null
	if(!relay)
		next_roam = world.time + PIRATE_ROAM_TIME
		if(new_state == PIRATE_AI_RETREAT)
			flee()
		return
	relay_uid = relay.UID()
	set_state(new_state)
	head_for_relay()

/datum/component/pirate_ship_ai/proc/flee()
	var/obj/overmap/entity/vessel = parent
	set_state(PIRATE_AI_PATROL)
	var/turf/spot = vessel.sector.get_turf_near(vessel.get_overmap_turf(), PIRATE_PATROL_RADIUS, PIRATE_PATROL_RADIUS * 2)
	if(!spot)
		return
	home_turf = spot
	var/span = OVERMAP_TILE_SPAN * vessel.sector.tile_travel
	patrol_point = list(spot.x * span, spot.y * span)
	patrol_until = world.time + PIRATE_PATROL_LEG_TIME
	fly_to(patrol_point[1], patrol_point[2], null)

/datum/component/pirate_ship_ai/proc/head_for_relay()
	var/obj/overmap/entity/vessel = parent
	var/obj/overmap/entity/hyperrelay/relay = locateUID(relay_uid)
	if(!istype(relay) || QDELETED(relay.paired) || relay.sector != vessel.sector)
		relay_uid = null
		if(state == PIRATE_AI_RETREAT)
			flee()
		else
			set_state(PIRATE_AI_PATROL)
			next_roam = world.time + PIRATE_ROAM_TIME
		return
	if(vessel.hyperrelay_on_tile() == relay && OVERMAP_SPEED_STOPPED(vessel.get_speed()))
		stand_down()
		vessel.begin_hyperrelay_jump(TRUE)
		return
	fly_to(relay.get_world_x(), relay.get_world_y(), null)

/datum/component/pirate_ship_ai/proc/threaten(obj/overmap/entity/target)
	if(world.time < next_threat)
		return
	next_threat = world.time + PIRATE_THREAT_COOLDOWN
	broadcast(pick(
		"Ты у нас на прицеле. Глуши двигатели и готовь шлюз к досмотру.",
		"Сбрось ход и не дёргайся — иначе разнесём корпус в решето.",
		"Говорят вольные рейдеры. Груз за жизнь — честная сделка.",
		"Видим тебя. Бежать некуда, стыковочный узел к нам.",
	))

/datum/component/pirate_ship_ai/proc/broadcast(text)
	var/obj/overmap/entity/vessel = parent
	if(!vessel.sector)
		return
	for(var/area/place as anything in vessel.shuttle.shuttle_areas)
		for(var/obj/machinery/overmap_intercom/intercom in place)
			if(intercom.stat & (NOPOWER|BROKEN))
				continue
			vessel.sector.add_comms_message(new /datum/overmap_sector_message(text, null, vessel.get_overmap_display_name(), vessel.sector.id))
			return

/datum/component/pirate_ship_ai/proc/admin_report()
	var/static/list/state_labels = list(
		PIRATE_AI_PATROL = "Патруль",
		PIRATE_AI_HUNT = "Перехват",
		PIRATE_AI_ATTACK = "Атака",
		PIRATE_AI_RETREAT = "Отступление",
		PIRATE_AI_ROAM = "Переход в другой сектор",
		PIRATE_AI_ADRIFT = "Нет пилота",
		PIRATE_AI_DERELICT = "Экипаж погиб",
	)
	var/obj/overmap/entity/target = locateUID(target_uid)
	return list(
		"state" = state_labels[state],
		"target" = istype(target) ? target.get_overmap_display_name() : null,
		"crew" = length(crew),
		"crew_max" = initial_crew,
		"pilot" = pilot_ready(),
		"radar" = radar_ready(),
		"attack_station" = attack_station,
		"roaming" = roaming,
	)

#undef PIRATE_AI_PATROL
#undef PIRATE_AI_HUNT
#undef PIRATE_AI_ATTACK
#undef PIRATE_AI_RETREAT
#undef PIRATE_AI_ROAM
#undef PIRATE_AI_ADRIFT
#undef PIRATE_AI_DERELICT
#undef PIRATE_ENGAGE_RANGE
#undef PIRATE_FIRE_RANGE
#undef PIRATE_VISUAL_RANGE
#undef PIRATE_VISUAL_QUALITY
#undef PIRATE_HUNT_QUALITY
#undef PIRATE_FIRE_QUALITY
#undef PIRATE_AIM_FLOOR
#undef PIRATE_AIM_SPREAD
#undef PIRATE_ORBIT_STEP
#undef PIRATE_REPLOT_SHIFT
#undef PIRATE_REPLOT_TURN
#undef PIRATE_PATROL_RADIUS
#undef PIRATE_PATROL_LEG_TIME
#undef PIRATE_SWEEP_INTERVAL
#undef PIRATE_SWEEP_TIME
#undef PIRATE_ROAM_TIME
#undef PIRATE_CALM_TIME
#undef PIRATE_THREAT_COOLDOWN
#undef PIRATE_RETREAT_CREW
