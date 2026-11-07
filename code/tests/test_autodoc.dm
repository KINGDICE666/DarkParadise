/obj/machinery/autodoc/unit_test
	var/forced_failure_chance = 0

/obj/machinery/autodoc/unit_test/get_failure_chance(datum/autodoc_procedure/procedure)
	return forced_failure_chance

/datum/unit_test/room_test/autodoc
	var/obj/machinery/autodoc/unit_test/machine
	var/mob/living/carbon/human/patient

/datum/unit_test/room_test/autodoc/Run()
	machine = allocate(/obj/machinery/autodoc/unit_test)
	machine.stat &= ~NOPOWER
	machine.installed_modules += new /obj/item/disk/autodoc_module/organs(machine)
	patient = allocate(/mob/living/carbon/human)

	check_refill()
	check_treatment()
	check_failure()
	check_out_of_fuel()
	check_interruption()
	check_organs()
	check_modules()
	check_stale_order_data()
	check_order_keeps_risk()
	check_failure_chances()
	check_emag()
	check_access()
	check_compatibility()
	check_organ_preservation()

/datum/unit_test/room_test/autodoc/proc/load_patient(obj/machinery/autodoc/into = machine)
	into.accept_patient(patient)

/datum/unit_test/room_test/autodoc/proc/run_program()
	machine.start_program(patient)
	for(var/tick in 1 to 500)
		if(!machine.running)
			return
		machine.process(2)

/datum/unit_test/room_test/autodoc/proc/check_refill()
	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human)
	var/obj/item/reagent_containers/cup/beaker/large/beaker = allocate(/obj/item/reagent_containers/cup/beaker/large)
	beaker.reagents.add_reagent("water", 10)
	beaker.reagents.add_reagent("synthflesh", 90)
	operator.a_intent = INTENT_HELP
	operator.put_in_active_hand(beaker)
	beaker.melee_attack_chain(operator, machine)
	TEST_ASSERT_EQUAL(machine.get_fuel(), 90, "synthflesh was not transferred from the beaker")
	TEST_ASSERT_EQUAL(machine.reagents.total_volume, 90, "something besides synthflesh got into the tank")
	TEST_ASSERT_EQUAL(beaker.reagents.get_reagent_amount("water"), 10, "water left the beaker")

/datum/unit_test/room_test/autodoc/proc/check_treatment()
	var/obj/item/organ/external/leg = patient.get_organ(BODY_ZONE_L_LEG)
	var/obj/item/organ/external/arm = patient.get_organ(BODY_ZONE_R_ARM)
	var/obj/item/organ/internal/heart = patient.get_organ_slot(INTERNAL_ORGAN_HEART)
	leg.fracture(silent = TRUE)
	arm.internal_bleeding(silent = TRUE)
	heart.internal_receive_damage(10, silent = TRUE)
	arm.external_receive_damage(0, 12, forced = TRUE)
	patient.adjustBrainLoss(10)
	load_patient()

	TEST_ASSERT_NOTNULL(machine.patient_icon, "the patient is not shown in the window")
	machine.add_all_orders()
	var/datum/autodoc_order/first_order = machine.queue[1]
	TEST_ASSERT_EQUAL(first_order.procedure.id, "internal_bleeding", "the worst condition was not queued first")
	var/queue_size = length(machine.queue)
	machine.add_all_orders()
	TEST_ASSERT_EQUAL(length(machine.queue), queue_size, "the same procedure was queued twice")

	var/fuel_before = machine.get_fuel()
	run_program()
	TEST_ASSERT_EQUAL(length(machine.queue), 0, "the queue was not finished")
	TEST_ASSERT_NOT(leg.has_fracture(), "the fracture was not mended")
	TEST_ASSERT_NOT(arm.has_internal_bleeding(), "the internal bleeding was not stopped")
	TEST_ASSERT_EQUAL(heart.damage, 0, "the heart was not repaired")
	TEST_ASSERT_EQUAL(arm.burn_dam, 0, "the burns were not healed")
	TEST_ASSERT_EQUAL(patient.getBrainLoss(), 0, "the brain was not repaired")
	TEST_ASSERT(patient.reagents.get_reagent_amount("hydrocodone") > 0, "no painkiller was injected")
	TEST_ASSERT(machine.get_fuel() < fuel_before, "the treatment was free")

/datum/unit_test/room_test/autodoc/proc/check_failure()
	var/obj/item/organ/internal/liver = patient.get_organ_slot(INTERNAL_ORGAN_LIVER)
	liver.internal_receive_damage(10, silent = TRUE)
	machine.reagents.add_reagent("synthflesh", 90)
	machine.forced_failure_chance = 100
	machine.add_all_orders()
	var/damage_before = liver.damage
	run_program()
	TEST_ASSERT(liver.damage > damage_before, "a failed procedure did not damage the treated organ")
	TEST_ASSERT_EQUAL(length(machine.queue), 0, "a failed procedure stayed in the queue")
	machine.forced_failure_chance = 0
	machine.add_all_orders()
	run_program()
	TEST_ASSERT_EQUAL(liver.damage, 0, "the organ was not repaired after the failure")

