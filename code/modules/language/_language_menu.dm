/datum/language_menu
	var/datum/language_holder/language_holder

/datum/language_menu/New(_language_holder)
	language_holder = _language_holder

/datum/language_menu/Destroy()
	language_holder = null
	. = ..()

/datum/language_menu/ui_state(mob/user)
	return GLOB.language_menu_state

/datum/language_menu/ui_interact(mob/user, datum/tgui/ui)
	if(isnull(language_holder.selected_language))
		language_holder.get_selected_language()

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LanguageMenu")
		ui.open()

/datum/language_menu/ui_data(mob/user)
	var/list/data = list()

	var/atom/movable/speaker = language_holder.owner
	var/list/partial_languages = speaker?.get_partially_understood_languages()
	data["languages"] = list()
	for(var/datum/language/language as anything in GLOB.all_languages)
		var/list/lang_data = list()

		lang_data["name"] = language::name
		lang_data["desc"] = language::desc
		lang_data["key"] = language::key
		lang_data["is_default"] = (language == language_holder.selected_language)
		lang_data["icon"] = language::icon
		lang_data["icon_state"] = language::icon_state
		if(speaker)
			lang_data["can_speak"] = !!speaker.has_language(language, SPOKEN_LANGUAGE)
			lang_data["could_speak"] = !!(language_holder.omnitongue || speaker.could_speak_language(language))
			lang_data["can_understand"] = !!speaker.has_language(language, UNDERSTOOD_LANGUAGE)
			lang_data["partial_understanding"] = partial_languages?[language] || 0

		UNTYPED_LIST_ADD(data["languages"], lang_data)

	data["is_living"] = isliving(speaker)
	data["admin_mode"] = check_rights_for(user.client, R_ADMIN) || isobserver(speaker)
	data["omnitongue"] = language_holder.omnitongue

	return data

/datum/language_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	var/atom/movable/speaker = language_holder.owner
	var/is_admin = check_rights_for(user.client, R_ADMIN)
	var/language_name = params["language_name"]
	var/datum/language/language_datum = GLOB.language_types_by_name[language_name]

	switch(action)
		if("select_default")
			if(language_datum && speaker.can_speak_language(language_datum))
				language_holder.selected_language = language_datum
				. = TRUE
		if("grant_language")
			if((is_admin || isobserver(speaker)) && language_datum)
				var/list/choices = list("Только говорить", "Только понимать", "Оба")
				var/choice = tgui_input_list(user, "Как выдать этот язык?", "[language_name]", choices)
				if(isnull(choice))
					return
				var/adding_flags = NONE
				switch(choice)
					if("Только говорить")
						adding_flags |= SPOKEN_LANGUAGE
					if("Только понимать")
						adding_flags |= UNDERSTOOD_LANGUAGE
					if("Оба")
						adding_flags |= ALL

				var/ask_to_remove_block
				var/list/block_being_removed_on = list()
				if(adding_flags & SPOKEN_LANGUAGE && LAZYACCESS(language_holder.blocked_speaking, language_datum))
					ask_to_remove_block = TRUE
					block_being_removed_on += "говорить"

				if(ask_to_remove_block)
					choice = tgui_alert(user, "Снять блокировку, которая не даёт [block_being_removed_on.Join(" или ")] на этом языке?", "[language_name]", list("Да", "Нет"))
					if(choice == "Да")
						language_holder.remove_blocked_language(language_datum, adding_flags, LANGUAGE_ALL)
				language_holder.grant_language(language_datum, adding_flags)
				if(is_admin)
					message_admins("[key_name_admin(user)] granted the [language_name] language to [key_name_admin(speaker)].")
					log_admin("[key_name(user)] granted the language [language_name] to [key_name(speaker)].")
				. = TRUE
		if("remove_language")
			if((is_admin || isobserver(speaker)) && language_datum)
				var/list/choices = list("Только говорить", "Только понимать", "Оба")
				var/choice = tgui_input_list(user, "Что убрать?", "[language_name]", choices)
				if(isnull(choice))
					return
				var/removing_flags = NONE
				switch(choice)
					if("Только говорить")
						removing_flags |= SPOKEN_LANGUAGE
					if("Только понимать")
						removing_flags |= UNDERSTOOD_LANGUAGE
					if("Оба")
						removing_flags |= ALL

				language_holder.remove_language(language_datum, removing_flags)
				if(is_admin)
					message_admins("[key_name_admin(user)] removed the [language_name] language to [key_name_admin(speaker)].")
					log_admin("[key_name(user)] removed the language [language_name] to [key_name(speaker)].")
				. = TRUE
		if("toggle_omnitongue")
			if(is_admin || isobserver(speaker))
				language_holder.omnitongue = !language_holder.omnitongue
				if(is_admin)
					message_admins("[key_name_admin(user)] [language_holder.omnitongue ? "enabled" : "disabled"] the ability to speak all languages (that they know) of [key_name_admin(speaker)].")
					log_admin("[key_name(user)] [language_holder.omnitongue ? "enabled" : "disabled"] the ability to speak all languages (that_they know) of [key_name(speaker)].")
				. = TRUE

GAME_VERB(/mob, check_languages, "Меню языков", VERB_CATEGORY_IC)
	get_language_holder().open_language_menu(src)
