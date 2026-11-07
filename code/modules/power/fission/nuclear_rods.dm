/proc/nuclear_rod_ru_name(rod_type)
	var/static/list/names_by_type = list()
	if(!names_by_type[rod_type])
		var/obj/item/nuclear_rod/rod = new rod_type
		names_by_type[rod_type] = rod.declent_ru(NOMINATIVE)
		qdel(rod)
	return names_by_type[rod_type]

/obj/item/nuclear_rod
	name = "Nuclear Control Rod"
	abstract_type = /obj/item/nuclear_rod
	icon = 'icons/obj/fission/reactor_rods.dmi'
	icon_state = "fuel_238"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE
	w_class = WEIGHT_CLASS_HUGE
	force = 15
	throwforce = 10
	/// The path of the object required to fabricate this rod. leave null for nothing
	var/required_object
	/// How much durability is left before the rod is useless
	var/durability
	/// The maximum amount of durability for this rod. Used for percentage calculations
	var/max_durability = 3000
	/// How fast does this rod degrade? higher = faster
	var/degradation_speed = 1
	/// How much heat does this rod add by default
	var/heat_amount = 0
	/// How does this rod affect its neighbors heating
	var/heat_amp_mod = 1
	/// Holds the current heat mod after durability loss
	var/current_heat_mod
	/// How much power does this rod add by default in watts
	var/power_amount = 0
	/// How does this rod affect its neighbors power production
	var/power_amp_mod = 1
	/// Holds the current power mod after durability loss
	var/current_power_mod
	var/radiation_range = 0
	var/radiation_treshhold = 0
	var/radiation_chance = 0
	/// How much Gamma Rad is emitted by this rod
	var/gamma_rad = 0
	/// What items need to be adjacent to this rod for it to function properly
	var/list/adjacent_requirements = list()
	/// Modifies the reactor's minimum operating temperature.
	var/minimum_temp_modifier = 0
	/// Modified the reactor's overheat threshold
	var/reactor_overheat_modifier = 0
	/// holds our component to modify
	var/datum/component/radioactive_emitter/rad_component
	/// Is this rod craftable at all via fabricators, or do they require other means?
	var/craftable = FALSE
	/// Does this rod require a science-upgraded fabricator?
	var/upgrade_required = FALSE
	var/radioactive

/obj/item/nuclear_rod/get_ru_names()
	return alist(
		NOMINATIVE = "ядерный стержень",
		GENITIVE = "ядерного стержня",
		DATIVE = "ядерному стержню",
		ACCUSATIVE = "ядерный стержень",
		INSTRUMENTAL = "ядерным стержнем",
		PREPOSITIONAL = "ядерном стержне",
	)

/obj/item/nuclear_rod/Initialize(mapload)
	. = ..()
	durability = max_durability
	calc_stat_decrease()

/obj/item/nuclear_rod/examine(mob/user)
	. = ..()
	if(!length(adjacent_requirements))
		. += span_notice("Требований к соседям нет.")
		return
	var/list/requirement_names = list()
	for(var/requirement in adjacent_requirements)
		requirement_names += nuclear_rod_ru_name(requirement)
	. += span_notice("Требуемые соседи: [english_list(requirement_names, and_text = ", ")].")

/obj/item/nuclear_rod/proc/get_rod_class()
	return ROD_CLASS_FUEL

/obj/item/nuclear_rod/proc/get_durability_mod()
	if(max_durability == INFINITY)
		return 1
	return clamp(1.5 * (durability / max_durability) - 0.25, 0.25, 1)

/obj/item/nuclear_rod/proc/get_durability_level()
	if(max_durability == INFINITY)
		return 5
	return clamp(ROUND_UP(((durability / max_durability) * 5) - 0.8), 0, 5)

/obj/item/nuclear_rod/proc/calc_stat_decrease()
	// Formula: y = (x * A) + (1 - A)
	var/durability_stat = get_durability_mod()
	current_power_mod = (power_amp_mod * durability_stat) + (1 - durability_stat)
	current_heat_mod = (heat_amp_mod * durability_stat) + (1 - durability_stat)

/obj/item/nuclear_rod/proc/start_rads(power_modifier = 1)
	rad_component = AddComponent(/datum/component/radioactive_emitter, range = radiation_range * power_modifier, threshold = radiation_treshhold * power_modifier, chance = radiation_chance * power_modifier)

/obj/item/nuclear_rod/proc/stop_rads()
	if(!rad_component)
		return
	rad_component.RemoveComponent()
	QDEL_NULL(rad_component)

/obj/item/nuclear_rod/proc/check_rad_shield()
	var/turf/location = get_turf(src)
	if(!location || !loc)
		stop_rads()
		return
	if(istype(location, /turf/simulated/floor/plasteel/reactor_pool))
		if(!rad_component)
			return
		else
			stop_rads()
	else if(istype(loc, /obj/machinery/atmospherics/reactor_chamber))
		stop_rads()
	else if(!rad_component)
		start_rads()

