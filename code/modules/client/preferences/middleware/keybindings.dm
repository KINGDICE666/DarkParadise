#define MAX_HOTKEY_SLOTS 3
#define MAX_CUSTOM_EMOTE_LENGTH 128

/datum/preference_middleware/keybindings
	action_delegations = list(
		"reset_all_keybinds" = PROC_REF(reset_all_keybinds),
		"reset_keybinds_to_defaults" = PROC_REF(reset_keybinds_to_defaults),
		"set_keybindings" = PROC_REF(set_keybindings),
		"set_custom_emote" = PROC_REF(set_custom_emote),
	)

/datum/preference_middleware/keybindings/get_ui_static_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_KEYBINDINGS)
		return list()

	var/list/keybindings = list()
	for(var/datum/keybinding/keybinding as anything in GLOB.keybindings)
		keybindings[keybinding.name] = preferences.keybindings_overrides?[keybinding.name] || keybinding.classic_keys || list()

	return list(
		"keybindings" = keybindings,
		"custom_emotes" = preferences.custom_emotes || list(),
	)

/datum/preference_middleware/keybindings/get_ui_assets()
	return list(get_asset_datum(/datum/asset/json/keybindings))

/datum/preference_middleware/keybindings/proc/apply_overrides(mob/user)
	preferences.init_keybindings(preferences.keybindings_overrides)
	preferences.update_static_data(user)

/datum/preference_middleware/keybindings/proc/reset_all_keybinds(list/params, mob/user)
	preferences.keybindings_overrides = list()
	apply_overrides(user)
	return TRUE

/datum/preference_middleware/keybindings/proc/reset_keybinds_to_defaults(list/params, mob/user)
	var/datum/keybinding/keybinding = GLOB.keybindings_by_name[params["keybind_name"]]
	if(isnull(keybinding))
		return FALSE
	preferences.keybindings_overrides -= keybinding.name
	apply_overrides(user)
	return TRUE

/datum/preference_middleware/keybindings/proc/set_keybindings(list/params, mob/user)
	var/datum/keybinding/keybinding = GLOB.keybindings_by_name[params["keybind_name"]]
	if(isnull(keybinding) || !keybinding.can_edit)
		return FALSE

	var/list/raw_hotkeys = params["hotkeys"]
	if(!istype(raw_hotkeys) || length(raw_hotkeys) > MAX_HOTKEY_SLOTS)
		return FALSE

	var/list/hotkeys = list()
	for(var/hotkey in raw_hotkeys)
		if(!istext(hotkey) || length(hotkey) > 100)
			return FALSE
		hotkeys += hotkey

	LAZYINITLIST(preferences.keybindings_overrides)
	preferences.keybindings_overrides[keybinding.name] = hotkeys
	apply_overrides(user)
	return TRUE

/datum/preference_middleware/keybindings/proc/set_custom_emote(list/params, mob/user)
	var/datum/keybinding/custom/custom_emote = GLOB.keybindings_by_name[params["keybind_name"]]
	if(!istype(custom_emote))
		return FALSE
	var/emote_text = copytext_char(trim(params["text"]), 1, MAX_CUSTOM_EMOTE_LENGTH + 1)
	if(!emote_text || emote_text == custom_emote.default_emote_text)
		preferences.custom_emotes -= custom_emote.name
	else
		preferences.custom_emotes[custom_emote.name] = emote_text
	preferences.update_static_data(user)
	return TRUE

/datum/asset/json/keybindings
	name = "keybindings"

/datum/asset/json/keybindings/generate()
	var/static/list/russian_names = list(
		"Movement" = "Движение",
		"Communication" = "Общение",
		"Living" = "Живые существа",
		"General" = "Общее",
		"General Emote" = "Общие эмоции",
		"Human" = "Гуманоиды",
		"Human Emotes" = "Эмоции гуманоидов",
		"Carbon" = "Углеродные",
		"Carbon Emote" = "Эмоции углеродных",
		"Robot" = "Киборги",
		"AI" = "ИИ",
		"Silicon/IPC Emote" = "Эмоции синтетиков и КПБ",
		"Animal Emote" = "Эмоции животных",
		"Brain Emote" = "Эмоции мозга",
		"Alien Emote" = "Эмоции ксеноморфов",
		"Admin" = "Администрация",
		"Other" = "Прочее",
		"Custom Emotes (Character-based)" = "Пользовательские эмоции персонажа",
	)
	var/list/category_names = list()
	for(var/category_name in GLOB.keybindings_groups)
		category_names["[GLOB.keybindings_groups[category_name]]"] = russian_names[category_name] || category_name

	var/list/keybindings = list()
	for(var/datum/keybinding/keybinding as anything in GLOB.keybindings)
		var/category = category_names["[keybinding.category]"] || "Прочее"
		if(!(category in keybindings))
			keybindings[category] = list()
		keybindings[category][keybinding.name] = list(
			"name" = keybinding.full_name || keybinding.name,
			"description" = keybinding.description,
			"can_edit" = keybinding.can_edit,
			"default" = keybinding.classic_keys || list(),
			"custom_emote" = istype(keybinding, /datum/keybinding/custom),
		)

	return keybindings

#undef MAX_HOTKEY_SLOTS
#undef MAX_CUSTOM_EMOTE_LENGTH
