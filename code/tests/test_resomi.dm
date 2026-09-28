/datum/unit_test/resomi_clothing

/datum/unit_test/resomi_clothing/Run()
	var/datum/species_fit/fit = get_species_fit(/datum/species_fit/resomi)
	for(var/state in list("grey_s", "security_s", "engine_s"))
		var/icon/uniform = fit.fit_worn_icon(null, DEFAULT_ICON_JUMPSUIT, state)
		for(var/fit_dir in GLOB.cardinal)
			var/reaches_ankles = FALSE
			for(var/y in 1 to 3)
				for(var/x in 1 to 32)
					if(uniform.GetPixel(x, y, dir = fit_dir))
						reaches_ankles = TRUE
			TEST_ASSERT(reaches_ankles, "[state] trousers stop short of the resomi ankles facing [fit_dir]")
			TEST_ASSERT_NOTNULL(uniform.GetPixel(16, 16, dir = fit_dir), "[state] lost its chest facing [fit_dir]")
		for(var/fit_dir in list(SOUTH, NORTH))
			TEST_ASSERT_NOTNULL(uniform.GetPixel(20, 5, dir = fit_dir), "[state] leaves the right resomi shin bare facing [fit_dir]")
			TEST_ASSERT_NULL(uniform.GetPixel(17, 5, dir = fit_dir), "[state] widens its right trouser leg into the gap facing [fit_dir]")
		for(var/y in 14 to 16)
			TEST_ASSERT_NULL(uniform.GetPixel(13, y, dir = EAST), "[state] sticks out behind the resomi back facing east")
			TEST_ASSERT_NULL(uniform.GetPixel(20, y, dir = WEST), "[state] sticks out behind the resomi back facing west")
	var/icon/labcoat = fit.fit_worn_icon(null, DEFAULT_ICON_OUTER_SUIT, "labcoat_open")
	TEST_ASSERT_NOTNULL(labcoat.GetPixel(16, 11, dir = EAST), "labcoat_open leaves the resomi hand poking through its sleeve gap facing east")
	TEST_ASSERT_NOTNULL(labcoat.GetPixel(17, 11, dir = WEST), "labcoat_open leaves the resomi hand poking through its sleeve gap facing west")
	for(var/state in list("leathercoat", "bltrenchcoat", "brtrenchcoat"))
		var/icon/coat = fit.fit_worn_icon(null, DEFAULT_ICON_OUTER_SUIT, state)
		for(var/fit_dir in GLOB.cardinal)
			for(var/y in 1 to 5)
				for(var/x in 1 to 32)
					TEST_ASSERT_NULL(coat.GetPixel(x, y, dir = fit_dir), "[state] hem covers the resomi feet facing [fit_dir]")
	for(var/state in list("hastur", "ghost_sheet", "magusblue", "spacemime_suit"))
		var/icon/suit = fit.fit_worn_icon(null, DEFAULT_ICON_OUTER_SUIT, state)
		for(var/fit_dir in list(SOUTH, NORTH))
			for(var/y in 19 to 32)
				for(var/x in 1 to 32)
					if(x >= 8 && x <= 25)
						continue
					TEST_ASSERT_NULL(suit.GetPixel(x, y, dir = fit_dir), "[state] keeps human-width shoulders above the resomi shoulders facing [fit_dir]")

/datum/unit_test/resomi_animation