/obj/item/nuclear_rod/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	check_rad_shield()

/obj/item/nuclear_rod/fuel
	name = "any fuel rod"
	radiation_range = 1
	radiation_chance = 40
	abstract_type = /obj/item/nuclear_rod/fuel

	/// the amount of cycles needed to complete enrichment. 30 = ~1 minute
	var/enrichment_cycles = 25
	/// the total power amp mod needed to enrich
	var/power_enrich_threshold = 0
	/// How far we have progressed from to power enrichment
	var/power_enrich_progress = 0
	/// What power enrichment results in
	var/power_enrich_result
	/// the total heat amp mod needed to enrich
	var/heat_enrich_threshold = 0
	/// How far we have progressed from to power enrichment
	var/heat_enrich_progress = 0
	/// What heat enrichment results in
	var/heat_enrich_result

/obj/item/nuclear_rod/fuel/get_ru_names()
	return alist(
		NOMINATIVE = "топливный стержень",
		GENITIVE = "топливного стержня",
		DATIVE = "топливному стержню",
		ACCUSATIVE = "топливный стержень",
		INSTRUMENTAL = "топливным стержнем",
		PREPOSITIONAL = "топливном стержне",
	)

/obj/item/nuclear_rod/fuel/Initialize(mapload)
	. = ..()
	if(!is_crate(loc))
		check_rad_shield()

/obj/item/nuclear_rod/fuel/proc/enrich(power_mod, heat_mod)
	var/successful_enrichment = FALSE
	if(power_enrich_result)
		if(power_mod > power_enrich_threshold && power_enrich_progress < enrichment_cycles)
			power_enrich_progress++
			successful_enrichment = TRUE
	if(heat_enrich_result)
		if(heat_mod > heat_enrich_threshold && heat_enrich_progress < enrichment_cycles)
			heat_enrich_progress++
			successful_enrichment = TRUE
	return successful_enrichment

// MARK: Fuel Rods

/obj/item/nuclear_rod/fuel/uranium_238
	name = "uranium 238 fuel rod"
	desc = "Стандартное топливо NGCR. Урана-235 в нём ровно столько, чтобы реакция вообще шла."
	heat_amount = 5
	power_amount = 20 KILO WATTS
	heat_amp_mod = 1.8
	power_amp_mod = 1.1
	radiation_range = 4
	radiation_chance = 80
	heat_enrich_threshold = 10 // all uranium rods surrounding: 1.8 x 1.8 x 1.8 x 1.8
	power_enrich_threshold = 6.4 // all graphite rods surrounding: 1.6 x 1.6 x 1.6 x 1.6
	heat_enrich_result = /obj/item/nuclear_rod/fuel/weak_thorium
	power_enrich_result = /obj/item/nuclear_rod/fuel/weak_plutonium
	adjacent_requirements = list(/obj/item/nuclear_rod/moderator)
	craftable = TRUE
	materials = list(MAT_METAL = 2000, MAT_URANIUM = 1000)

/obj/item/nuclear_rod/fuel/uranium_238/get_ru_names()
	return alist(
		NOMINATIVE = "стержень урана-238",
		GENITIVE = "стержня урана-238",
		DATIVE = "стержню урана-238",
		ACCUSATIVE = "стержень урана-238",
		INSTRUMENTAL = "стержнем урана-238",
		PREPOSITIONAL = "стержне урана-238",
	)

/obj/item/nuclear_rod/fuel/weak_thorium
	name = "weak thorium fuel rod"
	desc = "Переработанный уран-238. Служит дольше обычного топлива и греется слабее."
	icon_state = "fuel_weakthor"
	heat_amount = 5
	power_amount = 20 KILO WATTS
	heat_amp_mod = 1.6
	power_amp_mod = 1.1
	max_durability = 5000
	radiation_range = 2
	radiation_chance = 60
	power_enrich_threshold = 8
	power_enrich_result = /obj/item/nuclear_rod/fuel/uranium_235
	adjacent_requirements = list(
		/obj/item/nuclear_rod/moderator,
		/obj/item/nuclear_rod/coolant,
	)

/obj/item/nuclear_rod/fuel/weak_thorium/get_ru_names()
	return alist(
		NOMINATIVE = "стержень обеднённого тория",
		GENITIVE = "стержня обеднённого тория",
		DATIVE = "стержню обеднённого тория",
		ACCUSATIVE = "стержень обеднённого тория",
		INSTRUMENTAL = "стержнем обеднённого тория",
		PREPOSITIONAL = "стержне обеднённого тория",
	)

