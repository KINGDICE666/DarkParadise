#define MATERIAL_MARKET_MAX_STACKS 10
#define MATERIAL_MARKET_PRIVATE_MARKUP 1.1

/datum/material_market_order
	var/datum/money_account/paying_account
	var/orderer_name
	var/private = FALSE
	var/list/sheets = list()
	var/cost = 0
	var/markup = 0

/datum/material_market_order/Destroy(force)
	paying_account = null
	return ..()

/datum/material_market_order/proc/total_stacks()
	. = 0
	for(var/sheet_type in sheets)
		. += ROUND_UP(sheets[sheet_type] / MAX_STACK_SIZE)

/datum/material_market_order/proc/refund()
	if(cost)
		paying_account.credit(cost, "Возврат за отменённый заказ материалов", "Галактическая биржа материалов", paying_account.owner_name)
	for(var/sheet_type in sheets)
		for(var/material_id in SSstock_market.materials_prices)
			if(SSstock_market.get_sheet_type(material_id) == sheet_type)
				SSstock_market.adjust_material_quantity(material_id, sheets[sheet_type])

/datum/material_market_order/proc/deliver(turf/destination)
	var/obj/structure/closet/crate/crate = new(destination)
	crate.name = "material order ([orderer_name])"
	crate.ru_names = alist(
		NOMINATIVE = "ящик с биржевым заказом ([orderer_name])",
		GENITIVE = "ящика с биржевым заказом ([orderer_name])",
		DATIVE = "ящику с биржевым заказом ([orderer_name])",
		ACCUSATIVE = "ящик с биржевым заказом ([orderer_name])",
		INSTRUMENTAL = "ящиком с биржевым заказом ([orderer_name])",
		PREPOSITIONAL = "ящике с биржевым заказом ([orderer_name])",
	)
	if(private)
		crate.AddComponent(/datum/component/locked_to_account, paying_account)
	for(var/sheet_type in sheets)
		var/remaining = sheets[sheet_type]
		while(remaining > 0)
			var/amount = min(remaining, MAX_STACK_SIZE)
			new sheet_type(crate, amount)
			remaining -= amount
	crate.update_appearance()
	if(markup)
		SSshuttle.cargo_money_account.credit(markup, "Наценка за личный заказ материалов", "Галактическая биржа материалов", SSshuttle.cargo_money_account.owner_name)
	paying_account.notify_pda_owner("<b>Доставка груза </b>\"Шаттл снабжения доставил заказ с галактической биржи материалов.\" (Невозможно Ответить)")

/obj/machinery/materials_market
	name = "galactic materials market"
	desc = "Терминал галактической биржи. Здесь можно купить листы материалов по текущему курсу или сдать свои и зафиксировать цену в биржевом блоке. Курс меняется каждую минуту."
	icon = 'icons/obj/machines/materials_market.dmi'
	icon_state = "mat_market"
	density = TRUE
	anchored = TRUE
	idle_power_usage = 50
	active_power_usage = 500
	var/ordering_private = TRUE

/obj/machinery/materials_market/get_ru_names()
	return alist(
		NOMINATIVE = "терминал биржи материалов",
		GENITIVE = "терминала биржи материалов",
		DATIVE = "терминалу биржи материалов",
		ACCUSATIVE = "терминал биржи материалов",
		INSTRUMENTAL = "терминалом биржи материалов",
		PREPOSITIONAL = "терминале биржи материалов",
	)

/obj/machinery/materials_market/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/materials_market(null)
	component_parts += new /obj/item/stock_parts/scanning_module(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)
	component_parts += new /obj/item/stack/sheet/glass(null, 1)
	RefreshParts()

/obj/machinery/materials_market/update_icon_state()
	if(panel_open)
		icon_state = "mat_market_open"
		return
	if((stat & (NOPOWER|BROKEN)) || !anchored)
		icon_state = "mat_market_off"
		return
	icon_state = "mat_market"

/obj/machinery/materials_market/power_change(forced = FALSE)
	. = ..()
	if(.)
		update_icon(UPDATE_ICON_STATE)

/obj/machinery/materials_market/wrench_act(mob/living/user, obj/item/tool)
	. = TRUE
	default_unfasten_wrench(user, tool, 1.5 SECONDS)
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/materials_market/screwdriver_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(!tool.tool_use_check(user, 0))
		return
	default_deconstruction_screwdriver(user, "mat_market_open", "mat_market", tool)

/obj/machinery/materials_market/crowbar_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(!tool.tool_use_check(user, 0))
		return
	default_deconstruction_crowbar(user, tool)

/obj/machinery/materials_market/attack_hand(mob/user)
	if(..())
		return TRUE
	ui_interact(user)

