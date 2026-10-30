#define BUILDMODE_PREVIEW_ALPHA 150
#define BUILDMODE_PAGE_SIZE 96

/datum/buildmode_mode/builder
	key = "panel"
	button_icon_state = "buildmode_advanced"
	button_name = "Панель строительства"
	var/atom/selected_item
	var/image/preview_image
	var/mob/builder
	var/pixel_positioning = FALSE
	var/pixel_x_offset = 0
	var/pixel_y_offset = 0
	var/atom/movable/screen/buildmode_pixel_tracker/pixel_tracker
	var/datum/weakref/preview_eye_ref
	var/last_mouse_params
	var/list/preview_paths
	var/list/preview_icons = list()
	var/preview_revision = 0
	var/previews_loading = FALSE

/datum/buildmode_mode/builder/enter_mode(datum/click_intercept/buildmode/BM)
	RegisterSignal(BM, COMSIG_BUILDMODE_DIRECTION_CHANGED, PROC_REF(on_direction_changed))
	RegisterSignal(BM.holder, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_login))
	RegisterSignal(BM.holder, COMSIG_QDELETING, PROC_REF(on_client_deleted))
	RegisterSignal(BM.holder, COMSIG_CLIENT_SET_EYE, PROC_REF(on_eye_changed))
	RegisterSignal(BM.holder, COMSIG_VIEW_SET, PROC_REF(on_view_changed))
	on_login(BM.holder, BM.holder.mob)

/datum/buildmode_mode/builder/exit_mode(datum/click_intercept/buildmode/BM)
	SStgui.close_uis(src)
	preview_paths = null
	preview_icons = list()
	preview_revision++
	UnregisterSignal(BM, COMSIG_BUILDMODE_DIRECTION_CHANGED)
	UnregisterSignal(BM.holder, list(COMSIG_CLIENT_MOB_LOGIN, COMSIG_QDELETING, COMSIG_CLIENT_SET_EYE, COMSIG_VIEW_SET))
	set_preview_eye(null)
	if(builder)
		UnregisterSignal(builder, list(COMSIG_ATOM_MOUSE_ENTERED, COMSIG_QDELETING, COMSIG_VIEWDATA_UPDATE))
		builder = null
	clear_selection()

/datum/buildmode_mode/builder/Destroy()
	exit_mode(BM)
	. = ..()
	BM = null

/datum/buildmode_mode/builder/proc/on_login(client/source, mob/user)
	SIGNAL_HANDLER
	if(builder)
		UnregisterSignal(builder, list(COMSIG_ATOM_MOUSE_ENTERED, COMSIG_QDELETING, COMSIG_VIEWDATA_UPDATE))
	builder = user
	RegisterSignal(builder, COMSIG_ATOM_MOUSE_ENTERED, PROC_REF(on_mouse_entered))
	RegisterSignal(builder, COMSIG_QDELETING, PROC_REF(on_builder_deleted))
	RegisterSignal(builder, COMSIG_VIEWDATA_UPDATE, PROC_REF(on_view_changed))
	set_preview_eye(BM.holder.eye)
	if(preview_image)
		BM.holder.images |= preview_image
		preview_image.loc = null
	if(pixel_tracker)
		BM.holder.screen |= pixel_tracker
	INVOKE_ASYNC(src, PROC_REF(ui_interact), user)

/datum/buildmode_mode/builder/proc/on_client_deleted()
	SIGNAL_HANDLER
	BM.quit(TRUE)

/datum/buildmode_mode/builder/proc/on_builder_deleted()
	SIGNAL_HANDLER
	UnregisterSignal(builder, list(COMSIG_ATOM_MOUSE_ENTERED, COMSIG_QDELETING, COMSIG_VIEWDATA_UPDATE))
	builder = null
	if(preview_image)
		preview_image.loc = null

