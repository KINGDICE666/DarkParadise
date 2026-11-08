GLOBAL_LIST_INIT(net_ice_areas, zebra_typecacheof(list(
	/area/station/ai = NET_ICE_STANDARD,
	/area/station/command = NET_ICE_STANDARD,
	/area/station/security = NET_ICE_STANDARD,
	/area/station/telecomms = NET_ICE_STANDARD,
	/area/station/ai/satellite/exterior = NET_ICE_NONE,
	/area/station/security/checkpoint = NET_ICE_NONE,
	/area/station/security/courtroom = NET_ICE_NONE,
	/area/station/security/customs = NET_ICE_NONE,
	/area/station/security/lobby = NET_ICE_NONE,
	/area/station/ai/satellite/chamber = NET_ICE_BLACK,
	/area/station/ai/upload = NET_ICE_BLACK,
	/area/station/command/office/captain = NET_ICE_BLACK,
	/area/station/command/vault = NET_ICE_BLACK,
	/area/station/security/hallway/armory = NET_ICE_BLACK,
	/area/station/telecomms/server = NET_ICE_BLACK,
)))

/proc/get_net_ice(area/zone)
	if(!zone)
		return NET_ICE_NONE
	return GLOB.net_ice_areas[zone.type] || NET_ICE_NONE

/mob/living/basic/net_avatar/proc/is_ice_blocked(area/zone)
	if(!get_net_ice(zone) || zone == home_area)
		return FALSE
	return !(breached_areas[zone] > world.time)

/mob/living/basic/net_avatar/proc/on_pre_move(datum/source, atom/new_location)
	SIGNAL_HANDLER
	var/area/destination = get_area(new_location)
	if(destination == get_area(src) || !is_ice_blocked(destination))
		return NONE
	if(COOLDOWN_FINISHED(src, ice_notice))
		COOLDOWN_START(src, ice_notice, NET_ICE_NOTICE_COOLDOWN)
		balloon_alert(src, "лёд! взломайте узел за ним")
	return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/mob/living/basic/net_avatar/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	refresh_ice()
	follow_projection()

/mob/living/basic/net_avatar/proc/refresh_ice()
	if(!client)
		return
	client.images -= ice_images
	ice_images.Cut()
	for(var/turf/tile as anything in RANGE_TURFS(NET_ICE_VIEW_RANGE, src))
		if(tile.density)
			continue
		var/area/zone = tile.loc
		if(!is_ice_blocked(zone))
			continue
		for(var/direction in GLOB.cardinal)
			var/turf/neighbour = get_step(tile, direction)
			if(!neighbour || neighbour.loc == zone || neighbour.density)
				continue
			var/image/curtain = image('icons/effects/netrunning.dmi', tile, get_net_ice(zone) == NET_ICE_BLACK ? "black_ice" : "ice", ABOVE_ALL_MOB_LAYER)
			SET_PLANE_EXPLICIT(curtain, ABOVE_GAME_PLANE, tile)
			curtain.appearance_flags = RESET_COLOR|NO_CLIENT_COLOR
			curtain.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
			ice_images += curtain
			break
	client.images += ice_images

/mob/living/basic/net_avatar/proc/start_breach(area/zone)
	if(active_breach)
		active_breach.ui_interact(src)
		return
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	active_breach = new(src, zone, get_net_ice(zone), NET_BREACH_BASE_BUFFER + neuro?.get_breach_buffer_bonus())
	active_breach.ui_interact(src)
	add_game_logs("started a breach protocol against the ICE of [zone]", src)

/mob/living/basic/net_avatar/proc/on_breach_finished(datum/net_breach/breach, list/completed, aborted)
	active_breach = null
	var/area/zone = breach.target_area
	if(NET_DAEMON_ICE in completed)
		var/duration = (NET_DAEMON_HOLD in completed) ? NET_BREACH_DURATION_HELD : NET_BREACH_DURATION
		breached_areas[zone] = world.time + duration
		if(!(NET_DAEMON_TRACE in completed))
			add_trace(NET_TRACE_BREACH)
		playsound_local(get_turf(src), 'sound/machines/ping.ogg', 40, FALSE)
		balloon_alert(src, "лёд вскрыт")
		refresh_ice()
		addtimer(CALLBACK(src, PROC_REF(refresh_ice)), duration)
		add_game_logs("breached the ICE of [zone]", src)
		return
	if(aborted)
		add_trace(NET_TRACE_BREACH)
		balloon_alert(src, "взлом прерван")
		return
	var/black_ice = breach.tier == NET_ICE_BLACK
	add_trace(NET_TRACE_BREACH_FAIL)
	playsound_local(get_turf(src), 'sound/effects/empulse.ogg', 40, TRUE)
	to_chat(src, span_userdanger(black_ice ? "Чёрный лёд вгрызается в поток данных и выжигает его изнутри!" : "Лёд отбрасывает вас, обжигая поток данных!"))
	add_game_logs("failed to breach the ICE of [zone]", src)
	adjustFireLoss(black_ice ? NET_ICE_DAMAGE_BLACK : NET_ICE_DAMAGE_STANDARD)

/mob/living/basic/net_avatar/proc/get_trace()
	return max(trace - (world.time - trace_updated) / NET_TRACE_DECAY_TIME, 0)

/mob/living/basic/net_avatar/proc/add_trace(amount)
	trace = get_trace() + amount
	trace_updated = world.time
	if(trace >= NET_TRACE_MAX)
		trace = 0
		complete_trace()
	update_trace_alert()

/mob/living/basic/net_avatar/proc/update_trace_alert()
	var/current_trace = get_trace()
	var/stage = ceil(current_trace / NET_TRACE_MAX * NET_TRACE_STAGES)
	if(!stage)
		clear_alert(NET_TRACE_ALERT)
		return
	var/atom/movable/screen/alert/net_trace/alert = throw_alert(NET_TRACE_ALERT, /atom/movable/screen/alert/net_trace, stage)
	alert.desc = "Чужой нетраннер идёт по вашему следу: [round(current_trace)]%. Взломы и вскрытие льда ускоряют трассировку, затишье её сбивает. На 100% служба безопасности узнает, где лежит ваше тело."

/mob/living/basic/net_avatar/proc/complete_trace()
	var/datum/component/net_connection/connection = GetComponent(/datum/component/net_connection)
	var/atom/signal_source = connection?.pod || src
	var/location = get_area_name(signal_source, TRUE)
	for(var/mob/living/silicon/ai/station_ai as anything in GLOB.ai_list)
		to_chat(station_ai, span_danger("Трассировка завершена: в Сети станции нетраннер. Источник сигнала — [location]."))
	radio_announce("Обнаружено вторжение в Сеть станции. Источник сигнала: [location].", "Мониторинг сети", SEC_FREQ, signal_source)
	playsound_local(get_turf(src), 'sound/machines/twobeep.ogg', 60, TRUE)
	to_chat(src, span_userdanger("Трассировка завершена! Служба безопасности знает, где лежит ваше тело."))
	add_game_logs("was traced in the Net, source revealed as [location]", src)

/atom/movable/screen/alert/net_trace
	name = "Трассировка"
	desc = "Чужой нетраннер идёт по вашему следу."
	icon = 'icons/effects/netrunning.dmi'
	icon_state = "trace"
