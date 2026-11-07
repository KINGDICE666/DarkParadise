#define RAD_MONITOR_ANNOUNCE_COOLDOWN (2 MINUTES)

/// Отделы, к которым относятся зоны станции: токен пути зоны и отдел
GLOBAL_LIST_INIT(radiation_area_tokens, list(
	"engineering" = "engineering",
	"medical" = "medical",
	"science" = "science",
	"research" = "science",
	"security" = "security",
	"cargo" = "cargo",
	"quartermaster" = "cargo",
	"service" = "service",
	"resid_serv" = "service",
	"chapel" = "service",
	"command" = "command",
	"bridge" = "command",
	"legal" = "command",
	"commons" = "commons",
	"civilian" = "commons",
	"hallway" = "hallway",
	"maintenance" = "maintenance",
	"ai" = "ai",
	"turret_protected" = "ai",
	"telecomms" = "ai",
))

/// Названия и цвета отделов на карте
GLOBAL_LIST_INIT(radiation_departments, list(
	"engineering" = list("name" = "Инженерный отдел", "color" = "#ffba40"),
	"medical" = list("name" = "Медицинский отдел", "color" = "#6fd3ff"),
	"science" = list("name" = "Научный отдел", "color" = "#c58bff"),
	"security" = list("name" = "Служба безопасности", "color" = "#ff6b63"),
	"cargo" = list("name" = "Отдел снабжения", "color" = "#d9a066"),
	"service" = list("name" = "Сервисный отдел", "color" = "#7be08a"),
	"command" = list("name" = "Командование", "color" = "#5f8dff"),
	"commons" = list("name" = "Жилые отсеки", "color" = "#e0e0b0"),
	"hallway" = list("name" = "Коридоры", "color" = "#9aa7b0"),
	"maintenance" = list("name" = "Технические тоннели", "color" = "#7a7f6a"),
	"ai" = list("name" = "Сектор ИИ и связи", "color" = "#46d6c0"),
))

/// Участки пола каждого отдела для карты. Собираются один раз, при первом открытии консоли.
GLOBAL_LIST_EMPTY(radiation_department_spans)

/// Возвращает id отдела для зоны или null, если зона не относится к станции
/proc/get_radiation_department(area/target_area)
	var/static/list/department_by_type = list()
	if(isnull(target_area))
		return null

	var/area_type = target_area.type
	if(!(area_type in department_by_type))
		department_by_type[area_type] = get_radiation_department_by_type(area_type)

	return department_by_type[area_type]

/proc/get_radiation_department_by_type(area_type)
	if(!ispath(area_type, /area/station) && !ispath(area_type, /area/coldcolony))
		return null

	for(var/token in splittext("[area_type]", "/"))
		if(GLOB.radiation_area_tokens[token])
			return GLOB.radiation_area_tokens[token]

	return null

/// Склеивает пол отделов в полосы [x, y, ширина, z], чтобы не отправлять в интерфейс каждый тайл
/proc/build_radiation_department_spans()
	if(length(GLOB.radiation_department_spans))
		return GLOB.radiation_department_spans

	var/list/turf_keys = list()
	var/list/station_levels = levels_by_trait(STATION_LEVEL)
	for(var/area/station_area as anything in GLOB.areas)
		var/department = get_radiation_department(station_area)
		if(!department)
			continue

		var/list/keys = turf_keys[department]
		if(!keys)
			keys = list()
			turf_keys[department] = keys

		for(var/z_level in station_levels)
			for(var/turf/area_turf as anything in station_area.get_turfs_by_zlevel(z_level))
				keys += z_level * 65536 + area_turf.y * 256 + area_turf.x

	for(var/department in turf_keys)
		var/list/keys = sortTim(turf_keys[department], GLOBAL_PROC_REF(cmp_numeric_asc))
		var/list/spans = list()
		var/run_start
		var/previous
		for(var/key in keys)
			if(previous && key == previous + 1)
				previous = key
				continue

			if(previous)
				spans[++spans.len] = get_radiation_span(run_start, previous)
			run_start = key
			previous = key

		if(previous)
			spans[++spans.len] = get_radiation_span(run_start, previous)
		GLOB.radiation_department_spans[department] = spans

	return GLOB.radiation_department_spans

/proc/get_radiation_span(run_start, run_end)
	return list(run_start % 256, round(run_start / 256) % 256, run_end - run_start + 1, round(run_start / 65536))

/// Карта всей станции со всеми включёнными приборами и объявление эвакуации любого отдела, откуда бы консоль ни работала
/obj/machinery/computer/radiation_monitor
	name = "radiation monitoring console"
	desc = "Показывает на карте станции все включённые счётчики Гейгера, находит по ним источник излучения и объявляет эвакуацию отделов."
	icon_keyboard = "power_key"
	icon_screen = null
	circuit = /obj/item/circuitboard/radiation_monitor
	light_color = LIGHT_COLOR_GREEN
	req_access = list(ACCESS_ENGINE_EQUIP)

