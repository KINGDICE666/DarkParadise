/obj/item/paper/manifest
	name = "supply manifest"
	var/erroneous = 0
	var/cost = 0
	var/ordernumber = 0

/obj/item/paper/manifest/get_ru_names()
	return alist(
		NOMINATIVE = "манифест снабжения",
		GENITIVE = "манифеста снабжения",
		DATIVE = "манифесту снабжения",
		ACCUSATIVE = "манифест снабжения",
		INSTRUMENTAL = "манифестом снабжения",
		PREPOSITIONAL = "манифесте снабжения",
	)

/obj/item/paper/manifest/proc/is_approved()
	return LAZYLEN(stamped) && !is_denied()

/obj/item/paper/manifest/proc/is_denied()
	return LAZYLEN(stamped) && ( (/obj/item/stamp/denied in stamped) || ("stamp-deny" in stamped) )

/obj/docking_port/mobile/supply
	name = "supply shuttle"
	id = "supply"
	callTime = 2 MINUTES

	dir = 8
	width = 12
	dwidth = 5
	height = 7
	roundstart_move = "supply_away"

/obj/docking_port/mobile/supply/proc/forbidden_atoms_check(atom/A)
	var/static/list/cargo_blacklist = list(
		/obj/structure/blob,
		/obj/structure/spider/spiderling,
		/obj/item/disk/nuclear,
		/obj/machinery/nuclearbomb,
		/obj/item/beacon,
		/obj/machinery/the_singularitygen,
		/obj/singularity,
		/obj/machinery/teleport/station,
		/obj/machinery/teleport/hub,
		/obj/machinery/telepad,
		/obj/machinery/telepad_cargo,
		/obj/machinery/clonepod,
		/obj/effect/hierophant,
		/obj/item/warp_cube,
		/obj/machinery/quantumpad,
		/obj/structure/extraction_point,
		/obj/item/paicard
	)
	if(A)
		if(isliving(A))
			if(!istype(A.loc, /obj/item/mobcapsule))
				return TRUE
			var/mob/living/living = A
			if(living.client) //You cannot get out of the capsule and you will be destroyed. Saving clients
				return TRUE
		if(is_type_in_list(A, cargo_blacklist) || HAS_TRAIT(A, TRAIT_BANNED_FROM_CARGO_SHUTTLE))
			return TRUE
		for(var/thing in A)
			if(.(thing))
				return TRUE

	return FALSE

/obj/docking_port/mobile/supply/register()
	if(!..())
		return 0
	SSshuttle.supply = src
	return 1

/obj/docking_port/mobile/supply/canMove()
	if(is_station_level(z))
		return forbidden_atoms_check(areaInstance)
	return ..()

/obj/docking_port/mobile/supply/request(obj/docking_port/stationary/S)
	if(mode != SHUTTLE_IDLE)
		return 2
	return ..()

/obj/docking_port/mobile/supply/dock(obj/docking_port/stationary/S1, force, transit)
	. = ..()
	if(.)
		return .

	buy(S1)
	sell(S1)

/obj/docking_port/mobile/supply/proc/buy(obj/docking_port/stationary/destination)
	if(!is_station_level(destination.z))
		return 1

	if(!length(SSshuttle.shoppinglist) && !length(SSshuttle.material_orders))
		return 2

	var/list/emptyTurfs = list()
	for(var/turf/simulated/T in areaInstance)
		if(T.density)
			continue

		var/contcount
		for(var/atom/A in T.contents)
			if(!A.simulated)
				continue

			if(is_light(A))
				continue

			if(istype(A, /obj/machinery/light))
				continue //hacky but whatever, shuttles need three spots each for this shit
			contcount++

		if(contcount)
			continue

		emptyTurfs += T

	var/list/processed_orders = list()
	var/list/delivered_by_account = list()
	var/list/goodies_by_account = list()
	for(var/datum/supply_order/SO in SSshuttle.shoppinglist)
		if(!SO.object)
			stack_trace("Supply Order [SO] has no object associated with it.")
			processed_orders += SO
			continue

		if(SO.object.goody && SO.paying_account)
			LAZYADD(goodies_by_account[SO.paying_account], SO)
			continue

		var/turf/T = pick_n_take(emptyTurfs)		//turf we will place it in
		if(!T)
			break

		var/errors = 0
		if(SO.payment_type == CARGO_PAYMENT_SUPPLY)
			if(prob(5))
				errors |= MANIFEST_ERROR_COUNT
				investigate_log("Supply order #[SO] generated a manifest with packages incorrectly counted.", INVESTIGATE_CARGO)
			if(prob(5))
				errors |= MANIFEST_ERROR_NAME
				investigate_log("Supply order #[SO] generated a manifest with destination station incorrect.", INVESTIGATE_CARGO)
			if(prob(5))
				errors |= MANIFEST_ERROR_ITEM
				investigate_log("Supply order #[SO] generated a manifest with package incomplete.", INVESTIGATE_CARGO)
		SO.createObject(T, errors)
		processed_orders += SO
		if(SO.handling_fee)
			SSshuttle.cargo_money_account.credit(SO.handling_fee, "Наценка за личный заказ №[SO.ordernum]", "Терминал Бизель №[rand(111,333)]", SSshuttle.cargo_money_account.owner_name)
		if(SO.payment_type != CARGO_PAYMENT_SUPPLY)
			LAZYADD(delivered_by_account[SO.orderer_account], "№[SO.ordernum] ([SO.object.name])")

	for(var/datum/money_account/buyer as anything in goodies_by_account)
		var/turf/T = pick_n_take(emptyTurfs)
		if(!T)
			break
		var/list/buyer_orders = goodies_by_account[buyer]
		pack_goodies(T, buyer, buyer_orders)
		processed_orders += buyer_orders
		for(var/datum/supply_order/order as anything in buyer_orders)
			LAZYADD(delivered_by_account[buyer], "№[order.ordernum] ([order.object.name])")

	for(var/datum/material_market_order/material_order as anything in SSshuttle.material_orders)
		var/turf/T = pick_n_take(emptyTurfs)
		if(!T)
			break
		material_order.deliver(T)
		SSshuttle.material_orders -= material_order
		qdel(material_order)

	SSshuttle.shoppinglist -= processed_orders
	for(var/datum/money_account/account as anything in delivered_by_account)
		account.notify_pda_owner("<b>Доставка груза </b>\"Шаттл снабжения доставил ваши заказы: [jointext(delivered_by_account[account], ", ")].\" (Невозможно Ответить)")

