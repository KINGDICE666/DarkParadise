/datum/unit_test/pipe_dispenser_recipes

/datum/unit_test/pipe_dispenser_recipes/Run()
	var/list/expected_categories = list(
		/obj/machinery/pipedispenser = "Insulated",
		/obj/machinery/pipedispenser/disposal = "Transit Tubes",
	)
	for(var/dispenser_type in expected_categories)
		var/obj/machinery/pipedispenser/dispenser = allocate(dispenser_type)
		var/list/category_names = list()
		for(var/list/category in dispenser.ui_static_data()["categories"])
			category_names += category["cat_name"]
		TEST_ASSERT(expected_categories[dispenser_type] in category_names, "[dispenser_type] has no [expected_categories[dispenser_type]] category")

		for(var/datum/pipes/pipe as anything in GLOB.construction_pipe_list)
			if(!dispenser.get_recipe_category(pipe))
				continue
			TEST_ASSERT(icon_exists(pipe.pipe_icon_file, pipe.pipe_icon), "[pipe.pipe_name] has no icon state [pipe.pipe_icon] in [pipe.pipe_icon_file]")
			var/atom/movable/dispensed = dispenser.dispense(pipe)
			TEST_ASSERT(!QDELETED(dispensed), "[dispenser_type] failed to dispense [pipe.pipe_name]")
			qdel(dispensed)
