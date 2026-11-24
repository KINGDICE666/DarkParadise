#define PVE_ENEMY_SMASH_COOLDOWN (1 SECONDS)
#define PVE_ENEMY_STUCK_TIME (40 SECONDS)
#define PVE_ELITE_HEALTH_MULT 2.2
#define PVE_ELITE_DAMAGE_MULT 1.4
#define PVE_ELITE_BOUNTY_MULT 3
#define PVE_BOMBER_DAMAGE 30
#define PVE_BOMBER_OBJ_DAMAGE 90
#define PVE_SHAMAN_HEAL 15
#define PVE_SHAMAN_RANGE 5
#define PVE_CHARGE_DAMAGE 30
#define PVE_CHARGE_RANGE 8
#define PVE_TREASURE_ESCAPE_TIME (45 SECONDS)
#define PVE_CARRIER_BROOD 3
#define PVE_STALKER_REVEAL_RANGE 2
#define PVE_STALKER_HIDDEN_ALPHA 35
#define PVE_STALKER_REVEAL_TIME (3 SECONDS)
#define PVE_HOWLER_RANGE 5
#define PVE_HOWLER_COOLDOWN (7 SECONDS)
#define PVE_RALLY_DURATION (6 SECONDS)
#define PVE_RALLY_DAMAGE_MULT 1.4

/mob/living/simple_animal/hostile/pve
	abstract_type = /mob/living/simple_animal/hostile/pve
	name = "fog spawn"
	desc = "Тварь, выползшая из красного тумана."
	faction = list(PVE_FACTION_ENEMY)
	maxHealth = 40
	health = 40
	melee_damage_lower = 8
	melee_damage_upper = 8
	obj_damage = 20
	move_to_delay = 4
	speed = 0
	AI_delay_max = 0 SECONDS
	vision_range = 8
	aggro_vision_range = 10
	robust_searching = TRUE
	stat_attack = UNCONSCIOUS
	wander = FALSE
	dodging = FALSE
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES | ENVIRONMENT_SMASH_WALLS
	lose_patience_timeout = 15 SECONDS
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 0
	sentience_type = SENTIENCE_BOSS
	wanted_objects = list(/obj/structure/pve_core)
	attacktext = "рвёт"
	attack_sound = 'sound/weapons/bite.ogg'
	speak_emote = list("рычит")
	var/bounty = 5
	var/spawn_cost = 1
	var/unlock_wave = 1
	var/spawn_weight = 0
	var/group_size = 1
	var/elite = FALSE
	var/last_hit_melee = FALSE
	var/datum/weakref/last_hitter
	var/turf/last_turf
	var/last_activity = 0
	COOLDOWN_DECLARE(smash_cooldown)

/mob/living/simple_animal/hostile/pve/Initialize(mapload)
	. = ..()
	last_activity = world.time

/mob/living/simple_animal/hostile/pve/Destroy()
	last_hitter = null
	last_turf = null
	return ..()

/mob/living/simple_animal/hostile/pve/examine(mob/user)
	. = ..()
	if(elite)
		. += span_warning("Элитная особь: крепче, сильнее и ценнее обычных.")

/mob/living/simple_animal/hostile/pve/proc/get_mode()
	var/datum/game_mode/pve/mode = SSticker.mode
	return istype(mode) ? mode : null

/mob/living/simple_animal/hostile/pve/proc/apply_scaling(health_multiplier, damage_multiplier, speed_multiplier)
	maxHealth = round(maxHealth * health_multiplier)
	health = maxHealth
	melee_damage_lower = round(melee_damage_lower * damage_multiplier)
	melee_damage_upper = round(melee_damage_upper * damage_multiplier)
	move_to_delay = max(1, move_to_delay * speed_multiplier)

/mob/living/simple_animal/hostile/pve/proc/make_elite()
	elite = TRUE
	apply_scaling(PVE_ELITE_HEALTH_MULT, PVE_ELITE_DAMAGE_MULT, 1)
	bounty *= PVE_ELITE_BOUNTY_MULT
	transform = transform.Scale(1.15)
	add_filter("pve_elite", 2, outline_filter(1, "#ffcc33"))

/mob/living/simple_animal/hostile/pve/ListTargets()
	. = ..()
	var/datum/game_mode/pve/mode = get_mode()
	if(mode?.core && mode.core.z == z)
		. += mode.core

/mob/living/simple_animal/hostile/pve/handle_automated_action()
	. = ..()
	if(!. || stat)
		return
	if(loc != last_turf || (target && targets_from.Adjacent(target)))
		last_turf = loc
		last_activity = world.time
	else if(world.time > last_activity + PVE_ENEMY_STUCK_TIME)
		unstuck()
		return
	if(!ismob(target))
		FindTarget()

/mob/living/simple_animal/hostile/pve/proc/unstuck()
	last_activity = world.time
	var/datum/game_mode/pve/mode = get_mode()
	if(!length(mode?.enemy_spawns))
		return
	lose_target()
	forceMove(pick(mode.enemy_spawns))

