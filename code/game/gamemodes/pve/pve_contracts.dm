#define PVE_CONTRACT_BEACON_LOSS 0.05
#define PVE_CONTRACT_BLITZ_BASE (50 SECONDS)
#define PVE_CONTRACT_BLITZ_PER_ENEMY (2 SECONDS)
#define PVE_CONTRACT_MELEE_BASE 6

/datum/pve_contract
	abstract_type = /datum/pve_contract
	var/title
	var/description
	var/failed = FALSE
	var/min_wave = 2

/datum/pve_contract/proc/start(datum/game_mode/pve/mode)
	return

/datum/pve_contract/proc/status_text()
	return title

/datum/pve_contract/proc/fail(datum/game_mode/pve/mode)
	if(failed)
		return
	failed = TRUE
	mode.broadcast(span_warning("Контракт «[title]» провален."))

/datum/pve_contract/proc/on_kill(datum/game_mode/pve/mode, mob/living/simple_animal/hostile/pve/enemy)
	return

/datum/pve_contract/proc/on_defender_death(datum/game_mode/pve/mode)
	return

/datum/pve_contract/proc/on_core_damage(datum/game_mode/pve/mode, amount)
	return

/datum/pve_contract/proc/check_tick(datum/game_mode/pve/mode)
	return

/datum/pve_contract/proc/is_complete(datum/game_mode/pve/mode)
	return !failed

/datum/pve_contract/flawless
	title = "Без потерь"
	description = "ни один защитник не должен пасть до конца волны."

/datum/pve_contract/flawless/status_text()
	return failed ? "[title]: провален" : title

/datum/pve_contract/flawless/on_defender_death(datum/game_mode/pve/mode)
	fail(mode)

/datum/pve_contract/beacon
	title = "Несокрушимый Маяк"
	description = "Маяк должен потерять не больше 5% прочности."
	var/damage_taken = 0
	var/allowed_damage = 0

/datum/pve_contract/beacon/start(datum/game_mode/pve/mode)
	allowed_damage = mode.core ? mode.core.max_integrity * PVE_CONTRACT_BEACON_LOSS : 0

/datum/pve_contract/beacon/status_text()
	if(failed)
		return "[title]: провален"
	return "[title]: [round(damage_taken)]/[round(allowed_damage)] урона"

/datum/pve_contract/beacon/on_core_damage(datum/game_mode/pve/mode, amount)
	damage_taken += amount
	if(damage_taken > allowed_damage)
		fail(mode)

/datum/pve_contract/blitz
	title = "Блиц"
	description = "очистить поле от тварей, пока не истекло время."
	min_wave = 3
	var/deadline = 0

/datum/pve_contract/blitz/start(datum/game_mode/pve/mode)
	deadline = world.time + PVE_CONTRACT_BLITZ_BASE + length(mode.spawn_queue) * PVE_CONTRACT_BLITZ_PER_ENEMY
	if(mode.boss_type)
		deadline += PVE_CONTRACT_BLITZ_BASE

/datum/pve_contract/blitz/status_text()
	if(failed)
		return "[title]: провален"
	return "[title]: [max(0, round((deadline - world.time) / (1 SECONDS)))] с"

/datum/pve_contract/blitz/check_tick(datum/game_mode/pve/mode)
	if(world.time > deadline)
		fail(mode)

/datum/pve_contract/melee
	title = "Рукопашная"
	description = "добить в ближнем бою достаточно тварей."
	var/required = 0
	var/kills = 0

/datum/pve_contract/melee/start(datum/game_mode/pve/mode)
	required = PVE_CONTRACT_MELEE_BASE + mode.wave

/datum/pve_contract/melee/status_text()
	return "[title]: [min(kills, required)]/[required]"

/datum/pve_contract/melee/on_kill(datum/game_mode/pve/mode, mob/living/simple_animal/hostile/pve/enemy)
	if(enemy.last_hit_melee)
		kills++

/datum/pve_contract/melee/is_complete(datum/game_mode/pve/mode)
	return kills >= required

/datum/pve_contract/perimeter
	title = "Периметр"
	description = "ни одна тварь не должна ворваться в здания лагеря."

/datum/pve_contract/perimeter/status_text()
	return failed ? "[title]: прорван" : title

/datum/pve_contract/perimeter/check_tick(datum/game_mode/pve/mode)
	if(failed)
		return
	for(var/mob/living/simple_animal/hostile/pve/enemy as anything in mode.active_enemies)
		if(enemy.stat != DEAD && istype(get_area(enemy), /area/pve/base))
			fail(mode)
			return

#undef PVE_CONTRACT_BEACON_LOSS
#undef PVE_CONTRACT_BLITZ_BASE
#undef PVE_CONTRACT_BLITZ_PER_ENEMY
#undef PVE_CONTRACT_MELEE_BASE
