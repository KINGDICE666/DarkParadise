/obj/machinery/computer/helm/gunner
	name = "gunnery console"
	desc = "Пульт наводчика: радар и управление корабельными орудиями без доступа к штурвалу."
	icon_keyboard = "security_key"
	icon_screen = "cameras"
	light_color = LIGHT_COLOR_ORANGE
	circuit = /obj/item/circuitboard/helm/gunner

/obj/machinery/computer/helm/gunner/get_ru_names()
	return alist(
		NOMINATIVE = "консоль наводчика",
		GENITIVE = "консоли наводчика",
		DATIVE = "консоли наводчика",
		ACCUSATIVE = "консоль наводчика",
		INSTRUMENTAL = "консолью наводчика",
		PREPOSITIONAL = "консоли наводчика",
	)

/obj/machinery/computer/helm/gunner/claim_pilot(mob/user)
	return

/obj/machinery/computer/helm/gunner/ui_data(mob/user)
	. = ..()
	var/list/data = .
	data["gunner"] = TRUE

/obj/machinery/computer/helm/gunner/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(action in list("select_weapon", "weapon_auto", "helm_radar_reach", "relink", "toggle_shields", "lock_target", "clear_target", "fire_salvo", "toggle_free_fire"))
		return ..()
	if((action in list("radar_point", "set_dest")) && length(selected_weapons))
		return ..()
	return TRUE

/obj/item/circuitboard/helm/gunner
	board_name = "Gunnery Console"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/computer/helm/gunner
	origin_tech = "programming=3;combat=3"

/datum/design/gunnery_console
	name = "Console Board (Gunnery Console)"
	desc = "Плата консоли наводчика корабля."
	id = "gunnery_console"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/helm/gunner
	materials = list(MAT_GLASS = 1000)
	req_tech = list(RESEARCH_TREE_PROGRAMMING = 3, RESEARCH_TREE_COMBAT = 3)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_COMPUTER)

/obj/machinery/computer/helm/syndicate
	name = "syndicate helm control console"
	desc = "Штурвал синдикатского корабля. Управление огнём доступно только с допуском Синдиката."
	icon_keyboard = "syndie_key"
	icon_screen = "tcboss"
	light_color = LIGHT_COLOR_INTENSE_RED
	circuit = /obj/item/circuitboard/helm/syndicate
	fire_access = ACCESS_SYNDICATE

/obj/machinery/computer/helm/syndicate/get_ru_names()
	return alist(
		NOMINATIVE = "штурвал Синдиката",
		GENITIVE = "штурвала Синдиката",
		DATIVE = "штурвалу Синдиката",
		ACCUSATIVE = "штурвал Синдиката",
		INSTRUMENTAL = "штурвалом Синдиката",
		PREPOSITIONAL = "штурвале Синдиката",
	)

/obj/machinery/computer/helm/gunner/syndicate
	name = "syndicate gunnery console"
	desc = "Пульт наводчика синдикатского корабля. Работает только с допуском Синдиката."
	icon_keyboard = "syndie_key"
	icon_screen = "tcboss"
	light_color = LIGHT_COLOR_INTENSE_RED
	circuit = /obj/item/circuitboard/helm/gunner/syndicate
	fire_access = ACCESS_SYNDICATE

/obj/machinery/computer/helm/gunner/syndicate/get_ru_names()
	return alist(
		NOMINATIVE = "консоль наводчика Синдиката",
		GENITIVE = "консоли наводчика Синдиката",
		DATIVE = "консоли наводчика Синдиката",
		ACCUSATIVE = "консоль наводчика Синдиката",
		INSTRUMENTAL = "консолью наводчика Синдиката",
		PREPOSITIONAL = "консоли наводчика Синдиката",
	)

/obj/item/circuitboard/helm/syndicate
	board_name = "Syndicate Helm Console"
	build_path = /obj/machinery/computer/helm/syndicate

/obj/item/circuitboard/helm/gunner/syndicate
	board_name = "Syndicate Gunnery Console"
	build_path = /obj/machinery/computer/helm/gunner/syndicate
