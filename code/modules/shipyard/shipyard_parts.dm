GLOBAL_LIST_INIT(shipyard_parts, build_shipyard_parts())

GLOBAL_LIST_INIT(shipyard_door_paints, list(
	"Стандартная" = /obj/machinery/door/airlock,
	"Стандартная, остеклённая" = /obj/machinery/door/airlock/glass,
	"Командная" = /obj/machinery/door/airlock/command,
	"Командная, остеклённая" = /obj/machinery/door/airlock/command/glass,
	"Охрана" = /obj/machinery/door/airlock/security,
	"Охрана, остеклённая" = /obj/machinery/door/airlock/security/glass,
	"Инженерная" = /obj/machinery/door/airlock/engineering,
	"Инженерная, остеклённая" = /obj/machinery/door/airlock/engineering/glass,
	"Медицинская" = /obj/machinery/door/airlock/medical,
	"Медицинская, остеклённая" = /obj/machinery/door/airlock/medical/glass,
	"Научная" = /obj/machinery/door/airlock/science,
	"Шахтёрская" = /obj/machinery/door/airlock/mining,
	"Атмосферная" = /obj/machinery/door/airlock/atmos,
	"Техническая" = /obj/machinery/door/airlock/maintenance,
	"Титановая" = /obj/machinery/door/airlock/titanium,
	"Титановая, остеклённая" = /obj/machinery/door/airlock/titanium/glass,
	"Люк" = /obj/machinery/door/airlock/hatch,
	"Внешний шлюз" = /obj/machinery/door/airlock/external,
	"Внешний шлюз, остеклённый" = /obj/machinery/door/airlock/external/glass,
))

/datum/shipyard_part
	var/id
	var/name
	var/category
	var/build_path
	var/layer
	var/metal
	var/glass
	var/plasma
	var/credits
	var/rotatable
	var/size
	var/kind
	var/door
	var/preview_icon
	var/preview_state
	var/preview_layer

/datum/shipyard_part/New(id, name, category, build_path, layer = SHIPYARD_LAYER_OBJECT, metal = 0, glass = 0, plasma = 0, credits = 0, rotatable = FALSE, size = 1, kind, door = FALSE)
	src.id = id
	src.name = name
	src.category = category
	src.build_path = build_path
	src.layer = layer
	src.metal = metal
	src.glass = glass
	src.plasma = plasma
	src.credits = credits
	src.rotatable = rotatable
	src.size = size
	src.kind = kind
	src.door = door
	var/atom/sample = layer == SHIPYARD_LAYER_MOUNT ? text2path("[build_path]/directional/north") : build_path
	preview_icon = initial(sample.icon)
	preview_state = initial(sample.icon_state)
	preview_layer = initial(sample.layer)
	if(preview_icon && !(preview_state in icon_states(preview_icon)))
		var/list/states = icon_states(preview_icon)
		preview_state = ("[preview_state]-0" in states) ? "[preview_state]-0" : (length(states) ? states[1] : preview_state)

/datum/shipyard_part/proc/is_floor()
	return layer == SHIPYARD_LAYER_TURF && kind != SHIPYARD_KIND_WALL

/datum/shipyard_part/proc/takes_access()
	return door || kind == SHIPYARD_KIND_DOCK

/datum/shipyard_part/proc/path_for(dir, paint)
	if(door && paint && GLOB.shipyard_door_paints[paint])
		return GLOB.shipyard_door_paints[paint]
	if(layer == SHIPYARD_LAYER_MOUNT)
		return text2path("[build_path]/directional/[dir2text(dir)]")
	return build_path

