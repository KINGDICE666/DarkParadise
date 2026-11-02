#define PIPE_DISPENSER_COOLDOWN (0.4 SECONDS)

/obj/machinery/pipedispenser
	name = "pipe dispenser"
	icon_state = "pipe_d"
	density = TRUE
	anchored = TRUE
	interact_offline = TRUE
	interaction_flags_mouse_drop = NEED_DEXTERITY
	COOLDOWN_DECLARE(dispense_cooldown)

/obj/machinery/pipedispenser/attack_hand(mob/user)
	if(..())
		return TRUE

	ui_interact(user)

/obj/machinery/pipedispenser/attack_ghost(mob/user)
	ui_interact(user)

/obj/machinery/pipedispenser/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PipeDispenser", name)
		ui.open()

/obj/machinery/pipedispenser/ui_static_data(mob/user)
	var/list/recipes_by_category = list()
	for(var/datum/pipes/pipe as anything in GLOB.construction_pipe_list)
		var/category_name = get_recipe_category(pipe)
		if(!category_name)
			continue
		LAZYADDASSOCLIST(recipes_by_category, category_name, list(
			"pipe_name" = capitalize(pipe.pipe_name),
			"pipe_id" = pipe.pipe_id,
			"icon" = pipe.pipe_icon_file,
			"icon_state" = pipe.pipe_icon,
			"dir" = get_dispense_dir(pipe),
		))

	var/list/categories = list()
	for(var/category_name in recipes_by_category)
		categories += list(list("cat_name" = category_name, "recipes" = recipes_by_category[category_name]))
	return list("categories" = categories)

/obj/machinery/pipedispenser/ui_act(action, list/params)
	if(..() || !anchored)
		return

	if(action != "dispense" || !COOLDOWN_FINISHED(src, dispense_cooldown))
		return

	var/pipe_id = params["pipe_id"]
	for(var/datum/pipes/pipe as anything in GLOB.construction_pipe_list)
		if(pipe.pipe_id != pipe_id || !get_recipe_category(pipe))
			continue
		COOLDOWN_START(src, dispense_cooldown, PIPE_DISPENSER_COOLDOWN)
		var/atom/movable/dispensed = dispense(pipe)
		dispensed.add_fingerprint(usr)
		add_fingerprint(usr)
		return TRUE

/obj/machinery/pipedispenser/proc/get_recipe_category(datum/pipes/pipe)
	if(pipe.pipe_type != PIPETYPE_ATMOS)
		return
	if(istype(pipe, /datum/pipes/atmospheric/insulated))
		return "Insulated"
	if(!pipe.rpd_dispensable)
		return
	switch(pipe.pipe_category)
		if(RPD_ATMOS_PIPING)
			return "Pipes"
		if(RPD_SUPPLY_PIPING)
			return "Supply"
		if(RPD_SCRUBBERS_PIPING)
			return "Scrubbers"
		if(RPD_DEVICES)
			return "Devices"
		if(RPD_HEAT_PIPING)
			return "Heat Exchange"

/obj/machinery/pipedispenser/proc/get_dispense_dir(datum/pipes/pipe)
	if(pipe.pipe_type != PIPETYPE_ATMOS)
		return SOUTH
	return pipe.bendy ? NORTHEAST : NORTH

/obj/machinery/pipedispenser/proc/dispense(datum/pipes/pipe)
	switch(pipe.pipe_type)
		if(PIPETYPE_DISPOSAL)
			return new /obj/structure/disposalconstruct(loc, pipe.pipe_id)
		if(PIPETYPE_TRANSIT)
			var/datum/pipes/transit/tube = pipe
			return new tube.construct_type(loc)
	switch(pipe.pipe_id)
		if(PIPE_METER)
			return new /obj/item/pipe_meter(loc)
		if(PIPE_GAS_SENSOR)
			return new /obj/item/pipe_gsensor(loc)
	return new /obj/item/pipe(loc, pipe.pipe_id, get_dispense_dir(pipe))

/obj/machinery/pipedispenser/wrench_act(mob/living/user, obj/item/I)
	. = TRUE
	var/prev_state = anchored
	to_chat(user, span_notice("You begin to [anchored ? "un" : ""]fasten [src] [anchored ? "from" : "to"] the floor..."))
	if(!I.use_tool(src, user, 4 SECONDS, volume = I.tool_volume) || anchored != prev_state)
		return .
	set_anchored(!anchored)
	if(anchored)
		stat &= ~MAINT
		user.visible_message(
			span_notice("[user] fastens [src]."),
			span_notice("You have fastened [src]. Now it can dispense pipes."),
			span_italics("You hear ratchet."),
		)
	else
		stat |= MAINT
		user.visible_message(
			span_notice("[user] unfastens [src]."),
			span_notice("You have unfastened [src]. Now it can be pulled somewhere else."),
			span_italics("You hear ratchet."),
		)

/obj/machinery/pipedispenser/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(istype(I, /obj/item/pipe) || istype(I, /obj/item/pipe_meter) || istype(I, /obj/item/pipe_gsensor))
		if(!user.drop_transfer_item_to_loc(I, src))
			return ..()
		add_fingerprint(user)
		to_chat(user, span_notice("You put [I] back to [src]."))
		qdel(I)
		return ATTACK_CHAIN_BLOCKED_ALL

	return ..()

/obj/machinery/pipedispenser/disposal
	name = "Disposal Pipe Dispenser"

//Allow you to drag-drop disposal pipes and transit tubes into it
/obj/machinery/pipedispenser/disposal/mouse_drop_receive(obj/structure/pipe, mob/user, params)
	if(user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return

	if(!istype(pipe, /obj/structure/disposalconstruct) && !istype(pipe, /obj/structure/c_transit_tube) && !istype(pipe, /obj/structure/c_transit_tube_pod))
		return

	if(get_dist(user, src) > 1 || get_dist(src, pipe) > 1)
		return

	if(pipe.anchored)
		return

	qdel(pipe)

/obj/machinery/pipedispenser/disposal/get_recipe_category(datum/pipes/pipe)
	if(!pipe.rpd_dispensable)
		return
	switch(pipe.pipe_type)
		if(PIPETYPE_DISPOSAL)
			return "Disposals"
		if(PIPETYPE_TRANSIT)
			return "Transit Tubes"

#undef PIPE_DISPENSER_COOLDOWN
