SUBSYSTEM_DEF(voice_chat)
	name = "Voice Chat"
	wait = 1 SECONDS
	ss_flags = SS_KEEP_TIMING | SS_BACKGROUND
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/list/datum/voice_chat_client/sessions = list()
	var/request_pending = FALSE
	var/empty_snapshot_pending = FALSE
	var/request_was_empty = FALSE
	var/last_error = ""
	var/successful_requests = 0
	var/failed_requests = 0

/datum/controller/subsystem/voice_chat/Initialize()
	if(!CONFIG_GET(flag/voice_chat_enabled))
		can_fire = FALSE
		return SS_INIT_NO_NEED

	if(!CONFIG_GET(string/voice_chat_relay_url) || !CONFIG_GET(string/voice_chat_public_url) || !CONFIG_GET(string/voice_chat_api_key))
		log_startup_progress("Voice chat is enabled but relay configuration is incomplete.")
		can_fire = FALSE
		return SS_INIT_FAILURE

	return SS_INIT_SUCCESS

/datum/controller/subsystem/voice_chat/get_stat_details()
	return "S:[length(sessions)] | P:[request_pending ? "Y" : "N"] | OK:[successful_requests] | F:[failed_requests]"

/datum/controller/subsystem/voice_chat/fire()
	synchronize()

/datum/controller/subsystem/voice_chat/proc/register_session(datum/voice_chat_client/session)
	if(!session || !session.session_id)
		return
	sessions[session.session_id] = session
	empty_snapshot_pending = FALSE

/datum/controller/subsystem/voice_chat/proc/unregister_session(datum/voice_chat_client/session)
	if(!session?.session_id)
		return
	sessions -= session.session_id
	if(!length(sessions))
		empty_snapshot_pending = TRUE

/datum/controller/subsystem/voice_chat/proc/synchronize()
	if(request_pending || !can_fire || (!length(sessions) && !empty_snapshot_pending))
		return

	var/list/session_data = list()
	for(var/session_id in sessions)
		var/datum/voice_chat_client/session = sessions[session_id]
		if(QDELETED(session))
			sessions -= session_id
			continue
		session_data += list(session.build_snapshot())

	var/list/body = list(
		"protocol_version" = VOICE_CHAT_PROTOCOL_VERSION,
		"server_id" = CONFIG_GET(string/instance_id),
		"proximity_range" = CONFIG_GET(number/voice_chat_proximity_range),
		"sessions" = session_data,
	)
	var/list/headers = list(
		"Content-Type" = "application/json",
		"X-Voice-Key" = CONFIG_GET(string/voice_chat_api_key),
	)
	request_pending = TRUE
	request_was_empty = !length(session_data)
	SShttp.create_async_request(
		RUSTG_HTTP_METHOD_POST,
		"[CONFIG_GET(string/voice_chat_relay_url)]/v1/game/snapshot",
		json_encode(body),
		headers,
		CALLBACK(src, PROC_REF(on_snapshot_response)),
	)

/datum/controller/subsystem/voice_chat/proc/on_snapshot_response(datum/http_response/response)
	request_pending = FALSE
	if(response.errored)
		mark_relay_unavailable(response.error)
		return

	if(response.status_code != 200)
		mark_relay_unavailable("HTTP [response.status_code]")
		return

	var/list/data
	try
		data = json_decode(response.body)
	catch
		mark_relay_unavailable("Invalid JSON response")
		return

	if(!islist(data) || data["protocol_version"] != VOICE_CHAT_PROTOCOL_VERSION || !islist(data["sessions"]))
		mark_relay_unavailable("Protocol mismatch")
		return

	last_error = ""
	successful_requests++
	if(request_was_empty)
		empty_snapshot_pending = FALSE
	for(var/list/session_data in data["sessions"])
		var/session_id = session_data["session_id"]
		var/datum/voice_chat_client/session = sessions[session_id]
		if(QDELETED(session))
			continue
		session.apply_relay_state(session_data)

/datum/controller/subsystem/voice_chat/proc/mark_relay_unavailable(error)
	last_error = copytext_char("[error]", 1, VOICE_CHAT_MAX_ERROR_LENGTH + 1)
	failed_requests++
	for(var/session_id in sessions)
		var/datum/voice_chat_client/session = sessions[session_id]
		if(!QDELETED(session))
			session.set_relay_unavailable(last_error)
