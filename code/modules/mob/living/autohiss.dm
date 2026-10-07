/mob/proc/handle_autohiss(message, datum/language/L)
	return message // no autohiss at this level

/mob/living/carbon/human/handle_autohiss(message, datum/language/L)
	if(!client || client.prefs.read_preference(/datum/preference/choiced/autohiss) == AUTOHISS_OFF) // no need to process if there's no client or they have autohiss off
		return message
	return dna.species.handle_autohiss(message, L, client.prefs.read_preference(/datum/preference/choiced/autohiss))

GAME_VERB_DESC(/client, toggle_autohiss, "Авто-акцент", "Переключает автоматический акцент вашей расы при общении.", VERB_CATEGORY_OOC)

	var/datum/preference/choiced/autohiss/autohiss = GLOB.preference_entries[/datum/preference/choiced/autohiss]
	prefs.write_preference(autohiss, (prefs.read_preference(/datum/preference/choiced/autohiss) + 1) % AUTOHISS_NUM)
	switch(prefs.read_preference(/datum/preference/choiced/autohiss))
		if(AUTOHISS_OFF)
			to_chat(src, "Авто-акцент: Выключен.")
		if(AUTOHISS_BASIC)
			to_chat(src, "Авто-акцент: Базовый.")
		if(AUTOHISS_FULL)
			to_chat(src, "Авто-акцент: Полный.")
		else
			prefs.write_preference(autohiss, AUTOHISS_OFF)
			to_chat(src, "Авто-акцент: Выключен.")

/datum/species/proc/handle_autohiss(message, datum/language/lang, mode)
	if(!autohiss_basic_map)
		return message
	if(autohiss_exempt && (lang && (lang.name in autohiss_exempt)))
		return message

	var/map = autohiss_basic_map.Copy()
	if(mode == AUTOHISS_FULL && autohiss_extra_map)
		map |= autohiss_extra_map

	. = list()

	while(length_char(message))
		var/min_index = 10000 // if the message is longer than this, the autohiss is the least of your problems
		var/min_char = null
		for(var/char in map)
			var/i = findtext_char(message, char)
			if(!i) // no more of this character anywhere in the string, don't even bother searching next time
				map -= char
			else if(i < min_index)
				min_index = i
				min_char = char
		if(!min_char) // we didn't find any of the mapping characters
			. += message
			break
		. += copytext_char(message, 1, min_index)
		if(copytext_char(message, min_index, min_index+1) == uppertext(min_char))
			. += capitalize(pick(map[min_char]))
		else
			. += pick(map[min_char])
		message = copytext_char(message, min_index + 1)

	return jointext(., "")

#undef AUTOHISS_OFF
#undef AUTOHISS_BASIC
#undef AUTOHISS_FULL
#undef AUTOHISS_NUM
