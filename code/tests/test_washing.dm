/datum/unit_test/room_test/washing
	/// Stuff we want to test that isn't cleanables, just to make sure they are getting cleaned when they should
	var/list/cleanable_bonus_list = list(
		/obj/effect/rune,
		/obj/item/clothing/gloves/color/black,
		///mob/living/carbon/human/dummy/consistent,
	)
	/// Tracks if we caught the clean signal, to know we washed successfully
	VAR_PRIVATE/clean_sig_caught = 0

/datum/unit_test/room_test/washing/Run()
	for(var/i in subtypesof(/obj/effect/decal/cleanable) + cleanable_bonus_list)
		var/atom/movable/to_clean = allocate(i)
		var/mopable = HAS_TRAIT(to_clean, TRAIT_MOPABLE)

		clean_sig_caught = 0
		RegisterSignal(to_clean, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(clean_caught))
		run_loc_floor_bottom_left.wash_tg(CLEAN_ALL)
		// mopables are cleaned when their turf is cleaned
		if(mopable)
			if(clean_sig_caught == 0)
				TEST_FAIL("[i] was not cleaned when its turf was cleaned (cleaning only mopables)!")
			if(clean_sig_caught > 1)
				TEST_FAIL("[i] was cleaned more than once when its turf was cleaned (cleaning only mopables)!")
		// non-mopables require the all_contents = TRUE flag to be cleaned
		else
			if(clean_sig_caught != 0)
				TEST_FAIL("[i] was cleaned when its turf was cleaned (cleaning only mopables)!")
			run_loc_floor_bottom_left.wash_tg(CLEAN_ALL, TRUE)
			if(clean_sig_caught == 0)
				TEST_FAIL("[i] was not cleaned when its turf was cleaned (cleaning all contents)!")
			if(clean_sig_caught > 1)
				TEST_FAIL("[i] was cleaned more than once when its turf was cleaned (cleaning all contents)!")

		if(!QDELETED(to_clean))
			if(istype(to_clean, /obj/effect/decal/cleanable))
				TEST_FAIL("[i] was not deleted when its turf was cleaned!")
			qdel(to_clean)

/datum/unit_test/room_test/washing/proc/clean_caught(...)
	SIGNAL_HANDLER

	clean_sig_caught += 1
	return COMPONENT_CLEANED

/datum/unit_test/room_test/sink_water_supply/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/reagent_containers/cup/beaker/beaker = allocate(/obj/item/reagent_containers/cup/beaker, user)
	for(var/sink_type in list(/obj/structure/sink, /obj/structure/sink/kitchen, /obj/structure/sink/puddle))
		var/obj/structure/sink/sink = allocate(sink_type, run_loc_floor_bottom_left)
		for(var/fill_count in 1 to 30)
			beaker.reagents.clear_reagents()
			sink.attackby(beaker, user)
			TEST_ASSERT_EQUAL(beaker.reagents.get_reagent_amount(/datum/reagent/water), beaker.amount_per_transfer_from_this, "[sink_type] ran out of water after [fill_count] fills")

/datum/unit_test/room_test/shower_water_supply/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/machinery/shower/shower = allocate(/obj/machinery/shower, run_loc_floor_bottom_left)
	shower.attack_hand(user)
	TEST_ASSERT(shower.on, "Shower did not turn on")
	var/water_volume = shower.reagents.total_volume
	for(var/wash_count in 1 to 100)
		shower.process(2)
	TEST_ASSERT(shower.on, "Shower turned off during continuous use")
	TEST_ASSERT_EQUAL(shower.reagents.total_volume, water_volume, "Shower depleted its water supply")
	shower.attack_hand(user)
	TEST_ASSERT_NOT(shower.on, "Shower did not turn off")
	TEST_ASSERT_EQUAL(shower.process(2), PROCESS_KILL, "Inactive shower kept processing")
	TEST_ASSERT_NOT(user.has_status_effect(/datum/status_effect/washing_regen), "Shower left its washing status effect after turning off")

/obj/item/reagent_containers/cup/beaker/transfer_amount_test
	var/selection_count = 0

/obj/item/reagent_containers/cup/beaker/transfer_amount_test/select_transfer_amount(mob/user)
	selection_count++

/datum/unit_test/room_test/container_transfer_menu/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/reagent_containers/cup/beaker/transfer_amount_test/beaker = allocate(/obj/item/reagent_containers/cup/beaker/transfer_amount_test, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(beaker.attack_hand_secondary(user), SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN, "Transfer menu did not consume the human's right-click")
	TEST_ASSERT_EQUAL(beaker.selection_count, 1, "Human right-click did not open the transfer menu")
	TEST_ASSERT_EQUAL(beaker.attack_robot_secondary(user), SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN, "Transfer menu did not consume the cyborg's right-click")
	TEST_ASSERT_EQUAL(beaker.selection_count, 2, "Cyborg right-click did not open the transfer menu")
	beaker.attack_self(user)
	beaker.attack_self_secondary(user)
	TEST_ASSERT_EQUAL(beaker.selection_count, 4, "In-hand clicks did not open the transfer menu")
	beaker.has_variable_transfer_amount = FALSE
	TEST_ASSERT_EQUAL(beaker.attack_hand_secondary(user), SECONDARY_ATTACK_CALL_NORMAL, "Fixed-volume container blocked normal human interaction")
	TEST_ASSERT_EQUAL(beaker.attack_robot_secondary(user), SECONDARY_ATTACK_CALL_NORMAL, "Fixed-volume container blocked normal cyborg interaction")
	TEST_ASSERT_EQUAL(beaker.selection_count, 4, "Fixed-volume container opened the transfer menu")
	beaker.has_variable_transfer_amount = TRUE
	beaker.possible_transfer_amounts = null
	TEST_ASSERT_EQUAL(beaker.attack_hand_secondary(user), SECONDARY_ATTACK_CALL_NORMAL, "Container without transfer options blocked normal interaction")
	TEST_ASSERT_EQUAL(beaker.selection_count, 4, "Container without transfer options opened the transfer menu")
