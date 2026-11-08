/proc/has_net_cyberware(mob/target)
	if(!iscarbon(target))
		return FALSE
	var/mob/living/carbon/carbon_target = target
	return !!(locate(/obj/item/organ/internal/cyberimp) in carbon_target.internal_organs)

/mob/living/basic/net_avatar/proc/find_cyberware(mob/living/carbon/victim, implant_type)
	. = list()
	for(var/obj/item/organ/internal/cyberimp/implant in victim.internal_organs)
		if(istype(implant, implant_type) && !implant.emp_proof)
			. += implant

/mob/living/basic/net_avatar/proc/open_cyberware_hacks(mob/living/carbon/victim)
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	if(!neuro || neuro.crit_fail)
		balloon_alert(src, "нейроинтерфейс недоступен!")
		return
	if(!can_reach_node(victim))
		balloon_alert(src, "эхо вне досягаемости!")
		return
	var/list/options = list()
	for(var/hack_id in cyberware_hacks)
		var/list/hack = cyberware_hacks[hack_id]
		if(length(find_cyberware(victim, hack["requires"])))
			options["[hack["name"]] ([hack["cost"]] буфера)"] = hack_id
	if(!length(options))
		balloon_alert(src, "импланты защищены!")
		return
	var/choice = tgui_input_list(src, "Буфер: [round(neuro.get_buffer())]", "Киберэхо", options)
	if(!choice || QDELETED(victim) || stat != CONSCIOUS)
		return
	upload_cyberware_hack(victim, options[choice])

/mob/living/basic/net_avatar/proc/upload_cyberware_hack(mob/living/carbon/victim, hack_id)
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = get_neuro()
	var/list/hack = cyberware_hacks[hack_id]
	if(!neuro || neuro.get_buffer() < hack["cost"])
		balloon_alert(src, "мало буфера!")
		return
	if(!can_reach_node(victim))
		balloon_alert(src, "эхо вне досягаемости!")
		return
	to_chat(victim, span_userdanger("Импланты ловят чужой сигнал. Кто-то взламывает вас через Сеть!"))
	victim.playsound_local(get_turf(victim), 'sound/machines/twobeep.ogg', 50, TRUE)
	var/datum/beam/upload_beam = Beam(victim, "net_hack", 'icons/effects/netrunning.dmi', hack["upload"], beam_type = /obj/effect/ebeam/net)
	var/uploaded = do_after(src, hack["upload"], victim, DA_IGNORE_USER_LOC_CHANGE|DA_IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(can_reach_node), victim), interaction_key = victim)
	qdel(upload_beam)
	if(!uploaded || QDELETED(victim) || neuro.get_buffer() < hack["cost"] || !length(find_cyberware(victim, hack["requires"])))
		return
	neuro.spend_buffer(hack["cost"])
	add_trace(NET_TRACE_ICE_ACTION)
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/victim_neuro = victim.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEURO)
	if(victim_neuro?.has_firewall())
		balloon_alert(src, "файрвол отбил взлом!")
		to_chat(victim, span_notice("Файрвол кибердека отбивает взлом из Сети."))
		add_attack_logs(src, victim, "had the [hack_id] cyberware hack blocked by a firewall")
		return
	apply_cyberware_hack(victim, hack_id)
	new /obj/effect/temp_visual/net_glitch(get_turf(victim))
	add_attack_logs(src, victim, "uploaded the [hack_id] cyberware hack from the Net")

/mob/living/basic/net_avatar/proc/apply_cyberware_hack(mob/living/carbon/victim, hack_id)
	var/list/hack = cyberware_hacks[hack_id]
	var/list/implants = find_cyberware(victim, hack["requires"])
	switch(hack_id)
		if(NET_WARE_OPTICS)
			victim.EyeBlind(NET_WARE_BLIND_TIME)
			to_chat(victim, span_userdanger("Кибер-глаза гаснут, и мир проваливается во тьму!"))
		if(NET_WARE_ARM)
			for(var/obj/item/organ/internal/cyberimp/arm/arm_implant as anything in implants)
				arm_implant.Retract()
				var/obj/item/held = victim.get_item_by_slot(arm_implant.parent_organ_zone == BODY_ZONE_R_ARM ? ITEM_SLOT_HAND_RIGHT : ITEM_SLOT_HAND_LEFT)
				if(held)
					victim.drop_item_ground(held)
			to_chat(victim, span_userdanger("Рука с имплантом дёргается и разжимается сама собой!"))
		if(NET_WARE_OVERHEAT)
			var/obj/item/organ/internal/cyberimp/overheated = pick(implants)
			victim.apply_damage(NET_WARE_OVERHEAT_DAMAGE, BURN, overheated.parent_organ_zone)
			to_chat(victim, span_userdanger("[DECLENT_RU_CAP(overheated, NOMINATIVE)] раскаляется изнутри!"))
		if(NET_WARE_SYNAPSE)
			victim.Confused(NET_WARE_CONFUSION_TIME)
			victim.Jitter(NET_WARE_CONFUSION_TIME)
			to_chat(victim, span_userdanger("В голове визжат помехи, мысли рассыпаются!"))
		if(NET_WARE_NEURO)
			var/obj/item/organ/internal/cyberimp/brain/neuro_interface/victim_neuro = implants[1]
			victim_neuro.force_reboot()
			to_chat(victim, span_userdanger("Нейроинтерфейс сбрасывает буфер и уходит в перезагрузку!"))
