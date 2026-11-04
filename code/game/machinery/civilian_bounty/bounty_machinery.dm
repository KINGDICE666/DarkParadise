#define HIGH_PRIORITY_BOUNTY_ODDS 20

/obj/machinery/civilian_bounty_pad
	name = "civilian bounty pad"
	desc = "Устройство для отправки целей гражданских баунти на ЦК."
	icon = 'icons/obj/machines/civilian_bounty.dmi'
	icon_state = "lpad-off"
	anchored = TRUE
	layer = TABLE_LAYER
	resistance_flags = FIRE_PROOF
	var/cooldown_reduction = 0
	var/is_sending = FALSE

/obj/machinery/civilian_bounty_pad/get_ru_names()
	return alist(
		NOMINATIVE = "платформа гражданских баунти",
		GENITIVE = "платформы гражданских баунти",
		DATIVE = "платформе гражданских баунти",
		ACCUSATIVE = "платформу гражданских баунти",
		INSTRUMENTAL = "платформой гражданских баунти",
		PREPOSITIONAL = "платформе гражданских баунти",
	)

/obj/machinery/civilian_bounty_pad/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/civilian_bounty_pad(null)
	component_parts += new /obj/item/stock_parts/scanning_module(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)
	component_parts += new /obj/item/stack/ore/bluespace_crystal/artificial(null)
	RefreshParts()

/obj/machinery/civilian_bounty_pad/RefreshParts()
	var/tier = -2
	for(var/obj/item/stock_parts/micro_laser/micro_laser in component_parts)
		tier += micro_laser.rating
	for(var/obj/item/stock_parts/scanning_module/scanning_module in component_parts)
		tier += scanning_module.rating
	cooldown_reduction = tier * (30 SECONDS)

/obj/machinery/civilian_bounty_pad/update_icon_state()
	if(panel_open)
		icon_state = "lpad-open"
	else if(is_sending)
		icon_state = "lpad"
	else
		icon_state = "lpad-off"

/obj/machinery/civilian_bounty_pad/multitool_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!I.multitool_check_buffer(user))
		return
	var/obj/item/multitool/multitool = I
	multitool.set_multitool_buffer(user, src)

/obj/machinery/civilian_bounty_pad/screwdriver_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	default_deconstruction_screwdriver(user, "lpad-open", "lpad-off", I)

/obj/machinery/civilian_bounty_pad/crowbar_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	default_deconstruction_crowbar(user, I)

/obj/machinery/civilian_bounty_pad/proc/set_is_sending(value)
	if(is_sending == value)
		return
	is_sending = value
	update_appearance()

/obj/machinery/civilian_bounty_pad/proc/finish_sending()
	set_is_sending(FALSE)
	flick("lpad-beam", src)

/obj/machinery/computer/civilian_bounty
	name = "civilian bounty control terminal"
	desc = "Консоль для выдачи гражданских баунти на вставленную ID-карту и управления платформой отправки."
	icon_screen = "supply"
	icon_keyboard = "id_key"
	circuit = /obj/item/circuitboard/civilian_bounty
	var/status_report = "Готов к отправке."
	var/datum/weakref/pad_ref
	var/warmup_time = 3 SECONDS
	var/sending = FALSE
	var/sending_timer
	var/obj/item/card/id/inserted_scan_id
	COOLDOWN_DECLARE(sheet_printer_cooldown)

/obj/machinery/computer/civilian_bounty/get_ru_names()
	return alist(
		NOMINATIVE = "терминал гражданских баунти",
		GENITIVE = "терминала гражданских баунти",
		DATIVE = "терминалу гражданских баунти",
		ACCUSATIVE = "терминал гражданских баунти",
		INSTRUMENTAL = "терминалом гражданских баунти",
		PREPOSITIONAL = "терминале гражданских баунти",
	)

/obj/machinery/computer/civilian_bounty/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/civilian_bounty/LateInitialize()
	. = ..()
	var/obj/machinery/civilian_bounty_pad/pad = locate() in range(4, src)
	pad_ref = WEAKREF(pad)

