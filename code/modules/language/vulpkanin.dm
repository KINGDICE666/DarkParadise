/datum/language/vulpkanin
	name = "Канилунц"
	desc = "Гортанный язык, на котором говорят обитатели системы Ваззенд. Он состоит из рычания, лая и тявканья, также активно использует движения ушей и хвоста. Вульпканины говорят на нём с лёгкостью."
	speech_verbs = list("тявка%(ет,ют)%", "гавка%(ет,ют)%")
	ask_verbs = list("вопросительно тявка%(ет,ют)%", "вопросительно гавка%(ет,ют)%")
	exclaim_verbs = list("рыч%(ит,ят)%", "ла%(ет, ют)%")
	spans = list("vulpkanin")
	runechat_span = "vulpkanin"
	key = "7"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "animal"
	syllables = list(
		"rur", "ya", "cen", "rawr", "bar", "kuk", "tek", "qat", "uk", "wu", "vuh", "tah", "tch", "schz", "auch",
		"ist", "ein", "entch", "zwichs", "tut", "mir", "wo", "bis", "es", "vor", "nic", "gro", "lll", "enem", "zandt", "tzch", "noch",
		"hel", "ischt", "far", "wa", "baram", "iereng", "tech", "lach", "sam", "mak", "lich", "gen", "or", "ag", "eck", "gec", "stag", "onn",
		"bin", "ket", "jarl", "vulf", "einech", "cresthz", "azunein", "ghzth",
	)

/datum/language/vulpkanin/monkey
	name = "Вульпинский"
	desc = "Гаф-гав-гаф."
	key = "vu"
	default_priority = 80
