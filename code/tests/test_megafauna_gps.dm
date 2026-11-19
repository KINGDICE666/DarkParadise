/datum/unit_test/room_test/megafauna_gps/Run()
	var/mob/living/simple_animal/hostile/megafauna/dragon/drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon)
	var/obj/item/gps/mining/receiver = allocate(/obj/item/gps/mining)
	receiver.tracking = TRUE
	drake.forceMove(run_loc_floor_top_right)

	var/list/data = receiver.ui_data()
	var/found_signal = FALSE
	for(var/list/signal as anything in data["signals"])
		if(signal["tag"] == "Mysterious Signal" && (signal["position"] ~= ATOM_COORDS(run_loc_floor_top_right)))
			found_signal = TRUE
			break
	TEST_ASSERT(found_signal, "Mining GPS did not report the drake's current coordinates.")
	TEST_ASSERT(drake.internal_gps.local, "Megafauna signal should only be visible on the same Z-level.")

	drake.set_stat(DEAD)
	TEST_ASSERT_NOT(drake.internal_gps.tracking, "Dead drake continued transmitting.")
	drake.set_stat(CONSCIOUS)
	TEST_ASSERT(drake.internal_gps.tracking, "Revived drake did not resume transmitting.")

	var/obj/item/gps/beacon = drake.internal_gps
	drake.make_virtual_megafauna()
	TEST_ASSERT_NOT(beacon in GLOB.GPS_list, "Virtualized drake left a signal in the GPS list.")

	var/mob/living/simple_animal/hostile/megafauna/dragon/virtual_domain/virtual_drake = allocate(/mob/living/simple_animal/hostile/megafauna/dragon/virtual_domain)
	TEST_ASSERT_NULL(virtual_drake.internal_gps, "Virtual drake spawned with a GPS.")
