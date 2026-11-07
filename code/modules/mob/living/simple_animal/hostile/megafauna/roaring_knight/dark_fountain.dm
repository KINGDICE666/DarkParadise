#define FOUNTAIN_START_RADIUS 1
#define FOUNTAIN_MAX_RADIUS 7
#define FOUNTAIN_ERUPTED_MAX_RADIUS 10
#define FOUNTAIN_MAX_DARKNERS 10
#define FOUNTAIN_SWALLOW_RANGE 3
#define FOUNTAIN_SHADE_SLASH_LENGTH 5
#define FOUNTAIN_SHADE_WARNING_TIME (0.45 SECONDS)
#define FOUNTAIN_SEAL_TIME (30 SECONDS)
#define FOUNTAIN_MIN_SEAL_TIME (8 SECONDS)
#define FOUNTAIN_CLOSE_TIME (0.6 SECONDS)
#define FOUNTAIN_OPEN_TIME (0.9 SECONDS)
#define DARK_TILE_COLUMNS 10
#define DARK_TILE_ROWS 7

GLOBAL_LIST_INIT(knight_awakening_machines, list(/obj/machinery/vending, /obj/machinery/computer))

/proc/is_knight_ally(atom/target)
	if(!isliving(target))
		return FALSE
	var/mob/living/creature = target
	return "roaring_knight" in creature.faction

/datum/looping_sound/dark_fountain
	start_sound = 'sound/creatures/roaring_knight/fountain_open.ogg'
	start_length = 14 SECONDS
	mid_sounds = list('sound/creatures/roaring_knight/fountain_loop.ogg' = 1)
	mid_length = 17 SECONDS
	volume = 45
	extra_range = 5
	pressure_affected = FALSE
	use_sound_tokens = TRUE

/obj/structure/dark_fountain
	name = "dark fountain"
	desc = "Столб живой тьмы, бьющий из пола прямо в потолок. Рядом с ним вещи перестают вести себя как вещи."
	icon = 'icons/mob/roaring_knight/fountain.dmi'
	icon_state = "fountain"
	pixel_x = -32
	pixel_y = -8
	layer = ABOVE_ALL_MOB_LAYER
	density = TRUE
	anchored = TRUE
	max_integrity = 800
	damage_deflection = 10
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/mob/living/simple_animal/hostile/megafauna/roaring_knight/owner
	var/datum/looping_sound/dark_fountain/hum
	var/zone_radius = FOUNTAIN_START_RADIUS
	var/max_radius = FOUNTAIN_MAX_RADIUS
	var/list/obj/effect/dark_world_tile/zone_tiles = list()
	var/list/mob/living/simple_animal/hostile/mimic/copy/darkner/darkners = list()
	var/pool_state = "pool_open"
	var/closing = FALSE
	COOLDOWN_DECLARE(prank_cooldown)
	COOLDOWN_DECLARE(darkner_cooldown)

/obj/structure/dark_fountain/get_ru_names()
	return alist(
		NOMINATIVE = "тёмный фонтан",
		GENITIVE = "тёмного фонтана",
		DATIVE = "тёмному фонтану",
		ACCUSATIVE = "тёмный фонтан",
		INSTRUMENTAL = "тёмным фонтаном",
		PREPOSITIONAL = "тёмном фонтане",
	)

/obj/structure/dark_fountain/Initialize(mapload, mob/living/simple_animal/hostile/megafauna/roaring_knight/owner)
	. = ..()
	src.owner = owner
	owner?.fountains += src
	hum = new(src, TRUE)
	set_light(FOUNTAIN_MAX_RADIUS + 1, -2, "#2b1a4d")
	flick("fountain_open", src)
	update_appearance(UPDATE_OVERLAYS)
	addtimer(CALLBACK(src, PROC_REF(settle_pool)), FOUNTAIN_OPEN_TIME)
	COOLDOWN_START(src, prank_cooldown, 5 SECONDS)
	COOLDOWN_START(src, darkner_cooldown, 2 SECONDS)
	spread_zone()
	START_PROCESSING(SSobj, src)
	visible_message(span_userdanger("Из пола бьёт столб тьмы!"))

