/datum/game_mode/dynamic
	name = "dynamic"
	config_tag = "dynamic"
	required_players = 10
	required_enemies = 1
	var/datum/dynamic_tier/current_tier
	var/list/datum/dynamic_ruleset/executed_rulesets = list()
	var/list/rulesets_to_spawn = list()
	var/list/admin_disabled_rulesets = list()
	var/forced_tier_type
	COOLDOWN_DECLARE(midround_cooldown)
	COOLDOWN_DECLARE(latejoin_cooldown)

/datum/game_mode/dynamic/Destroy(force)
	QDEL_LIST(executed_rulesets)
	QDEL_NULL(current_tier)
	return ..()

/datum/game_mode/dynamic/announce()
	to_chat(world, "<b>Текущий режим игры — Динамический!</b>")
	to_chat(world, "<b>Никто не знает, что именно ждёт станцию в эту смену. Будьте готовы ко всему.</b>")
	to_chat(world, current_tier.advisory_report)

/datum/game_mode/dynamic/pre_setup()
	var/population_size = num_players()
	pick_tier(population_size)

	for(var/ruleset_type in pick_rulesets(DYNAMIC_ROUNDSTART, /datum/dynamic_ruleset/roundstart, population_size))
		var/datum/dynamic_ruleset/roundstart/ruleset = new ruleset_type
		if(!ruleset.prepare_execution(population_size))
			add_game_logs("Dynamic: [ruleset.config_tag] was picked, but did not run - [ruleset.log_data]")
			qdel(ruleset)
			continue

		executed_rulesets += ruleset
		for(var/datum/mind/selected as anything in ruleset.selected_minds)
			add_game_logs("has been selected for [ruleset.config_tag]", selected.current)

	if(!length(executed_rulesets))
		add_game_logs("Dynamic: no roundstart ruleset could be prepared.")

	return TRUE

/datum/game_mode/dynamic/post_setup()
	for(var/datum/dynamic_ruleset/ruleset as anything in executed_rulesets)
		ruleset.execute()
	COOLDOWN_START(src, midround_cooldown, current_tier.get_time_threshold(DYNAMIC_MIDROUND))
	COOLDOWN_START(src, latejoin_cooldown, current_tier.get_time_threshold(DYNAMIC_LATEJOIN))
	return ..()

/datum/game_mode/dynamic/process()
	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		return PROCESS_KILL
	if(rulesets_to_spawn[DYNAMIC_MIDROUND] <= 0 || !COOLDOWN_FINISHED(src, midround_cooldown))
		return
	COOLDOWN_START(src, midround_cooldown, current_tier.get_execution_cooldown(DYNAMIC_MIDROUND))
	try_spawn_midround()

/datum/game_mode/dynamic/latespawn(mob/player)
	if(!player.mind || rulesets_to_spawn[DYNAMIC_LATEJOIN] <= 0 || !COOLDOWN_FINISHED(src, latejoin_cooldown))
		return
	try_spawn_latejoin(player.mind)

/datum/game_mode/dynamic/proc/pick_tier(population_size)
	var/list/tier_weights = list()
	var/list/weight_overrides = CONFIG_GET(keyed_list/dynamic_tier_weights)
	for(var/datum/dynamic_tier/tier_type as anything in subtypesof(/datum/dynamic_tier))
		if(population_size < tier_type::min_pop)
			continue
		var/tier_weight = tier_type::weight
		if(tier_type::config_tag in weight_overrides)
			tier_weight = weight_overrides[tier_type::config_tag]
		if(tier_weight <= 0)
			continue
		tier_weights[tier_type] = tier_weight

	var/picked_tier = forced_tier_type || pick_weight_classic(tier_weights) || /datum/dynamic_tier/lowmedium
	current_tier = new picked_tier

	for(var/category in list(DYNAMIC_ROUNDSTART, DYNAMIC_MIDROUND, DYNAMIC_LATEJOIN))
		rulesets_to_spawn[category] = current_tier.get_ruleset_count(category, population_size)

	add_game_logs("Dynamic: tier [current_tier.name], population [population_size], rulesets \
		[rulesets_to_spawn[DYNAMIC_ROUNDSTART]]/[rulesets_to_spawn[DYNAMIC_MIDROUND]]/[rulesets_to_spawn[DYNAMIC_LATEJOIN]]")

