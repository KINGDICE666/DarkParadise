#define CAN_HEAR_MASTERS (1<<0)
#define CAN_HEAR_ACTIVE_HOLOCALLS (1<<1)
#define CAN_HEAR_RECORD_MODE (1<<2)
#define CAN_HEAR_HOLOCALL_USER (1<<3)
#define CAN_HEAR_ALL_FLAGS (CAN_HEAR_MASTERS|CAN_HEAR_ACTIVE_HOLOCALLS|CAN_HEAR_RECORD_MODE|CAN_HEAR_HOLOCALL_USER)
/* holograms!
 * Contains:
 *		Holopad
 *		hologram
 *		Other stuff
 */

/*
Revised. Original based on space ninja hologram code. Which is also mine. /N
How it works:
AI clicks on holopad in camera view. View centers on holopad.
AI clicks again on the holopad to display a hologram. hologram stays as long as AI is looking at the pad and it (the hologram) is in range of the pad.
AI can use the directional keys to move the hologram around, provided the above conditions are met and the AI in question is the holopad's master.
Only one AI may project from a holopad at any given time.
AI may cancel the hologram at any time by clicking on the holopad once more.
Possible to do for anyone motivated enough:
	Give an AI variable for different hologram icons.
	Itegrate EMP effect to disable the unit.
*/

/*
 * Holopad
 */

// HOLOPAD MODE
// 0 = RANGE BASED
// 1 = AREA BASED
#define HOLOPAD_PASSIVE_POWER_USAGE 1
#define HOLOGRAM_POWER_USAGE 2

GLOBAL_LIST_EMPTY(holopads)

/obj/machinery/hologram/holopad
	name = "holopad"
	desc = "It's a floor-mounted device for projecting holographic images."
	icon_state = "holopad0"
	anchored = TRUE
	idle_power_usage = 5
	active_power_usage = 100
	layer = HOLOPAD_LAYER //Preventing mice and drones from sneaking under them.
	plane = FLOOR_PLANE
	max_integrity = 300
	light_on = FALSE
	light_range = 2
	armor = list(melee = 50, bullet = 20, laser = 20, energy = 20, bomb = 0, bio = 0, fire = 50, acid = 0)
	interaction_flags_atom = parent_type::interaction_flags_atom | INTERACT_ATOM_IGNORE_MOBILITY
	interaction_flags_click = ALLOW_SILICON_REACH
	req_access = list(ACCESS_KEYCARD_AUTH)
	var/list/masters //List of living mobs that use the holopad
	var/list/holorays //Holoray-mob link.
	var/last_request = 0 //to prevent request spam. ~Carn
	var/holo_range = 5 // Change to change how far the AI can move away from the holopad before deactivating.
	/// Array of /datum/holocalls that are calling US. this is only filled for holopads answering calls from another holopad
	var/list/holo_calls
	/// Currently outgoing holocall, cannot call any other holopads unless this is null.
	/// creating a new holocall from us to another holopad sets this var to that holocall datum
	var/datum/holocall/outgoing_call
	var/static/force_answer_call = FALSE	//Calls will be automatically answered after a couple rings, here for debugging
	var/obj/effect/overlay/holoray/ray
	var/ringing = FALSE
	var/dialling_input = FALSE //The user is currently selecting where to send their call
	var/secure = FALSE
	var/calling = FALSE
	var/pointing = FALSE
	var/obj/item/disk/holodisk/disk
	var/replay_mode = FALSE
	var/loop_mode = FALSE
	var/record_mode = FALSE
	var/record_start = 0
	var/mob/living/record_user
	var/obj/effect/overlay/holo_pad_hologram/replay_holo
	var/replay_timer
	var/offset = 0
	///bitfield. used to turn on and off hearing sensitivity depending on if we can act on Hear() at all - meant for lowering the number of unessesary hearable atoms
	var/can_hear_flags = NONE

