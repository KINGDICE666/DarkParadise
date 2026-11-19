/obj/machinery/computer/camera_advanced/shipyard
	name = "shipyard assembly console"
	desc = "Консоль сборки верфи. Здесь проектируют корабль, оплачивают его и запускают постройку на площадке."
	icon_screen = "navigation"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_CYAN
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	jump_action = null
	move_up_action = null
	move_down_action = null
	should_supress_view_changes = FALSE
	var/datum/shipyard_design/design
	var/turf/zone_origin
	var/zone_width = 0
	var/zone_height = 0
	var/selected_part = "plating"
	var/selected_dir = NORTH
	var/selected_paint = "Стандартная"
	var/list/selected_access = list()
	var/list/preview_images = list()
	var/datum/click_intercept/shipyard/drafting
	var/building = FALSE
	var/paying = FALSE
	var/build_started = 0
	var/build_duration = 0
	var/build_done = 0
	var/build_timer
	var/list/build_queue
	var/list/build_turfs
	var/list/holograms
	var/area/shuttle/custom/build_hull

/obj/machinery/computer/camera_advanced/shipyard/get_ru_names()
	return alist(
		NOMINATIVE = "консоль сборки верфи",
		GENITIVE = "консоли сборки верфи",
		DATIVE = "консоли сборки верфи",
		ACCUSATIVE = "консоль сборки верфи",
		INSTRUMENTAL = "консолью сборки верфи",
		PREPOSITIONAL = "консоли сборки верфи",
	)

/obj/machinery/computer/camera_advanced/shipyard/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/camera_advanced/shipyard/LateInitialize()
	. = ..()
	locate_zone()

/obj/machinery/computer/camera_advanced/shipyard/Destroy()
	if(build_timer)
		deltimer(build_timer)
	QDEL_LIST(holograms)
	QDEL_NULL(drafting)
	preview_images = null
	build_turfs = null
	build_hull = null
	zone_origin = null
	design = null
	return ..()

/obj/machinery/computer/camera_advanced/shipyard/proc/locate_zone()
	var/min_x
	var/min_y
	var/max_x
	var/max_y
	for(var/turf/tile as anything in get_area_turfs(/area/space/shipyard_zone, z))
		min_x = isnull(min_x) ? tile.x : min(min_x, tile.x)
		min_y = isnull(min_y) ? tile.y : min(min_y, tile.y)
		max_x = isnull(max_x) ? tile.x : max(max_x, tile.x)
		max_y = isnull(max_y) ? tile.y : max(max_y, tile.y)
	if(isnull(min_x))
		return
	zone_origin = locate(min_x, min_y, z)
	zone_width = max_x - min_x + 1
	zone_height = max_y - min_y + 1
	design = new(zone_width, zone_height)

/obj/machinery/computer/camera_advanced/shipyard/proc/zone_coords(turf/spot, margin = 0)
	if(!spot || !zone_origin || spot.z != zone_origin.z)
		return null
	var/local_x = spot.x - zone_origin.x + 1
	var/local_y = spot.y - zone_origin.y + 1
	if(local_x < 1 - margin || local_y < 1 - margin || local_x > zone_width + margin || local_y > zone_height + margin)
		return null
	return list(local_x, local_y)

/obj/machinery/computer/camera_advanced/shipyard/proc/zone_turf(local_x, local_y)
	return locate(zone_origin.x + local_x - 1, zone_origin.y + local_y - 1, zone_origin.z)

/obj/machinery/computer/camera_advanced/shipyard/proc/linked_loader()
	return locate(/obj/machinery/shipyard_loader) in range(3, src)

/obj/machinery/computer/camera_advanced/shipyard/attack_hand(mob/user)
	if(stat & (NOPOWER|BROKEN))
		return
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/camera_advanced/shipyard/CreateEye()
	eyeobj = new /mob/camera/aiEye/remote/shipyard(get_turf(src))
	eyeobj.origin = src
	eyeobj.eye_initialized = TRUE

/obj/machinery/computer/camera_advanced/shipyard/give_eye_control(mob/user)
	. = ..()
	if(!user.client)
		return
	user.client.view_size.setTo(SHIPYARD_VIEW_RANGE)
	user.client.images |= all_preview_images()
	if(!user.client.click_intercept)
		drafting = new(user.client, src)

