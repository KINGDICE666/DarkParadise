/mob/living/basic/net_avatar/proc/open_combat_hacks(mob/living/basic/net_avatar/victim)
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	if(!neuro || neuro.crit_fail)
		balloon_alert(src, "нейроадаптер недоступен!")
		return
	if(!can_reach_node(victim))
		balloon_alert(src, "цель вне досягаемости!")
		return
	var/black_deck = neuro.has_black_deck()
	var/list/options = list()
	for(var/hack_id in combat_hacks)
		var/list/hack = combat_hacks[hack_id]
		if(hack["black"] && !black_deck)
			continue
		options["[hack["name"]] ([hack["cost"]] буфера)"] = hack_id
	var/choice = tgui_input_list(src, "Буфер: [round(neuro.get_buffer())]", DECLENT_RU_CAP(victim, NOMINATIVE), options)
	if(!choice || QDELETED(victim) || stat != CONSCIOUS)
		return
	upload_hack(victim, options[choice])

/mob/living/basic/net_avatar/proc/upload_hack(mob/living/basic/net_avatar/victim, hack_id)
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	var/list/hack = combat_hacks[hack_id]
	if(!neuro || neuro.get_buffer() < hack["cost"])
		balloon_alert(src, "мало буфера!")
		return
	if(!can_reach_node(victim))
		balloon_alert(src, "цель вне досягаемости!")
		return
	to_chat(victim, span_userdanger("Входящий взлом «[hack["name"]]» от [declent_ru(GENITIVE)]! Разорвите прямую видимость!"))
	victim.playsound_local(get_turf(victim), 'sound/machines/twobeep.ogg', 50, TRUE)
	var/datum/beam/upload_beam = Beam(victim, "net_hack", 'icons/effects/netrunning.dmi', hack["upload"], beam_type = /obj/effect/ebeam/net)
	var/uploaded = do_after(src, hack["upload"], victim, DA_IGNORE_USER_LOC_CHANGE|DA_IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(can_reach_node), victim), interaction_key = victim)
	qdel(upload_beam)
	if(!uploaded || QDELETED(victim) || victim.stat == DEAD || neuro.get_buffer() < hack["cost"])
		return
	neuro.spend_buffer(hack["cost"])
	victim.receive_hack(hack_id)
	add_attack_logs(src, victim, "uploaded the [hack_id] quickhack in the Net")

/mob/living/basic/net_avatar/proc/receive_hack(hack_id)
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	var/modifier = neuro?.has_firewall() ? NET_FIREWALL_MODIFIER : 1
	new /obj/effect/temp_visual/net_glitch(get_turf(src))
	playsound_local(get_turf(src), 'sound/effects/sparks4.ogg', 50, TRUE)
	switch(hack_id)
		if(NET_HACK_SHORT_CIRCUIT)
			apply_damage(NET_SHORT_CIRCUIT_DAMAGE * modifier, BURN)
			to_chat(src, span_userdanger("Короткое замыкание прошивает поток данных!"))
		if(NET_HACK_OVERHEAT)
			apply_status_effect(/datum/status_effect/net_overheat, modifier)
			to_chat(src, span_userdanger("Поток данных раскаляется!"))
		if(NET_HACK_OPTICS)
			apply_status_effect(/datum/status_effect/net_optics_glitch, NET_OPTICS_DURATION * modifier)
			to_chat(src, span_userdanger("Оптика сбоит, мир рассыпается на помехи!"))
		if(NET_HACK_REBOOT)
			Stun(NET_REBOOT_DURATION * modifier, TRUE)
			to_chat(src, span_userdanger("Система уходит в принудительную перезагрузку!"))
		if(NET_HACK_SYNAPSE)
			apply_damage(NET_SYNAPSE_DAMAGE * modifier, BURN)
			to_chat(src, span_userdanger("Синапсовый выжигатель бьёт прямо в нейроны!"))

/mob/living/basic/net_avatar/proc/defragment()
	if(stat == DEAD)
		return
	if(health < last_health)
		last_hurt = world.time
	else if(health < maxHealth && world.time - last_hurt > NET_DEFRAG_DELAY)
		adjustBruteLoss(-NET_DEFRAG_HEAL)
		adjustFireLoss(-NET_DEFRAG_HEAL)
	last_health = health

/obj/effect/ebeam/net
	invisibility = INVISIBILITY_NETRUNNER

/datum/status_effect/net_overheat
	id = "net_overheat"
	duration = NET_OVERHEAT_DURATION
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	var/damage_modifier = 1

/datum/status_effect/net_overheat/on_creation(mob/living/new_owner, damage_modifier)
	src.damage_modifier = damage_modifier
	return ..()

/datum/status_effect/net_overheat/tick(seconds_between_ticks)
	owner.apply_damage(NET_OVERHEAT_TICK_DAMAGE * damage_modifier, BURN)

/datum/status_effect/net_optics_glitch
	id = "net_optics_glitch"
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/net_optics_glitch/on_creation(mob/living/new_owner, duration)
	src.duration = duration
	return ..()

/datum/status_effect/net_optics_glitch/on_apply()
	owner.overlay_fullscreen("net_optics", /atom/movable/screen/fullscreen/blind)
	return TRUE

/datum/status_effect/net_optics_glitch/on_remove()
	owner.clear_fullscreen("net_optics")
