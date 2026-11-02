/datum/unit_test/room_test/new_dna_genes/Run()
	for(var/block in list(GLOB.immunityblock, GLOB.hypermetabolicbloodblock, GLOB.painthresholdblock))
		TEST_ASSERT(block, "a new gene was given no DNA block")
		TEST_ASSERT_NOTNULL(GLOB.assigned_gene_blocks[block], "DNA block [block] has no gene")

	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human)

	subject.force_gene_block(GLOB.immunityblock, TRUE)
	TEST_ASSERT(HAS_TRAIT(subject, TRAIT_VIRUSIMMUNE), "the immunity gene does not give virus immunity")
	var/datum/disease/virus/cold/cold = new
	TEST_ASSERT_NOT(cold.Contract(subject), "a mob with the immunity gene caught a cold")

	subject.force_gene_block(GLOB.painthresholdblock, TRUE)
	TEST_ASSERT_EQUAL(subject.shock_reduction(), /datum/reagent/medicine/sal_acid::shock_reduction, "the pain threshold gene does not work like salicylic acid")
	TEST_ASSERT_EQUAL(control.shock_reduction(), 0, "a mob without the pain threshold gene has reduced pain")

	subject.force_gene_block(GLOB.hypermetabolicbloodblock, TRUE)
	subject.setBlood(BLOOD_VOLUME_NORMAL / 2)
	control.setBlood(BLOOD_VOLUME_NORMAL / 2)
	for(var/tick in 1 to 1000)
		SSblood.restore_blood_volume(subject)
		SSblood.restore_blood_volume(control)
	var/subject_regen = subject.blood_volume - BLOOD_VOLUME_NORMAL / 2
	var/control_regen = control.blood_volume - BLOOD_VOLUME_NORMAL / 2
	TEST_ASSERT(control_regen > 0, "blood does not regenerate at all")
	var/regen_ratio = subject_regen / control_regen
	TEST_ASSERT(regen_ratio > 1.4 && regen_ratio < 1.6, "hypermetabolic blood regenerates [regen_ratio] times faster instead of one and a half")

	subject.force_gene_block(GLOB.immunityblock, FALSE)
	subject.force_gene_block(GLOB.painthresholdblock, FALSE)
	subject.force_gene_block(GLOB.hypermetabolicbloodblock, FALSE)
	TEST_ASSERT_NOT(HAS_TRAIT(subject, TRAIT_VIRUSIMMUNE), "removing the immunity gene leaves virus immunity")
	TEST_ASSERT_NOT(HAS_TRAIT(subject, TRAIT_HIGH_PAIN_THRESHOLD), "removing the pain threshold gene leaves the trait")
	TEST_ASSERT_NOT(HAS_TRAIT(subject, TRAIT_HYPERMETABOLIC_BLOOD), "removing the hypermetabolic blood gene leaves the trait")
