#define PRESET_FILTER_PRIORITY 10

/datum/filter_editor
	var/atom/target
	var/list/animations
	var/static/list/filter_presets = list(
		"Glow",
		"Pulsing Glow",
		"Outline",
		"Drop Shadow",
		"Silhouette",
		"Hologram",
		"Ghost",
		"Rainbow",
		"Holy Rays",
		"Ripple",
		"Heat Haze",
		"Wibbly",
	)
	var/static/list/colored_presets = list("Glow", "Pulsing Glow", "Outline", "Silhouette", "Holy Rays")
	var/static/list/unanimatable_fields = list("flags", "space", "blend_mode", "icon", "render_source", "transform")

/datum/filter_editor/New(atom/target)
	src.target = target

/datum/filter_editor/Destroy()
	target = null
	return ..()

/datum/filter_editor/ui_state(mob/user)
	return ADMIN_STATE(R_VAREDIT)

/datum/filter_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Filterrific")
		ui.open()

/datum/filter_editor/ui_static_data(mob/user)
	var/list/data = list()
	data["filter_info"] = GLOB.master_filter_info
	data["presets"] = filter_presets
	return data

/datum/filter_editor/ui_data(mob/user)
	var/list/data = list()
	data["target_name"] = target.name
	var/list/target_filter_data = list()
	for(var/list/filter_info as anything in target.filter_data)
		filter_info = deep_copy_list(filter_info)
		if(filter_info["transform"])
			var/matrix/filter_transform = filter_info["transform"]
			filter_info["transform"] = list("a" = filter_transform.a, "b" = filter_transform.b, "c" = filter_transform.c, "d" = filter_transform.d, "e" = filter_transform.e, "f" = filter_transform.f)
		target_filter_data += list(filter_info)
	data["target_filter_data"] = target_filter_data
	var/list/animated_filters = list()
	for(var/filter_name in animations)
		animated_filters += filter_name
	data["animated_filters"] = animated_filters
	data["has_clipboard"] = !!length(user.client?.holder?.copied_filters)
	return data

/datum/filter_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("add_filter")
			target.add_filter(unique_filter_name(params["name"]), params["priority"], list("type" = params["type"]))
			. = TRUE
		if("add_preset")
			. = apply_preset(params["preset"])
		if("remove_filter")
			LAZYREMOVE(animations, params["name"])
			target.remove_filter(params["name"])
			. = TRUE
		if("rename_filter")
			var/list/filter_info = target.get_filter_data(params["name"])
			if(!filter_info)
				return
			var/new_name = unique_filter_name(params["new_name"])
			target.remove_filter(params["name"])
			target.add_filter(new_name, filter_info["priority"], filter_info)
			if(LAZYACCESS(animations, params["name"]))
				LAZYSET(animations, new_name, animations[params["name"]])
				LAZYREMOVE(animations, params["name"])
			. = TRUE
		if("edit_filter")
			target.remove_filter(params["name"])
			target.add_filter(params["name"], params["priority"], params["new_filter"])
			. = TRUE
		if("change_priority")
			var/new_priority = params["new_priority"]
			target.change_filter_priority(params["name"], new_priority)
			. = TRUE
		if("transition_filter_value")
			target.transition_filter(params["name"], params["new_data"], 4)
			. = TRUE
		if("modify_filter_value")
			target.modify_filter(params["name"], params["new_data"])
			. = TRUE
		if("modify_color_value")
			var/new_color = tgui_input_color(usr, "Pick new filter color", "Filterrific Colors!")
			if(new_color)
				target.transition_filter(params["name"], list("color" = new_color), 4)
				. = TRUE
		if("modify_icon_value")
			var/icon/new_icon = input("Pick icon:", "Icon") as null|icon
			if(new_icon)
				target.modify_filter(params["name"], list("icon" = new_icon))
				. = TRUE
		if("modify_transform_value")
			var/list/filter_info = target.get_filter_data(params["name"])
			if(!filter_info)
				return
			var/matrix/new_transform = matrix(filter_info[params["field_name"]])
			if(!(params["transform_key"] in list("a", "b", "c", "d", "e", "f")))
				return
			new_transform.vars[params["transform_key"]] = text2num(params["transform_value"])
			target.modify_filter(params["name"], list(params["field_name"] = new_transform))
			. = TRUE
		if("animate_filter")
			. = setup_animation(params["name"])
		if("stop_animation")
			LAZYREMOVE(animations, params["name"])
			animate(target.get_filter(params["name"]))
			target.modify_filter(params["name"], list())
			. = TRUE
		if("clear_filters")
			animations = null
			target.clear_filters()
			. = TRUE
		if("copy_filters")
			usr.client.holder.copied_filters = deep_copy_list(target.filter_data)
			to_chat(usr, span_notice("Фильтры [target] скопированы."))
			. = TRUE
		if("paste_filters")
			var/list/copied_filters = usr.client.holder.copied_filters
			if(!length(copied_filters))
				return
			paste_filters(target, copied_filters)
			. = TRUE
		if("mass_apply")
			if(!check_rights_for(usr.client, R_EVENT))
				to_chat(usr, span_userdanger("Stay in your lane, jannie."))
				return
			var/target_path = text2path(params["path"])
			if(!target_path)
				return
			var/list/filter_data_to_copy = deep_copy_list(target.filter_data)
			var/count = 0
			for(var/atom/thing_at as anything in world.contents)
				if(!istype(thing_at, target_path))
					continue
				thing_at.clear_filters()
				paste_filters(thing_at, filter_data_to_copy)
				count += 1
			message_admins("LOCAL CLOWN [usr.ckey] JUST MASS FILTER EDITED [count] WITH PATH OF [params["path"]]!")
			log_admin("LOCAL CLOWN [usr.ckey] JUST MASS FILTER EDITED [count] WITH PATH OF [params["path"]]!")

	if(.)
		restart_animations()

