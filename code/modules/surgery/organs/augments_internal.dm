/obj/item/organ/internal/cyberimp
	name = "cybernetic implant"
	desc = "Передовой имплант, расширяющий возможности носителя."
	status = ORGAN_ROBOT
	var/implant_color = "#FFFFFF"
	var/implant_overlay
	var/cyber_cost = 10
	var/can_pause = FALSE
	var/paused = FALSE
	var/worn_icon = 'icons/mob/cyberware.dmi'
	var/worn_state
	var/worn_color
	var/worn_glow = FALSE
	var/blocked = FALSE
	var/list/block_sources
	tough = TRUE // Immune to damage
	pickup_sound = 'sound/items/handling/component_pickup.ogg'
	drop_sound = 'sound/items/handling/component_drop.ogg'
	lefthand_file = 'icons/mob/inhands/implants_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/implants_righthand.dmi'
	abstract_type = /obj/item/organ/internal/cyberimp

/obj/item/organ/internal/cyberimp/get_ru_names()
	return alist(
		NOMINATIVE = "кибернетический имплант",
		GENITIVE = "кибернетического импланта",
		DATIVE = "кибернетическому импланту",
		ACCUSATIVE = "кибернетический имплант",
		INSTRUMENTAL = "кибернетическим имплантом",
		PREPOSITIONAL = "кибернетическом импланте",
	)

/obj/item/organ/internal/cyberimp/Initialize(mapload, mob/M = null)
	. = ..()
	if(implant_overlay)
		var/image/overlay = new /image(icon, implant_overlay)
		overlay.color = implant_color
		overlays |= overlay

/obj/item/organ/internal/cyberimp/emp_act(severity)
	if(emp_shielded(severity))
		return
	return // These shouldn't be hurt by EMPs in the standard way

/obj/item/organ/internal/cyberimp/can_insert(mob/living/user, mob/living/carbon/target, fail_message = "Данное устройство не предусмотрено для существ с подобной анатомией.")
	. = ..()

/obj/item/organ/internal/cyberimp/render()
	if(!worn_state)
		return
	var/mutable_appearance/worn_overlay = mutable_appearance(worn_icon, worn_state, layer = -CYBERWARE_WORN_LAYER)
	worn_overlay.color = worn_color
	if(!worn_glow || blocked)
		return worn_overlay
	return list(worn_overlay, emissive_appearance(worn_icon, worn_state, owner, layer = -CYBERWARE_WORN_LAYER))

/obj/item/organ/internal/proc/is_suppressed()
	return FALSE

/obj/item/organ/internal/cyberimp/is_suppressed()
	return blocked

/obj/item/organ/internal/cyberimp/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	clear_blocks()
	return ..()

/obj/item/organ/internal/cyberimp/proc/can_block()
	return owner && is_robotic() && !unremovable && !is_contraband()

/obj/item/organ/internal/cyberimp/proc/can_lock()
	return owner && is_robotic()

/obj/item/organ/internal/cyberimp/proc/set_blocked(new_state, source = CYBERWARE_BLOCK_MANUAL)
	if(new_state)
		LAZYOR(block_sources, source)
	else
		LAZYREMOVE(block_sources, source)
	return update_blocked()

/obj/item/organ/internal/cyberimp/proc/clear_blocks()
	block_sources = null
	return update_blocked()

/obj/item/organ/internal/cyberimp/proc/update_blocked()
	var/new_state = LAZYLEN(block_sources) > 0
	if(blocked == new_state)
		return FALSE
	blocked = new_state
	on_block_changed()
	for(var/datum/action/action as anything in actions)
		action.UpdateButtonIcon()
	update_worn_overlay()
	return TRUE

/obj/item/organ/internal/cyberimp/proc/on_block_changed()
	return

/obj/item/organ/internal/cyberimp/proc/update_worn_overlay()
	var/mob/living/carbon/human/human_owner = owner
	if(istype(human_owner))
		human_owner.update_int_organs()

/obj/item/organ/internal/cyberimp/proc/get_ripper_settings()
	. = list()
	if(can_pause)
		. += list(list("id" = "active", "name" = "Работа импланта", "kind" = "toggle", "value" = !paused))

/obj/item/organ/internal/cyberimp/proc/set_ripper_setting(setting, value)
	if(setting != "active" || !can_pause)
		return FALSE
	paused = !value
	return TRUE

//[[[[BRAIN]]]]

/obj/item/organ/internal/cyberimp/brain
	name = "cybernetic brain implant"
	cyber_cost = 12
	desc = "Инжекторы дополнительных подпрограмм для мозга."
	icon_state = "brain_implant"
	implant_overlay = "brain_implant_overlay"
	parent_organ_zone = BODY_ZONE_HEAD

/obj/item/organ/internal/cyberimp/brain/get_ru_names()
	return alist(
		NOMINATIVE = "имплант мозга",
		GENITIVE = "импланта мозга",
		DATIVE = "импланту мозга",
		ACCUSATIVE = "имплант мозга",
		INSTRUMENTAL = "имплантом мозга",
		PREPOSITIONAL = "импланте мозга",
	)

/obj/item/organ/internal/cyberimp/brain/emp_act(severity)
	if(!owner || emp_proof)
		return
	if(emp_shielded(severity))
		return
	var/stun_amount = (5 + (severity-1 ? 0 : 5)) STATUS_EFFECT_CONSTANT
	owner.Stun(stun_amount)
	to_chat(owner, span_warning("Ваше тело сводит судорогой!"))
	return stun_amount

