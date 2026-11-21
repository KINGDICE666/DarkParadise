#define LIVING_CRYSTAL_COOLDOWN (5 SECONDS)
#define LIVING_CRYSTAL_RING_SHARDS 16
#define LIVING_CRYSTAL_SPIRAL_SHOTS 30
#define LIVING_CRYSTAL_SPIKE_LENGTH 9
#define LIVING_CRYSTAL_SPIKE_SPREAD 25
#define LIVING_CRYSTAL_SPIKE_DAMAGE 15
#define LIVING_CRYSTAL_PULSE_RANGE 3
#define LIVING_CRYSTAL_PULSE_PUSH 4
#define LIVING_CRYSTAL_PULSE_DAMAGE 10
#define LIVING_CRYSTAL_SUMMON_EVERY (40 SECONDS)
#define LIVING_CRYSTAL_SUMMON_COUNT 2
#define LIVING_CRYSTAL_MINION_CAP 4

/mob/living/simple_animal/hostile/megafauna/living_crystal
	name = "living crystal"
	desc = "Огромный парящий кристалл плазмы, окружённый роем острых осколков. Внутри пульсирует холодный свет."
	health = 1200
	maxHealth = 1200
	icon = 'icons/mob/living_crystal.dmi'
	icon_state = "living_crystal"
	icon_living = "living_crystal"
	icon_dead = "living_crystal_dead"
	pixel_x = -16
	base_pixel_x = -16
	attacktext = "рассекает осколками"
	attack_sound = 'sound/effects/glassbr2.ogg'
	friendly = "звенит на"
	speak_emote = list("звенит")
	armour_penetration = 20
	melee_damage_lower = 15
	melee_damage_upper = 20
	speed = 6
	move_to_delay = 6
	ranged = TRUE
	ranged_cooldown_time = LIVING_CRYSTAL_COOLDOWN
	faction = list(FACTION_PLASMA_WORLD, "boss")
	light_range = 4
	light_power = 1.2
	light_color = "#d070ff"
	loot = list(/obj/item/stack/sheet/mineral/plasma/fifty, /obj/item/stack/ore/bluespace_crystal, /obj/item/disk/autopilot_upgrade)
	crusher_loot = list(/obj/item/stack/sheet/mineral/plasma/fifty, /obj/item/stack/ore/bluespace_crystal, /obj/item/disk/autopilot_upgrade)
	deathmessage = "раскалывается и с оглушительным звоном осыпается грудой осколков."
	death_sound = 'sound/effects/glassbr3.ogg'
	var/next_summon = 0

/mob/living/simple_animal/hostile/megafauna/living_crystal/get_ru_names()
	return alist(
		NOMINATIVE = "живой кристалл",
		GENITIVE = "живого кристалла",
		DATIVE = "живому кристаллу",
		ACCUSATIVE = "живой кристалл",
		INSTRUMENTAL = "живым кристаллом",
		PREPOSITIONAL = "живом кристалле",
	)

/mob/living/simple_animal/hostile/megafauna/living_crystal/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)
	AddElement(/datum/element/simple_flying)

