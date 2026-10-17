/mob/new_player
	var/ready = 0
	var/spawning = 0	//Referenced when you want to delete the new_player later on in the code.
	var/totalPlayers = 0		 //Player counts for the Lobby tab
	var/totalPlayersReady = 0
	universal_speak = 1

	invisibility = INVISIBILITY_ABSTRACT
	hud_type = /datum/hud/new_player

	density = FALSE
	stat = DEAD

/mob/new_player/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE)
	if(flags & INITIALIZED)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags |= INITIALIZED
	if(length(GLOB.newplayer_start))
		forceMove(pick(GLOB.newplayer_start))
	else
		forceMove(locate(1,1,1))
	add_to_mob_list()
	return INITIALIZE_HINT_NORMAL

/mob/new_player/Destroy(force)
	if(mind)
		mind.current = null // We best null their mind as well, otherwise /every/ single new player is going to explode the server a little more going in/out of the round
	return ..()

/mob/new_player/proc/privacy_consent()
	close_window(src, "playersetup")
	var/output = GLOB.join_tos
	output += "<p><a href='byond://?src=[UID()];consent_signed=SIGNED'>Я согласен</a>"
	output += "<p><a href='byond://?src=[UID()];consent_rejected=NOTSIGNED'>Я НЕ согласен</a>"
	var/datum/browser/popup = new(src, "privacy_consent", "<div align='center'>Политика Конфидициальности</div>", 500, 400)
	popup.set_window_options("can_close=0")
	popup.set_content(output)
	popup.open(0)
	return

/mob/new_player/get_status_tab_items()
	var/list/status_tab_data = ..()
	. = status_tab_data

	if(!(SSticker && SSticker.current_state == GAME_STATE_PREGAME && check_rights(R_ADMIN, FALSE, src)))
		return .
	status_tab_data[++status_tab_data.len] = list("Список игроков:", "")
	for(var/mob/new_player/player in GLOB.player_list)
		status_tab_data[++status_tab_data.len] = list("[player.key]", player.ready ? "(Готов)" : "(Не готов)")

/mob/new_player/Topic(href, href_list[])
	if(!client)
		return FALSE

	if(href_list["consent_signed"])
		var/datum/db_query/query = SSdbcore.NewQuery("REPLACE INTO [format_table_name("privacy")] (ckey, datetime, consent) VALUES (:ckey, Now(), 1)", list(
			"ckey" = get_account_ckey()
		))
		// If the query fails we dont want them permenantly stuck on being unable to accept TOS
		query.warn_execute()
		qdel(query)
		close_window(src, "privacy_consent")
		client.tos_consent = TRUE

	if(href_list["consent_rejected"])
		client.tos_consent = FALSE
		to_chat(usr, span_warning("Прежде чем присоединиться, вы должны согласиться с политикой конфиденциальности!"))
		var/datum/db_query/query = SSdbcore.NewQuery("REPLACE INTO [format_table_name("privacy")] (ckey, datetime, consent) VALUES (:ckey, Now(), 0)", list(
			"ckey" = get_account_ckey()
		))
		// If the query fails we dont want them permenantly stuck on being unable to accept TOS
		query.warn_execute()
		qdel(query)

	if(href_list["viewpoll"])
		var/datum/poll_question/poll = locateUID(href_list["viewpoll"])
		poll_player(poll)

	if(href_list["votepollref"])
		var/datum/poll_question/poll = locateUID(href_list["votepollref"])
		vote_on_poll_handler(poll, href_list)

	if(href_list["refresh"])
		close_window(src, "playersetup")		//closes the player setup window

/mob/new_player/proc/check_join_access()
	if(!client.tos_consent)
		to_chat(src, span_warning("Прежде чем присоединиться, вы должны согласиться с политикой конфиденциальности!"))
		privacy_consent()
		return FALSE
	if(client.version_blocked)
		client.show_update_notice()
		return FALSE
	if(client.needs_discord_link())
		client.prefs.load_preferences(client)
		if(client.needs_discord_link())
			to_chat(src, span_danger("Вам необходимо привязать ваш профиль в Discord к аккаунту!"))
			to_chat(src, span_warning("Нажмите на кнопку \"Привязка Discord\" во вкладке \"Special Verbs\", чтобы получить необходимые инструкции."))
			return FALSE
	if(client.blocked_by_launcher_link())
		return FALSE
	return TRUE

