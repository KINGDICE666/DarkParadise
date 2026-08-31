/datum/component/avatar_connection
	var/datum/weakref/netpod_ref
	var/datum/weakref/old_body_ref
	var/datum/weakref/server_ref
	var/nohit = TRUE

/datum/component/avatar_connection/Initialize(mob/living/old_body, obj/machinery/quantum_server/server, obj/machinery/netpod/pod)
	if(!isliving(parent) || !isliving(old_body) || isnull(old_body.key))
		return COMPONENT_INCOMPATIBLE

	if(!server.is_operational() || !pod.is_operational())
		return COMPONENT_INCOMPATIBLE

	var/mob/living/avatar = parent

	netpod_ref = WEAKREF(pod)
	old_body_ref = WEAKREF(old_body)
	server_ref = WEAKREF(server)
	server.avatar_connection_refs += WEAKREF(src)

	ADD_TRAIT(old_body, TRAIT_MIND_TEMPORARILY_GONE, NETPOD_TRAIT)
	avatar.possess_by_player(old_body.key)
	if(isnull(avatar.mind))
		avatar.mind_initialize()

	RegisterSignals(old_body, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED), PROC_REF(on_sever_connection))
	RegisterSignal(pod, COMSIG_BITRUNNER_CROWBAR_ALERT, PROC_REF(on_netpod_crowbar))
	RegisterSignal(pod, COMSIG_BITRUNNER_NETPOD_INTEGRITY, PROC_REF(on_netpod_damaged))
	RegisterSignal(pod, COMSIG_BITRUNNER_NETPOD_SEVER, PROC_REF(on_sever_connection))
	RegisterSignal(server, COMSIG_BITRUNNER_DOMAIN_COMPLETE, PROC_REF(on_domain_completed))
	RegisterSignal(server, COMSIG_BITRUNNER_QSRV_SEVER, PROC_REF(on_sever_connection))
	RegisterSignal(server, COMSIG_BITRUNNER_SHUTDOWN_ALERT, PROC_REF(on_shutting_down))

	avatar.playsound_local(get_turf(avatar), 'sound/effects/phasein.ogg', 25, TRUE)
	avatar.EyeBlind(1 SECONDS)
	to_chat(avatar, span_notice("Соединение установлено. [server.generated_domain.help_text]"))

/datum/component/avatar_connection/Destroy(force)
	var/mob/living/old_body = old_body_ref?.resolve()
	if(old_body)
		REMOVE_TRAIT(old_body, TRAIT_MIND_TEMPORARILY_GONE, NETPOD_TRAIT)
		UnregisterSignal(old_body, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))

	var/obj/machinery/netpod/pod = netpod_ref?.resolve()
	if(pod)
		UnregisterSignal(pod, list(COMSIG_BITRUNNER_CROWBAR_ALERT, COMSIG_BITRUNNER_NETPOD_INTEGRITY, COMSIG_BITRUNNER_NETPOD_SEVER))

	var/obj/machinery/quantum_server/server = server_ref?.resolve()
	if(server)
		server.avatar_connection_refs -= WEAKREF(src)
		UnregisterSignal(server, list(COMSIG_BITRUNNER_DOMAIN_COMPLETE, COMSIG_BITRUNNER_QSRV_SEVER, COMSIG_BITRUNNER_SHUTDOWN_ALERT))

	netpod_ref = null
	old_body_ref = null
	server_ref = null
	return ..()

/datum/component/avatar_connection/RegisterWithParent()
	ADD_TRAIT(parent, TRAIT_TEMPORARY_BODY, NETPOD_TRAIT)
	RegisterSignals(parent, list(COMSIG_BITRUNNER_ALERT_SEVER, COMSIG_BITRUNNER_CACHE_SEVER, COMSIG_BITRUNNER_LADDER_SEVER), PROC_REF(on_safe_disconnect))
	RegisterSignals(parent, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING), PROC_REF(on_sever_connection))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_linked_damage))

/datum/component/avatar_connection/UnregisterFromParent()
	REMOVE_TRAIT(parent, TRAIT_TEMPORARY_BODY, NETPOD_TRAIT)
	UnregisterSignal(parent, list(
		COMSIG_BITRUNNER_ALERT_SEVER,
		COMSIG_BITRUNNER_CACHE_SEVER,
		COMSIG_BITRUNNER_LADDER_SEVER,
		COMSIG_LIVING_DEATH,
		COMSIG_MOB_APPLY_DAMAGE,
		COMSIG_QDELETING,
	))

/datum/component/avatar_connection/proc/full_avatar_disconnect(cause_damage = FALSE)
	return_to_old_body()

	var/obj/machinery/netpod/pod = netpod_ref?.resolve()
	pod?.disconnect_occupant(cause_damage)

	qdel(src)

/datum/component/avatar_connection/proc/return_to_old_body()
	var/mob/living/avatar = parent
	var/mob/living/old_body = old_body_ref?.resolve()
	var/player_key = avatar.key

	if(isnull(old_body) || isnull(player_key))
		return

	old_body.possess_by_player(player_key)

/datum/component/avatar_connection/proc/on_linked_damage(datum/source, damage, damagetype, def_zone, blocked, sharp, used_weapon, spread_damage, forced)
	SIGNAL_HANDLER

	var/mob/living/old_body = old_body_ref?.resolve()
	if(isnull(old_body) || damagetype == STAMINA || damagetype == OXY)
		return

	nohit = FALSE

	if(damage >= old_body.health + old_body.maxHealth)
		full_avatar_disconnect(cause_damage = TRUE)
		return

	var/zone = def_zone
	if(isexternalorgan(def_zone))
		var/obj/item/organ/external/limb = def_zone
		zone = limb.limb_zone

	old_body.apply_damage(damage, damagetype, zone, blocked, forced = TRUE)

	if(old_body.stat != CONSCIOUS)
		full_avatar_disconnect(cause_damage = TRUE)

/datum/component/avatar_connection/proc/on_domain_completed(datum/source, atom/movable/forge, reward_points)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.playsound_local(get_turf(avatar), 'sound/machines/terminal_success.ogg', 50, TRUE)
	avatar.throw_alert(ALERT_BITRUNNER_COMPLETED, /atom/movable/screen/alert/bitrunning/domain_complete, new_master = forge)

/datum/component/avatar_connection/proc/on_netpod_crowbar(datum/source, mob/living/intruder)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.playsound_local(get_turf(avatar), 'sound/machines/terminal_alert.ogg', 50, TRUE)
	avatar.throw_alert(ALERT_BITRUNNER_CROWBAR, /atom/movable/screen/alert/bitrunning/crowbar, new_master = intruder)

/datum/component/avatar_connection/proc/on_netpod_damaged(datum/source)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.throw_alert(ALERT_BITRUNNER_INTEGRITY, /atom/movable/screen/alert/bitrunning/integrity, new_master = source)

/datum/component/avatar_connection/proc/on_shutting_down(datum/source, mob/living/hackerman)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.playsound_local(get_turf(avatar), 'sound/machines/terminal_alert.ogg', 50, TRUE)
	avatar.throw_alert(ALERT_BITRUNNER_SHUTDOWN, /atom/movable/screen/alert/bitrunning/shutdown, new_master = hackerman)

/datum/component/avatar_connection/proc/on_safe_disconnect(datum/source)
	SIGNAL_HANDLER

	full_avatar_disconnect()

/datum/component/avatar_connection/proc/on_sever_connection(datum/source)
	SIGNAL_HANDLER

	full_avatar_disconnect(cause_damage = TRUE)
