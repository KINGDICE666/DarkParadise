/datum/language/unathi
	name = "Синта'Унати"
	desc = "Общий язык Могеса, состоящий из шипящих звуков и дребезжания. Является родным языком Унатхов."
	speech_verbs = list("шип%(ит,ят)%", "гортанно урч%(ит,ят)%")
	ask_verbs = list("вопросительно шип%(ит,ят)%", "урч%(ит,ят)%")
	exclaim_verbs = list("рыч%(ит,ят)%", "рев%(ёт,ут)%")
	spans = list("soghun")
	runechat_span = "soghun"
	key = "o"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "lizard"
	syllables = list(
		"za", "az", "ze", "ez", "zi", "iz", "zo", "oz", "zu", "uz", "zs", "sz", "ha", "ah", "he", "eh", "hi", "ih",
		"ho", "oh", "hu", "uh", "hs", "sh", "la", "al", "le", "el", "li", "il", "lo", "ol", "lu", "ul", "ls", "sl", "ka", "ak", "ke", "ek",
		"ki", "ik", "ko", "ok", "ku", "uk", "ks", "sk", "sa", "as", "se", "es", "si", "is", "so", "os", "su", "us", "ss", "ss", "ra", "ar",
		"re", "er", "ri", "ir", "ro", "or", "ru", "ur", "rs", "sr", "a", "a", "e", "e", "i", "i", "o", "o", "u", "u", "s", "s",
	)

/datum/language/unathi/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/new_name = ..()
	while(findtextEx(new_name, "sss", 1, null))
		new_name = replacetext(new_name, "sss", "ss")
	return capitalize(new_name)

/datum/language/unathi/monkey
	name = "Стокский"
	desc = "Шшш-шш-шшш."
	key = "fs"
	default_priority = 80
	icon_state = "animal"
