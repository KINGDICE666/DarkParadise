#define TRANSIT_TEST_LINE_LENGTH 4

/datum/unit_test/transit_tube_constructs

/datum/unit_test/transit_tube_constructs/Run()
	for(var/obj/structure/transit_tube/tube_type as anything in typesof(/obj/structure/transit_tube))
		var/obj/structure/c_transit_tube/construct_type = tube_type::tube_construction
		TEST_ASSERT(ispath(tube_type, construct_type::build_type), "[tube_type] detaches into [construct_type] that builds [construct_type::build_type]")

	for(var/obj/structure/c_transit_tube/construct_type as anything in typesof(/obj/structure/c_transit_tube))
		TEST_ASSERT(icon_exists(construct_type::icon, construct_type::icon_state), "[construct_type] has no icon state [construct_type::icon_state]")
		var/obj/structure/c_transit_tube/construct = allocate(construct_type)
		if(!construct.flipped_build_type)
			continue
		var/flipped_type = construct.flipped_build_type
		construct.flip()
		TEST_ASSERT_EQUAL(construct.build_type, flipped_type, "[construct_type] does not swap its build type on flip")
		TEST_ASSERT(icon_exists(construct.icon, construct.icon_state), "[construct_type] has no flipped icon state [construct.icon_state]")

	for(var/datum/pipes/transit/tube in GLOB.construction_pipe_list)
		if(!tube.rpd_dispensable)
			continue
		TEST_ASSERT_EQUAL(get_transit_tube_construct(tube.pipe_id), tube.construct_type, "[tube.pipe_name] does not resolve to its construct")
		TEST_ASSERT(icon_exists(tube.pipe_icon_file, tube.pipe_icon), "[tube.pipe_name] has no preview icon state [tube.pipe_icon]")

/datum/unit_test/room_test/transit_tube_travel

/datum/unit_test/room_test/transit_tube_travel/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/turf/start = anchor
	var/turf/finish = locate(anchor.x + TRANSIT_TEST_LINE_LENGTH, anchor.y, anchor.z)
	allocate(/obj/structure/transit_tube/station/reverse, start, NORTH)
	for(var/offset in 1 to TRANSIT_TEST_LINE_LENGTH - 1)
		allocate(/obj/structure/transit_tube, locate(anchor.x + offset, anchor.y, anchor.z), EAST)
	allocate(/obj/structure/transit_tube/station/reverse, finish, SOUTH)
	sleep(1 SECONDS)

	var/obj/structure/transit_tube_pod/pod = allocate(/obj/structure/transit_tube_pod, start)

	var/deadline = world.time + 15 SECONDS
	while(pod.loc != finish && world.time < deadline)
		sleep(1)
	TEST_ASSERT_EQUAL(pod.loc, finish, "the pod did not reach the far station")
	qdel(pod)

#undef TRANSIT_TEST_LINE_LENGTH
