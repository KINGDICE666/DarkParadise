#define EMERGENCY_CALL_DELAY (5 SECONDS)
#define EMERGENCY_CALL_COOLDOWN (5 MINUTES)
#define EMERGENCY_CALL_REASON_LENGTH 200

/datum/data/pda/app/emergency_call
	name = "Экстренный вызов"
	icon = "phone-volume"
	template = "pda_emergency_call"
	var/static/list/services = list(
		"medical" = list("name" = "Парамедик", "summon" = "парамедика", "icon" = "user-md", "freq" = MED_FREQ),
		"security" = list("name" = "Служба безопасности", "summon" = "службу безопасности", "icon" = "shield-alt", "freq" = SEC_FREQ),
	)
	var/pending_service
	var/pending_reason
	var/pending_timer
	COOLDOWN_DECLARE(call_cooldown)

/datum/data/pda/app/emergency_call/Destroy()
	deltimer(pending_timer)
	return ..()

/datum/data/pda/app/emergency_call/update_ui(mob/user, list/data)
	var/list/service_list = list()
	for(var/service_id in services)
		var/list/service = services[service_id]
		service_list += list(list("id" = service_id, "name" = service["name"], "icon" = service["icon"]))
	data["services"] = service_list
	data["reason_length"] = EMERGENCY_CALL_REASON_LENGTH
	data["pending"] = pending_service ? services[pending_service]["name"] : null
	data["pending_left"] = pending_timer ? ceil(timeleft(pending_timer) / (1 SECONDS)) : 0
	data["cooldown"] = COOLDOWN_FINISHED(src, call_cooldown) ? null : DisplayTimeText(COOLDOWN_TIMELEFT(src, call_cooldown), 1)

/datum/data/pda/app/emergency_call/ui_act(action, list/params)
	switch(action)
		if("call")
			if(pending_service || !COOLDOWN_FINISHED(src, call_cooldown))
				return
			var/service_id = params["service"]
			if(!services[service_id])
				return
			pending_service = service_id
			pending_reason = trim(sanitize(copytext_char(params["reason"], 1, EMERGENCY_CALL_REASON_LENGTH + 1)))
			pending_timer = addtimer(CALLBACK(src, PROC_REF(send_call), key_name_log(usr)), EMERGENCY_CALL_DELAY, TIMER_STOPPABLE)
			pda.balloon_alert(usr, "вызов через 5 секунд")
			return TRUE
		if("cancel")
			if(!pending_service)
				return
			deltimer(pending_timer)
			pending_timer = null
			pending_service = null
			pending_reason = null
			pda.balloon_alert(usr, "вызов отменён")
			return TRUE

/datum/data/pda/app/emergency_call/proc/send_call(requester_key)
	var/service_id = pending_service
	var/list/service = services[service_id]
	var/reason = pending_reason
	pending_timer = null
	pending_service = null
	pending_reason = null

	var/turf/location = get_turf(pda)
	if(!location)
		notify("Вызов не отправлен: нет связи.", blink = FALSE)
		SStgui.update_uis(pda)
		return

	COOLDOWN_START(src, call_cooldown, EMERGENCY_CALL_COOLDOWN)
	var/requester_name = pda.owner ? "[pda.owner][pda.ownjob ? " ([pda.ownjob])" : ""]" : "Неизвестный"
	var/message = "[requester_name] вызывает [service["summon"]]. Местоположение: [get_area_name(location, TRUE)] ([location.x], [location.y], [location.z])."
	if(reason)
		message += " Причина: [reason]"
	radio_announce(message, "Экстренный вызов КПК", service["freq"], pda)
	notify("Вызов передан в канал отдела: [service["name"]].", blink = FALSE)
	log_game("[requester_key] sent a PDA emergency call to [service_id] from [AREACOORD(location)]. Reason: [reason || "none"]")
	SStgui.update_uis(pda)

#undef EMERGENCY_CALL_DELAY
#undef EMERGENCY_CALL_COOLDOWN
#undef EMERGENCY_CALL_REASON_LENGTH