/datum/game_mode/dynamic/proc/get_weighted_rulesets(ruleset_family, population_size)
	. = list()
	for(var/ruleset_type in subtypesof(ruleset_family))
		if(ruleset_type in admin_disabled_rulesets)
			continue
		var/datum/dynamic_ruleset/ruleset = new ruleset_type
		var/ruleset_weight = ruleset.get_weight(population_size, current_tier.tier)
		if(ruleset_weight <= 0)
			qdel(ruleset)
			continue
		.[ruleset] = ruleset_weight

/datum/game_mode/dynamic/proc/pick_rulesets(category, ruleset_family, population_size)
	var/list/weighted_rulesets = get_weighted_rulesets(ruleset_family, population_size)
	var/list/available_rulesets = weighted_rulesets.Copy()

	. = list()
	while(rulesets_to_spawn[category] > 0 && length(weighted_rulesets))
		rulesets_to_spawn[category]--
		var/datum/dynamic_ruleset/picked = pick_weight_classic(weighted_rulesets)
		. += picked.type

		if(picked.ruleset_flags & RULESET_HIGH_IMPACT)
			for(var/datum/dynamic_ruleset/other as anything in weighted_rulesets.Copy())
				if(other.ruleset_flags & RULESET_HIGH_IMPACT)
					weighted_rulesets -= other

		if(!picked.repeatable)
			weighted_rulesets -= picked
			continue

		weighted_rulesets[picked] -= picked.repeatable_weight_decrease
		if(weighted_rulesets[picked] <= 0)
			weighted_rulesets -= picked

	QDEL_LIST(available_rulesets)

/datum/game_mode/dynamic/proc/try_spawn_midround()
	var/population_size = num_station_players()
	var/list/weighted_rulesets = get_weighted_rulesets(/datum/dynamic_ruleset/midround, population_size)
	var/datum/dynamic_ruleset/midround/picked = pick_weight_classic(weighted_rulesets)
	if(!picked)
		add_game_logs("Dynamic: no midround ruleset available.")
		QDEL_LIST(weighted_rulesets)
		return

	weighted_rulesets -= picked
	QDEL_LIST(weighted_rulesets)

	if(!picked.prepare_execution(population_size))
		add_game_logs("Dynamic: midround [picked.config_tag] did not run - [picked.log_data]")
		qdel(picked)
		return

	rulesets_to_spawn[DYNAMIC_MIDROUND]--
	executed_rulesets += picked
	picked.execute()
	for(var/datum/mind/selected as anything in picked.selected_minds)
		message_admins("Dynamic: [ADMIN_LOOKUPFLW(selected.current)] has been selected for [picked.config_tag].")
		add_game_logs("has been selected for [picked.config_tag]", selected.current)

/datum/game_mode/dynamic/proc/try_spawn_latejoin(datum/mind/joiner)
	var/population_size = num_station_players()
	var/list/weighted_rulesets = get_weighted_rulesets(/datum/dynamic_ruleset/latejoin, population_size)
	while(length(weighted_rulesets))
		var/datum/dynamic_ruleset/latejoin/picked = pick_weight_classic(weighted_rulesets)
		weighted_rulesets -= picked
		if(!picked.prepare_execution(population_size, joiner))
			qdel(picked)
			continue

		rulesets_to_spawn[DYNAMIC_LATEJOIN]--
		COOLDOWN_START(src, latejoin_cooldown, current_tier.get_execution_cooldown(DYNAMIC_LATEJOIN))
		executed_rulesets += picked
		picked.execute()
		message_admins("Dynamic: [ADMIN_LOOKUPFLW(joiner.current)] has been selected for [picked.config_tag].")
		add_game_logs("has been selected for [picked.config_tag]", joiner.current)
		break

	QDEL_LIST(weighted_rulesets)
