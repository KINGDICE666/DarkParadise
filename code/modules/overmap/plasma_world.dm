#define PLASMA_WORLD_EDGE 4
#define PLASMA_WORLD_CLEARING 42
#define PLASMA_WORLD_ROCK_CHANCE "40"
#define PLASMA_WORLD_VEIN_CHANCE "44"
#define PLASMA_WORLD_CRYSTAL_CHANCE 4
#define PLASMA_WORLD_MOB_CHANCE 0.3
#define PLASMA_WORLD_MOB_CLEARANCE 12
#define PLASMA_WORLD_HULL_GAP 3
#define PLASMA_WORLD_STATION_FALL_TIME (20 SECONDS)
#define PLASMA_WORLD_STATION_JOLTS 8
#define PLASMA_WORLD_STATION_BLASTS 14
#define PLASMA_WORLD_STATION_DAMAGE 40
#define PLASMA_WORLD_PULL_RANGE 60
#define PLASMA_WORLD_PULL_ACCEL 7
#define PLASMA_WORLD_ALARM_EVERY (10 SECONDS)
#define PLASMA_WORLD_EMP_CHANCE 35
#define PLASMA_WORLD_LANDING_TIME (10 SECONDS)
#define PLASMA_WORLD_LANDING_SHAKES 5
#define PLASMA_WORLD_CLOUD_TILE 480
#define PLASMA_WORLD_CLOUD_ALPHA 95
#define PLASMA_WORLD_CLOUD_DRIFT (90 SECONDS)
#define PLASMA_WORLD_CHASMS 16
#define PLASMA_WORLD_CHASM_RADIUS_MIN 2
#define PLASMA_WORLD_CHASM_RADIUS_MAX 4
#define PLASMA_WORLD_GEYSER_CHANCE 0.05
#define PLASMA_WORLD_CHARGED_CHANCE 8
#define PLASMA_WORLD_BOSS_DISTANCE 80
#define PLASMA_WORLD_BOSS_ARENA 7

/area/plasma_world
	name = "Plasma world"
	icon_state = "mining"
	has_gravity = STANDARD_GRAVITY
	sound_environment = SOUND_AREA_LAVALAND
	ambient_buzz = 'sound/ambience/plasma_world/plasma_wind.ogg'
	ambient_buzz_vol = 45
	always_unpowered = TRUE
	poweralm = FALSE
	power_environ = FALSE
	power_equip = FALSE
	power_light = FALSE
	outdoors = TRUE
	area_flags = NONE
	holomap_should_draw = FALSE
	static_lighting = FALSE
	base_lighting_alpha = 170
	base_lighting_color = "#b896e0"

/turf/simulated/floor/plating/asteroid/basalt/plasma_world
	name = "violet rock"
	desc = "Шершавый фиолетовый камень, изъеденный кислотой."
	icon = 'icons/turf/floors/plasma_world.dmi'
	baseturf = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	turf_type = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD

/turf/simulated/floor/plating/asteroid/basalt/plasma_world/update_visuals(use_initial_air = FALSE)
	return

/turf/simulated/floor/plating/asteroid/basalt/plasma_world/get_ru_names()
	return alist(
		NOMINATIVE = "фиолетовый камень",
		GENITIVE = "фиолетового камня",
		DATIVE = "фиолетовому камню",
		ACCUSATIVE = "фиолетовый камень",
		INSTRUMENTAL = "фиолетовым камнем",
		PREPOSITIONAL = "фиолетовом камне",
	)

/turf/simulated/mineral/random/plasma_world
	icon = 'icons/turf/walls/violet_rock.dmi'
	should_reset_color = FALSE
	environment_type = "basalt"
	turf_type = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	baseturf = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD
	defer_change = 1
	mineralChance = 22
	mineralSpawnChanceList = list(
		/turf/simulated/mineral/plasma/plasma_world = 60,
		/turf/simulated/mineral/iron/plasma_world = 18,
		/turf/simulated/mineral/titanium/plasma_world = 10,
		/turf/simulated/mineral/uranium/plasma_world = 6,
		/turf/simulated/mineral/silver/plasma_world = 6,
	)

/turf/simulated/mineral/plasma/plasma_world
	icon = 'icons/turf/walls/violet_rock.dmi'
	should_reset_color = FALSE
	environment_type = "basalt"
	turf_type = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	baseturf = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD
	defer_change = 1

/turf/simulated/mineral/plasma/plasma_world/crystal
	name = "plasma crystal"
	icon = 'icons/turf/walls/plasma_rock.dmi'
	mineralAmt = 5
	spread = 0
	spreadChance = 0

