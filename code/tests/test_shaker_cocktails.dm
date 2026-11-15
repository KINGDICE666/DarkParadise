/datum/unit_test/shaker_cocktails

/datum/unit_test/shaker_cocktails/Run()
	var/obj/item/reagent_containers/cup/glass/drinkingglass/glass = allocate(/obj/item/reagent_containers/cup/glass/drinkingglass)
	glass.reagents.add_reagent("vodka", 10)
	glass.reagents.add_reagent("orangejuice", 5)
	TEST_ASSERT(!glass.reagents.has_reagent("screwdrivercocktail"), "Cocktail mixed in a glass without shaking")

	var/obj/item/reagent_containers/cup/glass/shaker/shaker = allocate(/obj/item/reagent_containers/cup/glass/shaker)
	glass.reagents.trans_to(shaker, glass.reagents.total_volume)
	TEST_ASSERT(!shaker.reagents.has_reagent("screwdrivercocktail"), "Cocktail mixed in a shaker before shaking")

	shaker.reagents.flags |= REAGENT_SHAKING
	shaker.reagents.handle_reactions()
	shaker.reagents.flags &= ~REAGENT_SHAKING
	TEST_ASSERT_EQUAL(shaker.reagents.get_reagent_amount("screwdrivercocktail"), 15, "Shaking did not mix the cocktail")

	var/obj/item/reagent_containers/cup/glass/drinkingglass/coffee_cup = allocate(/obj/item/reagent_containers/cup/glass/drinkingglass)
	coffee_cup.reagents.add_reagent("coffee", 5)
	coffee_cup.reagents.add_reagent("milk", 5)
	TEST_ASSERT(coffee_cup.reagents.has_reagent("cafe_latte"), "Non-cocktail drink requires shaking")