/mob/living/simple_animal/hostile/pve/Goto(target, delay, minimum_distance, timeout)
	var/datum/game_mode/pve/mode = get_mode()
	if(!mode?.flow_field)
		return ..()
	approaching_target = (target == src.target)
	var/glide_flag = delay > END_GLIDE_SPEED ? MOVEMENT_LOOP_IGNORE_GLIDE : NONE
	return GLOB.move_manager.add_to_loop(src, SSmovement, /datum/move_loop/has_target/dist_bound/move_to/pve_flow, MOVEMENT_DEFAULT_PRIORITY, glide_flag, mode.flow_field, delay, timeout, target, minimum_distance)

/mob/living/simple_animal/hostile/pve/Bump(atom/bumped)
	. = ..()
	if(stat || client || !COOLDOWN_FINISHED(src, smash_cooldown))
		return
	if(isobj(bumped))
		var/obj/obstacle = bumped
		if(!obstacle.density || (obstacle.resistance_flags & INDESTRUCTIBLE))
			return
	else if(!iswallturf(bumped) || istype(bumped, /turf/simulated/wall/indestructible))
		return
	COOLDOWN_START(src, smash_cooldown, PVE_ENEMY_SMASH_COOLDOWN)
	last_activity = world.time
	face_atom(bumped)
	bumped.attack_animal(src)

/mob/living/simple_animal/hostile/pve/projectile_allow_through(obj/projectile/projectile, border_dir)
	if(stat == DEAD)
		return ..()
	return IS_PVE_ENEMY(projectile.firer)

/mob/living/simple_animal/hostile/pve/bullet_act(obj/projectile/proj)
	note_attacker(proj.firer || proj.firer_source_atom)
	return ..()

/mob/living/simple_animal/hostile/pve/proceed_attack_results(obj/item/I, mob/living/user, params, def_zone)
	note_attacker(user, melee = TRUE)
	return ..()

/mob/living/simple_animal/hostile/pve/proc/note_attacker(atom/attacker, melee = FALSE)
	last_hit_melee = melee
	if(istype(attacker, /obj/machinery/porta_turret/syndicate/pve))
		var/obj/machinery/porta_turret/syndicate/pve/turret = attacker
		if(turret.owner_mind)
			last_hitter = turret.owner_mind
		return
	if(!ismob(attacker))
		return
	var/mob/attacker_mob = attacker
	if(attacker_mob.mind && !IS_PVE_ENEMY(attacker_mob))
		last_hitter = WEAKREF(attacker_mob.mind)

/mob/living/simple_animal/hostile/pve/grunt
	name = "faceless"
	desc = "Сгорбленная фигура без лица. Медленно, но неумолимо бредёт к живым."
	icon_state = "faithless"
	icon_living = "faithless"
	icon_dead = "faithless_dead"
	maxHealth = 45
	health = 45
	bounty = 8
	attacktext = "душит"
	attack_sound = 'sound/hallucinations/growl1.ogg'
	spawn_weight = 10

/mob/living/simple_animal/hostile/pve/grunt/get_ru_names()
	return alist(
		NOMINATIVE = "безликий",
		GENITIVE = "безликого",
		DATIVE = "безликому",
		ACCUSATIVE = "безликого",
		INSTRUMENTAL = "безликим",
		PREPOSITIONAL = "безликом",
	)

/mob/living/simple_animal/hostile/pve/runner
	name = "fog hound"
	desc = "Тощая гончая с горящими глазами. Быстрая и хрупкая, нападает стаей."
	icon_state = "hellhound"
	icon_living = "hellhound"
	icon_dead = "hellhound_dead"
	maxHealth = 30
	health = 30
	melee_damage_lower = 6
	melee_damage_upper = 6
	move_to_delay = 2
	rapid_melee = 2
	dodging = TRUE
	bounty = 6
	attacktext = "кусает"
	unlock_wave = 2
	spawn_weight = 7

/mob/living/simple_animal/hostile/pve/runner/get_ru_names()
	return alist(
		NOMINATIVE = "туманная гончая",
		GENITIVE = "туманной гончей",
		DATIVE = "туманной гончей",
		ACCUSATIVE = "туманную гончую",
		INSTRUMENTAL = "туманной гончей",
		PREPOSITIONAL = "туманной гончей",
	)

/mob/living/simple_animal/hostile/pve/spitter
	name = "spitter"
	desc = "Вытянутая тварь с раздутым зобом. Держится на расстоянии и плюётся кислотой."
	icon = 'icons/mob/alien.dmi'
	icon_state = "aliens_running"
	icon_living = "aliens_running"
	icon_dead = "aliens_dead"
	melee_damage_lower = 5
	melee_damage_upper = 5
	bounty = 12
	ranged = TRUE
	projectiletype = /obj/projectile/pve_enemy/spit
	projectilesound = 'sound/effects/splat.ogg'
	ranged_message = "плюётся кислотой"
	ranged_cooldown_time = 2.5 SECONDS
	ranged_distance = 7
	retreat_distance = 2
	minimum_distance = 4
	check_friendly_fire = TRUE
	spawn_cost = 2
	unlock_wave = 3
	spawn_weight = 5

