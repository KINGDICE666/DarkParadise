GLOBAL_LIST_EMPTY(all_clockers)

/proc/is_convertable_to_clocker(datum/mind/mind)
	if(!mind)
		return FALSE
	if(!mind.current)
		return FALSE
	if(iscultist(mind.current))
		return FALSE // Damn Narsie and his servants
	if(isclocker(mind.current))
		return TRUE //If they're already in the cult, assume they are convertable
	if(mind.isholy)
		return FALSE
	if(ishuman(mind.current))
		var/mob/living/carbon/human/H = mind.current
		if(ismindshielded(H)) //mindshield protects against conversions unless removed
			return FALSE
	if(mind.offstation_role)
		return FALSE
	if(issilicon(mind.current))
		return FALSE //Can't be converted by platform. Have to use a clock slab as an emag.
	if(isalien(mind.current))
		return FALSE
	if(isguardian(mind.current))
		var/mob/living/simple_animal/hostile/guardian/G = mind.current
		if(!isclocker(G.summoner))
			return FALSE //can't convert it unless the owner is converted
	return TRUE

/proc/adjust_clockwork_power(amount)
	GLOB.clockwork_power += amount
	SSticker.mode.check_power_reveal()
	SSticker.mode.clocker_objs.power_check()

/datum/game_mode/clockwork
	name = "Clockwork Cult"
	config_tag = "clockwork"
	restricted_jobs = list(JOB_TITLE_CHAPLAIN, JOB_TITLE_AI, JOB_TITLE_CYBORG, JOB_TITLE_LAWYER, JOB_TITLE_OFFICER, JOB_TITLE_WARDEN, JOB_TITLE_DETECTIVE, JOB_TITLE_PILOT, JOB_TITLE_HOS, JOB_TITLE_CAPTAIN, JOB_TITLE_HOP, JOB_TITLE_BLUESHIELD, JOB_TITLE_REPRESENTATIVE, JOB_TITLE_MAGISTRATE, JOB_TITLE_BRIGDOC, JOB_TITLE_CCOFFICER, JOB_TITLE_CCFIELD, JOB_TITLE_CCSPECOPS, JOB_TITLE_CCCAPTAIN, JOB_TITLE_SYNDICATE_OFFICER, JOB_TITLE_PRISONER, JOB_TITLE_CMO, JOB_TITLE_RD, JOB_TITLE_QUARTERMASTER, JOB_TITLE_HOP, JOB_TITLE_CHIEF_ENGINEER)
	protected_jobs = list()
	required_players = 30
	required_enemies = 3
	recommended_enemies = 4

	var/static/max_clockers_to_start = 4

/datum/game_mode/clockwork/announce()
	to_chat(world, "<b>The current game mode is - Clockwork Cult!</b>")
	to_chat(world, "<b>Some crewmembers are attempting to start a clockwork cult!<br>\nClockers - complete your objectives. Convert crewmembers to your cause by using the credence structure. Remember - there is no you, there is only the cult.<br>\nPersonnel - Do not let the cult succeed in its mission. Brainwashing them with holy water reverts them to whatever CentComm-allowed faith they had.</b>")

/datum/game_mode/clockwork/pre_setup()
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs

	max_clockers_to_start += floor((num_players() - required_players) / RATVAR_PLAYER_PER_CULTIST)
	var/list/clockers_possible = get_players_for_role(ROLE_CLOCKER)
	for(var/clockers_number in 1 to max_clockers_to_start)
		if(!length(clockers_possible))
			break
		var/datum/mind/clocker = pick(clockers_possible)
		clockers_possible -= clocker
		clockwork_cult += clocker
		clocker.restricted_roles = restricted_jobs
	return (length(clockwork_cult) > 0)

/datum/game_mode/clockwork/post_setup()
	clocker_objs.setup()

	for(var/datum/mind/clockwork_mind in clockwork_cult.Copy())
		clockwork_mind.add_antag_datum(/datum/antagonist/clockwork)
		equip_clocker(clockwork_mind.current)
		clocker_objs.study(clockwork_mind.current)
	clockwork_threshold_check()
	addtimer(CALLBACK(src, PROC_REF(clockwork_threshold_check)), 2 MINUTES) // Check again in 2 minutes for latejoiners
	. = ..()

/**
 * Decides at the start of the round how many conversions are needed to reveal or how many power supplied to reveal.
 *
 * The number is decided by (Percentage * (Players - clockers)), so for example at 110 players it would be 16 conversions for rise. (0.15 * (110 - 4))
 * These values change based on population because 20 clockers are MUCH more powerful if there's only 50 players, compared to 120.
 *
 * Below 100 players, [CLOCK_POWER_REVEAL_LOW] and [CLOCK_CREW_REVEAL_LOW] are used.
 * Above 100 players, [CLOCK_POWER_REVEAL_HIGH] and [CLOCK_CREW_REVEAL_HIGH] are used.
 */
