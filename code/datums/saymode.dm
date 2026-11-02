/datum/saymode
	var/key
	var/mode
	var/allows_custom_say_emotes = FALSE

/datum/saymode/proc/can_be_used_by(mob/living/user)
	return TRUE

/datum/saymode/proc/handle_message(
	mob/living/user,
	message,
	list/spans = list(),
	datum/language/language,
	list/message_mods = list()
)
	return NONE

/datum/saymode/hivemind
	abstract_type = /datum/saymode/hivemind
	allows_custom_say_emotes = TRUE
	var/name
	var/hive_trait
	var/span_class = "say_quote"
	var/list/speech_verbs = list("сообща%(ет,ют)%")
	var/list/ask_verbs
	var/list/exclaim_verbs

/datum/saymode/hivemind/can_be_used_by(mob/living/user)
	return HAS_TRAIT(user, hive_trait)

/datum/saymode/hivemind/proc/can_hear(mob/listener, mob/living/speaker)
	return HAS_TRAIT(listener, hive_trait)

/datum/saymode/hivemind/proc/check_can_speak(mob/living/speaker)
	return TRUE

/datum/saymode/hivemind/proc/get_speaker_name(mob/living/speaker)
	return speaker.name

/datum/saymode/hivemind/proc/format_message(message, mob/living/speaker)
	return span_message("<span class='[span_class]'>[message]</span>")

/datum/saymode/hivemind/proc/get_spoken_verb(message)
	switch(copytext_char(message, -1))
		if("!")
			if(length(exclaim_verbs))
				return pick(exclaim_verbs)
		if("?")
			if(length(ask_verbs))
				return pick(ask_verbs)
	return pick(speech_verbs)

/datum/saymode/hivemind/handle_message(
	mob/living/user,
	message,
	list/spans = list(),
	datum/language/language,
	list/message_mods = list()
)
	if(!message || !check_can_speak(user))
		return SAYMODE_MESSAGE_HANDLED

	add_say_logs(user, message, language = "([name]-HIVE)")

	var/speaker_name = get_speaker_name(user)
	var/msg = span_gamesay("[name], [span_name("[speaker_name]")] [genderize_decode(user, get_spoken_verb(message))], [format_message(message, user)]")
	for(var/mob/player as anything in GLOB.player_list)
		if(isdead(player))
			to_chat(player, span_gamesay("([ghost_follow_link(user, ghost = player)]) [msg]"))
			continue

		if(!can_hear(player, user))
			continue

		to_chat(player, msg)
		if(player.client?.prefs.toggles2 & PREFTOGGLE_2_RUNECHAT)
			player.create_chat_message(user, "<i>[message]</i>", list("telepathy"), null)
	return SAYMODE_MESSAGE_HANDLED

/datum/saymode/hivemind/grey
	key = "^"
	name = "Псисвязь"
	hive_trait = TRAIT_GREY_TELEPATHY
	span_class = "abductor"
	speech_verbs = list("сообща%(ет,ют)%")
	ask_verbs = list("интересу%(ет,ют)%ся")
	exclaim_verbs = list("со всей важностью сообща%(ет,ют)%")

/datum/saymode/hivemind/grey/check_can_speak(mob/living/speaker)
	if(ishuman(speaker))
		var/mob/living/carbon/human/human_speaker = speaker
		var/obj/item/organ/external/rhand = human_speaker.get_organ(BODY_ZONE_PRECISE_R_HAND)
		var/obj/item/organ/external/lhand = human_speaker.get_organ(BODY_ZONE_PRECISE_L_HAND)
		if((!rhand || !rhand.is_usable()) && (!lhand || !lhand.is_usable()))
			to_chat(speaker, span_warning("Вы не можете использовать руки для телепатии!"))
			return FALSE
	if(speaker.incapacitated())
		to_chat(speaker, span_warning("Вы не можете поднести руки к голове для телепатии!"))
		return FALSE

	speaker.visible_message(span_notice("[speaker] прикладыва[PLUR_ET_YUT(speaker)] пальцы к виску."))
	return TRUE

/datum/saymode/hivemind/grey/can_hear(mob/listener, mob/living/speaker)
	return ..() && are_zs_connected(listener, speaker)

/datum/saymode/hivemind/grey/get_speaker_name(mob/living/speaker)
	return speaker.real_name