/datum/unit_test/room_test/autodoc/proc/check_out_of_fuel()
	var/obj/item/organ/external/leg = patient.get_organ(BODY_ZONE_L_LEG)
	leg.fracture(silent = TRUE)
	machine.reagents.clear_reagents()
	machine.add_all_orders()
	run_program()
	TEST_ASSERT(leg.has_fracture(), "the fracture was mended without synthflesh")
	TEST_ASSERT_EQUAL(length(machine.queue), 1, "the order was lost when the tank ran dry")
	machine.clear_queue()

/datum/unit_test/room_test/autodoc/proc/check_interruption()
	var/obj/item/organ/external/leg = patient.get_organ(BODY_ZONE_L_LEG)
	machine.reagents.add_reagent("synthflesh", 90)
	machine.add_all_orders()
	machine.start_program(patient)
	machine.process(2)
	var/brute_before = leg.brute_dam
	machine.go_out()
	TEST_ASSERT_NULL(machine.occupant, "the occupant was not cleared on exit")
	TEST_ASSERT_NULL(machine.patient_icon, "the patient icon survived the exit")
	TEST_ASSERT_EQUAL(length(machine.queue), 0, "the queue survived the exit")
	TEST_ASSERT_EQUAL(patient.loc, machine.loc, "the patient did not leave the machine")
	TEST_ASSERT(leg.brute_dam > brute_before, "aborting a paid surgery did not hurt the patient")
	leg.mend_fracture()

/datum/unit_test/room_test/autodoc/proc/check_organs()
	load_patient()
	machine.reagents.add_reagent("synthflesh", 90)
	var/obj/item/organ/internal/old_liver = patient.get_organ_slot(INTERNAL_ORGAN_LIVER)
	var/obj/item/organ/internal/spare_liver = allocate(/obj/item/organ/internal/liver)
	machine.store_organ(spare_liver)
	TEST_ASSERT(spare_liver in machine.organ_tray, "the organ did not reach the tray")

	TEST_ASSERT(machine.add_order(GLOB.autodoc_procedures["organ_install"], spare_liver), "the spare organ was rejected")
	run_program()
	TEST_ASSERT_EQUAL(patient.get_organ_slot(INTERNAL_ORGAN_LIVER), spare_liver, "the spare organ was not installed")
	TEST_ASSERT(old_liver in machine.organ_tray, "the replaced organ did not reach the tray")
	TEST_ASSERT_NOT(spare_liver in machine.organ_tray, "the installed organ stayed in the tray")

	TEST_ASSERT(machine.add_order(GLOB.autodoc_procedures["organ_extract"], spare_liver), "the extraction was rejected")
	run_program()
	TEST_ASSERT_NULL(patient.get_organ_slot(INTERNAL_ORGAN_LIVER), "the organ was not extracted")
	TEST_ASSERT(spare_liver in machine.organ_tray, "the extracted organ did not reach the tray")

	var/obj/item/organ/internal/brain = patient.get_organ_slot(INTERNAL_ORGAN_BRAIN)
	TEST_ASSERT_NOT(machine.add_order(GLOB.autodoc_procedures["organ_extract"], brain), "the brain must not be extractable")

	TEST_ASSERT(machine.add_order(GLOB.autodoc_procedures["organ_install"], old_liver), "the old organ was rejected")
	run_program()
	TEST_ASSERT_EQUAL(patient.get_organ_slot(INTERNAL_ORGAN_LIVER), old_liver, "the old organ was not returned")