/obj/machinery/materials_market/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!isstack(tool))
		return ..()
	if((stat & (NOPOWER|BROKEN)) || !anchored)
		balloon_alert(user, "терминал не работает!")
		return ITEM_INTERACT_BLOCKING
	var/obj/item/stack/stack = tool
	if(length(stack.materials) != 1)
		balloon_alert(user, "сплавы не принимаются!")
		return ITEM_INTERACT_BLOCKING
	var/material_id = stack.materials[1]
	var/price = SSstock_market.get_price(material_id)
	if(!price || istype(stack, /obj/item/stack/ore))
		balloon_alert(user, "биржа это не покупает!")
		return ITEM_INTERACT_BLOCKING
	var/sheets = stack.materials[material_id] * stack.amount / MINERAL_MATERIAL_AMOUNT
	if(!user.drop_transfer_item_to_loc(stack, src))
		return ITEM_INTERACT_BLOCKING
	var/obj/item/stock_block/new_block = new(drop_location(), material_id, sheets, price)
	to_chat(user, span_notice("Создан биржевой блок стоимостью [round(new_block.get_value())] кр. Продайте его, пока цена не стала плавающей!"))
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
	qdel(stack)
	use_power(active_power_usage)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/materials_market/proc/find_order(datum/money_account/account, is_ordering_private)
	for(var/datum/material_market_order/order as anything in SSshuttle.material_orders)
		if(order.private == is_ordering_private && order.paying_account == account)
			return order

/obj/machinery/materials_market/proc/get_buyer_info(mob/user)
	var/obj/item/card/id/card = user.get_id_card()
	if(!card)
		return null
	var/can_buy_via_budget = (ACCESS_CARGO in card.GetAccess())
	var/is_ordering_private = ordering_private || !can_buy_via_budget
	var/datum/money_account/account = is_ordering_private ? get_account_from_card(card) : GLOB.department_accounts[STATION_DEPARTMENT_SUPPLY]
	return list("account" = account, "private" = is_ordering_private, "cargo" = can_buy_via_budget)

/obj/machinery/materials_market/ui_interact(mob/user, datum/tgui/ui)
	if(!anchored)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MatMarket", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/materials_market/ui_data(mob/user)
	var/list/data = list()
	var/list/buyer = get_buyer_info(user)
	var/datum/money_account/account = buyer?["account"]
	var/datum/material_market_order/current_order = account ? find_order(account, buyer["private"]) : null

	var/list/material_data = list()
	for(var/material_id in SSstock_market.materials_prices)
		var/sheet_type = SSstock_market.get_sheet_type(material_id)
		if(!sheet_type)
			continue
		var/elastic = 100
		for(var/datum/export/material/export in GLOB.exports_list)
			if(export.material_id == material_id && export.sales_market == EXPORT_MARKET_STATION)
				elastic = export.k_elasticity * 100
				break
		material_data += list(list(
			"id" = material_id,
			"name" = SSstock_market.get_material_name(material_id),
			"price" = round(SSstock_market.get_price(material_id), 0.01),
			"base_price" = SSstock_market.base_prices[material_id],
			"min_threshold" = SSstock_market.price_minimum(material_id),
			"max_threshold" = SSstock_market.price_maximum(material_id),
			"quantity" = SSstock_market.materials_quantity[material_id],
			"trend" = SSstock_market.materials_trends[material_id],
			"requested" = current_order ? current_order.sheets[sheet_type] || 0 : 0,
			"elastic" = elastic,
		))
	data["materials"] = material_data
	data["hasId"] = !!buyer
	data["creditBalance"] = account?.money || 0
	data["orderBalance"] = current_order?.cost || 0
	data["orderingPrivate"] = buyer ? buyer["private"] : TRUE
	data["canOrderCargo"] = buyer ? buyer["cargo"] : FALSE
	data["privateMarkup"] = MATERIAL_MARKET_PRIVATE_MARKUP
	data["crateFee"] = CARGO_CRATE_REFUND
	data["updateTime"] = max(SSstock_market.next_fire - world.time, 0)
	return data

