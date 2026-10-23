/datum/language/tajaran
	name = "Сик'таир"
	desc = "Традиционный язык Адомая, состоящий из выразительных мяукающих звуков и щебета. Родной язык для Таяран."
	speech_verbs = list("мурч%(ит,ят)%", "мурлыч%(ет,ут)%")
	ask_verbs = list("вопросительно мурч%(ит,ят)%", "вопросительно мурлыч%(ет,ут)%")
	exclaim_verbs = list("во%(ет,ют)%")
	spans = list("tajaran")
	runechat_span = "tajaran"
	key = "j"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "neko"
	syllables = list(
		"rr", "rr", "tajr", "kir", "raj", "kii", "mir", "kra", "ahk", "nal", "vah", "khaz", "jri", "ran", "darr",
		"mi", "jri", "dynh", "manq", "rhe", "zar", "rrhaz", "kal", "chur", "eech", "thaa", "dra", "jurl", "mah", "sanu", "dra", "ii'r",
		"ka", "aasi", "far", "wa", "baq", "ara", "qara", "zir", "sam", "mak", "hrar", "nja", "rir", "khan", "jun", "dar", "rik", "kah",
		"hal", "ket", "jurl", "mah", "tul", "cresh", "azu", "ragh",
	)

/datum/language/tajaran/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/static/list/tajaran_female_endings_list = list("и", "а", "о", "е", "й", "ь")
	var/list/ru_name_syllables = list(
		"кан", "тай", "кир", "раи", "кии", "мир", "кра", "тэк", "нал", "вар", "хар", "марр", "ран", "дарр",
		"мирк", "ири", "дин", "манг", "рик", "зар", "раз", "кель", "шера", "тар", "кей", "ар", "но", "маи", "зир", "кер", "нир", "ра",
		"ми", "рир", "сей", "эка", "гир", "ари", "нэй", "нре", "ак", "таир", "эрай", "жин", "мра", "зур", "рин", "сар", "кин", "рид", "эра", "ри", "эна",
	)
	var/apostrophe = "'"
	var/new_name = ""
	var/full_name = ""

	for(var/i in 1 to 2)
		for(var/syllable_count in 1 to rand(1, 2))
			new_name += pick_n_take(ru_name_syllables)
		new_name += apostrophe
		apostrophe = ""
	full_name = "[capitalize(lowertext(new_name))]"
	if(gender == FEMALE)
		var/ending = copytext(full_name, -2)
		if(!(ending in tajaran_female_endings_list))
			full_name += "а"
	if(prob(75))
		full_name += " [pick(list("Хадии", "Кайтам", "Жан-Хазан", "Нъярир’Ахан"))]"
	else if(prob(80))
		full_name += " [pick(list("Энай-Сэндай", "Наварр-Сэндай", "Року-Сэндай", "Шенуар-Сэндай"))]"
	return full_name

/datum/language/tajaran/monkey
	name = "Фарвный"
	desc = "Мяу-мяу-мяу."
	key = "fa"
	default_priority = 80
	icon_state = "animal"
