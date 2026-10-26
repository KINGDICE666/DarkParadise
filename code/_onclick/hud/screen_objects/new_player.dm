#define SHUTTER_MOVEMENT_DURATION 0.4 SECONDS
#define SHUTTER_WAIT_DURATION 0.2 SECONDS
#define LOBBY_COLLAPSE_DISTANCE 146
#define LOBBY_HANDLE_COLLAPSE_DISTANCE 134
#define LOBBY_SHUTTER_DROP_DISTANCE 143
#define LOBBY_BOTTOM_BUTTON_SIZE 24
#define LINK_HINT_MAX_WIDTH 192
#define LINK_HINT_WIDTH_PADDING 2
#define LOBBY_DIMMED_COLOR "#4a4a4a"
#define DISCORD_SPOTLIGHT_OUTLINE "discord_spotlight_outline"
#define DISCORD_SPOTLIGHT_GLOW "discord_spotlight_glow"
#define DISCORD_SPOTLIGHT_GLOW_COLOR "#ffc83ccc"
#define DISCORD_SPOTLIGHT_PULSE_DURATION (0.8 SECONDS)
#define LOBBY_CAPTION_MARGIN 8
#define LAYOUT_LABEL_PADDING 2
#define LAYOUT_FRAME_COLOR "#4aa3ff"
#define LAYOUT_FRAME_ALPHA 60
#define LAYOUT_FRAME_DRAGGED_ALPHA 120
#define LAYOUT_CONTROL_ALPHA 210

INITIALIZE_IMMEDIATE(/atom/movable/screen/lobby)

/atom/movable/screen/lobby
	plane = SPLASHSCREEN_PLANE
	layer = LOBBY_MENU_LAYER
	screen_loc = "TOP,CENTER"
	abstract_type = /atom/movable/screen/lobby
	var/always_shown = FALSE
	var/always_available = TRUE
	var/collapse_distance = LOBBY_COLLAPSE_DISTANCE
	var/lobby_group = LOBBY_GROUP_MENU
	var/base_screen_loc

/atom/movable/screen/lobby/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	base_screen_loc = screen_loc

/atom/movable/screen/lobby/proc/is_available(client/viewer)
	return TRUE

/atom/movable/screen/lobby/proc/apply_layout_shift(shift_x, shift_y, anchor)
	screen_loc = shift_screen_loc(base_screen_loc, shift_x, shift_y)

/atom/movable/screen/lobby/proc/SlowInit()
	return

/atom/movable/screen/lobby/proc/collapse_button()
	SIGNAL_HANDLER
	var/datum/hud/new_player/lobby_hud = hud
	var/list/shift = lobby_hud.get_collapse_shift(src)
	animate(src, transform = transform, time = SHUTTER_MOVEMENT_DURATION + SHUTTER_WAIT_DURATION)
	animate(transform = transform.Translate(x = shift[1], y = shift[2]), time = SHUTTER_MOVEMENT_DURATION, easing = CUBIC_EASING|EASE_IN)

/atom/movable/screen/lobby/proc/expand_button()
	SIGNAL_HANDLER
	animate(src, transform = matrix(), time = SHUTTER_MOVEMENT_DURATION, easing = CUBIC_EASING|EASE_OUT)

/atom/movable/screen/lobby/background
	icon = 'icons/hud/lobby/background.dmi'
	icon_state = "background"
	layer = LOBBY_BACKGROUND_LAYER
	screen_loc = "TOP,CENTER:-61"

/atom/movable/screen/lobby/button
	abstract_type = /atom/movable/screen/lobby/button
	mouse_over_pointer = MOUSE_HAND_POINTER
	VAR_PROTECTED/enabled = TRUE
	var/highlighted = FALSE
	var/dimmed = FALSE
	var/select_sound_play = TRUE

/atom/movable/screen/lobby/button/Click(location, control, params)
	if(usr != hud?.mymob)
		return
	. = ..()
	if(!enabled)
		return
	flick("[base_icon_state]_pressed", src)
	if(select_sound_play)
		var/sound/ui_select_sound = sound('sound/misc/menu/ui_select1.ogg')
		ui_select_sound.frequency = get_rand_frequency_low_range()
		SEND_SOUND(hud.mymob, ui_select_sound)
	update_appearance(UPDATE_ICON)
	return TRUE

/atom/movable/screen/lobby/button/MouseEntered(location, control, params)
	if(usr != hud?.mymob)
		return
	. = ..()
	highlighted = TRUE
	color = null
	update_appearance(UPDATE_ICON)

/atom/movable/screen/lobby/button/MouseExited()
	if(usr != hud?.mymob)
		return
	. = ..()
	highlighted = FALSE
	color = dimmed ? LOBBY_DIMMED_COLOR : null
	update_appearance(UPDATE_ICON)

