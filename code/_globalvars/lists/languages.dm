GLOBAL_LIST_INIT_TYPED(language_datum_instances, /datum/language, init_language_prototypes())
GLOBAL_LIST_INIT(all_languages, init_all_languages())
GLOBAL_LIST_INIT(language_types_by_name, init_language_types_by_name())
GLOBAL_LIST_INIT(language_keys, init_language_keys())
GLOBAL_LIST_INIT(most_common_words_frequency, init_common_words_by_frequency())

/proc/init_language_prototypes()
	var/list/lang_list = list()
	for(var/datum/language/lang_type as anything in valid_subtypesof(/datum/language))
		lang_list[lang_type] = new lang_type()
	return lang_list

/proc/init_all_languages()
	var/list/lang_list = list()
	for(var/datum/language/lang_type as anything in valid_subtypesof(/datum/language))
		lang_list += lang_type
	return lang_list

/proc/init_language_types_by_name()
	var/list/lang_list = list()
	for(var/datum/language/lang_type as anything in valid_subtypesof(/datum/language))
		lang_list[initial(lang_type.name)] = lang_type
	return lang_list

/proc/init_language_keys()
	var/list/keys = list()
	for(var/datum/language/lang_type as anything in valid_subtypesof(/datum/language))
		var/key = initial(lang_type.key)
		if(!key)
			continue
		for(var/prefix in list(":", ".", "#"))
			keys["[prefix][lowertext(key)]"] = lang_type
			keys["[prefix][sanitize_english_string_to_russian(key)]"] = lang_type
	return keys

/proc/init_common_words_by_frequency()
	var/list/word_to_commonness_list = list()
	for(var/word in world.file2list("strings/most_common_words.txt"))
		if(word)
			word_to_commonness_list[word] = 500
	return word_to_commonness_list