/obj/machinery/hologram/holopad/Initialize(mapload)
	. = ..()
	GLOB.holopads += src
	component_parts = list()
	var/obj/item/circuitboard/holopad/board = new(null)
	if(secure)
		board.secure = TRUE
		board.build_path = /obj/machinery/hologram/holopad/secure
	component_parts += board
	component_parts += new /obj/item/stock_parts/capacitor(null)
	RefreshParts()
	become_hearing_sensitive()

/obj/machinery/hologram/holopad/Destroy()
	if(outgoing_call)
		outgoing_call.ConnectionFailure(src)

	for(var/datum/holocall/holocall_to_disconnect as anything in holo_calls)
		holocall_to_disconnect.ConnectionFailure(src)

	replay_stop()
	record_stop()

	for(var/I in masters)
		clear_holo(I)

	QDEL_NULL(disk)

	QDEL_LIST_ASSOC(holorays)
	QDEL_LIST(holo_calls)
	LAZYCLEARLIST(masters)
	outgoing_call = null
	ray = null
	GLOB.holopads -= src
	return ..()

/obj/machinery/hologram/holopad/secure
	name = "secure holopad"
	desc = "Напольный проектор голографических изображений. Этот не принимает входящие подключения автоматически."
	secure = TRUE

/obj/machinery/hologram/holopad/secure/get_ru_names()
	return alist(
		NOMINATIVE = "защищённый голопад",
		GENITIVE = "защищённого голопада",
		DATIVE = "защищённому голопаду",
		ACCUSATIVE = "защищённый голопад",
		INSTRUMENTAL = "защищённым голопадом",
		PREPOSITIONAL = "защищённом голопаде",
	)

/obj/machinery/hologram/holopad/power_change(forced = FALSE)
	if(!..())
		return
	if(stat & NOPOWER)
		if(outgoing_call)
			outgoing_call.ConnectionFailure(src)
		replay_stop()
		record_stop()
		set_light_on(FALSE)
	update_icon(UPDATE_OVERLAYS)

/obj/machinery/hologram/holopad/update_icon_state()
	var/total_users = LAZYLEN(masters) + LAZYLEN(holo_calls)
	if(icon_state == "holopad_open")
		return
	else if(ringing)
		icon_state = "holopad_ringing"
	else if(total_users || pointing)
		icon_state = "holopad1"
	else
		icon_state = "holopad0"

/obj/machinery/hologram/holopad/update_overlays()
	. = ..()

	if(stat & NOPOWER)
		return

	var/total_users = LAZYLEN(masters) + LAZYLEN(holo_calls)
	if(ringing)
		. += emissive_appearance(icon, "holopad_ringing_lightmask", src)
	else if(total_users || pointing)
		for(var/mob/living/silicon/ai/master in masters)
			if(!master.ai_holocolor)
				continue
			var/mutable_appearance/hololine_overlay = mutable_appearance(icon, "holopad1_mask")
			hololine_overlay.color = master.ai_holocolor
			. += hololine_overlay
			break
		. += emissive_appearance(icon, "holopad1_lightmask", src)

/obj/machinery/hologram/holopad/obj_break()
	. = ..()
	if(outgoing_call)
		outgoing_call.ConnectionFailure(src)

/obj/machinery/hologram/holopad/RefreshParts()
	var/holograph_range = 4
	for(var/obj/item/stock_parts/capacitor/B in component_parts)
		holograph_range += 1 * B.rating
	holo_range = holograph_range

/obj/machinery/hologram/holopad/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(istype(I, /obj/item/disk/holodisk))
		add_fingerprint(user)
		if(disk)
			to_chat(user, span_warning("В [declent_ru(PREPOSITIONAL)] уже есть диск!"))
			return ATTACK_CHAIN_PROCEED
		if(!user.drop_transfer_item_to_loc(I, src))
			return ATTACK_CHAIN_PROCEED
		to_chat(user, span_notice("Вы вставляете [I.declent_ru(ACCUSATIVE)] в [declent_ru(ACCUSATIVE)]."))
		disk = I
		SStgui.update_uis(src)
		return ATTACK_CHAIN_BLOCKED_ALL
	if(exchange_parts(user, I))
		return ATTACK_CHAIN_PROCEED_SUCCESS
	return ..()

