// Uncomment to show traffic.
// #define LOG_TRAFFIC

/datum/controller/subsystem/voicechat/proc/test_library()
	var/text = "hello world"
	var/output = call_ext(socket_library_path, "byond:Echo")(text)
	return output == text

/proc/voicechat_json_encode_sanitize(list/data)
	. = json_encode(data)
	// Remove characters that are not needed for the bridge protocol.
	var/static/regex/sanitize_regex = new/regex(@'[^\w"{}:,\s\[\]]', "g")
	. = sanitize_regex.Replace(., "")
	. = replacetext(., "\\", "\\\\")

/datum/controller/subsystem/voicechat/proc/send_json(list/data)
	var/json = voicechat_json_encode_sanitize(data)
	#ifdef LOG_TRAFFIC
	message_admins("BYOND: [json]")
	#endif
	call_ext(socket_library_path, "byond:SendJSON")(json)

/datum/controller/subsystem/voicechat/proc/handle_topic(topic, address)
	if(address != VOICECHAT_TOPIC_ADDRESS)
		return

	var/list/data = safe_json_decode(topic)
	if(!islist(data))
		message_admins("Voice chat received malformed JSON from Node.")
		return
	if(data["error"])
		message_admins(topic)
		return

	#ifdef LOG_TRAFFIC
	message_admins("NODE: [topic]")
	#endif

	if(data[VOICECHAT_TOPIC_NODE_STARTED])
		on_node_start(data[VOICECHAT_TOPIC_NODE_STARTED])
		return

	if(data[VOICECHAT_TOPIC_PONG])
		world.log << "started: [data["time"]] round trip: [world.timeofday] approx: [world.timeofday - data["time"]] x 1/10 seconds, data: [data[VOICECHAT_TOPIC_PONG]]"
		return

	if(data[VOICECHAT_TOPIC_CONFIRMED])
		confirm_user_code(data[VOICECHAT_TOPIC_CONFIRMED])
		return

	if(data[VOICECHAT_TOPIC_VOICE_ACTIVITY])
		toggle_active(data[VOICECHAT_TOPIC_VOICE_ACTIVITY], data["active"])
		return

	if(data[VOICECHAT_TOPIC_DISCONNECT])
		disconnect(data[VOICECHAT_TOPIC_DISCONNECT])
		return

	if(data[VOICECHAT_TOPIC_SHUTTING_DOWN])
		is_node_shutting_down = TRUE
		is_enabled = FALSE
