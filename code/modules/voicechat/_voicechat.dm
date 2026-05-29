SUBSYSTEM_DEF(voicechat)
	name = "Voice Chat"
	wait = VOICECHAT_UPDATE_INTERVAL
	ss_flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/is_enabled = FALSE
	var/is_node_shutting_down = FALSE
	var/node_shutdown_requested = FALSE
	var/node_process_id

	// Path to the native byondsocket library (no extension — DM appends .dll/.so).
	// Set in Initialize() based on world.system_type.
	var/lib_path

	// User codes associated with fully confirmed browser sessions.
	var/list/voice_clients
	var/list/user_code_client_uid
	var/list/client_uid_user_code

	// Current voice rooms. Change only through add_rooms() and remove_rooms().
	var/list/current_rooms
	var/list/user_code_room
	var/list/user_code_mob
	var/list/user_code_speaking_icons
	// Tracks whether the speaking overlay is currently applied (prevents add_overlay stacking).
	var/list/user_code_overlay_active
	// world.time of the last voice_activity:true per user. fire() clears overlays
	// that haven't been refreshed within VOICECHAT_SPEAKING_TIMEOUT, so a dropped
	// "stopped speaking" topic can't leave a bubble stuck on forever.
	var/list/user_code_last_active
	var/list/round_start_rooms

	var/const/node_script_path = "voicechat/node/server/main.js"
	var/const/node_root_path = "voicechat/node"
	var/const/node_modules_path = "voicechat/node/node_modules"
	var/const/node_log_dir = "data/logs"
	var/const/lib_path_unix = "voicechat/pipes/unix/byondsocket"
	var/const/lib_path_win = "voicechat/pipes/windows/byondsocket/Release/byondsocket"

/datum/controller/subsystem/voicechat/Initialize()
	reset_state()

	if(!CONFIG_GET(flag/enable_voicechat))
		can_fire = FALSE
		return SS_INIT_NO_NEED

	var/node_port = CONFIG_GET(number/port_voicechat)
	if(!node_port)
		log_world("Voice chat: missing or invalid port_voicechat config; subsystem disabled.")
		return SS_INIT_FAILURE

	lib_path = (world.system_type == MS_WINDOWS) ? lib_path_win : lib_path_unix
	if(!test_library())
		log_world("Voice chat: native library at '[lib_path]' failed to load. Build voicechat/pipes/{windows,unix}/byondsocket and retry.")
		return SS_INIT_FAILURE

	// Whitelist 127.0.0.1 for the topic spam-prevention handler. Node still
	// reaches BYOND via TCP world.Topic (only BYOND -> Node moved to the named
	// pipe), so localhost can still pile up topics. The bridge is localhost-only
	// by design, so this is safe.
	var/list/whitelist = CONFIG_GET(str_list/topic_filtering_whitelist)
	// .Add() mutates the underlying list (which CONFIG_GET returns by reference);
	// `whitelist += ...` would just reassign the local var, leaving config untouched.
	if(islist(whitelist) && !("127.0.0.1" in whitelist))
		whitelist.Add("127.0.0.1")

	can_fire = TRUE
	add_rooms(round_start_rooms)
	start_node()
	return SS_INIT_SUCCESS

/// Calls the library's Echo(text) function and returns TRUE iff it round-trips.
/// Failure means the DLL/SO is missing, wrong arch, or BYOND version too old.
/datum/controller/subsystem/voicechat/proc/test_library()
	if(!lib_path)
		return FALSE
	var/const/probe = "voicechat-library-probe"
	var/result
	try
		result = call_ext(lib_path, "byond:Echo")(probe)
	catch(var/exception/e)
		log_world("Voice chat: call_ext to '[lib_path]' Echo threw: [e.name]")
		return FALSE
	return result == probe

/datum/controller/subsystem/voicechat/proc/reset_state()
	is_enabled = FALSE
	node_shutdown_requested = FALSE
	is_node_shutting_down = FALSE
	node_process_id = null

	voice_clients = list()
	user_code_client_uid = list()
	client_uid_user_code = list()
	current_rooms = list()
	user_code_room = list()
	user_code_mob = list()
	user_code_speaking_icons = list()
	user_code_overlay_active = list()
	user_code_last_active = list()
	round_start_rooms = list(VOICECHAT_ROOM_LIVING, VOICECHAT_ROOM_GHOST)

