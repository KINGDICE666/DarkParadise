#define CRASH_GROWTH_RATE 0.1155
#define CRASH_HOUSE_EDGE 0.97
#define CRASH_MIN_POINT 1.01
#define CRASH_MAX_POINT 1000
#define CRASH_BIG_WIN_MULTIPLIER 10
#define CASINO_HISTORY_LENGTH 12
#define WHEEL_SPIN_TIME (5 SECONDS)

/obj/machinery/computer/casino
	var/working = FALSE
	var/player_uid
	var/datum/money_account/player_account
	var/bet = 0
	var/last_result
	var/list/history = list()

/obj/machinery/computer/casino/Destroy()
	if(working && bet)
		player_account?.credit(bet, "Возврат ставки", declent_ru(NOMINATIVE), player_account.owner_name)
	player_account = null
	return ..()

/obj/machinery/computer/casino/attack_hand(mob/user)
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/casino/update_icon_state()
	icon_state = "[base_icon_state]-[working ? "on" : "off"]"

/obj/machinery/computer/casino/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	default_unfasten_wrench(user, I)

/obj/machinery/computer/casino/ui_data(mob/user)
	var/list/data = list()
	var/datum/money_account/account = get_card_account(user)
	data["money"] = account ? account.money : null
	data["working"] = working
	data["is_player"] = working && player_uid == user.UID()
	data["bet"] = bet
	data["min_bet"] = CASINO_MIN_BET
	data["max_bet"] = CASINO_MAX_BET
	data["last_result"] = last_result
	data["history"] = history
	return data

/obj/machinery/computer/casino/proc/take_bet(mob/user, amount)
	if(issilicon(user))
		to_chat(user, span_warning("Обнаружен искусственный интеллект. Согласно регуляции \"Нанотрейзен\" #1023 вмешательство синтетических форм жизни в финансовые операции запрещено."))
		return FALSE
	if(working || !isnum(amount) || amount < CASINO_MIN_BET || amount > CASINO_MAX_BET)
		return FALSE
	var/datum/money_account/account = get_card_account(user)
	if(!account)
		balloon_alert(user, "нет карты!")
		return FALSE
	if(!pay_with_card(user, amount, "Ставка: [declent_ru(NOMINATIVE)]"))
		return FALSE
	if(working)
		account.credit(amount, "Возврат ставки", declent_ru(NOMINATIVE), account.owner_name)
		return FALSE
	player_uid = user.UID()
	player_account = account
	bet = amount
	return TRUE

/obj/machinery/computer/casino/proc/pay_out(amount)
	player_account?.credit(amount, "Выигрыш: [declent_ru(NOMINATIVE)]", declent_ru(NOMINATIVE), player_account.owner_name)

/obj/machinery/computer/casino/proc/add_history(entry)
	history.Insert(1, entry)
	if(length(history) > CASINO_HISTORY_LENGTH)
		history.Cut(CASINO_HISTORY_LENGTH + 1)

/obj/machinery/computer/casino/proc/set_working(new_working)
	working = new_working
	update_icon(UPDATE_ICON_STATE)
	SStgui.update_uis(src)

/obj/machinery/computer/casino/crash
	name = "crash machine"
	desc = "Множитель ставки растёт вместе с кривой. Заберите выигрыш, пока она не рухнула."
	icon = 'icons/obj/economy.dmi'
	icon_state = "crash-off"
	base_icon_state = "crash"
	circuit = /obj/item/circuitboard/arcade/crash
	var/crash_point = 0
	var/last_crash_point = 0
	var/cashed_out = 0
	var/auto_cashout = 0
	var/round_start = 0
	var/crash_timer
	var/cashout_timer

/obj/machinery/computer/casino/crash/get_ru_names()
	return alist(
		NOMINATIVE = "автомат «Краш»",
		GENITIVE = "автомата «Краш»",
		DATIVE = "автомату «Краш»",
		ACCUSATIVE = "автомат «Краш»",
		INSTRUMENTAL = "автоматом «Краш»",
		PREPOSITIONAL = "автомате «Краш»",
	)

