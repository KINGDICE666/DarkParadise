/proc/is_launcher_ckey(test_ckey)
	return findtext(test_ckey, LAUNCHER_CKEY_PREFIX, 1, length(LAUNCHER_CKEY_PREFIX) + 1) == 1

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

	account_ckey = claimed_ckey
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

	if(data["ckey"] != account_ckey)
		log_adminwarn("Launcher identity mismatch: [key] claimed [account_ckey], backend returned [data["ckey"]]")
		reject_launcher_client("Учётная запись лаунчера не совпала с заявленной.")
		return

	steam_id = data["steamid64"]
	launcher_nickname = data["nickname"]
	launcher_state = LAUNCHER_VERIFIED
	store_launcher_link()

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

/client/proc/reject_launcher_client(reason)
	to_chat(src, span_danger("[reason] Запустите игру из лаунчера или войдите с аккаунтом BYOND."), confidential = TRUE)
	qdel(src)

/client/proc/reject_unlinked_client()
	if(!CONFIG_GET(flag/launcher_required))
		return
	if(!is_guest_key(key))
		return

	reject_launcher_client("Вход без лаунчера здесь закрыт.")
