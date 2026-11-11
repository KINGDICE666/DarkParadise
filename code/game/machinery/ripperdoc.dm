#define RIPPERDOC_LOG_LIMIT 6
#define RIPPERDOC_POWER_TIME (3 SECONDS)

/obj/machinery/optable/ripperdoc
	name = "ripperdoc table"
	desc = "Стол для калибровки кибернетики. Сканер в изголовье находит всё, что установлено в пациенте, а тонкие манипуляторы правят прошивку прямо в теле. Подголовник протёрт до металла: лежали здесь многие."
	icon = 'icons/obj/machines/ripperdoc.dmi'
	icon_state = "ripperdoc-idle"
	req_access = list(ACCESS_ROBOTICS)
	light_range = 2
	light_power = 0.8
	light_color = "#FF3C46"
	var/obj/item/organ/internal/cyberimp/loaded
	var/busy = FALSE
	var/operation_name
	var/operation_time = 0
	var/list/operation_log = list()
	var/static/list/power_access = list(ACCESS_SECURITY)
	var/static/list/encyclopedia_hidden = list(
		/obj/item/organ/internal/cyberimp/arm/janitorial/advanced,
		/obj/item/organ/internal/cyberimp/arm/katana,
		/obj/item/organ/internal/cyberimp/arm/surgery/adv/ert,
		/obj/item/organ/internal/cyberimp/arm/surgery/advanced,
		/obj/item/organ/internal/cyberimp/brain,
		/obj/item/organ/internal/cyberimp/brain/anti_drop/hardened,
		/obj/item/organ/internal/cyberimp/brain/anti_sleep/hardened,
		/obj/item/organ/internal/cyberimp/brain/anti_sleep/hardened/compatible,
		/obj/item/organ/internal/cyberimp/brain/anti_stun/hardened,
		/obj/item/organ/internal/cyberimp/chest/nutriment_old/plus/hardened,
		/obj/item/organ/internal/cyberimp/chest/reviver/hardened,
		/obj/item/organ/internal/cyberimp/eyes,
		/obj/item/organ/internal/cyberimp/eyes/hud,
		/obj/item/organ/internal/cyberimp/eyes/map/ert,
		/obj/item/organ/internal/cyberimp/eyes/map/nuke,
		/obj/item/organ/internal/cyberimp/leg,
		/obj/item/organ/internal/cyberimp/mouth,
		/obj/item/organ/internal/cyberimp/tail,
		/obj/item/organ/internal/cyberimp/tail/blade/laser/syndi,
	)

/obj/machinery/optable/ripperdoc/security
	req_access = list(ACCESS_SECURITY)

/obj/machinery/optable/ripperdoc/get_ru_names()
	return alist(
		NOMINATIVE = "стол рипердока",
		GENITIVE = "стола рипердока",
		DATIVE = "столу рипердока",
		ACCUSATIVE = "стол рипердока",
		INSTRUMENTAL = "столом рипердока",
		PREPOSITIONAL = "столе рипердока",
	)

/obj/machinery/optable/ripperdoc/Destroy()
	loaded?.forceMove(loc)
	loaded = null
	return ..()

/obj/machinery/optable/ripperdoc/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == loaded)
		loaded = null
		SStgui.update_uis(src)

/obj/machinery/optable/ripperdoc/update_icon_state()
	if(busy)
		icon_state = "ripperdoc-operating"
		return
	icon_state = "ripperdoc-[(patient?.pulse) ? "active" : "idle"]"

/obj/machinery/optable/ripperdoc/update_overlays()
	. = ..()
	if(stat & (NOPOWER|BROKEN))
		return
	. += emissive_appearance(icon, "ripperdoc-emissive", src)

/obj/machinery/optable/ripperdoc/power_change(forced = FALSE)
	. = ..()
	update_icon(UPDATE_OVERLAYS)
	set_light_on(!(stat & (NOPOWER|BROKEN)))

/obj/machinery/optable/ripperdoc/examine(mob/user)
	. = ..()
	if(loaded)
		. += span_notice("В лотке лежит [loaded.declent_ru(NOMINATIVE)]. Alt+клик, чтобы забрать.")

/obj/machinery/optable/ripperdoc/attack_hand(mob/user)
	if(..())
		return TRUE
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/optable/ripperdoc/attack_ghost(mob/user)
	ui_interact(user)

/obj/machinery/optable/ripperdoc/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM || !istype(I, /obj/item/organ/internal/cyberimp))
		return ..()
	add_fingerprint(user)
	if(loaded)
		balloon_alert(user, "лоток занят!")
		return ATTACK_CHAIN_BLOCKED_ALL
	if(!user.drop_transfer_item_to_loc(I, src))
		return ATTACK_CHAIN_BLOCKED_ALL
	loaded = I
	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 40, TRUE)
	playsound(src, 'sound/machines/ripperdoc/scan.ogg', 35, TRUE)
	log_operation("В лоток: [loaded.declent_ru(NOMINATIVE)]")
	balloon_alert(user, "имплант в лотке")
	SStgui.update_uis(src)
	return ATTACK_CHAIN_BLOCKED_ALL