/obj/item/nuclear_rod/fuel/weak_plutonium
	name = "weak plutonium fuel rod"
	desc = "Переработанный уран-238. Даёт вдвое больше энергии, чем исходник, но требует больше соседей."
	icon_state = "fuel_weakplut"
	heat_amount = 10
	power_amount = 40 KILO WATTS
	heat_amp_mod = 1.6
	power_amp_mod = 1.1
	max_durability = 3500
	radiation_treshhold = RAD_VERY_LIGHT_INSULATION
	radiation_chance = 50
	heat_enrich_threshold = 14
	heat_enrich_result = /obj/item/nuclear_rod/fuel/uranium_235
	adjacent_requirements = list(
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/moderator,
		/obj/item/nuclear_rod/coolant,
	)

/obj/item/nuclear_rod/fuel/weak_plutonium/get_ru_names()
	return alist(
		NOMINATIVE = "стержень обеднённого плутония",
		GENITIVE = "стержня обеднённого плутония",
		DATIVE = "стержню обеднённого плутония",
		ACCUSATIVE = "стержень обеднённого плутония",
		INSTRUMENTAL = "стержнем обеднённого плутония",
		PREPOSITIONAL = "стержне обеднённого плутония",
	)

/obj/item/nuclear_rod/fuel/uranium_235
	name = "uranium 235 fuel rod"
	desc = "Высокоплотное урановое топливо. Основа мощных конфигураций NGCR."
	icon_state = "fuel_235"
	heat_amount = 20
	power_amount = 50 KILO WATTS
	heat_amp_mod = 2.2
	power_amp_mod = 1.3
	max_durability = 5000
	radiation_range = 3
	radiation_chance = 70
	heat_enrich_threshold = 25
	power_enrich_threshold = 18
	heat_enrich_result = /obj/item/nuclear_rod/fuel/thorium_salts
	power_enrich_result = /obj/item/nuclear_rod/fuel/enriched_plutonium
	origin_tech = "toxins=2"
	craftable = TRUE
	upgrade_required = TRUE
	adjacent_requirements = list(
		/obj/item/nuclear_rod/coolant/plasma_injector,
		/obj/item/nuclear_rod/moderator,
		/obj/item/nuclear_rod/moderator,
	)
	materials = list(MAT_METAL = 4000, MAT_URANIUM = 4000)

/obj/item/nuclear_rod/fuel/uranium_235/get_ru_names()
	return alist(
		NOMINATIVE = "стержень урана-235",
		GENITIVE = "стержня урана-235",
		DATIVE = "стержню урана-235",
		ACCUSATIVE = "стержень урана-235",
		INSTRUMENTAL = "стержнем урана-235",
		PREPOSITIONAL = "стержне урана-235",
	)

/obj/item/nuclear_rod/fuel/thorium_salts
	name = "thorium salts fuel rod"
	desc = "Продукт обогащения урана-235. Мощность скромная, зато ресурса хватит на всю смену, если удастся удержать тепло."
	icon_state = "fuel_richthor"
	heat_amount = 40
	power_amount = 35 KILO WATTS
	heat_amp_mod = 2.2
	power_amp_mod = 1.3
	max_durability = 15000
	radiation_range = 4
	radiation_chance = 80
	adjacent_requirements = list(
		/obj/item/nuclear_rod/moderator,
		/obj/item/nuclear_rod/fuel/uranium_235,
		/obj/item/nuclear_rod/fuel,
	)

/obj/item/nuclear_rod/fuel/thorium_salts/get_ru_names()
	return alist(
		NOMINATIVE = "стержень ториевых солей",
		GENITIVE = "стержня ториевых солей",
		DATIVE = "стержню ториевых солей",
		ACCUSATIVE = "стержень ториевых солей",
		INSTRUMENTAL = "стержнем ториевых солей",
		PREPOSITIONAL = "стержне ториевых солей",
	)

/obj/item/nuclear_rod/fuel/enriched_plutonium
	name = "enriched plutonium fuel rod"
	desc = "Продукт обогащения урана-235. Высокая мощность при умеренном ресурсе, но тепловыделение по-настоящему опасно."
	icon_state = "fuel_richplut"
	heat_amount = 60
	power_amount = 75 KILO WATTS
	heat_amp_mod = 4
	power_amp_mod = 1.6
	max_durability = 5000
	radiation_range = 4
	radiation_chance = 80
	power_enrich_threshold = 25
	power_enrich_result = /obj/item/nuclear_rod/fuel/americium
	adjacent_requirements = list(
		/obj/item/nuclear_rod/moderator/plasma_agitator,
		/obj/item/nuclear_rod/fuel/thorium_salts,
	)

