SUBSYSTEM_DEF(voicechat)
	name = "Voice Chat"
	wait = VOICECHAT_UPDATE_INTERVAL
	ss_flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/is_enabled = FALSE
	var/is_node_shutting_down = FALSE
	var/node_shutdown_requested = FALSE
	var/node_process_id

	// User codes associated with fully confirmed browser sessions.
	var/list/voice_clients
	var/list/user_code_client_uid
	var/list/client_uid_user_code

	// Current voice rooms. Change only through add_rooms() and remove_rooms().
	var/list/current_rooms
	var/list/user_code_room
	var/list/user_code_mob
	var/list/user_code_speaking_icons
	var/list/round_start_rooms

	var/const/node_script_path = "voicechat/node/server/main.js"
	var/const/node_executable_win = "C:\\Program Files\\nodejs\\node.exe"
	var/socket_library_path
	var/const/socket_library_path_unix = "voicechat/pipes/unix/byondsocket"
	var/const/socket_library_path_win = "voicechat/pipes/windows/byondsocket/Release/byondsocket"

/datum/controller/subsystem/voicechat/Initialize()
	reset_state()

	if(world.system_type == MS_WINDOWS)
		socket_library_path = socket_library_path_win
	else
		socket_library_path = socket_library_path_unix

	if(!CONFIG_GET(flag/enable_voicechat))
		can_fire = FALSE
		return SS_INIT_NO_NEED

	if(!test_library())
		return SS_INIT_FAILURE

	can_fire = TRUE
	add_rooms(round_start_rooms)
	start_node()
	is_enabled = TRUE
	return SS_INIT_SUCCESS

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
	round_start_rooms = list(VOICECHAT_ROOM_LIVING, VOICECHAT_ROOM_GHOST)

/datum/controller/subsystem/voicechat/proc/is_available()
	return is_enabled && initialized && !node_shutdown_requested && !is_node_shutting_down

/datum/controller/subsystem/voicechat/proc/should_shutdown()
	return is_enabled || node_process_id || node_shutdown_requested || is_node_shutting_down

/datum/controller/subsystem/voicechat/proc/can_handle_topic(topic)
	return (is_enabled || node_shutdown_requested || node_process_id) && istext(topic) && copytext(topic, 1, 2) == "{"

/datum/controller/subsystem/voicechat/proc/start_node()
	var/byond_port = world.port
	var/node_port = CONFIG_GET(number/port_voicechat)
	if(!node_port)
		CRASH("bad port option specified in config {node_port: [node_port || "null"]}")

	var/command = "node [node_script_path] --node-port=[node_port] --byond-port=[byond_port] &"
	if(world.system_type == MS_WINDOWS)
		command = "powershell.exe -Command \"Start-Process -FilePath '[node_executable_win]' -ArgumentList '[node_script_path]','--node-port=[node_port]','--byond-port=[byond_port]' -WorkingDirectory '.' -WindowStyle Hidden -RedirectStandardOutput 'data/logs/voicechat_node.out.log' -RedirectStandardError 'data/logs/voicechat_node.err.log'\""

	var/exit_code = shell(command)
	if(exit_code != 0)
		CRASH("launching node failed {exit_code: [exit_code || "null"], cmd: [command || "null"]}")

	// Node reports its PID asynchronously through world/Topic, but the verb should be usable as soon as launch succeeds.
	is_enabled = TRUE

/datum/controller/subsystem/voicechat/Shutdown()
	if(should_shutdown())
		stop_node()
	is_enabled = FALSE
	initialized = FALSE
	. = ..()

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

	message_admins("node failed to shutdown, trying forcefully...")

	if(!node_process_id)
		message_admins("cant find pid to shutdown node. hard restart required to fix voicechat")
		return

	var/command = "kill [node_process_id]"
	if(world.system_type == MS_WINDOWS)
		command = "taskkill /F /PID [node_process_id]"

	var/exit_code = shell(command)
	if(exit_code != 0)
		message_admins("killing node failed {exit_code: [exit_code || "null"], cmd: [command || "null"]}")
	else
		message_admins("node shutdown")

/datum/controller/subsystem/voicechat/fire()
	send_locations()

/datum/controller/subsystem/voicechat/proc/on_node_start(pid)
	if(!pid || !isnum(pid))
		CRASH("invalid pid {pid: [pid || "null"]}")

	node_process_id = pid

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
	log_world("Voice chat confirmed for userCode: [user_code]")
	post_confirm(user_code)

// Sends active clients' positions to Node.
/datum/controller/subsystem/voicechat/proc/send_locations()
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
	if(speaker_overlay && old_mob)
		old_mob.cut_overlay(speaker_overlay)
	else if(speaker_overlay)
		var/client/client = get_client_by_user_code(user_code)
		client?.mob?.cut_overlay(speaker_overlay)

	user_code_speaking_icons.Remove(user_code)
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