/obj/machinery/computer/camera_advanced/shipyard/remove_eye_control(mob/living/user)
	QDEL_NULL(drafting)
	if(user?.client)
		user.client.images -= all_preview_images()
		user.client.view_size.resetToDefault()
	return ..()

/obj/machinery/computer/camera_advanced/shipyard/proc/start_view(mob/user)
	if(current_user || !zone_origin || !iscarbon(user))
		return
	if(!eyeobj)
		CreateEye()
	user.set_machine(src)
	give_eye_control(user)
	eyeobj.setLoc(zone_turf(round(zone_width / 2) + 1, round(zone_height / 2) + 1))

/obj/machinery/computer/camera_advanced/shipyard/proc/all_preview_images()
	. = list()
	for(var/key in preview_images)
		. += preview_images[key]

/obj/machinery/computer/camera_advanced/shipyard/proc/hologram_image(datum/shipyard_part/part, turf/spot, list/placement)
	var/dir = placement["dir"]
	var/image/hologram = image(part.preview_icon, spot, part.preview_state, part.preview_layer, part.rotatable && part.layer != SHIPYARD_LAYER_MOUNT ? dir : SOUTH)
	if(part.layer == SHIPYARD_LAYER_MOUNT)
		var/atom/mount = part.path_for(dir)
		hologram.dir = initial(mount.dir)
		hologram.pixel_x = initial(mount.pixel_x)
		hologram.pixel_y = initial(mount.pixel_y)
	hologram.color = SHIPYARD_HOLOGRAM_COLOR
	hologram.alpha = SHIPYARD_HOLOGRAM_ALPHA
	hologram.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	SET_PLANE_EXPLICIT(hologram, GAME_PLANE, spot)
	return hologram

/obj/machinery/computer/camera_advanced/shipyard/proc/update_preview(list/tiles)
	var/client/viewer = current_user?.client
	for(var/key in tiles)
		if(preview_images[key])
			viewer?.images -= preview_images[key]
			preview_images -= key
		var/list/coords = splittext(key, ",")
		var/local_x = text2num(coords[1])
		var/local_y = text2num(coords[2])
		var/turf/spot = zone_turf(local_x, local_y)
		var/list/images = list()
		for(var/layer in list(SHIPYARD_LAYER_TURF, SHIPYARD_LAYER_OBJECT, SHIPYARD_LAYER_MOUNT, SHIPYARD_LAYER_DECAL))
			var/list/placement = design.entry(local_x, local_y, layer)
			var/datum/shipyard_part/part = design.part_of(placement)
			if(part)
				images += hologram_image(part, spot, placement)
		if(!length(images))
			continue
		preview_images[key] = images
		viewer?.images |= images

/obj/machinery/computer/camera_advanced/shipyard/proc/reset_preview()
	current_user?.client?.images -= all_preview_images()
	preview_images = list()
	var/list/tiles = list()
	for(var/local_x in 1 to zone_width)
		for(var/local_y in 1 to zone_height)
			tiles += "[local_x],[local_y]"
	update_preview(tiles)

/obj/machinery/computer/camera_advanced/shipyard/proc/locked()
	return building || paying

/obj/machinery/computer/camera_advanced/shipyard/proc/place_at(mob/user, local_x, local_y)
	if(locked())
		return
	var/datum/shipyard_part/part = GLOB.shipyard_parts[selected_part]
	if(!part)
		return
	design.touched = list()
	var/error = design.place(part, local_x, local_y, selected_dir, selected_paint, selected_access)
	if(error)
		to_chat(user, span_warning(error))
		return
	update_preview(design.touched)
	SStgui.update_uis(src)

/obj/machinery/computer/camera_advanced/shipyard/proc/erase_at(mob/user, local_x, local_y)
	if(locked())
		return
	design.touched = list()
	design.erase(local_x, local_y)
	update_preview(design.touched)
	SStgui.update_uis(src)

/obj/machinery/computer/camera_advanced/shipyard/proc/save_design(mob/user)
	var/path = "data/shipyard/[user.ckey].json"
	fdel(path)
	text2file(design.export_json(), path)
	DIRECT_OUTPUT(user, ftp(file(path), "[ckey(design.name) || "shuttle"].json"))