/obj/machinery/hologram/holopad/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == disk)
		disk = null

/obj/machinery/hologram/holopad/on_deconstruction()
	disk?.forceMove(drop_location())

/obj/machinery/hologram/holopad/screwdriver_act(mob/user, obj/item/I)
	. = TRUE
	default_deconstruction_screwdriver(user, "holopad_open", "holopad0", I)

/obj/machinery/hologram/holopad/wrench_act(mob/user, obj/item/I)
	. = TRUE
	default_unfasten_wrench(user, I)

/obj/machinery/hologram/holopad/crowbar_act(mob/user, obj/item/I)
	. = TRUE
	default_deconstruction_crowbar(user, I)

/obj/machinery/hologram/holopad/attack_hand(mob/living/carbon/human/user)
	if(..())
		return

	ui_interact(user)

/obj/machinery/hologram/holopad/click_alt(mob/living/carbon/human/user)
	if(isAI(user))
		hangup_all_calls()
		return CLICK_ACTION_SUCCESS

//setters
/**
 * setter for can_hear_flags. handles adding or removing the given flag on can_hear_flags and then adding hearing sensitivity or removing it depending on the final state
 * this is necessary because holopads are a significant fraction of the hearable atoms on station which increases the cost of procs that iterate through hearables
 * so we need holopads to not be hearable until it is needed
 *
 * * flag - one of the can_hear_flags flag defines
 * * set_flag - boolean, if TRUE sets can_hear_flags to that flag and might add hearing sensitivity if can_hear_flags was NONE before,
 * if FALSE unsets the flag and possibly removes hearing sensitivity
 */
/obj/machinery/hologram/holopad/proc/set_can_hear_flags(flag, set_flag = TRUE)
	if(!(flag & CAN_HEAR_ALL_FLAGS))
		return FALSE //the given flag doesnt exist

	if(set_flag)
		if(can_hear_flags == NONE)//we couldnt hear before, so become hearing sensitive
			become_hearing_sensitive()

		can_hear_flags |= flag
		return TRUE

	else
		can_hear_flags &= ~flag
		if(can_hear_flags == NONE)
			lose_hearing_sensitivity()

		return TRUE

///setter for adding/removing holocalls to this holopad. used to update the holo_calls list and can_hear_flags
///adds the given holocall if add_holocall is TRUE, removes if FALSE
/obj/machinery/hologram/holopad/proc/set_holocall(datum/holocall/holocall_to_update, add_holocall = TRUE)
	if(!istype(holocall_to_update))
		return FALSE

	if(add_holocall)
		set_can_hear_flags(CAN_HEAR_ACTIVE_HOLOCALLS)
		LAZYADD(holo_calls, holocall_to_update)

	else
		LAZYREMOVE(holo_calls, holocall_to_update)
		if(!LAZYLEN(holo_calls))
			set_can_hear_flags(CAN_HEAR_ACTIVE_HOLOCALLS, FALSE)

	return TRUE

//Stop ringing the AI!!
/obj/machinery/hologram/holopad/proc/hangup_all_calls()
	for(var/datum/holocall/holocall_to_disconnect as anything in holo_calls)
		holocall_to_disconnect.Disconnect(src)

/obj/machinery/hologram/holopad/ui_status(mob/user, datum/ui_state/state)
	if(!is_operational() || !anchored)
		return UI_CLOSE
	if(outgoing_call && !calling)
		return UI_CLOSE
	return ..()

/obj/machinery/hologram/holopad/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Holopad", name)
		ui.open()

/obj/machinery/hologram/holopad/ui_data(mob/user)
	var/list/data = list()
	data["calling"] = calling
	data["on_cooldown"] = last_request + 20 SECONDS > world.time
	data["allowed"] = allowed(user)
	data["disk"] = !!disk
	data["disk_record"] = !!disk?.record
	data["replay_mode"] = replay_mode
	data["loop_mode"] = loop_mode
	data["record_mode"] = record_mode
	data["holo_calls"] = list()
	for(var/datum/holocall/holocall as anything in holo_calls)
		data["holo_calls"] += list(list(
			"caller" = "[holocall.user]",
			"connected" = holocall.connected_holopad == src,
			"ref" = holocall.UID(),
		))
	return data

