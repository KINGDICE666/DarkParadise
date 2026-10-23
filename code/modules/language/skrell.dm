#define SKRELL_ADDITIONAL_SYLLABLES 2

/datum/language/skrell
	name = "Скреллианский"
	desc = "Мелодичный и сложный язык, на котором говорят Скреллы. Некоторые из его звуков находятся за пределами слышимости человека."
	speech_verbs = list("мыч%(ит,ят)%", "напева%(ет,ют)%", "гуд%(ит,ят)%")
	ask_verbs = list("вопросительно мыч%(ит,ят)%", "вопросительно гуд%(ит,ят)%")
	exclaim_verbs = list("трещ%(ит,ат)%")
	spans = list("skrell")
	runechat_span = "skrell"
	key = "k"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "skrell"
	syllables = list("qr", "qrr", "xuq", "qil", "quum", "xuqm", "vol", "xrim", "zaoo", "qu-uu", "qix", "qoo", "zix")
	special_characters = list("!", "*")

/datum/language/skrell/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/list/ru_name_syllables = list(
		list(
			list("заоо", "зао", "зикс", "зо", "йуо", "кью", "кьюм", "кси", "ксу", "квум", "кву",
				"кви", "квей", "квиш", "куу", "кюан", "киэн", "ку", "кил", "лиа", "люик", "луи",
				"рио", "сейу", "тсой", "уль", "улур", "урр", "ур", "цу", "эль", "эо", "эу"),

			list(
			"аг", "вум", "вул", "вол", "гли", "зи", "заоо", "зао", "зикс", "зуо", "зук", "зуво",
			"икс", "ил", "ис", "йук", "кву", "квум", "куум", "куо", "куа", "куак", "кул", "квол",
			"кью", "кьюа", "кэ", "кин", "кии", "кс", "ки", "киу", "кос", "лоа", "лак", "лум", "лик",
			"лии", "ллак", "мзикс", "мвол", "ори", "ору", "орр", "ррум", "ру", "руум", "руа", "рл",
			"сэк", "су", "сиа", "тейе", "тейку", "тсу", "туа", "туи", "ту", "тал", "уат", "уок", "урр",
			"уоо", "уо", "уик", "уии", "уэк", "эйкс", "эль", "эрр", "эй", "эйс", "о", "у", "а", "з", "э", "м" ,"к", "с", "р"
			)
		),

		list(
			list("заоо", "зао", "зо", "йуо", "лиа", "луи", "рио", "сейу", "эо"),

			list(
			"вум", "вул", "вол", "гли", "зи", "заоо", "зао", "зикс", "зуо", "зук", "зуво",
			"йук", "кву", "квум", "куум", "куо", "куа", "куак", "кул", "квол", "кью", "кьюа",
			"кэ", "кин", "кии", "кс", "ки", "киу", "кос", "лоа", "лак", "лум", "лик", "лии", "ллак",
			"мзикс", "мвол", "ррум", "ру", "руум", "руа", "рл", "сэк", "су", "сиа", "тейе", "тейку",
			"тсу", "туа", "туи", "ту", "тал", "з", "м", "к", "с", "р"
			)
		)
	)

	var/full_name = ""

	for(var/i in 1 to 2)
		var/apostrophe = "'"
		var/new_name = ""
		var/using_list = rand(1, LAZYLEN(ru_name_syllables))

		new_name += pick(ru_name_syllables[using_list][1])

		for(var/add_syllables in 1 to rand(1, SKRELL_ADDITIONAL_SYLLABLES))
			if(apostrophe && prob(50))
				new_name += apostrophe
				apostrophe = null

			new_name += pick(ru_name_syllables[using_list][2])

		full_name += " [capitalize(new_name)]"

	return "[trim(full_name)]"

/datum/language/skrell/monkey
	name = "Неарский"
	desc = "Пи-пи-пи!"
	key = "fn"
	default_priority = 80
	icon_state = "animal"

#undef SKRELL_ADDITIONAL_SYLLABLES
