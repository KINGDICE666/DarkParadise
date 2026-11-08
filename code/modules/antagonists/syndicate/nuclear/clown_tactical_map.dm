#define TACTICAL_MAP_MAX_ANNOTATIONS 256
#define TACTICAL_MAP_MAX_LABEL_LENGTH 40

/obj/item/implant/tacmap/nuclear
	name = "tactical map implant"
	gender = MALE
	desc = "Био-чип тактической карты. Показывает оперативников, боеголовки и диск аутентификации."
	actions_types = list(/datum/action/item_action/hands_free/activate/tactical_map)
	var/can_draw = FALSE
	var/obj/machinery/station_map/tactical/tactical_map

/obj/item/implant/tacmap/nuclear/get_ru_names()
	return alist(
		NOMINATIVE = "био-чип тактической карты",
		GENITIVE = "био-чипа тактической карты",
		DATIVE = "био-чипу тактической карты",
		ACCUSATIVE = "био-чип тактической карты",
		INSTRUMENTAL = "био-чипом тактической карты",
		PREPOSITIONAL = "био-чипе тактической карты",
	)

/obj/item/implant/tacmap/nuclear/activate(cause)
	. = ..()
	if(!imp_in)
		return
	if(!tactical_map)
		tactical_map = new(src)
	if(tactical_map.watching_mob)
		tactical_map.close_map()
	else
		tactical_map.open_map(imp_in)

/obj/item/implant/tacmap/nuclear/removed(mob/living/carbon/human/source)
	QDEL_NULL(tactical_map)
	return ..()

/obj/item/implant/tacmap/nuclear/Destroy()
	QDEL_NULL(tactical_map)
	return ..()

/obj/item/implant/tacmap/nuclear/leader
	can_draw = TRUE

/datum/action/item_action/hands_free/activate/tactical_map
	name = "Тактическая карта"

/obj/machinery/station_map/tactical
	name = "tactical map"
	gender = FEMALE
	use_power = NO_POWER_USE
	auto_update = TRUE
	var/datum/team/nuclear_team/tactical_team
	var/last_draw_x
	var/last_draw_y

/obj/machinery/station_map/tactical/get_ru_names()
	return alist(
		NOMINATIVE = "тактическая голокарта",
		GENITIVE = "тактической голокарты",
		DATIVE = "тактической голокарте",
		ACCUSATIVE = "тактическую голокарту",
		INSTRUMENTAL = "тактической голокартой",
		PREPOSITIONAL = "тактической голокарте",
	)

/obj/machinery/station_map/tactical/Initialize(mapload)
	. = ..()
	var/obj/item/implant/tacmap/nuclear/implant = loc
	var/datum/antagonist/nuclear_operative/operative = implant.imp_in.mind.has_antag_datum(/datum/antagonist/nuclear_operative)
	tactical_team = operative?.nuclear_team
	for(var/level in 1 to world.maxz)
		if(is_station_level(level))
			current_z_level = level
			break
	var/turf/wearer_turf = get_turf(implant.imp_in)
	if(is_station_level(wearer_turf.z))
		current_z_level = wearer_turf.z

/obj/machinery/station_map/tactical/Destroy()
	tactical_team = null
	return ..()

/obj/machinery/station_map/tactical/power_change()
	return

/obj/machinery/station_map/tactical/open_map(mob/user)
	. = ..()
	use_power = NO_POWER_USE
	if(!.)
		return
	var/obj/item/implant/tacmap/nuclear/implant = loc
	if(!implant.can_draw)
		return
	to_chat(user, span_notice("Нажимайте на карту, чтобы соединять точки маршрута. Shift-клик добавляет подпись, Ctrl-клик стирает все отметки отряда."))

/obj/machinery/station_map/tactical/check_position(mob/user)
	if(!user?.client)
		close_map()
		return
	var/turf/user_turf = get_turf(user)
	if(is_station_level(user_turf.z) && current_z_level != user_turf.z)
		close_map()
		QDEL_NULL(holomap_datum)
		current_z_level = user_turf.z
		open_map(user)

/obj/machinery/station_map/tactical/close_map(animate_close = FALSE)
	. = ..(animate_close)
	last_draw_x = null
	last_draw_y = null

