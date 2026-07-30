/datum/brain_trauma/unit_test
	name = "Unit Test Trauma"
	random_gain = FALSE
	var/gained = 0
	var/lost = 0

/datum/brain_trauma/unit_test/on_gain()
	gained++
	return ..()

/datum/brain_trauma/unit_test/on_lose(silent)
	lost++
	return ..()

/datum/brain_trauma/unit_test/stubborn
	resilience = TRAUMA_RESILIENCE_SURGERY

/datum/unit_test/brain_damage_strings/Run()
	for(var/attempt in 1 to 50)
		var/phrase = pick_list_replacements(BRAIN_DAMAGE_FILE, "brain_damage")
		TEST_ASSERT(phrase, "[BRAIN_DAMAGE_FILE] gave an empty phrase")
		TEST_ASSERT(!findtext(phrase, "@pick("), "[BRAIN_DAMAGE_FILE] left an unresolved substitution in '[phrase]'")

/datum/unit_test/room_test/brain_trauma_lifecycle/Run()
	for(var/datum/brain_trauma/trauma_type as anything in subtypesof(/datum/brain_trauma))
		if(trauma_type::abstract_type == trauma_type)
			continue

		var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
		var/datum/brain_trauma/trauma = patient.gain_trauma(trauma_type)
		if(QDELETED(trauma))
			continue

		TEST_ASSERT_EQUAL(trauma.type, trauma_type, "gain_trauma() gave [trauma.type] instead of [trauma_type]")
		for(var/tick in 1 to 20)
			trauma.on_life()
			patient.say("проверка связи это тестовое сообщение")

		qdel(trauma)
		TEST_ASSERT(!patient.has_trauma_type(trauma_type, TRAUMA_RESILIENCE_ABSOLUTE), "[trauma_type] survived being deleted")

/datum/unit_test/room_test/brain_trauma_resilience/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/datum/brain_trauma/stubborn = patient.gain_trauma(/datum/brain_trauma/unit_test/stubborn)

	patient.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)
	TEST_ASSERT(!QDELETED(stubborn), "a surgery tier trauma was cured by basic tier curing")

	patient.cure_trauma_type(resilience = TRAUMA_RESILIENCE_SURGERY)
	TEST_ASSERT(QDELETED(stubborn), "a surgery tier trauma survived surgery tier curing")

/datum/unit_test/room_test/brain_trauma_traits/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/external/left_hand = patient.get_organ(BODY_ZONE_PRECISE_L_HAND)
	var/obj/item/organ/external/right_hand = patient.get_organ(BODY_ZONE_PRECISE_R_HAND)

	TEST_ASSERT(left_hand.is_usable(), "the test dummy started with an unusable left hand")

	ADD_TRAIT(patient, TRAIT_PARALYSIS_L_ARM, TRAUMA_TRAIT)
	TEST_ASSERT(!left_hand.is_usable(), "a paralysed left hand is still usable")
	TEST_ASSERT(right_hand.is_usable(), "paralysing the left arm made the right hand unusable")

	REMOVE_TRAIT(patient, TRAIT_PARALYSIS_L_ARM, TRAUMA_TRAIT)
	TEST_ASSERT(left_hand.is_usable(), "the left hand stayed unusable after the paralysis was cured")

	TEST_ASSERT(patient.is_literate(), "the test dummy started illiterate")
	ADD_TRAIT(patient, TRAIT_ILLITERATE, TRAUMA_TRAIT)
	TEST_ASSERT(!patient.is_literate(), "an illiterate mob can still read")

	TEST_ASSERT(patient.IsAdvancedToolUser(), "the test dummy started unable to use tools")
	patient.apply_status_effect(/datum/status_effect/discoordinated)
	TEST_ASSERT(!patient.IsAdvancedToolUser(), "a discoordinated mob can still use tools")
	patient.remove_status_effect(/datum/status_effect/discoordinated)
	TEST_ASSERT(patient.IsAdvancedToolUser(), "tool use did not come back after discoordination ended")

/datum/unit_test/room_test/brain_damage_scale/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	patient.adjustBrainLoss(BRAIN_DAMAGE_DEATH - 20, forced = TRUE)
	TEST_ASSERT_EQUAL(patient.getBrainLoss(), BRAIN_DAMAGE_DEATH - 20, "brain damage did not reach [BRAIN_DAMAGE_DEATH - 20]")
	TEST_ASSERT(patient.stat != DEAD, "the patient died before reaching [BRAIN_DAMAGE_DEATH] brain damage")

	patient.adjustBrainLoss(40, forced = TRUE)
	TEST_ASSERT_EQUAL(patient.getBrainLoss(), BRAIN_DAMAGE_DEATH, "brain damage was not capped at [BRAIN_DAMAGE_DEATH]")
	TEST_ASSERT_EQUAL(patient.stat, DEAD, "the patient survived [BRAIN_DAMAGE_DEATH] brain damage")

/datum/unit_test/room_test/brain_traumas/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/datum/brain_trauma/unit_test/trauma = patient.gain_trauma(/datum/brain_trauma/unit_test)

	TEST_ASSERT_NOTNULL(trauma, "gain_trauma() returned nothing")
	TEST_ASSERT_EQUAL(trauma.gained, 1, "on_gain() was not called exactly once on gaining the trauma")
	TEST_ASSERT(patient.has_trauma_type(/datum/brain_trauma/unit_test), "has_trauma_type() cannot find the gained trauma")
	TEST_ASSERT_NULL(patient.gain_trauma(/datum/brain_trauma/unit_test), "the same trauma type was gained twice")

	var/obj/item/organ/internal/brain/donor_brain = patient.get_int_organ(/obj/item/organ/internal/brain)
	donor_brain.remove(patient)
	TEST_ASSERT_EQUAL(trauma.lost, 1, "on_lose() was not called when the brain was removed")
	TEST_ASSERT_NULL(trauma.owner, "the trauma kept its owner after the brain was removed")
	TEST_ASSERT_EQUAL(trauma.brain, donor_brain, "the trauma did not stay with the removed brain")

	var/mob/living/carbon/human/recipient = allocate(/mob/living/carbon/human)
	qdel(recipient.get_int_organ(/obj/item/organ/internal/brain))
	donor_brain.insert(recipient)
	TEST_ASSERT_EQUAL(trauma.gained, 2, "on_gain() was not called when the brain was transplanted")
	TEST_ASSERT_EQUAL(trauma.owner, recipient, "the trauma did not follow the brain to its new owner")

	recipient.cure_trauma_type(/datum/brain_trauma/unit_test, TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT(QDELETED(trauma), "cure_trauma_type() did not delete the trauma")
	TEST_ASSERT(!length(donor_brain.traumas), "the cured trauma was left in the brain's trauma list")
