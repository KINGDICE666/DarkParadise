#define PLASMA_GEYSER_ERUPTION (4 SECONDS)
#define PLASMA_GEYSER_REST_MIN (20 SECONDS)
#define PLASMA_GEYSER_REST_MAX (45 SECONDS)
#define PLASMA_GEYSER_FLIGHT (1.4 SECONDS)
#define PLASMA_GEYSER_HEIGHT 80
#define PLASMA_GEYSER_RANGE_MIN 4
#define PLASMA_GEYSER_RANGE_MAX 7
#define PLASMA_GEYSER_LANDING_TRIES 6
#define PLASMA_GEYSER_LANDING_DAMAGE 6
#define PLASMA_GEYSER_LAUNCH_TRAIT "plasma_geyser_launch"
#define PLASMA_BEAM_SPLIT_SHARE 0.5
#define PLASMA_BEAM_SPLIT_RANGE 8
#define PLASMA_CRYSTAL_PULSE_RANGE 3
#define PLASMA_CRYSTAL_SHOCK_DAMAGE 12
#define PLASMA_CRYSTAL_SHOCK_TARGETS 3
#define PLASMA_CRYSTAL_SONIC_PUSH 2
#define PLASMA_CRYSTAL_HEAL 4

/turf/simulated/floor/chasm/straight_down/plasma_world
	name = "plasma chasm"
	desc = "Бездонная трещина в фиолетовой породе. Снизу тянет тёплым ядовитым ветром."
	icon = 'icons/turf/floors/plasma_chasm.dmi'
	baseturf = /turf/simulated/floor/chasm/straight_down/plasma_world
	atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
	atmos_environment = ENVIRONMENT_PLASMA_WORLD

/turf/simulated/floor/chasm/straight_down/plasma_world/get_ru_names()
	return alist(
		NOMINATIVE = "плазменный разлом",
		GENITIVE = "плазменного разлома",
		DATIVE = "плазменному разлому",
		ACCUSATIVE = "плазменный разлом",
		INSTRUMENTAL = "плазменным разломом",
		PREPOSITIONAL = "плазменном разломе",
	)

/turf/simulated/floor/chasm/straight_down/plasma_world/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	underlay_appearance.icon = 'icons/turf/floors/plasma_world.dmi'
	underlay_appearance.icon_state = "basalt0"
	return TRUE

/turf/simulated/floor/chasm/straight_down/plasma_world/update_visuals(use_initial_air = FALSE)
	return

/obj/structure/plasma_geyser
	name = "plasma geyser"
	desc = "Горячий источник жидкой плазмы в каменной чаше."
	icon = 'icons/obj/flora/plasma_geyser.dmi'
	icon_state = "plasma_geyser"
	anchored = TRUE
	layer = TURF_LAYER + 0.1
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	light_range = 2
	light_power = 0.8
	light_color = "#d070ff"
	var/erupting = FALSE
	var/next_eruption = 0

/obj/structure/plasma_geyser/get_ru_names()
	return alist(
		NOMINATIVE = "плазменный гейзер",
		GENITIVE = "плазменного гейзера",
		DATIVE = "плазменному гейзеру",
		ACCUSATIVE = "плазменный гейзер",
		INSTRUMENTAL = "плазменным гейзером",
		PREPOSITIONAL = "плазменном гейзере",
	)

/obj/structure/plasma_geyser/Initialize(mapload)
	. = ..()
	next_eruption = world.time + rand(PLASMA_GEYSER_REST_MIN, PLASMA_GEYSER_REST_MAX)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	START_PROCESSING(SSprocessing, src)

/obj/structure/plasma_geyser/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/structure/plasma_geyser/examine(mob/user)
	. = ..()
	if(erupting)
		. += span_warning("Из источника с рёвом бьёт фонтан плазмы!")

/obj/structure/plasma_geyser/process(seconds_per_tick)
	if(!erupting && world.time >= next_eruption)
		erupt()

/obj/structure/plasma_geyser/proc/erupt()
	erupting = TRUE
	icon_state = "plasma_geyser_active"
	set_light(5, 1.6)
	new /obj/effect/temp_visual/plasma_geyser_column(loc)
	playsound(src, 'sound/effects/bubbles2.ogg', 70, TRUE)
	playsound(src, 'sound/magic/repulse.ogg', 50, TRUE)
	for(var/mob/living/victim in loc)
		launch(victim)
	addtimer(CALLBACK(src, PROC_REF(calm)), PLASMA_GEYSER_ERUPTION)

/obj/structure/plasma_geyser/proc/calm()
	erupting = FALSE
	icon_state = initial(icon_state)
	set_light(initial(light_range), initial(light_power))
	next_eruption = world.time + rand(PLASMA_GEYSER_REST_MIN, PLASMA_GEYSER_REST_MAX)

