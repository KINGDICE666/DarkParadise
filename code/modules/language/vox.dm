/datum/language/vox
	name = "Вокс-пиджин"
	desc = "Общий язык различных кораблей Воксов, составляющих Ковчег. Для всех остальных он звучит как помесь чириканья, крика и визга."
	speech_verbs = list("чирика%(ет,ют)%", "визж%(ит,ат)%", "крич%(ит,ат)%")
	ask_verbs = list("вопросительно чирика%(ет,ют)%", "вопросительно визж%(ит,ат)%", "вопросительно крич%(ит,ат)%")
	exclaim_verbs = list("громко чирика%(ет,ют)%", "громко визж%(ит,ат)%", "громко крич%(ит,ат)%")
	spans = list("vox")
	runechat_span = "vox"
	key = "v"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "vox"
	syllables = list(
		"ti", "ti", "ti", "hi", "hi", "ki", "ki", "ki", "ki", "ya", "ta", "ha", "ka", "ya", "yi", "chi", "cha", "kah",
		"SKRE", "AHK", "EHK", "RAWK", "KRA", "AAA", "EEE", "KI", "II", "KRI", "KA",
	)

/datum/language/vox/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/static/list/vox_name_syllables = list("ти", "хи", "ки", "йа", "та", "ха", "ка", "йа", "чи", "ча", "ках")
	var/newname = ""
	for(var/i in 0 to rand(2, 8))
		newname += pick(vox_name_syllables)
	return capitalize(newname)