/obj/machinery/computer/camera_advanced/shipyard/proc/load_design(mob/user)
	var/upload = input(user, "Выберите файл проекта верфи (.json)", "Загрузка проекта") as null|file
	if(!upload || locked() || QDELETED(src) || !design)
		return
	var/datum/shipyard_design/loaded = new(zone_width, zone_height)
	var/error = loaded.import_json(file2text(upload))
	if(error)
		to_chat(user, span_warning(error))
		return
	design = loaded
	reset_preview()
	if(loaded.skipped)
		to_chat(user, span_warning("Проект загружен, но [loaded.skipped] деталей не поместились на площадку или не прошли проверку."))
	else
		to_chat(user, span_notice("Проект «[loaded.name]» загружен."))

/obj/machinery/computer/camera_advanced/shipyard/proc/zone_problem()
	for(var/local_x in 1 to zone_width)
		for(var/local_y in 1 to zone_height)
			var/turf/spot = zone_turf(local_x, local_y)
			if(!isspaceturf(spot))
				return "Площадка сборки занята: сначала уведите прошлый корабль."
			for(var/atom/movable/thing as anything in spot)
				if(istype(thing, /obj/docking_port/stationary))
					if(pad_awaited(thing))
						return "На площадку сборки заходит корабль."
					continue
				if(iseffect(thing) || isobserver(thing) || istype(thing, /mob/camera))
					continue
				return "На площадке сборки посторонние предметы или люди."
	return null

/obj/machinery/computer/camera_advanced/shipyard/proc/clear_old_pads()
	for(var/local_x in 1 to zone_width)
		for(var/local_y in 1 to zone_height)
			for(var/obj/docking_port/stationary/pad in zone_turf(local_x, local_y))
				if(!pad.get_docked() && !pad_awaited(pad))
					qdel(pad, force = TRUE)

/obj/machinery/computer/camera_advanced/shipyard/proc/pad_awaited(obj/docking_port/stationary/pad)
	for(var/obj/docking_port/mobile/port as anything in SSshuttle.mobile)
		if(port.destination == pad)
			return TRUE
	return FALSE

/obj/machinery/computer/camera_advanced/shipyard/proc/start_build(mob/user)
	if(building || paying)
		return
	var/list/stats = design.stats()
	if(length(stats["problems"]))
		to_chat(user, span_warning(stats["problems"][1]))
		return
	var/zone_issue = zone_problem()
	if(zone_issue)
		to_chat(user, span_warning(zone_issue))
		return
	var/obj/machinery/shipyard_loader/loader = linked_loader()
	if(!loader)
		to_chat(user, span_warning("Загрузчик материалов не найден."))
		return
	if(!loader.has_sheets(stats["metal"], stats["glass"], stats["plasma"]))
		to_chat(user, span_warning("В загрузчике не хватает материалов."))
		return
	paying = TRUE
	loader.use_sheets(stats["metal"], stats["glass"], stats["plasma"])
	var/paid = stats["credits"] <= 0 || pay_with_card(user, stats["credits"], "постройка шаттла «[design.name]»")
	paying = FALSE
	if(!paid || QDELETED(src))
		if(!QDELETED(loader))
			loader.add_sheets(stats["metal"], stats["glass"], stats["plasma"])
		return
	log_game("[key_name(user)] started building shuttle [design.name] at the shipyard for [stats["credits"]] credits.")
	begin_construction()

/obj/machinery/computer/camera_advanced/shipyard/proc/begin_construction()
	building = TRUE
	clear_old_pads()
	build_started = world.time
	build_duration = rand(SHIPYARD_BUILD_TIME_MIN, SHIPYARD_BUILD_TIME_MAX)
	build_queue = design.build_steps()
	build_done = 0
	build_turfs = list()
	for(var/list/tile as anything in design.hull_tiles())
		build_turfs[zone_turf(tile[1], tile[2])] = TRUE
	build_hull = new /area/shuttle/custom
	build_hull.name = design.name
	set_turfs_to_area(build_turfs, build_hull)
	build_hull.reg_in_areas_in_z()
	if(build_hull.static_lighting)
		build_hull.create_area_lighting_objects()
	require_area_resort()
	holograms = list()
	for(var/list/step as anything in build_queue)
		var/datum/shipyard_part/part = GLOB.shipyard_parts[step[1]]
		var/turf/spot = zone_turf(step[2], step[3])
		var/obj/effect/abstract/shipyard_hologram/hologram = new(spot)
		hologram.appearance = hologram_image(part, spot, list("dir" = step[4]))
		holograms += hologram
	icon_screen = "holocontrol"
	update_icon()
	atom_say("Постройка шаттла «[design.name]» начата. Ориентировочное время: [round(build_duration / (1 MINUTES), 0.1)] мин.")
	build_timer = addtimer(CALLBACK(src, PROC_REF(construction_tick)), SHIPYARD_BUILD_TICK, TIMER_STOPPABLE)