/mob/living/simple_animal/hostile/pve/spitter/get_ru_names()
	return alist(
		NOMINATIVE = "плевун",
		GENITIVE = "плевуна",
		DATIVE = "плевуну",
		ACCUSATIVE = "плевуна",
		INSTRUMENTAL = "плевуном",
		PREPOSITIONAL = "плевуне",
	)

/mob/living/simple_animal/hostile/pve/bomber
	name = "bloater"
	desc = "Раздутый мешок плоти. Взрывается рядом с жертвой или после смерти, задевая и своих."
	icon_state = "otherthing-pink"
	icon_living = "otherthing-pink"
	icon_dead = "otherthing-pink-dead"
	maxHealth = 35
	health = 35
	melee_damage_lower = 0
	melee_damage_upper = 0
	move_to_delay = 3
	bounty = 10
	del_on_death = TRUE
	var/exploded = FALSE
	spawn_cost = 2
	unlock_wave = 4
	spawn_weight = 4

/mob/living/simple_animal/hostile/pve/bomber/get_ru_names()
	return alist(
		NOMINATIVE = "пузырь",
		GENITIVE = "пузыря",
		DATIVE = "пузырю",
		ACCUSATIVE = "пузыря",
		INSTRUMENTAL = "пузырём",
		PREPOSITIONAL = "пузыре",
	)

/mob/living/simple_animal/hostile/pve/bomber/AttackingTarget()
	death()
	return TRUE

/mob/living/simple_animal/hostile/pve/bomber/death(gibbed)
	if(!exploded && stat != DEAD)
		detonate()
	return ..()

/mob/living/simple_animal/hostile/pve/bomber/proc/detonate()
	exploded = TRUE
	var/turf/center = get_turf(src)
	new /obj/effect/temp_visual/explosion(center, 1, "#c03050", TRUE)
	playsound(center, 'sound/effects/splat.ogg', 100, TRUE)
	for(var/mob/living/victim in range(1, center))
		if(victim == src || victim.stat == DEAD)
			continue
		if(IS_PVE_ENEMY(victim))
			var/mob/living/simple_animal/hostile/pve/neighbour = victim
			neighbour.last_hitter ||= last_hitter
		victim.apply_damage(PVE_BOMBER_DAMAGE, BRUTE)
	for(var/obj/structure/thing in range(1, center))
		if(!(thing.resistance_flags & INDESTRUCTIBLE))
			thing.take_damage(PVE_BOMBER_OBJ_DAMAGE, BRUTE, MELEE)
	for(var/obj/machinery/thing in range(1, center))
		if(!(thing.resistance_flags & INDESTRUCTIBLE))
			thing.take_damage(PVE_BOMBER_OBJ_DAMAGE, BRUTE, MELEE)

/mob/living/simple_animal/hostile/pve/shaman
	name = "fog shaman"
	desc = "Многорукое существо, сплетающее туман. Подлечивает сородичей неподалёку. Убивайте первым."
	icon_state = "mi-go"
	icon_living = "mi-go"
	icon_dead = "mi-go-dead"
	maxHealth = 70
	health = 70
	melee_damage_lower = 5
	melee_damage_upper = 5
	bounty = 25
	retreat_distance = 4
	minimum_distance = 5
	COOLDOWN_DECLARE(heal_cooldown)
	spawn_cost = 4
	unlock_wave = 8
	spawn_weight = 2

/mob/living/simple_animal/hostile/pve/shaman/get_ru_names()
	return alist(
		NOMINATIVE = "шаман тумана",
		GENITIVE = "шамана тумана",
		DATIVE = "шаману тумана",
		ACCUSATIVE = "шамана тумана",
		INSTRUMENTAL = "шаманом тумана",
		PREPOSITIONAL = "шамане тумана",
	)

/mob/living/simple_animal/hostile/pve/shaman/handle_automated_action()
	. = ..()
	if(!. || stat || !COOLDOWN_FINISHED(src, heal_cooldown))
		return
	COOLDOWN_START(src, heal_cooldown, 5 SECONDS)
	var/healed = FALSE
	for(var/mob/living/simple_animal/hostile/pve/kin in range(PVE_SHAMAN_RANGE, src))
		if(kin == src || kin.stat == DEAD || kin.health >= kin.maxHealth)
			continue
		kin.adjustHealth(-PVE_SHAMAN_HEAL)
		new /obj/effect/temp_visual/heal(get_turf(kin), "#ff4060")
		healed = TRUE
	if(healed)
		playsound(src, 'sound/magic/staff_healing.ogg', 40, TRUE)