/obj/structure/dark_fountain/Destroy()
	STOP_PROCESSING(SSobj, src)
	clear_zone()
	clear_darkners()
	owner?.fountains -= src
	owner = null
	QDEL_NULL(hum)
	return ..()

/obj/structure/dark_fountain/obj_destruction(damage_flag)
	close()

/obj/structure/dark_fountain/attack_animal(mob/living/simple_animal/attacker)
	if(is_knight_ally(attacker))
		return FALSE
	return ..()

/obj/structure/dark_fountain/bullet_act(obj/projectile/proj)
	if(istype(proj, /obj/projectile/roaring_knight))
		return -1
	return ..()

/obj/structure/dark_fountain/update_overlays()
	. = ..()
	. += mutable_appearance(icon, pool_state, ABOVE_OPEN_TURF_LAYER)
	if(!closing)
		. += emissive_appearance(icon, icon_state, src)

/obj/structure/dark_fountain/attack_hand(mob/user)
	if(!isliving(user) || closing || is_knight_ally(user))
		return ..()
	var/sealers = 0
	for(var/mob/living/carbon/human/helper in range(1, src))
		if(helper.stat == CONSCIOUS)
			sealers++
	var/seal_time = max(FOUNTAIN_SEAL_TIME / max(sealers, 1), FOUNTAIN_MIN_SEAL_TIME)
	user.visible_message(span_warning("[DECLENT_RU_CAP(user, NOMINATIVE)] пытается запечатать [declent_ru(ACCUSATIVE)]."), span_notice("Вы пытаетесь запечатать [declent_ru(ACCUSATIVE)]. Вместе это выйдет быстрее."))
	if(!do_after(user, seal_time, src))
		return
	if(closing)
		return
	visible_message(span_notice("[DECLENT_RU_CAP(user, NOMINATIVE)] запечатывает [declent_ru(ACCUSATIVE)]!"))
	close()

/obj/structure/dark_fountain/process(seconds_per_tick)
	if(closing)
		return PROCESS_KILL
	if(zone_radius < max_radius)
		zone_radius++
	spread_zone()
	for(var/mob/living/victim in range(zone_radius, src))
		if(victim.stat != DEAD && !is_knight_ally(victim))
			victim.apply_status_effect(/datum/status_effect/dark_world)
	if(COOLDOWN_FINISHED(src, darkner_cooldown))
		COOLDOWN_START(src, darkner_cooldown, rand(2 SECONDS, 4 SECONDS))
		prank_darkner()
	if(COOLDOWN_FINISHED(src, prank_cooldown))
		COOLDOWN_START(src, prank_cooldown, rand(6 SECONDS, 10 SECONDS))
		play_prank()

/obj/structure/dark_fountain/proc/settle_pool()
	pool_state = "pool"
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/dark_fountain/proc/spread_zone()
	for(var/turf/zone_turf as anything in circle_range_turfs(src, zone_radius))
		if(isclosedturf(zone_turf) || isspaceturf(zone_turf))
			continue
		if(locate(/obj/effect/dark_world_tile) in zone_turf)
			continue
		zone_tiles += new /obj/effect/dark_world_tile(zone_turf, src)

/obj/structure/dark_fountain/proc/clear_zone()
	for(var/obj/effect/dark_world_tile/tile as anything in zone_tiles)
		tile.fade_out()
	zone_tiles.Cut()

/obj/structure/dark_fountain/proc/clear_darkners()
	for(var/mob/living/simple_animal/hostile/mimic/copy/darkner/darkner as anything in darkners.Copy())
		darkner.death()
	darkners.Cut()