/obj/machinery/computer/civilian_bounty/Destroy()
	deltimer(sending_timer)
	if(inserted_scan_id)
		inserted_scan_id.forceMove(drop_location())
		inserted_scan_id = null
	pad_ref = null
	return ..()

/obj/machinery/computer/civilian_bounty/attack_hand(mob/user)
	if(..())
		return TRUE
	ui_interact(user)

/obj/machinery/computer/civilian_bounty/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!is_id_card(tool))
		return ..()
	if(inserted_scan_id)
		balloon_alert(user, "карта уже вставлена!")
		return ITEM_INTERACT_BLOCKING
	if(!user.drop_transfer_item_to_loc(tool, src))
		return ITEM_INTERACT_BLOCKING
	inserted_scan_id = tool
	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
	ui_interact(user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/computer/civilian_bounty/multitool_act(mob/living/user, obj/item/I)
	. = TRUE
	var/obj/item/multitool/multitool = I
	if(!istype(multitool.buffer, /obj/machinery/civilian_bounty_pad))
		return
	pad_ref = WEAKREF(multitool.buffer)
	to_chat(user, span_notice("Вы связываете [declent_ru(ACCUSATIVE)] с [multitool.buffer.declent_ru(INSTRUMENTAL)] из буфера мультитула."))

/obj/machinery/computer/civilian_bounty/click_alt(mob/user)
	id_eject(user)
	return CLICK_ACTION_SUCCESS

/obj/machinery/computer/civilian_bounty/proc/get_id_account()
	if(!inserted_scan_id)
		return
	return get_account_from_card(inserted_scan_id)

/obj/machinery/computer/civilian_bounty/proc/id_eject(mob/user)
	if(!inserted_scan_id)
		balloon_alert(user, "слот пуст!")
		return FALSE
	if(ishuman(user) && Adjacent(user))
		inserted_scan_id.forceMove_turf()
		user.put_in_hands(inserted_scan_id, ignore_anim = FALSE)
	else
		inserted_scan_id.forceMove(drop_location())
	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
	inserted_scan_id = null
	return TRUE

/obj/machinery/computer/civilian_bounty/proc/is_shippable(atom/movable/possible_shippable, obj/machinery/civilian_bounty_pad/pad)
	if(possible_shippable == pad || possible_shippable.anchored)
		return FALSE
	if(possible_shippable.flags & HOLOGRAM)
		return FALSE
	if(isitem(possible_shippable))
		var/obj/item/possible_shippable_item = possible_shippable
		if(possible_shippable_item.item_flags & ABSTRACT)
			return FALSE
	return isobj(possible_shippable)

/obj/machinery/computer/civilian_bounty/proc/recalc()
	if(sending)
		return
	var/datum/money_account/id_account = get_id_account()
	if(!id_account)
		status_report = "Сначала вставьте ID-карту."
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return
	if(!id_account.civilian_bounty)
		status_report = "Сначала возьмите новую гражданскую баунти."
		playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)
		return
	var/obj/machinery/civilian_bounty_pad/pad = pad_ref?.resolve()
	for(var/atom/movable/possible_shippable in get_turf(pad))
		if(!is_shippable(possible_shippable, pad))
			continue
		if(id_account.civilian_bounty.applies_to(possible_shippable))
			status_report = "Баунти: груз подходит."
			playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)
			return
	status_report = "Баунти: груз не подходит."
	playsound(loc, 'sound/machines/synth_no.ogg', 30, TRUE)

/obj/machinery/computer/civilian_bounty/proc/start_sending(check_global = FALSE, mob/user)
	var/obj/machinery/civilian_bounty_pad/pad = pad_ref?.resolve()
	if(!pad)
		status_report = "Платформа не найдена. Постройте или привяжите платформу."
		return
	if(pad.panel_open)
		status_report = "Закройте панель платформы отвёрткой, чтобы отправить груз."
		return
	if(sending)
		return
	sending = TRUE
	status_report = "Отправка..."
	pad.visible_message(span_notice("[DECLENT_RU_CAP(pad, NOMINATIVE)] начинает заряжаться."))
	pad.set_is_sending(TRUE)
	sending_timer = addtimer(CALLBACK(src, PROC_REF(send), check_global, user), warmup_time, TIMER_STOPPABLE)

