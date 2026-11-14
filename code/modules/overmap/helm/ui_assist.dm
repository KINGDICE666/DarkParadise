/datum/component/overmap_flight/proc/note_burn(side, force)
	if(force > burn_main_force)
		burn_main = side
		burn_main_force = force

/datum/component/overmap_flight/proc/current_bow()
	var/obj/overmap/entity/vessel = parent
	if(!vessel.in_free_flight() || vessel.docking_approach || navigation_host)
		return 0
	return bow_angle

/datum/component/overmap_flight/proc/bow_local(forward, sideways)
	switch(current_bow())
		if(90)
			return list(forward, -sideways)
		if(180)
			return list(-sideways, -forward)
		if(270)
			return list(-forward, sideways)
	return list(sideways, forward)

/datum/component/overmap_flight/proc/nose_heading()
	return SIMPLIFY_DEGREES(facing + current_bow())

/datum/component/overmap_flight/proc/held_heading()
	if(isnull(heading_hold) || fixed_facing)
		return null
	if(isnum(heading_hold))
		return SIMPLIFY_DEGREES(heading_hold - current_bow())
	var/obj/overmap/entity/vessel = parent
	if(OVERMAP_SPEED_STOPPED(vessel.get_speed()))
		return null
	if(heading_hold == OVERMAP_HOLD_PROGRADE)
		return SIMPLIFY_DEGREES(velocity_angle() - current_bow())
	if(heading_hold == OVERMAP_HOLD_RETROGRADE)
		return SIMPLIFY_DEGREES(velocity_angle() + 180 - current_bow())
	return null

/datum/component/overmap_flight/proc/set_heading_hold(mode)
	switch(mode)
		if(OVERMAP_HOLD_PROGRADE, OVERMAP_HOLD_RETROGRADE)
			heading_hold = mode
		if(OVERMAP_HOLD_CURRENT)
			heading_hold = round(nose_heading())
		else
			heading_hold = null

/datum/asset/simple/namespaced/bridge_fonts
	assets = list(
		"Tektur-cyrillic.woff2" = file("interface/fonts/Tektur-cyrillic.woff2"),
		"Tektur-latin.woff2" = file("interface/fonts/Tektur-latin.woff2"),
		"JetBrainsMono-cyrillic.woff2" = file("interface/fonts/JetBrainsMono-cyrillic.woff2"),
		"JetBrainsMono-latin.woff2" = file("interface/fonts/JetBrainsMono-latin.woff2"),
	)
	parents = list(
		"bridge_fonts.css" = file("interface/fonts/bridge_fonts.css"),
	)

/obj/machinery/computer/helm/on_overmap_notice(datum/source, text, tone, origin)
	. = ..()
	if(!text)
		return
	last_notice = text
	last_notice_tone = tone
	last_notice_origin = origin
	last_notice_time = world.time

/obj/machinery/computer/helm/proc/docked_craft()
	. = list()
	for(var/obj/overmap/entity/guest in vessel)
		if(guest.docked_to == vessel && guest.shuttle && !guest.overmap_pod && !guest.programmed)
			. += guest

/obj/machinery/computer/helm/proc/craft_ready(obj/overmap/entity/guest)
	return guest.can_helm_undock() && (guest.shuttle.mode == SHUTTLE_IDLE || guest.shuttle.mode == SHUTTLE_RECHARGING)

/obj/machinery/computer/helm/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/namespaced/bridge_fonts),
	)

/obj/machinery/computer/helm/ui_data(mob/user)
	. = ..()
	if(vessel)
		fire_control_data(.)
	var/list/data = .
	if(last_notice)
		data["notice"] = list("text" = last_notice, "tone" = last_notice_tone, "origin" = last_notice_origin, "age" = round((world.time - last_notice_time) / (1 SECONDS)))
	if(istype(vessel, /obj/overmap/entity/station))
		var/list/craft = list()
		for(var/obj/overmap/entity/guest as anything in docked_craft())
			craft += list(list("id" = guest.UID(), "name" = guest.get_overmap_display_name(), "busy" = !craft_ready(guest)))
		data["docked_craft"] = craft
	var/datum/component/overmap_flight/nav = vessel?.flight
	if(!nav)
		return
	var/overdrive = FALSE
	for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
		overdrive ||= engine.overdrive
	data["overdrive"] = overdrive
	data["held_brake"] = nav.held_brake
	data["drift_assist"] = nav.drift_assist
	data["nose"] = round(nav.nose_heading())
	data["station_ship"] = istype(vessel, /obj/overmap/entity/station/ship)
	data["cruise"] = round(OVERMAP_DISPLAY_SPEED(nav.cruise_speed), 0.1)
	data["max_cruise"] = round(OVERMAP_DISPLAY_SPEED(vessel.max_speed), 0.1)
	data["heading_hold"] = isnum(nav.heading_hold) ? OVERMAP_HOLD_CURRENT : nav.heading_hold
	data["hold_angle"] = isnum(nav.heading_hold) ? nav.heading_hold : null
	data["precision"] = nav.precision
	data["can_turn"] = !nav.fixed_facing
	data["turn_rate"] = round(nav.max_turn_rate * (1 SECONDS), 0.1)
	data["brake_distance"] = round(nav.get_brake_distance(), 0.1)
	data["velocity_heading"] = OVERMAP_SPEED_STOPPED(vessel.get_speed()) ? null : round(nav.velocity_angle())
	var/list/generators = vessel.shield_generators()
	if(length(generators))
		var/active = FALSE
		for(var/obj/machinery/ship_shield_generator/generator as anything in generators)
			active ||= generator.active
		data["shield"] = list("charge" = round(vessel.shield_charge()), "capacity" = vessel.shield_capacity(), "generators" = length(generators), "active" = active)