/obj/machinery/optable/ripperdoc/click_alt(mob/user)
	if(!loaded || busy)
		return CLICK_ACTION_BLOCKING
	eject_loaded(user)
	return CLICK_ACTION_SUCCESS

/obj/machinery/optable/ripperdoc/proc/eject_loaded(mob/user)
	var/obj/item/organ/internal/cyberimp/implant = loaded
	loaded = null
	implant.forceMove(loc)
	user?.put_in_hands(implant)
	playsound(src, 'sound/machines/terminal_eject.ogg', 40, TRUE)
	SStgui.update_uis(src)

/obj/machinery/optable/ripperdoc/proc/set_busy(new_name, duration = 0)
	busy = !!new_name
	operation_name = new_name
	operation_time = duration
	update_icon(UPDATE_ICON_STATE)
	SStgui.update_uis(src)

/obj/machinery/optable/ripperdoc/proc/log_operation(text, bad = FALSE)
	operation_log += list(list("time" = station_time_timestamp("hh:mm"), "text" = text, "bad" = bad))
	if(length(operation_log) > RIPPERDOC_LOG_LIMIT)
		operation_log.Cut(1, 2)

/obj/machinery/optable/ripperdoc/proc/is_hidden(obj/item/organ/internal/cyberimp/implant)
	return !implant.is_robotic() || implant.is_contraband()

/obj/machinery/optable/ripperdoc/proc/can_configure(mob/user)
	if(stat & (NOPOWER|BROKEN))
		balloon_alert(user, "нет питания!")
		return FALSE
	if(busy)
		balloon_alert(user, "манипуляторы заняты!")
		return FALSE
	if(!allowed(user))
		playsound(src, 'sound/machines/buzz-two.ogg', 40, TRUE)
		balloon_alert(user, "доступ запрещён!")
		return FALSE
	return TRUE

/obj/machinery/optable/ripperdoc/proc/toggle_implant_power(mob/user, obj/item/organ/internal/cyberimp/implant)
	var/mob/living/carbon/target = patient
	if(!target || !can_configure(user))
		return
	if(!has_access(power_access, FALSE, user.get_access()))
		playsound(src, 'sound/machines/buzz-two.ogg', 40, TRUE)
		balloon_alert(user, "нужен доступ службы безопасности!")
		return
	var/waking = implant.blocked
	if(!waking && !implant.can_block())
		balloon_alert(user, "этот имплант не отключить!")
		return

	set_busy(waking ? "Включение: [implant.declent_ru(NOMINATIVE)]" : "Отключение: [implant.declent_ru(NOMINATIVE)]", RIPPERDOC_POWER_TIME)
	playsound(src, 'sound/machines/ripperdoc/servo.ogg', 45, TRUE)
	var/success = do_after(user, RIPPERDOC_POWER_TIME, target)
	set_busy(null)
	if(!success || patient != target)
		playsound(src, 'sound/machines/ripperdoc/glitch.ogg', 45, TRUE)
		log_operation("Манипуляторы отведены", bad = TRUE)
		return

	if(implant.owner != target)
		return
	implant.set_blocked(!waking)
	playsound(src, waking ? 'sound/machines/ripperdoc/install.ogg' : 'sound/machines/ripperdoc/extract.ogg', 50, TRUE)
	log_operation("[waking ? "Включён" : "Отключён"]: [implant.declent_ru(NOMINATIVE)]")
	add_attack_logs(user, target, "[waking ? "enabled" : "disabled"] [implant] with a ripperdoc table")
	SStgui.update_uis(src)

/obj/machinery/optable/ripperdoc/proc/configure_implant(mob/user, obj/item/organ/internal/cyberimp/implant, setting_id, value)
	if(!can_configure(user))
		return FALSE
	var/list/setting
	for(var/list/candidate as anything in implant.get_ripper_settings())
		if(candidate["id"] == setting_id)
			setting = candidate
			break
	if(!setting)
		return FALSE
	switch(setting["kind"])
		if("toggle")
			value = !!value
		if("choice", "color")
			if(!(value in setting["options"]))
				return FALSE
	if(!implant.set_ripper_setting(setting_id, value))
		balloon_alert(user, "не удалось!")
		return FALSE
	playsound(src, 'sound/machines/terminal_select.ogg', 40, TRUE)
	log_operation("Прошивка: [implant.declent_ru(NOMINATIVE)], [setting["name"]]")
	return TRUE

