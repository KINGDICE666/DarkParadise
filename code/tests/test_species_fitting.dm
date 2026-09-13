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
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)
	TEST_ASSERT_EQUAL(swine_fit.describe_source(null, DEFAULT_ICON_JUMPSUIT, "maid_s"), "manual patch", "a hand-drawn patch state lost to the generator")
	TEST_ASSERT_EQUAL(swine_fit.describe_source(null, DEFAULT_ICON_JUMPSUIT, "security_s"), "generated", "a state with no hand-drawn patch was not generated")
	TEST_ASSERT_EQUAL(swine_fit.describe_source(null, DEFAULT_ICON_WEAR_MASK, "gas_alt"), "blocked", "the deliberately vanilla mask slot was fitted anyway")

	var/mob/living/carbon/human/trottine = allocate(/mob/living/carbon/human)
	trottine.set_species(/datum/species/swine)
	var/obj/item/clothing/under/uniform = allocate(/obj/item/clothing/under/rank/security)
	trottine.equip_to_slot_or_del(uniform, ITEM_SLOT_CLOTH_INNER)

	var/mutable_appearance/worn = uniform.build_worn_icon(default_icon_file = DEFAULT_ICON_JUMPSUIT, override_state = "[uniform.icon_state]_s")
	TEST_ASSERT_NOTNULL(worn, "a worn uniform produced no appearance at all")
	TEST_ASSERT_EQUAL("[worn.icon]", "", "the worn uniform came straight from a file instead of the generator")

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
	TEST_ASSERT_NULL(vanilla.GetPixel(16, 7), "the vanilla uniform is expected to stop above the lower swine groin")
	TEST_ASSERT_NULL(vanilla.GetPixel(11, 9), "the vanilla uniform is expected to stop short of the wider swine hip")

	var/icon/fitted = swine_fit.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, "security_s")
	TEST_ASSERT_NOTNULL(fitted.GetPixel(16, 7, dir = SOUTH), "the fitted uniform still leaves the swine bare where its body reaches lower than a human one")
	TEST_ASSERT_NOTNULL(fitted.GetPixel(11, 9, dir = SOUTH), "the fitted uniform still leaves the swine bare where its body is wider than a human one")

/datum/unit_test/species_fitting_greyscale

/datum/unit_test/species_fitting_greyscale/Run()
	var/mob/living/carbon/human/trottine = allocate(/mob/living/carbon/human)
	trottine.set_species(/datum/species/swine)
	var/obj/item/clothing/under/color/jumpsuit = allocate(/obj/item/clothing/under/color)
	trottine.equip_to_slot_or_del(jumpsuit, ITEM_SLOT_CLOTH_INNER)

	TEST_ASSERT_NULL(jumpsuit.sprite_sheets?[SPECIES_SWINE], "a hand-made swine greyscale sheet is back, so the generator never gets to see this item")

	var/human_sheet = jumpsuit.onmob_sheets[ITEM_SLOT_CLOTH_INNER_STRING]
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)
	TEST_ASSERT_NOTNULL(swine_fit.fit_worn_icon(null, human_sheet, "[jumpsuit.icon_state]_s"), "the fitter cannot read a greyscale-generated sheet, so a species without greyscale configs gets nothing")

	var/mutable_appearance/worn = jumpsuit.build_worn_icon(default_icon_file = human_sheet, override_state = "[jumpsuit.icon_state]_s")
	TEST_ASSERT_EQUAL("[worn.icon]", "", "the greyscale jumpsuit reached the swine body without being fitted")

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

/datum/unit_test/species_fitting_disk_cache

