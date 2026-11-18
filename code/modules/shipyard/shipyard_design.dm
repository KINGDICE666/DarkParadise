/datum/shipyard_design
	var/name = ""
	var/width
	var/height
	var/list/placements = list()
	var/list/object_cover = list()
	var/list/touched = list()
	var/skipped = 0

/datum/shipyard_design/New(width, height)
	src.width = width
	src.height = height

/datum/shipyard_design/proc/entry(x, y, layer)
	return placements["[x],[y],[layer]"]

/datum/shipyard_design/proc/part_of(list/placement)
	return placement ? GLOB.shipyard_parts[placement["part"]] : null

/datum/shipyard_design/proc/object_origin(x, y)
	return object_cover["[x],[y]"]

/datum/shipyard_design/proc/has_floor(x, y)
	var/datum/shipyard_part/part = part_of(entry(x, y, SHIPYARD_LAYER_TURF))
	return part?.is_floor()

/datum/shipyard_design/proc/has_wall(x, y)
	var/datum/shipyard_part/part = part_of(entry(x, y, SHIPYARD_LAYER_TURF))
	return part && !part.is_floor()

/datum/shipyard_design/proc/in_bounds(x, y)
	return x >= 1 && y >= 1 && x <= width && y <= height

/datum/shipyard_design/proc/set_entry(x, y, layer, datum/shipyard_part/part, dir, paint, list/access)
	placements["[x],[y],[layer]"] = list("part" = part.id, "dir" = dir, "paint" = part.door ? paint : null, "access" = part.takes_access() ? access?.Copy() : null)
	touched |= "[x],[y]"

/datum/shipyard_design/proc/clear_entry(x, y, layer)
	placements -= "[x],[y],[layer]"
	touched |= "[x],[y]"

/datum/shipyard_design/proc/remove_object(x, y)
	var/origin = object_origin(x, y)
	if(!origin)
		return
	var/list/coords = splittext(origin, ",")
	var/origin_x = text2num(coords[1])
	var/origin_y = text2num(coords[2])
	var/datum/shipyard_part/part = part_of(entry(origin_x, origin_y, SHIPYARD_LAYER_OBJECT))
	var/size = part?.size || 1
	for(var/offset_x in 0 to size - 1)
		for(var/offset_y in 0 to size - 1)
			object_cover -= "[origin_x + offset_x],[origin_y + offset_y]"
			touched |= "[origin_x + offset_x],[origin_y + offset_y]"
	clear_entry(origin_x, origin_y, SHIPYARD_LAYER_OBJECT)

/datum/shipyard_design/proc/drop_hanging_mounts(x, y)
	for(var/direction in GLOB.cardinal)
		var/turf_x = x - (direction == EAST ? 1 : direction == WEST ? -1 : 0)
		var/turf_y = y - (direction == NORTH ? 1 : direction == SOUTH ? -1 : 0)
		var/list/mount = entry(turf_x, turf_y, SHIPYARD_LAYER_MOUNT)
		if(mount && mount["dir"] == direction)
			clear_entry(turf_x, turf_y, SHIPYARD_LAYER_MOUNT)

/datum/shipyard_design/proc/strip_tile(x, y)
	remove_object(x, y)
	clear_entry(x, y, SHIPYARD_LAYER_MOUNT)
	clear_entry(x, y, SHIPYARD_LAYER_DECAL)

/datum/shipyard_design/proc/ensure_floor(x, y)
	if(!entry(x, y, SHIPYARD_LAYER_TURF))
		set_entry(x, y, SHIPYARD_LAYER_TURF, GLOB.shipyard_parts["plating"], SOUTH)

