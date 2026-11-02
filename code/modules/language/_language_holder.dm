/datum/language_holder
	var/list/understood_languages
	var/list/spoken_languages
	var/list/blocked_understanding
	var/list/blocked_speaking
	var/omnitongue = FALSE
	VAR_FINAL/datum/language_menu/language_menu
	var/selected_language
	VAR_FINAL/atom/movable/owner
	VAR_PROTECTED/list/mutual_understanding
	VAR_FINAL/list/best_mutual_languages

/datum/language_holder/New(atom/new_owner)
	if(new_owner)
		if(QDELETED(new_owner))
			CRASH("Language holder added to a qdeleting thing, what the fuck [text_ref(new_owner)]")
		if(!ismovable(new_owner))
			CRASH("Language holder being added to a non-movable thing, this is invalid (was: [new_owner] / [new_owner.type])")

	owner = new_owner

	if(owner)
		get_selected_language()
	for(var/language in understood_languages)
		gain_partial_understanding_from_language(language)

/datum/language_holder/Destroy()
	QDEL_NULL(language_menu)
	owner = null
	return ..()

/datum/language_holder/proc/gain_partial_understanding_from_language(language)
	PRIVATE_PROC(TRUE)

	var/datum/language/prototype = GLOB.language_datum_instances[language]
	for(var/other_language in prototype.mutual_understanding)
		grant_partial_language(other_language, prototype.mutual_understanding[other_language], language)

/datum/language_holder/proc/lose_partial_understanding_from_language(language)
	PRIVATE_PROC(TRUE)

	var/datum/language/prototype = GLOB.language_datum_instances[language]
	for(var/other_language in prototype.mutual_understanding)
		remove_partial_language(other_language, language)

/datum/language_holder/proc/calculate_best_mutual_language()
	best_mutual_languages = list()
	for(var/language in mutual_understanding)
		for(var/source in mutual_understanding[language])
			if(LAZYACCESS(blocked_understanding, source))
				continue
			if(!best_mutual_languages[language] || best_mutual_languages[language] < mutual_understanding[language][source])
				best_mutual_languages[language] = mutual_understanding[language][source]

/datum/language_holder/proc/grant_language(language, language_flags = ALL, source = LANGUAGE_MIND)
	if(language_flags & UNDERSTOOD_LANGUAGE)
		LAZYORASSOCLIST(understood_languages, language, source)
		gain_partial_understanding_from_language(language)
		. = TRUE
	if(language_flags & SPOKEN_LANGUAGE)
		LAZYORASSOCLIST(spoken_languages, language, source)
		. = TRUE

	return .

/datum/language_holder/proc/grant_all_languages(language_flags = ALL, grant_omnitongue = TRUE, source = LANGUAGE_MIND)
	for(var/language in GLOB.all_languages)
		grant_language(language, language_flags, source)
	if(grant_omnitongue)
		omnitongue = TRUE
	return TRUE

/datum/language_holder/proc/grant_all_babel_languages(language_flags = ALL, source = LANGUAGE_MIND)
	for(var/datum/language/language as anything in GLOB.all_languages)
		if(language::flags & LANGUAGE_NOBABEL)
			continue
		grant_language(language, language_flags, source)
	return TRUE

/datum/language_holder/proc/grant_partial_language(language, amount = 50, source = LANGUAGE_MIND)
	LAZYINITLIST(mutual_understanding)
	LAZYSET(mutual_understanding[language], source, amount)
	calculate_best_mutual_language()
	return TRUE

/datum/language_holder/proc/remove_language(language, language_flags = ALL, source = LANGUAGE_ALL)
	if(language_flags & UNDERSTOOD_LANGUAGE)
		if(source == LANGUAGE_ALL)
			LAZYREMOVE(understood_languages, language)
		else
			LAZYREMOVEASSOC(understood_languages, language, source)
		if(!LAZYACCESS(understood_languages, language))
			lose_partial_understanding_from_language(language)
		. = TRUE

	if(language_flags & SPOKEN_LANGUAGE)
		if(source == LANGUAGE_ALL)
			LAZYREMOVE(spoken_languages, language)
		else
			LAZYREMOVEASSOC(spoken_languages, language, source)
		. = TRUE

	return .