/obj/machinery/computer/casino/crash/Destroy()
	deltimer(crash_timer)
	deltimer(cashout_timer)
	return ..()

/obj/machinery/computer/casino/crash/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CasinoCrash", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/computer/casino/crash/ui_data(mob/user)
	var/list/data = ..()
	data["growth"] = CRASH_GROWTH_RATE
	data["elapsed"] = working ? (world.time - round_start) / (1 SECONDS) : 0
	data["crash_point"] = working ? null : last_crash_point
	data["cashed_out"] = cashed_out
	data["auto_cashout"] = auto_cashout
	return data

/obj/machinery/computer/casino/crash/ui_act(action, list/params)
	if(..())
		return
	add_fingerprint(usr)
	switch(action)
		if("start")
			var/auto = text2num(params["auto_cashout"])
			if(!take_bet(usr, round(text2num(params["bet"]))))
				return
			start_round(auto)
			return TRUE
		if("cashout")
			if(!working || cashed_out || player_uid != usr.UID())
				return
			var/multiplier = get_multiplier()
			if(multiplier >= crash_point)
				return
			cash_out(multiplier)
			return TRUE

/obj/machinery/computer/casino/crash/proc/get_multiplier()
	return floor(NUM_E ** (CRASH_GROWTH_RATE * (world.time - round_start) / (1 SECONDS)) * 100) / 100

/obj/machinery/computer/casino/crash/proc/time_to_reach(multiplier)
	return log(multiplier) / CRASH_GROWTH_RATE * (1 SECONDS)

/obj/machinery/computer/casino/crash/proc/start_round(auto)
	crash_point = clamp(floor(CRASH_HOUSE_EDGE / (1 - rand()) * 100) / 100, CRASH_MIN_POINT, CRASH_MAX_POINT)
	auto_cashout = (isnum(auto) && auto >= CRASH_MIN_POINT) ? floor(auto * 100) / 100 : 0
	cashed_out = 0
	round_start = world.time
	last_result = null
	crash_timer = addtimer(CALLBACK(src, PROC_REF(bust)), time_to_reach(crash_point), TIMER_STOPPABLE)
	if(auto_cashout && auto_cashout < crash_point)
		cashout_timer = addtimer(CALLBACK(src, PROC_REF(cash_out), auto_cashout), time_to_reach(auto_cashout), TIMER_STOPPABLE)
	playsound(src, 'sound/machines/ding.ogg', 50, TRUE)
	set_working(TRUE)

/obj/machinery/computer/casino/crash/proc/cash_out(multiplier)
	deltimer(cashout_timer)
	cashout_timer = null
	cashed_out = multiplier
	var/winnings = floor(bet * multiplier)
	bet = 0
	pay_out(winnings)
	last_result = "Забрано на x[multiplier]: +[winnings] кр."
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	if(multiplier >= CRASH_BIG_WIN_MULTIPLIER)
		atom_say("Невероятно! Выигрыш [winnings] кредитов на множителе x[multiplier]!")
	SStgui.update_uis(src)

/obj/machinery/computer/casino/crash/proc/bust()
	crash_timer = null
	deltimer(cashout_timer)
	cashout_timer = null
	last_crash_point = crash_point
	add_history(crash_point)
	if(!cashed_out)
		last_result = "Крах на x[crash_point]: ставка сгорела."
		playsound(src, 'sound/machines/buzz-sigh.ogg', 40, TRUE)
	player_uid = null
	player_account = null
	bet = 0
	set_working(FALSE)

