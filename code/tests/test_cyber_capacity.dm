/datum/unit_test/room_test/cyber_capacity
	var/mob/living/carbon/human/patient

/datum/unit_test/room_test/cyber_capacity/Run()
	patient = allocate(/mob/living/carbon/human)
	check_capacity_limit()
	check_replacement()
	check_chips()
	check_sensors()

/datum/unit_test/room_test/cyber_capacity/proc/check_capacity_limit()
	TEST_ASSERT_EQUAL(patient.cyber_capacity, CYBER_CAPACITY_BASE, "wrong starting cyber capacity")
	var/obj/item/organ/internal/cyberimp/arm/combat/combat = allocate(/obj/item/organ/internal/cyberimp/arm/combat)
	var/obj/item/organ/internal/cyberimp/eyes/xray/xray = allocate(/obj/item/organ/internal/cyberimp/eyes/xray)
	var/obj/item/organ/internal/cyberimp/brain/anti_stun/anti_stun = allocate(/obj/item/organ/internal/cyberimp/brain/anti_stun)
	TEST_ASSERT(combat.can_insert(null, patient, FALSE), "first implant did not fit into base capacity")
	combat.insert(patient)
	TEST_ASSERT(xray.can_insert(null, patient, FALSE), "second implant did not fit into base capacity")
	xray.insert(patient)
	TEST_ASSERT_EQUAL(patient.get_cyber_load(), combat.cyber_cost + xray.cyber_cost, "cyber load does not sum installed implants")
	TEST_ASSERT(!anti_stun.can_insert(null, patient, FALSE), "implant over capacity was allowed")

/datum/unit_test/room_test/cyber_capacity/proc/check_replacement()
	var/obj/item/organ/internal/cyberimp/eyes/thermals/thermals = allocate(/obj/item/organ/internal/cyberimp/eyes/thermals)
	TEST_ASSERT(thermals.cyber_cost > patient.get_free_cyber_capacity(), "test implant fits without replacement")
	TEST_ASSERT(thermals.can_insert(null, patient, FALSE), "replacing an implant did not free its capacity")

/datum/unit_test/room_test/cyber_capacity/proc/check_chips()
	var/obj/item/organ/internal/cyberimp/brain/anti_stun/anti_stun = allocate(/obj/item/organ/internal/cyberimp/brain/anti_stun)
	var/obj/item/cyber_capacity_chip/chip = allocate(/obj/item/cyber_capacity_chip)
	chip.attack_self(patient)
	TEST_ASSERT_EQUAL(patient.cyber_capacity, CYBER_CAPACITY_BASE, "chip worked without a neuroadapter")

	var/obj/item/organ/internal/cyberimp/brain/neuroadapter/adapter = allocate(/obj/item/organ/internal/cyberimp/brain/neuroadapter)
	adapter.insert(patient)
	chip.attack_self(patient)
	TEST_ASSERT_EQUAL(patient.cyber_capacity, CYBER_CAPACITY_BASE + CYBER_CAPACITY_CHIP_BONUS, "chip did not raise cyber capacity")
	TEST_ASSERT(QDELETED(chip), "chip was not consumed")
	TEST_ASSERT(anti_stun.can_insert(null, patient, FALSE), "raised capacity did not allow a new implant")

	for(var/i in 1 to 10)
		var/obj/item/cyber_capacity_chip/extra_chip = allocate(/obj/item/cyber_capacity_chip)
		extra_chip.attack_self(patient)
	TEST_ASSERT_EQUAL(patient.cyber_capacity, CYBER_CAPACITY_MAX, "cyber capacity went over the maximum")
	patient.adjust_cyber_capacity(-INFINITY)
	TEST_ASSERT_EQUAL(patient.cyber_capacity, 0, "cyber capacity went below zero")

/datum/unit_test/room_test/cyber_capacity/proc/check_sensors()
	var/obj/item/organ/internal/cyberimp/brain/neuroadapter/adapter = patient.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEUROADAPTER)
	adapter.sensor_mode = SUIT_SENSOR_TRACKING
	TEST_ASSERT(hassensorlevel(patient, SUIT_SENSOR_TRACKING), "neuroadapter sensors are not read")
	adapter.remove(patient)
	TEST_ASSERT_EQUAL(getsensorlevel(patient), SUIT_SENSOR_OFF, "sensors still report without a neuroadapter")
