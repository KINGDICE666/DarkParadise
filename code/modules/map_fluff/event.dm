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

/datum/map/Backrooms
	name = "Backrooms"
	map_path = "_maps/map_files/event/Station/fallout.dmm"
	lavaland_path = "_maps/map_files/coldcolony/Lavaland.dmm"
	linkage = UNAFFECTED
	traits = list(
		list(MAIN_STATION, STATION_CONTACT, STATION_LEVEL = "Lower Floor", REACHABLE, AI_OK, ZTRAIT_UP, ZTRAIT_BASETURF = /turf/simulated/floor/plating/asteroid),
		list(STATION_CONTACT, STATION_LEVEL = "Second Floor", REACHABLE, AI_OK, ZTRAIT_UP, ZTRAIT_DOWN, ZTRAIT_BASETURF = /turf/simulated/openspace),
		list(STATION_CONTACT, STATION_LEVEL = "Third Floor", REACHABLE, AI_OK, ZTRAIT_UP, ZTRAIT_DOWN, ZTRAIT_BASETURF = /turf/simulated/openspace),
		list(STATION_CONTACT, STATION_LEVEL = "Upper Floor", REACHABLE, AI_OK, ZTRAIT_DOWN, ZTRAIT_BASETURF = /turf/simulated/openspace),
	)

	station_name = "Backrooms"
	english_station_name = "Backrooms"
	station_short = "Backrooms"
	dock_name = "Backrooms"
	company_name = "\"Нанотрейзен\""
	company_short = "НТ"
	starsys_name = "Epsilon Lucusta"
	webmap_url = "https://webmap.wiki-ss13.space/coldcolony/"
	planetary = TRUE
