/mob/Hear(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, list/spans, list/message_mods = list(), message_range = 0)
	if(!client && !LAZYACCESS(_listen_lookup, COMSIG_MOVABLE_HEAR))
		return FALSE

	var/atom/movable/source = speaker.GetSource() || speaker

	var/ghost_in_view
	if(isobserver(src) && !radio_freq && get_preference(PREFTOGGLE_CHAT_GHOSTEARS))
		ghost_in_view = (source in view(src))
		var/mob/speaker_mob = source
		if(!ghost_in_view && (!istype(speaker_mob) || !speaker_mob.client))
			return FALSE

	var/italics = (SPAN_ITALICS in spans)
	var/turf/hearer_turf = get_turf(src)
	if(!radio_freq && hearer_turf && !isobserver(src) && !message_mods[MODE_IGNORE_ATMOSPHERICS])
		var/datum/gas_mixture/environment = hearer_turf.get_readonly_air()
		var/pressure = environment ? environment.return_pressure() : 0
		if(pressure < SOUND_MINIMUM_PRESSURE && get_dist(source, src) > 1)
			return FALSE
		if(pressure < ONE_ATMOSPHERE * 0.4)
			italics = TRUE

	var/understood = TRUE
	var/untranslated_raw_message = raw_message
	raw_message = translate_language(source, message_language, raw_message, spans, message_mods)
	if(raw_message != untranslated_raw_message)
		understood = FALSE

	if(!radio_freq && message_range != INFINITY && message_mods[WHISPER_MODE] && !HAS_TRAIT(src, TRAIT_GOOD_HEARING) && !isobserver(src))
		var/outside_dist = max(get_dist(source, src) - message_range, 0)
		if(outside_dist > EAVESDROP_RANGE)
			if(!has_vision(information_only = TRUE) || !isturf(source.loc))
				return FALSE
			to_chat(src, span_gamesay("[span_name(source.GetVoice())] [genderize_decode(source, message_mods[SAY_MOD_VERB] || source.verb_whisper)] что-то."))
			return FALSE
		if(outside_dist > 0)
			raw_message = stars(raw_message)

	if(stat == UNCONSCIOUS)
		hear_sleep(raw_message)
		return FALSE

	SEND_SIGNAL(src, COMSIG_MOVABLE_HEAR, args)

	if(!client || !raw_message)
		return FALSE

	var/list/shown_spans = spans ? spans.Copy() : list()
	if(italics)
		shown_spans |= SPAN_ITALICS
	if(ghost_in_view)
		shown_spans |= "bold"

	var/message_clean = replace_characters(apply_message_emphasis(capitalize(raw_message)), list("+"))

	if(HAS_TRAIT(src, TRAIT_DEAF))
		if(radio_freq)
			if(prob(20))
				to_chat(src, span_warning("Ваша гарнитура вибрирует, но вы не слышите ни звука!"))
		else if(source == src)
			to_chat(src, span_warning("Вы не слышите собственной речи!"))
		else
			to_chat(src, "[span_name(source.GetVoice())] что-то говор[PLUR_IT_YAT(source)], но вы ничего не слышите!")
		return FALSE

	to_chat(src, compose_message(speaker, message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, shown_spans, message_mods))

	if(client?.prefs.toggles2 & PREFTOGGLE_2_RUNECHAT)
		var/list/runechat_spans = radio_freq ? list("radio") : ((italics || !ismob(source)) ? list("italics") : null)
		create_chat_message(radio_freq ? source : speaker, message_clean, runechat_spans, GLOB.language_datum_instances[message_language])

	if(!message_mods[MODE_NO_TTS])
		hear_tts(speaker, raw_message, radio_freq, message_mods)

	return HEAR_HEARD | (understood ? HEAR_UNDERSTOOD : NONE)

/mob/proc/hear_tts(atom/movable/speaker, message_tts, radio_freq, list/message_mods)
	var/atom/movable/source = speaker.GetSource() || speaker
	if(radio_freq)
		if(src != source || isrobot(src) || isAI(src))
			INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(tts_cast), src, src, message_tts, speaker.tts_seed, FALSE, SOUND_EFFECT_RADIO, null, null, 'sound/effects/radio_chatter.ogg', source)
		return
	if(!ismob(source))
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(tts_cast), speaker, src, message_tts, speaker.tts_seed, TRUE, speaker.tts_atom_say_effect, TTS_TRAIT_RATE_MEDIUM)
		return
	var/traits = TTS_TRAIT_RATE_FASTER
	if(message_mods[WHISPER_MODE])
		traits |= TTS_TRAIT_PITCH_WHISPER
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(tts_cast), speaker, src, message_tts, speaker.tts_seed, TRUE, SOUND_EFFECT_NONE, traits)

/mob/compose_name(atom/movable/speaker, radio_freq, list/message_mods)
	var/atom/movable/source = speaker.GetSource() || speaker
	var/speaker_name = speaker.GetVoice()
	if(radio_freq && message_mods[MODE_RADIO_GARBLED])
		speaker_name = UNKNOWN_NAME_RUS
	return perceived_name(source, speaker_name)

/mob/proc/hear_sleep(message)
	var/heard = ""
	if(prob(15))
		message = strip_html_properly(message)
		var/list/punctuation = list(",", "!", ".", ";", "?")
		var/list/messages = splittext(message, " ")
		if(length(messages) > 0)
			var/R = rand(1, length(messages))
			var/heardword = messages[R]
			if(copytext(heardword,1, 1) in punctuation)
				heardword = copytext(heardword,2)
			if(copytext(heardword,-1) in punctuation)
				heardword = copytext(heardword,1,length(heardword))
			heard = span_gamesay("...<i>Вы слышите что-то про</i>... \"[heardword]\"...")
		else
			heard = span_gamesay("...<i>Вы почти что смогли расслышать что-то</i>...")
	else
		heard = span_gamesay("...<i>Вы едва слышите, как кто-то говорит</i>...")

	to_chat(src, heard)

/mob/proc/perceived_name(atom/movable/speaker, speaker_name)
	return speaker_name
