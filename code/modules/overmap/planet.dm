#define OVERMAP_PLANET_PULL_RANGE 1
#define OVERMAP_PLANET_FALL_HEIGHT 480
#define OVERMAP_PLANET_FALL_TIME (3 SECONDS)
#define OVERMAP_PLANET_FALL_DAMAGE 120
#define OVERMAP_PLANET_FALL_KNOCKDOWN (10 SECONDS)
#define OVERMAP_PLANET_FALL_TRIES 50
#define OVERMAP_PLANET_FALL_TRAIT "overmap_planet_fall"

/obj/overmap/planet
	name = "planet"
	desc = "Крупное тело на карте системы. Занимает несколько клеток."
	icon = OVERMAP_PLANET_ICON_FILE
	icon_state = "lavaland"
	color = null
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	overmap_kind = OVERMAP_KIND_PLANET
	hidden_from_contacts = TRUE
	scannable = FALSE
	deny_pod_edge_dock = TRUE
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
	var/footprint = OVERMAP_LAVALAND_FOOTPRINT
	var/obj/overmap/entity/planet_station/outpost
	var/list/obj/effect/overmap_planet_cell/cells

/obj/overmap/planet/Initialize(mapload)
	. = ..()
	spawn_footprint_cells()

	icon = null

/obj/overmap/planet/update_overmap_pixel()
	pixel_x = 0
	pixel_y = 0

/obj/overmap/planet/update_overlays()
	return list()

/obj/overmap/planet/proc/spawn_footprint_cells()
	var/turf/origin = loc
	if(!isturf(origin) || footprint <= 0)
		return
	var/icon/full = icon(OVERMAP_PLANET_ICON_FILE, icon_state)
	cells = list()
	for(var/tile_x in 0 to footprint - 1)
		for(var/tile_y in 0 to footprint - 1)
			var/turf/spot = locate(origin.x + tile_x, origin.y + tile_y, origin.z)
			if(!spot)
				continue
			var/icon/piece = icon(full)
			piece.Crop(tile_x * 32 + 1, tile_y * 32 + 1, (tile_x + 1) * 32, (tile_y + 1) * 32)
			var/obj/effect/overmap_planet_cell/cell = new(spot)
			cell.icon = piece
			cell.parent_planet = src
			cells += cell

/obj/overmap/planet/Destroy()
	QDEL_LIST(cells)
	if(outpost?.planet == src)
		outpost.planet = null
	outpost = null
	return ..()

/obj/effect/overmap_planet_cell
	name = ""
	desc = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
	var/obj/overmap/planet/parent_planet

/obj/effect/overmap_planet_cell/Initialize(mapload)
	. = ..()
	SET_PLANE_IMPLICIT(src, FLOOR_PLANE)

/obj/effect/overmap_planet_cell/Destroy()
	if(parent_planet)
		parent_planet.cells -= src
		parent_planet = null
	return ..()

/obj/overmap/planet/proc/covers_turf(turf/spot)
	var/turf/origin = loc
	if(!isturf(origin) || !spot || spot.z != origin.z)
		return FALSE
	return spot.x >= origin.x && spot.x < origin.x + footprint && spot.y >= origin.y && spot.y < origin.y + footprint

/obj/overmap/planet/proc/covers_world(world_x, world_y)
	return sector && covers_turf(sector.turf_at_world(world_x, world_y))