/turf/simulated/mineral/plasma/plasma_world/crystal/get_ru_names()
	return alist(
		NOMINATIVE = "плазменный кристалл",
		GENITIVE = "плазменного кристалла",
		DATIVE = "плазменному кристаллу",
		ACCUSATIVE = "плазменный кристалл",
		INSTRUMENTAL = "плазменным кристаллом",
		PREPOSITIONAL = "плазменном кристалле",
	)

/turf/simulated/mineral/iron/plasma_world
	icon = 'icons/turf/walls/violet_rock.dmi'
	should_reset_color = FALSE
	environment_type = "basalt"
	turf_type = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	baseturf = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD
	defer_change = 1

/turf/simulated/mineral/titanium/plasma_world
	icon = 'icons/turf/walls/violet_rock.dmi'
	should_reset_color = FALSE
	environment_type = "basalt"
	turf_type = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	baseturf = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD
	defer_change = 1

/turf/simulated/mineral/uranium/plasma_world
	icon = 'icons/turf/walls/violet_rock.dmi'
	should_reset_color = FALSE
	environment_type = "basalt"
	turf_type = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	baseturf = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD
	defer_change = 1

/turf/simulated/mineral/silver/plasma_world
	icon = 'icons/turf/walls/violet_rock.dmi'
	should_reset_color = FALSE
	environment_type = "basalt"
	turf_type = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	baseturf = /turf/simulated/floor/plating/asteroid/basalt/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD
	defer_change = 1

/obj/structure/flora/plasma_crystal
	name = "plasma crystal cluster"
	desc = "Друза кристаллической плазмы. Излучает слабоватое свечение."
	icon = 'icons/obj/flora/plasma_crystals.dmi'
	icon_state = "plasma_crystal1"
	anchored = TRUE
	density = TRUE
	max_integrity = 120
	resistance_flags = FIRE_PROOF | LAVA_PROOF | ACID_PROOF
	light_range = 2
	light_power = 0.7
	light_color = "#d070ff"
	var/variant = 1
	var/crystal_kind = "plasma"
	var/crystal_variants = 4

/obj/structure/flora/plasma_crystal/get_ru_names()
	return alist(
		NOMINATIVE = "друза плазмы",
		GENITIVE = "друзы плазмы",
		DATIVE = "друзе плазмы",
		ACCUSATIVE = "друзу плазмы",
		INSTRUMENTAL = "друзой плазмы",
		PREPOSITIONAL = "друзе плазмы",
	)

/obj/structure/flora/plasma_crystal/Initialize(mapload)
	. = ..()
	variant = rand(1, crystal_variants)
	icon_state = "[crystal_kind]_crystal[variant]"
	update_appearance(UPDATE_OVERLAYS)
	start_glow()

/obj/structure/flora/plasma_crystal/update_overlays()
	. = ..()
	. += emissive_appearance(icon, "[crystal_kind]_crystal[variant]_glow", src)

/obj/structure/flora/plasma_crystal/deconstruct(disassembled = TRUE)
	new /obj/item/stack/ore/plasma(get_turf(src), rand(3, 6))
	return ..()

/mob/living/simple_animal/hostile/asteroid/crystal_plasmaman
	name = "crystal plasmaman"
	desc = "Дикий плазмамен. Выше обычного... Выглядит агрессивно."
	icon = 'icons/mob/crystal_plasmaman.dmi'
	icon_state = "crystal_plasmaman"
	icon_living = "crystal_plasmaman"
	icon_aggro = "crystal_plasmaman"
	icon_dead = "crystal_plasmaman_dead"
	faction = list(FACTION_PLASMA_WORLD)
	vision_range = 6
	maxHealth = 150
	health = 150
	melee_damage_lower = 14
	melee_damage_upper = 20
	attacktext = "полосует кристаллами"
	attack_sound = 'sound/effects/glassbr1.ogg'
	speak_emote = list("звенит")
	light_range = 2
	light_power = 0.6
	light_color = "#d070ff"
	butcher_results = list(/obj/item/stack/ore/plasma = 4)
	has_laser_resist = FALSE

/mob/living/simple_animal/hostile/asteroid/crystal_plasmaman/get_ru_names()
	return alist(
		NOMINATIVE = "кристаллический плазмамен",
		GENITIVE = "кристаллического плазмамена",
		DATIVE = "кристаллическому плазмамену",
		ACCUSATIVE = "кристаллического плазмамена",
		INSTRUMENTAL = "кристаллическим плазменом",
		PREPOSITIONAL = "кристаллическом плазмамене",
	)

/mob/living/simple_animal/hostile/asteroid/crystal_plasmaman/Initialize(mapload)
	. = ..()
	transform = transform.Scale(1.15)

