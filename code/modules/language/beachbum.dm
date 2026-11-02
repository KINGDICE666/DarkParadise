/datum/language/beachbum
	name = "Пляжный"
	desc = "Древний язык с далёкой Пляжной планеты. Под действием космических наркотиков люди волшебным образом начинают на нём говорить."
	key = "bb"
	flags = LANGUAGE_RESTRICTED
	space_chance = 80
	sentence_chance = 5
	additional_syllable_low = -2
	additional_syllable_high = -1
	default_priority = 90
	syllables = list(
		"cowabunga", "rad", "radical", "dudes", "bogus", "weeed", "every",
		"dee", "dah", "woah", "surf", "blazed", "high", "heinous", "day",
		"brah", "bro", "blown", "catch", "body", "beach", "oooo", "twenty",
		"shiz", "phiz", "wizz", "pop", "chill", "awesome", "dude", "it",
		"wax", "stoked", "yes", "ding", "way", "no", "wicked", "aaaa",
		"cool", "hoo", "wah", "wee", "man", "maaaaaan", "mate", "wick",
		"oh", "ocean", "up", "out", "rip", "slide", "big", "stomp",
		"weed", "pot", "smoke", "four-twenty", "shove", "wacky", "hah",
		"sick", "slash", "spit", "stoked", "shallow", "gun", "party",
		"heavy", "stellar", "excellent", "triumphant", "babe", "four",
		"tail", "trim", "tube", "wobble", "roll", "gnarly", "epic",
	)
	icon_state = "beach"
	always_use_default_namelist = TRUE
	mutual_understanding = list(
		/datum/language/common = 50,
		/datum/language/uncommon = 33,
	)