/obj/item/organ/internal/cyberimp/brain/anti_drop
	name = "Anti-drop implant"
	desc = "Мозговой имплант, позволяющий принудительно сжать мышцы кистей и не выронить предмет. Переключается подёргиванием уха."
	var/active = FALSE
	var/l_hand_ignore = FALSE
	var/r_hand_ignore = FALSE
	var/obj/item/l_hand_obj = null
	var/obj/item/r_hand_obj = null
	implant_color = "#DE7E00"
	slot = INTERNAL_ORGAN_BRAIN_ANTIDROP
	cyber_cost = 15
	origin_tech = "materials=4;programming=5;biotech=4"
	actions_types = list(/datum/action/item_action/organ_action/toggle)

/obj/item/organ/internal/cyberimp/brain/anti_drop/get_ru_names()
	return alist(
		NOMINATIVE = "имплант \"Антисброс\"",
		GENITIVE = "импланта \"Антисброс\"",
		DATIVE = "импланту \"Антисброс\"",
		ACCUSATIVE = "имплант \"Антисброс\"",
		INSTRUMENTAL = "имплантом \"Антисброс\"",
		PREPOSITIONAL = "импланте \"Антисброс\"",
	)

/obj/item/organ/internal/cyberimp/brain/anti_drop/hardened
	name = "Hardened Anti-drop implant"
	desc = "Военная версия стандартного импланта для элитных сил НТ."
	origin_tech = "materials=6;programming=5;biotech=5"
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/brain/anti_drop/hardened/get_ru_names()
	return alist(
		NOMINATIVE = "укрепленный имплант анти-дроп",
		GENITIVE = "укрепленного импланта анти-дропа",
		DATIVE = "укрепленному импланту анти-дропа",
		ACCUSATIVE = "укрепленный имплант анти-дропа",
		INSTRUMENTAL = "укрепленным имплантом анти-дропа",
		PREPOSITIONAL = "укрепленном импланте анти-дропа",
	)

/obj/item/organ/internal/cyberimp/brain/anti_drop/ui_action_click(mob/user, datum/action/action, leftclick)
	active = !active
	if(active)
		l_hand_obj = owner.l_hand
		r_hand_obj = owner.r_hand
		if(l_hand_obj)
			if(HAS_TRAIT_FROM(l_hand_obj, TRAIT_NODROP, ANTIDROP_TRAIT))
				l_hand_ignore = TRUE
			else
				ADD_TRAIT(l_hand_obj, TRAIT_NODROP, ANTIDROP_TRAIT)
				RegisterSignal(l_hand_obj, COMSIG_ITEM_DROPPED, PROC_REF(on_held_item_dropped))
				l_hand_ignore = FALSE

		if(r_hand_obj)
			if(HAS_TRAIT_FROM(r_hand_obj, TRAIT_NODROP, ANTIDROP_TRAIT))
				r_hand_ignore = TRUE
			else
				ADD_TRAIT(r_hand_obj, TRAIT_NODROP, ANTIDROP_TRAIT)
				RegisterSignal(r_hand_obj, COMSIG_ITEM_DROPPED, PROC_REF(on_held_item_dropped))
				r_hand_ignore = FALSE

		if(!l_hand_obj && !r_hand_obj)
			to_chat(owner, span_notice("Вы ничего не держите, руки расслабляются..."))
			active = 0
		else
			var/msg = 0
			msg += !l_hand_ignore && l_hand_obj ? 1 : 0
			msg += !r_hand_ignore && r_hand_obj ? 2 : 0
			switch(msg)
				if(1)
					to_chat(owner, span_notice("Хватка левой руки усиливается."))
				if(2)
					to_chat(owner, span_notice("Хватка правой руки усиливается."))
				if(3)
					to_chat(owner, span_notice("Хватка обеих рук усиливается."))
	else
		release_items()
		to_chat(owner, span_notice("Ваши руки расслабляются..."))
		l_hand_obj = null
		r_hand_obj = null

/obj/item/organ/internal/cyberimp/brain/anti_drop/proc/on_held_item_dropped(obj/item/source, mob/user, slot)
	SIGNAL_HANDLER

	REMOVE_TRAIT(source, TRAIT_NODROP, ANTIDROP_TRAIT)
	UnregisterSignal(source, COMSIG_ITEM_DROPPED)

	if(l_hand_obj == source)
		l_hand_obj = null
		l_hand_ignore = FALSE
	else if(r_hand_obj == source)
		r_hand_obj = null
		r_hand_ignore = FALSE

	if(!l_hand_obj && !r_hand_obj)
		active = FALSE

/obj/item/organ/internal/cyberimp/brain/anti_drop/emp_act(severity)
	if(!owner || emp_proof)
		return
	if(emp_shielded(severity))
		return
	var/range = severity ? 10 : 5
	var/atom/A
	var/obj/item/L_item = owner.l_hand
	var/obj/item/R_item = owner.r_hand

	release_items()
	..()
	var/list/surrounds = oview(range)
	if(L_item)
		A = pick(surrounds)
		L_item.throw_at(A, range, 2)
		to_chat(owner, span_notice("Левую руку сводит спазмом, и она отбрасывает [L_item.declent_ru(ACCUSATIVE)]!"))
		l_hand_obj = null
	if(R_item)
		A = pick(surrounds)
		R_item.throw_at(A, range, 2)
		to_chat(owner, span_notice("Правую руку сводит спазмом, и она отбрасывает [R_item.declent_ru(ACCUSATIVE)]!"))
		r_hand_obj = null