/obj/structure/plasma_geyser/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(erupting && isliving(arrived))
		INVOKE_ASYNC(src, PROC_REF(launch), arrived)

/obj/structure/plasma_geyser/proc/landing_spot(mob/living/victim)
	for(var/attempt in 1 to PLASMA_GEYSER_LANDING_TRIES)
		var/turf/candidate = get_ranged_target_turf(victim, pick(GLOB.alldirs), rand(PLASMA_GEYSER_RANGE_MIN, PLASMA_GEYSER_RANGE_MAX))
		if(candidate && !ischasm(candidate) && !candidate.is_blocked_turf(exclude_mobs = TRUE))
			return candidate
	return get_turf(victim)

/obj/structure/plasma_geyser/proc/launch(mob/living/victim)
	if(QDELETED(victim) || victim.buckled || victim.anchored || victim.move_resist >= MOVE_FORCE_OVERPOWERING || HAS_TRAIT_FROM(victim, TRAIT_IMMOBILIZED, PLASMA_GEYSER_LAUNCH_TRAIT))
		return
	var/turf/start = get_turf(victim)
	var/turf/landing = landing_spot(victim)
	var/shift_x = (landing.x - start.x) * world.icon_size
	var/shift_y = (landing.y - start.y) * world.icon_size
	ADD_TRAIT(victim, TRAIT_IMMOBILIZED, PLASMA_GEYSER_LAUNCH_TRAIT)
	ADD_TRAIT(victim, TRAIT_MOVE_FLYING, PLASMA_GEYSER_LAUNCH_TRAIT)
	victim.visible_message(
		span_danger("Столб плазмы подбрасывает [victim.declent_ru(ACCUSATIVE)] высоко в воздух!"),
		span_userdanger("Струя плазмы подбрасывает вас высоко в небо!"),
	)
	playsound(start, 'sound/effects/whoosh.ogg', 80, TRUE)
	var/obj/effect/temp_visual/plasma_geyser_shadow/shadow = new(start)
	animate(shadow, pixel_w = shift_x, pixel_z = shift_y, time = PLASMA_GEYSER_FLIGHT)
	var/start_w = victim.pixel_w
	var/start_z = victim.pixel_z
	animate(victim, pixel_w = start_w + shift_x, time = PLASMA_GEYSER_FLIGHT, flags = ANIMATION_PARALLEL)
	animate(victim, pixel_z = start_z + shift_y / 2 + PLASMA_GEYSER_HEIGHT, time = PLASMA_GEYSER_FLIGHT / 2, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	animate(pixel_z = start_z + shift_y, time = PLASMA_GEYSER_FLIGHT / 2, easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(land), victim, landing, start_w, start_z), PLASMA_GEYSER_FLIGHT)

