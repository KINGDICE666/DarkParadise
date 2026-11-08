#define KNIGHT_QUICK_SLASH 1
#define KNIGHT_FLURRY 2
#define KNIGHT_STAR_BURST 3
#define KNIGHT_SWORD_VOLLEY 4
#define KNIGHT_FLY_DASH 5
#define KNIGHT_BALL_WARP 6
#define KNIGHT_ROAR 7
#define KNIGHT_FRONT_SLASH 8
#define KNIGHT_HAND_VACUUM 9
#define KNIGHT_DARK_FOUNTAIN 10
#define KNIGHT_SPLIT_FLAME 11

#define KNIGHT_MAX_ANGER 20
#define KNIGHT_SLASH_LENGTH 7
#define KNIGHT_SLASH_WARNING_TIME (0.45 SECONDS)
#define KNIGHT_FLY_RANGE 12
#define KNIGHT_ROAR_RANGE 9
#define KNIGHT_LIGHT_BREAK_RANGE 7
#define KNIGHT_VACUUM_RANGE 8
#define KNIGHT_VACUUM_PULLS 10
#define KNIGHT_FRONT_RANGE 6
#define KNIGHT_FRONT_HALF_WIDTH 55
#define KNIGHT_MAX_FOUNTAINS 3
#define KNIGHT_FOUNTAIN_SPACING 5
#define KNIGHT_FLOAT_PIXEL_Y -80
#define KNIGHT_WRECK_DAMAGE 100000
#define KNIGHT_DEFLECT_CHANCE 25
#define KNIGHT_PHASE_DEFLECT_CHANCE 40
#define KNIGHT_COMBO_CHANCE 25
#define KNIGHT_PHASE_COMBO_CHANCE 45
#define KNIGHT_FLAME_RANGE 9
#define KNIGHT_DARK_ZONE_HEAL 20

/mob/living/simple_animal/hostile/megafauna/roaring_knight
	name = "roaring knight"
	desc = "Чёрный силуэт с белым контуром и длинным клинком. Там, где он проходит, мир становится темнее."
	icon = 'icons/mob/roaring_knight/roaring_knight.dmi'
	icon_state = "stance"
	icon_living = "stance"
	pixel_x = -80
	base_pixel_x = -80
	pixel_y = -18
	base_pixel_y = -18
	mouse_opacity = MOUSE_OPACITY_ICON
	health = 3000
	maxHealth = 3000
	melee_damage_lower = 25
	melee_damage_upper = 25
	armour_penetration = 40
	attacktext = "рассекает"
	attack_sound = 'sound/creatures/roaring_knight/cut.ogg'
	friendly = "молча разглядывает"
	speak_emote = list("рокочет")
	faction = list("roaring_knight")
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	obj_damage = 100
	speed = 0
	move_to_delay = 2
	rapid_melee = 2
	next_move_modifier = 0.5
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS
	nightvision = 8
	ranged = TRUE
	ranged_cooldown_time = 1.2 SECONDS
	aggro_vision_range = 14
	stat_attack = CONSCIOUS
	true_spawn = FALSE
	del_on_death = TRUE
	death_sound = 'sound/creatures/roaring_knight/swoon.ogg'
	deathmessage = "распадается чёрными каплями и исчезает."
	attack_action_types = list(
		/datum/action/innate/megafauna_attack/knight_quick_slash,
		/datum/action/innate/megafauna_attack/knight_flurry,
		/datum/action/innate/megafauna_attack/knight_star_burst,
		/datum/action/innate/megafauna_attack/knight_sword_volley,
		/datum/action/innate/megafauna_attack/knight_fly_dash,
		/datum/action/innate/megafauna_attack/knight_ball_warp,
		/datum/action/innate/megafauna_attack/knight_roar,
		/datum/action/innate/megafauna_attack/knight_front_slash,
		/datum/action/innate/megafauna_attack/knight_hand_vacuum,
		/datum/action/innate/megafauna_attack/knight_dark_fountain,
		/datum/action/innate/megafauna_attack/knight_split_flame,
	)
	var/acting = FALSE
	var/rooted = FALSE
	var/floating = FALSE
	var/phase_two = FALSE
	var/step_counter = 0
	var/list/obj/structure/dark_fountain/fountains = list()
	COOLDOWN_DECLARE(roar_cooldown)
	COOLDOWN_DECLARE(fountain_cooldown)
	COOLDOWN_DECLARE(hurt_sound_cooldown)
	COOLDOWN_DECLARE(voice_cooldown)
	COOLDOWN_DECLARE(laugh_cooldown)
	COOLDOWN_DECLARE(taunt_cooldown)
	COOLDOWN_DECLARE(dark_heal_sound_cooldown)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/get_ru_names()
	return alist(
		NOMINATIVE = "рокочущий рыцарь",
		GENITIVE = "рокочущего рыцаря",
		DATIVE = "рокочущему рыцарю",
		ACCUSATIVE = "рокочущего рыцаря",
		INSTRUMENTAL = "рокочущим рыцарем",
		PREPOSITIONAL = "рокочущем рыцаре",
	)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)
	flick("ball_rise", src)
	playsound(src, 'sound/creatures/roaring_knight/voiceline.ogg', 80, FALSE, 7)
	COOLDOWN_START(src, voice_cooldown, 30 SECONDS)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/Destroy()
	for(var/obj/structure/dark_fountain/fountain as anything in fountains.Copy())
		fountain.close()
	return ..()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/death(gibbed)
	if(health > 0)
		return
	new /obj/effect/temp_visual/roaring_knight/bubble_blow(loc)
	return ..()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/adjustHealth(
	amount = 0,
	updating_health = TRUE,
	blocked = 0,
	damage_type = BRUTE,
	forced = FALSE,
)
	if(amount > 0 && COOLDOWN_FINISHED(src, hurt_sound_cooldown))
		COOLDOWN_START(src, hurt_sound_cooldown, 2 SECONDS)
		playsound(src, 'sound/creatures/roaring_knight/hurt.ogg', 70, TRUE)
	. = ..()
	if(!phase_two && stat != DEAD && health <= maxHealth * 0.5)
		phase_two = TRUE
		INVOKE_ASYNC(src, PROC_REF(phase_shift))

