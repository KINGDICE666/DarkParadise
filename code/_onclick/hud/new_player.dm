#define LINK_BUTTON_ROW_Y 112
#define LINK_BUTTONS_PER_ROW 5
#define LINK_BUTTON_STEP 27
#define LINK_BUTTON_SIZE 24
#define LINK_HINT_HEIGHT 20
#define LINK_BUTTONS_RIGHT (4 * ICON_SIZE_X)
#define NEW_PLAYER_INFO_BODY_CENTER 52
#define NEW_PLAYER_INFO_BOTTOM 140
#define NEW_PLAYER_INFO_WIDTH 128
#define NEW_PLAYER_INFO_HEIGHT 96
#define LOBBY_MENU_LEFT -120
#define LOBBY_MENU_WIDTH 269
#define LOBBY_MENU_HEIGHT 166
#define LOBBY_MENU_START_NOW_HEIGHT 189
#define LOBBY_LAYOUT_MARGIN 8
#define LOBBY_LAYOUT_SNAP_DISTANCE 8
#define LOBBY_LAYOUT_BUTTON_WIDTH 72
#define LOBBY_LAYOUT_BUTTON_HEIGHT 18
#define LOBBY_LAYOUT_BUTTON_GAP 6
#define LOBBY_LAYOUT_HINT_WIDTH 320
#define LOBBY_VIEWPORT_FIT_DELAY (1 SECONDS)

GLOBAL_LIST_INIT(lobby_layout_presets, list(
	LOBBY_LAYOUT_DEFAULT = list(),
	LOBBY_LAYOUT_CORNERS = list(
		LOBBY_GROUP_PHRASE = list(NORTHWEST, 0, -LOBBY_LAYOUT_MARGIN),
		LOBBY_GROUP_NOTICE = list(NORTHWEST, 0, -4 * LOBBY_LAYOUT_MARGIN),
		LOBBY_GROUP_LINKS = list(SOUTHEAST, -LOBBY_LAYOUT_MARGIN, 0),
	),
	LOBBY_LAYOUT_MENU_LEFT = list(
		LOBBY_GROUP_MENU = list(NORTHWEST, 0, 0),
	),
	LOBBY_LAYOUT_MENU_RIGHT = list(
		LOBBY_GROUP_MENU = list(NORTHEAST, 0, 0),
		LOBBY_GROUP_INFO = list(NORTHWEST, 0, -20),
		LOBBY_GROUP_LINKS = list(NORTHWEST, 0, -120),
	),
))

/datum/hud/new_player
	var/menu_hud_status = TRUE
	var/list/layout = list()
	var/list/group_shifts = list()
	var/list/link_box
	var/datum/lobby_layout_editor/layout_editor

/datum/hud/new_player/New(mob/owner)
	. = ..()
	if(!owner?.client)
		return

	var/list/link_buttons = list()
	for(var/atom/movable/screen/lobby/lobbyscreen as anything in subtypesof(/atom/movable/screen/lobby))
		if(lobbyscreen::abstract_type == lobbyscreen || !lobbyscreen::always_available)
			continue
		lobbyscreen = new lobbyscreen(null, src)
		if(!lobbyscreen.is_available(owner.client))
			qdel(lobbyscreen)
			continue
		static_inventory += lobbyscreen
		lobbyscreen.SlowInit()
		if(istype(lobbyscreen, /atom/movable/screen/lobby/button/bottom/link))
			link_buttons += lobbyscreen
		if(!lobbyscreen.always_shown)
			lobbyscreen.RegisterSignal(src, COMSIG_HUD_LOBBY_COLLAPSED, TYPE_PROC_REF(/atom/movable/screen/lobby, collapse_button))
			lobbyscreen.RegisterSignal(src, COMSIG_HUD_LOBBY_EXPANDED, TYPE_PROC_REF(/atom/movable/screen/lobby, expand_button))

	place_link_buttons(link_buttons)
	var/atom/movable/screen/lobby/button/bottom/link/discord_link/discord_link = locate() in static_inventory
	discord_link?.start_spotlight()
	addtimer(CALLBACK(owner.client, TYPE_PROC_REF(/client, attempt_auto_fit_viewport)), LOBBY_VIEWPORT_FIT_DELAY)

	if(owner.client.is_connecting_from_localhost())
		var/atom/movable/screen/lobby/button/start_now/start_button = new(null, src)
		static_inventory += start_button
		start_button.SlowInit()
		start_button.RegisterSignal(src, COMSIG_HUD_LOBBY_COLLAPSED, TYPE_PROC_REF(/atom/movable/screen/lobby, collapse_button))
		start_button.RegisterSignal(src, COMSIG_HUD_LOBBY_EXPANDED, TYPE_PROC_REF(/atom/movable/screen/lobby, expand_button))

	RegisterSignal(owner.client, COMSIG_VIEW_SET, PROC_REF(on_view_set))
	apply_layout(get_saved_layout())

