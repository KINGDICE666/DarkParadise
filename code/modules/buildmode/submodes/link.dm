/obj/effect/portal/rick/buildmode
	force_teleport = TRUE
	ignore_tele_proof_area_setting = TRUE

/datum/buildmode_mode/link
	key = "link"

	var/list/link_lines = list()
	var/obj/link_obj
	var/datum/weakref/pending_portal_ref
	var/portal_color

/datum/buildmode_mode/link/proc/clear_lines()
	QDEL_LIST(link_lines)

/datum/buildmode_mode/link/proc/form_connection(atom/source, atom/dest, valid)
	var/obj/effect/buildmode_line/L = new(get_turf(source), BM.holder, source, dest, "[source.name] to [dest.name]")
	L.color = valid ? "#339933" : "#993333"
	link_lines += L
	var/obj/effect/buildmode_line/L2 = new(get_turf(dest), BM.holder, dest, source, "[dest.name] to [source.name]") // Yes, reversed one so that you can see it source both sides.
	L2.color = L.color
	link_lines += L2

/datum/buildmode_mode/link/Destroy()
	clear_lines()
	link_obj = null
	pending_portal_ref = null
	return ..()

/datum/buildmode_mode/link/Reset()
	clear_lines()
	link_obj = null
	pending_portal_ref = null
	..()

/datum/buildmode_mode/link/show_help(mob/user)
	to_chat(user, span_purple(boxed_message(
		"[span_bold("Select button to link")] -> Left Mouse Button on obj\n\
		[span_bold("Link/unlink to selected button")] -> Right Mouse Button on obj\n\
		[span_bold("Open portal / open linked exit")] -> Left Mouse Button on turf\n\
		[span_bold("Open portal to an area")] -> Ctrl + Left Mouse Button on turf\n\
		[span_bold("Close portal pair")] -> Right Mouse Button on portal\n\
		[span_bold("Portal color")] -> Right Mouse Button on buildmode button"))
	)

/datum/buildmode_mode/link/change_settings(mob/user)
	var/new_color = tgui_input_color(user, "Portal color", "Buildmode", portal_color || "#43F45B")
	if(new_color)
		portal_color = new_color

/datum/buildmode_mode/link/proc/open_portal(mob/user, turf/portal_turf, turf/target_turf)
	if(locate(/obj/effect/portal) in portal_turf)
		to_chat(user, span_warning("There is already a portal at [AREACOORD(portal_turf)]."))
		return
	var/obj/effect/portal/portal = new /obj/effect/portal/rick/buildmode(portal_turf, target_turf, null, 0, user, FALSE)
	if(portal_color)
		portal.color = portal_color
		portal.set_light_color(portal_color)
	log_admin("Build Mode: [key_name(user)] opened a portal at [AREACOORD(portal_turf)][target_turf ? " leading to [AREACOORD(target_turf)]" : ""]")
	return portal

/datum/buildmode_mode/link/proc/link_portals(mob/user, obj/effect/portal/entrance, turf/exit_turf)
	var/obj/effect/portal/exit = open_portal(user, exit_turf, get_turf(entrance))
	if(!exit)
		pending_portal_ref = WEAKREF(entrance)
		return
	entrance.target = exit_turf
	clear_lines()
	form_connection(entrance, exit, TRUE)

/datum/buildmode_mode/link/proc/close_portal(mob/user, obj/effect/portal/portal)
	var/turf/portal_turf = get_turf(portal)
	var/turf/exit_turf = portal.target
	if(exit_turf)
		for(var/obj/effect/portal/partner in exit_turf)
			if(partner.target == portal_turf)
				qdel(partner)
	log_admin("Build Mode: [key_name(user)] closed a portal at [AREACOORD(portal_turf)]")
	qdel(portal)
	clear_lines()

