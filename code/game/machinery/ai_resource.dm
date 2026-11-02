GLOBAL_LIST_EMPTY(ai_nodes)

#define ALLOCATED_RESOURCES 0
#define ONLINE_NODES 1

/obj/machinery/ai_node
	name = "AI Node"
	desc = "Если вы это видите, сообщите о баге!"
	icon = 'icons/obj/machines/ai_machinery.dmi'
	icon_state = "processor-off"
	density = TRUE
	anchored = TRUE
	max_integrity = 100
	idle_power_usage = 5
	active_power_usage = 750
	var/icon_base
	var/active = FALSE
	var/mob/living/silicon/ai/assigned_ai = null
	var/resource_key
	var/resource_name
	var/resource_amount = 1
	var/heat_amount = 25000
	var/overheating = FALSE
	var/overheat_temp = 324
	var/overheat_counter = 0
	var/efficiency = 1
	var/datum/milla_safe/ai_node_process/milla = new()

/obj/machinery/ai_node/get_ru_names()
	return alist(
		NOMINATIVE = "узел ИИ",
		GENITIVE = "узла ИИ",
		DATIVE = "узлу ИИ",
		ACCUSATIVE = "узел ИИ",
		INSTRUMENTAL = "узлом ИИ",
		PREPOSITIONAL = "узле ИИ",
	)

/obj/machinery/ai_node/Initialize(mapload)
	. = ..()
	GLOB.ai_nodes += src

/obj/machinery/ai_node/examine(mob/user)
	. = ..()
	. += span_notice("Машина чувствительна к температуре: ниже 273K она замерзает, а выше [overheat_temp]K — перегревается.")

/obj/machinery/ai_node/process()
	..()
	if(active)
		if(stat & NOPOWER)
			atom_say("ОШИБКА: недостаточно энергии! Отключение...")
			turn_off()
			return
		milla.invoke_async(src)

/obj/machinery/ai_node/Destroy()
	turn_off()
	GLOB.ai_nodes -= src
	QDEL_NULL(milla)
	return ..()

/obj/machinery/ai_node/on_deconstruction()
	. = ..()
	if(assigned_ai)
		assigned_ai.program_picker.modify_resource(resource_key, -resource_amount)
		assigned_ai = null
	GLOB.ai_nodes -= src

/obj/machinery/ai_node/screwdriver_act(mob/living/user, obj/item/I)
	if(!I.use_tool(src, user, 0, volume = 0))
		return
	. = TRUE
	default_deconstruction_screwdriver(user, icon_state, icon_state, I)

/obj/machinery/ai_node/default_deconstruction_screwdriver(mob/user, icon_state_open, icon_state_closed, obj/item/I)
	. = ..()
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/ai_node/crowbar_act(mob/living/user, obj/item/I)
	if(default_deconstruction_crowbar(user, I))
		return TRUE

/obj/machinery/ai_node/update_icon_state()
	. = ..()
	if(overheating)
		icon_state = "[icon_base]-hot"
		return
	if(panel_open)
		icon_state = "[icon_base]-open"
		return
	icon_state = "[icon_base]-[active ? "on" : "off"]"

/obj/machinery/ai_node/attack_ai(mob/user)
	return

/obj/machinery/ai_node/RefreshParts()
	var/E
	for(var/obj/item/stock_parts/capacitor/M in component_parts)
		E += M.rating
	efficiency = E / 2
	heat_amount = initial(heat_amount) * efficiency
	overheat_temp = initial(overheat_temp) + (50 * efficiency)
	idle_power_usage = initial(idle_power_usage) * efficiency
	active_power_usage = initial(active_power_usage) * efficiency
	var/old_resource_amount = resource_amount
	resource_amount = round_down(initial(resource_amount) * efficiency)
	if(assigned_ai)
		assigned_ai.program_picker.modify_resource(resource_key, (resource_amount - old_resource_amount))

/obj/machinery/ai_node/attack_hand(mob/user)
	toggle(user)