/datum/hud/new_player/Destroy()
	QDEL_NULL(layout_editor)
	return ..()

/datum/hud/new_player/apply_parallax_pref()
	mymob.client.parallax_rock.set_layer_settings(layers_to_draw = 0, draw_old_space = FALSE, animate_parallax = FALSE)

/datum/hud/new_player/proc/place_link_buttons(list/link_buttons)
	var/min_x = INFINITY
	var/min_y = INFINITY
	var/max_x = -INFINITY
	var/max_y = -INFINITY
	for(var/row_start in 1 to length(link_buttons) step LINK_BUTTONS_PER_ROW)
		var/list/row = link_buttons.Copy(row_start, min(row_start + LINK_BUTTONS_PER_ROW, length(link_buttons) + 1))
		var/row_width = length(row) * LINK_BUTTON_STEP - (LINK_BUTTON_STEP - LINK_BUTTON_SIZE)
		var/x_offset = round(NEW_PLAYER_INFO_BODY_CENTER - row_width / 2)
		var/y_offset = LINK_BUTTON_ROW_Y - (row_start - 1) / LINK_BUTTONS_PER_ROW * LINK_BUTTON_STEP
		min_x = min(min_x, x_offset)
		max_x = max(max_x, x_offset + row_width)
		min_y = min(min_y, y_offset)
		max_y = max(max_y, y_offset + LINK_BUTTON_SIZE)
		for(var/atom/movable/screen/lobby/button/bottom/link/button as anything in row)
			button.screen_loc = "EAST-3:[x_offset],CENTER:[y_offset]"
			button.base_screen_loc = button.screen_loc
			button.edge_distance = LINK_BUTTONS_RIGHT - x_offset
			x_offset += LINK_BUTTON_STEP
	if(length(link_buttons))
		link_box = list(min_x, min_y - LINK_HINT_HEIGHT, max_x - min_x, max_y - min_y + LINK_HINT_HEIGHT)

/datum/hud/new_player/proc/get_saved_layout()
	var/datum/preferences/prefs = mymob.client?.prefs
	if(!prefs)
		return list()
	var/preset = prefs.read_preference(/datum/preference/choiced/lobby_layout)
	if(preset == LOBBY_LAYOUT_CUSTOM)
		return prefs.read_preference(/datum/preference/lobby_layout_custom)
	return GLOB.lobby_layout_presets[preset]

/datum/hud/new_player/proc/apply_layout(list/new_layout)
	layout = new_layout
	if(!menu_hud_status)
		var/atom/movable/screen/lobby/button/collapse/collapse_button = locate() in static_inventory
		INVOKE_ASYNC(collapse_button, TYPE_PROC_REF(/atom/movable/screen/lobby/button/collapse, toggle_menu))
	group_shifts = list()
	for(var/atom/movable/screen/lobby/element in static_inventory)
		var/group = element.lobby_group
		if(!group)
			continue
		if(!group_shifts[group])
			var/list/default_box = get_default_box(group)
			var/list/box = get_layout_box(group)
			group_shifts[group] = list(box[1] - default_box[1], box[2] - default_box[2])
		var/list/shift = group_shifts[group]
		var/list/entry = layout[group]
		element.apply_layout_shift(shift[1], shift[2], length(entry) ? entry[1] : NONE)
	layout_editor?.refresh()

