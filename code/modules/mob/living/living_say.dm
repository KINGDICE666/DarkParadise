GLOBAL_LIST_INIT(department_radio_keys, list(
/*
	Busy letters for language:
	a b d f g j k o q v x y
	aa as bo db fa fm fn fs vu

	Busy symbols for language:
	0 1 2 3 4 5 6 7 8 9
	% ? ^

	Busy letters by radio(eng):
	c e h i l m n p r s t u w x z

	Busy letters by radio(rus):
	б г д е ё з к р с т у ц ч ш ы ь я э

	Busy symbols by radio:
	~ , $ _ - + *

	CAUTION!	The key must not repeat the key of the languages (language.dm)
				and must not contain prohibited characters!
*/
	// English text lowercase
	":r" = R_EAR_MODE,				"#r" = R_EAR_MODE,				"№r" = R_EAR_MODE,				".r" = R_EAR_MODE,
	":l" = L_EAR_MODE,				"#l" = L_EAR_MODE,				"№l" = L_EAR_MODE,				".l" = L_EAR_MODE,
	":i" = INTERCOM_MODE,				"#i" = INTERCOM_MODE,			"№i" = INTERCOM_MODE,			".i" = INTERCOM_MODE,
	":h" = DEPARTMENT_FREQ_NAME,		"#h" = DEPARTMENT_FREQ_NAME,	"№h" = DEPARTMENT_FREQ_NAME,	".h" = DEPARTMENT_FREQ_NAME,
	":c" = COMM_FREQ_NAME,			"#c" = COMM_FREQ_NAME,			"№c" = COMM_FREQ_NAME,			".c" = COMM_FREQ_NAME,
	":n" = SCI_FREQ_NAME,				"#n" = SCI_FREQ_NAME,			"№n" = SCI_FREQ_NAME,			".n" = SCI_FREQ_NAME,
	":m" = MED_FREQ_NAME,				"#m" = MED_FREQ_NAME,			"№m" = MED_FREQ_NAME,			".m" = MED_FREQ_NAME,
	":x" = PROC_FREQ_NAME,			"#x" = PROC_FREQ_NAME,			"№x" = PROC_FREQ_NAME,			".x" = PROC_FREQ_NAME,
	":e" = ENG_FREQ_NAME,			"#e" = ENG_FREQ_NAME,			"№e" = ENG_FREQ_NAME,			".e" = ENG_FREQ_NAME,
	":s" = SEC_FREQ_NAME,				"#s" = SEC_FREQ_NAME,			"№s" = SEC_FREQ_NAME,			".s" = SEC_FREQ_NAME,
	":w" = WHISPER_CHANNEL,			"#w" = WHISPER_CHANNEL,			"№w" = WHISPER_CHANNEL,			".w" = WHISPER_CHANNEL,
	":t" = SYND_FREQ_NAME,			"#t" = SYND_FREQ_NAME,			"№t" = SYND_FREQ_NAME,			".t" = SYND_FREQ_NAME,
	":'" = SOV_FREQ_NAME,				"#'" = SOV_FREQ_NAME,			"№'" = SOV_FREQ_NAME,			".'" = SOV_FREQ_NAME,
	":u" = SUP_FREQ_NAME,				"#u" = SUP_FREQ_NAME,			"№u" = SUP_FREQ_NAME,			".u" = SUP_FREQ_NAME,
	":z" = SRV_FREQ_NAME,				"#z" = SRV_FREQ_NAME,			"№z" = SRV_FREQ_NAME,			".z" = SRV_FREQ_NAME,
	":p" = AI_FREQ_NAME,				"#p" = AI_FREQ_NAME,			"№p" = AI_FREQ_NAME,			".p" = AI_FREQ_NAME,
	":e1" = EVENT_ALPHA_FREQ_NAME,		"#e1" = EVENT_ALPHA_FREQ_NAME,	"№e1" = EVENT_ALPHA_FREQ_NAME,	".e1" = EVENT_ALPHA_FREQ_NAME,
	":e2" = EVENT_BETA_FREQ_NAME,		"#e2" = EVENT_BETA_FREQ_NAME,	"№e2" = EVENT_BETA_FREQ_NAME,	".e2" = EVENT_BETA_FREQ_NAME,
	":e3" = EVENT_GAMMA_FREQ_NAME,		"#e3" = EVENT_GAMMA_FREQ_NAME,	"№e3" = EVENT_GAMMA_FREQ_NAME,	".e3" = EVENT_GAMMA_FREQ_NAME,

	// English text uppercase
	":R" = R_EAR_MODE,				"#R" = R_EAR_MODE,				"№R" = R_EAR_MODE,				".R" = R_EAR_MODE,
	":L" = L_EAR_MODE,				"#L" = L_EAR_MODE,				"№L" = L_EAR_MODE,				".L" = L_EAR_MODE,
	":I" = INTERCOM_MODE,				"#I" = INTERCOM_MODE,			"№I" = INTERCOM_MODE,			".I" = INTERCOM_MODE,
	":H" = DEPARTMENT_FREQ_NAME,		"#H" = DEPARTMENT_FREQ_NAME,	"№H" = DEPARTMENT_FREQ_NAME,	".H" = DEPARTMENT_FREQ_NAME,
	":C" = COMM_FREQ_NAME,			"#C" = COMM_FREQ_NAME,			"№C" = COMM_FREQ_NAME,			".C" = COMM_FREQ_NAME,
	":N" = SCI_FREQ_NAME,				"#N" = SCI_FREQ_NAME,			"№N" = SCI_FREQ_NAME,			".N" = SCI_FREQ_NAME,
	":M" = MED_FREQ_NAME,				"#M" = MED_FREQ_NAME,			"№M" = MED_FREQ_NAME,			".M" = MED_FREQ_NAME,
	":X" = PROC_FREQ_NAME,			"#X" = PROC_FREQ_NAME,			"№X" = PROC_FREQ_NAME,			".X" = PROC_FREQ_NAME,
	":E" = ENG_FREQ_NAME,				"#E" = ENG_FREQ_NAME,			"№E" = ENG_FREQ_NAME,			".E" = ENG_FREQ_NAME,
	":S" = SEC_FREQ_NAME,				"#S" = SEC_FREQ_NAME,			"№S" = SEC_FREQ_NAME,			".S" = SEC_FREQ_NAME,
	":W" = WHISPER_CHANNEL,			"#W" = WHISPER_CHANNEL,			"№W" = WHISPER_CHANNEL,			".W" = WHISPER_CHANNEL,
	":T" = SYND_FREQ_NAME,			"#T" = SYND_FREQ_NAME,			"№T" = SYND_FREQ_NAME,			".T" = SYND_FREQ_NAME,
	":'" = SOV_FREQ_NAME,				"#'" = SOV_FREQ_NAME,			"№'" = SOV_FREQ_NAME,			".'" = SOV_FREQ_NAME,
	":U" = SUP_FREQ_NAME,				"#U" = SUP_FREQ_NAME,			"№U" = SUP_FREQ_NAME,			".U" = SUP_FREQ_NAME,
	":Z" = SRV_FREQ_NAME,				"#Z" = SRV_FREQ_NAME,			"№Z" = SRV_FREQ_NAME,			".Z" = SRV_FREQ_NAME,
	":P" = AI_FREQ_NAME,				"#P" = AI_FREQ_NAME,			"№P" = AI_FREQ_NAME,			".P" = AI_FREQ_NAME,
	":." = PRS_FREQ_NAME,				"#." = PRS_FREQ_NAME,			"№." = PRS_FREQ_NAME,			".." = PRS_FREQ_NAME,
	":E1" = EVENT_ALPHA_FREQ_NAME,		"#E1" = EVENT_ALPHA_FREQ_NAME,	"№E1" = EVENT_ALPHA_FREQ_NAME,	".E1" = EVENT_ALPHA_FREQ_NAME,
	":E2" = EVENT_BETA_FREQ_NAME,		"#E2" = EVENT_BETA_FREQ_NAME,	"№E2" = EVENT_BETA_FREQ_NAME,	".E2" = EVENT_BETA_FREQ_NAME,
	":E3" = EVENT_GAMMA_FREQ_NAME,		"#E3" = EVENT_GAMMA_FREQ_NAME,	"№E3" = EVENT_GAMMA_FREQ_NAME,	".E3" = EVENT_GAMMA_FREQ_NAME,

	// Russian text lowercase
	":к" = R_EAR_MODE,				"#к" = R_EAR_MODE,				"№к" = R_EAR_MODE,				".к" = R_EAR_MODE,
	":д" = L_EAR_MODE,				"#д" = L_EAR_MODE,				"№д" = L_EAR_MODE,				".д" = L_EAR_MODE,
	":ш" = INTERCOM_MODE,				"#ш" = INTERCOM_MODE,			"№ш" = INTERCOM_MODE,			".ш" = INTERCOM_MODE,
	":р" = DEPARTMENT_FREQ_NAME,		"#р" = DEPARTMENT_FREQ_NAME,	"№р" = DEPARTMENT_FREQ_NAME,	".р" = DEPARTMENT_FREQ_NAME,
	":с" = COMM_FREQ_NAME,			"#с" = COMM_FREQ_NAME,			"№с" = COMM_FREQ_NAME,			".с" = COMM_FREQ_NAME,
	":т" = SCI_FREQ_NAME,				"#т" = SCI_FREQ_NAME,			"№т" = SCI_FREQ_NAME,			".т" = SCI_FREQ_NAME,
	":ь" = MED_FREQ_NAME,				"#ь" = MED_FREQ_NAME,			"№ь" = MED_FREQ_NAME,			".ь" = MED_FREQ_NAME,
	":ч" = PROC_FREQ_NAME,			"#ч" = PROC_FREQ_NAME,			"№ч" = PROC_FREQ_NAME,			".ч" = PROC_FREQ_NAME,
	":у" = ENG_FREQ_NAME,			"#у" = ENG_FREQ_NAME,			"№у" = ENG_FREQ_NAME,			".у" = ENG_FREQ_NAME,
	":ы" = SEC_FREQ_NAME,				"#ы" = SEC_FREQ_NAME,			"№ы" = SEC_FREQ_NAME,			".ы" = SEC_FREQ_NAME,
	":ц" = WHISPER_CHANNEL,			"#ц" = WHISPER_CHANNEL,			"№ц" = WHISPER_CHANNEL,			".ц" = WHISPER_CHANNEL,
	":е" = SYND_FREQ_NAME,			"#е" = SYND_FREQ_NAME,			"№е" = SYND_FREQ_NAME,			".е" = SYND_FREQ_NAME,
	":э" = SOV_FREQ_NAME,				"#э" = SOV_FREQ_NAME,			"№э" = SOV_FREQ_NAME,			".э" = SOV_FREQ_NAME,
	":б" = SYND_TAIPAN_FREQ_NAME,		"#б" = SYND_TAIPAN_FREQ_NAME,	"№б" = SYND_TAIPAN_FREQ_NAME,	".б" = SYND_TAIPAN_FREQ_NAME,
	":г" = SUP_FREQ_NAME,				"#г" = SUP_FREQ_NAME,			"№г" = SUP_FREQ_NAME,			".г" = SUP_FREQ_NAME,
	":я" = SRV_FREQ_NAME,				"#я" = SRV_FREQ_NAME,			"№я" = SRV_FREQ_NAME,			".я" = SRV_FREQ_NAME,
	":з" = AI_FREQ_NAME,				"#з" = AI_FREQ_NAME,			"№з" = AI_FREQ_NAME,			".з" = AI_FREQ_NAME,
	":ё" = CORDS_MODE,				"#ё" = CORDS_MODE,				"№ё" = CORDS_MODE,				".ё" = CORDS_MODE,
	":ю" = PRS_FREQ_NAME,				"#ю" = PRS_FREQ_NAME,			"№ю" = PRS_FREQ_NAME,			".ю" = PRS_FREQ_NAME,
	":у1" = EVENT_ALPHA_FREQ_NAME,		"#у1" = EVENT_ALPHA_FREQ_NAME,	"№у1" = EVENT_ALPHA_FREQ_NAME,	".у1" = EVENT_ALPHA_FREQ_NAME,
	":у2" = EVENT_BETA_FREQ_NAME,		"#у2" = EVENT_BETA_FREQ_NAME,	"№у2" = EVENT_BETA_FREQ_NAME,	".у2" = EVENT_BETA_FREQ_NAME,
	":у3" = EVENT_GAMMA_FREQ_NAME,		"#у3" = EVENT_GAMMA_FREQ_NAME,	"№у3" = EVENT_GAMMA_FREQ_NAME,	".у3" = EVENT_GAMMA_FREQ_NAME,

	// Russian text uppercase
	":К" = R_EAR_MODE,				"#К" = R_EAR_MODE,				"№К" = R_EAR_MODE,				".К" = R_EAR_MODE,
	":Д" = L_EAR_MODE,				"#Д" = L_EAR_MODE,				"№Д" = L_EAR_MODE,				".Д" = L_EAR_MODE,
	":Ш" = INTERCOM_MODE,				"#Ш" = INTERCOM_MODE,			"№Ш" = INTERCOM_MODE,			".Ш" = INTERCOM_MODE,
	":Р" = DEPARTMENT_FREQ_NAME,		"#Р" = DEPARTMENT_FREQ_NAME,	"№Р" = DEPARTMENT_FREQ_NAME,	".Р" = DEPARTMENT_FREQ_NAME,
	":С" = COMM_FREQ_NAME,			"#С" = COMM_FREQ_NAME,			"№С" = COMM_FREQ_NAME,			".С" = COMM_FREQ_NAME,
	":Т" = SCI_FREQ_NAME,				"#Т" = SCI_FREQ_NAME,			"№Т" = SCI_FREQ_NAME,			".Т" = SCI_FREQ_NAME,
	":Ь" = MED_FREQ_NAME,				"#Ь" = MED_FREQ_NAME,			"№Ь" = MED_FREQ_NAME,			".Ь" = MED_FREQ_NAME,
	":У" = ENG_FREQ_NAME,				"#У" = ENG_FREQ_NAME,			"№У" = ENG_FREQ_NAME,			".У" = ENG_FREQ_NAME,
	":Ы" = SEC_FREQ_NAME,				"#Ы" = SEC_FREQ_NAME,			"№Ы" = SEC_FREQ_NAME,			".Ы" = SEC_FREQ_NAME,
	":Ц" = WHISPER_CHANNEL,			"#Ц" = WHISPER_CHANNEL,			"№Ц" = WHISPER_CHANNEL,			".Ц" = WHISPER_CHANNEL,
	":Е" = SYND_FREQ_NAME,			"#Е" = SYND_FREQ_NAME,			"№Е" = SYND_FREQ_NAME,			".Е" = SYND_FREQ_NAME,
	":Э" = SOV_FREQ_NAME,				"#Э" = SOV_FREQ_NAME,			"№Э" = SOV_FREQ_NAME,			".Э" = SOV_FREQ_NAME,
	":Б" = SYND_TAIPAN_FREQ_NAME,		"#Б" = SYND_TAIPAN_FREQ_NAME,	"№Б" = SYND_TAIPAN_FREQ_NAME,	".Б" = SYND_TAIPAN_FREQ_NAME,
	":Г" = SUP_FREQ_NAME,				"#Г" = SUP_FREQ_NAME,			"№Г" = SUP_FREQ_NAME,			".Г" = SUP_FREQ_NAME,
	":Я" = SRV_FREQ_NAME,				"#Я" = SRV_FREQ_NAME,			"№Я" = SRV_FREQ_NAME,			".Я" = SRV_FREQ_NAME,
	":З" = AI_FREQ_NAME,				"#З" = AI_FREQ_NAME,			"№З" = AI_FREQ_NAME,			".З" = AI_FREQ_NAME,
	":Ё" = CORDS_MODE,				"#Ё" = CORDS_MODE,				"№Ё" = CORDS_MODE,				".Ё" = CORDS_MODE,
	":Ю" = PRS_FREQ_NAME,				"#Ю" = PRS_FREQ_NAME,			"№Ю" = PRS_FREQ_NAME,			".Ю" = PRS_FREQ_NAME,
	":У1" = EVENT_ALPHA_FREQ_NAME,		"#У1" = EVENT_ALPHA_FREQ_NAME,	"№У1" = EVENT_ALPHA_FREQ_NAME,	".У1" = EVENT_ALPHA_FREQ_NAME,
	":У2" = EVENT_BETA_FREQ_NAME,		"#У2" = EVENT_BETA_FREQ_NAME,	"№У2" = EVENT_BETA_FREQ_NAME,	".У2" = EVENT_BETA_FREQ_NAME,
	":У3" = EVENT_GAMMA_FREQ_NAME,		"#У3" = EVENT_GAMMA_FREQ_NAME,	"№У3" = EVENT_GAMMA_FREQ_NAME,	".У3" = EVENT_GAMMA_FREQ_NAME,

	// English symbols no case
	":~" = CORDS_MODE,				"#~" = CORDS_MODE,				"№~" = CORDS_MODE,				".~" = CORDS_MODE,
	":," = SYND_TAIPAN_FREQ_NAME,		"#," = SYND_TAIPAN_FREQ_NAME,	"№," = SYND_TAIPAN_FREQ_NAME,	".," = SYND_TAIPAN_FREQ_NAME,
	// Russian symbols no case
		// None yet.

	// Special symbols only (that means that they don't have/use an english/russian analogue)
	":*" = NINJA_FREQ_NAME,			"#*" = NINJA_FREQ_NAME,			"№*" = NINJA_FREQ_NAME,			".*" = NINJA_FREQ_NAME,
	":$" = ERT_FREQ_NAME,				"#$" = ERT_FREQ_NAME,			"№$" = ERT_FREQ_NAME,			".$" = ERT_FREQ_NAME,
	":_" = SYNDTEAM_FREQ_NAME,		"#_" = SYNDTEAM_FREQ_NAME,		"№_" = SYNDTEAM_FREQ_NAME,		"._" = SYNDTEAM_FREQ_NAME,
	":-" = DTH_FREQ_NAME,				"#-" = DTH_FREQ_NAME,			"№-" = DTH_FREQ_NAME,			".-" = DTH_FREQ_NAME,
	":vr" = VOX_RAID_FREQ_NAME,		"#vr" = VOX_RAID_FREQ_NAME,		".vr" = VOX_RAID_FREQ_NAME,		":мк" = VOX_RAID_FREQ_NAME,
	"#мк" = VOX_RAID_FREQ_NAME,		".мк" = VOX_RAID_FREQ_NAME,
	":+" = SPEC_FREQ_NAME,			"#+" = SPEC_FREQ_NAME,			"№+" = SPEC_FREQ_NAME,			".+" = SPEC_FREQ_NAME //activate radio-specific special functions
))