/mob/living/simple_animal/hostile/megafauna/roaring_knight/Life(seconds, times_fired)
	. = ..()
	if(stat == DEAD)
		return
	if(in_dark_zone() && health < maxHealth)
		adjustHealth(-KNIGHT_DARK_ZONE_HEAL)
		if(COOLDOWN_FINISHED(src, dark_heal_sound_cooldown))
			COOLDOWN_START(src, dark_heal_sound_cooldown, 8 SECONDS)
			playsound(src, 'sound/creatures/roaring_knight/fountain_heal.ogg', 60, TRUE)
	if(target && !client && COOLDOWN_FINISHED(src, taunt_cooldown))
		COOLDOWN_START(src, taunt_cooldown, rand(15 SECONDS, 25 SECONDS))
		playsound(src, pick('sound/creatures/roaring_knight/voiceline.ogg', 'sound/creatures/roaring_knight/voice_low.ogg', 'sound/creatures/roaring_knight/laugh_short.ogg'), 70, FALSE, 5)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/bullet_act(obj/projectile/proj, def_zone)
	if(stat == CONSCIOUS && !floating && !istype(proj, /obj/projectile/roaring_knight) && prob(phase_two ? KNIGHT_PHASE_DEFLECT_CHANCE : KNIGHT_DEFLECT_CHANCE))
		proj.reflect_back(src)
		flick("point", src)
		playsound(src, 'sound/weapons/blade1.ogg', 70, TRUE)
		new /obj/effect/temp_visual/roaring_knight/glint(loc)
		return -1
	return ..()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(acting)
		return
	step_counter++
	if(step_counter % 2 == 0)
		playsound(src, pick('sound/effects/footstep/catwalk1.ogg', 'sound/effects/footstep/catwalk2.ogg', 'sound/effects/footstep/catwalk3.ogg', 'sound/effects/footstep/catwalk4.ogg', 'sound/effects/footstep/catwalk5.ogg'), 40, TRUE, -2)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/Aggro()
	if(COOLDOWN_FINISHED(src, voice_cooldown))
		COOLDOWN_START(src, voice_cooldown, 30 SECONDS)
		playsound(src, 'sound/creatures/roaring_knight/voiceline.ogg', 80, FALSE, 7)
	return ..()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/setDir(newdir)
	. = ..()
	refresh_facing()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/Move(atom/newloc, direct = NONE, glide_size_override = 0, update_dir = TRUE)
	if(rooted)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/AttackingTarget()
	if(acting)
		return
	. = ..()
	if(. && !QDELETED(target))
		flick("pull_back", src)
		new /obj/effect/temp_visual/roaring_knight/red_slash(get_turf(target), rand(0, 359))

/mob/living/simple_animal/hostile/megafauna/roaring_knight/devour(mob/living/victim)
	laugh()
	return FALSE

