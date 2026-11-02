/datum/language/kidan
	name = "Хитин"
	desc = "Звук, который издают Киданы, потирая усики друг о друга, на самом деле является сложной формой общения."
	speech_verbs = list("потира%(ет,ют)% свои усики")
	ask_verbs = list("потира%(ет,ют)% свои усики")
	exclaim_verbs = list("потира%(ет,ют)% свои усики")
	spans = list("kidan")
	runechat_span = "kidan"
	key = "4"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "kidan"
	syllables = list("click", "clack")
	mutual_understanding = list(
		/datum/language/buzzwords = 20,
	)

/datum/language/kidan/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/new_name = "[pick(list("Вракс", "Крек", "Вриз", "Зрик", "Зарак", "Клик", "Зерк", "Дракс", "Звен", "Дрэкс"))]"
	new_name += ", "
	new_name += "[pick(list("Дворянин", "Рабочий", "Разведчик", "Строитель", "Фермер", "Собиратель", "Солдат", "Охранник", "Старатель"))]"
	new_name += " Клана "
	new_name += "[pick(list("Тристан", "Зарлан", "Клак", "Краз", "Крамн", "Орлан", "Зракс"))]"
	return new_name
