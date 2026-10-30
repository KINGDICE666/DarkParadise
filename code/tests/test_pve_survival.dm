/datum/unit_test/pve_survival
	var/datum/game_mode/previous_mode
	var/datum/game_mode/pve/mode
	var/previous_force_ending

/datum/unit_test/pve_survival/Run()
	previous_mode = SSticker.mode
	previous_force_ending = SSticker.force_ending
	mode = allocate(/datum/game_mode/pve)
	SSticker.mode = mode
	TEST_ASSERT(mode.pre_setup(), "PvE arena failed to load.")
	TEST_ASSERT_EQUAL(length(GLOB.start_override), 5, "Unexpected PvE state.")
	TEST_ASSERT_EQUAL(length(mode.enemy_spawns), 4, "Unexpected PvE state.")
	var/turf/player_spawn = GLOB.start_override[1]
	var/turf/enemy_spawn = mode.enemy_spawns[1]
	TEST_ASSERT(player_spawn.x < enemy_spawn.x, "Players must spawn to the left of enemies.")
	TEST_ASSERT_EQUAL(player_spawn.z, enemy_spawn.z, "Unexpected PvE state.")
	var/mob/living/carbon/human/player = allocate(/mob/living/carbon/human, player_spawn)
	player.mind_initialize()
	var/datum/outfit/pve/outfit = allocate(/datum/outfit/pve)
	outfit.equip(player)
	TEST_ASSERT(istype(player.l_hand, /obj/item/melee/baseball_bat), "PvE starter bat was not equipped.")
	TEST_ASSERT(istype(player.r_store, /obj/item/kitchen/knife), "PvE starter knife was not equipped.")
	var/datum/pve_account/account = mode.player_accounts[player.mind.UID()]
	TEST_ASSERT_NOTNULL(account, "Required PvE fixture is missing.")
	TEST_ASSERT_EQUAL(account.credits, 100, "Unexpected PvE state.")
	account.credits = 75
	mode.register_player(player)
	TEST_ASSERT_EQUAL(account.credits, 75, "Registering a player twice must preserve the balance.")
	var/obj/machinery/computer/pve_shop/shop
	for(var/obj/machinery/computer/pve_shop/candidate in get_area(player))
		shop = candidate
		break
	TEST_ASSERT_NOTNULL(shop, "Required PvE fixture is missing.")
	player.forceMove(get_step(shop, EAST))
	TEST_ASSERT(shop.purchase(player, "bandages"), "An affordable purchase failed.")
	TEST_ASSERT_EQUAL(account.credits, 50, "Unexpected PvE state.")
	TEST_ASSERT(!shop.purchase(player, "armor"), "An unaffordable purchase succeeded.")
	TEST_ASSERT(!shop.purchase(player, "invalid_product"), "An invalid product was accepted.")
	TEST_ASSERT_EQUAL(account.credits, 50, "Unexpected PvE state.")
	player.forceMove(player_spawn)
	TEST_ASSERT(!shop.purchase(player, "bandages"), "A remote purchase succeeded.")
	TEST_ASSERT_EQUAL(account.credits, 50, "Unexpected PvE state.")
	mode.started = TRUE
	mode.next_wave = world.time + 1 MINUTES
	mode.process()
	TEST_ASSERT_EQUAL(mode.wave, 0, "A wave started before preparation ended.")
	mode.next_wave = world.time
	mode.process()
	TEST_ASSERT_EQUAL(mode.wave, 1, "Unexpected PvE state.")
	TEST_ASSERT(mode.wave_active, "First wave did not activate.")
	TEST_ASSERT_EQUAL(mode.enemies_to_spawn, 5, "Unexpected PvE state.")
	mode.process()
	TEST_ASSERT_EQUAL(length(mode.active_enemies), 1, "Unexpected PvE state.")
	var/mob/living/simple_animal/hostile/carp/pve/enemy = mode.active_enemies[1]
	TEST_ASSERT(player in enemy.ListTargets(), "Enemies cannot find players across the corridor.")
	TEST_ASSERT(enemy.CanAttack(player), "Enemies cannot attack the survivor.")
	enemy.death()
	TEST_ASSERT_EQUAL(length(mode.active_enemies), 0, "Enemy death did not update the wave.")
	mode.process()
	TEST_ASSERT_EQUAL(mode.completed_waves, 0, "Wave was rewarded before all enemies spawned.")
	while(mode.enemies_to_spawn)
		mode.spawn_enemy()
	for(var/mob/living/remaining_enemy as anything in mode.active_enemies.Copy())
		qdel(remaining_enemy)
	mode.process()
	TEST_ASSERT_EQUAL(mode.completed_waves, 1, "Unexpected PvE state.")
	TEST_ASSERT_EQUAL(account.credits, 175, "Unexpected PvE state.")
	TEST_ASSERT_EQUAL(account.score, 100, "Unexpected PvE state.")
	mode.process()
	TEST_ASSERT_EQUAL(account.credits, 175, "The wave reward was issued twice.")
	TEST_ASSERT(!mode.wave_active, "Preparation did not resume after clearing the wave.")
	mode.wave = 4
	mode.start_wave(1)
	while(mode.enemies_to_spawn)
		mode.spawn_enemy()
	var/boss_count = 0
	for(var/mob/living/simple_animal/hostile/carp/pve/opponent as anything in mode.active_enemies)
		if(istype(opponent, /mob/living/simple_animal/hostile/carp/pve/boss))
			boss_count++
	TEST_ASSERT_EQUAL(boss_count, 1, "The fifth wave must contain one boss.")
	enemy = mode.active_enemies[1]
	TEST_ASSERT(enemy.maxHealth > initial(enemy.maxHealth), "Enemy health did not scale with wave number.")
	mode.started = FALSE
	var/obj/machinery/porta_turret/syndicate/pve/turret = allocate(/obj/machinery/porta_turret/syndicate/pve, get_step(player, EAST))
	TEST_ASSERT_EQUAL(turret.assess_living(player), TURRET_NOT_TARGET, "Unexpected PvE state.")
	TEST_ASSERT_EQUAL(turret.assess_living(enemy), TURRET_PRIORITY_TARGET, "Unexpected PvE state.")
	var/obj/projectile/bullet/pve_turret/bullet = allocate(/obj/projectile/bullet/pve_turret, get_turf(turret))
	var/previous_damage = player.getBruteLoss()
	bullet.prehit(player)
	player.bullet_act(bullet)
	TEST_ASSERT_EQUAL(player.getBruteLoss(), previous_damage, "PvE turret bullets hurt an ally.")
	bullet.prehit(enemy)
	TEST_ASSERT(!bullet.nodamage, "A turret bullet stayed harmless after passing an ally.")
	TEST_ASSERT(!bullet.forcedodge, "A turret bullet would pass through a wave enemy.")
	mode.started = TRUE
	player.death()
	mode.process()
	TEST_ASSERT(mode.finished, "PvE did not end after all survivors died.")
	TEST_ASSERT(mode.check_finished(), "The ticker cannot see the PvE defeat.")
	TEST_ASSERT(SSticker.force_ending, "PvE defeat cannot end a continuous round.")

/datum/unit_test/pve_survival/Destroy()
	mode.started = FALSE
	SSticker.mode = previous_mode
	SSticker.force_ending = previous_force_ending
	previous_mode = null
	mode = null
	return ..()