/obj/docking_port/mobile/supply/proc/pack_goodies(turf/destination, datum/money_account/buyer, list/orders)
	var/atom/container
	if(length(orders) > CARGO_GOODY_FREE_SHIPPING_MAX)
		container = new /obj/structure/closet/crate(destination)
		container.AddComponent(/datum/component/locked_to_account, buyer)
		if(buyer.money >= CARGO_GOODY_CRATE_FEE && buyer.charge(CARGO_GOODY_CRATE_FEE, SSshuttle.cargo_money_account, "Доставка личных покупок ящиком", "Терминал Бизель №[rand(111,333)]", SSshuttle.cargo_money_account.owner_name, "Доставка личных покупок ящиком", buyer.owner_name))
			SScapitalism.add_audit_entry(buyer, CARGO_GOODY_CRATE_FEE, "Отдел снабжения: доставка ящиком")
			buyer.notify_pda_owner("<b>Оплата доставки </b>\"Личных покупок больше [CARGO_GOODY_FREE_SHIPPING_MAX], они доставлены в ящике. С вашего счёта списано [CARGO_GOODY_CRATE_FEE] кредит[DECL_0_A_OV(CARGO_GOODY_CRATE_FEE)] за доставку.\" (Невозможно Ответить)")
	else
		container = new /obj/item/storage/lockbox/order(destination, buyer)
	for(var/datum/supply_order/order as anything in orders)
		for(var/path in order.object.contains)
			new path(container)
	container.update_appearance()

/obj/docking_port/mobile/supply/proc/sell(obj/docking_port/stationary/destination)
	if(destination.z != level_name_to_num(CENTCOMM))		//we only sell when we are -at- centcomm
		return TRUE

	var/quest_reward = 0
	var/total_credits = 0
	var/list/msg = list("<center>---[station_time_timestamp()]---</center><br>")
	var/datum/export_report/report = new

	for(var/atom/movable/sold_atom in areaInstance)
		if(sold_atom.anchored || isdead(sold_atom) || isobserver(sold_atom))
			continue
		SSshuttle.sold_atoms += " [sold_atom.declent_ru(NOMINATIVE)]"

		if(istype(sold_atom, /obj/structure/bigDelivery))
			var/delivery_reward = SScargo_quests.check_delivery(sold_atom)
			if(delivery_reward)
				quest_reward += delivery_reward
				qdel(sold_atom, force = TRUE)
				continue

		for(var/obj/item/disk/tech_disk/disk in sold_atom.get_all_contents())
			sell_tech_disk(disk, msg)

		if(istype(sold_atom, /obj/structure/closet/crate/critter/mecha))
			var/obj/structure/closet/crate/critter/mecha/mecha_crate = sold_atom
			if(mecha_crate.console && mecha_crate.quest)
				total_credits += sell_roboquest_mecha(mecha_crate, msg)
				qdel(mecha_crate, force = TRUE)
				continue

		export_item_and_contents(sold_atom, apply_elastic = TRUE, dry_run = FALSE, external_report = report)
		if(!QDELETED(sold_atom))
			qdel(sold_atom, force = TRUE)
		SSshuttle.sold_atoms += "."

	if(quest_reward > 0)
		msg += "[span_good("+[quest_reward] кр.")]: Получена оплата за заказы.<br>"
		total_credits += quest_reward

	var/datum/money_account/cargo_money_account = GLOB.department_accounts[STATION_DEPARTMENT_SUPPLY]
	if(total_credits)
		cargo_money_account.credit(total_credits, "Расчёт за рейс шаттла снабжения", "Терминал Бизель №[rand(111,333)]", "Счёт Отдела снабжения")

	var/export_total = 0
	for(var/datum/export/exported_datum in report.total_amount)
		var/export_text = exported_datum.total_printout(report)
		if(!export_text)
			continue
		msg += export_text + "<br>"
		export_total += report.total_value[exported_datum]

	if(export_total > 0)
		cargo_money_account.credit(export_total, "Экспорт грузов", "Терминал Бизель №[rand(111,333)]", "Счёт Отдела снабжения")
	else if(export_total < 0)
		cargo_money_account.charge(min(-export_total, cargo_money_account.money), null, "Штраф за ошибки в манифестах", "Терминал Бизель №[rand(111,333)]", "Центральное командование")

	SSshuttle.centcom_message += "[msg.Join("")]<hr>"
	if(length(report.exported_atoms))
		investigate_log("contents sold for [total_credits + export_total] credits. Contents: [report.exported_atoms.Join(", ")].", INVESTIGATE_CARGO)

