#define BLACK_HOLE_EMP_CHANCE 40
#define BLACK_HOLE_DEBRIS_CHANCE 10
#define BLACK_HOLE_CORE_BLAST_CHANCE 30
#define BLACK_HOLE_CORE_SOUND_VOLUME 70
#define BLACK_HOLE_TEAR_DAMAGE 30
#define BLACK_HOLE_TEAR_MESSAGE_CHANCE 30

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
		return "КРИТИЧЕСКАЯ ОПАСНОСТЬ: корабль пересёк горизонт событий. Корпус разрывает приливными силами!"
	return ..()

/obj/overmap/celestial/black_hole/warn_vessel(obj/overmap/entity/vessel, zone)
	. = ..()
	if(zone != OVERMAP_CELESTIAL_ZONE_CORE)
		return
	for(var/mob/living/crew as anything in overmap_vessel_crew(vessel))
		crew.playsound_local(get_turf(crew), 'sound/overmap/black_hole_core.ogg', BLACK_HOLE_CORE_SOUND_VOLUME, FALSE)

/obj/overmap/celestial/black_hole/affect_vessel(obj/overmap/entity/vessel, zone)
	var/turf/spot = overmap_vessel_structure_turf(vessel)
	if(!spot)
		return
	if(zone == OVERMAP_CELESTIAL_ZONE_CORE)
		if(prob(BLACK_HOLE_CORE_BLAST_CHANCE))
			explosion(spot, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 4, adminlog = FALSE, cause = "overmap black hole horizon")
		vessel.shake_shuttle(2 SECONDS, 4)
		for(var/mob/living/crew as anything in overmap_vessel_crew(vessel))
			crew.adjustBruteLoss(BLACK_HOLE_TEAR_DAMAGE)
			if(prob(BLACK_HOLE_TEAR_MESSAGE_CHANCE))
				to_chat(crew, span_userdanger("Вас вытягивает и разрывает приливными силами!"))
		return
	vessel.shake_shuttle(1 SECONDS, 1)
	if(prob(BLACK_HOLE_EMP_CHANCE))
		empulse(spot, 1, 4, FALSE, "overmap accretion disk")
	if(prob(BLACK_HOLE_DEBRIS_CHANCE))
		explosion(spot, devastation_range = 0, heavy_impact_range = 1, light_impact_range = 2, adminlog = FALSE, cause = "overmap accretion disk")

#undef BLACK_HOLE_EMP_CHANCE
#undef BLACK_HOLE_DEBRIS_CHANCE
#undef BLACK_HOLE_CORE_BLAST_CHANCE
#undef BLACK_HOLE_CORE_SOUND_VOLUME
#undef BLACK_HOLE_TEAR_DAMAGE
#undef BLACK_HOLE_TEAR_MESSAGE_CHANCE
