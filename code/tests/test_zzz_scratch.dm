/datum/unit_test/scratch_light_range

/datum/unit_test/scratch_light_range/Run()
	var/obj/effect/thing = allocate(/obj/effect)
	thing.set_light_range(9000)
	TEST_ASSERT_EQUAL(thing.light_range, MAXIMUM_LIGHT_RANGE, "set_light_range did not clamp")

	var/datum/sm_delam/delam = new
	var/obj/machinery/power/supermatter_crystal/crystal = allocate(/obj/machinery/power/supermatter_crystal)
	crystal.internal_energy = 1703324
	delam.lights(crystal)
	TEST_ASSERT_EQUAL(crystal.light_range, 30, "sm lights() did not clamp, got [crystal.light_range]")
	crystal.internal_energy = 2500
	delam.lights(crystal)
	TEST_ASSERT_EQUAL(crystal.light_range, 17, "sm lights() wrong at normal energy, got [crystal.light_range]")