/obj/docking_port/mobile/supply/proc/sell_tech_disk(obj/item/disk/tech_disk/disk, list/msg)
	var/datum/tech/tech = disk.stored
	if(!tech)
		return
	var/cost = tech.getCost(SSshuttle.techLevels[tech.id])
	if(!cost)
		return
	if(tech.level >= 7)
		SScapitalism.base_account.credit(7000, "Благодарность за вклад в науку.", "Терминал Института \"Нанотрейзен\" №[rand(111,333)]", "Институт \"Нанотрейзен\"")
	SSshuttle.techLevels[tech.id] = tech.level
	for(var/mob/mob in GLOB.player_list)
		if(!mob.mind)
			continue
		for(var/datum/job_objective/further_research/objective in mob.mind.job_objectives)
			objective.unit_completed(round(cost / 3))
	msg += "[tech.name] — новые данные.<br>"

/obj/docking_port/mobile/supply/proc/sell_roboquest_mecha(obj/structure/closet/crate/critter/mecha/crate, list/msg)
	for(var/category in crate.quest.reward)
		crate.quest.reward[category] = max(crate.quest.reward[category] - crate.penalty, 0)
		crate.console.points[category] += crate.quest.reward[category]
	var/credits_earned = crate.quest.reward["robo"] * ROBOQUEST_CREDITS_PER_POINT
	var/cash_reward = crate.quest.maximum_cash - round(crate.quest.maximum_cash * crate.penalty / 4)
	if(crate.quest.id)
		var/datum/money_account/account = get_money_account(crate.quest.id.associated_account_number)
		if(account)
			account.credit(cash_reward, "Награда за экзоскелет", "Терминал Бизель №[rand(111,333)]", account.owner_name)
		crate.quest.id.robo_bounty = null
	SSshuttle.cargo_money_account.credit(cash_reward, "Награда за экзоскелет", "Терминал Бизель №[rand(111,333)]", SSshuttle.cargo_money_account.owner_name)
	crate.console.on_quest_complete()
	msg += "[span_good("+[credits_earned] кр.")]: Получен запрошенный экзоскелет: [crate.quest.name].<br>"
	crate.quest = null
	return credits_earned

/********************
	SUPPLY ORDER
 ********************/
/datum/supply_order
	var/ordernum
	var/datum/supply_packs/object = null
	var/orderedby = null
	var/orderedbyRank
	var/comment = null
	var/crates
	var/payment_type = CARGO_PAYMENT_SUPPLY
	var/datum/money_account/paying_account
	var/datum/money_account/orderer_account
	var/payer_department
	var/paid_amount = 0
	var/handling_fee = 0

/datum/supply_order/proc/get_payer_name()
	switch(payment_type)
		if(CARGO_PAYMENT_PERSONAL)
			return paying_account.owner_name
		if(CARGO_PAYMENT_DEPARTMENT)
			return "бюджет отдела «[GLOB.station_departments_ru[payer_department]]»"
		if(CARGO_PAYMENT_DEPARTMENT_ORDER)
			return "заказ отдела «[GLOB.station_departments_ru[payer_department]]»"
	return "бюджет снабжения"

/datum/supply_order/proc/refund()
	if(!paid_amount)
		return
	paying_account.credit(paid_amount, "Возврат средств за отменённый заказ №[ordernum]", "Консоль снабжения", paying_account.owner_name)
	if(payment_type != CARGO_PAYMENT_SUPPLY)
		orderer_account.notify_pda_owner("<b>Возврат средств </b>\"Заказ №[ordernum] ([object.name]) отменён. Возврат [paid_amount] кредит[DECL_0_A_OV(paid_amount)]: [get_payer_name()].\" (Невозможно Ответить)")

