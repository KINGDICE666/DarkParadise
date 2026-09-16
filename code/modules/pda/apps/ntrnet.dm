/datum/data/pda/app/ntrnet
	name = "НТрнет"
	icon = "globe"
	template = "pda_ntrnet"
	var/site_id
	var/slug

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

/datum/data/pda/app/ntrnet/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(!SSntrnet.is_enabled())
		return
	switch(action)
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
		if("Back")
			site_id = null
			slug = null
		else
			return FALSE
	return TRUE