/datum/language_holder/proc/remove_all_languages(source = LANGUAGE_ALL, remove_omnitongue = FALSE)
	for(var/language in GLOB.all_languages)
		remove_language(language, ALL, source)
	if(remove_omnitongue)
		omnitongue = FALSE
	return TRUE

/datum/language_holder/proc/remove_partial_language(language, source = LANGUAGE_MIND)
	. = FALSE
	if(source == LANGUAGE_ALL)
		for(var/other_source in mutual_understanding[language])
			if(ispath(other_source, /datum/language))
				continue
			. = remove_partial_language(language, other_source) || .
	else if(LAZYACCESSASSOC(mutual_understanding, language, source))
		LAZYREMOVE(mutual_understanding[language], source)
		ASSOC_UNSETEMPTY(mutual_understanding, language)
		UNSETEMPTY(mutual_understanding)
		. = TRUE

	if(.)
		calculate_best_mutual_language()
	return .

/datum/language_holder/proc/remove_all_partial_languages(source = LANGUAGE_MIND)
	for(var/language in mutual_understanding)
		remove_partial_language(language, source)
	return TRUE

/datum/language_holder/proc/add_blocked_language(languages, language_flags = ALL, source = LANGUAGE_MIND)
	if(!islist(languages))
		languages = list(languages)

	for(var/language in languages)
		if(language_flags & SPOKEN_LANGUAGE)
			LAZYORASSOCLIST(blocked_speaking, language, source)
		if(language_flags & UNDERSTOOD_LANGUAGE)
			LAZYORASSOCLIST(blocked_understanding, language, source)
	calculate_best_mutual_language()
	return TRUE

/datum/language_holder/proc/remove_blocked_language(languages, language_flags = ALL, source = LANGUAGE_MIND)
	if(!islist(languages))
		languages = list(languages)

	for(var/language in languages)
		if(source == LANGUAGE_ALL)
			if(language_flags & SPOKEN_LANGUAGE)
				LAZYREMOVE(blocked_speaking, language)
			if(language_flags & UNDERSTOOD_LANGUAGE)
				LAZYREMOVE(blocked_understanding, language)
		else
			if(language_flags & SPOKEN_LANGUAGE)
				LAZYREMOVEASSOC(blocked_speaking, language, source)
			if(language_flags & UNDERSTOOD_LANGUAGE)
				LAZYREMOVEASSOC(blocked_understanding, language, source)
	calculate_best_mutual_language()
	return TRUE

/datum/language_holder/proc/has_language(language, flag_to_check = UNDERSTOOD_LANGUAGE)
	var/list/langs_to_check = list()
	if(flag_to_check & SPOKEN_LANGUAGE && !LAZYACCESS(blocked_speaking, language))
		langs_to_check |= spoken_languages
	if(flag_to_check & UNDERSTOOD_LANGUAGE && !LAZYACCESS(blocked_understanding, language))
		langs_to_check |= understood_languages

	return language in langs_to_check

/datum/language_holder/proc/has_partial_language(language)
	return LAZYACCESS(best_mutual_languages, language)

/datum/language_holder/proc/can_speak_language(language)
	var/can_speak_language_path = omnitongue || owner.could_speak_language(language)
	return (can_speak_language_path && has_language(language, SPOKEN_LANGUAGE))

/datum/language_holder/proc/get_selected_language()
	if(selected_language && can_speak_language(selected_language))
		return selected_language
	selected_language = null
	var/highest_priority
	for(var/lang in spoken_languages)
		var/datum/language/language = lang
		var/priority = initial(language.default_priority)
		if((!highest_priority || (priority > highest_priority)) && !(language in blocked_speaking))
			if(can_speak_language(language))
				selected_language = language
				highest_priority = priority
	return selected_language

/datum/language_holder/proc/get_random_understood_language()
	return pick(understood_languages)

/datum/language_holder/proc/get_random_spoken_language()
	return pick(spoken_languages)

/datum/language_holder/proc/get_random_spoken_uncommon_language()
	var/list/languages_minus_common = assoc_to_keys(spoken_languages) - /datum/language/common

	if(length(languages_minus_common))
		return pick(languages_minus_common)

	return /datum/language/common

