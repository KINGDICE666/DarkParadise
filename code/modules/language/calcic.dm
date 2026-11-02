/datum/language/calcic
	name = "Кальцийский"
	desc = "Отрывистый, стаккатный язык костей. Понятен скелетам и плазмолюдам."
	speech_verbs = list("клаца%(ет,ют)%")
	ask_verbs = list("вопросительно клаца%(ет,ют)%")
	exclaim_verbs = list("громко клаца%(ет,ют)%")
	key = "cl"
	flags = LANGUAGE_RESTRICTED
	space_chance = 10
	between_word_sentence_chance = 10
	between_word_space_chance = 75
	additional_syllable_low = 0
	additional_syllable_high = 1
	syllables = list(
		"k", "ck", "ack", "ick", "cl", "tk", "sk", "isk", "tak",
		"kl", "hs", "ss", "ks", "lk", "dk", "gk", "ka", "ska", "la", "pk",
		"wk", "ak", "ik", "ip", "ski", "bk", "kb", "ta", "is", "it", "li", "di",
		"ds", "ya", "sck", "crk", "hs", "ws", "mk", "aaa", "skraa", "skee", "hss",
		"raa", "klk", "tk", "stk", "clk",
	)
	icon_state = "calcic"
	default_priority = 90