/atom/movable/screen/lobby/button/update_icon_state()
	if(!enabled)
		icon_state = "[base_icon_state]_disabled"
		return ..()
	if(highlighted)
		icon_state = "[base_icon_state]_highlighted"
		return ..()
	icon_state = base_icon_state
	return ..()

/atom/movable/screen/lobby/button/proc/set_button_status(status)
	if(status == enabled)
		return FALSE
	enabled = status
	update_appearance(UPDATE_ICON)
	mouse_over_pointer = enabled ? MOUSE_HAND_POINTER : MOUSE_INACTIVE_POINTER
	return TRUE

/atom/movable/screen/lobby/button/proc/set_dimmed(dimmed)
	src.dimmed = dimmed
	color = (dimmed && !highlighted) ? LOBBY_DIMMED_COLOR : null

/atom/movable/screen/lobby/button/character_setup
	name = "View Character Setup"
	screen_loc = "TOP:-70,CENTER:-54"
	icon = 'icons/hud/lobby/character_setup.dmi'
	icon_state = "character_setup_disabled"
	base_icon_state = "character_setup"
	enabled = FALSE

/atom/movable/screen/lobby/button/character_setup/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	if(SSatoms.initialized == INITIALIZATION_INNEW_REGULAR)
		flick("[base_icon_state]_enabled", src)
		set_button_status(TRUE)
	else
		set_button_status(FALSE)
		RegisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(enable_character_setup))

/atom/movable/screen/lobby/button/character_setup/Click(location, control, params)
	. = ..()
	if(!.)
		return
	hud.mymob.client.prefs.open_window(hud.mymob, PREFERENCE_TAB_CHARACTER_PREFERENCES)

/atom/movable/screen/lobby/button/character_setup/proc/enable_character_setup()
	SIGNAL_HANDLER
	flick("[base_icon_state]_enabled", src)
	set_button_status(TRUE)
	UnregisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE)

/atom/movable/screen/lobby/button/ready
	name = "Toggle Readiness"
	screen_loc = "TOP:-8,CENTER:-65"
	icon = 'icons/hud/lobby/ready.dmi'
	icon_state = "not_ready"
	base_icon_state = "not_ready"

/atom/movable/screen/lobby/button/ready/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	var/mob/new_player/new_player = hud.mymob
	base_icon_state = new_player.ready ? "ready" : "not_ready"
	update_appearance(UPDATE_ICON)
	RegisterSignal(SSticker, COMSIG_TICKER_GAME_STATE_CHANGED, PROC_REF(on_game_state_changed))
	on_game_state_changed(SSticker, SSticker.current_state)

/atom/movable/screen/lobby/button/ready/proc/on_game_state_changed(datum/source, new_state)
	SIGNAL_HANDLER
	set_button_status(new_state <= GAME_STATE_PREGAME)

/atom/movable/screen/lobby/button/ready/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/new_player/new_player = hud.mymob
	if(!new_player.toggle_ready())
		return
	base_icon_state = new_player.ready ? "ready" : "not_ready"
	update_appearance(UPDATE_ICON)
	SEND_SIGNAL(hud, COMSIG_HUD_PLAYER_READY_TOGGLE)

/atom/movable/screen/lobby/button/join
	name = "Join Game"
	screen_loc = "TOP:-13,CENTER:-58"
	icon = 'icons/hud/lobby/join.dmi'
	icon_state = ""
	base_icon_state = "join_game"
	enabled = null

/atom/movable/screen/lobby/button/join/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	RegisterSignal(SSticker, COMSIG_TICKER_GAME_STATE_CHANGED, PROC_REF(on_game_state_changed))
	on_game_state_changed(SSticker, SSticker.current_state)

/atom/movable/screen/lobby/button/join/proc/on_game_state_changed(datum/source, new_state)
	SIGNAL_HANDLER
	set_button_status(new_state > GAME_STATE_PREGAME)

/atom/movable/screen/lobby/button/join/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/new_player/new_player = hud.mymob
	new_player.try_late_join()

/atom/movable/screen/lobby/button/observe
	name = "Observe"
	screen_loc = "TOP:-40,CENTER:-54"
	icon = 'icons/hud/lobby/observe.dmi'
	icon_state = "observe_disabled"
	base_icon_state = "observe"
	enabled = null

/atom/movable/screen/lobby/button/observe/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	if(SSticker.current_state > GAME_STATE_STARTUP)
		set_button_status(TRUE)
		return
	set_button_status(FALSE)
	RegisterSignal(SSticker, COMSIG_TICKER_GAME_STATE_CHANGED, PROC_REF(on_game_state_changed))

/atom/movable/screen/lobby/button/observe/proc/on_game_state_changed(datum/source, new_state)
	SIGNAL_HANDLER
	if(new_state == GAME_STATE_STARTUP)
		return
	flick("[base_icon_state]_enabled", src)
	set_button_status(TRUE)
	UnregisterSignal(SSticker, COMSIG_TICKER_GAME_STATE_CHANGED)