/mob/living/simple_animal/hostile/pve/armored
	name = "stone golem"
	desc = "Глыба камня, скреплённая туманом. Пули и клинки почти не берут её, а вот лазеры плавят."
	icon = 'icons/mob/mob.dmi'
	icon_state = "behemoth"
	icon_living = "behemoth"
	maxHealth = 140
	health = 140
	melee_damage_lower = 12
	melee_damage_upper = 12
	obj_damage = 35
	move_to_delay = 5
	bounty = 20
	del_on_death = TRUE
	deathmessage = "рассыпается грудой камней."
	attacktext = "бьёт"
	attack_sound = 'sound/weapons/punch3.ogg'
	damage_coeff = list(BRUTE = 0.35, BURN = 1.3, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 0)
	spawn_cost = 3
	unlock_wave = 7
	spawn_weight = 4

/mob/living/simple_animal/hostile/pve/armored/get_ru_names()
	return alist(
		NOMINATIVE = "каменный голем",
		GENITIVE = "каменного голема",
		DATIVE = "каменному голему",
		ACCUSATIVE = "каменного голема",
		INSTRUMENTAL = "каменным големом",
		PREPOSITIONAL = "каменном големе",
	)

/mob/living/simple_animal/hostile/pve/wraith
	name = "wraith"
	desc = "Полупрозрачный силуэт. Энергия проходит сквозь него, но картечь и сталь рвут на клочья."
	icon = 'icons/mob/mob.dmi'
	icon_state = "floating"
	icon_living = "floating"
	alpha = 200
	maxHealth = 60
	health = 60
	melee_damage_lower = 10
	melee_damage_upper = 10
	move_to_delay = 3
	bounty = 15
	del_on_death = TRUE
	deathmessage = "растворяется в тумане."
	attacktext = "полосует"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	damage_coeff = list(BRUTE = 1.3, BURN = 0.35, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 0)
	spawn_cost = 2
	unlock_wave = 6
	spawn_weight = 5

/mob/living/simple_animal/hostile/pve/wraith/get_ru_names()
	return alist(
		NOMINATIVE = "призрак",
		GENITIVE = "призрака",
		DATIVE = "призраку",
		ACCUSATIVE = "призрака",
		INSTRUMENTAL = "призраком",
		PREPOSITIONAL = "призраке",
	)

/mob/living/simple_animal/hostile/pve/brute
	name = "brute"
	desc = "Огромная бронированная туша. Сносит баррикады и стены, отбрасывает ударом."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "goliath"
	icon_living = "goliath"
	icon_dead = "goliath_dead"
	maxHealth = 180
	health = 180
	melee_damage_lower = 18
	melee_damage_upper = 18
	obj_damage = 70
	move_to_delay = 6
	bounty = 24
	move_resist = MOVE_FORCE_VERY_STRONG
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES | ENVIRONMENT_SMASH_RWALLS
	attacktext = "таранит"
	attack_sound = 'sound/weapons/punch4.ogg'
	spawn_cost = 4
	unlock_wave = 6
	spawn_weight = 3

/mob/living/simple_animal/hostile/pve/brute/get_ru_names()
	return alist(
		NOMINATIVE = "громила",
		GENITIVE = "громилы",
		DATIVE = "громиле",
		ACCUSATIVE = "громилу",
		INSTRUMENTAL = "громилой",
		PREPOSITIONAL = "громиле",
	)

/mob/living/simple_animal/hostile/pve/brute/AttackingTarget()
	. = ..()
	if(!. || !isliving(target) || !prob(35))
		return
	var/mob/living/victim = target
	victim.throw_at(get_edge_target_turf(victim, get_dir(src, victim)), 2, 2, src)

/mob/living/simple_animal/hostile/pve/swarm
	name = "fog bat"
	desc = "Мелкая летучая тварь. Поодиночке безобидна, но их всегда много."
	icon = 'icons/mob/bats.dmi'
	icon_state = "bat"
	icon_living = "bat"
	icon_dead = "bat_dead"
	maxHealth = 12
	health = 12
	melee_damage_lower = 3
	melee_damage_upper = 3
	obj_damage = 5
	move_to_delay = 2
	bounty = 2
	density = FALSE
	pass_flags = PASSTABLE
	mob_size = MOB_SIZE_TINY
	attacktext = "кусает"
	spawn_cost = 2
	unlock_wave = 3
	spawn_weight = 4
	group_size = 4

/mob/living/simple_animal/hostile/pve/swarm/get_ru_names()
	return alist(
		NOMINATIVE = "туманная мышь",
		GENITIVE = "туманной мыши",
		DATIVE = "туманной мыши",
		ACCUSATIVE = "туманную мышь",
		INSTRUMENTAL = "туманной мышью",
		PREPOSITIONAL = "туманной мыши",
	)

/mob/living/simple_animal/hostile/pve/carrier
	name = "fog carrier"
	desc = "Раздутый улей на ножках. Если его разорвать, наружу вылетит стайка туманных мышей."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Hivelord"
	icon_living = "Hivelord"
	icon_dead = "Hivelord_dead"
	maxHealth = 90
	health = 90
	melee_damage_lower = 7
	melee_damage_upper = 7
	move_to_delay = 5
	bounty = 14
	attacktext = "хлещет"
	spawn_cost = 3
	unlock_wave = 5
	spawn_weight = 3

