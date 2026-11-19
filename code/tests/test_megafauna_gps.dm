/datum/unit_test/room_test/megafauna_gps/Run()
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon)
	var/obj/item/gps/mining/receiver = allocate(/obj/item/gps/mining)
	receiver.tracking = TRUE
	drake.forceMove(run_loc_floor_top_right)

	TEST_ASSERT(shows_drake(receiver), "Mining GPS did not report the drake's current coordinates.")
	var/turf/station_turf = locate(receiver.x, receiver.y, pick(levels_by_trait(STATION_LEVEL)))
	TEST_ASSERT(station_turf && station_turf.z != drake.z, "Expected a station turf outside the test Z-level.")
	var/obj/item/gps/mining/station_receiver = allocate(/obj/item/gps/mining, station_turf)
	station_receiver.tracking = TRUE
	TEST_ASSERT_NOT(shows_drake(station_receiver), "Mining GPS picked up the drake on a different Z-level.")

	drake.health = 0
	drake.death()
	TEST_ASSERT_EQUAL(drake.stat, DEAD, "Expected the drake to die.")
	TEST_ASSERT_NOT(shows_drake(receiver), "Dead drake continued transmitting.")
	drake.revive()
	TEST_ASSERT_EQUAL(drake.stat, CONSCIOUS, "Expected the drake to revive.")
	TEST_ASSERT(shows_drake(receiver), "Revived drake did not resume transmitting.")

	var/obj/item/gps/beacon = drake.internal_gps
	drake.make_virtual_megafauna()
	TEST_ASSERT_NOT(beacon in GLOB.GPS_list, "Virtualized drake left a signal in the GPS list.")

	var/mob/living/simple_animal/hostile/megafauna/dragon/virtual_domain/virtual_drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon/virtual_domain)
	TEST_ASSERT_NULL(virtual_drake.internal_gps, "Virtual drake spawned with a GPS.")

/datum/unit_test/room_test/megafauna_gps/proc/shows_drake(obj/item/gps/receiver)
	var/list/data = receiver.ui_data()
	for(var/list/signal as anything in data["signals"])
		if(signal["tag"] == "Mysterious Signal" && (signal["position"] ~= ATOM_COORDS(run_loc_floor_top_right)))
			return TRUE
	return FALSE
