#define NTNET_LOGIN_TIMEOUT (20 SECONDS)
#define NTNET_LOGIN_COOLDOWN (1 MINUTES)
#define NTNET_CODE_LIFETIME (15 MINUTES)
#define NTNET_LOGIN_MAX_BODY 4096

/datum/config_entry/string/ntnet_editor_url
	default = "https://ntnet.wiki-ss13.space"

/client
	var/ntnet_code
	var/ntnet_code_expires = 0
	var/ntnet_login_pending = FALSE
	var/ntnet_login_retry = 0
	var/ntnet_login_request = 0
	var/ntnet_login_error

/datum/controller/subsystem/ntnet/proc/request_login(client/user)
	if(!user || !is_enabled() || user.ntnet_login_pending || world.time < user.ntnet_login_retry)
		return
	var/identity = user.account_ckey || user.ckey
	if((is_guest_key(user.key) && !user.is_launcher_client()) || is_launcher_ckey(identity) || (user.is_launcher_client() && user.launcher_state != LAUNCHER_VERIFIED))
		user.ntnet_login_error = "Для входа нужен подтверждённый BYOND-аккаунт."
		return
	user.ntnet_code = null
	user.ntnet_code_expires = 0
	user.ntnet_login_error = null
	user.ntnet_login_pending = TRUE
	user.ntnet_login_retry = world.time + NTNET_LOGIN_COOLDOWN
	user.ntnet_login_request++
	var/user_uid = user.UID()
	var/request_id = user.ntnet_login_request
	var/list/headers = list("X-Server-Key" = CONFIG_GET(string/ntnet_server_key), "Content-Type" = "application/json")
	SShttp.create_async_request(RUSTG_HTTP_METHOD_POST, "[CONFIG_GET(string/ntnet_api_url)]/api/v1/device/new", json_encode(list("ckey" = identity)), headers, CALLBACK(src, PROC_REF(on_login), user_uid, identity, request_id), sensitive = TRUE)
	addtimer(CALLBACK(src, PROC_REF(login_timeout), user_uid, request_id), NTNET_LOGIN_TIMEOUT)

/datum/controller/subsystem/ntnet/proc/login_timeout(user_uid, request_id)
	var/client/user = locateUID(user_uid)
	if(!user || !user.ntnet_login_pending || user.ntnet_login_request != request_id)
		return
	user.ntnet_login_pending = FALSE
	user.ntnet_login_error = "NTnet не ответил. Попробуйте снова через минуту."

/datum/controller/subsystem/ntnet/proc/on_login(user_uid, identity, request_id, datum/http_response/response)
	var/client/user = locateUID(user_uid)
	if(!user || !user.ntnet_login_pending || user.ntnet_login_request != request_id)
		return
	user.ntnet_login_pending = FALSE
	if((user.account_ckey || user.ckey) != identity)
		return
	user.ntnet_login_error = "Не удалось получить код. Попробуйте снова через минуту."
	var/code = parse_ntnet_login_response(response)
	if(!code)
		return
	user.ntnet_code = code
	user.ntnet_code_expires = world.time + NTNET_CODE_LIFETIME - NTNET_LOGIN_TIMEOUT
	user.ntnet_login_error = null
	var/editor_url = html_encode(CONFIG_GET(string/ntnet_editor_url))
	to_chat(user, span_notice("NTnet: Ваш одноразовый код — [user.ntnet_code]. Действует до 15 минут. <a href='[editor_url]'>Открыть редактор</a>. Не передавайте код другим игрокам."), confidential = TRUE)

/proc/parse_ntnet_login_response(datum/http_response/response)
	if(response.errored || response.status_code != 201 || !istext(response.body) || length(response.body) > NTNET_LOGIN_MAX_BODY)
		return
	var/list/document = safe_json_decode(response.body)
	if(!islist(document) || !istext(document["code"]) || length(document["code"]) != 14 || document["expires_in"] != NTNET_CODE_LIFETIME / (1 SECONDS))
		return
	var/static/regex/code_pattern = regex("^\[23456789ABCDEFGHJKLMNPQRSTUVWXYZ\]{4}-\[23456789ABCDEFGHJKLMNPQRSTUVWXYZ\]{4}-\[23456789ABCDEFGHJKLMNPQRSTUVWXYZ\]{4}$")
	if(!code_pattern.Find(document["code"]))
		return
	return document["code"]

#undef NTNET_LOGIN_TIMEOUT
#undef NTNET_LOGIN_COOLDOWN
#undef NTNET_CODE_LIFETIME
#undef NTNET_LOGIN_MAX_BODY