/obj/structure/dark_fountain/proc/close()
	if(closing)
		return
	closing = TRUE
	STOP_PROCESSING(SSobj, src)
	set_light(0)
	hum.stop()
	playsound(src, 'sound/magic/repulse.ogg', 80, TRUE, 5)
	owner?.fountains -= src
	owner = null
	clear_zone()
	clear_darkners()
	pool_state = "pool_close"
	icon_state = "fountain_close"
	update_appearance(UPDATE_OVERLAYS)
	density = FALSE
	QDEL_IN(src, FOUNTAIN_CLOSE_TIME)

/obj/structure/dark_fountain/proc/erupt()
	if(closing)
		return
	flick("fountain_open", src)
	playsound(src, 'sound/creatures/roaring_knight/fountain_burst.ogg', 100, FALSE, 10)
	max_radius = FOUNTAIN_ERUPTED_MAX_RADIUS
	zone_radius = min(zone_radius + 2, max_radius)
	spread_zone()
	for(var/angle in 0 to 330 step 30)
		fire_knight_bullet(/obj/projectile/roaring_knight, get_turf(src), angle, owner, 9)
	if(length(darkners) < FOUNTAIN_MAX_DARKNERS)
		prank_darkner()

/obj/structure/dark_fountain/proc/list_zone_victims(max_range = zone_radius)
	var/list/victims = list()
	for(var/mob/living/victim in range(max_range, src))
		if(victim.stat == CONSCIOUS && !is_knight_ally(victim))
			victims += victim
	return victims

/obj/structure/dark_fountain/proc/play_prank()
	switch(pick("shade", "stars", "flicker", "soul", "scatter", "swallow"))
		if("shade")
			prank_shade()
		if("stars")
			prank_stars()
		if("flicker")
			prank_flicker()
		if("soul")
			prank_soul()
		if("scatter")
			prank_scatter()
		if("swallow")
			prank_swallow()

/obj/structure/dark_fountain/proc/prank_darkner()
	if(length(darkners) >= FOUNTAIN_MAX_DARKNERS)
		return
	var/list/candidates = list()
	for(var/obj/candidate in range(zone_radius, src))
		if(can_awaken(candidate))
			candidates += candidate
	if(!length(candidates))
		return
	var/obj/chosen = pick(candidates)
	var/mob/living/simple_animal/hostile/mimic/copy/darkner/darkner = new(chosen.loc, chosen, owner)
	darkners += darkner
	RegisterSignal(darkner, COMSIG_QDELETING, PROC_REF(on_darkner_deleted))
	new /obj/effect/temp_visual/roaring_knight/bullet/awaken(get_turf(darkner))
	playsound(darkner, 'sound/creatures/roaring_knight/darkner_wake.ogg', 70, TRUE, 3)
	playsound(darkner, 'sound/effects/ghost2.ogg', 40, TRUE)
	darkner.visible_message(span_danger("Тьма вливается в [chosen.declent_ru(ACCUSATIVE)], и [chosen.declent_ru(NOMINATIVE)] открывает глаза!"))

/obj/structure/dark_fountain/proc/can_awaken(obj/candidate)
	if(candidate.has_buckled_mobs())
		return FALSE
	if(is_type_in_list(candidate, GLOB.knight_awakening_machines))
		return TRUE
	if(!isitem(candidate) && !isstructure(candidate))
		return FALSE
	if(candidate.anchored && !istype(candidate, /obj/structure/chair))
		return FALSE
	return !is_type_in_list(candidate, GLOB.protected_objects)

/obj/structure/dark_fountain/proc/on_darkner_deleted(datum/source)
	SIGNAL_HANDLER
	darkners -= source

/obj/structure/dark_fountain/proc/prank_stars()
	playsound(src, 'sound/magic/magic_missile.ogg', 70, TRUE, 3)
	var/first_angle = rand(0, 44)
	for(var/angle in first_angle to first_angle + 315 step 45)
		fire_knight_bullet(/obj/projectile/roaring_knight, get_turf(src), angle, owner, zone_radius + 2)