/datum/buildmode_mode/builder/proc/on_mouse_entered(datum/source, atom/target)
	SIGNAL_HANDLER
	if(pixel_positioning || is_screen_atom(target))
		return
	update_preview(get_turf(target))

/datum/buildmode_mode/builder/proc/on_direction_changed()
	SIGNAL_HANDLER
	if(preview_image)
		preview_image.dir = BM.build_dir
	SStgui.update_uis(src)

/datum/buildmode_mode/builder/proc/on_eye_changed(client/source, atom/old_eye, atom/new_eye)
	SIGNAL_HANDLER
	set_preview_eye(new_eye)

/datum/buildmode_mode/builder/proc/set_preview_eye(atom/new_eye)
	var/atom/old_eye = preview_eye_ref?.resolve()
	if(old_eye)
		UnregisterSignal(old_eye, COMSIG_MOVABLE_MOVED)
	preview_eye_ref = WEAKREF(new_eye)
	if(ismovable(new_eye))
		RegisterSignal(new_eye, COMSIG_MOVABLE_MOVED, PROC_REF(on_view_changed))
	on_view_changed()

/datum/buildmode_mode/builder/proc/on_view_changed()
	SIGNAL_HANDLER
	if(!pixel_positioning || !last_mouse_params)
		return
	addtimer(CALLBACK(src, PROC_REF(refresh_pixel_preview)), 0, TIMER_UNIQUE)

/datum/buildmode_mode/builder/proc/refresh_pixel_preview()
	if(pixel_positioning && last_mouse_params)
		track_pixel_position(BM.holder.mob, last_mouse_params)

/datum/buildmode_mode/builder/change_settings(mob/user)
	ui_interact(user)

/datum/buildmode_mode/builder/show_help(mob/user)
	to_chat(user, span_notice("Выберите тип в панели строительства. ЛКМ — разместить, Alt+ЛКМ — выбрать тип с карты, ПКМ — снять выбор, Alt+ПКМ — удалить объект. В пиксельном режиме Alt+клик открывает выбор цели на тайле. ПКМ по кнопке режима повторно открывает панель."))

/datum/buildmode_mode/builder/ui_state(mob/user)
	return ADMIN_STATE(R_BUILDMODE)

/datum/buildmode_mode/builder/ui_interact(mob/user, datum/tgui/ui = null)
	if(QDELETED(src) || user != BM.holder.mob)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BuildMode", "Панель строительства")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/buildmode_mode/builder/ui_close(mob/user)
	preview_paths = null
	preview_icons = list()
	preview_revision++

/datum/buildmode_mode/builder/ui_static_data(mob/user)
	return list("categories" = get_buildmode_categories())

/datum/buildmode_mode/builder/ui_data(mob/user)
	return list(
		"selected_item" = selected_item ? "[selected_item]" : null,
		"pixel_positioning" = pixel_positioning,
		"build_dir" = BM.build_dir,
		"preview_icons" = preview_icons,
	)

/datum/buildmode_mode/builder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(ui.user != BM.holder.mob || BM.mode != src)
		return
	switch(action)
		if("request_previews")
			var/list/paths = params["paths"]
			if(!islist(paths) || length(paths) > BUILDMODE_PAGE_SIZE)
				return
			preview_paths = list()
			preview_icons = list()
			for(var/path_text in paths)
				if(istext(path_text) && GLOB.buildmode_items[path_text])
					preview_paths |= path_text
			preview_revision++
			if(!previews_loading)
				INVOKE_ASYNC(src, PROC_REF(load_previews))
		if("select_item")
			if(!GLOB.buildmode_items[params["path"]])
				return
			select_item(text2path(params["path"]))
		if("clear_selection")
			clear_selection()
		if("toggle_pixel")
			if(!selected_item || ispath(selected_item, /turf))
				return
			set_pixel_positioning(!pixel_positioning)
		if("set_direction")
			var/new_direction = params["direction"]
			if(!(new_direction in GLOB.alldirs))
				return
			BM.change_dir(new_direction)
		else
			return
	return TRUE

