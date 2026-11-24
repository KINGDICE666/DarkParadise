#define PVE_FIRST_PREPARATION (2 MINUTES)
#define PVE_PREPARATION (75 SECONDS)
#define PVE_BOSS_PREPARATION (100 SECONDS)
#define PVE_READY_COUNTDOWN (10 SECONDS)
#define PVE_STARTING_CREDITS 200
#define PVE_LATE_JOIN_CREDITS_PER_WAVE 60
#define PVE_WAVE_REWARD_BASE 60
#define PVE_WAVE_REWARD_PER_WAVE 15
#define PVE_MAX_ALIVE_ENEMIES 45
#define PVE_SPAWN_GROUP_INTERVAL (5 SECONDS)
#define PVE_SUPPLY_DROP_INTERVAL (70 SECONDS)
#define PVE_CLASS_PROMPT_INTERVAL (30 SECONDS)
#define PVE_NEST_TOXIN 3
#define PVE_REGEN_AMOUNT 1
#define PVE_BED_REGEN_AMOUNT 3
#define PVE_CORE_WAVE_REGEN 0.1
#define PVE_END_DELAY (40 SECONDS)
#define PVE_NIGHT_LIGHTING_ALPHA 25
#define PVE_BOSS_QUEUE_FRACTION 0.6
#define PVE_MAX_ELITE_CHANCE 25
#define PVE_MUTATOR_CHANCE 55
#define PVE_CONTRACT_CHANCE 70
#define PVE_CONTRACT_REWARD_BASE 30
#define PVE_CONTRACT_REWARD_PER_WAVE 10
#define PVE_TREASURE_CHANCE 35
#define PVE_TREASURE_MIN_WAVE 3
#define PVE_LOOT_CHIP_CHANCE 8
#define PVE_LOOT_ITEM_CHANCE 3
#define PVE_REGEN_FRACTION 0.015
#define PVE_LOOTER_BONUS 0.15

/datum/game_mode/pve
	name = "Colonial Marines"
	config_tag = "pve"
	votable = TRUE
	forced_job = JOB_TITLE_CIVILIAN
	required_players = 1
	ert_disabled = TRUE
	var/arena_z
	var/wave = 0
	var/wave_active = FALSE
	var/started = FALSE
	var/finished = FALSE
	var/victory = FALSE
	var/end_reason
	var/end_timer_id
	var/next_wave_time = 0
	var/next_spawn_time = 0
	var/next_supply_drop = 0
	var/total_kills = 0
	var/mutator
	var/next_mutator
	var/last_mutator
	var/treasure_spawn_at = 0
	var/datum/pve_contract/contract
	var/boss_type
	var/boss_spawn_at = 0
	var/events_enabled
	var/obj/structure/pve_core/core
	var/mob/living/simple_animal/hostile/pve/boss/active_boss
	var/datum/pve_flow_field/flow_field
	var/list/turf/player_spawns = list()
	var/list/turf/enemy_spawns = list()
	var/list/turf/drop_turfs = list()
	var/list/spawn_queue = list()
	var/list/mob/living/simple_animal/hostile/pve/active_enemies = list()
	var/list/player_accounts = list()
	var/list/classes = list()
	var/list/products = list()
	var/list/previous_spawns
	var/previous_outfit

/datum/game_mode/pve/announce()
	to_chat(world, span_boldannounceic("Режим — Colonial Marines: оборона Маяка!"))
	to_chat(world, span_notice("Защищайте лагерь слева от волн тварей из красного тумана. Выберите класс, закупайтесь между волнами и продержитесь [PVE_FINAL_WAVE] волн."))

/datum/game_mode/pve/pre_setup()
	var/datum/map_template/pve_arena/arena = new
	arena_z = GLOB.space_manager.add_new_zlevel("PvE Arena [UID()]", linkage = UNAFFECTED, traits = list(BLOCK_TELEPORT))
	var/turf/bottom_left = locate(TRANSITIONEDGE + 1, TRANSITIONEDGE + 1, arena_z)
	var/loaded = arena.load(bottom_left)
	var/turf/top_right = locate(bottom_left.x + arena.width - 1, bottom_left.y + arena.height - 1, arena_z)
	qdel(arena)
	if(!loaded)
		return FALSE
	for(var/obj/effect/landmark/pve_spawn/spawn_point in GLOB.landmarks_list)
		if(spawn_point.z != arena_z)
			continue
		if(istype(spawn_point, /obj/effect/landmark/pve_spawn/enemy))
			enemy_spawns += get_turf(spawn_point)
		else
			player_spawns += get_turf(spawn_point)
	var/list/turf/arena_turfs = block(bottom_left, top_right)
	for(var/turf/tile as anything in arena_turfs)
		core ||= locate(/obj/structure/pve_core) in tile
		if(tile.blocks_air)
			continue
		tile.atmos_mode = ATMOS_MODE_EXPOSED_TO_ENVIRONMENT
		tile.atmos_environment = ENVIRONMENT_TEMPERATE
		tile.initialize_milla()
	if(!length(player_spawns) || !length(enemy_spawns) || !core)
		return FALSE
	RegisterSignal(core, COMSIG_QDELETING, PROC_REF(on_core_deleted))
	for(var/class_type in valid_subtypesof(/datum/pve_class))
		var/datum/pve_class/player_class = new class_type
		classes[player_class.id] = player_class
	for(var/product_type in valid_subtypesof(/datum/pve_product))
		products["[product_type]"] = new product_type
	flow_field = new(bottom_left, top_right)
	flow_field.update(player_spawns)
	for(var/turf/tile as anything in arena_turfs)
		if(istype(tile.loc, /area/pve/field) && !isnull(flow_field.distance_at(tile)) && !tile.is_blocked_turf())
			drop_turfs += tile
	previous_spawns = GLOB.start_override.Copy()
	previous_outfit = GLOB.start_override_outfit
	GLOB.start_override = player_spawns.Copy()
	GLOB.start_override_outfit = /datum/outfit/pve
	return TRUE

