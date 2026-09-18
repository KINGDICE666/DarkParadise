#define NTRNET_SEARCH_TIMEOUT (20 SECONDS)
#define NTRNET_SEARCH_MAX_QUERY_LENGTH 80
#define NTRNET_SEARCH_MAX_RESULTS 20
#define NTRNET_SEARCH_MAX_BODY 8192

/datum/data/pda/app/ntrnet
	name = "НТрнет"
	icon = "globe"
	template = "pda_ntrnet"
	var/site_id
	var/slug
	var/search_query
	var/list/search_results = list()
	var/search_pending = FALSE
	var/search_error
	var/search_request = 0

/datum/data/pda/app/ntrnet/start()
	if(!SSntrnet.is_enabled())
		return FALSE
	. = ..()
	SSntrnet.refresh_index()

/datum/data/pda/app/ntrnet/update_ui(mob/user, list/data)
	var/list/site = SSntrnet.sites[site_id]
	if(site_id && !SSntrnet.has_page(site_id, slug))
		site_id = null
		slug = null
		site = null
	has_back = !isnull(site_id)
	data["app"]["has_back"] = has_back
	var/cache_key = json_encode(list(site_id, slug))
	if(site_id)
		SSntrnet.request_page(site_id, slug)
	data["ntrnet"] = list(
		"available" = SSntrnet.available,
		"loading" = site_id ? !!SSntrnet.pending[cache_key] : SSntrnet.index_pending,
		"catalog" = SSntrnet.catalog,
		"site" = site,
		"page" = SSntrnet.pages[cache_key],
		"slug" = slug,
	)
	data["ntrnet"]["search"] = list(
		"query" = search_query,
		"results" = search_results,
		"pending" = search_pending,
		"error" = search_error,
	)
	var/client/viewer = user.client
	data["ntrnet"]["login"] = list(
		"code" = viewer && viewer.ntrnet_code_expires > world.time ? viewer.ntrnet_code : null,
		"pending" = viewer?.ntrnet_login_pending,
		"retry_seconds" = viewer ? max(0, ceil((viewer.ntrnet_login_retry - world.time) / (1 SECONDS))) : 0,
		"error" = viewer?.ntrnet_login_error,
	)

/datum/data/pda/app/ntrnet/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(!SSntrnet.is_enabled())
		return
	switch(action)
		if("ntrnet_login")
			SSntrnet.request_login(ui.user.client)
		if("ntrnet_open")
			if(!SSntrnet.has_page(params["site_id"], params["slug"]))
				return
			site_id = params["site_id"]
			slug = params["slug"]
			SSntrnet.request_page(site_id, slug)
		if("ntrnet_refresh")
			SSntrnet.refresh_index()
			if(site_id)
				SSntrnet.request_page(site_id, slug)
		if("ntrnet_search")
			search(params["query"])
		if("Back")
			site_id = null
			slug = null
		else
			return FALSE
	return TRUE

/datum/data/pda/app/ntrnet/proc/search(raw_query)
	if(!istext(raw_query) || search_pending || !SSntrnet.is_enabled())
		return
	var/query = trim(raw_query)
	if(length_char(query) < 2 || length_char(query) > NTRNET_SEARCH_MAX_QUERY_LENGTH)
		search_error = "Введите от 2 до [NTRNET_SEARCH_MAX_QUERY_LENGTH] символов."
		return
	search_query = query
	search_results = list()
	search_error = null
	search_pending = TRUE
	search_request++
	var/request_id = search_request
	SShttp.create_async_request(RUSTG_HTTP_METHOD_GET, "[CONFIG_GET(string/ntrnet_api_url)]/api/v1/search?q=[url_encode(query)]", headers = list("X-Server-Key" = CONFIG_GET(string/ntrnet_server_key)), proc_callback = CALLBACK(src, PROC_REF(on_search), request_id), sensitive = TRUE)
	addtimer(CALLBACK(src, PROC_REF(search_timeout), request_id), NTRNET_SEARCH_TIMEOUT)

/datum/data/pda/app/ntrnet/proc/search_timeout(request_id)
	if(!search_pending || search_request != request_id)
		return
	search_pending = FALSE
	search_error = "Поиск не ответил. Попробуйте ещё раз."
	if(!QDELETED(pda))
		SStgui.update_uis(pda)

/datum/data/pda/app/ntrnet/proc/on_search(request_id, datum/http_response/response)
	if(!search_pending || search_request != request_id)
		return
	search_pending = FALSE
	search_error = "Не удалось выполнить поиск."
	if(response.errored || response.status_code != 200 || !istext(response.body) || length(response.body) > NTRNET_SEARCH_MAX_BODY)
		if(!QDELETED(pda))
			SStgui.update_uis(pda)
		return
	var/list/document = safe_json_decode(response.body)
	if(!islist(document))
		if(!QDELETED(pda))
			SStgui.update_uis(pda)
		return
	var/list/site_ids = document["site_ids"]
	if(!islist(site_ids) || length(site_ids) > NTRNET_SEARCH_MAX_RESULTS)
		if(!QDELETED(pda))
			SStgui.update_uis(pda)
		return
	var/list/results = list()
	for(var/result_id in site_ids)
		if(!istext(result_id) || length(result_id) > 64)
			continue
		var/list/site = SSntrnet.sites[result_id]
		if(site && !(site in results))
			results += list(site)
	search_results = results
	search_error = null
	if(!QDELETED(pda))
		SStgui.update_uis(pda)

#undef NTRNET_SEARCH_TIMEOUT
#undef NTRNET_SEARCH_MAX_QUERY_LENGTH
#undef NTRNET_SEARCH_MAX_RESULTS
#undef NTRNET_SEARCH_MAX_BODY