/datum/shipyard_design/proc/place(datum/shipyard_part/part, x, y, dir, paint, list/access)
	if(!in_bounds(x, y) || !in_bounds(x + part.size - 1, y + part.size - 1))
		return "Деталь не помещается на площадку."
	switch(part.layer)
		if(SHIPYARD_LAYER_TURF)
			var/was_wall = has_wall(x, y)
			if(!part.is_floor())
				strip_tile(x, y)
			else if(was_wall)
				drop_hanging_mounts(x, y)
			set_entry(x, y, SHIPYARD_LAYER_TURF, part, dir)
		if(SHIPYARD_LAYER_OBJECT)
			for(var/offset_x in 0 to part.size - 1)
				for(var/offset_y in 0 to part.size - 1)
					if(has_wall(x + offset_x, y + offset_y))
						return "Мешает стена."
			for(var/offset_x in 0 to part.size - 1)
				for(var/offset_y in 0 to part.size - 1)
					remove_object(x + offset_x, y + offset_y)
					ensure_floor(x + offset_x, y + offset_y)
					object_cover["[x + offset_x],[y + offset_y]"] = "[x],[y]"
			set_entry(x, y, SHIPYARD_LAYER_OBJECT, part, dir, paint, access)
		if(SHIPYARD_LAYER_MOUNT)
			var/turf_x = x + (dir == EAST ? 1 : dir == WEST ? -1 : 0)
			var/turf_y = y + (dir == NORTH ? 1 : dir == SOUTH ? -1 : 0)
			if(has_wall(x, y))
				return "Настенный предмет ставится на пол рядом со стеной."
			if(!has_wall(turf_x, turf_y))
				return "С выбранной стороны нет стены."
			ensure_floor(x, y)
			set_entry(x, y, SHIPYARD_LAYER_MOUNT, part, dir)
		if(SHIPYARD_LAYER_DECAL)
			if(!has_floor(x, y))
				return "Разметка рисуется только на полу."
			set_entry(x, y, SHIPYARD_LAYER_DECAL, part, dir)
	return null

/datum/shipyard_design/proc/erase(x, y)
	if(entry(x, y, SHIPYARD_LAYER_DECAL))
		clear_entry(x, y, SHIPYARD_LAYER_DECAL)
		return
	if(entry(x, y, SHIPYARD_LAYER_MOUNT))
		clear_entry(x, y, SHIPYARD_LAYER_MOUNT)
		return
	if(object_origin(x, y))
		remove_object(x, y)
		return
	if(!entry(x, y, SHIPYARD_LAYER_TURF))
		return
	if(has_wall(x, y))
		drop_hanging_mounts(x, y)
	strip_tile(x, y)
	clear_entry(x, y, SHIPYARD_LAYER_TURF)

/datum/shipyard_design/proc/hull_tiles()
	. = list()
	for(var/key in placements)
		var/list/coords = splittext(key, ",")
		if(coords[3] == SHIPYARD_LAYER_TURF)
			. += list(list(text2num(coords[1]), text2num(coords[2])))

/datum/shipyard_design/proc/hull_connected()
	var/list/hull = list()
	for(var/list/tile as anything in hull_tiles())
		hull["[tile[1]],[tile[2]]"] = tile
	if(!length(hull))
		return FALSE
	var/first = hull[1]
	var/list/reached = list()
	reached[first] = TRUE
	var/list/queue = list(hull[first])
	while(length(queue))
		var/list/current = queue[length(queue)]
		queue.len--
		for(var/direction in GLOB.cardinal)
			var/next_x = current[1] + (direction == EAST ? 1 : direction == WEST ? -1 : 0)
			var/next_y = current[2] + (direction == NORTH ? 1 : direction == SOUTH ? -1 : 0)
			var/next_key = "[next_x],[next_y]"
			if(hull[next_key] && !reached[next_key])
				reached[next_key] = TRUE
				queue += list(hull[next_key])
	return length(reached) == length(hull)

