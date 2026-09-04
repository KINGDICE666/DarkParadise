#define DEN_TEMPLATE "bitrunning_den.dmm"
#define DEN_TEST_OFFSET 12

/datum/unit_test/room_test/bitrunning

/datum/unit_test/room_test/bitrunning/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/machinery/quantum_server/server = allocate(/obj/machinery/quantum_server, anchor)
	var/obj/machinery/byteforge/forge = allocate(/obj/machinery/byteforge, locate(anchor.x + 1, anchor.y, anchor.z))
	var/obj/machinery/computer/quantum_console/console = allocate(/obj/machinery/computer/quantum_console, locate(anchor.x, anchor.y + 1, anchor.z))

	TEST_ASSERT_EQUAL(console.find_server(), server, "the console did not find the server standing next to it")

	server.points = BITRUNNER_COST_LOW
	TEST_ASSERT(server.cold_boot_map(LAZY_TEMPLATE_KEY_BITRUNNING_XENO_NEST), "server failed to boot the xeno nest domain")
	TEST_ASSERT_NOTNULL(server.generated_domain, "server lost the reference to the loaded domain")
	TEST_ASSERT_NOTNULL(server.domain_reservation, "server lost the reference to the domain reservation")
	TEST_ASSERT(length(server.exit_turfs), "no exit turfs were collected from the domain")
	TEST_ASSERT(length(server.goal_turfs), "no goal turfs were collected from the domain")

	var/obj/structure/closet/crate/secure/bitrunning/encrypted/cache
	var/obj/modular_map_connector/safehouse
	for(var/turf/tile as anything in server.domain_reservation.reserved_turfs)
		cache ||= locate(/obj/structure/closet/crate/secure/bitrunning/encrypted) in tile
		safehouse ||= locate(/obj/modular_map_connector) in tile

	TEST_ASSERT_NOTNULL(cache, "the domain loaded without an encrypted cache")
	TEST_ASSERT_NOTNULL(safehouse, "the domain loaded without its modular safehouse")
	TEST_ASSERT(length(server.mutation_candidate_refs), "no mutation candidates were collected from the domain")
	TEST_ASSERT_NOTNULL(server.get_glitch_role(), "no glitch role was available at zero threat")

	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human)
	var/obj/item/disk/bitrunning/item/tier1/program = allocate(/obj/item/disk/bitrunning/item/tier1)
	program.selected_path = /obj/item/resonator
	pilot.put_in_hands(program)

	var/mob/living/carbon/human/avatar = server.start_new_connection(pilot)
	TEST_ASSERT_NOTNULL(avatar, "server failed to build an avatar")
	TEST_ASSERT(locate(/obj/item/resonator) in avatar, "the carried program did not load its gear onto the avatar")
	TEST_ASSERT_EQUAL(server.retries_spent, 1, "building an avatar did not spend a hololadder")
	TEST_ASSERT(locate(/obj/structure/hololadder) in get_turf(avatar), "the avatar was not placed on a hololadder")

	var/list/console_data = console.ui_data(pilot)
	TEST_ASSERT(console_data["connected"], "the console reported no server in its interface data")
	TEST_ASSERT_EQUAL(console_data["generated_domain"], LAZY_TEMPLATE_KEY_BITRUNNING_XENO_NEST, "the console reported the wrong loaded domain")
	TEST_ASSERT(length(console_data["available_domains"]), "the console offered no domains to load")

	var/points_before = server.points
	var/reward_points = server.generated_domain.reward_points
	cache.forceMove(pick(server.goal_turfs))

	TEST_ASSERT(server.domain_complete, "delivering the cache did not complete the domain")
	TEST_ASSERT_EQUAL(server.points, points_before + reward_points, "completing the domain did not award server points")

	sleep(2 SECONDS)

	var/obj/structure/closet/crate/secure/bitrunning/decrypted/reward = locate() in get_turf(forge)
	TEST_ASSERT_NOTNULL(reward, "the byteforge did not materialize a decrypted cache")
	TEST_ASSERT(locate(/obj/item/stack/ore/iron) in reward, "the decrypted cache came without ore")
	TEST_ASSERT(locate(/obj/item/paper) in reward, "the decrypted cache came without a completion certificate")
	TEST_ASSERT(locate(/obj/item/toy/plushie/rouny) in reward, "the decrypted cache came without the domain completion loot")

	var/obj/machinery/netpod/pod = allocate(/obj/machinery/netpod, locate(anchor.x + 1, anchor.y + 1, anchor.z))
	TEST_ASSERT_EQUAL(pod.resolve_outfit("[/datum/outfit/bit_avatar]"), /datum/outfit/bit_avatar, "the netpod rejected an outfit it offers")
	TEST_ASSERT_NULL(pod.resolve_outfit("[/obj/item/stack/sheet/metal]"), "the netpod accepted something that is not an outfit")

	server.scrub_vdom()
	TEST_ASSERT_NULL(server.generated_domain, "scrubbing did not clear the loaded domain")
	TEST_ASSERT_NULL(server.domain_reservation, "scrubbing did not release the domain reservation")
	TEST_ASSERT_EQUAL(length(server.exit_turfs), 0, "scrubbing did not clear the exit turfs")
	TEST_ASSERT_NULL(console.ui_data(pilot)["generated_domain"], "the console still reported a loaded domain after scrubbing")