/datum/filter_editor/proc/unique_filter_name(filter_name)
	while(target.get_filter(filter_name))
		filter_name = "[filter_name]-dupe"
	return filter_name

/datum/filter_editor/proc/paste_filters(atom/receiver, list/filters_to_paste)
	for(var/list/filter_info as anything in filters_to_paste)
		receiver.add_filter(filter_info["name"], filter_info["priority"], filter_info)

/datum/filter_editor/proc/restart_animations()
	for(var/filter_name in animations)
		if(!target.get_filter(filter_name))
			animations -= filter_name
			continue
		target.transition_filter_chain(arglist(list(filter_name, -1) + animations[filter_name]))
	UNSETEMPTY(animations)

/datum/filter_editor/proc/setup_animation(filter_name)
	var/list/filter_info = target.get_filter_data(filter_name)
	if(!filter_info)
		return FALSE

	var/list/defaults = GLOB.master_filter_info[filter_info["type"]]["defaults"]
	var/list/animatable_fields = list()
	for(var/field in defaults)
		if(field in unanimatable_fields)
			continue
		var/value = isnull(filter_info[field]) ? defaults[field] : filter_info[field]
		if(islist(value) || istype(value, /matrix))
			continue
		animatable_fields[field] = value
	if(!length(animatable_fields))
		to_chat(usr, span_warning("У фильтра [filter_name] нет параметров, которые можно анимировать."))
		return FALSE

	var/field = tgui_input_list(usr, "Какой параметр анимировать?", "Анимация [filter_name]", animatable_fields)
	if(!field)
		return FALSE
	var/start_value = animatable_fields[field]
	var/end_value
	if(istext(start_value))
		end_value = tgui_input_color(usr, "До какого цвета анимировать?", "Анимация [filter_name]", start_value)
	else
		end_value = tgui_input_number(usr, "До какого значения анимировать? Сейчас: [start_value]", "Анимация [filter_name]", start_value, 500, -500, round_value = FALSE)
	if(isnull(end_value))
		return FALSE
	var/half_period = tgui_input_number(usr, "Сколько секунд длится переход в одну сторону?", "Анимация [filter_name]", 1, 60, 0.1, round_value = FALSE)
	if(!half_period)
		return FALSE

	LAZYSET(animations, filter_name, list(
		filter_chain_step(list("[field]" = end_value), half_period SECONDS, SINE_EASING),
		filter_chain_step(list("[field]" = start_value), half_period SECONDS, SINE_EASING),
	))
	return TRUE

