#define SCRAMBLE_CACHE_LEN 50
#define SENTENCE_CACHE_LEN 20

/datum/language
	abstract_type = /datum/language
	var/name = "an unknown language"
	var/desc = "A language."
	var/key
	var/flags = NONE
	var/list/syllables
	var/list/special_characters
	var/join_override

	var/sentence_chance = 2
	var/between_word_sentence_chance = 0
	var/space_chance = 20
	var/between_word_space_chance = 100
	var/additional_syllable_low = -1
	var/additional_syllable_high = 3

	var/list/spans
	var/runechat_span
	var/list/speech_verbs = list("говор%(ит,ят)%")
	var/list/ask_verbs = list("спрашива%(ет,ют)%")
	var/list/exclaim_verbs = list("восклица%(ет,ют)%", "выкрикива%(ет,ют)%")
	var/list/whisper_verbs

	VAR_PRIVATE/list/scramble_cache = list()
	VAR_PRIVATE/list/most_common_cache = list()
	VAR_PRIVATE/list/last_sentence_cache = list()

	var/default_priority = 0
	var/always_use_default_namelist = FALSE
	var/icon = 'icons/ui/chat/language.dmi'
	var/icon_state = "unknown"

	var/default_name_count = 2
	var/default_name_syllable_min = 2
	var/default_name_syllable_max = 4
	var/random_name_spacer = " "

	var/list/mutual_understanding

/datum/language/vv_edit_var(var_name, var_value)
	. = ..()
	var/list/delete_cache = list(
		NAMEOF(src, additional_syllable_high),
		NAMEOF(src, additional_syllable_low),
		NAMEOF(src, between_word_sentence_chance),
		NAMEOF(src, between_word_space_chance),
		NAMEOF(src, sentence_chance),
		NAMEOF(src, space_chance),
		NAMEOF(src, special_characters),
		NAMEOF(src, syllables),
	)
	if(var_name in delete_cache)
		scramble_cache.Cut()
		most_common_cache.Cut()
		last_sentence_cache.Cut()

/datum/language/proc/display_icon_type(atom/movable/hearer, list/message_mods)
	if(hearer.has_language(type))
		if(flags & LANGUAGE_HIDE_ICON_IF_UNDERSTOOD)
			return DISPLAY_LANGUAGE_ICON_NONE

	else
		if(hearer.has_partial_language(type) || LAZYACCESSASSOC(message_mods, LANGUAGE_MUTUAL_BONUS, type))
			return DISPLAY_LANGUAGE_ICON_PARTIAL
		if(flags & LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD)
			return DISPLAY_LANGUAGE_ICON_NONE

	return DISPLAY_LANGUAGE_ICON_FULL

/datum/language/proc/default_name(gender = NEUTER)
	if(gender != MALE && gender != FEMALE)
		gender = pick(MALE, FEMALE)
	if(gender == FEMALE)
		return capitalize(pick(GLOB.first_names_female)) + " " + capitalize(pick(GLOB.last_names_female))
	return capitalize(pick(GLOB.first_names_male)) + " " + capitalize(pick(GLOB.last_names_male))

/datum/language/proc/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	if(gender != MALE && gender != FEMALE)
		gender = pick(MALE, FEMALE)
	if(!length(syllables) || always_use_default_namelist)
		return default_name(gender)

	var/list/full_name = list()
	for(var/i in 1 to name_count)
		var/new_name = ""
		for(var/j in 1 to rand(default_name_syllable_min, default_name_syllable_max))
			new_name += pick_weight_recursive(syllables)
		full_name += capitalize(LOWER_TEXT(new_name))

	return jointext(full_name, random_name_spacer)

/datum/language/proc/get_random_unique_name(...)
	var/result = get_random_name(arglist(args))
	for(var/i in 1 to 10)
		if(!findname(result))
			break
		result = get_random_name(arglist(args))

	return result

/datum/language/proc/read_word_cache(input)
	SHOULD_NOT_OVERRIDE(TRUE)
	var/lowertext_input = LOWER_TEXT(input)
	if(most_common_cache[lowertext_input])
		return most_common_cache[lowertext_input]

	. = scramble_cache[lowertext_input]
	if(. && scramble_cache[1] != lowertext_input)
		scramble_cache -= lowertext_input
		scramble_cache[lowertext_input] = .
	return .