/datum/unit_test/species_fitting_disk_cache/Run()
	var/datum/species_fit/writer = new /datum/species_fit/swine
	writer.build()
	TEST_ASSERT_NOTNULL(writer.cache_key, "the swine profile produced no key to store its cached sheets under")

	var/icon/fitted = writer.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, "security_s")
	TEST_ASSERT_NOTNULL(fitted, "the swine profile refused to fit a plain uniform state")
	writer.flush_disk_cache()

	var/directory = writer.cache_directory()
	var/entry_name = writer.cache_entry_name("[DEFAULT_ICON_JUMPSUIT]")
	TEST_ASSERT(fexists("[directory]/manifest.json"), "the disk cache was flushed without writing a manifest")
	TEST_ASSERT(fexists("[directory]/[entry_name].dmi"), "the disk cache was flushed without writing the fitted sheet")

	var/datum/species_fit/reader = new /datum/species_fit/swine
	reader.build()
	reader.load_disk_cache()
	var/icon/restored = reader.read_disk_cache(DEFAULT_ICON_JUMPSUIT, "security_s")
	TEST_ASSERT_NOTNULL(restored, "the flushed uniform state was not found in the cache on the next load")

	var/east_pixels = 0
	for(var/fit_dir in GLOB.cardinal)
		for(var/y in 1 to writer.height)
			for(var/x in 1 to writer.width)
				var/pixel = fitted.GetPixel(x, y, dir = fit_dir)
				if(pixel && fit_dir == EAST)
					east_pixels++
				TEST_ASSERT_EQUAL(restored.GetPixel(x, y, dir = fit_dir), pixel, "the cached uniform lost pixel ([x], [y]) of its [dir2text(fit_dir)] frame")
	TEST_ASSERT(east_pixels > 0, "the east frame is empty, so the cache never proved it round-trips anything but south")

	var/list/manifest = json_decode(file2text("[directory]/manifest.json"))
	var/list/entry = manifest[entry_name]
	TEST_ASSERT_NOTNULL(entry, "the flushed uniform sheet is missing from the manifest")
	entry["hash"] = "stale"
	rustg_file_write(json_encode(manifest), "[directory]/manifest.json", "false")

	var/datum/species_fit/stale_reader = new /datum/species_fit/swine
	stale_reader.build()
	stale_reader.load_disk_cache()
	TEST_ASSERT_NULL(stale_reader.read_disk_cache(DEFAULT_ICON_JUMPSUIT, "security_s"), "a cache entry was served even though its source sheet had changed")
	TEST_ASSERT(!fexists("[directory]/[entry_name].dmi"), "an invalidated cache entry was left on disk")

	fdel("[directory]/")

/datum/unit_test/species_fitting_span_remap

/datum/unit_test/species_fitting_span_remap/Run()
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)
	swine_fit.build()

	var/remapped_pixels = 0
	var/claimed_pixels = 0
	for(var/fit_dir in GLOB.cardinal)
		var/list/span_map = swine_fit.span_maps["[fit_dir]"]
		var/list/pixel_tier = swine_fit.pixel_tier_maps["[fit_dir]"]
		for(var/index in 1 to swine_fit.width * swine_fit.height)
			if(span_map[index])
				remapped_pixels++
			if(pixel_tier[index])
				claimed_pixels++
	TEST_ASSERT(claimed_pixels > 0, "no target pixel was claimed by a body part, so the span map never saw the body")
	TEST_ASSERT(remapped_pixels > 0, "the span map is empty, so the remap step is dead code on the swine")

	var/icon/vanilla = icon(DEFAULT_ICON_SHOES, "workboots")
	var/icon/fitted = swine_fit.fit_worn_icon(null, DEFAULT_ICON_SHOES, "workboots")
	TEST_ASSERT_NOTNULL(fitted, "the swine profile refused to fit a boot")
	for(var/fit_dir in GLOB.cardinal)
		var/list/shrunk = swine_fit.shrunk_masks["[fit_dir]"]
		for(var/y in 1 to swine_fit.height)
			for(var/x in 1 to swine_fit.width)
				if(!vanilla.GetPixel(x, y, dir = fit_dir) || shrunk[swine_fit.width * (y - 1) + x])
					continue
				TEST_ASSERT_NOTNULL(fitted.GetPixel(x, y, dir = fit_dir), "the remap squashed the boot into a hole at ([x], [y]) of its [dir2text(fit_dir)] frame")

