/datum/language/terrum
	name = "Террум"
	desc = "Язык големов. Звучит похоже на древнеземной иврит."
	speech_verbs = list("грохоч%(ет,ут)%")
	ask_verbs = list("вопросительно грохоч%(ет,ут)%")
	exclaim_verbs = list("громко грохоч%(ет,ут)%")
	key = "te"
	flags = LANGUAGE_RESTRICTED
	sentence_chance = 0
	between_word_sentence_chance = 10
	between_word_space_chance = 75
	additional_syllable_low = 1
	additional_syllable_high = 2
	syllables = list(
		"sha", "vu", "nah", "ha", "yom", "ma", "cha", "ar", "et", "mol", "lua",
		"ch", "na", "sh", "ni", "yah", "bes", "ol", "hish", "ev", "la", "ot", "la",
		"khe", "tza", "chak", "hak", "hin", "hok", "lir", "tov", "yef", "yfe",
		"cho", "ar", "kas", "kal", "ra", "lom", "im", "bok",
		"erev", "shlo", "lo", "ta", "im", "yom",
	)
	special_characters = list("'")
	icon_state = "golem"
	default_priority = 90

/datum/language/terrum/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	if(force_use_syllables)
		return ..()

	var/name = pick(GLOB.golem_names)
	if(prob(3))
		name += " [pick(GLOB.last_names_male)]"
	return name
