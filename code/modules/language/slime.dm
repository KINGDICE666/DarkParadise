/datum/language/slime
	name = "Пузырчатый"
	desc = "Язык Плазмолюдов. Это смесь булькающих и хлюпающих звуков. Другим гуманоидам очень сложно говорить на нём без механической помощи."
	speech_verbs = list("булька%(ет,ют)%", "хлюпа%(ет,ют)%")
	ask_verbs = list("булька%(ет,ют)%", "хлюпа%(ет,ют)%")
	exclaim_verbs = list("булька%(ет,ют)%", "хлюпа%(ет,ют)%")
	spans = list("slime")
	runechat_span = "slime"
	key = "f"
	flags = LANGUAGE_RESTRICTED
	default_priority = 70
	icon_state = "slime"
	syllables = list("blob", "plop", "pop", "bop", "boop")