/obj/item/nuclear_rod/fuel/enriched_plutonium/get_ru_names()
	return alist(
		NOMINATIVE = "стержень обогащённого плутония",
		GENITIVE = "стержня обогащённого плутония",
		DATIVE = "стержню обогащённого плутония",
		ACCUSATIVE = "стержень обогащённого плутония",
		INSTRUMENTAL = "стержнем обогащённого плутония",
		PREPOSITIONAL = "стержне обогащённого плутония",
	)

/obj/item/nuclear_rod/fuel/supermatter
	name = "supermatter fuel rod"
	desc = "Суперматерия в защитном корпусе. Греет за десятерых и почти полностью гасит мощность соседних стержней."
	icon_state = "fuel_sm"
	heat_amount = 1200
	power_amount = 800 KILO WATTS
	heat_amp_mod = 8
	power_amp_mod = 0.1
	max_durability = INFINITY
	radiation_treshhold = RAD_MEDIUM_INSULATION
	radiation_chance = 50
	adjacent_requirements = list(
		/obj/item/nuclear_rod/coolant/steam_hammerjet,
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/moderator,
	)

/obj/item/nuclear_rod/fuel/supermatter/get_ru_names()
	return alist(
		NOMINATIVE = "стержень суперматерии",
		GENITIVE = "стержня суперматерии",
		DATIVE = "стержню суперматерии",
		ACCUSATIVE = "стержень суперматерии",
		INSTRUMENTAL = "стержнем суперматерии",
		PREPOSITIONAL = "стержне суперматерии",
	)

/obj/item/nuclear_rod/fuel/americium
	name = "americium fuel rod"
	desc = "Продукт обогащения плутония. Почти непревзойдённая мощность, если справиться с чудовищным теплом."
	icon_state = "fuel_americium"
	heat_amount = 100
	power_amount = 200 KILO WATTS
	heat_amp_mod = 6
	power_amp_mod = 3
	max_durability = 4000
	radiation_treshhold = RAD_MEDIUM_INSULATION
	radiation_chance = 50
	adjacent_requirements = list(
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/fuel,
	)

/obj/item/nuclear_rod/fuel/americium/get_ru_names()
	return alist(
		NOMINATIVE = "стержень америция",
		GENITIVE = "стержня америция",
		DATIVE = "стержню америция",
		ACCUSATIVE = "стержень америция",
		INSTRUMENTAL = "стержнем америция",
		PREPOSITIONAL = "стержне америция",
	)

/obj/item/nuclear_rod/fuel/bananium
	name = "bananium fuel rod"
	desc = "Топливо без постоянных свойств: ресурс, мощность и тепло у каждого экземпляра свои."
	icon_state = "fuel_clown"
	radiation_treshhold = RAD_MEDIUM_INSULATION
	radiation_chance = 50
	craftable = TRUE
	upgrade_required = TRUE
	materials = list(MAT_TITANIUM = 2000, MAT_BANANIUM = 2000)

/obj/item/nuclear_rod/fuel/bananium/get_ru_names()
	return alist(
		NOMINATIVE = "стержень бананиума",
		GENITIVE = "стержня бананиума",
		DATIVE = "стержню бананиума",
		ACCUSATIVE = "стержень бананиума",
		INSTRUMENTAL = "стержнем бананиума",
		PREPOSITIONAL = "стержне бананиума",
	)

/obj/item/nuclear_rod/fuel/bananium/Initialize(mapload)
	max_durability = rand(1000, 10000)
	power_amp_mod = rand(1, 40) / 10
	heat_amp_mod = rand(5, 80) / 10
	power_amount = rand(10 KILO WATTS, 200 KILO WATTS)
	heat_amount = rand(10, 500)
	return ..()

/obj/item/nuclear_rod/fuel/meltdown
	name = "meltdown rod"
	desc = "Изделие Синдиката. Выделяет столько тепла и так снижает порог перегрева, что расплав становится вопросом времени."
	icon_state = "fuel_syndie"
	heat_amount = 2000
	max_durability = INFINITY
	minimum_temp_modifier = 4000 // BIG hot
	reactor_overheat_modifier = -400
	radiation_range = 5
	radiation_chance = 80
	var/disguise_class

/obj/item/nuclear_rod/fuel/meltdown/Initialize(mapload)
	. = ..()
	var/disguise_type = pick(valid_subtypesof(/obj/item/nuclear_rod) - type)
	var/obj/item/nuclear_rod/disguise = new disguise_type
	name = disguise.name
	desc = disguise.desc
	icon_state = disguise.icon_state
	ru_names = disguise.get_ru_names_cached().Copy()
	adjacent_requirements = disguise.adjacent_requirements.Copy()
	disguise_class = disguise.get_rod_class()
	qdel(disguise)

/obj/item/nuclear_rod/fuel/meltdown/get_rod_class()
	return disguise_class

