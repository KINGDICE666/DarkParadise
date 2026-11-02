/datum/unit_test/room_test/holomap_cleanup/Run()
	var/obj/machinery/station_map/map = allocate(/obj/machinery/station_map)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/hud/viewer_hud = allocate(/datum/hud, viewer)
	viewer.hud_used = viewer_hud
	var/atom/movable/screen/holomap/map_screen = viewer_hud.holomap
	if(!map.holomap_datum)
		map.setup_holomap()

	map.watching_mob = viewer
	map.moving_mob = viewer
	map.use_power = ACTIVE_POWER_USE
	map.holomap_datum.disabled_overlays += "test"
	map_screen.used_station_map = map
	map_screen.used_base_map = map.holomap_datum.base_map
	var/update_timer_id = addtimer(CALLBACK(map, TYPE_PROC_REF(/obj/machinery/station_map, redraw_map), viewer), 1 MINUTES, TIMER_LOOP | TIMER_STOPPABLE)
	map.auto_update_timer_id = update_timer_id
	map.close_map()

	TEST_ASSERT_NULL(map.watching_mob, "Closing a map kept its disconnected viewer")
	TEST_ASSERT_NULL(map.moving_mob, "Closing a map kept its tracked mob")
	TEST_ASSERT_NULL(map_screen.used_station_map, "Closing a map kept its HUD owner")
	TEST_ASSERT_NULL(map_screen.used_base_map, "Closing a map kept its HUD image")
	TEST_ASSERT_NULL(map.auto_update_timer_id, "Closing a map kept its update timer")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[update_timer_id], "Closing a map did not cancel its update timer")
	TEST_ASSERT_EQUAL(map.use_power, IDLE_POWER_USE, "Closing a map did not restore idle power use")
	TEST_ASSERT_EQUAL(length(map.holomap_datum.disabled_overlays), 0, "Closing a map did not reset its overlay selection")
	map.close_map()

	update_timer_id = addtimer(CALLBACK(map, TYPE_PROC_REF(/obj/machinery/station_map, redraw_map), viewer), 1 MINUTES, TIMER_LOOP | TIMER_STOPPABLE)
	map.auto_update_timer_id = update_timer_id
	map.close_map()
	TEST_ASSERT_NULL(map.auto_update_timer_id, "Closing a map without a viewer kept its update timer")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[update_timer_id], "Closing a map without a viewer left an update callback")

	map.watching_mob = viewer
	map_screen.used_station_map = map
	map_screen.used_base_map = map.holomap_datum.base_map
	var/close_timer_id = addtimer(CALLBACK(map, TYPE_PROC_REF(/obj/machinery/station_map, finish_close_map)), 1 MINUTES, TIMER_STOPPABLE)
	map.close_map_timer_id = close_timer_id
	map.close_map(animate_close = FALSE)

	TEST_ASSERT_NULL(map.watching_mob, "Immediate closure did not finish a pending fade")
	TEST_ASSERT_NULL(map_screen.used_station_map, "Immediate closure kept its HUD owner")
	TEST_ASSERT_NULL(map.close_map_timer_id, "Immediate closure kept its close timer")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[close_timer_id], "Immediate closure left a callback that could close a reopened map")

	map.watching_mob = viewer
	map_screen.used_station_map = map
	map_screen.used_base_map = map.holomap_datum.base_map
	close_timer_id = addtimer(CALLBACK(map, TYPE_PROC_REF(/obj/machinery/station_map, finish_close_map)), 1 MINUTES, TIMER_STOPPABLE)
	map.close_map_timer_id = close_timer_id
	qdel(map)

	TEST_ASSERT_NULL(map_screen.used_station_map, "Deleting a map during a fade kept its HUD owner")
	TEST_ASSERT_NULL(map_screen.used_base_map, "Deleting a map during a fade kept its HUD image")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[close_timer_id], "Deleting a map during a fade kept its close timer")
