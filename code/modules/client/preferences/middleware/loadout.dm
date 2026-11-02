/datum/preference_middleware/loadout
	action_delegations = list(
		"clear_all_items" = PROC_REF(action_clear_all),
		"pass_to_loadout_item" = PROC_REF(action_pass_to_loadout_item),
		"rotate_dummy" = PROC_REF(action_rotate_model_dir),
		"select_item" = PROC_REF(action_select_item),
		"toggle_job_clothes" = PROC_REF(action_toggle_job_outfit),
		"close_greyscale_menu" = PROC_REF(action_close_modify_menu),
	)

/datum/preference_middleware/loadout/proc/action_select_item(list/params, mob/user)
	var/datum/gear/gear = GLOB.gear_datums[params["path"]]
	if(!istype(gear))
		return TRUE

	if(params["deselect"])
		preferences.loadout_gear -= gear.index_name
	else if(!select_item(gear, user))
		return FALSE

	preferences.form_choosen_gears()
	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/loadout/proc/select_item(datum/gear/gear, mob/user)
	if(gear.index_name in preferences.loadout_gear)
		return FALSE
	if(!gear.can_select(user.client, species_name = preferences.read_preference(/datum/preference/choiced/species)))
		return FALSE

	preferences.loadout_gear[gear.index_name] = list()
	if(preferences.get_loadout_cost() > preferences.max_gear_slots)
		preferences.loadout_gear -= gear.index_name
		to_chat(user, span_warning("Недостаточно очков снаряжения для \"[gear.get_display_name()]\"!"))
		return FALSE
	return TRUE

/datum/preference_middleware/loadout/proc/action_clear_all(list/params, mob/user)
	preferences.loadout_gear.Cut()
	preferences.form_choosen_gears()
	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/loadout/proc/action_toggle_job_outfit(list/params, mob/user)
	preferences.character_preview_view.show_job_clothes = !preferences.character_preview_view.show_job_clothes
	preferences.character_preview_view.update_body()
	return TRUE

/datum/preference_middleware/loadout/proc/action_rotate_model_dir(list/params, mob/user)
	switch(params["dir"])
		if("left")
			preferences.character_preview_view.dir = turn(preferences.character_preview_view.dir, -90)
		if("right")
			preferences.character_preview_view.dir = turn(preferences.character_preview_view.dir, 90)
	return FALSE

/datum/preference_middleware/loadout/proc/action_pass_to_loadout_item(list/params, mob/user)
	var/datum/gear/gear = preferences.choosen_gears[params["path"]]
	if(!istype(gear))
		return TRUE

	var/datum/gear_tweak/tweak = locate(text2path(params["subaction"])) in gear.gear_tweaks
	if(!tweak)
		return FALSE

	preferences.set_tweak_metadata(gear, tweak, tweak.get_metadata(user, preferences.get_tweak_metadata(gear, tweak)))
	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/loadout/proc/action_close_modify_menu(list/params, mob/user)
	return FALSE

/datum/preference_middleware/loadout/get_character_preferences(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return

	var/list/loadout_list = list()
	for(var/gear_name in preferences.loadout_gear)
		var/list/metadata = preferences.loadout_gear[gear_name]
		loadout_list[gear_name] = length(metadata) ? metadata.Copy() : list()

	return list("misc" = list("loadout_list" = loadout_list))

/datum/preference_middleware/loadout/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	return list(
		"job_clothes" = preferences.character_preview_view?.show_job_clothes,
		"loadout_points" = preferences.get_loadout_cost(),
		"max_loadout_points" = preferences.max_gear_slots,
	)

/datum/preference_middleware/loadout/get_constant_data()
	var/static/list/category_icons = list(
		"Основное" = "box",
		"Униформа" = "tshirt",
		"Верхняя одежда" = "vest",
		"Головные уборы" = "hat-cowboy",
		"Очки" = "glasses",
		"Перчатки" = "mitten",
		"Обувь" = "shoe-prints",
		"Аксессуары" = "ring",
		"Плащи" = "user-tie",
		"Импланты" = "microchip",
		"Расовое" = "dna",
		"Игрушки" = "hippo",
		"Донат" = "star",
	)

	var/list/tabs = list()
	for(var/gear_name in GLOB.gear_datums)
		var/datum/gear/gear = GLOB.gear_datums[gear_name]
		if(!tabs[gear.sort_category])
			tabs[gear.sort_category] = list()
		tabs[gear.sort_category] += list(gear_to_ui_data(gear))

	var/list/loadout_tabs = list()
	for(var/category in category_icons | tabs)
		if(!tabs[category])
			continue
		loadout_tabs += list(list(
			"name" = category,
			"category_icon" = category_icons[category],
			"category_info" = null,
			"contents" = tabs[category],
		))

	return list("loadout_tabs" = loadout_tabs)

/datum/preference_middleware/loadout/proc/gear_to_ui_data(datum/gear/gear)
	var/obj/item/item = gear.path
	var/list/buttons = list()
	var/list/information = list(list(
		"icon" = "coins",
		"tooltip" = "Стоимость: [gear.cost] [declension_ru(gear.cost, "очко", "очка", "очков")]",
	))

	for(var/datum/gear_tweak/tweak as anything in gear.gear_tweaks)
		buttons += list(list(
			"label" = tweak.display_type,
			"act_key" = "[tweak.type]",
			"button_icon" = tweak.fa_icon,
			"button_text" = "Изменить",
		))
		information += list(list(
			"icon" = tweak.fa_icon,
			"tooltip" = tweak.info,
		))

	var/header_tips = gear.get_header_tips()
	if(header_tips)
		information += list(list(
			"icon" = "info",
			"tooltip" = trim(header_tips),
		))

	if(LAZYLEN(gear.allowed_roles))
		var/list/role_names = list()
		for(var/role in gear.allowed_roles)
			role_names += get_job_title_ru(role)
		information += list(list(
			"icon" = "briefcase",
			"tooltip" = "Только для: [jointext(role_names, ", ")]",
		))

	return list(
		"name" = gear.get_display_name(),
		"group" = LAZYLEN(gear.allowed_roles) ? "Для профессий" : gear.sort_category,
		"path" = gear.index_name,
		"icon" = gear.icon || item::icon,
		"icon_state" = gear.icon_state || item::icon_state,
		"buttons" = buttons,
		"reskins" = null,
		"information" = information,
	)

/datum/preferences/proc/get_loadout_cost()
	var/total_cost = 0
	var/list/counted_paths = list()
	for(var/gear_name in loadout_gear)
		var/datum/gear/gear = GLOB.gear_datums[gear_name]
		if(!gear)
			continue
		if(!gear.subtype_cost_overlap)
			if(gear.path in counted_paths)
				continue
			counted_paths += gear.path
		total_cost += gear.cost
	return total_cost
