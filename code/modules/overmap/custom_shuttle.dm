/area/shuttle/custom
	name = "Custom Shuttle"
	icon_state = "shuttle"

/datum/controller/subsystem/overmap
	var/custom_shuttle_serial = 0

/proc/custom_shuttle_near(list/turfs)
	for(var/turf/tile as anything in turfs)
		if(istype(tile.loc, /area/shuttle/custom))
			return tile.loc
		for(var/direction in GLOB.cardinal)
			var/turf/outside = get_step(tile, direction)
			if(istype(outside?.loc, /area/shuttle/custom))
				return outside.loc
	return null

/proc/custom_shuttle_problem(list/turfs, area/shuttle/custom/extending)
	if(!length(turfs))
		return "Разметка пуста."
	var/list/hull = turfs.Copy()
	if(extending)
		var/turf/sample = turfs[1]
		extending.cannonize_contained_turfs_by_zlevel(sample.z)
		for(var/turf/tile as anything in extending.get_turfs_by_zlevel(sample.z))
			hull[tile] = TRUE
	if(length(hull) > OVERMAP_CUSTOM_SHUTTLE_MAX_TILES)
		return "Шаттл не может быть больше [OVERMAP_CUSTOM_SHUTTLE_MAX_TILES] клеток."
	for(var/turf/tile as anything in hull)
		if(isspaceturf(tile))
			return "В разметке есть открытый космос. Отмечайте только пол и стены корпуса."
		var/area/place = get_area(tile)
		if(place != extending && !isspacearea(place))
			return "Разметка задевает зону «[place.name]». Шаттл размечается только в открытом космосе."
		for(var/direction in GLOB.cardinal)
			var/turf/outside = get_step(tile, direction)
			if(outside && !hull[outside] && !isspaceturf(outside))
				return "Корпус касается постройки за пределами разметки ([outside.x], [outside.y]). Шаттл не должен соединяться со станцией."
	var/turf/first = hull[1]
	var/list/reached = list()
	reached[first] = TRUE
	var/list/queue = list(first)
	while(length(queue))
		var/turf/current = queue[length(queue)]
		queue.len--
		for(var/direction in GLOB.cardinal)
			var/turf/next = get_step(current, direction)
			if(next && hull[next] && !reached[next])
				reached[next] = TRUE
				queue += next
	if(length(reached) != length(hull))
		return "Разметка должна быть одним цельным корпусом."
	return null

/obj/docking_port/stationary/proc/match_port_bounds(obj/docking_port/mobile/port)
	setDir(port.dir)
	width = port.width
	height = port.height
	dwidth = port.dwidth
	dheight = port.dheight

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
	pad.match_port_bounds(port)
	pad.register()
	var/obj/overmap/entity/vessel = get_or_register_shuttle(port)
	if(vessel)
		relink_hardware(turfs)
	return vessel

/datum/controller/subsystem/overmap/proc/extend_custom_shuttle(mob/user, area/shuttle/custom/hull, list/turfs)
	var/list/added = list()
	for(var/turf/tile as anything in turfs)
		if(tile.loc != hull)
			added[tile] = TRUE
	if(!length(added))
		return "Все отмеченные клетки уже входят в шаттл «[hull.name]»."
	var/obj/docking_port/mobile/port = get_shuttle_at(locate(/turf) in hull.contents)
	if(!port)
		return "Шаттл «[hull.name]» не найден в реестре полётов."
	var/obj/docking_port/stationary/pad = port.get_docked()
	if(port.mode != SHUTTLE_IDLE || pad?.id != "[port.id]_home")
		return "Достраивать шаттл «[hull.name]» можно только на его стоянке."
	if(!assign_area_turfs(user, added, hull, force_new = TRUE))
		return "Не удалось пристроить клетки к шаттлу «[hull.name]»."
	port.overmap_sync_bounds(TRUE)
	pad.match_port_bounds(port)
	relink_hardware(added)
	var/obj/overmap/entity/vessel = shuttle_vessels[port]
	if(vessel)
		vessel.hull_dirty = TRUE
		vessel.recalculate_mass()
	return null