/datum/hud/new_player/proc/get_default_box(group)
	var/list/view_size = view_to_pixels(mymob.client.view)
	var/center_x = view_size[1] / 2 - ICON_SIZE_X / 2
	var/center_y = view_size[2] / 2 - ICON_SIZE_Y / 2
	switch(group)
		if(LOBBY_GROUP_MENU)
			var/menu_height = (locate(/atom/movable/screen/lobby/button/start_now) in static_inventory) ? LOBBY_MENU_START_NOW_HEIGHT : LOBBY_MENU_HEIGHT
			return list(center_x + LOBBY_MENU_LEFT, view_size[2] - menu_height, LOBBY_MENU_WIDTH, menu_height)
		if(LOBBY_GROUP_INFO)
			return list(view_size[1] - NEW_PLAYER_INFO_WIDTH, center_y + NEW_PLAYER_INFO_BOTTOM, NEW_PLAYER_INFO_WIDTH, NEW_PLAYER_INFO_HEIGHT)
		if(LOBBY_GROUP_LINKS)
			return list(view_size[1] - LINK_BUTTONS_RIGHT + link_box[1], center_y + link_box[2], link_box[3], link_box[4])
	for(var/atom/movable/screen/lobby/caption/caption in static_inventory)
		if(caption.lobby_group == group)
			return list(0, caption.bottom_row * ICON_SIZE_Y, view_size[1], caption.maptext_height)

/datum/hud/new_player/proc/get_layout_box(group, list/entry = layout[group])
	var/list/box = get_default_box(group)
	if(!length(entry))
		return box
	var/list/view_size = view_to_pixels(mymob.client.view)
	box[1] = clamp(get_anchor_origin(entry[1] & (WEST|EAST), WEST, view_size[1], box[3]) + entry[2], 0, max(view_size[1] - box[3], 0))
	box[2] = clamp(get_anchor_origin(entry[1] & (SOUTH|NORTH), SOUTH, view_size[2], box[4]) + entry[3], 0, max(view_size[2] - box[4], 0))
	return box

/datum/hud/new_player/proc/get_layout_entry(list/box, focus_x = box[1] + box[3] / 2)
	var/list/view_size = view_to_pixels(mymob.client.view)
	var/horizontal = get_edge_anchor(focus_x, view_size[1], WEST, EAST)
	var/vertical = get_edge_anchor(box[2] + box[4] / 2, view_size[2], SOUTH, NORTH)
	return list(
		horizontal | vertical,
		box[1] - get_anchor_origin(horizontal, WEST, view_size[1], box[3]),
		box[2] - get_anchor_origin(vertical, SOUTH, view_size[2], box[4]),
	)

/datum/hud/new_player/proc/get_anchor_origin(anchor, near_edge, space, size)
	if(!anchor)
		return round((space - size) / 2)
	return anchor == near_edge ? 0 : space - size

/datum/hud/new_player/proc/get_edge_anchor(position, space, near_edge, far_edge)
	if(position < space / 3)
		return near_edge
	if(position > space * 2 / 3)
		return far_edge
	return NONE

/datum/hud/new_player/proc/get_collapse_shift(atom/movable/screen/lobby/element)
	var/list/shift = group_shifts[element.lobby_group]
	if(element.lobby_group == LOBBY_GROUP_MENU)
		return list(0, element.collapse_distance - shift[2])
	var/list/box = get_layout_box(element.lobby_group)
	var/view_width = view_to_pixels(mymob.client.view)[1]
	if(box[1] + box[3] / 2 < view_width / 2)
		return list(-max(element.collapse_distance, box[1] + box[3]), 0)
	return list(max(element.collapse_distance, view_width - box[1]), 0)

/datum/hud/new_player/proc/on_view_set(datum/source, new_size)
	SIGNAL_HANDLER
	apply_layout(layout)

/datum/hud/new_player/proc/start_layout_editing()
	if(layout_editor)
		return
	var/list/editable_layout = list()
	for(var/group in layout)
		var/list/entry = layout[group]
		editable_layout[group] = entry.Copy()
	apply_layout(editable_layout)
	layout_editor = new(src)

/datum/hud/new_player/proc/stop_layout_editing(save)
	if(!layout_editor)
		return
	var/list/edited_layout = layout_editor.layout
	QDEL_NULL(layout_editor)
	if(save)
		var/datum/preferences/prefs = mymob.client.prefs
		prefs.write_preference(GLOB.preference_entries[/datum/preference/lobby_layout_custom], edited_layout)
		prefs.write_preference(GLOB.preference_entries[/datum/preference/choiced/lobby_layout], LOBBY_LAYOUT_CUSTOM)
	apply_layout(get_saved_layout())
	if(save)
		mymob.client.prefs.save_preferences(mymob.client)

