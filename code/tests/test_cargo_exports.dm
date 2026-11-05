/datum/unit_test/cargo_exports

/datum/unit_test/cargo_exports/Run()
	for(var/datum/export/subtype as anything in valid_subtypesof(/datum/export))
		var/datum/export/sell = new subtype
		if(!length(sell.export_types))
			TEST_FAIL("[subtype] has no export types")
		if(!sell.unit_name)
			TEST_FAIL("[subtype] has no unit name")
		qdel(sell)

/datum/unit_test/room_test/cargo_crate_sanity

/datum/unit_test/room_test/cargo_crate_sanity/Run()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_packs/pack = SSshuttle.supply_packs[pack_id]
		if(!pack.cost || !pack.containertype)
			continue
		var/atom/movable/container = allocate(pack.containertype)
		for(var/path in pack.contains)
			new path(container)
		var/datum/export_report/report = export_item_and_contents(container, apply_elastic = FALSE, dry_run = TRUE)
		var/value = counterlist_sum(report.total_value)
		if(value > pack.cost)
			TEST_FAIL("[pack.type] sells for [value], more than its cost of [pack.cost]")
		for(var/atom/movable/content as anything in container.get_all_contents() - container)
			qdel(content)
		qdel(container)

/datum/unit_test/room_test/cargo_material_exports

/datum/unit_test/room_test/cargo_material_exports/Run()
	var/obj/item/stack/sheet/metal/metal = allocate(/obj/item/stack/sheet/metal, null, 10)
	var/datum/export_report/report = export_item_and_contents(metal, apply_elastic = FALSE, dry_run = TRUE)
	var/expected = ROUND_UP(SSstock_market.get_price(MAT_METAL) * 10)
	TEST_ASSERT_EQUAL(counterlist_sum(report.total_value), expected, "10 metal sheets did not sell at market price")

	var/obj/item/stock_block/block = allocate(/obj/item/stock_block, null, MAT_GOLD, 5, 100)
	report = export_item_and_contents(block, apply_elastic = FALSE, dry_run = TRUE)
	TEST_ASSERT_EQUAL(counterlist_sum(report.total_value), 500, "stock block did not sell at its locked price")