/datum/shipyard_part/proc/build(turf/spot, dir, paint, list/access)
	var/path = path_for(dir, paint)
	switch(layer)
		if(SHIPYARD_LAYER_TURF)
			spot.ChangeTurf(path)
			return
		if(SHIPYARD_LAYER_DECAL)
			var/obj/effect/turf_decal/decal = path
			spot.AddElement(/datum/element/decal, initial(decal.icon), initial(decal.icon_state), dir, null, initial(decal.layer), initial(decal.alpha), initial(decal.color), FALSE, null)
			return
	var/atom/movable/built = new path(spot)
	if(rotatable)
		built.setDir(dir)
		SEND_SIGNAL(built, COMSIG_OVERMAP_WEAPON_ROTATED, 0, dir)
	if(takes_access() && length(access))
		var/obj/machinery/door/airlock/airlock = built
		airlock.req_access = access.Copy()

/proc/build_shipyard_parts()
	. = list()
	for(var/datum/shipyard_part/part as anything in list(
		new /datum/shipyard_part("plating", "Обшивка", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/plating, SHIPYARD_LAYER_TURF, metal = 1, credits = 5),
		new /datum/shipyard_part("plasteel", "Стальной пол", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/plasteel, SHIPYARD_LAYER_TURF, metal = 1, credits = 10),
		new /datum/shipyard_part("plasteel_dark", "Тёмный стальной пол", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/plasteel/dark, SHIPYARD_LAYER_TURF, metal = 1, credits = 10),
		new /datum/shipyard_part("plasteel_white", "Белый стальной пол", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/plasteel/white, SHIPYARD_LAYER_TURF, metal = 1, credits = 10),
		new /datum/shipyard_part("shuttle_floor", "Пол шаттла", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/shuttle, SHIPYARD_LAYER_TURF, metal = 1, credits = 10),
		new /datum/shipyard_part("titanium_floor", "Титановый пол", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/mineral/titanium, SHIPYARD_LAYER_TURF, metal = 2, credits = 20),
		new /datum/shipyard_part("titanium_blue", "Титановый пол, синий", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/mineral/titanium/blue, SHIPYARD_LAYER_TURF, metal = 2, credits = 20),
		new /datum/shipyard_part("titanium_yellow", "Титановый пол, жёлтый", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/mineral/titanium/yellow, SHIPYARD_LAYER_TURF, metal = 2, credits = 20),
		new /datum/shipyard_part("titanium_purple", "Титановый пол, фиолетовый", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/mineral/titanium/purple, SHIPYARD_LAYER_TURF, metal = 2, credits = 20),
		new /datum/shipyard_part("plastitanium_floor", "Пластитановый пол", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/mineral/plastitanium, SHIPYARD_LAYER_TURF, metal = 2, plasma = 1, credits = 30),
		new /datum/shipyard_part("plastitanium_red", "Пластитановый пол, красный", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/mineral/plastitanium/red, SHIPYARD_LAYER_TURF, metal = 2, plasma = 1, credits = 30),
		new /datum/shipyard_part("wood", "Деревянный пол", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/wood, SHIPYARD_LAYER_TURF, metal = 1, credits = 15),
		new /datum/shipyard_part("carpet", "Ковёр", SHIPYARD_CATEGORY_FLOOR, /turf/simulated/floor/carpet, SHIPYARD_LAYER_TURF, metal = 1, credits = 15),
		new /datum/shipyard_part("wall", "Стена", SHIPYARD_CATEGORY_WALL, /turf/simulated/wall, SHIPYARD_LAYER_TURF, metal = 2, credits = 20, kind = SHIPYARD_KIND_WALL),
		new /datum/shipyard_part("r_wall", "Укреплённая стена", SHIPYARD_CATEGORY_WALL, /turf/simulated/wall/r_wall, SHIPYARD_LAYER_TURF, metal = 4, plasma = 1, credits = 50, kind = SHIPYARD_KIND_WALL),
		new /datum/shipyard_part("titanium_wall", "Титановая стена", SHIPYARD_CATEGORY_WALL, /turf/simulated/wall/mineral/titanium, SHIPYARD_LAYER_TURF, metal = 3, credits = 40, kind = SHIPYARD_KIND_WALL),
		new /datum/shipyard_part("plastitanium_wall", "Пластитановая стена", SHIPYARD_CATEGORY_WALL, /turf/simulated/wall/mineral/plastitanium, SHIPYARD_LAYER_TURF, metal = 3, plasma = 2, credits = 80, kind = SHIPYARD_KIND_WALL),
		new /datum/shipyard_part("window", "Окно", SHIPYARD_CATEGORY_WALL, /obj/effect/spawner/window, metal = 1, glass = 2, credits = 15),
		new /datum/shipyard_part("window_reinforced", "Укреплённое окно", SHIPYARD_CATEGORY_WALL, /obj/effect/spawner/window/reinforced, metal = 1, glass = 2, credits = 20),
		new /datum/shipyard_part("window_plasma", "Плазменное окно", SHIPYARD_CATEGORY_WALL, /obj/effect/spawner/window/reinforced/plasma, metal = 1, glass = 2, plasma = 2, credits = 50),
		new /datum/shipyard_part("window_plastitanium", "Пластитановое окно", SHIPYARD_CATEGORY_WALL, /obj/effect/spawner/window/plastitanium, metal = 1, glass = 3, plasma = 1, credits = 50),
		new /datum/shipyard_part("window_shuttle", "Окно шаттла", SHIPYARD_CATEGORY_WALL, /obj/effect/spawner/window/shuttle, metal = 1, glass = 3, credits = 40),
		new /datum/shipyard_part("airlock", "Шлюз", SHIPYARD_CATEGORY_DOOR, /obj/machinery/door/airlock, metal = 5, glass = 1, credits = 60, rotatable = TRUE, door = TRUE),
		new /datum/shipyard_part("docking_airlock", "Стыковочный шлюз", SHIPYARD_CATEGORY_DOOR, /obj/machinery/door/airlock/external/docking, metal = 6, glass = 1, credits = 100, rotatable = TRUE, kind = SHIPYARD_KIND_DOCK),
		new /datum/shipyard_part("apc", "ЛКП", SHIPYARD_CATEGORY_POWER, /obj/machinery/power/apc, SHIPYARD_LAYER_MOUNT, metal = 3, glass = 1, credits = 80, rotatable = TRUE),
		new /datum/shipyard_part("firealarm", "Пожарная тревога", SHIPYARD_CATEGORY_POWER, /obj/machinery/firealarm, SHIPYARD_LAYER_MOUNT, metal = 1, glass = 1, credits = 30, rotatable = TRUE),
		new /datum/shipyard_part("air_alarm", "Воздушная тревога", SHIPYARD_CATEGORY_POWER, /obj/machinery/alarm, SHIPYARD_LAYER_MOUNT, metal = 1, glass = 1, credits = 30, rotatable = TRUE),
		new /datum/shipyard_part("light", "Лампа", SHIPYARD_CATEGORY_POWER, /obj/machinery/light, SHIPYARD_LAYER_MOUNT, metal = 1, glass = 1, credits = 10, rotatable = TRUE),
		new /datum/shipyard_part("light_small", "Малая лампа", SHIPYARD_CATEGORY_POWER, /obj/machinery/light/small, SHIPYARD_LAYER_MOUNT, metal = 1, credits = 8, rotatable = TRUE),
		new /datum/shipyard_part("helm", "Штурвал", SHIPYARD_CATEGORY_CONSOLE, /obj/machinery/computer/helm, metal = 5, glass = 5, credits = 400, rotatable = TRUE, kind = SHIPYARD_KIND_HELM),
		new /datum/shipyard_part("gunner", "Консоль наводчика", SHIPYARD_CATEGORY_CONSOLE, /obj/machinery/computer/helm/gunner, metal = 5, glass = 5, credits = 300, rotatable = TRUE),
		new /datum/shipyard_part("engines_console", "Консоль двигателей", SHIPYARD_CATEGORY_CONSOLE, /obj/machinery/computer/engines, metal = 4, glass = 4, credits = 250, rotatable = TRUE),
		new /datum/shipyard_part("sensors_console", "Консоль сенсоров", SHIPYARD_CATEGORY_CONSOLE, /obj/machinery/computer/sensors, metal = 4, glass = 4, plasma = 1, credits = 300, rotatable = TRUE),
		new /datum/shipyard_part("navmap", "Монитор карты системы", SHIPYARD_CATEGORY_CONSOLE, /obj/machinery/computer/navmap, metal = 3, glass = 3, credits = 150, rotatable = TRUE),
		new /datum/shipyard_part("transponder", "Транспондер", SHIPYARD_CATEGORY_CONSOLE, /obj/machinery/transponder, metal = 3, glass = 2, credits = 150),
		new /datum/shipyard_part("intercom", "Межсекторная связь", SHIPYARD_CATEGORY_CONSOLE, /obj/machinery/overmap_intercom, metal = 2, glass = 1, credits = 100),
		new /datum/shipyard_part("autocannon", "Автопушка", SHIPYARD_CATEGORY_WEAPON, /obj/machinery/ship_gun/autocannon, metal = 15, glass = 4, credits = 800, rotatable = TRUE, kind = SHIPYARD_KIND_WEAPON),
		new /datum/shipyard_part("laser", "Корабельный лазер", SHIPYARD_CATEGORY_WEAPON, /obj/machinery/ship_gun/laser, metal = 12, glass = 8, plasma = 4, credits = 1000, rotatable = TRUE, kind = SHIPYARD_KIND_WEAPON),
		new /datum/shipyard_part("railgun", "Рельсотрон", SHIPYARD_CATEGORY_WEAPON, /obj/machinery/ship_gun/railgun, metal = 25, glass = 8, plasma = 10, credits = 1600, rotatable = TRUE, kind = SHIPYARD_KIND_WEAPON),
		new /datum/shipyard_part("torpedo", "Торпедный аппарат", SHIPYARD_CATEGORY_WEAPON, /obj/machinery/ship_gun/torpedo, metal = 25, glass = 6, plasma = 12, credits = 1800, rotatable = TRUE, kind = SHIPYARD_KIND_WEAPON),
		new /datum/shipyard_part("gun_loader", "Зарядник орудий", SHIPYARD_CATEGORY_WEAPON, /obj/machinery/ship_gun_loader, metal = 10, glass = 4, credits = 400),
		new /datum/shipyard_part("shield_generator", "Генератор щита", SHIPYARD_CATEGORY_WEAPON, /obj/machinery/ship_shield_generator, metal = 15, glass = 10, plasma = 10, credits = 1500),
		new /datum/shipyard_part("ion_engine", "Малый ионный двигатель", SHIPYARD_CATEGORY_ENGINE, /obj/machinery/ship_engine, metal = 10, glass = 4, plasma = 2, credits = 500, rotatable = TRUE, kind = SHIPYARD_KIND_ENGINE),
		new /datum/shipyard_part("ion_engine_large", "Большой ионный двигатель", SHIPYARD_CATEGORY_ENGINE, /obj/machinery/ship_engine/large, metal = 30, glass = 10, plasma = 8, credits = 1500, rotatable = TRUE, size = 2, kind = SHIPYARD_KIND_ENGINE),
		new /datum/shipyard_part("plasma_engine", "Малый плазменный двигатель", SHIPYARD_CATEGORY_ENGINE, /obj/machinery/ship_engine/plasma, metal = 12, glass = 4, plasma = 6, credits = 700, rotatable = TRUE, kind = SHIPYARD_KIND_ENGINE),
		new /datum/shipyard_part("plasma_engine_large", "Большой плазменный двигатель", SHIPYARD_CATEGORY_ENGINE, /obj/machinery/ship_engine/plasma/large, metal = 35, glass = 10, plasma = 20, credits = 2000, rotatable = TRUE, size = 2, kind = SHIPYARD_KIND_ENGINE),
		new /datum/shipyard_part("sensor_long", "Массив сенсоров дальнего действия", SHIPYARD_CATEGORY_SENSOR, /obj/machinery/sensor_array/long_range, metal = 8, glass = 4, plasma = 2, credits = 600, kind = SHIPYARD_KIND_SENSOR),
		new /datum/shipyard_part("sensor_short", "Массив сенсоров ближнего действия", SHIPYARD_CATEGORY_SENSOR, /obj/machinery/sensor_array/short_range, metal = 5, glass = 3, plasma = 1, credits = 350, kind = SHIPYARD_KIND_SENSOR),
		new /datum/shipyard_part("chair", "Стул", SHIPYARD_CATEGORY_FURNITURE, /obj/structure/chair, metal = 1, credits = 5, rotatable = TRUE),
		new /datum/shipyard_part("shuttle_chair", "Кресло шаттла", SHIPYARD_CATEGORY_FURNITURE, /obj/structure/chair/comfy/shuttle, metal = 2, credits = 20, rotatable = TRUE),
		new /datum/shipyard_part("office_chair", "Офисное кресло", SHIPYARD_CATEGORY_FURNITURE, /obj/structure/chair/office/dark, metal = 2, credits = 15, rotatable = TRUE),
		new /datum/shipyard_part("stool", "Табурет", SHIPYARD_CATEGORY_FURNITURE, /obj/structure/chair/stool, metal = 1, credits = 5),
		new /datum/shipyard_part("table", "Стол", SHIPYARD_CATEGORY_FURNITURE, /obj/structure/table, metal = 2, credits = 15),
		new /datum/shipyard_part("table_reinforced", "Укреплённый стол", SHIPYARD_CATEGORY_FURNITURE, /obj/structure/table/reinforced, metal = 3, credits = 25),
		new /datum/shipyard_part("table_glass", "Стеклянный стол", SHIPYARD_CATEGORY_FURNITURE, /obj/structure/table/glass, metal = 1, glass = 2, credits = 20),
		new /datum/shipyard_part("railing", "Ограждение", SHIPYARD_CATEGORY_STRUCTURE, /obj/structure/railing, metal = 1, credits = 8, rotatable = TRUE),
		new /datum/shipyard_part("catwalk", "Мостки", SHIPYARD_CATEGORY_STRUCTURE, /obj/structure/lattice/catwalk, metal = 1, credits = 8),
		new /datum/shipyard_part("lattice", "Каркас", SHIPYARD_CATEGORY_STRUCTURE, /obj/structure/lattice, metal = 1, credits = 4),
		new /datum/shipyard_part("stripes_line", "Полоса", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/stripes/line, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
		new /datum/shipyard_part("stripes_corner", "Угол полосы", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/stripes/corner, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
		new /datum/shipyard_part("stripes_end", "Конец полосы", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/stripes/end, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
		new /datum/shipyard_part("delivery", "Зона доставки", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/delivery, SHIPYARD_LAYER_DECAL, credits = 2),
		new /datum/shipyard_part("delivery_hollow", "Контур зоны доставки", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/delivery/hollow, SHIPYARD_LAYER_DECAL, credits = 2),
		new /datum/shipyard_part("box", "Рамка", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/box, SHIPYARD_LAYER_DECAL, credits = 2),
		new /datum/shipyard_part("box_corners", "Уголки рамки", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/box/corners, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
		new /datum/shipyard_part("caution", "Осторожно", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/caution, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
		new /datum/shipyard_part("stand_clear", "Не стоять", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/caution/stand_clear, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
		new /datum/shipyard_part("arrows", "Стрелки", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/arrows, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
		new /datum/shipyard_part("loading_area", "Зона погрузки", SHIPYARD_CATEGORY_DECAL, /obj/effect/turf_decal/loading_area, SHIPYARD_LAYER_DECAL, credits = 2, rotatable = TRUE),
	))
		.[part.id] = part
