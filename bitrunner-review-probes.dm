/datum/unit_test/room_test/bitrunning_review_probe/Run()
	var/obj/machinery/quantum_server/server = allocate(/obj/machinery/quantum_server)
	TEST_ASSERT(server.cold_boot_map(LAZY_TEMPLATE_KEY_BITRUNNING_BEACH_BAR), "Beach Bar failed to load")
	sleep(3 SECONDS)
	var/carpet_count = 0
	var/missing_carpet_states = 0
	var/loose_items = 0
	for(var/turf/tile as anything in server.domain_reservation.reserved_turfs)
		if(istype(tile, /turf/simulated/floor/carpet))
			carpet_count++
			if(!(tile.icon_state in icon_states(tile.icon)))
				missing_carpet_states++
				log_world("REVIEW carpet missing: [tile.type] state=[tile.icon_state] dir=[tile.dir] smooth=[tile.smooth]")
		for(var/obj/structure/closet/closet in tile)
			if(closet.opened)
				continue
			var/count = 0
			for(var/obj/item/item in tile)
				if(!item.anchored && !item.density)
					count++
			if(count)
				loose_items += count
				log_world("REVIEW closet: [closet.type] contents=[length(closet.contents)] loose=[count] offset=[tile.x-server.domain_reservation.bottom_left_turfs[1].x+1],[tile.y-server.domain_reservation.bottom_left_turfs[1].y+1]")
	log_world("REVIEW Beach Bar carpets=[carpet_count] missing_states=[missing_carpet_states] loose_items=[loose_items]")
	server.scrub_vdom()