/datum/lobby_layout_editor
	var/datum/hud/new_player/hud
	var/list/layout
	var/list/frames = list()
	var/list/screen_objects = list()
	var/list/controls = list()
	var/atom/movable/screen/lobby/layout_label/hint
	var/atom/movable/screen/lobby/layout_rect/frame/dragged_frame
	var/list/drag_start_cursor
	var/list/drag_start_box

/datum/lobby_layout_editor/New(datum/hud/new_player/hud)
	src.hud = hud
	layout = hud.layout
	var/static/list/group_names = list(
		LOBBY_GROUP_PHRASE = "Фраза",
		LOBBY_GROUP_NOTICE = "Объявление",
		LOBBY_GROUP_MENU = "Меню",
		LOBBY_GROUP_INFO = "Статус раунда",
		LOBBY_GROUP_LINKS = "Ссылки",
	)
	for(var/group in group_names)
		if(!hud.group_shifts[group])
			continue
		var/atom/movable/screen/lobby/layout_rect/frame/frame = add_rect(/atom/movable/screen/lobby/layout_rect/frame, group_names[group])
		frame.group = group
		if(group == LOBBY_GROUP_PHRASE || group == LOBBY_GROUP_NOTICE)
			frame.layer = LOBBY_LAYOUT_FRAME_LAYER - 0.01
			frame.label.layer = frame.layer
		frames[group] = frame
	for(var/control_type in list(
		/atom/movable/screen/lobby/layout_rect/control/done,
		/atom/movable/screen/lobby/layout_rect/control/reset,
		/atom/movable/screen/lobby/layout_rect/control/cancel,
	))
		controls += add_rect(control_type)
	hint = new(null, hud)
	hint.layer = LOBBY_LAYOUT_CONTROL_LAYER
	hint.text_style = "text-align: center"
	hint.set_text("Перетаскивайте блоки мышью")
	screen_objects += hint
	hud.mymob.client.screen += screen_objects
	var/client/owner = hud.mymob.client
	RegisterSignal(owner, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(on_mouse_down))
	RegisterSignal(owner, COMSIG_CLIENT_MOUSEDRAG, PROC_REF(on_mouse_drag))
	RegisterSignal(owner, COMSIG_CLIENT_MOUSEUP, PROC_REF(on_mouse_up))
	refresh()

/datum/lobby_layout_editor/Destroy()
	hud.mymob?.client?.screen -= screen_objects
	QDEL_LIST(screen_objects)
	frames.Cut()
	controls.Cut()
	hint = null
	dragged_frame = null
	hud = null
	return ..()

/datum/lobby_layout_editor/proc/add_rect(rect_type, label_text)
	var/atom/movable/screen/lobby/layout_rect/rect = new rect_type(null, hud, src)
	if(label_text)
		rect.label.set_text(label_text)
	screen_objects += rect
	screen_objects += rect.label
	return rect

/datum/lobby_layout_editor/proc/refresh()
	for(var/group in frames)
		var/atom/movable/screen/lobby/layout_rect/frame/frame = frames[group]
		frame.set_box(hud.get_layout_box(group, layout[group]))
	var/list/view_size = view_to_pixels(hud.mymob.client.view)
	var/controls_width = length(controls) * (LOBBY_LAYOUT_BUTTON_WIDTH + LOBBY_LAYOUT_BUTTON_GAP) - LOBBY_LAYOUT_BUTTON_GAP
	var/control_x = round((view_size[1] - controls_width) / 2)
	var/control_y = round((view_size[2] - LOBBY_LAYOUT_BUTTON_HEIGHT) / 2)
	for(var/atom/movable/screen/lobby/layout_rect/control/control as anything in controls)
		control.set_box(list(control_x, control_y, LOBBY_LAYOUT_BUTTON_WIDTH, LOBBY_LAYOUT_BUTTON_HEIGHT))
		control_x += LOBBY_LAYOUT_BUTTON_WIDTH + LOBBY_LAYOUT_BUTTON_GAP
	hint.screen_loc = shift_screen_loc(hint.base_screen_loc, round((view_size[1] - LOBBY_LAYOUT_HINT_WIDTH) / 2), control_y + LOBBY_LAYOUT_BUTTON_HEIGHT + LOBBY_LAYOUT_BUTTON_GAP)
	hint.maptext_width = LOBBY_LAYOUT_HINT_WIDTH

