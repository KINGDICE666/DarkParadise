/datum/map_template/shipyard
	name = "Shipyard"
	mappath = "_maps/map_files/generic/shipyard.dmm"

/obj/overmap/entity/service_site/shipyard
	name = "Верфь"
	site_id = OVERMAP_SITE_SHIPYARD
	area_root = /area/shipyard
	map_color = COLOR_VERY_SOFT_YELLOW
	identity_color = COLOR_VERY_SOFT_YELLOW
	identity_iff_ids = list(OVERMAP_IFF_CENTCOM)
	project_terrain = TRUE
	var/list/footprint

/obj/overmap/entity/service_site/shipyard/add_overmap_components()
	AddComponent(/datum/component/overmap_sensors)
	AddComponent(/datum/component/overmap_dock_host, OVERMAP_DOCK_Z_SERVICE, area_root, TRUE, FALSE)

/obj/overmap/entity/service_site/shipyard/host_content_bounds(z_level)
	if(length(footprint) && footprint[5] == z_level)
		return footprint.Copy(1, 5)
	return ..()

/datum/controller/subsystem/overmap/proc/spawn_shipyard()
	#ifdef SKIP_SPACE_LEVELS
	return
	#endif
	var/obj/overmap/entity/service_site/shipyard/site = service_sites[OVERMAP_SITE_SHIPYARD]
	if(!site)
		return
	var/datum/map_template/shipyard/template = new
	var/turf/load_at = find_shipyard_space(template)
	if(!load_at || !template.load(load_at))
		log_world("Overmap: failed to load the shipyard map.")
		qdel(site)
		return
	for(var/turf/marked as anything in template.get_affected_turfs(load_at))
		marked.turf_flags |= NO_RUINS
		ruin_lighting_turfs += marked
	site.footprint = list(load_at.x, load_at.y, load_at.x + template.width - 1, load_at.y + template.height - 1, load_at.z)
	var/datum/overmap_sector/sector = (prob(SHIPYARD_ALPHA_CHANCE) && wilderness_sector) ? wilderness_sector : station_sector
	if(!sector)
		return
	var/turf/spot
	if(sector == station_sector && lavaland_planet)
		var/offset = OVERMAP_LAVALAND_FOOTPRINT + 2
		spot = sector.get_nearest_open_turf(sector.coord_x(lavaland_planet.loc) + pick(-offset, offset), sector.coord_y(lavaland_planet.loc) + pick(-offset, offset))
	else
		spot = sector.get_random_open_turf()
	if(spot)
		site.move_to_sector(sector, spot)
	site.dock_host.cached_host_areas = null
	ensure_host_space(site)

/datum/controller/subsystem/overmap/proc/find_shipyard_space(datum/map_template/template)
	var/margin = SHIPYARD_SPACE_MARGIN
	for(var/z_level in levels_by_trait(ADMIN_LEVEL))
		for(var/corner_x in (1 + margin) to (world.maxx - template.width - margin) step margin)
			for(var/corner_y in (1 + margin) to (world.maxy - template.height - margin) step margin)
				if(shipyard_space_free(corner_x - margin, corner_y - margin, template.width + margin * 2, template.height + margin * 2, z_level))
					return locate(corner_x, corner_y, z_level)
	return null

/datum/controller/subsystem/overmap/proc/shipyard_space_free(low_x, low_y, width, height, z_level)
	for(var/turf/tile as anything in block(low_x, low_y, z_level, low_x + width - 1, low_y + height - 1, z_level))
		if(!isspaceturf(tile) || !isspacearea(tile.loc) || (tile.turf_flags & (RESERVATION_TURF | UNUSED_RESERVATION_TURF | NO_RUINS)))
			return FALSE
	return TRUE
