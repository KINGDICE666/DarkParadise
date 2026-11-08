/mob/living/basic/net_avatar/proc/get_neuro()
	var/datum/component/net_connection/connection = GetComponent(/datum/component/net_connection)
	return connection?.neuro

/mob/living/basic/net_avatar/proc/net_interact(atom/target, list/modifiers)
	var/area/target_area = get_area(target)
	if(is_ice_blocked(target_area))
		if(get_dist(src, target) > NET_HACK_RANGE)
			balloon_alert(src, "лёд слишком далеко!")
			return TRUE
		start_breach(target_area)
		return TRUE
	if(isnetavatar(target) && target != src)
		INVOKE_ASYNC(src, PROC_REF(open_combat_hacks), target)
		return TRUE
	if(!LAZYACCESS(modifiers, RIGHT_CLICK) && is_net_door(target) && Adjacent(target))
		INVOKE_ASYNC(src, PROC_REF(net_toggle_door), target)
		return TRUE
	var/atom/movable/node = resolve_node(target)
	if(!node)
		return FALSE
	INVOKE_ASYNC(src, PROC_REF(open_quickhacks), node)
	return TRUE

/mob/living/basic/net_avatar/proc/is_net_door(atom/thing)
	return is_airlock(thing) || istype(thing, /obj/machinery/door/window)

/mob/living/basic/net_avatar/proc/is_net_node(atom/thing)
	if(isapc(thing) || istype(thing, /obj/item/radio/intercom) || istype(thing, /obj/machinery/hologram/holopad) || istype(thing, /obj/machinery/status_display))
		return TRUE
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	return !!neuro?.get_device_kind(thing)

/mob/living/basic/net_avatar/proc/resolve_node(atom/target)
	if(is_net_node(target))
		return target
	if(!isturf(target))
		return null
	for(var/atom/movable/thing as anything in target)
		if(is_net_node(thing))
			return thing
	return null

/mob/living/basic/net_avatar/proc/can_reach_node(atom/movable/node)
	return get_dist(src, node) <= NET_HACK_RANGE && (node in view(NET_HACK_RANGE, src))

/mob/living/basic/net_avatar/proc/open_quickhacks(atom/movable/node)
	if(!can_reach_node(node))
		balloon_alert(src, "узел вне досягаемости!")
		return
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	var/list/options = list()
	if(neuro && !neuro.crit_fail)
		var/kind = neuro.get_device_kind(node)
		if(kind)
			for(var/list/button as anything in neuro.device_buttons(node, kind))
				options[button["cost"] ? "[button["label"]] ([button["cost"]] буфера)" : button["label"]] = button["id"]
	options += get_native_actions(node)
	if(!length(options))
		balloon_alert(src, "узел молчит")
		return
	var/choice = tgui_input_list(src, neuro ? "Буфер: [round(neuro.get_buffer())]" : "Нейроинтерфейс недоступен", DECLENT_RU_CAP(node, NOMINATIVE), options)
	if(!choice || QDELETED(node) || stat != CONSCIOUS || !can_reach_node(node))
		return
	var/action_id = options[choice]
	if(findtext(action_id, "net_") == 1)
		run_native_action(node, action_id)
		return
	if(neuro?.run_device_action(node, action_id))
		new /obj/effect/temp_visual/net_glitch(get_turf(node))
		add_trace(get_net_ice(get_area(node)) ? NET_TRACE_ICE_ACTION : NET_TRACE_ACTION)

/mob/living/basic/net_avatar/proc/get_native_actions(atom/movable/node)
	. = list()
	if(isapc(node))
		.["Нырнуть в канал данных"] = "net_conduit"
	if(istype(node, /obj/item/radio/intercom))
		.["Сказать через динамик"] = "net_speak"
		.[tapped_intercom == node ? "Снять прослушку" : "Прослушивать"] = "net_tap"
	if(istype(node, /obj/machinery/hologram/holopad))
		.[projection?.pad == node ? "Погасить голограмму" : "Спроецировать голограмму"] = "net_holo"
	if(istype(node, /obj/machinery/status_display))
		.["Вывести сообщение на табло"] = "net_display"

