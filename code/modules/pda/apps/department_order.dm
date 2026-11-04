GLOBAL_LIST_INIT(department_order_areas, list(
	STATION_DEPARTMENT_ENGINEERING = list(/area/station/engineering),
	STATION_DEPARTMENT_MEDICAL = list(/area/station/medical),
	STATION_DEPARTMENT_SCIENCE = list(/area/station/science),
	STATION_DEPARTMENT_SECURITY = list(/area/station/security),
	STATION_DEPARTMENT_SERVICE = list(/area/station/service, /area/hydroponics, /area/janitor),
))

GLOBAL_LIST_INIT(department_order_groups, list(
	STATION_DEPARTMENT_ENGINEERING = list(SUPPLY_ENGINEER, SUPPLY_MATERIALS),
	STATION_DEPARTMENT_MEDICAL = list(SUPPLY_MEDICAL),
	STATION_DEPARTMENT_SCIENCE = list(SUPPLY_SCIENCE, SUPPLY_MATERIALS),
	STATION_DEPARTMENT_SECURITY = list(SUPPLY_SECURITY),
	STATION_DEPARTMENT_SERVICE = list(SUPPLY_ORGANIC, SUPPLY_MISC),
))

/datum/data/pda/app/department_order
	name = "Заказы отдела"
	icon = "truck-loading"
	template = "pda_department_order"
	update = PDA_APP_UPDATE_SLOW
	var/static/list/department_cooldowns = list()
	var/static/list/pending_orders = list()

/datum/data/pda/app/department_order/proc/get_account()
	if(!pda.id)
		return
	return get_account_from_card(pda.id)

/datum/data/pda/app/department_order/proc/can_order_pack(datum/supply_packs/pack, department)
	if(!(pack.group in GLOB.department_order_groups[department]))
		return FALSE
	if(pack.hidden || pack.contraband || pack.goody || (pack.special && !pack.special_enabled))
		return FALSE
	for(var/tech_id in pack.required_tech)
		if(SSshuttle.techLevels[tech_id] < pack.required_tech[tech_id])
			return FALSE
	return TRUE

/datum/data/pda/app/department_order/update_ui(mob/user, list/data)
	var/datum/money_account/account = get_account()
	var/datum/job/job = account?.linked_job
	if(istype(job) && job.head_position && GLOB.department_accounts[job.department])
		var/datum/money_account/department_account = GLOB.department_accounts[job.department]
		var/list/transactions = list()
		for(var/datum/transaction/transaction as anything in department_account.transaction_log)
			transactions.Insert(1, list(transaction.get_ui_data()))
		data["statement"] = list(
			"department" = GLOB.station_departments_ru[job.department],
			"balance" = department_account.money,
			"transactions" = transactions,
		)

	var/department = account?.get_order_department()
	data["department_name"] = department ? GLOB.station_departments_ru[department] : null
	data["can_order"] = !!GLOB.department_order_groups[department]
	if(!data["can_order"])
		return

	var/datum/supply_order/pending_order = pending_orders[department]
	if(!(pending_order in SSshuttle.shoppinglist))
		pending_orders -= department
		pending_order = null
	data["pending_order"] = pending_order ? "№[pending_order.ordernum] ([pending_order.object.name])" : null
	data["can_cancel"] = pending_order && job.head_position
	data["cooldown"] = department_cooldowns[department] > world.time ? DisplayTimeText(department_cooldowns[department] - world.time, 1) : null

	var/list/packs = list()
	for(var/key in SSshuttle.supply_packs)
		var/datum/supply_packs/pack = SSshuttle.supply_packs[key]
		if(!can_order_pack(pack, department))
			continue
		packs += list(list(
			"name" = pack.name,
			"cost" = pack.get_cost(),
			"group" = get_supply_group_name(pack.group),
			"ref" = pack.UID(),
		))
	data["packs"] = packs

/datum/data/pda/app/department_order/ui_act(action, list/params)
	var/datum/money_account/account = get_account()
	var/department = account?.get_order_department()
	if(!GLOB.department_order_groups[department])
		return

	switch(action)
		if("order")
			if(department_cooldowns[department] > world.time)
				return
			var/datum/supply_packs/pack = locateUID(params["ref"])
			if(!istype(pack) || !can_order_pack(pack, department))
				return
			var/datum/supply_order/order = SSshuttle.generateSupplyOrder(pack.UID(), pda.id.registered_name, pda.id.assignment, "Заказ отдела", 1, CARGO_PAYMENT_DEPARTMENT_ORDER, account, department)
			if(!order)
				return
			pending_orders[department] = order
			department_cooldowns[department] = world.time + DEPARTMENT_ORDER_COOLDOWN_COEFFICIENT * (log(10, pack.get_cost()) ** DEPARTMENT_ORDER_COOLDOWN_EXPONENT) * (1 SECONDS)
			pda.investigate_log("[key_name_log(usr)] placed a free department order for [pack.name] ([department]).", INVESTIGATE_CARGO)
			pda.balloon_alert(usr, "заказ оформлен")

		if("cancel")
			var/datum/job/job = account.linked_job
			var/datum/supply_order/pending_order = pending_orders[department]
			if(!job.head_position || !(pending_order in SSshuttle.shoppinglist))
				return
			SSshuttle.shoppinglist -= pending_order
			pending_orders -= department
			department_cooldowns[department] = 0
			pda.investigate_log("[key_name_log(usr)] cancelled the free department order for [pending_order.object.name] ([department]).", INVESTIGATE_CARGO)