/datum/game_mode/pve/post_setup()
	. = ..()
	events_enabled = SSevents.can_fire
	SSevents.can_fire = FALSE
	SSshuttle.add_hostile_environment(src)
	started = TRUE
	next_wave_time = world.time + PVE_FIRST_PREPARATION

/datum/game_mode/pve/generate_station_goals()
	return

/datum/game_mode/pve/generate_traits_list()
	return

/datum/game_mode/pve/allow_antag_events()
	return FALSE

/datum/game_mode/pve/process(wait)
	if(!started || finished)
		return
	var/list/mob/living/carbon/human/survivors = living_players()
	update_players(survivors)
	if(!wave_active)
		if(!length(survivors))
			next_wave_time = max(next_wave_time, world.time + PVE_PREPARATION)
			return
		if(world.time >= next_wave_time)
			start_wave(length(survivors))
		return
	if(!length(survivors))
		finish(FALSE, "Все защитники пали.")
		return
	flow_field.update(core ? survivors + core : survivors)
	if(treasure_spawn_at && length(spawn_queue) <= treasure_spawn_at)
		spawn_treasure()
	process_spawning(length(survivors))
	contract?.check_tick(src)
	if(mutator == PVE_MUTATOR_REGEN)
		regenerate_enemies()
	if(world.time >= next_supply_drop)
		next_supply_drop = world.time + PVE_SUPPLY_DROP_INTERVAL
		if(prob(50))
			launch_supply_drop()
	if(!length(spawn_queue) && !boss_type && !length(active_enemies))
		complete_wave()

/datum/game_mode/pve/proc/living_players()
	. = list()
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		var/mob/living/carbon/human/player = account.get_body()
		if(ishuman(player) && player.stat != DEAD && player.z == arena_z)
			. += player

/datum/game_mode/pve/proc/get_account(mob/user)
	var/datum/pve_account/account = player_accounts[user?.mind?.UID()]
	if(account?.mind_ref?.resolve() != user.mind)
		return null
	return account

/datum/game_mode/pve/proc/get_player_class(mob/user)
	var/datum/pve_account/account = get_account(user)
	return account ? classes[account.class_id] : null

/datum/game_mode/pve/proc/get_audience()
	. = list()
	for(var/mob/listener as anything in GLOB.player_list)
		if(!isnewplayer(listener))
			. += listener

/datum/game_mode/pve/proc/broadcast(message, sound_file)
	var/list/audience = get_audience()
	for(var/mob/listener as anything in audience)
		to_chat(listener, message)
		if(sound_file)
			SEND_SOUND(listener, sound(sound_file))

/datum/game_mode/pve/proc/banner(message, color = "#ff5555")
	show_blurb(get_audience(), 4 SECONDS, message, screen_position = "CENTER-6,CENTER+4", text_alignment = "center", text_color = color, ignore_key = TRUE)

/datum/game_mode/pve/proc/register_player(mob/living/carbon/human/player)
	if(!player.mind || finished)
		return
	var/account_key = player.mind.UID()
	var/datum/pve_account/account = player_accounts[account_key]
	if(!account)
		account = new(player.mind, PVE_STARTING_CREDITS + completed_waves() * PVE_LATE_JOIN_CREDITS_PER_WAVE)
		player_accounts[account_key] = account
	account.player_name = player.real_name
	account.ready_action.Grant(player)
	RegisterSignal(player, COMSIG_LIVING_DEATH, PROC_REF(on_player_death), override = TRUE)
	to_chat(player, span_notice("Вы — защитник Маяка. Баланс: [account.credits] кредитов. Терминалы снабжения стоят в штабе, оружейной, медбее и инженерной. Памятка лежит на столе в штабе."))

/datum/game_mode/pve/proc/on_player_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	var/datum/pve_account/account = get_account(source)
	if(!account || finished)
		return
	account.deaths++
	if(wave_active)
		contract?.on_defender_death(src)
	broadcast(span_danger("[account.player_name] пал[GEND_A_O_I(source)]! Возвращение в строй — после окончания волны."))

/datum/game_mode/pve/proc/update_players(list/mob/living/carbon/human/survivors)
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		update_hud(account)
		if(!account.class_id && world.time >= account.next_class_prompt && prompt_class(account))
			account.next_class_prompt = world.time + PVE_CLASS_PROMPT_INTERVAL
	for(var/mob/living/carbon/human/player as anything in survivors)
		var/area/player_area = get_area(player)
		if(istype(player_area, /area/pve/nest))
			if(!istype(player.wear_mask, /obj/item/clothing/mask/gas))
				player.apply_damage(PVE_NEST_TOXIN, TOX)
				if(prob(25))
					to_chat(player, span_warning("Ядовитый туман гнезда жжёт лёгкие! Противогаз бы не помешал."))
		else if(istype(player_area, /area/pve/base/rest) || istype(player_area, /area/pve/base/medbay))
			if(istype(player.buckled, /obj/structure/bed))
				player.heal_overall_damage(PVE_BED_REGEN_AMOUNT, PVE_BED_REGEN_AMOUNT)
			else if(!wave_active)
				player.heal_overall_damage(PVE_REGEN_AMOUNT, PVE_REGEN_AMOUNT)
		var/datum/pve_class/player_class = get_player_class(player)
		player_class?.class_process(player, survivors)

