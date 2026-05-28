// Uncomment to log all BYOND↔Node traffic to message_admins.
// #define LOG_TRAFFIC

/datum/controller/subsystem/voicechat/proc/send_json(list/data)
	if(!bridge_url || !auth_token)
		return

	var/json = json_encode(data)
	#ifdef LOG_TRAFFIC
	message_admins("BYOND→NODE: [json]")
	#endif

	var/list/headers = list(
		"Content-Type" = "application/json",
		"X-Byond-Auth" = auth_token,
	)
	// Fire-and-forget — the bridge POST is local and idempotent, and we don't want
	// to block the voicechat SS tick on a network response.
	rustg_http_request_async(RUSTG_HTTP_METHOD_POST, bridge_url, json, json_encode(headers), null)

/datum/controller/subsystem/voicechat/proc/handle_topic(topic, address)
	var/list/data = safe_json_decode(topic)
	if(!islist(data))
		log_world("Voice chat: received malformed JSON from Node: [topic]")
		message_admins("Voice chat: received malformed JSON from Node.")
		return
	if(data["error"])
		log_world("Voice chat error from Node: [topic]")
		message_admins("Voice chat error from Node: [topic]")
		return

	#ifdef LOG_TRAFFIC
	message_admins("NODE→BYOND: [topic]")
	#endif

	if(data[VOICECHAT_TOPIC_NODE_STARTED])
		on_node_start(data[VOICECHAT_TOPIC_NODE_STARTED])
		return

	if(data[VOICECHAT_TOPIC_PONG])
		log_world("Voice chat pong: time=[data["time"]] roundtrip=[world.timeofday - data["time"]] data=[data[VOICECHAT_TOPIC_PONG]]")
		return

	if(data[VOICECHAT_TOPIC_CONFIRMED])
		log_world("Voice chat: client confirmed userCode=[data[VOICECHAT_TOPIC_CONFIRMED]]")
		confirm_user_code(data[VOICECHAT_TOPIC_CONFIRMED])
		return

	if(data[VOICECHAT_TOPIC_VOICE_ACTIVITY])
		log_world("Voice chat: voice_activity userCode=[data[VOICECHAT_TOPIC_VOICE_ACTIVITY]] active=[data["active"]]")
		toggle_active(data[VOICECHAT_TOPIC_VOICE_ACTIVITY], data["active"])
		return

	if(data[VOICECHAT_TOPIC_DISCONNECT])
		log_world("Voice chat: disconnect from Node userCode=[data[VOICECHAT_TOPIC_DISCONNECT]]")
		disconnect(data[VOICECHAT_TOPIC_DISCONNECT])
		return

	if(data[VOICECHAT_TOPIC_SHUTTING_DOWN])
		log_world("Voice chat: Node reports shutting_down")
		is_node_shutting_down = TRUE
		is_enabled = FALSE
		return

	log_world("Voice chat: unhandled topic from Node: [topic]")
