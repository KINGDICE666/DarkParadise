/datum/test_runner/Run()
	var/datum/unit_test/overmap_probe/test = new
	test_logs[test.type] = list()
	current_test = test
	var/duration = REALTIMEOFDAY
	test.Run()
	durations[test.type] = REALTIMEOFDAY - duration
	current_test = null
	if(!test.succeeded)
		failed_any_test = TRUE
		for(var/reason in test.fail_reasons)
			if(islist(reason))
				test_logs[test.type] += "[reason[2]]:[reason[3]]: [reason[1]]"
			else
				test_logs[test.type] += reason
	qdel(test)

/datum/unit_test/overmap_probe
	var/list/fleet = list()
	var/list/start_state = list()
	var/list/results = list()
	var/datum/overmap_bubble/space
	var/moved_signals = 0

/datum/unit_test/overmap_probe/proc/launch_fleet()
	var/list/ids = list("specops", "sit", "sst", "ferry", "admin", "syndicate", "vox_shuttle", "ombra", "trade_sol")
	var/index = 0
	for(var/id in ids)
		var/obj/docking_port/mobile/port = SSshuttle.getShuttle(id)
		var/obj/overmap/entity/vessel = SSovermap.shuttle_vessels[port]
		if(!vessel || vessel.begin_physical_undock(instant = TRUE) != TRUE)
			TEST_FAIL("could not launch [id]")
			continue
		fleet += vessel
	for(var/attempt in 1 to 100)
		var/ready = TRUE
		for(var/obj/overmap/entity/vessel as anything in fleet)
			if(!vessel.in_free_flight())
				ready = FALSE
		if(ready)
			break
		sleep(1)
	for(var/obj/overmap/entity/vessel as anything in fleet)
		TEST_ASSERT(vessel.in_free_flight(), "[vessel] never reached free flight")
		vessel.set_free_flight_view(TRUE)
		vessel.sector.remove_object(vessel)
		space.sector.add_object(vessel, space.sector.get_turf_at(1, 1))
		vessel.local_space = space
		var/angle = index * 360 / length(fleet)
		var/list/spot = space.to_world(space.center_x + 95 * sin(angle), space.center_y + 95 * cos(angle))
		vessel.set_world_position(spot[1], spot[2])
		vessel.flight.set_facing(angle)
		vessel.speed[1] = 0
		vessel.speed[2] = 0
		vessel.flight.angular_velocity = 0
		start_state[vessel] = list(spot[1], spot[2], angle)
		index++

/datum/unit_test/overmap_probe/proc/reset_fleet(speed, turning)
	for(var/obj/overmap/entity/vessel as anything in fleet)
		var/list/state = start_state[vessel]
		vessel.set_world_position(state[1], state[2])
		vessel.flight.set_facing(state[3])
		var/heading = state[3] + 90
		vessel.speed[1] = OVERMAP_FROM_DISPLAY(speed) * sin(heading)
		vessel.speed[2] = OVERMAP_FROM_DISPLAY(speed) * cos(heading)
		vessel.flight.angular_velocity = turning ? 10 / (1 SECONDS) : 0
		vessel.remember_pose()

/datum/unit_test/overmap_probe/proc/watch_all(list/watched, list/eyes)
	for(var/obj/overmap/entity/vessel as anything in SSovermap.flying_vessels)
		watched[vessel] = TRUE
		var/list/spot = space.to_bubble(vessel.get_world_x(), vessel.get_world_y())
		eyes += locate(round(spot[1]), round(spot[2]), space.bubble_z)

/datum/unit_test/overmap_probe/proc/step_views(everyone_watches)
	if(!everyone_watches)
		SSovermap.process_flight_views(OVERMAP_FLIGHT_TICK)
		return
	var/list/watched = list()
	var/list/eyes = list()
	watch_all(watched, eyes)
	SSovermap.process_encounters(SSovermap.flying_vessels, OVERMAP_FLIGHT_TICK, watched, eyes)

/datum/unit_test/overmap_probe/proc/run_ticks(count, label, everyone_watches, speed, turning)
	reset_fleet(speed, turning)
	var/physics = 0
	var/views = 0
	var/worst = 0
	var/list/samples = list()
	for(var/tick in 1 to count)
		rustg_time_reset("overmap_probe")
		for(var/datum/component/overmap_flight/flight as anything in SSovermap.flights)
			flight.process_tick(OVERMAP_FLIGHT_TICK)
		var/after_physics = rustg_time_microseconds("overmap_probe")
		step_views(everyone_watches)
		var/total = rustg_time_microseconds("overmap_probe")
		physics += after_physics
		views += total - after_physics
		worst = max(worst, total)
		samples += round(total / 1000, 0.01)
		sleep(OVERMAP_FLIGHT_TICK)
	var/list/steady = samples.Copy(2)
	var/steady_sum = 0
	for(var/sample in steady)
		steady_sum += sample
	results += list(list("scenario" = label, "physics_ms" = round(physics / count / 1000, 0.01), "views_ms" = round(views / count / 1000, 0.01), "steady_ms" = round(steady_sum / length(steady), 0.01), "worst_ms" = round(worst / 1000, 0.01), "samples_ms" = samples))
	log_world("PROBE perf [label]: physics [round(physics / count / 1000, 0.01)] ms, views [round(views / count / 1000, 0.01)] ms, steady [round(steady_sum / length(steady), 0.01)] ms, worst [round(worst / 1000, 0.01)] ms")