/datum/game_mode/pve/proc/update_hud(datum/pve_account/account)
	var/client/player_client = account.get_client()
	if(!player_client)
		return
	player_client.screen |= account.hud
	var/status_line
	var/extra_line
	if(finished)
		status_line = victory ? "Туман рассеян. Победа!" : "Оборона пала."
	else if(wave_active)
		status_line = "Волна [wave]/[PVE_FINAL_WAVE] · Врагов: [enemies_remaining()]"
		if(mutator)
			status_line += " · [mutator_title(mutator)]"
		if(active_boss)
			status_line += " · Босс: [round(active_boss.health / active_boss.maxHealth * 100)]%"
		if(contract)
			extra_line = "Контракт — [contract.status_text()]"
	else
		var/seconds = max(0, round((next_wave_time - world.time) / (1 SECONDS)))
		status_line = "Подготовка к волне [wave + 1]/[PVE_FINAL_WAVE] · [round(seconds / 60)]:[seconds % 60 < 10 ? "0" : ""][seconds % 60]"
		if(is_boss_wave(wave + 1))
			status_line += " · Босс!"
		if(next_mutator)
			extra_line = "Разведка: [mutator_title(next_mutator)]"
	var/ready_count = 0
	var/alive_count = 0
	for(var/account_key in player_accounts)
		var/datum/pve_account/teammate = player_accounts[account_key]
		var/mob/living/teammate_body = teammate.get_body()
		if(teammate_body?.stat == DEAD || teammate_body?.z != arena_z)
			continue
		alive_count++
		if(teammate.ready)
			ready_count++
	var/info_line = "Маяк: [core ? round(core.obj_integrity / core.max_integrity * 100) : 0]% · Кредиты: [account.credits]"
	if(!wave_active && !finished)
		info_line += " · Готовы: [ready_count]/[alive_count]"
	account.hud.maptext = MAPTEXT("<div style='text-align:center'><b>[status_line]</b><br>[info_line][extra_line ? "<br>[extra_line]" : ""]</div>")

/datum/game_mode/pve/proc/prompt_class(datum/pve_account/account)
	var/mob/living/carbon/human/player = account.get_body()
	if(!ishuman(player) || player.stat == DEAD || !player.client || account.class_id || account.class_prompt_open)
		return FALSE
	account.class_prompt_open = TRUE
	INVOKE_ASYNC(src, PROC_REF(show_class_menu), account, player)
	return TRUE

/datum/game_mode/pve/proc/show_class_menu(datum/pve_account/account, mob/living/carbon/human/player)
	var/list/choices = list()
	for(var/class_id in classes)
		var/datum/pve_class/option = classes[class_id]
		choices[class_id] = option.radial_choice()
	var/picked = show_radial_menu(player, player, choices, require_near = FALSE)
	account.class_prompt_open = FALSE
	if(picked)
		choose_class(account, picked)

/datum/game_mode/pve/proc/choose_class(datum/pve_account/account, class_id)
	var/datum/pve_class/player_class = classes[class_id]
	var/mob/living/carbon/human/player = account.get_body()
	if(account.class_id || !player_class || !ishuman(player) || player.stat == DEAD)
		return FALSE
	account.class_id = class_id
	player_class.equip(player)
	to_chat(player, span_boldnotice("Ваш класс — [player_class.title]. [player_class.description]"))
	return TRUE

/datum/game_mode/pve/proc/toggle_ready(datum/pve_account/account)
	if(!account || wave_active || finished)
		return
	account.set_ready(!account.ready)
	if(!account.ready)
		return
	var/list/mob/living/carbon/human/survivors = living_players()
	for(var/mob/living/carbon/human/player as anything in survivors)
		var/datum/pve_account/teammate = get_account(player)
		if(!teammate?.ready)
			return
	if(next_wave_time > world.time + PVE_READY_COUNTDOWN)
		next_wave_time = world.time + PVE_READY_COUNTDOWN
		broadcast(span_boldnotice("Все защитники готовы! Волна начнётся через [PVE_READY_COUNTDOWN / (1 SECONDS)] секунд."))

/datum/game_mode/pve/proc/transfer_credits(datum/pve_account/sender, receiver_key, amount)
	var/datum/pve_account/receiver = player_accounts[receiver_key]
	amount = round(amount)
	if(!receiver || receiver == sender || amount <= 0 || sender.credits < amount)
		return FALSE
	sender.credits -= amount
	receiver.credits += amount
	var/mob/receiver_body = receiver.get_body()
	if(receiver_body)
		to_chat(receiver_body, span_notice("[sender.player_name] переводит вам [amount] кредитов."))
	return TRUE

/datum/game_mode/pve/proc/completed_waves()
	return wave_active ? wave - 1 : wave

/datum/game_mode/pve/proc/is_boss_wave(wave_number)
	return wave_number >= PVE_FINAL_WAVE || !(wave_number % PVE_BOSS_WAVE_INTERVAL)

/datum/game_mode/pve/proc/boss_for_wave(wave_number)
	if(wave_number >= PVE_FINAL_WAVE)
		return /mob/living/simple_animal/hostile/pve/boss/devourer
	switch(wave_number / PVE_BOSS_WAVE_INTERVAL)
		if(1)
			return /mob/living/simple_animal/hostile/pve/boss/broodmother
		if(2)
			return /mob/living/simple_animal/hostile/pve/boss/legionnaire
		if(3)
			return /mob/living/simple_animal/hostile/pve/boss/herald
	return null