/datum/unit_test/room_test/autodoc/proc/check_modules()
	var/obj/item/organ/internal/liver = patient.get_organ_slot(INTERNAL_ORGAN_LIVER)
	var/obj/item/organ/internal/brain/brain = patient.get_organ_slot(INTERNAL_ORGAN_BRAIN)
	var/datum/autodoc_procedure/organ_procedure = GLOB.autodoc_procedures["organ_damage"]
	var/datum/autodoc_procedure/lobotomy = GLOB.autodoc_procedures["lobotomy"]
	var/datum/autodoc_procedure/implant_install = GLOB.autodoc_procedures["implant_install"]
	liver.internal_receive_damage(5, silent = TRUE)

	var/obj/item/disk/autodoc_module/organs/organ_disk = locate() in machine.installed_modules
	TEST_ASSERT(machine.can_perform(organ_procedure, liver), "the organ module did not unlock organ repair")
	organ_disk.forceMove(machine.loc)
	TEST_ASSERT_NOT(organ_disk in machine.installed_modules, "the ejected disk stayed installed")
	TEST_ASSERT_NOT(machine.can_perform(organ_procedure, liver), "organ repair works without the module")
	for(var/list/entry as anything in machine.get_diagnosis())
		TEST_ASSERT_NOTEQUAL(entry["id"], organ_procedure.id, "diagnosis offered organ repair without the module")
	machine.add_all_orders()
	for(var/datum/autodoc_order/order as anything in machine.queue)
		TEST_ASSERT_NOTEQUAL(order.procedure, organ_procedure, "organ repair was queued without the module")
	machine.clear_queue()

	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human)
	operator.a_intent = INTENT_HELP
	operator.put_in_active_hand(organ_disk)
	organ_disk.melee_attack_chain(operator, machine)
	TEST_ASSERT(organ_disk in machine.installed_modules, "the disk was not inserted by hand")

	TEST_ASSERT_NOT(machine.can_perform(lobotomy, brain), "lobotomy works without the module")
	var/obj/item/disk/autodoc_module/lobotomy/lobotomy_disk = allocate(/obj/item/disk/autodoc_module/lobotomy)
	operator.put_in_active_hand(lobotomy_disk)
	lobotomy_disk.melee_attack_chain(operator, machine)
	TEST_ASSERT(machine.can_perform(lobotomy, brain), "the module did not unlock lobotomy")
	var/datum/brain_trauma/stubborn = brain.gain_trauma_type(BRAIN_TRAUMA_SPECIAL, TRAUMA_RESILIENCE_LOBOTOMY)
	if(stubborn)
		machine.reagents.add_reagent("synthflesh", 90)
		machine.add_order(lobotomy, brain)
		run_program()
		TEST_ASSERT(QDELETED(stubborn), "lobotomy did not cure a stubborn trauma")
		brain.cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)

	var/obj/item/organ/internal/implant = allocate(/obj/item/organ/internal/cyberimp/chest/nutriment)
	machine.store_organ(implant)
	TEST_ASSERT_NOT(machine.can_perform(implant_install, implant), "implant installation works without the module")
	TEST_ASSERT_NOT(machine.can_perform(GLOB.autodoc_procedures["organ_install"], implant), "an implant was treated as an organ")
	var/obj/item/disk/autodoc_module/implants/implant_disk = allocate(/obj/item/disk/autodoc_module/implants)
	operator.put_in_active_hand(implant_disk)
	implant_disk.melee_attack_chain(operator, machine)
	TEST_ASSERT(machine.add_order(implant_install, implant), "the module did not unlock implant installation")
	run_program()
	TEST_ASSERT_EQUAL(implant.owner, patient, "the implant was not installed")
	TEST_ASSERT(machine.add_order(GLOB.autodoc_procedures["organ_extract"], implant), "the implant could not be extracted")
	run_program()
	TEST_ASSERT(implant in machine.organ_tray, "the implant was not extracted")
	machine.clear_queue()
	machine.go_out()

/datum/unit_test/room_test/autodoc/proc/check_failure_chances()
	var/obj/machinery/autodoc/real = allocate(/obj/machinery/autodoc)
	var/datum/autodoc_procedure/organ_procedure = GLOB.autodoc_procedures["organ_damage"]
	var/datum/autodoc_procedure/safe_procedure = GLOB.autodoc_procedures["regeneration"]
	TEST_ASSERT_EQUAL(round(real.get_failure_chance(), 1), 60, "wrong base failure chance")
	TEST_ASSERT_EQUAL(round(real.get_failure_chance(organ_procedure), 1), 90, "wrong organ failure chance")
	TEST_ASSERT_EQUAL(real.get_failure_chance(safe_procedure), 0, "a non-invasive procedure must not fail")
	real.scanner_rating = 4
	TEST_ASSERT_EQUAL(round(real.get_failure_chance(), 1), 20, "wrong upgraded failure chance")
	TEST_ASSERT_EQUAL(round(real.get_failure_chance(organ_procedure), 1), 20, "wrong upgraded organ failure chance")
	real.scanner_rating = 1
	real.mode = AUTODOC_MODE_SLOW
	TEST_ASSERT_EQUAL(round(real.get_failure_chance(), 1), 45, "the slow mode should lower the risk")
	real.mode = AUTODOC_MODE_FAST
	TEST_ASSERT_EQUAL(round(real.get_failure_chance(), 1), 75, "the fast mode should raise the risk")