/obj/item/organ/internal/cyberimp/brain/anti_drop/proc/release_items()
	active = FALSE
	if(!l_hand_ignore && (l_hand_obj in owner.contents))
		REMOVE_TRAIT(l_hand_obj, TRAIT_NODROP, ANTIDROP_TRAIT)
	if(!r_hand_ignore && (r_hand_obj in owner.contents))
		REMOVE_TRAIT(r_hand_obj, TRAIT_NODROP, ANTIDROP_TRAIT)

/obj/item/organ/internal/cyberimp/brain/anti_drop/on_block_changed()
	if(blocked && active)
		ui_action_click()

/obj/item/organ/internal/cyberimp/brain/anti_drop/remove(mob/living/carbon/M, special = ORGAN_MANIPULATION_DEFAULT)
	if(active)
		ui_action_click()
	return ..()

/obj/item/organ/internal/cyberimp/brain/anti_stun
	name = "CNS Rebooter implant"
	desc = "Имплант сам возвращает вам контроль над центральной нервной системой и сокращает время оглушения. Несовместим с \"Нейростартером\"."
	implant_color = "#FFFF00"
	slot = INTERNAL_ORGAN_BRAIN_ANTISTUN
	cyber_cost = 30
	can_pause = TRUE
	origin_tech = "materials=5;programming=4;biotech=5"

/obj/item/organ/internal/cyberimp/brain/anti_stun/get_ru_names()
	return alist(
		NOMINATIVE = "имплант \"Перезапуск ЦНС\"",
		GENITIVE = "импланта \"Перезапуск ЦНС\"",
		DATIVE = "импланту \"Перезапуск ЦНС\"",
		ACCUSATIVE = "имплант \"Перезапуск ЦНС\"",
		INSTRUMENTAL = "имплантом \"Перезапуск ЦНС\"",
		PREPOSITIONAL = "импланте \"Перезапуск ЦНС\"",
	)

/obj/item/organ/internal/cyberimp/brain/anti_stun/hardened
	name = "Hardened CNS Rebooter implant"
	desc = "Военная версия стандартного импланта для элитных сил НТ."
	origin_tech = "materials=6;programming=5;biotech=5"
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/brain/anti_stun/hardened/get_ru_names()
	return alist(
		NOMINATIVE = "имплант \"Перезапуск ЦНС\" (укреплённый)",
		GENITIVE = "импланта \"Перезапуск ЦНС\" (укреплённый)",
		DATIVE = "импланту \"Перезапуск ЦНС\" (укреплённый)",
		ACCUSATIVE = "имплант \"Перезапуск ЦНС\" (укреплённый)",
		INSTRUMENTAL = "имплантом \"Перезапуск ЦНС\" (укреплённый)",
		PREPOSITIONAL = "импланте \"Перезапуск ЦНС\" (укреплённый)",
	)

/obj/item/organ/internal/cyberimp/brain/anti_stun/hardened/Initialize(mapload)
	. = ..()
	desc += " Имплант укреплён и неуязвим к ЭМИ."

/obj/item/organ/internal/cyberimp/brain/anti_stun/on_life()
	..()
	if(crit_fail || paused)
		return
	if(owner.getStaminaLoss() > 60)
		owner.adjustStaminaLoss(-9)

/obj/item/organ/internal/cyberimp/brain/anti_stun/emp_act(severity)
	if(emp_shielded(severity))
		return
	..()
	if(crit_fail || emp_proof)
		return
	crit_fail = TRUE
	addtimer(CALLBACK(src, PROC_REF(reboot)), 90 / severity)

/obj/item/organ/internal/cyberimp/brain/anti_stun/proc/reboot()
	crit_fail = FALSE

/obj/item/organ/internal/cyberimp/brain/anti_sleep
	name = "Neural Jumpstarter implant"
	desc = "Имплант сам пытается привести вас в сознание, если вы его теряете. Имеет короткую перезарядку, несовместим с \"Перезапуском ЦНС\"."
	implant_color = "#0356fc"
	slot = INTERNAL_ORGAN_BRAIN_ANTISTUN //one or the other not both.
	cyber_cost = 20
	can_pause = TRUE
	origin_tech = "materials=5;programming=4;biotech=5"
	var/cooldown = FALSE

/obj/item/organ/internal/cyberimp/brain/anti_sleep/get_ru_names()
	return alist(
		NOMINATIVE = "имплант \"Нейростартер\"",
		GENITIVE = "импланта \"Нейростартер\"",
		DATIVE = "импланту \"Нейростартер\"",
		ACCUSATIVE = "имплант \"Нейростартер\"",
		INSTRUMENTAL = "имплантом \"Нейростартер\"",
		PREPOSITIONAL = "импланте \"Нейростартер\"",
	)

/obj/item/organ/internal/cyberimp/brain/anti_sleep/on_life()
	..()
	if(crit_fail || paused)
		return
	if(owner.stat == UNCONSCIOUS && cooldown == FALSE)
		owner.AdjustSleeping(-200 SECONDS)
		owner.AdjustParalysis(-200 SECONDS)
		to_chat(owner, span_notice("По телу прокатывается волна энергии!"))
		cooldown = TRUE
		addtimer(CALLBACK(src, PROC_REF(sleepy_timer_end)), 50)

/obj/item/organ/internal/cyberimp/brain/anti_sleep/proc/sleepy_timer_end()
		cooldown = FALSE
		to_chat(owner, span_notice("В голове тихо пищит: \"Нейростартер\" перезарядился."))