/datum/game_mode/pve/proc/start_wave(player_count)
	wave++
	wave_active = TRUE
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		account.set_ready(FALSE)
	mutator = is_boss_wave(wave) ? null : next_mutator
	next_mutator = null
	if(mutator == PVE_MUTATOR_NIGHT)
		set_outdoor_lighting(PVE_NIGHT_LIGHTING_ALPHA)
	boss_type = is_boss_wave(wave) ? boss_for_wave(wave) : null
	spawn_queue = build_wave_queue(max(player_count, 1))
	boss_spawn_at = round(length(spawn_queue) * PVE_BOSS_QUEUE_FRACTION)
	treasure_spawn_at = 0
	if(wave >= PVE_TREASURE_MIN_WAVE && (mutator == PVE_MUTATOR_GOLD || prob(PVE_TREASURE_CHANCE)))
		treasure_spawn_at = rand(1, max(1, length(spawn_queue)))
	contract = roll_contract()
	next_spawn_time = world.time
	next_supply_drop = world.time + PVE_SUPPLY_DROP_INTERVAL
	var/headline = "ВОЛНА [wave]"
	if(wave >= PVE_FINAL_WAVE)
		headline = "ПОСЛЕДНЯЯ ВОЛНА"
	if(mutator)
		headline += "\n[uppertext(mutator_title(mutator))]"
	banner(headline)
	var/message = "Волна [wave] из [PVE_FINAL_WAVE]! Тварей: [length(spawn_queue)]."
	if(mutator)
		message += " [mutator_title(mutator)]: [mutator_description(mutator)]"
	if(boss_type)
		message += " С ними идёт босс!"
	if(contract)
		message += " Контракт «[contract.title]»: [contract.description]"
	broadcast(span_boldannounceic(message), boss_type ? 'sound/effects/siren-spooky.ogg' : 'sound/misc/notice1.ogg')

/datum/game_mode/pve/proc/build_wave_queue(player_count)
	var/budget = (4 + wave * 3) * (0.6 + 0.4 * min(player_count, 10))
	if(mutator == PVE_MUTATOR_HORDE)
		budget *= 1.5
	if(boss_type)
		budget *= 0.5
	budget = round(budget)
	var/list/weights = list()
	for(var/mob/living/simple_animal/hostile/pve/enemy_type as anything in valid_subtypesof(/mob/living/simple_animal/hostile/pve))
		if(initial(enemy_type.spawn_weight) && initial(enemy_type.unlock_wave) <= wave)
			weights[enemy_type] = initial(enemy_type.spawn_weight)
	var/list/queue = list()
	while(budget > 0 && length(weights))
		var/mob/living/simple_animal/hostile/pve/picked = pickweight(weights)
		var/cost = initial(picked.spawn_cost)
		if(cost > budget)
			weights -= picked
			continue
		budget -= cost
		for(var/i in 1 to initial(picked.group_size))
			queue += picked
	return shuffle(queue)

/datum/game_mode/pve/proc/roll_mutator(wave_number)
	if(wave_number < 3 || is_boss_wave(wave_number) || !prob(PVE_MUTATOR_CHANCE))
		return null
	var/list/options = list(PVE_MUTATOR_NIGHT, PVE_MUTATOR_FRENZY, PVE_MUTATOR_HORDE, PVE_MUTATOR_BLOOD_MOON, PVE_MUTATOR_IRONHIDE, PVE_MUTATOR_REGEN, PVE_MUTATOR_GOLD) - last_mutator
	last_mutator = pick(options)
	return last_mutator

/datum/game_mode/pve/proc/roll_contract()
	if(wave < 2 || !prob(PVE_CONTRACT_CHANCE))
		return null
	var/list/options = list()
	for(var/datum/pve_contract/contract_type as anything in valid_subtypesof(/datum/pve_contract))
		if(initial(contract_type.min_wave) <= wave)
			options += contract_type
	if(!length(options))
		return null
	var/contract_type = pick(options)
	var/datum/pve_contract/new_contract = new contract_type
	new_contract.start(src)
	return new_contract

/datum/game_mode/pve/proc/on_core_damaged(amount)
	if(wave_active)
		contract?.on_core_damage(src, amount)

/datum/game_mode/pve/proc/mutator_title(mutator_id)
	switch(mutator_id)
		if(PVE_MUTATOR_NIGHT)
			return "Ночь"
		if(PVE_MUTATOR_FRENZY)
			return "Ярость"
		if(PVE_MUTATOR_HORDE)
			return "Орда"
		if(PVE_MUTATOR_BLOOD_MOON)
			return "Кровавая луна"
		if(PVE_MUTATOR_IRONHIDE)
			return "Железная шкура"
		if(PVE_MUTATOR_REGEN)
			return "Живучесть"
		if(PVE_MUTATOR_GOLD)
			return "Золотая лихорадка"

/datum/game_mode/pve/proc/mutator_description(mutator_id)
	switch(mutator_id)
		if(PVE_MUTATOR_NIGHT)
			return "туман гасит свет над полем, нужны фонари и прожекторы."
		if(PVE_MUTATOR_FRENZY)
			return "твари двигаются заметно быстрее."
		if(PVE_MUTATOR_HORDE)
			return "тварей в полтора раза больше, но они слабее."
		if(PVE_MUTATOR_BLOOD_MOON)
			return "твари крепче и злее, зато награда за них выше."
		if(PVE_MUTATOR_IRONHIDE)
			return "пули и клинки бьют тварей слабее, лазеры — как обычно."
		if(PVE_MUTATOR_REGEN)
			return "раны тварей затягиваются на глазах — добивайте раненых."
		if(PVE_MUTATOR_GOLD)
			return "каждая тварь роняет кредитный чип, а по полю мечется светоч тумана."