/datum/unit_test/room_test/autodoc/proc/check_emag()
	var/obj/machinery/autodoc/real = allocate(/obj/machinery/autodoc)
	real.stat &= ~NOPOWER
	real.reagents.add_reagent("synthflesh", 100)
	patient.reagents.clear_reagents()
	load_patient(real)
	real.emag_act(null)
	TEST_ASSERT_EQUAL(real.mode, AUTODOC_MODE_OVERDRIVE, "the emag did not enable overdrive")
	TEST_ASSERT(real.running, "the emagged machine did not start on its own")
	TEST_ASSERT(length(real.queue), "the emagged machine did not find anything to treat")
	TEST_ASSERT_EQUAL(real.get_failure_chance(), 100, "the emag should make every procedure fail")

	real.relaymove(patient)
	TEST_ASSERT_EQUAL(patient.loc, real, "the patient escaped from the emagged machine")

	var/health_before = patient.health
	for(var/tick in 1 to 20)
		real.process(2)
	TEST_ASSERT(patient.health < health_before, "the emagged machine did not hurt the patient")
	TEST_ASSERT_EQUAL(patient.reagents.get_reagent_amount("hydrocodone"), 0, "the emagged machine injected a painkiller")

	real.reagents.clear_reagents()
	real.process(2)
	TEST_ASSERT_NOT(real.running, "the emagged machine kept working without synthflesh")
	real.relaymove(patient)
	TEST_ASSERT_EQUAL(patient.loc, real.loc, "the patient could not leave once the machine ran dry")

/datum/unit_test/room_test/autodoc/proc/check_access()
	var/obj/machinery/autodoc/real = allocate(/obj/machinery/autodoc)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NOT(real.allowed(stranger), "a stranger without an ID got access")
	var/list/data = real.ui_data(stranger)
	TEST_ASSERT(data["controlsLocked"], "the interface did not lock for a stranger")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_MEDICAL)
	stranger.put_in_active_hand(card)
	TEST_ASSERT(real.allowed(stranger), "a medical ID did not grant access")

/datum/unit_test/room_test/autodoc/proc/check_compatibility()
	var/obj/machinery/autodoc/real = allocate(/obj/machinery/autodoc)
	var/mob/living/carbon/human/candidate = allocate(/mob/living/carbon/human)
	TEST_ASSERT(real.can_accept(candidate, candidate), "a human was rejected")
	for(var/datum/species/species_type as anything in list(/datum/species/machine, /datum/species/plasmaman, /datum/species/nucleation, /datum/species/unathi))
		candidate.set_species(species_type)
		TEST_ASSERT_NOT(real.can_accept(candidate, candidate), "[species_type] was accepted")

/datum/unit_test/room_test/autodoc/proc/check_organ_preservation()
	var/obj/machinery/autodoc/real = allocate(/obj/machinery/autodoc)
	var/obj/item/organ/internal/liver/stored = allocate(/obj/item/organ/internal/liver)
	var/obj/item/organ/internal/liver/loose = allocate(/obj/item/organ/internal/liver)
	real.store_organ(stored)
	stored.germ_level = 0
	loose.germ_level = 0
	for(var/tick in 1 to 90)
		stored.process()
		loose.process()
	TEST_ASSERT(stored.germ_level < loose.germ_level / 2, "the tray did not slow the organ decay: [stored.germ_level] vs [loose.germ_level]")

/datum/unit_test/room_test/autodoc/proc/check_stale_order_data()
	var/obj/item/organ/external/leg = patient.get_organ(BODY_ZONE_L_LEG)
	load_patient()
	leg.fracture(silent = TRUE)
	machine.add_order(GLOB.autodoc_procedures["fracture"], leg)
	leg.mend_fracture()
	var/list/data = machine.ui_data(patient)
	var/list/order_data = data["queue"][1]
	TEST_ASSERT_EQUAL(order_data["duration"], 0, "a stale order reported a duration")
	machine.clear_queue()

/datum/unit_test/room_test/autodoc/proc/check_order_keeps_risk()
	var/obj/item/organ/external/leg = patient.get_organ(BODY_ZONE_L_LEG)
	leg.fracture(silent = TRUE)
	machine.reagents.add_reagent("synthflesh", 90)
	machine.forced_failure_chance = 100
	machine.add_order(GLOB.autodoc_procedures["fracture"], leg)
	machine.start_program(patient)
	machine.process(2)
	var/datum/autodoc_order/order = machine.queue[1]
	TEST_ASSERT_EQUAL(order.failure_chance, 100, "the order did not remember its risk")
	machine.forced_failure_chance = 0
	var/brute_before = leg.brute_dam
	for(var/tick in 1 to 500)
		if(!machine.running)
			break
		machine.process(2)
	TEST_ASSERT(leg.brute_dam > brute_before, "changing the risk mid-order affected a paid order")
	TEST_ASSERT(leg.has_fracture(), "a doomed order mended the fracture")
	TEST_ASSERT_EQUAL(length(machine.queue), 0, "the failed order stayed queued")
	TEST_ASSERT_EQUAL(machine.occupant, patient, "a failed program ejected the patient")
	leg.mend_fracture()
	machine.go_out()