/obj/machinery/hologram/holopad/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..() || isAI(usr))
		return
	add_fingerprint(usr)
	switch(action)
		if("AIrequest")
			if(last_request + 20 SECONDS > world.time)
				to_chat(usr, span_warning("Запрос присутствия ИИ уже был отправлен недавно."))
				return
			last_request = world.time
			to_chat(usr, span_notice("Вы запросили присутствие ИИ."))
			var/area/area = get_area(src)
			for(var/mob/living/silicon/ai/AI in GLOB.ai_list)
				if(!AI.client)
					continue
				to_chat(AI, span_notice("Your presence is requested at <a href='byond://?src=[AI.UID()];jumptoholopad=[UID()]'>\the [area]</a>."))
			return TRUE
		if("holocall")
			if(outgoing_call || dialling_input)
				return
			if(usr.loc != loc)
				to_chat(usr, span_warning("Чтобы позвонить, нужно стоять на голопаде!"))
				return
			var/list/callnames = list()
			for(var/obj/machinery/hologram/holopad/pad as anything in GLOB.holopads)
				var/area/pad_area = get_area(pad)
				if(pad_area)
					LAZYADD(callnames[pad_area], pad)
			callnames -= get_area(src)
			dialling_input = TRUE
			var/result = tgui_input_list(usr, "Выберите зону для звонка", "Голозвонок", sortAtom(callnames))
			dialling_input = FALSE
			if(isnull(result) || QDELETED(usr) || outgoing_call || usr.loc != loc)
				return
			var/datum/holocall/holocall = new(usr, src, callnames[result], params["headcall"] && allowed(usr))
			if(QDELETED(holocall))
				return
			calling = TRUE
			return TRUE
		if("connectcall")
			var/datum/holocall/call_to_connect = locateUID(params["holopad"])
			if(!QDELETED(call_to_connect) && (call_to_connect in holo_calls))
				call_to_connect.Answer(src)
				return TRUE
		if("disconnectcall")
			var/datum/holocall/call_to_disconnect = locateUID(params["holopad"])
			if(!QDELETED(call_to_disconnect) && (call_to_disconnect in holo_calls))
				call_to_disconnect.Disconnect(src)
				return TRUE
		if("rejectall")
			for(var/datum/holocall/call_to_reject as anything in holo_calls)
				if(call_to_reject.connected_holopad == src)
					continue
				call_to_reject.Disconnect(src)
			return TRUE
		if("hang_up")
			if(outgoing_call)
				outgoing_call.Disconnect(src)
				return TRUE
		if("disk_eject")
			if(disk && !replay_mode && !record_mode)
				usr.put_in_hands(disk)
				return TRUE
		if("replay_mode")
			if(replay_mode)
				replay_stop()
			else
				replay_start()
			return TRUE
		if("loop_mode")
			loop_mode = !loop_mode
			return TRUE
		if("record_mode")
			if(record_mode)
				record_stop()
			else
				record_start(usr)
			return TRUE
		if("record_clear")
			record_clear()
			return TRUE
		if("offset")
			if(!replay_mode)
				return
			offset = (offset + 1) % (length(GLOB.cardinal) + 1)
			if(!move_hologram(disk.record, offset ? get_step(src, GLOB.cardinal[offset]) : get_turf(src)))
				replay_stop()
			return TRUE

/obj/machinery/hologram/holopad/proc/callee_picked_up()
	calling = FALSE
	set_can_hear_flags(CAN_HEAR_HOLOCALL_USER)

/obj/machinery/hologram/holopad/proc/callee_hung_up()
	set_can_hear_flags(CAN_HEAR_HOLOCALL_USER, set_flag = FALSE)
	calling = FALSE
	outgoing_call = null