/datum/controller/subsystem/voicechat/proc/is_available()
	return is_enabled && initialized && !node_shutdown_requested && !is_node_shutting_down

/datum/controller/subsystem/voicechat/proc/should_shutdown()
	return is_enabled || node_process_id || node_shutdown_requested || is_node_shutting_down

/datum/controller/subsystem/voicechat/proc/can_handle_topic(topic)
	// A JSON-shaped topic is unambiguously ours — no other world topic source
	// produces `{` as the first character. Earlier we also gated on `is_enabled`,
	// but that caused topics to fall through to spam_prevention during the brief
	// window before start_node finishes (or after a transient reset), triggering
	// a cascading 1-minute lockout for localhost. JSON-shape gating is enough.
	if(!istext(topic) || !length(topic))
		return FALSE
	// Raw topic packets from Node keep the leading "?" query marker that BYOND
	// strips only for URL-style world.Export. So the string actually arrives as
	// `?{...}`. Skip a leading "?" before checking for the JSON `{`.
	var/start = (copytext(topic, 1, 2) == "?") ? 2 : 1
	return copytext(topic, start, start + 1) == "{"

/datum/controller/subsystem/voicechat/proc/start_node()
	var/byond_port = world.port
	// Node talks back to BYOND through world.Topic over TCP, which only exists
	// if the world is hosted on a real network port. When the .dmb is launched
	// in Dream Seeker (solo mode) world.port is 0, so Node would try to connect
	// to 127.0.0.1:0 and every reply (confirm, voice_activity, disconnect) fails
	// with EADDRNOTAVAIL — voice "half works" (browser sees the mic, but nothing
	// reaches the game). Refuse to start and tell the host how to fix it.
	if(!byond_port)
		log_world("Voice chat: world.port is 0 — the server must be hosted on a network port for the Node->BYOND bridge to work. Launch via DreamDaemon, e.g. 'dreamdaemon paradise.dmb 1984 -trusted', instead of running the .dmb directly in Dream Seeker. Voice chat disabled.")
		return
	var/node_port = CONFIG_GET(number/port_voicechat)

	// Ensure the log directory exists so the redirect doesn't silently fail.
	// mkdir is idempotent on both platforms — errors are intentionally ignored.
	if(world.system_type == MS_WINDOWS)
		shell("cmd /c if not exist \"[node_log_dir]\" mkdir \"[node_log_dir]\"")
	else
		shell("mkdir -p [node_log_dir]")

	// Auto-install Node dependencies if node_modules is missing (e.g. fresh clone,
	// branch switch with git clean, etc.). Without this, Node crashes with
	// "Cannot find module 'minimist'" and the voice chat site is unreachable.
	if(!fexists("[node_modules_path]/.package-lock.json"))
		log_world("Voice chat: node_modules missing, running npm install (this may take a while)...")
		var/npm_command
		if(world.system_type == MS_WINDOWS)
			npm_command = "powershell.exe -NoProfile -Command \"cd '[node_root_path]'; npm install\" >> [node_log_dir]/voicechat_node.out.log 2>> [node_log_dir]/voicechat_node.err.log"
		else
			npm_command = "cd [node_root_path] && npm install >> ../../[node_log_dir]/voicechat_node.out.log 2>> ../../[node_log_dir]/voicechat_node.err.log"
		var/npm_exit = shell(npm_command)
		if(npm_exit != 0)
			log_world("Voice chat: npm install failed (exit_code=[npm_exit || "null"]). Voice chat will not work until dependencies are installed manually.")
			return
		log_world("Voice chat: npm install completed.")

	var/node_args = "[node_script_path] --node-port=[node_port] --byond-port=[byond_port]"
	var/command = "node [node_args] >> [node_log_dir]/voicechat_node.out.log 2>> [node_log_dir]/voicechat_node.err.log &"
	if(world.system_type == MS_WINDOWS)
		// Resolve node.exe through PATH so non-default install locations work.
		command = "powershell.exe -NoProfile -Command \"Start-Process -FilePath 'node.exe' -ArgumentList '[node_script_path]','--node-port=[node_port]','--byond-port=[byond_port]' -WindowStyle Hidden -RedirectStandardOutput '[node_log_dir]/voicechat_node.out.log' -RedirectStandardError '[node_log_dir]/voicechat_node.err.log'\""

	var/exit_code = shell(command)
	if(exit_code != 0)
		log_world("Voice chat: launching Node failed (exit_code=[exit_code || "null"]).")
		return

	// Node reports its PID asynchronously through world/Topic, but the verb should be usable as soon as launch succeeds.
	is_enabled = TRUE
	log_world("Voice chat: Node process launch requested (port=[node_port], pipe=byond_node).")

