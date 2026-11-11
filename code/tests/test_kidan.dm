/// Pesticide must reach lethal toxicity in kida through metabolism, with normal depletion and no extra damage to humans.
/datum/unit_test/room_test/kidan_pesticide

/datum/unit_test/room_test/kidan_pesticide/Run()
	var/mob/living/carbon/human/kidan = allocate(/mob/living/carbon/human)
	kidan.set_species(/datum/species/kidan)
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human)
	kidan.reagents.add_reagent("pestkiller", 10)
	control.reagents.add_reagent("pestkiller", 10)

	for(var/cycle in 1 to 20)
		kidan.reagents.metabolize(kidan)
		control.reagents.metabolize(control)

	TEST_ASSERT(kidan.getToxLoss() >= kidan.maxHealth - HEALTH_THRESHOLD_DEAD, "Pesticide did not reach lethal toxicity in a kidan despite prolonged exposure.")
	TEST_ASSERT_EQUAL(control.getToxLoss(), 20, "Kidan pesticide vulnerability affected a human.")
	TEST_ASSERT_EQUAL(kidan.reagents.get_reagent_amount("pestkiller"), control.reagents.get_reagent_amount("pestkiller"), "Kidan pesticide vulnerability changed the normal metabolism rate.")
