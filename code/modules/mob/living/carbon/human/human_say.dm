/mob/living/carbon/human/GetAltName()
	if(name != GetVoice())
		return " (как [get_id_name(UNKNOWN_NAME_RUS)])"
	return ..()

/mob/living/carbon/human/proc/HasVoiceChanger()
	for(var/obj/item/gear in list(wear_mask, wear_suit, head))
		if(!gear)
			continue

		var/obj/item/voice_changer/changer = locate() in gear
		if(changer?.active)
			if(changer.voice)
				return changer.voice
			else if(wear_id)
				var/obj/item/card/id/idcard = wear_id.GetID()
				if(istype(idcard))
					return idcard.registered_name

	return FALSE

/mob/living/carbon/human/proc/HasTTSVoiceChanger()
	for(var/obj/item/gear in list(wear_mask, wear_suit, head))
		if(!gear)
			continue

		var/obj/item/voice_changer/changer = locate() in gear
		if(changer?.active && changer.tts_voice)
			return changer.tts_voice

	return FALSE

/mob/living/carbon/human/GetVoice()
	var/has_changer = HasVoiceChanger()

	if(has_changer)
		return has_changer

	var/datum/antagonist/changeling/cling = mind?.has_antag_datum(/datum/antagonist/changeling)
	if(cling?.mimicking)
		return cling.mimicking

	if(GetSpecialVoice())
		return GetSpecialVoice()

	if(HAS_TRAIT(src, TRAIT_UNKNOWN_VOICE))
		return UNKNOWN_NAME_RUS

	return real_name

/mob/living/carbon/human/GetTTSVoice()
	var/has_changer_tts = HasTTSVoiceChanger()

	if(has_changer_tts)
		return has_changer_tts

	var/datum/antagonist/changeling/cling = mind?.has_antag_datum(/datum/antagonist/changeling)
	if(cling?.tts_mimicking)
		return cling.tts_mimicking

	if(GetSpecialTTSVoice())
		return GetSpecialTTSVoice()

	return dna.tts_seed_dna

/mob/living/carbon/human/IsVocal()
	var/obj/item/organ/internal/cyberimp/mouth/translator/translator = get_organ_slot(INTERNAL_ORGAN_SPEECH_TRANSLATOR)
	if(translator?.active && !(mind && HAS_TRAIT(mind, TRAIT_MIMING)))
		return TRUE // Cyberimps don't care if you need to breathe at all, but make some respect to mimes

	if(HAS_TRAIT(src, TRAIT_MUTE))
		return FALSE

	if(TRAIT_NO_VOCAL_CORDS in dna?.species.inherent_traits)
		return FALSE

	// How do species that don't breathe talk? magic, that's what.
	var/breathes = !HAS_TRAIT(src, TRAIT_NO_BREATH)
	var/obj/item/organ/internal/lungs = get_organ_slot(INTERNAL_ORGAN_LUNGS)
	if((breathes && !lungs) || (breathes && lungs && lungs.is_dead()))
		return FALSE

	if(mind)
		return !HAS_TRAIT(mind, TRAIT_MIMING)

	return TRUE

/mob/living/carbon/human/cannot_speak_loudly()
	return ..() || getOxyLoss() > 10 || AmountLoseBreath() >= 8 SECONDS

/mob/living/carbon/human/proc/SetSpecialVoice(new_voice)
	if(new_voice)
		special_voice = new_voice

/mob/living/carbon/human/proc/UnsetSpecialVoice()
	special_voice = ""

/mob/living/carbon/human/proc/GetSpecialVoice()
	return special_voice

/mob/living/carbon/human/proc/SetSpecialTTSVoice(new_voice)
	if(new_voice)
		special_tts_voice = new_voice

/mob/living/carbon/human/proc/UnsetSpecialTTSVoice()
	special_tts_voice = ""

/mob/living/carbon/human/proc/GetSpecialTTSVoice()
	return special_tts_voice

