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
		var/turf/center = turfs_bounding_center(turfs)
		for(var/turf/tile as anything in turfs)
			if(!anchor || get_dist(tile, center) < get_dist(anchor, center))
				anchor = tile
	custom_shuttle_serial++
	hull.has_gravity = STANDARD_GRAVITY
	var/list/areas = list()
	areas[hull] = TRUE
	var/obj/docking_port/mobile/port = make_area_mobile_port(anchor, areas, collar, hull.name)
	register_runtime_mobile_port(port, "custom_shuttle_[custom_shuttle_serial]")
	var/obj/docking_port/stationary/pad = new(anchor)
	pad.name = "[hull.name]: стоянка"
	pad.id = "[port.id]_home"
	pad.setDir(port.dir)
	pad.width = port.width
	pad.height = port.height
	pad.dwidth = port.dwidth
	pad.dheight = port.dheight
	pad.register()
	var/obj/overmap/entity/vessel = get_or_register_shuttle(port)
	if(vessel)
		relink_hardware(turfs)
	return vessel
