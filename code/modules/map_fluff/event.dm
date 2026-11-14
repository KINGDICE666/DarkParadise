/datum/map/coldcolony
	name = "Malta"
	map_path = "_maps/map_files/event/Station/coldcolony.dmm"
	lavaland_path = "_maps/map_files/coldcolony/Lavaland.dmm"
	traits = list(MAIN_STATION, STATION_CONTACT, STATION_LEVEL = "Surface", REACHABLE, AI_OK, ZTRAIT_SNOWSTORM, ZTRAIT_BASETURF = /turf/simulated/floor/plating/asteroid/snow)

	station_name = "ШОН Мальта"
	english_station_name = "NMC Malta"
	station_short = "Мальта"
	dock_name = "АКН Трурль"
	company_name = "\"Нанотрейзен\""
	company_short = "НТ"
	starsys_name = "Эпсилон Лукуста"
	webmap_url = "https://webmap.wiki-ss13.space/coldcolony/"
	planetary = TRUE

/datum/map/coldcolony/miners
	name = "Shaft"
	map_path = "_maps/map_files/event/Station/rustedevents.dmm"
	traits = list(
		list(MAIN_STATION, STATION_LEVEL = "First Floor", STATION_CONTACT, REACHABLE, AI_OK, ZTRAIT_UP, ZTRAIT_BASETURF = /turf/simulated/floor/plating/asteroid/basalt),
		list(STATION_LEVEL = "Second Floor", STATION_CONTACT, ZTRAIT_ASHSTORM, REACHABLE, AI_OK, ZTRAIT_DOWN, ZTRAIT_BASETURF = /turf/simulated/openspace),
	)
	station_name = "Исследователиский Объект МРК"
	english_station_name = "MPK"
	company_name = "\"USSP\""
	company_short = "USSP"
	station_short = "Coldcolony"
	admin_only = TRUE
