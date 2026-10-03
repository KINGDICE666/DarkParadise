/datum/unit_test/overmap_probe

/datum/unit_test/overmap_probe/proc/run_ticks(count, label, everyone_watches)
	var/physics = 0
	var/views = 0
	var/worst = 0
	for(var/tick in 1 to count)
		rustg_time_reset("overmap_probe")
		for(var/datum/component/overmap_flight/flight as anything in SSovermap.flights)
			flight.process_tick(OVERMAP_FLIGHT_TICK)
		var/after_physics = rustg_time_microseconds("overmap_probe")
		if(everyone_watches)
			var/list/watched = list()
			var/list/eyes = list()
			for(var/obj/overmap/entity/vessel as anything in SSovermap.flying_vessels)
				watched[vessel] = TRUE
				var/list/spot = vessel.local_space.to_bubble(vessel.get_world_x(), vessel.get_world_y())
				eyes += locate(round(spot[1]), round(spot[2]), vessel.local_space.bubble_z)
			SSovermap.process_encounters(SSovermap.flying_vessels, OVERMAP_FLIGHT_TICK, watched, eyes)
		else
			SSovermap.process_flight_views(OVERMAP_FLIGHT_TICK)
		var/total = rustg_time_microseconds("overmap_probe")
		physics += after_physics
		views += total - after_physics
		worst = max(worst, total)
	log_world("PROBE perf [label]: physics [round(physics / count / 1000, 0.01)] ms, mirrors+terrain+collisions [round(views / count / 1000, 0.01)] ms, worst tick [round(worst / 1000, 0.01)] ms per 0.2 s tick")

/datum/unit_test/overmap_probe/proc/launch_fleet(datum/overmap_bubble/space)
	. = list()
	var/list/ids = list("specops", "sit", "sst", "ferry", "admin", "syndicate", "vox_shuttle", "ombra", "trade_sol")
	var/index = 0
	for(var/id in ids)
		var/obj/docking_port/mobile/port = SSshuttle.getShuttle(id)
		var/obj/overmap/entity/vessel = SSovermap.shuttle_vessels[port]
		if(!vessel || vessel.begin_physical_undock(instant = TRUE) != TRUE)
			continue
		vessel.set_free_flight_view(TRUE)
		vessel.sector.remove_object(vessel)
		space.sector.add_object(vessel, space.sector.get_turf_at(1, 1))
		vessel.local_space = space
		var/angle = index * 360 / length(ids)
		var/list/spot = space.to_world(space.center_x + 95 * sin(angle), space.center_y + 95 * cos(angle))
		vessel.set_world_position(spot[1], spot[2])
		vessel.flight.set_facing(angle)
		. += vessel
		index++

/datum/unit_test/overmap_probe/proc/set_moving(list/fleet)
	for(var/obj/overmap/entity/vessel as anything in fleet)
		var/heading = vessel.get_facing() + 90
		vessel.speed[1] = OVERMAP_FROM_DISPLAY(8) * sin(heading)
		vessel.speed[2] = OVERMAP_FROM_DISPLAY(8) * cos(heading)
		vessel.flight.angular_velocity = 10 / (1 SECONDS)

/datum/unit_test/overmap_probe/Run()
	var/datum/overmap_bubble/space
	for(var/datum/overmap_bubble/bubble as anything in SSovermap.bubbles_by_z)
		if(bubble)
			space = bubble
	var/list/fleet = launch_fleet(space)
	TEST_ASSERT(length(fleet), "no ships launched")
	SSovermap.reserve_bubble_space()
	SSovermap.process_flight_views(OVERMAP_FLIGHT_TICK)
	run_ticks(25, "parked, everyone watching", TRUE)
	run_ticks(25, "parked, empty ships", FALSE)
	set_moving(fleet)
	run_ticks(25, "8 m/s, empty ships", FALSE)
	world.Profile(PROFILE_CLEAR)
	world.Profile(PROFILE_START)
	run_ticks(50, "8 m/s, everyone watching", TRUE)
	world.Profile(PROFILE_STOP)
	text2file(world.Profile(PROFILE_REFRESH, "json"), "data/overmap_profile.json")
	var/proxy_tiles = 0
	var/terrain_tiles = 0
	for(var/obj/overmap/entity/vessel as anything in SSovermap.flying_vessels)
		terrain_tiles += length(vessel.terrain_view?.tiles)
		for(var/obj/overmap/entity/other as anything in vessel.neighbor_proxies)
			var/datum/hull_proxy/proxy = vessel.neighbor_proxies[other]
			proxy_tiles += length(proxy.tiles)
	log_world("PROBE visuals while watched: neighbour tiles [proxy_tiles], terrain tiles [terrain_tiles], contacts of first ship [length(fleet[1]:nearby_ships)]")