/obj/machinery/materials_market/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(stat & (NOPOWER|BROKEN))
		return
	var/mob/user = ui.user
	var/list/buyer = get_buyer_info(user)
	if(!buyer)
		atom_say("ID-карта не обнаружена.")
		return
	var/datum/money_account/account = buyer["account"]
	var/is_ordering_private = buyer["private"]
	switch(action)
		if("toggle_budget")
			if(!buyer["cargo"])
				return
			ordering_private = !ordering_private
			return TRUE
		if("clear")
			var/datum/material_market_order/order = account ? find_order(account, is_ordering_private) : null
			if(!order)
				return
			order.refund()
			SSshuttle.material_orders -= order
			qdel(order)
			return TRUE
		if("buy")
			if(!account)
				atom_say("Счёт не найден.")
				return
			var/material_id = params["material"]
			var/quantity = text2num(params["quantity"])
			if(!(material_id in SSstock_market.materials_prices) || !(quantity in list(1, 5, 10, 25, 50)))
				return
			var/sheet_type = SSstock_market.get_sheet_type(material_id)
			if(!sheet_type)
				return
			if(quantity > SSstock_market.materials_quantity[material_id])
				atom_say("На бирже недостаточно материала.")
				return
			var/datum/material_market_order/order = find_order(account, is_ordering_private)
			if(order && order.total_stacks() + ROUND_UP(quantity / MAX_STACK_SIZE) > MATERIAL_MARKET_MAX_STACKS)
				atom_say("В заказе уже [MATERIAL_MARKET_MAX_STACKS] стопок. Дождитесь доставки.")
				return
			var/base_cost = ROUND_UP(SSstock_market.get_price(material_id) * quantity)
			var/markup = is_ordering_private ? ROUND_UP(base_cost * (MATERIAL_MARKET_PRIVATE_MARKUP - 1)) : 0
			var/cost = base_cost + markup
			if(!order)
				cost += CARGO_CRATE_REFUND
			if(account.money < cost || !account.charge(cost, null, "Покупка на галактической бирже материалов", "Галактическая биржа материалов", "Галактическая биржа материалов"))
				atom_say("Недостаточно средств.")
				return
			SScapitalism.add_audit_entry(account, cost, "Галактическая биржа материалов")
			if(!order)
				order = new
				order.paying_account = account
				order.private = is_ordering_private
				order.orderer_name = user.name
				SSshuttle.material_orders += order
			order.sheets[sheet_type] += quantity
			order.cost += cost
			order.markup += markup
			SSstock_market.on_material_bought(material_id, quantity)
			playsound(src, 'sound/machines/ping.ogg', 30, FALSE)
			return TRUE

/obj/item/circuitboard/materials_market
	board_name = "Galactic Materials Market"
	build_path = /obj/machinery/materials_market
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_SUPPLY
	origin_tech = "programming=2;materials=2"
	req_components = list(
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stack/sheet/glass = 1,
	)

/obj/item/stock_block
	name = "stock block"
	desc = "Биржевой блок, обеспеченный сданными на бирже материалами. Отправьте его шаттлом снабжения, чтобы получить деньги."
	icon = 'icons/obj/machines/materials_market.dmi'
	icon_state = "stock_block"
	w_class = WEIGHT_CLASS_SMALL
	var/material_id
	var/sheets = 0
	var/export_value = 0
	var/warned = FALSE
	var/fluid = FALSE

/obj/item/stock_block/get_ru_names()
	return alist(
		NOMINATIVE = "биржевой блок",
		GENITIVE = "биржевого блока",
		DATIVE = "биржевому блоку",
		ACCUSATIVE = "биржевой блок",
		INSTRUMENTAL = "биржевым блоком",
		PREPOSITIONAL = "биржевом блоке",
	)

/obj/item/stock_block/Initialize(mapload, material_id, sheets, export_value)
	. = ..()
	src.material_id = material_id
	src.sheets = sheets
	src.export_value = export_value
	addtimer(CALLBACK(src, PROC_REF(value_warning)), 1.5 MINUTES, TIMER_DELETE_ME)
	addtimer(CALLBACK(src, PROC_REF(become_liquid)), 3 MINUTES, TIMER_DELETE_ME)

/obj/item/stock_block/examine(mob/user)
	. = ..()
	if(fluid)
		. += span_warning("Цена блока плавающая и следует за биржевым курсом.")
	else
		. += span_notice("Цена блока пока <b>зафиксирована</b>. Продайте его, пока она не стала плавающей!")
	. += span_notice("Стоимость: [round(get_value())] кр. за [round(sheets, 0.1)] лист. ([SSstock_market.get_material_name(material_id)]).")

/obj/item/stock_block/update_icon_state()
	if(fluid)
		icon_state = "stock_block_liquid"
	else if(warned)
		icon_state = "stock_block_fluid"
	else
		icon_state = initial(icon_state)

/obj/item/stock_block/proc/get_value()
	return sheets * (fluid ? SSstock_market.get_price(material_id) : export_value)

/obj/item/stock_block/proc/value_warning()
	warned = TRUE
	update_icon(UPDATE_ICON_STATE)
	visible_message(span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] начинает терять фиксированную цену!"))

/obj/item/stock_block/proc/become_liquid()
	fluid = TRUE
	update_icon(UPDATE_ICON_STATE)
	visible_message(span_warning("Цена [declent_ru(GENITIVE)] стала плавающей!"))

/datum/export/stock_block
	unit_name = "биржевые блоки"
	k_elasticity = 0
	export_types = list(/obj/item/stock_block)

/datum/export/stock_block/get_base_cost(obj/item/stock_block/block)
	return block.get_value()

/datum/export/stock_block/sell_object(obj/item/stock_block/block, datum/export_report/report, dry_run, apply_elastic)
	. = ..()
	if(!. || dry_run)
		return
	SSstock_market.on_material_sold(block.material_id, block.sheets)

#undef MATERIAL_MARKET_MAX_STACKS
#undef MATERIAL_MARKET_PRIVATE_MARKUP