/datum/game_mode/pve/proc/current_mutator_title()
	return wave_active && mutator ? mutator_title(mutator) : null

/datum/game_mode/pve/proc/set_outdoor_lighting(alpha)
	for(var/area/pve/outdoor_area in GLOB.areas)
		if(istype(outdoor_area, /area/pve/field) || istype(outdoor_area, /area/pve/nest))
			outdoor_area.set_base_lighting(new_alpha = alpha)

/datum/game_mode/pve/proc/process_spawning(player_count)
	if(world.time < next_spawn_time)
		return
	next_spawn_time = world.time + PVE_SPAWN_GROUP_INTERVAL
	if(boss_type && length(spawn_queue) <= boss_spawn_at)
		spawn_boss(player_count)
	var/group_size = rand(3, 5) + round(player_count / 2)
	for(var/i in 1 to group_size)
		if(!length(spawn_queue) || length(active_enemies) >= PVE_MAX_ALIVE_ENEMIES)
			return
		var/enemy_type = spawn_queue[length(spawn_queue)]
		spawn_queue.len--
		spawn_enemy(enemy_type)

/datum/game_mode/pve/proc/get_spawn_turf()
	var/turf/center = pick(enemy_spawns)
	var/list/turf/candidates = list()
	for(var/turf/nearby in range(1, center))
		if(!nearby.is_blocked_turf())
			candidates += nearby
	return length(candidates) ? pick(candidates) : center

/datum/game_mode/pve/proc/spawn_enemy(enemy_type)
	var/turf/spawn_turf = get_spawn_turf()
	var/mob/living/simple_animal/hostile/pve/enemy = new enemy_type(spawn_turf)
	var/health_multiplier = 1 + 0.07 * (wave - 1)
	var/damage_multiplier = 1 + 0.04 * (wave - 1)
	var/speed_multiplier = 1
	switch(mutator)
		if(PVE_MUTATOR_FRENZY)
			speed_multiplier = 0.7
		if(PVE_MUTATOR_HORDE)
			health_multiplier *= 0.7
		if(PVE_MUTATOR_BLOOD_MOON)
			health_multiplier *= 1.25
			damage_multiplier *= 1.2
	enemy.apply_scaling(health_multiplier, damage_multiplier, speed_multiplier)
	if(wave >= 4 && prob(min(PVE_MAX_ELITE_CHANCE, (wave - 3) * 2)))
		enemy.make_elite()
	new /obj/effect/temp_visual/small_smoke/halfsecond(spawn_turf)
	add_enemy(enemy)
	return enemy

/datum/game_mode/pve/proc/spawn_treasure()
	treasure_spawn_at = 0
	var/mob/living/simple_animal/hostile/pve/treasure/wisp = new(get_spawn_turf())
	add_enemy(wisp)
	broadcast(span_boldnotice("По полю мечется светоч тумана! Догоните его, пока он не ускользнул обратно в гнездо, — за него щедро платят."), 'sound/magic/staff_healing.ogg')

/datum/game_mode/pve/proc/regenerate_enemies()
	for(var/mob/living/simple_animal/hostile/pve/enemy as anything in active_enemies)
		if(enemy.stat != DEAD && enemy.health < enemy.maxHealth)
			enemy.adjustHealth(-enemy.maxHealth * PVE_REGEN_FRACTION)

/datum/game_mode/pve/proc/spawn_boss(player_count)
	var/mob/living/simple_animal/hostile/pve/boss/boss = new boss_type(pick(enemy_spawns))
	boss_type = null
	boss.apply_scaling((0.6 + 0.4 * max(player_count, 1)) * (1 + 0.03 * (wave - 1)), 1, 1)
	active_boss = boss
	add_enemy(boss)
	banner("[uppertext(boss.declent_ru(NOMINATIVE))]", "#ff2020")
	broadcast(span_userdanger("Из тумана выходит [boss.declent_ru(NOMINATIVE)]!"), 'sound/effects/curse5.ogg')

/datum/game_mode/pve/proc/add_enemy(mob/living/simple_animal/hostile/pve/enemy)
	active_enemies += enemy
	RegisterSignals(enemy, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING), PROC_REF(on_enemy_removed))
	if(mutator == PVE_MUTATOR_NIGHT)
		enemy.set_light(2, 1, "#ff3030")
	if(mutator == PVE_MUTATOR_IRONHIDE)
		enemy.damage_coeff = enemy.damage_coeff.Copy()
		enemy.damage_coeff[BRUTE] *= 0.75
	enemy.toggle_ai(AI_ON)

/datum/game_mode/pve/proc/enemies_remaining()
	return length(active_enemies) + length(spawn_queue) + (boss_type ? 1 : 0)

/datum/game_mode/pve/proc/on_enemy_removed(mob/living/simple_animal/hostile/pve/source)
	SIGNAL_HANDLER
	active_enemies -= source
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	if(source == active_boss)
		active_boss = null
		if(source.stat == DEAD)
			banner("БОСС ПОВЕРЖЕН", "#ffd040")
	if(source.stat == DEAD && !finished)
		reward_kill(source)
	if(!QDELETED(source))
		QDEL_IN(source, 30 SECONDS)