/datum/unit_test/resomi_animation/Run()
	var/datum/species_fit/writer = new /datum/species_fit/resomi
	writer.build()
	writer.cache_key = "unit_test_animation_[writer.cache_key]"
	for(var/state in list("cigon", "cigaron", "swat", "spliffon2"))
		TEST_ASSERT_NOTNULL(writer.fit_worn_icon(null, DEFAULT_ICON_WEAR_MASK, state), "[state] skipped fitting")
	writer.flush_disk_cache()
	var/datum/species_fit/reader = new /datum/species_fit/resomi
	reader.build()
	reader.cache_key = writer.cache_key
	reader.load_disk_cache()
	var/list/source_metadata = icon_metadata(DEFAULT_ICON_WEAR_MASK)
	var/list/cached_metadata = rustlib_dmi_read_metadata("[writer.cache_directory()]/[writer.cache_entry_name("[DEFAULT_ICON_WEAR_MASK]")].dmi")
	for(var/state in list("cigon", "cigaron", "swat", "spliffon2"))
		var/icon/fitted = reader.read_disk_cache(DEFAULT_ICON_WEAR_MASK, state)
		TEST_ASSERT_NOTNULL(fitted, "[state] did not survive the disk cache")
		var/list/source_state
		var/list/cached_state
		for(var/list/metadata in source_metadata["states"])
			if(metadata["name"] == state)
				source_state = metadata
		for(var/list/metadata in cached_metadata["states"])
			if(metadata["name"] == state)
				cached_state = metadata
		TEST_ASSERT_NOTNULL(cached_state, "[state] has no cached metadata")
		for(var/key in list("delay", "rewind", "movement", "loop_count"))
			TEST_ASSERT_EQUAL(json_encode(cached_state[key]), json_encode(source_state[key]), "[state] lost animation [key]")
	var/icon/cigarette = reader.read_disk_cache(DEFAULT_ICON_WEAR_MASK, "cigon")
	var/datum/fit_step/pixel_map/map_step = new
	for(var/fit_dir in GLOB.cardinal)
		var/list/first_pixels
		var/animated = FALSE
		for(var/frame_index in 1 to 8)
			TEST_ASSERT(length(icon_states(icon(cigarette, dir = fit_dir, frame = frame_index))), "cigarette lost frame [frame_index] facing [fit_dir]")
			var/list/pixels = writer.read_frame(icon(DEFAULT_ICON_WEAR_MASK, "cigon", fit_dir, frame_index))
			var/datum/fit_context/context = new(writer, fit_dir, pixels, writer.maps_for(null, DEFAULT_ICON_WEAR_MASK))
			map_step.apply(context)
			var/list/fitted_pixels = writer.read_frame(icon(cigarette, dir = fit_dir, frame = frame_index))
			TEST_ASSERT_EQUAL(json_encode(fitted_pixels), json_encode(context.working), "cigarette frame [frame_index] was frozen or fitted incorrectly facing [fit_dir]")
			if(first_pixels && json_encode(first_pixels) != json_encode(fitted_pixels))
				animated = TRUE
			first_pixels ||= fitted_pixels
		TEST_ASSERT(animated, "all fitted cigarette frames are identical facing [fit_dir]")
	fdel("[writer.cache_directory()]/")

/datum/unit_test/resomi_shoes

/datum/unit_test/resomi_shoes/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	wearer.set_species(/datum/species/resomi)
	for(var/shoe_type in list(/obj/item/clothing/shoes/color/black, /obj/item/clothing/shoes/jackboots))
		var/obj/item/clothing/shoes/shoes = allocate(shoe_type)
		wearer.equip_to_slot_or_del(shoes, ITEM_SLOT_FEET)
		var/sheet = shoes.onmob_sheets[ITEM_SLOT_FEET_STRING]
		var/mutable_appearance/clean = shoes.build_worn_icon(default_layer = SHOES_LAYER, default_icon_file = sheet)
		TEST_ASSERT_EQUAL(clean.icon_state, "", "resomi shoes bypassed fitting")
		var/icon/clean_icon = icon(clean.icon, clean.icon_state)
		TEST_ASSERT_NULL(clean_icon.GetPixel(10, 1, dir = SOUTH), "shoes still extend to the human toe position")
		TEST_ASSERT_NOTNULL(clean_icon.GetPixel(15, 3, dir = SOUTH), "fitting flattened the shoe upper into the sole")
		shoes.blood_DNA = list("resomi-shoe-test" = "O+")
		shoes.blood_color = COLOR_RED
		var/list/blood_overlays = shoes.separate_worn_overlays(clean, clean, FALSE, sheet)
		TEST_ASSERT_EQUAL(length(blood_overlays), 1, "bloody shoes need one separate blood layer")
		var/mutable_appearance/blood_overlay = blood_overlays[1]
		TEST_ASSERT_EQUAL(blood_overlay.color, COLOR_RED, "fitting changed the blood color")
		var/icon/blood_icon = icon(blood_overlay.icon, blood_overlay.icon_state)
		for(var/fit_dir in GLOB.cardinal)
			var/blood_pixels = 0
			for(var/y in 1 to 32)
				for(var/x in 1 to 32)
					if(!blood_icon.GetPixel(x, y, dir = fit_dir))
						continue
					blood_pixels++
					TEST_ASSERT_NOTNULL(clean_icon.GetPixel(x, y, dir = fit_dir), "blood floats outside the fitted shoe at [x],[y] facing [fit_dir]")
			TEST_ASSERT(blood_pixels, "fitting erased all shoe blood facing [fit_dir]")
		shoes.blood_DNA = null
		TEST_ASSERT_EQUAL(length(shoes.separate_worn_overlays(clean, clean, FALSE, sheet)), 0, "clean shoes retained their blood layer")
		wearer.drop_item_ground(shoes)