/datum/unit_test/overmap_probe/proc/reference_contacts(obj/overmap/entity/vessel)
	. = list()
	var/datum/overmap_bubble/bubble = vessel.collision_space()
	for(var/turf/hull_turf as anything in vessel.hull_edge)
		var/list/spot = vessel.hull_to_world(hull_turf.x, hull_turf.y)
		var/turf/struck = bubble.solid_turf_at(spot[1], spot[2])
		if(struck)
			. += "[hull_turf.x]_[hull_turf.y]_[struck.x]_[struck.y]"

/datum/unit_test/overmap_probe/proc/check_contacts()
	var/checked = 0
	for(var/obj/overmap/entity/vessel as anything in fleet)
		vessel.remember_pose()
		var/list/expected = reference_contacts(vessel)
		var/list/actual = list()
		for(var/list/contact as anything in vessel.contacts_at(1))
			var/turf/hull_turf = contact[1]
			var/turf/struck = contact[2]
			actual += "[hull_turf.x]_[hull_turf.y]_[struck.x]_[struck.y]"
		TEST_ASSERT_EQUAL(jointext(sortList(actual), ","), jointext(sortList(expected), ","), "contacts of [vessel] differ from reference")
		checked += length(expected)
	log_world("PROBE contacts match reference ([checked] solid contacts)")

/datum/unit_test/overmap_probe/proc/free_edge_spot(obj/overmap/entity/vessel)
	for(var/turf/hull_turf as anything in vessel.hull_edge)
		var/list/spot = vessel.hull_to_world(hull_turf.x, hull_turf.y)
		var/turf/target = space.turf_at(spot[1], spot[2])
		if(target && isspaceturf(target) && !space.is_solid(target))
			return target

/datum/unit_test/overmap_probe/proc/check_live_obstacle()
	var/obj/overmap/entity/vessel = fleet[1]
	vessel.remember_pose()
	var/turf/target = free_edge_spot(vessel)
	for(var/obj/overmap/entity/ship as anything in fleet)
		var/list/at = space.to_bubble(ship.get_world_x(), ship.get_world_y())
		var/list/want = start_state[ship]
		var/list/want_at = space.to_bubble(want[1], want[2])
		log_world("PROBE debug [ship.shuttle?.id] at [round(at[1])],[round(at[2])] want [round(want_at[1])],[round(want_at[2])] r [round(ship.hull_radius)] sector [ship.sector == space.sector] loc [ship.loc?.x],[ship.loc?.y],[ship.loc?.z] tt [ship.sector?.tile_travel]")
	TEST_ASSERT_NOTNULL(target, "no free space under the hull edge")
	var/obj/structure/girder/obstacle = new(target)
	var/found = FALSE
	for(var/list/contact as anything in vessel.contacts_at(1))
		if(contact[2] == target)
			found = TRUE
	TEST_ASSERT(found, "a new dense object must block immediately")
	qdel(obstacle)
	for(var/list/contact as anything in vessel.contacts_at(1))
		TEST_ASSERT(contact[2] != target, "a removed object must stop blocking immediately")
	log_world("PROBE live obstacle detected and released")

/datum/unit_test/overmap_probe/proc/check_terrain_refresh()
	reset_fleet(0, FALSE)
	step_views(TRUE)
	var/obj/overmap/entity/vessel = fleet[1]
	var/datum/terrain_view/view = vessel.terrain_view
	TEST_ASSERT_NOTNULL(view, "watched ship has no terrain view")
	var/list/spot = space.to_bubble(vessel.get_world_x(), vessel.get_world_y())
	var/turf/target
	for(var/turf/candidate as anything in block(round(spot[1]) - 20, round(spot[2]) - 20, space.bubble_z, round(spot[1]) + 20, round(spot[2]) + 20, space.bubble_z))
		if(!isspaceturf(candidate) || (locate(/obj/structure) in candidate))
			continue
		var/list/candidate_world = space.to_world(candidate.x, candidate.y)
		if(vessel.hull_turf_at(candidate_world[1], candidate_world[2]))
			continue
		var/distance = max(abs(candidate.x - spot[1]), abs(candidate.y - spot[2]))
		if(distance > vessel.hull_radius + 3 && distance < vessel.hull_radius + 10)
			target = candidate
			break
	TEST_ASSERT_NOTNULL(target, "no empty space near the parked ship")
	var/obj/structure/girder/wall = new(target)
	for(var/tick in 1 to 7)
		sleep(OVERMAP_FLIGHT_TICK)
		step_views(TRUE)
	TEST_ASSERT(view.tiles[target], "new structure near a parked ship must appear in its terrain view")
	qdel(wall)
	for(var/tick in 1 to 7)
		sleep(OVERMAP_FLIGHT_TICK)
		step_views(TRUE)
	TEST_ASSERT(!view.tiles[target], "removed structure must leave the terrain view")
	log_world("PROBE parked terrain view refreshed")

