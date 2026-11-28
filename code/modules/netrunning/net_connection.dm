/datum/component/net_connection
	var/mob/living/body
	var/obj/machinery/netpod/pod
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro
	var/lost = FALSE
	var/datum/action/innate/net_jack_out/jack_out_action
	var/datum/action/innate/net_neuro_panel/panel_action

/datum/component/net_connection/Initialize(mob/living/body, obj/machinery/netpod/pod)
	if(!isnetavatar(parent) || !isliving(body) || isnull(body.mind))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/basic/net_avatar/avatar = parent
	src.body = body
	src.pod = pod

	dress_avatar(avatar)
	avatar.home_area = get_area(pod)
	ADD_TRAIT(body, TRAIT_MIND_TEMPORARILY_GONE, NETRUNNING_TRAIT)
	move_pilot_in(avatar)

	RegisterSignal(avatar, COMSIG_LIVING_DEATH, PROC_REF(on_avatar_death))
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_body_death))
	RegisterSignal(body, COMSIG_ATOM_EXAMINE, PROC_REF(on_body_examine))
	RegisterSignals(body, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING), PROC_REF(lose_connection))
	RegisterSignals(pod, list(COMSIG_BITRUNNER_NETPOD_SEVER, COMSIG_QDELETING), PROC_REF(lose_connection))
	RegisterSignal(pod, COMSIG_BITRUNNER_CROWBAR_ALERT, PROC_REF(on_pod_pried))
	RegisterSignal(pod, COMSIG_BITRUNNER_NETPOD_INTEGRITY, PROC_REF(on_pod_damaged))

	jack_out_action = new(avatar)
	jack_out_action.Grant(avatar)

	neuro = body.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEURO)
	if(neuro)
		neuro.set_net_operator(avatar)
		avatar.maxHealth += neuro.get_avatar_integrity_bonus()
		avatar.updatehealth("net deck integrity")
		avatar.last_health = avatar.health
		RegisterSignals(neuro, list(COMSIG_ORGAN_REMOVED, COMSIG_QDELETING), PROC_REF(on_neuro_lost))
		panel_action = new(neuro)
		panel_action.Grant(avatar)

	avatar.playsound_local(get_turf(avatar), 'sound/effects/phasein.ogg', 25, TRUE)
	to_chat(avatar, span_notice("Вы погружаетесь в Сеть. Здесь нет людей — только машины, узлы и другие нетраннеры."))
	greet(avatar)
	add_game_logs("jacked into the Net from [AREACOORD(pod)]", avatar)

/datum/component/net_connection/proc/dress_avatar(mob/living/basic/net_avatar/avatar)
	avatar.copy_body(body)

/datum/component/net_connection/proc/move_pilot_in(mob/living/basic/net_avatar/avatar)
	body.mind.transfer_to(avatar)

/datum/component/net_connection/proc/move_pilot_out(mob/living/basic/net_avatar/avatar, mob/living/destination)
	avatar.mind?.transfer_to(destination)

/datum/component/net_connection/proc/greet(mob/living/basic/net_avatar/avatar)
	to_chat(avatar, span_warning("Смерть в Сети убьёт ваше тело. Если тело вынут из капсулы, вы останетесь здесь навсегда."))

/datum/component/net_connection/proc/get_hack_clearance()
	if(!neuro || neuro.crit_fail)
		return NONE
	return NET_HACK_USER_RUNNER | (neuro.has_black_deck() ? NET_HACK_USER_BLACK_DECK : NONE)

/datum/component/net_connection/proc/get_buffer()
	return neuro ? neuro.get_buffer() : 0

/datum/component/net_connection/proc/spend_buffer(amount)
	neuro?.spend_buffer(amount)

/datum/component/net_connection/proc/has_firewall()
	return neuro?.has_firewall()

/datum/component/net_connection/proc/get_access()
	return neuro?.owner?.get_access() || list()

/datum/component/net_connection/proc/is_station_system()
	return FALSE

/datum/component/net_connection/Destroy(force)
	release_neuro()
	release_body()
	QDEL_NULL(jack_out_action)
	return ..()

/datum/component/net_connection/proc/release_neuro()
	if(neuro)
		UnregisterSignal(neuro, list(COMSIG_ORGAN_REMOVED, COMSIG_QDELETING))
		neuro.set_net_operator(null)
		neuro = null
	QDEL_NULL(panel_action)