/atom/movable/screen/lobby/button/observe/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/new_player/new_player = hud.mymob
	new_player.make_me_an_observer()

/atom/movable/screen/lobby/button/bottom
	abstract_type = /atom/movable/screen/lobby/button/bottom
	layer = LOBBY_BOTTOM_BUTTON_LAYER
	icon = 'icons/hud/lobby/bottom_buttons.dmi'
	maptext_width = 128
	maptext_height = 20
	maptext_x = -52
	maptext_y = -20

/atom/movable/screen/lobby/button/bottom/MouseEntered(location, control, params)
	. = ..()
	update_hint()

/atom/movable/screen/lobby/button/bottom/MouseExited()
	. = ..()
	update_hint()

/atom/movable/screen/lobby/button/bottom/proc/update_hint()
	layer = highlighted ? LOBBY_HINT_LAYER : initial(layer)
	maptext = (highlighted && desc) ? MAPTEXT("<span style='text-align: center'>[desc]</span>") : null

/atom/movable/screen/lobby/button/bottom/link
	abstract_type = /atom/movable/screen/lobby/button/bottom/link
	lobby_group = LOBBY_GROUP_LINKS
	var/edge_distance = LINK_HINT_MAX_WIDTH
	var/hint_room = LINK_HINT_MAX_WIDTH
	var/hint_left_room = LINK_HINT_MAX_WIDTH
	var/hint_fitted = FALSE

/atom/movable/screen/lobby/button/bottom/link/apply_layout_shift(shift_x, shift_y, anchor)
	. = ..()
	hint_room = edge_distance - shift_x
	hint_left_room = view_to_pixels(hud.mymob.client.view)[1] - hint_room
	hint_fitted = FALSE

/atom/movable/screen/lobby/button/bottom/link/update_hint()
	if(highlighted && !hint_fitted)
		fit_hint()
	return ..()

/atom/movable/screen/lobby/button/bottom/link/proc/fit_hint()
	var/measurement = hud?.mymob?.client?.MeasureText(MAPTEXT(desc))
	var/text_width = measurement ? text2num(copytext(measurement, 1, findtextEx(measurement, "x"))) : 0
	if(QDELETED(src))
		return
	hint_fitted = TRUE
	maptext_width = text_width > 0 ? min(text_width + LINK_HINT_WIDTH_PADDING, LINK_HINT_MAX_WIDTH) : LINK_HINT_MAX_WIDTH
	maptext_x = clamp(round((LOBBY_BOTTOM_BUTTON_SIZE - maptext_width) / 2), -hint_left_room, hint_room - maptext_width)

/atom/movable/screen/lobby/button/bottom/character
	abstract_type = /atom/movable/screen/lobby/button/bottom/character

/atom/movable/screen/lobby/button/bottom/poll
	name = "View Available Polls"
	desc = "Голосования"
	icon_state = "poll"
	base_icon_state = "poll"
	screen_loc = "TOP:-122,CENTER:-26"
	var/new_poll = FALSE

/atom/movable/screen/lobby/button/bottom/poll/SlowInit()
	. = ..()
	var/mob/new_player/new_player = hud.mymob
	if(is_guest_key(new_player.key) || !SSdbcore.Connect())
		set_button_status(FALSE)
		return
	var/datum/db_query/query_get_new_polls = SSdbcore.NewQuery({"
		SELECT id FROM [format_table_name("poll_question")]
		WHERE (adminonly = 0 OR :isadmin = 1)
		AND Now() BETWEEN starttime AND endtime
		AND deleted = 0
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_vote")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_textreply")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
	"}, list("isadmin" = !!new_player.client?.holder, "ckey" = new_player.get_account_ckey()))
	if(!query_get_new_polls.Execute())
		qdel(query_get_new_polls)
		set_button_status(FALSE)
		return
	new_poll = query_get_new_polls.NextRow()
	qdel(query_get_new_polls)
	if(QDELETED(src))
		return
	update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/lobby/button/bottom/poll/update_overlays()
	. = ..()
	if(new_poll)
		. += mutable_appearance('icons/hud/lobby/poll_overlay.dmi', "new_poll")

/atom/movable/screen/lobby/button/bottom/poll/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/new_player/new_player = hud.mymob
	new_player.handle_player_polling()

/atom/movable/screen/lobby/button/bottom/crew_manifest
	name = "View Crew Manifest"
	desc = "Список экипажа"
	icon_state = "crew_manifest"
	base_icon_state = "crew_manifest"
	screen_loc = "TOP:-122,CENTER:+2"

/atom/movable/screen/lobby/button/bottom/crew_manifest/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/new_player/new_player = hud.mymob
	new_player.ViewManifest()

/atom/movable/screen/lobby/button/bottom/settings
	name = "View Game Preferences"
	desc = "Настройки игры"
	icon_state = "settings_disabled"
	base_icon_state = "settings"
	screen_loc = "TOP:-122,CENTER:+29"
	enabled = FALSE

/atom/movable/screen/lobby/button/bottom/settings/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	if(SSatoms.initialized == INITIALIZATION_INNEW_REGULAR)
		set_button_status(TRUE)
	else
		set_button_status(FALSE)
		RegisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(enable_settings))