/datum/unit_test/room_test/bitrunning_domains

/datum/unit_test/room_test/bitrunning_domains/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/machinery/quantum_server/server = allocate(/obj/machinery/quantum_server, anchor)
	allocate(/obj/machinery/byteforge, locate(anchor.x + 1, anchor.y, anchor.z))

	for(var/datum/lazy_template/virtual_domain/domain as anything in get_virtual_domains())
		server.points = domain.cost
		TEST_ASSERT(server.cold_boot_map(domain.key), "the server failed to boot [domain.name]")
		TEST_ASSERT(length(server.exit_turfs), "[domain.name] was mapped without hololadder spawns")
		TEST_ASSERT(length(server.goal_turfs), "[domain.name] was mapped without a delivery pad")

		var/found_cache = FALSE
		var/found_safehouse = FALSE
		var/list/mob/living/simple_animal/hostile/megafauna/bosses = list()
		for(var/turf/tile as anything in server.domain_reservation.reserved_turfs)
			if(locate(/obj/structure/closet/crate/secure/bitrunning/encrypted) in tile)
				found_cache = TRUE
			if(locate(/obj/modular_map_connector) in tile)
				found_safehouse = TRUE
			for(var/mob/living/simple_animal/hostile/megafauna/boss in tile)
				bosses += boss

		for(var/mob/living/simple_animal/hostile/megafauna/boss as anything in bosses)
			TEST_ASSERT(!boss.true_spawn, "[domain.name] left [boss.type] as a real megafauna")
			TEST_ASSERT(/obj/structure/closet/crate/secure/bitrunning/encrypted in boss.loot, "[domain.name] left [boss.type] without the cache in its loot")
			found_cache = TRUE

		TEST_ASSERT(found_cache, "[domain.name] offers no path to an encrypted cache")
		TEST_ASSERT(found_safehouse, "[domain.name] did not load its modular safehouse")
		server.scrub_vdom()

/datum/unit_test/room_test/bitrunning_den

/datum/unit_test/room_test/bitrunning_den/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/datum/map_template/den = GLOB.map_templates[DEN_TEMPLATE]
	TEST_ASSERT_NOTNULL(den, "the bitrunning den template was not preloaded")

	var/turf/origin = locate(anchor.x, anchor.y + DEN_TEST_OFFSET, anchor.z)
	TEST_ASSERT(den.load(origin), "the bitrunning den template failed to load")

	var/obj/machinery/quantum_server/server
	var/obj/machinery/computer/quantum_console/console
	var/obj/machinery/byteforge/forge
	var/obj/machinery/bitrunner_vendor/vendor
	var/obj/machinery/power/apc/breaker
	var/list/netpods = list()
	var/list/spawns = list()

	for(var/turf/tile as anything in den.get_affected_turfs(origin))
		server ||= locate(/obj/machinery/quantum_server) in tile
		console ||= locate(/obj/machinery/computer/quantum_console) in tile
		forge ||= locate(/obj/machinery/byteforge) in tile
		vendor ||= locate(/obj/machinery/bitrunner_vendor) in tile
		breaker ||= locate(/obj/machinery/power/apc) in tile

		var/obj/machinery/netpod/pod = locate() in tile
		if(pod)
			netpods += pod

		var/obj/effect/landmark/start/bitrunner/spawn_point = locate() in tile
		if(spawn_point)
			spawns += spawn_point

	TEST_ASSERT_NOTNULL(server, "the den was mapped without a quantum server")
	TEST_ASSERT_NOTNULL(console, "the den was mapped without a quantum console")
	TEST_ASSERT_NOTNULL(forge, "the den was mapped without a byteforge")
	TEST_ASSERT_NOTNULL(vendor, "the den was mapped without a bitrunner vendor")
	TEST_ASSERT_NOTNULL(breaker, "the den was mapped without an apc")
	TEST_ASSERT_EQUAL(length(netpods), 3, "the den does not hold three netpods")

	var/datum/job/supply/bitrunner/job = SSjobs.GetJobType(/datum/job/supply/bitrunner)
	TEST_ASSERT_EQUAL(length(spawns), job.spawn_positions, "the den does not hold a spawn point per bitrunner slot")

	TEST_ASSERT_EQUAL(console.find_server(), server, "the console cannot reach the server it stands next to")
	TEST_ASSERT_EQUAL(server.get_random_nearby_forge(), forge, "the server cannot reach the byteforge")

	for(var/obj/machinery/netpod/pod as anything in netpods)
		TEST_ASSERT_EQUAL(pod.find_server(), server, "a netpod was mapped out of range of the server")

#undef DEN_TEMPLATE
#undef DEN_TEST_OFFSET
