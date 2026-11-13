/obj/machinery/ship_gun_loader
	name = "ship gun loader"
	desc = "Автоматический зарядник. Хранит боеприпасы и по транспортной ленте подаёт их всем орудиям с тем же ID. ID задаётся мультитулом, как у дверей."
	icon = 'icons/obj/machines/sec_autolathe.dmi'
	icon_state = "autolathe"
	color = "#b8c8ff"
	anchored = TRUE
	density = TRUE
	max_integrity = 250
	use_power = NO_POWER_USE
	var/id
	var/list/stock = list()
	var/max_stock = OVERMAP_LOADER_CAPACITY

/obj/machinery/ship_gun_loader/get_ru_names()
	return alist(
		NOMINATIVE = "зарядник орудий",
		GENITIVE = "зарядника орудий",
		DATIVE = "заряднику орудий",
		ACCUSATIVE = "зарядник орудий",
		INSTRUMENTAL = "зарядником орудий",
		PREPOSITIONAL = "заряднике орудий",
	)

/obj/machinery/ship_gun_loader/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSmachines, src)

/obj/machinery/ship_gun_loader/proc/stored_rounds()
	. = 0
	for(var/ammo_type in stock)
		. += stock[ammo_type]

/obj/machinery/ship_gun_loader/proc/linked_guns()
	. = list()
	if(!id)
		return
	var/obj/overmap/entity/home = SSovermap.resolve_vessel(src)
	for(var/obj/machinery/ship_gun/gun as anything in GLOB.ship_guns)
		if(gun.loader_id == id && !QDELETED(gun) && SSovermap.resolve_vessel(gun) == home)
			. += gun

/obj/machinery/ship_gun_loader/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	if(!istype(used, /obj/item/ship_ammo))
		return ..()
	var/obj/item/ship_ammo/pack = used
	if(stored_rounds() + pack.rounds > max_stock)
		balloon_alert(user, "хранилище заполнено")
		return ITEM_INTERACT_BLOCKING
	stock[pack.type] += pack.rounds
	flick("autolathe_work", src)
	playsound(src, 'sound/weapons/gun_interactions/rifle_load.ogg', 40, TRUE)
	balloon_alert(user, "загружено")
	qdel(pack)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/ship_gun_loader/multitool_act(mob/living/user, obj/item/tool)
	. = TRUE
	var/new_id = tgui_input_text(user, "ID зарядника. Орудия с этим же ID будут получать от него боезапас.", "Настройка зарядника", id, max_length = MAX_NAME_LEN)
	if(isnull(new_id) || QDELETED(src) || !user.Adjacent(src))
		return
	id = new_id || null
	balloon_alert(user, id ? "ID задан" : "ID сброшен")

/obj/machinery/ship_gun_loader/wrench_act(mob/living/user, obj/item/tool)
	. = TRUE
	default_unfasten_wrench(user, tool)

/obj/machinery/ship_gun_loader/examine(mob/user)
	. = ..()
	. += span_notice("ID: [id || "не задан"]. Привязано орудий: [length(linked_guns())].")
	for(var/ammo_type in stock)
		var/obj/item/ship_ammo/sample = ammo_type
		if(stock[ammo_type])
			. += span_notice("[sample::name]: [stock[ammo_type]].")

/obj/machinery/ship_gun_loader/process()
	if(!anchored || (stat & BROKEN) || !id || !stored_rounds())
		return
	var/fed = FALSE
	for(var/obj/machinery/ship_gun/gun as anything in linked_guns())
		var/need = gun.max_ammo - gun.ammo
		if(need <= 0 || !stock[gun.ammo_type])
			continue
		var/given = min(need, stock[gun.ammo_type], OVERMAP_LOADER_FEED)
		stock[gun.ammo_type] -= given
		gun.ammo += given
		fed = TRUE
	if(fed)
		flick("autolathe_work", src)

/obj/item/circuitboard/ship_gun_loader
	board_name = "Ship gun loader"
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_SECURITY
	build_path = /obj/machinery/ship_gun_loader
	req_components = list(/obj/item/stock_parts/manipulator = 2, /obj/item/stock_parts/matter_bin = 3)

/datum/design/ship_gun_loader
	name = "Machine Board (Ship Gun Loader)"
	desc = "Плата зарядника корабельных орудий."
	id = "ship_gun_loader"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/ship_gun_loader
	materials = list(MAT_GLASS = 1000)
	req_tech = list(RESEARCH_TREE_COMBAT = 3, RESEARCH_TREE_ENGINEERING = 3)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_ENGINEERING)