/datum/shipyard_design/proc/stats()
	var/list/counts = list("tiles" = 0, "walls" = 0, "doors" = 0, "engines" = 0, "weapons" = 0, "sensors" = 0, "helms" = 0, "docks" = 0)
	var/metal = 0
	var/glass = 0
	var/plasma = 0
	var/credits = 0
	var/thrust = 0
	for(var/key in placements)
		var/list/placement = placements[key]
		var/datum/shipyard_part/part = part_of(placement)
		if(!part)
			continue
		metal += part.metal
		glass += part.glass
		plasma += part.plasma
		credits += part.credits
		if(part.layer == SHIPYARD_LAYER_TURF)
			counts["tiles"]++
		if(part.door || part.kind == SHIPYARD_KIND_DOCK)
			counts["doors"]++
		switch(part.kind)
			if(SHIPYARD_KIND_WALL)
				counts["walls"]++
			if(SHIPYARD_KIND_ENGINE)
				counts["engines"]++
				var/obj/machinery/ship_engine/engine = part.build_path
				thrust += initial(engine.generated_thrust)
			if(SHIPYARD_KIND_WEAPON)
				counts["weapons"]++
			if(SHIPYARD_KIND_SENSOR)
				counts["sensors"]++
			if(SHIPYARD_KIND_HELM)
				counts["helms"]++
			if(SHIPYARD_KIND_DOCK)
				counts["docks"]++
	. = counts
	.["metal"] = metal
	.["glass"] = glass
	.["plasma"] = plasma
	.["credits"] = credits
	.["thrust"] = round(thrust, 0.1)
	var/list/problems = list()
	if(!counts["tiles"])
		problems += "Проект пуст: поставьте пол или стены."
	else if(!hull_connected())
		problems += "Корпус должен быть одним цельным куском."
	if(!length(trim(name)))
		problems += "Дайте шаттлу название."
	.["problems"] = problems
	var/list/warnings = list()
	if(!counts["helms"])
		warnings += "Нет штурвала: кораблём нельзя будет управлять."
	if(!counts["engines"])
		warnings += "Нет двигателей: корабль не сдвинется с места."
	if(!counts["sensors"])
		warnings += "Нет сенсоров: радар будет почти слепым."
	if(!counts["docks"])
		warnings += "Нет стыковочного шлюза: корабль не сможет пристыковаться к другим."
	.["warnings"] = warnings

/datum/shipyard_design/proc/build_steps()
	. = list()
	var/static/list/order = list(SHIPYARD_LAYER_TURF, SHIPYARD_LAYER_OBJECT, SHIPYARD_LAYER_MOUNT, SHIPYARD_LAYER_DECAL)
	for(var/layer in order)
		for(var/wall_pass in list(FALSE, TRUE))
			for(var/key in placements)
				var/list/coords = splittext(key, ",")
				if(coords[3] != layer)
					continue
				var/list/placement = placements[key]
				var/datum/shipyard_part/part = part_of(placement)
				if(!part || (layer == SHIPYARD_LAYER_TURF && (part.kind == SHIPYARD_KIND_WALL) != wall_pass) || (layer != SHIPYARD_LAYER_TURF && wall_pass))
					continue
				. += list(list(part.id, text2num(coords[1]), text2num(coords[2]), placement["dir"], placement["paint"], placement["access"]))

/datum/shipyard_design/proc/export_json()
	var/list/parts = list()
	for(var/key in placements)
		var/list/coords = splittext(key, ",")
		var/list/placement = placements[key]
		parts += list(list("id" = placement["part"], "x" = text2num(coords[1]), "y" = text2num(coords[2]), "dir" = placement["dir"], "paint" = placement["paint"], "access" = placement["access"]))
	return json_encode(list("version" = SHIPYARD_DESIGN_VERSION, "name" = name, "width" = width, "height" = height, "parts" = parts))

/datum/shipyard_design/proc/import_json(text)
	var/list/data
	try
		data = json_decode(text)
	catch
		return "Файл не похож на проект верфи."
	if(!length(data))
		return "Файл не похож на проект верфи."
	if(!islist(data) || data["version"] != SHIPYARD_DESIGN_VERSION || !islist(data["parts"]))
		return "Файл не похож на проект верфи."
	if(length(data["parts"]) > width * height * 4)
		return "В проекте слишком много деталей для этой площадки."
	name = shipyard_ship_name(data["name"])
	var/list/valid_access = get_all_accesses()
	var/static/list/order = list(SHIPYARD_LAYER_TURF, SHIPYARD_LAYER_OBJECT, SHIPYARD_LAYER_MOUNT, SHIPYARD_LAYER_DECAL)
	skipped = 0
	for(var/layer in order)
		for(var/list/item in data["parts"])
			if(!islist(item))
				continue
			var/datum/shipyard_part/part = GLOB.shipyard_parts[item["id"]]
			if(!part || part.layer != layer)
				continue
			var/dir = (item["dir"] in GLOB.cardinal) ? item["dir"] : SOUTH
			var/paint = (item["paint"] in GLOB.shipyard_door_paints) ? item["paint"] : null
			var/list/access = islist(item["access"]) ? (item["access"] & valid_access) : null
			if(!isnum(item["x"]) || !isnum(item["y"]) || place(part, item["x"], item["y"], dir, paint, access))
				skipped++
	return null

/proc/shipyard_ship_name(text)
	return copytext_char(sanitize(trim("[text]")), 1, SHIPYARD_MAX_NAME + 1)