/obj/item/nuclear_rod/fuel/meltdown/get_ru_names()
	return alist(
		NOMINATIVE = "стержень расплава",
		GENITIVE = "стержня расплава",
		DATIVE = "стержню расплава",
		ACCUSATIVE = "стержень расплава",
		INSTRUMENTAL = "стержнем расплава",
		PREPOSITIONAL = "стержне расплава",
	)

// MARK: Moderator Rods

/obj/item/nuclear_rod/moderator
	name = "any moderator rod"
	abstract_type = /obj/item/nuclear_rod/moderator
	icon_state = "mod_water"

/obj/item/nuclear_rod/moderator/get_rod_class()
	return ROD_CLASS_MODERATOR

/obj/item/nuclear_rod/moderator/get_ru_names()
	return alist(
		NOMINATIVE = "замедлитель",
		GENITIVE = "замедлителя",
		DATIVE = "замедлителю",
		ACCUSATIVE = "замедлитель",
		INSTRUMENTAL = "замедлителем",
		PREPOSITIONAL = "замедлителе",
	)

/obj/item/nuclear_rod/moderator/heavy_water
	name = "heavy water moderator"
	desc = "Простейший замедлитель на дейтериевой воде. Умеренно усиливает мощность соседнего топлива."
	heat_amp_mod = 1.1
	power_amp_mod = 1.4
	craftable = TRUE
	materials = list(MAT_METAL = 2000, MAT_GLASS = 1000)

/obj/item/nuclear_rod/moderator/heavy_water/get_ru_names()
	return alist(
		NOMINATIVE = "замедлитель на тяжёлой воде",
		GENITIVE = "замедлителя на тяжёлой воде",
		DATIVE = "замедлителю на тяжёлой воде",
		ACCUSATIVE = "замедлитель на тяжёлой воде",
		INSTRUMENTAL = "замедлителем на тяжёлой воде",
		PREPOSITIONAL = "замедлителе на тяжёлой воде",
	)

/obj/item/nuclear_rod/moderator/graphite
	name = "graphite moderator"
	desc = "Слоистый графит, классика реакторостроения. Сильнее тяжёлой воды, но без охладителя рядом не работает."
	icon_state = "mod_graphite"
	heat_amp_mod = 1.3
	power_amp_mod = 1.6
	craftable = TRUE
	materials = list(MAT_METAL = 4000, MAT_PLASMA = 2000)
	adjacent_requirements = list(/obj/item/nuclear_rod/coolant)

/obj/item/nuclear_rod/moderator/graphite/get_ru_names()
	return alist(
		NOMINATIVE = "графитовый замедлитель",
		GENITIVE = "графитового замедлителя",
		DATIVE = "графитовому замедлителю",
		ACCUSATIVE = "графитовый замедлитель",
		INSTRUMENTAL = "графитовым замедлителем",
		PREPOSITIONAL = "графитовом замедлителе",
	)

/obj/item/nuclear_rod/moderator/titanium
	name = "titanium moderator"
	desc = "Литой титан. Неплохо усиливает мощность, при этом охлаждает соседей и служит очень долго."
	icon_state = "mod_titanium"
	max_durability = 5500
	heat_amp_mod = 0.7
	power_amp_mod = 1.5
	craftable = TRUE
	materials = list(MAT_METAL = 2000, MAT_TITANIUM = 2000)

/obj/item/nuclear_rod/moderator/titanium/get_ru_names()
	return alist(
		NOMINATIVE = "титановый замедлитель",
		GENITIVE = "титанового замедлителя",
		DATIVE = "титановому замедлителю",
		ACCUSATIVE = "титановый замедлитель",
		INSTRUMENTAL = "титановым замедлителем",
		PREPOSITIONAL = "титановом замедлителе",
	)

/obj/item/nuclear_rod/moderator/plasma_agitator
	name = "plasma agitator"
	desc = "Разгоняет деление в соседнем топливе серией плазменных микровспышек. Изнашивается быстро."
	icon_state = "mod_plasma"
	max_durability = 2250
	heat_amount = 20
	heat_amp_mod = 5
	power_amp_mod = 3
	adjacent_requirements = list(
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/moderator,
	)

/obj/item/nuclear_rod/moderator/plasma_agitator/get_ru_names()
	return alist(
		NOMINATIVE = "плазменный активатор",
		GENITIVE = "плазменного активатора",
		DATIVE = "плазменному активатору",
		ACCUSATIVE = "плазменный активатор",
		INSTRUMENTAL = "плазменным активатором",
		PREPOSITIONAL = "плазменном активаторе",
	)