/obj/structure/dark_fountain/proc/prank_shade()
	var/list/victims = list_zone_victims()
	if(!length(victims) || QDELETED(owner))
		return
	var/turf/center = get_turf(pick(victims))
	var/angle = rand(0, 179)
	new /obj/effect/temp_visual/decoy/fading/halfsecond(get_turf_in_angle(angle, center, 2) || center, owner)
	new /obj/effect/temp_visual/roaring_knight/line/warning(center, angle, FOUNTAIN_SHADE_SLASH_LENGTH)
	playsound(center, 'sound/creatures/roaring_knight/cut_reverse.ogg', 60, TRUE, 3)
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob/living/simple_animal/hostile/megafauna/roaring_knight, cut_line), center, angle, FOUNTAIN_SHADE_SLASH_LENGTH), FOUNTAIN_SHADE_WARNING_TIME)

/obj/structure/dark_fountain/proc/prank_flicker()
	playsound(src, 'sound/magic/disable_tech.ogg', 50, TRUE, 3)
	for(var/obj/machinery/light/lamp in range(zone_radius + 2, src))
		INVOKE_ASYNC(lamp, TYPE_PROC_REF(/obj/machinery/light, flicker_event), rand(3, 6))

/obj/structure/dark_fountain/proc/prank_soul()
	var/list/victims = list_zone_victims()
	if(!length(victims))
		return
	var/mob/living/victim = pick(victims)
	new /obj/effect/temp_visual/roaring_knight/soul(get_turf(victim), src)
	to_chat(victim, span_userdanger("Что-то тянет вашу душу из груди к [declent_ru(DATIVE)]!"))
	victim.playsound_local(get_turf(victim), 'sound/effects/heart_beat.ogg', 80, FALSE)
	victim.adjustStaminaLoss(30)
	victim.Confused(2 SECONDS)

/obj/structure/dark_fountain/proc/prank_scatter()
	playsound(src, 'sound/magic/repulse.ogg', 60, TRUE, 3)
	for(var/obj/item/loose_item in range(zone_radius, src))
		if(!loose_item.anchored && prob(40))
			loose_item.throw_at(get_ranged_target_turf(loose_item, pick(GLOB.alldirs), 3), 3, 1)

/obj/structure/dark_fountain/proc/prank_swallow()
	var/list/victims = list()
	for(var/mob/living/candidate as anything in list_zone_victims(FOUNTAIN_SWALLOW_RANGE))
		if(!candidate.anchored && !candidate.buckled)
			victims += candidate
	if(!length(victims))
		return
	var/mob/living/victim = pick(victims)
	var/obj/structure/dark_fountain/exit = src
	if(owner && length(owner.fountains) > 1)
		exit = pick(owner.fountains - src)
	var/list/exits = list()
	for(var/turf/exit_turf as anything in RANGE_TURFS(2, exit))
		if(!exit_turf.is_blocked_turf())
			exits += exit_turf
	if(!length(exits))
		return
	new /obj/effect/temp_visual/decoy/fading/halfsecond(get_turf(victim), victim)
	victim.visible_message(span_danger("Тьма проглатывает [victim.declent_ru(ACCUSATIVE)]!"), span_userdanger("Тьма проглатывает вас и выплёвывает в другом месте!"))
	playsound(victim, 'sound/magic/blink.ogg', 60, TRUE)
	victim.forceMove(pick(exits))
	victim.Knockdown(2 SECONDS)
	playsound(victim, 'sound/magic/blink.ogg', 60, TRUE)

/obj/effect/dark_world_tile
	name = "dark ground"
	icon = 'icons/mob/roaring_knight/effects.dmi'
	icon_state = "dark_tile_0_0"
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	var/obj/structure/dark_fountain/source

/obj/effect/dark_world_tile/Initialize(mapload, obj/structure/dark_fountain/source)
	. = ..()
	src.source = source
	icon_state = "dark_tile_[x % DARK_TILE_COLUMNS]_[DARK_TILE_ROWS - 1 - (y % DARK_TILE_ROWS)]"
	animate(src, alpha = 255, time = 1 SECONDS)

