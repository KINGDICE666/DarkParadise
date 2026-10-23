/datum/language/common
	name = "Общегалактический"
	desc = "Универсальный язык, разработанный людьми для упрощения общения с другими гуманоидными расами."
	speech_verbs = list("говор%(ит,ят)%")
	exclaim_verbs = list("восклица%(ет,ют)%", "выкрикива%(ет,ют)%")
	whisper_verbs = list("шепч%(ет,ут)%")
	key = "9"
	flags = LANGUAGE_TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_UNDERSTOOD | LANGUAGE_RESTRICTED
	default_priority = 100
	sentence_chance = 0
	between_word_sentence_chance = 10
	between_word_space_chance = 75
	additional_syllable_low = 0
	additional_syllable_high = 0
	icon_state = "galcom"
	always_use_default_namelist = TRUE
	syllables = list(
		list(
			"a", "ai", "an", "ang", "ao", "ba", "bai", "ban", "bang", "bao", "bei", "ben", "beng", "bi", "bian", "biao",
			"bie", "bin", "bing", "bo", "bu", "ca", "cai", "can", "cang", "cao", "ce", "cei", "cen", "ceng", "cha", "chai",
			"chan", "chang", "chao", "che", "chen", "cheng", "chi", "chong", "chou", "chu", "chua", "chuai", "chuan", "chuang", "chui", "chun",
			"chuo", "ci", "cong", "cou", "cu", "cuan", "cui", "cun", "cuo", "da", "dai", "dan", "dang", "dao", "de", "dei",
			"den", "deng", "di", "dian", "diao", "die", "ding", "diu", "dong", "dou", "du", "duan", "dui", "dun", "duo", "e",
			"ei", "en", "er", "fa", "fan", "fang", "fei", "fen", "feng", "fo", "fou", "fu", "ga", "gai", "gan", "gang",
			"gao", "ge", "gei", "gen", "geng", "gong", "gou", "gu", "gua", "guai", "guan", "guang", "gui", "gun", "guo", "ha",
			"hai", "han", "hang", "hao", "he", "hei", "hen", "heng", "hm", "hng", "hong", "hou", "hu", "hua", "huai", "huan",
			"huang", "hui", "hun", "huo", "ji", "jia", "jian", "jiang", "jiao", "jie", "jin", "jing", "jiong", "jiu", "ju", "juan",
			"jue", "jun", "ka", "kai", "kan", "kang", "kao", "ke", "kei", "ken", "keng", "kong", "kou", "ku", "kua", "kuai",
			"kuan", "kuang", "kui", "kun", "kuo", "la", "lai", "lan", "lang", "lao", "le", "lei", "leng", "li", "lia", "lian",
			"liang", "liao", "lie", "lin", "ling", "liu", "long", "lou", "lu", "luan", "lun", "luo", "ma", "mai", "man", "mang",
			"mao", "me", "mei", "men", "meng", "mi", "mian", "miao", "mie", "min", "ming", "miu", "mo", "mou", "mu", "na",
			"nai", "nan", "nang", "nao", "ne", "nei", "nen", "neng", "ng", "ni", "nian", "niang", "niao", "nie", "nin", "ning",
			"niu", "nong", "nou", "nu", "nuan", "nuo", "o", "ou", "pa", "pai", "pan", "pang", "pao", "pei", "pen", "peng",
			"pi", "pian", "piao", "pie", "pin", "ping", "po", "pou", "pu", "qi", "qia", "qian", "qiang", "qiao", "qie", "qin",
			"qing", "qiong", "qiu", "qu", "quan", "que", "qun", "ran", "rang", "rao", "re", "ren", "reng", "ri", "rong", "rou",
			"ru", "rua", "ruan", "rui", "run", "ruo", "sa", "sai", "san", "sang", "sao", "se", "sei", "sen", "seng", "sha",
			"shai", "shan", "shang", "shao", "she", "shei", "shen", "sheng", "shi", "shou", "shu", "shua", "shuai", "shuan", "shuang", "shui",
			"shun", "shuo", "si", "song", "sou", "su", "suan", "sui", "sun", "suo", "ta", "tai", "tan", "tang", "tao", "te",
			"teng", "ti", "tian", "tiao", "tie", "ting", "tong", "tou", "tu", "tuan", "tui", "tun", "tuo", "wa", "wai", "wan",
			"wang", "wei", "wen", "weng", "wo", "wu", "xi", "xia", "xian", "xiang", "xiao", "xie", "xin", "xing", "xiong", "xiu",
			"xu", "xuan", "xue", "xun", "ya", "yan", "yang", "yao", "ye", "yi", "yin", "ying", "yong", "you", "yu", "yuan",
			"yue", "yun", "za", "zai", "zan", "zang", "zao", "ze", "zei", "zen", "zeng", "zha", "zhai", "zhan", "zhang", "zhao",
			"zhe", "zhei", "zhen", "zheng", "zhi", "zhong", "zhou", "zhu", "zhua", "zhuai", "zhuan", "zhuang", "zhui", "zhun", "zhuo", "zi",
			"zong", "zou", "zuan", "zui", "zun", "zuo", "zu",
		),
		list(
			"al", "an", "ar", "as", "at", "ea", "ed", "en", "er", "es", "ha", "he", "hi", "in", "is", "it",
			"le", "me", "nd", "ne", "ng", "nt", "on", "or", "ou", "re", "se", "st", "te", "th", "ti", "to",
			"ve", "wa", "all", "and", "are", "but", "ent", "era", "ere", "eve", "for", "had", "hat", "hen", "her", "hin",
			"his", "ing", "ion", "ith", "not", "ome", "oul", "our", "sho", "ted", "ter", "tha", "the", "thi",
		),
	)
	mutual_understanding = list(
		/datum/language/beachbum = 33,
		/datum/language/uncommon = 20,
	)