/datum/unit_test/room_test/resomi_mechanics

/datum/unit_test/room_test/resomi_mechanics/Run()
	var/mob/living/carbon/human/resomi = allocate(/mob/living/carbon/human)
	resomi.set_species(/datum/species/resomi)
	TEST_ASSERT(resomi.pass_flags & PASSTABLE, "resomi cannot run over tables")
	TEST_ASSERT(HAS_TRAIT(resomi, TRAIT_SMALL_MOB), "resomi is not a small mob")
	TEST_ASSERT_EQUAL(resomi.mob_size, MOB_SIZE_SMALL, "resomi has a human-sized body")
	passtable_on(resomi, DNA_TRAIT)
	passtable_off(resomi, DNA_TRAIT)
	TEST_ASSERT(resomi.pass_flags & PASSTABLE, "curing dwarfism stops resomi from running over tables")
	TEST_ASSERT(istype(resomi.get_organ(BODY_ZONE_TAIL), /obj/item/organ/external/tail/resomi), "resomi grows a generic tail with no sprite")
	TEST_ASSERT(HAS_TRAIT(resomi, TRAIT_GOOD_HEARING), "resomi ears do not give good hearing")
	var/obj/item/organ/internal/eyes/eyes = resomi.get_int_organ(/obj/item/organ/internal/eyes)
	TEST_ASSERT_EQUAL(eyes.see_in_dark, 5, "resomi night vision is not five tiles")
	TEST_ASSERT_EQUAL(resomi.blood_volume, BLOOD_VOLUME_NORMAL * 0.6, "resomi blood volume is not 40% lower")
	for(var/damage_type in list(BRUTE, BURN, TOX, OXY, CLONE, STAMINA, BRAIN))
		TEST_ASSERT_EQUAL(resomi.get_incoming_damage_modifier(10, damage_type), 1.3, "resomi takes the wrong amount of [damage_type] damage")
	var/obj/item/gun/heavy = allocate(/obj/item/gun/projectile/automatic/l6_saw)
	TEST_ASSERT_NOT(resomi.can_use_guns(heavy), "resomi fired a heavy machine gun")
	var/obj/item/gun/light = allocate(/obj/item/gun/energy/laser)
	TEST_ASSERT(resomi.can_use_guns(light), "resomi cannot fire a laser rifle")

	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/obj/item/holder/held = resomi.get_scooped(carrier)
	TEST_ASSERT(istype(held, /obj/item/holder/humanoid), "resomi was not picked up")
	TEST_ASSERT_EQUAL(held.w_class, WEIGHT_CLASS_SMALL, "a held resomi does not weigh as a small item")
	TEST_ASSERT(resomi.loc == held && held.loc == carrier, "the picked up resomi is not in the carrier's hands")
	carrier.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(carrier), ITEM_SLOT_CLOTH_INNER)
	TEST_ASSERT_NOT(carrier.can_equip(held, ITEM_SLOT_POCKET_LEFT, disable_warning = TRUE), "a held resomi fits into a jumpsuit pocket")
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(bag.can_be_inserted(held, stop_messages = TRUE), "a held resomi does not fit into a backpack")
	carrier.drop_item_ground(held)
	bag.handle_item_insertion(held, prevent_warning = TRUE)
	TEST_ASSERT(resomi.is_hiding_in_storage(), "resomi in a backpack does not count as hiding in it")
	TEST_ASSERT_NOT(resomi.can_use_guns(light), "resomi fired a gun from inside a backpack")
	TEST_ASSERT_NOTNULL(resomi.alerts?[ALERT_PICKUPABLE_CONTAINER], "resomi got no alert to open the backpack it sits in")
	qdel(bag)
	TEST_ASSERT(!QDELETED(resomi) && isturf(resomi.loc), "deleting the backpack deleted the resomi sitting in it")

	resomi.change_body_accessory("Spiky tail")
	resomi.regenerate_icons()
	TEST_ASSERT_NOTNULL(resomi.overlays_standing[TAIL_LAYER], "the resomi tail is drawn under the body when seen from behind")