/datum/buildmode_mode/link/proc/handle_portal_click(mob/user, atom/object, list/modifiers)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(istype(object, /obj/effect/portal/rick/buildmode))
			close_portal(user, object)
		return
	var/turf/clicked_turf = get_turf(object)
	if(!clicked_turf || !LAZYACCESS(modifiers, LEFT_CLICK))
		return
	if(LAZYACCESS(modifiers, CTRL_CLICK))
		var/area/destination_area = tgui_input_list(user, "Area the portal leads to", "Buildmode", get_sorted_areas())
		if(!destination_area)
			return
		for(var/turf/candidate as anything in shuffle(destination_area.get_turfs_from_all_zlevels()))
			if(candidate.density || candidate == clicked_turf || (locate(/obj/effect/portal) in candidate))
				continue
			var/obj/effect/portal/area_entrance = open_portal(user, clicked_turf)
			if(area_entrance)
				link_portals(user, area_entrance, candidate)
			return
		to_chat(user, span_warning("No free turf in [destination_area]."))
		return
	var/obj/effect/portal/pending_portal = pending_portal_ref?.resolve()
	if(pending_portal)
		pending_portal_ref = null
		link_portals(user, pending_portal, clicked_turf)
		return
	var/obj/effect/portal/entrance = open_portal(user, clicked_turf)
	if(entrance)
		pending_portal_ref = WEAKREF(entrance)
		to_chat(user, span_notice("Portal opened at [AREACOORD(clicked_turf)]. Left click another turf to open its exit."))

// FIXME: this probably would work better with something component-based
/datum/buildmode_mode/link/handle_click(mob/user, params, obj/object)
	var/list/modifiers = params2list(params)

	var/left_click = LAZYACCESS(modifiers, LEFT_CLICK)
	var/right_click = LAZYACCESS(modifiers, RIGHT_CLICK)

	if(!ismachinery(object))
		handle_portal_click(user, object, modifiers)
		return TRUE

	if(left_click && ismachinery(object))
		link_obj = object
	if(right_click && ismachinery(object))
		if(istype(link_obj, /obj/machinery/door_control) && is_airlock(object))
			var/obj/machinery/door_control/M = link_obj
			var/obj/machinery/door/airlock/P = object
			if(!M.id || M.id == "")
				M.id = tgui_input_text(user, "Please select an ID for the button", "Buildmode", "", encode = FALSE)
				if(!M.id || M.id == "")
					speed_execute()
					return
			if(P.id_tag == M.id && P.id_tag && P.id_tag != "")
				P.id_tag = null
				to_chat(user, "[P] unlinked.")
				speed_execute()
				return
			if(!M.normaldoorcontrol)
				if(length(link_lines) && tgui_alert(user, "Warning: This will disable links to connected pod doors. Continue?", "Buildmode", list("Yes", "No")) == "No")
					speed_execute()
					return
				M.normaldoorcontrol = 1
			if(P.id_tag && tgui_alert(user, "Warning: This will unlink something else from the door. Continue?", "Buildmode", list("Yes", "No")) == "No")
				speed_execute()
				return
			P.id_tag = M.id
		if(istype(link_obj, /obj/machinery/door_control) && istype(object, /obj/machinery/door/poddoor))
			var/obj/machinery/door_control/M = link_obj
			var/obj/machinery/door/poddoor/P = object
			if(!M.id || M.id == "")
				M.id = tgui_input_text(user, "Please select an ID for the button", "Buildmode", "", encode = FALSE)
				if(!M.id || M.id == "")
					speed_execute()
					return
			if(P.id_tag == M.id && P.id_tag && P.id_tag != "")
				P.id_tag = null
				to_chat(user, "[P] unlinked.")
				speed_execute()
				return
			if(M.normaldoorcontrol)
				if(length(link_lines) && tgui_alert(user, "Warning: This will disable links to connected airlocks. Continue?", "Buildmode", list("Yes", "No")) == "No")
					speed_execute()
					return
				M.normaldoorcontrol = 0
			if(!M.id || M.id == "")
				M.id = tgui_input_text(user, "Please select an ID for the button", "Buildmode", "", encode = FALSE)
				if(!M.id || M.id == "")
					speed_execute()
					return
			if(P.id_tag && P.id_tag != 1 && tgui_alert(user, "Warning: This will unlink something else from the door. Continue?", "Buildmode", list("Yes", "No")) == "No")
				speed_execute()
				return
			P.id_tag = M.id

/datum/buildmode_mode/link/proc/speed_execute() // For exiting out of hell
	clear_lines()

	if(istype(link_obj, /obj/machinery/door_control))
		var/obj/machinery/door_control/M = link_obj
		for(var/obj/machinery/door/airlock/P in GLOB.airlocks)
			if(P.id_tag == M.id)
				form_connection(M, P, M.normaldoorcontrol)
		for(var/obj/machinery/door/poddoor/P in GLOB.airlocks)
			if(P.id_tag == M.id)
				form_connection(M, P, !M.normaldoorcontrol)