/datum/saymode/hivemind/wryn
	key = "y"
	name = "Разум улья Вринов"
	hive_trait = TRAIT_WRYN_HIVEMIND
	span_class = "alien"
	speech_verbs = list("щебеч%(ет,ут)%")
	ask_verbs = list("вопросительно щебеч%(ет,ут)%")
	exclaim_verbs = list("громко жужж%(ит,ат)%")

/datum/saymode/hivemind/wryn/can_hear(mob/listener, mob/living/speaker)
	if(!..())
		return FALSE
	var/mob/living/carbon/carbon_listener = listener
	if(!istype(carbon_listener))
		return TRUE
	return !!(locate(/obj/item/organ/internal/wryn/hivenode) in carbon_listener.internal_organs)

/datum/saymode/hivemind/xeno
	key = "a"
	mode = MODE_ALIEN
	name = "Разум улья Ксеноморфов"
	hive_trait = TRAIT_XENO_HIVEMIND
	span_class = "alien"
	speech_verbs = list("шип%(ит,ят)%")
	ask_verbs = list("вопросительно шип%(ит,ят)%")
	exclaim_verbs = list("рыч%(ит,ят)%")

/datum/saymode/hivemind/terror_spider
	key = "as"
	name = "Разум улья Пауков Ужаса"
	hive_trait = TRAIT_TERRORSPIDER_HIVEMIND
	span_class = "terrorspider"
	speech_verbs = list("щебеч%(ет,ут)%")
	ask_verbs = list("вопросительно щебеч%(ет,ут)%")
	exclaim_verbs = list("громко жужж%(ит,ат)%")

/datum/saymode/hivemind/changeling
	key = "g"
	mode = MODE_CHANGELING
	name = "Коллективный разум Генокрадов"
	hive_trait = TRAIT_CHANGELING_HIVEMIND
	span_class = "changeling"

/datum/saymode/hivemind/changeling/get_speaker_name(mob/living/speaker)
	var/datum/antagonist/changeling/cling = speaker.mind?.has_antag_datum(/datum/antagonist/changeling)
	return cling ? cling.changelingID : ..()

/datum/saymode/hivemind/eventling
	key = "gi"
	name = "Инфильтрованный коллективный разум Генокрадов"
	hive_trait = TRAIT_EVENTLING_HIVEMIND
	span_class = "changeling"

/datum/saymode/hivemind/eventling/get_speaker_name(mob/living/speaker)
	var/datum/antagonist/changeling/evented/cling = speaker.mind?.has_antag_datum(/datum/antagonist/changeling/evented)
	return cling ? cling.changelingID : ..()

/datum/saymode/hivemind/shadowling
	key = "8"
	name = "Коллективный разум Тенеморфов"
	hive_trait = TRAIT_SHADOWLING_HIVEMIND
	span_class = "shadowling"

/datum/saymode/hivemind/shadowling/get_speaker_name(mob/living/speaker)
	if(speaker.mind?.special_role == SPECIAL_ROLE_SHADOWLING)
		return span_shadowling(span_fontsize3("([speaker.mind.special_role]) [speaker]"))
	if(speaker.mind?.special_role)
		return "([speaker.mind.special_role]) [speaker]"
	return ..()

/datum/saymode/hivemind/shadowling/format_message(message, mob/living/speaker)
	if(speaker.mind?.special_role == SPECIAL_ROLE_SHADOWLING)
		message = span_bold(span_fontsize3(message))
	return ..()

/datum/saymode/hivemind/abductor
	key = "aa"
	name = "Псисвязь Абдукторов"
	hive_trait = TRAIT_ABDUCTOR_HIVEMIND
	span_class = "abductor"
	speech_verbs = list("бормоч%(ет,ут)%")

/datum/saymode/hivemind/abductor/get_speaker_name(mob/living/speaker)
	return speaker.real_name

/datum/saymode/hivemind/abductor/can_hear(mob/living/carbon/human/listener, mob/living/carbon/human/speaker)
	if(!..())
		return FALSE
	if(!isabductor(listener) || !isabductor(speaker))
		return FALSE
	var/datum/species/abductor/speaker_species = speaker.dna.species
	var/datum/species/abductor/listener_species = listener.dna.species
	return speaker_species.team == listener_species.team

/datum/saymode/hivemind/golem
	key = "aa"
	name = "Псисвязь Големов"
	hive_trait = TRAIT_GOLEM_HIVEMIND
	span_class = "abductor"
	speech_verbs = list("бормоч%(ет,ут)%")