/datum/supply_order/proc/generateRequisition(atom/_loc)
	if(!object)
		return

	var/obj/item/paper/reqform = new /obj/item/paper(_loc)
	playsound(_loc, 'sound/goonstation/machines/printer_thermal.ogg', 50, TRUE)
	var/request_desc = "на поставку — [crates] \"[object.name]\" для [orderedby]"
	reqform.name = "запрос [request_desc]"
	reqform.ru_names = alist(
		NOMINATIVE = "запрос [request_desc]",
		GENITIVE = "запроса [request_desc]",
		DATIVE = "запросу [request_desc]",
		ACCUSATIVE = "запрос [request_desc]",
		INSTRUMENTAL = "запросом [request_desc]",
		PREPOSITIONAL = "запросе [request_desc]",
	)
	reqform.info += "<h3>[station_name()] — запрос на поставку грузов</h3><hr>"
	reqform.info += "ИНДЕКС: №[SSshuttle.ordernum]<br>"
	reqform.info += "ЗАПРОСИВШИЙ: [orderedby]<br>"
	reqform.info += "ПРИОРИТЕТ: [orderedbyRank]<br>"
	reqform.info += "ОПЛАТА: [capitalize(get_payer_name())]<br>"
	reqform.info += "ПРИЧИНА: [comment]<br>"
	reqform.info += "ТИП ГРУЗА: [object.name]<br>"
	reqform.info += "КОЛИЧЕСТВО ЯЩИКОВ: [crates]<br>"
	reqform.info += "ТРЕБОВАНИЯ К ДОСТУПУ: [object.access ? get_access_desc(object.access) : "Нет"]<br>"
	reqform.info += "СОДЕРЖИМОЕ:<br>"
	reqform.info += object.manifest
	reqform.info += "<hr>"
	reqform.info += "ПОСТАВЬТЕ ПЕЧАТЬ НИЖЕ ДЛЯ ОДОБРЕНИЯ ЗАПРОСА:<br>"

	reqform.update_icon()	//Fix for appearing blank when printed.

	return reqform

/datum/supply_order/proc/createObject(atom/_loc, errors=0)
	if(!object)
		return
	//create the crate
	var/atom/Crate = new object.containertype(_loc)
	var/list/suffix_parts = list()
	if(comment)
		suffix_parts += comment
	if(payment_type != CARGO_PAYMENT_SUPPLY)
		suffix_parts += "оплата: [get_payer_name()]"
	var/comment_suffix = length(suffix_parts) ? " ([suffix_parts.Join(", ")])" : ""
	Crate.name = "[object.containername][comment_suffix]"
	var/alist/base_names = object.container_ru_names
	Crate.ru_names = alist()
	for(var/case_id in NOMINATIVE to PREPOSITIONAL)
		var/base_name = length(base_names) ? base_names[case_id] : null
		Crate.ru_names[case_id] = base_name ? "[base_name][comment_suffix]" : Crate.name

	if(object.access)
		Crate:req_access = list(text2num(object.access))

	if(payment_type == CARGO_PAYMENT_PERSONAL && iscloset(Crate))
		Crate.AddComponent(/datum/component/locked_to_account, paying_account)
	if(payment_type == CARGO_PAYMENT_DEPARTMENT_ORDER && iscloset(Crate))
		Crate.AddElement(/datum/element/deliver_first, payer_department, object.get_department_order_reward())

	//create the manifest slip
	var/obj/item/paper/manifest/slip = new()
	slip.erroneous = errors
	slip.cost = object.get_cost()
	slip.ordernumber = ordernum

	var/stationName = (errors & MANIFEST_ERROR_NAME) ? new_station_name() : station_name()
	var/packagesAmt = length(SSshuttle.shoppinglist) + ((errors & MANIFEST_ERROR_COUNT) ? rand(1,2) : 0)

	var/order_desc = "поставки – \"[object.name]\" для [orderedby]"
	slip.name = "Манифест [order_desc]"
	slip.ru_names = alist(
		NOMINATIVE = "манифест [order_desc]",
		GENITIVE = "манифеста [order_desc]",
		DATIVE = "манифесту [order_desc]",
		ACCUSATIVE = "манифест [order_desc]",
		INSTRUMENTAL = "манифестом [order_desc]",
		PREPOSITIONAL = "манифесте [order_desc]",
	)
	slip.info = "<h3>[command_name()] Манифест поставки</h3><hr><br>"
	slip.info +="Заказ: №[ordernum]<br>"
	slip.info +="Пункт назначения: [stationName]<br>"
	slip.info +="Запросивший: [orderedby]<br>"
	slip.info +="Приоритет: [orderedbyRank]<br>"
	slip.info +="Оплата: [capitalize(get_payer_name())]<br>"
	slip.info +="Причина: [comment]<br>"
	slip.info +="Тип груза: [object.name]<br>"
	slip.info +="Требования к доступу: [object.access ? get_access_desc(object.access) : "Нет"]<br>"
	slip.info +="[packagesAmt] ЯЩИК[declension_ru(packagesAmt, "", "А", "ОВ")] В ЗАКАЗЕ<br>"
	slip.info +="СОДЕРЖИМОЕ:<br><ul>"

	//we now create the actual contents
	var/list/contains
	if(istype(object, /datum/supply_packs/misc/randomised))
		var/datum/supply_packs/misc/randomised/SO = object
		contains = list()
		if(length(object.contains))
			for(var/j=1, j<=SO.num_contained, j++)
				contains += pick(object.contains)
	else
		contains = object.contains

	for(var/typepath in contains)
		if(!typepath)	continue
		var/atom/A = new typepath(Crate)
		if(object.amount && A.vars.Find("amount") && A:amount)
			A:amount = object.amount
		slip.info += "<li>[A.declent_ru(NOMINATIVE)]</li>"	//add the item to the manifest (even if it was misplaced)

	if(istype(Crate, /obj/structure/closet/crate/critter)) // critter crates do not actually spawn mobs yet and have no contains var, but the manifest still needs to list them
		var/obj/structure/closet/crate/critter/CritCrate = Crate
		if(CritCrate.content_mob)
			var/mob/crittername = CritCrate.content_mob
			slip.info += "<li>[crittername.declent_ru(NOMINATIVE)]</li>"

	if(errors & MANIFEST_ERROR_ITEM)
		//secure and large crates cannot lose items
		if(findtext("[object.containertype]", "/secure/") || findtext("[object.containertype]","/largecrate/"))
			errors &= ~MANIFEST_ERROR_ITEM
		else
			var/lostAmt = max(round(length(Crate.contents)/10), 1)
			//lose some of the items
			while(--lostAmt >= 0)
				qdel(pick(Crate.contents))

	//manifest finalisation
	slip.info += "</ul><br>"
	slip.info += "ПРОВЕРЬТЕ СОДЕРЖИМОЕ И ПОСТАВЬТЕ ПЕЧАТЬ ПОД ЛИНИЕЙ, ЧТОБЫ ПОДТВЕРДИТЬ КОРРЕКТНОСТЬ МАНИФЕСТА<hr>" // And now this is actually meaningful.
	slip.update_appearance()
	slip.loc = Crate
	if(is_crate(Crate))
		var/obj/structure/closet/crate/CR = Crate
		CR.manifest = WEAKREF(slip)
		CR.update_appearance()
		CR.announce_beacons = object.announce_beacons

	return Crate

