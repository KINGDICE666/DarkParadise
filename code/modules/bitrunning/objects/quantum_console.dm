#define RANDOM_DOMAIN_LABEL "Случайный домен"

/obj/machinery/computer/quantum_console
	name = "quantum console"
	desc = "Терминал управления квантовым сервером. Отсюда выбирают, во что нырять."
	icon_keyboard = "mining_key"
	icon_screen = "mining"
	circuit = /obj/item/circuitboard/quantum_console
	req_access = list(ACCESS_MINING)
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
		. += span_notice("Подключено битраннеров: [length(server.avatar_connection_refs)].")
		. += span_notice("Осталось выходов: [length(server.exit_turfs) - server.retries_spent].")
		return

	. += span_notice(server.is_ready ? "Сервер готов к загрузке домена." : "Сервер остывает.")

/obj/machinery/computer/quantum_console/attack_hand(mob/user)
	if(..())
		return TRUE

	INVOKE_ASYNC(src, PROC_REF(open_menu), user)

/obj/machinery/computer/quantum_console/proc/open_menu(mob/living/user)
	if(!allowed(user))
		balloon_alert(user, "доступ запрещён!")
		return

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		balloon_alert(user, "сервер не найден!")
		return

	if(server.generated_domain)
		if(tgui_alert(user, "Домен \"[server.generated_domain.name]\" запущен. Остановить его?", "Квантовая консоль", list("Остановить", "Отмена")) != "Остановить")
			return
		server.begin_shutdown(user)
		return

	if(!server.is_ready)
		balloon_alert(user, "сервер остывает!")
		return

	var/list/options = list()
	options[RANDOM_DOMAIN_LABEL] = RANDOM_DOMAIN_LABEL

	for(var/datum/lazy_template/virtual_domain/domain as anything in get_virtual_domains())
		if(domain.cost > server.points)
			continue

		var/label = domain.can_view_name(server.scanner_tier, server.points) ? domain.name : "Зашифрованный домен [domain.key]"
		if(domain.can_view_reward(server.scanner_tier, server.points))
			label += " (цена [domain.cost], награда [domain.reward_points])"

		options[label] = domain

	var/choice = tgui_input_list(user, "Какой домен собрать?", "Квантовая консоль", options)
	if(isnull(choice) || !Adjacent(user) || !is_operational())
		return

	var/picked = options[choice]
	if(picked == RANDOM_DOMAIN_LABEL)
		server.cold_boot_map(server.get_random_domain_id(), was_random_selection = TRUE)
		return

	var/datum/lazy_template/virtual_domain/chosen_domain = picked
	server.cold_boot_map(chosen_domain.key)

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

#undef RANDOM_DOMAIN_LABEL