/obj/machinery/computer/radiation_monitor/get_ru_names()
	return alist(
		NOMINATIVE = "консоль радиационного контроля",
		GENITIVE = "консоли радиационного контроля",
		DATIVE = "консоли радиационного контроля",
		ACCUSATIVE = "консоль радиационного контроля",
		INSTRUMENTAL = "консолью радиационного контроля",
		PREPOSITIONAL = "консоли радиационного контроля",
	)

/obj/machinery/computer/radiation_monitor/update_overlays()
	. = ..()
	if(stat & (BROKEN|NOPOWER))
		return

	. += mutable_appearance('icons/obj/machines/radiation.dmi', "radmon")
	. += emissive_appearance('icons/obj/machines/radiation.dmi', "radmon", src)

/obj/machinery/computer/radiation_monitor/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/computer/radiation_monitor/attack_hand(mob/user)
	if(..())
		return TRUE

	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/radiation_monitor/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/radiation_monitor/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RadiationMonitor", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/computer/radiation_monitor/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/nanomaps),
	)

/obj/machinery/computer/radiation_monitor/ui_static_data(mob/user)
	var/list/data = list()
	var/list/level_numbers = list()
	var/list/level_names = list()
	for(var/z_level in levels_by_trait(STATION_LEVEL))
		level_numbers += z_level
		level_names += check_level_trait(z_level, STATION_LEVEL)
	data["stationLevelNum"] = level_numbers
	data["stationLevelName"] = level_names

	var/list/spans = build_radiation_department_spans()
	var/list/departments = list()
	for(var/department in GLOB.radiation_departments)
		var/list/info = GLOB.radiation_departments[department]
		departments += list(list(
			"id" = department,
			"name" = info["name"],
			"color" = info["color"],
			"spans" = spans[department] || list(),
		))
	data["departments"] = departments
	return data

/obj/machinery/computer/radiation_monitor/ui_data(mob/user)
	var/list/data = list()
	var/list/meters = list()
	for(var/obj/item/geiger_counter/meter as anything in GLOB.geiger_counters)
		if(!meter.scanning)
			continue

		var/turf/meter_turf = get_turf(meter)
		if(meter_turf && is_station_level(meter_turf.z))
			meters += list(meter.get_monitor_entry())
	data["meters"] = meters
	data["evacuating"] = SSradiation.evacuating
	data["authorized"] = emagged || allowed(user)
	data["announce_ready"] = COOLDOWN_FINISHED(SSradiation, evacuation_cooldown)
	return data

/obj/machinery/computer/radiation_monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	add_fingerprint(ui.user)
	if(!emagged && !allowed(ui.user))
		balloon_alert(ui.user, "нет доступа!")
		return

	switch(action)
		if("evacuate")
			var/department = params["department"]
			var/list/info = GLOB.radiation_departments[department]
			if(!info || (department in SSradiation.evacuating) || !COOLDOWN_FINISHED(SSradiation, evacuation_cooldown))
				return

			COOLDOWN_START(SSradiation, evacuation_cooldown, RAD_MONITOR_ANNOUNCE_COOLDOWN)
			SSradiation.evacuating += department
			GLOB.major_announcement.announce(
				message = "Радиационная опасность: [info["name"]]. Всему персоналу немедленно покинуть отсеки!",
				new_title = ANNOUNCE_ANOMALY_RU,
				new_sound = ANNOUNCER_RADIATION,
			)
			investigate_log("[key_name_log(ui.user)] announced an evacuation of [department].", INVESTIGATE_RADIATION)
		if("cancel_evacuation")
			var/department = params["department"]
			var/list/info = GLOB.radiation_departments[department]
			if(!info || !(department in SSradiation.evacuating))
				return

			SSradiation.evacuating -= department
			GLOB.minor_announcement.announce(
				message = "Радиационная опасность миновала: [info["name"]]. Персонал может вернуться на рабочие места.",
				new_title = ANNOUNCE_ANOMALY_RU,
			)
			investigate_log("[key_name_log(ui.user)] cancelled the evacuation of [department].", INVESTIGATE_RADIATION)
		if("reset_meter")
			var/obj/item/geiger_counter/meter = locateUID(params["uid"])
			if(!(meter in GLOB.geiger_counters))
				return
			meter.total_rads = 0
		else
			return

	return TRUE

/obj/machinery/computer/radiation_monitor/emag_act(mob/user)
	if(emagged)
		return FALSE

	emagged = TRUE
	playsound(src, 'sound/machines/twobeep.ogg', 40, TRUE)
	balloon_alert(user, "доступ снят")
	return TRUE

#undef RAD_MONITOR_ANNOUNCE_COOLDOWN
