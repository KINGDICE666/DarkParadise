#define CHALLENGE_TIME_LIMIT 10 MINUTES
#define CHALLENGE_SHUTTLE_DELAY 30 MINUTES //30 minutes, so the ops have at least 10 minutes before the shuttle is callable. Gives the nuke ops at least 15 minutes before shuttle arrive.
#define CHALLENGE_MIN_PLAYERS 50
#define CHALLENGE_CONFIRM "Да"
#define CHALLENGE_CANCEL "Нет"

/obj/item/nuclear_challenge
	name = "Declaration of War (Challenge Mode)"
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-red"
	item_state = "walkietalkie"
	desc = "Устройство для объявления войны станции. Синдикат предоставит отряду дополнительные телекристаллы, \
		но экипаж получит время на подготовку к нападению. Используйте на базе в течение 10 минут после получения."
	var/declaring_war = FALSE
	var/total_tc = 0 //Total amount of telecrystals shared between nuke ops
	var/creation_time
	var/announcement_sound = 'sound/effects/siren.ogg'

/obj/item/nuclear_challenge/get_ru_names()
	return alist(
		NOMINATIVE = "объявление войны",
		GENITIVE = "объявления войны",
		DATIVE = "объявлению войны",
		ACCUSATIVE = "объявление войны",
		INSTRUMENTAL = "объявлением войны",
		PREPOSITIONAL = "объявлении войны",
	)

/obj/item/nuclear_challenge/Initialize(mapload)
	. = ..()
	creation_time = world.time

/obj/item/nuclear_challenge/attack_self(mob/living/user)
	if(!check_allowed(user))
		return

	declaring_war = TRUE
	var/remaining_seconds = max(0, round((CHALLENGE_TIME_LIMIT - (world.time - creation_time)) / (1 SECONDS)))
	var/confirmation = tgui_alert(
		user,
		"Обсудите план с отрядом. Объявить войну станции [station_name()]? До конца срока: [remaining_seconds] секунд[DECL_A_Y_0(remaining_seconds)].",
		"Объявление войны",
		list(CHALLENGE_CONFIRM, CHALLENGE_CANCEL),
	)
	declaring_war = FALSE

	if(!check_allowed(user))
		return

	if(confirmation != CHALLENGE_CONFIRM)
		to_chat(user, span_notice("Вы решили сохранить эффект неожиданности."))
		return

	var/war_declaration = "[user.declent_ru(NOMINATIVE)] объявля[PLUR_ET_YUT(user)] о намерении уничтожить станцию [station_name()] ядерной боеголовкой и предлага[PLUR_ET_YUT(user)] экипажу попытаться помешать этому."

	declaring_war = TRUE
	var/custom_threat = tgui_alert(user, "Хотите изменить текст объявления?", "Объявление войны", list(CHALLENGE_CONFIRM, CHALLENGE_CANCEL))
	declaring_war = FALSE

	if(!check_allowed(user))
		return

	if(custom_threat == CHALLENGE_CONFIRM)
		declaring_war = TRUE
		war_declaration = tgui_input_text(user, "Введите текст объявления войны:", "Объявление войны")
		declaring_war = FALSE

	if(!check_allowed(user) || !war_declaration)
		return

	GLOB.major_announcement.announce(
		message = war_declaration,
		new_title = ANNOUNCE_DECLAREWAR_RU,
		msg_sanitized = TRUE,
		new_sound = announcement_sound,
		color_override = "crimson"
	)
	addtimer(CALLBACK(SSsecurity_level, TYPE_PROC_REF(/datum/controller/subsystem/security_level, set_level), SEC_LEVEL_GAMMA), 30 SECONDS)

	to_chat(user, span_notice("Синдикат предоставил отряду дополнительные телекристаллы за объявление войны."))
	to_chat(user, span_bold("Телекристаллы распределены между аплинками Вашего отряда."))

	for(var/obj/machinery/computer/shuttle/syndicate/shuttle_console in SSmachines.get_by_type(/obj/machinery/computer/shuttle/syndicate))
		shuttle_console.challenge = TRUE
		shuttle_console.challenge_start_time = creation_time

	// No. of player - Min. Player to dec, divided by player per bonus, then multipled by TC per bonus. Rounded.
	var/datum/antagonist/nuclear_operative/operative = user.mind.has_antag_datum(/datum/antagonist/nuclear_operative)
	var/datum/team/nuclear_team/team = operative.nuclear_team
	team.scale_challange()
	team.share_telecrystals()
	CONFIG_SET(number/shuttle_refuel_delay, CHALLENGE_SHUTTLE_DELAY)
	qdel(src)

/obj/item/nuclear_challenge/proc/check_allowed(mob/living/user)
	var/datum/antagonist/nuclear_operative/operative = user.mind?.has_antag_datum(/datum/antagonist/nuclear_operative)
	if(!operative?.nuclear_team)
		balloon_alert(user, "нет доступа!")
		return FALSE
	if(declaring_war)
		to_chat(user, span_warning("Сначала завершите текущее объявление войны."))
		return FALSE
	if(length(GLOB.player_list) < CHALLENGE_MIN_PLAYERS)
		to_chat(user, span_warning("На станции слишком мало членов экипажа для объявления войны."))
		return FALSE
	if(!is_admin_level(user.z))
		to_chat(user, span_warning("Объявить войну можно только с базы."))
		return FALSE
	if((world.time - creation_time) > CHALLENGE_TIME_LIMIT) // Only count after the round started
		to_chat(user, span_warning("Срок объявления войны истёк. Дополнительное финансирование недоступно."))
		return FALSE
	for(var/obj/machinery/computer/shuttle/syndicate/shuttle_console in SSmachines.get_by_type(/obj/machinery/computer/shuttle/syndicate))
		if(shuttle_console.moved)
			to_chat(user, span_warning("Шаттл уже покинул базу. Объявить войну больше нельзя."))
			return FALSE
	return TRUE

#undef CHALLENGE_TIME_LIMIT
#undef CHALLENGE_SHUTTLE_DELAY
#undef CHALLENGE_MIN_PLAYERS
#undef CHALLENGE_CONFIRM
#undef CHALLENGE_CANCEL
