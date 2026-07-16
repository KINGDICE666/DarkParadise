/datum/voice_chat_client
	var/client/owner
	var/session_id
	var/status = VOICE_CHAT_STATUS_DISCONNECTED
	var/status_error = ""
	var/connect_token = ""
	var/helper_feature_version = 0
	var/helper_launch_url = ""
	var/helper_relay_url = ""
	var/helper_download_url = ""
	var/is_local_connection = FALSE
	var/wants_connection = FALSE
	var/muted = FALSE
	var/deafened = FALSE
	var/push_to_talk_pressed = FALSE
	var/transmission_mode = VOICE_CHAT_TRANSMISSION_PUSH_TO_TALK
	var/voice_activation_threshold = VOICE_CHAT_DEFAULT_ACTIVATION_THRESHOLD
	var/input_gain = VOICE_CHAT_DEFAULT_INPUT_GAIN
	var/output_volume = VOICE_CHAT_DEFAULT_OUTPUT_VOLUME
	var/input_device_id = ""
	var/output_device_id = ""
	var/list/input_devices = list()
	var/list/output_devices = list()
	var/list/peer_volumes = list()
	var/list/muted_peers = list()
	var/output_test_sequence = 0
	var/microphone_test_sequence = 0
	var/calibration_sequence = 0
	var/calibration_result_sequence = 0
	var/calibration_pending = FALSE
	var/calibrating = FALSE
	var/calibration_progress = 0
	var/recommended_threshold = 0
	var/noise_floor = 0
	var/audio_processing_active = FALSE
	var/audio_transport = ""
	var/speaking = FALSE
	var/image/speaking_overlay
	var/datum/weakref/speaking_mob
	var/speaking_overlay_visible = FALSE
	var/input_level = 0

/datum/voice_chat_client/New(client/new_owner)
	owner = new_owner
	session_id = md5("[world.realtime]-[world.time]-[rand(1, 1e9)]-[owner?.ckey]")
	is_local_connection = owner?.address == VOICE_CHAT_LOOPBACK_IPV4 || owner?.address == VOICE_CHAT_LOOPBACK_IPV6
	helper_relay_url = CONFIG_GET(string/voice_chat_public_url)
	helper_download_url = CONFIG_GET(string/voice_chat_helper_download_url)
	if(is_local_connection)
		helper_relay_url = CONFIG_GET(string/voice_chat_relay_url)
		helper_relay_url = replacetext_char(helper_relay_url, VOICE_CHAT_HTTP_PREFIX, VOICE_CHAT_WS_PREFIX)
		helper_relay_url = replacetext_char(helper_relay_url, VOICE_CHAT_HTTPS_PREFIX, VOICE_CHAT_WSS_PREFIX)
		helper_relay_url += VOICE_CHAT_CONNECT_PATH
		helper_download_url = "[CONFIG_GET(string/voice_chat_relay_url)][VOICE_CHAT_DOWNLOAD_PATH]"
	if(CONFIG_GET(flag/voice_chat_enabled) && SSvoice_chat?.can_fire)
		SSvoice_chat.register_session(src)
	else
		status = VOICE_CHAT_STATUS_DISABLED

/datum/voice_chat_client/Destroy()
	set_speaking(FALSE)
	SStgui.close_uis(src)
	SSvoice_chat?.unregister_session(src)
	if(owner?.voice_chat == src)
		owner.voice_chat = null
	owner = null
	input_devices = null
	output_devices = null
	peer_volumes = null
	muted_peers = null
	speaking_overlay = null
	speaking_mob = null
	return ..()

/datum/voice_chat_client/ui_state(mob/user)
	return GLOB.always_state

/datum/voice_chat_client/ui_status(mob/user, datum/ui_state/state)
	if(user?.client != owner)
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/voice_chat_client/ui_interact(mob/user, datum/tgui/ui = null)
	if(user?.client != owner)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VoiceChat", "Голосовой чат")
		ui.open()

