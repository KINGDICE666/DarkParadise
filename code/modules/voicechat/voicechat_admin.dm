/// Admin diagnostics for the voice chat subsystem.
/// Shows internal state and pings Node.
ADMIN_VERB(voicechat_status, R_ADMIN, "Voicechat Status", "Inspect SSvoicechat state and ping Node.", ADMIN_CATEGORY_DEBUG)
	if(!SSvoicechat)
		to_chat(user, span_warning("SSvoicechat is null."))
		return

	var/list/lines = list()
	lines += "<b>=== Voice Chat status ===</b>"
	lines += "Initialized: [SSvoicechat.initialized ? "yes" : "no"]"
	lines += "Enabled: [SSvoicechat.is_enabled ? "yes" : "no"]"
	lines += "Available: [SSvoicechat.is_available() ? "yes" : "no"]"
	lines += "Node PID: [SSvoicechat.node_process_id || "unknown"]"
	lines += "Bridge URL: [SSvoicechat.bridge_url || "n/a"]"
	lines += "Shutdown requested: [SSvoicechat.node_shutdown_requested ? "yes" : "no"]"
	lines += "Node shutting down: [SSvoicechat.is_node_shutting_down ? "yes" : "no"]"
	lines += "Confirmed clients: [length(SSvoicechat.voice_clients)]"
	lines += "Pending registrations: [length(SSvoicechat.user_code_client_uid) - length(SSvoicechat.voice_clients)]"
	lines += "Active rooms: [length(SSvoicechat.current_rooms)]"

	for(var/room in SSvoicechat.current_rooms)
		var/list/members = SSvoicechat.current_rooms[room]
		lines += "&nbsp;&nbsp;[room]: [length(members)] member(s)"

	to_chat(user, lines.Join("<br>"))

	// Ping Node and observe the pong in world.log / message_admins.
	SSvoicechat.send_json(list(
		"cmd" = "ping",
		"message" = "diagnostic ping from [user.ckey]",
		"time" = world.timeofday,
	))
	to_chat(user, span_notice("Ping sent to Node. Watch world.log for the pong (or enable LOG_TRAFFIC in voicechat_routes.dm)."))

/// Renders the speaking overlay on the user's mob for 5 seconds — verifies the icon, layer and plane independently of Node.
ADMIN_VERB(voicechat_test_overlay, R_ADMIN, "Voicechat Test Overlay", "Flash the speaking icon on your mob for 5 seconds.", ADMIN_CATEGORY_DEBUG)
	if(!user.mob)
		return

	var/image/test_overlay = image('icons/mob/effects/talk.dmi', icon_state = "voice", layer = FLY_LAYER)
	SET_PLANE_EXPLICIT(test_overlay, ABOVE_GAME_PLANE, user.mob)
	test_overlay.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	test_overlay.alpha = VOICECHAT_SPEAKING_ICON_ALPHA
	user.mob.add_overlay(test_overlay)
	to_chat(user, span_notice("Voice chat test overlay applied for 5 seconds. If you can't see it, the icon/layer config is wrong."))
	addtimer(CALLBACK(user.mob, TYPE_PROC_REF(/atom, cut_overlay), test_overlay), 5 SECONDS)

/// Stops Node and tries to relaunch it without rebooting the server.
ADMIN_VERB(voicechat_restart_node, R_ADMIN, "Voicechat Restart Node", "Stop and relaunch the Node process.", ADMIN_CATEGORY_DEBUG)
	if(!SSvoicechat)
		to_chat(user, span_warning("SSvoicechat is null."))
		return

	if(SSvoicechat.should_shutdown())
		SSvoicechat.stop_node()
		to_chat(user, span_notice("Sent shutdown to Node. Waiting 3 seconds before relaunch."))

	addtimer(CALLBACK(SSvoicechat, TYPE_PROC_REF(/datum/controller/subsystem/voicechat, restart_after_shutdown)), 3 SECONDS)

/datum/controller/subsystem/voicechat/proc/restart_after_shutdown()
	reset_state()
	if(!CONFIG_GET(flag/enable_voicechat))
		message_admins("Voice chat: cannot restart — disabled in config.")
		return

	auth_token = md5("[world.realtime][rand()][world.time][world.port]")
	var/node_port = CONFIG_GET(number/port_voicechat)
	if(!node_port)
		message_admins("Voice chat: cannot restart — missing port config.")
		return
	bridge_url = "http://127.0.0.1:[node_port + 1]/byond/cmd"

	add_rooms(round_start_rooms)
	start_node()
	message_admins("Voice chat: relaunch attempted. See world.log for status.")
