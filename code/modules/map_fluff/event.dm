/datum/map/newmap
	name = "WWTWO"
	map_path = "_maps/map_files/event/Station/warsoftea.dmm"
	lavaland_path = "_maps/map_files/coldcolony/Lavaland.dmm"
	traits = list(
		list(
			MAIN_STATION,
			STATION_LEVEL = "Main Floor",
			STATION_CONTACT,
			REACHABLE,
			AI_OK,
			ZTRAIT_UP,
			ZTRAIT_BASETURF = /turf/simulated/floor/indestructible/dirt_floor
		),
		list(
			STATION_LEVEL = "Second Floor",
			STATION_CONTACT,
			REACHABLE,
			AI_OK,
			ZTRAIT_DOWN,
			ZTRAIT_BASETURF = /turf/simulated/openspace
		),
	)
	space_ruins_levels = 3
	station_name = "Nool"
	english_station_name = "Nool"
	station_short = "Nool"
	dock_name = "АКН Трурль"
	company_name = "\"Нанотрейзен\""
	company_short = "НТ"
	starsys_name = "Эпсилон Лукуста"
	webmap_url = "https://webmap.wiki-ss13.space/coldcolony/"
	admin_only = TRUE
	planetary = TRUE