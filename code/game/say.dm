/atom/movable/proc/say(
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
	if(!try_speak(message, ignore_spam, forced, filterproof))
		return
	if(sanitize)
		message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message || message == "")
		return
	if(speech_span)
		spans |= speech_span
	language ||= get_selected_language()
	var/datum/language/spoken_lang = GLOB.language_datum_instances[language]
	if(LAZYLEN(spoken_lang?.spans))
		spans |= spoken_lang.spans
	message_mods[SAY_MOD_VERB] ||= say_mod(message, message_mods, language)
	send_speech(message, message_range, src, bubble_type, spans, language, message_mods, forced = forced)

/atom/movable/atom_say(message, use_tts = TRUE)
	if(!message)
		return
	return say(message, sanitize = FALSE, message_mods = list(MODE_NO_TTS = !use_tts))

/atom/movable/proc/Hear(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, list/spans, list/message_mods = list(), message_range = 0)
	SEND_SIGNAL(src, COMSIG_MOVABLE_HEAR, args)
	return HEAR_HEARD | HEAR_UNDERSTOOD

/atom/movable/proc/try_speak(message, ignore_spam = FALSE, forced = null, filterproof = FALSE)
	return !HAS_TRAIT(src, TRAIT_MUTE)

/atom/movable/proc/send_speech(message, range = 7, obj/source = src, bubble_type, list/spans, datum/language/message_language, list/message_mods = list(), forced = FALSE)
	var/list/listeners = get_hearers_in_view(range, source)
	var/list/speech_bubble_recipients = list()
	for(var/atom/movable/hearing_movable as anything in listeners)
		if(!hearing_movable)
			stack_trace("somehow theres a null returned from get_hearers_in_view() in send_speech!")
			continue
		if(!(hearing_movable.Hear(src, message_language, message, null, null, null, spans, message_mods, range) & HEAR_HEARD))
			continue
		var/mob/hearing_mob = hearing_movable
		if(ismob(hearing_mob) && hearing_mob.client)
			speech_bubble_recipients += hearing_mob.client

	if(!length(speech_bubble_recipients))
		return
	var/image/say_popup = image('icons/mob/talk.dmi', src, "[bubble_type || bubble_icon][say_test(message)]", FLY_LAYER)
	SET_PLANE_EXPLICIT(say_popup, ABOVE_GAME_PLANE, src)
	say_popup.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay), say_popup, speech_bubble_recipients, 3 SECONDS)

/atom/movable/proc/compose_message(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, list/spans, list/message_mods = list(), visible_name = FALSE)
	var/raw_name = message_mods[MODE_SPEAKER_NAME_OVERRIDE] || compose_name(speaker, radio_freq, message_mods)
	var/namepart = colorize_name(speaker.GetSource() || speaker, raw_name)

	var/languageicon = ""
	var/datum/language/dialect = GLOB.language_datum_instances[message_language]
	var/dialect_icon_type = (dialect?.icon_state && dialect.display_icon_type(src, message_mods)) || DISPLAY_LANGUAGE_ICON_NONE
	if(dialect_icon_type != DISPLAY_LANGUAGE_ICON_NONE)
		var/datum/asset/spritesheet_batched/sheet = get_asset_datum(/datum/asset/spritesheet_batched/chat)
		var/icon_tag = sheet.icon_tag("language-[dialect.icon_state][dialect_icon_type == DISPLAY_LANGUAGE_ICON_PARTIAL ? "-partial" : ""]")
		languageicon = span_tooltip_subtle(dialect.name, icon_tag) + " "

	var/messagepart = speaker.generate_messagepart(raw_message, spans, message_mods)
	var/track = compose_track_href(speaker, raw_name, radio_freq, message_mods)
	if(track)
		track += " "

	if(radio_freq)
		var/freq_color = get_radio_color(radio_freq, radio_freq_color)
		return "[track]<span class='[get_radio_span(radio_freq)]'[freq_color ? " style='color:[freq_color];'" : ""]><b>\[[get_radio_name(radio_freq, radio_freq_name)]\]</b> [languageicon]<span class='name'>[namepart]</span> [messagepart]</span>"

	return span_gamesay("[track][languageicon][span_name(namepart)][speaker.GetAltName()] [messagepart]")

/atom/movable/proc/compose_name(atom/movable/speaker, radio_freq, list/message_mods)
	return speaker.GetVoice()

/atom/movable/proc/compose_track_href(atom/movable/speaker, namepart, radio_freq, list/message_mods)
	return ""

/atom/movable/proc/say_mod(input, list/message_mods = list(), datum/language/language)
	var/ending = copytext_char(input, -1)
	if(copytext_char(input, -2) == "!!")
		return verb_yell
	else if(message_mods[WHISPER_MODE])
		return verb_whisper
	else if(ending == "?")
		return verb_ask
	else if(ending == "!")
		return verb_exclaim
	return get_default_say_verb()