/datum/controller/subsystem/voicechat/Shutdown()
	if(should_shutdown())
		stop_node()
	is_enabled = FALSE
	return ..()

/datum/controller/subsystem/voicechat/proc/stop_node()
	if(!should_shutdown())
		return
	if(node_shutdown_requested)
		return

	node_shutdown_requested = TRUE
	is_enabled = FALSE
	send_json(list("cmd" = VOICECHAT_CMD_STOP_NODE))
	addtimer(CALLBACK(src, PROC_REF(confirm_node_stopped)), 1 SECONDS)

/datum/controller/subsystem/voicechat/proc/confirm_node_stopped()
	if(is_node_shutting_down)
		node_process_id = null
		return

	message_admins("Voice chat: Node failed to shut down gracefully, trying forcefully...")

	if(!node_process_id)
		message_admins("Voice chat: no Node PID known; a hard restart is required to recover.")
		return

	var/command = "kill [node_process_id]"
	if(world.system_type == MS_WINDOWS)
		command = "taskkill /F /PID [node_process_id]"

	var/exit_code = shell(command)
	if(exit_code != 0)
		message_admins("Voice chat: killing Node failed (exit_code=[exit_code || "null"]).")
	else
		message_admins("Voice chat: Node forcefully stopped.")

/datum/controller/subsystem/voicechat/fire()
	send_locations()
	expire_stale_overlays()

// Clears speaking overlays whose voice_activity:true heartbeat stopped arriving.
// The Node->BYOND transport (one TCP world.Topic per message over loopback) can
// silently drop packets; without this, a lost "stopped speaking" message would
// leave a bubble stuck above a player's head until they disconnect.
/datum/controller/subsystem/voicechat/proc/expire_stale_overlays()
	if(!length(user_code_overlay_active))
		return

	for(var/user_code in user_code_overlay_active)
		if(!user_code_overlay_active[user_code])
			continue
		var/last = user_code_last_active[user_code]
		if(last && (world.time - last) <= VOICECHAT_SPEAKING_TIMEOUT)
			continue
		var/mob/mob = user_code_mob[user_code]
		var/image/speaker_overlay = user_code_speaking_icons[user_code]
		if(mob && speaker_overlay)
			mob.cut_overlay(speaker_overlay)
		user_code_overlay_active[user_code] = FALSE

// Cuts every currently-shown speaking overlay. Call before reset_state() on a
// restart/disable, otherwise the overlay images are orphaned (the tracking lists
// are replaced) and stay stuck above players until they move or relog.
/datum/controller/subsystem/voicechat/proc/clear_all_speaking_overlays()
	for(var/user_code in user_code_overlay_active)
		if(!user_code_overlay_active[user_code])
			continue
		var/mob/mob = user_code_mob[user_code]
		var/image/speaker_overlay = user_code_speaking_icons[user_code]
		if(mob && speaker_overlay)
			mob.cut_overlay(speaker_overlay)
		user_code_overlay_active[user_code] = FALSE

/datum/controller/subsystem/voicechat/proc/on_node_start(pid)
	if(!pid || !isnum(pid))
		log_world("Voice chat: received invalid pid from Node: [pid || "null"]")
		return

	node_process_id = pid
	log_world("Voice chat: Node confirmed start (pid=[pid]).")

/datum/controller/subsystem/voicechat/proc/add_rooms(rooms, zlevel_mode = FALSE)
	if(!islist(rooms))
		rooms = list(rooms)

	for(var/room in rooms)
		if(room in current_rooms)
			continue
		if(isnum(room) && !zlevel_mode)
			continue
		current_rooms[room] = list()