/mob/living/simple_animal/hostile/pve/carrier/get_ru_names()
	return alist(
		NOMINATIVE = "носитель",
		GENITIVE = "носителя",
		DATIVE = "носителю",
		ACCUSATIVE = "носителя",
		INSTRUMENTAL = "носителем",
		PREPOSITIONAL = "носителе",
	)

/mob/living/simple_animal/hostile/pve/carrier/death(gibbed)
	. = ..()
	if(!.)
		return
	var/datum/game_mode/pve/mode = get_mode()
	if(!mode || mode.finished)
		return
	visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] лопается, выпуская рой!"))
	for(var/i in 1 to PVE_CARRIER_BROOD)
		mode.add_enemy(new /mob/living/simple_animal/hostile/pve/swarm(get_turf(src)))

/mob/living/simple_animal/hostile/pve/stalker
	name = "stalker"
	desc = "Почти невидимая тень. Проявляется, лишь подобравшись вплотную, и бьёт очень больно."
	icon = 'icons/mob/mob.dmi'
	icon_state = "shadow"
	icon_living = "shadow"
	alpha = PVE_STALKER_HIDDEN_ALPHA
	maxHealth = 55
	health = 55
	melee_damage_lower = 20
	melee_damage_upper = 20
	move_to_delay = 3
	bounty = 18
	del_on_death = TRUE
	deathmessage = "рассеивается клочьями тьмы."
	attacktext = "вспарывает"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	spawn_cost = 3
	unlock_wave = 9
	spawn_weight = 3
	var/revealed = FALSE
	var/reveal_until = 0

/mob/living/simple_animal/hostile/pve/stalker/get_ru_names()
	return alist(
		NOMINATIVE = "скрытень",
		GENITIVE = "скрытня",
		DATIVE = "скрытню",
		ACCUSATIVE = "скрытня",
		INSTRUMENTAL = "скрытнем",
		PREPOSITIONAL = "скрытне",
	)

/mob/living/simple_animal/hostile/pve/stalker/handle_automated_action()
	. = ..()
	if(stat)
		return
	var/near_target = target && get_dist(src, target) <= PVE_STALKER_REVEAL_RANGE
	set_revealed(near_target || world.time < reveal_until)

/mob/living/simple_animal/hostile/pve/stalker/adjustHealth(amount = 0, updating_health = TRUE, blocked = 0, damage_type = BRUTE, forced = FALSE)
	. = ..()
	if(amount > 0 && stat != DEAD)
		reveal_until = world.time + PVE_STALKER_REVEAL_TIME
		set_revealed(TRUE)

/mob/living/simple_animal/hostile/pve/stalker/proc/set_revealed(new_revealed)
	if(revealed == new_revealed)
		return
	revealed = new_revealed
	animate(src, alpha = revealed ? 255 : PVE_STALKER_HIDDEN_ALPHA, time = 0.5 SECONDS)

/mob/living/simple_animal/hostile/pve/howler
	name = "howler"
	desc = "Вожак стаи. Его вой приводит сородичей в бешенство — бейте его первым."
	icon_state = "hellhoundgreater"
	icon_living = "hellhoundgreater"
	maxHealth = 110
	health = 110
	melee_damage_lower = 12
	melee_damage_upper = 12
	move_to_delay = 4
	bounty = 22
	del_on_death = TRUE
	deathmessage = "издаёт последний вой и обращается в пепел."
	attacktext = "рвёт"
	spawn_cost = 4
	unlock_wave = 11
	spawn_weight = 2
	COOLDOWN_DECLARE(howl_cooldown)

/mob/living/simple_animal/hostile/pve/howler/get_ru_names()
	return alist(
		NOMINATIVE = "вожак",
		GENITIVE = "вожака",
		DATIVE = "вожаку",
		ACCUSATIVE = "вожака",
		INSTRUMENTAL = "вожаком",
		PREPOSITIONAL = "вожаке",
	)

/mob/living/simple_animal/hostile/pve/howler/handle_automated_action()
	. = ..()
	if(!. || stat || !target || !COOLDOWN_FINISHED(src, howl_cooldown))
		return
	COOLDOWN_START(src, howl_cooldown, PVE_HOWLER_COOLDOWN)
	visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] протяжно воет!"))
	playsound(src, 'sound/hallucinations/growl1.ogg', 80, TRUE)
	for(var/mob/living/simple_animal/hostile/pve/kin in range(PVE_HOWLER_RANGE, src))
		if(kin.stat != DEAD && !istype(kin, /mob/living/simple_animal/hostile/pve/boss))
			kin.apply_status_effect(/datum/status_effect/pve_rallied)

/datum/status_effect/pve_rallied
	id = "pve_rallied"
	duration = PVE_RALLY_DURATION
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	var/bonus_lower = 0
	var/bonus_upper = 0

/datum/status_effect/pve_rallied/on_apply()
	var/mob/living/simple_animal/hostile/pve/enemy = owner
	if(!istype(enemy))
		return FALSE
	bonus_lower = round(enemy.melee_damage_lower * (PVE_RALLY_DAMAGE_MULT - 1))
	bonus_upper = round(enemy.melee_damage_upper * (PVE_RALLY_DAMAGE_MULT - 1))
	enemy.melee_damage_lower += bonus_lower
	enemy.melee_damage_upper += bonus_upper
	enemy.add_filter("pve_rallied", 3, outline_filter(1, "#ff3030"))
	return TRUE