//do not allow AIs to answer calls or people will use it to meta the AI satellite
/obj/machinery/hologram/holopad/attack_ai(mob/living/silicon/ai/user)
	if(!istype(user))
		return
	if(outgoing_call)
		return
	/*There are pretty much only three ways to interact here.
	I don't need to check for client since they're clicking on an object.
	This may change in the future but for now will suffice.*/
	if(user.eyeobj.loc != loc)//Set client eye on the object if it's not already.
		user.eyeobj.setLoc(get_turf(src))
	else if(!LAZYLEN(masters) || !masters[user])//If there is no hologram, possibly make one.
		activate_holo(user, 1)
	else//If there is a hologram, remove it.
		clear_holo(user)

/obj/machinery/hologram/holopad/process()
	for(var/I in masters)
		var/mob/living/master = I
		if((stat & NOPOWER) || !validate_user(master) || !anchored)
			clear_holo(master)

	if(outgoing_call)
		outgoing_call.Check()

	ringing = FALSE

	for(var/I in holo_calls)
		var/datum/holocall/HC = I
		//Sanity check and skip if no longer valid call
		if(!HC.Check())
			atom_say("Вызов был завершен на удаленном терминале.")
			continue

		if(HC.connected_holopad != src)
			if(force_answer_call && world.time > (HC.call_start_time + (HOLOPAD_MAX_DIAL_TIME / 2)))
				HC.Answer(src)
				break
			if(HC.head_call && !secure)
				HC.Answer(src)
				break
			if(outgoing_call)
				HC.Disconnect(src)//can't answer calls while calling
			else
				playsound(src, 'sound/machines/twobeep.ogg', 100)	//bring, bring!
				ringing = TRUE

	update_icon()

//Try to transfer hologram to another pad that can project on T
/obj/machinery/hologram/holopad/proc/transfer_to_nearby_pad(turf/T, mob/holo_owner)
	if(!isAI(holo_owner))
		return
	for(var/pad in GLOB.holopads)
		var/obj/machinery/hologram/holopad/another = pad
		if(another == src)
			continue
		if(another.validate_location(T))
			var/obj/effect/overlay/holo_pad_hologram/h = LAZYACCESS(masters, holo_owner)
			unset_holo(holo_owner)
			another.set_holo(holo_owner, h)
			return TRUE
	return FALSE

/obj/machinery/hologram/holopad/proc/validate_user(datum/owner)
	if(QDELETED(owner))
		return FALSE
	if(!isliving(owner))
		return TRUE
	var/mob/living/user = owner
	if(user.incapacitated() || !user.client)
		return FALSE

	if(isAI(user))
		var/mob/living/silicon/ai/AI = user
		if(!AI.current)
			return FALSE
	return TRUE

//Can we display holos there
//Area check instead of line of sight check because this is a called a lot if AI wants to move around.
/obj/machinery/hologram/holopad/proc/validate_location(turf/T,check_los = FALSE)
	if(T.z == z && get_dist(T, src) <= holo_range && T.loc == get_area(src))
		return TRUE
	return FALSE

/obj/machinery/hologram/holopad/proc/move_hologram(mob/living/user, turf/new_turf)
	if(LAZYACCESS(masters, user))
		var/obj/effect/overlay/holo_pad_hologram/holo = masters[user]
		var/transfered = FALSE
		if(!validate_location(new_turf))
			if(!transfer_to_nearby_pad(new_turf,user))
				clear_holo(user)
				return FALSE
			else
				transfered = TRUE
		//All is good.
		holo.setDir(get_dir(holo.loc, new_turf))
		holo.forceMove(new_turf)
		if(!transfered)
			update_holoray(user,new_turf)
	return TRUE

