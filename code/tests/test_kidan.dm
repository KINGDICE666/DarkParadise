/**
 * Pesticide must kill kida through normal metabolism and critical-condition handling.
 * Humans must survive the same exposure, and both species must deplete the reagent at the normal rate.
 */
/datum/unit_test/room_test/kidan_pesticide

/datum/unit_test/room_test/kidan_pesticide/Run()
	var/mob/living/carbon/human/kidan = allocate(/mob/living/carbon/human)
	kidan.set_species(/datum/species/kidan)
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human)
	kidan.reagents.add_reagent("pestkiller", 25)
	control.reagents.add_reagent("pestkiller", 25)

	// Accumulate enough toxicity for deterministic death, without relying on random critical-condition rolls.
	for(var/cycle in 1 to 50)
		kidan.reagents.metabolize(kidan)
		control.reagents.metabolize(control)

	kidan.handle_critical_condition()
	control.handle_critical_condition()
	TEST_ASSERT_EQUAL(kidan.stat, DEAD, "A kidan survived prolonged pesticide exposure.")
	TEST_ASSERT_NOT(control.stat == DEAD, "A human died from kidan-specific pesticide vulnerability.")
	TEST_ASSERT_EQUAL(control.getToxLoss(), 50, "Kidan pesticide vulnerability affected a human.")
	TEST_ASSERT_EQUAL(kidan.reagents.get_reagent_amount("pestkiller"), control.reagents.get_reagent_amount("pestkiller"), "Kidan pesticide vulnerability changed the normal metabolism rate.")

/**
 * Touching pesticide from a spray must poison kida, respect clothing permeability, and leave humans unaffected by absorption.
 */
/datum/unit_test/room_test/kidan_pesticide_contact

/datum/unit_test/room_test/kidan_pesticide_contact/Run()
	var/mob/living/carbon/human/kidan = allocate(/mob/living/carbon/human)
	kidan.set_species(/datum/species/kidan)
	var/mob/living/carbon/human/protected_kidan = allocate(/mob/living/carbon/human)
	protected_kidan.set_species(/datum/species/kidan)
	protected_kidan.equip_to_slot_or_del(allocate(/obj/item/clothing/suit/bio_suit), ITEM_SLOT_CLOTH_OUTER)
	protected_kidan.equip_to_slot_or_del(allocate(/obj/item/clothing/head/bio_hood), ITEM_SLOT_HEAD)
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human)
	var/obj/item/reagent_containers/spray/pestspray/spray = allocate(/obj/item/reagent_containers/spray/pestspray)
	var/exposure_fraction = spray.amount_per_transfer_from_this / spray.reagents.total_volume
	spray.reagents.reaction(kidan, REAGENT_TOUCH, exposure_fraction)
	spray.reagents.reaction(protected_kidan, REAGENT_TOUCH, exposure_fraction)
	spray.reagents.reaction(control, REAGENT_TOUCH, exposure_fraction)

	var/kidan_dose = kidan.reagents.get_reagent_amount("pestkiller")
	var/protected_dose = protected_kidan.reagents.get_reagent_amount("pestkiller")
	TEST_ASSERT_EQUAL(kidan_dose, spray.amount_per_transfer_from_this, "Contact pesticide did not enter an unprotected kidan.")
	TEST_ASSERT(protected_dose < kidan_dose, "Protective clothing did not reduce the absorbed pesticide dose.")
	TEST_ASSERT_EQUAL(control.reagents.get_reagent_amount("pestkiller"), 0, "Contact pesticide unexpectedly penetrated a human.")
	var/tox_before_metabolism = kidan.getToxLoss()
	kidan.reagents.metabolize(kidan)
	TEST_ASSERT(kidan.getToxLoss() > tox_before_metabolism, "Sprayed pesticide did not cause ongoing poisoning.")

	var/tox_before_zero_exposure = protected_kidan.getToxLoss()
	spray.reagents.reaction(protected_kidan, REAGENT_TOUCH, volume_modifier = 0)
	TEST_ASSERT_EQUAL(protected_kidan.getToxLoss(), tox_before_zero_exposure, "Zero pesticide exposure dealt contact damage.")
	TEST_ASSERT_EQUAL(protected_kidan.reagents.get_reagent_amount("pestkiller"), protected_dose, "Zero pesticide exposure entered a kidan.")