/obj/item/nuclear_rod/moderator/aluminum_reflector
	name = "liquid aluminum plate reflector"
	desc = "Жидкий алюминий сильно усиливает соседнее топливо, но держит реактор горячим и сам потребляет энергию."
	icon_state = "mod_aluminium"
	max_durability = 6000
	power_amount = -15 KILO WATTS
	heat_amp_mod = 5
	power_amp_mod = 3
	minimum_temp_modifier = 400
	reactor_overheat_modifier = 100
	adjacent_requirements = list(
		/obj/item/nuclear_rod/coolant/nitrogen_circulator,
		/obj/item/nuclear_rod/moderator,
	)

/obj/item/nuclear_rod/moderator/aluminum_reflector/get_ru_names()
	return alist(
		NOMINATIVE = "алюминиевый отражатель",
		GENITIVE = "алюминиевого отражателя",
		DATIVE = "алюминиевому отражателю",
		ACCUSATIVE = "алюминиевый отражатель",
		INSTRUMENTAL = "алюминиевым отражателем",
		PREPOSITIONAL = "алюминиевом отражателе",
	)

/obj/item/nuclear_rod/moderator/bluespace_agitator
	name = "bluespace crystal agitator"
	desc = "Вытягивает нейтроны из блюспейса и обстреливает ими соседнее топливо. Огромный прирост мощности и тепла ценой собственного энергопотребления."
	icon_state = "mod_bluespace"
	max_durability = 4000
	power_amount = -30 KILO WATTS
	heat_amp_mod = 12
	power_amp_mod = 5
	upgrade_required = TRUE
	craftable = TRUE
	materials = list(MAT_METAL = 2000, MAT_TITANIUM = 1000, MAT_BLUESPACE = 1000)

/obj/item/nuclear_rod/moderator/bluespace_agitator/get_ru_names()
	return alist(
		NOMINATIVE = "блюспейс-активатор",
		GENITIVE = "блюспейс-активатора",
		DATIVE = "блюспейс-активатору",
		ACCUSATIVE = "блюспейс-активатор",
		INSTRUMENTAL = "блюспейс-активатором",
		PREPOSITIONAL = "блюспейс-активаторе",
	)

/obj/item/nuclear_rod/moderator/diamond_plate
	name = "diamond reflector plates"
	desc = "Алмазные пластины отражают почти все нейтроны обратно в топливо. Стабильный и надёжный усилитель."
	icon_state = "mod_diamond"
	max_durability = 6000
	heat_amp_mod = 6.5
	power_amp_mod = 3.3
	reactor_overheat_modifier = 100
	craftable = TRUE
	upgrade_required = TRUE
	materials = list(MAT_METAL = 2000, MAT_TITANIUM = 1000, MAT_DIAMOND = 1000)
	adjacent_requirements = list(
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/fuel,
	)

/obj/item/nuclear_rod/moderator/diamond_plate/get_ru_names()
	return alist(
		NOMINATIVE = "алмазный отражатель",
		GENITIVE = "алмазного отражателя",
		DATIVE = "алмазному отражателю",
		ACCUSATIVE = "алмазный отражатель",
		INSTRUMENTAL = "алмазным отражателем",
		PREPOSITIONAL = "алмазном отражателе",
	)

/obj/item/nuclear_rod/moderator/platinum_plating
	name = "platinum reflector plating"
	desc = "Платиновое покрытие поверх алмазных пластин. Сильнее алмазного отражателя и повышает порог перегрева."
	icon_state = "mod_platinum"
	max_durability = 8000
	heat_amp_mod = 8
	power_amp_mod = 3.9
	reactor_overheat_modifier = 300
	adjacent_requirements = list(/obj/item/nuclear_rod/fuel/americium)

/obj/item/nuclear_rod/moderator/platinum_plating/get_ru_names()
	return alist(
		NOMINATIVE = "платиновый отражатель",
		GENITIVE = "платинового отражателя",
		DATIVE = "платиновому отражателю",
		ACCUSATIVE = "платиновый отражатель",
		INSTRUMENTAL = "платиновым отражателем",
		PREPOSITIONAL = "платиновом отражателе",
	)

/// MARK: Coolant Rods

/obj/item/nuclear_rod/coolant
	name = "any coolant rod"
	abstract_type = /obj/item/nuclear_rod/coolant
	icon_state = "coolant_water"

/obj/item/nuclear_rod/coolant/get_rod_class()
	return ROD_CLASS_COOLANT

/obj/item/nuclear_rod/coolant/get_ru_names()
	return alist(
		NOMINATIVE = "охладитель",
		GENITIVE = "охладителя",
		DATIVE = "охладителю",
		ACCUSATIVE = "охладитель",
		INSTRUMENTAL = "охладителем",
		PREPOSITIONAL = "охладителе",
	)

/obj/item/nuclear_rod/coolant/light_water
	name = "light water circulator"
	desc = "Базовый охладитель: прокачивает дистиллированную воду через активную зону и немного поднимает порог перегрева."
	heat_amount = -10
	power_amount = -10 KILO WATTS
	reactor_overheat_modifier = 25
	craftable = TRUE
	adjacent_requirements = list(/obj/item/nuclear_rod/moderator)
	materials = list(MAT_METAL = 2000, MAT_GLASS = 1000)