/obj/machinery/computer/civilian_bounty/proc/stop_sending(custom_report)
	if(!sending)
		return
	sending = FALSE
	status_report = custom_report || "Готов к отправке."
	var/obj/machinery/civilian_bounty_pad/pad = pad_ref?.resolve()
	pad?.set_is_sending(FALSE)
	deltimer(sending_timer)

/obj/machinery/computer/civilian_bounty/proc/send(check_global = FALSE, mob/user)
	status_report = ""
	if(!sending)
		return FALSE
	var/datum/money_account/id_account = get_id_account()
	var/list/datum/bounty/bounty_stack = list()
	if(check_global)
		bounty_stack = GLOB.shared_crew_bounties.Copy()
	else if(id_account?.civilian_bounty)
		bounty_stack += id_account.civilian_bounty

	if(!length(bounty_stack) || !id_account)
		stop_sending()
		return FALSE

	var/active_count = 0
	var/obj/machinery/civilian_bounty_pad/pad = pad_ref?.resolve()
	for(var/atom/movable/possible_shippable in get_turf(pad))
		if(!is_shippable(possible_shippable, pad))
			continue
		for(var/datum/bounty/stack_item as anything in bounty_stack)
			if(!stack_item.applies_to(possible_shippable))
				continue
			active_count++
			stack_item.contribution[id_account] += stack_item.contribution_amount(possible_shippable)
			if(stack_item.contribution[id_account] <= 0)
				stack_item.contribution[id_account] = stack_item.contribution_amount(possible_shippable)
			stack_item.ship(possible_shippable)
			qdel(possible_shippable)
			break

	if(active_count)
		status_report += "Найдено целей баунти: [active_count]. "
	else
		status_report = "Подходящий груз не найден. Отмена. "
		stop_sending()

	var/claimed_count = 0
	for(var/datum/bounty/stack_item as anything in bounty_stack)
		if(!stack_item.can_claim())
			continue
		claimed_count++
		stack_item.claimed = TRUE
		stack_item.on_claimed(inserted_scan_id)
		if(check_global)
			SScapitalism.civ_bounty_tracker++
			for(var/datum/money_account/helper as anything in stack_item.contribution)
				if(istype(helper?.civilian_bounty, stack_item.type))
					helper.reset_bounty(inserted_scan_id)
					helper.notify_pda_owner("<b>Баунти </b>\"Ваша баунти \"[stack_item.name]\" засчитана вместе с выполненной общей баунти станции!\" (Невозможно Ответить)")
		else
			id_account.reset_bounty(inserted_scan_id)
		var/obj/item/bounty_cube/reward = new(drop_location())
		reward.set_up(stack_item, inserted_scan_id)

	if(claimed_count)
		status_report += "Выполнено баунти: [claimed_count]! Отдайте куб[claimed_count > 1 ? "ы" : ""] баунти снабжению для выплаты."

	if(check_global)
		update_global_bounty_list(round(CIV_BOUNTY_BASELINE + (SScapitalism.civ_bounty_tracker / 3)), FALSE)

	pad.visible_message(span_notice("[DECLENT_RU_CAP(pad, NOMINATIVE)] срабатывает!"))
	pad.finish_sending()
	playsound(loc, 'sound/machines/synth_yes.ogg', 30, TRUE)
	sending = FALSE
	SStgui.update_uis(src)
	return TRUE

/obj/machinery/computer/civilian_bounty/proc/add_bounties(mob/user, cooldown_reduction = 0)
	var/datum/money_account/id_account = get_id_account()
	if(!id_account)
		return FALSE
	if((id_account.civilian_bounty || id_account.bounties) && !COOLDOWN_FINISHED(id_account, bounty_timer))
		balloon_alert(user, "попробуйте через [DisplayTimeText(COOLDOWN_TIMELEFT(id_account, bounty_timer), 1)]!")
		return FALSE
	var/datum/job/job = id_account.linked_job
	if(!istype(job))
		atom_say("К счёту ID-карты не привязана должность!")
		return FALSE
	QDEL_LIST(id_account.bounties)
	id_account.bounties = job.generate_bounty_list()
	COOLDOWN_START(id_account, bounty_timer, (5 MINUTES) - cooldown_reduction)
	return TRUE

