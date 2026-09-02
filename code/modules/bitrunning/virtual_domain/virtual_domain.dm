/datum/lazy_template/virtual_domain
	map_dir = "_maps/minigames/bitrunning"
	key = "Virtual Domain"
	var/name = "Virtual Domain"
	var/desc = "Пустой домен."
	var/cost = BITRUNNER_COST_NONE
	var/difficulty = BITRUNNER_DIFFICULTY_NONE
	var/reward_points = BITRUNNER_REWARD_MIN
	var/domain_flags = NONE
	var/help_text = "Найдите зашифрованный контейнер и доставьте его на площадку выдачи."
	var/start_time
	var/list/completion_loot
	var/datum/outfit/forced_outfit

/datum/lazy_template/virtual_domain/proc/can_view_name(scanner_tier, server_points)
	return difficulty < scanner_tier && cost <= server_points + 5

/datum/lazy_template/virtual_domain/proc/can_view_reward(scanner_tier, server_points)
	return difficulty < (scanner_tier + 1) && cost <= server_points + 3

/proc/get_virtual_domains()
	var/static/list/domains
	if(!isnull(domains))
		return domains

	domains = list()
	for(var/template_key in GLOB.lazy_templates)
		var/datum/lazy_template/virtual_domain/domain = GLOB.lazy_templates[template_key]
		if(!istype(domain) || domain.type == /datum/lazy_template/virtual_domain)
			continue
		if(domain.domain_flags & DOMAIN_TEST_ONLY)
			continue
		domains += domain

	return domains

/proc/get_available_domains(scanner_tier, server_points)
	var/list/entries = list()

	for(var/datum/lazy_template/virtual_domain/domain as anything in get_virtual_domains())
		var/can_view = domain.can_view_name(scanner_tier, server_points)
		entries += list(list(
			"cost" = domain.cost,
			"desc" = can_view ? domain.desc : "Сканера не хватает, чтобы разобрать содержимое домена.",
			"difficulty" = domain.difficulty,
			"id" = domain.key,
			"name" = can_view ? domain.name : DOMAIN_REDACTED,
			"reward" = domain.can_view_reward(scanner_tier, server_points) ? domain.reward_points : DOMAIN_REDACTED,
		))

	return entries