/obj/item/nuclear_rod/coolant/light_water/get_ru_names()
	return alist(
		NOMINATIVE = "водяной циркулятор",
		GENITIVE = "водяного циркулятора",
		DATIVE = "водяному циркулятору",
		ACCUSATIVE = "водяной циркулятор",
		INSTRUMENTAL = "водяным циркулятором",
		PREPOSITIONAL = "водяном циркуляторе",
	)

/obj/item/nuclear_rod/coolant/co2_regulator
	name = "carbon dioxide regulator"
	desc = "Сглаживает тепловые всплески в соседнем топливе за счёт углекислого газа. Крайне прожорлив по энергии."
	icon_state = "coolant_carbon"
	heat_amount = -4
	heat_amp_mod = 0.6
	power_amount = -15 KILO WATTS
	craftable = TRUE
	adjacent_requirements = list(/obj/item/nuclear_rod/moderator)
	materials = list(MAT_METAL = 2000, MAT_PLASMA = 2000, MAT_GLASS = 1000)

/obj/item/nuclear_rod/coolant/co2_regulator/get_ru_names()
	return alist(
		NOMINATIVE = "углекислотный регулятор",
		GENITIVE = "углекислотного регулятора",
		DATIVE = "углекислотному регулятору",
		ACCUSATIVE = "углекислотный регулятор",
		INSTRUMENTAL = "углекислотным регулятором",
		PREPOSITIONAL = "углекислотном регуляторе",
	)

/obj/item/nuclear_rod/coolant/plasma_injector
	name = "plasma injector"
	desc = "Впрыскивает плазму вокруг топлива: гасит лишнее тепло и заодно усиливает мощность. Баллон кончается быстро."
	icon_state = "coolant_plasma"
	max_durability = 1900
	heat_amp_mod = 0.5
	power_amp_mod = 1.5
	craftable = TRUE
	adjacent_requirements = list(/obj/item/nuclear_rod/coolant)
	materials = list(MAT_METAL = 2000, MAT_PLASMA = 2000, MAT_GLASS = 1000)

/obj/item/nuclear_rod/coolant/plasma_injector/get_ru_names()
	return alist(
		NOMINATIVE = "плазменный инжектор",
		GENITIVE = "плазменного инжектора",
		DATIVE = "плазменному инжектору",
		ACCUSATIVE = "плазменный инжектор",
		INSTRUMENTAL = "плазменным инжектором",
		PREPOSITIONAL = "плазменном инжекторе",
	)

/obj/item/nuclear_rod/coolant/nitrogen_circulator
	name = "nitrogen circulator"
	desc = "Азотный охладитель. Не самый мощный, зато не требует соседей и служит дольше аналогов."
	icon_state = "coolant_nitrogen"
	max_durability = 3500
	heat_amount = -10
	power_amp_mod = 0.9
	heat_amp_mod = 0.7
	craftable = TRUE
	reactor_overheat_modifier = 50
	power_amount = -5 KILO WATTS
	materials = list(MAT_METAL = 2000, MAT_PLASMA = 2000, MAT_GLASS = 1000)

/obj/item/nuclear_rod/coolant/nitrogen_circulator/get_ru_names()
	return alist(
		NOMINATIVE = "азотный циркулятор",
		GENITIVE = "азотного циркулятора",
		DATIVE = "азотному циркулятору",
		ACCUSATIVE = "азотный циркулятор",
		INSTRUMENTAL = "азотным циркулятором",
		PREPOSITIONAL = "азотном циркуляторе",
	)

/obj/item/nuclear_rod/coolant/molten_salt
	name = "molten salt circulator"
	desc = "Гонит расплав солей через активную зону. Не даёт реактору остыть ниже 750 K, но выше этой температуры охлаждает превосходно."
	icon_state = "coolant_salt"
	power_amount = -20 KILO WATTS
	heat_amount = -60
	heat_amp_mod = 0.8
	max_durability = 8000
	minimum_temp_modifier = 750
	reactor_overheat_modifier = 100
	materials = list(MAT_METAL = 2000, MAT_PLASMA = 2000, MAT_GLASS = 1000)
	adjacent_requirements = list(
		/obj/item/nuclear_rod/coolant/nitrogen_circulator,
		/obj/item/nuclear_rod/moderator,
		/obj/item/nuclear_rod/fuel,
		/obj/item/nuclear_rod/fuel,
	)