/datum/filter_editor/proc/apply_preset(preset_name)
	if(!(preset_name in filter_presets))
		return FALSE
	var/preset_color
	if(preset_name in colored_presets)
		preset_color = tgui_input_color(usr, "Цвет эффекта", preset_name, COLOR_WHITE)
		if(!preset_color)
			return FALSE

	var/filter_name
	switch(preset_name)
		if("Glow")
			target.add_filter(unique_filter_name("glow"), PRESET_FILTER_PRIORITY, drop_shadow_filter(x = 0, y = 0, size = 3, offset = 1, color = preset_color))
		if("Pulsing Glow")
			filter_name = unique_filter_name("pulsing_glow")
			target.add_filter(filter_name, PRESET_FILTER_PRIORITY, drop_shadow_filter(x = 0, y = 0, size = 2, color = preset_color))
			LAZYSET(animations, filter_name, list(
				filter_chain_step(list("size" = 5), 1 SECONDS, SINE_EASING),
				filter_chain_step(list("size" = 2), 1 SECONDS, SINE_EASING),
			))
		if("Outline")
			target.add_filter(unique_filter_name("outline"), PRESET_FILTER_PRIORITY, outline_filter(size = 1, color = preset_color))
		if("Drop Shadow")
			target.add_filter(unique_filter_name("shadow"), PRESET_FILTER_PRIORITY, drop_shadow_filter(x = 2, y = -2, size = 2, color = COLOR_HALF_TRANSPARENT_BLACK))
		if("Silhouette")
			var/list/rgb = rgb2num(preset_color)
			target.add_filter(unique_filter_name("silhouette"), PRESET_FILTER_PRIORITY, color_matrix_filter(list(
				0, 0, 0, 0,
				0, 0, 0, 0,
				0, 0, 0, 0,
				0, 0, 0, 1,
				rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 0,
			)))
		if("Hologram")
			var/static/list/hologram_matrix = list(
				0.2, 0.4, 0.5, 0,
				0.2, 0.5, 0.6, 0,
				0.1, 0.3, 0.4, 0,
				0, 0, 0, 0.75,
				0, 0.08, 0.15, 0,
			)
			var/static/list/hologram_flicker_matrix = list(
				0.2, 0.4, 0.5, 0,
				0.2, 0.5, 0.6, 0,
				0.1, 0.3, 0.4, 0,
				0, 0, 0, 0.4,
				0, 0.08, 0.15, 0,
			)
			filter_name = unique_filter_name("hologram")
			target.add_filter(filter_name, PRESET_FILTER_PRIORITY, color_matrix_filter(hologram_matrix))
			LAZYSET(animations, filter_name, list(
				filter_chain_step(list("color" = hologram_flicker_matrix), 0.1 SECONDS),
				filter_chain_step(list("color" = hologram_matrix), 0.1 SECONDS),
				filter_chain_step(list("color" = hologram_matrix), 2 SECONDS),
			))
		if("Ghost")
			target.add_filter(unique_filter_name("ghost_blur"), PRESET_FILTER_PRIORITY, gauss_blur_filter(0.6))
			target.add_filter(unique_filter_name("ghost_fade"), PRESET_FILTER_PRIORITY, color_matrix_filter(list(
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 0.5,
				0.1, 0.1, 0.2, 0,
			)))
		if("Rainbow")
			filter_name = unique_filter_name("rainbow")
			target.add_filter(filter_name, PRESET_FILTER_PRIORITY, color_matrix_filter(color_matrix_rotate_hue(0)))
			LAZYSET(animations, filter_name, list(
				filter_chain_step(list("color" = color_matrix_rotate_hue(120)), 1 SECONDS),
				filter_chain_step(list("color" = color_matrix_rotate_hue(240)), 1 SECONDS),
				filter_chain_step(list("color" = color_matrix_rotate_hue(0)), 1 SECONDS),
			))
		if("Holy Rays")
			filter_name = unique_filter_name("rays")
			target.add_filter(filter_name, PRESET_FILTER_PRIORITY, rays_filter(size = 40, color = preset_color, factor = 6, density = 20, flags = FILTER_UNDERLAY))
			LAZYSET(animations, filter_name, list(
				filter_chain_step(list("offset" = 10), 10 SECONDS),
				filter_chain_step(list("offset" = 0), 10 SECONDS),
			))
		if("Ripple")
			filter_name = unique_filter_name("ripple")
			target.add_filter(filter_name, PRESET_FILTER_PRIORITY, ripple_filter(radius = 0, size = 2, falloff = 1, repeat = 2))
			LAZYSET(animations, filter_name, list(
				filter_chain_step(list("radius" = 32, "size" = 0), 1.5 SECONDS),
				filter_chain_step(list("radius" = 0, "size" = 2), 0),
			))
		if("Heat Haze")
			filter_name = unique_filter_name("heat_haze")
			target.add_filter(filter_name, PRESET_FILTER_PRIORITY, wave_filter(x = 12, y = 0, size = 0.8))
			LAZYSET(animations, filter_name, list(
				filter_chain_step(list("offset" = 1), 2 SECONDS),
				filter_chain_step(list("offset" = 0), 0),
			))
		if("Wibbly")
			apply_wibbly_filters(target)
			for(var/list/filter_info as anything in target.filter_data)
				if(!findtext(filter_info["name"], "wibbly-"))
					continue
				LAZYSET(animations, filter_info["name"], list(
					filter_chain_step(list("offset" = filter_info["offset"] - 1), rand() * 2 SECONDS + 1 SECONDS),
					filter_chain_step(list("offset" = filter_info["offset"]), 0),
				))
	return TRUE

#undef PRESET_FILTER_PRIORITY
