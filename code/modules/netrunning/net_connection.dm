/datum/component/net_connection
	var/mob/living/carbon/human/body
	var/obj/machinery/netpod/pod
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro
	var/lost = FALSE
	var/datum/action/innate/net_jack_out/jack_out_action
	var/datum/action/innate/net_neuro_panel/panel_action

/datum/component/net_connection/Initialize(mob/living/carbon/human/body, obj/machinery/netpod/pod)
	if(!isnetavatar(parent) || !ishuman(body) || isnull(body.mind))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/basic/net_avatar/avatar = parent
	src.body = body
	src.pod = pod

	avatar.copy_body(body)
	avatar.home_area = get_area(pod)
	ADD_TRAIT(body, TRAIT_MIND_TEMPORARILY_GONE, NETRUNNING_TRAIT)
	body.mind.transfer_to(avatar)

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
		RegisterSignals(neuro, list(COMSIG_ORGAN_REMOVED, COMSIG_QDELETING), PROC_REF(lose_connection))
		panel_action = new(neuro)
		panel_action.Grant(avatar)

	avatar.playsound_local(get_turf(avatar), 'sound/effects/phasein.ogg', 25, TRUE)
	to_chat(avatar, span_notice("Вы погружаетесь в Сеть. Здесь нет людей — только машины, узлы и другие нетраннеры."))
	to_chat(avatar, span_warning("Смерть в Сети убьёт ваше тело. Если тело вынут из капсулы, вы останетесь здесь навсегда."))
	add_game_logs("jacked into the Net from [AREACOORD(pod)]", avatar)

/datum/component/net_connection/Destroy(force)
	release_body()
	QDEL_NULL(jack_out_action)
	return ..()

/datum/component/net_connection/proc/release_body()
	if(neuro)
		UnregisterSignal(neuro, list(COMSIG_ORGAN_REMOVED, COMSIG_QDELETING))
		neuro.set_net_operator(null)
		neuro = null
	QDEL_NULL(panel_action)
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
	var/mob/living/carbon/human/returning_body = body
	var/obj/machinery/netpod/returning_pod = pod
	add_game_logs("jacked out of the Net at [AREACOORD(avatar)]", avatar)
	release_body()
	avatar.mind?.transfer_to(returning_body)
	returning_pod.disconnect_occupant()
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

/datum/component/net_connection/proc/on_avatar_death(datum/source, gibbed)
	SIGNAL_HANDLER
	if(lost)
		return
	var/mob/living/basic/net_avatar/avatar = parent
	var/mob/living/carbon/human/dying_body = body
	var/obj/machinery/netpod/dying_pod = pod
	add_game_logs("flatlined in the Net at [AREACOORD(avatar)]", avatar)
	release_body()
	avatar.mind?.transfer_to(dying_body)
	to_chat(dying_body, span_userdanger("ФЛЭТЛАЙН. Сигнал из Сети выжигает нейроны дотла."))
	if(dying_body.stat != DEAD)
		dying_body.death()
	dying_pod.disconnect_occupant()

/datum/component/net_connection/proc/on_body_death(datum/source, gibbed)
	SIGNAL_HANDLER
	var/mob/living/basic/net_avatar/avatar = parent
	to_chat(avatar, span_userdanger("Ваше тело в капсуле умирает. Поток данных гаснет..."))
	avatar.death()

/datum/component/net_connection/proc/on_body_examine(mob/living/carbon/human/source, mob/user, list/examine_list)
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
