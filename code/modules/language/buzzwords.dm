/datum/language/buzzwords
	name = "Жужжащий"
	desc = "Общий язык всех насекомых, создаваемый ритмичными взмахами крыльев."
	speech_verbs = list("жужж%(ит,ат)%")
	ask_verbs = list("вопросительно жужж%(ит,ат)%")
	exclaim_verbs = list("громко жужж%(ит,ат)%")
	key = "bz"
	flags = LANGUAGE_RESTRICTED
	space_chance = 0
	sentence_chance = 0
	between_word_sentence_chance = 5
	between_word_space_chance = 0
	additional_syllable_low = 0
	additional_syllable_high = 0
	syllables = list(
		"bzz", "zzz", "z", "bz", "bzzz", "zzzz", "bzzzz", "b", "zz", "zzzzz",
	)
	icon_state = "buzz"
	default_priority = 90
	always_use_default_namelist = TRUE
