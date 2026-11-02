/*
Destructive Analyzer

It is used to destroy hand-held objects and advance technological research. Controls are in the linked R&D console.

Note: Must be placed within 3 tiles of the R&D Console
*/
/obj/machinery/r_n_d/destructive_analyzer
	name = "Destructive Analyzer"
	desc = "Оборудование, предназначенное для проведения научных исследований методом обратной инженерии \
			путём разборки различных объектов. Управление происходит с помощью подключаемой консоли."
	icon_state = "d_analyzer"
	base_icon_state = "d_analyzer"
	var/decon_mod = 0
	var/list/item_queue = list()
	var/list/processing_queue = list()
	var/processing_timer

/obj/machinery/r_n_d/destructive_analyzer/get_ru_names()
	return alist(
		NOMINATIVE = "деструктивный анализатор",
		GENITIVE = "деструктивного анализатора",
		DATIVE = "деструктивному анализатору",
		ACCUSATIVE = "деструктивный анализатор",
		INSTRUMENTAL = "деструктивным анализатором",
		PREPOSITIONAL = "деструктивном анализаторе",
	)

/obj/machinery/r_n_d/destructive_analyzer/Initialize(mapload)
	. = ..()
	init_parts()
	RefreshParts()
	if(is_taipan(z))
		icon_state = "syndie_d_analyzer"
		base_icon_state = "syndie_d_analyzer"

/obj/machinery/r_n_d/destructive_analyzer/proc/init_parts()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/destructive_analyzer(null)
	component_parts += new /obj/item/stock_parts/scanning_module(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)

/obj/machinery/r_n_d/destructive_analyzer/upgraded/init_parts()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/destructive_analyzer(null)
	component_parts += new /obj/item/stock_parts/scanning_module/phasic(null)
	component_parts += new /obj/item/stock_parts/manipulator/pico(null)
	component_parts += new /obj/item/stock_parts/micro_laser/ultra(null)

/obj/machinery/r_n_d/destructive_analyzer/Destroy(force)
	deltimer(processing_timer)
	processing_timer = null
	loaded_item = null
	for(var/obj/item/queued_item as anything in item_queue)
		UnregisterSignal(queued_item, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
		queued_item.forceMove(drop_location())
	item_queue.Cut()
	processing_queue.Cut()
	if(linked_console)
		linked_console.linked_destroy = null
	return ..()

/obj/machinery/r_n_d/destructive_analyzer/RefreshParts()
	var/T = 0
	for(var/obj/item/stock_parts/S in component_parts)
		T += S.rating
	decon_mod = T

/obj/machinery/r_n_d/destructive_analyzer/proc/ConvertReqString2List(list/source_list)
	var/list/temp_list = params2list(source_list)
	for(var/O in temp_list)
		temp_list[O] = text2num(temp_list[O])
	return temp_list

/obj/machinery/r_n_d/destructive_analyzer/attackby(obj/item/I, mob/user, params)
	if(shocked && shock(user, 50))
		add_fingerprint(user)
		return ATTACK_CHAIN_BLOCKED_ALL

	if(user.a_intent == INTENT_HARM)
		return ..()

	if(exchange_parts(user, I))
		return ATTACK_CHAIN_PROCEED_SUCCESS

	add_fingerprint(user)
	if(disabled)
		balloon_alert(user, "отключено!")
		return ATTACK_CHAIN_PROCEED
	if(!linked_console)
		balloon_alert(user, "не подключено к консоли НИО!")
		return ATTACK_CHAIN_PROCEED
	if(busy)
		balloon_alert(user, "в процессе разборки!")
		return ATTACK_CHAIN_PROCEED
	// anomaly cores are only disassembed in the upgraded machine.
	// 3x4(femto-manipulator,quad-ultra micro-laser,triphasic scanning module)
	if(iscore(I) && (decon_mod < 12))
		balloon_alert(user, "слишком сложный объект!")
		return ATTACK_CHAIN_PROCEED
	if(!I.origin_tech)
		balloon_alert(user, "не подходит для анализа!")
		return ATTACK_CHAIN_PROCEED
	var/list/temp_tech = ConvertReqString2List(I.origin_tech)
	if(!length(temp_tech))
		balloon_alert(user, "не подходит для анализа!")
		return ATTACK_CHAIN_PROCEED
	if(!user.drop_transfer_item_to_loc(I, src))
		return ..()
	busy = TRUE
	flick("[base_icon_state]_insert", src)
	item_queue += I
	RegisterSignal(I, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED), PROC_REF(on_queued_item_removed))
	update_loaded_item()
	balloon_alert(user, "помещено в камеру разбора")
	processing_timer = addtimer(CALLBACK(src, PROC_REF(reset_processing)), 1 SECONDS, TIMER_STOPPABLE)
	return ATTACK_CHAIN_BLOCKED_ALL

/obj/machinery/r_n_d/destructive_analyzer/screwdriver_act_secondary(mob/living/user, obj/item/tool)
	if(shocked && shock(user, 50))
		add_fingerprint(user)
		return TRUE
	. = default_deconstruction_screwdriver(user, "[base_icon_state]_unscrewed", base_icon_state, tool)
	if(. && linked_console)
		linked_console.linked_destroy = null
		linked_console = null
		stop_processing()

/obj/machinery/r_n_d/destructive_analyzer/crowbar_act_secondary(mob/living/user, obj/item/tool)
	if(shocked && shock(user, 50))
		add_fingerprint(user)
		return TRUE
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/r_n_d/destructive_analyzer/proc/reset_processing()
	processing_timer = null
	busy = FALSE
	update_loaded_item()

/obj/machinery/r_n_d/destructive_analyzer/proc/stop_processing()
	deltimer(processing_timer)
	processing_queue.Cut()
	reset_processing()

/obj/machinery/r_n_d/destructive_analyzer/proc/update_loaded_item()
	loaded_item = length(processing_queue) ? processing_queue[1] : (length(item_queue) ? item_queue[1] : null)
	update_icon(UPDATE_ICON_STATE)
	if(linked_console)
		SStgui.update_uis(linked_console)

/obj/machinery/r_n_d/destructive_analyzer/proc/on_queued_item_removed(obj/item/source)
	SIGNAL_HANDLER
	if(!QDELING(source) && source.loc == src)
		return
	UnregisterSignal(source, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	item_queue -= source
	processing_queue -= source
	update_loaded_item()

/obj/machinery/r_n_d/destructive_analyzer/update_icon_state()
	if(loaded_item)
		icon_state = "[base_icon_state]_inserted"
	else
		icon_state = base_icon_state

