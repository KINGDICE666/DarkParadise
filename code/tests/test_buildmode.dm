/datum/unit_test/buildmode_catalog
	priority = TEST_PRE

/datum/unit_test/buildmode_catalog/Run()
	TEST_ASSERT(!length(GLOB.buildmode_previews), "Buildmode previews were loaded before opening the catalog.")
	TEST_ASSERT(!length(GLOB.buildmode_items), "Buildmode catalog was populated during startup.")
	var/list/categories = get_buildmode_categories()
	TEST_ASSERT(length(categories), "Buildmode catalog is empty.")
	TEST_ASSERT(categories == get_buildmode_categories(), "Buildmode catalog is rebuilt on every request.")
	TEST_ASSERT(!length(GLOB.buildmode_previews), "Reading the catalog must not generate previews.")
	for(var/list/category as anything in categories)
		TEST_ASSERT(length(category["items"]), "Empty buildmode category: [category["name"]].")
		for(var/list/item as anything in category["items"])
			var/path_text = item["path"]
			var/atom/item_path = text2path(path_text)
			TEST_ASSERT(ispath(item_path, /turf) || ispath(item_path, /obj) || ispath(item_path, /mob), "Invalid buildmode type: [path_text].")
			TEST_ASSERT(!(item_path in get_abstract_types()), "Abstract type in buildmode catalog: [path_text].")
			TEST_ASSERT(!ispath(item_path, /mob/dead), "Dead mob in buildmode catalog: [path_text].")
			TEST_ASSERT(GLOB.buildmode_items[path_text] == item, "Catalog entry differs between categories: [path_text].")
	TEST_ASSERT(GLOB.buildmode_items["[/obj/machinery/portable_atmospherics/canister/air]"], "Air canister is missing from buildmode catalog.")

/datum/unit_test/buildmode_previews

/datum/unit_test/buildmode_previews/Run()
	var/list/paths = list("[/obj/item/pen]", "[/obj/machinery/portable_atmospherics/canister]", "[/obj/structure/chair/sofa/bench]", "[/obj/item/encryptionkey]")
	var/list/previews = get_buildmode_previews(paths)
	TEST_ASSERT_EQUAL(length(previews), length(paths), "Preview generation must return only requested types.")
	for(var/path_text in paths)
		TEST_ASSERT(length(previews[path_text]), "Missing buildmode preview for [path_text].")
		TEST_ASSERT_EQUAL(previews[path_text], GLOB.buildmode_previews[path_text], "Generated previews must be cached.")
	var/list/repeated = get_buildmode_previews(paths)
	TEST_ASSERT_EQUAL(json_encode(previews), json_encode(repeated), "Repeated preview requests must reuse the cache.")
	var/list/catalog_paths = list()
	for(var/path_text in GLOB.buildmode_items)
		catalog_paths += path_text
		if(length(catalog_paths) >= 480)
			break
	for(var/page_start in 1 to length(catalog_paths) step 96)
		get_buildmode_previews(catalog_paths.Copy(page_start, min(page_start + 96, length(catalog_paths) + 1)))
		TEST_ASSERT(length(GLOB.buildmode_previews) <= 384, "Paging must not grow the preview cache without a limit.")
	var/evicted_path = paths[1]
	TEST_ASSERT_NULL(GLOB.buildmode_previews[evicted_path], "Old previews must be evicted from the cache.")
	repeated = get_buildmode_previews(list(evicted_path))
	TEST_ASSERT_EQUAL(repeated[evicted_path], previews[evicted_path], "Evicted previews must regenerate identically.")
	GLOB.buildmode_previews.Cut()

/datum/unit_test/buildmode_greyscale_state

/datum/unit_test/buildmode_greyscale_state/Run()
	TEST_ASSERT_EQUAL(get_buildmode_greyscale_state(/obj/machinery/portable_atmospherics/canister), "", "An empty greyscale state must remain valid.")
	TEST_ASSERT_EQUAL(get_buildmode_greyscale_state(/obj/structure/chair/sofa/bench), "bench_middle", "Post-initialization greyscale state is incorrect.")
	TEST_ASSERT_NULL(get_buildmode_greyscale_state(/obj/item/encryptionkey), "Invalid greyscale colors must use the fallback icon.")
	TEST_ASSERT_NULL(get_buildmode_greyscale_state(/obj/structure/flora/tree/new_year), "A non-greyscale type must use the fallback icon.")

/datum/buildmode_mode/builder/test
	var/view_changes = 0

/datum/buildmode_mode/builder/test/exit_mode(datum/click_intercept/buildmode/BM)
	set_preview_eye(null)

/datum/buildmode_mode/builder/test/on_view_changed()
	view_changes++

/obj/item/buildmode_test
	name = "buildmode test item"
	abstract_type = /obj/item/buildmode_test

/obj/item/buildmode_test/Initialize(mapload)
	. = ..()
	pixel_x = 11
	pixel_y = -7

/datum/unit_test/room_test/buildmode_placement

