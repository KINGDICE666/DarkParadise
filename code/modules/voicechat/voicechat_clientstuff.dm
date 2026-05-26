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

	var/web_link = "https://[address]:[node_port]?sessionId=[session_id]&popup=1"
	show_launcher(client, web_link, !show_link_only)

	send_json(list(
		"cmd" = VOICECHAT_CMD_REGISTER,
		"userCode" = user_code,
		"sessionId" = session_id,
	))

/datum/controller/subsystem/voicechat/proc/show_launcher(client/client, web_link, auto_open = TRUE)
	if(!client)
		return

	var/encoded_link = html_encode(web_link)
	var/auto_open_value = auto_open ? "true" : "false"
	client << browse({"
		<html>
			<head>
				<meta charset='UTF-8'>
				<style>
					* { box-sizing: border-box; }
					body { background: #101318; color: #edf2f7; font-family: Arial, sans-serif; margin: 0; }
					.panel { display: flex; flex-direction: column; gap: 12px; min-height: 100vh; padding: 16px; }
					h3 { font-size: 18px; margin: 0; }
					p { color: #aeb8c4; line-height: 1.4; margin: 0; }
					.actions { display: grid; gap: 8px; grid-template-columns: 1fr 1fr; }
					.button { align-items: center; background: #26313d; border: 1px solid #435061; border-radius: 6px; color: #f4f8fb; cursor: pointer; display: flex; font-weight: 700; justify-content: center; min-height: 38px; padding: 8px 10px; text-align: center; text-decoration: none; }
					.button.primary { background: #22573e; border-color: #54c58a; }
					.button:hover { filter: brightness(1.08); }
					code { background: #1a2028; border: 1px solid #343f4d; border-radius: 6px; display: block; font-size: 12px; padding: 8px; word-break: break-all; }
					.note { border-left: 3px solid #73b7ff; color: #c7d3df; min-height: 40px; padding-left: 10px; }
					.qr-wrap { align-items: center; display: flex; gap: 12px; }
					img { background: #ffffff; border-radius: 6px; height: 92px; padding: 6px; width: 92px; }
				</style>
			</head>
			<body>
				<div class='panel'>
					<h3>&#1043;&#1086;&#1083;&#1086;&#1089;&#1086;&#1074;&#1086;&#1081; &#1095;&#1072;&#1090;</h3>
					<p>&#1055;&#1072;&#1085;&#1077;&#1083;&#1100; &#1075;&#1086;&#1083;&#1086;&#1089;&#1072; &#1086;&#1090;&#1082;&#1088;&#1086;&#1077;&#1090;&#1089;&#1103; &#1086;&#1090;&#1076;&#1077;&#1083;&#1100;&#1085;&#1099;&#1084; &#1082;&#1086;&#1084;&#1087;&#1072;&#1082;&#1090;&#1085;&#1099;&#1084; &#1086;&#1082;&#1085;&#1086;&#1084; &#1073;&#1088;&#1072;&#1091;&#1079;&#1077;&#1088;&#1072;.</p>
					<div class='actions'>
						<button class='button primary' id='open'>&#1054;&#1090;&#1082;&#1088;&#1099;&#1090;&#1100;</button>
						<button class='button' id='copy'>&#1050;&#1086;&#1087;&#1080;&#1088;&#1086;&#1074;&#1072;&#1090;&#1100;</button>
					</div>
					<div class='note' id='note'>&#1056;&#1072;&#1079;&#1088;&#1077;&#1096;&#1080;&#1090;&#1077; &#1076;&#1086;&#1089;&#1090;&#1091;&#1087; &#1082; &#1084;&#1080;&#1082;&#1088;&#1086;&#1092;&#1086;&#1085;&#1091; &#1074; &#1073;&#1088;&#1072;&#1091;&#1079;&#1077;&#1088;&#1077;.</div>
					<code>[encoded_link]</code>
					<div class='qr-wrap'>
						<img src='https://api.qrserver.com/v1/create-qr-code/?data=[url_encode(web_link)]&size=150x150' alt='QR'>
						<p>QR &#1084;&#1086;&#1078;&#1085;&#1086; &#1086;&#1090;&#1082;&#1088;&#1099;&#1090;&#1100; &#1089; &#1076;&#1088;&#1091;&#1075;&#1086;&#1075;&#1086; &#1091;&#1089;&#1090;&#1088;&#1086;&#1081;&#1089;&#1090;&#1074;&#1072; &#1074; &#1101;&#1090;&#1086;&#1081; &#1089;&#1077;&#1090;&#1080;.</p>
					</div>
				</div>
				<script>
					const voiceUrl = [json_encode(web_link)];
					const autoOpen = [auto_open_value];
					const features = 'popup=yes,width=[VOICECHAT_WEB_POPUP_WIDTH],height=[VOICECHAT_WEB_POPUP_HEIGHT],left=80,top=80,resizable=yes,scrollbars=no,toolbar=no,menubar=no,status=no';
					const note = document.getElementById('note');
					function setNote(text) {
						note.innerHTML = text;
					}
					function openVoicePanel() {
						const popup = window.open(voiceUrl, 'ss13_voicechat', features);
						if(popup) {
							popup.focus();
							setNote('&#1055;&#1072;&#1085;&#1077;&#1083;&#1100; &#1086;&#1090;&#1082;&#1088;&#1099;&#1090;&#1072;.');
							return;
						}
						setNote('&#1041;&#1088;&#1072;&#1091;&#1079;&#1077;&#1088; &#1079;&#1072;&#1073;&#1083;&#1086;&#1082;&#1080;&#1088;&#1086;&#1074;&#1072;&#1083; popup. &#1053;&#1072;&#1078;&#1084;&#1080;&#1090;&#1077; &quot;&#1054;&#1090;&#1082;&#1088;&#1099;&#1090;&#1100;&quot; &#1077;&#1097;&#1077; &#1088;&#1072;&#1079;.');
					}
					document.getElementById('open').addEventListener('click', openVoicePanel);
					document.getElementById('copy').addEventListener('click', async () => {
						try {
							await navigator.clipboard.writeText(voiceUrl);
							setNote('&#1057;&#1089;&#1099;&#1083;&#1082;&#1072; &#1089;&#1082;&#1086;&#1087;&#1080;&#1088;&#1086;&#1074;&#1072;&#1085;&#1072;.');
						} catch(error) {
							setNote('&#1057;&#1082;&#1086;&#1087;&#1080;&#1088;&#1091;&#1081;&#1090;&#1077; &#1089;&#1089;&#1099;&#1083;&#1082;&#1091; &#1080;&#1079; &#1087;&#1086;&#1083;&#1103; &#1085;&#1080;&#1078;&#1077;.');
						}
					});
					if(autoOpen) {
						setTimeout(openVoicePanel, 100);
					}
				</script>
			</body>
		</html>"}, "window=voicechat_launcher;size=[VOICECHAT_LAUNCHER_WIDTH]x[VOICECHAT_LAUNCHER_HEIGHT];can_close=1;can_minimize=1;can_maximize=0;can_resize=0;titlebar=1")

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
