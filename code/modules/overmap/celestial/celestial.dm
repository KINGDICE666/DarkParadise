GLOBAL_LIST_EMPTY(overmap_celestials)

/proc/overmap_gravity_accel(distance, strength, core_radius, gravity_radius)
	if(distance >= gravity_radius)
		return 0
	return strength / max(distance, core_radius, OVERMAP_CELESTIAL_CORE_FLOOR) ** 2

/proc/overmap_celestial_zone(distance, core_radius, hazard_radius, gravity_radius)
	if(distance < core_radius)
		return OVERMAP_CELESTIAL_ZONE_CORE
	if(distance < hazard_radius)
		return OVERMAP_CELESTIAL_ZONE_HAZARD
	if(distance < gravity_radius)
		return OVERMAP_CELESTIAL_ZONE_GRAVITY
	return OVERMAP_CELESTIAL_ZONE_CLEAR

/proc/overmap_vessel_structure_turf(obj/overmap/entity/vessel)
	var/obj/overmap/entity/pod/pod_vessel = vessel
	if(istype(pod_vessel))
		return get_turf(pod_vessel.pod)
	if(length(vessel.hull_turfs))
		var/turf/spot = pick(vessel.hull_turfs)
		return isturf(spot) ? spot : null
	if(vessel != SSovermap.station_entity)
		return null
	var/list/station_levels = levels_by_trait(STATION_LEVEL)
	if(!length(station_levels))
		return null
	for(var/attempt in 1 to OVERMAP_CELESTIAL_STATION_TRIES * 10)
		var/turf/spot = locate(rand(TRANSITIONEDGE + 1, world.maxx - TRANSITIONEDGE), rand(TRANSITIONEDGE + 1, world.maxy - TRANSITIONEDGE), pick(station_levels))
		if(spot && !isspaceturf(spot) && !isspacearea(get_area(spot)))
			return spot

/proc/overmap_vessel_crew(obj/overmap/entity/vessel)
	. = list()
	var/obj/overmap/entity/pod/pod_vessel = vessel
	if(istype(pod_vessel))
		return pod_vessel.pod ? pod_vessel.pod.get_all_contents_type(/mob/living) : list()
	if(vessel.shuttle)
		for(var/area/place as anything in vessel.shuttle.shuttle_areas)
			for(var/mob/living/crew in place)
				. += crew
		return
	if(vessel != SSovermap.station_entity)
		return
	for(var/mob/living/crew as anything in GLOB.alive_mob_list)
		var/turf/spot = get_turf(crew)
		if(spot && is_station_level(spot.z))
			. += crew

/obj/overmap/celestial
	name = "celestial body"
	desc = "Массивное небесное тело."
	icon_state = "star"
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	visible_without_scanner = TRUE
	hidden_from_contacts = TRUE
	scannable = FALSE
	deny_pod_edge_dock = TRUE
	appearance_flags = RESET_COLOR | KEEP_APART
	color = null
	var/core_radius = 1
	var/hazard_radius = 2.5
	var/gravity_radius = 6
	var/gravity_strength = 5.6e-4
	var/list/vessel_zones = list()
	var/designation

/obj/overmap/celestial/get_ru_names()
	return alist(
		NOMINATIVE = "небесное тело",
		GENITIVE = "небесного тела",
		DATIVE = "небесному телу",
		ACCUSATIVE = "небесное тело",
		INSTRUMENTAL = "небесным телом",
		PREPOSITIONAL = "небесном теле",
	)

/obj/overmap/celestial/Initialize(mapload)
	. = ..()
	designation = "[pick("HD", "GJ", "KIC", "LHS", "TYC")]-[rand(100, 9999)]"
	GLOB.overmap_celestials += src

/obj/overmap/celestial/get_overmap_display_name()
	return "[DECLENT_RU_CAP(src, NOMINATIVE)] [designation]"

/obj/overmap/celestial/Destroy()
	GLOB.overmap_celestials -= src
	vessel_zones.Cut()
	return ..()

/obj/overmap/celestial/proc/span()
	return OVERMAP_TILE_SPAN * (sector?.tile_travel || 1)

/obj/overmap/celestial/proc/covers_turf(turf/spot)
	if(!spot || !isturf(loc) || spot.z != z)
		return FALSE
	return sqrt((spot.x - x) ** 2 + (spot.y - y) ** 2) < hazard_radius + 0.5

/obj/overmap/celestial/proc/radar_zones()
	return list("core" = core_radius, "hazard" = hazard_radius, "gravity" = gravity_radius)

/obj/overmap/celestial/proc/navigation_box(span)
	var/reach = hazard_radius * span
	return list(x * span - reach, y * span - reach, x * span + reach, y * span + reach)

/obj/overmap/celestial/proc/affects(obj/overmap/entity/vessel)
	if(QDELETED(vessel) || vessel.sector != sector || !vessel.movable || vessel.halted)
		return FALSE
	if(vessel.programmed_mission || vessel.relay_jump_from || vessel.docked_ship)
		return FALSE
	if(vessel != SSovermap.station_entity && !vessel.shuttle && !vessel.overmap_pod)
		return FALSE
	return vessel.in_free_flight()