/obj/overmap/planet/proc/pull_drifters()
	var/turf/origin = loc
	if(!sector || !isturf(origin))
		return
	var/span = OVERMAP_TILE_SPAN * sector.tile_travel
	var/center_x = (origin.x + (footprint - 1) / 2) * span
	var/center_y = (origin.y + (footprint - 1) / 2) * span
	var/pull_reach = (footprint / 2 + OVERMAP_PLANET_PULL_RANGE) * span
	for(var/datum/overmap_bubble/bubble as anything in SSovermap.bubbles)
		if(bubble.static_level || bubble.sector != sector || !length(bubble.drifters))
			continue
		for(var/atom/movable/drifter as anything in bubble.drifters.Copy())
			var/turf/spot = drifter.loc
			if(!isturf(spot) || drifter.anchored || isprojectile(drifter))
				continue
			var/list/drifter_world = bubble.to_world(spot.x, spot.y)
			if(covers_world(drifter_world[1], drifter_world[2]))
				drop_onto_surface(drifter)
				continue
			var/delta_x = center_x - drifter_world[1]
			var/delta_y = center_y - drifter_world[2]
			if(max(abs(delta_x), abs(delta_y)) > pull_reach)
				continue
			if(!bubble.gravity_warned[drifter])
				to_chat(drifter.get_all_contents_type(/mob/living), span_warning("Вас затягивает гравитация [declent_ru(GENITIVE)]!"))
				bubble.gravity_warned[drifter] = TRUE
			drifter.newtonian_move(angle2dir(delta_to_angle(delta_x, delta_y)))

/obj/overmap/planet/proc/find_fall_turf()
	var/list/surface_levels = levels_by_trait(ORE_LEVEL)
	if(!length(surface_levels))
		return null
	for(var/attempt in 1 to OVERMAP_PLANET_FALL_TRIES)
		var/turf/candidate = locate(rand(TRANSITIONEDGE + 1, world.maxx - TRANSITIONEDGE), rand(TRANSITIONEDGE + 1, world.maxy - TRANSITIONEDGE), surface_levels[1])
		if(!istype(get_area(candidate), /area/lavaland/surface/outdoors) || candidate.density || ismineralturf(candidate) || ischasm(candidate))
			continue
		return candidate

/obj/overmap/planet/proc/drop_onto_surface(atom/movable/thing)
	if(isprojectile(thing))
		qdel(thing)
		return
	var/turf/landing = find_fall_turf()
	if(!landing)
		return
	to_chat(thing.get_all_contents_type(/mob/living), span_userdanger("Вы входите в атмосферу [declent_ru(GENITIVE)] и камнем летите вниз!"))
	qdel(thing.GetComponent(/datum/component/drift))
	ADD_TRAIT(thing, TRAIT_MOVE_FLYING, OVERMAP_PLANET_FALL_TRAIT)
	ADD_TRAIT(thing, TRAIT_IMMOBILIZED, OVERMAP_PLANET_FALL_TRAIT)
	ADD_TRAIT(thing, TRAIT_HANDS_BLOCKED, OVERMAP_PLANET_FALL_TRAIT)
	cross_frame_with_pull(thing, landing)
	var/base_pixel_z = thing.pixel_z
	thing.pixel_z = base_pixel_z + OVERMAP_PLANET_FALL_HEIGHT
	animate(thing, pixel_z = base_pixel_z, time = OVERMAP_PLANET_FALL_TIME, easing = QUAD_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(land_faller), thing), OVERMAP_PLANET_FALL_TIME)