/obj/machinery/hologram/holopad/proc/activate_holo(mob/living/user, force = 0)
	var/mob/living/silicon/ai/AI = user
	if(!istype(AI))
		AI = null
	if(AI && !force && AI.eyeobj.loc != loc) // allows holopads to pass off holograms to the next holopad in the chain
		to_chat(user, "<font color='red'>ERROR:</font> Unable to project hologram.")
	if(!(stat & NOPOWER) && (!AI || force))
		if(AI && (istype(AI.current, /obj/machinery/hologram/holopad)))
			to_chat(user, "[span_danger("ERROR:")] Image feed in progress.")
			return

		var/obj/effect/overlay/holo_pad_hologram/hologram = new(loc)//Spawn a blank effect at the location.
		if(isAI(user))
			hologram.icon = AI.holo_icon
		else	//make it like real life
			hologram.icon = getHologramIcon(get_id_photo(user))
			hologram.icon_state = user.icon_state
			hologram.alpha = 100
			hologram.Impersonation = user

		hologram.mouse_opacity = MOUSE_OPACITY_TRANSPARENT//So you can't click on it.
		hologram.layer = FLY_LAYER//Above all the other objects/mobs. Or the vast majority of them.
		SET_PLANE_EXPLICIT(hologram, ABOVE_GAME_PLANE, src)
		hologram.set_anchored(TRUE)	//So space wind cannot drag it.
		hologram.name = "[user.name] (hologram)"//If someone decides to right click.
		hologram.set_light(2)	//hologram lighting
		move_hologram()

		set_holo(user, hologram)

		if(!LAZYACCESS(masters, user))//If there is not already a hologram.
			visible_message("A holographic image of [user] flicks to life right before your eyes!")

		return hologram

	to_chat(user, span_danger("ERROR: ") + "Hologram Projection Malfunction.")
	clear_holo(user)//safety check

/*This is the proc for special two-way communication between AI and holopad/people talking near holopad.
For the other part of the code, check silicon say.dm. Particularly robot talk.*/
/obj/machinery/hologram/holopad/hear_talk(atom/movable/speaker, list/message_pieces, verb)
	. = ..()
	if(speaker && LAZYLEN(masters))//Master is mostly a safety in case lag hits or something. Radio_freq so AIs dont hear holopad stuff through radios.
		for(var/mob/living/silicon/ai/master in masters)
			if(masters[master] && speaker != master)
				master.relay_speech(speaker, message_pieces, verb)

	for(var/datum/holocall/holocall_to_update as anything in holo_calls)
		if(holocall_to_update.connected_holopad == src && speaker != holocall_to_update.hologram)
			holocall_to_update.user.hear_say(message_pieces, verb, speaker = speaker)

	if(outgoing_call?.hologram && speaker == outgoing_call.user)
		outgoing_call.hologram.atom_say(multilingual_to_message(message_pieces))

	if(record_mode && speaker == record_user)
		record_message(speaker, multilingual_to_message(message_pieces))

/obj/machinery/hologram/holopad/proc/SetLightsAndPower()
	var/total_users = LAZYLEN(masters) + LAZYLEN(holo_calls)
	use_power = total_users > 0 ? ACTIVE_POWER_USE : IDLE_POWER_USE
	active_power_usage = HOLOPAD_PASSIVE_POWER_USAGE + (HOLOGRAM_POWER_USAGE * total_users)
	if(total_users || pointing)
		set_light_on(TRUE)
	else
		set_light_on(FALSE)
	update_icon()

/obj/machinery/hologram/holopad/proc/set_holo(mob/living/user, obj/effect/overlay/holo_pad_hologram/h)
	LAZYSET(masters, user, h)
	LAZYSET(holorays, user, new /obj/effect/overlay/holoray(loc))
	var/mob/living/silicon/ai/AI = user
	if(istype(AI))
		AI.current = src
		if(AI.ai_holocolor)
			var/obj/effect/overlay/holoray/ray = holorays[user]
			ray.color = AI.ai_holocolor
	SetLightsAndPower()
	update_holoray(user, get_turf(loc))
	return TRUE

/obj/machinery/hologram/holopad/proc/clear_holo(mob/living/user)
	qdel(LAZYACCESS(masters, user)) // Get rid of user's hologram
	unset_holo(user)
	return TRUE