/obj/structure/plasma_geyser/proc/land(mob/living/victim, turf/landing, start_w, start_z)
	if(QDELETED(victim))
		return
	REMOVE_TRAITS_IN(victim, PLASMA_GEYSER_LAUNCH_TRAIT)
	victim.pixel_w = start_w
	victim.pixel_z = start_z
	if(isturf(victim.loc))
		victim.forceMove(landing)
	playsound(landing, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	new /obj/effect/temp_visual/small_smoke/halfsecond(landing)
	victim.Knockdown(2 SECONDS)
	victim.adjustBruteLoss(PLASMA_GEYSER_LANDING_DAMAGE)
	to_chat(victim, span_warning("Вы тяжело падаете на камни."))

/obj/effect/temp_visual/plasma_geyser_column
	icon = 'icons/effects/plasma_geyser_column.dmi'
	icon_state = "geyser_column"
	layer = ABOVE_ALL_MOB_LAYER
	randomdir = FALSE
	duration = PLASMA_GEYSER_ERUPTION
	pixel_z = 4
	light_range = 4
	light_power = 1.5
	light_color = "#d070ff"

/obj/effect/temp_visual/plasma_geyser_column/Initialize(mapload)
	. = ..()
	alpha = 0
	animate(src, alpha = 255, time = 0.3 SECONDS)
	animate(alpha = 255, time = duration - 0.8 SECONDS)
	animate(alpha = 0, time = 0.5 SECONDS)

/obj/effect/temp_visual/plasma_geyser_shadow
	icon = 'icons/effects/planet_descent_heat.dmi'
	icon_state = "fall_shadow"
	layer = BELOW_MOB_LAYER
	randomdir = FALSE
	duration = PLASMA_GEYSER_FLIGHT
	alpha = 160

/obj/effect/temp_visual/plasma_crystal_wave
	icon = 'icons/effects/crystal_waves.dmi'
	icon_state = "crystal_wave"
	randomdir = FALSE
	duration = 0.5 SECONDS
	pixel_w = -32
	pixel_z = -32

/obj/effect/temp_visual/plasma_crystal_wave/sonic
	icon_state = "sonic_wave"

/obj/effect/temp_visual/plasma_crystal_wave/heal
	icon_state = "heal_wave"

/obj/structure/flora/plasma_crystal/bullet_act(obj/projectile/proj)
	if(split_plasma_beam(src, proj))
		return
	return ..()

/obj/structure/flora/plasma_crystal/proc/start_glow()
	add_filter("crystal_glow", 1, drop_shadow_filter(x = 0, y = 0, size = 2, color = "[light_color]a0"))
	var/glow = get_filter("crystal_glow")
	animate(glow, size = 5, time = 2 SECONDS, loop = -1, easing = SINE_EASING)
	animate(size = 2, time = 2 SECONDS, easing = SINE_EASING)

/turf/simulated/mineral/plasma/plasma_world/crystal/Initialize(mapload)
	. = ..()
	add_filter("crystal_glow", 1, drop_shadow_filter(x = 0, y = 0, size = 3, color = "#d070ff90"))

/turf/simulated/mineral/plasma/plasma_world/crystal/bullet_act(obj/projectile/proj)
	split_plasma_beam(src, proj)
	return ..()

/proc/split_plasma_beam(atom/crystal, obj/projectile/proj)
	if(!istype(proj, /obj/projectile/beam) || istype(proj, /obj/projectile/beam/plasma_shard) || !proj.damage)
		return FALSE
	var/turf/origin = get_turf(crystal)
	playsound(origin, 'sound/effects/glassbang.ogg', 50, TRUE)
	new /obj/effect/temp_visual/impact_effect/purple_laser(origin)
	for(var/angle in 45 to 360 step 45)
		var/obj/projectile/beam/plasma_shard/shard = new(origin)
		shard.damage = proj.damage * PLASMA_BEAM_SPLIT_SHARE
		shard.damage_type = proj.damage_type
		shard.flag = proj.flag
		shard.log_override = TRUE
		shard.preparePixelProjectile(get_step(origin, angle2dir(angle)), origin)
		shard.firer = crystal
		shard.fire(angle)
	return TRUE

/obj/projectile/beam/plasma_shard
	name = "plasma beam"
	icon_state = "purple_laser"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/purple_laser
	light_color = LIGHT_COLOR_PURPLE
	range = PLASMA_BEAM_SPLIT_RANGE
	ricochets_max = 0

/obj/projectile/beam/plasma_shard/get_ru_names()
	return alist(
		NOMINATIVE = "плазменный луч",
		GENITIVE = "плазменного луча",
		DATIVE = "плазменному лучу",
		ACCUSATIVE = "плазменный луч",
		INSTRUMENTAL = "плазменным лучом",
		PREPOSITIONAL = "плазменном луче",
	)

/obj/structure/flora/plasma_crystal/charged
	abstract_type = /obj/structure/flora/plasma_crystal/charged
	crystal_variants = 2
	light_range = 3
	light_power = 1
	var/pulse_min = 5 SECONDS
	var/pulse_max = 7 SECONDS
	var/next_pulse = 0

/obj/structure/flora/plasma_crystal/charged/Initialize(mapload)
	. = ..()
	next_pulse = world.time + rand(pulse_min, pulse_max)
	START_PROCESSING(SSprocessing, src)

/obj/structure/flora/plasma_crystal/charged/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/structure/flora/plasma_crystal/charged/process(seconds_per_tick)
	if(world.time < next_pulse)
		return
	next_pulse = world.time + rand(pulse_min, pulse_max)
	var/list/victims = list()
	for(var/mob/living/victim in range(PLASMA_CRYSTAL_PULSE_RANGE, src))
		if(victim.stat != DEAD)
			victims += victim
	if(length(victims))
		pulse(victims)

/obj/structure/flora/plasma_crystal/charged/proc/pulse(list/victims)
	return

/obj/structure/flora/plasma_crystal/charged/shock
	name = "yellow crystal cluster"
	desc = "Жёлтая друза, от неё исходит характерный электрический треск."
	crystal_kind = "shock"
	light_color = "#ffe060"

/obj/structure/flora/plasma_crystal/charged/shock/get_ru_names()
	return alist(
		NOMINATIVE = "жёлтая друза",
		GENITIVE = "жёлтой друзы",
		DATIVE = "жёлтой друзе",
		ACCUSATIVE = "жёлтую друзу",
		INSTRUMENTAL = "жёлтой друзой",
		PREPOSITIONAL = "жёлтой друзе",
	)

/obj/structure/flora/plasma_crystal/charged/shock/pulse(list/victims)
	playsound(src, 'sound/magic/lightningshock.ogg', 60, TRUE)
	var/struck = 0
	for(var/mob/living/victim as anything in shuffle(victims))
		if(FACTION_PLASMA_WORLD in victim.faction)
			continue
		Beam(victim, icon_state = "lightning[rand(1, 12)]", time = 0.5 SECONDS)
		victim.electrocute_act(PLASMA_CRYSTAL_SHOCK_DAMAGE, src, flags = SHOCK_NOGLOVES)
		if(++struck >= PLASMA_CRYSTAL_SHOCK_TARGETS)
			break

/obj/structure/flora/plasma_crystal/charged/sonic
	name = "blue crystal cluster"
	desc = "Голубая друза, от которой исходит низкий гул."
	crystal_kind = "sonic"
	light_color = "#60e0ff"

/obj/structure/flora/plasma_crystal/charged/sonic/get_ru_names()
	return alist(
		NOMINATIVE = "голубая друза",
		GENITIVE = "голубой друзы",
		DATIVE = "голубой друзе",
		ACCUSATIVE = "голубую друзу",
		INSTRUMENTAL = "голубой друзой",
		PREPOSITIONAL = "голубой друзе",
	)

/obj/structure/flora/plasma_crystal/charged/sonic/pulse(list/victims)
	new /obj/effect/temp_visual/plasma_crystal_wave/sonic(loc)
	playsound(src, 'sound/magic/repulse.ogg', 60, TRUE)
	for(var/mob/living/victim as anything in victims)
		if(FACTION_PLASMA_WORLD in victim.faction)
			continue
		to_chat(victim, span_warning("Звуковая волна оглушает вас!"))
		shake_camera(victim, 1 SECONDS, 3)
		victim.Stun(1 SECONDS)
		victim.AdjustConfused(3 SECONDS, bound_upper = 6 SECONDS)
		victim.AdjustDizzy(4 SECONDS, bound_upper = 10 SECONDS)
		victim.AdjustDeaf(3 SECONDS)
		victim.adjustStaminaLoss(15)
		if(!victim.anchored && !victim.buckled)
			victim.throw_at(get_ranged_target_turf(victim, get_dir(src, victim) || pick(GLOB.alldirs), PLASMA_CRYSTAL_SONIC_PUSH), PLASMA_CRYSTAL_SONIC_PUSH, 1)

/obj/structure/flora/plasma_crystal/charged/heal
	name = "green crystal cluster"
	desc = "Зелёная друза с мягким тёплым светом."
	crystal_kind = "heal"
	light_color = "#70ff90"

/obj/structure/flora/plasma_crystal/charged/heal/get_ru_names()
	return alist(
		NOMINATIVE = "зелёная друза",
		GENITIVE = "зелёной друзы",
		DATIVE = "зелёной друзе",
		ACCUSATIVE = "зелёную друзу",
		INSTRUMENTAL = "зелёной друзой",
		PREPOSITIONAL = "зелёной друзе",
	)

/obj/structure/flora/plasma_crystal/charged/heal/pulse(list/victims)
	new /obj/effect/temp_visual/plasma_crystal_wave/heal(loc)
	playsound(src, 'sound/magic/staff_healing.ogg', 40, TRUE)
	for(var/mob/living/patient as anything in victims)
		patient.heal_overall_damage(PLASMA_CRYSTAL_HEAL, PLASMA_CRYSTAL_HEAL)

#undef PLASMA_GEYSER_ERUPTION
#undef PLASMA_GEYSER_REST_MIN
#undef PLASMA_GEYSER_REST_MAX
#undef PLASMA_GEYSER_FLIGHT
#undef PLASMA_GEYSER_HEIGHT
#undef PLASMA_GEYSER_RANGE_MIN
#undef PLASMA_GEYSER_RANGE_MAX
#undef PLASMA_GEYSER_LANDING_TRIES
#undef PLASMA_GEYSER_LANDING_DAMAGE
#undef PLASMA_GEYSER_LAUNCH_TRAIT
#undef PLASMA_BEAM_SPLIT_SHARE
#undef PLASMA_BEAM_SPLIT_RANGE
#undef PLASMA_CRYSTAL_PULSE_RANGE
#undef PLASMA_CRYSTAL_SHOCK_DAMAGE
#undef PLASMA_CRYSTAL_SHOCK_TARGETS
#undef PLASMA_CRYSTAL_SONIC_PUSH
#undef PLASMA_CRYSTAL_HEAL