/obj/item/organ/internal/cyberimp/brain/anti_sleep/emp_act(severity)
	if(emp_shielded(severity))
		return
	. = ..()
	if(crit_fail || emp_proof)
		return
	crit_fail = TRUE
	owner.AdjustSleeping(400 SECONDS)
	cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(reboot)), 90 / severity)

/obj/item/organ/internal/cyberimp/brain/anti_sleep/proc/reboot()
	crit_fail = FALSE
	cooldown = FALSE

/obj/item/organ/internal/cyberimp/brain/anti_sleep/hardened
	name = "Hardened Neural Jumpstarter implant"
	desc = "Военная версия стандартного импланта для элитных сил НТ."
	origin_tech = "materials=6;programming=5;biotech=5"
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/brain/anti_sleep/hardened/get_ru_names()
	return alist(
		NOMINATIVE = "имплант \"Нейростартер\" (укреплённый)",
		GENITIVE = "импланта \"Нейростартер\" (укреплённый)",
		DATIVE = "импланту \"Нейростартер\" (укреплённый)",
		ACCUSATIVE = "имплант \"Нейростартер\" (укреплённый)",
		INSTRUMENTAL = "имплантом \"Нейростартер\" (укреплённый)",
		PREPOSITIONAL = "импланте \"Нейростартер\" (укреплённый)",
	)

/obj/item/organ/internal/cyberimp/brain/anti_sleep/hardened/compatible
	desc = "Военная версия стандартного импланта для элитных сил НТ. Эта версия совместима с \"Перезапуском ЦНС\"."
	slot = INTERNAL_ORGAN_BRAIN_ANTISLEEP

/obj/item/organ/internal/cyberimp/brain/clown_voice
	name = "Comical implant"
	desc = span_sans_alt("Ой-ой.")
	implant_color = "#DEDE00"
	slot = INTERNAL_ORGAN_BRAIN_CLOWNVOICE
	cyber_cost = 2
	origin_tech = "materials=2;biotech=2"

/obj/item/organ/internal/cyberimp/brain/clown_voice/get_ru_names()
	return alist(
		NOMINATIVE = "комический имплант",
		GENITIVE = "комического импланта",
		DATIVE = "комическому импланту",
		ACCUSATIVE = "комический имплант",
		INSTRUMENTAL = "комическим имплантом",
		PREPOSITIONAL = "комическом импланте",
	)

//[[[[MOUTH]]]]
/obj/item/organ/internal/cyberimp/mouth
	cyber_cost = 5
	parent_organ_zone = BODY_ZONE_PRECISE_MOUTH

/obj/item/organ/internal/cyberimp/mouth/breathing_tube
	name = "breathing tube implant"
	desc = "Простой имплант с разъёмом для баллона на спине: можно дышать из баллона без маски, а удушение вам не грозит."
	icon_state = "implant_mask"
	slot = INTERNAL_ORGAN_BREATHING_TUBE
	w_class = WEIGHT_CLASS_TINY
	origin_tech = "materials=2;biotech=3"

/obj/item/organ/internal/cyberimp/mouth/breathing_tube/get_ru_names()
	return alist(
		NOMINATIVE = "имплант дыхательной трубки",
		GENITIVE = "импланта дыхательной трубки",
		DATIVE = "импланту дыхательной трубки",
		ACCUSATIVE = "имплант дыхательной трубки",
		INSTRUMENTAL = "имплантом дыхательной трубки",
		PREPOSITIONAL = "импланте дыхательной трубки",
	)

/obj/item/organ/internal/cyberimp/mouth/breathing_tube/emp_act(severity)
	if(emp_proof)
		return
	if(emp_shielded(severity))
		return
	if(prob(60/severity) && owner)
		to_chat(owner, span_warning("Дыхательная трубка внезапно перекрывается!"))
		owner.AdjustLoseBreath(4 SECONDS)

//[[[[CHEST]]]]
/obj/item/organ/internal/cyberimp/chest
	name = "cybernetic torso implant"
	cyber_cost = 12
	desc = "Импланты для органов торса."
	icon_state = "chest_implant"
	implant_overlay = "chest_implant_overlay"
	abstract_type = /obj/item/organ/internal/cyberimp/chest

/obj/item/organ/internal/cyberimp/chest/get_ru_names()
	return alist(
		NOMINATIVE = "имплант торса",
		GENITIVE = "импланта торса",
		DATIVE = "импланту торса",
		ACCUSATIVE = "имплант торса",
		INSTRUMENTAL = "имплантом торса",
		PREPOSITIONAL = "импланте торса",
	)

/obj/item/organ/internal/cyberimp/chest/nutriment
	name = "Nutriment pump implant"
	desc = "Имплант синтезирует немного питательных веществ и впрыскивает их прямо в кровь, когда вы истощены."
	implant_color = "#00AA00"
	var/hunger_modificator = 0.7
	var/poison_amount = 5
	slot = INTERNAL_ORGAN_STOMACH
	cyber_cost = 6
	origin_tech = "materials=2;powerstorage=2;biotech=2"

/obj/item/organ/internal/cyberimp/chest/nutriment/get_ru_names()
	return alist(
		NOMINATIVE = "имплант питательного насоса",
		GENITIVE = "импланта питательного насоса",
		DATIVE = "импланту питательного насоса",
		ACCUSATIVE = "имплант питательного насоса",
		INSTRUMENTAL = "имплантом питательного насоса",
		PREPOSITIONAL = "импланте питательного насоса",
	)