/atom/movable/screen/lobby/button/bottom/settings/Click(location, control, params)
	. = ..()
	if(!.)
		return
	hud.mymob.client.prefs.open_window(hud.mymob, PREFERENCE_TAB_GAME_PREFERENCES)

/atom/movable/screen/lobby/button/bottom/settings/proc/enable_settings()
	SIGNAL_HANDLER
	set_button_status(TRUE)
	UnregisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE)

/atom/movable/screen/lobby/button/bottom/link/changelog
	name = "View Changelog"
	desc = "Список изменений"
	icon_state = "changelog"
	base_icon_state = "changelog"

/atom/movable/screen/lobby/button/bottom/link/changelog/Click(location, control, params)
	. = ..()
	if(!.)
		return
	hud.mymob.client?.changelog()

/atom/movable/screen/lobby/button/bottom/character/job_preferences
	name = "View Job Preferences"
	desc = "Выбор профессии"
	screen_loc = "TOP:-85,CENTER:-88"
	icon_state = "job_preferences"
	base_icon_state = "job_preferences"

/atom/movable/screen/lobby/button/bottom/character/job_preferences/Click(location, control, params)
	. = ..()
	if(!.)
		return
	hud.mymob.client.prefs.open_window(hud.mymob, PREFERENCE_TAB_CHARACTER_PREFERENCES, PREFERENCE_PAGE_JOBS)

/atom/movable/screen/lobby/button/bottom/volume
	name = "View Volume Mixer"
	desc = "Настройки громкости"
	icon_state = "volume"
	base_icon_state = "volume"
	screen_loc = "TOP:-122,CENTER:+57"

/atom/movable/screen/lobby/button/bottom/volume/Click(location, control, params)
	. = ..()
	if(!.)
		return
	hud.mymob.client?.volume_mixer()

/atom/movable/screen/lobby/button/bottom/character/antag
	name = "Toggle Antagonist Roles"
	screen_loc = "TOP:-85,CENTER:+93"
	icon_state = "antag_on"
	base_icon_state = "antag_on"

/atom/movable/screen/lobby/button/bottom/character/antag/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_toggle_state()

/atom/movable/screen/lobby/button/bottom/character/antag/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/datum/preferences/preferences = hud.mymob.client.prefs
	preferences.skip_antag = !preferences.skip_antag
	update_toggle_state()

/atom/movable/screen/lobby/button/bottom/character/antag/proc/update_toggle_state()
	var/skip_antag = hud.mymob.client?.prefs.skip_antag
	base_icon_state = skip_antag ? "antag_off" : "antag_on"
	desc = skip_antag ? "Антагонисты: выкл." : "Антагонисты: вкл."
	update_appearance(UPDATE_ICON)
	update_hint()

/atom/movable/screen/lobby/button/bottom/link/wiki
	name = "Open Wiki"
	desc = "Вики проекта"
	icon_state = "wiki"
	base_icon_state = "wiki"

/atom/movable/screen/lobby/button/bottom/link/wiki/is_available(client/viewer)
	return !!CONFIG_GET(string/wikiurl)

/atom/movable/screen/lobby/button/bottom/link/wiki/Click(location, control, params)
	. = ..()
	if(!.)
		return
	if(tgui_alert(usr, "Открыть вики проекта?", "Вики", list("Да", "Нет")) != "Да")
		return
	usr.client << link(CONFIG_GET(string/wikiurl))

/atom/movable/screen/lobby/button/bottom/link/discord
	name = "Open Discord"
	desc = "Discord-сервер"
	icon_state = "discord"
	base_icon_state = "discord"

/atom/movable/screen/lobby/button/bottom/link/discord/is_available(client/viewer)
	return !!CONFIG_GET(string/discordurl)

/atom/movable/screen/lobby/button/bottom/link/discord/Click(location, control, params)
	. = ..()
	if(!.)
		return
	if(tgui_alert(usr, "Перейти на Discord-сервер?", "Discord", list("Да", "Нет")) != "Да")
		return
	usr.client << link(CONFIG_GET(string/discordurl))

/atom/movable/screen/lobby/button/bottom/link/discord_link
	name = "Link Discord Account"
	desc = "Привязка Discord"
	icon_state = "discord_link"
	base_icon_state = "discord_link"
	var/spotlit = FALSE

/atom/movable/screen/lobby/button/bottom/link/discord_link/is_available(client/viewer)
	if(is_guest_key(viewer.key) && !viewer.is_launcher_client())
		return FALSE
	var/discord_id = viewer.prefs?.discord_id
	return !discord_id || length(discord_id) == DISCORD_TOKEN_LENGTH

