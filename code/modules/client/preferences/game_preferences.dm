/datum/preference/choiced/ui_style
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "UI_style"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/ui_style/init_possible_values()
	return list(UI_THEME_MIDNIGHT, UI_THEME_PLASMAFIRE, UI_THEME_RETRO, UI_THEME_SLIMECORE, UI_THEME_OPERATIVE, UI_THEME_WHITE, UI_THEME_GLASS, UI_THEME_CLOCKWORK)

/datum/preference/choiced/ui_style/create_default_value()
	return UI_THEME_MIDNIGHT

/datum/preference/choiced/ui_style/apply_to_client_updated(client/client, value)
	client.mob?.remake_hud()

/datum/preference/choiced/ui_style/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		UI_THEME_MIDNIGHT = UI_THEME_MIDNIGHT_RUS,
		UI_THEME_PLASMAFIRE = UI_THEME_PLASMAFIRE_RUS,
		UI_THEME_RETRO = UI_THEME_RETRO_RUS,
		UI_THEME_SLIMECORE = UI_THEME_SLIMECORE_RUS,
		UI_THEME_OPERATIVE = UI_THEME_OPERATIVE_RUS,
		UI_THEME_WHITE = UI_THEME_WHITE_RUS,
		UI_THEME_GLASS = UI_THEME_GLASS_RUS,
		UI_THEME_CLOCKWORK = UI_THEME_CLOCKWORK_RUS,
	)
	return data

/datum/preference/color/ui_style_color
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "UI_style_color"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/color/ui_style_color/create_default_value()
	return "#ffffff"

/datum/preference/color/ui_style_color/apply_to_client_updated(client/client, value)
	client.mob?.remake_hud()

/datum/preference/numeric/ui_style_alpha
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "UI_style_alpha"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	minimum = 50
	maximum = 255

/datum/preference/numeric/ui_style_alpha/create_default_value()
	return 255

/datum/preference/numeric/ui_style_alpha/apply_to_client_updated(client/client, value)
	client.mob?.remake_hud()

/datum/preference/color/ooc_color
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "ooccolor"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/color/ooc_color/create_default_value()
	return "#b82e00"

/datum/preference/color/ooc_color/is_accessible(datum/preferences/preferences)
	if(!..())
		return FALSE
	return check_rights_for(preferences.parent, R_ADMIN)

/datum/preference/numeric/fps
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "clientfps"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	minimum = -1
	maximum = 120

/datum/preference/numeric/fps/create_default_value()
	return 0

/datum/preference/numeric/fps/apply_to_client(client/client, value)
	client.fps = value || CONFIG_GET(number/clientfps)

/datum/preference/choiced/parallax
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "parallax"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/parallax/init_possible_values()
	return list(PARALLAX_DISABLE, PARALLAX_BOOMER, PARALLAX_LOW, PARALLAX_MED, PARALLAX_HIGH, PARALLAX_INSANE)

/datum/preference/choiced/parallax/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/parallax/create_default_value()
	return PARALLAX_HIGH

/datum/preference/choiced/parallax/apply_to_client_updated(client/client, value)
	client.mob?.hud_used?.update_parallax_pref()

/datum/preference/choiced/parallax/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		"[PARALLAX_DISABLE]" = "Отключено",
		"[PARALLAX_BOOMER]" = "Старое",
		"[PARALLAX_LOW]" = "Низкое",
		"[PARALLAX_MED]" = "Среднее",
		"[PARALLAX_HIGH]" = "Высокое",
		"[PARALLAX_INSANE]" = "Очень высокое",
	)
	return data

/datum/preference/choiced/multiz_detail
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "multiz_detail"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/multiz_detail/init_possible_values()
	return list(MULTIZ_DETAIL_DEFAULT, MULTIZ_DETAIL_LOW, MULTIZ_DETAIL_MEDIUM, MULTIZ_DETAIL_HIGH)

/datum/preference/choiced/multiz_detail/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/multiz_detail/create_default_value()
	return MULTIZ_DETAIL_DEFAULT

/datum/preference/choiced/multiz_detail/apply_to_client_updated(client/client, value)
	var/datum/hud/my_hud = client.mob?.hud_used
	if(!my_hud)
		return
	for(var/group_key in my_hud.master_groups)
		var/datum/plane_master_group/group = my_hud.master_groups[group_key]
		group.build_planes_offset(my_hud, my_hud.current_plane_offset)

/datum/preference/choiced/multiz_detail/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		"[MULTIZ_DETAIL_DEFAULT]" = "По умолчанию",
		"[MULTIZ_DETAIL_LOW]" = "Низкое",
		"[MULTIZ_DETAIL_MEDIUM]" = "Среднее",
		"[MULTIZ_DETAIL_HIGH]" = "Высокое",
	)
	return data