/obj/item/organ/internal/cyberimp/chest/nutriment/insert(mob/living/carbon/human/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(. && ishuman(target))
		target.physiology.hunger_mod *= hunger_modificator

/obj/item/organ/internal/cyberimp/chest/nutriment/remove(mob/living/carbon/human/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(. && ishuman(target))
		target.physiology.hunger_mod /= hunger_modificator

/obj/item/organ/internal/cyberimp/chest/nutriment/emp_act(severity)
	if(!owner || emp_proof)
		return
	if(emp_shielded(severity))
		return
	owner.reagents.add_reagent("????",poison_amount / severity) //food poisoning
	to_chat(owner, span_warning("Внутренности будто горят."))

/obj/item/organ/internal/cyberimp/chest/nutriment/plus
	name = "Nutriment pump implant PLUS"
	cyber_cost = 8
	desc = "Имплант синтезирует немного питательных веществ и впрыскивает их прямо в кровь, когда вы голодны."
	implant_color = "#006607"
	hunger_modificator = 0.5
	poison_amount = 10
	origin_tech = "materials=4;powerstorage=3;biotech=3"

/obj/item/organ/internal/cyberimp/chest/nutriment/plus/get_ru_names()
	return alist(
		NOMINATIVE = "имплант питательного насоса ПЛЮС",
		GENITIVE = "импланта питательного насоса ПЛЮС",
		DATIVE = "импланту питательного насоса ПЛЮС",
		ACCUSATIVE = "имплант питательного насоса ПЛЮС",
		INSTRUMENTAL = "имплантом питательного насоса ПЛЮС",
		PREPOSITIONAL = "импланте питательного насоса ПЛЮС",
	)

/obj/item/organ/internal/cyberimp/chest/nutriment/plus/insert(mob/living/carbon/human/target, special = ORGAN_MANIPULATION_DEFAULT)
	if(HAS_TRAIT(target, TRAIT_ADVANCED_CYBERIMPLANTS))
		hunger_modificator = 0.2
		ADD_TRAIT(target, TRAIT_CYBERIMP_IMPROVED, UNIQUE_TRAIT_SOURCE(src))

	. = ..()

/obj/item/organ/internal/cyberimp/chest/nutriment/plus/remove(mob/living/carbon/human/target, special = ORGAN_MANIPULATION_DEFAULT)
	if(HAS_TRAIT_FROM(target, TRAIT_CYBERIMP_IMPROVED, UNIQUE_TRAIT_SOURCE(src)))
		hunger_modificator = initial(hunger_modificator)
		REMOVE_TRAIT(target, TRAIT_CYBERIMP_IMPROVED, UNIQUE_TRAIT_SOURCE(src))

	. = ..()

/obj/item/organ/internal/cyberimp/chest/nutriment_old
	name = "Nutriment pump implant"
	desc = "Имплант синтезирует немного питательных веществ и впрыскивает их прямо в кровь, когда вы истощены."
	implant_color = "#00AA00"
	var/hunger_threshold = NUTRITION_LEVEL_STARVING
	var/synthesizing = 0
	var/poison_amount = 5
	slot = INTERNAL_ORGAN_STOMACH
	cyber_cost = 6
	can_pause = TRUE
	origin_tech = "materials=2;powerstorage=2;biotech=2"

/obj/item/organ/internal/cyberimp/chest/nutriment_old/get_ru_names()
	return alist(
		NOMINATIVE = "имплант питательного насоса",
		GENITIVE = "импланта питательного насоса",
		DATIVE = "импланту питательного насоса",
		ACCUSATIVE = "имплант питательного насоса",
		INSTRUMENTAL = "имплантом питательного насоса",
		PREPOSITIONAL = "импланте питательного насоса",
	)

/obj/item/organ/internal/cyberimp/chest/nutriment_old/on_life()
	if(!owner || paused)
		return
	if(synthesizing)
		return
	if(owner.stat == DEAD)
		return
	if(ismachineperson(owner))
		return
	if(isvampire(owner))
		return
	if(owner.nutrition <= hunger_threshold)
		synthesizing = TRUE
		to_chat(owner, span_notice("Голод отступает..."))
		owner.adjust_nutrition(50)
		addtimer(CALLBACK(src, PROC_REF(synth_cool)), 50)

/obj/item/organ/internal/cyberimp/chest/nutriment_old/proc/synth_cool()
	synthesizing = FALSE

/obj/item/organ/internal/cyberimp/chest/nutriment_old/emp_act(severity)
	if(!owner || emp_proof)
		return
	if(emp_shielded(severity))
		return
	owner.reagents.add_reagent("????",poison_amount / severity) //food poisoning
	to_chat(owner, span_warning("Внутренности будто горят."))

/obj/item/organ/internal/cyberimp/chest/nutriment_old/plus
	name = "Nutriment pump implant PLUS"
	cyber_cost = 8
	desc = "Имплант синтезирует немного питательных веществ и впрыскивает их прямо в кровь, когда вы голодны."
	implant_color = "#006607"
	hunger_threshold = NUTRITION_LEVEL_HUNGRY
	poison_amount = 10
	origin_tech = "materials=4;powerstorage=3;biotech=3"

/obj/item/organ/internal/cyberimp/chest/nutriment_old/plus/get_ru_names()
	return alist(
		NOMINATIVE = "имплант питательного насоса ПЛЮС",
		GENITIVE = "импланта питательного насоса ПЛЮС",
		DATIVE = "импланту питательного насоса ПЛЮС",
		ACCUSATIVE = "имплант питательного насоса ПЛЮС",
		INSTRUMENTAL = "имплантом питательного насоса ПЛЮС",
		PREPOSITIONAL = "импланте питательного насоса ПЛЮС",
	)

/obj/item/organ/internal/cyberimp/chest/nutriment_old/plus/get_ripper_settings()
	. = ..()
	. += list(list(
		"id" = "threshold",
		"name" = "Порог срабатывания",
		"kind" = "choice",
		"value" = hunger_threshold == NUTRITION_LEVEL_HUNGRY ? "Голод" : "Истощение",
		"options" = list("Голод", "Истощение"),
	))

/obj/item/organ/internal/cyberimp/chest/nutriment_old/plus/set_ripper_setting(setting, value)
	if(setting != "threshold")
		return ..()
	hunger_threshold = value == "Голод" ? NUTRITION_LEVEL_HUNGRY : NUTRITION_LEVEL_STARVING
	return TRUE

/obj/item/organ/internal/cyberimp/chest/nutriment_old/plus/hardened
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/chest/reviver
	name = "Reviver implant"
	desc = "Имплант пытается вернуть вас в строй, если вы теряете сознание. Для слабых сердцем!"
	implant_color = "#AD0000"
	origin_tech = "materials=5;programming=4;biotech=4"
	slot = INTERNAL_ORGAN_HEART_DRIVE
	cyber_cost = 25
	can_pause = TRUE
	var/revive_cost = 0
	var/reviving = FALSE
	var/cooldown = 0

/obj/item/organ/internal/cyberimp/chest/reviver/get_ru_names()
	return alist(
		NOMINATIVE = "имплант реанимации",
		GENITIVE = "импланта реанимации",
		DATIVE = "импланту реанимации",
		ACCUSATIVE = "имплант реанимации",
		INSTRUMENTAL = "имплантом реанимации",
		PREPOSITIONAL = "импланте реанимации",
	)

/obj/item/organ/internal/cyberimp/chest/reviver/hardened
	name = "Hardened reviver implant"
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/chest/reviver/hardened/get_ru_names()
	return alist(
		NOMINATIVE = "имплант реанимации (укреплённый)",
		GENITIVE = "импланта реанимации (укреплённый)",
		DATIVE = "импланту реанимации (укреплённый)",
		ACCUSATIVE = "имплант реанимации (укреплённый)",
		INSTRUMENTAL = "имплантом реанимации (укреплённый)",
		PREPOSITIONAL = "импланте реанимации (укреплённый)",
	)

/obj/item/organ/internal/cyberimp/chest/reviver/hardened/Initialize(mapload)
	. = ..()
	desc += " Имплант укреплён и неуязвим к ЭМИ."

/obj/item/organ/internal/cyberimp/chest/reviver/on_life()
	if(paused || cooldown > world.time || owner.suiciding) // don't heal while you're in cooldown!
		return
	if(reviving)
		if(owner.health <= HEALTH_THRESHOLD_CRIT)
			addtimer(CALLBACK(src, PROC_REF(heal)), 30)
		else
			reviving = FALSE
			return
	cooldown = revive_cost + world.time
	revive_cost = 0
	reviving = TRUE

/obj/item/organ/internal/cyberimp/chest/reviver/proc/heal()
	if(QDELETED(owner))
		return
	var/heal_brute = 0
	var/heal_burn = 0
	var/heal_tox = 0
	var/heal_oxy = 0
	if(prob(75) && owner.getBruteLoss())
		heal_brute += 1
		revive_cost += 20
	if(prob(75) && owner.getFireLoss())
		heal_burn += 1
		revive_cost += 20
	if(prob(40) && owner.getToxLoss())
		heal_tox += 1
		revive_cost += 50
	if(prob(90) && owner.getOxyLoss())
		heal_oxy += 3
		revive_cost += 5
	owner.heal_damages(heal_brute, heal_burn, heal_tox, heal_oxy)

/obj/item/organ/internal/cyberimp/chest/reviver/emp_act(severity)
	if(!owner || emp_proof)
		return
	if(emp_shielded(severity))
		return
	if(reviving)
		revive_cost += 200
	else
		cooldown += 200
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.stat != DEAD && prob(50 / severity))
			H.set_heartattack(TRUE)
			addtimer(CALLBACK(src, PROC_REF(undo_heart_attack)), 600 / severity)

/obj/item/organ/internal/cyberimp/chest/reviver/proc/undo_heart_attack()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	H.set_heartattack(FALSE)
	if(H.stat == CONSCIOUS)
		to_chat(H, span_notice("Ваше сердце снова бьётся!"))

/obj/item/organ/internal/cyberimp/chest/exoframe
	name = "Exoframe"
	desc = "Несущая опора, выполняющая роль \"скелета\" в конструкции гуманоидных роботов. Стандартная модель, не отличающаяся выдающимися характеристиками."
	implant_color = "#3a3a3aff"
	implant_overlay = null
	origin_tech = "materials=3;engineering=4"
	slot = INTERNAL_ORGAN_CHEST_EXOFRAME
	cyber_cost = 30
	species_restrictions = list(SPECIES_MACHINEPERSON)
	var/id = "EXO_DEFAULT"
	var/given_health = 0
	var/repair_time = 1 SECONDS
	var/list/traits_added
	var/strength_gain = 1
	var/internal_emp_damage = 1
	var/external_emp_damage = 1
	var/low_pressure_hazard = HAZARD_LOW_PRESSURE
	var/low_pressure_warning = WARNING_LOW_PRESSURE
	var/coldmod = 1

/obj/item/organ/internal/cyberimp/chest/exoframe/get_ru_names()
	return alist(
		NOMINATIVE = "стандартный каркас экзоскелета",
		GENITIVE = "стандартного каркаса экзоскелета",
		DATIVE = "стандартному каркасу экзоскелета",
		ACCUSATIVE = "стандартный каркас экзоскелета",
		INSTRUMENTAL = "стандартным каркасом экзоскелета",
		PREPOSITIONAL = "стандартном каркасе экзоскелета",
	)

/obj/item/organ/internal/cyberimp/chest/exoframe/insert(mob/living/carbon/human/target)
	if(!crit_fail)
		target.add_traits(traits_added, UNIQUE_TRAIT_SOURCE(src))
		target.maxHealth += given_health
		target.health += given_health
		target.dna.species.hazard_low_pressure = low_pressure_hazard
		target.dna.species.warning_low_pressure = low_pressure_warning
		target.dna.species.coldmod = coldmod
	target.robotic_limb_repair_time = repair_time
	target.emp_damage_multiplier_external = external_emp_damage
	target.emp_damage_multiplier_internal = internal_emp_damage
	SEND_SIGNAL(target, COMSIG_STRENGTH_LEVEL_UP, strength_gain)
	return ..()

/obj/item/organ/internal/cyberimp/chest/exoframe/remove(mob/living/carbon/human/target)
	if(!crit_fail)
		target.remove_traits(traits_added, UNIQUE_TRAIT_SOURCE(src))
		target.health -= given_health
		target.maxHealth -= given_health
		target.dna.species.hazard_low_pressure = initial(target.dna.species.hazard_low_pressure)
		target.dna.species.warning_low_pressure = initial(target.dna.species.warning_low_pressure)
		target.dna.species.coldmod = initial(target.dna.species.coldmod)
	target.robotic_limb_repair_time = initial(target.robotic_limb_repair_time)
	target.emp_damage_multiplier_external = initial(target.emp_damage_multiplier_external)
	target.emp_damage_multiplier_internal = initial(target.emp_damage_multiplier_internal)
	SEND_SIGNAL(target, COMSIG_STRENGTH_LEVEL_UP, 1)
	return ..()

/obj/item/organ/internal/cyberimp/chest/exoframe/emp_act(severity)
	if(emp_proof || crit_fail)
		return
	if(emp_shielded(severity))
		return

	if(!ishuman(owner))
		return

	if(!prob(30))
		return

	to_chat(owner, span_warning("Приводы вашего экзоскелета перестают двигаться!"))
	crit_fail = TRUE
	var/mob/living/carbon/human/human = owner
	human.health -= given_health
	human.maxHealth -= given_health
	human.dna.species.hazard_low_pressure = initial(human.dna.species.hazard_low_pressure)
	human.dna.species.warning_low_pressure = initial(human.dna.species.warning_low_pressure)
	human.dna.species.coldmod = initial(human.dna.species.coldmod)
	human.remove_traits(traits_added, UNIQUE_TRAIT_SOURCE(src))
	damage = 1

/obj/item/organ/internal/cyberimp/chest/exoframe/surgeryize()
	if(crit_fail && owner)
		to_chat(owner, span_notice("Приводы вашего экзоскелета вновь активны."))
	crit_fail = FALSE

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human = owner
	human.add_traits(traits_added, UNIQUE_TRAIT_SOURCE(src))
	human.maxHealth += given_health
	human.health += given_health
	human.dna.species.hazard_low_pressure = low_pressure_hazard
	human.dna.species.warning_low_pressure = low_pressure_warning
	human.dna.species.coldmod = coldmod

/obj/item/organ/internal/cyberimp/chest/exoframe/reinforced
	name = "Reinforced exoframe"
	desc = "Несущая опора, выполняющая роль \"скелета\" в конструкции гуманоидных роботов. Укреплённая модель, способная выдержать больше повреждений."
	id = "EXO_REINFORCED"
	icon_state = "exoframe_reinforced"
	given_health = 20
	repair_time = 2 SECONDS
	traits_added = list(TRAIT_IGNOREDAMAGESLOWDOWN)
	strength_gain = 3

/obj/item/organ/internal/cyberimp/chest/exoframe/reinforced/get_ru_names()
	return alist(
			NOMINATIVE = "укрепленный каркас экзоскелета",
			GENITIVE = "укрепленного каркаса экзоскелета",
			DATIVE = "укрепленному каркасу экзоскелета",
			ACCUSATIVE = "укрепленный каркас экзоскелета",
			INSTRUMENTAL = "укрепленным каркасом экзоскелета",
			PREPOSITIONAL = "укрепленном каркасе экзоскелета",
		)

/obj/item/organ/internal/cyberimp/chest/exoframe/industrial
	name = "Industrial exoframe"
	desc = "Несущая опора, выполняющая роль \"скелета\" в конструкции гуманоидных роботов. Промышленная модель, созданная специально для работ в открытом космосе."
	id = "EXO_INDUSTRIAL"
	icon_state = "exoframe_industrial"
	traits_added = list(TRAIT_SHOCKIMMUNE)
	strength_gain = 4
	low_pressure_hazard = 1
	low_pressure_warning = -300
	coldmod = -1
	external_emp_damage = 1.5

/obj/item/organ/internal/cyberimp/chest/exoframe/industrial/get_ru_names()
	return alist(
		NOMINATIVE = "промышленный каркас экзоскелета",
		GENITIVE = "промышленного каркаса экзоскелета",
		DATIVE = "промышленному каркасу экзоскелета",
		ACCUSATIVE = "промышленный каркас экзоскелета",
		INSTRUMENTAL = "промышленным каркасом экзоскелета",
		PREPOSITIONAL = "промышленном каркасе экзоскелета",
	)

/obj/item/organ/internal/cyberimp/chest/exoframe/combat
	name = "Combat exoframe"
	cyber_cost = 40
	desc = "Несущая опора, выполняющая роль \"скелета\" в конструкции гуманоидных роботов. Облегченная модель из пластитанового сплава с повышенной прочностью конструкции."
	id = "EXO_COMBAT"
	icon_state = "exoframe_combat"
	origin_tech = "materials=4;engineering=4;syndicate=3;combat=4"
	given_health = 40
	repair_time = 4 SECONDS
	traits_added = list(TRAIT_IGNOREDAMAGESLOWDOWN)
	strength_gain = 4
	internal_emp_damage = 0.25
	external_emp_damage = 0.5
	var/active = FALSE
	actions_types = list(/datum/action/item_action/organ_action/toggle)

/obj/item/organ/internal/cyberimp/chest/exoframe/combat/get_ru_names()
	return alist(
		NOMINATIVE = "боевой каркас экзоскелета",
		GENITIVE = "боевого каркаса экзоскелета",
		DATIVE = "боевому каркасу экзоскелета",
		ACCUSATIVE = "боевой каркас экзоскелета",
		INSTRUMENTAL = "боевым каркасом экзоскелета",
		PREPOSITIONAL = "боевом каркасе экзоскелета",
	)

/obj/item/organ/internal/cyberimp/chest/exoframe/combat/insert(mob/living/carbon/human/target)
	. = ..()
	if(.)
		ADD_TRAIT(target, TRAIT_COMBAT_EXOFRAME_EMP_SHIELD, UNIQUE_TRAIT_SOURCE(src))
	return .

/obj/item/organ/internal/cyberimp/chest/exoframe/combat/remove(mob/living/carbon/human/target)
	if(active)
		ui_action_click()
	REMOVE_TRAIT(target, TRAIT_COMBAT_EXOFRAME_EMP_SHIELD, UNIQUE_TRAIT_SOURCE(src))
	return ..()

/obj/item/organ/internal/cyberimp/chest/exoframe/combat/emp_act(severity)
	if(emp_shielded(severity))
		return
	if(active)
		ui_action_click()
	. = ..()
	if(owner && crit_fail)
		REMOVE_TRAIT(owner, TRAIT_COMBAT_EXOFRAME_EMP_SHIELD, UNIQUE_TRAIT_SOURCE(src))
	return .

/obj/item/organ/internal/cyberimp/chest/exoframe/combat/surgeryize()
	. = ..()
	if(owner)
		ADD_TRAIT(owner, TRAIT_COMBAT_EXOFRAME_EMP_SHIELD, UNIQUE_TRAIT_SOURCE(src))
	return .

/obj/item/organ/internal/cyberimp/chest/exoframe/combat/ui_action_click(mob/user, datum/action/action, leftclick)
	if(crit_fail)
		owner.balloon_alert(owner, "каркас не отвечает!")
		return

	if(active)
		to_chat(owner, span_notice("Ваши движения замедляются!"))
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/increaserun)
		owner.dna.species.hunger_drain_mod /= 4
		active = FALSE
		return

	to_chat(owner, span_notice("Ваши движения ускоряются!"))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/increaserun)
	owner.dna.species.hunger_drain_mod *= 4
	active = TRUE

