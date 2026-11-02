/datum/language/codespeak
	name = "Кодовый язык"
	desc = "Оперативники Синдиката используют набор кодовых слов, чтобы передавать сложную информацию. Для остальных это звучит как случайные понятия и названия напитков."
	key = "cd"
	flags = LANGUAGE_TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD | LANGUAGE_RESTRICTED | LANGUAGE_NOBABEL
	icon_state = "codespeak"
	always_use_default_namelist = TRUE

/datum/language/codespeak/scramble_sentence(input, list/mutual_languages)
	var/sentence = read_word_cache(input)
	if(sentence)
		return sentence

	sentence = ""
	var/list/words = list()
	while(length_char(sentence) < length_char(input))
		words += generate_code_phrase(return_list = TRUE)
		sentence = jointext(words, ", ")

	sentence = capitalize(sentence)

	sentence += find_last_punctuation(input)

	write_word_cache(input, sentence)

	return sentence
