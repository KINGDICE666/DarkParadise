// To add a rev to the list of revolutionaries, make sure it's rev (with if(ticker.mode.name == "revolution)),
// then call ticker.mode:add_revolutionary(_THE_PLAYERS_MIND_)
// nothing else needs to be done, as that proc will check if they are a valid target.
// Just make sure the converter is a head before you call it!
// To remove a rev (from brainwashing or w/e), call ticker.mode:remove_revolutionary(_THE_PLAYERS_MIND_),
// this will also check they're not a head, so it can just be called freely

/datum/game_mode/revolution
	name = "revolution"
	config_tag = "revolution"
	restricted_jobs = list(JOB_TITLE_LAWYER)
	always_protect_roles = TRUE
	required_players = 20
	required_enemies = 1
	recommended_enemies = 3

	var/list/datum/mind/pre_head_revolutionaries = list()
	var/obj/machinery/computer/communications/data_stream_console
	var/war_declared = FALSE
	var/syndicate_progress = 0
	var/nt_progress = 0
	var/last_progress_tick = 0
	var/victor

///////////////////////////
//Announces the game type//
///////////////////////////
/datum/game_mode/revolution/announce()
	to_chat(world, "<b>Текущий режим игры - <font color='red'>Революция</font>!</b>")
	to_chat(world, "<b>Мятеж на станции спонсируется и возглавляется Синдикатом. Об этом знают и сами мятежники, и служба безопасности.</b>")
	to_chat(world, "Революционеры - наберите сторонников, запустите с консоли связи передачу данных флоту Синдиката и удержите её до подхода флота.")
	to_chat(world, "Экипаж - не дайте передаче состояться. Рабов революции возвращайте имплантами защиты разума, добровольцев и главрев судите как врагов Нанотрейзен.")

///////////////////////////////////////////////////////////////////////////////
//Gets the round setup, cancelling if there's not enough players at the start//
///////////////////////////////////////////////////////////////////////////////
/datum/game_mode/revolution/pre_setup()
	var/list/possible_revolutionaries = get_players_for_role(ROLE_REV)

	for(var/i=1 to MAX_HEAD_REVOLUTIONARIES)
		if(!length(possible_revolutionaries))
			break
		var/datum/mind/lenin = pick(possible_revolutionaries)
		possible_revolutionaries -= lenin
		pre_head_revolutionaries += lenin
		lenin.restricted_roles = get_restricted_roles()

	if(length(pre_head_revolutionaries) < required_enemies)
		return FALSE

	return TRUE

/datum/game_mode/revolution/post_setup()
	var/list/heads = get_living_heads()
	var/list/sec = get_living_sec()
	var/weighted_score = min(max(round(length(heads) - ((8 - length(sec)) / 3)),1),MAX_HEAD_REVOLUTIONARIES)

	while(weighted_score < length(pre_head_revolutionaries)) //das vi danya
		var/datum/mind/trotsky = pick(pre_head_revolutionaries)
		pre_head_revolutionaries -= trotsky

	for(var/datum/mind/rev_mind in pre_head_revolutionaries)
		add_game_logs("has been selected as a head rev", rev_mind.current)
		rev_mind.add_antag_datum(/datum/antagonist/rev/head)
	..()

/datum/game_mode/revolution/process()
	var/datum/team/revolution/team = GLOB.antagonist_teams[/datum/team/revolution]
	team?.check_latejoin()
	advance_war()
	return FALSE

/datum/game_mode/revolution/proc/living_head_revolutionaries(datum/mind/excluded)
	var/datum/team/revolution/team = GLOB.antagonist_teams[/datum/team/revolution]
	if(!team)
		return 0
	. = 0
	for(var/datum/mind/leader as anything in team.get_head_revolutionaries())
		if(leader == excluded || !leader.current || leader.current.stat == DEAD)
			continue
		.++

/datum/game_mode/revolution/proc/declare_war()
	if(war_declared)
		return
	war_declared = TRUE
	last_progress_tick = world.time
	SSsecurity_level.set_level(SECURITY_CODE_GAMMA)
	for(var/datum/mind/rebel as anything in get_antag_minds(/datum/antagonist/rev))
		to_chat(rebel.current, span_userdanger("Поток данных пошёл. Прятаться больше незачем — экипаж знает, кто вы. Удержите консоль!"))
	send_to_playing_players(span_boldannounceic("ВНИМАНИЕ: с одной из консолей связи [station_name()] идёт несанкционированная передача данных флоту Синдиката. \
		Обнаружившим её приказано немедленно прервать передачу. Все причастные лишаются статуса сотрудника и подлежат немедленной ликвидации. \
		Капсулы со снаряжением сброшены на станцию."))
	launch_nanotrasen_pods()

