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