/datum/status_effect/pve_rallied/on_remove()
	var/mob/living/simple_animal/hostile/pve/enemy = owner
	enemy.melee_damage_lower -= bonus_lower
	enemy.melee_damage_upper -= bonus_upper
	enemy.remove_filter("pve_rallied")

/mob/living/simple_animal/hostile/pve/treasure
	name = "fog wisp"
	desc = "Сгусток золотого света, который туман гонит перед собой. Пугливый и юркий, но за него щедро платят."
	icon_state = "lightgeist"
	icon_living = "lightgeist"
	maxHealth = 70
	health = 70
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	move_to_delay = 2
	retreat_distance = 8
	minimum_distance = 8
	environment_smash = ENVIRONMENT_SMASH_NONE
	wanted_objects = list()
	bounty = 120
	del_on_death = TRUE
	deathmessage = "рассыпается золотыми искрами."
	light_range = 3
	light_power = 2
	light_color = "#ffd040"
	var/escape_timer

/mob/living/simple_animal/hostile/pve/treasure/get_ru_names()
	return alist(
		NOMINATIVE = "светоч тумана",
		GENITIVE = "светоча тумана",
		DATIVE = "светочу тумана",
		ACCUSATIVE = "светоч тумана",
		INSTRUMENTAL = "светочем тумана",
		PREPOSITIONAL = "светоче тумана",
	)

/mob/living/simple_animal/hostile/pve/treasure/Initialize(mapload)
	. = ..()
	add_filter("pve_treasure", 2, outline_filter(1, "#ffd040"))
	escape_timer = addtimer(CALLBACK(src, PROC_REF(escape)), PVE_TREASURE_ESCAPE_TIME, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/pve/treasure/Destroy()
	deltimer(escape_timer)
	return ..()

/mob/living/simple_animal/hostile/pve/treasure/ListTargets()
	. = ..()
	var/datum/game_mode/pve/mode = get_mode()
	. -= mode?.core

/mob/living/simple_animal/hostile/pve/treasure/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/pve/treasure/make_elite()
	return

/mob/living/simple_animal/hostile/pve/treasure/unstuck()
	last_activity = world.time

/mob/living/simple_animal/hostile/pve/treasure/proc/escape()
	if(stat == DEAD)
		return
	visible_message(span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] ускользает в туман."))
	var/datum/game_mode/pve/mode = get_mode()
	mode?.broadcast(span_warning("Светоч тумана ускользнул."))
	qdel(src)

/mob/living/simple_animal/hostile/pve/boss
	abstract_type = /mob/living/simple_animal/hostile/pve/boss
	maxHealth = 900
	health = 900
	obj_damage = 100
	bounty = 300
	del_on_death = TRUE
	move_resist = MOVE_FORCE_OVERPOWERING
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES | ENVIRONMENT_SMASH_RWALLS
	vision_range = 10
	aggro_vision_range = 12
	lose_patience_timeout = 0
	var/ability_cooldown_time = 8 SECONDS
	var/charging = FALSE
	COOLDOWN_DECLARE(ability_cooldown)

/mob/living/simple_animal/hostile/pve/boss/Initialize(mapload)
	. = ..()
	COOLDOWN_START(src, ability_cooldown, ability_cooldown_time)

/mob/living/simple_animal/hostile/pve/boss/unstuck()
	last_activity = world.time

/mob/living/simple_animal/hostile/pve/boss/handle_automated_action()
	. = ..()
	if(!. || stat || !target || !COOLDOWN_FINISHED(src, ability_cooldown))
		return
	COOLDOWN_START(src, ability_cooldown, ability_cooldown_time)
	use_ability()

/mob/living/simple_animal/hostile/pve/boss/proc/use_ability()
	return

/mob/living/simple_animal/hostile/pve/boss/death(gibbed)
	var/turf/center = get_turf(src)
	. = ..()
	if(!.)
		return
	new /obj/effect/temp_visual/explosion(center, 2, "#aa2030", FALSE, TRUE)
	playsound(center, 'sound/effects/explosion_distant.ogg', 100, TRUE)

/mob/living/simple_animal/hostile/pve/boss/proc/summon_minions(minion_type, amount)
	var/datum/game_mode/pve/mode = get_mode()
	if(!mode)
		return
	var/list/turf/free_turfs = list()
	for(var/turf/nearby in orange(1, src))
		if(!nearby.is_blocked_turf(exclude_mobs = TRUE))
			free_turfs += nearby
	if(!length(free_turfs))
		return
	for(var/i in 1 to amount)
		mode.add_enemy(new minion_type(pick(free_turfs)))

/mob/living/simple_animal/hostile/pve/boss/proc/radial_volley(projectile_type, count)
	var/turf/start = get_turf(src)
	playsound(start, 'sound/magic/fireball.ogg', 80, TRUE)
	for(var/i in 0 to count - 1)
		var/obj/projectile/bolt = new projectile_type(start)
		bolt.firer = src
		bolt.firer_source_atom = src
		bolt.fire(i * (360 / count))

/mob/living/simple_animal/hostile/pve/boss/broodmother
	name = "brood mother"
	desc = "Раздувшаяся матка тумана. Из её брюха непрерывно лезут летучие твари."
	icon = 'icons/mob/lavaland/lavaland_elites.dmi'
	icon_state = "broodmother"
	icon_living = "broodmother"
	melee_damage_lower = 20
	melee_damage_upper = 20
	move_to_delay = 5
	bounty = 400
	attacktext = "пронзает"
	attack_sound = 'sound/weapons/bladeslice.ogg'

/mob/living/simple_animal/hostile/pve/boss/broodmother/get_ru_names()
	return alist(
		NOMINATIVE = "матка тумана",
		GENITIVE = "матки тумана",
		DATIVE = "матке тумана",
		ACCUSATIVE = "матку тумана",
		INSTRUMENTAL = "маткой тумана",
		PREPOSITIONAL = "матке тумана",
	)

/mob/living/simple_animal/hostile/pve/boss/broodmother/use_ability()
	visible_message(span_danger("Из брюха [declent_ru(GENITIVE)] вырывается рой!"))
	playsound(src, 'sound/creatures/bats_spawn.ogg', 80, TRUE)
	summon_minions(/mob/living/simple_animal/hostile/pve/swarm, 3)

/mob/living/simple_animal/hostile/pve/boss/legionnaire
	name = "legionnaire"
	desc = "Костяной исполин. Разгоняется и сметает всё на своём пути."
	icon = 'icons/mob/lavaland/lavaland_elites.dmi'
	icon_state = "legionnaire"
	icon_living = "legionnaire"
	maxHealth = 1600
	health = 1600
	melee_damage_lower = 28
	melee_damage_upper = 28
	bounty = 600
	ability_cooldown_time = 7 SECONDS
	attacktext = "рубит"
	attack_sound = 'sound/weapons/bladeslice.ogg'

/mob/living/simple_animal/hostile/pve/boss/legionnaire/get_ru_names()
	return alist(
		NOMINATIVE = "легионер",
		GENITIVE = "легионера",
		DATIVE = "легионеру",
		ACCUSATIVE = "легионера",
		INSTRUMENTAL = "легионером",
		PREPOSITIONAL = "легионере",
	)

/mob/living/simple_animal/hostile/pve/boss/legionnaire/use_ability()
	if(get_dist(src, target) > PVE_CHARGE_RANGE)
		return
	start_charge(get_turf(target))

/mob/living/simple_animal/hostile/pve/boss/proc/start_charge(turf/destination)
	visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] пригибается, готовясь к рывку!"))
	animate(src, color = "#ff4040", time = 0.4 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(launch_charge), destination), 0.8 SECONDS)