/datum/voice_chat_client/ui_data(mob/user)
	var/list/data = list()
	data["enabled"] = CONFIG_GET(flag/voice_chat_enabled) && SSvoice_chat?.can_fire
	data["status"] = status
	data["error"] = status_error
	data["connected"] = status == VOICE_CHAT_STATUS_CONNECTED
	data["wants_connection"] = wants_connection
	data["helper_download_available"] = !!helper_download_url
	data["helper_launch_url"] = helper_launch_url
	data["helper_feature_version"] = helper_feature_version
	data["muted"] = muted
	data["deafened"] = deafened
	data["ptt_pressed"] = push_to_talk_pressed
	data["ptt_keys"] = get_push_to_talk_keys()
	data["transmission_mode"] = transmission_mode
	data["voice_activation_threshold"] = voice_activation_threshold
	data["input_gain"] = input_gain
	data["output_volume"] = output_volume
	data["input_level"] = input_level
	data["calibrating"] = calibrating
	data["calibration_progress"] = calibration_progress
	data["recommended_threshold"] = recommended_threshold
	data["noise_floor"] = noise_floor
	data["audio_processing_active"] = audio_processing_active
	data["audio_transport"] = audio_transport
	data["input_device_id"] = input_device_id
	data["output_device_id"] = output_device_id
	data["input_devices"] = input_devices
	data["output_devices"] = output_devices
	data["observer"] = isobserver(owner?.mob)
	data["can_speak"] = can_transmit_voice()
	data["can_listen"] = can_receive_voice()
	data["speaking"] = speaking
	data["nearby_players"] = get_nearby_players()
	return data

/datum/voice_chat_client/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(ui.user?.client != owner)
		return TRUE

	. = TRUE
	switch(action)
		if("download_helper")
			if(!helper_download_url)
				return FALSE
			owner << link(helper_download_url)
		if("connect")
			connect()
		if("disconnect")
			disconnect()
		if("toggle_mute")
			muted = !muted
			SSvoice_chat.synchronize()
		if("toggle_deafen")
			deafened = !deafened
			SSvoice_chat.synchronize()
		if("transmission_mode")
			var/new_mode = params["mode"]
			if(helper_feature_version < VOICE_CHAT_HELPER_FEATURE_VERSION || (new_mode != VOICE_CHAT_TRANSMISSION_PUSH_TO_TALK && new_mode != VOICE_CHAT_TRANSMISSION_VOICE_ACTIVATION))
				return FALSE
			transmission_mode = new_mode
			SSvoice_chat.synchronize()
		if("voice_activation_threshold")
			if(helper_feature_version < VOICE_CHAT_HELPER_FEATURE_VERSION)
				return FALSE
			var/new_threshold = text2num(params["value"])
			if(isnull(new_threshold))
				return FALSE
			voice_activation_threshold = clamp(round(new_threshold), VOICE_CHAT_MIN_ACTIVATION_THRESHOLD, VOICE_CHAT_MAX_ACTIVATION_THRESHOLD)
			SSvoice_chat.synchronize()
		if("output_test")
			if(status != VOICE_CHAT_STATUS_CONNECTED || helper_feature_version < VOICE_CHAT_HELPER_FEATURE_VERSION || !length(output_devices))
				return FALSE
			output_test_sequence++
			SSvoice_chat.synchronize()
		if("microphone_test")
			if(status != VOICE_CHAT_STATUS_CONNECTED || helper_feature_version < VOICE_CHAT_HELPER_FEATURE_VERSION || !length(input_devices) || !length(output_devices))
				return FALSE
			microphone_test_sequence++
			SSvoice_chat.synchronize()
		if("calibrate_microphone")
			if(status != VOICE_CHAT_STATUS_CONNECTED || helper_feature_version < VOICE_CHAT_HELPER_FEATURE_VERSION || !length(input_devices))
				return FALSE
			calibration_sequence++
			calibration_pending = TRUE
			calibrating = TRUE
			calibration_progress = 0
			recommended_threshold = 0
			noise_floor = 0
			SSvoice_chat.synchronize()
		if("input_gain")
			var/new_gain = text2num(params["value"])
			if(isnull(new_gain))
				return FALSE
			input_gain = clamp(round(new_gain), 0, 150)
		if("output_volume")
			var/new_volume = text2num(params["value"])
			if(isnull(new_volume))
				return FALSE
			output_volume = clamp(round(new_volume), 0, 100)
		if("input_device")
			if(!select_device(params["id"], input_devices, TRUE))
				return FALSE
		if("output_device")
			if(!select_device(params["id"], output_devices, FALSE))
				return FALSE
		if("peer_volume")
			if(!set_peer_volume(params["id"], params["value"]))
				return FALSE
		if("toggle_peer_mute")
			if(!toggle_peer_mute(params["id"]))
				return FALSE
		else
			return FALSE

