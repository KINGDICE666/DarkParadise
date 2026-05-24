// Connects a client to voice chat via an external browser.
/datum/controller/subsystem/voicechat/proc/join_voicechat(client/client, show_link_only = FALSE)
	if(!client)
		return

	var/node_port = CONFIG_GET(number/port_voicechat)
	var/client_uid = client.UID()
	var/existing_user_code = client_uid_user_code[client_uid]
	if(existing_user_code)
		disconnect(existing_user_code, from_byond = TRUE)

	var/session_id = md5("[world.time][rand()][world.realtime][rand(0, 9999)][client.address][client.computer_id]")
	var/user_code = generate_user_code(client)
	if(!user_code)
		return

	user_code_client_uid[user_code] = client_uid
	client_uid_user_code[client_uid] = user_code

	var/address = CONFIG_GET(string/domain_voicechat)
	if(!address)
		if(client.address in list("127.0.0.1", "::1", "localhost"))
			address = "127.0.0.1"
		else
			address = world.internet_address || world.address || client.address || "127.0.0.1"

	var/web_link = "https://[address]:[node_port]?sessionId=[session_id]"
	if(!show_link_only)
		client << link(web_link)
	else
		client << browse({"
		<html>
			<head>
				<meta charset='UTF-8'>
				<style>
					body { background: #11151c; color: #e9eef5; font-family: Arial, sans-serif; margin: 16px; }
					code { display: block; background: #202938; border: 1px solid #334155; padding: 8px; word-break: break-all; }
					img { display: block; margin-top: 12px; background: #fff; padding: 8px; }
				</style>
			</head>
			<body>
				<h3>Голосовой чат</h3>
				<p>Скопируйте ссылку в браузер или отсканируйте QR-код.</p>
				<code>[web_link]</code>
				<img src='https://api.qrserver.com/v1/create-qr-code/?data=[url_encode(web_link)]&size=150x150' alt='QR'>
			</body>
		</html>"}, "window=voicechat_help;size=420x520")

	send_json(list(
		"cmd" = VOICECHAT_CMD_REGISTER,
		"userCode" = user_code,
		"sessionId" = session_id,
	))

// Disconnects a client from voice chat.
/datum/controller/subsystem/voicechat/proc/leave_voicechat(client/client)
	if(!client)
		return

	var/user_code = client_uid_user_code[client.UID()]
	if(!user_code)
		to_chat(client, span_ooc("Вы не подключены к голосовому чату."))
		return

	disconnect(user_code, from_byond = TRUE)
	to_chat(client, span_ooc("Вы отключились от голосового чата."))

// Sets up signals for a confirmed voice chat user.
/datum/controller/subsystem/voicechat/proc/post_confirm(user_code)
	var/client/client = get_client_by_user_code(user_code)
	if(!client || !client.mob)
		disconnect(user_code, from_byond = TRUE)
		return

	room_update(client.mob)

// Toggles the speaker overlay for a user.
/datum/controller/subsystem/voicechat/proc/toggle_active(user_code, is_active)
	if(!user_code || isnull(is_active))
		return

	var/client/client = get_client_by_user_code(user_code)
	if(!client || !client.mob)
		disconnect(user_code)
		return

	var/mob/mob = client.mob
	if(!user_code_speaking_icons[user_code])
		var/image/speaker_overlay = image('icons/mob/effects/talk.dmi', icon_state = "voice")
		speaker_overlay.alpha = VOICECHAT_SPEAKING_ICON_ALPHA
		user_code_speaking_icons[user_code] = speaker_overlay

	var/image/speaker_overlay = user_code_speaking_icons[user_code]
	var/mob/old_mob = user_code_mob[user_code]
	if(mob != old_mob)
		if(old_mob)
			old_mob.cut_overlay(speaker_overlay)
		user_code_mob[user_code] = mob
		room_update(mob)

	if(is_active && (isobserver(mob) || !mob.stat))
		mob.add_overlay(speaker_overlay)
	else
		mob.cut_overlay(speaker_overlay)

// Mutes or deafens a user's microphone.
/datum/controller/subsystem/voicechat/proc/mute_mic(client/client, deafen = FALSE)
	if(!client)
		return

	var/user_code = client_uid_user_code[client.UID()]
	if(!user_code)
		return

	send_json(list(
		"cmd" = deafen ? VOICECHAT_CMD_DEAFEN : VOICECHAT_CMD_MUTE_MIC,
		"userCode" = user_code,
	))
