/obj/machinery/quantum_server/proc/cold_boot_map(map_key, was_random_selection = FALSE)
	if(!is_ready)
		return FALSE

	if(isnull(map_key))
		balloon_alert_to_viewers("домен не выбран!")
		return FALSE

	if(generated_domain)
		balloon_alert_to_viewers("сначала остановите домен!")
		return FALSE

	if(length(avatar_connection_refs))
		balloon_alert_to_viewers("сначала отключите всех!")
		return FALSE

	is_ready = FALSE
	playsound(src, 'sound/machines/terminal_processing.ogg', 30, TRUE)

	if(!load_domain(map_key) || !load_map_items())
		balloon_alert_to_viewers("сбой инициализации!")
		scrub_vdom()
		is_ready = TRUE
		return FALSE

	is_ready = TRUE
	domain_randomized = was_random_selection
	points -= generated_domain.cost
	generated_domain.start_time = world.time

	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 30, TRUE)
	balloon_alert_to_viewers("домен загружен")
	update_use_power(ACTIVE_POWER_USE)
	update_appearance()
	return TRUE

/obj/machinery/quantum_server/proc/load_domain(map_key)
	for(var/datum/lazy_template/virtual_domain/available as anything in get_virtual_domains())
		if(map_key == available.key && points >= available.cost)
			generated_domain = available
			break

	if(isnull(generated_domain))
		return FALSE

	domain_reservation = generated_domain.lazy_load()
	if(isnull(domain_reservation))
		generated_domain = null
		return FALSE

	return TRUE

/obj/machinery/quantum_server/proc/load_map_items()
	var/list/obj/effect/landmark/bitrunning/found_landmarks = list()
	for(var/obj/effect/landmark/bitrunning/landmark in GLOB.landmarks_list)
		found_landmarks += landmark

	var/list/turf/cache_turfs = list()

	for(var/obj/effect/landmark/bitrunning/landmark as anything in found_landmarks)
		var/turf/tile = get_turf(landmark)

		if(istype(landmark, /obj/effect/landmark/bitrunning/hololadder_spawn))
			exit_turfs += tile

		else if(istype(landmark, /obj/effect/landmark/bitrunning/permanent_exit))
			exit_turfs += tile
			new /obj/structure/hololadder(tile, src)

		else if(istype(landmark, /obj/effect/landmark/bitrunning/cache_goal_turf))
			goal_turfs += tile
			RegisterSignal(tile, COMSIG_ATOM_ENTERED, PROC_REF(on_goal_turf_entered))

		else if(istype(landmark, /obj/effect/landmark/bitrunning/cache_spawn))
			cache_turfs += tile

		qdel(landmark)

	if(!length(exit_turfs))
		stack_trace("vdom: no exit turfs on [generated_domain.key]")
		return FALSE

	if(!length(goal_turfs))
		stack_trace("vdom: no goal turfs on [generated_domain.key]")
		return FALSE

	return attempt_spawn_cache(cache_turfs)

/obj/machinery/quantum_server/proc/begin_shutdown(mob/living/user)
	if(isnull(generated_domain))
		return

	if(!length(avatar_connection_refs))
		balloon_alert_to_viewers("отключение домена...")
		playsound(src, 'sound/machines/terminal_off.ogg', 40, TRUE)
		reset()
		return

	balloon_alert_to_viewers("оповещение клиентов...")
	playsound(src, 'sound/machines/terminal_alert.ogg', 100, TRUE)
	user.visible_message(
		span_danger("[user] начинает обесточивать [declent_ru(ACCUSATIVE)]!"),
		span_notice("Вы начинаете отключать клиентов..."),
		span_danger("Вы слышите быстрый стук по клавиатуре."),
	)

	SEND_SIGNAL(src, COMSIG_BITRUNNER_SHUTDOWN_ALERT, user)

	if(!do_after(user, 20 SECONDS, src))
		return

	reset()

/obj/machinery/quantum_server/proc/reset()
	is_ready = FALSE
	domain_complete = FALSE
	domain_randomized = FALSE
	retries_spent = 0

	sever_connections()

	addtimer(CALLBACK(src, PROC_REF(scrub_vdom)), 15 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
	addtimer(CALLBACK(src, PROC_REF(cool_off)), round(server_cooldown_time * capacitor_coefficient), TIMER_UNIQUE|TIMER_OVERRIDE)

	update_use_power(IDLE_POWER_USE)
	update_appearance()

/obj/machinery/quantum_server/proc/scrub_vdom()
	sever_connections()
	SEND_SIGNAL(src, COMSIG_BITRUNNER_DOMAIN_SCRUBBED)

	for(var/turf/tile as anything in goal_turfs)
		UnregisterSignal(tile, COMSIG_ATOM_ENTERED)

	if(domain_reservation)
		for(var/turf/tile as anything in domain_reservation.reserved_turfs)
			tile.empty()
		generated_domain?.reservations -= domain_reservation
		QDEL_NULL(domain_reservation)

	avatar_connection_refs.Cut()
	exit_turfs.Cut()
	goal_turfs.Cut()
	generated_domain = null

	update_use_power(IDLE_POWER_USE)
	update_appearance()