/obj/machinery/computer/civilian_bounty/proc/pick_bounty(choice)
	var/datum/money_account/id_account = get_id_account()
	if(!id_account || !ISINDEXSAFE(id_account.bounties, choice))
		playsound(loc, 'sound/machines/synth_no.ogg', 40, TRUE)
		return
	var/datum/bounty/picked = id_account.bounties[choice]
	id_account.bounties -= picked
	QDEL_LIST(id_account.bounties)
	id_account.bounties = null
	id_account.set_bounty(picked, inserted_scan_id)
	return picked

/obj/machinery/computer/civilian_bounty/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CivCargoHoldTerminal", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/computer/civilian_bounty/ui_data(mob/user)
	var/list/data = list()
	data["pad"] = !!pad_ref?.resolve()
	data["sending"] = sending
	data["status_report"] = status_report
	data["id_inserted"] = !!inserted_scan_id
	data["claimed_bounties"] = SScapitalism.civ_bounty_tracker
	data["bounty_cut"] = BOUNTY_CUT_STANDARD

	var/datum/money_account/id_account = get_id_account()
	if(id_account?.civilian_bounty)
		data["id_bounty_info"] = id_account.civilian_bounty.description
		data["id_bounty_num"] = id_account.bounty_num()
		data["id_bounty_value"] = id_account.civilian_bounty.get_bounty_reward() * BOUNTY_CUT_STANDARD
	data["picking"] = !!id_account?.bounties
	if(id_account?.bounties)
		data["id_bounty_names"] = list()
		data["id_bounty_infos"] = list()
		data["id_bounty_values"] = list()
		for(var/datum/bounty/bounty as anything in id_account.bounties)
			data["id_bounty_names"] += bounty.name
			data["id_bounty_infos"] += bounty.description
			data["id_bounty_values"] += bounty.get_bounty_reward() * BOUNTY_CUT_STANDARD

	var/list/global_bounties = list()
	for(var/datum/bounty/global_bounty as anything in GLOB.shared_crew_bounties)
		global_bounties += list(list(
			"name" = global_bounty.name,
			"description" = global_bounty.description,
			"reward" = global_bounty.get_bounty_reward(),
			"claimed" = global_bounty.claimed,
			"shipped" = global_bounty.get_total(),
			"maximum" = global_bounty.get_max(),
			"priority" = global_bounty.high_priority,
			"unique" = global_bounty.unique,
		))
	data["listBounty"] = global_bounties
	return data

/obj/machinery/computer/civilian_bounty/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	var/obj/machinery/civilian_bounty_pad/pad = pad_ref?.resolve()
	if(!pad || (stat & (NOPOWER|BROKEN)))
		return
	var/mob/user = ui.user
	. = TRUE
	switch(action)
		if("recalc")
			recalc()
		if("send")
			start_sending(params["global"], user)
		if("stop")
			stop_sending()
		if("pick")
			pick_bounty(text2num(params["value"]))
		if("bounty")
			add_bounties(user, pad.cooldown_reduction)
		if("eject")
			id_eject(user)
		if("update_list")
			var/bonus_bounties = clamp(round(length(GLOB.player_list) / 8), 0, 5)
			looped_global_update(1, CIV_BOUNTY_BASELINE + bonus_bounties, first_time = TRUE)
		if("print")
			print_sheet(user)

