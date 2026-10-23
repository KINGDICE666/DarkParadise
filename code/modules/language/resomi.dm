/datum/language/resomi
	name = "Скречи"
	desc = "Смесь чириканья, свиста и щелчков, дополненная активной жестикуляцией ушами и хвостом."
	speech_verbs = list("чирика%(ет,ют)%")
	exclaim_verbs = list("вскрикива%(ет,ют)%")
	whisper_verbs = list("тихо щёлка%(ет,ют)%")
	spans = list("vox")
	runechat_span = "vox"
	key = "sa"
	flags = LANGUAGE_RESTRICTED
	default_priority = 90
	icon_state = "resomi"
	syllables = list(
		"ki", "skre", "chir", "vli", "tri", "kree", "zrit", "pree", "skrit", "kli",
		"shree", "tchi", "vree", "kri", "zri", "shkree", "tiv", "lit", "skra", "krrr",
		"tik", "klik", "prik", "skrik", "vrik", "trik", "zrik", "shrik", "krik", "va",
		"si", "li", "re", "so", "mi", "ka", "tu", "ra", "tsi", "kree-ah", "vlee-it",
		"skree-at", "chri-it", "zree-al", "tkri", "skli", "vri", "zra",
	)
	mutual_understanding = list(
		/datum/language/vox = 20,
	)

/datum/language/resomi/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	var/static/list/name_starts = list(
		"Ме", "Ши", "Ре", "Ас", "Им", "За", "Ки", "Ли", "Ти", "Ва", "Ни", "Хо", "Се", "Ми", "Па",
		"Ри", "Те", "Ко", "Си", "Лу", "Кри", "Тка", "Фло", "Ма", "Не", "Ос", "Ве", "Зи", "Юн",
	)
	var/static/list/name_ends = list(
		"ути", "рива", "тини", "сиер", "аки", "ери", "зи", "ива", "ель", "оми", "ата", "уна", "кит", "лис",
		"вет", "ани", "ро", "та", "ми", "не", "тра", "ка", "ири", "ко", "ла", "на", "ри", "си", "ти", "вэ",
	)
	return "[pick(name_starts)][pick(name_ends)]"
