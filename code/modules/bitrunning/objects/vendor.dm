#define BITRUNNER_VENDOR_FLAIR "Flair"
#define BITRUNNER_VENDOR_GEAR "Gear"
#define BITRUNNER_VENDOR_PROGRAMS "Programs"

#define BITRUNNER_PRIZE(prize_name, object_type, price) prize_name = new /datum/data/mining_equipment(prize_name, object_type, price)

GLOBAL_LIST_INIT(bitrunner_vendor_items, list(
	BITRUNNER_VENDOR_FLAIR = list(
		BITRUNNER_PRIZE("Cornchips", /obj/item/reagent_containers/food/snacks/cornchips, 100),
		BITRUNNER_PRIZE("Space Mountain Wind", /obj/item/reagent_containers/food/drinks/cans/space_mountain_wind, 100),
		BITRUNNER_PRIZE("Thirteen Loko", /obj/item/reagent_containers/food/drinks/cans/thirteenloko, 200),
		BITRUNNER_PRIZE("Sunglasses", /obj/item/clothing/glasses/sunglasses, 1000),
		BITRUNNER_PRIZE("Brown Trenchcoat", /obj/item/clothing/suit/storage/browntrenchcoat, 1000),
		BITRUNNER_PRIZE("Jackboots", /obj/item/clothing/shoes/jackboots, 1000),
	),
	BITRUNNER_VENDOR_GEAR = list(
		BITRUNNER_PRIZE("Brute First-Aid Kit", /obj/item/storage/firstaid/brute, 500),
		BITRUNNER_PRIZE("Fire First-Aid Kit", /obj/item/storage/firstaid/fire, 500),
		BITRUNNER_PRIZE("Laser Pointer", /obj/item/laser_pointer, 750),
		BITRUNNER_PRIZE("Personal AI Device", /obj/item/paicard, 1500),
	),
	BITRUNNER_VENDOR_PROGRAMS = list(
		BITRUNNER_PRIZE("Simple Gear Program", /obj/item/disk/bitrunning/item/tier1, 750),
		BITRUNNER_PRIZE("Complex Gear Program", /obj/item/disk/bitrunning/item/tier2, 1250),
		BITRUNNER_PRIZE("Advanced Gear Program", /obj/item/disk/bitrunning/item/tier3, 2000),
		BITRUNNER_PRIZE("Basic Ability Program", /obj/item/disk/bitrunning/ability/tier1, 750),
		BITRUNNER_PRIZE("Complex Ability Program", /obj/item/disk/bitrunning/ability/tier2, 1500),
		BITRUNNER_PRIZE("Elite Ability Program", /obj/item/disk/bitrunning/ability/tier3, 2500),
	),
))

#undef BITRUNNER_PRIZE

/obj/machinery/bitrunner_vendor
	name = "bitrunner vendor"
	desc = "Раздатчик, торгующий скомпилированным барахлом. Принимает только очки битраннера."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "vendor"
	base_icon_state = "vendor"
	density = TRUE
	anchored = TRUE
	max_integrity = 300
	idle_power_usage = 100
	var/obj/item/card/id/inserted_id

/obj/machinery/bitrunner_vendor/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/bitrunner_vendor(null)
	component_parts += new /obj/item/stock_parts/matter_bin(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stack/cable_coil(null, 2)
	register_context()

/obj/machinery/bitrunner_vendor/Destroy()
	eject_id()
	return ..()

/obj/machinery/bitrunner_vendor/get_ru_names()
	return alist(
		NOMINATIVE = "раздатчик битраннера",
		GENITIVE = "раздатчика битраннера",
		DATIVE = "раздатчику битраннера",
		ACCUSATIVE = "раздатчик битраннера",
		INSTRUMENTAL = "раздатчиком битраннера",
		PREPOSITIONAL = "раздатчике битраннера",
	)

/obj/machinery/bitrunner_vendor/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	if(isnull(held_item))
		return

	if(is_id_card(held_item))
		context[SCREENTIP_CONTEXT_LMB] = "Вставить карту"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_LMB] = panel_open ? "Закрыть панель" : "Открыть панель"
		return CONTEXTUAL_SCREENTIP_SET

	if(held_item.tool_behaviour == TOOL_CROWBAR && panel_open)
		context[SCREENTIP_CONTEXT_LMB] = "Разобрать"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/bitrunner_vendor/examine(mob/user)
	. = ..()
	if(inserted_id)
		. += span_notice("Вставлена карта [inserted_id.registered_name], на счету [inserted_id.bitrunning_points] очков.")

