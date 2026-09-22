/datum/map/coldcolony
	name = "Malta"
	map_path = "_maps/map_files/event/Station/rustedevents.dmm"
	lavaland_path = "_maps/map_files/coldcolony/Lavaland.dmm"
	traits = list(
		list(MAIN_STATION, STATION_CONTACT, STATION_LEVEL = "First Floor", ZTRAIT_UP, REACHABLE, ZTRAIT_BASETURF = /turf/simulated/floor/plating/asteroid),
		list(STATION_LEVEL = "Second Floor", STATION_CONTACT, REACHABLE, ZTRAIT_DOWN, ZTRAIT_BASETURF = /turf/simulated/openspace),
	)
	space_ruins_levels = 0
	station_name = "ШОН Мальта"
	english_station_name = "NMC Malta"
	station_short = "Мальта"
	dock_name = "АКН Трурль"
	company_name = "\"Нанотрейзен\""
	company_short = "НТ"
	starsys_name = "Эпсилон Лукуста"
	admin_only = TRUE
	planetary = TRUE
	webmap_url = "https://webmap.wiki-ss13.space/coldcolony/"