/mob/new_player/proc/check_character_access()
	if(!is_used_species_available(client.prefs.read_preference(/datum/preference/choiced/species)))
		to_chat(src, span_warning("Вы не можете играть за выбранную расу персонажа, так как она в данный момент недоступна для вас! Пожалуйста, выберите другую расу."))
		return FALSE
	if(!CONFIG_GET(flag/tts_enabled))
		return TRUE
	var/tts_seed = client.prefs.read_preference(/datum/preference/tts_seed)
	if(!tts_seed)
		to_chat(src, span_danger("Пожалуйста, настройте голос вашего персонажа!"))
		client.prefs.open_window(src, PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return FALSE
	var/datum/tts_seed/seed = SStts.tts_seeds[tts_seed]
	if(client.donator_level < seed.donator_level)
		to_chat(src, span_danger("К сожалению, выбранный вами голос персонажа больше не доступен на вашем текущем уровне подписки."))
		client.prefs.open_window(src, PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return FALSE
	return TRUE

/mob/new_player/proc/toggle_ready()
	if(ready)
		ready = FALSE
		return TRUE
	if(!check_join_access())
		return FALSE
	if(client.launcher_state == LAUNCHER_PENDING)
		to_chat(src, span_warning("Вход через лаунчер ещё подтверждается, подождите пару секунд."))
		return FALSE
	if(!check_character_access())
		return FALSE
	ready = TRUE
	return TRUE

/mob/new_player/proc/try_late_join()
	if(!check_join_access())
		return
	if(SSticker?.current_state != GAME_STATE_PLAYING)
		to_chat(src, span_warning("Раунд либо ещё не готов, либо в данный момент уже завершён..."))
		return
	if(!check_character_access())
		return
	if(SSticker.mode?.late_join(src))
		return
	GLOB.latejoin_menu.ui_interact(src)

/mob/new_player/proc/late_join_as(rank)
	if(!GLOB.enter_allowed)
		to_chat(src, span_notice("Вход в игру невозможен из-за блокировки администрацией!"))
		return

	if(client.prefs.toggles2 & PREFTOGGLE_2_RANDOMSLOT)
		client.prefs.load_random_character_slot(client)

	if(!is_used_species_available(client.prefs.read_preference(/datum/preference/choiced/species)))
		to_chat(src, span_warning("Вы не можете играть за выбранную расу персонажа, так как она в данный момент недоступна для вас! Пожалуйста, выберите другую расу."))
		return

	var/char_name = client.prefs.read_preference(/datum/preference/name/real_name)
	if(!is_admin(src) && (char_name in GLOB.human_names_list))
		to_chat(src, span_danger("Уже существует персонаж с таким именем: <b>[char_name]</b>, пожалуйста, выберите другое имя."))
		return

	if(rank == JOB_TITLE_PRISONER)
		client.prefs.spawnpoint = "Permabrig"
	AttemptLateSpawn(rank, client.prefs.spawnpoint)

/mob/new_player/proc/make_me_an_observer()
	if(!check_join_access())
		return FALSE
	if(!SSticker || SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(src, span_warning("Пожалуйста, подождите, пока сервер полностью запустится, прежде чем присоединяться!"))
		return FALSE
	if(tgui_alert(src, "Вы уверены что хотите стать наблюдателем?[(CONFIG_GET(flag/respawn_observer) ? "" : " Вы не сможете принять участие в этом раунде в качестве члена экипажа после этого!")]", "Наблюдать", list("Да", "Нет")) != "Да")
		return FALSE
	if(!client)
		return FALSE

	var/mob/dead/observer/observer = new()
	close_window(src, "playersetup")
	spawning = 1
	client?.tgui_panel?.stop_music()

	observer.started_as_observer = 1
	close_spawn_windows()
	var/obj/O = locate(/obj/effect/landmark/observer_start)
	to_chat(src, span_notice("Телепортация."))
	observer.abstract_move(get_turf(O))
	observer.icon = client.prefs.get_preview_icon()
	observer.alpha = 127

	var/observer_name = client.prefs.read_preference(/datum/preference/name/real_name)
	if(client.prefs.read_preference(/datum/preference/choiced/random_name) == RANDOM_ENABLED)
		observer_name = random_name(client.prefs.read_preference(/datum/preference/choiced/gender), client.prefs.read_preference(/datum/preference/choiced/species))
	observer.real_name = observer_name
	observer.name = observer.real_name
	observer.possess_by_player(key)
	observer.persistent_client.time_of_death = world.time
	if(CONFIG_GET(flag/respawn_observer))
		observer.add_to_respawnable_list()			// If enabled in config - observer cant respawn as Player
	qdel(src)
	return TRUE

/mob/new_player/proc/IsJobAvailable(rank)
	return !get_job_unavailable_reason(rank)

/mob/new_player/proc/get_job_unavailable_reason(rank)
	var/datum/job/job = SSjobs.GetJob(rank)
	if(!job)
		return "Должность не найдена"
	if(!job.is_position_available())
		return "Нет свободных мест"
	if(jobban_isbanned(src, rank))
		return "Заблокировано"
	if(!job.player_old_enough(client))
		return "Аккаунт слишком новый"
	if(job.admin_only && !check_rights(R_ADMIN, FALSE))
		return "Только для администрации"
	if(job.available_in_playtime(client))
		return "Недостаточно наигранного времени"
	if(!job.can_novice_play(client))
		return "Только для новичков"
	if(CONFIG_GET(flag/assistant_limit) && job.title == JOB_TITLE_CIVILIAN)
		var/datum/job/security/officer = SSjobs.GetJob(JOB_TITLE_OFFICER)
		var/datum/job/security/warden = SSjobs.GetJob(JOB_TITLE_WARDEN)
		var/datum/job/head_of_staff/hos = SSjobs.GetJob(JOB_TITLE_HOS)
		var/security_count = officer.current_positions + warden.current_positions + hos.current_positions
		if(security_count < 5 && job.current_positions > CONFIG_GET(number/assistant_ratio) * security_count)
			return "Не хватает службы безопасности"

/mob/new_player/proc/IsAdminJob(rank)
	var/datum/job/job = SSjobs.GetJob(rank)
	if(job.admin_only)
		return 1
	else
		return 0

/mob/new_player/proc/is_used_species_available(species)
	if(has_admin_rights())
		return TRUE
	var/list/available_species = list(SPECIES_HUMAN)
	available_species += CONFIG_GET(str_list/playable_species)
	if(species in available_species)
		return TRUE
	else
		return FALSE

/mob/new_player/proc/IsERTSpawnJob(rank)
	var/datum/job/job = SSjobs.GetJob(rank)
	if(job.spawn_ert)
		return 1
	else
		return 0

/mob/new_player/proc/IsSyndicateCommand(rank)
	var/datum/job/job = SSjobs.GetJob(rank)
	if(job.syndicate_command)
		return 1
	else
		return 0

/mob/new_player/proc/random_job()
	var/jobs_available = list()
	for(var/datum/job/job in SSjobs.occupations)
		if(job && IsJobAvailable(job.title) && !job.barred_by_disability(client) && job.check_custom_requirements(client))
			jobs_available += job.title
	if(!length(jobs_available))
		return FALSE
	return pick(jobs_available)

/mob/proc/move_to_spawn(list/spawn_turfs)
	if(length(GLOB.start_override))
		forceMove(pick(GLOB.start_override))
		return

	forceMove(pick(spawn_turfs))

/mob/proc/spawn_equip(rank)
	if(GLOB.start_override_outfit)
		var/datum/outfit/outfit_override = new GLOB.start_override_outfit
		outfit_override.equip(src)
		return src

	. = SSjobs.EquipRank(src, rank, 1)
	EquipCustomItems(.)

/mob/new_player/proc/AttemptLateSpawn(rank, spawning_at)
	if(src != usr)
		return FALSE

	if(!SSticker || SSticker.current_state != GAME_STATE_PLAYING)
		to_chat(usr, span_warning("Раунд либо ещё не готов, либо уже завершился..."))
		return FALSE

	if(!GLOB.enter_allowed)
		to_chat(usr, span_notice("Администратор заблокировал вход в игру!"))
		return FALSE

	if(client.launcher_state == LAUNCHER_PENDING)
		to_chat(usr, span_warning("Вход через лаунчер ещё подтверждается, подождите пару секунд."))
		return FALSE

	if("[client.prefs.default_slot]" in persistent_client.joined_as_slots)
		tgui_alert(usr, "Вы уже играли за этого персонажа в этом раунде!")
		return FALSE

	if(rank == "RandomJob")
		rank = random_job()
		if(!rank)
			var/msg = "Нет свободных ролей. Пожалуйста, попробуйте позже."
			to_chat(src, msg)
			tgui_alert(usr, msg)
			return FALSE

	if(!IsJobAvailable(rank))
		var/msg = "Должность [rank] недоступна. Пожалуйста, попробуйте другую."
		to_chat(src, span_warning(msg))
		tgui_alert(usr, msg)
		return FALSE

	var/datum/job/thisjob = SSjobs.GetJob(rank)
	if(thisjob.barred_by_disability(client))
		var/msg = "Должность [rank] недоступна в связи с инвалидностью персонажа. Пожалуйста, попробуйте другую."
		to_chat(src, span_warning(msg))
		tgui_alert(usr, msg)
		return FALSE

	if(!thisjob.character_old_enough(client))
		var/datum/species/species = client.prefs.get_species_prototype()
		var/msg = "Должность [rank] недоступна в связи с недостаточным возрастом персонажа ([client.prefs.read_preference(/datum/preference/numeric/age)]). Минимальный возраст — [get_age_limits(species, thisjob.min_age_type)]"
		to_chat(src, span_warning(msg))
		tgui_alert(usr, msg)
		return FALSE

	if(!thisjob.check_custom_requirements(client))
		var/msg = "Должность [rank] доступна только после получения достижения \"Опора проекта\". Пожалуйста, попробуйте другую."
		to_chat(src, span_warning(msg))
		tgui_alert(usr, msg)
		return FALSE

	SSjobs.AssignRole(src, rank, 1)

	var/mob/living/character = create_character()	//creates the human and transfers vars and mind
	character = SSjobs.AssignRank(character, rank, 1)					//equips the human

	// AIs don't need a spawnpoint, they must spawn at an empty core
	if(character.mind.assigned_role == JOB_TITLE_AI)
		var/mob/living/silicon/ai/ai_character = character.AIize() // AIize the character, but don't move them yet

		// IsJobAvailable for AI checks that there is an empty core available in this list
		ai_character.moveToEmptyCore()
		AnnounceCyborg(ai_character, rank, "был загружен в пустое ядро в [get_area(ai_character)]")

		SSticker.mode.latespawn(ai_character)
		SSticker?.score?.save_silicon_laws(ai_character, additional_info = "latespawn", log_all_laws = TRUE)
		qdel(src)
		return

	//Find our spawning point.
	var/join_message
	var/datum/spawnpoint/spawnpoint

	if(IsAdminJob(rank))
		if(IsERTSpawnJob(rank))
			character.loc = pick(GLOB.ertdirector)

		else if(IsSyndicateCommand(rank))
			character.loc = pick(GLOB.syndicateofficer)

		else
			character.forceMove(pick(GLOB.aroomwarp))

		join_message = "прибыл"

	else
		if(spawning_at)
			spawnpoint = GLOB.spawntypes[spawning_at]

		if(spawnpoint && istype(spawnpoint))
			if(spawnpoint.check_job_spawning(rank))
				character.move_to_spawn(spawnpoint.turfs)
				join_message = spawnpoint.msg

			else
				to_chat(character, "Выбранная вами зона появления ([spawnpoint.display_name]) недоступна для выбранной вами профессии. Вместо этого мы отправляем вас на шаттл Прибытия.")
				character.move_to_spawn(GLOB.latejoin)
				join_message = "прибыл на станцию"

		else
			if(character.mind.assigned_role == JOB_TITLE_PRISONER && length(GLOB.latejoin_prisoner))
				character.move_to_spawn(GLOB.latejoin_prisoner)
				join_message = "очнулся от криогенного сна"

			else
				character.move_to_spawn(GLOB.latejoin)
				join_message = "прибыл на станцию"

	character.lastarea = get_area(loc)
	character = character.spawn_equip(rank)
	if(ishuman(character))
		var/obj/item/storage/halloween/bucket = new /obj/item/storage/halloween
		character.put_in_l_hand(bucket, force = TRUE)
	SSticker.mode.latespawn(character)

	if(character.mind.assigned_role == JOB_TITLE_CYBORG)
		var/mob/living/silicon/robot/R = character
		AnnounceCyborg(character, R.mind.role_alt_title ? R.mind.role_alt_title : JOB_TITLE_CYBORG, join_message)
		if(!thisjob.is_position_available() && (thisjob in SSjobs.prioritized_jobs))
			SSjobs.prioritized_jobs -= thisjob

		qdel(src)
		return

	SSticker.minds += character.mind//Cyborgs and AIs handle this in the transform proc.	//TODO!!!!! ~Carn
	if(!IsAdminJob(rank))
		GLOB.data_core.manifest_inject(character)
		AnnounceArrival(character, rank, join_message)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(add_employment_contract), character), 3 SECONDS)

		if(GLOB.summon_guns_triggered)
			give_guns(character)
		if(GLOB.summon_magic_triggered)
			give_magic(character)

	if(!thisjob.is_position_available() && (thisjob in SSjobs.prioritized_jobs))
		SSjobs.prioritized_jobs -= thisjob

	qdel(src)

#define ARRIVALS_ANNOUNCEMENT_COMPUTER "Уведомитель о прибытии"

/mob/new_player/proc/AnnounceArrival(mob/living/carbon/human/character, rank, join_message)
	if(SSticker.current_state == GAME_STATE_PLAYING)
		var/ailist[] = list()
		for(var/mob/living/silicon/ai/A in GLOB.alive_mob_list)
			if(A.announce_arrivals)
				ailist += A
		if(length(ailist))
			var/mob/living/silicon/ai/announcer = pick(ailist)
			if(character.mind)
				if((character.mind.assigned_role != JOB_TITLE_CYBORG) && (character.mind.assigned_role != character.mind.special_role))
					var/arrivalmessage = create_announce_message(character, rank, join_message, announcer.arrivalmsg)
					announcer.say(";[arrivalmessage]")

		else
			if(character.mind)
				if((character.mind.assigned_role != JOB_TITLE_CYBORG) && (character.mind.assigned_role != character.mind.special_role))
					var/arrivalmessage = create_announce_message(character, rank, join_message, GLOB.global_announcer_base_text)
					radio_announce(arrivalmessage, ARRIVALS_ANNOUNCEMENT_COMPUTER, PUB_FREQ, follow_target_override = character)

/mob/new_player/proc/create_announce_message(mob/living/carbon/human/arrived, rank, join_message, message)
	if(arrived.mind.role_alt_title)
		rank = arrived.mind.role_alt_title
	message = replacetext(message,"$name",arrived.real_name)
	message = replacetext(message,"$rank",rank ? "[rank]" : "visitor")
	message = replacetext(message,"$species",arrived.dna.species.name)
	message = replacetext(message,"$age",num2text(arrived.age))
	message = replacetext(message,"$gender",arrived.gender == FEMALE ? "Female" : "Male")
	message = replacetext(message,"$join_message",join_message)
	return message

/proc/add_employment_contract(mob/living/carbon/human/employee)
	for(var/obj/structure/filingcabinet/employment/cabinet as anything in GLOB.employmentCabinets)
		if(cabinet.populated)
			cabinet.addFile(employee)

/mob/new_player/proc/AnnounceCyborg(mob/living/character, rank, join_message)
	if(SSticker.current_state == GAME_STATE_PLAYING)
		var/ailist[] = list()
		for(var/mob/living/silicon/ai/A in GLOB.alive_mob_list)
			ailist += A
		if(length(ailist))
			var/mob/living/silicon/ai/announcer = pick(ailist)
			if(character.mind)
				if(character.mind.assigned_role != character.mind.special_role)
					var/arrivalmessage = "Новый [rank ? "[rank]" : "турист" ] [join_message ? join_message : "прибыл на станцию"]."
					announcer.say(";[arrivalmessage]", ignore_languages = TRUE)
		else
			if(character.mind)
				if(character.mind.assigned_role != character.mind.special_role)
					// can't use their name here, since cyborg namepicking is done post-spawn, so we'll just say "A new Cyborg has arrived"/"A new Android has arrived"/etc.
					radio_announce("Новый [rank ? " [rank]" : " турист" ] [join_message ? join_message : "прибыл на станцию"].", ARRIVALS_ANNOUNCEMENT_COMPUTER, PUB_FREQ, follow_target_override = character)

#undef ARRIVALS_ANNOUNCEMENT_COMPUTER

// If current character can't be antagonist, try to pick random character, who can.
/mob/new_player/proc/handle_can_be_antagonist()
	if(!mind.special_role || client.prefs.read_preference(/datum/preference/toggle/can_be_antagonist))
		return

	client.prefs.get_possible_antagonist()

/mob/new_player/proc/create_character()
	spawning = TRUE
	close_spawn_windows()

	var/mob/living/carbon/human/new_character = new(loc)
	new_character.lastarea = get_area(loc)

	handle_can_be_antagonist()
	LAZYADD(persistent_client.joined_as_slots, "[client.prefs.default_slot]")

	client.prefs.apply_character_randomization_prefs(!!mind?.special_role)
	if(SSticker.random_players || appearance_isbanned(new_character))
		client.prefs.sync_save_data(PREFERENCE_CHARACTER)
		var/datum/preferences/random_preferences = new
		random_preferences.character_data = client.prefs.character_data.Copy()
		random_preferences.clear_character_cache()
		random_preferences.organ_data = client.prefs.organ_data.Copy()
		random_preferences.rlimb_data = client.prefs.rlimb_data.Copy()
		random_preferences.disabilities = client.prefs.disabilities
		random_preferences.randomise_appearance_prefs()
		random_preferences.apply_prefs_to(new_character)
		qdel(random_preferences)
	else
		client.prefs.apply_prefs_to(new_character)

	// stop_sound_channel(CHANNEL_LOBBYMUSIC)
	client?.tgui_panel?.stop_music()

	if(mind)
		mind.active = FALSE					// we wish to transfer the key manually

		if(mind.assigned_role == JOB_TITLE_CLOWN)				// give them a clownname if they are a clown
			new_character.rename_character(null, client.prefs.read_preference(/datum/preference/name/clown))

		else if(mind.assigned_role == JOB_TITLE_MIME)
			new_character.rename_character(null, client.prefs.read_preference(/datum/preference/name/mime))

		mind.set_original_mob(new_character)
		mind.transfer_to(new_character)					// won't transfer key since the mind is not active
		GLOB.human_names_list += new_character.real_name

	new_character.possess_by_player(key)		// Manually transfer the key to log them in

	return new_character

/mob/new_player/proc/ViewManifest()
	GLOB.generic_crew_manifest.ui_interact(usr)

/mob/new_player/Move(atom/newloc, direct = NONE, glide_size_override = 0, update_dir = TRUE)
	return FALSE

/mob/new_player/proc/close_spawn_windows()
	SStgui.close_user_uis(src, GLOB.latejoin_menu)
	close_window(src, "playersetup") //closes the player setup window
	if(client?.prefs)
		SStgui.close_uis(client.prefs)

/mob/new_player/proc/has_admin_rights()
	return check_rights(R_ADMIN, FALSE, src)

/mob/new_player/get_gender()
	if(!client?.prefs)
		return ..()
	return client.prefs.read_preference(/datum/preference/choiced/gender)

/mob/new_player/is_ready()
	return ready && ..()

/mob/new_player/mob_negates_gravity()
	return TRUE //no need to calculate if they have gravity.