/atom/movable/screen/lobby/button/bottom/link/discord_link/Click(location, control, params)
	. = ..()
	if(!.)
		return
	if(spotlit)
		stop_spotlight()
	hud.mymob.client?.link_discord_account()

/atom/movable/screen/lobby/button/bottom/link/discord_link/proc/start_spotlight()
	spotlit = TRUE
	add_filter(DISCORD_SPOTLIGHT_GLOW, 1, drop_shadow_filter(size = 2, offset = 0, color = DISCORD_SPOTLIGHT_GLOW_COLOR))
	add_filter(DISCORD_SPOTLIGHT_OUTLINE, 2, outline_filter(size = 1, color = COLOR_GOLD))
	animate(get_filter(DISCORD_SPOTLIGHT_GLOW), size = 5, time = DISCORD_SPOTLIGHT_PULSE_DURATION, easing = SINE_EASING, loop = -1)
	animate(size = 2, time = DISCORD_SPOTLIGHT_PULSE_DURATION, easing = SINE_EASING)
	for(var/atom/movable/screen/lobby/button/button in hud.static_inventory)
		if(button != src)
			button.set_dimmed(TRUE)

/atom/movable/screen/lobby/button/bottom/link/discord_link/proc/stop_spotlight()
	spotlit = FALSE
	remove_filter(list(DISCORD_SPOTLIGHT_GLOW, DISCORD_SPOTLIGHT_OUTLINE))
	for(var/atom/movable/screen/lobby/button/button in hud.static_inventory)
		button.set_dimmed(FALSE)

/atom/movable/screen/lobby/button/bottom/link/referrals
	name = "View Referral System"
	desc = "Реферальная система"
	icon_state = "referrals"
	base_icon_state = "referrals"

/atom/movable/screen/lobby/button/bottom/link/referrals/Click(location, control, params)
	. = ..()
	if(!.)
		return
	hud.mymob.client?.referral_panel()

/atom/movable/screen/lobby/button/bottom/link/privacy_policy
	name = "View Privacy Policy"
	desc = "Политика конфиденциальности"
	icon_state = "privacy_policy"
	base_icon_state = "privacy_policy"

/atom/movable/screen/lobby/button/bottom/link/privacy_policy/is_available(client/viewer)
	return GLOB.join_tos && !viewer.tos_consent

/atom/movable/screen/lobby/button/bottom/link/privacy_policy/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/new_player/new_player = hud.mymob
	new_player.privacy_consent()

/atom/movable/screen/lobby/button/bottom/link/change_picture
	name = "Change Title Screen"
	desc = "Изменить изображение лобби"
	icon_state = "change_picture"
	base_icon_state = "change_picture"

/atom/movable/screen/lobby/button/bottom/link/change_picture/is_available(client/viewer)
	return check_rights_for(viewer, R_EVENT)

/atom/movable/screen/lobby/button/bottom/link/change_picture/Click(location, control, params)
	. = ..()
	if(!.)
		return
	SSadmin_verbs.dynamic_invoke_verb(usr.client, /datum/admin_verb/admin_change_title_screen)

/atom/movable/screen/lobby/button/bottom/link/leave_notice
	name = "Set Title Screen Notice"
	desc = "Оставить уведомление в лобби"
	icon_state = "leave_notice"
	base_icon_state = "leave_notice"

/atom/movable/screen/lobby/button/bottom/link/leave_notice/is_available(client/viewer)
	return check_rights_for(viewer, R_EVENT)

/atom/movable/screen/lobby/button/bottom/link/leave_notice/Click(location, control, params)
	. = ..()
	if(!.)
		return
	SSadmin_verbs.dynamic_invoke_verb(usr.client, /datum/admin_verb/change_title_screen_notice)

/atom/movable/screen/lobby/button/collapse
	name = "Collapse Lobby Menu"
	icon = 'icons/hud/lobby/collapse_expand.dmi'
	icon_state = "collapse"
	base_icon_state = "collapse"
	layer = LOBBY_BELOW_MENU_LAYER
	screen_loc = "TOP:-82,CENTER:-54"
	always_shown = TRUE
	collapse_distance = LOBBY_HANDLE_COLLAPSE_DISTANCE
	var/blip_enabled = TRUE

/atom/movable/screen/lobby/button/collapse/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	RegisterSignal(SSticker, COMSIG_TICKER_GAME_STATE_CHANGED, PROC_REF(on_game_state_changed))
	RegisterSignal(hud, COMSIG_HUD_PLAYER_READY_TOGGLE, PROC_REF(on_player_ready_toggle))
	blip_enabled = SSticker.current_state <= GAME_STATE_PREGAME
	update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/lobby/button/collapse/update_overlays()
	. = ..()
	var/blip_icon_state = "ready_blip"
	if(blip_enabled && hud)
		var/mob/new_player/new_player = hud.mymob
		blip_icon_state += "_[new_player.ready ? "" : "not_"]ready"
	else
		blip_icon_state += "_disabled"
	. += mutable_appearance(icon, blip_icon_state)