/datum/language_holder/proc/get_understood_languages()
	return assoc_to_keys(understood_languages) - assoc_to_keys(blocked_understanding)

/datum/language_holder/proc/get_mind_languages()
	var/list/mind_languages = list()
	for(var/language in spoken_languages)
		if(LANGUAGE_MIND in spoken_languages[language])
			mind_languages += language
	return mind_languages

/datum/language_holder/proc/open_language_menu(mob/user)
	if(!language_menu)
		language_menu = new (src)
	language_menu.ui_interact(user)

/datum/language_holder/proc/copy_languages(datum/language_holder/from_holder, source_override)
	if(source_override)
		for(var/language in from_holder.understood_languages)
			grant_language(language, UNDERSTOOD_LANGUAGE, source_override)
		for(var/language in from_holder.spoken_languages)
			grant_language(language, SPOKEN_LANGUAGE, source_override)
	else
		for(var/language in from_holder.understood_languages)
			grant_language(language, UNDERSTOOD_LANGUAGE, from_holder.understood_languages[language])
		for(var/language in from_holder.spoken_languages)
			grant_language(language, SPOKEN_LANGUAGE, from_holder.spoken_languages[language])
		for(var/language in from_holder.blocked_speaking)
			add_blocked_language(language, SPOKEN_LANGUAGE, from_holder.blocked_speaking[language])
		for(var/language in from_holder.blocked_understanding)
			add_blocked_language(language, UNDERSTOOD_LANGUAGE, from_holder.blocked_understanding[language])
	return TRUE

/datum/language_holder/proc/transfer_mind_languages(datum/language_holder/to_holder)
	for(var/language in understood_languages)
		if(LANGUAGE_MIND in understood_languages[language])
			remove_language(language, UNDERSTOOD_LANGUAGE, LANGUAGE_MIND)
			to_holder.grant_language(language, UNDERSTOOD_LANGUAGE, LANGUAGE_MIND)
	for(var/language in spoken_languages)
		if(LANGUAGE_MIND in spoken_languages[language])
			remove_language(language, SPOKEN_LANGUAGE, LANGUAGE_MIND)
			to_holder.grant_language(language, SPOKEN_LANGUAGE, LANGUAGE_MIND)
	for(var/language in blocked_speaking)
		if(LANGUAGE_MIND in blocked_speaking[language])
			remove_blocked_language(language, SPOKEN_LANGUAGE, LANGUAGE_MIND)
			to_holder.add_blocked_language(language, SPOKEN_LANGUAGE, LANGUAGE_MIND)
	for(var/language in blocked_understanding)
		if(LANGUAGE_MIND in blocked_understanding[language])
			remove_blocked_language(language, UNDERSTOOD_LANGUAGE, LANGUAGE_MIND)
			to_holder.add_blocked_language(language, UNDERSTOOD_LANGUAGE, LANGUAGE_MIND)
	for(var/language in mutual_understanding)
		var/mind_understanding = mutual_understanding[language][LANGUAGE_MIND]
		if(mind_understanding > 0)
			remove_partial_language(language, LANGUAGE_MIND)
			to_holder.grant_partial_language(language, mind_understanding, LANGUAGE_MIND)

	if(owner)
		get_selected_language()
	if(to_holder.owner)
		to_holder.get_selected_language()

GLOBAL_LIST_INIT(prototype_language_holders, init_language_holder_prototypes())

/proc/init_language_holder_prototypes()
	var/list/prototypes = list()
	for(var/holdertype in typesof(/datum/language_holder))
		prototypes[holdertype] = new holdertype()

	return prototypes

/datum/language_holder/atom_basic
	understood_languages = list(/datum/language/common = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/common = list(LANGUAGE_ATOM))

/datum/language_holder/empty

/datum/language_holder/universal

/datum/language_holder/universal/New()
	. = ..()
	grant_all_languages(source = LANGUAGE_ATOM)

/datum/language_holder/understand_all

/datum/language_holder/understand_all/New()
	. = ..()
	grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)