/obj/machinery/hologram/holopad/proc/unset_holo(mob/living/user)
	var/mob/living/silicon/ai/AI = user
	if(istype(AI) && AI.current == src)
		AI.current = null
	LAZYREMOVE(masters, user) // Discard AI from the list of those who use holopad
	if(!LAZYLEN(masters))
		set_can_hear_flags(CAN_HEAR_MASTERS, set_flag = FALSE)
	qdel(LAZYACCESS(holorays, user))
	LAZYREMOVE(holorays, user)
	SetLightsAndPower()
	return TRUE

/obj/machinery/hologram/holopad/proc/update_holoray(mob/living/user, turf/new_turf)
	var/obj/effect/overlay/holo_pad_hologram/holo = LAZYACCESS(masters, user)
	var/obj/effect/overlay/holoray/ray = LAZYACCESS(holorays, user)
	if(!holo || !ray)
		return
	var/disty = holo.y - ray.y
	var/distx = holo.x - ray.x
	var/newangle
	if(!disty)
		if(distx >= 0)
			newangle = 90
		else
			newangle = 270
	else
		newangle = arctan(distx/disty)
		if(disty < 0)
			newangle += 180
		else if(distx < 0)
			newangle += 360
	var/matrix/M = matrix()
	if(get_dist(get_turf(holo), new_turf) <= 1)
		animate(ray, transform = turn(M.Scale(1, sqrt(distx*distx+disty*disty)), newangle), time = 1)
	else
		ray.transform = turn(M.Scale(1, sqrt(distx*distx+disty*disty)), newangle)

/obj/machinery/hologram/holopad/proc/holo_point(atom/target, invisibility = 0)
	if(pointing)
		return
	var/turf/pad_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!pad_turf || !target_turf)
		return
	pointing = TRUE
	var/obj/effect/temp_visual/point/holo/visual = new(pad_turf, invisibility)
	var/obj/effect/overlay/holoray/point_ray = new(pad_turf)
	var/disty = target_turf.y - pad_turf.y
	var/distx = target_turf.x - pad_turf.x
	var/angle
	if(!disty)
		angle = distx >= 0 ? 90 : 270
	else
		angle = arctan(distx / disty)
		if(disty < 0)
			angle += 180
		else if(distx < 0)
			angle += 360
	var/matrix/ray_matrix = matrix()
	point_ray.transform = turn(ray_matrix.Scale(1, sqrt(distx * distx + disty * disty)), angle)
	animate(visual, pixel_x = distx * ICON_SIZE_X + target.pixel_x, pixel_y = disty * ICON_SIZE_Y + target.pixel_y, time = 1.7, easing = EASE_OUT)
	SetLightsAndPower()
	addtimer(CALLBACK(src, PROC_REF(clear_holo_point), point_ray), 2.5 SECONDS)
	return visual

/obj/machinery/hologram/holopad/proc/clear_holo_point(obj/effect/overlay/holoray/point_ray)
	qdel(point_ray)
	pointing = FALSE
	SetLightsAndPower()

/obj/machinery/hologram/holopad/proc/setup_replay_holo(datum/holorecord/record)
	var/obj/effect/overlay/holo_pad_hologram/hologram = new(loc)
	var/image/work_off = record.caller_image
	hologram.icon = work_off.icon
	hologram.icon_state = work_off.icon_state
	hologram.copy_overlays(work_off, TRUE)
	hologram.makeHologram()
	hologram.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	hologram.layer = FLY_LAYER
	SET_PLANE_EXPLICIT(hologram, ABOVE_GAME_PLANE, src)
	hologram.set_anchored(TRUE)
	hologram.name = "[record.caller_name] (hologram)"
	set_holo(record, hologram)
	visible_message(span_notice("Перед вами вспыхивает голографическое изображение: [record.caller_name]!"))
	return hologram

/obj/machinery/hologram/holopad/proc/replay_start()
	if(!disk)
		atom_say("Вставьте диск для воспроизведения записи.")
		return
	if(!disk.record)
		atom_say("На диске нет записи.")
		return
	if(replay_mode)
		return
	replay_mode = TRUE
	replay_holo = setup_replay_holo(disk.record)
	replay_entry(1)