/obj/item/nuclear_rod/coolant/molten_salt/get_ru_names()
	return alist(
		NOMINATIVE = "солевой циркулятор",
		GENITIVE = "солевого циркулятора",
		DATIVE = "солевому циркулятору",
		ACCUSATIVE = "солевой циркулятор",
		INSTRUMENTAL = "солевым циркулятором",
		PREPOSITIONAL = "солевом циркуляторе",
	)

/obj/item/nuclear_rod/coolant/steam_hammerjet
	name = "steam hammerjet"
	desc = "Впрыскивает пар в активную зону. Держит реактор не ниже 450 K, зато очень хорошо подавляет нагрев соседей."
	icon_state = "coolant_steam"
	power_amount = -10 KILO WATTS
	heat_amount = -40
	heat_amp_mod = 0.4
	max_durability = 6000
	minimum_temp_modifier = 450
	reactor_overheat_modifier = 100
	adjacent_requirements = list(
		/obj/item/nuclear_rod/coolant/light_water,
		/obj/item/nuclear_rod/coolant/light_water,
	)

/obj/item/nuclear_rod/coolant/steam_hammerjet/get_ru_names()
	return alist(
		NOMINATIVE = "паровой инжектор",
		GENITIVE = "парового инжектора",
		DATIVE = "паровому инжектору",
		ACCUSATIVE = "паровой инжектор",
		INSTRUMENTAL = "паровым инжектором",
		PREPOSITIONAL = "паровом инжекторе",
	)

/obj/item/nuclear_rod/coolant/bluespace_displacer
	name = "bluespace heat displacer"
	desc = "Вытягивает тепло из соседних стержней и отправляет его куда-то через блюспейс. Не изнашивается, но работает только рядом с блюспейс-активатором."
	icon_state = "coolant_bluespace"
	power_amount = -40 KILO WATTS
	heat_amount = -100
	heat_amp_mod = 0.8
	power_amp_mod = 1.3
	max_durability = INFINITY
	reactor_overheat_modifier = 200
	craftable = TRUE
	upgrade_required = TRUE
	materials = list(MAT_METAL = 2000, MAT_PLASMA = 2000, MAT_BLUESPACE = 1000)
	adjacent_requirements = list(/obj/item/nuclear_rod/moderator/bluespace_agitator)

/obj/item/nuclear_rod/coolant/bluespace_displacer/get_ru_names()
	return alist(
		NOMINATIVE = "блюспейс-теплоотвод",
		GENITIVE = "блюспейс-теплоотвода",
		DATIVE = "блюспейс-теплоотводу",
		ACCUSATIVE = "блюспейс-теплоотвод",
		INSTRUMENTAL = "блюспейс-теплоотводом",
		PREPOSITIONAL = "блюспейс-теплоотводе",
	)

/obj/item/nuclear_rod/coolant/iridium_conductor
	name = "iridium conductor coolant rod"
	desc = "Иридиевый стержень с исключительной теплопроводностью. Почти полностью гасит нагрев соседей и сильно поднимает порог перегрева."
	icon_state = "coolant_iridium"
	heat_amp_mod = 0.1
	max_durability = 10000
	reactor_overheat_modifier = 300
	adjacent_requirements = list(
		/obj/item/nuclear_rod/moderator/aluminum_reflector,
		/obj/item/nuclear_rod/fuel/uranium_235,
	)

/obj/item/nuclear_rod/coolant/iridium_conductor/get_ru_names()
	return alist(
		NOMINATIVE = "иридиевый проводник",
		GENITIVE = "иридиевого проводника",
		DATIVE = "иридиевому проводнику",
		ACCUSATIVE = "иридиевый проводник",
		INSTRUMENTAL = "иридиевым проводником",
		PREPOSITIONAL = "иридиевом проводнике",
	)

/obj/item/nuclear_rod/coolant/condensed_spacematter
	name = "condensed spacematter coolant rod"
	desc = "Чем он заполнен, неизвестно, но тепло он гасит как ничто другое. Разрушается от контакта с чем угодно, кроме своей камеры."
	icon_state = "coolant_spacematter"
	heat_amount = -1500
	heat_amp_mod = 0.2
	materials = list(MAT_METAL = 6000, MAT_PLASMA = 4000, MAT_TITANIUM = 2000)
	craftable = TRUE
	upgrade_required = TRUE
	adjacent_requirements = list(
		/obj/item/nuclear_rod/fuel/enriched_plutonium,
		/obj/item/nuclear_rod/fuel/thorium_salts,
	)

/obj/item/nuclear_rod/coolant/condensed_spacematter/get_ru_names()
	return alist(
		NOMINATIVE = "стержень космоматерии",
		GENITIVE = "стержня космоматерии",
		DATIVE = "стержню космоматерии",
		ACCUSATIVE = "стержень космоматерии",
		INSTRUMENTAL = "стержнем космоматерии",
		PREPOSITIONAL = "стержне космоматерии",
	)