/datum/game_mode/proc/clockwork_threshold_check()
	var/players = length(GLOB.player_list)
	var/clockers = get_clockers()
	if(players >= CLOCK_POPULATION_THRESHOLD)
		// Highpop
		reveal_percent = CLOCK_CREW_REVEAL_HIGH
		clocker_objs.power_goal = CLOCK_BASIC_POWER_GOAL + length(GLOB.player_list) * CLOCK_POWER_PER_CREW_HIGH
		power_reveal_number = round(clocker_objs.power_goal * 0.67) // 2/3 of power goal
		crew_reveal_number = round(CLOCK_CREW_REVEAL_HIGH * (players - clockers), 1)
	else
		// Lowpop
		reveal_percent = CLOCK_CREW_REVEAL_LOW
		clocker_objs.power_goal = CLOCK_BASIC_POWER_GOAL + length(GLOB.player_list) * CLOCK_POWER_PER_CREW_LOW
		power_reveal_number = round(clocker_objs.power_goal * 0.67) // 2/3 of power goal
		crew_reveal_number = round(CLOCK_CREW_REVEAL_LOW * (players - clockers), 1)
	add_game_logs("Clockwork Cult power/crew reveal numbers: [power_reveal_number]/[clocker_objs.clocker_goal].")

/**
 * Returns the current number of clockers and constructs.
 *
 * Returns the number of clockers and constructs in a list ([1] = Clockers, [2] = Constructs), or as one combined number.
 *
 * * separate - Should the number be returned in two separate values (Humans and Constructs) or as one?
 */
/datum/game_mode/proc/get_clockers(separate = FALSE)
	var/clockers = 0
	var/constructs = 0
	for(var/I in clockwork_cult)
		var/datum/mind/mind = I
		if(ishuman(mind.current) && !mind.madeby_sentience_potion)
			clockers++
		else if(ismarauder(mind.current) && isclocker(mind.current))
			constructs++
	if(separate)
		return list(clockers, constructs)
	else
		return clockers + constructs

/datum/game_mode/proc/equip_clocker(mob/living/carbon/human/H, metal = TRUE)
	if(!istype(H))
		return
	. += clock_give_item(/obj/item/clockwork/clockslab, H)
	if(metal)
		. += clock_give_item(/obj/item/stack/sheet/brass/ten, H)
	to_chat(H, span_clock("These will help you start the cult on this station. Use them well, and remember - you are not the only one."))

/datum/game_mode/proc/clock_give_item(obj/item/item_path, mob/living/carbon/human/H)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_POCKET_LEFT,
		"right pocket" = ITEM_SLOT_POCKET_RIGHT)
	var/T = new item_path(H)
	var/item_name = initial(item_path.name)
	var/where = H.equip_in_one_of_slots(T, slots, qdel_on_fail = TRUE)
	if(!where)
		to_chat(H, span_userdanger("Unfortunately, you weren't able to get a [item_name]. This is very bad and you should adminhelp immediately (press F1)."))
		return FALSE
	else
		to_chat(H, span_danger("You have a [item_name] in your [where]."))
		return TRUE

/datum/game_mode/proc/add_clocker(datum/mind/clock_mind)
	if(!istype(clock_mind))
		return FALSE

	if(!reveal_percent) // If the rise/ascend thresholds haven't been set (non-cult rounds)
		clocker_objs.setup()
		clockwork_threshold_check()

	if(!clock_mind.add_antag_datum(/datum/antagonist/clockwork))
		return FALSE

	add_conversion_logs(clock_mind.current, "converted to the clockwork cult")
	if(!clocker_objs.clock_status && ishuman(clock_mind.current))
		clocker_objs.setup()

	adjust_clockwork_power(CLOCK_POWER_CONVERT)
	check_clock_reveal()
	if(!clocker_objs.obj_demand.clockers_get)
		clocker_objs.clockers_check()
	clocker_objs.study(clock_mind.current)
	return TRUE

/datum/game_mode/proc/check_power_reveal()
	if(power_reveal)
		return
	if((GLOB.clockwork_power >= power_reveal_number) && !power_reveal)
		power_reveal = TRUE
		for(var/datum/mind/M in clockwork_cult)
			if(!M.current)
				continue
			if(!ishuman(M.current))
				powered_borgs(M.current)
				continue
			SEND_SOUND(M.current, sound('sound/hallucinations/i_see_you2.ogg'))
			to_chat(M.current, span_clocklarge("The veil begins to stutter in fear as the power of Ratvar grows, your hands begin to glow..."))
			addtimer(CALLBACK(src, PROC_REF(powered), M.current), 20 SECONDS)