/atom/movable/screen/lobby/button/collapse/Click(location, control, params)
	. = ..()
	if(!.)
		return
	toggle_menu()

/atom/movable/screen/lobby/button/collapse/proc/toggle_menu()
	var/datum/hud/new_player/our_hud = hud
	base_icon_state = our_hud.menu_hud_status ? "expand" : "collapse"
	name = "[our_hud.menu_hud_status ? "Expand" : "Collapse"] Lobby Menu"
	set_button_status(FALSE)

	var/atom/movable/screen/lobby/shutter/menu_shutter = locate() in hud.static_inventory
	menu_shutter.setup_shutter_animation()
	if(our_hud.menu_hud_status)
		collapse_menu()
	else
		expand_menu()
	our_hud.menu_hud_status = !our_hud.menu_hud_status

	sleep(2 * SHUTTER_MOVEMENT_DURATION + SHUTTER_WAIT_DURATION)
	set_button_status(TRUE)

/atom/movable/screen/lobby/button/collapse/proc/on_player_ready_toggle()
	SIGNAL_HANDLER
	update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/lobby/button/collapse/proc/on_game_state_changed(datum/source, new_state)
	SIGNAL_HANDLER
	blip_enabled = new_state <= GAME_STATE_PREGAME
	update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/lobby/button/collapse/proc/collapse_menu()
	SEND_SIGNAL(hud, COMSIG_HUD_LOBBY_COLLAPSED)
	var/datum/hud/new_player/lobby_hud = hud
	var/list/shift = lobby_hud.get_collapse_shift(src)
	animate(src, transform = transform, time = SHUTTER_MOVEMENT_DURATION + SHUTTER_WAIT_DURATION)
	animate(transform = transform.Translate(x = shift[1], y = shift[2]), time = SHUTTER_MOVEMENT_DURATION, easing = CUBIC_EASING|EASE_IN)
	SEND_SOUND(hud.mymob, sound('sound/misc/menu/menu_rollup1.ogg'))

/atom/movable/screen/lobby/button/collapse/proc/expand_menu()
	SEND_SIGNAL(hud, COMSIG_HUD_LOBBY_EXPANDED)
	animate(src, transform = matrix(), time = SHUTTER_MOVEMENT_DURATION, easing = CUBIC_EASING|EASE_OUT)
	SEND_SOUND(hud.mymob, sound('sound/misc/menu/menu_rolldown1.ogg'))

/atom/movable/screen/lobby/shutter
	icon = 'icons/hud/lobby/shutter.dmi'
	icon_state = "shutter"
	base_icon_state = "shutter"
	screen_loc = "TOP:+143,CENTER:-73"
	layer = LOBBY_SHUTTER_LAYER
	always_shown = TRUE
	collapse_distance = LOBBY_SHUTTER_DROP_DISTANCE

/atom/movable/screen/lobby/shutter/apply_layout_shift(shift_x, shift_y, anchor)
	screen_loc = shift_screen_loc(base_screen_loc, shift_x, 0)

/atom/movable/screen/lobby/shutter/proc/setup_shutter_animation()
	var/datum/hud/new_player/lobby_hud = hud
	var/list/shift = lobby_hud.get_collapse_shift(src)
	animate(src, transform = transform.Translate(x = 0, y = -shift[2]), time = SHUTTER_MOVEMENT_DURATION, easing = CUBIC_EASING|EASE_OUT)
	animate(transform = transform, time = SHUTTER_WAIT_DURATION)
	animate(transform = matrix(), time = SHUTTER_MOVEMENT_DURATION, easing = CUBIC_EASING|EASE_IN)

/atom/movable/screen/lobby/button/start_now
	name = "Start Now (LOCALHOST ONLY)"
	screen_loc = "TOP:-141,CENTER:-54"
	icon = 'icons/hud/lobby/start_now.dmi'
	icon_state = "start_now"
	base_icon_state = "start_now"
	always_available = FALSE
	select_sound_play = FALSE

/atom/movable/screen/lobby/button/start_now/Click(location, control, params)
	. = ..()
	if(!. || !usr.client.is_connecting_from_localhost() || !check_rights_for(usr.client, R_SERVER))
		return
	SEND_SOUND(hud.mymob, sound('sound/effects/cartoon_sfx/cartoon_splat.ogg', volume = 50))
	SSadmin_verbs.dynamic_invoke_verb(usr.client, /datum/admin_verb/start_now)

#define OVERLAY_X_DIFF 12
#define OVERLAY_Y_DIFF 5