/datum/controller/subsystem/voicechat/proc/remove_rooms(rooms)
	if(!islist(rooms))
		rooms = list(rooms)

	for(var/room in rooms)
		if(!(room in current_rooms))
			continue
		for(var/user_code in current_rooms[room])
			user_code_room[user_code] = null
		current_rooms.Remove(room)

/datum/controller/subsystem/voicechat/proc/move_user_code_to_room(user_code, room)
	var/previous_room = user_code_room[user_code]
	if(previous_room && (previous_room in current_rooms))
		current_rooms[previous_room] -= user_code

	if(!room || !(room in current_rooms))
		user_code_room[user_code] = null
		return

	user_code_room[user_code] = room
	current_rooms[room] += user_code

/datum/controller/subsystem/voicechat/proc/get_client_by_user_code(user_code)
	var/client_uid = user_code_client_uid[user_code]
	if(!client_uid)
		return

	var/client/client = locateUID(client_uid)
	return client

// Confirms user_code when browser and microphone access are granted.
/datum/controller/subsystem/voicechat/proc/confirm_user_code(user_code)
	if(!user_code || (user_code in voice_clients))
		return

	if(!user_code_client_uid[user_code])
		return

	voice_clients |= user_code
	log_world("Voice chat: confirmed userCode [user_code].")
	post_confirm(user_code)

// Sends active clients' positions to Node.
/datum/controller/subsystem/voicechat/proc/send_locations()
	if(!length(voice_clients))
		return

	var/list/params = list("cmd" = VOICECHAT_CMD_LOCATION)
	var/locations_sent = 0

	for(var/user_code in voice_clients.Copy())
		var/client/client = get_client_by_user_code(user_code)
		if(!client)
			disconnect(user_code, from_byond = TRUE)
			continue

		var/mob/mob = client.mob
		if(!mob)
			continue

		room_update(mob)
		var/room = user_code_room[user_code]
		if(!room)
			continue

		var/turf/turf = get_turf(mob)
		if(!turf)
			continue

		var/local_room = "[turf.z]_[room]"
		if(!params[local_room])
			params[local_room] = list()
		params[local_room][user_code] = list(turf.x, turf.y)
		locations_sent++

	if(!locations_sent)
		return

	send_json(params)

// Disconnects a user from voice chat.
/datum/controller/subsystem/voicechat/proc/disconnect(user_code, from_byond = FALSE)
	if(!user_code)
		return

	var/room = user_code_room[user_code]
	if(room && (room in current_rooms))
		current_rooms[room] -= user_code

	var/client_uid = user_code_client_uid[user_code]
	var/image/speaker_overlay = user_code_speaking_icons[user_code]
	var/mob/old_mob = user_code_mob[user_code]
	if(speaker_overlay && old_mob && user_code_overlay_active[user_code])
		old_mob.cut_overlay(speaker_overlay)

	user_code_speaking_icons.Remove(user_code)
	user_code_overlay_active.Remove(user_code)
	user_code_last_active.Remove(user_code)
	user_code_mob.Remove(user_code)

	if(client_uid)
		user_code_client_uid.Remove(user_code)
		client_uid_user_code.Remove(client_uid)

	user_code_room.Remove(user_code)
	voice_clients -= user_code

	if(from_byond)
		send_json(list("cmd" = VOICECHAT_CMD_DISCONNECT, "userCode" = user_code))

/datum/controller/subsystem/voicechat/proc/generate_user_code(client/client)
	if(!client)
		return

	. = copytext(md5("[client.computer_id][client.address][rand()]"), -VOICECHAT_USER_CODE_LENGTH)
	while(. in user_code_client_uid)
		. = copytext(md5("[client.computer_id][client.address][rand()]"), -VOICECHAT_USER_CODE_LENGTH)

// Updates the voice chat room based on mob status.
// This needs to be moved to signals at some point.
/datum/controller/subsystem/voicechat/proc/room_update(mob/source)
	if(!source)
		return

	var/client/client = source.client
	if(!client)
		return

	var/user_code = client_uid_user_code[client.UID()]
	if(!user_code)
		return

	var/room
	switch(source.stat)
		if(CONSCIOUS)
			room = VOICECHAT_ROOM_LIVING
		if(UNCONSCIOUS)
			room = null
		if(DEAD)
			room = VOICECHAT_ROOM_GHOST

	if(user_code_room[user_code] != room)
		move_user_code_to_room(user_code, room)