/mob/living/carbon/human/treat_message(message, list/message_mods, list/spans, datum/language/language)
	var/check_mute = TRUE
	var/check_wingdings = TRUE

	var/obj/item/organ/internal/cyberimp/mouth/translator/translator = get_organ_slot(INTERNAL_ORGAN_SPEECH_TRANSLATOR)
	if(translator?.active)
		check_mute = FALSE

		if(translator.can_wingdings)
			check_wingdings = FALSE

	if(HAS_TRAIT(src, TRAIT_COMIC) \
		|| (locate(/obj/item/organ/internal/cyberimp/brain/clown_voice) in internal_organs) \
		|| HAS_TRAIT(src, TRAIT_JESTER))
		spans |= SPAN_SANS

	if(check_wingdings && HAS_TRAIT(src, TRAIT_WINGDINGS))
		spans |= "wingdings"

	message = ..()

	if(check_mute && HAS_TRAIT(src, TRAIT_MUTE))
		return ""

	if(istype(wear_mask, /obj/item/clothing/mask/horsehead))
		var/obj/item/clothing/mask/horsehead/hoers = wear_mask
		if(hoers.voicechange)
			message = pick("NEEIIGGGHHHH!", "NEEEIIIIGHH!", "NEIIIGGHH!", "HAAWWWWW!", "HAAAWWW!")

	if(dna)
		for(var/datum/dna/gene/gene as anything in GLOB.dna_genes)
			if(!gene.is_active(src))
				continue
			if(!check_wingdings && istype(gene, /datum/dna/gene/disability/wingdings))
				continue
			message = gene.OnSay(src, message)

		if(check_mute && (TRAIT_NO_VOCAL_CORDS in dna.species.inherent_traits))
			return ""

	var/braindam = getBrainLoss()
	if(braindam >= 60)
		if(prob(braindam / 4))
			message = stutter(message)
			message_mods[SAY_MOD_VERB] = "бормоч[PLUR_ET_UT(src)]"

		if(prob(braindam))
			message = uppertext(message)
			message_mods[SAY_MOD_VERB] = "громко крич[PLUR_IT_AT(src)]"

	if(wear_mask)
		var/speech_verb_when_masked = wear_mask.change_speech_verb()
		if(speech_verb_when_masked)
			message_mods[SAY_MOD_VERB] = speech_verb_when_masked

	return message

/mob/living/carbon/human/radio(message, list/message_mods = list(), list/spans, language)
	. = ..()
	if(. & NOPASS)
		return .

	var/obj/item/radio/used_radio
	var/channel = message_mods[RADIO_EXTENSION]
	if(message_mods[MODE_HEADSET])
		for(var/obj/item/radio/ear_radio in list(l_ear, r_ear))
			used_radio = ear_radio
			if(ear_radio.talk_into(src, message, null, spans, language, message_mods))
				break
	else
		switch(channel)
			if(null)
				return .
			if(INTERCOM_MODE)
				for(var/obj/item/radio/intercom/intercom in view(MODE_RANGE_INTERCOM, src))
					used_radio = intercom
					intercom.talk_into(src, message, null, spans, language, message_mods)
			if(R_EAR_MODE)
				used_radio = isradio(r_hand) ? r_hand : (isradio(r_ear) ? r_ear : null)
				used_radio?.talk_into(src, message, null, spans, language, message_mods)
			if(L_EAR_MODE)
				used_radio = isradio(l_hand) ? l_hand : (isradio(l_ear) ? l_ear : null)
				used_radio?.talk_into(src, message, null, spans, language, message_mods)
			else
				for(var/obj/item/radio/ear_radio in list(l_ear, r_ear))
					used_radio = ear_radio
					if(ear_radio.talk_into(src, message, channel, spans, language, message_mods))
						break

	if(!used_radio)
		return .
	announce_radio_use(used_radio, message_mods)
	return . | ITALICS | REDUCE_RANGE

/mob/living/carbon/human/get_default_saymode()
	if(dna?.species?.default_saymode)
		return SSradio.get_say_mode(dna.species.default_saymode)
	return ..()

/mob/living/carbon/human/handle_speech_sound()
	var/list/returns[3]
	if(dna.species.speech_sounds && prob(dna.species.speech_chance))
		returns[1] = sound(pick(dna.species.speech_sounds))
		returns[2] = 50
		returns[3] = get_age_pitch()
	return returns

/mob/living/carbon/human/binarycheck()
	. = FALSE
	var/obj/item/radio/headset/R
	if(istype(l_ear, /obj/item/radio/headset))
		R = l_ear
		if(R.translate_binary)
			. = TRUE

	if(istype(r_ear, /obj/item/radio/headset))
		R = r_ear
		if(R.translate_binary)
			. = TRUE