GLOBAL_LIST_EMPTY(channel_to_radio_key)

/proc/get_radio_key_from_channel(channel)
	var/key = GLOB.channel_to_radio_key[channel]
	if(!key)
		for(var/radio_key in GLOB.department_radio_keys)
			if(GLOB.department_radio_keys[radio_key] == channel)
				key = radio_key
				break
		if(!key)
			key = ""
		GLOB.channel_to_radio_key[channel] = key

	return key


GLOBAL_LIST_INIT(say_prefixes, list(":", ".", "#", "№"))

/mob/living/proc/binarycheck()
	return FALSE

/mob/living/proc/get_default_saymode()
	return null

/mob/living/proc/handle_speech_sound()
	var/list/returns[3]
	returns[1] = null
	returns[2] = null
	returns[3] = null
	return returns

/mob/living/say(
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
	if(sanitize)
		message = trim_strip_html_properly(message, 512)
	if(!message)
		return

	var/original_message = message
	message = get_message_mods(message, message_mods)
	saymode = SSradio.get_available_say_mode(src, message_mods[RADIO_KEY])
	if(!saymode && !message_mods[RADIO_KEY] && !message_mods[RADIO_EXTENSION] && !message_mods[MODE_HEADSET] && !message_mods[LANGUAGE_EXTENSION] && !language)
		saymode = get_default_saymode()

	if(!message)
		return

	if(stat == DEAD)
		return say_dead(original_message)

	if(check_emote(original_message, forced))
		return

	if(stat)
		return FALSE

	if(!try_speak(original_message, ignore_spam, forced, filterproof))
		return FALSE

	language ||= message_mods[LANGUAGE_EXTENSION] || get_selected_language()

	if(copytext_char(message, 1, 2) == "!" && length_char(message) > 1)
		custom_emote(EMOTE_AUDIBLE, trim(copytext_char(message, 2)), TRUE)
		return TRUE

	if(!(copytext_char(message, -1) in list("!", "?", ",", ".")))
		message += "."

	var/sigreturn = SEND_SIGNAL(src, COMSIG_MOB_SAY, args)
	if(sigreturn & COMPONENT_UPPERCASE_SPEECH)
		message = uppertext(message)
	if(sigreturn & COMPONENT_SMALL_SPEECH)
		spans |= SPAN_SMALL_VOICE

	if(saymode && (saymode.handle_message(src, message, spans, language, message_mods) & SAYMODE_MESSAGE_HANDLED))
		return TRUE

	message = handle_autohiss(message, language)

	if(speech_span)
		spans |= speech_span
	var/datum/language/spoken_lang = GLOB.language_datum_instances[language]
	if(LAZYLEN(spoken_lang?.spans))
		spans |= spoken_lang.spans

	message_mods[SAY_MOD_VERB] ||= say_mod(message, message_mods, language)

	if(message_mods[RADIO_EXTENSION] == CORDS_MODE)
		message_mods -= RADIO_EXTENSION
		var/mob/living/carbon/carbon_speaker = src
		var/obj/item/organ/internal/vocal_cords/cords = iscarbon(src) ? carbon_speaker.get_int_organ(/obj/item/organ/internal/vocal_cords) : null
		if(!cords?.can_speak_with())
			return TRUE
		cords.speak_with(message)
		message = cords.handle_speech(message, spans)
		if(!message)
			return TRUE
		message_mods[MODE_IGNORE_SPEECH_PROBLEMS] = TRUE
		message_mods[MODE_IGNORE_ATMOSPHERICS] = TRUE

	if(message_mods[WHISPER_MODE] && !can_whisper())
		return FALSE

	if(!message_mods[WHISPER_MODE] && is_muzzled())
		var/obj/item/organ/internal/cyberimp/mouth/translator/translator = get_organ_slot(INTERNAL_ORGAN_SPEECH_TRANSLATOR)
		var/obj/item/clothing/mask/muzzle/muzzle = wear_mask
		if(translator)
			message_mods[WHISPER_MODE] = MODE_WHISPER
		else if(muzzle.mute == MUZZLE_MUTE_ALL)
			to_chat(src, span_danger("На вас надет намордник, и вы не можете говорить."))
			return FALSE
		else if(muzzle.mute == MUZZLE_MUTE_MUFFLE)
			message = muffledspeech(message)
			message_mods[SAY_MOD_VERB] = "бормоч[PLUR_ET_UT(src)]"

	if(is_facehugged())
		message = muffledspeech(message)
		message_mods[SAY_MOD_VERB] = "булька[PLUR_ET_YUT(src)]"

	if(!wear_mask && pulledby && pulledby.grab_state > GRAB_PASSIVE && pulledby.zone_selected == BODY_ZONE_PRECISE_MOUTH)
		message = muffledspeech(message)
		message_mods[SAY_MOD_VERB] = "бормоч[PLUR_ET_UT(src)]"

	if(!message_mods[MODE_IGNORE_SPEECH_PROBLEMS] && !(spoken_lang?.flags & LANGUAGE_NO_STUTTER))
		message = treat_message(message, message_mods, spans, language)

	if(!message)
		return FALSE

	if(!message_mods[WHISPER_MODE] && cannot_speak_loudly())
		message_mods[WHISPER_MODE] = MODE_WHISPER

	if(message_mods[WHISPER_MODE])
		message_range = WHISPER_RANGE
		spans |= SPAN_ITALICS
		message_mods[SAY_MOD_VERB] = say_mod(message, message_mods, language)
		log_whisper(message, src)
	else
		add_say_logs(src, "'[message]'", null, message_mods[RADIO_EXTENSION] || (message_mods[MODE_HEADSET] ? HEADSET_MODE : null))

	var/radio_return = radio(message, message_mods, spans, language)
	if(radio_return & NOPASS)
		return TRUE
	if(radio_return & ITALICS)
		spans |= SPAN_ITALICS
	if(radio_return & REDUCE_RANGE)
		message_range = (copytext_char(message, -1) == "!") ? 2 : 1

	var/turf/speaker_turf = get_turf(src)
	if(speaker_turf && !message_mods[MODE_IGNORE_ATMOSPHERICS])
		var/datum/gas_mixture/environment = speaker_turf.get_readonly_air()
		var/pressure = environment ? environment.return_pressure() : 0
		if(pressure < SOUND_MINIMUM_PRESSURE)
			message_range = 1
		if(pressure < ONE_ATMOSPHERE * 0.4)
			spans |= SPAN_ITALICS

	send_speech(message, message_range, get_whisper_loc(), bubble_type, spans, language, message_mods, forced = forced)

	var/list/speech_sound = handle_speech_sound()
	if(speech_sound[1])
		playsound(src, speech_sound[1], (radio_return & REDUCE_RANGE) ? speech_sound[2] * 0.5 : speech_sound[2], TRUE, frequency = speech_sound[3])

	return TRUE

/mob/living/proc/can_whisper()
	var/obj/item/organ/internal/cyberimp/mouth/translator/translator = get_organ_slot(INTERNAL_ORGAN_SPEECH_TRANSLATOR)
	if(is_muzzled() && !translator?.active)
		if(istype(wear_mask, /obj/item/clothing/mask/muzzle/tapegag))
			to_chat(src, span_danger("Ваш рот заклеен скотчем, и вы не можете говорить!"))
		else
			to_chat(src, span_danger("На вас надет намордник, и вы не можете говорить."))
		return FALSE

	if(is_facehugged())
		to_chat(src, span_danger("Вы не можете вымолвить ни слова с этим ужасным существом на лице!"))
		return FALSE

	return TRUE

/mob/living/try_speak(message, ignore_spam = FALSE, forced = null, filterproof = FALSE)
	if(client && !forced)
		client.check_say_flood(5)
		if(check_mute(client.account_ckey, MUTE_IC))
			to_chat(src, span_boldwarning("Вы не можете отправлять IC сообщения (мут)."))
			return FALSE

	if(SEND_SIGNAL(src, COMSIG_MOB_TRY_SPEECH, message, ignore_spam, forced) & COMPONENT_CANNOT_SPEAK)
		return FALSE

	return TRUE

/mob/living/proc/treat_message(message, list/message_mods, list/spans, datum/language/language)
	var/robot = ismachineperson(src)

	if(HAS_TRAIT(src, TRAIT_HULK) && health >= 25)
		message = "[uppertext(message)]!!!"
		message_mods[SAY_MOD_VERB] = pick("крич[PLUR_IT_AT(src)]", "рыч[PLUR_IT_AT(src)]", "воп[PLUR_IT_YAT(src)]")

	if(AmountSluring())
		if(robot)
			message = slur(message, list("@", "!", "#", "$", "%", "&", "?"))
		else
			message = slur(message)
		message_mods[SAY_MOD_VERB] = "бормоч[PLUR_ET_UT(src)]"

	if(AmountStuttering())
		if(robot)
			message = robostutter(message)
		else
			message = stutter(message)
		message_mods[SAY_MOD_VERB] = "заика[PLUR_ET_YUT(src)]ся"

	if(HAS_TRAIT(src, TRAIT_UNINTELLIGIBLE_SPEECH))
		message = unintelligize(message)

	if(AmountCultSlurring())
		message = cultslur(message)
		message_mods[SAY_MOD_VERB] = "бормоч[PLUR_ET_UT(src)]"

	if(AmountClockSlurring())
		message = clockslur(message)
		message_mods[SAY_MOD_VERB] = "бормоч[PLUR_ET_UT(src)]"

	if(!IsVocal())
		return ""

	return message

/mob/living/proc/radio(message, list/message_mods = list(), list/spans, language)
	return NONE

/mob/living/proc/announce_radio_use(obj/item/radio_device, list/message_mods)
	if(!client)
		return
	var/static/list/special_radio_channels = list(SYND_FREQ_NAME, SYNDTEAM_FREQ_NAME, SEC_FREQ_NAME, PROC_FREQ_NAME, COMM_FREQ_NAME, ERT_FREQ_NAME, DTH_FREQ_NAME, NINJA_FREQ_NAME, SYND_TAIPAN_FREQ_NAME, SOV_FREQ_NAME)
	var/radio_sound = (message_mods[RADIO_EXTENSION] in special_radio_channels) ? 'sound/items/radio_security.ogg' : 'sound/items/radio_common.ogg'
	SEND_SOUND(src, sound(radio_sound, volume = rand(4, 16) * 5 * client.prefs.get_channel_volume(CHANNEL_RADIO_NOISE), channel = CHANNEL_RADIO_NOISE))
	var/notice = span_notice("[src] говор[PLUR_IT_YAT(src)] в [radio_device.declent_ru(ACCUSATIVE)]")
	for(var/mob/living/nearby in hearers(5, src) - src)
		nearby.show_message(notice)

/mob/living/say_mod(input, list/message_mods = list(), datum/language/language)
	var/datum/language/dialect = GLOB.language_datum_instances[language]
	if(message_mods[WHISPER_MODE])
		if(LAZYLEN(dialect?.whisper_verbs))
			return pick(dialect.whisper_verbs)
		var/adverb = pick("еле слышно", "едва слышно", "тихо", "очень тихо", "негромко")
		if(LAZYLEN(dialect?.speech_verbs))
			return "[adverb] [pick(dialect.speech_verbs)]"
		return "[adverb] [verb_say]"
	if(dialect)
		return dialect.get_spoken_verb(copytext_char(input, -1))
	return ..()

/mob/living/whisper(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language, ignore_spam = FALSE, forced, filterproof)
	if(!message)
		return
	say(message, bubble_type, spans, sanitize, language, ignore_spam, forced, filterproof, message_mods = list(WHISPER_MODE = MODE_WHISPER))

/mob/living/proc/get_whisper_loc()
	if(istype(loc, /obj/item/holder))
		return get_atom_on_turf(src)
	return src

/mob/living/send_speech(message, message_range = 6, obj/source = src, bubble_type = bubble_icon, list/spans, datum/language/message_language = null, list/message_mods = list(), forced = null)
	var/whisper_range = message_mods[WHISPER_MODE] ? MESSAGE_RANGE - WHISPER_RANGE : 0
	var/list/listening = get_hearers_in_view(message_range + whisper_range, source)

	if(client)
		for(var/mob/player_mob as anything in GLOB.player_list)
			if(QDELETED(player_mob) || !isobserver(player_mob))
				continue
			if(player_mob.get_preference(PREFTOGGLE_CHAT_GHOSTEARS) || (player_mob.z == z && get_dist(player_mob, src) <= world.view))
				listening |= player_mob

	var/turf/source_turf = get_turf(source)
	var/list/speech_bubble_recipients = list()
	for(var/atom/movable/listening_movable as anything in listening)
		if(!listening_movable)
			stack_trace("somehow theres a null returned from get_hearers_in_view() in send_speech!")
			continue
		if(whisper_range && !ismob(listening_movable) && get_dist(source_turf, get_turf(listening_movable)) > message_range)
			continue
		if(!(listening_movable.Hear(src, message_language, message, null, null, null, spans, message_mods, message_range) & HEAR_HEARD))
			continue
		var/mob/listening_mob = listening_movable
		if(ismob(listening_mob) && listening_mob.client)
			speech_bubble_recipients += listening_mob.client

	if(!length(speech_bubble_recipients))
		return
	var/talk_icon_state = "[bubble_type || bubble_icon][say_test(message)]"
	if(loc && !isturf(loc))
		var/atom/container = loc
		container.speech_bubble("[container.bubble_icon][say_test(message)]", container, speech_bubble_recipients)
		return
	speech_bubble(talk_icon_state, src, speech_bubble_recipients)

/mob/living/speech_bubble(bubble_state = "", bubble_loc = src, list/bubble_recipients = list())
	var/image/I = image('icons/mob/talk.dmi', bubble_loc, bubble_state, FLY_LAYER)
	SET_PLANE_EXPLICIT(I, ABOVE_GAME_PLANE, src)
	I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay), I, bubble_recipients, 3 SECONDS)
