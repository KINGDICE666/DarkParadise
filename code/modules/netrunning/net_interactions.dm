/mob/living/basic/net_avatar/proc/net_interact(atom/target)
	if(is_airlock(target) || istype(target, /obj/machinery/door/window))
		INVOKE_ASYNC(src, PROC_REF(net_toggle_door), target)
		return TRUE
	if(isapc(target))
		INVOKE_ASYNC(src, PROC_REF(enter_conduit), target)
		return TRUE
	return FALSE

/mob/living/basic/net_avatar/proc/net_toggle_door(obj/machinery/door/door)
	if(door.operating || DOING_INTERACTION(src, door))
		return
	if(is_airlock(door))
		var/obj/machinery/door/airlock/airlock = door
		if(!airlock.canAIControl())
			balloon_alert(src, "нет сетевого канала!")
			return
		if(airlock.locked || airlock.welded)
			balloon_alert(src, "заблокировано!")
			return
	if(!door.allowed(src))
		balloon_alert(src, "взлом доступа...")
		if(!do_after(src, NET_DOOR_HACK_TIME, door, interaction_key = door))
			return
		if(QDELETED(door) || door.operating)
			return
	new /obj/effect/temp_visual/net_glitch(get_turf(door))
	door.add_hiddenprint(src)
	if(door.density)
		door.open()
	else
		door.close()

/mob/living/basic/net_avatar/proc/enter_conduit(obj/machinery/power/apc/apc)
	if(!COOLDOWN_FINISHED(src, conduit_cooldown))
		balloon_alert(src, "канал перегружен!")
		return
	var/list/destinations = get_conduit_destinations(apc)
	if(!length(destinations))
		balloon_alert(src, "узел изолирован!")
		return
	var/choice = tgui_input_list(src, "Куда направить поток данных?", "Канал данных", destinations)
	var/obj/machinery/power/apc/exit = destinations[choice]
	if(QDELETED(exit) || stat != CONSCIOUS || !Adjacent(apc) || !COOLDOWN_FINISHED(src, conduit_cooldown))
		return
	if(!(exit in get_conduit_destinations(apc)))
		balloon_alert(src, "канал разорван!")
		return
	COOLDOWN_START(src, conduit_cooldown, NET_CONDUIT_COOLDOWN)
	new /obj/effect/temp_visual/net_dissolve(loc, src)
	playsound_local(get_turf(src), 'sound/effects/phasein.ogg', 25, TRUE)
	forceMove(get_turf(exit))
	new /obj/effect/temp_visual/net_glitch(loc)

/mob/living/basic/net_avatar/proc/get_conduit_destinations(obj/machinery/power/apc/entrance)
	. = list()
	var/datum/powernet/grid = entrance.terminal?.powernet
	if(!grid)
		return
	for(var/obj/machinery/power/terminal/terminal in grid.nodes)
		var/obj/machinery/power/apc/exit = terminal.master
		if(!isapc(exit) || exit == entrance || exit.z != entrance.z)
			continue
		.["[get_area_name(exit, TRUE)] ([exit.x], [exit.y])"] = exit
