/datum/language/machine
	name = "Кодированный звуковой язык"
	desc = "Эффективный язык закодированных тонов, разработанный синтетиками и киборгами."
	speech_verbs = list("пища%(ет,ют)%", "сообща%(ет,ют)%")
	ask_verbs = list("запрашива%(ет,ют)%")
	exclaim_verbs = list("громко пища%(ет,ют)%")
	spans = list("robot")
	key = "ea"
	flags = LANGUAGE_NO_STUTTER | LANGUAGE_RESTRICTED
	syllables = list(
		"beep", "beep", "beep", "beep", "beep", "boop", "boop", "boop",
		"bop", "bop", "dee", "dee", "doo", "doo", "hiss", "hss", "buzz",
		"buzz", "bzz", "ksssh", "keey", "wurr", "wahh", "tzzz",
	)
	space_chance = 0
	sentence_chance = 0
	between_word_sentence_chance = 10
	between_word_space_chance = 10
	additional_syllable_low = 0
	additional_syllable_high = 0
	default_priority = 90
	icon_state = "eal"
	mutual_understanding = list(
		/datum/language/trinary = 50,
	)

/datum/language/machine/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	if(force_use_syllables)
		return ..()
	return pick(GLOB.ai_names)