/datum/lobby_layout_editor/proc/reset()
	layout.Cut()
	hud.apply_layout(layout)

/datum/lobby_layout_editor/proc/on_mouse_down(client/source, atom/object, location, control, params)
	SIGNAL_HANDLER
	var/atom/movable/screen/lobby/layout_rect/frame/frame = object
	if(!istype(frame) || frame.editor != src)
		return
	var/list/modifiers = params2list(params)
	var/cursor_loc = LAZYACCESS(modifiers, SCREEN_LOC)
	if(!LAZYACCESS(modifiers, LEFT_CLICK) || !cursor_loc)
		return
	dragged_frame?.set_dragged(FALSE)
	dragged_frame = frame
	drag_start_cursor = screen_loc_to_offset(cursor_loc, source.view)
	drag_start_box = hud.get_layout_box(frame.group, layout[frame.group])
	frame.set_dragged(TRUE)

/datum/lobby_layout_editor/proc/on_mouse_drag(client/source, atom/src_object, atom/over_object, src_location, over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	if(!dragged_frame || src_object != dragged_frame)
		return
	var/cursor_loc = LAZYACCESS(params2list(params), SCREEN_LOC)
	if(!cursor_loc)
		return
	var/list/cursor = screen_loc_to_offset(cursor_loc, source.view)
	var/list/view_size = view_to_pixels(source.view)
	var/group = dragged_frame.group
	var/list/default_box = hud.get_default_box(group)
	var/list/box = drag_start_box.Copy()
	var/max_x = max(view_size[1] - box[3], 0)
	var/max_y = max(view_size[2] - box[4], 0)
	box[1] = snap_position(clamp(box[1] + cursor[1] - drag_start_cursor[1], 0, max_x), list(0, max_x, round(max_x / 2), default_box[1]))
	box[2] = snap_position(clamp(box[2] + cursor[2] - drag_start_cursor[2], 0, max_y), list(0, max_y, round(max_y / 2), default_box[2]))
	var/list/entry = hud.get_layout_entry(box, max_x ? box[1] + box[3] / 2 : cursor[1] - ICON_SIZE_X)
	if((box ~= default_box) && (max_x || !(entry[1] & (WEST|EAST))))
		layout -= group
	else
		layout[group] = entry
	hud.apply_layout(layout)

/datum/lobby_layout_editor/proc/on_mouse_up(client/source, atom/object, location, control, params)
	SIGNAL_HANDLER
	dragged_frame?.set_dragged(FALSE)
	dragged_frame = null

/datum/lobby_layout_editor/proc/snap_position(position, list/targets)
	for(var/target in targets)
		if(abs(position - target) <= LOBBY_LAYOUT_SNAP_DISTANCE)
			return target
	return position

#undef LINK_BUTTON_ROW_Y
#undef LINK_BUTTONS_PER_ROW
#undef LINK_BUTTON_STEP
#undef LINK_BUTTON_SIZE
#undef LINK_HINT_HEIGHT
#undef LINK_BUTTONS_RIGHT
#undef NEW_PLAYER_INFO_BODY_CENTER
#undef NEW_PLAYER_INFO_BOTTOM
#undef NEW_PLAYER_INFO_WIDTH
#undef NEW_PLAYER_INFO_HEIGHT
#undef LOBBY_MENU_LEFT
#undef LOBBY_MENU_WIDTH
#undef LOBBY_MENU_HEIGHT
#undef LOBBY_MENU_START_NOW_HEIGHT
#undef LOBBY_LAYOUT_MARGIN
#undef LOBBY_LAYOUT_SNAP_DISTANCE
#undef LOBBY_LAYOUT_BUTTON_WIDTH
#undef LOBBY_LAYOUT_BUTTON_HEIGHT
#undef LOBBY_LAYOUT_BUTTON_GAP
#undef LOBBY_LAYOUT_HINT_WIDTH
#undef LOBBY_VIEWPORT_FIT_DELAY
