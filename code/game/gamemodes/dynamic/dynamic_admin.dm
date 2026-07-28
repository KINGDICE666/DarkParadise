ADMIN_VERB(dynamic_panel, R_ADMIN, "Dynamic Panel", "Inspect and steer the dynamic game mode.", ADMIN_CATEGORY_GAME)
	if(!user.holder)
		return

	user.holder.dynamic_panel()

/datum/admins/proc/dynamic_panel()
	var/datum/game_mode/dynamic/mode = SSticker.mode
	if(!istype(mode))
		to_chat(usr, span_warning("Текущий режим игры — не динамический."))
		return

	var/list/dat = list("<body><h1><b>Dynamic</b></h1>")
	if(mode.current_tier)
		dat += "Тир: <b>[mode.current_tier.name]</b><br>"
		dat += "Осталось правил: мидраунд <b>[mode.rulesets_to_spawn[DYNAMIC_MIDROUND]]</b>, латеджойн <b>[mode.rulesets_to_spawn[DYNAMIC_LATEJOIN]]</b><br>"
	else
		dat += "Тир ещё не выбран.<br>"
		dat += "<a href='byond://?src=[UID()];dynamic_force_tier=1'>Форсировать тир</a><br>"

	dat += "<br><a href='byond://?src=[UID()];dynamic_force_midround=1'>Запустить мидраунд-правило</a><br>"
	dat += "<a href='byond://?src=[UID()];dynamic_toggle_ruleset=1'>Включить/выключить правило</a><br>"

	dat += "<br><b>Отработавшие правила</b><br><table cellspacing=5>"
	for(var/datum/dynamic_ruleset/ruleset as anything in mode.executed_rulesets)
		dat += "<tr><td>[ruleset.config_tag]</td><td>[length(ruleset.selected_minds)] игрок[DECL_CREDIT(length(ruleset.selected_minds))]</td></tr>"
	dat += "</table>"

	if(length(mode.admin_disabled_rulesets))
		dat += "<br><b>Выключенные правила</b><br>"
		for(var/datum/dynamic_ruleset/ruleset_type as anything in mode.admin_disabled_rulesets)
			dat += "[ruleset_type::config_tag]<br>"

	dat += "</body>"
	var/datum/browser/popup = new(usr, "dynamicpanel", "<div align='center'>Dynamic</div>", 500, 600)
	popup.set_content(dat.Join())
	popup.open()

/datum/admins/proc/dynamic_force_tier()
	var/datum/game_mode/dynamic/mode = SSticker.mode
	if(mode.current_tier)
		to_chat(usr, span_warning("Тир уже выбран."))
		return

	var/list/tier_choices = list()
	for(var/datum/dynamic_tier/tier_type as anything in subtypesof(/datum/dynamic_tier))
		tier_choices[tier_type::name] = tier_type

	var/chosen = tgui_input_list(usr, "Какой тир форсировать?", "Dynamic", tier_choices)
	if(!chosen)
		return

	mode.forced_tier_type = tier_choices[chosen]
	log_and_message_admins("has forced the dynamic tier to [chosen]")

/datum/admins/proc/dynamic_force_midround()
	var/datum/game_mode/dynamic/mode = SSticker.mode
	if(!mode.current_tier)
		to_chat(usr, span_warning("Раунд ещё не начался."))
		return

	mode.rulesets_to_spawn[DYNAMIC_MIDROUND]++
	log_and_message_admins("has forced a dynamic midround ruleset")
	mode.try_spawn_midround()

/datum/admins/proc/dynamic_toggle_ruleset()
	var/datum/game_mode/dynamic/mode = SSticker.mode
	var/list/ruleset_choices = list()
	for(var/datum/dynamic_ruleset/ruleset_type as anything in subtypesof(/datum/dynamic_ruleset))
		if(!ruleset_type::config_tag)
			continue
		ruleset_choices[ruleset_type::config_tag] = ruleset_type

	var/chosen = tgui_input_list(usr, "Какое правило переключить?", "Dynamic", ruleset_choices)
	if(!chosen)
		return

	var/ruleset_type = ruleset_choices[chosen]
	if(ruleset_type in mode.admin_disabled_rulesets)
		mode.admin_disabled_rulesets -= ruleset_type
		log_and_message_admins("has re-enabled the dynamic ruleset [chosen]")
		return

	mode.admin_disabled_rulesets += ruleset_type
	log_and_message_admins("has disabled the dynamic ruleset [chosen]")
