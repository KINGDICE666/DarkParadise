/obj/machinery/computer/sensors/proc/resolve_scan_target()
	if(selected_uid)
		var/datum/found = locateUID(selected_uid)
		if(istype(found, /obj/overmap) && vessel?.can_short_scan(found))
			return found

/obj/machinery/computer/sensors/proc/sync_peel_loop()
	if(!peel_loop)
		return
	if(vessel?.long_sensors_on && !(stat & (NOPOWER|BROKEN)))
		if(!peel_loop.timer_id)
			peel_loop.start(src)
	else
		peel_loop.stop()

/obj/machinery/computer/sensors/attack_hand(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return
	if(..())
		return TRUE
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/sensors/attackby(obj/item/item, mob/living/user, params)
	if(can_dump && istype(item, /obj/item/paper) && !istype(item, /obj/item/paper_bundle))
		add_fingerprint(user)
		if(insert_dump_paper(item, user))
			return ATTACK_CHAIN_BLOCKED_ALL
		return ATTACK_CHAIN_PROCEED
	return ..()

/obj/machinery/computer/sensors/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/computer/sensors/ui_interact(mob/user, datum/tgui/ui = null)
	if(!user.client)
		return
	user.set_machine(src)
	link_vessel()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OvermapSensors", name)
		ui.open()
	update_scan_info()

/obj/machinery/computer/sensors/ui_close(mob/user)
	. = ..()
	if(user.machine == src)
		user.unset_machine()

/obj/machinery/computer/sensors/proc/play_sensor_alert(kind)
	if(!kind || (stat & (NOPOWER|BROKEN)))
		return
	switch(kind)
		if("iff_lost")
			kind = "iff"
		if("undock", "dock_fail", "recall")
			kind = "dock"
	if(!alert_enabled || !alert_enabled[kind])
		return
	var/soundfile = OVERMAP_SENSOR_ALERT_SOUND
	switch(kind)
		if("distress")
			soundfile = OVERMAP_SENSOR_DISTRESS_SOUND
		if("appear")
			soundfile = OVERMAP_SENSOR_NEWCONTACT_SOUND
		if("disappear")
			soundfile = OVERMAP_SENSOR_LOST_SOUND
	playsound(src, soundfile, 30, FALSE)

/obj/machinery/computer/sensors/ui_data(mob/user)
	var/list/data = list()
	var/datum/component/overmap_sensors/pack = vessel?.sensor_pack
	data["linked"] = !!vessel
	data["has_long"] = vessel?.has_working_sensor(OVERMAP_SENSOR_KIND_LONG)
	data["has_short"] = vessel?.has_working_sensor(OVERMAP_SENSOR_KIND_SHORT)
	data["passive_on"] = !!pack?.passive_on()
	data["active_mode"] = pack?.active_on() ? (isnull(vessel.sensor_sector_bearing) ? "circle" : "sector") : "off"
	data["sector_bearing"] = vessel?.sensor_sector_bearing
	data["long_view"] = OVERMAP_SENSOR_LONG_VIEW
	data["short_view"] = OVERMAP_SENSOR_SHORT_VIEW
	data["sweep_period"] = OVERMAP_SENSOR_PEEL_INTERVAL / (1 SECONDS)
	data["can_run"] = can_run()
	data["tracks"] = can_run() ? pack?.build_tracks_data() || list() : list()
	data["clutter"] = can_run() ? pack?.build_clutter_data() || list() : list()
	data["emission"] = pack?.emission_report()
	data["locked"] = pack?.locked_uid
	data["haywire"] = !!pack?.passive_haywire()
	data["scanning"] = scanning
	data["scan_error"] = scan_error
	data["scan"] = scan_info
	data["scan_done"] = scan_finished
	data["scan_target"] = scanning_target?.UID()
	data["scan_progress"] = 0
	if(scanning)
		data["scan_progress"] = scan_finished ? 1 : clamp((world.time - scan_started_at) / OVERMAP_SENSOR_SCAN_TIME, 0, 1)
		var/obj/overmap/entity/subject = scan_subject(scanning_target)
		if(istype(subject) && subject.shuttle)
			if(!length(subject.radar_shape?["tiles"]))
				subject.map_hull()
			data["silhouette"] = subject.radar_shape?["tiles"]
	data["can_print"] = can_print
	data["can_dump"] = can_dump
	data["dump_loaded"] = !!dump_paper
	data["dump_name"] = dump_paper?.name
	data["dump_has_data"] = !!length(dump_paper?.overmap_scan_dump)
	data["dump_count"] = length(dump_paper?.overmap_scan_dump)
	data["known_count"] = length(pack?.short_identified)
	data["selected"] = selected_uid
	data["map_jammed"] = !!vessel?.is_overmap_jammed()
	data["journal"] = vessel?.sensor_journal || list()
	var/list/alerts = list()
	alerts += list(list("id" = "appear", "label" = "Контакт", "on" = !!alert_enabled["appear"]))
	alerts += list(list("id" = "disappear", "label" = "Пропажа", "on" = !!alert_enabled["disappear"]))
	alerts += list(list("id" = "scan", "label" = "Скан", "on" = !!alert_enabled["scan"]))
	alerts += list(list("id" = "scanned_by", "label" = "Нас сканируют", "on" = !!alert_enabled["scanned_by"]))
	alerts += list(list("id" = "distress", "label" = "Авария", "on" = !!alert_enabled["distress"]))
	alerts += list(list("id" = "iff", "label" = "Транспондер", "on" = !!alert_enabled["iff"]))
	alerts += list(list("id" = "dock", "label" = "Стыковка", "on" = !!alert_enabled["dock"]))
	data["alerts"] = alerts
	if(vessel)
		var/turf/here = vessel.get_overmap_turf()
		data["vessel_name"] = vessel.get_overmap_display_name()
		data["x"] = vessel.sector && here ? vessel.sector.coord_x(here) : here?.x
		data["y"] = vessel.sector && here ? vessel.sector.coord_y(here) : here?.y
		data["sector_name"] = vessel.sector?.name
		data["sector_id"] = vessel.sector?.id
		data["heading"] = vessel.get_heading_angle()
		data["speed"] = round(OVERMAP_DISPLAY_SPEED(vessel.get_speed()), 0.01)
		data["galaxy"] = SSovermap.galaxy_map(vessel)
	return data

/obj/machinery/computer/sensors/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(stat & (NOPOWER|BROKEN))
		return TRUE
	var/datum/component/overmap_sensors/pack = vessel?.sensor_pack
	switch(action)
		if("relink")
			link_vessel()
			. = TRUE
		if("toggle_alert")
			var/alert_id = params["id"]
			if(alert_id in alert_enabled)
				alert_enabled[alert_id] = !alert_enabled[alert_id]
			. = TRUE
		if("toggle_passive")
			if(!vessel?.has_working_sensor(OVERMAP_SENSOR_KIND_SHORT))
				return TRUE
			vessel.set_short_sensors(!vessel.short_sensors_on)
			if(!vessel.short_sensors_on)
				scanning = FALSE
				scanning_target = null
				scan_finished = FALSE
			update_scan_info()
			. = TRUE
		if("set_active")
			if(!vessel?.has_working_sensor(OVERMAP_SENSOR_KIND_LONG))
				return TRUE
			var/mode = params["mode"]
			if(mode == "off")
				vessel.set_long_sensors(FALSE)
				pack?.release_lock()
				return TRUE
			if(mode == "sector")
				vessel.sensor_sector_bearing = isnull(vessel.sensor_sector_bearing) ? vessel.get_heading_angle() : vessel.sensor_sector_bearing
			else
				vessel.sensor_sector_bearing = null
			if(!vessel.long_sensors_on)
				vessel.set_long_sensors(TRUE)
			. = TRUE
		if("aim")
			var/bearing = text2num(params["bearing"])
			if(isnum(bearing) && !isnull(vessel?.sensor_sector_bearing))
				vessel.sensor_sector_bearing = round(bearing) % 360
			. = TRUE
		if("lock")
			if(!pack?.try_lock(params["ref"]))
				to_chat(usr, span_warning("Цель вне луча активного радара."))
			. = TRUE
		if("unlock")
			pack?.release_lock()
			. = TRUE
		if("select")
			selected_uid = params["ref"]
			. = TRUE
		if("scan")
			if(params["ref"])
				selected_uid = params["ref"]
			var/obj/overmap/target = resolve_scan_target()
			if(!start_short_scan(target))
				to_chat(usr, span_warning("Нет цели в зоне детального сканирования."))
			. = TRUE
		if("print_scan")
			if(!print_scan_report())
				to_chat(usr, span_warning("Нет готового отчёта."))
			. = TRUE
		if("dump_write")
			if(!write_sensor_dump(usr))
				to_chat(usr, span_warning("Сначала вставьте листок бумаги в консоль."))
			. = TRUE
		if("dump_load")
			if(!load_sensor_dump(usr))
				to_chat(usr, span_warning("На листке нет дампа сенсоров."))
			. = TRUE
		if("dump_eject")
			eject_dump_paper(usr)
			. = TRUE
		if("close_scan")
			scanning = FALSE
			scanning_target = null
			scan_error = null
			scan_info = null
			scan_finished = FALSE
			scan_started_at = 0
			update_scan_info(TRUE)
			. = TRUE

/obj/machinery/computer/sensors/process()
	sync_peel_loop()
	if(..())
		if(scanning && !scan_finished && (world.time >= scan_started_at + OVERMAP_SENSOR_SCAN_TIME))
			complete_short_scan()
		if(vessel && !scanning)
			var/turf/here = vessel.get_overmap_turf()
			if(here != last_map_turf)
				update_scan_info()
		SStgui.update_uis(src)

/obj/machinery/computer/sensors/power_change(forced = FALSE)
	. = ..()
	sync_peel_loop()
	update_scan_info()

/obj/machinery/computer/sensors/long_range

/obj/machinery/computer/sensors/short_range
	view_mode = OVERMAP_SENSOR_KIND_SHORT

/obj/machinery/computer/sensors/short_range/pod
	name = "pod sensors"
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	density = FALSE
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	can_print = FALSE

/obj/machinery/computer/sensors/short_range/pod/Initialize(mapload)
	. = ..()
	stat &= ~NOPOWER

/obj/machinery/computer/sensors/short_range/pod/powered(chan)
	return TRUE

/obj/machinery/computer/sensors/short_range/pod/link_vessel()
	var/obj/spacepod/craft = loc
	if(!isspacepod(craft) || !craft.overmap_vessel)
		return
	if(vessel && vessel != craft.overmap_vessel)
		vessel.unregister_sensor(src)
	vessel = craft.overmap_vessel
	vessel.register_sensor(src)
	view_mode = OVERMAP_SENSOR_KIND_SHORT
	update_scan_info()

/obj/machinery/computer/sensors/short_range/pod/ui_status(mob/user, datum/ui_state/state)
	if(!overmap_pod_user_ok(user, loc))
		return UI_CLOSE
	return UI_INTERACTIVE

/obj/machinery/computer/sensors/short_range/pod/ui_interact(mob/user, datum/tgui/ui = null)
	if(!vessel)
		link_vessel()
	return ..()
