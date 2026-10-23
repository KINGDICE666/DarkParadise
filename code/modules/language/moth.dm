/datum/language/moth
	name = "Ткачий язык"
	desc = "Язык мотыльковых гуманоидов Луам, в котором используется прерывистая жестикуляция усиками, крыльями или челюстями, а также жужжание или чириканье."
	speech_verbs = list("жужж%(ит,ат)%")
	ask_verbs = list("хлопа%(ет,ют)% крыльями")
	exclaim_verbs = list("щебеч%(ет,ут)%")
	spans = list("moth")
	runechat_span = "moth"
	key = "#"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "moth"
	join_override = "-"
	syllables = list(
		"år", "i", "går", "sek", "mo", "ff", "ok", "gj", "ø", "gå", "la", "le",
		"lit", "ygg", "van", "dår", "nø", "møt", "idd", "hvo", "ja", "på", "han",
		"så", "ån", "det", "att", "nå", "gö", "bra", "int", "tyc", "om", "när", "två",
		"må", "dag", "sjä", "vii", "vuo", "eil", "tun", "käyt", "teh", "vä", "hei",
		"huo", "suo", "ää", "ten", "ja", "heu", "stu", "uhr", "kön", "we", "hön",
	)

/datum/language/moth/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/new_name = "[pick(list("Abbot", "Archer", "Arkwright", "Baker", "Bard", "Biologist", "Broker", "Caller", "Chamberlain", "Clerk", "Cooper", "Culinarian", "Dean", "Director", "Duke", "Energizer", "Excavator", "Explorer", "Fletcher", "Gatekeeper", "Guardian", "Guide", "Healer", "Horner", "Keeper", "Knight", "Laidler", "Mapper", "Marshall", "Mechanic", "Miller", "Navigator", "Pilot", "Prior", "Seeker", "Seer", "Smith", "Stargazer", "Teacher", "Tech Whisperer", "Tender", "Thatcher", "Voidcrafter", "Voidhunter", "Voidwalker", "Ward", "Watcher", "Weaver", "Webster", "Wright"))]"
	new_name += "[pick(list(" of", " for", " in Service of", ", Servant of", " for the Good of", ", Student of", " to"))]"
	new_name += " [pick(list("Andromeda", "Antlia", "Apus", "Auriga", "Caelum", "Camelopardalis", "Canes Venatici", "Carinae", "Cassiopeia", "Centauri", "Circinus", "Cygnus", "Dorado", "Draco", "Eridanus", "Errakis", "Fornax", "Gliese", "Grus", "Horologium", "Hydri", "Lacerta", "Leo Minor", "Lupus", "Lynx", "Maffei", "Megrez", "Messier", "Microscopium", "Monocerotis", "Muscae", "Ophiuchi", "Orion", "Pegasi", "Persei", "Perseus", "Polaris", "Pyxis", "Sculptor", "Syrma", "Telescopium", "Tianyi", "Triangulum", "Trifid", "Tucana", "Tycho", "Vir", "Volans", "Zavyava"))]"
	return new_name