/***************************
	ORDER/REQUESTS CONSOLE
 **************************/
/obj/machinery/computer/supplycomp
	name = "Supply Shuttle Console"
	desc = "Компьютер, используемый для оформления заказов на поставку. Предназначен для пользования персоналом Отдела снабжения."
	icon_screen = "supply"
	req_access = list(ACCESS_CARGO)
	circuit = /obj/item/circuitboard/supplycomp
	/// Is this a public console (Confirm + Shuttle controls are not visible)
	var/is_public = FALSE
	/// Can we order special supplies
	var/hacked = FALSE
	/// Can we order contraband
	var/can_order_contraband = FALSE

/obj/machinery/computer/supplycomp/get_ru_names()
	return alist(
		NOMINATIVE = "консоль оформления заказов",
		GENITIVE = "консоли оформления заказов",
		DATIVE = "консоли оформления заказов",
		ACCUSATIVE = "консоль оформления заказов",
		INSTRUMENTAL = "консолью оформления заказов",
		PREPOSITIONAL = "консоли оформления заказов",
	)

/obj/machinery/computer/supplycomp/public
	name = "Supply Ordering Console"
	desc = "Используется для оформления заказов. Предназначено для общего пользования."
	icon_screen = "request"
	circuit = /obj/item/circuitboard/ordercomp
	req_access = list()
	is_public = TRUE

/obj/machinery/computer/supplycomp/public/get_ru_names()
	return alist(
		NOMINATIVE = "публичная консоль оформления заказов",
		GENITIVE = "публичной консоли оформления заказов",
		DATIVE = "публичной консоли оформления заказов",
		ACCUSATIVE = "публичную консоль оформления заказов",
		INSTRUMENTAL = "публичной консолью оформления заказов",
		PREPOSITIONAL = "публичной консоли оформления заказов",
	)

/obj/machinery/computer/supplycomp/Initialize(mapload, obj/structure/computerframe/frame)
	. = ..()

	var/obj/item/circuitboard/supplycomp/my_circuit = src.frame.circuit
	if(!istype(my_circuit))
		return

	can_order_contraband = my_circuit.contraband_enabled

/obj/machinery/computer/supplycomp/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/supplycomp/attack_hand(mob/user as mob)
	if(!allowed(user) && !isobserver(user))
		user.balloon_alert(user, "отказано в доступе!")
		playsound(src, SFX_BUTTON_DENIED, 20)
		return 1

	if(..())
		return TRUE

	add_fingerprint(user)
	ui_interact(user)
	return

