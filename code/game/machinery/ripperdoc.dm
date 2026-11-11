#define RIPPERDOC_BASE_TIME 5
#define RIPPERDOC_TIME_PER_COST 0.2
#define RIPPERDOC_CONSENT_TIMEOUT (15 SECONDS)

/obj/machinery/optable/ripperdoc
	name = "ripperdoc table"
	desc = "Операционный стол рипердока: хромированные фиксаторы, нейросканер и манипуляторы для установки, снятия и прошивки кибернетических имплантов. Внизу кто-то нацарапал \"хром не лечит душу\"."
	icon = 'icons/obj/machines/ripperdoc.dmi'
	icon_state = "ripperdoc-idle"
	req_access = list(ACCESS_ROBOTICS)
	light_range = 2
	light_power = 0.8
	light_color = "#FF3C46"
	var/obj/item/organ/internal/cyberimp/loaded
	var/busy = FALSE

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
	icon_state = "ripperdoc-[(patient?.pulse) ? "active" : "idle"]"

/obj/machinery/optable/ripperdoc/examine(mob/user)
	. = ..()
	if(loaded)
		. += span_notice("В лотке лежит [loaded.declent_ru(NOMINATIVE)]. Alt+клик, чтобы достать.")

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

/obj/machinery/optable/ripperdoc/proc/get_operation_time(obj/item/organ/internal/cyberimp/implant)
	return (RIPPERDOC_BASE_TIME + implant.cyber_cost * RIPPERDOC_TIME_PER_COST) SECONDS

/obj/machinery/optable/ripperdoc/proc/can_operate(mob/user)
	if(stat & (NOPOWER|BROKEN))
		balloon_alert(user, "нет питания!")
		return FALSE
	if(busy)
		balloon_alert(user, "идёт операция!")
		return FALSE
	if(!patient)
		balloon_alert(user, "нет пациента!")
		return FALSE
	if(!allowed(user))
		playsound(src, 'sound/machines/buzz-two.ogg', 40, TRUE)
		balloon_alert(user, "доступ запрещён!")
		return FALSE
	return TRUE

/obj/machinery/optable/ripperdoc/proc/install_loaded(mob/user)
	var/mob/living/carbon/target = patient
	var/obj/item/organ/internal/cyberimp/implant = loaded
	if(!implant || !can_operate(user))
		return
	if(!target.get_organ(check_zone(implant.parent_organ_zone)))
		balloon_alert(user, "нет нужной части тела!")
		return
	if(!implant.ignore_cybernetic_restrictions && HAS_TRAIT(target, TRAIT_NO_CYBERIMPLANTS))
		balloon_alert(user, "организм отторгает импланты!")
		return
	if(!implant.can_insert(user, target))
		return
	var/obj/item/organ/internal/replaced = target.get_organ_slot(implant.slot)
	if(replaced?.unremovable)
		balloon_alert(user, "слот занят намертво!")
		return

	busy = TRUE
	SStgui.update_uis(src)
	if(target.stat == CONSCIOUS && target.client)
		var/answer = tgui_alert(target, "[DECLENT_RU_CAP(implant, NOMINATIVE)] будет установлен вам рипердоком. Согласны?", "Установка импланта", list("Да", "Нет"), RIPPERDOC_CONSENT_TIMEOUT)
		if(answer != "Да")
			busy = FALSE
			balloon_alert(user, "пациент отказался!")
			SStgui.update_uis(src)
			return
	playsound(src, 'sound/surgery/surgicaldrill.ogg', 50, TRUE)
	target.visible_message(span_notice("Манипуляторы [declent_ru(GENITIVE)] вскрывают [target.declent_ru(ACCUSATIVE)] и подводят [implant.declent_ru(ACCUSATIVE)] к разъёму."))
	var/success = do_after(user, get_operation_time(implant), target)
	busy = FALSE
	if(!success || loaded != implant || patient != target)
		SStgui.update_uis(src)
		return

	loaded = null
	if(replaced)
		replaced.remove(target, ORGAN_MANIPULATION_NOEFFECT)
		replaced.forceMove(loc)
	implant.insert(target)
	target.update_icons()
	playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
	target.visible_message(span_notice("[DECLENT_RU_CAP(implant, NOMINATIVE)] щёлкает, входя в разъём, а манипуляторы [declent_ru(GENITIVE)] складываются."))
	add_attack_logs(user, target, "installed [implant] with a ripperdoc table, cyber load [target.get_cyber_load()]/[target.cyber_capacity]")
	SStgui.update_uis(src)

/obj/machinery/optable/ripperdoc/proc/extract_implant(mob/user, obj/item/organ/internal/cyberimp/implant)
	var/mob/living/carbon/target = patient
	if(!can_operate(user))
		return
	if(implant.owner != target || implant.unremovable)
		balloon_alert(user, "не извлечь!")
		return

	busy = TRUE
	SStgui.update_uis(src)
	playsound(src, 'sound/surgery/saw1.ogg', 50, TRUE)
	target.visible_message(span_notice("Манипуляторы [declent_ru(GENITIVE)] тянутся к [implant.declent_ru(DATIVE)] в теле [target.declent_ru(GENITIVE)]."))
	var/success = do_after(user, get_operation_time(implant), target)
	busy = FALSE
	if(!success || implant.owner != target || patient != target)
		SStgui.update_uis(src)
		return

	implant.remove(target)
	target.update_icons()
	if(loaded)
		implant.forceMove(loc)
	else
		implant.forceMove(src)
		loaded = implant
	playsound(src, 'sound/surgery/organ2.ogg', 50, TRUE)
	target.visible_message(span_notice("[DECLENT_RU_CAP(implant, NOMINATIVE)] с влажным щелчком выходит из разъёма."))
	add_attack_logs(user, target, "extracted [implant] with a ripperdoc table, cyber load [target.get_cyber_load()]/[target.cyber_capacity]")
	SStgui.update_uis(src)