/datum/language/proc/write_word_cache(input, scrambled_text)
	SHOULD_NOT_OVERRIDE(TRUE)
	var/lowertext_input = LOWER_TEXT(input)
	if(GLOB.most_common_words_frequency[lowertext_input])
		most_common_cache[lowertext_input] = scrambled_text
		return
	scramble_cache[lowertext_input] = scrambled_text
	if(length(scramble_cache) > SCRAMBLE_CACHE_LEN)
		scramble_cache.Cut(1, scramble_cache.len - SCRAMBLE_CACHE_LEN + 1)

/datum/language/proc/read_sentence_cache(input)
	SHOULD_NOT_OVERRIDE(TRUE)
	var/input_capitalized = capitalize(input)
	. = last_sentence_cache[input_capitalized]
	if(. && last_sentence_cache[1] != input_capitalized)
		last_sentence_cache -= input_capitalized
		last_sentence_cache[input_capitalized] = .
	return .

/datum/language/proc/write_sentence_cache(input, key, result_scramble)
	SHOULD_NOT_OVERRIDE(TRUE)
	var/input_capitalized = capitalize(input)
	LAZYSET(last_sentence_cache[input_capitalized], key, result_scramble)
	if(length(last_sentence_cache) > SENTENCE_CACHE_LEN)
		last_sentence_cache.Cut(1, last_sentence_cache.len - SENTENCE_CACHE_LEN + 1)

/datum/language/proc/scramble_paragraph(input, list/mutual_languages)
	if(mutual_languages?[type] >= 100)
		return input

	var/static/regex/first_sentence = regex(@"(.+?(?:[\.!\?]|$))", "g")
	var/list/new_paragraph = list()
	while(first_sentence.Find(input))
		new_paragraph += scramble_sentence(trim(first_sentence.group[1]), mutual_languages)
	return jointext(new_paragraph, " ")

/datum/language/proc/scramble_sentence(input, list/mutual_languages)
	var/cache_key = "[mutual_languages?[type] || 0]-understanding"
	var/list/cache = read_sentence_cache(input)
	if(cache?[cache_key])
		return cache[cache_key]

	var/list/scrambled_words = list()
	var/list/translated_index = list()
	for(var/word in splittext(input, " "))
		var/translate_prob = mutual_languages?[type] || 0
		var/base_word = strip_outer_punctuation(html_decode(word))
		if(translate_prob > 0)
			var/commonness = GLOB.most_common_words_frequency[LOWER_TEXT(base_word)] || 1250
			translate_prob += max(20 - (commonness / 1000) * 20, -5)
			if(prob(translate_prob))
				scrambled_words += word
				translated_index += FALSE
				continue

		var/scrambled_word = scramble_word(base_word)
		scrambled_words += scrambled_word
		translated_index += (scrambled_word != base_word)

	var/sentence = capitalize(scrambled_words[1])
	for(var/i in 2 to length(scrambled_words))
		var/word = scrambled_words[i]
		if(!translated_index[i])
			sentence += " [word]"
			continue
		if(join_override)
			sentence += join_override
		else if(translated_index[i - 1] || prob(between_word_space_chance))
			sentence += " "
		else if(prob(between_word_sentence_chance))
			sentence += ". "
			word = capitalize(word)

		sentence += word

	if(translated_index[length(scrambled_words)])
		sentence += find_last_punctuation(input)

	write_sentence_cache(input, cache_key, sentence)

	return sentence

/datum/language/proc/scramble_word(input)
	var/word = read_word_cache(input)
	if(word)
		return (is_uppercase(input) && length_char(input) >= 2) ? uppertext(word) : word

	if(!length(syllables))
		word = stars(input)

	else
		var/input_size = max(length_char(input) + rand(additional_syllable_low, additional_syllable_high), 1)
		var/add_space = FALSE
		var/add_period = FALSE
		word = ""
		while(length_char(word) < input_size)
			if(join_override && word)
				word += join_override
			else if(add_period)
				word += ". "
			else if(add_space)
				word += " "
			else if(word && prob(1) && length(special_characters))
				word += pick(special_characters)
			var/next = pick_weight_recursive(syllables)
			word += add_period ? capitalize(next) : next
			add_period = prob(sentence_chance)
			add_space = prob(space_chance)

	write_word_cache(input, word)

	return (is_uppercase(input) && length_char(input) >= 2) ? uppertext(word) : word

/datum/language/proc/get_spoken_verb(msg_end)
	switch(msg_end)
		if("!")
			return pick(exclaim_verbs)
		if("?")
			return pick(ask_verbs)
	return pick(speech_verbs)

/proc/get_language_prefix(datum/language/language_type)
	var/key = initial(language_type.key)
	if(!key)
		CRASH("[language_type] has no key.")
	return ":[key] "

#undef SCRAMBLE_CACHE_LEN
#undef SENTENCE_CACHE_LEN
