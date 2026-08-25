GLOBAL_LIST_EMPTY(launcher_account_aliases)

/proc/is_launcher_ckey(test_ckey)
	return findtext(test_ckey, LAUNCHER_CKEY_PREFIX, 1, length(LAUNCHER_CKEY_PREFIX) + 1) == 1

/proc/load_launcher_aliases()
	if(!SSdbcore.IsConnected())
		return

	var/datum/db_query/query = SSdbcore.NewQuery({"
		SELECT launcher.ckey, byond.ckey FROM [format_table_name("player")] AS launcher
		INNER JOIN [format_table_name("player")] AS byond ON byond.discord_id = launcher.discord_id
		WHERE launcher.ckey LIKE :prefix AND byond.ckey NOT LIKE :prefix
		AND LENGTH(launcher.discord_id) < :token_length
	"}, list("prefix" = "[LAUNCHER_CKEY_PREFIX]%", "token_length" = DISCORD_TOKEN_LENGTH))

	if(!query.warn_execute(async = FALSE))
		qdel(query)
		return

	while(query.NextRow())
		GLOB.launcher_account_aliases[query.item[1]] = query.item[2]
	qdel(query)

/mob/proc/get_account_ckey()
	return client?.account_ckey || persistent_client?.account_ckey || ckey

/client/proc/is_launcher_client()
	return account_ckey != ckey

/client/proc/display_key()
	if(!launcher_nickname)
		return key
	if(!is_launcher_ckey(account_ckey))
		return account_ckey
	return "[launcher_nickname] (Steam)"

/client/proc/refresh_launcher_alias()
	if(!is_launcher_client() || !SSdbcore.IsConnected())
		return
	if(GLOB.launcher_account_aliases[launcher_claimed_ckey])
		return

	var/datum/db_query/query = SSdbcore.NewQuery({"
		SELECT byond.ckey FROM [format_table_name("player")] AS launcher
		INNER JOIN [format_table_name("player")] AS byond ON byond.discord_id = launcher.discord_id
		WHERE launcher.ckey = :ckey AND byond.ckey NOT LIKE :prefix
		AND LENGTH(launcher.discord_id) < :token_length
		LIMIT 1
	"}, list("ckey" = launcher_claimed_ckey, "prefix" = "[LAUNCHER_CKEY_PREFIX]%", "token_length" = DISCORD_TOKEN_LENGTH))

	if(!query.warn_execute())
		qdel(query)
		return

	var/linked_ckey
	if(query.NextRow())
		linked_ckey = query.item[1]
	qdel(query)

	if(!linked_ckey)
		return

	GLOB.launcher_account_aliases[launcher_claimed_ckey] = linked_ckey
	log_game("Launcher account [launcher_claimed_ckey] linked to [linked_ckey] through Discord")
	return linked_ckey

/client/proc/has_persistent_identity()
	return !is_guest_key(key) || launcher_state == LAUNCHER_VERIFIED

/client/proc/setup_account_ckey(connectiontopic)
	account_ckey = ckey

	if(!CONFIG_GET(string/launcher_api_url))
		return

	var/list/connection_params = params2list(connectiontopic)
	if(!connection_params["launcher_token"])
		return

	var/claimed_ckey = ckey(connection_params["launcher_ckey"])
	if(!is_launcher_ckey(claimed_ckey))
		return

	launcher_claimed_ckey = claimed_ckey
	account_ckey = GLOB.launcher_account_aliases[claimed_ckey] || claimed_ckey
	launcher_state = LAUNCHER_PENDING
	addtimer(CALLBACK(src, PROC_REF(launcher_link_timeout)), LAUNCHER_VERIFY_TIMEOUT)

/client/proc/launcher_link_timeout()
	if(launcher_state != LAUNCHER_PENDING)
		return

	reject_launcher_client("Сервис лаунчера не ответил.")

/client/proc/check_launcher_link(connectiontopic)
	set waitfor = FALSE
	var/api_url = CONFIG_GET(string/launcher_api_url)
	if(!api_url)
		return

	var/list/connection_params = params2list(connectiontopic)
	var/token = connection_params["launcher_token"]
	if(!token)
		reject_unlinked_client()
		return

	var/list/headers = list(
		"content-type" = "application/json",
		"x-game-secret" = CONFIG_GET(string/launcher_api_secret),
	)
	var/body = json_encode(list(
		"token" = token,
		"serverId" = CONFIG_GET(string/launcher_server_id),
	))
	SShttp.create_async_request(RUSTG_HTTP_METHOD_POST, "[api_url]/v1/connect/verify", body, headers, CALLBACK(src, PROC_REF(on_launcher_link_response)))

/client/proc/on_launcher_link_response(datum/http_response/response)
	if(!response || response.errored || response.status_code != 200 || !response.body)
		reject_launcher_client("Не удалось подтвердить вход через лаунчер.")
		return

	var/list/data = safe_json_decode(response.body)
	if(!islist(data) || !data["steamid64"])
		reject_launcher_client("Не удалось подтвердить вход через лаунчер.")
		return

	if(data["ckey"] != launcher_claimed_ckey)
		log_adminwarn("Launcher identity mismatch: [key] claimed [launcher_claimed_ckey], backend returned [data["ckey"]]")
		reject_launcher_client("Учётная запись лаунчера не совпала с заявленной.")
		return

	steam_id = data["steamid64"]
	launcher_nickname = data["nickname"]
	launcher_state = LAUNCHER_VERIFIED
	store_launcher_link()
	claim_admin_holder()
	if(holder)
		add_admin_verbs()
		INVOKE_ASYNC(src, PROC_REF(announce_join))
		INVOKE_ASYNC(src, PROC_REF(admin_memo_output), "Show", FALSE, TRUE)
	donator_check()
	referral_payout_check()

/client/proc/store_launcher_link()
	if(!SSdbcore.IsConnected())
		return

	var/datum/db_query/query = SSdbcore.NewQuery({"
		INSERT INTO [format_table_name("launcher_link")] (steamid64, ckey, nickname)
		VALUES (:steamid, :ckey, :nickname)
		ON DUPLICATE KEY UPDATE ckey = :ckey, nickname = :nickname, last_seen = Now()
	"}, list("steamid" = steam_id, "ckey" = account_ckey, "nickname" = launcher_nickname))
	query.warn_execute()
	qdel(query)

/client/proc/check_launcher_ban()
	set waitfor = FALSE
	if(!is_launcher_client())
		return

	var/ban_message
	if(CONFIG_GET(flag/ban_legacy_system))
		var/list/legacy_ban = CheckBan(account_ckey, computer_id, address)
		if(legacy_ban)
			ban_message = "Учётная запись [account_ckey] заблокирована.[legacy_ban["desc"]]"
	else
		if(!SSdbcore.IsConnected())
			log_world("Ban database connection failure. Launcher account [account_ckey] not checked")
			return

		var/datum/db_query/query = SSdbcore.NewQuery({"
			SELECT a_ckey, reason, expiration_time, duration, bantime, bantype FROM [CONFIG_GET(string/utility_database)].[format_table_name("ban")]
			WHERE ckey = :ckey AND (bantype = 'PERMABAN' OR bantype = 'ADMIN_PERMABAN'
			OR ((bantype = 'TEMPBAN' OR bantype = 'ADMIN_TEMPBAN') AND expiration_time > Now())) AND isnull(unbanned)
		"}, list("ckey" = account_ckey))

		if(!query.warn_execute())
			message_admins("Failed to do a launcher ban check for [account_ckey]. You have been warned.")
			qdel(query)
			return

		while(query.NextRow())
			var/a_ckey = query.item[1]
			var/reason = query.item[2]
			var/expiration = query.item[3]
			var/duration = query.item[4]
			var/bantime = query.item[5]
			var/bantype = query.item[6]
			var/is_admin_ban = bantype == "ADMIN_PERMABAN" || bantype == "ADMIN_TEMPBAN"
			if(holder && (holder.rights & R_ADMIN) && !is_admin_ban)
				log_admin("The admin [account_ckey] has been allowed to bypass a matching ban")
				continue
			var/expires = "Бан не истекает автоматически, его нужно обжаловать."
			if(text2num(duration) > 0)
				expires = "Бан выдан на [duration] минут и истекает [expiration] (время сервера)."
			var/appeal = ""
			if(CONFIG_GET(string/banappeals))
				appeal = " Обжаловать можно здесь: [CONFIG_GET(string/banappeals)]"
			ban_message = "Учётная запись [account_ckey] заблокирована. Причина: [reason]. Бан выдал [a_ckey], [bantime]. [expires][appeal]"
			break

		qdel(query)

	if(!ban_message)
		return

	log_adminwarn("Failed Login: [key]/[account_ckey] [computer_id] [address] - Banned launcher account")
	to_chat(src, span_danger(ban_message), confidential = TRUE)
	qdel(src)

/client/proc/reject_launcher_client(reason)
	to_chat(src, span_danger("[reason] Запустите игру из лаунчера или войдите с аккаунтом BYOND."), confidential = TRUE)
	qdel(src)

/client/proc/reject_unlinked_client()
	if(!CONFIG_GET(flag/launcher_required))
		return
	if(!is_guest_key(key))
		return

	reject_launcher_client("Вход без лаунчера здесь закрыт.")
