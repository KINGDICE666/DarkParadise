#define NEBULA_BLOB_MIN 4
#define NEBULA_BLOB_MAX 9
#define NEBULA_WISPS_MAX 3
#define NEBULA_WISP_MIN 2
#define NEBULA_WISP_MAX 4

/proc/overmap_celestial_spot_clear(datum/overmap_sector/sector, turf/spot, obj/overmap/celestial/body_type)
	var/hazard_reach = body_type::hazard_radius
	var/edge = CEILING(hazard_reach, 1) + OVERMAP_CELESTIAL_EDGE_CLEARANCE
	var/local_x = sector.coord_x(spot)
	var/local_y = sector.coord_y(spot)
	if(local_x <= edge || local_x > sector.size - edge || local_y <= edge || local_y > sector.size - edge)
		return FALSE
	if(sector.turf_occupied(spot))
		return FALSE
	for(var/obj/overmap/other as anything in sector.objects)
		if(!isturf(other.loc))
			continue
		var/distance = sqrt((other.x - spot.x) ** 2 + (other.y - spot.y) ** 2)
		var/obj/overmap/celestial/body = other
		if(istype(body))
			if(distance < body.gravity_radius + hazard_reach + OVERMAP_CELESTIAL_BODY_GAP)
				return FALSE
			continue
		if(istype(other, /obj/overmap/entity/hyperrelay) || istype(other, /obj/overmap/portal))
			if(distance < hazard_reach + OVERMAP_CELESTIAL_RELAY_CLEARANCE)
				return FALSE
			continue
		if(istype(other, /obj/overmap/entity) && distance < hazard_reach + 1)
			return FALSE
	return TRUE

/proc/place_overmap_celestial(datum/overmap_sector/sector, body_type)
	var/list/candidates = list()
	for(var/turf/spot as anything in sector.get_map_turfs())
		if(overmap_celestial_spot_clear(sector, spot, body_type))
			candidates += spot
	if(!length(candidates))
		log_world("Overmap: no room for [body_type] in sector [sector.id].")
		return null
	var/turf/spot = pick(candidates)
	var/obj/overmap/celestial/body = new body_type(spot)
	sector.add_object(body, spot)
	return body

/proc/spawn_overmap_celestials(datum/overmap_sector/sector)
	if(!sector || sector.sector_kind != OVERMAP_SECTOR_KIND_WILDERNESS)
		return
	if(prob(OVERMAP_STAR_CHANCE))
		place_overmap_celestial(sector, pick(subtypesof(/obj/overmap/celestial/star) + /obj/overmap/celestial/star))
	if(prob(OVERMAP_BLACK_HOLE_CHANCE))
		place_overmap_celestial(sector, /obj/overmap/celestial/black_hole)
	var/list/nebula_types = list(/obj/overmap/feature/hazard/nebula, /obj/overmap/feature/hazard/nebula/ion, /obj/overmap/feature/hazard/nebula/plasma)
	for(var/i in 1 to rand(OVERMAP_NEBULA_MIN, OVERMAP_NEBULA_MAX))
		var/turf/start = overmap_hazard_pick_start(sector)
		if(!start)
			break
		var/nebula_type = pick(nebula_types)
		overmap_hazard_paint_blob(nebula_type, sector, start, rand(NEBULA_BLOB_MIN, NEBULA_BLOB_MAX))
		for(var/wisp in 1 to rand(1, NEBULA_WISPS_MAX))
			overmap_hazard_paint_arc(nebula_type, sector, start, rand(NEBULA_WISP_MIN, NEBULA_WISP_MAX), pick(GLOB.alldirs))

#undef NEBULA_BLOB_MIN
#undef NEBULA_BLOB_MAX
#undef NEBULA_WISPS_MAX
#undef NEBULA_WISP_MIN
#undef NEBULA_WISP_MAX