/datum/voice_chat_client/proc/connect()
	if(!CONFIG_GET(flag/voice_chat_enabled) || !SSvoice_chat?.can_fire)
		status = VOICE_CHAT_STATUS_DISABLED
		return
	wants_connection = TRUE
	connect_token = ""
	helper_feature_version = 0
	helper_launch_url = ""
	status = VOICE_CHAT_STATUS_CONNECTING
	status_error = ""
	SSvoice_chat.synchronize()

/datum/voice_chat_client/proc/disconnect()
	wants_connection = FALSE
	connect_token = ""
	helper_feature_version = 0
	helper_launch_url = ""
	status = VOICE_CHAT_STATUS_DISCONNECTED
	status_error = ""
	set_speaking(FALSE)
	input_level = 0
	calibrating = FALSE
	calibration_pending = FALSE
	calibration_progress = 0
	recommended_threshold = 0
	noise_floor = 0
	audio_processing_active = FALSE
	audio_transport = ""
	SSvoice_chat.synchronize()

/datum/voice_chat_client/proc/set_push_to_talk(pressed)
	push_to_talk_pressed = !!pressed

/datum/voice_chat_client/proc/build_snapshot()
	var/mob/player = owner?.mob
	var/turf/player_turf = get_turf(player)
	var/list/position
	if(player_turf)
		position = list(
			"x" = player_turf.x,
			"y" = player_turf.y,
			"z" = player_turf.z,
		)

	return list(
		"session_id" = session_id,
		"display_name" = copytext_char(player?.name || owner?.key || "Unknown", 1, MAX_NAME_LEN + 1),
		"position" = position,
		"can_speak" = can_transmit_voice(),
		"can_listen" = can_receive_voice(),
		"wants_connection" = wants_connection,
		"muted" = muted,
		"deafened" = deafened,
		"push_to_talk_pressed" = push_to_talk_pressed,
		"push_to_talk_keys" = get_push_to_talk_keys(),
		"voice_activation_enabled" = transmission_mode == VOICE_CHAT_TRANSMISSION_VOICE_ACTIVATION,
		"voice_activation_threshold" = voice_activation_threshold,
		"output_test_sequence" = output_test_sequence,
		"microphone_test_sequence" = microphone_test_sequence,
		"calibration_sequence" = calibration_sequence,
		"calibration_requested" = calibration_pending,
		"input_gain" = input_gain,
		"output_volume" = output_volume,
		"input_device_id" = input_device_id,
		"output_device_id" = output_device_id,
		"peer_volumes" = get_peer_volumes_snapshot(),
		"muted_peers" = muted_peers,
	)

/datum/voice_chat_client/proc/can_transmit_voice()
	var/mob/living/player = owner?.mob
	return istype(player) && player.stat == CONSCIOUS && !player.IsSleeping() && player.can_speak() && player.IsVocal()

/datum/voice_chat_client/proc/can_receive_voice()
	var/mob/player = owner?.mob
	if(isobserver(player))
		return !!get_turf(player)
	if(!isliving(player))
		return FALSE
	var/mob/living/living_player = player
	return living_player.stat == CONSCIOUS && !living_player.IsSleeping() && !HAS_TRAIT(living_player, TRAIT_DEAF)

