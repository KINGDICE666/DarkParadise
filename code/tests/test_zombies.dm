/datum/unit_test/room_test/zombie_lifecycle/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.mind_initialize()
	var/legs_before = patient.usable_legs
	var/hands_before = patient.usable_hands

	var/datum/disease/virus/zombie/zombie_virus = new
	var/datum/disease/virus/zombie/infection = zombie_virus.Contract(patient)
	TEST_ASSERT_NOTNULL(infection, "the zombie virus could not infect a human")
	infection.stage = 8
	for(var/tick in 1 to 10)
		infection.stage_act()

	TEST_ASSERT(patient.stat != DEAD, "rotting into a zombie killed the host")
	TEST_ASSERT(HAS_TRAIT(patient, TRAIT_I_WANT_BRAINS), "a fully rotten host did not become a zombie")
	TEST_ASSERT_NOTNULL(patient.GetComponent(/datum/component/zombie_regen), "the zombie got no regeneration")
	TEST_ASSERT(istype(patient.get_organ_slot(INTERNAL_ORGAN_BRAIN_TUMOR), /obj/item/organ/internal/zombietumor), "the zombie got no necrotic tumor")
	TEST_ASSERT_NOTNULL(patient.mind.has_antag_datum(/datum/antagonist/zombie), "the zombie got no antagonist datum")
	TEST_ASSERT(patient.can_speak_language(/datum/language/zombie), "the zombie can not speak the zombie language")
	TEST_ASSERT(!patient.can_speak_language(/datum/language/common), "the zombie can still speak common")
	TEST_ASSERT_EQUAL(patient.usable_legs, legs_before, "dead legs of the zombie stopped counting as usable")
	TEST_ASSERT_EQUAL(patient.usable_hands, hands_before, "dead hands of the zombie stopped counting as usable")
	for(var/obj/item/organ/external/limb as anything in patient.bodyparts)
		TEST_ASSERT(limb.is_dead(), "[limb] did not rot")

	infection.cure()

	TEST_ASSERT(!HAS_TRAIT(patient, TRAIT_I_WANT_BRAINS), "the cured zombie is still a zombie")
	TEST_ASSERT(!patient.HasDisease(/datum/disease/virus/zombie), "the cure left the virus in place")
	TEST_ASSERT_NULL(patient.mind.has_antag_datum(/datum/antagonist/zombie), "the cure left the antagonist datum")
	TEST_ASSERT_NULL(patient.GetComponent(/datum/component/zombie_regen), "the cure left the regeneration")
	TEST_ASSERT_NULL(patient.get_organ_slot(INTERNAL_ORGAN_BRAIN_TUMOR), "the cure left the necrotic tumor")
	TEST_ASSERT(patient.can_speak_language(/datum/language/common), "the cured zombie can not speak common again")
	TEST_ASSERT_EQUAL(patient.usable_legs, legs_before, "the cure broke the usable legs count")
	TEST_ASSERT_EQUAL(patient.usable_hands, hands_before, "the cure broke the usable hands count")
	for(var/obj/item/organ/external/limb as anything in patient.bodyparts)
		TEST_ASSERT(!limb.is_dead(), "[limb] stayed rotten after the cure")

/datum/unit_test/room_test/zombie_cure_research/Run()
	var/obj/item/paper/zombie_cure/research = allocate(/obj/item/paper/zombie_cure)
	TEST_ASSERT(findtext(research.info, "Омега"), "the research paper does not describe the omega sequence")
	TEST_ASSERT(length(research.info) > 200, "the research paper is empty")