/obj/overmap/celestial/proc/process_gravity(elapsed)
	if(!sector || !isturf(loc))
		return
	var/span = span()
	var/center_x = x * span
	var/center_y = y * span
	for(var/obj/overmap/entity/vessel in sector.objects)
		if(!affects(vessel))
			continue
		var/delta_x = center_x - vessel.get_world_x()
		var/delta_y = center_y - vessel.get_world_y()
		var/world_distance = sqrt(delta_x ** 2 + delta_y ** 2)
		var/distance = world_distance / span
		set_vessel_zone(vessel, overmap_celestial_zone(distance, core_radius, hazard_radius, gravity_radius))
		var/accel = overmap_gravity_accel(distance, gravity_strength, core_radius, gravity_radius)
		if(!accel || !world_distance)
			continue
		vessel.speed[1] += delta_x / world_distance * accel * elapsed
		vessel.speed[2] += delta_y / world_distance * accel * elapsed

/obj/overmap/celestial/proc/set_vessel_zone(obj/overmap/entity/vessel, zone)
	var/uid = vessel.UID()
	var/old_zone = vessel_zones[uid] || OVERMAP_CELESTIAL_ZONE_CLEAR
	if(zone == old_zone)
		return
	if(zone == OVERMAP_CELESTIAL_ZONE_CLEAR)
		vessel_zones -= uid
	else
		vessel_zones[uid] = zone
	if(zone < old_zone)
		return
	warn_vessel(vessel, zone)
	if(zone == OVERMAP_CELESTIAL_ZONE_CORE)
		log_game("Overmap vessel [vessel.name] entered the core of [name] at [sector.id] [sector.coord_x(loc)]:[sector.coord_y(loc)].")
	if(zone >= OVERMAP_CELESTIAL_ZONE_HAZARD && vessel.shield_absorb(zone == OVERMAP_CELESTIAL_ZONE_CORE ? OVERMAP_SHIELD_CORE_COST : OVERMAP_SHIELD_CORONA_COST))
		INVOKE_ASYNC(src, PROC_REF(affect_vessel), vessel, zone)

/obj/overmap/celestial/proc/zone_warning(zone)
	switch(zone)
		if(OVERMAP_CELESTIAL_ZONE_GRAVITY)
			return "Сенсоры: корабль вошёл в гравитационный колодец объекта «[get_overmap_display_name()]». Курс сносит к центру."
		if(OVERMAP_CELESTIAL_ZONE_HAZARD)
			return "ОПАСНОСТЬ: корабль в опасной зоне объекта «[get_overmap_display_name()]». Немедленно уходите."
		if(OVERMAP_CELESTIAL_ZONE_CORE)
			return "КРИТИЧЕСКАЯ ОПАСНОСТЬ: корабль разрушается у объекта «[get_overmap_display_name()]»!"

/obj/overmap/celestial/proc/warn_vessel(obj/overmap/entity/vessel, zone)
	var/text = zone_warning(zone)
	if(!text)
		return
	var/dangerous = zone >= OVERMAP_CELESTIAL_ZONE_HAZARD
	vessel.shuttle_visible_message(dangerous ? span_userdanger(text) : span_warning(text))
	SEND_SIGNAL(vessel, COMSIG_OVERMAP_NOTICE, text, dangerous ? OVERMAP_NOTICE_DANGER : OVERMAP_NOTICE_WARN, OVERMAP_NOTICE_FROM_SENSORS)
	vessel.add_sensor_journal(text, dangerous ? "distress" : "recall", loc, get_overmap_display_name())
	if(dangerous)
		vessel.play_shuttle_sound(OVERMAP_SENSOR_DISTRESS_SOUND, 60)

/obj/overmap/celestial/proc/process_effects()
	for(var/uid in vessel_zones.Copy())
		var/obj/overmap/entity/vessel = locateUID(uid)
		if(!affects(vessel))
			vessel_zones -= uid
			continue
		var/zone = vessel_zones[uid]
		if(zone < OVERMAP_CELESTIAL_ZONE_HAZARD)
			continue
		var/shield_cost = zone == OVERMAP_CELESTIAL_ZONE_CORE ? OVERMAP_SHIELD_CORE_COST : OVERMAP_SHIELD_CORONA_COST
		if(!vessel.shield_absorb(shield_cost))
			continue
		INVOKE_ASYNC(src, PROC_REF(affect_vessel), vessel, zone)

/obj/overmap/celestial/proc/affect_vessel(obj/overmap/entity/vessel, zone)
	return

/datum/controller/subsystem/overmap/proc/process_celestials(elapsed)
	var/static/effect_elapsed = 0
	for(var/obj/overmap/celestial/body as anything in GLOB.overmap_celestials)
		body.process_gravity(elapsed)
	effect_elapsed += elapsed
	if(effect_elapsed < OVERMAP_CELESTIAL_EFFECT_TICK)
		return
	effect_elapsed = 0
	for(var/obj/overmap/celestial/body as anything in GLOB.overmap_celestials)
		body.process_effects()
	process_nebulae()
	process_space_environment()
