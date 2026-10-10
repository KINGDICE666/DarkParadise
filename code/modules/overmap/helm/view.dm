/proc/overmap_open_helm(mob/user, control)
	for(var/datum/tgui/open_ui as anything in user?.tgui_open_uis)
		var/obj/machinery/computer/helm/helm = open_ui.src_object
		if(istype(helm) && open_ui.status == UI_INTERACTIVE && findtext(control, helm.cam_screen.assigned_map))
			return helm

/obj/machinery/computer/helm/proc/register_map_overlays(mob/user)
	if(!user?.client)
		return
	if(nav_blip)
		nav_blip.assigned_map = cam_screen.assigned_map
		user.client.register_map_obj(nav_blip)
	for(var/atom/movable/screen/overmap_sensor_blip/blip as anything in sensor_blips)
		blip.assigned_map = cam_screen.assigned_map
		user.client.register_map_obj(blip)
	for(var/atom/movable/screen/overmap_sensor_radar/radar as anything in radar_blips)
		radar.assigned_map = cam_screen.assigned_map
		user.client.register_map_obj(radar)

/obj/machinery/computer/helm/proc/on_vessel_loc_changed()
	if(vessel?.get_overmap_turf() != last_map_turf)
		update_map_view()

/obj/machinery/computer/helm/proc/update_sensor_ghosts()
	sensor_blips = overmap_paint_sensor_ghosts(vessel, sensor_blips, cam_screen?.assigned_map, map_view_min_x, map_view_min_y, map_view_range(), open_uis)
	radar_blips = overmap_paint_sensor_radars(vessel, radar_blips, cam_screen?.assigned_map, map_view_min_x, map_view_min_y, map_view_range(), open_uis)

/obj/machinery/computer/helm/proc/update_nav_marker()
	if(!nav_blip)
		return
	var/turf/mark
	if(vessel?.flight?.autopilot_x && vessel.flight.autopilot_y && vessel.sector)
		mark = vessel.sector.get_turf_at(vessel.flight.autopilot_x, vessel.flight.autopilot_y)
	var/shown_size = map_camera?.last_size_x
	var/turf/here = vessel?.get_overmap_turf()
	var/in_view = mark && here && cam_screen && map_view_min_x && map_view_min_y && mark.z == here.z
	if(in_view)
		in_view = ISINRANGE(mark.x - map_view_min_x, 0, shown_size - 1) && ISINRANGE(mark.y - map_view_min_y, 0, shown_size - 1)
	if(!in_view)
		nav_blip.alpha = 0
		nav_blip.screen_loc = null
		return
	nav_blip.assigned_map = cam_screen.assigned_map
	nav_blip.alpha = 255
	nav_blip.set_position(mark.x - map_view_min_x + 1, mark.y - map_view_min_y + 1)
	for(var/datum/tgui/open_ui as anything in open_uis)
		if(open_ui.user?.client)
			open_ui.user.client.register_map_obj(nav_blip)

/obj/machinery/computer/helm/proc/add_waypoint(waypoint_name, waypoint_x, waypoint_y)
	if(!waypoint_name)
		waypoint_name = "Клетка [waypoint_x]-[waypoint_y]"
	waypoints.Cut()
	waypoints[waypoint_name] = list("x" = waypoint_x, "y" = waypoint_y)
	return waypoint_name

/obj/machinery/computer/helm/proc/mark_atom(mob/user, atom/target)
	if(!vessel?.sector || vessel.is_overmap_jammed() || vessel.is_programmed_locked())
		return FALSE
	var/turf/marked = get_turf(target)
	if(!istype(marked, /turf/simulated/floor/indestructible/overmap))
		return FALSE
	var/mark_x = vessel.sector.coord_x(marked)
	var/mark_y = vessel.sector.coord_y(marked)
	var/waypoint_name = "Клетка [mark_x]-[mark_y]"
	var/obj/overmap/contact = target
	if(istype(contact) && vessel.display_identified(contact))
		waypoint_name = contact.get_overmap_display_name()
	var/saved = add_waypoint(waypoint_name, mark_x, mark_y)
	vessel.set_autopilot(vessel.flight?.autopilot, mark_x, mark_y)
	update_nav_marker()
	SStgui.update_uis(src)
	to_chat(user, span_notice("Точка автопилота обновлена: [saved] ([mark_x]:[mark_y])."))
	return TRUE