/obj/machinery/optable/ripperdoc/proc/configure_implant(mob/user, obj/item/organ/internal/cyberimp/implant, setting_id, value)
	if(stat & (NOPOWER|BROKEN))
		balloon_alert(user, "нет питания!")
		return FALSE
	if(busy || !allowed(user))
		playsound(src, 'sound/machines/buzz-two.ogg', 40, TRUE)
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
	return TRUE

/obj/machinery/optable/ripperdoc/proc/find_implant(uid)
	var/obj/item/organ/internal/cyberimp/implant = locateUID(uid)
	if(!istype(implant))
		return null
	if(implant == loaded || (patient && implant.owner == patient && implant.is_robotic()))
		return implant
	return null

/obj/machinery/optable/ripperdoc/proc/get_implant_data(obj/item/organ/internal/cyberimp/implant)
	return list(
		"uid" = implant.UID(),
		"name" = DECLENT_RU_CAP(implant, NOMINATIVE),
		"desc" = implant.desc,
		"zone" = implant.parent_organ_zone,
		"cost" = implant.cyber_cost,
		"removable" = !implant.unremovable,
		"broken" = !!implant.crit_fail,
		"settings" = implant.get_ripper_settings(),
	)

/obj/machinery/optable/ripperdoc/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "RipperDoc", "RipperDoc")
	if(ui.open())
		playsound(src, 'sound/machines/terminal_on.ogg', 30, TRUE)

/obj/machinery/optable/ripperdoc/ui_static_data(mob/user)
	return list(
		"maxCapacity" = CYBER_CAPACITY_MAX,
		"baseCapacity" = CYBER_CAPACITY_BASE,
		"chipBonus" = CYBER_CAPACITY_CHIP_BONUS,
		"psychoStage" = CYBERPSYCHOSIS_STAGE_PSYCHO,
	)

/obj/machinery/optable/ripperdoc/ui_data(mob/user)
	var/list/data = list(
		"busy" = busy,
		"powered" = !(stat & (NOPOWER|BROKEN)),
		"hasAccess" = allowed(user),
		"patient" = null,
		"implants" = list(),
		"loaded" = null,
	)
	var/mob/living/carbon/target = patient
	var/load = target?.get_cyber_load()
	if(target)
		var/datum/status_effect/cyberpsychosis/psychosis = target.has_status_effect(/datum/status_effect/cyberpsychosis)
		data["patient"] = list(
			"name" = target.name,
			"capacity" = target.cyber_capacity,
			"load" = load,
			"neuroadapter" = !!target.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEUROADAPTER),
			"psychosisStage" = psychosis ? psychosis.stage : 0,
			"psychosisName" = psychosis?.get_stage_name(),
		)
		var/list/implants = list()
		for(var/obj/item/organ/internal/cyberimp/implant in target.internal_organs)
			if(implant.is_robotic())
				implants += list(get_implant_data(implant))
		data["implants"] = implants

	if(loaded)
		var/list/loaded_data = get_implant_data(loaded)
		if(target)
			var/obj/item/organ/internal/cyberimp/replaced = target.get_organ_slot(loaded.slot)
			var/freed = istype(replaced) ? replaced.cyber_cost : 0
			loaded_data["freed"] = freed
			loaded_data["replaces"] = replaced ? DECLENT_RU_CAP(replaced, NOMINATIVE) : null
			loaded_data["risk"] = get_cyberpsychosis_chance(load - freed + loaded.cyber_cost - target.cyber_capacity)
		data["loaded"] = loaded_data
	return data

/obj/machinery/optable/ripperdoc/ui_act(action, list/params)
	if(..())
		return
	if(usr == patient)
		return
	. = TRUE
	switch(action)
		if("install")
			INVOKE_ASYNC(src, PROC_REF(install_loaded), usr)
		if("extract")
			var/obj/item/organ/internal/cyberimp/implant = find_implant(params["uid"])
			if(!implant || implant == loaded)
				return FALSE
			INVOKE_ASYNC(src, PROC_REF(extract_implant), usr, implant)
		if("eject")
			if(!loaded || busy)
				return FALSE
			eject_loaded(usr)
		if("setting")
			var/obj/item/organ/internal/cyberimp/implant = find_implant(params["uid"])
			if(!implant)
				return FALSE
			if(configure_implant(usr, implant, params["id"], params["value"]))
				add_attack_logs(usr, implant.owner || src, "set [params["id"]] of [implant] to [params["value"]] with a ripperdoc table", ATKLOG_ALMOSTALL)
		else
			return FALSE
	add_fingerprint(usr)

#undef RIPPERDOC_BASE_TIME
#undef RIPPERDOC_TIME_PER_COST
#undef RIPPERDOC_CONSENT_TIMEOUT