/obj/machinery/ai_node/proc/toggle(mob/user = null)
	if(overheating)
		if(user)
			to_chat(user, span_notice("Вы выключаете перегревшийся [declent_ru(ACCUSATIVE)]."))
		overheating = FALSE
		update_icon(UPDATE_ICON_STATE)
		return
	active = !active
	if(user)
		to_chat(user, span_notice("Вы [active ? "включаете" : "выключаете"] [declent_ru(ACCUSATIVE)]."))
	if(active)
		refresh_ai()
	else
		turn_off()
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/ai_node/proc/refresh_ai()
	assigned_ai = null
	find_ai()
	if(!assigned_ai)
		active = FALSE
		atom_say("ОШИБКА: ИИ не обнаружен. Отключение...")
		turn_off()
	else
		assigned_ai.program_picker.modify_resource(resource_key, resource_amount)
		var/area/our_area = get_area(src)
		to_chat(assigned_ai, span_notice("Подключён новый серверный узел: [our_area.name]."))
		update_use_power(ACTIVE_POWER_USE)
		update_icon(UPDATE_ICON_STATE)

/obj/machinery/ai_node/proc/turn_off()
	active = FALSE
	if(assigned_ai)
		assigned_ai.program_picker.modify_resource(resource_key, -resource_amount)
		var/area/our_area = get_area(src)
		to_chat(assigned_ai, span_warning("Серверный узел отключён: [our_area.name]!"))
		assigned_ai = null
	update_use_power(IDLE_POWER_USE)
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/ai_node/proc/find_ai()
	if(!resource_key)
		return
	for(var/mob/living/silicon/ai/new_ai as anything in GLOB.ai_list)
		if(new_ai.stat || new_ai.shunted)
			continue
		if(isapc(new_ai.loc))
			continue
		if(!assigned_ai)
			assigned_ai = new_ai
			continue
		if(resource_key == "memory" && assigned_ai.program_picker.memory > new_ai.program_picker.memory)
			assigned_ai = new_ai
			continue
		if(resource_key == "bandwidth" && assigned_ai.program_picker.bandwidth > new_ai.program_picker.bandwidth)
			assigned_ai = new_ai

/obj/machinery/ai_node/proc/overheat()
	turn_off()
	overheating = TRUE
	atom_say("ОШИБКА: критический перегрев!")
	take_damage(max_integrity / 3, BRUTE, sound_effect = FALSE)
	update_use_power(IDLE_POWER_USE)
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/ai_node/proc/change_ai(mob/living/silicon/ai/new_ai)
	if(!istype(new_ai) || !assigned_ai)
		return
	var/area/our_area = get_area(src)
	assigned_ai.program_picker.modify_resource(resource_key, -resource_amount)
	to_chat(assigned_ai, span_warning("Серверный узел отключён: [our_area.name]!"))
	assigned_ai = new_ai
	assigned_ai.program_picker.modify_resource(resource_key, resource_amount)
	to_chat(assigned_ai, span_notice("Подключён новый серверный узел: [our_area.name]."))

/datum/milla_safe/ai_node_process

/datum/milla_safe/ai_node_process/on_run(obj/machinery/ai_node/node)
	var/turf/simulated/L = get_turf(node)
	if(!istype(L))
		return
	var/datum/gas_mixture/env = get_turf_air(L)
	var/transfer_moles = 0.25 * env.total_moles()
	var/datum/gas_mixture/removed = env.remove(transfer_moles)
	if(!removed)
		node.overheat_counter++
		if(node.overheat_counter >= 5)
			node.overheat()
		return
	var/heat_capacity = removed.heat_capacity()
	if(heat_capacity)
		removed.set_temperature(removed.temperature() + node.heat_amount / heat_capacity)
	env.merge(removed)
	if(env.temperature() > node.overheat_temp || env.temperature() < 273)
		node.overheat_counter++
		if(node.overheat_counter >= 5)
			node.overheat()
		return
	if(node.overheat_counter)
		node.overheat_counter--

/obj/machinery/ai_node/processing_node
	name = "processing node"
	desc = "Стойка процессоров с ручным выключателем. Во время работы даёт ИИ память."
	resource_key = "memory"
	resource_name = "память"
	icon_base = "processor"