/mob/living/basic/net_avatar/proc/run_native_action(atom/movable/node, action_id)
	switch(action_id)
		if("net_conduit")
			enter_conduit(node)
		if("net_speak")
			speak_through(node)
		if("net_tap")
			toggle_tap(node)
		if("net_holo")
			toggle_projection(node)
		if("net_display")
			hijack_display(node)

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
	if(is_ice_blocked(get_area(door)))
		balloon_alert(src, "дверь закрыта льдом!")
		return
	var/hacked = FALSE
	if(!door.allowed(src))
		balloon_alert(src, "взлом доступа...")
		if(!do_after(src, NET_DOOR_HACK_TIME, door, interaction_key = door))
			return
		if(QDELETED(door) || door.operating)
			return
		hacked = TRUE
	if(get_net_ice(get_area(door)))
		add_trace(NET_TRACE_ICE_ACTION)
	else if(hacked)
		add_trace(NET_TRACE_ACTION)
	new /obj/effect/temp_visual/net_glitch(get_turf(door))
	door.add_hiddenprint(src)
	if(door.density)
		door.open()
	else
		door.close()

/mob/living/basic/net_avatar/proc/enter_conduit(obj/machinery/power/apc/apc)
	if(!Adjacent(apc))
		balloon_alert(src, "подойдите к узлу!")
		return
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
	add_trace(NET_TRACE_ACTION)

/mob/living/basic/net_avatar/proc/get_conduit_destinations(obj/machinery/power/apc/entrance)
	. = list()
	var/datum/powernet/grid = entrance.terminal?.powernet
	if(!grid)
		return
	for(var/obj/machinery/power/terminal/terminal in grid.nodes)
		var/obj/machinery/power/apc/exit = terminal.master
		if(!isapc(exit) || exit == entrance || exit.z != entrance.z || is_ice_blocked(get_area(exit)))
			continue
		.["[get_area_name(exit, TRUE)] ([exit.x], [exit.y])"] = exit

/mob/living/basic/net_avatar/proc/speak_through(obj/item/radio/intercom/intercom)
	var/message = tgui_input_text(src, "Что произнести через динамик?", "Голос из Сети", max_length = MAX_MESSAGE_LEN)
	if(!message || QDELETED(intercom) || stat != CONSCIOUS || !can_reach_node(intercom))
		return
	intercom.atom_say(message)
	add_trace(NET_TRACE_ACTION)
	add_say_logs(src, "через [intercom] из Сети: [message]")

/mob/living/basic/net_avatar/proc/toggle_tap(obj/item/radio/intercom/intercom)
	var/obj/item/radio/intercom/previous = tapped_intercom
	stop_tap()
	if(previous == intercom)
		balloon_alert(src, "прослушка снята")
		return
	tapped_intercom = intercom
	RegisterSignal(intercom, COMSIG_MOVABLE_HEAR, PROC_REF(on_tap_hear))
	RegisterSignal(intercom, COMSIG_QDELETING, PROC_REF(stop_tap))
	tap_timer = addtimer(CALLBACK(src, PROC_REF(stop_tap)), NET_EAVESDROP_TIME, TIMER_STOPPABLE)
	add_trace(NET_TRACE_ACTION)
	balloon_alert(src, "прослушка на минуту")

/mob/living/basic/net_avatar/proc/stop_tap()
	SIGNAL_HANDLER
	if(!tapped_intercom)
		return
	UnregisterSignal(tapped_intercom, list(COMSIG_MOVABLE_HEAR, COMSIG_QDELETING))
	tapped_intercom = null
	deltimer(tap_timer)
	tap_timer = null

