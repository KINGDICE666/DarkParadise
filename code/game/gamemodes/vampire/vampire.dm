/datum/game_mode/vampire
	name = "vampire"
	config_tag = "vampire"
	restricted_jobs = list(JOB_TITLE_AI, JOB_TITLE_CYBORG)
	protected_jobs = list(JOB_TITLE_OFFICER, JOB_TITLE_WARDEN, JOB_TITLE_DETECTIVE, JOB_TITLE_HOS, JOB_TITLE_CAPTAIN, JOB_TITLE_BLUESHIELD, JOB_TITLE_REPRESENTATIVE, JOB_TITLE_PILOT, JOB_TITLE_MAGISTRATE, JOB_TITLE_CHAPLAIN, JOB_TITLE_BRIGDOC, JOB_TITLE_CCOFFICER, JOB_TITLE_CCFIELD, JOB_TITLE_CCSPECOPS, JOB_TITLE_CCCAPTAIN, JOB_TITLE_SYNDICATE_OFFICER, JOB_TITLE_PRISONER, JOB_TITLE_CMO, JOB_TITLE_RD, JOB_TITLE_QUARTERMASTER, JOB_TITLE_HOP, JOB_TITLE_CHIEF_ENGINEER)
	protected_species = SPECIES_BLOCKED_FOR_VAMPIRE
	required_players = 15
	required_enemies = 1
	recommended_enemies = 4
	var/vampire_amount = 4

/datum/game_mode/vampire/announce()
	to_chat(world, "<b>The current game mode is - Vampires!</b>")
	to_chat(world, "<b>There are Bluespace Vampires infesting your fellow crewmates, keep your blood close and neck safe!</b>")

/datum/game_mode/vampire/pre_setup()

	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs

	var/list/datum/mind/possible_vampires = get_players_for_role(ROLE_VAMPIRE)

	var/vampire_scale = 10
	if(CONFIG_GET(number/traitor_scaling))
		vampire_scale = CONFIG_GET(number/traitor_scaling)
	vampire_amount = 1 + round(num_players() / vampire_scale)
	add_game_logs("Number of vampires chosen: [vampire_amount]")

	if(length(possible_vampires))
		for(var/i in 1 to vampire_amount)
			if(!length(possible_vampires))
				break
			var/datum/mind/vampire = pick_n_take(possible_vampires)
			pre_vampires += vampire
			vampire.special_role = SPECIAL_ROLE_VAMPIRE
			vampire.restricted_roles = restricted_jobs

		..()
		return TRUE
	else
		return FALSE

/datum/game_mode/vampire/post_setup()
	for(var/datum/mind/vampire in pre_vampires)
		vampire.add_antag_datum(/datum/antagonist/vampire/new_vampire)
	..()



