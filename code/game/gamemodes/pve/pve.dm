#define PVE_PREPARATION_TIME (1 MINUTES)
#define PVE_SPAWN_INTERVAL (2 SECONDS)
#define PVE_MAX_ENEMIES 60
#define PVE_STARTING_CREDITS 100
#define PVE_BOSS_INTERVAL 5

/datum/game_mode/pve
	name = "PvE Survival"
	config_tag = "pve"
	forced_job = JOB_TITLE_CIVILIAN
	required_players = 1
	ert_disabled = TRUE
	var/arena_z
	var/wave = 0
	var/completed_waves = 0
	var/enemies_to_spawn = 0
	var/next_spawn = 0
	var/next_wave = 0
	var/wave_active = FALSE
	var/finished = FALSE
	var/started = FALSE
	var/events_enabled
	var/list/enemy_spawns = list()
	var/list/active_enemies = list()
	var/list/player_accounts = list()
	var/list/previous_spawns
	var/previous_outfit

/datum/game_mode/pve/announce()
	to_chat(world, span_boldannounceic("Режим — PvE: выживание!"))
	to_chat(world, span_notice("Игроки появляются слева, враги наступают справа. Уничтожайте волны и покупайте снаряжение за кредиты. После каждой волны — минута на подготовку. Поражение наступит при гибели всей команды."))

/datum/game_mode/pve/pre_setup()
	var/datum/map_template/pve_arena/arena = new
	arena_z = GLOB.space_manager.add_new_zlevel("PvE Arena [UID()]", linkage = UNAFFECTED, traits = list(BLOCK_TELEPORT))
	var/loaded = arena.load(locate(TRANSITIONEDGE + 1, TRANSITIONEDGE + 1, arena_z))
	qdel(arena)
	if(!loaded)
		return FALSE
	var/list/player_spawns = list()
	for(var/obj/effect/landmark/pve_spawn/spawn_point in GLOB.landmarks_list)
		if(spawn_point.z != arena_z)
			continue
		if(istype(spawn_point, /obj/effect/landmark/pve_spawn/enemy))
			enemy_spawns += get_turf(spawn_point)
		else
			player_spawns += get_turf(spawn_point)
	if(!length(player_spawns) || !length(enemy_spawns))
		return FALSE
	previous_spawns = GLOB.start_override.Copy()
	previous_outfit = GLOB.start_override_outfit
	GLOB.start_override = player_spawns
	GLOB.start_override_outfit = /datum/outfit/pve
	return TRUE

/datum/game_mode/pve/post_setup()
	. = ..()
	events_enabled = SSevents.can_fire
	SSevents.can_fire = FALSE
	SSshuttle.add_hostile_environment(src)
	started = TRUE
	next_wave = world.time + PVE_PREPARATION_TIME

/datum/game_mode/pve/generate_station_goals()
	return

/datum/game_mode/pve/generate_traits_list()
	return

/datum/game_mode/pve/allow_antag_events()
	return FALSE

/datum/game_mode/pve/process(wait)
	if(!started || finished)
		return
	var/list/survivors = living_players()
	if(!length(survivors))
		finished = TRUE
		SSticker.force_ending = TRUE
		to_chat(world, span_boldannounceic("Команда погибла. Зачищено волн: [completed_waves]."))
		return
	if(!wave_active)
		if(world.time >= next_wave)
			start_wave(length(survivors))
		return
	if(enemies_to_spawn && world.time >= next_spawn)
		spawn_enemy()
	if(!enemies_to_spawn && !length(active_enemies))
		complete_wave(survivors)

/datum/game_mode/pve/proc/living_players()
	. = list()
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		var/datum/mind/mind = account.mind_ref?.resolve()
		var/mob/living/player = mind?.current
		if(istype(player) && player.stat != DEAD && player.z == arena_z)
			. += player

/datum/game_mode/pve/proc/register_player(mob/living/carbon/human/player)
	if(!player.mind || finished)
		return
	var/datum/pve_account/account = player_accounts[player.mind.UID()]
	if(!account)
		account = new
		player_accounts[player.mind.UID()] = account
	account.mind_ref = WEAKREF(player.mind)
	account.player_name = player.real_name
	to_chat(player, span_notice("Защищайте коридор. Ваш баланс: [account.credits] кредитов. Магазины находятся слева. Счёт и таймер волны доступны в магазине."))

/datum/game_mode/pve/proc/start_wave(player_count)
	wave++
	wave_active = TRUE
	enemies_to_spawn = min(PVE_MAX_ENEMIES, 2 + player_count * 2 + wave)
	next_spawn = world.time
	to_chat(world, span_boldannounceic("Волна [wave]! Противников: [enemies_to_spawn].[wave % PVE_BOSS_INTERVAL ? "" : " Приближается вожак!"]"))