/datum/language_holder/human_basic
	understood_languages = list(/datum/language/common = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/common = list(LANGUAGE_ATOM))

/datum/language_holder/human
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/human = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/human = list(LANGUAGE_ATOM),
	)

/datum/language_holder/unathi
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/unathi = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/unathi = list(LANGUAGE_ATOM),
	)

/datum/language_holder/unathi/ash
	understood_languages = list(/datum/language/unathi = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/unathi = list(LANGUAGE_ATOM))
	selected_language = /datum/language/unathi

/datum/language_holder/tajaran
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/tajaran = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/tajaran = list(LANGUAGE_ATOM),
	)

/datum/language_holder/vulpkanin
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/vulpkanin = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/vulpkanin = list(LANGUAGE_ATOM),
	)

/datum/language_holder/skrell
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/skrell = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/skrell = list(LANGUAGE_ATOM),
	)

/datum/language_holder/vox
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/vox = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/vox = list(LANGUAGE_ATOM),
	)

/datum/language_holder/diona
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/diona = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/diona = list(LANGUAGE_ATOM),
	)

/datum/language_holder/diona/nymph
	understood_languages = list(/datum/language/diona = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/diona = list(LANGUAGE_ATOM))

/datum/language_holder/drask
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/drask = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/drask = list(LANGUAGE_ATOM),
	)

/datum/language_holder/kidan
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/kidan = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/kidan = list(LANGUAGE_ATOM),
	)

/datum/language_holder/moth
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/moth = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/moth = list(LANGUAGE_ATOM),
	)

/datum/language_holder/resomi
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/resomi = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/resomi = list(LANGUAGE_ATOM),
	)

/datum/language_holder/slime
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/slime = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/slime = list(LANGUAGE_ATOM),
	)

/datum/language_holder/slime/simple
	understood_languages = list(/datum/language/slime = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/slime = list(LANGUAGE_ATOM))

/datum/language_holder/machine
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/trinary = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/trinary = list(LANGUAGE_ATOM),
	)

/datum/language_holder/skeleton
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/calcic = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/calcic = list(LANGUAGE_ATOM),
	)

/datum/language_holder/golem
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/terrum = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/terrum = list(LANGUAGE_ATOM),
	)

/datum/language_holder/monkey
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/human/monkey = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/human/monkey = list(LANGUAGE_ATOM),
	)
	selected_language = /datum/language/human/monkey

/datum/language_holder/monkey/tajaran
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/tajaran/monkey = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/tajaran/monkey = list(LANGUAGE_ATOM),
	)
	selected_language = /datum/language/tajaran/monkey

/datum/language_holder/monkey/vulpkanin
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/vulpkanin/monkey = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/vulpkanin/monkey = list(LANGUAGE_ATOM),
	)
	selected_language = /datum/language/vulpkanin/monkey

/datum/language_holder/monkey/skrell
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/skrell/monkey = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/skrell/monkey = list(LANGUAGE_ATOM),
	)
	selected_language = /datum/language/skrell/monkey

/datum/language_holder/monkey/unathi
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/unathi/monkey = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/unathi/monkey = list(LANGUAGE_ATOM),
	)
	selected_language = /datum/language/unathi/monkey

/datum/language_holder/alien
	understood_languages = list(/datum/language/xenocommon = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/xenocommon = list(LANGUAGE_ATOM))

/datum/language_holder/drone
	understood_languages = list(/datum/language/drone = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/drone = list(LANGUAGE_ATOM))

/datum/language_holder/drone/New()
	. = ..()
	grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)

/datum/language_holder/carp
	understood_languages = list(/datum/language/carptongue = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/carptongue = list(LANGUAGE_ATOM))
	selected_language = /datum/language/carptongue

/datum/language_holder/carp/dragon
	understood_languages = list(
		/datum/language/carptongue = list(LANGUAGE_ATOM),
		/datum/language/common = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/carptongue = list(LANGUAGE_ATOM),
	)

/datum/language_holder/carp/hear_common
	understood_languages = list(
		/datum/language/carptongue = list(LANGUAGE_ATOM),
		/datum/language/common = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/carptongue = list(LANGUAGE_ATOM),
	)

