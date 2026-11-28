/obj/machinery/ship_engine/proc/fuel_available()
	return TRUE

/obj/machinery/ship_engine/proc/consume_fuel(elapsed)
	return TRUE

/obj/machinery/ship_engine/proc/resource_fraction(elapsed)
	return 1

/obj/machinery/ship_engine/examine(mob/user)
	. = ..()
	. += span_notice("Состояние: [get_status()].")

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
