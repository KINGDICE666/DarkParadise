/mob/new_player/Login()
	if(!client)
		return

	//Overflow rerouting, if set, forces players to be moved to a different server once a player cap is reached. Less rough than a pure kick.
	if(CONFIG_GET(number/player_reroute_cap) && CONFIG_GET(string/overflow_server_url))
		if(!whitelist_check())
			if(CONFIG_GET(number/player_reroute_cap) == 1 || length(GLOB.clients) > CONFIG_GET(number/player_reroute_cap))
				close_window(src, "privacy_consent")
				src << link(CONFIG_GET(string/overflow_server_url))

	if(!mind)
		mind = new /datum/mind(key)
		mind.active = 1
		mind.current = src

	if(length(GLOB.newplayer_start))
		loc = pick(GLOB.newplayer_start)
	else
		loc = locate(1,1,1)

	lastarea = loc

	. = ..()
	if(!. || !client)
		return FALSE

	if(GLOB.join_motd)
		// Strip source newlines so to_chat() does not turn HTML indentation into <br>.
		var/motd_html = replacetext(GLOB.join_motd, "\n", "")
		to_chat(src, span_infoplain("<div class=\"motd\">[motd_html]</div>"))

	if(GLOB.admin_notice)
		to_chat(src, span_notice("<b>Admin Notice:</b>\n \t [GLOB.admin_notice]"))

	add_sight(SEE_TURFS)
	GLOB.new_player_mobs |= src

	client.playtitlemusic()

/mob/new_player/proc/whitelist_check()
	// Admins are immune to overflow rerouting
	if(check_rights(rights_required = R_NONE, show_msg = FALSE))
		return TRUE

	if(CONFIG_GET(flag/usewhitelist_nojobbanned) && GLOB.jobban_assoclist[src.ckey])
		return FALSE

	//Whitelisted people are immune to overflow rerouting.
	if(CONFIG_GET(flag/usewhitelist_database) && SSdbcore.IsConnected())
		var/datum/db_query/find_ticket = SSdbcore.NewQuery(
			"SELECT ckey FROM [CONFIG_GET(string/utility_database)].[format_table_name("ckey_whitelist")] WHERE ckey=:ckey AND is_valid=true AND port=:port AND date_start<=NOW() AND (NOW()<date_end OR date_end IS NULL)",
			list("ckey" = src.ckey, "port" = "[world.port]")
		)
		if(!find_ticket.warn_execute(async = FALSE))
			QDEL_NULL(find_ticket)
			return FALSE
		if(!find_ticket.NextRow())
			QDEL_NULL(find_ticket)
			return FALSE
		QDEL_NULL(find_ticket)
		return TRUE
	else if(GLOB.overflow_whitelist.Find(lowertext(src.ckey)))
		return TRUE
	return FALSE