/obj/effect/dark_world_tile/Destroy()
	source?.zone_tiles -= src
	source = null
	return ..()

/obj/effect/dark_world_tile/ex_act(severity, target)
	return

/obj/effect/dark_world_tile/singularity_act()
	return

/obj/effect/dark_world_tile/singularity_pull(atom/singularity, current_size)
	return

/obj/effect/dark_world_tile/proc/fade_out()
	source = null
	animate(src, alpha = 0, time = 1 SECONDS)
	QDEL_IN(src, 1 SECONDS)

/mob/living/simple_animal/hostile/mimic/copy/darkner
	faction = list("roaring_knight")
	AI_delay_max = 1 SECONDS

/mob/living/simple_animal/hostile/mimic/copy/darkner/CheckObject(obj/copied)
	return ..() || is_type_in_list(copied, GLOB.knight_awakening_machines)

/mob/living/simple_animal/hostile/mimic/copy/darkner/CopyObject(obj/copied, mob/living/user, destroy_original = FALSE)
	. = ..()
	add_filter("darkner_outline", 1, outline_filter(1, "#412ac0"))

/datum/status_effect/dark_world
	id = "dark_world"
	duration = 6 SECONDS
	tick_interval = 5 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/dark_world
	var/mutable_appearance/soul_overlay
	var/list/grey_matrix = MATRIX_GREYSCALE

/datum/status_effect/dark_world/on_apply()
	owner.add_atom_colour(grey_matrix, TEMPORARY_COLOUR_PRIORITY)
	soul_overlay = mutable_appearance('icons/mob/roaring_knight/effects.dmi', "soul", ABOVE_MOB_LAYER, owner, ABOVE_LIGHTING_PLANE, appearance_flags = RESET_COLOR | RESET_ALPHA)
	owner.add_overlay(soul_overlay)
	to_chat(owner, span_warning("Цвета вокруг гаснут, и остаётся только красное биение вашей души."))
	return TRUE

/datum/status_effect/dark_world/on_remove()
	owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, grey_matrix)
	owner.cut_overlay(soul_overlay)
	soul_overlay = null
	to_chat(owner, span_notice("Цвета понемногу возвращаются."))

/datum/status_effect/dark_world/tick(seconds_between_ticks)
	owner.AdjustHallucinate(2 SECONDS, bound_upper = 30 SECONDS)
	if(prob(35))
		owner.playsound_local(get_turf(owner), pick('sound/shadowdemon/shadowhalluc1.ogg', 'sound/shadowdemon/shadowhalluc2.ogg', 'sound/shadowdemon/shadowhalluc3.ogg'), 35, TRUE)
		to_chat(owner, span_warning(pick(
			"Тени на полу ползут против света.",
			"Вещи вокруг будто следят за вами.",
			"Из глубины фонтана доносится далёкий рокот.",
			"На секунду кажется, что вы забыли своё имя.",
		)))

/atom/movable/screen/alert/status_effect/dark_world
	name = "Тёмный мир"
	desc = "Вы в зоне тёмного фонтана. Мир потерял цвет, а ваша душа видна всем."
	icon = 'icons/mob/roaring_knight/effects.dmi'
	icon_state = "soul"

#undef FOUNTAIN_START_RADIUS
#undef FOUNTAIN_MAX_RADIUS
#undef FOUNTAIN_ERUPTED_MAX_RADIUS
#undef FOUNTAIN_MAX_DARKNERS
#undef FOUNTAIN_SWALLOW_RANGE
#undef FOUNTAIN_SHADE_SLASH_LENGTH
#undef FOUNTAIN_SHADE_WARNING_TIME
#undef FOUNTAIN_SEAL_TIME
#undef FOUNTAIN_MIN_SEAL_TIME
#undef FOUNTAIN_CLOSE_TIME
#undef FOUNTAIN_OPEN_TIME
#undef DARK_TILE_COLUMNS
#undef DARK_TILE_ROWS
