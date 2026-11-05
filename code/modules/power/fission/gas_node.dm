#define MINIMUM_MOLES 3 //! the minimum amount of moles we transfer, regardless of pressure on the other side.

/obj/machinery/atmospherics/unary/reactor_gas_node
	name = "reactor gas intake"
	desc = "Узел газообмена с активной зоной реактора. Работает как пассивный клапан: мультитул переключает направление потока."
	icon = 'icons/obj/fission/reactor_machines.dmi'
	icon_state = "gas_node"
	layer = GAS_PIPE_VISIBLE_LAYER
	max_integrity = 2000
	var/target_pressure = 100000 // Maximum pressure in KPA
	resistance_flags = parent_type::resistance_flags | NO_MALF_EFFECT

	/// Hold which reactor the intake is connected to.
	var/obj/machinery/atmospherics/fission_reactor/linked_reactor
	/// Is this vent taking air in or out. TRUE by default.
	var/intake_vent = TRUE

/obj/machinery/atmospherics/unary/reactor_gas_node/output
	name = "Reactor Gas Extractor"
	intake_vent = FALSE

/obj/machinery/atmospherics/unary/reactor_gas_node/get_ru_names()
	return flow_ru_names(TRUE)

/obj/machinery/atmospherics/unary/reactor_gas_node/output/get_ru_names()
	return flow_ru_names(FALSE)

/obj/machinery/atmospherics/unary/reactor_gas_node/proc/flow_ru_names(intake)
	var/prefix = intake ? "впускн" : "выпускн"
	return alist(
		NOMINATIVE = "[prefix]ой газовый узел",
		GENITIVE = "[prefix]ого газового узла",
		DATIVE = "[prefix]ому газовому узлу",
		ACCUSATIVE = "[prefix]ой газовый узел",
		INSTRUMENTAL = "[prefix]ым газовым узлом",
		PREPOSITIONAL = "[prefix]ом газовом узле",
	)

/obj/machinery/atmospherics/unary/reactor_gas_node/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/reactor_gas_node(src)
	component_parts += new /obj/item/stack/sheet/metal(src, 2)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	initialize_directions = dir
	RefreshParts()
	update_icon()
	return INITIALIZE_HINT_LATELOAD

// Needs lateload to prevent reactor not being initialized yet and thus not able to set the link.
/obj/machinery/atmospherics/unary/reactor_gas_node/LateInitialize()
	. = ..()
	form_link(TRUE)

/obj/machinery/atmospherics/unary/reactor_gas_node/examine(mob/user)
	. = ..()
	. += span_notice("Гаечный ключ меняет сторону подключения трубы.")
	. += span_notice("Узел подключается к реактору, только если реактор находится с противоположной от трубы стороны.")

/obj/machinery/atmospherics/unary/reactor_gas_node/proc/get_reactor_gas()
	return linked_reactor.air_contents

/obj/machinery/atmospherics/unary/reactor_gas_node/process_atmos()
	if(stat & (NOPOWER|BROKEN))
		return FALSE

	if(!linked_reactor)
		return FALSE

	if(linked_reactor.admin_intervention)
		return FALSE

	if(linked_reactor.safety_override) // We dont want to cool down an intentional runaway reactor
		return FALSE

	var/datum/gas_mixture/network1
	var/datum/gas_mixture/network2

	if(intake_vent)
		network1 = get_reactor_gas()
		network2 = air_contents
	else
		network1 = air_contents
		network2 = get_reactor_gas()

	if(!network1 || !network2)
		return FALSE

	// This is basically passive gate code
	var/output_starting_pressure = network1.return_pressure()
	var/input_starting_pressure = network2.return_pressure()

	// Calculate necessary moles to transfer using PV = nRT
	if((network2.total_moles() > 0) && (network2.temperature() > 0))
		var/pressure_delta = min(target_pressure - output_starting_pressure, (input_starting_pressure - output_starting_pressure) / 2)
		if(intake_vent)
			pressure_delta = max(pressure_delta, MINIMUM_MOLES) // Always work at least a little bit when inputting gas
		var/transfer_moles = pressure_delta * network1.volume / (network2.temperature() * R_IDEAL_GAS_EQUATION)

		// Actually transfer the gas
		var/datum/gas_mixture/removed = network2.remove(transfer_moles)
		network1.merge(removed)

		parent.update = TRUE

	return TRUE