/obj/machinery/ai_node/processing_node/get_ru_names()
	return alist(
		NOMINATIVE = "вычислительный узел",
		GENITIVE = "вычислительного узла",
		DATIVE = "вычислительному узлу",
		ACCUSATIVE = "вычислительный узел",
		INSTRUMENTAL = "вычислительным узлом",
		PREPOSITIONAL = "вычислительном узле",
	)

/obj/machinery/ai_node/processing_node/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/processing_node(null)
	component_parts += new /obj/item/stock_parts/capacitor(null)
	component_parts += new /obj/item/stock_parts/capacitor(null)
	component_parts += new /obj/item/stack/sheet/mineral/gold(null)
	component_parts += new /obj/item/stack/sheet/mineral/silver(null)
	component_parts += new /obj/item/stack/cable_coil(null, 5)
	component_parts += new /obj/item/stack/sheet/mineral/diamond(null)
	RefreshParts()

/obj/machinery/ai_node/processing_node/upgraded/Initialize(mapload)
	. = ..()
	QDEL_LIST(component_parts)
	component_parts = list()
	component_parts += new /obj/item/circuitboard/processing_node(null)
	component_parts += new /obj/item/stock_parts/capacitor/quadratic(null)
	component_parts += new /obj/item/stock_parts/capacitor/quadratic(null)
	component_parts += new /obj/item/stack/sheet/mineral/gold(null)
	component_parts += new /obj/item/stack/sheet/mineral/silver(null)
	component_parts += new /obj/item/stack/cable_coil(null, 5)
	component_parts += new /obj/item/stack/sheet/mineral/diamond(null)
	RefreshParts()

/obj/machinery/ai_node/network_node
	name = "network node"
	desc = "Стойка серверов с ручным выключателем. Во время работы даёт ИИ пропускную способность."
	icon_state = "network-off"
	resource_key = "bandwidth"
	resource_name = "пропускная способность"
	icon_base = "network"

/obj/machinery/ai_node/network_node/get_ru_names()
	return alist(
		NOMINATIVE = "сетевой узел",
		GENITIVE = "сетевого узла",
		DATIVE = "сетевому узлу",
		ACCUSATIVE = "сетевой узел",
		INSTRUMENTAL = "сетевым узлом",
		PREPOSITIONAL = "сетевом узле",
	)

/obj/machinery/ai_node/network_node/examine_more(mob/user)
	. = ..()
	. += "Мне сказали по секрету: \
	Капитан узлом сетевым \
	Щёлкает с утра до света — \
	Стукачом слывёт штабным!"

/obj/machinery/ai_node/network_node/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/network_node(null)
	component_parts += new /obj/item/stock_parts/capacitor(null)
	component_parts += new /obj/item/stock_parts/capacitor(null)
	component_parts += new /obj/item/stack/sheet/mineral/gold(null)
	component_parts += new /obj/item/stack/sheet/mineral/silver(null)
	component_parts += new /obj/item/stack/cable_coil(null, 5)
	RefreshParts()

/obj/machinery/ai_node/network_node/upgraded/Initialize(mapload)
	. = ..()
	QDEL_LIST(component_parts)
	component_parts = list()
	component_parts += new /obj/item/circuitboard/network_node(null)
	component_parts += new /obj/item/stock_parts/capacitor/quadratic(null)
	component_parts += new /obj/item/stock_parts/capacitor/quadratic(null)
	component_parts += new /obj/item/stack/sheet/mineral/gold(null)
	component_parts += new /obj/item/stack/sheet/mineral/silver(null)
	component_parts += new /obj/item/stack/cable_coil(null, 5)
	RefreshParts()

/obj/machinery/computer/ai_resource
	name = "AI Resource Control Console"
	desc = "Используется для перераспределения памяти и пропускной способности между несколькими ИИ."
	icon_keyboard = "rd_key"
	icon_screen = "ai_resource"
	req_access = list(ACCESS_RD)
	circuit = /obj/item/circuitboard/ai_resource_console
	light_color = LIGHT_COLOR_PURPLE
	var/screen = ALLOCATED_RESOURCES

