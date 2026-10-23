/datum/language/aphasia
	name = "Бормотание"
	desc = "Считается, что на этом языке способен заговорить любой, чей мозг повреждён достаточно сильно."
	speech_verbs = list("бормоч%(ет,ут)%", "мыч%(ит,ат)%")
	ask_verbs = list("вопросительно мыч%(ит,ат)%")
	exclaim_verbs = list("невнятно выкрикива%(ет,ют)%")
	whisper_verbs = list("невнятно шепч%(ет,ут)%")
	flags = LANGUAGE_RESTRICTED | LANGUAGE_NOBABEL | LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD
	syllables = list("м", "н", "гх", "х", "л", "с", "р", "а", "е", "и", "о", "у")
	space_chance = 0
	sentence_chance = 0
	between_word_sentence_chance = 10
	between_word_space_chance = 75
	additional_syllable_low = 0
	additional_syllable_high = 0
	default_priority = 10
	icon_state = "aphasia"
	always_use_default_namelist = TRUE
