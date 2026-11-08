/obj/machinery/ship_engine/proc/get_power_apc() as /obj/machinery/power/apc
	if(!QDELETED(power_apc) && (power_apc.area == get_area(src) || vessel?.shuttle?.shuttle_areas[power_apc.area]) && (!vessel?.shuttle || vessel.shuttle.overmap_is_hull_turf(get_turf(power_apc))))
		return power_apc
	power_apc = null
	var/list/areas = list(get_area(src))
	for(var/area/place as anything in vessel?.shuttle?.shuttle_areas)
		areas |= place
	for(var/area/place as anything in areas)
		for(var/obj/machinery/power/apc/candidate as anything in place?.apc)
			if(!QDELETED(candidate) && (!vessel?.shuttle || vessel.shuttle.overmap_is_hull_turf(get_turf(candidate))))
				power_apc = candidate
				return candidate

/obj/machinery/ship_engine/proc/requires_apc_power()
	var/area/place = get_area(src)
	return requires_apc && (!place || place.requires_power || vessel?.programmed_profile()?.powered_engines)

/obj/machinery/ship_engine/proc/on_reserve_power()
	return requires_apc_power() && !get_power_apc()?.can_supply_equipment()

/obj/machinery/ship_engine/proc/burn_power_cost(elapsed)
	return active_power_usage * thrust_limit * elapsed / (1 SECONDS) * GLOB.CELLRATE

/obj/machinery/ship_engine/proc/fuel_available()
	return TRUE

/obj/machinery/ship_engine/proc/consume_fuel(elapsed)
	return TRUE

/obj/machinery/ship_engine/proc/resource_fraction(elapsed)
	if(!requires_apc_power() || !active_power_usage || !thrust_limit)
		return 1
	if(on_reserve_power())
		return OVERMAP_ENGINE_RESERVE_THRUST
	return clamp(get_power_apc().cell.charge / max(burn_power_cost(elapsed), 0.001), OVERMAP_ENGINE_RESERVE_THRUST, 1)

/obj/machinery/ship_engine/examine(mob/user)
	. = ..()
	. += span_notice("Состояние: [get_status()].")
	if(requires_apc_power())
		var/obj/machinery/power/apc/apc = get_power_apc()
		. += span_notice("Потребление при полной тяге: [active_power_usage] Вт. APC: [apc ? "[apc.name], заряд [round(apc.cell?.percent() || 0)]%" : "не найден"].")

/obj/machinery/ship_engine/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, "[icon_state]", "[icon_state]", tool)

/obj/machinery/ship_engine/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/ship_engine/wrench_act(mob/living/user, obj/item/tool)
	if(firing || !tool.use_tool(src, user, 1 SECONDS, volume = tool.tool_volume))
		return TRUE
	setDir(turn(dir, 90))
	var/obj/machinery/ship_engine/plasma/plasma = src
	if(istype(plasma))
		plasma.fuel_port?.set_inlet_direction(REVERSE_DIR(dir))
	update_icon(UPDATE_OVERLAYS)
	return TRUE
