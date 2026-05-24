/mob/verb/join_voicechat()
	set name = "Подключиться"
	set category = VERB_CATEGORY_PROXCHAT

	if(!SSvoicechat || !SSvoicechat.is_available())
		to_chat(src, span_ooc("Голосовой чат не запущен или временно недоступен."))
		return

	SSvoicechat.show_help(src)
	SSvoicechat.join_voicechat(client)

/mob/verb/join_voicechat_external()
	set name = "Ссылка"
	set category = VERB_CATEGORY_PROXCHAT

	if(!SSvoicechat || !SSvoicechat.is_available())
		to_chat(src, span_ooc("Голосовой чат не запущен или временно недоступен."))
		return

	SSvoicechat.join_voicechat(client, show_link_only = TRUE)

/mob/verb/leave_voicechat()
	set name = "Отключиться"
	set category = VERB_CATEGORY_PROXCHAT

	if(!SSvoicechat || !SSvoicechat.is_available())
		to_chat(src, span_ooc("Голосовой чат не запущен или временно недоступен."))
		return

	SSvoicechat.leave_voicechat(client)

/mob/verb/help_voicechat()
	set name = "Помощь"
	set category = VERB_CATEGORY_PROXCHAT

	if(!SSvoicechat)
		to_chat(src, span_ooc("Голосовой чат не запущен или временно недоступен."))
		return

	SSvoicechat.show_help(src)

/mob/verb/mute_self()
	set name = "Микрофон"
	set category = VERB_CATEGORY_PROXCHAT

	if(SSvoicechat)
		SSvoicechat.mute_mic(client)

/mob/verb/deafen()
	set name = "Звук"
	set category = VERB_CATEGORY_PROXCHAT

	if(SSvoicechat)
		SSvoicechat.mute_mic(client, deafen = TRUE)

/datum/controller/subsystem/voicechat/proc/show_help(mob/user)
	if(!user)
		return

	user << browse({"
	<html>
		<head>
			<meta charset='UTF-8'>
			<style>
				body { background: #11151c; color: #e9eef5; font-family: Arial, sans-serif; line-height: 1.45; margin: 16px; }
				h2, h4 { color: #ffffff; }
				li { margin-bottom: 6px; }
				code { background: #202938; border: 1px solid #334155; padding: 2px 5px; }
			</style>
		</head>
		<body>
			<h2>Голосовой чат</h2>
			<p>Откройте вкладку <code>ProxChat</code> и нажмите <b>Подключиться</b>. Если браузер не открылся автоматически, используйте команду <b>Ссылка</b>.</p>
			<ol>
				<li>Примите предупреждение тестового сертификата в браузере.</li>
				<li>Разрешите доступ к микрофону.</li>
				<li>Когда подключение завершится, индикатор речи будет появляться над персонажем.</li>
			</ol>
			<p>Держите окно голосового чата сразу под окном игры. Некоторые браузеры ограничивают захват микрофона, если активным становится другое приложение.</p>
			<h4>Команды</h4>
			<p><b>Микрофон</b> переключает передачу речи.<br>
			<b>Звук</b> переключает входящий голосовой звук.<br>
			<b>Отключиться</b> завершает текущую сессию голосового чата.</p>
			<h4>Проблемы с подключением</h4>
			<p>Проверьте расширения браузера, VPN, разрешения микрофона и выбранные устройства ввода/вывода. Для баг-репорта приложите ОС, браузер, статус VPN и скриншот консоли браузера.</p>
		</body>
	</html>"}, "window=voicechat_help;size=520x640")
