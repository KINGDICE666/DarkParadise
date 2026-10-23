/datum/language/trinary
	name = "Троичный"
	desc = "Модификация двоичного кода, позволяющая использовать нечёткую логику. 0 — нет, 1 — возможно, 2 — да. Считается, что именно эта система дала способность позитронным системам мыслить творчески."
	speech_verbs = list("сообща%(ет,ют)%", "констатиру%(ет,ют)%")
	ask_verbs = list("запрашива%(ет,ют)%", "дела%(ет,ют)% запрос")
	exclaim_verbs = list("восклица%(ет,ют)%")
	spans = list("trinary")
	runechat_span = "trinary"
	key = "5"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "eal"
	syllables = list("0+2+0+1+1", "0+1+2+2+2", "1+0+1+0+0", "1+0+2+1+0", "2+1+0+1+2", "0+2+0+1+1", "2+1+2+0+0", "1+0+0+2", "2+0+0+1", "0+0+0+2", "0+0+1+2", "0+0+1+2", "0+0+0", "1+2+0", "1+2+1", "2+0+1", "2+2+0", "1+0", "1+1", "0")
	mutual_understanding = list(
		/datum/language/machine = 50,
	)

/datum/language/trinary/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	if(prob(70))
		return "[pick(list("СИМ", "АИС", "ТЕК", "АРМА", "АОС"))]-[rand(100, 999)]"
	return pick(GLOB.ai_names)
