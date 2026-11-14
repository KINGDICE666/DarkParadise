/datum/looping_sound/ship_engine/ion
	start_sound = 'sound/machines/fission/centrifuge_start.ogg'
	start_length = 0.9 SECONDS
	mid_sounds = list('sound/machines/fission/centrifuge_mid.ogg' = 1)
	mid_length = 1 SECONDS
	end_sound = 'sound/machines/fission/reactor_shutoff.ogg'
	volume = 30

/datum/looping_sound/ship_engine/heavy
	start_sound = 'sound/machines/gravgen/grav_gen_start.ogg'
	start_length = 1 SECONDS
	mid_sounds = list(
		'sound/machines/gravgen/grav_gen_mid1.ogg' = 12,
		'sound/machines/gravgen/grav_gen_mid2.ogg' = 1,
	)
	mid_length = 2.3 SECONDS
	end_sound = 'sound/machines/gravgen/grav_gen_end.ogg'
	volume = 45
	extra_range = 10

/datum/looping_sound/ship_engine/plasma
	start_sound = 'sound/effects/unathiignite.ogg'
	mid_sounds = list('sound/machines/hypertorus/loops/hypertorus_nominal.ogg' = 1)
	mid_length = 6.5 SECONDS
	end_sound = 'sound/machines/hiss.ogg'
	volume = 35
	extra_range = 10

/proc/overmap_engine_heat_step(heat, thrust_limit, overdrive, firing, elapsed)
	if(firing && overdrive)
		return min(heat + OVERMAP_ENGINE_HEAT_RATE * thrust_limit * elapsed / (1 SECONDS), OVERMAP_ENGINE_HEAT_MAX)
	return max(heat - OVERMAP_ENGINE_COOL_RATE * elapsed / (1 SECONDS), 0)

/obj/machinery/ship_engine/proc/overdrive_factor()
	return overdrive ? OVERMAP_ENGINE_OVERDRIVE_THRUST : 1

/obj/machinery/ship_engine/proc/set_overdrive(enabled)
	if(overdrive == enabled)
		return
	overdrive = enabled
	if(overdrive)
		START_PROCESSING(SSmachines, src)

/obj/machinery/ship_engine/proc/heat_engine(elapsed)
	heat = overmap_engine_heat_step(heat, thrust_limit, overdrive, TRUE, elapsed)
	if(heat > 0)
		START_PROCESSING(SSmachines, src)
	if(heat >= OVERMAP_ENGINE_HEAT_MAX && !overheated)
		overheat()

/obj/machinery/ship_engine/proc/overheat()
	overheated = TRUE
	set_firing(FALSE)
	playsound(src, 'sound/machines/engine_alert2.ogg', 60, TRUE)
	do_sparks(4, TRUE, src)
	take_damage(max_integrity * OVERMAP_ENGINE_OVERHEAT_DAMAGE, BURN, sound_effect = FALSE)
	if(QDELETED(src))
		return
	visible_message(span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] перегревается и аварийно глохнет!"))
	vessel?.announce_engine_fault(src)
	update_icon(UPDATE_OVERLAYS)

/obj/machinery/ship_engine/process()
	if(firing)
		return
	heat = overmap_engine_heat_step(heat, thrust_limit, overdrive, FALSE, SSMACHINES_DT SECONDS)
	if(overheated && heat <= OVERMAP_ENGINE_HEAT_RESTART)
		overheated = FALSE
		playsound(src, 'sound/machines/hiss.ogg', 30, TRUE)
		update_icon(UPDATE_OVERLAYS)
	if(heat <= 0 && !overheated)
		return PROCESS_KILL

/obj/machinery/ship_engine/proc/burn_exhaust()
	if(world.time < next_exhaust_check || !isturf(loc) || !active_pushes)
		return
	next_exhaust_check = world.time + OVERMAP_ENGINE_EXHAUST_INTERVAL
	var/reach = engine_size + 1
	var/turf/center = locate(x + round((engine_size - 1) / 2), y + round((engine_size - 1) / 2), z)
	for(var/push in GLOB.cardinal)
		if(!(active_pushes & push))
			continue
		var/exhaust_dir = REVERSE_DIR(push)
		var/turf/cursor = center
		for(var/step in 1 to round(engine_size / 2) + reach)
			cursor = get_step(cursor, exhaust_dir)
			if(!cursor)
				break
			if(step <= round(engine_size / 2))
				continue
			if(!isspaceturf(cursor) || cursor.is_blocked_turf(exclude_mobs = TRUE))
				break
			for(var/mob/living/victim in cursor)
				victim.adjustFireLoss(OVERMAP_ENGINE_EXHAUST_BURN * overdrive_factor())
				to_chat(victim, span_userdanger("Вас обдаёт раскалённым выхлопом двигателя!"))

/obj/overmap/entity/proc/announce_engine_fault(obj/machinery/ship_engine/engine)
	LAZYOR(faulted_engines, engine)
	addtimer(CALLBACK(src, PROC_REF(report_engine_faults)), OVERMAP_ENGINE_FAULT_BATCH, TIMER_UNIQUE)

/obj/overmap/entity/proc/report_engine_faults()
	var/list/faulted = list()
	for(var/obj/machinery/ship_engine/engine as anything in faulted_engines)
		if(!QDELETED(engine) && engine.overheated)
			faulted += engine
	faulted_engines = null
	if(!length(faulted))
		return
	var/obj/machinery/ship_engine/first = faulted[1]
	var/text = length(faulted) == 1 ? "Двигатель «[first.declent_ru(NOMINATIVE)]» перегрелся и отключён до остывания." : "Перегрелись и отключены до остывания двигатели: [length(faulted)] из [length(engines)]."
	SEND_SIGNAL(src, COMSIG_OVERMAP_NOTICE, text, OVERMAP_NOTICE_WARN, OVERMAP_NOTICE_FROM_ENGINES)
	shuttle_visible_message(span_warning(text))

/datum/component/overmap_flight/proc/engine_turn_push(obj/machinery/ship_engine/engine)
	var/obj/overmap/entity/vessel = parent
	var/center_x = vessel.shuttle ? vessel.hull_center_x : vessel.physical_space?.center_x
	var/center_y = vessel.shuttle ? vessel.hull_center_y : vessel.physical_space?.center_y
	if(isnull(center_x) || isnull(center_y))
		return NONE
	var/arm_x = engine.x + (engine.engine_size - 1) / 2 - center_x
	var/arm_y = engine.y + (engine.engine_size - 1) / 2 - center_y
	var/tangent_x = arm_y * burn_turn
	var/tangent_y = -arm_x * burn_turn
	if(!tangent_x && !tangent_y)
		return NONE
	if(abs(tangent_x) >= abs(tangent_y))
		return tangent_x > 0 ? EAST : WEST
	return tangent_y > 0 ? NORTH : SOUTH