/atom/movable/proc/get_default_say_verb()
	return verb_say

/atom/movable/proc/generate_messagepart(input, list/spans = list(speech_span), list/message_mods = list())
	if(!input)
		input = "..."

	var/say_mod = genderize_decode(src, message_mods[SAY_MOD_VERB] || say_mod(input, message_mods))

	if(copytext_char(input, -2) == "!!")
		spans |= SPAN_YELL

	var/processed_input = replace_characters(apply_message_emphasis(input), list("+"))
	processed_input = span_message(attach_spans(processed_input, spans))

	return "[apply_message_emphasis(say_mod)]: \"[processed_input]\""

/atom/movable/proc/translate_language(atom/movable/speaker, datum/language/language, raw_message, list/spans, list/message_mods)
	if(!language)
		return stars(raw_message)

	if(!has_language(language))
		var/datum/language/dialect = GLOB.language_datum_instances[language]
		var/list/mutual_languages
		var/list/partially_understood_languages = get_partially_understood_languages()
		if(LAZYLEN(partially_understood_languages))
			mutual_languages = partially_understood_languages.Copy()
			for(var/bonus_language in LAZYACCESS(message_mods, LANGUAGE_MUTUAL_BONUS))
				mutual_languages[bonus_language] = max(message_mods[LANGUAGE_MUTUAL_BONUS][bonus_language], mutual_languages[bonus_language])

		raw_message = dialect.scramble_paragraph(raw_message, mutual_languages)

	return raw_message

/atom/movable/proc/colorize_name(atom/movable/speaker, speaker_name)
	if(!speaker)
		return speaker_name

	if(!speaker.chat_color || speaker.chat_color_name != speaker.name)
		var/list/components = generate_color_components(speaker_name)
		speaker.chat_color = rgb(components[1], components[2], components[3])
		speaker.chat_color_darkened = rgb(
			max(components[1] - 23, 0),
			max(components[2] - 23, 0),
			max(components[3] - 23, 0)
		)
		speaker.chat_color_name = speaker.name

	return "<span style='color:[speaker.chat_color];'>[speaker_name]</span>"

/atom/movable/proc/generate_color_components(name)
	var/step = round(length_char(name) / 3)
	var/list/components = list(0, 0, 0)

	for(var/i in 1 to 3)
		var/char_code = text2ascii_char(name, step * i)
		components[i] = normalize_char_code(char_code)

	return components

/proc/normalize_char_code(char_code)
	if(char_code > 1071)
		char_code -= 1072
	else if(char_code > 1039)
		char_code -= 1040
	else if(char_code > 96)
		char_code -= 97
	else if(char_code > 64)
		char_code -= 65
	else if(char_code > 31)
		char_code -= 32

	return char_code * 4 + 63

/proc/get_radio_span(freq)
	return SSradio.frequency_span_class(freq)

/proc/get_radio_name(freq, freq_name)
	if(freq_name)
		return freq_name
	return get_frequency_name(freq)

/proc/get_radio_color(freq, freq_color)
	return freq_color

/proc/attach_spans(input, list/spans)
	if(!length(spans))
		return input
	return "[message_spans_start(spans)][input]</span>"

/proc/message_spans_start(list/spans)
	var/output = "<span class='"
	for(var/span in spans)
		output = "[output][span] "
	output = "[output]'>"
	return output

/proc/say_test(text)
	var/ending = copytext_char(text, -1)
	if(ending == "?")
		return "1"
	else if(ending == "!")
		return "2"
	return "0"

/atom/movable/proc/GetJob()
	return

/atom/movable/proc/GetSource()
	return

/atom/movable/proc/GetRadio()
	return

/atom/movable/virtualspeaker
	var/job
	var/atom/movable/source
	var/obj/item/radio/radio
	var/atom/follow_target
	var/check_name

INITIALIZE_IMMEDIATE(/atom/movable/virtualspeaker)

/atom/movable/virtualspeaker/Initialize(mapload, atom/movable/speaker, radio, name_override, job_override, follow_target)
	. = ..()
	src.radio = radio
	src.follow_target = follow_target
	source = speaker
	name = name_override || speaker?.GetVoice() || name
	if(istype(speaker))
		gender = speaker.gender
		verb_say = speaker.get_default_say_verb()
		verb_ask = speaker.verb_ask
		verb_exclaim = speaker.verb_exclaim
		verb_yell = speaker.verb_yell
		tts_seed = speaker.tts_seed
	job = job_override

/atom/movable/virtualspeaker/Destroy(force)
	source = null
	radio = null
	follow_target = null
	return ..()

/atom/movable/virtualspeaker/GetJob()
	return job

/atom/movable/virtualspeaker/GetSource()
	return source

/atom/movable/virtualspeaker/GetRadio()
	return radio

/atom/movable/virtualspeaker/GetVoice()
	return name
