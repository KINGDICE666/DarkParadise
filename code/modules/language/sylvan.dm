/datum/language/sylvan
	name = "Сильванский"
	desc = "Сложный древний язык, на котором говорят разумные растения."
	speech_verbs = list("шелест%(ит,ят)%")
	ask_verbs = list("вопросительно шелест%(ит,ят)%")
	exclaim_verbs = list("громко шелест%(ит,ят)%")
	key = "sy"
	flags = LANGUAGE_RESTRICTED
	space_chance = 10
	sentence_chance = 0
	between_word_sentence_chance = 10
	between_word_space_chance = 50
	additional_syllable_low = 1
	additional_syllable_high = 2
	syllables = list(
		"fii", "sii", "rii", "rel", "maa", "ala", "san", "tol", "tok", "dia", "eres",
		"fal", "tis", "bis", "qel", "aras", "losk", "rasa", "eob", "hil", "tanl", "aere",
		"fer", "bal", "pii", "dala", "ban", "foe", "doa", "cii", "uis", "mel", "wex",
		"incas", "int", "elc", "ent", "aws", "qip", "nas", "vil", "jens", "dila", "fa",
		"la", "re", "do", "ji", "ae", "so", "qe", "ce", "na", "mo", "ha", "yu",
	)
	icon_state = "plant"
	default_priority = 90
	default_name_syllable_max = 3
	mutual_understanding = list(
		/datum/language/diona = 33,
	)