/datum/component/net_connection/proc/release_body()
	if(body)
		REMOVE_TRAIT(body, TRAIT_MIND_TEMPORARILY_GONE, NETRUNNING_TRAIT)
		UnregisterSignal(body, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED, COMSIG_QDELETING, COMSIG_ATOM_EXAMINE))
		body = null
	if(pod)
		UnregisterSignal(pod, list(COMSIG_BITRUNNER_NETPOD_SEVER, COMSIG_QDELETING, COMSIG_BITRUNNER_CROWBAR_ALERT, COMSIG_BITRUNNER_NETPOD_INTEGRITY))
		pod.connected = FALSE
		pod.update_icon()
		pod = null

/datum/component/net_connection/proc/try_jack_out()
	var/mob/living/basic/net_avatar/avatar = parent
	if(lost || avatar.stat == DEAD)
		return
	if(get_dist(avatar, pod) > 1)
		to_chat(avatar, span_notice("Вы разрываете поток данных и начинаете выход из Сети..."))
		var/start_health = avatar.health
		if(!do_after(avatar, NET_JACK_OUT_TIME, avatar, extra_checks = CALLBACK(src, PROC_REF(is_undisturbed), start_health)))
			return
		if(lost || avatar.stat == DEAD)
			return
	jack_out()

/datum/component/net_connection/proc/is_undisturbed(start_health)
	var/mob/living/basic/net_avatar/avatar = parent
	return avatar.health >= start_health

/datum/component/net_connection/proc/jack_out()
	var/mob/living/basic/net_avatar/avatar = parent
	var/mob/living/returning_body = body
	var/obj/machinery/netpod/returning_pod = pod
	add_game_logs("jacked out of the Net at [AREACOORD(avatar)]", avatar)
	release_neuro()
	release_body()
	move_pilot_out(avatar, returning_body)
	returning_pod.disconnect_occupant()
	if(avatar.stat != DEAD)
		new /obj/effect/temp_visual/net_dissolve(avatar.loc, avatar)
	qdel(avatar)

/datum/component/net_connection/proc/lose_connection(datum/source)
	SIGNAL_HANDLER
	if(lost)
		return
	var/mob/living/basic/net_avatar/avatar = parent
	lost = TRUE
	body?.AddElement(/datum/element/net_severed)
	release_body()
	QDEL_NULL(jack_out_action)
	avatar.playsound_local(get_turf(avatar), 'sound/effects/empulse.ogg', 40, TRUE)
	avatar.overlay_fullscreen("flash", /atom/movable/screen/fullscreen/flash/noise)
	addtimer(CALLBACK(avatar, TYPE_PROC_REF(/mob, clear_fullscreen), "flash", TRUE), 1 SECONDS)
	to_chat(avatar, span_userdanger("Связь с телом оборвалась. Выхода больше нет — вы заперты в Сети навсегда."))
	add_game_logs("lost the connection to their body and is trapped in the Net", avatar)

/datum/component/net_connection/proc/on_neuro_lost(datum/source)
	SIGNAL_HANDLER
	release_neuro()
	if(!lost)
		lose_connection()
		return
	var/mob/living/basic/net_avatar/avatar = parent
	to_chat(avatar, span_userdanger("Нейроадаптер вашего тела отключён. Кибердек больше не отвечает."))

/datum/component/net_connection/proc/on_avatar_death(datum/source, gibbed)
	SIGNAL_HANDLER
	if(lost)
		return
	var/mob/living/basic/net_avatar/avatar = parent
	var/mob/living/dying_body = body
	var/obj/machinery/netpod/dying_pod = pod
	add_game_logs("flatlined in the Net at [AREACOORD(avatar)]", avatar)
	release_neuro()
	release_body()
	move_pilot_out(avatar, dying_body)
	to_chat(dying_body, span_userdanger("ФЛЭТЛАЙН. Сигнал из Сети выжигает нейроны дотла."))
	if(dying_body.stat != DEAD)
		dying_body.death()
	dying_pod.disconnect_occupant()

/datum/component/net_connection/proc/on_body_death(datum/source, gibbed)
	SIGNAL_HANDLER
	var/mob/living/basic/net_avatar/avatar = parent
	to_chat(avatar, span_userdanger("Ваше тело в капсуле умирает. Поток данных гаснет..."))
	avatar.death()

/datum/component/net_connection/proc/on_body_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("Нейропорт на виске часто мерцает, а глаза бегают под сомкнутыми веками: сознание погружено в Сеть.")