/datum/game_mode/pve/proc/reward_kill(mob/living/simple_animal/hostile/pve/enemy)
	total_kills++
	if(wave_active)
		contract?.on_kill(src, enemy)
	drop_loot(enemy)
	var/bounty = enemy.bounty
	if(mutator == PVE_MUTATOR_BLOOD_MOON)
		bounty *= 1.6
	var/datum/mind/killer_mind = enemy.last_hitter?.resolve()
	var/datum/pve_account/killer = killer_mind ? player_accounts[killer_mind.UID()] : null
	if(istype(enemy, /mob/living/simple_animal/hostile/pve/boss))
		for(var/account_key in player_accounts)
			var/datum/pve_account/account = player_accounts[account_key]
			account.add_credits(round(bounty / 2))
		broadcast(span_boldannounceic("[DECLENT_RU_CAP(enemy, NOMINATIVE)] повержен[killer ? " рукой [killer.player_name]" : ""]! Каждый получает [round(bounty / 2)] кредитов."), 'sound/misc/notice2.ogg')
	if(istype(enemy, /mob/living/simple_animal/hostile/pve/treasure))
		broadcast(span_boldnotice("[killer ? killer.player_name : "Кто-то"] ловит светоч тумана!"), 'sound/misc/notice2.ogg')
	if(!killer)
		return
	var/datum/pve_class/killer_class = classes[killer.class_id]
	var/reward = round(bounty * (killer_class ? killer_class.bounty_multiplier : 1) * (1 + killer.upgrade_level(PVE_UPGRADE_LOOTER) * PVE_LOOTER_BONUS))
	killer.kills++
	killer.add_credits(reward)
	var/mob/killer_body = killer.get_body()
	killer_body?.balloon_alert(killer_body, "+[reward]")

/datum/game_mode/pve/proc/drop_loot(mob/living/simple_animal/hostile/pve/enemy)
	var/static/list/field_loot = list(
		/obj/item/stack/medical/bruise_pack = 3,
		/obj/item/stack/medical/ointment = 3,
		/obj/item/reagent_containers/hypospray/autoinjector = 2,
		/obj/item/ammo_box/magazine/m10mm = 2,
		/obj/item/ammo_box/speedloader/shotgun/buck = 2,
		/obj/item/ammo_box/speedloader/a762 = 2,
		/obj/item/flashlight/flare = 2,
		/obj/item/pve_deployable/mine = 1,
		/obj/item/grenade/frag = 1,
	)
	var/turf/drop_turf = get_turf(enemy)
	if(!drop_turf || istype(enemy, /mob/living/simple_animal/hostile/pve/boss))
		return
	if(enemy.elite || mutator == PVE_MUTATOR_GOLD || prob(PVE_LOOT_CHIP_CHANCE))
		new /obj/item/pve_credit_chip(drop_turf, max(5, round(enemy.bounty)))
	if(prob(PVE_LOOT_ITEM_CHANCE))
		var/loot_type = pickweight(field_loot)
		new loot_type(drop_turf)

/datum/game_mode/pve/proc/complete_wave()
	wave_active = FALSE
	if(mutator == PVE_MUTATOR_NIGHT)
		set_outdoor_lighting(255)
	mutator = null
	treasure_spawn_at = 0
	var/reward = PVE_WAVE_REWARD_BASE + wave * PVE_WAVE_REWARD_PER_WAVE
	var/contract_reward = 0
	if(contract?.is_complete(src))
		contract_reward = PVE_CONTRACT_REWARD_BASE + wave * PVE_CONTRACT_REWARD_PER_WAVE
		broadcast(span_boldnotice("Контракт «[contract.title]» выполнен! Каждый получает ещё [contract_reward] кредитов."))
	else if(contract)
		broadcast(span_warning("Контракт «[contract.title]» не выполнен."))
	QDEL_NULL(contract)
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		var/mob/living/body = account.get_body()
		account.add_credits((body?.stat == DEAD ? round(reward / 2) : reward) + contract_reward)
	core?.repair_damage(core.max_integrity * PVE_CORE_WAVE_REGEN)
	respawn_dead()
	if(wave >= PVE_FINAL_WAVE)
		finish(TRUE, "Пожиратель тумана повержен, туман рассеивается.")
		return
	next_wave_time = world.time + (is_boss_wave(wave + 1) ? PVE_BOSS_PREPARATION : PVE_PREPARATION)
	next_mutator = roll_mutator(wave + 1)
	banner("ВОЛНА [wave] ОТБИТА", "#60ff80")
	broadcast(span_boldannounceic("Волна [wave] отбита! Каждый получает [reward] кредитов (павшие — половину), Маяк частично восстановлен. Следующая волна через [round((next_wave_time - world.time) / (1 SECONDS))] секунд[is_boss_wave(wave + 1) ? " — и это будет босс" : ""]."), 'sound/misc/notice2.ogg')
	if(next_mutator)
		broadcast(span_notice("Разведка докладывает: следующая волна — [mutator_title(next_mutator)], [mutator_description(next_mutator)]"))

/datum/game_mode/pve/proc/respawn_dead()
	. = FALSE
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		var/mob/living/body = account.get_body()
		if(istype(body) && body.stat != DEAD && body.z == arena_z)
			continue
		if(respawn_player(account))
			. = TRUE

