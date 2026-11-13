#define STAR_HEAT_CHANCE 45
#define STAR_LIGHTS_CHANCE 20
#define STAR_RADIATION_THRESHOLD 0.3
#define STAR_CORE_BURN 12

/obj/overmap/celestial/star
	name = "star"
	desc = "Звезда главной последовательности. Корона прожигает обшивку, ядро испаряет корабли."
	overmap_kind = OVERMAP_KIND_STAR
	map_color = "#ffd36b"
	var/heat_temperature = 1500
	var/radiation_range = 5

/obj/overmap/celestial/star/get_ru_names()
	return alist(
		NOMINATIVE = "звезда",
		GENITIVE = "звезды",
		DATIVE = "звезде",
		ACCUSATIVE = "звезду",
		INSTRUMENTAL = "звездой",
		PREPOSITIONAL = "звезде",
	)

/obj/overmap/celestial/star/affect_vessel(obj/overmap/entity/vessel, zone)
	var/turf/spot = overmap_vessel_structure_turf(vessel)
	if(!spot)
		return
	if(zone == OVERMAP_CELESTIAL_ZONE_CORE)
		explosion(spot, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 4, flame_range = 5, adminlog = FALSE, cause = "overmap star core")
		for(var/mob/living/crew as anything in overmap_vessel_crew(vessel))
			crew.adjustFireLoss(STAR_CORE_BURN)
		return
	radiation_pulse(spot, max_range = radiation_range, threshold = STAR_RADIATION_THRESHOLD)
	if(prob(STAR_HEAT_CHANCE))
		spot.hotspot_expose(heat_temperature, CELL_VOLUME)
	if(prob(STAR_LIGHTS_CHANCE))
		vessel.flicker_shuttle_lights()

/obj/overmap/celestial/star/red_dwarf
	name = "red dwarf"
	desc = "Тусклый красный карлик. Слабая гравитация, но корона всё равно опасна."
	map_color = "#ff7a52"
	core_radius = 0.7
	hazard_radius = 1.6
	gravity_radius = 4
	gravity_strength = 3e-4
	heat_temperature = 900
	radiation_range = 3

/obj/overmap/celestial/star/red_dwarf/get_ru_names()
	return alist(
		NOMINATIVE = "красный карлик",
		GENITIVE = "красного карлика",
		DATIVE = "красному карлику",
		ACCUSATIVE = "красный карлик",
		INSTRUMENTAL = "красным карликом",
		PREPOSITIONAL = "красном карлике",
	)

/obj/overmap/celestial/star/white_dwarf
	name = "white dwarf"
	desc = "Плотный белый карлик. Маленький, но с сильным притяжением и жёстким излучением."
	map_color = "#e8f1ff"
	core_radius = 0.4
	hazard_radius = 1.2
	gravity_radius = 5
	gravity_strength = 4e-4
	heat_temperature = 1800
	radiation_range = 6

/obj/overmap/celestial/star/white_dwarf/get_ru_names()
	return alist(
		NOMINATIVE = "белый карлик",
		GENITIVE = "белого карлика",
		DATIVE = "белому карлику",
		ACCUSATIVE = "белый карлик",
		INSTRUMENTAL = "белым карликом",
		PREPOSITIONAL = "белом карлике",
	)

/obj/overmap/celestial/star/blue_giant
	name = "blue giant"
	desc = "Огромная голубая звезда. Широкая корона и мощная гравитация — держитесь подальше."
	map_color = "#7fb2ff"
	core_radius = 1.6
	hazard_radius = 3.5
	gravity_radius = 8
	gravity_strength = 1.1e-3
	heat_temperature = 2500
	radiation_range = 7

/obj/overmap/celestial/star/blue_giant/get_ru_names()
	return alist(
		NOMINATIVE = "голубой гигант",
		GENITIVE = "голубого гиганта",
		DATIVE = "голубому гиганту",
		ACCUSATIVE = "голубой гигант",
		INSTRUMENTAL = "голубым гигантом",
		PREPOSITIONAL = "голубом гиганте",
	)

#undef STAR_HEAT_CHANCE
#undef STAR_LIGHTS_CHANCE
#undef STAR_RADIATION_THRESHOLD
#undef STAR_CORE_BURN