/obj/machinery/computer/supplycomp/emag_act(mob/user)
	if(!hacked)
		add_attack_logs(user, src, "emagged")
		if(user)
			user.balloon_alert(user, "открыты дополнительные заказы")
		hacked = TRUE
		return

/obj/machinery/computer/supplycomp/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CargoConsole", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/computer/supplycomp/ui_data(mob/user)
	var/list/data = list()
	var/datum/money_account/user_account = get_user_account(user)
	var/user_department = user_account?.get_order_department()

	var/list/requests_list = list()
	for(var/set_name in SSshuttle.requestlist)
		var/datum/supply_order/SO = set_name
		if(SO)
			if(!SO.comment)
				SO.comment = "Без комментариев."
			var/list/pack_techs = list()
			if(length(SO.object.required_tech))
				for(var/tech_id in SO.object.required_tech)
					pack_techs += "[CallTechName(tech_id)]: [SO.object.required_tech[tech_id]];  "
			requests_list.Add(list(list("ordernum" = SO.ordernum, "supply_type" = SO.object.name, "orderedby" = SO.orderedby, "comment" = SO.comment, "payer" = SO.get_payer_name(), "cost" = SO.object.get_cost(), "command1" = list("confirmorder" = SO.ordernum), "command2" = list("rreq" = SO.ordernum), "pack_techs" = pack_techs.Join(""))))
	data["requests"] = requests_list

	var/list/orders_list = list()
	for(var/set_name in SSshuttle.shoppinglist)
		var/datum/supply_order/SO = set_name
		if(SO)
			var/can_cancel = SO.payment_type != CARGO_PAYMENT_DEPARTMENT_ORDER && (!is_public || (SO.payment_type == CARGO_PAYMENT_PERSONAL && SO.orderer_account == user_account))
			orders_list.Add(list(list("ordernum" = SO.ordernum, "supply_type" = SO.object.name, "orderedby" = SO.orderedby, "comment" = SO.comment, "payer" = SO.get_payer_name(), "can_cancel" = can_cancel)))
	data["orders"] = orders_list

	data["is_public"] = is_public
	data["has_account"] = !isnull(user_account)
	data["department_name"] = user_department ? GLOB.station_departments_ru[user_department] : null

	data["canapprove"] = (SSshuttle.supply.getDockedId() == "supply_away") && !(SSshuttle.supply.mode != SHUTTLE_IDLE) && !is_public
	data["credits"] = SSshuttle.cargo_money_account.money

	data["moving"] = SSshuttle.supply.mode != SHUTTLE_IDLE
	data["at_station"] = SSshuttle.supply.getDockedId() == "supply_home"
	data["timeleft"] = SSshuttle.supply.getTimerStr()
	data["can_launch"] = !SSshuttle.supply.canMove()

	return data

/obj/machinery/computer/supplycomp/ui_static_data(mob/user)
	var/list/data = list()
	var/list/packs_list = list()

	for(var/set_name in SSshuttle.supply_packs)
		var/datum/supply_packs/pack = SSshuttle.supply_packs[set_name]
		var/has_sale = pack.get_cost() < initial(pack.cost)
		var/is_enough_techs = pack.has_required_tech()
		if((pack.hidden && hacked) || (pack.contraband && can_order_contraband) || (pack.special && pack.special_enabled) || (!pack.contraband && !pack.hidden && !pack.special))
			packs_list.Add(list(list("name" = pack.name, "cost" = pack.get_cost(), "ref" = "[pack.UID()]", "contents" = pack.ui_manifest, "cat" = pack.group, "has_sale" = has_sale, "is_enough_techs" = is_enough_techs, "goody" = pack.goody)))

	data["supply_packs"] = packs_list
	data["personal_markup"] = CARGO_PERSONAL_ORDER_MARKUP

	var/list/categories = list() // meow
	for(var/category in GLOB.all_supply_groups)
		if(category == SUPPLY_CONTRABAND && !can_order_contraband)
			continue
		categories.Add(list(list("name" = get_supply_group_name(category), "category" = category)))
	data["categories"] = categories

	return data

/obj/machinery/computer/supplycomp/proc/is_authorized(mob/user)
	if(allowed(user))
		return TRUE

	if(user.can_admin_interact())
		return TRUE

	return FALSE

/obj/machinery/computer/supplycomp/proc/get_user_account(mob/user)
	if(!issilicon(user))
		return get_card_account(user)

/obj/machinery/computer/supplycomp/proc/can_pay_with(mob/user, datum/money_account/account, datum/supply_packs/pack)
	if(!account)
		balloon_alert(user, "нет привязанного счёта!")
		return FALSE
	if(account.suspended)
		balloon_alert(user, "счёт заблокирован!")
		return FALSE
	var/obj/item/card/id/id_card = user.get_id_card()
	if(pack.access && !(pack.access in id_card.GetAccess()))
		balloon_alert(user, "нет доступа к грузу!")
		return FALSE
	return TRUE

