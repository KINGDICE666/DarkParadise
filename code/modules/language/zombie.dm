/datum/language/zombie
	name = "Зомби"
	desc = "Стонущий язык жаждущих плоти зомби. Мозгииии..."
	speech_verbs = list("стон%(ет,ут)%")
	ask_verbs = list("стон%(ет,ут)%")
	exclaim_verbs = list("воп%(ит,ят)%")
	key = "zm"
	flags = LANGUAGE_RESTRICTED | LANGUAGE_NOBABEL
	spans = list("zombie")
	syllables = list("Мозги", "Мозгиии", "Плоть", "Грр", "Хнн", "Мооозги", "Мозгиииии")
	icon_state = "aphasia"
	default_priority = 100

/datum/language/zombie/scramble_sentence(input, list/mutual_languages)
	var/terminator = "..."
	if(!length(input))
		return "[pick(syllables)][terminator]"

	var/last_letter = copytext_char(input, -1)
	if(last_letter in list("?", "!"))
		terminator = last_letter

	if(prob(90))
		return "[pick(syllables)][terminator]"
	return "[copytext_char(input, 1, min(7, length_char(input)))][terminator]"
