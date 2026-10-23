/datum/language/drone
	name = "Дрон"
	desc = "Зашифрованный поток данных, преобразованный в речевые паттерны."
	speech_verbs = list("сообща%(ет,ют)%", "констатиру%(ет,ют)%")
	ask_verbs = list("запрашива%(ет,ют)%", "дела%(ет,ют)% запрос")
	exclaim_verbs = list("восклица%(ет,ют)%")
	spans = list("robot")
	key = "db"
	flags = LANGUAGE_RESTRICTED | LANGUAGE_NO_STUTTER
	syllables = list(".", "|")
	space_chance = 0
	sentence_chance = 0
	between_word_space_chance = 0
	additional_syllable_low = 0
	additional_syllable_high = 0
	default_priority = 20
	icon_state = "drone"
	always_use_default_namelist = TRUE