/obj/machinery/computer/ai_resource/get_ru_names()
	return alist(
		NOMINATIVE = "консоль управления ресурсами ИИ",
		GENITIVE = "консоли управления ресурсами ИИ",
		DATIVE = "консоли управления ресурсами ИИ",
		ACCUSATIVE = "консоль управления ресурсами ИИ",
		INSTRUMENTAL = "консолью управления ресурсами ИИ",
		PREPOSITIONAL = "консоли управления ресурсами ИИ",
	)

/obj/machinery/computer/ai_resource/attack_ai(mob/user)
	to_chat(user, span_warning("ОШИБКА: заблокировано брандмауэром! Станционным ИИ запрещено работать с этой консолью!"))
	return

/obj/machinery/computer/ai_resource/attack_hand(mob/user)
	if(..())
		return TRUE
	if(stat & (NOPOWER|BROKEN))
		return
	ui_interact(user)

/obj/machinery/computer/ai_resource/proc/is_authenticated(mob/user)
	if(!istype(user))
		return FALSE
	if(user.can_admin_interact())
		return TRUE
	if(allowed(user))
		return TRUE
	return FALSE

/obj/machinery/computer/ai_resource/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/ai_resource/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AIResourceManagementConsole", DECLENT_RU_CAP(src, NOMINATIVE))
		ui.open()

/obj/machinery/computer/ai_resource/ui_data(mob/user)
	var/list/data = list()
	data["auth"] = is_authenticated(user)
	data["screen"] = screen
	data["ai_list"] = list()
	data["nodes_list"] = list()
	for(var/mob/living/silicon/ai/A as anything in GLOB.ai_list)
		if(isapc(A.loc))
			continue
		if(A.shunted)
			continue
		var/list/ai_data = list(
			"name" = A.name,
			"uid" = A.UID(),
			"memory" = A.program_picker.memory,
			"memory_max" = A.program_picker.total_memory,
			"bandwidth" = A.program_picker.bandwidth,
			"bandwidth_max" = A.program_picker.total_bandwidth
		)
		data["ai_list"] += list(ai_data)
	for(var/obj/machinery/ai_node/node as anything in GLOB.ai_nodes)
		var/list/node_data = list(
			"name" = node.declent_ru(NOMINATIVE),
			"uid" = node.UID(),
			"resource" = node.resource_name,
			"amount" = node.resource_amount,
			"assigned_ai" = node.assigned_ai?.name
		)
		data["nodes_list"] += list(node_data)
	return data

/obj/machinery/computer/ai_resource/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	. = FALSE
	if(!is_authenticated(ui.user))
		to_chat(ui.user, span_warning("Доступ запрещён."))
		return
	if(SSticker.current_state == GAME_STATE_FINISHED)
		to_chat(ui.user, span_warning("Доступ запрещён: ИИ больше не принадлежат вашей станции."))
		return

	switch(action)
		if("menu")
			switch(text2num(params["screen"]))
				if(ALLOCATED_RESOURCES)
					screen = ALLOCATED_RESOURCES
					return TRUE
				if(ONLINE_NODES)
					screen = ONLINE_NODES
					return TRUE
		if("reassign")
			if(!length(GLOB.ai_list))
				return FALSE
			var/list/ais = list()
			for(var/mob/living/silicon/ai/new_ai as anything in GLOB.ai_list)
				if(new_ai.stat || new_ai.shunted)
					continue
				if(isapc(new_ai.loc))
					continue
				ais += new_ai
			var/new_ai = tgui_input_list(ui.user, "Выберите новый ИИ", "Выбор ИИ", ais)
			if(!new_ai)
				return FALSE
			var/obj/machinery/ai_node/selected_node = locateUID(params["uid"])
			if(!istype(selected_node))
				return FALSE
			selected_node.change_ai(new_ai)
			return TRUE

#undef ALLOCATED_RESOURCES
#undef ONLINE_NODES