/mob/living/simple_animal/hostile/pve/boss/proc/launch_charge(turf/destination)
	animate(src, color = initial(color), time = 0.2 SECONDS)
	if(stat)
		return
	GLOB.move_manager.stop_looping(src)
	charging = TRUE
	throw_at(destination, PVE_CHARGE_RANGE, 3, src, spin = FALSE, callback = CALLBACK(src, PROC_REF(end_charge)))

/mob/living/simple_animal/hostile/pve/boss/proc/end_charge()
	charging = FALSE

/mob/living/simple_animal/hostile/pve/boss/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!charging)
		return
	if(isliving(hit_atom) && !IS_PVE_ENEMY(hit_atom))
		var/mob/living/victim = hit_atom
		victim.apply_damage(PVE_CHARGE_DAMAGE, BRUTE)
		victim.Weaken(1.5 SECONDS)
		victim.throw_at(get_edge_target_turf(victim, get_dir(src, victim)), 3, 2, src)
		playsound(victim, 'sound/effects/meteorimpact.ogg', 80, TRUE)
	else if(isobj(hit_atom))
		var/obj/obstacle = hit_atom
		if(!(obstacle.resistance_flags & INDESTRUCTIBLE))
			obstacle.take_damage(obj_damage * 2, BRUTE, MELEE)

/mob/living/simple_animal/hostile/pve/boss/herald
	name = "herald"
	desc = "Вестник тумана. Обрушивает на защитников град кровавых снарядов."
	icon = 'icons/mob/lavaland/lavaland_elites.dmi'
	icon_state = "herald"
	icon_living = "herald"
	maxHealth = 2200
	health = 2200
	melee_damage_lower = 15
	melee_damage_upper = 15
	bounty = 800
	ranged = TRUE
	projectiletype = /obj/projectile/pve_enemy/bolt
	projectilesound = 'sound/magic/fireball.ogg'
	ranged_message = "выпускает кровавые снаряды"
	ranged_cooldown_time = 2 SECONDS
	rapid = 3
	ranged_distance = 9
	retreat_distance = 3
	minimum_distance = 5
	ability_cooldown_time = 6 SECONDS