/atom/movable/screen/lobby/new_player_info
	name = "New Player Info"
	screen_loc = "EAST-3,CENTER:140"
	icon = 'icons/hud/lobby/newplayer.dmi'
	icon_state = null
	base_icon_state = "newplayer"
	maptext_height = 75
	maptext_width = 80
	maptext_x = OVERLAY_X_DIFF
	maptext_y = OVERLAY_Y_DIFF
	lobby_group = LOBBY_GROUP_INFO
	var/show_static = TRUE

/atom/movable/screen/lobby/new_player_info/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	SSnew_player_info.info_screens += src
	update_text()
	update_appearance(UPDATE_ICON)

/atom/movable/screen/lobby/new_player_info/Destroy()
	SSnew_player_info.info_screens -= src
	return ..()

/atom/movable/screen/lobby/new_player_info/update_icon_state()
	icon_state = base_icon_state
	return ..()

/atom/movable/screen/lobby/new_player_info/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "[base_icon_state]_overlay", layer = layer + 0.01)
	if(!show_static)
		return
	. += mutable_appearance(icon, "static_base", alpha = 20, layer = layer + 0.03)
	var/mutable_appearance/scanline = mutable_appearance(generate_icon_alpha_mask('icons/hud/lobby/newplayer_scanline.dmi', "scanline"), alpha = 20, layer = layer + 0.04)
	scanline.pixel_y = OVERLAY_X_DIFF
	scanline.pixel_x = OVERLAY_Y_DIFF
	. += scanline

/atom/movable/screen/lobby/new_player_info/collapse_button()
	show_static = FALSE
	update_text()
	update_appearance(UPDATE_ICON)
	return ..()

/atom/movable/screen/lobby/new_player_info/expand_button()
	. = ..()
	show_static = TRUE
	update_appearance(UPDATE_ICON)
	update_text()

/atom/movable/screen/lobby/new_player_info/proc/update_text()
	if(!hud || !show_static || !SSnew_player_info.initialized)
		maptext = null
		return
	maptext = MAPTEXT("<span style='text-align: center; vertical-align: middle'>[SSnew_player_info.get_info_text(!!hud.mymob.client?.holder)]</span>")

#undef OVERLAY_X_DIFF
#undef OVERLAY_Y_DIFF

/atom/movable/screen/lobby/caption
	abstract_type = /atom/movable/screen/lobby/caption
	screen_loc = "SOUTH,WEST"
	always_shown = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	maptext_x = LOBBY_CAPTION_MARGIN
	var/bottom_row = 0
	var/text_align = "center"

/atom/movable/screen/lobby/caption/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	var/client/owner = hud.mymob.client
	RegisterSignal(owner, COMSIG_VIEW_SET, PROC_REF(fit_to_view))
	fit_to_view(owner, owner.view)

/atom/movable/screen/lobby/caption/proc/fit_to_view(datum/source, new_size)
	SIGNAL_HANDLER
	maptext_width = view_to_pixels(new_size)[1] - 2 * maptext_x

/atom/movable/screen/lobby/caption/apply_layout_shift(shift_x, shift_y, anchor)
	. = ..()
	text_align = (anchor & WEST) ? "left" : ((anchor & EAST) ? "right" : "center")
	update_text()

/atom/movable/screen/lobby/caption/proc/update_text()
	SIGNAL_HANDLER
	return

/atom/movable/screen/lobby/caption/notice
	name = "Lobby Notice"
	screen_loc = "SOUTH+2,WEST"
	maptext_height = 64
	lobby_group = LOBBY_GROUP_NOTICE
	bottom_row = 2

/atom/movable/screen/lobby/caption/notice/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	RegisterSignal(SStitle, COMSIG_TITLE_NOTICE_CHANGED, PROC_REF(update_text))
	update_text()

/atom/movable/screen/lobby/caption/notice/update_text()
	maptext = SStitle.notice ? MAPTEXT_PIXELLARI("<span style='text-align: [text_align]; color: #ff4040'>[SStitle.notice]</span>") : null

/atom/movable/screen/lobby/caption/phrase
	name = "Lobby Phrase"
	maptext_height = 24
	lobby_group = LOBBY_GROUP_PHRASE

/atom/movable/screen/lobby/caption/phrase/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	RegisterSignal(SStitle, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(update_text))
	update_text()

/atom/movable/screen/lobby/caption/phrase/update_text()
	maptext = SStitle.initialized ? MAPTEXT_PIXELLARI("<span style='text-align: [text_align]'>[SStitle.random_phrase]</span>") : null

/atom/movable/screen/lobby/layout_label
	screen_loc = "1,1"
	layer = LOBBY_LAYOUT_FRAME_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	always_available = FALSE
	lobby_group = null
	var/text_style = "text-align: right"

/atom/movable/screen/lobby/layout_label/proc/set_text(text)
	maptext = MAPTEXT("<span style='[text_style]'>[text]</span>")