GLOBAL_LIST_INIT(revolution_standard_pod_kits, list(
	list(/obj/item/gun/projectile/automatic/smg/wt550 = 1, /obj/item/ammo_box/magazine/wt550m9 = 3),
	list(/obj/item/gun/projectile/shotgun/riot = 1, /obj/item/ammo_box/shotgun = 2),
	list(/obj/item/gun/projectile/shotgun/winchester = 1, /obj/item/ammo_box/shotgun = 2),
	list(/obj/item/storage/backpack/duffel/security/bulletproof_armory = 1, /obj/item/storage/belt/security/sec = 1),
	list(/obj/item/storage/backpack/duffel/security/riot_armory = 1, /obj/item/storage/belt/security/sec = 1),
	list(/obj/item/mod/control/pre_equipped/security = 1),
))

GLOBAL_LIST_INIT(revolution_reinforced_pod_kits, list(
	list(/obj/item/gun/projectile/shotgun/automatic/combat = 1, /obj/item/ammo_box/speedloader/shotgun/slug = 2),
	list(/obj/item/gun/projectile/automatic/smg/sfg = 1, /obj/item/ammo_box/magazine/sfg9mm = 2),
	list(/obj/item/gun/projectile/automatic/smg/saber = 1, /obj/item/ammo_box/magazine/smgm9mm = 2),
	list(/obj/item/gun/projectile/automatic/ik60 = 1, /obj/item/ammo_box/magazine/ik60mag = 2),
	list(/obj/item/mod/control/pre_equipped/safeguard_mk_two = 1, /obj/item/gun/projectile/automatic/pistol/sp8 = 1, /obj/item/ammo_box/magazine/sp8 = 2),
))

GLOBAL_LIST_INIT(revolution_pod_blacklist, typecacheof(list(
	/area/station/command,
	/area/station/maintenance,
	/area/station/security/brig,
)))

GLOBAL_LIST_INIT(revolution_reinforced_pod_areas, typecacheof(list(
	/area/station/command/office,
	/area/station/command/bridge,
	/area/station/security/brig,
)))

/datum/game_mode/revolution/proc/launch_nanotrasen_pods()
	var/crew = length(GLOB.data_core.general)
	for(var/count in 1 to round(crew / CREW_PER_SUPPLY_POD))
		drop_supply_pod(pick_pod_turf(reinforced = FALSE), standard_pod_payload())
	for(var/count in 1 to round(crew / CREW_PER_REINFORCED_POD))
		drop_supply_pod(pick_pod_turf(reinforced = TRUE), pick(GLOB.revolution_reinforced_pod_kits) + list(/obj/item/storage/lockbox/mindshield = 1))

/datum/game_mode/revolution/proc/standard_pod_payload()
	var/list/payload = pick(GLOB.revolution_standard_pod_kits) + list(/obj/item/implanter/mindshield = 2)
	if(payload[/obj/item/mod/control/pre_equipped/security])
		var/datum/security_voucher_kit/officer/kit = pick(subtypesof(/datum/security_voucher_kit/officer))
		payload[kit.kit_box] = 1
	return payload

/datum/game_mode/revolution/proc/pick_pod_turf(reinforced)
	var/list/candidates = list()
	for(var/area/station/area as anything in GLOB.areas)
		if(!istype(area))
			continue
		if(reinforced ? !is_type_in_typecache(area, GLOB.revolution_reinforced_pod_areas) : is_type_in_typecache(area, GLOB.revolution_pod_blacklist))
			continue
		candidates += area
	while(length(candidates))
		var/area/chosen = pick_n_take(candidates)
		var/list/turfs = chosen.get_turfs_from_all_zlevels()
		shuffle_inplace(turfs)
		for(var/turf/simulated/floor/candidate_turf in turfs)
			if(is_station_level(candidate_turf.z) && !candidate_turf.density)
				return candidate_turf

/datum/game_mode/revolution/proc/drop_supply_pod(turf/landing_spot, list/payload)
	if(!landing_spot)
		return
	podspawn(list(
		"target" = landing_spot,
		"path" = /obj/structure/closet/supplypod/podspawn,
		"spawn" = payload,
	))

/datum/game_mode/revolution/proc/advance_war()
	if(!war_declared || victor)
		return
	var/elapsed = world.time - last_progress_tick
	last_progress_tick = world.time
	if(data_stream_console?.streaming_data)
		syndicate_progress += elapsed
	else
		nt_progress += elapsed

	if(syndicate_progress >= REVOLUTION_WAR_DURATION)
		declare_victor(REVOLUTION_VICTOR_SYNDICATE)
	else if(nt_progress >= REVOLUTION_WAR_DURATION)
		declare_victor(REVOLUTION_VICTOR_NT)