/datum/language/human
	name = "Общесолнечный"
	desc = "Искуственный язык, созданный на основе английского, китайского и эсперанто. Является основным для Людей."
	speech_verbs = list("говор%(ит,ят)%")
	exclaim_verbs = list("восклица%(ет,ют)%", "выкрикива%(ет,ют)%")
	whisper_verbs = list("шепч%(ет,ут)%")
	spans = list("solcom")
	runechat_span = "solcom"
	key = "1"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	syllables = list("tao", "shi", "tzu", "yi", "com", "be", "is", "i", "op", "vi", "ed", "lec", "mo", "cle", "te", "dis", "e")
	always_use_default_namelist = TRUE
	icon_state = "spinwarder"

/datum/language/trader
	name = "Торговый"
	desc = "Этот элегантный и структурированный язык используется различными торговыми картелями в крупных системах для торговли и заключения сделок."
	speech_verbs = list("утвержда%(ет,ют)%")
	spans = list("say_quote")
	key = "2"
	default_priority = 40
	space_chance = 100
	icon_state = "trader"
	syllables = list(
		"lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
		"sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore",
		"magna", "aliqua", "ut", "enim", "ad", "minim", "veniam", "quis", "nostrud",
		"exercitation", "ullamco", "laboris", "nisi", "ut", "aliquip", "ex", "ea", "commodo",
		"consequat", "duis", "aute", "irure", "dolor", "in", "reprehenderit", "in",
		"voluptate", "velit", "esse", "cillum", "dolore", "eu", "fugiat", "nulla",
		"pariatur", "excepteur", "sint", "occaecat", "cupidatat", "non", "proident", "sunt",
		"in", "culpa", "qui", "officia", "deserunt", "mollit", "anim", "id", "est", "laborum",
	)

/datum/language/gutter
	name = "Гангстерский"
	desc = "Грубая, исковерканная версия Общегалактического языка, используемая криминальными элементами по всей Галактике."
	speech_verbs = list("рявка%(ет,ют)%")
	ask_verbs = list("нагло спрашива%(ет,ют)%")
	exclaim_verbs = list("агрессивно говор%(ит,ят)%")
	spans = list("gutter")
	key = "3"
	default_priority = 40
	icon_state = "gutter"
	syllables = list("gra", "ba", "ba", "breh", "bra", "rah", "dur", "ra", "ro", "gro", "go", "ber", "bar", "geh", "heh", "gra")
	mutual_understanding = list(
		/datum/language/common = 20,
	)

/datum/language/clown
	name = "Клоунский"
	desc = "Язык планеты клоунов. Родной язык клоунов по всей Галактике."
	speech_verbs = list("хонка%(ет,ют)%")
	ask_verbs = list("вопросительно хонка%(ет,ют)%")
	exclaim_verbs = list("труб%(ит,ят)%", "громко хонка%(ет,ют)%")
	spans = list("clown")
	runechat_span = "clown"
	key = "0"
	default_priority = 40
	icon_state = "clown"
	syllables = list("honk", "squeak", "bonk", "toot", "narf", "zub", "wee", "wub", "norf")

/datum/language/com_srus
	name = "Нео-русский"
	desc = "Официальный язык СССП. Является смесью Общесолнечного и старых человеческих языков славянской группы. Лингвистический символ противостояния Транс-солнечной Федерации."
	speech_verbs = list("чётко выговарива%(ет,ют)%", "твёрдо произнос%(ит,ят)%")
	whisper_verbs = list("бормоч%(ет,ут)%")
	exclaim_verbs = list("громко произнос%(ит,ят)%", "твёрдо восклица%(ет,ют)%")
	spans = list("com_srus")
	runechat_span = "com_srus"
	key = "?"
	default_priority = 40
	space_chance = 40
	always_use_default_namelist = TRUE
	icon_state = "com_srus"
	syllables = list(
		"dyen", "bar", "bota", "vyek", "tvo", "slov", "slav", "syen", "doup", "vah", "laz", "gloz", "yet",
		"nyet", "da", "sky", "glav", "glaz", "netz", "doomat", "zat", "moch", "boz",
		"comy", "vrad", "vrade", "tay", "bli", "ay", "nov", "livn", "tolv", "glaz", "gliz",
		"ouy", "zet", "yevt", "dat", "botat", "nev", "novy", "vzy", "nov", "sho", "obsh", "dasky",
		"key", "skey", "ovsky", "skaya", "bib", "kiev", "studen", "var", "bul", "vyan",
		"tzion", "vaya", "myak", "gino", "volo", "olam", "miti", "nino", "menov", "perov",
		"odasky", "trov", "niki", "ivano", "dostov", "sokol", "oupa", "pervom", "schel",
		"tizan", "chka", "tagan", "dobry", "okt", "boda", "veta", "idi", "cyk", "blyt", "hui", "na",
		"udi", "litchki", "casa", "linka", "toly", "anatov", "vich", "vech", "vuch", "toi", "ka", "vod",
	)
	mutual_understanding = list(
		/datum/language/human = 20,
	)