/datum/buildmode_mode/builder/proc/load_previews()
	previews_loading = TRUE
	while(!QDELETED(src) && BM?.mode == src && !isnull(preview_paths))
		var/revision = preview_revision
		var/list/paths = preview_paths.Copy()
		if(selected_item)
			paths |= "[selected_item]"
		var/list/icons = get_buildmode_previews(paths)
		if(QDELETED(src) || BM?.mode != src)
			break
		if(revision != preview_revision)
			continue
		preview_icons = icons
		SStgui.update_uis(src)
		break
	previews_loading = FALSE

/datum/buildmode_mode/builder/proc/select_item(atom/item_path)
	if(!(ispath(item_path, /turf) || ispath(item_path, /obj) || ispath(item_path, /mob)))
		return
	if(item_path in get_abstract_types())
		return
	if(ispath(item_path, /atom/movable/screen))
		return
	selected_item = item_path
	if(ispath(selected_item, /turf))
		set_pixel_positioning(FALSE)
	var/turf/preview_turf = get_turf(preview_image?.loc)
	if(preview_image)
		BM.holder.images -= preview_image
		QDEL_NULL(preview_image)
	preview_image = image(new /mutable_appearance(item_path))
	var/icon_state = get_buildmode_greyscale_state(item_path)
	if(!isnull(icon_state))
		preview_image.icon = SSgreyscale.get_colored_icon_by_type(item_path::greyscale_config, item_path::greyscale_colors)
		preview_image.icon_state = icon_state
	preview_image.alpha = BUILDMODE_PREVIEW_ALPHA
	preview_image.color = LIGHT_COLOR_LIGHT_CYAN
	preview_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	preview_image.layer = FLOAT_LAYER
	BM.holder.images += preview_image
	update_preview(preview_turf)
	SStgui.update_uis(src)

/datum/buildmode_mode/builder/proc/clear_selection()
	set_pixel_positioning(FALSE)
	selected_item = null
	if(preview_image)
		BM.holder.images -= preview_image
		QDEL_NULL(preview_image)
	SStgui.update_uis(src)

/datum/buildmode_mode/builder/proc/set_pixel_positioning(enabled)
	pixel_positioning = enabled
	last_mouse_params = null
	pixel_x_offset = 0
	pixel_y_offset = 0
	if(pixel_tracker)
		BM.holder.screen -= pixel_tracker
		QDEL_NULL(pixel_tracker)
	if(enabled)
		pixel_tracker = new(null, src)
		BM.holder.screen += pixel_tracker
	if(preview_image)
		update_preview(get_turf(preview_image.loc))

/datum/buildmode_mode/builder/proc/update_preview(turf/location)
	if(!preview_image)
		return
	preview_image.loc = location
	preview_image.dir = BM.build_dir
	preview_image.pixel_x = selected_item::pixel_x + pixel_x_offset
	preview_image.pixel_y = selected_item::pixel_y + pixel_y_offset
	if(location)
		SET_PLANE(preview_image, ABOVE_LIGHTING_PLANE, location)

/datum/buildmode_mode/builder/handle_click(mob/user, params, atom/object)
	if(user != BM.holder.mob || is_screen_atom(object))
		return TRUE
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, ALT_CLICK))
		if(LAZYACCESS(modifiers, LEFT_CLICK))
			select_item(object.type)
		else if(LAZYACCESS(modifiers, RIGHT_CLICK) && isobj(object))
			log_admin("Build Mode: [key_name(user)] deleted [object] at [AREACOORD(object)]")
			qdel(object)
		return TRUE
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		clear_selection()
		return TRUE
	if(!LAZYACCESS(modifiers, LEFT_CLICK) || !selected_item)
		return TRUE
	var/turf/location = get_turf(object)
	if(!location)
		return TRUE
	place_object(location, user, BM.build_dir)
	return TRUE