/datum/game_mode/pve/proc/spawn_enemy()
	var/enemy_type = /mob/living/simple_animal/hostile/carp/pve
	if(wave >= 3 && prob(35))
		enemy_type = /mob/living/simple_animal/hostile/carp/pve/runner
	if(wave >= 5 && prob(25))
		enemy_type = /mob/living/simple_animal/hostile/carp/pve/brute
	if(!(wave % PVE_BOSS_INTERVAL) && enemies_to_spawn == 1)
		enemy_type = /mob/living/simple_animal/hostile/carp/pve/boss
	var/mob/living/simple_animal/hostile/carp/pve/enemy = new enemy_type(pick(enemy_spawns))
	enemy.maxHealth += (wave - 1) * 5
	enemy.health = enemy.maxHealth
	enemy.melee_damage_lower += round((wave - 1) / 2)
	enemy.melee_damage_upper = enemy.melee_damage_lower
	active_enemies += enemy
	RegisterSignals(enemy, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING), PROC_REF(on_enemy_removed))
	enemies_to_spawn--
	next_spawn = world.time + PVE_SPAWN_INTERVAL

/datum/game_mode/pve/proc/on_enemy_removed(mob/living/source)
	SIGNAL_HANDLER
	active_enemies -= source
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	if(!QDELETED(source))
		QDEL_IN(source, 15 SECONDS)

/datum/game_mode/pve/proc/complete_wave(list/survivors)
	wave_active = FALSE
	completed_waves = wave
	next_wave = world.time + PVE_PREPARATION_TIME
	var/reward = 100 + wave * 25
	for(var/mob/living/player as anything in survivors)
		var/datum/pve_account/account = player_accounts[player.mind.UID()]
		if(!account)
			continue
		account.credits += reward
		account.score += wave * 100
	to_chat(world, span_boldannounceic("Волна [wave] зачищена! Выжившим начислено [reward] кредитов и [wave * 100] очков. Следующая волна через минуту."))

/datum/game_mode/pve/check_finished()
	return finished || station_was_nuked

/datum/game_mode/pve/declare_completion()
	to_chat(world, span_boldannounceic("PvE: зачищено волн — [completed_waves]."))
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		to_chat(world, span_notice("[account.player_name]: [account.score] очков; осталось кредитов: [account.credits]."))
	return ..()

/datum/game_mode/pve/Destroy()
	for(var/mob/living/enemy as anything in active_enemies)
		UnregisterSignal(enemy, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	QDEL_LIST(active_enemies)
	QDEL_LIST_ASSOC_VAL(player_accounts)
	enemy_spawns = null
	if(previous_spawns)
		GLOB.start_override = previous_spawns
		GLOB.start_override_outfit = previous_outfit
	previous_spawns = null
	previous_outfit = null
	if(started)
		SSevents.can_fire = events_enabled
		SSshuttle.remove_hostile_environment(src)
	return ..()

/datum/pve_account
	var/credits = PVE_STARTING_CREDITS
	var/score = 0
	var/player_name
	var/datum/weakref/mind_ref

/datum/pve_account/Destroy()
	mind_ref = null
	return ..()

/datum/map_template/pve_arena
	name = "PvE Corridor"
	mappath = "_maps/map_files/pve/corridor.dmm"

/area/pve_arena
	name = "PvE Arena"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	static_lighting = FALSE
	base_lighting_alpha = 255
	ambient_buzz = null

/obj/effect/landmark/pve_spawn
	name = "PvE player spawn"

/obj/effect/landmark/pve_spawn/enemy
	name = "PvE enemy spawn"

/mob/living/simple_animal/hostile/carp/pve
	maxHealth = 30
	health = 30
	melee_damage_lower = 6
	melee_damage_upper = 6
	carp_stamina_damage = 0
	obj_damage = 15
	move_to_delay = 5
	vision_range = 60
	aggro_vision_range = 60
	stat_attack = UNCONSCIOUS
	faction = list("pve_enemies")
	gold_core_spawnable = NO_SPAWN
	butcher_results = list()
	loot = list()

/mob/living/simple_animal/hostile/carp/pve/ListTargets()
	. = list()
	var/datum/game_mode/pve/mode = SSticker.mode
	if(!istype(mode) || z != mode.arena_z)
		return
	. = mode.living_players()
	for(var/obj/machinery/porta_turret/syndicate/pve/turret in range(7, src))
		. += turret

/mob/living/simple_animal/hostile/carp/pve/runner
	maxHealth = 25
	health = 25
	move_to_delay = 2
	melee_damage_lower = 8
	melee_damage_upper = 8

/mob/living/simple_animal/hostile/carp/pve/brute
	maxHealth = 90
	health = 90
	move_to_delay = 7
	melee_damage_lower = 12
	melee_damage_upper = 12

/mob/living/simple_animal/hostile/carp/pve/boss
	maxHealth = 250
	health = 250
	move_to_delay = 6
	melee_damage_lower = 18
	melee_damage_upper = 18
	obj_damage = 35

#undef PVE_PREPARATION_TIME
#undef PVE_SPAWN_INTERVAL
#undef PVE_MAX_ENEMIES
#undef PVE_STARTING_CREDITS
#undef PVE_BOSS_INTERVAL