/datum/saymode/hivemind/golem/get_speaker_name(mob/living/speaker)
	return speaker.real_name

/datum/saymode/hivemind/borer
	key = "bo"
	name = "Кортикальная связь"
	hive_trait = TRAIT_BORER_HIVEMIND
	span_class = "alien"

/datum/saymode/hivemind/borer/get_speaker_name(mob/living/speaker)
	var/mob/living/simple_animal/borer/borer = isborer(speaker) ? speaker : speaker.has_brain_worms()
	return borer ? borer.truename : ..()

/datum/saymode/hivemind/swarmer
	key = "sw"
	name = "Связь Роевиков"
	hive_trait = TRAIT_SWARMER_HIVEMIND
	speech_verbs = list("сообща%(ет,ют)%", "констатиру%(ет,ют)%")
	ask_verbs = list("запрашива%(ет,ют)%", "дела%(ет,ют)% запрос")
	exclaim_verbs = list("восклица%(ет,ют)%")

/datum/saymode/binary
	key = MODE_KEY_BINARY
	mode = MODE_BINARY
	allows_custom_say_emotes = TRUE
	var/name = "Бинарный канал"
	var/drone_only = FALSE
	var/list/speech_verbs = list("сообща%(ет,ют)%", "констатиру%(ет,ют)%")
	var/list/ask_verbs = list("запрашива%(ет,ют)%", "дела%(ет,ют)% запрос")
	var/list/exclaim_verbs = list("восклица%(ет,ют)%")

/datum/saymode/binary/can_be_used_by(mob/living/user)
	return user.binarycheck() && !HAS_TRAIT(user, TRAIT_DRONE_BINARY)

/datum/saymode/binary/proc/can_hear(mob/living/listener)
	if(!listener.binarycheck())
		return FALSE
	if(drone_only && !HAS_TRAIT(listener, TRAIT_DRONE_BINARY))
		return FALSE
	return TRUE

/datum/saymode/binary/proc/get_spoken_verb(message)
	switch(copytext_char(message, -1))
		if("!")
			return pick(exclaim_verbs)
		if("?")
			return pick(ask_verbs)
	return pick(speech_verbs)

/datum/saymode/binary/handle_message(
	mob/living/user,
	message,
	list/spans = list(),
	datum/language/language,
	list/message_mods = list()
)
	if(!message)
		return SAYMODE_MESSAGE_HANDLED

	add_say_logs(user, message, language = "ROBOT")

	var/verb = genderize_decode(user, get_spoken_verb(message))
	var/list/message_start = list("<i><span class='game say'>[name], [span_name("[user.name]")]")
	var/list/message_body = list(span_message("[verb],</i>[span_robot("\"[message]\"")]</span>"))

	for(var/mob/dead_mob as anything in GLOB.dead_mob_list)
		if(!isnewplayer(dead_mob) && !isbrain(dead_mob))
			var/list/message_start_dead = list("([ghost_follow_link(user, ghost = dead_mob)]) <i><span class='game say'>[name], [span_name("[user.name]")]")
			var/list/dead_message = message_start_dead + message_body
			dead_mob.show_message(dead_message.Join(" "), 2)

	for(var/mob/living/listener in GLOB.alive_mob_list)
		if(!can_hear(listener))
			continue
		var/list/listener_start = message_start
		var/list/listener_body = message_body
		if(isAI(listener))
			listener_start = list("<i><span class='game say'>[name], <a href='byond://?src=[listener.UID()];track=[user.UID()]'>[span_name("[user.name]")]</a>")
		else if(isrobot(listener))
			var/mob/living/silicon/robot/borg = listener
			if(borg.check_binary_master(user))
				listener_start = list("<span style='font-size: 18px;'>") + listener_start
				listener_body = listener_body + list("</span>")
		var/list/final_message = listener_start + listener_body
		listener.show_message(final_message.Join(" "), 2)
	return SAYMODE_MESSAGE_HANDLED

/datum/saymode/binary/drone
	key = MODE_KEY_DRONE
	name = "Канал Дронов"
	drone_only = TRUE
	speech_verbs = list("переда%(ёт,ют)%")
	ask_verbs = list("переда%(ёт,ют)%")
	exclaim_verbs = list("переда%(ёт,ют)%")

/datum/saymode/binary/drone/can_be_used_by(mob/living/user)
	return user.binarycheck() && HAS_TRAIT(user, TRAIT_DRONE_BINARY)