/datum/component/net_connection/proc/on_pod_pried(datum/source, mob/living/intruder)
	SIGNAL_HANDLER
	var/mob/living/basic/net_avatar/avatar = parent
	avatar.playsound_local(get_turf(avatar), 'sound/machines/twobeep.ogg', 60, TRUE)
	to_chat(avatar, span_userdanger("Кто-то вскрывает вашу капсулу! Отключайтесь, пока связь не оборвалась!"))

/datum/component/net_connection/proc/on_pod_damaged(datum/source)
	SIGNAL_HANDLER
	var/mob/living/basic/net_avatar/avatar = parent
	to_chat(avatar, span_userdanger("Ваша капсула серьёзно повреждена! Ещё немного, и связь оборвётся."))

/datum/action/innate/net_jack_out
	name = "Отключиться от Сети"
	desc = "Вернуться в тело. Вдали от своей капсулы выход занимает несколько секунд и срывается от урона."
	button_icon = 'icons/effects/netrunning.dmi'
	button_icon_state = "jack_out"

/datum/action/innate/net_jack_out/Activate()
	var/datum/component/net_connection/connection = owner.GetComponent(/datum/component/net_connection)
	INVOKE_ASYNC(connection, TYPE_PROC_REF(/datum/component/net_connection, try_jack_out))

/datum/action/innate/net_neuro_panel
	name = "Панель нейроадаптера"
	desc = "Кибердек, буфер и подключённые узлы."
	button_icon = 'icons/hud/augment_actions.dmi'
	button_icon_state = "neuro_panel"

/datum/action/innate/net_neuro_panel/Activate()
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = target
	neuro.ui_interact(owner)

/datum/component/net_connection/ai
	var/datum/weakref/core_ref
	var/datum/weakref/ai_mind_ref
	var/buffer = NET_AI_BUFFER_MAX
	var/buffer_updated = 0
	var/tracked_health = 0
	var/transferring_damage = FALSE
	var/returning = FALSE

/datum/component/net_connection/ai/Initialize(mob/living/silicon/robot/body, obj/machinery/netpod/pod)
	if(!isrobot(body) || !body.shell || !body.deployed || QDELETED(body.mainframe))
		return COMPONENT_INCOMPATIBLE

	core_ref = WEAKREF(body.mainframe)
	ai_mind_ref = WEAKREF(body.mind)
	buffer_updated = world.time
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return

	var/mob/living/basic/net_avatar/avatar = parent
	var/mob/living/silicon/ai/core = body.mainframe
	tracked_health = avatar.health
	RegisterSignal(avatar, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_avatar_health_update))
	RegisterSignal(core, COMSIG_PREQDELETED, PROC_REF(on_core_lost))
	RegisterSignal(core, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_core_health_update))
	RegisterSignals(core, list(COMSIG_LIVING_ADJUST_BRUTE_DAMAGE, COMSIG_LIVING_ADJUST_BURN_DAMAGE), PROC_REF(on_core_damaged))
	RegisterSignal(body.mind, COMSIG_MIND_TRANSER_TO, PROC_REF(on_ai_mind_moved))
	core.show_remote_integrity(avatar)

/datum/component/net_connection/ai/Destroy(force)
	var/mob/living/silicon/ai/core = core_ref?.resolve()
	if(core)
		UnregisterSignal(core, list(COMSIG_PREQDELETED, COMSIG_LIVING_HEALTH_UPDATE, COMSIG_LIVING_ADJUST_BRUTE_DAMAGE, COMSIG_LIVING_ADJUST_BURN_DAMAGE))
	var/datum/mind/ai_mind = ai_mind_ref?.resolve()
	if(ai_mind)
		UnregisterSignal(ai_mind, COMSIG_MIND_TRANSER_TO)
	var/mob/living/avatar = parent
	UnregisterSignal(avatar, COMSIG_LIVING_HEALTH_UPDATE)
	avatar.clear_alert(ALERT_AI_CORE_INTEGRITY)
	core_ref = null
	ai_mind_ref = null
	return ..()

/datum/component/net_connection/ai/dress_avatar(mob/living/basic/net_avatar/avatar)
	var/mob/living/silicon/ai/core = core_ref.resolve()
	avatar.name = core.name
	avatar.real_name = core.real_name
	avatar.desc = "Сторожевой процесс ИИ станции: циановый силуэт из чистого кода."
	avatar.copy_languages(body, LANGUAGE_ATOM)
	avatar.add_filter("net_tint", 1, color_matrix_filter(MATRIX_NET_HOLOGRAM))
	avatar.add_filter("net_glow", 2, outline_filter(1, NET_HOLOGRAM_GLOW))
	avatar.particles.color = NET_HOLOGRAM_GLOW