/datum/buildmode_mode/builder/proc/place_object(turf/location, mob/user, build_dir)
	var/atom/placed
	if(ispath(selected_item, /turf))
		placed = location.ChangeTurf(selected_item)
	else
		placed = new selected_item(location)
		if(QDELETED(placed))
			return
		placed.pixel_x += pixel_x_offset
		placed.pixel_y += pixel_y_offset
	placed.setDir(build_dir)
	log_admin("Build Mode: [key_name(user)] placed [selected_item] at [AREACOORD(placed)] with dir [build_dir] and pixel offset [pixel_x_offset],[pixel_y_offset]")
	update_preview(get_turf(placed))
	return placed

/datum/buildmode_mode/builder/proc/track_pixel_position(mob/user, params)
	if(user != BM.holder.mob || !pixel_positioning)
		return
	var/list/modifiers = params2list(params)
	var/screen_location = LAZYACCESS(modifiers, SCREEN_LOC)
	if(!screen_location)
		return
	last_mouse_params = params
	var/list/position = get_buildmode_pixel_position(screen_location, get_turf(BM.holder.eye), BM.holder.view, BM.holder.pixel_x, BM.holder.pixel_y)
	if(!position)
		return
	pixel_x_offset = position[2]
	pixel_y_offset = position[3]
	update_preview(position[1])
	return position[1]

/proc/get_buildmode_pixel_position(screen_location, turf/eye_turf, view_size, camera_pixel_x = 0, camera_pixel_y = 0)
	if(!eye_turf)
		return
	var/list/offsets = screen_loc_to_offset(screen_location, view_size)
	var/list/view_dimensions = getviewsize(view_size)
	var/map_x = offsets[1] - ICON_SIZE_X - 1 + camera_pixel_x
	var/map_y = offsets[2] - ICON_SIZE_Y - 1 + camera_pixel_y
	var/turf/location = locate(eye_turf.x + floor(map_x / ICON_SIZE_X) - floor(view_dimensions[1] / 2), eye_turf.y + floor(map_y / ICON_SIZE_Y) - floor(view_dimensions[2] / 2), eye_turf.z)
	return list(
		location,
		map_x - floor(map_x / ICON_SIZE_X) * ICON_SIZE_X + 1 - ICON_SIZE_X / 2,
		map_y - floor(map_y / ICON_SIZE_Y) * ICON_SIZE_Y + 1 - ICON_SIZE_Y / 2,
	)

/atom/movable/screen/buildmode_pixel_tracker
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	alpha = 1
	layer = BACKGROUND_LAYER
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	var/datum/buildmode_mode/builder/owner

/atom/movable/screen/buildmode_pixel_tracker/Initialize(mapload, datum/buildmode_mode/builder/owner)
	. = ..(mapload)
	src.owner = owner

/atom/movable/screen/buildmode_pixel_tracker/Destroy()
	owner = null
	return ..()

/atom/movable/screen/buildmode_pixel_tracker/MouseEntered(location, control, params)
	MouseMove(location, control, params)

/atom/movable/screen/buildmode_pixel_tracker/MouseMove(location, control, params)
	owner.track_pixel_position(usr, params)

/atom/movable/screen/buildmode_pixel_tracker/Click(location, control, params)
	var/datum/buildmode_mode/builder/build_mode = owner
	var/turf/target = build_mode.track_pixel_position(usr, params)
	if(!target)
		return
	var/atom/selected = target
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, ALT_CLICK))
		var/list/targets = list(target)
		for(var/atom/movable/candidate in target)
			if(ismob(candidate) || isobj(candidate))
				targets += candidate
		selected = tgui_input_list(usr, "Выберите цель на тайле.", "Панель строительства", targets)
		if(!selected || QDELETED(selected) || QDELETED(build_mode))
			return
	build_mode.handle_click(usr, params, selected)

#undef BUILDMODE_PREVIEW_ALPHA
#undef BUILDMODE_PAGE_SIZE