/mob/living/simple_animal/hostile/megafauna/living_crystal/OpenFire(atom/target_atom)
	anger_modifier = clamp((maxHealth - health) / 75, 0, 20)
	ranged_cooldown = world.time + LIVING_CRYSTAL_COOLDOWN
	if(health <= maxHealth / 2 && world.time >= next_summon)
		summon_minions()
		return
	if(get_dist(src, target_atom) <= LIVING_CRYSTAL_PULSE_RANGE && prob(50))
		resonance_pulse()
	else if(prob(20 + anger_modifier))
		shard_spiral()
	else if(prob(50))
		spike_lines(target_atom)
	else
		shard_ring()

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/telegraph(delay = 1 SECONDS)
	icon_state = "living_crystal_attack"
	for(var/mob/viewer in range(9, src))
		if(viewer.client)
			flash_color(viewer.client, "#b050ff", 0.5 SECONDS)
	playsound(src, 'sound/creatures/living_crystal/living_crystal_roar.ogg', 70, TRUE)
	SLEEP_CHECK_DEATH(src, delay)
	return TRUE

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/calm_down()
	icon_state = icon_living

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/shoot_shard(angle)
	var/turf/origin = get_turf(src)
	var/obj/projectile/living_crystal_shard/shard = new(origin)
	shard.preparePixelProjectile(get_step(origin, angle2dir(angle)), src)
	shard.firer = src
	shard.fire(angle || 360)

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/shard_ring()
	if(!telegraph())
		return
	var/rings = health <= maxHealth / 2 ? 3 : 2
	for(var/ring in 1 to rings)
		playsound(src, 'sound/creatures/living_crystal/living_crystal_attack.ogg', 50, TRUE)
		for(var/shard in 1 to LIVING_CRYSTAL_RING_SHARDS)
			shoot_shard((shard + (ring % 2) / 2) * 360 / LIVING_CRYSTAL_RING_SHARDS)
		SLEEP_CHECK_DEATH(src, 0.8 SECONDS)
	calm_down()

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/shard_spiral()
	if(!telegraph(1.5 SECONDS))
		return
	var/arms = health <= maxHealth / 3 ? 3 : 2
	var/turn_dir = pick(-1, 1)
	playsound(src, 'sound/creatures/living_crystal/living_crystal_attack.ogg', 70, TRUE)
	for(var/shot in 1 to LIVING_CRYSTAL_SPIRAL_SHOTS)
		for(var/arm in 1 to arms)
			shoot_shard((shot * 14 * turn_dir + arm * 360 / arms) % 360)
		SLEEP_CHECK_DEATH(src, 1)
	calm_down()

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/spike_lines(atom/target_atom)
	var/base_angle = get_angle(src, target_atom)
	var/list/lines = list()
	for(var/offset in list(-LIVING_CRYSTAL_SPIKE_SPREAD, 0, LIVING_CRYSTAL_SPIKE_SPREAD))
		var/list/line = list()
		for(var/step in 1 to LIVING_CRYSTAL_SPIKE_LENGTH)
			var/turf/spot = locate(x + round(step * sin(base_angle + offset)), y + round(step * cos(base_angle + offset)), z)
			if(!spot || spot.density)
				break
			line += spot
			new /obj/effect/temp_visual/living_crystal_warning(spot)
		lines += list(line)
	if(!telegraph())
		return
	playsound(src, 'sound/creatures/living_crystal/living_crystal_attack.ogg', 70, TRUE)
	for(var/step in 1 to LIVING_CRYSTAL_SPIKE_LENGTH)
		for(var/list/line as anything in lines)
			if(step <= length(line))
				erupt_spike(line[step])
		SLEEP_CHECK_DEATH(src, 1)
	calm_down()

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/erupt_spike(turf/spot)
	new /obj/effect/temp_visual/living_crystal_spike(spot)
	playsound(spot, 'sound/effects/glassbr1.ogg', 30, TRUE)
	for(var/mob/living/victim in spot)
		if(faction_check_mob(victim))
			continue
		to_chat(victim, span_userdanger("Из земли вырывается кристаллический шип!"))
		victim.apply_damage(LIVING_CRYSTAL_SPIKE_DAMAGE, BRUTE)
		victim.Knockdown(1 SECONDS)

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/resonance_pulse()
	if(!telegraph(0.8 SECONDS))
		return
	new /obj/effect/temp_visual/plasma_crystal_wave(loc)
	playsound(src, 'sound/creatures/living_crystal/living_crystal_attack.ogg', 80, TRUE)
	for(var/mob/living/victim in range(LIVING_CRYSTAL_PULSE_RANGE, src))
		if(victim == src || faction_check_mob(victim))
			continue
		to_chat(victim, span_userdanger("Резонансная волна отбрасывает вас!"))
		victim.apply_damage(LIVING_CRYSTAL_PULSE_DAMAGE, BRUTE)
		shake_camera(victim, 1 SECONDS, 2)
		if(!victim.anchored && !victim.buckled)
			victim.throw_at(get_ranged_target_turf(victim, get_dir(src, victim) || pick(GLOB.alldirs), LIVING_CRYSTAL_PULSE_PUSH), LIVING_CRYSTAL_PULSE_PUSH, 2)
	calm_down()