/obj/machinery/computer/camera_advanced/shipyard/proc/construction_tick()
	build_timer = null
	if(!building)
		return
	var/progress = min((world.time - build_started) / build_duration, 1)
	var/due = round(length(build_queue) * progress)
	var/turf/last_spot
	while(build_done < due)
		build_done++
		var/list/step = build_queue[build_done]
		var/datum/shipyard_part/part = GLOB.shipyard_parts[step[1]]
		last_spot = zone_turf(step[2], step[3])
		qdel(holograms[build_done])
		part.build(last_spot, step[4], step[5], step[6])
		if(traps_occupants(last_spot))
			for(var/atom/movable/stuck in last_spot)
				if((isliving(stuck) || isitem(stuck)) && !stuck.anchored)
					stuck.forceMove(get_turf(src))
	if(last_spot)
		do_sparks(3, TRUE, last_spot)
		playsound(last_spot, 'sound/items/welder.ogg', 40, TRUE)
	if(progress >= 1)
		finish_construction()
		return
	build_timer = addtimer(CALLBACK(src, PROC_REF(construction_tick)), SHIPYARD_BUILD_TICK, TIMER_STOPPABLE)

/obj/machinery/computer/camera_advanced/shipyard/proc/traps_occupants(turf/spot)
	if(spot.density)
		return TRUE
	for(var/atom/movable/thing as anything in spot)
		if(thing.density && !ismob(thing) && !(thing.flags & ON_BORDER) && !HAS_TRAIT(thing, TRAIT_CLIMBABLE))
			return TRUE
	return FALSE

/obj/machinery/computer/camera_advanced/shipyard/proc/finish_construction()
	QDEL_LIST(holograms)
	building = FALSE
	icon_screen = initial(icon_screen)
	update_icon()
	var/ship_name = build_hull.name
	var/obj/overmap/entity/vessel = SSovermap.commission_custom_shuttle(build_hull, build_turfs, SSovermap.service_sites[OVERMAP_SITE_SHIPYARD])
	for(var/turf/tile as anything in build_turfs)
		for(var/obj/docking_port/stationary/pad in tile)
			pad.area_type = /area/space/shipyard_zone
	atom_say(vessel ? "Шаттл «[ship_name]» построен и внесён в реестр полётов." : "Шаттл «[ship_name]» построен, но внести его в реестр полётов не удалось.")
	log_game("Shipyard finished building shuttle [ship_name] ([vessel ? "registered" : "not registered"]).")
	build_hull = null
	build_turfs = null
	build_queue = null
	SStgui.update_uis(src)

/obj/machinery/computer/camera_advanced/shipyard/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Shipyard", name)
		ui.open()

/obj/machinery/computer/camera_advanced/shipyard/ui_static_data(mob/user)
	var/list/parts = list()
	for(var/id in GLOB.shipyard_parts)
		var/datum/shipyard_part/part = GLOB.shipyard_parts[id]
		parts += list(list("id" = part.id, "name" = part.name, "category" = part.category, "metal" = part.metal, "glass" = part.glass, "plasma" = part.plasma, "credits" = part.credits, "rotatable" = part.rotatable, "door" = part.door, "access" = part.takes_access(), "size" = part.size, "mount" = part.layer == SHIPYARD_LAYER_MOUNT))
	var/list/accesses = list()
	for(var/access in get_all_accesses())
		accesses += list(list("id" = access, "name" = get_access_desc(access)))
	return list(
		"parts" = parts,
		"categories" = list(SHIPYARD_CATEGORY_FLOOR, SHIPYARD_CATEGORY_WALL, SHIPYARD_CATEGORY_DOOR, SHIPYARD_CATEGORY_POWER, SHIPYARD_CATEGORY_CONSOLE, SHIPYARD_CATEGORY_WEAPON, SHIPYARD_CATEGORY_ENGINE, SHIPYARD_CATEGORY_SENSOR, SHIPYARD_CATEGORY_FURNITURE, SHIPYARD_CATEGORY_STRUCTURE, SHIPYARD_CATEGORY_DECAL),
		"paints" = GLOB.shipyard_door_paints.Copy(),
		"accesses" = accesses,
		"zone" = list(zone_width, zone_height),
	)

