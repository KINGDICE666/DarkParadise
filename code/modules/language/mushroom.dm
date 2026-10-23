/datum/language/mushroom
	name = "Грибной"
	desc = "Язык, состоящий из звуков периодических выбросов воздуха, наполненного спорами."
	speech_verbs = list("пыхт%(ит,ят)%")
	ask_verbs = list("вопросительно пыхт%(ит,ят)%")
	exclaim_verbs = list("громко пыхт%(ит,ят)%")
	key = "mu"
	flags = LANGUAGE_RESTRICTED
	sentence_chance = 0
	between_word_sentence_chance = 10
	between_word_space_chance = 75
	additional_syllable_low = -4
	additional_syllable_high = -2
	default_priority = 80
	syllables = list("poof", "pff", "pFfF", "piff", "puff", "pooof", "pfffff", "piffpiff", "puffpuff", "poofpoof", "pifpafpofpuf")
	default_name_syllable_min = 1
	default_name_syllable_max = 2
