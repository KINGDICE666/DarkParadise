/datum/unit_test/species_fitting

/datum/unit_test/species_fitting/Run()
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)
	TEST_ASSERT_NOTNULL(swine_fit, "the swine fit profile was not created")

	var/icon/vanilla = icon(DEFAULT_ICON_JUMPSUIT, "security_s", SOUTH)
	TEST_ASSERT_NULL(vanilla.GetPixel(11, 16), "the vanilla uniform is expected to leave this pixel bare")

	var/icon/fitted = swine_fit.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, "security_s")
	TEST_ASSERT_NOTNULL(fitted, "the swine profile refused to fit a plain uniform state")
	TEST_ASSERT_NOTNULL(fitted.GetPixel(11, 16, dir = SOUTH), "the fitted uniform still leaves swine skin bare at the widened torso")

	TEST_ASSERT(fitted == swine_fit.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, "security_s"), "fitting the same state twice did not hit the cache")

	TEST_ASSERT_NULL(swine_fit.fit_worn_icon(null, DEFAULT_ICON_WEAR_MASK, "gas_alt"), "a blocked sheet was fitted anyway")
	TEST_ASSERT_NULL(swine_fit.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, "there_is_no_such_state"), "a missing icon state was fitted anyway")

/datum/unit_test/species_fitting_priority

/datum/unit_test/species_fitting_priority/Run()
	var/mob/living/carbon/human/trottine = allocate(/mob/living/carbon/human)
	trottine.set_species(/datum/species/swine)
	var/obj/item/clothing/under/uniform = allocate(/obj/item/clothing/under/rank/security)
	trottine.equip_to_slot_or_del(uniform, ITEM_SLOT_CLOTH_INNER)

	var/mutable_appearance/worn = uniform.build_worn_icon(default_icon_file = DEFAULT_ICON_JUMPSUIT)
	TEST_ASSERT_NOTNULL(worn, "a worn uniform produced no appearance at all")
	TEST_ASSERT_EQUAL("[worn.icon]", "icons/mob/clothing/species/swine/uniform.dmi", "an explicit worn_sheets entry lost to the generator")

/datum/unit_test/species_fitting_contour

/datum/unit_test/species_fitting_contour/Run()
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)
	var/icon/fitted = swine_fit.fit_worn_icon(null, DEFAULT_ICON_OUTER_SUIT, "labcoat")
	TEST_ASSERT_NOTNULL(fitted, "the swine profile refused to fit a labcoat")

	TEST_ASSERT_EQUAL(fitted.GetPixel(12, 9, dir = EAST), "#898989", "the left outline of the coat was smeared away when the row was widened")
	TEST_ASSERT_EQUAL(fitted.GetPixel(22, 9, dir = EAST), "#848484", "the right outline of the coat was smeared away when the row was widened")
	TEST_ASSERT_EQUAL(fitted.GetPixel(12, 14, dir = EAST), "#898989", "the coat outline was lost on the chest row")

/datum/unit_test/species_fitting_shoulders

/datum/unit_test/species_fitting_shoulders/Run()
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)

	var/icon/vanilla = icon(DEFAULT_ICON_JUMPSUIT, "security_s", SOUTH)
	TEST_ASSERT_NULL(vanilla.GetPixel(16, 23), "the vanilla uniform is expected to stop below the swine shoulders")

	var/icon/fitted = swine_fit.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, "security_s")
	TEST_ASSERT_NOTNULL(fitted.GetPixel(16, 23, dir = SOUTH), "the fitted uniform still leaves the taller swine shoulders bare")
	TEST_ASSERT_NOTNULL(fitted.GetPixel(15, 24, dir = SOUTH), "the fitted uniform still leaves the swine neckline bare")

/datum/unit_test/species_fitting_greyscale

/datum/unit_test/species_fitting_greyscale/Run()
	var/mob/living/carbon/human/trottine = allocate(/mob/living/carbon/human)
	trottine.set_species(/datum/species/swine)
	var/obj/item/clothing/under/color/jumpsuit = allocate(/obj/item/clothing/under/color)
	trottine.equip_to_slot_or_del(jumpsuit, ITEM_SLOT_CLOTH_INNER)

	var/species_sheet = jumpsuit.sprite_sheets?[SPECIES_SWINE]
	TEST_ASSERT_NOTNULL(species_sheet, "the greyscale jumpsuit lost its hand-made swine configuration")

	var/mutable_appearance/worn = jumpsuit.build_worn_icon(default_icon_file = jumpsuit.onmob_sheets[ITEM_SLOT_CLOTH_INNER_STRING], override_state = "[jumpsuit.icon_state]_s")
	TEST_ASSERT_EQUAL("[worn.icon]", "[species_sheet]", "a hand-made greyscale species sheet was re-fitted instead of being used as-is")

	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)
	var/human_sheet = jumpsuit.onmob_sheets[ITEM_SLOT_CLOTH_INNER_STRING]
	TEST_ASSERT_NOTNULL(swine_fit.fit_worn_icon(null, human_sheet, "[jumpsuit.icon_state]_s"), "the fitter cannot read a greyscale-generated sheet, so a species without greyscale configs gets nothing")

/datum/unit_test/species_fitting_trim

/datum/unit_test/species_fitting_trim/Run()
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)
	var/icon/fitted = swine_fit.fit_worn_icon(null, DEFAULT_ICON_OUTER_SUIT, "labcoat")
	TEST_ASSERT_NOTNULL(fitted, "the swine profile refused to fit a labcoat")

	var/list/shrunk = swine_fit.shrunk_masks["[SOUTH]"]
	var/shrunk_pixels = 0
	for(var/y in 1 to swine_fit.height)
		for(var/x in 1 to swine_fit.width)
			if(!shrunk[swine_fit.width * (y - 1) + x])
				continue
			shrunk_pixels++
			TEST_ASSERT_NULL(fitted.GetPixel(x, y, dir = SOUTH), "cloth was left hanging at ([x], [y]), where the swine body is narrower than the human one")
	TEST_ASSERT(shrunk_pixels > 0, "the swine body is nowhere narrower than the human one, so the trim step went untested")