//BOX O' IMPLANTS

/obj/item/storage/box/cyber_implants
	name = "boxed cybernetic implant"
	desc = "Гладкая прочная коробка."
	icon_state = "box_implants"
	item_state = "spec"

/obj/item/storage/box/cyber_implants/populate_contents()
	new /obj/item/autoimplanter(src)

/obj/item/storage/box/cyber_implants/thermals/populate_contents()
	..()
	new /obj/item/organ/internal/cyberimp/eyes/thermals(src)

/obj/item/storage/box/cyber_implants/xray/populate_contents()
	..()
	new /obj/item/organ/internal/cyberimp/eyes/xray(src)

/obj/item/storage/box/cyber_implants/reviver_hardened/populate_contents()
	..()
	new /obj/item/organ/internal/cyberimp/chest/reviver/hardened(src)

/obj/item/storage/box/cyber_implants/anti_stun_hardened/populate_contents()
	..()
	new /obj/item/organ/internal/cyberimp/brain/anti_stun/hardened(src)

/obj/item/storage/box/cyber_implants/anti_sleep_hardened/populate_contents()
	..()
	new /obj/item/organ/internal/cyberimp/brain/anti_sleep/hardened(src)

/obj/item/storage/box/cyber_implants/nuke_map/populate_contents()
	..()
	new /obj/item/organ/internal/cyberimp/eyes/map/nuke(src)

/obj/item/storage/box/cyber_implants/bundle
	name = "boxed cybernetic implants"
	var/list/boxed = list(/obj/item/organ/internal/cyberimp/eyes/xray,/obj/item/organ/internal/cyberimp/eyes/thermals,
						/obj/item/organ/internal/cyberimp/brain/anti_stun/hardened, /obj/item/organ/internal/cyberimp/chest/reviver/hardened)
	var/amount = 5

/obj/item/storage/box/cyber_implants/bundle/populate_contents()
	..()
	var/implant
	while(amount > 0)
		implant = pick(boxed)
		new implant(src)
		amount--