/obj/machinery/bitrunner_vendor/update_icon_state()
	icon_state = is_operational() ? base_icon_state : "[base_icon_state]_off"

/obj/machinery/bitrunner_vendor/power_change(forced = FALSE)
	..()
	if(inserted_id && !is_operational())
		visible_message(span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] выплёвывает карту, теряя питание."))
		eject_id()
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/bitrunner_vendor/attack_hand(mob/user)
	if(..())
		return TRUE

	ui_interact(user)

/obj/machinery/bitrunner_vendor/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!is_id_card(tool))
		return ..()

	if(inserted_id)
		balloon_alert(user, "карта уже вставлена!")
		return ITEM_INTERACT_BLOCKING

	if(!user.drop_transfer_item_to_loc(tool, src))
		return ITEM_INTERACT_BLOCKING

	inserted_id = tool
	ui_interact(user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/bitrunner_vendor/screwdriver_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_screwdriver(user, base_icon_state, base_icon_state, tool))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/bitrunner_vendor/crowbar_act(mob/living/user, obj/item/tool)
	eject_id()
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/bitrunner_vendor/proc/eject_id(mob/user)
	if(isnull(inserted_id))
		return

	if(ishuman(user) && Adjacent(user))
		inserted_id.forceMove_turf()
		user.put_in_hands(inserted_id, ignore_anim = FALSE)
	else
		inserted_id.forceMove(drop_location())

	inserted_id = null

/obj/machinery/bitrunner_vendor/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MiningVendor", name)
		ui.open()

/obj/machinery/bitrunner_vendor/ui_data(mob/user)
	var/list/data = list()
	data["has_id"] = !isnull(inserted_id)
	if(inserted_id)
		data["id"] = list(
			"name" = inserted_id.registered_name,
			"points" = inserted_id.bitrunning_points,
		)

	return data

/obj/machinery/bitrunner_vendor/ui_static_data(mob/user)
	var/list/static_data = list()
	static_data["items"] = list()

	for(var/category in GLOB.bitrunner_vendor_items)
		var/list/category_items = list()
		for(var/prize_name in GLOB.bitrunner_vendor_items[category])
			var/datum/data/mining_equipment/prize = GLOB.bitrunner_vendor_items[category][prize_name]
			var/obj/item/prize_item = prize.equipment_path
			category_items[prize_name] = list(
				"name" = prize_name,
				"price" = prize.cost,
				"icon" = prize_item.icon,
				"icon_state" = prize_item.icon_state,
			)
		static_data["items"][category] = category_items

	return static_data

/obj/machinery/bitrunner_vendor/ui_act(action, params)
	if(..())
		return

	. = TRUE
	switch(action)
		if("logoff")
			eject_id(usr)

		if("purchase")
			if(isnull(inserted_id))
				return

			var/category = params["cat"]
			var/prize_name = params["name"]
			if(!(category in GLOB.bitrunner_vendor_items) || !(prize_name in GLOB.bitrunner_vendor_items[category]))
				return

			var/datum/data/mining_equipment/prize = GLOB.bitrunner_vendor_items[category][prize_name]
			if(prize.cost > inserted_id.bitrunning_points)
				balloon_alert(usr, "недостаточно очков!")
				return

			inserted_id.bitrunning_points -= prize.cost
			var/obj/purchase = new prize.equipment_path(drop_location())
			if(Adjacent(usr))
				usr.put_in_hands(purchase, ignore_anim = FALSE)

		else
			return FALSE

	add_fingerprint()

#undef BITRUNNER_VENDOR_FLAIR
#undef BITRUNNER_VENDOR_GEAR
#undef BITRUNNER_VENDOR_PROGRAMS