/obj/machinery/computer/casino/wheel
	name = "wheel of fortune"
	desc = "Выберите цвет и испытайте удачу. Чем реже цвет, тем больше выигрыш."
	icon = 'icons/obj/economy.dmi'
	icon_state = "wheel-off"
	base_icon_state = "wheel"
	circuit = /obj/item/circuitboard/arcade/wheel
	var/static/list/sectors = list(
		"blue" = list("name" = "Синий", "multiplier" = 2, "count" = 26),
		"green" = list("name" = "Зелёный", "multiplier" = 3, "count" = 17),
		"red" = list("name" = "Красный", "multiplier" = 5, "count" = 10),
		"black" = list("name" = "Чёрный", "multiplier" = 50, "count" = 1),
	)
	var/static/list/layout
	var/bet_color
	var/result_index = 1
	var/spins = 0
	var/spin_timer

/obj/machinery/computer/casino/wheel/get_ru_names()
	return alist(
		NOMINATIVE = "колесо фортуны",
		GENITIVE = "колеса фортуны",
		DATIVE = "колесу фортуны",
		ACCUSATIVE = "колесо фортуны",
		INSTRUMENTAL = "колесом фортуны",
		PREPOSITIONAL = "колесе фортуны",
	)

/obj/machinery/computer/casino/wheel/Initialize(mapload)
	. = ..()
	if(layout)
		return
	var/total = 0
	for(var/color in sectors)
		total += sectors[color]["count"]
	var/list/placed = list()
	layout = list()
	for(var/index in 1 to total)
		var/best_color
		var/best_lag
		for(var/color in sectors)
			var/lag = sectors[color]["count"] * index / total - placed[color]
			if(isnull(best_color) || lag > best_lag)
				best_color = color
				best_lag = lag
		layout += best_color
		placed[best_color]++

/obj/machinery/computer/casino/wheel/Destroy()
	deltimer(spin_timer)
	return ..()

/obj/machinery/computer/casino/wheel/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CasinoWheel", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/computer/casino/wheel/ui_static_data(mob/user)
	var/list/sector_data = list()
	for(var/color in sectors)
		sector_data += list(list("id" = color, "name" = sectors[color]["name"], "multiplier" = sectors[color]["multiplier"]))
	return list("layout" = layout, "sectors" = sector_data, "spin_time" = WHEEL_SPIN_TIME / (1 SECONDS))

/obj/machinery/computer/casino/wheel/ui_data(mob/user)
	var/list/data = ..()
	data["result_index"] = result_index
	data["spins"] = spins
	data["bet_color"] = bet_color
	return data

/obj/machinery/computer/casino/wheel/ui_act(action, list/params)
	if(..())
		return
	add_fingerprint(usr)
	if(action != "spin")
		return
	var/color = params["color"]
	if(!sectors[color] || !take_bet(usr, round(text2num(params["bet"]))))
		return
	bet_color = color
	result_index = rand(1, length(layout))
	spins++
	last_result = null
	spin_timer = addtimer(CALLBACK(src, PROC_REF(finish_spin)), WHEEL_SPIN_TIME, TIMER_STOPPABLE)
	playsound(src, 'sound/machines/ding.ogg', 50, TRUE)
	set_working(TRUE)
	return TRUE

/obj/machinery/computer/casino/wheel/proc/finish_spin()
	spin_timer = null
	var/landed = layout[result_index]
	add_history(landed)
	if(landed == bet_color)
		var/winnings = bet * sectors[landed]["multiplier"]
		pay_out(winnings)
		last_result = "[sectors[landed]["name"]]! Выигрыш: +[winnings] кр."
		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
		if(landed == "black")
			atom_say("ЧЁРНЫЙ! Выигрыш [winnings] кредитов!")
	else
		last_result = "Выпало: [sectors[landed]["name"]]. Ставка сгорела."
		playsound(src, 'sound/machines/buzz-sigh.ogg', 40, TRUE)
	player_uid = null
	player_account = null
	bet = 0
	set_working(FALSE)

#undef CRASH_GROWTH_RATE
#undef CRASH_HOUSE_EDGE
#undef CRASH_MIN_POINT
#undef CRASH_MAX_POINT
#undef CRASH_BIG_WIN_MULTIPLIER
#undef CASINO_HISTORY_LENGTH
#undef WHEEL_SPIN_TIME