/datum/game_mode/pve/proc/respawn_player(datum/pve_account/account)
	var/datum/mind/player_mind = account.mind_ref?.resolve()
	if(!player_mind)
		return FALSE
	var/turf/spawn_turf = pick(player_spawns)
	var/mob/living/carbon/human/body = player_mind.current
	if(ishuman(body) && !QDELETED(body))
		body.check_and_regenerate_organs()
		body.rejuvenate()
		body.forceMove(spawn_turf)
		body.grab_ghost(TRUE)
		to_chat(body, span_boldnotice("Вы снова в строю!"))
		return TRUE
	var/client/player_client = account.get_client()
	if(!player_client)
		return FALSE
	var/mob/living/carbon/human/new_body = new(spawn_turf)
	player_client.prefs.apply_prefs_to(new_body)
	player_mind.transfer_to(new_body)
	var/datum/outfit/pve/outfit = new
	outfit.equip(new_body)
	var/datum/pve_class/player_class = classes[account.class_id]
	player_class?.equip(new_body)
	apply_upgrades(account, new_body)
	to_chat(new_body, span_boldnotice("Вы снова в строю!"))
	return TRUE

/datum/game_mode/pve/proc/apply_upgrades(datum/pve_account/account, mob/living/carbon/human/body)
	for(var/product_id in products)
		var/datum/pve_product/upgrade/upgrade = products[product_id]
		if(!istype(upgrade))
			continue
		for(var/i in 1 to account.upgrade_level(upgrade.upgrade_id))
			upgrade.apply_upgrade(body)

/datum/game_mode/pve/proc/launch_supply_drop()
	if(!length(drop_turfs))
		return FALSE
	var/static/list/supply_loot = list(
		/obj/item/storage/firstaid/regular = 3,
		/obj/item/reagent_containers/hypospray/autoinjector/survival = 2,
		/obj/item/grenade/frag = 3,
		/obj/item/ammo_box/magazine/m10mm = 3,
		/obj/item/ammo_box/speedloader/shotgun/buck = 3,
		/obj/item/ammo_box/magazine/wt550m9 = 2,
		/obj/item/ammo_box/speedloader/a762 = 2,
		/obj/item/pve_deployable/mine = 3,
		/obj/item/pve_deployable/sandbags = 2,
		/obj/item/pve_deployable/lamp = 2,
		/obj/item/gun/energy/laser = 1,
		/obj/item/pve_deployable/med_station = 1,
	)
	var/turf/landing = pick(drop_turfs)
	var/obj/structure/closet/supplypod/bluespacepod/pve_drop/pod = new
	for(var/i in 1 to rand(2, 3))
		var/loot_type = pickweight(supply_loot)
		new loot_type(pod)
	new /obj/item/pve_credit_chip(pod, 50 + wave * 10)
	new /obj/effect/pod_landingzone(landing, pod)
	var/distance = get_dist(landing, core)
	var/location = distance < 20 ? "у самого лагеря" : (distance < 35 ? "в центре поля" : "у входа в гнездо")
	broadcast(span_boldnotice("Капсула снабжения падает [location]!"), 'sound/misc/notice3.ogg')
	return TRUE

/datum/game_mode/pve/proc/on_core_destroyed(obj/structure/pve_core/destroyed_core)
	if(finished)
		return
	finish(FALSE, "Маяк погас, и туман поглотил лагерь.")

/datum/game_mode/pve/proc/on_core_deleted(datum/source)
	SIGNAL_HANDLER
	core = null

/datum/game_mode/pve/proc/finish(won, reason)
	var/survived_waves = completed_waves()
	finished = TRUE
	victory = won
	end_reason = reason
	wave_active = FALSE
	spawn_queue.Cut()
	boss_type = null
	treasure_spawn_at = 0
	QDEL_NULL(contract)
	set_outdoor_lighting(255)
	for(var/mob/living/simple_animal/hostile/pve/enemy as anything in active_enemies)
		enemy.toggle_ai(AI_OFF)
	banner(won ? "ПОБЕДА" : "ПОРАЖЕНИЕ", won ? "#ffd040" : "#ff2020")
	broadcast(span_boldannounceic("[reason] Волн отбито: [survived_waves]."), won ? 'sound/misc/announce.ogg' : 'sound/effects/siren-spooky.ogg')
	end_timer_id = addtimer(VARSET_CALLBACK(SSticker, force_ending, TRUE), PVE_END_DELAY, TIMER_STOPPABLE)

/datum/game_mode/pve/check_finished()
	return (finished && SSticker.force_ending) || station_was_nuked

