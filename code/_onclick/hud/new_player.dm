#define LINK_BUTTON_ROW_Y 112
#define LINK_BUTTONS_PER_ROW 5
#define LINK_BUTTON_STEP 27
#define LINK_BUTTON_SIZE 24
#define NEW_PLAYER_INFO_BODY_CENTER 52
#define LOBBY_VIEWPORT_FIT_DELAY (1 SECONDS)

/datum/hud/new_player
	var/menu_hud_status = TRUE

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
	addtimer(CALLBACK(owner.client, TYPE_PROC_REF(/client, attempt_auto_fit_viewport)), LOBBY_VIEWPORT_FIT_DELAY)

	if(!owner.client.is_connecting_from_localhost())
		return

	var/atom/movable/screen/lobby/button/start_now/start_button = new(null, src)
	static_inventory += start_button
	start_button.SlowInit()
	start_button.RegisterSignal(src, COMSIG_HUD_LOBBY_COLLAPSED, TYPE_PROC_REF(/atom/movable/screen/lobby, collapse_button))
	start_button.RegisterSignal(src, COMSIG_HUD_LOBBY_EXPANDED, TYPE_PROC_REF(/atom/movable/screen/lobby, expand_button))

/datum/hud/new_player/apply_parallax_pref()
	mymob.client.parallax_rock.set_layer_settings(layers_to_draw = 0, draw_old_space = FALSE, animate_parallax = FALSE)

/datum/hud/new_player/proc/place_link_buttons(list/link_buttons)
	for(var/row_start in 1 to length(link_buttons) step LINK_BUTTONS_PER_ROW)
		var/list/row = link_buttons.Copy(row_start, min(row_start + LINK_BUTTONS_PER_ROW, length(link_buttons) + 1))
		var/row_width = length(row) * LINK_BUTTON_STEP - (LINK_BUTTON_STEP - LINK_BUTTON_SIZE)
		var/x_offset = round(NEW_PLAYER_INFO_BODY_CENTER - row_width / 2)
		var/y_offset = LINK_BUTTON_ROW_Y - (row_start - 1) / LINK_BUTTONS_PER_ROW * LINK_BUTTON_STEP
		for(var/atom/movable/screen/lobby/button/bottom/link/button as anything in row)
			button.screen_loc = "EAST-3:[x_offset],CENTER:[y_offset]"
			button.maptext_x = min(button.maptext_x, -x_offset)
			x_offset += LINK_BUTTON_STEP

#undef LINK_BUTTON_ROW_Y
#undef LINK_BUTTONS_PER_ROW
#undef LINK_BUTTON_STEP
#undef LINK_BUTTON_SIZE
#undef NEW_PLAYER_INFO_BODY_CENTER
#undef LOBBY_VIEWPORT_FIT_DELAY