/mob/living/simple_animal/hostile/pve/boss/herald/get_ru_names()
	return alist(
		NOMINATIVE = "вестник",
		GENITIVE = "вестника",
		DATIVE = "вестнику",
		ACCUSATIVE = "вестника",
		INSTRUMENTAL = "вестником",
		PREPOSITIONAL = "вестнике",
	)

/mob/living/simple_animal/hostile/pve/boss/herald/use_ability()
	radial_volley(/obj/projectile/pve_enemy/bolt, 16)

/mob/living/simple_animal/hostile/pve/boss/devourer
	name = "fog devourer"
	desc = "Сердце красного тумана во плоти. Если оно падёт, туман рассеется."
	icon = 'icons/mob/lavaland/96x96megafauna.dmi'
	icon_state = "mega_legion"
	icon_living = "mega_legion"
	pixel_x = -32
	base_pixel_x = -32
	maxHealth = 6000
	health = 6000
	melee_damage_lower = 40
	melee_damage_upper = 40
	move_to_delay = 5
	bounty = 2000
	ranged = TRUE
	projectiletype = /obj/projectile/pve_enemy/bolt
	projectilesound = 'sound/magic/fireball.ogg'
	ranged_message = "изрыгает кровавые снаряды"
	rapid = 2
	ranged_distance = 8
	ability_cooldown_time = 7 SECONDS
	attacktext = "сокрушает"
	attack_sound = 'sound/effects/meteorimpact.ogg'
	var/ability_index = 0
	var/enraged = FALSE

/mob/living/simple_animal/hostile/pve/boss/devourer/get_ru_names()
	return alist(
		NOMINATIVE = "пожиратель тумана",
		GENITIVE = "пожирателя тумана",
		DATIVE = "пожирателю тумана",
		ACCUSATIVE = "пожирателя тумана",
		INSTRUMENTAL = "пожирателем тумана",
		PREPOSITIONAL = "пожирателе тумана",
	)

/mob/living/simple_animal/hostile/pve/boss/devourer/use_ability()
	ability_index++
	switch(ability_index % 3)
		if(0)
			visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] исторгает из себя безликих!"))
			summon_minions(/mob/living/simple_animal/hostile/pve/grunt, enraged ? 6 : 4)
		if(1)
			radial_volley(/obj/projectile/pve_enemy/bolt, enraged ? 32 : 20)
		if(2)
			if(get_dist(src, target) <= PVE_CHARGE_RANGE)
				start_charge(get_turf(target))

/mob/living/simple_animal/hostile/pve/boss/devourer/adjustHealth(amount = 0, updating_health = TRUE, blocked = 0, damage_type = BRUTE, forced = FALSE)
	. = ..()
	if(enraged || stat || health > maxHealth * 0.4)
		return
	enraged = TRUE
	move_to_delay = 3
	ability_cooldown_time = 4 SECONDS
	add_atom_colour("#ff8080", FIXED_COLOUR_PRIORITY)
	visible_message(span_userdanger("[DECLENT_RU_CAP(src, NOMINATIVE)] впадает в ярость!"))
	playsound(src, 'sound/effects/curse5.ogg', 100, TRUE)

/obj/projectile/pve_enemy
	name = "fog spit"
	damage = 12
	damage_type = BURN
	flag = ACID
	icon_state = "neurotoxin"
	hitsound = 'sound/weapons/sear.ogg'

/obj/projectile/pve_enemy/prehit(atom/target)
	. = ..()
	nodamage = IS_PVE_ENEMY(target)
	forcedodge = nodamage

/obj/projectile/pve_enemy/on_hit(atom/target, blocked = 0, hit_zone)
	if(IS_PVE_ENEMY(target))
		return -1
	return ..()

/obj/projectile/pve_enemy/spit

/obj/projectile/pve_enemy/bolt
	name = "blood bolt"
	icon_state = "blood_bolt"
	damage = 15
	flag = LASER
	speed = 1

#undef PVE_ENEMY_SMASH_COOLDOWN
#undef PVE_ENEMY_STUCK_TIME
#undef PVE_ELITE_HEALTH_MULT
#undef PVE_ELITE_DAMAGE_MULT
#undef PVE_ELITE_BOUNTY_MULT
#undef PVE_BOMBER_DAMAGE
#undef PVE_BOMBER_OBJ_DAMAGE
#undef PVE_SHAMAN_HEAL
#undef PVE_SHAMAN_RANGE
#undef PVE_CHARGE_DAMAGE
#undef PVE_CHARGE_RANGE
#undef PVE_TREASURE_ESCAPE_TIME
#undef PVE_CARRIER_BROOD
#undef PVE_STALKER_REVEAL_RANGE
#undef PVE_STALKER_HIDDEN_ALPHA
#undef PVE_STALKER_REVEAL_TIME
#undef PVE_HOWLER_RANGE
#undef PVE_HOWLER_COOLDOWN
#undef PVE_RALLY_DURATION
#undef PVE_RALLY_DAMAGE_MULT