/datum/unit_test/species_fitting_head_trim

/datum/unit_test/species_fitting_head_trim/Run()
	var/datum/species_fit/swine_fit = get_species_fit(/datum/species_fit/swine)

	var/icon/vanilla = icon(DEFAULT_ICON_JUMPSUIT, "security_s", SOUTH)
	TEST_ASSERT_NULL(vanilla.GetPixel(15, 23), "the vanilla uniform is expected to leave the human head bare here")
	TEST_ASSERT_NOTNULL(vanilla.GetPixel(15, 22), "the vanilla uniform is expected to draw its own collar here")

	var/icon/fitted = swine_fit.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, "security_s")
	TEST_ASSERT_NOTNULL(fitted, "the swine profile refused to fit a plain uniform state")
	TEST_ASSERT_NULL(fitted.GetPixel(15, 23, dir = SOUTH), "the fitter smeared the uniform onto a head the garment does not dress")
	TEST_ASSERT_NOTNULL(fitted.GetPixel(15, 22, dir = SOUTH), "the head trim ate the collar the garment draws itself")

	var/icon/hat = swine_fit.fit_worn_icon(null, DEFAULT_ICON_HEAD, "welding")
	TEST_ASSERT_NOTNULL(hat, "the swine profile refused to fit a welding helmet")
	for(var/fit_dir in GLOB.cardinal)
		var/list/target_head = swine_fit.target_head_masks["[fit_dir]"]
		var/hat_pixels = 0
		for(var/y in 1 to swine_fit.height)
			for(var/x in 1 to swine_fit.width)
				if(target_head[swine_fit.width * (y - 1) + x] && hat.GetPixel(x, y, dir = fit_dir))
					hat_pixels++
		TEST_ASSERT(hat_pixels > 0, "the head trim stripped a helmet on its [dir2text(fit_dir)] frame, and a helmet is exactly the garment that should dress a head")

	var/icon/vanilla_monocle = icon(DEFAULT_ICON_GLASSES, "monocle", NORTH)
	TEST_ASSERT_NULL(vanilla_monocle.GetPixel(19, 23), "the vanilla monocle is expected to leave this pixel to the fitter")
	var/icon/monocle = swine_fit.fit_worn_icon(null, DEFAULT_ICON_GLASSES, "monocle")
	TEST_ASSERT_NOTNULL(monocle.GetPixel(19, 23, dir = NORTH), "the monocle was head-trimmed on the one frame where it barely covers a human head, so the gate is being judged per direction instead of per state")

/datum/unit_test/species_fitting_profiles

/datum/unit_test/species_fitting_profiles/Run()
	for(var/fit_type in list(/datum/species_fit/vox, /datum/species_fit/drask))
		var/datum/species_fit/fit = get_species_fit(fit_type)
		TEST_ASSERT_NOTNULL(fit, "[fit_type] was never created")
		TEST_ASSERT_NOTNULL(fit.fit_worn_icon(null, DEFAULT_ICON_BELT, "assault"), "[fit_type] left a belt human-shaped, and no hand-drawn sheet covers that slot")

	TEST_ASSERT_NULL(/datum/species/vox/armalis::fit_profile, "the armalis form inherited the vox profile, whose masks come from a body half its height")

	var/mob/living/carbon/human/raider = allocate(/mob/living/carbon/human)
	raider.set_species(/datum/species/vox)
	var/obj/item/clothing/gloves/gauntlets = allocate(/obj/item/clothing/gloves/vox)
	raider.equip_to_slot_or_del(gauntlets, ITEM_SLOT_GLOVES)
	TEST_ASSERT_EQUAL(get_worn_icon_source(raider, gauntlets, DEFAULT_ICON_GLOVES, gauntlets.icon_state), "sprite_sheets", "a hand-drawn vox sheet lost to the generator")