/obj/machinery/hologram/holopad/proc/replay_stop()
	if(!replay_mode)
		return
	replay_mode = FALSE
	offset = 0
	deltimer(replay_timer)
	replay_timer = null
	clear_holo(disk.record)
	replay_holo = null

/obj/machinery/hologram/holopad/proc/record_start(mob/living/user)
	if(!istype(user) || !disk || disk.record)
		return
	disk.record = new
	record_mode = TRUE
	set_can_hear_flags(CAN_HEAR_RECORD_MODE)
	record_start = world.time
	record_user = user
	disk.record.set_caller_image(user)

/obj/machinery/hologram/holopad/proc/record_message(mob/living/speaker, message)
	if(!record_mode)
		return
	if(disk.record.caller_name == "Unknown")
		disk.record.caller_name = speaker.name
	var/current_delay = 0
	for(var/list/entry as anything in disk.record.entries)
		if(entry[1] == HOLORECORD_DELAY)
			current_delay += entry[2]
	var/time_delta = world.time - record_start - current_delay
	if(time_delta >= 1)
		disk.record.entries += list(list(HOLORECORD_DELAY, time_delta))
	disk.record.entries += list(list(HOLORECORD_SAY, message))
	if(length(disk.record.entries) >= HOLORECORD_MAX_LENGTH)
		record_stop()

/obj/machinery/hologram/holopad/proc/replay_entry(entry_number)
	replay_timer = null
	if(!replay_mode || !length(disk.record.entries))
		return
	if(length(disk.record.entries) < entry_number)
		if(!loop_mode)
			replay_stop()
			return
		replay_timer = addtimer(CALLBACK(src, PROC_REF(replay_entry), 1), HOLORECORD_LOOP_DELAY, TIMER_STOPPABLE)
		return
	var/list/entry = disk.record.entries[entry_number]
	switch(entry[1])
		if(HOLORECORD_SAY)
			replay_holo.atom_say(entry[2])
		if(HOLORECORD_DELAY)
			replay_timer = addtimer(CALLBACK(src, PROC_REF(replay_entry), entry_number + 1), entry[2], TIMER_STOPPABLE)
			return
	replay_entry(entry_number + 1)

/obj/machinery/hologram/holopad/proc/record_stop()
	if(!record_mode)
		return
	record_mode = FALSE
	record_user = null
	set_can_hear_flags(CAN_HEAR_RECORD_MODE, FALSE)

/obj/machinery/hologram/holopad/proc/record_clear()
	if(!disk?.record || replay_mode || record_mode)
		return
	QDEL_NULL(disk.record)

/obj/effect/overlay/holo_pad_hologram
	appearance_flags = TILE_BOUND|PIXEL_SCALE|LONG_GLIDE|KEEP_TOGETHER
	var/mob/living/Impersonation
	var/datum/holocall/HC

/obj/effect/overlay/holo_pad_hologram/Destroy()
	Impersonation = null
	if(!QDELETED(HC))
		HC.Disconnect(HC.calling_holopad)
	HC = null
	return ..()

/obj/effect/overlay/holo_pad_hologram/Process_Spacemove(movement_dir = NONE, continuous_move = FALSE)
	return TRUE

/obj/effect/overlay/holo_pad_hologram/examine(mob/user)
	if(Impersonation)
		. = Impersonation.examine(user)
	else
		. = ..()

/obj/effect/overlay/holoray
	name = "holoray"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "holoray"
	layer = FLY_LAYER
	pixel_x = -32
	pixel_y = -32
	alpha = 100

#undef HOLOPAD_PASSIVE_POWER_USAGE
#undef HOLOGRAM_POWER_USAGE
#undef CAN_HEAR_MASTERS
#undef CAN_HEAR_ACTIVE_HOLOCALLS
#undef CAN_HEAR_RECORD_MODE
#undef CAN_HEAR_HOLOCALL_USER
#undef CAN_HEAR_ALL_FLAGS