/datum/language_holder/venus
	understood_languages = list(/datum/language/sylvan = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/sylvan = list(LANGUAGE_ATOM))

/datum/language_holder/spider
	understood_languages = list(/datum/language/buzzwords = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/buzzwords = list(LANGUAGE_ATOM))

/datum/language_holder/mushroom
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/mushroom = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/mushroom = list(LANGUAGE_ATOM),
	)

/datum/language_holder/mushroom/simple
	understood_languages = list(/datum/language/mushroom = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/mushroom = list(LANGUAGE_ATOM))

/datum/language_holder/plant
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/sylvan = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/sylvan = list(LANGUAGE_ATOM),
	)

/datum/language_holder/construct
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/narsie = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/narsie = list(LANGUAGE_ATOM),
	)

/datum/language_holder/synthetic
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/uncommon = list(LANGUAGE_ATOM),
		/datum/language/machine = list(LANGUAGE_ATOM),
		/datum/language/human = list(LANGUAGE_ATOM),
		/datum/language/trader = list(LANGUAGE_ATOM),
		/datum/language/com_srus = list(LANGUAGE_ATOM),
		/datum/language/gutter = list(LANGUAGE_ATOM),
		/datum/language/unathi = list(LANGUAGE_ATOM),
		/datum/language/tajaran = list(LANGUAGE_ATOM),
		/datum/language/vulpkanin = list(LANGUAGE_ATOM),
		/datum/language/skrell = list(LANGUAGE_ATOM),
		/datum/language/vox = list(LANGUAGE_ATOM),
		/datum/language/drask = list(LANGUAGE_ATOM),
		/datum/language/diona = list(LANGUAGE_ATOM),
		/datum/language/trinary = list(LANGUAGE_ATOM),
		/datum/language/kidan = list(LANGUAGE_ATOM),
		/datum/language/slime = list(LANGUAGE_ATOM),
		/datum/language/clown = list(LANGUAGE_ATOM),
		/datum/language/moth = list(LANGUAGE_ATOM),
		/datum/language/resomi = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/uncommon = list(LANGUAGE_ATOM),
		/datum/language/machine = list(LANGUAGE_ATOM),
		/datum/language/human = list(LANGUAGE_ATOM),
		/datum/language/trader = list(LANGUAGE_ATOM),
		/datum/language/com_srus = list(LANGUAGE_ATOM),
		/datum/language/gutter = list(LANGUAGE_ATOM),
		/datum/language/unathi = list(LANGUAGE_ATOM),
		/datum/language/tajaran = list(LANGUAGE_ATOM),
		/datum/language/vulpkanin = list(LANGUAGE_ATOM),
		/datum/language/skrell = list(LANGUAGE_ATOM),
		/datum/language/vox = list(LANGUAGE_ATOM),
		/datum/language/drask = list(LANGUAGE_ATOM),
		/datum/language/diona = list(LANGUAGE_ATOM),
		/datum/language/trinary = list(LANGUAGE_ATOM),
		/datum/language/kidan = list(LANGUAGE_ATOM),
		/datum/language/slime = list(LANGUAGE_ATOM),
		/datum/language/clown = list(LANGUAGE_ATOM),
		/datum/language/moth = list(LANGUAGE_ATOM),
		/datum/language/resomi = list(LANGUAGE_ATOM),
	)

/datum/language_holder/synthetic/robot
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/machine = list(LANGUAGE_ATOM),
	)

/datum/language_holder/synthetic/robot/New()
	. = ..()
	grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)

/datum/language_holder/synthetic/pai
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/machine = list(LANGUAGE_ATOM),
		/datum/language/human = list(LANGUAGE_ATOM),
		/datum/language/trader = list(LANGUAGE_ATOM),
		/datum/language/gutter = list(LANGUAGE_ATOM),
		/datum/language/trinary = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/machine = list(LANGUAGE_ATOM),
		/datum/language/human = list(LANGUAGE_ATOM),
		/datum/language/trader = list(LANGUAGE_ATOM),
		/datum/language/gutter = list(LANGUAGE_ATOM),
		/datum/language/trinary = list(LANGUAGE_ATOM),
	)