/datum/preference/choiced/view_range
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "viewrange"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/view_range/init_possible_values()
	return list(SQUARE_VIEWPORT_SIZE, WIDESCREEN_PARTIAL_VIEWPORT_SIZE, WIDESCREEN_VIEWPORT_SIZE)

/datum/preference/choiced/view_range/create_default_value()
	return WIDESCREEN_VIEWPORT_SIZE

/datum/preference/choiced/view_range/apply_to_client_updated(client/client, value)
	client.view_size?.setDefault(VIEWPORT_USE_PREF)

/datum/preference/choiced/view_range/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		SQUARE_VIEWPORT_SIZE = "15x15 (Классический)",
		WIDESCREEN_PARTIAL_VIEWPORT_SIZE = "17x15 (Широкий)",
		WIDESCREEN_VIEWPORT_SIZE = "19x15 (Ультраширокий)",
	)
	return data

/datum/preference/choiced/ghost_lighting
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "ghost_darkness_level"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/ghost_lighting/init_possible_values()
	var/list/values = list()
	for(var/lighting_name in GLOB.ghost_lightings)
		values += GLOB.ghost_lightings[lighting_name]
	return values

/datum/preference/choiced/ghost_lighting/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/ghost_lighting/create_default_value()
	return LIGHTING_CUTOFF_VISIBLE

/datum/preference/choiced/ghost_lighting/apply_to_client_updated(client/client, value)
	var/mob/dead/observer/ghost = client.mob
	if(!istype(ghost))
		return
	ghost.lighting_cutoff = value
	ghost.update_sight()

/datum/preference/choiced/ghost_lighting/compile_constant_data()
	var/list/data = ..()
	var/list/display_names = list()
	for(var/lighting_name in GLOB.ghost_lightings)
		display_names["[GLOB.ghost_lightings[lighting_name]]"] = lighting_name
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = display_names
	return data

/datum/preference/numeric/screentip_size
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "screentip_mode"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	minimum = 0
	maximum = 20

/datum/preference/numeric/screentip_size/create_default_value()
	return 8

/datum/preference/color/screentip_color
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "screentip_color"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/color/screentip_color/create_default_value()
	return "#deefff"

/datum/preference/choiced/achievement_sound
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "achivements_sound"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/achievement_sound/init_possible_values()
	return assoc_to_keys(GLOB.achievement_sounds)

/datum/preference/choiced/achievement_sound/create_default_value()
	return CHEEVO_SOUND_PING

/datum/preference/choiced/achievement_sound/apply_to_client_updated(client/client, value)
	var/sound/sound_to_send = LAZYACCESS(GLOB.achievement_sounds, value)
	if(sound_to_send)
		SEND_SOUND(client, sound_to_send)

/datum/preference/choiced/scaling_method
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "zoom_mode"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/scaling_method/init_possible_values()
	return assoc_to_keys(GLOB.zoom_modes)

/datum/preference/choiced/scaling_method/create_default_value()
	return SCALING_METHOD_DISTORT

/datum/preference/choiced/scaling_method/apply_to_client(client/client, value)
	client.view_size?.setZoomMode()

/datum/preference/choiced/scaling_method/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = GLOB.zoom_modes.Copy()
	return data

/datum/preference/numeric/pixel_size
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "zoom"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	minimum = 0
	maximum = 9
	step = 0.5

/datum/preference/numeric/pixel_size/create_default_value()
	return 0

/datum/preference/numeric/pixel_size/apply_to_client(client/client, value)
	client.view_size?.resetFormat()

/datum/preference/choiced/attack_log_level
	savefile_identifier = PREFERENCE_PLAYER
	savefile_key = "atklog"
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/attack_log_level/init_possible_values()
	return list(ATKLOG_ALL, ATKLOG_ALMOSTALL, ATKLOG_MOST, ATKLOG_FEW, ATKLOG_NONE)

/datum/preference/choiced/attack_log_level/deserialize(input, datum/preferences/preferences)
	if(istext(input))
		input = text2num(input)
	return ..(input, preferences)

/datum/preference/choiced/attack_log_level/create_default_value()
	return ATKLOG_ALL

/datum/preference/choiced/attack_log_level/is_accessible(datum/preferences/preferences)
	if(!..())
		return FALSE
	return check_rights_for(preferences.parent, R_ADMIN)

/datum/preference/choiced/attack_log_level/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = list(
		"[ATKLOG_ALL]" = "Все",
		"[ATKLOG_ALMOSTALL]" = "Почти все",
		"[ATKLOG_MOST]" = "Большинство",
		"[ATKLOG_FEW]" = "Только важные",
		"[ATKLOG_NONE]" = "Никаких",
	)
	return data