/datum/game_mode/proc/check_clock_reveal()
	if(crew_reveal)
		return
	var/clocker_players = get_clockers()
	if(clocker_players < crew_reveal_number && GLOB.heart.curse_dial)
		return
	for(var/datum/mind/M in clockwork_cult)
		if(!M.current)
			continue
		SEND_SOUND(M.current, sound('sound/hallucinations/im_here1.ogg'))
		if(!ishuman(M.current))
			continue
		to_chat(M.current, span_clocklarge("Your cult gets bigger as the clocked harvest approaches - you cannot hide your true nature for much longer!"))
		addtimer(CALLBACK(src, PROC_REF(clocked), M.current), 20 SECONDS)
	GLOB.major_announcement.announce("На вашей станции обнаружена внепространственная активность, связанная с Заводным культом Ратвара. Данные свидетельствуют о том, что в ряды культа обращено около [reveal_percent * 100]% экипажа станции. Служба безопасности получает право свободно применять летальную силу против культистов. Прочий персонал должен быть готов защищать себя и свои рабочие места от нападений культистов (в том числе используя летальную силу в качестве крайней меры самообороны), но не должен выслеживать культистов и охотиться на них. Погибшие члены экипажа должны быть оживлены и деконвертированы, как только ситуация будет взята под контроль.",
										ANNOUNCE_CCPARANORMAL_RU,
										SSstation.announcer.get_rand_report_sound()
		)
	log_game("Clockwork cult reveal. Powergame allowed.")
	crew_reveal = TRUE

/datum/game_mode/proc/powered(clocker)
	if(ishuman(clocker) && isclocker(clocker))
		var/mob/living/carbon/human/H = clocker

		ADD_TRAIT(H, TRAIT_CLOCK_HANDS, CLOCK_TRAIT)
		H.update_worn_gloves()

/datum/game_mode/proc/powered_borgs(clocker)
	if(isrobot(clocker))
		var/mob/living/silicon/robot/borg = clocker
		borg.update_icons()

/datum/game_mode/proc/clocked(clocker)
	if(ishuman(clocker) && isclocker(clocker))
		var/mob/living/carbon/human/H = clocker
		new /obj/effect/temp_visual/ratvar/sparks(get_turf(H), H.dir)
		SEND_SIGNAL(H, COMSIG_MOB_HALO_GAINED)

/datum/game_mode/proc/remove_clocker(datum/mind/clock_mind, show_message = TRUE)
	var/datum/antagonist/clockwork/clocker = clock_mind?.has_antag_datum(/datum/antagonist/clockwork)
	if(!clocker || !clock_mind.current)
		return

	clocker.silent = !show_message
	clock_mind.remove_antag_datum(/datum/antagonist/clockwork)
	add_conversion_logs(clock_mind.current, "deconverted from the clockwork cult.")

/datum/game_mode/clockwork/declare_completion()
	if(clocker_objs.clock_status == RATVAR_HAS_RISEN)
		SSticker.mode_result = "clockwork cult win - cult win"
	else if(clocker_objs.clock_status == RATVAR_HAS_FALLEN)
		SSticker.mode_result = "clockwork cult draw - ratvar died, nobody wins"
	else
		SSticker.mode_result = "clockwork cult loss - staff stopped the cult"

	var/list/endtext = list()
	endtext += "<br><b>The clockers' objectives were:</b>"
	endtext += "<br>[clocker_objs.obj_demand.explanation_text] - "
	if(!clocker_objs.obj_demand.check_completion())
		endtext += "<font color='red'>Fail.</font>"
	else
		endtext += "<font color='green'><b>Success!</b></font>"

	if(clocker_objs.clock_status >= RATVAR_NEEDS_SUMMONING)
		endtext += "<br>[clocker_objs.obj_summon.explanation_text] - "
		if(!clocker_objs.obj_summon.check_completion())
			endtext+= "<font color='red'>Fail.</font>"
		else
			endtext += "<font color='green'><b>Success!</b></font>"

	to_chat(world, endtext.Join(""))
	. = ..()

/proc/isclocker(mob/living/user)
	return istype(user) && user.mind && SSticker?.mode && (user.mind in SSticker.mode.clockwork_cult)

/proc/isclocker_ascended(mob/living/user)
	return isclocker(user) && SSticker.mode.crew_reveal