/atom/movable/screen/lobby/layout_rect
	abstract_type = /atom/movable/screen/lobby/layout_rect
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	screen_loc = "1,1"
	layer = LOBBY_LAYOUT_FRAME_LAYER
	mouse_over_pointer = MOUSE_HAND_POINTER
	always_available = FALSE
	lobby_group = null
	var/label_text
	var/label_style = "text-align: right"
	var/datum/lobby_layout_editor/editor
	var/atom/movable/screen/lobby/layout_label/label

/atom/movable/screen/lobby/layout_rect/Initialize(mapload, datum/hud/hud_owner, datum/lobby_layout_editor/editor)
	. = ..()
	src.editor = editor
	label = new(null, hud_owner)
	label.layer = layer
	label.text_style = label_style
	if(label_text)
		label.set_text(label_text)

/atom/movable/screen/lobby/layout_rect/Destroy()
	editor = null
	label = null
	return ..()

/atom/movable/screen/lobby/layout_rect/proc/set_box(list/box)
	screen_loc = shift_screen_loc(base_screen_loc, box[1], box[2])
	transform = matrix(box[3] / ICON_SIZE_X, 0, (box[3] - ICON_SIZE_X) / 2, 0, box[4] / ICON_SIZE_Y, (box[4] - ICON_SIZE_Y) / 2)
	label.screen_loc = shift_screen_loc(label.base_screen_loc, box[1] + LAYOUT_LABEL_PADDING, box[2])
	label.maptext_width = box[3] - 2 * LAYOUT_LABEL_PADDING
	label.maptext_height = box[4] - LAYOUT_LABEL_PADDING

/atom/movable/screen/lobby/layout_rect/frame
	name = "Lobby Block"
	color = LAYOUT_FRAME_COLOR
	alpha = LAYOUT_FRAME_ALPHA
	mouse_over_pointer = MOUSE_DRAG_POINTER
	var/group

/atom/movable/screen/lobby/layout_rect/frame/proc/set_dragged(dragged)
	alpha = dragged ? LAYOUT_FRAME_DRAGGED_ALPHA : LAYOUT_FRAME_ALPHA

/atom/movable/screen/lobby/layout_rect/control
	abstract_type = /atom/movable/screen/lobby/layout_rect/control
	layer = LOBBY_LAYOUT_CONTROL_LAYER
	alpha = LAYOUT_CONTROL_ALPHA
	label_style = "text-align: center; vertical-align: middle"

/atom/movable/screen/lobby/layout_rect/control/Click(location, control, params)
	if(usr != hud?.mymob)
		return
	SEND_SOUND(usr, sound('sound/misc/menu/ui_select1.ogg'))
	activate()

/atom/movable/screen/lobby/layout_rect/control/proc/activate()
	return

/atom/movable/screen/lobby/layout_rect/control/done
	name = "Save Lobby Layout"
	label_text = "Готово"
	color = "#3f9e4d"

/atom/movable/screen/lobby/layout_rect/control/done/activate()
	var/datum/hud/new_player/lobby_hud = hud
	lobby_hud.stop_layout_editing(save = TRUE)

/atom/movable/screen/lobby/layout_rect/control/reset
	name = "Reset Lobby Layout"
	label_text = "Сбросить"
	color = "#b07a26"

/atom/movable/screen/lobby/layout_rect/control/reset/activate()
	editor.reset()

/atom/movable/screen/lobby/layout_rect/control/cancel
	name = "Cancel Lobby Layout"
	label_text = "Отмена"
	color = "#a83b3b"

/atom/movable/screen/lobby/layout_rect/control/cancel/activate()
	var/datum/hud/new_player/lobby_hud = hud
	lobby_hud.stop_layout_editing(save = FALSE)

#undef SHUTTER_MOVEMENT_DURATION
#undef SHUTTER_WAIT_DURATION
#undef LOBBY_COLLAPSE_DISTANCE
#undef LOBBY_HANDLE_COLLAPSE_DISTANCE
#undef LOBBY_SHUTTER_DROP_DISTANCE
#undef LOBBY_BOTTOM_BUTTON_SIZE
#undef LINK_HINT_MAX_WIDTH
#undef LINK_HINT_WIDTH_PADDING
#undef LOBBY_DIMMED_COLOR
#undef DISCORD_SPOTLIGHT_OUTLINE
#undef DISCORD_SPOTLIGHT_GLOW
#undef DISCORD_SPOTLIGHT_GLOW_COLOR
#undef DISCORD_SPOTLIGHT_PULSE_DURATION
#undef LOBBY_CAPTION_MARGIN
#undef LAYOUT_LABEL_PADDING
#undef LAYOUT_FRAME_COLOR
#undef LAYOUT_FRAME_ALPHA
#undef LAYOUT_FRAME_DRAGGED_ALPHA
#undef LAYOUT_CONTROL_ALPHA
