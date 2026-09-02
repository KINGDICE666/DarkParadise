/datum/unit_test/room_test/bitrunning

/datum/unit_test/room_test/bitrunning/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/machinery/quantum_server/server = allocate(/obj/machinery/quantum_server, anchor)
	var/obj/machinery/byteforge/forge = allocate(/obj/machinery/byteforge, locate(anchor.x + 1, anchor.y, anchor.z))
	var/obj/machinery/computer/quantum_console/console = allocate(/obj/machinery/computer/quantum_console, locate(anchor.x, anchor.y + 1, anchor.z))

	TEST_ASSERT_EQUAL(console.find_server(), server, "the console did not find the server standing next to it")

	TEST_ASSERT(server.cold_boot_map(LAZY_TEMPLATE_KEY_BITRUNNING_OUTPOST), "server failed to boot the outpost domain")
	TEST_ASSERT_NOTNULL(server.generated_domain, "server lost the reference to the loaded domain")
	TEST_ASSERT_NOTNULL(server.domain_reservation, "server lost the reference to the domain reservation")
	TEST_ASSERT(length(server.exit_turfs), "no exit turfs were collected from the domain")
	TEST_ASSERT(length(server.goal_turfs), "no goal turfs were collected from the domain")

	var/obj/structure/closet/crate/secure/bitrunning/encrypted/cache
	for(var/turf/tile as anything in server.domain_reservation.reserved_turfs)
		cache = locate() in tile
		if(cache)
			break

	TEST_ASSERT_NOTNULL(cache, "the domain loaded without an encrypted cache")
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
	TEST_ASSERT_EQUAL(console_data["generated_domain"], LAZY_TEMPLATE_KEY_BITRUNNING_OUTPOST, "the console reported the wrong loaded domain")
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
	TEST_ASSERT(locate(/obj/item/stack/sheet/metal) in reward, "the decrypted cache came without the domain completion loot")

	server.scrub_vdom()
	TEST_ASSERT_NULL(server.generated_domain, "scrubbing did not clear the loaded domain")
	TEST_ASSERT_NULL(server.domain_reservation, "scrubbing did not release the domain reservation")
	TEST_ASSERT_EQUAL(length(server.exit_turfs), 0, "scrubbing did not clear the exit turfs")
	TEST_ASSERT_NULL(console.ui_data(pilot)["generated_domain"], "the console still reported a loaded domain after scrubbing")
