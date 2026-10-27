/obj/machinery/computer/quantum_console
	name = "quantum console"
	desc = "Терминал управления квантовым сервером. Отсюда выбирают, во что нырять."
	icon_keyboard = "mining_key"
	icon_screen = "mining"
	circuit = /obj/item/circuitboard/quantum_console
	req_access = list(ACCESS_BITRUNNING)
	var/datum/weakref/server_ref

/obj/machinery/computer/quantum_console/get_ru_names()
	return alist(
		NOMINATIVE = "квантовая консоль",
		GENITIVE = "квантовой консоли",
		DATIVE = "квантовой консоли",
		ACCUSATIVE = "квантовую консоль",
		INSTRUMENTAL = "квантовой консолью",
		PREPOSITIONAL = "квантовой консоли",
	)

/obj/machinery/computer/quantum_console/examine(mob/user)
	. = ..()
	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		. += span_warning("Консоль не подключена к серверу. Он должен стоять вплотную.")
		return

	. += span_notice("Накоплено очков: [server.points].")
	. += span_notice("Уровень сканера: [server.scanner_tier].")

	if(server.generated_domain)
		. += span_notice("Запущен домен: [server.generated_domain.name].")
		if(server.hardcore)
			. += span_userdanger("HRDM: награды удвоены. Смерть аватара убивает оператора в капсуле!")
		. += span_notice("Подключено битраннеров: [length(server.avatar_connection_refs)].")
		. += span_notice("Осталось выходов: [length(server.exit_turfs) - server.retries_spent].")
		return

	. += span_notice(server.is_ready ? "Сервер готов к загрузке домена." : "Сервер остывает.")

/obj/machinery/computer/quantum_console/attack_hand(mob/user)
	if(..())
		return TRUE

	if(!allowed(user))
		balloon_alert(user, "доступ запрещён!")
		playsound(src, SFX_BUTTON_DENIED, 20)
		return TRUE

	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/quantum_console/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "QuantumConsole", name)
		ui.open()

/obj/machinery/computer/quantum_console/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/disk/bitrunning_hardcore))
		return ..()

	if(!allowed(user) || !is_operational())
		balloon_alert(user, "доступ запрещён!")
		return ITEM_INTERACT_SUCCESS

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server) || !server.is_operational() || !server.is_ready)
		balloon_alert(user, "сервер недоступен!")
		return ITEM_INTERACT_SUCCESS

	if(server.hardcore || server.domain_entered || server.domain_complete || length(server.avatar_connection_refs))
		to_chat(user, span_warning("HRDM можно включить только один раз, до первого входа в домен."))
		return ITEM_INTERACT_SUCCESS

	var/datum/lazy_template/virtual_domain/chosen_domain = server.generated_domain
	if(isnull(chosen_domain))
		var/list/available = list()
		for(var/datum/lazy_template/virtual_domain/domain as anything in get_virtual_domains())
			if(domain.difficulty == BITRUNNER_DIFFICULTY_NONE || domain.cost > server.points)
				continue
			var/domain_name = domain.can_view_name(server.scanner_tier, server.points) ? domain.name : "Неизвестный домен [length(available) + 1]"
			available["[domain_name] ([domain.cost] очк.)"] = domain

		if(!length(available))
			to_chat(user, span_warning("У сервера недостаточно очков для загрузки боевого домена."))
			return ITEM_INTERACT_SUCCESS

		var/choice = tgui_input_list(user, "Выберите домен HRDM. Награды удвоены; смерть аватара убивает оператора в капсуле!", "Диск HRDM", available)
		chosen_domain = available[choice]
		if(isnull(chosen_domain))
			return ITEM_INTERACT_SUCCESS
	else if(chosen_domain.difficulty == BITRUNNER_DIFFICULTY_NONE)
		to_chat(user, span_warning("В мирном домене нельзя включить HRDM."))
		return ITEM_INTERACT_SUCCESS
	else if(tgui_alert(user, "Включить HRDM для домена «[chosen_domain.name]»? Награды удвоены; смерть аватара убивает оператора в капсуле!", "Диск HRDM", list("Включить", "Отмена")) != "Включить")
		return ITEM_INTERACT_SUCCESS

	if(QDELETED(src) || QDELETED(server) || QDELETED(tool) || !user.Adjacent(src) || !user.is_in_hands(tool) || user.incapacitated() || !allowed(user) || !is_operational())
		return ITEM_INTERACT_SUCCESS
	if(find_server() != server || !server.is_operational() || !server.is_ready || server.hardcore || server.domain_entered || server.domain_complete || length(server.avatar_connection_refs))
		return ITEM_INTERACT_SUCCESS
	if(server.generated_domain && server.generated_domain != chosen_domain)
		return ITEM_INTERACT_SUCCESS
	if(!user.drop_transfer_item_to_loc(tool, src))
		return ITEM_INTERACT_SUCCESS

	var/activated = server.generated_domain ? server.enable_hardcore() : server.cold_boot_map(chosen_domain.key, hardcore = TRUE)
	if(!activated)
		tool.forceMove(get_turf(src))
		user.put_in_hands(tool)
		return ITEM_INTERACT_SUCCESS

	qdel(tool)
	add_fingerprint(user)
	playsound(src, 'sound/machines/terminal_alert.ogg', 50, TRUE)
	to_chat(user, span_userdanger("HRDM активирован. Награды удвоены. Смерть аватара убивает оператора в капсуле!"))
	SStgui.update_uis(src)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/computer/quantum_console/ui_data(mob/user)
	var/list/data = list()

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		data["connected"] = FALSE
		return data

	data["connected"] = TRUE
	data["available_domains"] = get_available_domains(server.scanner_tier, server.points)
	data["broadcasting"] = server.broadcasting
	data["broadcasting_on_cd"] = !COOLDOWN_FINISHED(server, broadcast_toggle_cd)
	data["avatars"] = server.get_avatar_data()
	data["generated_domain"] = server.generated_domain?.key
	data["hardcore"] = server.hardcore
	data["occupants"] = length(server.avatar_connection_refs)
	data["points"] = server.points
	data["randomized"] = server.domain_randomized
	data["ready"] = server.is_ready && server.is_operational()
	data["retries_left"] = length(server.exit_turfs) - server.retries_spent
	data["scanner_tier"] = server.scanner_tier

	return data

/obj/machinery/computer/quantum_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	if(!allowed(usr))
		to_chat(usr, span_warning("Доступ запрещён."))
		playsound(src, SFX_BUTTON_DENIED, 20)
		return TRUE

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		return TRUE

	. = TRUE
	switch(action)
		if("random_domain")
			server.cold_boot_map(server.get_random_domain_id(), was_random_selection = TRUE)

		if("set_domain")
			server.cold_boot_map(params["id"])

		if("stop_domain")
			server.begin_shutdown(usr)

		if("broadcast")
			server.toggle_broadcast()

		else
			return FALSE

	add_fingerprint(usr)

/obj/machinery/computer/quantum_console/proc/find_server()
	var/obj/machinery/quantum_server/server = server_ref?.resolve()
	if(server)
		return server

	for(var/direction in GLOB.cardinal)
		server = locate(/obj/machinery/quantum_server) in get_step(src, direction)
		if(isnull(server))
			continue

		server_ref = WEAKREF(server)
		return server
