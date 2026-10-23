/mob/living/silicon/robot/radio(message, list/message_mods = list(), list/spans, language)
	. = ..()
	if(. & NOPASS)
		return .
	var/channel = message_mods[RADIO_EXTENSION]
	if(!channel && !message_mods[MODE_HEADSET])
		return .
	if(!is_component_functioning("radio"))
		to_chat(src, span_warning("Your radio isn't functional at this time."))
		return .
	if(channel == PUB_FREQ_NAME)
		channel = null
	if(radio.talk_into(src, message, channel, spans, language, message_mods))
		return NOPASS
	return .

/mob/living/silicon/ai/radio(message, list/message_mods = list(), list/spans, language)
	. = ..()
	if(. & NOPASS)
		return .
	var/channel = message_mods[RADIO_EXTENSION]
	if(channel == DEPARTMENT_FREQ_NAME)
		if(holopad_talk(message, spans, language, message_mods))
			return NOPASS
		return .
	if(!channel && !message_mods[MODE_HEADSET])
		return .
	if(aiRadio.disabledAi || aiRestorePowerRoutine || stat)
		to_chat(src, span_warning("System Error - Transceiver Disabled."))
		return .
	if(channel == PUB_FREQ_NAME)
		channel = null
	if(aiRadio.talk_into(src, message, channel, spans, language, message_mods))
		return NOPASS
	return .

/mob/living/silicon/pai/radio(message, list/message_mods = list(), list/spans, language)
	. = ..()
	if(. & NOPASS)
		return .
	var/channel = message_mods[RADIO_EXTENSION]
	if(!channel && !message_mods[MODE_HEADSET])
		return .
	if(channel == PUB_FREQ_NAME)
		channel = null
	if(radio.talk_into(src, message, channel, spans, language, message_mods))
		return NOPASS
	return .

/mob/living/silicon/say_mod(input, list/message_mods = list(), datum/language/language)
	if(message_mods[WHISPER_MODE])
		return ..()

	var/ending = copytext_char(input, -1)
	if(ending == "?")
		return speak_query
	else if(ending == "!")
		return speak_exclamation

	return speak_statement

/mob/living/silicon/ai/proc/holopad_talk(message, list/spans, language, list/message_mods)
	add_say_logs(src, message, language = "HPAD")

	var/obj/machinery/hologram/holopad/T = current
	if(!istype(T) || !T.masters[src])
		to_chat(src, "No holopad connected.")
		return FALSE

	var/obj/effect/overlay/holo_pad_hologram/hologram = T.masters[src]
	hologram.say(message, spans = spans, sanitize = FALSE, language = language, message_mods = list(SAY_MOD_VERB = message_mods[SAY_MOD_VERB]))
	to_chat(src, span_gamesay("<i>Holopad transmitted, [span_name(real_name)] [span_message("[genderize_decode(src, message_mods[SAY_MOD_VERB])]: \"[message]\"")]</i>"))
	return TRUE

/mob/living/silicon/ai/proc/holopad_emote(message) //This is called when the AI uses the 'me' verb while using a holopad.
	message = trim(message)

	if(!message)
		return

	var/obj/machinery/hologram/holopad/T = current
	if(istype(T) && T.masters[src])
		var/rendered = span_gamesay("[span_name(name)] [span_message(message)]")
		to_chat(src, span_gamesay("<i>Holopad action relayed, [span_name(real_name)] [span_message(message)]</i>"))

		for(var/mob/M in viewers(T.loc))
			M.show_message(rendered, EMOTE_VISIBLE, chat_message_type = MESSAGE_TYPE_LOCALCHAT)

		log_emote("(HPAD) [message]", src)
	else //This shouldn't occur, but better safe then sorry.
		to_chat(src, "No holopad connected.")
		return
	return TRUE

/mob/living/silicon/ai/emote(emote_key, type_override = null, message = null, intentional = FALSE, force_silence = FALSE, ignore_cooldowns = FALSE)
	var/obj/machinery/hologram/holopad/T = current
	if(istype(T) && T.masters[src])//Is the AI using a holopad?
		holopad_emote(message)
	else //Emote normally, then.
		..()
