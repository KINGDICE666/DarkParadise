GLOBAL_LIST_EMPTY(buildmode_categories)
GLOBAL_LIST_EMPTY(buildmode_items)

/proc/get_buildmode_categories()
	if(length(GLOB.buildmode_categories))
		return GLOB.buildmode_categories
	var/list/category_paths = list(
		"Турфы" = list(/turf),
		"Объекты" = list(/obj),
		"Существа" = list(/mob),
		"Предметы" = list(/obj/item),
		"Оружие" = list(/obj/item/gun),
		"Одежда" = list(/obj/item/clothing),
		"Реагенты" = list(/obj/item/reagent_containers),
		"Еда" = list(/obj/item/reagent_containers/food),
		"Материалы" = list(/obj/item/stack/sheet),
		"Газы" = list(/obj/machinery/portable_atmospherics/canister, /obj/machinery/atmospherics/miner),
	)
	var/list/excluded_paths = list(
		"Турфы" = list(/turf/template_noop),
		"Объекты" = list(/obj/item, /obj/effect),
		"Существа" = list(/mob/dead, /mob/camera, /mob/new_player),
		"Предметы" = list(/obj/item/clothing, /obj/item/reagent_containers, /obj/item/gun, /obj/item/stack),
		"Реагенты" = list(/obj/item/reagent_containers/food),
	)
	for(var/category_name in category_paths)
		var/list/items = list()
		var/list/excluded = excluded_paths[category_name]
		for(var/base_path in category_paths[category_name])
			for(var/atom/item_path as anything in valid_subtypesof(base_path))
				var/skip = FALSE
				for(var/excluded_path in excluded)
					if(ispath(item_path, excluded_path))
						skip = TRUE
						break
				if(skip || !item_path::icon || !length(item_path::name))
					continue
				var/icon_state = item_path::icon_state
				if(ispath(item_path, /obj))
					var/obj/object_path = item_path
					icon_state = object_path::icon_state_preview || icon_state
				if(!icon_exists(item_path::icon, icon_state))
					continue
				var/path_text = "[item_path]"
				var/list/item = GLOB.buildmode_items[path_text]
				if(!item)
					item = list("path" = path_text, "name" = item_path::name, "icon" = "bm_[length(GLOB.buildmode_items) + 1]")
					GLOB.buildmode_items[path_text] = item
				items += list(item)
		GLOB.buildmode_categories += list(list("name" = category_name, "items" = items))
	return GLOB.buildmode_categories

/proc/get_buildmode_greyscale_state(atom/item_path)
	var/datum/greyscale_config/config = SSgreyscale.configurations["[item_path::greyscale_config]"]
	if(!config || !item_path::greyscale_colors)
		return
	var/icon_state = item_path::post_init_icon_state
	if(isnull(icon_state))
		icon_state = item_path::icon_state
	if(!(icon_state in config.icon_states))
		return
	if(length(parse_color_string(item_path::greyscale_colors)) != config.expected_colors)
		return
	return icon_state

/datum/asset/spritesheet_batched/buildmode
	name = "buildmode"
	load_on_demand = TRUE
	ignore_dir_errors = TRUE

/datum/asset/spritesheet_batched/buildmode/create_spritesheets()
	get_buildmode_categories()
	for(var/path_text in GLOB.buildmode_items)
		var/list/item = GLOB.buildmode_items[path_text]
		var/atom/item_path = text2path(path_text)
		var/icon_state = get_buildmode_greyscale_state(item_path)
		var/datum/universal_icon/item_icon
		if(!isnull(icon_state))
			item_icon = SSgreyscale.get_colored_icon_by_type_universal_icon(item_path::greyscale_config, item_path::greyscale_colors, icon_state)
		else
			icon_state = item_path::icon_state
			if(ispath(item_path, /obj))
				var/obj/object_path = item_path
				icon_state = object_path::icon_state_preview || icon_state
			item_icon = uni_icon(item_path::icon, icon_state, SOUTH, 1)
		if(item_path::color)
			item_icon.map_colors_rgba(arglist(color_to_full_rgba_matrix(item_path::color)))
		item_icon.scale(ICON_SIZE_X, ICON_SIZE_Y)
		insert_icon(item["icon"], item_icon)