/obj/machinery/optable/ripperdoc/proc/find_implant(uid)
	var/obj/item/organ/internal/cyberimp/implant = locateUID(uid)
	if(!istype(implant) || is_hidden(implant))
		return null
	if(implant == loaded)
		return implant
	if(patient && implant.owner == patient)
		return implant
	return null

/obj/machinery/optable/ripperdoc/proc/get_implant_data(obj/item/organ/internal/cyberimp/implant)
	return list(
		"uid" = implant.UID(),
		"name" = DECLENT_RU_CAP(implant, NOMINATIVE),
		"desc" = implant.desc,
		"zone" = implant.parent_organ_zone,
		"cost" = implant.cyber_cost,
		"blocked" = implant.blocked,
		"canToggle" = implant.blocked || implant.can_block(),
		"broken" = !!implant.crit_fail,
		"settings" = implant.blocked ? list() : implant.get_ripper_settings(),
	)

/obj/machinery/optable/ripperdoc/proc/get_encyclopedia()
	var/static/list/entries
	if(entries)
		return entries
	entries = list()
	var/list/seen_names = list()
	for(var/implant_type in valid_subtypesof(/obj/item/organ/internal/cyberimp) - encyclopedia_hidden)
		var/obj/item/organ/internal/cyberimp/implant = new implant_type
		var/implant_name = DECLENT_RU_CAP(implant, NOMINATIVE)
		if(!is_hidden(implant) && !(implant_name in seen_names))
			seen_names += implant_name
			entries += list(list(
				"name" = implant_name,
				"desc" = implant.desc,
				"zone" = implant.parent_organ_zone,
				"cost" = implant.cyber_cost,
				"icon" = icon2base64(getFlatIcon(implant, no_anim = TRUE)),
			))
		qdel(implant)
	return entries

/obj/machinery/optable/ripperdoc/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "RipperDoc", "RipperDoc")
	if(ui.open())
		playsound(src, 'sound/machines/ripperdoc/boot.ogg', 35, TRUE)

/obj/machinery/optable/ripperdoc/ui_static_data(mob/user)
	return list(
		"maxCapacity" = CYBER_CAPACITY_MAX,
		"baseCapacity" = CYBER_CAPACITY_BASE,
		"chipBonus" = CYBER_CAPACITY_CHIP_BONUS,
		"encyclopedia" = get_encyclopedia(),
	)

/obj/machinery/optable/ripperdoc/ui_data(mob/user)
	var/list/data = list(
		"busy" = busy,
		"operation" = operation_name,
		"operationTime" = operation_time / (1 SECONDS),
		"log" = operation_log,
		"powered" = !(stat & (NOPOWER|BROKEN)),
		"hasAccess" = allowed(user),
		"canToggle" = has_access(power_access, FALSE, user.get_access()),
		"patient" = null,
		"implants" = list(),
		"loaded" = null,
	)
	var/mob/living/carbon/target = patient
	if(target)
		data["patient"] = list(
			"name" = target.name,
			"health" = round(target.health / target.maxHealth * 100),
			"stat" = target.stat,
			"capacity" = target.cyber_capacity,
			"load" = target.get_cyber_load(),
			"neuroadapter" = !!target.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEURO),
		)
		var/list/implants = list()
		for(var/obj/item/organ/internal/cyberimp/implant in target.internal_organs)
			if(!is_hidden(implant))
				implants += list(get_implant_data(implant))
		data["implants"] = implants

	if(loaded)
		data["loaded"] = is_hidden(loaded) ? list("uid" = null, "name" = "Неопознанный имплант", "hidden" = TRUE) : get_implant_data(loaded)
	return data

/obj/machinery/optable/ripperdoc/ui_act(action, list/params)
	if(..())
		return
	if(usr == patient)
		return
	. = TRUE
	switch(action)
		if("eject")
			if(!loaded || busy)
				return FALSE
			eject_loaded(usr)
		if("toggle_power")
			var/obj/item/organ/internal/cyberimp/implant = find_implant(params["uid"])
			if(!implant || implant == loaded)
				return FALSE
			INVOKE_ASYNC(src, PROC_REF(toggle_implant_power), usr, implant)
		if("setting")
			var/obj/item/organ/internal/cyberimp/implant = find_implant(params["uid"])
			if(!implant || implant.blocked)
				return FALSE
			if(configure_implant(usr, implant, params["id"], params["value"]))
				add_attack_logs(usr, implant.owner || src, "set [params["id"]] of [implant] to [params["value"]] with a ripperdoc table", ATKLOG_ALMOSTALL)
		else
			return FALSE
	add_fingerprint(usr)

#undef RIPPERDOC_LOG_LIMIT
#undef RIPPERDOC_POWER_TIME