/obj/machinery/computer/helm/proc/weapons_access(mob/user)
	return user.can_admin_interact() || (fire_access in user.get_access())

/obj/machinery/computer/helm/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/static/list/weapon_actions = list("select_weapon", "weapon_auto", "lock_target", "clear_target", "fire_salvo", "toggle_free_fire")
	if(((action in weapon_actions) || (length(selected_weapons) && (action in list("radar_point", "set_dest")))) && !weapons_access(usr))
		to_chat(usr, span_warning("Управление огнём требует карту с доступом службы безопасности."))
		return TRUE
	if(action != "helm_radar_reach" && ui?.status == UI_INTERACTIVE)
		playsound(src, 'sound/overmap/bridge_click.ogg', 35, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	var/fire_action = (action in list("lock_target", "clear_target", "fire_salvo", "toggle_free_fire")) || (action == "set_dest" && length(selected_weapons) && istype(locateUID(params["id"]), /obj/overmap/entity))
	if(action == "release_craft")
		if(!vessel || !ui || ui.status != UI_INTERACTIVE)
			return TRUE
		var/obj/overmap/entity/guest = locateUID(params["id"])
		if(!(guest in docked_craft()) || !craft_ready(guest))
			return TRUE
		var/result = guest.begin_physical_undock(instant = TRUE)
		if(result != TRUE)
			to_chat(usr, span_warning("[result]"))
		else
			log_game("[key_name(usr)] released [guest.name] from [vessel.name].")
		return TRUE
	if(action in list("nav_dest", "nav_point"))
		var/list/armed = selected_weapons
		selected_weapons = list()
		try
			. = ..(action == "nav_dest" ? "set_dest" : "radar_point", params, ui, state)
		catch(var/exception/error)
			selected_weapons = armed
			throw error
		selected_weapons = armed
		return
	if(!fire_action && !(action in list("toggle_drift_assist", "heading_hold", "toggle_shields", "set_cruise", "full_stop", "toggle_overdrive")))
		return ..()
	if(!ui || ui.status != UI_INTERACTIVE)
		return TRUE
	if(fire_action)
		return vessel ? fire_control_act(action, params, usr) : TRUE
	if(action == "toggle_shields")
		if(!vessel)
			return TRUE
		var/enable = TRUE
		for(var/obj/machinery/ship_shield_generator/generator as anything in vessel.shield_generators())
			if(generator.active)
				enable = FALSE
				break
		for(var/obj/machinery/ship_shield_generator/generator as anything in vessel.shield_generators())
			if(generator.active != enable)
				generator.toggle(usr)
		return TRUE
	var/datum/component/overmap_flight/nav = vessel?.flight
	if(!nav || vessel.is_programmed_locked())
		return TRUE
	if(action == "full_stop")
		if(nav.autopilot)
			nav.set_autopilot(FALSE)
		nav.held_brake = TRUE
		return TRUE
	if(action == "toggle_overdrive")
		var/enable = TRUE
		for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
			if(engine.overdrive)
				enable = FALSE
				break
		for(var/obj/machinery/ship_engine/engine as anything in vessel.engines)
			if(engine != vessel.virtual_engine)
				engine.set_overdrive(enable)
		log_game("[key_name(usr)] [enable ? "enabled" : "disabled"] engine overdrive from the helm of [vessel.name].")
		return TRUE
	if(action == "set_cruise")
		var/wanted = text2num(params["value"])
		if(isnum(wanted))
			nav.cruise_speed = OVERMAP_FROM_DISPLAY(clamp(wanted, OVERMAP_HEADING_SPEED_MIN, OVERMAP_DISPLAY_SPEED(vessel.max_speed)))
			nav.held_brake = FALSE
		return TRUE
	if(action == "toggle_drift_assist")
		nav.drift_assist = !nav.drift_assist
		to_chat(usr, span_notice("Гашение дрейфа [nav.drift_assist ? "включено" : "отключено"]."))
	else
		nav.set_heading_hold(params["mode"])
	return TRUE
