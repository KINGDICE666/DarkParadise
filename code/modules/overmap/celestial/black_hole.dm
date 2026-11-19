#define BLACK_HOLE_EMP_CHANCE 40
#define BLACK_HOLE_DEBRIS_CHANCE 10
#define BLACK_HOLE_CORE_SOUND_VOLUME 70
#define BLACK_HOLE_CORE_RADIATION_RANGE 8
#define BLACK_HOLE_CORE_RADIATION_THRESHOLD 0.05
#define BLACK_HOLE_CORE_PULSES 3
#define BLACK_HOLE_CORE_RADIATION_CHANCE 100

/obj/overmap/celestial/black_hole
	name = "black hole"
	desc = "Гравитационная воронка. Аккреционный диск жжёт электронику, а за горизонтом событий спасения нет."
	icon_state = "grav1"
	overmap_kind = OVERMAP_KIND_BLACK_HOLE
	map_color = "#9d6bff"
	core_radius = 0.6
	hazard_radius = 2
	gravity_radius = 8
	gravity_strength = 1.08e-3

/obj/overmap/celestial/black_hole/get_ru_names()
	return alist(
		NOMINATIVE = "чёрная дыра",
		GENITIVE = "чёрной дыры",
		DATIVE = "чёрной дыре",
		ACCUSATIVE = "чёрную дыру",
		INSTRUMENTAL = "чёрной дырой",
		PREPOSITIONAL = "чёрной дыре",
	)

/obj/overmap/celestial/black_hole/zone_warning(zone)
	if(zone == OVERMAP_CELESTIAL_ZONE_CORE)
		return "КРИТИЧЕСКАЯ ОПАСНОСТЬ: корабль пересёк горизонт событий. Зафиксировано мощнейшее радиоактивное излучение, требуется аварийный прыжок!"
	return ..()

/obj/overmap/celestial/black_hole/warn_vessel(obj/overmap/entity/vessel, zone)
	. = ..()
	if(zone != OVERMAP_CELESTIAL_ZONE_CORE)
		return
	for(var/mob/living/crew as anything in overmap_vessel_crew(vessel))
		crew.playsound_local(get_turf(crew), 'sound/overmap/black_hole_core.ogg', BLACK_HOLE_CORE_SOUND_VOLUME, FALSE)

/obj/overmap/celestial/black_hole/affects(obj/overmap/entity/vessel)
	if(istype(vessel, /obj/overmap/entity/station/ship))
		return !QDELETED(vessel) && vessel.sector == sector && vessel.movable && !vessel.halted && isturf(vessel.loc) && !vessel.landed_planet
	return ..()

/obj/overmap/celestial/black_hole/core_tick(obj/overmap/entity/vessel)
	vessel.horizon_seen_at = world.time
	for(var/mob/living/crew as anything in overmap_vessel_crew(vessel))
		crew.apply_status_effect(/datum/status_effect/event_horizon)

/obj/overmap/celestial/black_hole/affect_vessel(obj/overmap/entity/vessel, zone)
	var/turf/spot = overmap_vessel_structure_turf(vessel)
	if(!spot)
		return
	if(zone == OVERMAP_CELESTIAL_ZONE_CORE)
		vessel.shake_shuttle(1 SECONDS, 2)
		for(var/pulse in 1 to BLACK_HOLE_CORE_PULSES)
			var/turf/source = overmap_vessel_structure_turf(vessel)
			if(source)
				radiation_pulse(source, BLACK_HOLE_CORE_RADIATION_RANGE, BLACK_HOLE_CORE_RADIATION_THRESHOLD, BLACK_HOLE_CORE_RADIATION_CHANCE)
		for(var/mob/living/crew as anything in overmap_vessel_crew(vessel))
			SSradiation.irradiate(crew)
		return
	vessel.shake_shuttle(1 SECONDS, 1)
	if(vessel == SSovermap.station_entity)
		return
	if(prob(BLACK_HOLE_EMP_CHANCE))
		empulse(spot, 1, 4, FALSE, "overmap accretion disk")
	if(prob(BLACK_HOLE_DEBRIS_CHANCE))
		explosion(spot, devastation_range = 0, heavy_impact_range = 1, light_impact_range = 2, adminlog = FALSE, cause = "overmap accretion disk")

#undef BLACK_HOLE_EMP_CHANCE
#undef BLACK_HOLE_DEBRIS_CHANCE
#undef BLACK_HOLE_CORE_SOUND_VOLUME
#undef BLACK_HOLE_CORE_RADIATION_RANGE
#undef BLACK_HOLE_CORE_RADIATION_THRESHOLD
#undef BLACK_HOLE_CORE_PULSES
#undef BLACK_HOLE_CORE_RADIATION_CHANCE