/datum/voice_chat_client/proc/set_speaking(new_speaking)
	var/mob/current_mob = owner?.mob
	var/mob/previous_mob = speaking_mob?.resolve()
	if(previous_mob != current_mob && speaking_overlay_visible)
		previous_mob?.cut_overlay(speaking_overlay)
		speaking_overlay_visible = FALSE

	var/should_show = !!new_speaking && can_transmit_voice()
	if(should_show && !speaking_overlay)
		speaking_overlay = image('icons/mob/effects/talk.dmi', icon_state = VOICE_CHAT_SPEAKING_ICON_STATE, layer = FLY_LAYER)
		speaking_overlay.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
		speaking_overlay.alpha = VOICE_CHAT_SPEAKING_ICON_ALPHA

	if(should_show && !speaking_overlay_visible)
		SET_PLANE_EXPLICIT(speaking_overlay, ABOVE_GAME_PLANE, current_mob)
		current_mob.add_overlay(speaking_overlay)
		speaking_overlay_visible = TRUE
	else if(!should_show && speaking_overlay_visible)
		current_mob?.cut_overlay(speaking_overlay)
		speaking_overlay_visible = FALSE

	speaking = should_show
	speaking_mob = current_mob ? WEAKREF(current_mob) : null

/datum/voice_chat_client/proc/get_push_to_talk_keys()
	var/list/keys = list()
	for(var/key in owner?.prefs?.keybindings)
		var/list/datum/keybinding/bindings = owner.prefs.keybindings[key]
		for(var/datum/keybinding/binding as anything in bindings)
			if(istype(binding, /datum/keybinding/client/voice_chat_push_to_talk))
				keys += key
	return keys

/datum/voice_chat_client/proc/get_peer_volumes_snapshot()
	var/list/volumes = list()
	for(var/peer_id in peer_volumes)
		volumes += list(list(
			"session_id" = peer_id,
			"volume" = peer_volumes[peer_id],
		))
	return volumes

/datum/voice_chat_client/proc/get_nearby_players()
	var/list/nearby_players = list()
	var/turf/owner_turf = get_turf(owner?.mob)
	if(!owner_turf)
		return nearby_players

	var/max_distance = CONFIG_GET(number/voice_chat_proximity_range)
	for(var/other_session_id in SSvoice_chat.sessions)
		if(other_session_id == session_id)
			continue
		var/datum/voice_chat_client/other_session = SSvoice_chat.sessions[other_session_id]
		var/turf/other_turf = get_turf(other_session.owner?.mob)
		if(!other_turf || other_turf.z != owner_turf.z)
			continue
		var/distance = get_dist(owner_turf, other_turf)
		if(distance > max_distance)
			continue
		nearby_players += list(list(
			"id" = other_session_id,
			"name" = copytext_char(other_session.owner?.mob?.name || other_session.owner?.key || "Unknown", 1, MAX_NAME_LEN + 1),
			"distance" = distance,
			"volume" = isnull(peer_volumes[other_session_id]) ? 100 : peer_volumes[other_session_id],
			"muted" = (other_session_id in muted_peers),
			"speaking" = other_session.speaking,
			"connected" = other_session.status == VOICE_CHAT_STATUS_CONNECTED,
		))
	return nearby_players

/datum/voice_chat_client/proc/apply_relay_state(list/data)
	var/new_status = data["status"]
	if(new_status in list(VOICE_CHAT_STATUS_DISCONNECTED, VOICE_CHAT_STATUS_CONNECTING, VOICE_CHAT_STATUS_CONNECTED, VOICE_CHAT_STATUS_ERROR))
		status = new_status
	status_error = copytext_char("[data["error"]]", 1, VOICE_CHAT_MAX_ERROR_LENGTH + 1)
	set_speaking(!!data["speaking"])
	input_level = clamp(text2num(data["input_level"]), 0, 100)
	helper_feature_version = max(0, round(text2num(data["helper_feature_version"])))
	var/helper_calibrating = !!data["calibrating"]
	calibration_progress = clamp(round(text2num(data["calibration_progress"])), 0, 100)
	var/new_calibration_result_sequence = max(0, round(text2num(data["calibration_sequence"])))
	recommended_threshold = clamp(round(text2num(data["recommended_threshold"])), 0, 100)
	noise_floor = clamp(round(text2num(data["noise_floor"])), 0, 100)
	audio_processing_active = !!data["audio_processing_active"]
	audio_transport = copytext_char("[data["audio_transport"]]", 1, 17)
	if(!helper_calibrating && new_calibration_result_sequence == calibration_sequence && new_calibration_result_sequence != calibration_result_sequence && recommended_threshold)
		calibration_result_sequence = new_calibration_result_sequence
		calibration_pending = FALSE
		voice_activation_threshold = clamp(recommended_threshold, VOICE_CHAT_MIN_ACTIVATION_THRESHOLD, VOICE_CHAT_MAX_ACTIVATION_THRESHOLD)
	calibrating = calibration_pending || helper_calibrating
	input_devices = sanitize_devices(data["input_devices"])
	output_devices = sanitize_devices(data["output_devices"])
	if(!input_device_id)
		input_device_id = get_default_device(input_devices)
	if(!output_device_id)
		output_device_id = get_default_device(output_devices)
	if(data["connect_token"] && data["connect_token"] != connect_token)
		connect_token = copytext_char("[data["connect_token"]]", 1, VOICE_CHAT_MAX_TOKEN_LENGTH + 1)
		var/relay_url = url_encode(helper_relay_url)
		var/token = url_encode(connect_token)
		helper_launch_url = "[VOICE_CHAT_HELPER_BROKER_URL]?relay=[relay_url]&token=[token]&protocol=[VOICE_CHAT_PROTOCOL_VERSION]"

