/datum/language/carptongue
	name = "Карпий"
	desc = "Разнообразные рыбьи звуки, в которых, возможно, есть смысл для космических карпов."
	speech_verbs = list("булька%(ет,ют)%")
	ask_verbs = list("вопросительно булька%(ет,ют)%")
	exclaim_verbs = list("громко булька%(ет,ют)%")
	key = "cr"
	icon_state = "fish"
	flags = LANGUAGE_NO_STUTTER | LANGUAGE_TONGUELESS_SPEECH | LANGUAGE_RESTRICTED
	sentence_chance = 0
	space_chance = 0
	between_word_space_chance = 75
	additional_syllable_low = -2
	additional_syllable_high = -1
	syllables = list("glub", "blub", "bloop")
	default_priority = 25
	default_name_syllable_min = 1
	default_name_syllable_max = 2
