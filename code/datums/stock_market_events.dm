/datum/stock_market_event
	var/static/list/company_names = list(
		"«Накамура Инжиниринг»",
		"«Робаст Индастриз»",
		"«Шелленберг и партнёры»",
		"Транс-Солнечная Федерация",
		"«Австраликус Майнинг»",
		"«Нанотрейзен-Дефорест»",
		"«Оружейная Аусек»",
		"«Дримленд Роботикс»",
		"Синдикат Кибериады",
		"Гильдия старателей Тау Кита",
	)
	var/list/circumstances = list()
	var/material_id
	var/trend_value
	var/trend_duration

/datum/stock_market_event/proc/start_event(material_id)
	src.material_id = material_id
	if(!isnull(trend_value))
		SSstock_market.materials_trends[material_id] = trend_value
		if(!isnull(trend_duration))
			SSstock_market.materials_trend_life[material_id] = trend_duration
	return TRUE

/datum/stock_market_event/proc/handle()
	trend_duration--
	if(trend_duration <= 0)
		end_event()

/datum/stock_market_event/proc/end_event()
	SSstock_market.active_events -= src
	qdel(src)

/datum/stock_market_event/proc/create_news()
	SSstock_market.pending_news += "[pick(company_names)] [pick(circumstances)] [SSstock_market.get_material_name(material_id)]."

/datum/stock_market_event/market_reset
	trend_value = MARKET_TREND_STABLE
	trend_duration = 1
	circumstances = list(
		"выкуплена частным инвестиционным фондом, цена вернулась к норме:",
		"провела реструктуризацию, цена вернулась к норме:",
		"вошла в состав крупного холдинга, цена вернулась к норме:",
	)

/datum/stock_market_event/market_reset/start_event(material_id)
	. = ..()
	SSstock_market.materials_prices[material_id] = SSstock_market.base_prices[material_id]
	create_news()

/datum/stock_market_event/large_boost
	trend_value = MARKET_TREND_UPWARD
	trend_duration = 4
	circumstances = list(
		"выпустила новый продукт, и спрос резко вырос:",
		"нашла новое ценное применение материалу, цена растёт:",
		"опубликовала отчёт, после которого подорожал материал:",
	)

/datum/stock_market_event/large_boost/start_event(material_id)
	. = ..()
	var/price = SSstock_market.materials_prices[material_id]
	SSstock_market.adjust_material_price(material_id, abs(gaussian(price * 0.5, price * 0.1)))
	create_news()

/datum/stock_market_event/large_drop
	trend_value = MARKET_TREND_DOWNWARD
	trend_duration = 4
	circumstances = list(
		"оказалась в центре скандала, и цена обвалилась:",
		"проиграла крупный судебный иск, цена падает:",
		"опубликовала отчёт, после которого подешевел материал:",
	)

/datum/stock_market_event/large_drop/start_event(material_id)
	. = ..()
	var/price = SSstock_market.materials_prices[material_id]
	SSstock_market.adjust_material_price(material_id, -abs(gaussian(price * 0.5, price * 0.1)))
	create_news()

/datum/stock_market_event/hotcakes
	trend_value = MARKET_TREND_UPWARD
	trend_duration = 1
	circumstances = list(
		"монополизировала поставки, и цена взлетела до предела:",
		"выпустила хит сезона, расхватывают всё:",
	)

/datum/stock_market_event/hotcakes/start_event(material_id)
	. = ..()
	SSstock_market.materials_prices[material_id] = SSstock_market.price_maximum(material_id)
	create_news()

/datum/stock_market_event/lockdown
	trend_value = MARKET_TREND_DOWNWARD
	trend_duration = 2
	circumstances = list(
		"попала под расследование Галактической торговой комиссии, торги остановлены:",
		"оказалась под эмбарго ТСФ, торги остановлены:",
	)

/datum/stock_market_event/lockdown/start_event(material_id)
	. = ..()
	create_news()

/datum/stock_market_event/lockdown/handle()
	SSstock_market.materials_quantity[material_id] = 0
	return ..()

/datum/stock_market_event/lockdown/end_event()
	SSstock_market.materials_quantity[material_id] = SSstock_market.base_quantities[material_id]
	SSstock_market.materials_prices[material_id] = SSstock_market.base_prices[material_id]
	SSstock_market.pending_news += "Торги возобновлены: [SSstock_market.get_material_name(material_id)]."
	return ..()