/datum/unit_test/room_test/buildmode_placement/Run()
	var/datum/buildmode_mode/builder/build_mode = allocate(/datum/buildmode_mode/builder/test)
	build_mode.selected_item = /obj/structure/flora/tree/new_year
	var/atom/placed = build_mode.place_object(run_loc_floor_bottom_left, null, SOUTH)
	allocated += placed
	TEST_ASSERT_EQUAL(placed.pixel_x, /obj/structure/flora/tree/new_year::pixel_x, "Placement must retain the tree's native horizontal offset.")
	TEST_ASSERT_EQUAL(placed.pixel_y, /obj/structure/flora/tree/new_year::pixel_y, "Placement must retain the tree's native vertical offset.")
	build_mode.selected_item = /obj/item/buildmode_test
	build_mode.pixel_x_offset = 5
	build_mode.pixel_y_offset = -3
	placed = build_mode.place_object(run_loc_floor_bottom_left, null, NORTH)
	allocated += placed
	TEST_ASSERT_EQUAL(placed.pixel_x, 16, "Placement must add the horizontal offset to the value set in Initialize().")
	TEST_ASSERT_EQUAL(placed.pixel_y, -10, "Placement must add the vertical offset to the value set in Initialize().")
	TEST_ASSERT_EQUAL(placed.dir, NORTH, "Placement must apply the requested direction.")

/datum/unit_test/room_test/buildmode_tracker

/datum/unit_test/room_test/buildmode_tracker/Run()
	var/datum/buildmode_mode/builder/test/build_mode = allocate(/datum/buildmode_mode/builder/test)
	var/atom/movable/screen/buildmode_pixel_tracker/tracker = allocate(/atom/movable/screen/buildmode_pixel_tracker, null, build_mode)
	TEST_ASSERT_EQUAL(tracker.owner, build_mode, "Tracker must keep its buildmode owner.")
	TEST_ASSERT_NULL(tracker.vars["hud"], "Tracker must not register the buildmode as a HUD owner.")
	var/obj/item/pen/first_eye = allocate(/obj/item/pen)
	var/obj/item/pen/second_eye = allocate(/obj/item/pen)
	var/turf/next_turf = get_step(run_loc_floor_bottom_left, EAST)
	build_mode.set_preview_eye(first_eye)
	var/view_changes = build_mode.view_changes
	first_eye.forceMove(next_turf)
	TEST_ASSERT_EQUAL(build_mode.view_changes, view_changes + 1, "Moving the camera must refresh the preview without mouse input.")
	build_mode.on_eye_changed(null, first_eye, second_eye)
	view_changes = build_mode.view_changes
	first_eye.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(build_mode.view_changes, view_changes, "Changing the camera must detach the old movement listener.")
	second_eye.forceMove(next_turf)
	TEST_ASSERT_EQUAL(build_mode.view_changes, view_changes + 1, "The replacement camera must refresh the preview.")
	build_mode.set_preview_eye(null)
	view_changes = build_mode.view_changes
	second_eye.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(build_mode.view_changes, view_changes, "Clearing the camera must detach the movement listener.")
	qdel(tracker)
	TEST_ASSERT_NULL(tracker.owner, "Deleted tracker must release its buildmode owner.")

/datum/unit_test/room_test/buildmode_pixel_position

/datum/unit_test/room_test/buildmode_pixel_position/Run()
	var/turf/eye_turf = run_loc_floor_bottom_left
	var/list/position = get_buildmode_pixel_position("8:16,8:16", eye_turf, "15x15")
	TEST_ASSERT_EQUAL(position[1], eye_turf, "Center of viewport must select the camera turf.")
	TEST_ASSERT_EQUAL(position[2], 0, "Center of tile has no horizontal offset.")
	TEST_ASSERT_EQUAL(position[3], 0, "Center of tile has no vertical offset.")
	position = get_buildmode_pixel_position("8:1,8:32", eye_turf, "15x15")
	TEST_ASSERT_EQUAL(position[1], eye_turf, "Tile edge must not select a neighboring tile.")
	TEST_ASSERT_EQUAL(position[2], 1 - ICON_SIZE_X / 2, "Leftmost pixel has an incorrect offset.")
	TEST_ASSERT_EQUAL(position[3], ICON_SIZE_Y / 2, "Topmost pixel has an incorrect offset.")
	position = get_buildmode_pixel_position("8:16,8:16", eye_turf, "15x15", camera_pixel_x = ICON_SIZE_X, camera_pixel_y = ICON_SIZE_Y)
	TEST_ASSERT_EQUAL(position[1], locate(eye_turf.x + 1, eye_turf.y + 1, eye_turf.z), "Camera panning must move the target turf.")
	TEST_ASSERT_EQUAL(position[2], 0, "Camera panning must preserve the horizontal offset.")
	TEST_ASSERT_EQUAL(position[3], 0, "Camera panning must preserve the vertical offset.")
	position = get_buildmode_pixel_position("12:16,10:16", eye_turf, "23x19")
	TEST_ASSERT_EQUAL(position[1], eye_turf, "Resized viewport must preserve the camera center.")
