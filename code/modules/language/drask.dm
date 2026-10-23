/datum/language/drask
	name = "Орлуум"
	desc = "Монотонный, гудящий, вибрирующий язык Драсков. Звучит примерно как песня китов."
	speech_verbs = list("гуд%(ит,ят)%", "напева%(ет,ют)%", "мыч%(ит,ат)%", "грохоч%(ет,ут)%")
	ask_verbs = list("вопросительно гуд%(ит,ят)%", "вопросительно мыч%(ит,ат)%", "вопросительно грохоч%(ет,ут)%")
	exclaim_verbs = list("громко гуд%(ит,ят)%", "громко грохоч%(ет,ут)%", "рев%(ёт,ут)%")
	spans = list("drask")
	runechat_span = "drask"
	key = "%"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "drask"
	syllables = list("hoorb", "vrrm", "ooorm", "urrrum", "ooum", "ee", "ffm", "hhh", "mn", "ongg")

/datum/language/drask/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/static/list/drask_name_parts = list("Хоорм", "Вииск", "Саар", "Мнуу", "Оумн", "Фмонг", "Гнии", "Вррм", "Оорм", "Дромнн", "Ссуумн", "Овв", "Хоорб", "Ваар", "Гаар", "Гуум", "Руум", "Румум")
	return "[pick(drask_name_parts)]-[pick(drask_name_parts)]-[pick(drask_name_parts)]"