/obj/machinery/computer/civilian_bounty/proc/update_global_bounty_list(update_up_to = CIV_BOUNTY_BASELINE, enable_high_priority = FALSE, list/running_jobs)
	for(var/datum/bounty/complete_or_unique as anything in GLOB.shared_crew_bounties)
		if(complete_or_unique.claimed)
			GLOB.shared_crew_bounties -= complete_or_unique
			continue
		if(complete_or_unique.unique)
			update_up_to++

	var/list/jobs_picked = running_jobs || list()
	while(length(GLOB.shared_crew_bounties) < update_up_to && length(jobs_picked) < MAXIMUM_BOUNTY_JOBS)
		var/job_code = rand(CIV_JOB_BASIC, CIV_JOB_BITRUN)
		if(job_code in jobs_picked)
			continue
		jobs_picked += job_code

		var/datum/bounty/new_bounty = random_bounty(job_code)
		if(new_bounty.global_exempt)
			qdel(new_bounty)
			continue

		GLOB.shared_crew_bounties.Insert(1, new_bounty)
		if(enable_high_priority && prob(HIGH_PRIORITY_BOUNTY_ODDS))
			new_bounty.high_priority = TRUE
			new_bounty.description += "<br>Эта баунти отмечена как <b>приоритетная</b> и принесёт в <b>1,5 раза</b> больше обычного!"
	return jobs_picked

/obj/machinery/computer/civilian_bounty/proc/looped_global_update(current_count, update_to, list/inherited_list, first_time = FALSE)
	var/list/jobs_picked = update_global_bounty_list(current_count, enable_high_priority = TRUE, running_jobs = inherited_list)
	if(current_count >= update_to)
		if(first_time)
			setup_special_bounties()
		return TRUE
	addtimer(CALLBACK(src, PROC_REF(looped_global_update), current_count + 1, update_to, jobs_picked, first_time), 0.8 SECONDS)
	return FALSE

/obj/machinery/computer/civilian_bounty/proc/setup_special_bounties()
	for(var/special_type in subtypesof(/datum/bounty/item/special))
		GLOB.shared_crew_bounties += new special_type

/obj/machinery/computer/civilian_bounty/proc/print_sheet(mob/living/user)
	if(!COOLDOWN_FINISHED(src, sheet_printer_cooldown))
		balloon_alert(user, "принтер занят!")
		return FALSE

	var/obj/item/paper/paper = new(loc)
	paper.name = "paper - Bounties"
	var/list/printout_text = list("<center><h2>Баунти снабжения \"Нанотрейзен\"</h2></center>")
	for(var/datum/bounty/current_bounty as anything in GLOB.shared_crew_bounties)
		if(current_bounty.claimed)
			continue
		printout_text += {"<h3>[current_bounty.name]</h3>
			<ul>
			<li>Требуется: <i>[current_bounty.print_required()]</i></li>
			<li>Награда: <b>[current_bounty.get_bounty_reward()]</b> кр.</li>
			<li>Доля исполнителя: <b>[round(BOUNTY_CUT_STANDARD * current_bounty.get_bounty_reward())]</b> кр.</li>
			</ul>"}
	paper.info = printout_text.Join("")
	paper.update_appearance()
	playsound(src, 'sound/machines/printer.ogg', 100, TRUE)
	COOLDOWN_START(src, sheet_printer_cooldown, 4 SECONDS)
	return TRUE

/obj/item/civ_bounty_beacon
	name = "civilian bounty beacon"
	desc = "Одобренный \"Нанотрейзен\" маяк гражданских баунти. Активируйте его, и вам доставят платформу и терминал баунти."
	icon = 'icons/obj/machines/civilian_bounty.dmi'
	icon_state = "floor_beacon"
	var/uses = 2

/obj/item/civ_bounty_beacon/get_ru_names()
	return alist(
		NOMINATIVE = "маяк гражданских баунти",
		GENITIVE = "маяка гражданских баунти",
		DATIVE = "маяку гражданских баунти",
		ACCUSATIVE = "маяк гражданских баунти",
		INSTRUMENTAL = "маяком гражданских баунти",
		PREPOSITIONAL = "маяке гражданских баунти",
	)

/obj/item/civ_bounty_beacon/attack_self(mob/user)
	loc.visible_message(span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] начинает громко пищать!"))
	addtimer(CALLBACK(src, PROC_REF(launch_payload)), 1 SECONDS)

/obj/item/civ_bounty_beacon/proc/launch_payload()
	playsound(src, SFX_SPARKS, 80, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	switch(uses)
		if(2)
			new /obj/machinery/civilian_bounty_pad(drop_location())
		if(1)
			new /obj/machinery/computer/civilian_bounty(drop_location())
			qdel(src)
	uses--

#undef HIGH_PRIORITY_BOUNTY_ODDS
