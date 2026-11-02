/datum/language/narsie
	name = "Нар'Сианский"
	desc = "Древний, пропитанный кровью, невероятно сложный язык культистов Нар'Си."
	speech_verbs = list("нараспев произнос%(ит,ят)%")
	ask_verbs = list("вопрошающе произнос%(ит,ят)%")
	exclaim_verbs = list("взыва%(ет,ют)%")
	key = "ns"
	flags = LANGUAGE_RESTRICTED | LANGUAGE_NOBABEL
	space_chance = 75
	sentence_chance = 10
	between_word_sentence_chance = 5
	between_word_space_chance = 95
	additional_syllable_high = 0
	var/static/list/base_syllables = list(
		"h", "v", "c", "e", "g", "d", "r", "n", "h", "o", "p",
		"ra", "so", "at", "il", "ta", "gh", "sh", "ya", "te", "sh", "ol", "ma", "om", "ig", "ni", "in",
		"sha", "mir", "sas", "mah", "zar", "tok", "lyr", "nqa", "nap", "olt", "val", "qha",
		"fwe", "ath", "yro", "eth", "gal", "gib", "bar", "jin", "kla", "atu", "kal", "lig",
		"yoka", "drak", "loso", "arta", "weyh", "ines", "toth", "fara", "amar", "nyag", "eske", "reth", "dedo", "btoh", "nikt", "neth",
		"kanas", "garis", "uloft", "tarat", "khari", "thnor", "rekka", "ragga", "rfikk", "harfr", "andid", "ethra", "dedol", "totum",
		"ntrath", "keriam",
	)
	syllables = list(
		"sha", "mir", "sas", "mah", "hra", "zar", "tok", "lyr", "nqa", "nap", "olt", "val",
		"yam", "qha", "fel", "det", "fwe", "mah", "erl", "ath", "yro", "eth", "gal", "mud",
		"gib", "bar", "tea", "fuu", "jin", "kla", "atu", "kal", "lig",
		"yoka", "drak", "loso", "arta", "weyh", "ines", "toth", "fara", "amar", "nyag", "eske", "reth", "dedo", "btoh", "nikt", "neth", "abis",
		"kanas", "garis", "uloft", "tarat", "khari", "thnor", "rekka", "ragga", "rfikk", "harfr", "andid", "ethra", "dedol", "totum",
		"verbot", "pleggh", "ntrath", "barhah", "pasnar", "keriam", "usinar", "savrae", "amutan", "tannin", "remium", "barada",
		"forbici",
	)
	icon_state = "narsie"
	default_priority = 10

/datum/language/narsie/New()
	for(var/syllable in base_syllables)
		for(var/target_syllable in base_syllables)
			if(syllable == target_syllable)
				continue
			if(length(syllable) + length(target_syllable) > 8)
				syllables += "[syllable][target_syllable]"
			else if(prob(80))
				syllables += "[syllable]'[target_syllable]"
			else if(prob(25))
				syllables += "[syllable]-[target_syllable]"
			else
				syllables += "[syllable][target_syllable]"
	..()
