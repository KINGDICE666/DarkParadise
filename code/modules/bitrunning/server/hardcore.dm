/obj/machinery/quantum_server/proc/enable_hardcore()
	if(hardcore || isnull(generated_domain) || domain_entered || domain_complete || length(avatar_connection_refs))
		return FALSE

	if(generated_domain.difficulty == BITRUNNER_DIFFICULTY_NONE)
		return FALSE

	hardcore = TRUE
	var/list/mob/living/simple_animal/hostile/enemies = list()
	for(var/turf/tile as anything in domain_reservation.reserved_turfs)
		for(var/mob/living/simple_animal/hostile/enemy in tile)
			if(enemy.stat == DEAD || enemy.GetComponent(/datum/component/avatar_connection))
				continue
			enemies += enemy

	for(var/mob/living/simple_animal/hostile/enemy as anything in enemies)
		if(ismegafauna(enemy))
			var/mob/living/simple_animal/hostile/megafauna/boss = enemy
			var/max_health = boss.maxHealth
			var/health = boss.health
			boss.enrage()
			boss.maxHealth = max_health
			boss.health = health
			empower_hardcore_mob(boss)
			continue

		var/list/turf/reinforcement_turfs = list()
		for(var/turf/tile as anything in get_adjacent_open_turfs(enemy))
			var/area/destination = get_area(tile)
			if((tile in domain_reservation.reserved_turfs) && !(destination.area_flags & VIRTUAL_SAFE_AREA) && !tile.is_blocked_turf())
				reinforcement_turfs += tile

		if(length(reinforcement_turfs))
			var/mob/living/simple_animal/hostile/reinforcement = new enemy.type(pick(reinforcement_turfs))
			reinforcement.faction = enemy.faction.Copy()
			mutation_candidate_refs |= WEAKREF(reinforcement)
			empower_hardcore_mob(reinforcement)

		empower_hardcore_mob(enemy)

	return TRUE

/obj/machinery/quantum_server/proc/empower_hardcore_mob(mob/living/simple_animal/hostile/enemy)
	enemy.maxHealth *= BITRUNNER_HARDCORE_HEALTH_MULTIPLIER
	enemy.health *= BITRUNNER_HARDCORE_HEALTH_MULTIPLIER
	enemy.melee_damage_lower *= BITRUNNER_HARDCORE_DAMAGE_MULTIPLIER
	enemy.melee_damage_upper *= BITRUNNER_HARDCORE_DAMAGE_MULTIPLIER

	if(enemy.ranged && !ismegafauna(enemy))
		enemy.casingtype = null
		enemy.projectiletype = /obj/projectile/beam/laser/heavylaser
		enemy.projectilesound = 'sound/weapons/laser.ogg'
		enemy.ranged_cooldown_time /= BITRUNNER_HARDCORE_DAMAGE_MULTIPLIER
