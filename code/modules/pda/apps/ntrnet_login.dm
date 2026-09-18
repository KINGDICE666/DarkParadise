#define NTRNET_LOGIN_TIMEOUT (20 SECONDS)
#define NTRNET_LOGIN_COOLDOWN (1 MINUTES)
#define NTRNET_CODE_LIFETIME (15 MINUTES)
#define NTRNET_LOGIN_MAX_BODY 4096

/datum/config_entry/string/ntrnet_editor_url
	default = "https://wiki-ss13.space/ntrnet"

/client
	var/ntrnet_code
	var/ntrnet_code_expires = 0
	var/ntrnet_login_pending = FALSE
	var/ntrnet_login_retry = 0
	var/ntrnet_login_request = 0
	var/ntrnet_login_error

/datum/controller/subsystem/ntrnet/proc/request_login(client/user)
	if(!user || !is_enabled() || user.ntrnet_login_pending || world.time < user.ntrnet_login_retry)
		return
	var/identity = user.account_ckey || user.ckey
	if((is_guest_key(user.key) && !user.is_launcher_client()) || is_launcher_ckey(identity) || (user.is_launcher_client() && user.launcher_state != LAUNCHER_VERIFIED))
		user.ntrnet_login_error = "Для входа нужен подтверждённый BYOND-аккаунт."
		return
	user.ntrnet_code = null
	user.ntrnet_code_expires = 0
	user.ntrnet_login_error = null
	user.ntrnet_login_pending = TRUE
	user.ntrnet_login_retry = world.time + NTRNET_LOGIN_COOLDOWN
	user.ntrnet_login_request++
	var/user_uid = user.UID()
	var/request_id = user.ntrnet_login_request
	var/list/headers = list("X-Server-Key" = CONFIG_GET(string/ntrnet_server_key), "Content-Type" = "application/json")
	SShttp.create_async_request(RUSTG_HTTP_METHOD_POST, "[CONFIG_GET(string/ntrnet_api_url)]/api/v1/device/new", json_encode(list("ckey" = identity)), headers, CALLBACK(src, PROC_REF(on_login), user_uid, identity, request_id), sensitive = TRUE)
	addtimer(CALLBACK(src, PROC_REF(login_timeout), user_uid, request_id), NTRNET_LOGIN_TIMEOUT)

/datum/controller/subsystem/ntrnet/proc/login_timeout(user_uid, request_id)
	var/client/user = locateUID(user_uid)
	if(!user || !user.ntrnet_login_pending || user.ntrnet_login_request != request_id)
		return
	user.ntrnet_login_pending = FALSE
	user.ntrnet_login_error = "НТрнет не ответил. Попробуйте снова через минуту."

/datum/controller/subsystem/ntrnet/proc/on_login(user_uid, identity, request_id, datum/http_response/response)
	var/client/user = locateUID(user_uid)
	if(!user || !user.ntrnet_login_pending || user.ntrnet_login_request != request_id)
		return
	user.ntrnet_login_pending = FALSE
	if((user.account_ckey || user.ckey) != identity)
		return
	user.ntrnet_login_error = "Не удалось получить код. Попробуйте снова через минуту."
	var/code = parse_ntrnet_login_response(response)
	if(!code)
		return
	user.ntrnet_code = code
	user.ntrnet_code_expires = world.time + NTRNET_CODE_LIFETIME - NTRNET_LOGIN_TIMEOUT
	user.ntrnet_login_error = null
	var/editor_url = html_encode(CONFIG_GET(string/ntrnet_editor_url))
	to_chat(user, span_notice("НТрнет: Ваш одноразовый код — [user.ntrnet_code]. Действует до 15 минут. <a href='[editor_url]'>Открыть редактор</a>. Не передавайте код другим игрокам."), confidential = TRUE)

/proc/parse_ntrnet_login_response(datum/http_response/response)
	if(response.errored || response.status_code != 201 || !istext(response.body) || length(response.body) > NTRNET_LOGIN_MAX_BODY)
		return
	var/list/document = safe_json_decode(response.body)
	if(!islist(document) || !istext(document["code"]) || length(document["code"]) != 14 || document["expires_in"] != NTRNET_CODE_LIFETIME / (1 SECONDS))
		return
	var/static/regex/code_pattern = regex("^\[23456789ABCDEFGHJKLMNPQRSTUVWXYZ\]{4}-\[23456789ABCDEFGHJKLMNPQRSTUVWXYZ\]{4}-\[23456789ABCDEFGHJKLMNPQRSTUVWXYZ\]{4}$")
	if(!code_pattern.Find(document["code"]))
		return
	return document["code"]

#undef NTRNET_LOGIN_TIMEOUT
#undef NTRNET_LOGIN_COOLDOWN
#undef NTRNET_CODE_LIFETIME
#undef NTRNET_LOGIN_MAX_BODY