/obj/machinery/computer/supplycomp/proc/authorize_account(mob/user, datum/money_account/account)
	if(!account.security_level)
		return TRUE
	var/attempt_pin = tgui_input_number(user, "Введите PIN-код счёта", "Оплата заказа", max_value = 999999, min_value = 100000)
	if(isnull(attempt_pin))
		return FALSE
	if(attempt_account_access(account.account_number, attempt_pin, 2))
		return TRUE
	balloon_alert(user, "неверный PIN-код!")
	return FALSE

/obj/machinery/computer/supplycomp/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	// If its not a public console, and they aint authed, dont let them use this
	if(!is_public && !is_authorized(usr))
		return

	if(!SSshuttle)
		stack_trace("The SSshuttle controller datum is missing somehow.")
		return

	. = TRUE
	add_fingerprint(usr)

	switch(action)
		if("moveShuttle")
			// Public consoles cant move the shuttle. Dont allow exploiters.
			if(is_public)
				return
			if(SSshuttle.supply.canMove())
				to_chat(usr, span_warning("По соображениям безопасности шаттл снабжения не может перемещать живые организмы, ядерное оружие или маячки перемещния."))
			else if(SSshuttle.supply.getDockedId() == "supply_home")
				SSshuttle.toggleShuttle("supply", "supply_home", "supply_away", 1)
				investigate_log("[key_name_log(usr)] has sent the supply shuttle away. Cargo budget: [SSshuttle.cargo_money_account.money]. Shuttle contents: [SSshuttle.sold_atoms]", INVESTIGATE_CARGO)
			else if(!SSshuttle.supply.request(SSshuttle.getDock("supply_home")))
				if(LAZYLEN(SSshuttle.shoppinglist) && prob(10))
					var/datum/supply_order/O = new /datum/supply_order()
					O.ordernum = SSshuttle.ordernum
					O.object = SSshuttle.supply_packs[pick(SSshuttle.supply_packs)]
					O.orderedby = random_name(pick(MALE,FEMALE), species = SPECIES_HUMAN)
					SSshuttle.shoppinglist += O
					investigate_log("Random [O.object] crate added to supply shuttle", INVESTIGATE_CARGO)

		if("order")

			var/datum/supply_packs/P = locateUID(params["crate"])
			if(!istype(P))
				return
/*

			if(P.times_ordered >= P.order_limit && P.order_limit != -1) //If the crate has reached the limit, do not allow it to be ordered.
				to_chat(usr, span_warning("[P.name] is out of stock, and can no longer be ordered."))	// Unused for now (Crate limit #3056).
				return	*/

			var/payment_type = params["payment"]
			if(!(payment_type in list(CARGO_PAYMENT_SUPPLY, CARGO_PAYMENT_DEPARTMENT, CARGO_PAYMENT_PERSONAL)))
				return

			var/datum/money_account/orderer_account
			var/payer_department
			if(P.goody && payment_type != CARGO_PAYMENT_PERSONAL)
				balloon_alert(ui.user, "только за личный счёт!")
				return

			if(payment_type == CARGO_PAYMENT_PERSONAL && !P.has_required_tech())
				balloon_alert(ui.user, "мало тех. уровней!")
				return

			if(payment_type != CARGO_PAYMENT_SUPPLY)
				orderer_account = get_user_account(ui.user)
				if(!can_pay_with(ui.user, orderer_account, P))
					return
				if(payment_type == CARGO_PAYMENT_DEPARTMENT)
					payer_department = orderer_account.get_order_department()
					if(!payer_department)
						balloon_alert(ui.user, "нет бюджета отдела!")
						return

			var/amount = 1
			if(params["multiple"])
				var/num_input = tgui_input_number(ui.user, "Объём заказа", "Укажите количество ящиков", max_value = 20, min_value = 1)
				if(isnull(num_input) || (!is_public && !is_authorized(ui.user)) || ..()) // Make sure they dont walk away
					return
				amount = num_input

			var/timeout = world.time + (60 SECONDS) // If you dont type the reason within a minute, theres bigger problems here
			var/reason = tgui_input_text(ui.user, "Причина заказа", "Напишите причину заказа", encode = FALSE, timeout = timeout)
			if(!reason || (!is_public && !is_authorized(ui.user)) || ..())
				// Cancel if they take too long, they dont give a reason, they aint authed, or if they walked away
				return
			reason = sanitize(copytext_char(reason, 1, 100)) //Preventing tgui overflow

			if(orderer_account && (!authorize_account(ui.user, orderer_account) || ..()))
				return

			var/personal_price = P.goody ? P.get_cost() : round(P.get_cost() * CARGO_PERSONAL_ORDER_MARKUP)
			if(payment_type == CARGO_PAYMENT_PERSONAL)
				var/total_price = personal_price * amount
				if(orderer_account.money < total_price)
					balloon_alert(ui.user, "недостаточно средств!")
					return
				if(!orderer_account.charge(total_price, null, "Заказ: [P.name] ×[amount]", "Консоль снабжения", "Отдел снабжения"))
					return
				SScapitalism.add_audit_entry(orderer_account, total_price, "Отдел снабжения: [P.name] ×[amount]")
				orderer_account.notify_pda_owner("<b>Оплата заказа </b>\"С вашего счёта списано [total_price] кредит[DECL_0_A_OV(total_price)] за заказ: [P.name] ×[amount]. Груз прибудет ближайшим рейсом шаттла снабжения.\" (Невозможно Ответить)")

			var/idname = "*Не указано*"
			var/idrank = "*Не указано*"

			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				idname = H.get_authentification_name()
				idrank = H.get_assignment()
			else if(issilicon(usr))
				idname = usr.real_name

			investigate_log("[key_name_log(usr)] made an order for [P.name] with amount [amount], payment: [payment_type][payer_department ? " ([payer_department])" : ""]. Cargo budget: [SSshuttle.cargo_money_account.money].", INVESTIGATE_CARGO)
			//make our supply_order datums
			for(var/i = 1; i <= amount; i++)
				var/datum/supply_order/O = SSshuttle.generateSupplyOrder(params["crate"], idname, idrank, reason, amount, payment_type, orderer_account, payer_department)
				if(!O)
					return
				if(payment_type == CARGO_PAYMENT_PERSONAL)
					O.paid_amount = personal_price
					O.handling_fee = personal_price - P.get_cost()
					P.times_ordered += 1
				else if(i == 1)
					O.generateRequisition(loc)

		if("approve")
			// Public consoles cant approve stuff
			if(is_public)
				return
			if(SSshuttle.supply.getDockedId() != "supply_away" || SSshuttle.supply.mode != SHUTTLE_IDLE)
				return

			var/ordernum = text2num(params["ordernum"])
			var/datum/supply_order/O
			var/datum/supply_packs/P
			for(var/i=1, i<=length(SSshuttle.requestlist), i++)
				var/datum/supply_order/SO = SSshuttle.requestlist[i]
				if(SO.ordernum == ordernum)
					O = SO
					P = O.object
