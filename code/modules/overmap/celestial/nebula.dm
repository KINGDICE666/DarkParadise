#define NEBULA_ION_EMP_CHANCE 20
#define NEBULA_PLASMA_HEAT_CHANCE 15
#define NEBULA_PLASMA_TEMPERATURE 700
#define NEBULA_PUFF_FALLOFF 0.8
#define NEBULA_EDGE 0.5

/obj/overmap/feature/hazard/nebula
	name = "пылевая туманность"
	desc = "Облако межзвёздной пыли. Слепит сенсоры, но кораблю не вредит."
	icon_state = "dust1"
	map_color = "#9a8f7a"
	var/flavour = OVERMAP_NEBULA_DUST
	var/sensor_factor = 0.35

/obj/overmap/feature/hazard/nebula/get_ru_names()
	return alist(
		NOMINATIVE = "пылевая туманность",
		GENITIVE = "пылевой туманности",
		DATIVE = "пылевой туманности",
		ACCUSATIVE = "пылевую туманность",
		INSTRUMENTAL = "пылевой туманностью",
		PREPOSITIONAL = "пылевой туманности",
	)

/obj/overmap/feature/hazard/nebula/roll_density()
	return rand(3, 6)

/obj/overmap/feature/hazard/nebula/generate_scatter()
	scatter_points = list()
	scatter_chunks = list()
	scatter_radar_chunks = list()

/obj/overmap/feature/hazard/nebula/cloud_strength(world_x, world_y)
	var/span = OVERMAP_TILE_SPAN * (sector?.tile_travel || 1)
	var/cx = world_x / span
	var/cy = world_y / span
	var/strength = 0
	for(var/ix in round(cx) - 1 to round(cx) + 1)
		for(var/iy in round(cy) - 1 to round(cy) + 1)
			for(var/obj/overmap/feature/hazard/nebula/other in locate(ix, iy, z))
				if(other.flavour == flavour)
					strength += max(0, 1 - ((cx - other.x) ** 2 + (cy - other.y) ** 2) / NEBULA_PUFF_FALLOFF)
	var/wisps = sin(cx * 157 + cy * 61) * 0.22 + sin(cx * 293 - cy * 211) * 0.14 + sin((cx + cy) * 523) * 0.08
	return max(0, strength - NEBULA_EDGE + wisps)

/obj/overmap/feature/hazard/nebula/proc/affect_inside(obj/overmap/entity/vessel, strength)
	return

/obj/overmap/feature/hazard/nebula/ion
	name = "ионная туманность"
	desc = "Заряженный газ. Сбивает сенсоры и бьёт по электронике короткими импульсами."
	icon_state = "ion1"
	map_color = "#5fd0ff"
	flavour = OVERMAP_NEBULA_ION
	sensor_factor = 0.4

/obj/overmap/feature/hazard/nebula/ion/get_ru_names()
	return alist(
		NOMINATIVE = "ионная туманность",
		GENITIVE = "ионной туманности",
		DATIVE = "ионной туманности",
		ACCUSATIVE = "ионную туманность",
		INSTRUMENTAL = "ионной туманностью",
		PREPOSITIONAL = "ионной туманности",
	)

/obj/overmap/feature/hazard/nebula/ion/affect_inside(obj/overmap/entity/vessel, strength)
	if(vessel.shield_charge() > 0)
		vessel.shield_absorb(OVERMAP_SHIELD_ION_DRAIN * min(strength, 1))
		return
	if(!prob(NEBULA_ION_EMP_CHANCE * min(strength, 1)))
		return
	var/turf/spot = overmap_vessel_structure_turf(vessel)
	if(spot)
		empulse(spot, 0, 3, FALSE, "overmap ion nebula")

/obj/overmap/feature/hazard/nebula/plasma
	name = "плазменная туманность"
	desc = "Раскалённая плазма. Ослепляет сенсоры и разогревает обшивку до возгорания."
	icon_state = "electrical1"
	map_color = "#ff7ad9"
	flavour = OVERMAP_NEBULA_PLASMA
	sensor_factor = 0.5

/obj/overmap/feature/hazard/nebula/plasma/get_ru_names()
	return alist(
		NOMINATIVE = "плазменная туманность",
		GENITIVE = "плазменной туманности",
		DATIVE = "плазменной туманности",
		ACCUSATIVE = "плазменную туманность",
		INSTRUMENTAL = "плазменной туманностью",
		PREPOSITIONAL = "плазменной туманности",
	)

/obj/overmap/feature/hazard/nebula/plasma/affect_inside(obj/overmap/entity/vessel, strength)
	if(!prob(NEBULA_PLASMA_HEAT_CHANCE * min(strength, 1)))
		return
	var/turf/spot = overmap_vessel_structure_turf(vessel)
	spot?.hotspot_expose(NEBULA_PLASMA_TEMPERATURE, CELL_VOLUME)

/obj/overmap/entity/proc/nebula_fields()
	if(nebula_cache_time == world.time)
		return nebula_cache_fields
	nebula_cache_time = world.time
	nebula_cache_fields = list()
	nebula_cache_factor = 1
	var/turf/here = get_overmap_turf()
	if(!here || !sector)
		return nebula_cache_fields
	var/self_x = get_world_x()
	var/self_y = get_world_y()
	var/list/checked = list()
	for(var/turf/cell as anything in RANGE_TURFS(1, here))
		for(var/obj/overmap/feature/hazard/nebula/field in cell)
			if(field.sector != sector || checked[field.flavour])
				continue
			checked[field.flavour] = TRUE
			var/strength = field.cloud_strength(self_x, self_y)
			if(strength <= 0)
				continue
			nebula_cache_fields[field] = strength
			nebula_cache_factor = min(nebula_cache_factor, 1 - (1 - field.sensor_factor) * min(strength, 1))
	return nebula_cache_fields

/obj/overmap/entity/proc/nebula_sensor_factor()
	nebula_fields()
	return nebula_cache_factor

/datum/controller/subsystem/overmap/proc/process_nebulae()
	for(var/obj/overmap/entity/vessel as anything in vessels)
		if(QDELETED(vessel) || !vessel.in_free_flight() || vessel.programmed_mission)
			continue
		var/list/fields = vessel.nebula_fields()
		for(var/obj/overmap/feature/hazard/nebula/field as anything in fields)
			field.affect_inside(vessel, fields[field])

#undef NEBULA_ION_EMP_CHANCE
#undef NEBULA_PLASMA_HEAT_CHANCE
#undef NEBULA_PLASMA_TEMPERATURE
#undef NEBULA_PUFF_FALLOFF
#undef NEBULA_EDGE