/datum/unit_test/overmap_probe/proc/check_carriers()
	for(var/obj/overmap/entity/vessel as anything in fleet)
		var/datum/terrain_view/view = vessel.terrain_view
		if(!view)
			continue
		var/list/carriers = view.vars["carriers"]
		var/members = 0
		for(var/key in carriers)
			var/obj/effect/abstract/carrier = carriers[key]
			var/list/carrier_members = carrier.vars["members"]
			members += length(carrier_members)
			TEST_ASSERT(isturf(carrier.loc), "terrain carrier off the map")
		TEST_ASSERT_EQUAL(members, length(view.tiles), "terrain carriers lost tiles of [vessel]")
		for(var/obj/overmap/entity/other as anything in vessel.neighbor_proxies)
			var/datum/hull_proxy/proxy = vessel.neighbor_proxies[other]
			var/proxy_members = 0
			for(var/obj/effect/abstract/carrier as anything in proxy.vars["carriers"])
				var/list/carrier_members = carrier.vars["members"]
				proxy_members += length(carrier_members)
			TEST_ASSERT_EQUAL(proxy_members, length(other.hull_turfs), "neighbour mirror of [other] lost tiles")
	log_world("PROBE carriers hold every mirrored tile")

/datum/unit_test/overmap_probe/proc/count_moved()
	SIGNAL_HANDLER
	moved_signals++

/datum/unit_test/overmap_probe/proc/check_moved_signal()
	var/obj/overmap/entity/vessel = fleet[2]
	RegisterSignal(vessel, COMSIG_OVERMAP_MOVED, PROC_REF(count_moved))
	sleep(OVERMAP_SLOW_TICK * 2 + 1)
	moved_signals = 0
	vessel.update_overmap_pixel()
	vessel.update_overmap_pixel()
	vessel.update_overmap_pixel()
	var/immediate = moved_signals
	sleep(OVERMAP_SLOW_TICK + 5)
	UnregisterSignal(vessel, COMSIG_OVERMAP_MOVED)
	TEST_ASSERT_EQUAL(immediate, 1, "first move must signal at once")
	TEST_ASSERT_EQUAL(moved_signals, 2, "the last move must be delivered after the throttle window")
	log_world("PROBE moved signal throttled with a trailing update")

/datum/unit_test/overmap_probe/proc/check_cleanup()
	reset_fleet(0, FALSE)
	step_views(TRUE)
	var/obj/overmap/entity/vessel = fleet[length(fleet)]
	vessel.clear_encounter_visuals()
	for(var/obj/overmap/entity/other as anything in fleet)
		TEST_ASSERT(!other.nearby_ships[vessel], "[other] still lists a ship that left flight")
		TEST_ASSERT(!other.neighbor_proxies[vessel], "[other] still mirrors a ship that left flight")
	TEST_ASSERT(!space.ships[vessel], "bubble still holds a ship that left flight")
	TEST_ASSERT(!space.ship_proxies[vessel], "bubble still mirrors a ship that left flight")
	log_world("PROBE flight exit cleanup passed")

/datum/unit_test/overmap_probe/Run()
	for(var/datum/overmap_bubble/bubble as anything in SSovermap.bubbles_by_z)
		if(bubble)
			space = bubble
	TEST_ASSERT_NOTNULL(space, "no station bubble")
	SSovermap.can_fire = FALSE
	launch_fleet()
	TEST_ASSERT_EQUAL(length(fleet), 9, "not every ship launched")
	SSovermap.reserve_bubble_space()
	SSovermap.process_flight_views(OVERMAP_FLIGHT_TICK)
	sleep(OVERMAP_SLOW_TICK)
	reset_fleet(0, FALSE)
	SSovermap.process_flight_views(OVERMAP_FLIGHT_TICK)
	check_contacts()
	check_live_obstacle()
	check_moved_signal()
	if(world.GetConfig("env", "OVERMAP_PROBE_PERF"))
		run_ticks(25, "parked, everyone watching", TRUE, 0, FALSE)
		run_ticks(25, "parked, empty ships", FALSE, 0, FALSE)
		run_ticks(25, "8 m/s turning, empty ships", FALSE, 8, TRUE)
		run_ticks(25, "8 m/s straight, everyone watching", TRUE, 8, FALSE)
		world.Profile(PROFILE_CLEAR)
		world.Profile(PROFILE_START)
		run_ticks(50, "8 m/s turning, everyone watching", TRUE, 8, TRUE)
		world.Profile(PROFILE_STOP)
		text2file(world.Profile(PROFILE_REFRESH, "json"), "data/overmap_profile.json")
		fdel("data/overmap_benchmark.json")
		text2file(json_encode(results), "data/overmap_benchmark.json")
	if(!world.GetConfig("env", "OVERMAP_PROBE_BASELINE"))
		run_ticks(5, "settle", TRUE, 8, TRUE)
		check_carriers()
		check_terrain_refresh()
	check_cleanup()
	SSovermap.can_fire = TRUE