/*					if(P.times_ordered >= P.order_limit && P.order_limit != -1) //If this order would put it over the limit, deny it. Unused for now (Crate limit #3056).
						to_chat(usr, span_warning("[P.name] is out of stock, and can no longer be ordered."))	*/
					if(P.can_approve(usr, O.paying_account) && O.paying_account.charge(P.get_cost(), null, "Заказ: [P.name]", "Консоль снабжения", "Центральное командование"))
						O.paid_amount = P.get_cost()
						SSshuttle.requestlist.Cut(i,i+1)
						SSshuttle.shoppinglist += O
						P.times_ordered += 1
						if(O.payment_type == CARGO_PAYMENT_DEPARTMENT)
							O.orderer_account.notify_pda_owner("<b>Оплата заказа </b>\"Запрос №[O.ordernum] ([P.name]) одобрен, с бюджета вашего отдела списано [O.paid_amount] кредит[DECL_0_A_OV(O.paid_amount)].\" (Невозможно Ответить)")
						investigate_log("[key_name_log(usr)] has authorized an order for [P.name], paid by [O.paying_account.owner_name]. Cargo budget: [SSshuttle.cargo_money_account.money].", INVESTIGATE_CARGO)
					break

		if("deny")
			var/ordernum = text2num(params["ordernum"])
			for(var/i=1, i<=length(SSshuttle.requestlist), i++)
				var/datum/supply_order/SO = SSshuttle.requestlist[i]
				if(SO.ordernum == ordernum)
					// If we are on a public console, only allow cancelling of our own orders
					if(is_public)
						var/obj/item/card/id/I = usr.get_id_card()
						if(I && SO.orderedby == I.registered_name)
							SSshuttle.requestlist.Cut(i,i+1)
							break
					// If we arent public, were cargo access. CANCELLATIONS FOR EVERYONE
					else
						SSshuttle.requestlist.Cut(i,i+1)
						break

		if("cancel")
			var/ordernum = text2num(params["ordernum"])
			var/datum/money_account/user_account = get_user_account(usr)
			for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
				if(order.ordernum != ordernum)
					continue
				if(order.payment_type == CARGO_PAYMENT_DEPARTMENT_ORDER)
					return
				if(is_public && (order.payment_type != CARGO_PAYMENT_PERSONAL || order.orderer_account != user_account))
					return
				SSshuttle.shoppinglist -= order
				investigate_log("[key_name_log(usr)] has cancelled an order for [order.object.name], refunding [order.paid_amount] to [order.paying_account?.owner_name].", INVESTIGATE_CARGO)
				order.refund()
				break

		// Popup to show CC message logs. Its easier this way to avoid box-spam in TGUI
		if("showMessages")
			// Public consoles cant view messages
			if(is_public)
				return
			var/datum/browser/ccmsg_browser = new(usr, "ccmsg", "Журнал сообщений снабжения Центрального командования.", 800, 600)
			ccmsg_browser.set_content(SSshuttle.centcom_message)
			ccmsg_browser.open()