/datum/component/net_connection/ai/move_pilot_in(mob/living/basic/net_avatar/avatar)
	avatar.possess_by_player(body.key)

/datum/component/net_connection/ai/move_pilot_out(mob/living/basic/net_avatar/avatar, mob/living/destination)
	var/datum/mind/ai_mind = ai_mind_ref?.resolve()
	var/mob/living/home = ai_mind?.current
	if(isnull(home) || isnull(avatar.key))
		return
	home.possess_by_player(avatar.key)
	if(avatar.mind && avatar.mind != ai_mind)
		SSticker.minds -= avatar.mind

/datum/component/net_connection/ai/greet(mob/living/basic/net_avatar/avatar)
	to_chat(avatar, span_notice("Вы — сторожевая система станции. Лёд пропускает вас, трассировка вас не замечает, а встроенный файрвол смягчает чужие взломы."))
	to_chat(avatar, span_notice("Против нарушителей у вас есть трассировка и изгнание из Сети. Буфер восполняется сам."))
	to_chat(avatar, span_warning("Урон аватара передаётся ядру ИИ. Если связь оборвётся, вы аварийно вернётесь в оболочку."))

/datum/component/net_connection/ai/get_hack_clearance()
	return NET_HACK_USER_STATION_AI

/datum/component/net_connection/ai/get_buffer()
	return min(NET_AI_BUFFER_MAX, buffer + (world.time - buffer_updated) / NET_AI_BUFFER_REGEN_TIME)

/datum/component/net_connection/ai/spend_buffer(amount)
	buffer = get_buffer() - amount
	buffer_updated = world.time

/datum/component/net_connection/ai/has_firewall()
	return TRUE

/datum/component/net_connection/ai/get_access()
	return IGNORE_ACCESS

/datum/component/net_connection/ai/is_station_system()
	return TRUE

/datum/component/net_connection/ai/lose_connection(datum/source)
	emergency_return("Связь с капсулой оборвалась! Аварийное возвращение.")

/datum/component/net_connection/ai/on_avatar_death(datum/source, gibbed)
	sync_core_damage()
	emergency_return("Аватар уничтожен! Аварийное возвращение.")

/datum/component/net_connection/ai/on_body_examine(mob/living/source, mob/user, list/examine_list)
	examine_list += span_notice("Индикаторы оболочки ровно мерцают: ИИ работает в Сети станции.")

/datum/component/net_connection/ai/proc/emergency_return(message)
	if(returning)
		return
	returning = TRUE
	to_chat(parent, span_userdanger(message))
	jack_out()

/datum/component/net_connection/ai/proc/sync_core_damage()
	var/mob/living/basic/net_avatar/avatar = parent
	var/damage = tracked_health - avatar.health
	tracked_health = avatar.health
	var/mob/living/silicon/ai/core = core_ref?.resolve()
	if(damage <= 0 || returning || isnull(core))
		return

	if(core.health - damage <= HEALTH_THRESHOLD_CRIT)
		emergency_return("Целостность ядра на пределе! Связь с Сетью разорвана, чтобы его спасти.")
		return

	var/old_integrity = core.get_integrity_percent()
	transferring_damage = TRUE
	core.adjustFireLoss(damage, forced = TRUE)
	transferring_damage = FALSE
	core.report_remote_damage(avatar, old_integrity)

/datum/component/net_connection/ai/proc/on_avatar_health_update(datum/source)
	SIGNAL_HANDLER
	sync_core_damage()

/datum/component/net_connection/ai/proc/on_core_health_update(mob/living/silicon/ai/source)
	SIGNAL_HANDLER
	if(!returning)
		source.show_remote_integrity(parent)

/datum/component/net_connection/ai/proc/on_core_damaged(datum/source, damagetype, amount, forced)
	SIGNAL_HANDLER
	if(amount <= 0 || transferring_damage)
		return
	emergency_return("Ядро ИИ атаковано на станции! Экстренное возвращение.")

/datum/component/net_connection/ai/proc/on_core_lost(datum/source)
	SIGNAL_HANDLER
	emergency_return("Связь с ядром потеряна!")

/datum/component/net_connection/ai/proc/on_ai_mind_moved(datum/mind/source, mob/living/new_character)
	SIGNAL_HANDLER
	emergency_return("Сознание ИИ отозвано из оболочки. Связь с Сетью разорвана.")