/datum/voice_chat_client/proc/set_relay_unavailable(error)
	if(!wants_connection)
		return
	status = VOICE_CHAT_STATUS_RELAY_UNAVAILABLE
	status_error = copytext_char("[error]", 1, VOICE_CHAT_MAX_ERROR_LENGTH + 1)
	set_speaking(FALSE)
	input_level = 0
	calibrating = FALSE
	calibration_pending = FALSE
	calibration_progress = 0
	audio_processing_active = FALSE
	audio_transport = ""

/datum/voice_chat_client/proc/sanitize_devices(list/devices)
	var/list/result = list()
	if(!islist(devices))
		return result
	var/device_count = 0
	for(var/list/device in devices)
		if(++device_count > VOICE_CHAT_MAX_DEVICES)
			break
		var/device_id = copytext_char("[device["id"]]", 1, VOICE_CHAT_MAX_DEVICE_NAME_LENGTH + 1)
		if(!device_id)
			continue
		result += list(list(
			"id" = device_id,
			"name" = copytext_char("[device["name"]]", 1, VOICE_CHAT_MAX_DEVICE_NAME_LENGTH + 1),
			"default" = !!device["default"],
		))
	return result

/datum/voice_chat_client/proc/get_default_device(list/devices)
	for(var/list/device in devices)
		if(device["default"])
			return device["id"]
	return ""

/datum/voice_chat_client/proc/select_device(device_id, list/devices, is_input)
	for(var/list/device in devices)
		if(device["id"] != device_id)
			continue
		if(is_input)
			input_device_id = device_id
		else
			output_device_id = device_id
		SSvoice_chat.synchronize()
		return TRUE
	return FALSE

/datum/voice_chat_client/proc/set_peer_volume(peer_id, value)
	if(!is_nearby_session(peer_id))
		return FALSE
	var/new_volume = text2num(value)
	if(isnull(new_volume))
		return FALSE
	peer_volumes[peer_id] = clamp(round(new_volume), 0, 100)
	return TRUE

/datum/voice_chat_client/proc/toggle_peer_mute(peer_id)
	if(!is_nearby_session(peer_id))
		return FALSE
	if(peer_id in muted_peers)
		muted_peers -= peer_id
	else
		muted_peers += peer_id
	return TRUE

/datum/voice_chat_client/proc/is_nearby_session(peer_id)
	if(peer_id == session_id)
		return FALSE
	var/datum/voice_chat_client/other_session = SSvoice_chat.sessions[peer_id]
	if(QDELETED(other_session))
		return FALSE
	var/turf/owner_turf = get_turf(owner?.mob)
	var/turf/other_turf = get_turf(other_session.owner?.mob)
	return owner_turf && other_turf && owner_turf.z == other_turf.z && get_dist(owner_turf, other_turf) <= CONFIG_GET(number/voice_chat_proximity_range)

/client/verb/voice_chat()
	set name = "Голосовой чат"
	set category = VERB_CATEGORY_SPECIALVERBS

	if(!voice_chat)
		voice_chat = new(src)
	voice_chat.ui_interact(mob)
