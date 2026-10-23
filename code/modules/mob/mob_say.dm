#define ILLEGAL_CHARACTERS_LIST list("<" = "", ">" = "", \
	"\[" = "", "]" = "", "{" = "", "}" = "")

#define MESSAGE_MODS_LENGTH 6

/mob/say(
	message,
	bubble_type,
	list/spans = list(),
	sanitize = TRUE,
	datum/language/language,
	ignore_spam = FALSE,
	forced,
	filterproof = FALSE,
	message_range = 7,
	datum/saymode/saymode,
	list/message_mods = list(),
)
	return

GAME_VERB(/mob, whisper_verb, VERB_WHISPER, VERB_CATEGORY_IC)
	VERB_ARG(message, VERB_ARG_TYPE_TEXT, VERB_ARG_SOURCE_INPUT)

	if(!message)
		return

	QUEUE_OR_CALL_VERB_FOR(VERB_CALLBACK(src, TYPE_PROC_REF(/mob, whisper), message), SSspeech_controller)

/mob/proc/whisper(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language, ignore_spam = FALSE, forced, filterproof)
	if(!message)
		return
	say(message, language = language)

GAME_VERB(/mob, say_verb, VERB_SAY, VERB_CATEGORY_IC)
	VERB_ARG(message, VERB_ARG_TYPE_TEXT, VERB_ARG_SOURCE_INPUT)

	message = replace_characters(message, ILLEGAL_CHARACTERS_LIST)
	set_typing_indicator(FALSE)

	if(!message)
		return

	QUEUE_OR_CALL_VERB_FOR(VERB_CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), message), SSspeech_controller)

GAME_VERB(/mob, me_verb, VERB_ME, VERB_CATEGORY_IC)
	VERB_ARG(message, VERB_ARG_TYPE_TEXT, VERB_ARG_SOURCE_INPUT)

	message = strip_html_properly(message)

	set_typing_indicator(FALSE, TRUE)

	if(!message)
		return

	if(use_me)
		QUEUE_OR_CALL_VERB_FOR(VERB_CALLBACK(src, TYPE_PROC_REF(/mob, custom_emote), usr.emote_type, message, TRUE), SSspeech_controller)
	else
		QUEUE_OR_CALL_VERB_FOR(VERB_CALLBACK(src, TYPE_PROC_REF(/mob, emote), "me", 1, message, TRUE), SSspeech_controller)

/mob/proc/say_dead(message)
	var/runechat_message = apply_message_emphasis(message)
	message = handle_emojis(runechat_message)
	if(client)
		if(!check_rights(R_ADMIN, FALSE) && !CONFIG_GET(flag/dsay_allowed))
			to_chat(src, span_danger("Deadchat is globally muted."))
			return

		if(check_mute(client.account_ckey, MUTE_DEADCHAT))
			to_chat(src, span_warning("You cannot talk in deadchat (muted)."))
			return

		if(!(client.prefs.toggles & PREFTOGGLE_CHAT_DEAD))
			to_chat(src, span_danger("You have deadchat muted."))
			return

		if(client.handle_spam_prevention(message, MUTE_DEADCHAT))
			return

	if(SEND_SIGNAL(src, COMSIG_MOB_DEADSAY, message) & MOB_DEADSAY_SIGNAL_INTERCEPT)
		return

	if(message in USABLE_DEAD_EMOTES)
		emote(copytext(message, 2), intentional = TRUE)
		log_emote(message, src)
		create_log(DEADCHAT_LOG, message)
		return

	say_dead_direct("[pick("жалуется", "стонет", "хнычет", "причитает", "рыдает", "ноет")], \"[span_message(message)]\"", src, runechat_message)
	add_deadchat_logs(src, message)

/mob/proc/get_verb(list/verbs)
	if(!verbs)
		return ""
	if(!istype(verbs))
		return verbs
	return pick(verbs)

/mob/proc/get_ear()
	return get_turf(src)

/mob/proc/check_emote(message, forced)
	if(copytext(message, 1, 2) == "*")
		emote(copytext(message, 2), intentional = !forced)
		return TRUE

/mob/proc/hivecheck()
	return FALSE

/mob/proc/get_message_mods(message, list/mods)
	for(var/iteration in 1 to MESSAGE_MODS_LENGTH)
		if(!length(message))
			return message

		var/first_char = copytext_char(message, 1, 2)
		if(first_char == ";" && !mods[MODE_HEADSET] && !mods[RADIO_EXTENSION])
			mods[MODE_HEADSET] = TRUE
			message = trim_left(copytext_char(message, 2))
			continue

		if(!(first_char in GLOB.say_prefixes))
			return message

		var/list/words = splittext(message, " ")
		var/token = words[1]
		var/key = lowertext(copytext_char(token, 2))
		if(!mods[RADIO_EXTENSION] && !mods[WHISPER_MODE] && GLOB.department_radio_keys[token])
			var/radio_mode = GLOB.department_radio_keys[token]
			if(radio_mode == WHISPER_CHANNEL)
				mods[WHISPER_MODE] = MODE_WHISPER
			else
				mods[RADIO_EXTENSION] = radio_mode
				mods[RADIO_KEY] = key
		else if(!mods[RADIO_KEY] && SSradio.saymodes[key])
			mods[RADIO_KEY] = key
		else if(!mods[LANGUAGE_EXTENSION] && GLOB.language_keys[lowertext(token)])
			var/datum/language/language = GLOB.language_keys[lowertext(token)]
			if(can_speak_language(language))
				mods[LANGUAGE_EXTENSION] = language
		else
			return message

		message = trim_left(copytext_char(message, length_char(token) + 1))
	return message

#undef MESSAGE_MODS_LENGTH
#undef ILLEGAL_CHARACTERS_LIST