/datum/weather/acid_rain
	name = "acid rain"
	desc = "Из фиолетовых туч льёт кислотой, разъедающей всё живое."
	telegraph_message = span_boldwarning_alt("Тучи наливаются ядовитой зеленью. Скоро хлынет кислотный дождь — ищите укрытие!")
	telegraph_overlay = "acid_drizzle"
	weather_message = span_userdanger_alt("<i>Кислотный дождь обжигает кожу и разъедает снаряжение!</i>")
	weather_overlay = "acid_rain"
	weather_duration_lower = 60 SECONDS
	weather_duration_upper = 120 SECONDS
	end_message = span_boldannounceic_alt("Кислотный дождь стихает.")
	end_overlay = "acid_drizzle"
	area_type = /area/plasma_world
	target_trait = ZTRAIT_ACID_RAIN
	probability = 90
	barometer_predictable = TRUE

/datum/weather/acid_rain/can_weather_act(mob/living/mob_to_check)
	. = ..()
	if(. && (FACTION_PLASMA_WORLD in mob_to_check.faction))
		return FALSE

/datum/weather/acid_rain/weather_act(mob/living/target)
	if(!ishuman(target) || (!target.mind && target.stat == DEAD))
		target.adjustFireLoss(3)
		return
	var/mob/living/carbon/human/human_target = target
	for(var/zone in list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		if(human_target.get_organ(zone))
			human_target.apply_damage((1 - human_target.getarmor(zone, ACID) / 100) * 0.7, BURN, zone)

/obj/overmap/planet/violet
	name = "violet planet"
	desc = "Неизвестная планета в фиолетовых облаках. Атмосфера из плазмы, кислотные дожди и кристаллы."
	icon_state = "violet"
	map_color = "#9a60d0"
	surface_area_type = /area/plasma_world
	pull_range = PLASMA_WORLD_PULL_RANGE
	pull_accel = PLASMA_WORLD_PULL_ACCEL
	rough_landing = TRUE
	cloud_state = "clouds_violet_tile"
	var/z_level
	var/surface_ready = FALSE
	var/turf/landing_center
	var/designation

/obj/overmap/planet/violet/Initialize(mapload)
	designation = "[pick("PX", "VQ", "KR", "ZN", "XM")]-[rand(100, 999)]"
	name = "planet [designation]"
	return ..()

/obj/overmap/planet/violet/get_ru_names()
	return alist(
		NOMINATIVE = "планета [designation]",
		GENITIVE = "планеты [designation]",
		DATIVE = "планете [designation]",
		ACCUSATIVE = "планету [designation]",
		INSTRUMENTAL = "планетой [designation]",
		PREPOSITIONAL = "планете [designation]",
	)

/obj/overmap/planet/violet/sky_state()
	return "planet_violet"

/obj/overmap/planet/violet/surface_z()
	if(!surface_ready)
		return null
	if(station_landed())
		return levels_by_trait(STATION_LEVEL)[1]
	return z_level

/obj/overmap/planet/violet/surface_point(world_x, world_y)
	if(!station_landed())
		return ..()
	var/obj/overmap/entity/station/ship/rubin = SSovermap.station_entity
	var/width = footprint * OVERMAP_TILE_SPAN * sector.tile_travel
	return list((world.maxx + 1) / 2 + (world_x - rubin.get_world_x()) * world.maxx / width, (world.maxy + 1) / 2 + (world_y - rubin.get_world_y()) * world.maxy / width)

/obj/overmap/planet/violet/proc/station_landed()
	var/obj/overmap/entity/station/ship/rubin = SSovermap.station_entity
	return istype(rubin) && rubin.landed_planet == src

/obj/overmap/planet/violet/surface_floor_type()
	return /turf/simulated/floor/plating/asteroid/basalt/plasma_world

/obj/overmap/planet/violet/sector_tick(obj/overmap/entity/vessel, powered)
	if(powered || vessel.planet_crash || world.time < vessel.void_alarm_at)
		return
	vessel.void_alarm_at = world.time + PLASMA_WORLD_ALARM_EVERY
	vessel.play_shuttle_sound('sound/machines/alarm.ogg', 15)
	vessel.shuttle_visible_message(span_userdanger("ТРЕВОГА: двигатели заглушены полем сектора, корабль падает на [declent_ru(ACCUSATIVE)]!"))
	vessel.shake_shuttle(1 SECONDS, 2)
	if(!prob(PLASMA_WORLD_EMP_CHANCE))
		return
	var/turf/spot = overmap_vessel_structure_turf(vessel)
	if(spot)
		empulse(spot, 0, 2, FALSE, "plasma world field")

/obj/overmap/planet/violet/proc/generate_surface()
	z_level = GLOB.space_manager.add_new_zlevel("Plasma world [UID()]", UNAFFECTED, list(ZTRAIT_ACID_RAIN, BLOCK_TELEPORT))
	landing_center = locate(round(world.maxx / 2), round(world.maxy / 2), z_level)
	apply_terrain(z_level, terrain_text(z_level, FALSE), TRUE)
	surface_ready = TRUE
	log_world("Overmap: violet planet surface generated on z [z_level].")

/obj/overmap/planet/violet/proc/terrain_text(target_z, terraform)
	var/rocks = rustg_cnoise_generate(PLASMA_WORLD_ROCK_CHANCE, "6", "4", "3", "[world.maxx]", "[world.maxy]")
	var/veins = terraform ? null : rustg_cnoise_generate(PLASMA_WORLD_VEIN_CHANCE, "4", "4", "3", "[world.maxx]", "[world.maxy]")
	var/list/near_hull = terraform ? hull_margin(target_z) : null
	var/center_x = round(world.maxx / 2)
	var/center_y = round(world.maxy / 2)
	var/list/chasms = terraform ? null : chasm_marks(center_x, center_y)
	var/boss_angle = rand(0, 359)
	var/boss_x = clamp(round(center_x + PLASMA_WORLD_BOSS_DISTANCE * cos(boss_angle)), PLASMA_WORLD_EDGE + PLASMA_WORLD_BOSS_ARENA + 1, world.maxx - PLASMA_WORLD_EDGE - PLASMA_WORLD_BOSS_ARENA)
	var/boss_y = clamp(round(center_y + PLASMA_WORLD_BOSS_DISTANCE * sin(boss_angle)), PLASMA_WORLD_EDGE + PLASMA_WORLD_BOSS_ARENA + 1, world.maxy - PLASMA_WORLD_EDGE - PLASMA_WORLD_BOSS_ARENA)
	var/floor_path = "/turf/simulated/floor/plating/asteroid/basalt/plasma_world"
	var/area_path = "[surface_area_type]"
	var/list/lines = list(
		"\"a\" = ([floor_path],[area_path])",
		"\"b\" = (/turf/simulated/mineral/random/plasma_world,[area_path])",
		"\"c\" = (/turf/simulated/mineral/plasma/plasma_world/crystal,[area_path])",
		"\"d\" = (/obj/structure/flora/plasma_crystal,[floor_path],[area_path])",
		"\"e\" = (/mob/living/simple_animal/hostile/asteroid/crystal_plasmaman,[floor_path],[area_path])",
		"\"f\" = (/turf/simulated/floor/chasm/straight_down/plasma_world,[area_path])",
		"\"g\" = (/obj/structure/plasma_geyser,[floor_path],[area_path])",
		"\"h\" = (/obj/structure/flora/plasma_crystal/charged/shock,[floor_path],[area_path])",
		"\"i\" = (/obj/structure/flora/plasma_crystal/charged/sonic,[floor_path],[area_path])",
		"\"j\" = (/obj/structure/flora/plasma_crystal/charged/heal,[floor_path],[area_path])",
		"\"k\" = (/mob/living/simple_animal/hostile/megafauna/living_crystal,[floor_path],[area_path])",
		"\"z\" = (/turf/template_noop,/area/template_noop)",
		"",
		"(1,1,1) = {\"",
	)
	for(var/y in world.maxy to 1 step -1)
		var/list/row = list()
		for(var/x in 1 to world.maxx)
			var/index = world.maxx * (y - 1) + x
			if(terraform)
				var/turf/existing = locate(x, y, target_z)
				if(!isspaceturf(existing) || !isspacearea(existing.loc))
					row += "z"
					continue
				if(near_hull[index])
					row += "a"
					continue
			var/edge = x <= PLASMA_WORLD_EDGE || y <= PLASMA_WORLD_EDGE || x > world.maxx - PLASMA_WORLD_EDGE || y > world.maxy - PLASMA_WORLD_EDGE
			var/cleared = !terraform && abs(x - center_x) <= PLASMA_WORLD_CLEARING && abs(y - center_y) <= PLASMA_WORLD_CLEARING
			var/in_arena = !terraform && abs(x - boss_x) <= PLASMA_WORLD_BOSS_ARENA && abs(y - boss_y) <= PLASMA_WORLD_BOSS_ARENA
			if(edge || (!cleared && !in_arena && rocks[index] != "0"))
				row += (!terraform && veins[index] != "0") ? "c" : "b"
				continue
			if(terraform)
				row += "a"
				continue
			if(in_arena)
				row += (x == boss_x && y == boss_y) ? "k" : "a"
				continue
			if(chasms[index])
				row += "f"
				continue
			if(!cleared && prob(PLASMA_WORLD_CRYSTAL_CHANCE))
				row += prob(PLASMA_WORLD_CHARGED_CHANCE) ? pick("h", "i", "j") : "d"
				continue
			if(!cleared && prob(PLASMA_WORLD_GEYSER_CHANCE))
				row += "g"
				continue
			var/near_landing = abs(x - center_x) <= PLASMA_WORLD_CLEARING + PLASMA_WORLD_MOB_CLEARANCE && abs(y - center_y) <= PLASMA_WORLD_CLEARING + PLASMA_WORLD_MOB_CLEARANCE
			row += (!near_landing && prob(PLASMA_WORLD_MOB_CHANCE)) ? "e" : "a"
		lines += jointext(row, "")
		CHECK_TICK
	lines += "\"}"
	return jointext(lines, "\n")

/obj/overmap/planet/violet/proc/chasm_marks(center_x, center_y)
	var/list/marks = new(world.maxx * world.maxy)
	var/reach = PLASMA_WORLD_EDGE + PLASMA_WORLD_CHASM_RADIUS_MAX + 1
	for(var/chasm in 1 to PLASMA_WORLD_CHASMS)
		var/chasm_x = rand(reach, world.maxx - reach)
		var/chasm_y = rand(reach, world.maxy - reach)
		if(abs(chasm_x - center_x) <= PLASMA_WORLD_CLEARING + reach && abs(chasm_y - center_y) <= PLASMA_WORLD_CLEARING + reach)
			continue
		var/radius_x = rand(PLASMA_WORLD_CHASM_RADIUS_MIN, PLASMA_WORLD_CHASM_RADIUS_MAX)
		var/radius_y = rand(PLASMA_WORLD_CHASM_RADIUS_MIN, PLASMA_WORLD_CHASM_RADIUS_MAX)
		for(var/x in chasm_x - radius_x to chasm_x + radius_x)
			for(var/y in chasm_y - radius_y to chasm_y + radius_y)
				if(((x - chasm_x) / radius_x) ** 2 + ((y - chasm_y) / radius_y) ** 2 <= 1 + rand() * 0.3)
					marks[world.maxx * (y - 1) + x] = TRUE
	return marks

/obj/overmap/planet/violet/proc/hull_margin(target_z)
	var/list/marks = new(world.maxx * world.maxy)
	for(var/turf/spot as anything in block(1, 1, target_z, world.maxx, world.maxy, target_z))
		if(isspaceturf(spot) && isspacearea(spot.loc) && !length(spot.contents))
			continue
		for(var/x in max(1, spot.x - PLASMA_WORLD_HULL_GAP) to min(world.maxx, spot.x + PLASMA_WORLD_HULL_GAP))
			for(var/y in max(1, spot.y - PLASMA_WORLD_HULL_GAP) to min(world.maxy, spot.y + PLASMA_WORLD_HULL_GAP))
				marks[world.maxx * (y - 1) + x] = TRUE
		CHECK_TICK
	return marks

/obj/overmap/planet/violet/proc/apply_terrain(target_z, text, fresh)
	if(fresh)
		GLOB.space_manager.add_dirt(target_z)
		var/datum/milla_safe/freeze_z_level/freeze = new
		freeze.invoke_async(target_z)
		UNTIL(freeze.done)
		SSicon_smooth.add_halt_source(src)
	var/datum/parsed_map/parsed = new(text)
	parsed.load(1, 1, target_z, crop_map = TRUE, no_changeturf = fresh)
	if(fresh)
		var/list/mapload_arg = list(TRUE)
		for(var/turf/spot as anything in block(1, 1, target_z, world.maxx, world.maxy, target_z))
			if(!(spot.flags & INITIALIZED))
				SSatoms.InitAtom(spot, mapload_arg)
			for(var/atom/movable/thing as anything in spot)
				if(!(thing.flags & INITIALIZED))
					SSatoms.InitAtom(thing, mapload_arg)
			CHECK_TICK
	require_area_resort()
	if(fresh)
		SSicon_smooth.remove_halt_source(src)
		GLOB.space_manager.remove_dirt(target_z)
	var/list/runs = list()
	if(fresh)
		runs += list(list(locate(1, 1, target_z), locate(world.maxx, world.maxy, target_z)))
	else
		for(var/y in 1 to world.maxy)
			var/turf/run_start
			var/turf/run_end
			for(var/x in 1 to world.maxx)
				var/turf/spot = locate(x, y, target_z)
				if(istype(spot.loc, surface_area_type))
					run_start = run_start || spot
					run_end = spot
					continue
				if(run_start)
					runs += list(list(run_start, run_end))
					run_start = null
			if(run_start)
				runs += list(list(run_start, run_end))
			CHECK_TICK
	var/datum/milla_safe_must_sleep/plasma_world_setup/setup = new
	setup.invoke_async(target_z, runs)
	SSweather.make_eligible("[target_z]", list(/datum/weather/acid_rain = 100))

/datum/milla_safe_must_sleep/plasma_world_setup/on_run(target_z, list/runs)
	if(SSair?.initialized)
		for(var/list/run as anything in runs)
			SSair.setup_turfs(run[1], run[2])
	set_zlevel_freeze(target_z, FALSE)

GLOBAL_DATUM(plasma_world_clouds, /atom/movable/screen/plasma_world_clouds)

/atom/movable/screen/plasma_world_clouds
	screen_loc = "CENTER-7,CENTER-7"
	plane = ABOVE_LIGHTING_PLANE
	layer = 1
	alpha = PLASMA_WORLD_CLOUD_ALPHA
	appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_TRANSFORM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plasma_world_clouds/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	for(var/tile_x in -1 to 1)
		for(var/tile_y in -1 to 1)
			var/atom/movable/planet_cloud_tile/tile = new
			tile.icon_state = "clouds_violet_tile"
			tile.pixel_w = tile_x * PLASMA_WORLD_CLOUD_TILE
			tile.pixel_z = tile_y * PLASMA_WORLD_CLOUD_TILE
			vis_contents += tile
	animate(src, pixel_w = -PLASMA_WORLD_CLOUD_TILE, pixel_z = -PLASMA_WORLD_CLOUD_TILE, time = PLASMA_WORLD_CLOUD_DRIFT, loop = -1)
	animate(pixel_w = 0, pixel_z = 0, time = 0)

/proc/update_plasma_world_clouds(client/viewer, turf/eye)
	var/outdoors = istype(eye?.loc, /area/plasma_world)
	if(!outdoors)
		if(GLOB.plasma_world_clouds)
			viewer.screen -= GLOB.plasma_world_clouds
		return
	if(!GLOB.plasma_world_clouds)
		GLOB.plasma_world_clouds = new
	viewer.screen |= GLOB.plasma_world_clouds

/obj/overmap/entity/planet_station/violet
	name = "violet planet surface"
	desc = "Поверхность неизвестной фиолетовой планеты."

/obj/overmap/entity/planet_station/violet/add_overmap_components()
	AddComponent(/datum/component/overmap_sensors)
	AddComponent(/datum/component/overmap_dock_host, OVERMAP_DOCK_Z_PLANET, null, TRUE, TRUE)

/obj/overmap/entity/planet_station/violet/get_ru_names()
	return alist(
		NOMINATIVE = "поверхность фиолетовой планеты",
		GENITIVE = "поверхности фиолетовой планеты",
		DATIVE = "поверхности фиолетовой планеты",
		ACCUSATIVE = "поверхность фиолетовой планеты",
		INSTRUMENTAL = "поверхностью фиолетовой планеты",
		PREPOSITIONAL = "поверхности фиолетовой планеты",
	)

/obj/overmap/entity/proc/planet_landing_host()
	RETURN_TYPE(/obj/overmap/entity/planet_station)
	var/obj/overmap/entity/planet_station/host = get_dock_host()
	if(!istype(host) || !host.planet || !in_free_flight())
		return null
	return host

/obj/overmap/entity/proc/begin_planet_landing(mob/user)
	var/obj/overmap/entity/planet_station/host = planet_landing_host()
	if(!host)
		return "Корабль не над поверхностью планеты."
	var/obj/docking_port/stationary/pad = get_custom_dock(host)
	if(!pad)
		return OVERMAP_DOCK_NEED_CUSTOM_PICK
	if(!host.planet.rough_landing)
		return prepare_landing(pad) ? TRUE : "Посадочная область недоступна."
	if(world.time < rough_landing_until)
		return "Посадка уже идёт."
	rough_landing_until = world.time + PLASMA_WORLD_LANDING_TIME
	shuttle_visible_message(span_userdanger("Начинается жёсткий вход в атмосферу [host.planet.declent_ru(GENITIVE)]! Держитесь!"))
	play_shuttle_sound('sound/machines/alarm.ogg', 20)
	for(var/shake in 1 to PLASMA_WORLD_LANDING_SHAKES)
		addtimer(CALLBACK(src, PROC_REF(rough_landing_jolt)), PLASMA_WORLD_LANDING_TIME * shake / (PLASMA_WORLD_LANDING_SHAKES + 1))
	addtimer(CALLBACK(src, PROC_REF(finish_rough_landing), host, pad), PLASMA_WORLD_LANDING_TIME)
	return TRUE

/obj/overmap/entity/proc/rough_landing_jolt()
	if(!in_free_flight())
		return
	shake_shuttle(1 SECONDS, 3)
	var/turf/spot = overmap_vessel_structure_turf(src)
	if(spot && prob(PLASMA_WORLD_EMP_CHANCE))
		empulse(spot, 0, 2, FALSE, "rough planet landing")

/obj/overmap/entity/proc/finish_rough_landing(obj/overmap/entity/planet_station/host, obj/docking_port/stationary/pad)
	if(QDELETED(host) || QDELETED(pad) || !in_free_flight())
		return
	speed[1] = 0
	speed[2] = 0
	if(!prepare_landing(pad))
		shuttle_visible_message(span_warning("Посадка сорвалась: площадка недоступна."))

/datum/overmap_sector/wilderness/unknown/populate_roundstart()
	var/turf/origin = get_centered_footprint_origin(OVERMAP_LAVALAND_FOOTPRINT)
	if(!origin)
		spawn_static_overmap_hazards(src)
		return
	var/obj/overmap/planet/violet/world_planet = new(origin)
	add_object(world_planet, origin)
	var/obj/overmap/entity/planet_station/violet/surface = new(pick(world_planet.footprint_turfs()))
	surface.planet = world_planet
	surface.movable = FALSE
	surface.halted = TRUE
	world_planet.outpost = surface
	add_object(surface, surface.loc)
	spawn_static_overmap_hazards(src)
	INVOKE_ASYNC(world_planet, TYPE_PROC_REF(/obj/overmap/planet/violet, generate_surface))

/obj/overmap/planet/violet/capture_derelicts(elapsed)
	if(!surface_ready)
		for(var/obj/overmap/entity/vessel as anything in SSovermap.vessels)
			if(!QDELETED(vessel) && vessel.sector == sector && vessel.overmap_kind == OVERMAP_KIND_SHUTTLE && vessel.in_free_flight() && !vessel.autopilot_upgraded)
				sector_tick(vessel, vessel.has_working_engines())
		return
	. = ..()
	var/obj/overmap/entity/station/ship/rubin = SSovermap.station_entity
	if(!surface_ready || !istype(rubin) || rubin.sector != sector || rubin.landed_planet || rubin.station_falling || rubin.has_working_engines() || rubin.autopilot_upgraded)
		return
	var/world_x = rubin.get_world_x()
	var/world_y = rubin.get_world_y()
	if(covers_world(world_x, world_y))
		begin_station_fall(rubin)
		return
	if(world.time >= rubin.void_alarm_at)
		if(!rubin.void_alarm_at)
			GLOB.major_announcement.announce(message = "Двигатели станции перегружены. Шаттл затягивает гравитационное поле. Готовьтесь к аварийной посадке!", new_title = "ТРЕВОГА")
		rubin.void_alarm_at = world.time + PLASMA_WORLD_ALARM_EVERY
		for(var/mob/living/crew as anything in station_crew())
			SEND_SOUND(crew, sound('sound/machines/alarm.ogg', volume = 10))
	var/turf/origin = loc
	var/span = OVERMAP_TILE_SPAN * sector.tile_travel
	var/delta_x = (origin.x + (footprint - 1) / 2) * span - world_x
	var/delta_y = (origin.y + (footprint - 1) / 2) * span - world_y
	var/distance = sqrt(delta_x ** 2 + delta_y ** 2)
	if(!distance)
		return
	var/push = OVERMAP_FROM_DISPLAY(pull_accel) * elapsed / (1 SECONDS)
	rubin.speed[1] += push * delta_x / distance
	rubin.speed[2] += push * delta_y / distance

/obj/overmap/planet/violet/proc/station_crew()
	. = list()
	var/list/station_levels = levels_by_trait(STATION_LEVEL)
	for(var/mob/living/crew as anything in GLOB.mob_living_list)
		if(crew.z in station_levels)
			. += crew

/obj/overmap/planet/violet/proc/begin_station_fall(obj/overmap/entity/station/ship/rubin)
	rubin.station_falling = TRUE
	rubin.speed[1] = 0
	rubin.speed[2] = 0
	rubin.halted = TRUE
	log_game("Station [rubin.name] started falling onto [name].")
	GLOB.major_announcement.announce(message = "Станция входит в атмосферу планеты. До удара о поверхность [PLASMA_WORLD_STATION_FALL_TIME / (1 SECONDS)] секунд. Всем занять безопасные места и пристегнуться!", new_title = "АВАРИЙНАЯ ПОСАДКА")
	for(var/jolt in 1 to PLASMA_WORLD_STATION_JOLTS)
		addtimer(CALLBACK(src, PROC_REF(station_jolt), rubin, jolt), PLASMA_WORLD_STATION_FALL_TIME * jolt / (PLASMA_WORLD_STATION_JOLTS + 1))
	addtimer(CALLBACK(src, PROC_REF(station_impact), rubin), PLASMA_WORLD_STATION_FALL_TIME)

/obj/overmap/planet/violet/proc/station_jolt(obj/overmap/entity/station/ship/rubin, jolt)
	if(QDELETED(rubin))
		return
	for(var/mob/living/crew as anything in station_crew())
		shake_camera(crew, 2 SECONDS, 1 + round(jolt / 2))
		SEND_SOUND(crew, sound(pick('sound/effects/wind/wind_4_1.ogg', 'sound/effects/wind/wind_5_1.ogg'), volume = 50))
	var/turf/spot = overmap_vessel_structure_turf(rubin)
	if(spot)
		empulse(spot, 1, 4, FALSE, "station planet fall")

/obj/overmap/planet/violet/proc/station_impact(obj/overmap/entity/station/ship/rubin)
	if(QDELETED(rubin))
		return
	for(var/blast in 1 to PLASMA_WORLD_STATION_BLASTS)
		var/turf/spot = overmap_vessel_structure_turf(rubin)
		if(spot)
			explosion(spot, 0, 1, 3, 4, cause = "station planet fall")
	for(var/mob/living/crew as anything in station_crew())
		SEND_SOUND(crew, sound('sound/effects/meteorimpact.ogg', volume = 100))
		shake_camera(crew, 4 SECONDS, 6)
		to_chat(crew, span_userdanger("Станция с чудовищным грохотом врезается в поверхность планеты!"))
		var/share = crew.buckled ? 0.5 : 1
		crew.Weaken(crew.buckled ? 3 SECONDS : 12 SECONDS)
		crew.adjustBruteLoss(PLASMA_WORLD_STATION_DAMAGE * share)
	INVOKE_ASYNC(src, PROC_REF(terraform_station), rubin)

/obj/overmap/planet/violet/proc/terraform_station(obj/overmap/entity/station/ship/rubin)
	for(var/station_z in levels_by_trait(STATION_LEVEL))
		apply_terrain(station_z, terrain_text(station_z, TRUE), FALSE)
	rubin.landed_planet = src
	rubin.station_falling = FALSE
	log_game("Station [rubin.name] landed on [name].")
	GLOB.major_announcement.announce(message = "Станция совершила аварийную посадку на [declent_ru(ACCUSATIVE)]. Снаружи токсичная плазменная атмосфера и кислотные дожди. Без защиты не выходить!", new_title = "ПОСАДКА")

#undef PLASMA_WORLD_EDGE
#undef PLASMA_WORLD_CLEARING
#undef PLASMA_WORLD_ROCK_CHANCE
#undef PLASMA_WORLD_VEIN_CHANCE
#undef PLASMA_WORLD_CRYSTAL_CHANCE
#undef PLASMA_WORLD_MOB_CHANCE
#undef PLASMA_WORLD_MOB_CLEARANCE
#undef PLASMA_WORLD_HULL_GAP
#undef PLASMA_WORLD_STATION_FALL_TIME
#undef PLASMA_WORLD_STATION_JOLTS
#undef PLASMA_WORLD_STATION_BLASTS
#undef PLASMA_WORLD_STATION_DAMAGE
#undef PLASMA_WORLD_PULL_RANGE
#undef PLASMA_WORLD_PULL_ACCEL
#undef PLASMA_WORLD_ALARM_EVERY
#undef PLASMA_WORLD_EMP_CHANCE
#undef PLASMA_WORLD_LANDING_TIME
#undef PLASMA_WORLD_LANDING_SHAKES
#undef PLASMA_WORLD_CLOUD_TILE
#undef PLASMA_WORLD_CLOUD_ALPHA
#undef PLASMA_WORLD_CLOUD_DRIFT
#undef PLASMA_WORLD_CHASMS
#undef PLASMA_WORLD_CHASM_RADIUS_MIN
#undef PLASMA_WORLD_CHASM_RADIUS_MAX
#undef PLASMA_WORLD_GEYSER_CHANCE
#undef PLASMA_WORLD_CHARGED_CHANCE
#undef PLASMA_WORLD_BOSS_DISTANCE
#undef PLASMA_WORLD_BOSS_ARENA
