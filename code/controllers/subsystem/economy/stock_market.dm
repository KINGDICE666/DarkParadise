SUBSYSTEM_DEF(stock_market)
	name = "Stock Market"
	wait = 1 MINUTES
	runlevels = RUNLEVEL_GAME
	ss_flags = SS_BACKGROUND | SS_KEEP_TIMING

	var/static/list/base_prices = list(
		MAT_METAL = 2,
		MAT_GLASS = 2,
		MAT_PLASTIC = 10,
		MAT_PLASMA = 25,
		MAT_SILVER = 40,
		MAT_TITANIUM = 40,
		MAT_URANIUM = 50,
		MAT_GOLD = 60,
		MAT_DIAMOND = 150,
		MAT_BLUESPACE = 200,
		MAT_BANANIUM = 300,
		MAT_TRANQUILLITE = 300,
	)
	var/static/list/base_quantities = list(
		MAT_METAL = 1000,
		MAT_GLASS = 1000,
		MAT_PLASTIC = 500,
		MAT_PLASMA = 300,
		MAT_SILVER = 200,
		MAT_TITANIUM = 200,
		MAT_URANIUM = 150,
		MAT_GOLD = 150,
		MAT_DIAMOND = 50,
		MAT_BLUESPACE = 30,
		MAT_BANANIUM = 20,
		MAT_TRANQUILLITE = 20,
	)
	var/list/materials_prices = list()
	var/list/materials_trends = list()
	var/list/materials_trend_life = list()
	var/list/materials_quantity = list()
	var/list/active_events = list()
	var/list/pending_news = list()

/datum/controller/subsystem/stock_market/Initialize()
	for(var/material_id in base_prices)
		materials_prices[material_id] = base_prices[material_id]
		materials_trends[material_id] = rand(MARKET_TREND_DOWNWARD, MARKET_TREND_UPWARD)
		materials_trend_life[material_id] = rand(1, 3)
		var/base_quantity = base_quantities[material_id]
		materials_quantity[material_id] = round(base_quantity + rand(-base_quantity * 0.5, base_quantity * 0.5))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/stock_market/fire(resumed)
	for(var/material_id in materials_prices)
		handle_trends_and_price(material_id)
	for(var/datum/stock_market_event/event as anything in active_events)
		event.handle()
	publish_news()

/datum/controller/subsystem/stock_market/proc/get_price(material_id)
	return materials_prices[material_id] || 0

/datum/controller/subsystem/stock_market/proc/price_minimum(material_id)
	return base_prices[material_id] * MARKET_PRICE_MIN_MULT

/datum/controller/subsystem/stock_market/proc/price_maximum(material_id)
	return base_prices[material_id] * MARKET_PRICE_MAX_MULT

/datum/controller/subsystem/stock_market/proc/adjust_material_price(material_id, delta)
	if(!(material_id in materials_prices))
		return
	materials_prices[material_id] = clamp(materials_prices[material_id] + delta, price_minimum(material_id), price_maximum(material_id))

/datum/controller/subsystem/stock_market/proc/adjust_material_quantity(material_id, delta)
	if(!(material_id in materials_quantity))
		return
	materials_quantity[material_id] = round(clamp(materials_quantity[material_id] + delta, 0, base_quantities[material_id] * 2))

/datum/controller/subsystem/stock_market/proc/on_material_sold(material_id, sheets)
	if(!(material_id in materials_prices) || sheets <= 0)
		return
	adjust_material_price(material_id, -materials_prices[material_id] * (sheets / (sheets + materials_quantity[material_id] + 1)))
	adjust_material_quantity(material_id, sheets)

/datum/controller/subsystem/stock_market/proc/on_material_bought(material_id, sheets)
	if(!(material_id in materials_prices) || sheets <= 0)
		return
	adjust_material_quantity(material_id, -sheets)

/datum/controller/subsystem/stock_market/proc/handle_trends_and_price(material_id)
	if(prob(MARKET_EVENT_PROBABILITY))
		handle_market_event(material_id)

	var/price = materials_prices[material_id]
	var/price_baseline = base_prices[material_id]
	var/price_min = price_minimum(material_id)
	var/price_max = price_maximum(material_id)
	var/quantity_baseline = base_quantities[material_id]

	if(materials_trend_life[material_id] <= 0)
		if(price < price_baseline)
			var/chance_swap = 100 - (max(price - price_min, 0) / (price_baseline - price_min)) * 100
			materials_trends[material_id] = prob(chance_swap) ? MARKET_TREND_UPWARD : MARKET_TREND_STABLE
		else if(price > price_baseline)
			var/chance_swap = (price - price_baseline) / (price_max - price_baseline) * 100
			materials_trends[material_id] = prob(chance_swap) ? MARKET_TREND_DOWNWARD : MARKET_TREND_STABLE
		else
			materials_trends[material_id] = rand(MARKET_TREND_DOWNWARD, MARKET_TREND_UPWARD)
		materials_trend_life[material_id] = rand(1, 3)
	else
		materials_trend_life[material_id]--

	var/price_change = 0
	var/quantity_change = 0
	switch(materials_trends[material_id])
		if(MARKET_TREND_UPWARD)
			price_change = abs(gaussian(price * 0.1, price_baseline * 0.05))
			quantity_change = -round(abs(gaussian(quantity_baseline * 0.1, quantity_baseline * 0.05)))
		if(MARKET_TREND_STABLE)
			price_change = gaussian(0, price_baseline * 0.01)
			quantity_change = round(gaussian(0, quantity_baseline * 0.1))
		if(MARKET_TREND_DOWNWARD)
			price_change = -abs(gaussian(price * 0.1, price_baseline * 0.05))
			quantity_change = round(abs(gaussian(quantity_baseline * 0.1, quantity_baseline * 0.05)))
	adjust_material_price(material_id, price_change)
	adjust_material_quantity(material_id, quantity_change)

/datum/controller/subsystem/stock_market/proc/handle_market_event(material_id)
	for(var/datum/stock_market_event/event as anything in active_events)
		if(event.material_id == material_id)
			return
	var/event_type = pick(subtypesof(/datum/stock_market_event))
	var/datum/stock_market_event/event = new event_type
	if(event.start_event(material_id))
		active_events += event
	else
		qdel(event)

/datum/controller/subsystem/stock_market/proc/publish_news()
	if(!length(pending_news))
		return
	var/datum/feed_message/report = new
	report.author = EDITOR_NYX
	report.admin_locked = TRUE
	report.body = "Галактическая биржа материалов. [jointext(pending_news, " ")]"
	pending_news.Cut()
	GLOB.news_network.get_channel_by_name(NEWS_CHANNEL_NYX)?.add_message(report)

/datum/controller/subsystem/stock_market/proc/get_material_name(material_id)
	var/static/list/material_names
	if(!material_names)
		material_names = list()
		for(var/datum/material/material as anything in subtypesof(/datum/material))
			material_names[material::id] = material::name
	return material_names[material_id] || material_id

/datum/controller/subsystem/stock_market/proc/get_sheet_type(material_id)
	var/static/list/sheet_types
	if(!sheet_types)
		sheet_types = list()
		for(var/datum/material/material as anything in subtypesof(/datum/material))
			sheet_types[material::id] = material::sheet_type
	return sheet_types[material_id]