/mob/living/basic/net_avatar/proc/on_tap_hear(obj/item/radio/intercom/source, list/hearing_args)
	SIGNAL_HANDLER
	var/atom/movable/speaker = hearing_args[HEARING_SPEAKER]
	if(hearing_args[HEARING_RADIO_FREQ] || speaker == source)
		return
	to_chat(src, span_notice("<i>Прослушка, [get_area_name(source, TRUE)]</i> — [speaker.name]: «[hearing_args[HEARING_RAW_MESSAGE]]»"))

/mob/living/basic/net_avatar/proc/toggle_projection(obj/machinery/hologram/holopad/pad)
	var/obj/machinery/hologram/holopad/previous = projection?.pad
	stop_projection()
	if(previous == pad)
		return
	if(!pad.is_operational())
		balloon_alert(src, "голопад обесточен!")
		return
	if(get_dist(src, pad) > NET_HOLO_RANGE)
		balloon_alert(src, "подойдите к голопаду!")
		return
	projection = new(get_turf(src), src, pad)
	RegisterSignal(pad, COMSIG_QDELETING, PROC_REF(stop_projection))
	add_trace(NET_TRACE_ACTION)
	add_game_logs("projected a hologram through [pad] from the Net", src)

/mob/living/basic/net_avatar/proc/stop_projection()
	SIGNAL_HANDLER
	if(!projection)
		return
	UnregisterSignal(projection.pad, COMSIG_QDELETING)
	QDEL_NULL(projection)

/mob/living/basic/net_avatar/proc/follow_projection()
	if(!projection)
		return
	var/obj/machinery/hologram/holopad/pad = projection.pad
	if(!pad.is_operational() || pad.z != z || get_dist(src, pad) > NET_HOLO_RANGE)
		stop_projection()
		return
	projection.forceMove(get_turf(src))
	projection.setDir(dir)

/mob/living/basic/net_avatar/proc/hijack_display(obj/machinery/status_display/display)
	var/text = tgui_input_text(src, "Текст для табло. Вторая строка — после «/».", "Табло", max_length = DISPLAY_CHARS_PER_LINE * 4)
	if(!text || QDELETED(display) || stat != CONSCIOUS || !can_reach_node(display))
		return
	var/list/lines = splittext(text, "/")
	display.set_mode(STATUS_DISPLAY_MESSAGE)
	display.set_message(lines[1], length(lines) > 1 ? lines[2] : null)
	display.update()
	addtimer(CALLBACK(display, TYPE_PROC_REF(/obj/machinery/status_display, release_net_message)), NET_DISPLAY_TIME, TIMER_UNIQUE|TIMER_OVERRIDE)
	new /obj/effect/temp_visual/net_glitch(get_turf(display))
	add_trace(NET_TRACE_ACTION)
	add_game_logs("put [text] on [display] from the Net", src)

/obj/machinery/status_display/proc/release_net_message()
	set_mode(STATUS_DISPLAY_TRANSFER_SHUTTLE_TIME)
	update()

/obj/effect/overlay/net_hologram
	name = "hologram"
	desc = "Мерцающая голограмма. Изображение рябит помехами, будто сигнал идёт не с этой станции."
	layer = FLY_LAYER
	appearance_flags = KEEP_TOGETHER
	alpha = 190
	var/obj/machinery/hologram/holopad/pad

/obj/effect/overlay/net_hologram/Initialize(mapload, mob/living/basic/net_avatar/avatar, obj/machinery/hologram/holopad/pad)
	. = ..()
	src.pad = pad
	name = avatar.name
	add_overlay(avatar.body_overlays)
	add_filter("holo_tint", 1, color_matrix_filter(MATRIX_NET_HOLOGRAM))
	add_filter("holo_glow", 2, outline_filter(1, NET_HOLOGRAM_GLOW))
	add_filter("holo_glitch", 3, wave_filter(x = 1, size = 1))
	animate(get_filter("holo_glitch"), offset = 32, time = 3 SECONDS, loop = -1)

/obj/effect/overlay/net_hologram/Destroy()
	pad = null
	return ..()