/obj/machinery/station_map/tactical/handle_overlays()
	var/list/markers = list()
	if(tactical_team)
		for(var/datum/mind/member as anything in tactical_team.members)
			var/mob/living/operative = member.current
			if(!operative)
				continue
			var/marker_color = operative.stat == DEAD ? COLOR_GRAY : (member == tactical_team.leader ? COLOR_YELLOW : COLOR_RED)
			add_marker(markers, get_turf(operative), marker_color, operative.real_name)
	for(var/obj/item/disk/nuclear/disk in GLOB.poi_list)
		if(!disk.fake)
			add_marker(markers, get_turf(disk), COLOR_GREEN, "Диск")
	for(var/obj/machinery/nuclearbomb/bomb in GLOB.poi_list)
		add_marker(markers, get_turf(bomb), COLOR_ORANGE, bomb.declent_ru(NOMINATIVE))
	for(var/obj/mecha/combat/honker/dark/mech in GLOB.mechas_list)
		add_marker(markers, get_turf(mech), COLOR_RED, mech.declent_ru(NOMINATIVE))
	for(var/list/point as anything in tactical_team?.tactical_annotations)
		if(point["z"] != current_z_level)
			continue
		var/image/marker = image('icons/misc/8x8.dmi', "you")
		marker.color = COLOR_YELLOW
		marker.pixel_w = HOLOMAP_CENTER_X + point["x"] - 3
		marker.pixel_z = HOLOMAP_CENTER_Y + point["y"] - 3
		marker.maptext = MAPTEXT("[html_encode(point["label"])]")
		marker.maptext_width = 160
		markers += marker
	return list(
		"Тактические отметки" = list(
			"icon" = image('icons/misc/8x8.dmi', "you"),
			"markers" = markers,
		),
	)

/obj/machinery/station_map/tactical/proc/add_marker(list/markers, turf/location, marker_color, label)
	if(!location || location.z != current_z_level)
		return
	var/image/marker = image('icons/misc/8x8.dmi', "you")
	marker.color = marker_color
	marker.pixel_w = HOLOMAP_CENTER_X + location.x - 3
	marker.pixel_z = HOLOMAP_CENTER_Y + location.y - 3
	marker.maptext = MAPTEXT("[html_encode(label)]")
	marker.maptext_width = 160
	markers += marker

/obj/machinery/station_map/tactical/on_map_click(mob/user, icon_x, icon_y, list/modifiers)
	var/obj/item/implant/tacmap/nuclear/implant = loc
	if(!implant.can_draw || user != watching_mob || !tactical_team)
		return FALSE
	if(modifiers[CTRL_CLICK])
		tactical_team.tactical_annotations.Cut()
		last_draw_x = null
		last_draw_y = null
		return TRUE
	var/map_x = icon_x - HOLOMAP_CENTER_X
	var/map_y = icon_y - HOLOMAP_CENTER_Y
	if(map_x < 1 || map_y < 1 || map_x > world.maxx || map_y > world.maxy)
		return FALSE
	if(modifiers[SHIFT_CLICK])
		INVOKE_ASYNC(src, PROC_REF(add_label), user, map_x, map_y)
		return TRUE
	if(last_draw_x && last_draw_y)
		var/steps = max(abs(map_x - last_draw_x), abs(map_y - last_draw_y))
		for(var/index in 1 to steps)
			if(length(tactical_team.tactical_annotations) >= TACTICAL_MAP_MAX_ANNOTATIONS)
				break
			tactical_team.tactical_annotations += list(list(
				"x" = round(last_draw_x + (map_x - last_draw_x) * index / steps),
				"y" = round(last_draw_y + (map_y - last_draw_y) * index / steps),
				"z" = current_z_level,
				"label" = "",
			))
	last_draw_x = map_x
	last_draw_y = map_y
	holomap_datum.update_map(handle_overlays())
	return TRUE

/obj/machinery/station_map/tactical/proc/add_label(mob/user, map_x, map_y)
	var/label = tgui_input_text(
		user,
		"Текст отметки на тактической карте:",
		"Тактическая карта",
		max_length = TACTICAL_MAP_MAX_LABEL_LENGTH,
	)
	if(!label || user != watching_mob || !tactical_team)
		return
	if(length(tactical_team.tactical_annotations) >= TACTICAL_MAP_MAX_ANNOTATIONS)
		return
	tactical_team.tactical_annotations += list(list(
		"x" = map_x,
		"y" = map_y,
		"z" = current_z_level,
		"label" = label,
	))
	holomap_datum.update_map(handle_overlays())

#undef TACTICAL_MAP_MAX_ANNOTATIONS
#undef TACTICAL_MAP_MAX_LABEL_LENGTH
