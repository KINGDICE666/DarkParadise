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
		if(!pack.cost || !pack.containertype || pack.test_ignored)
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

/datum/unit_test/room_test/cargo_vendor_sanity

/datum/unit_test/room_test/cargo_vendor_sanity/Run()
	var/static/list/centcom_vendors = typecacheof(list(
		/obj/machinery/vending/nta,
		/obj/machinery/vending/ntc,
		/obj/machinery/vending/ntc_resources,
		/obj/machinery/vending/ntcrates,
		/obj/machinery/vending/mech/ntc,
	))
	for(var/vendor_type in valid_subtypesof(/obj/machinery/vending))
		if(is_path_in_typecache(vendor_type, centcom_vendors))
			continue
		var/obj/machinery/vending/vendor = allocate(vendor_type)
		if(vendor.all_products_free)
			continue
		for(var/datum/data/vending_product/record as anything in vendor.product_records + vendor.premium_records)
			if(!record.price || !record.product_path)
				continue
			var/atom/movable/product = allocate(record.product_path)
			var/datum/export_report/report = export_item_and_contents(product, apply_elastic = FALSE, dry_run = TRUE)
			var/value = counterlist_sum(report.total_value)
			if(value > record.price)
				TEST_FAIL("[record.product_path] sold by [vendor_type] for [record.price] exports for [value]")
			for(var/atom/movable/content as anything in product.get_all_contents())
				qdel(content)

/datum/unit_test/room_test/civilian_bounty_pad_link

/datum/unit_test/room_test/civilian_bounty_pad_link/Run()
	var/obj/machinery/civilian_bounty_pad/pad = allocate(/obj/machinery/civilian_bounty_pad, run_loc_floor_bottom_left)
	var/obj/machinery/computer/civilian_bounty/terminal = allocate(/obj/machinery/computer/civilian_bounty, locate(pad.x + 1, pad.y, pad.z))
	TEST_ASSERT_EQUAL(terminal.pad_ref?.resolve(), pad, "civilian bounty terminal did not link to an adjacent pad")

/datum/unit_test/stock_market_events

/datum/unit_test/stock_market_events/Run()
	for(var/material_id in SSstock_market.materials_prices)
		for(var/i in 1 to 20)
			SSstock_market.handle_trends_and_price(material_id)
		var/price = SSstock_market.get_price(material_id)
		if(price < SSstock_market.price_minimum(material_id) || price > SSstock_market.price_maximum(material_id))
			TEST_FAIL("[material_id] price [price] left its bounds")
	for(var/datum/stock_market_event/leftover as anything in SSstock_market.active_events)
		leftover.end_event()
	for(var/event_type in subtypesof(/datum/stock_market_event))
		var/datum/stock_market_event/event = new event_type
		event.start_event(MAT_GOLD)
		SSstock_market.active_events += event
		for(var/i in 1 to 5)
			if(QDELETED(event))
				break
			event.handle()
		TEST_ASSERT(QDELETED(event), "[event_type] did not end")
	TEST_ASSERT(SSstock_market.get_sheet_type(MAT_GOLD), "gold has no sheet type on the market")
	SSstock_market.pending_news.Cut()