/datum/game_mode/pve/declare_completion()
	var/list/lines = list()
	lines += "<b>Colonial Marines: [victory ? "победа" : "поражение"].</b> [end_reason || "Оборона прервана."]"
	lines += "Отбито волн: [completed_waves()] из [PVE_FINAL_WAVE]. Тварей убито: [total_kills]."
	var/list/ranking = list()
	for(var/account_key in player_accounts)
		var/datum/pve_account/account = player_accounts[account_key]
		ranking[account] = account.kills
	sortTim(ranking, GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	var/place = 0
	for(var/datum/pve_account/account as anything in ranking)
		place++
		var/datum/pve_class/player_class = classes[account.class_id]
		lines += "[place]. [account.player_name] ([player_class?.title || "без класса"]) — убийств: [account.kills], заработано: [account.earned] кр., смертей: [account.deaths]."
	to_chat(world, custom_boxed_message("blue_box", lines.Join("<br>")))
	return ..()

/datum/game_mode/pve/Destroy()
	deltimer(end_timer_id)
	for(var/mob/living/enemy as anything in active_enemies)
		UnregisterSignal(enemy, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	QDEL_LIST(active_enemies)
	QDEL_LIST_ASSOC_VAL(player_accounts)
	QDEL_LIST_ASSOC_VAL(classes)
	QDEL_LIST_ASSOC_VAL(products)
	QDEL_NULL(flow_field)
	QDEL_NULL(contract)
	if(core)
		UnregisterSignal(core, COMSIG_QDELETING)
	core = null
	active_boss = null
	enemy_spawns = null
	player_spawns = null
	drop_turfs = null
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
	var/datum/weakref/mind_ref
	var/player_name
	var/credits = 0
	var/earned = 0
	var/kills = 0
	var/deaths = 0
	var/class_id
	var/list/upgrades = list()
	var/ready = FALSE
	var/class_prompt_open = FALSE
	var/next_class_prompt = 0
	var/atom/movable/screen/pve_hud/hud
	var/datum/action/innate/pve_ready/ready_action

/datum/pve_account/New(datum/mind/player_mind, credits)
	mind_ref = WEAKREF(player_mind)
	src.credits = credits
	hud = new
	ready_action = new(src)

/datum/pve_account/Destroy()
	var/client/player_client = get_client()
	player_client?.screen -= hud
	QDEL_NULL(hud)
	QDEL_NULL(ready_action)
	mind_ref = null
	return ..()

/datum/pve_account/proc/get_body()
	var/datum/mind/player_mind = mind_ref?.resolve()
	return player_mind?.current

/datum/pve_account/proc/get_client()
	var/datum/mind/player_mind = mind_ref?.resolve()
	return player_mind?.key ? GLOB.directory[ckey(player_mind.key)] : null

/datum/pve_account/proc/upgrade_level(upgrade_id)
	return upgrades[upgrade_id] || 0

/datum/pve_account/proc/add_credits(amount)
	credits += amount
	earned += amount

/datum/pve_account/proc/set_ready(new_ready)
	ready = new_ready
	ready_action.active = new_ready
	ready_action.build_all_button_icons(UPDATE_BUTTON_STATUS)

/datum/action/innate/pve_ready
	name = "Готов к волне"
	desc = "Отметиться готовым. Когда готовы все живые защитники, волна начнётся через 10 секунд."
	button_icon = 'icons/hud/radial.dmi'
	button_icon_state = "radial_yes"

/datum/action/innate/pve_ready/Activate()
	var/datum/game_mode/pve/mode = get_pve_mode()
	var/datum/pve_account/account = target
	mode?.toggle_ready(account)

/datum/action/innate/pve_ready/Deactivate()
	var/datum/game_mode/pve/mode = get_pve_mode()
	var/datum/pve_account/account = target
	mode?.toggle_ready(account)

/atom/movable/screen/pve_hud
	name = "defense status"
	screen_loc = "CENTER-5,TOP-1"
	maptext_width = 352
	maptext_height = 56
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/map_template/pve_arena
	name = "PvE Fog Arena"
	mappath = "_maps/map_files/pve/fog.dmm"

/area/pve
	name = "Fog Arena"
	icon_state = "away"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	base_lighting_alpha = 255
	ambient_buzz = null

/area/pve/base
	name = "Fog Arena Headquarters"
	icon_state = "bridge"

/area/pve/base/armory
	name = "Fog Arena Armory"
	icon_state = "armory"

/area/pve/base/rest
	name = "Fog Arena Rest Zone"
	icon_state = "dorms"

/area/pve/base/medbay
	name = "Fog Arena Medbay"
	icon_state = "medbay"

/area/pve/base/engineering
	name = "Fog Arena Engineering"
	icon_state = "engine"

/area/pve/field
	name = "Fog Field"
	icon_state = "away1"

/area/pve/nest
	name = "Fog Nest"
	icon_state = "away2"

/obj/effect/landmark/pve_spawn
	name = "PvE player spawn"

/obj/effect/landmark/pve_spawn/enemy
	name = "PvE enemy spawn"

#undef PVE_FIRST_PREPARATION
#undef PVE_PREPARATION
#undef PVE_BOSS_PREPARATION
#undef PVE_READY_COUNTDOWN
#undef PVE_STARTING_CREDITS
#undef PVE_LATE_JOIN_CREDITS_PER_WAVE
#undef PVE_WAVE_REWARD_BASE
#undef PVE_WAVE_REWARD_PER_WAVE
#undef PVE_MAX_ALIVE_ENEMIES
#undef PVE_SPAWN_GROUP_INTERVAL
#undef PVE_SUPPLY_DROP_INTERVAL
#undef PVE_CLASS_PROMPT_INTERVAL
#undef PVE_NEST_TOXIN
#undef PVE_REGEN_AMOUNT
#undef PVE_BED_REGEN_AMOUNT
#undef PVE_CORE_WAVE_REGEN
#undef PVE_END_DELAY
#undef PVE_NIGHT_LIGHTING_ALPHA
#undef PVE_BOSS_QUEUE_FRACTION
#undef PVE_MAX_ELITE_CHANCE
#undef PVE_MUTATOR_CHANCE
#undef PVE_CONTRACT_CHANCE
#undef PVE_CONTRACT_REWARD_BASE
#undef PVE_CONTRACT_REWARD_PER_WAVE
#undef PVE_TREASURE_CHANCE
#undef PVE_TREASURE_MIN_WAVE
#undef PVE_LOOT_CHIP_CHANCE
#undef PVE_LOOT_ITEM_CHANCE
#undef PVE_REGEN_FRACTION
#undef PVE_LOOTER_BONUS