/datum/game_mode/revolution/proc/declare_victor(new_victor)
	if(victor)
		return
	victor = new_victor
	data_stream_console?.stop_data_stream()

	if(victor == REVOLUTION_VICTOR_SYNDICATE)
		send_to_playing_players(span_boldannounceic("Флот Синдиката вышел из блюспейса раньше сил Нанотрейзен и берёт [station_name()] под свой контроль. \
			Связь с Трурлем оборвана. Абордажные группы уже на борту."))
		spawn_on_beacons(/mob/living/simple_animal/hostile/syndicate/ranged/space)
		addtimer(CALLBACK(src, PROC_REF(finish_round)), REVOLUTION_SYNDICATE_ENDING_DELAY)
		return

	send_to_playing_players(span_boldannounceic("Флот Нанотрейзен успел занять сектор и закрыл [station_name()] от кораблей Синдиката. \
		Плацдарм потерян, революция обезглавлена. Эвакуационный шаттл вызван."))
	spawn_on_beacons(/mob/living/simple_animal/bot/ed209)
	for(var/datum/mind/rebel as anything in get_antag_minds(/datum/antagonist/rev))
		if(rebel.has_antag_datum(/datum/antagonist/rev/slave))
			continue
		var/datum/antagonist/rev/revolutionary = rebel.has_antag_datum(/datum/antagonist/rev)
		revolutionary.add_objective(/datum/objective/survive)
		to_chat(rebel.current, span_userdanger("Синдикат не придёт. Выживите любой ценой."))
	SSshuttle.emergency.canRecall = FALSE
	SSshuttle.emergency.request(null, REVOLUTION_EVAC_TIME / SSshuttle.emergencyCallTime)

/datum/game_mode/revolution/proc/spawn_on_beacons(mob_type)
	for(var/obj/item/beacon/beacon as anything in GLOB.beacons)
		var/turf/landing_spot = get_turf(beacon)
		if(!landing_spot || !is_station_level(landing_spot.z))
			continue
		for(var/count in 1 to REVOLUTION_ENDING_SPAWNS_PER_BEACON)
			new mob_type(landing_spot)

/datum/game_mode/revolution/proc/finish_round()
	SSticker.force_ending = TRUE

/datum/objective/revolution
	explanation_text = "Наберите сторонников, запустите с консоли связи поток данных для флота Синдиката и удерживайте её до подхода флота."
	needs_target = FALSE
	antag_menu_name = "Революция"

/datum/objective/revolution/check_completion()
	var/datum/game_mode/revolution/revolution = SSticker.mode
	return istype(revolution) && revolution.victor == REVOLUTION_VICTOR_SYNDICATE

/////////////////////////////////////////////////////////////////////////////////
//This are equips the rev heads with their gear, and makes the clown not clumsy//
/////////////////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/equip_revolutionary(mob/living/carbon/human/mob)
	if(!istype(mob))
		return

	var/obj/item/toy/crayon/spraycan/R = new(mob)
	var/obj/item/clothing/glasses/hud/security/chameleon/C = new(mob)
	var/obj/item/storage/box/revolution/kit = new(mob)

	var/list/slots = list (
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_POCKET_LEFT,
		"right pocket" = ITEM_SLOT_POCKET_RIGHT,
		"left hand" = ITEM_SLOT_HAND_LEFT,
		"right hand" = ITEM_SLOT_HAND_RIGHT,
	)
	var/where2 = mob.equip_in_one_of_slots(C, slots, qdel_on_fail = TRUE)
	mob.equip_in_one_of_slots(R,slots)
	mob.equip_in_one_of_slots(kit, slots)

	mob.update_icons()

	if(!where2)
		to_chat(mob, "The Syndicate were unfortunately unable to get you a chameleon security HUD.")
	else
		to_chat(mob, "The chameleon security HUD in your [where2] will help you keep track of who is mindshield-implanted, and unable to be recruited.")
		return 1

///////////////////////////////////////////////////
//Deals with converting players to the revolution//
///////////////////////////////////////////////////
/datum/game_mode/proc/add_revolutionary(datum/mind/rev_mind, rev_type = /datum/antagonist/rev/volunteer)
	if(rev_mind.has_antag_datum(/datum/antagonist/rev))
		return 0
	if(!rev_mind.add_antag_datum(rev_type))
		return 0
	add_conversion_logs(rev_mind.current, "recruited to the revolution")
	return 1
//////////////////////////////////////////////////////////////////////////////
//Deals with players being converted from the revolution (Not a rev anymore)//  // Modified to handle borged MMIs.  Accepts another var if the target is being borged at the time  -- Polymorph.
//////////////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/remove_revolutionary(datum/mind/rev_mind, beingborged)
	var/datum/antagonist/rev/rev = rev_mind.has_antag_datum(/datum/antagonist/rev)
	if(!rev)
		return
	if(!beingborged && !rev.can_be_deconverted)
		return
	var/remove_head = istype(rev, /datum/antagonist/rev/head)
	add_conversion_logs(rev_mind.current, "renounced the revolution")
	if(beingborged)
		to_chat(rev_mind.current, span_danger(span_fontsize3("The frame's firmware detects and deletes your neural reprogramming! You remember nothing[remove_head ? "." : " but the name of the one who recruited you."]")))
		message_admins("[ADMIN_LOOKUPFLW(rev_mind.current)] has been borged while being a [remove_head ? "leader" : " member"] of the revolution.")
		rev.silent = TRUE
	rev_mind.remove_antag_datum(/datum/antagonist/rev)

//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relavent information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/revolution/declare_completion()
	..()
	return TRUE