/obj/machinery/computer/camera_advanced/shipyard/ui_data(mob/user)
	var/list/data = list()
	var/obj/machinery/shipyard_loader/loader = linked_loader()
	data["ready"] = !!design
	data["name"] = design?.name
	data["selected"] = selected_part
	data["dir"] = selected_dir
	data["paint"] = selected_paint
	data["access"] = selected_access
	data["viewing"] = current_user == user
	data["building"] = building
	data["stats"] = design?.stats()
	data["materials"] = loader ? list("metal" = loader.sheets(MAT_METAL), "glass" = loader.sheets(MAT_GLASS), "plasma" = loader.sheets(MAT_PLASMA)) : null
	if(building)
		data["progress"] = round(min((world.time - build_started) / build_duration, 1) * 100)
		data["time_left"] = round(max(build_started + build_duration - world.time, 0) / (1 SECONDS))
	data["zone_busy"] = !building && !!zone_problem()
	return data

/obj/machinery/computer/camera_advanced/shipyard/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..() || !design)
		return
	var/mob/user = ui.user
	switch(action)
		if("select_part")
			var/id = params["id"]
			if(id == SHIPYARD_ERASER || GLOB.shipyard_parts[id])
				selected_part = id
		if("set_dir")
			var/dir = text2num(params["dir"])
			if(dir in GLOB.cardinal)
				selected_dir = dir
		if("set_paint")
			if(params["paint"] in GLOB.shipyard_door_paints)
				selected_paint = params["paint"]
		if("toggle_access")
			var/access = text2num(params["access"])
			if(access in get_all_accesses())
				if(access in selected_access)
					selected_access -= access
				else
					selected_access += access
		if("clear_access")
			selected_access = list()
		if("set_name")
			if(!locked())
				design.name = shipyard_ship_name(params["name"])
		if("view")
			if(current_user == user)
				user.unset_machine()
			else
				start_view(user)
		if("clear")
			if(!locked())
				var/old_name = design.name
				design = new(zone_width, zone_height)
				design.name = old_name
				reset_preview()
		if("save")
			save_design(user)
		if("load")
			if(!locked())
				load_design(user)
		if("build")
			start_build(user)
	return TRUE

/mob/camera/aiEye/remote/shipyard
	name = "shipyard overview"
	use_static = FALSE
	simulated = FALSE

/mob/camera/aiEye/remote/shipyard/can_move(turf/target_turf, mob/user)
	var/obj/machinery/computer/camera_advanced/shipyard/console = origin
	return istype(console) && !!console.zone_coords(target_turf, SHIPYARD_EYE_MARGIN)

/obj/effect/abstract/shipyard_hologram
	name = "hologram"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/click_intercept/shipyard
	var/obj/machinery/computer/camera_advanced/shipyard/console

/datum/click_intercept/shipyard/New(client/C, obj/machinery/computer/camera_advanced/shipyard/console)
	src.console = console
	return ..()

/datum/click_intercept/shipyard/Destroy()
	if(console?.drafting == src)
		console.drafting = null
	console = null
	return ..()

/datum/click_intercept/shipyard/InterceptClickOn(mob/user, params, atom/object)
	if(QDELETED(console) || console.current_user != user)
		quit()
		return TRUE
	if(!isturf(object) && !isturf(object.loc))
		return FALSE
	var/list/coords = console.zone_coords(get_turf(object))
	if(!coords)
		return TRUE
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, ALT_CLICK))
		console.selected_dir = turn(console.selected_dir, -90)
		SStgui.update_uis(console)
	else if(LAZYACCESS(modifiers, RIGHT_CLICK) || console.selected_part == SHIPYARD_ERASER)
		console.erase_at(user, coords[1], coords[2])
	else
		console.place_at(user, coords[1], coords[2])
	return TRUE
