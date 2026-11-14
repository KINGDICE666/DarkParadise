/area/shuttle/custom
	name = "Custom Shuttle"
	icon_state = "shuttle"

/datum/controller/subsystem/overmap
	var/custom_shuttle_serial = 0

/proc/custom_shuttle_problem(list/turfs)
	if(!length(turfs))
		return "Разметка пуста."
	if(length(turfs) > OVERMAP_CUSTOM_SHUTTLE_MAX_TILES)
		return "Шаттл не может быть больше [OVERMAP_CUSTOM_SHUTTLE_MAX_TILES] клеток."
	for(var/turf/tile as anything in turfs)
		if(isspaceturf(tile))
			return "В разметке есть открытый космос. Отмечайте только пол и стены корпуса."
		if(!isspacearea(get_area(tile)))
			return "Разметка задевает зону станции или другую зону. Шаттл размечается только в открытом космосе."
		for(var/direction in GLOB.cardinal)
			var/turf/outside = get_step(tile, direction)
			if(outside && !turfs[outside] && !isspaceturf(outside))
				return "Корпус соединён с постройкой за пределами разметки. Шаттл не должен касаться станции."
	var/turf/first = turfs[1]
	var/list/reached = list()
	reached[first] = TRUE
	var/list/queue = list(first)
	while(length(queue))
		var/turf/current = queue[length(queue)]
		queue.len--
		for(var/direction in GLOB.cardinal)
			var/turf/next = get_step(current, direction)
			if(next && turfs[next] && !reached[next])
				reached[next] = TRUE
				queue += next
	if(length(reached) != length(turfs))
		return "Разметка должна быть одним цельным корпусом."
	return null

/datum/controller/subsystem/overmap/proc/commission_custom_shuttle(area/shuttle/custom/hull, list/turfs)
	var/turf/anchor
	var/obj/machinery/door/airlock/external/docking/collar
	for(var/turf/tile as anything in turfs)
		var/obj/machinery/door/airlock/external/docking/door = locate() in tile
		if(door && !door.overmap_is_support)
			collar = door
			anchor = tile
			break
	if(!anchor)
		var/center_x = 0
		var/center_y = 0
		for(var/turf/tile as anything in turfs)
			center_x += tile.x / length(turfs)
			center_y += tile.y / length(turfs)
		for(var/turf/tile as anything in turfs)
			if(!anchor || abs(tile.x - center_x) + abs(tile.y - center_y) < abs(anchor.x - center_x) + abs(anchor.y - center_y))
				anchor = tile
	custom_shuttle_serial++
	hull.has_gravity = STANDARD_GRAVITY
	var/obj/docking_port/mobile/port = new /obj/docking_port/mobile{timid = TRUE}(anchor)
	port.name = hull.name
	port.id = "custom_shuttle_[custom_shuttle_serial]"
	port.areaInstance = hull
	port.shuttle_areas = list()
	port.shuttle_areas[hull] = TRUE
	if(collar)
		port.overmap_collar = collar
		port.setDir(REVERSE_DIR(collar.dir))
	port.overmap_sync_bounds(TRUE)
	port.timid = FALSE
	port.register()
	var/obj/docking_port/stationary/pad = new(anchor)
	pad.name = "[hull.name]: стоянка"
	pad.id = "[port.id]_home"
	pad.setDir(port.dir)
	pad.width = port.width
	pad.height = port.height
	pad.dwidth = port.dwidth
	pad.dheight = port.dheight
	pad.register()
	area_shuttle_cache_ready = FALSE
	var/obj/overmap/entity/vessel = get_or_register_shuttle(port)
	if(vessel)
		relink_hull_hardware(turfs)
	return vessel

/datum/controller/subsystem/overmap/proc/relink_hull_hardware(list/turfs)
	for(var/turf/tile as anything in turfs)
		for(var/obj/machinery/machine in tile)
			if(istype(machine, /obj/machinery/ship_engine))
				var/obj/machinery/ship_engine/engine = machine
				engine.link_vessel()
			else if(istype(machine, /obj/machinery/computer/helm))
				var/obj/machinery/computer/helm/helm = machine
				helm.link_vessel()
			else if(istype(machine, /obj/machinery/computer/engines))
				var/obj/machinery/computer/engines/engine_console = machine
				engine_console.link_vessel()
			else if(istype(machine, /obj/machinery/computer/sensors))
				var/obj/machinery/computer/sensors/sensor = machine
				sensor.link_vessel()
			else if(istype(machine, /obj/machinery/sensor_array))
				var/obj/machinery/sensor_array/array = machine
				array.link_vessel()
			else if(istype(machine, /obj/machinery/computer/navmap))
				var/obj/machinery/computer/navmap/monitor = machine
				monitor.link_vessel()
			else if(istype(machine, /obj/machinery/transponder))
				var/obj/machinery/transponder/transponder = machine
				transponder.link_vessel()
			else if(istype(machine, /obj/machinery/overmap_intercom))
				var/obj/machinery/overmap_intercom/panel = machine
				panel.link_vessel()