/mob/living/simple_animal/hostile/megafauna/living_crystal/proc/summon_minions()
	next_summon = world.time + LIVING_CRYSTAL_SUMMON_EVERY
	var/alive = 0
	for(var/mob/living/simple_animal/hostile/asteroid/crystal_plasmaman/minion in range(9, src))
		if(minion.stat != DEAD)
			alive++
	if(alive >= LIVING_CRYSTAL_MINION_CAP)
		return
	if(!telegraph())
		return
	visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] издаёт пронзительный звон, и из земли поднимаются кристаллические фигуры!"))
	var/list/spots = list()
	for(var/turf/spot in orange(2, src))
		if(!spot.is_blocked_turf(exclude_mobs = FALSE) && !ischasm(spot))
			spots += spot
	for(var/summon in 1 to min(LIVING_CRYSTAL_SUMMON_COUNT, LIVING_CRYSTAL_MINION_CAP - alive))
		if(!length(spots))
			break
		var/turf/spot = pick_n_take(spots)
		new /obj/effect/temp_visual/living_crystal_spike(spot)
		new /mob/living/simple_animal/hostile/asteroid/crystal_plasmaman(spot)
	calm_down()

/obj/projectile/living_crystal_shard
	name = "crystal shard"
	icon = 'icons/effects/crystal_attacks.dmi'
	icon_state = "crystal_shard"
	damage = 9
	armour_penetration = 20
	speed = 3
	light_system = OVERLAY_LIGHT
	light_range = 1
	light_color = "#d070ff"

/obj/projectile/living_crystal_shard/get_ru_names()
	return alist(
		NOMINATIVE = "кристаллический осколок",
		GENITIVE = "кристаллического осколка",
		DATIVE = "кристаллическому осколку",
		ACCUSATIVE = "кристаллический осколок",
		INSTRUMENTAL = "кристаллическим осколком",
		PREPOSITIONAL = "кристаллическом осколке",
	)

/obj/effect/temp_visual/living_crystal_warning
	icon = 'icons/effects/crystal_attacks.dmi'
	icon_state = "crystal_warning"
	layer = BELOW_MOB_LAYER
	randomdir = FALSE
	duration = 2 SECONDS

/obj/effect/temp_visual/living_crystal_spike
	icon = 'icons/effects/crystal_attacks.dmi'
	icon_state = "crystal_spike"
	randomdir = FALSE
	light_range = 1
	light_color = "#d070ff"

/obj/effect/temp_visual/living_crystal_spike/Initialize(mapload)
	. = ..()
	animate(src, alpha = 255, time = duration - 0.3 SECONDS)
	animate(alpha = 0, time = 0.3 SECONDS)

#undef LIVING_CRYSTAL_COOLDOWN
#undef LIVING_CRYSTAL_RING_SHARDS
#undef LIVING_CRYSTAL_SPIRAL_SHOTS
#undef LIVING_CRYSTAL_SPIKE_LENGTH
#undef LIVING_CRYSTAL_SPIKE_SPREAD
#undef LIVING_CRYSTAL_SPIKE_DAMAGE
#undef LIVING_CRYSTAL_PULSE_RANGE
#undef LIVING_CRYSTAL_PULSE_PUSH
#undef LIVING_CRYSTAL_PULSE_DAMAGE
#undef LIVING_CRYSTAL_SUMMON_EVERY
#undef LIVING_CRYSTAL_SUMMON_COUNT
#undef LIVING_CRYSTAL_MINION_CAP