/obj/machinery/atmospherics/unary/reactor_gas_node/screwdriver_act(mob/living/user, obj/item/I)
	default_deconstruction_screwdriver(user, icon_state, icon_state, I)

/obj/machinery/atmospherics/unary/reactor_gas_node/crowbar_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("Вы начинаете выламывать внутренние трубы..."))
	if(I.use_tool(src, user, 3 SECONDS, volume = I.tool_volume))
		default_deconstruction_crowbar(user, I)

/obj/machinery/atmospherics/unary/reactor_gas_node/wrench_act(mob/user, obj/item/I)
	var/list/choices = list("Запад" = WEST, "Восток" = EAST, "Юг" = SOUTH, "Север" = NORTH)
	var/selected = tgui_input_list(user, "Выберите сторону подключения трубы.", "Направление узла", choices)
	if(!selected)
		return TRUE
	if(!I.use_tool(src, user, 3 SECONDS, volume = I.tool_volume))
		return TRUE
	if(!IsReachableBy(user))
		to_chat(user, span_warning("Вы отошли слишком далеко!"))
		return TRUE
	dir = choices[selected]
	initialize_directions = dir
	for(var/obj/machinery/atmospherics/target in get_step(src, dir))
		if(target.initialize_directions & get_dir(target,src))
			node = target
			break
	form_link(FALSE)
	initialize_atmos_network()
	update_icon()
	return TRUE

/obj/machinery/atmospherics/unary/reactor_gas_node/proc/form_link(silent = FALSE)
	linked_reactor = null
	var/turf/T = get_step(src, REVERSE_DIR(dir))
	for(var/obj/machinery/atmospherics/fission_reactor/reactor in T)
		linked_reactor = reactor
	for(var/obj/structure/filler/filler in T)
		if(istype(filler.parent, /obj/machinery/atmospherics/fission_reactor))
			linked_reactor = filler.parent
	if(silent)
		return
	if(!linked_reactor)
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		audible_message(span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] пищит: реактор не найден."))
	else
		playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
		audible_message(span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] звенит, подключившись к реактору."))

/obj/machinery/atmospherics/unary/reactor_gas_node/multitool_act(mob/living/user, obj/item/I)
	. = TRUE
	to_chat(user, span_notice("Вы начинаете переключать направление потока..."))
	if(do_after(user, 1 SECONDS, src))
		intake_vent = !intake_vent
		name = intake_vent ? "Reactor Gas Intake" : "Reactor Gas Extractor"
		ru_names = flow_ru_names(intake_vent)

/obj/machinery/atmospherics/unary/reactor_gas_node/moderator
	name = "Reactor Gas Moderator"
	desc = "Подаёт газ в камеру замедлителя. Каждый цикл реактора весь газ в ней расходуется."

/obj/machinery/atmospherics/unary/reactor_gas_node/moderator/get_ru_names()
	return alist(
		NOMINATIVE = "узел подачи замедлителя",
		GENITIVE = "узла подачи замедлителя",
		DATIVE = "узлу подачи замедлителя",
		ACCUSATIVE = "узел подачи замедлителя",
		INSTRUMENTAL = "узлом подачи замедлителя",
		PREPOSITIONAL = "узле подачи замедлителя",
	)


/obj/machinery/atmospherics/unary/reactor_gas_node/moderator/Initialize(mapload)
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/reactor_moderator_gas_node(src)
	component_parts += new /obj/item/stack/sheet/metal(src, 2)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	initialize_directions = dir
	RefreshParts()
	update_icon()

/obj/machinery/atmospherics/unary/reactor_gas_node/moderator/get_reactor_gas()
	return linked_reactor.moderator_gas

/obj/machinery/atmospherics/unary/reactor_gas_node/moderator/multitool_act(mob/living/user, obj/item/I)
	return

#undef MINIMUM_MOLES