/obj/overmap/planet/proc/land_faller(atom/movable/thing)
	if(QDELETED(thing))
		return
	REMOVE_TRAITS_IN(thing, OVERMAP_PLANET_FALL_TRAIT)
	var/turf/landing = get_turf(thing)
	playsound(landing, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	for(var/mob/witness in range(7, landing))
		shake_camera(witness, 1 SECONDS, 2)
	thing.visible_message(span_danger("[DECLENT_RU_CAP(thing, NOMINATIVE)] с грохотом падает с неба!"))
	for(var/mob/living/victim as anything in thing.get_all_contents_type(/mob/living))
		to_chat(victim, span_userdanger("Вы с чудовищной силой врезаетесь в землю!"))
		shake_camera(victim, 2 SECONDS, 4)
		victim.Weaken(OVERMAP_PLANET_FALL_KNOCKDOWN)
		if(!ishuman(victim))
			victim.adjustBruteLoss(OVERMAP_PLANET_FALL_DAMAGE)
			continue
		var/mob/living/carbon/human/human_victim = victim
		var/damage_share = OVERMAP_PLANET_FALL_DAMAGE / max(length(human_victim.bodyparts), 1)
		for(var/obj/item/organ/external/limb as anything in human_victim.bodyparts.Copy())
			human_victim.apply_damage(damage_share, BRUTE, limb.limb_zone)
		for(var/leg_zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
			var/obj/item/organ/external/leg = human_victim.get_organ(leg_zone)
			leg?.fracture()
	if(islava(landing))
		var/turf/simulated/floor/lava/lava = landing
		if(lava.burn_stuff(thing))
			START_PROCESSING(SSprocessing, lava)

/obj/overmap/planet/proc/footprint_turfs()
	. = list()
	var/turf/origin = loc
	if(!isturf(origin))
		return
	var/max_x = origin.x + footprint - 1
	var/max_y = origin.y + footprint - 1
	for(var/turf/spot as anything in block(origin, locate(max_x, max_y, origin.z)))
		. += spot

/obj/overmap/planet/lavaland
	name = "Лазис Ардакс"
	desc = "Одно из крупнейших тел в секторе. Вулканистая поверхность богата ресурсами и сочится плазмой."
	map_color = "#c45c2a"
	visible_without_scanner = TRUE

/obj/overmap/planet/lavaland/get_ru_names()
	return alist(
		NOMINATIVE = "Лаваленд",
		GENITIVE = "Лаваленда",
		DATIVE = "Лаваленду",
		ACCUSATIVE = "Лаваленд",
		INSTRUMENTAL = "Лавалендом",
		PREPOSITIONAL = "Лаваленде",
	)

/obj/overmap/entity/planet_station
	name = "planetary outpost"
	movable = FALSE
	halted = TRUE
	vessel_mass = OVERMAP_MASS_STATION
	map_color = "#c45c2a"
	overmap_hazard_immune = TRUE
	deny_pod_edge_dock = TRUE
	var/obj/overmap/planet/planet

/obj/overmap/entity/planet_station/add_overmap_components()
	AddComponent(/datum/component/overmap_sensors)
	AddComponent(/datum/component/overmap_dock_host, OVERMAP_DOCK_Z_MINING, null, FALSE, TRUE)

/obj/overmap/entity/planet_station/Destroy()
	if(planet?.outpost == src)
		planet.outpost = null
	planet = null
	if(SSovermap?.lavaland_entity == src)
		SSovermap.lavaland_entity = null
	return ..()

/obj/overmap/entity/planet_station/lavaland
	name = "Lavaland mining station"
	desc = "Шахтерский аванпост на Лаваленде."

/obj/overmap/entity/planet_station/lavaland/Initialize(mapload)
	. = ..()
	apply_overmap_identity("Шахтерский аванпост", COLOR_WHITE, "station", FALSE, TRUE, null, TRUE)

/obj/overmap/entity/planet_station/lavaland/get_ru_names()
	return alist(
		NOMINATIVE = "шахтёрская станция Лаваленда",
		GENITIVE = "шахтёрской станции Лаваленда",
		DATIVE = "шахтёрской станции Лаваленда",
		ACCUSATIVE = "шахтёрскую станцию Лаваленда",
		INSTRUMENTAL = "шахтёрской станцией Лаваленда",
		PREPOSITIONAL = "шахтёрской станции Лаваленда",
	)

/proc/overmap_lavaland_landing_blocked(turf/spot)
	if(!spot)
		return TRUE
	if(spot.density)
		return TRUE
	if(islava(spot) || ischasm(spot) || isopenspaceturf(spot))
		return TRUE
	if(ismineralturf(spot))
		return TRUE
	if(locate(/obj/structure/spawner/lavaland) in spot)
		return TRUE
	for(var/mob/living/simple_animal/hostile/megafauna/fauna in spot)
		if(!QDELETED(fauna) && fauna.stat != DEAD)
			return TRUE
	return FALSE

#undef OVERMAP_PLANET_PULL_RANGE
#undef OVERMAP_PLANET_FALL_HEIGHT
#undef OVERMAP_PLANET_FALL_TIME
#undef OVERMAP_PLANET_FALL_DAMAGE
#undef OVERMAP_PLANET_FALL_KNOCKDOWN
#undef OVERMAP_PLANET_FALL_TRIES
#undef OVERMAP_PLANET_FALL_TRAIT
