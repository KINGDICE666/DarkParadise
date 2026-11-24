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
	TEST_ASSERT_NOTNULL(mode.core, "PvE arena has no beacon.")
	TEST_ASSERT(length(mode.player_spawns) >= 4, "PvE arena has too few player spawns.")
	TEST_ASSERT(length(mode.enemy_spawns) >= 4, "PvE arena has too few enemy spawns.")
	TEST_ASSERT(length(mode.drop_turfs), "PvE arena has no supply drop turfs.")
	TEST_ASSERT_EQUAL(length(mode.classes), 5, "Unexpected PvE class count.")
	var/turf/player_spawn = mode.player_spawns[1]
	var/turf/enemy_spawn = mode.enemy_spawns[1]
	TEST_ASSERT(player_spawn.x < enemy_spawn.x, "Players must spawn to the left of enemies.")
	TEST_ASSERT_NOTNULL(mode.flow_field.distance_at(enemy_spawn), "Enemy spawns cannot reach the base.")

	var/mob/living/carbon/human/player = allocate(/mob/living/carbon/human, player_spawn)
	player.mind_initialize()
	var/datum/outfit/pve/outfit = allocate(/datum/outfit/pve)
	outfit.equip(player)
	var/datum/pve_account/account = mode.get_account(player)
	TEST_ASSERT_NOTNULL(account, "Equipping the PvE outfit did not register an account.")
	TEST_ASSERT_EQUAL(account.credits, 200, "Unexpected starting credits.")
	TEST_ASSERT(mode.choose_class(account, PVE_CLASS_ASSAULT), "Choosing a class failed.")
	TEST_ASSERT(istype(player.wear_suit, /obj/item/clothing/suit/armor/vest), "Assault class did not equip its vest.")
	TEST_ASSERT(!mode.choose_class(account, PVE_CLASS_MEDIC), "A class was chosen twice.")
	mode.register_player(player)
	TEST_ASSERT_EQUAL(account.credits, 200, "Registering a player twice must preserve the balance.")

	var/obj/machinery/computer/pve_shop/armory/armory
	for(var/obj/machinery/computer/pve_shop/armory/candidate as anything in SSmachines.get_by_type(/obj/machinery/computer/pve_shop/armory))
		if(candidate.z == mode.arena_z)
			armory = candidate
			break
	TEST_ASSERT_NOTNULL(armory, "PvE arena has no armory terminal.")
	player.forceMove(get_step(armory, SOUTH))
	TEST_ASSERT(armory.purchase(player, "[/datum/pve_product/weapon/mosin]"), "An affordable purchase failed.")
	TEST_ASSERT_EQUAL(account.credits, 35, "The assault weapon discount was not applied.")
	TEST_ASSERT(!armory.purchase(player, "[/datum/pve_product/weapon/sniper]"), "A class-locked product was sold to another class.")
	TEST_ASSERT(!armory.purchase(player, "[/datum/pve_product/armor/heavy]"), "An unaffordable purchase succeeded.")
	TEST_ASSERT(!armory.purchase(player, "[/datum/pve_product/medicine/firstaid]"), "The armory sold a medbay product.")
	TEST_ASSERT_EQUAL(account.credits, 35, "A failed purchase changed the balance.")
	player.forceMove(player_spawn)
	TEST_ASSERT(!armory.purchase(player, "[/datum/pve_product/ammo/pistol]"), "A remote purchase succeeded.")

	var/obj/machinery/computer/pve_shop/command/command
	for(var/obj/machinery/computer/pve_shop/command/candidate as anything in SSmachines.get_by_type(/obj/machinery/computer/pve_shop/command))
		if(candidate.z == mode.arena_z)
			command = candidate
			break
	TEST_ASSERT_NOTNULL(command, "PvE arena has no command terminal.")
	player.forceMove(get_step(command, SOUTH))
	account.credits = 1000
	var/base_max_health = player.maxHealth
	TEST_ASSERT(command.purchase(player, "[/datum/pve_product/upgrade/toughness]"), "Buying an upgrade failed.")
	TEST_ASSERT_EQUAL(account.upgrade_level(PVE_UPGRADE_TOUGHNESS), 1, "The upgrade level was not recorded.")
	TEST_ASSERT_EQUAL(player.maxHealth, base_max_health + 15, "The toughness upgrade did not raise max health.")
	TEST_ASSERT(command.purchase(player, "[/datum/pve_product/upgrade/sprint]"), "Buying the sprint upgrade failed.")
	TEST_ASSERT(!command.purchase(player, "[/datum/pve_product/upgrade/sprint]"), "An upgrade was bought past its max level.")
	account.credits = 35
	player.forceMove(player_spawn)

	mode.started = TRUE
	mode.next_wave_time = world.time + 1 MINUTES
	mode.process()
	TEST_ASSERT_EQUAL(mode.wave, 0, "A wave started before preparation ended.")
	mode.next_wave_time = world.time
	mode.process()
	TEST_ASSERT_EQUAL(mode.wave, 1, "The first wave did not start.")
	TEST_ASSERT(mode.wave_active, "The first wave did not activate.")
	TEST_ASSERT(length(mode.spawn_queue), "The first wave has no enemies.")
	mode.process()
	TEST_ASSERT(length(mode.active_enemies), "No enemies spawned during the wave.")
	var/mob/living/simple_animal/hostile/pve/enemy = mode.active_enemies[1]
	TEST_ASSERT(enemy.CanAttack(player), "Enemies cannot attack defenders.")
	TEST_ASSERT(mode.core in enemy.ListTargets(), "Enemies cannot see the beacon.")
	var/turf/next_turf = mode.flow_field.next_step(enemy)
	TEST_ASSERT_NOTNULL(next_turf, "The flow field gives enemies no route.")
	TEST_ASSERT(mode.flow_field.distance_at(next_turf) < mode.flow_field.distance_at(get_turf(enemy)), "The flow field leads enemies away from defenders.")

	enemy.note_attacker(player)
	var/expected_credits = account.credits + enemy.bounty
	enemy.death()
	TEST_ASSERT_EQUAL(account.kills, 1, "A kill was not attributed.")
	TEST_ASSERT_EQUAL(account.credits, expected_credits, "A kill bounty was not paid.")

	mode.spawn_queue.Cut()
	for(var/mob/living/remaining_enemy as anything in mode.active_enemies.Copy())
		qdel(remaining_enemy)
	var/datum/pve_contract/flawless = new /datum/pve_contract/flawless
	mode.contract = flawless
	player.death()
	TEST_ASSERT_EQUAL(account.deaths, 1, "A defender death was not counted.")
	TEST_ASSERT(flawless.failed, "A defender death did not fail the flawless contract.")
	expected_credits = account.credits + round((60 + 15) / 2)
	mode.complete_wave()
	TEST_ASSERT(!mode.wave_active, "Preparation did not resume after clearing the wave.")
	TEST_ASSERT_NULL(mode.contract, "The wave contract was not cleared.")
	TEST_ASSERT_EQUAL(account.credits, expected_credits, "A fallen defender did not get half of the wave reward.")
	TEST_ASSERT(player.stat != DEAD, "A fallen defender was not revived after the wave.")
	TEST_ASSERT(get_turf(player) in mode.player_spawns, "A revived defender was not returned to the base.")
	TEST_ASSERT_EQUAL(player.maxHealth, base_max_health + 15, "The toughness upgrade was lost on revival.")

	var/datum/pve_contract/beacon/beacon_contract = allocate(/datum/pve_contract/beacon)
	beacon_contract.start(mode)
	beacon_contract.on_core_damage(mode, 10)
	TEST_ASSERT(beacon_contract.is_complete(mode), "Light beacon damage failed the beacon contract.")
	beacon_contract.on_core_damage(mode, mode.core.max_integrity)
	TEST_ASSERT(!beacon_contract.is_complete(mode), "Heavy beacon damage did not fail the beacon contract.")

	mode.wave = 4
	mode.start_wave(1)
	TEST_ASSERT_EQUAL(mode.boss_type, /mob/living/simple_animal/hostile/pve/boss/broodmother, "The fifth wave has no boss.")
	mode.spawn_boss(1)
	TEST_ASSERT(istype(mode.active_boss, /mob/living/simple_animal/hostile/pve/boss/broodmother), "The boss did not spawn.")

	var/enemies_before = length(mode.active_enemies)
	var/mob/living/simple_animal/hostile/pve/carrier/carrier = mode.spawn_enemy(/mob/living/simple_animal/hostile/pve/carrier)
	carrier.death()
	TEST_ASSERT_EQUAL(length(mode.active_enemies), enemies_before + 3, "A dead carrier did not release its swarm.")
	mode.spawn_treasure()
	var/mob/living/simple_animal/hostile/pve/treasure/wisp = locate() in mode.active_enemies
	TEST_ASSERT_NOTNULL(wisp, "The treasure wisp did not spawn.")
	wisp.escape()
	TEST_ASSERT(!(wisp in mode.active_enemies), "An escaped treasure wisp stayed in the wave.")

	var/obj/machinery/porta_turret/syndicate/pve/turret = allocate(/obj/machinery/porta_turret/syndicate/pve, get_step(player, EAST))
	mode.active_boss.forceMove(get_step(turret, EAST))
	TEST_ASSERT_EQUAL(turret.assess_living(player), TURRET_NOT_TARGET, "Turrets target defenders.")
	TEST_ASSERT_EQUAL(turret.assess_living(mode.active_boss), TURRET_PRIORITY_TARGET, "Turrets ignore wave enemies.")
	var/obj/projectile/bullet/pve_turret/bullet = allocate(/obj/projectile/bullet/pve_turret, get_turf(turret))
	var/previous_damage = player.getBruteLoss()
	bullet.prehit(player)
	player.bullet_act(bullet)
	TEST_ASSERT_EQUAL(player.getBruteLoss(), previous_damage, "Turret bullets hurt a defender.")
	bullet.prehit(mode.active_boss)
	TEST_ASSERT(!bullet.nodamage, "A turret bullet stayed harmless after passing a defender.")

	var/obj/item/flamethrower/full/tank/pve/flamer = allocate(/obj/item/flamethrower/full/tank/pve, get_turf(player))
	var/fuel = flamer.ptank.air_contents.toxins()
	var/boss_health = mode.active_boss.health
	var/player_health = player.health
	flamer.default_ignite(get_turf(mode.active_boss))
	flamer.default_ignite(get_turf(player))
	TEST_ASSERT(mode.active_boss.health < boss_health, "The flamethrower did not burn an enemy.")
	TEST_ASSERT(mode.active_boss.has_status_effect(/datum/status_effect/pve_burning), "The flamethrower did not ignite an enemy.")
	TEST_ASSERT_EQUAL(player.health, player_health, "The flamethrower burned a defender.")
	TEST_ASSERT(flamer.ptank.air_contents.toxins() < fuel, "The flamethrower used no fuel.")

	player.death()
	mode.process()
	TEST_ASSERT(mode.finished, "PvE did not end after all defenders died.")
	TEST_ASSERT(!mode.victory, "A wipe was counted as a victory.")

/datum/unit_test/pve_survival/Destroy()
	mode.started = FALSE
	SSticker.mode = previous_mode
	SSticker.force_ending = previous_force_ending
	previous_mode = null
	mode = null
	return ..()
