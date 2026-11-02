/datum/language/diona
	name = "Песнь корней"
	desc = "Скрипучий, подголосочный язык, на котором инстинктивно говорят Дионы. Из-за уникального строения обычной Дионы, фраза на таком языке может представлять собой комбинацию от одного до двенадцати отдельных голосов и звуков."
	speech_verbs = list("трещ%(ит,ат)%", "скрип%(ит,ят)%")
	ask_verbs = list("вопросительно трещ%(ит,ат)%", "вопросительно скрип%(ит,ят)%")
	exclaim_verbs = list("громко шурш%(ит,ат)%", "громко скрип%(ит,ят)%")
	spans = list("diona")
	runechat_span = "diona"
	key = "q"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "plant"
	syllables = list("hs", "zt", "kr", "st", "sh")
	mutual_understanding = list(
		/datum/language/sylvan = 33,
	)

/datum/language/diona/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/new_name = "[pick(list("To Sleep Beneath", "Wind Over", "Embrace Of", "Dreams Of", "Witnessing", "To Walk Beneath", "Approaching The", "Glimmer Of", "The Ripple Of", "Colors Of", "The Still Of", "Silence Of", "Gentle Breeze Of", "Glistening Waters Under", "Child Of", "Blessed Plant-Ling Of", "Grass-Walker Of", "Element Of", "Spawn Of"))]"
	new_name += " [pick(list("The Void", "The Sky", "Encroaching Night", "Planetsong", "Starsong", "The Wandering Star", "The Empty Day", "Daybreak", "Nightfall", "The Rain", "The Stars", "The Waves", "Dusk", "Night", "The Wind", "The Summer Wind", "The Blazing Sun", "The Scorching Sun", "Eternal Fields", "The Soothing Plains", "The Undying Fiona", "Mother Nature's Bousum"))]"
	return new_name