/mob/living/simple_animal/hostile/megafauna/roaring_knight/OpenFire(atom/fire_target)
	if(acting || QDELETED(fire_target))
		return
	if(GLOB.pacifism_after_gt || HAS_TRAIT(src, TRAIT_PACIFISM))
		return
	anger_modifier = clamp((maxHealth - health) / (maxHealth / KNIGHT_MAX_ANGER), 0, KNIGHT_MAX_ANGER)
	var/cooldown = ranged_cooldown_time - anger_modifier * 0.25
	if(in_dark_zone())
		cooldown *= 0.7
	ranged_cooldown = world.time + max(0.4 SECONDS, cooldown)
	INVOKE_ASYNC(src, PROC_REF(run_attack), client ? chosen_attack : choose_attack(fire_target), fire_target)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/choose_attack(atom/victim)
	if(!has_clear_path(victim))
		return pick(KNIGHT_QUICK_SLASH, KNIGHT_QUICK_SLASH, KNIGHT_BALL_WARP)
	var/list/options = list(KNIGHT_QUICK_SLASH, KNIGHT_QUICK_SLASH, KNIGHT_STAR_BURST, KNIGHT_SWORD_VOLLEY, KNIGHT_SPLIT_FLAME)
	if(get_dist(src, victim) > 3)
		options += list(KNIGHT_FLY_DASH, KNIGHT_FLY_DASH, KNIGHT_BALL_WARP, KNIGHT_HAND_VACUUM)
	else
		options += list(KNIGHT_FLURRY, KNIGHT_FLURRY, KNIGHT_FRONT_SLASH, KNIGHT_FRONT_SLASH)
	if(COOLDOWN_FINISHED(src, roar_cooldown))
		options += KNIGHT_ROAR
	if(COOLDOWN_FINISHED(src, fountain_cooldown) && length(fountains) < KNIGHT_MAX_FOUNTAINS)
		options += KNIGHT_DARK_FOUNTAIN
	return pick(options)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/run_attack(attack, atom/victim)
	switch(attack)
		if(KNIGHT_QUICK_SLASH)
			quick_slash(victim)
		if(KNIGHT_FLURRY)
			flurry(victim)
		if(KNIGHT_STAR_BURST)
			star_burst(victim)
		if(KNIGHT_SWORD_VOLLEY)
			sword_volley(victim)
		if(KNIGHT_FLY_DASH)
			fly_dash(victim)
		if(KNIGHT_BALL_WARP)
			ball_warp(victim)
		if(KNIGHT_ROAR)
			roar()
		if(KNIGHT_FRONT_SLASH)
			front_slash(victim)
		if(KNIGHT_HAND_VACUUM)
			hand_vacuum()
		if(KNIGHT_DARK_FOUNTAIN)
			open_dark_fountain(victim)
		if(KNIGHT_SPLIT_FLAME)
			split_flame(victim)
	if(client || QDELETED(src) || stat == DEAD || QDELETED(target))
		return
	if(prob(phase_two ? KNIGHT_PHASE_COMBO_CHANCE : KNIGHT_COMBO_CHANCE))
		OpenFire(target)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/has_clear_path(atom/destination)
	var/turf/start = get_turf(src)
	var/turf/end = get_turf(destination)
	if(!end || end.z != start.z)
		return FALSE
	for(var/turf/line_turf as anything in get_line(start, end))
		if(line_turf == start || line_turf == end)
			continue
		if(line_turf.is_blocked_turf(exclude_mobs = TRUE, ignore_atoms = fountains))
			return FALSE
	return TRUE

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/in_dark_zone()
	return locate(/obj/effect/dark_world_tile) in loc

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/phase_shift()
	while(acting)
		SLEEP_CHECK_DEATH(src, 1)
	begin_action("sword_form")
	ADD_TRAIT(src, TRAIT_GODMODE, INNATE_TRAIT)
	ranged_cooldown_time = 0.8 SECONDS
	move_to_delay = 1.5
	icon_living = "stance_alt"
	add_filter("knight_rage", 1, outline_filter(1, "#ff2020"))
	visible_message(span_userdanger("[DECLENT_RU_CAP(src, NOMINATIVE)] заново выковывает клинок из тьмы, и контур вспыхивает красным!"))
	playsound(src, 'sound/creatures/roaring_knight/voice_low.ogg', 100, FALSE, 10)
	playsound(src, 'sound/creatures/roaring_knight/roar_short.ogg', 100, FALSE, 10)
	new /obj/effect/temp_visual/roaring_knight/sword_break_ring(loc)
	for(var/mob/living/witness in range(KNIGHT_ROAR_RANGE, src))
		shake_camera(witness, 1 SECONDS, 3)
	for(var/obj/structure/dark_fountain/fountain as anything in fountains)
		fountain.erupt()
	SLEEP_CHECK_DEATH(src, 1 SECONDS)
	REMOVE_TRAIT(src, TRAIT_GODMODE, INNATE_TRAIT)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/begin_action(pose, atom/look_at, root = TRUE)
	acting = TRUE
	rooted = root
	icon_state = pose
	if(look_at)
		face_atom(look_at)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/finish_action()
	acting = FALSE
	rooted = FALSE
	icon_state = icon_living

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/refresh_facing()
	if(floating)
		return
	if(dir & EAST)
		transform = matrix(-1, 0, 0, 0, 1, 0)
	else if(dir & WEST)
		transform = matrix()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/set_floating(new_state, angle = 90)
	floating = new_state
	pixel_y = floating ? KNIGHT_FLOAT_PIXEL_Y : base_pixel_y
	var/matrix/turned = matrix()
	if(floating)
		turned.Turn(angle - 90)
	transform = turned
	refresh_facing()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/cut_turf(turf/cut_location, damage, list/already_hit, knockdown_time = 0)
	for(var/mob/living/victim in cut_location)
		if(victim == src || (victim in already_hit) || victim.stat == DEAD || faction_check_mob(victim))
			continue
		already_hit += victim
		var/limb_to_hit = victim.get_organ(pick(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
		var/armor = victim.run_armor_check(limb_to_hit, MELEE, armour_penetration = armour_penetration)
		victim.apply_damage(damage, BRUTE, limb_to_hit, armor)
		to_chat(victim, span_userdanger("[DECLENT_RU_CAP(src, NOMINATIVE)] рассекает вас!"))
		new /obj/effect/temp_visual/roaring_knight/red_slash_hit(cut_location, rand(0, 359))
		if(knockdown_time)
			victim.Knockdown(knockdown_time)
		if(victim.stat == DEAD)
			laugh()
	for(var/obj/mecha/mech in cut_location)
		if(mech in already_hit)
			continue
		already_hit += mech
		mech.take_damage(damage, BRUTE, MELEE)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/wreck_turf(turf/wreck_location)
	var/wrecked = FALSE
	for(var/obj/thing in wreck_location)
		if(QDELETED(thing) || thing.layer < LOW_OBJ_LAYER || !(isstructure(thing) || ismachinery(thing)))
			continue
		if(istype(thing, /obj/structure/dark_fountain) || (thing.resistance_flags & INDESTRUCTIBLE))
			continue
		thing.take_damage(KNIGHT_WRECK_DAMAGE, BRUTE, MELEE, FALSE, null, 100)
		wrecked = TRUE
	if(!isclosedturf(wreck_location))
		return wrecked
	var/old_type = wreck_location.type
	if(iswallturf(wreck_location))
		var/turf/simulated/wall/wall = wreck_location
		wall.dismantle_wall(TRUE)
	else
		wreck_location.ex_act(EXPLODE_DEVASTATE)
	if(wreck_location.type == old_type)
		return wrecked
	new /obj/effect/temp_visual/small_smoke/halfsecond(wreck_location)
	return TRUE

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/laugh()
	if(!COOLDOWN_FINISHED(src, laugh_cooldown))
		return
	COOLDOWN_START(src, laugh_cooldown, 15 SECONDS)
	playsound(src, 'sound/creatures/roaring_knight/laugh.ogg', 80, FALSE, 7)
	if(!acting)
		flick("laugh", src)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/quick_slash(atom/victim)
	var/turf/center = get_turf(victim)
	if(!center)
		return
	begin_action("slash_attack", victim, root = FALSE)
	var/slashes = 3 + round(anger_modifier / 10) + (phase_two ? 2 : 0)
	for(var/slash in 1 to slashes)
		var/angle = rand(0, 179)
		new /obj/effect/temp_visual/roaring_knight/line/warning(center, angle, KNIGHT_SLASH_LENGTH)
		playsound(center, 'sound/creatures/roaring_knight/cut_reverse.ogg', 50, TRUE, 3)
		addtimer(CALLBACK(src, PROC_REF(execute_slash), center, angle), KNIGHT_SLASH_WARNING_TIME)
		SLEEP_CHECK_DEATH(src, 0.15 SECONDS)
	SLEEP_CHECK_DEATH(src, KNIGHT_SLASH_WARNING_TIME)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/execute_slash(turf/center, angle)
	if(QDELETED(src) || stat == DEAD)
		return
	if(!floating)
		flick("flurry", src)
	cut_line(center, angle, KNIGHT_SLASH_LENGTH, wrecking = TRUE)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/cut_line(turf/center, angle, tiles, wrecking = FALSE)
	if(QDELETED(src) || stat == DEAD)
		return
	playsound(center, 'sound/creatures/roaring_knight/cut.ogg', 80, TRUE, 3)
	new /obj/effect/temp_visual/roaring_knight/line/slash(center, angle, tiles)
	var/list/already_hit = list()
	var/turf/first_end = get_turf_in_angle(angle, center, tiles) || center
	var/turf/second_end = get_turf_in_angle(angle + 180, center, tiles) || center
	var/wrecked_anything = FALSE
	for(var/turf/line_turf as anything in get_line(first_end, second_end))
		cut_turf(line_turf, 18, already_hit)
		if(wrecking && wreck_turf(line_turf))
			wrecked_anything = TRUE
	if(wrecked_anything)
		playsound(center, 'sound/effects/break_stone.ogg', 90, TRUE, 5)
		playsound(center, 'sound/effects/meteorimpact.ogg', 60, TRUE, 5)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/flurry(atom/victim)
	begin_action("flurry_prep", victim)
	playsound(src, 'sound/creatures/roaring_knight/jump.ogg', 70, TRUE)
	SLEEP_CHECK_DEATH(src, 0.2 SECONDS)
	for(var/strike in 1 to (phase_two ? 7 : 5))
		if(QDELETED(victim))
			break
		var/turf/victim_turf = get_turf(victim)
		var/list/landing_spots = list()
		for(var/turf/spot as anything in RANGE_TURFS(1, victim_turf))
			if(spot != victim_turf && !spot.is_blocked_turf(exclude_mobs = TRUE))
				landing_spots += spot
		if(length(landing_spots))
			new /obj/effect/temp_visual/decoy/fading/halfsecond(loc, src)
			forceMove(pick(landing_spots))
		face_atom(victim)
		flick("flurry", src)
		playsound(victim_turf, 'sound/creatures/roaring_knight/cut_light.ogg', 70, TRUE)
		if(prob(40))
			playsound(victim_turf, pick('sound/shadowdemon/shadowattack1.ogg', 'sound/shadowdemon/shadowattack2.ogg', 'sound/shadowdemon/shadowattack3.ogg', 'sound/shadowdemon/shadowattack4.ogg'), 50, TRUE)
		new /obj/effect/temp_visual/roaring_knight/red_slash(victim_turf, rand(0, 359))
		var/list/already_hit = list()
		for(var/turf/cut_location as anything in RANGE_TURFS(1, victim_turf))
			cut_turf(cut_location, 10, already_hit)
		SLEEP_CHECK_DEATH(src, 0.2 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/star_burst(atom/victim)
	var/turf/aim = get_turf(victim)
	var/turf/start = get_turf(src)
	if(!aim || aim == start)
		return
	begin_action("point", victim, root = FALSE)
	SLEEP_CHECK_DEATH(src, 0.25 SECONDS)
	playsound(src, 'sound/magic/magic_missile.ogg', 60, TRUE)
	var/base_angle = get_angle(start, aim)
	var/flight_range = clamp(get_dist(start, aim) + 1, 2, 9)
	for(var/spread in phase_two ? list(-50, -25, 0, 25, 50) : list(-25, 0, 25))
		fire_knight_bullet(/obj/projectile/roaring_knight/star, start, base_angle + spread, src, flight_range)
	SLEEP_CHECK_DEATH(src, 0.25 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/sword_volley(atom/victim)
	var/turf/center = get_turf(victim)
	if(!center)
		return
	begin_action("sword_appear", victim, root = FALSE)
	playsound(src, 'sound/weapons/blade_dark_unsheath.ogg', 70, TRUE)
	var/swords = 6 + round(anger_modifier / 5) + (phase_two ? 4 : 0)
	var/first_angle = rand(0, 359)
	for(var/sword in 1 to swords)
		var/angle = first_angle + sword * 360 / swords
		var/turf/spawn_turf
		for(var/radius in 6 to 2 step -1)
			var/turf/candidate = get_turf_in_angle(angle, center, radius)
			if(candidate && !isclosedturf(candidate))
				spawn_turf = candidate
				break
		if(!spawn_turf)
			continue
		var/aim_angle = get_angle(spawn_turf, center)
		new /obj/effect/temp_visual/roaring_knight/bullet/sword_ready(spawn_turf, aim_angle)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(fire_knight_bullet), /obj/projectile/roaring_knight/sword, spawn_turf, aim_angle, src, 13), 0.5 SECONDS)
	playsound(center, 'sound/creatures/roaring_knight/cut_reverse.ogg', 70, TRUE, 3)
	SLEEP_CHECK_DEATH(src, 0.6 SECONDS)
	playsound(center, 'sound/creatures/roaring_knight/cut.ogg', 70, TRUE)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/fly_dash(atom/victim)
	begin_action("fly_form", victim)
	playsound(src, 'sound/creatures/roaring_knight/swoon_rise.ogg', 80, FALSE, 5)
	SLEEP_CHECK_DEATH(src, 0.9 SECONDS)
	var/dashes = phase_two ? 3 : (anger_modifier >= (KNIGHT_MAX_ANGER / 4) ? 2 : 1)
	var/crashed = FALSE
	icon_state = "fly"
	for(var/dash in 1 to dashes)
		if(QDELETED(victim) || crashed)
			break
		var/turf/start = get_turf(src)
		var/turf/aim = get_turf(victim)
		if(aim == start)
			break
		var/angle = get_angle(start, aim)
		var/turf/destination = get_turf_in_angle(angle, start, KNIGHT_FLY_RANGE) || aim
		set_floating(TRUE, angle)
		icon_state = "fly_fast"
		playsound(start, 'sound/creatures/roaring_knight/jump.ogg', 80, TRUE)
		playsound(start, 'sound/creatures/roaring_knight/swoon_short.ogg', 80, TRUE, 5)
		var/list/already_hit = list()
		for(var/turf/next_turf as anything in get_line(start, destination) - start)
			for(var/obj/obstacle in next_turf)
				if(obstacle.density && !QDELETED(obstacle) && !istype(obstacle, /obj/structure/dark_fountain))
					obstacle.take_damage(obj_damage, BRUTE, MELEE)
			if(next_turf.is_blocked_turf(exclude_mobs = TRUE, ignore_atoms = fountains))
				crashed = TRUE
				break
			new /obj/effect/temp_visual/decoy/fading/halfsecond(loc, src)
			forceMove(next_turf)
			cut_turf(next_turf, 30, already_hit, 1.5 SECONDS)
			SLEEP_CHECK_DEATH(src, 0.5)
		set_floating(FALSE)
		icon_state = "fly"
		SLEEP_CHECK_DEATH(src, 0.15 SECONDS)
	if(crashed)
		playsound(src, 'sound/effects/meteorimpact.ogg', 80, TRUE, 5)
		for(var/mob/living/witness in range(5, src))
			shake_camera(witness, 0.5 SECONDS, 2)
		icon_state = "wall_hit"
		SLEEP_CHECK_DEATH(src, 0.7 SECONDS)
	else
		icon_state = "ball_burst"
		SLEEP_CHECK_DEATH(src, 0.3 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/ball_warp(atom/victim)
	var/turf/destination = get_turf(victim)
	if(!destination)
		return
	begin_action("ball_form", victim)
	playsound(src, 'sound/creatures/roaring_knight/jump.ogg', 80, TRUE)
	SLEEP_CHECK_DEATH(src, 0.2 SECONDS)
	icon_state = "ball"
	set_floating(TRUE)
	for(var/turf/next_turf as anything in get_line(get_turf(src), destination))
		forceMove(next_turf)
		SLEEP_CHECK_DEATH(src, 0.5)
	var/list/landing_spots = list()
	for(var/turf/spot as anything in RANGE_TURFS(1, destination))
		if(spot != destination && !spot.is_blocked_turf(exclude_mobs = TRUE))
			landing_spots += spot
	if(length(landing_spots))
		forceMove(pick(landing_spots))
	set_floating(FALSE)
	icon_state = "ball_burst"
	playsound(src, 'sound/magic/repulse.ogg', 60, TRUE)
	playsound(src, 'sound/creatures/roaring_knight/roar_short.ogg', 50, TRUE, 3)
	var/list/already_hit = list()
	for(var/turf/cut_location as anything in RANGE_TURFS(1, src))
		cut_turf(cut_location, 15, already_hit)
	for(var/angle in 0 to 315 step 45)
		fire_knight_bullet(/obj/projectile/roaring_knight/tooth, get_turf(src), angle, src, 8)
	SLEEP_CHECK_DEATH(src, 0.25 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/roar()
	if(!COOLDOWN_FINISHED(src, roar_cooldown))
		balloon_alert(src, "рокот ещё не готов!")
		return
	COOLDOWN_START(src, roar_cooldown, 20 SECONDS)
	begin_action("roar")
	playsound(src, 'sound/creatures/roaring_knight/roar.ogg', 100, FALSE, 15, ignore_walls = TRUE)
	SLEEP_CHECK_DEATH(src, 0.4 SECONDS)
	new /obj/effect/temp_visual/roaring_knight/sword_break_ring(loc)
	icon_state = "static"
	for(var/mob/living/witness in range(KNIGHT_ROAR_RANGE, src))
		shake_camera(witness, 3 SECONDS, 3)
		if(witness == src || faction_check_mob(witness))
			continue
		to_chat(witness, span_userdanger("Рокот проходит сквозь вас, и на миг мир теряет цвет!"))
		witness.Confused(5 SECONDS)
		witness.Stuttering(6 SECONDS)
		if(!witness.anchored)
			witness.throw_at(get_ranged_target_turf(witness, get_dir(src, witness), 3), 3, 2, src)
	for(var/obj/machinery/light/lamp in range(KNIGHT_LIGHT_BREAK_RANGE, src))
		if(prob(50))
			lamp.break_light_tube()
	if(length(fountains) >= KNIGHT_MAX_FOUNTAINS)
		visible_message(span_userdanger("Все тёмные фонтаны откликаются на рокот разом!"))
		for(var/obj/structure/dark_fountain/fountain as anything in fountains)
			fountain.erupt()
	SLEEP_CHECK_DEATH(src, 0.8 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/front_slash(atom/victim)
	var/turf/start = get_turf(src)
	var/turf/aim = get_turf(victim)
	if(!aim || aim == start)
		return
	var/angle = get_angle(start, aim)
	begin_action("front_rage", victim)
	playsound(src, 'sound/creatures/roaring_knight/roar_short.ogg', 70, TRUE, 5)
	var/list/cone = list()
	for(var/turf/cone_turf as anything in RANGE_TURFS(KNIGHT_FRONT_RANGE, start))
		if(cone_turf == start || get_dist(start, cone_turf) > KNIGHT_FRONT_RANGE)
			continue
		if(abs(closer_angle_difference(get_angle(start, cone_turf), angle)) > KNIGHT_FRONT_HALF_WIDTH)
			continue
		cone += cone_turf
		new /obj/effect/temp_visual/roaring_knight/tile_warning(cone_turf)
	SLEEP_CHECK_DEATH(src, 0.8 SECONDS)
	icon_state = "front_slash"
	playsound(src, 'sound/creatures/roaring_knight/cut_heavy.ogg', 100, FALSE, 7)
	playsound(src, 'sound/magic/repulse.ogg', 70, TRUE)
	new /obj/effect/temp_visual/roaring_knight/crescent(get_step(start, get_dir(start, aim)), angle)
	var/list/already_hit = list()
	var/wrecked_anything = FALSE
	for(var/turf/cone_turf as anything in cone)
		cut_turf(cone_turf, 35, already_hit, 2 SECONDS)
		if(wreck_turf(cone_turf))
			wrecked_anything = TRUE
	if(wrecked_anything)
		playsound(src, 'sound/effects/break_stone.ogg', 100, TRUE, 7)
		playsound(src, 'sound/effects/meteorimpact.ogg', 80, TRUE, 7)
	SLEEP_CHECK_DEATH(src, 0.4 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/hand_vacuum()
	begin_action("lift_arm")
	playsound(src, 'sound/creatures/roaring_knight/hand_vacuum.ogg', 90, FALSE, 7)
	SLEEP_CHECK_DEATH(src, 0.4 SECONDS)
	icon_state = "down_grab"
	for(var/pull in 1 to KNIGHT_VACUUM_PULLS)
		for(var/mob/living/victim in range(KNIGHT_VACUUM_RANGE, src))
			if(victim == src || victim.anchored || victim.buckled || faction_check_mob(victim))
				continue
			if(HAS_TRAIT(victim, TRAIT_NEGATES_GRAVITY) || !has_clear_path(victim))
				continue
			step_towards(victim, src)
		for(var/obj/item/loose_item in range(KNIGHT_VACUUM_RANGE, src))
			if(!loose_item.anchored && has_clear_path(loose_item))
				step_towards(loose_item, src)
		SLEEP_CHECK_DEATH(src, 0.25 SECONDS)
	icon_state = "down_look"
	new /obj/effect/temp_visual/roaring_knight/swipe(loc)
	playsound(src, 'sound/creatures/roaring_knight/cut_heavy.ogg', 100, FALSE, 3)
	var/list/already_hit = list()
	for(var/turf/cut_location as anything in RANGE_TURFS(2, src))
		cut_turf(cut_location, 30, already_hit, 1.5 SECONDS)
	SLEEP_CHECK_DEATH(src, 0.3 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/open_dark_fountain(atom/where)
	if(!COOLDOWN_FINISHED(src, fountain_cooldown))
		balloon_alert(src, "фонтан ещё не готов!")
		return
	if(length(fountains) >= KNIGHT_MAX_FOUNTAINS)
		balloon_alert(src, "слишком много фонтанов!")
		return
	var/turf/spot = find_fountain_spot(where)
	if(!spot)
		balloon_alert(src, "здесь фонтан не открыть!")
		return
	COOLDOWN_START(src, fountain_cooldown, 12 SECONDS)
	begin_action("throw_swords", spot)
	visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] заносит над собой клинки!"))
	SLEEP_CHECK_DEATH(src, 0.75 SECONDS)
	new /obj/effect/temp_visual/roaring_knight/bullet/planted_sword(spot)
	playsound(spot, 'sound/creatures/roaring_knight/cut_heavy.ogg', 80, FALSE, 5)
	SLEEP_CHECK_DEATH(src, 0.25 SECONDS)
	new /obj/structure/dark_fountain(spot, src)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/split_flame(atom/victim)
	var/turf/start = get_turf(src)
	var/turf/aim = get_turf(victim)
	if(!aim || aim == start)
		return
	begin_action("sword_glow", victim)
	playsound(src, 'sound/magic/fireball.ogg', 70, TRUE, 3)
	SLEEP_CHECK_DEATH(src, 0.3 SECONDS)
	icon_state = "slash_attack"
	playsound(src, 'sound/creatures/roaring_knight/cut.ogg', 80, TRUE, 3)
	var/base_angle = get_angle(start, aim)
	for(var/spread in phase_two ? list(-60, -30, 0, 30, 60) : list(-30, 0, 30))
		INVOKE_ASYNC(src, PROC_REF(flame_wave), start, base_angle + spread)
	SLEEP_CHECK_DEATH(src, 0.3 SECONDS)
	finish_action()

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/flame_wave(turf/start, angle)
	var/list/already_hit = list()
	for(var/distance in 1 to KNIGHT_FLAME_RANGE)
		var/turf/flame_turf = get_turf_in_angle(angle, start, distance)
		if(!flame_turf || isclosedturf(flame_turf))
			return
		new /obj/effect/temp_visual/roaring_knight/bullet/dark_fire(flame_turf)
		cut_turf(flame_turf, 12, already_hit)
		SLEEP_CHECK_DEATH(src, 0.5)

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/find_fountain_spot(atom/where)
	var/turf/spot = get_turf(where)
	if(client)
		return can_hold_fountain(spot) ? spot : null
	var/list/spots = list()
	for(var/turf/candidate as anything in RANGE_TURFS(4, src))
		if(can_hold_fountain(candidate))
			spots += candidate
	return length(spots) ? pick(spots) : null

/mob/living/simple_animal/hostile/megafauna/roaring_knight/proc/can_hold_fountain(turf/spot)
	if(!spot || spot.is_blocked_turf() || isspaceturf(spot))
		return FALSE
	for(var/obj/structure/dark_fountain/fountain as anything in fountains)
		if(get_dist(spot, fountain) < KNIGHT_FOUNTAIN_SPACING)
			return FALSE
	return TRUE

/datum/action/innate/megafauna_attack/knight_quick_slash
	name = "Быстрый разрез"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "quickslash"
	chosen_message = span_colossus_alt("Вы рассечёте пространство линиями через цель.")
	chosen_attack_num = KNIGHT_QUICK_SLASH

/datum/action/innate/megafauna_attack/knight_flurry
	name = "Шквал"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "flurry"
	chosen_message = span_colossus_alt("Вы обрушите на цель серию ударов со всех сторон.")
	chosen_attack_num = KNIGHT_FLURRY

/datum/action/innate/megafauna_attack/knight_star_burst
	name = "Звёзды"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "star"
	chosen_message = span_colossus_alt("Вы выпустите звёзды, которые раскроются роем осколков.")
	chosen_attack_num = KNIGHT_STAR_BURST

/datum/action/innate/megafauna_attack/knight_sword_volley
	name = "Кольцо мечей"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "swords"
	chosen_message = span_colossus_alt("Вокруг цели появятся мечи и сойдутся в одной точке.")
	chosen_attack_num = KNIGHT_SWORD_VOLLEY

/datum/action/innate/megafauna_attack/knight_fly_dash
	name = "Чёрный полёт"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "fly"
	chosen_message = span_colossus_alt("Вы растечётесь тенью и пронесётесь сквозь цель.")
	chosen_attack_num = KNIGHT_FLY_DASH

/datum/action/innate/megafauna_attack/knight_ball_warp
	name = "Сгусток"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "ball"
	chosen_message = span_colossus_alt("Вы сожмётесь в шар, пройдёте сквозь стены и взорвётесь рядом с целью.")
	chosen_attack_num = KNIGHT_BALL_WARP

/datum/action/innate/megafauna_attack/knight_roar
	name = "Рокот"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "roar"
	chosen_message = span_colossus_alt("Ваш рокот оглушит всех вокруг и разобьёт лампы. Три фонтана ответят на него.")
	chosen_attack_num = KNIGHT_ROAR

/datum/action/innate/megafauna_attack/knight_front_slash
	name = "Фронтальный разрез"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "front_slash"
	chosen_message = span_colossus_alt("Вы рассечёте широким полумесяцем всё перед собой.")
	chosen_attack_num = KNIGHT_FRONT_SLASH

/datum/action/innate/megafauna_attack/knight_hand_vacuum
	name = "Втягивающая длань"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "vacuum"
	chosen_message = span_colossus_alt("Вы притянете к себе всё незакреплённое и ударите вплотную.")
	chosen_attack_num = KNIGHT_HAND_VACUUM

/datum/action/innate/megafauna_attack/knight_dark_fountain
	name = "Открыть тёмный фонтан"
	button_icon = 'icons/mob/roaring_knight/actions.dmi'
	button_icon_state = "fountain"
	chosen_message = span_colossus_alt("Вы откроете тёмный фонтан на выбранной клетке.")
	chosen_attack_num = KNIGHT_DARK_FOUNTAIN

/datum/action/innate/megafauna_attack/knight_split_flame
	name = "Расколотое пламя"
	button_icon = 'icons/mob/roaring_knight/bullets.dmi'
	button_icon_state = "dark_fire"
	chosen_message = span_colossus_alt("Вы пустите по полу расходящиеся волны тёмного пламени.")
	chosen_attack_num = KNIGHT_SPLIT_FLAME

#undef KNIGHT_QUICK_SLASH
#undef KNIGHT_FLURRY
#undef KNIGHT_STAR_BURST
#undef KNIGHT_SWORD_VOLLEY
#undef KNIGHT_FLY_DASH
#undef KNIGHT_BALL_WARP
#undef KNIGHT_ROAR
#undef KNIGHT_FRONT_SLASH
#undef KNIGHT_HAND_VACUUM
#undef KNIGHT_DARK_FOUNTAIN
#undef KNIGHT_SPLIT_FLAME

#undef KNIGHT_MAX_ANGER
#undef KNIGHT_SLASH_LENGTH
#undef KNIGHT_SLASH_WARNING_TIME
#undef KNIGHT_FLY_RANGE
#undef KNIGHT_ROAR_RANGE
#undef KNIGHT_LIGHT_BREAK_RANGE
#undef KNIGHT_VACUUM_RANGE
#undef KNIGHT_VACUUM_PULLS
#undef KNIGHT_FRONT_RANGE
#undef KNIGHT_FRONT_HALF_WIDTH
#undef KNIGHT_MAX_FOUNTAINS
#undef KNIGHT_FOUNTAIN_SPACING
#undef KNIGHT_FLOAT_PIXEL_Y
#undef KNIGHT_WRECK_DAMAGE
#undef KNIGHT_DEFLECT_CHANCE
#undef KNIGHT_PHASE_DEFLECT_CHANCE
#undef KNIGHT_COMBO_CHANCE
#undef KNIGHT_PHASE_COMBO_CHANCE
#undef KNIGHT_FLAME_RANGE
#undef KNIGHT_DARK_ZONE_HEAL
