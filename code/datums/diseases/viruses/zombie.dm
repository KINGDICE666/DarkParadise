/datum/disease/virus/zombie
	name = "Некротическая чума"
	desc = "Вирус поражает гуманоидов и сводит их с ума неутолимым голодом по плоти, одновременно наделяя способностью к регенерации."
	agent = "Синдром продвинутого воскрешения"
	cure_text = "Античумные вирусные растворы"
	max_stages = 7
	spread_flags = BLOOD
	severity = DISEASE_SEVERITY_BIOHAZARD
	stage_prob = 100
	cure_prob = 80
	curable = FALSE
	can_immunity = FALSE
	virus_heal_resistant = TRUE
	can_progress_in_dead = TRUE
	can_contract_dead = TRUE
	carrier_mobtypes = list()
	no_vaccine = TRUE
	var/cure_stage = 0
	COOLDOWN_DECLARE(stage_timer)
	var/plague_disease
	var/instant_zombie

/datum/disease/virus/zombie/New(chosen_plague, plague_zomb)
	..()
	if(plague_zomb)
		plague_disease = chosen_plague
		instant_zombie = TRUE

/datum/disease/virus/zombie/Copy()
	var/datum/disease/virus/zombie/copy = new type(plague_disease, instant_zombie)
	copy.spread_flags = spread_flags
	copy.visibility_flags = visibility_flags
	return copy

/datum/disease/virus/zombie/CanContract(mob/living/M, act_type, need_protection_check, zone)
	if(act_type & (CONTACT|AIRBORNE))
		return FALSE
	return ..()

/datum/disease/virus/zombie/stage_act()
	if(stage == 8 && !rot_all_limbs())
		return FALSE

	if(!..())
		return FALSE
	if(stage <= 0)
		cure()
		return FALSE
	if(HAS_TRAIT(affected_mob, TRAIT_I_WANT_BRAINS) || affected_mob.mind?.has_antag_datum(/datum/antagonist/zombie))
		SSticker.mode?.zombie_infected -= affected_mob
		if(affected_mob.reagents.has_reagent("zombiecure4"))
			return FALSE
		handle_rot()
		stage = 7
		return FALSE
	SSticker.mode?.zombie_infected |= affected_mob
	switch(stage)
		if(1)
			if(prob(4))
				to_chat(affected_mob, span_warning(pick("У вас чешется кожа головы.", "Ваша кожа шелушится.")))
			else if(prob(5))
				to_chat(affected_mob, span_warning("У вас чешется [pick("спина", "рука", "нога", "локоть", "голова")]."))
		if(2)
			if(prob(2))
				to_chat(affected_mob, span_danger("По задней стенке горла стекает слизь."))
			else if(prob(5))
				to_chat(affected_mob, span_warning(pick("Вы чувствуете голод.", "Вам очень хочется что-нибудь съесть.")))
		if(3)
			if(prob(2))
				affected_mob.emote("sneeze")
			else if(prob(2))
				affected_mob.emote("cough")
			else if(prob(5))
				to_chat(affected_mob, span_warning("<i>[pick("Так голодно...", "Вы бы убили кого-нибудь за кусочек еды...", "Вас скручивают голодные спазмы...")]</i>"))
			if(prob(5))
				affected_mob.adjustToxLoss(1)
		if(4)
			if(prob(2))
				affected_mob.emote("stare")
			else if(prob(2))
				affected_mob.emote("drool")
			else if(prob(5))
				to_chat(affected_mob, span_danger("Вас прошибает холодный пот."))
			if(prob(25))
				affected_mob.adjustToxLoss(1)
		if(5, 6)
			var/turf/current_turf = get_turf(affected_mob)
			if(current_turf.get_lumcount() >= 0.5)
				if(prob(5))
					to_chat(affected_mob, span_danger("Свет кажется слишком ярким. Он жжётся."))
				if(prob(25))
					affected_mob.adjustFireLoss(2)
			if(prob(2))
				affected_mob.emote("drool")
			if(stage == 6 && !affected_mob.reagents.has_reagent("zombiecure3"))
				if(prob(10))
					to_chat(affected_mob, span_zombie_danger("Вы чувствуете, как гниёт ваша плоть."))
				if(prob(10) || affected_mob.stat != DEAD)
					handle_rot()
		if(7)
			if(!handle_rot())
				stage = 6
				return FALSE
	return TRUE

/datum/disease/virus/zombie/try_increase_stage()
	if(!stage_timer)
		COOLDOWN_START(src, stage_timer, 1 MINUTES)
	if(affected_mob.stat != DEAD || !prob(30))
		if(!COOLDOWN_FINISHED(src, stage_timer))
			return
	COOLDOWN_START(src, stage_timer, 1 MINUTES)
	return ..()

/datum/disease/virus/zombie/try_reduce_stage()
	if(prob(cure_prob))
		stage = max(stage - 1, 0)

/datum/disease/virus/zombie/proc/rot_all_limbs()
	var/mob/living/carbon/human/human = affected_mob
	if(!istype(human))
		return FALSE
	for(var/obj/item/organ/external/limb as anything in human.bodyparts)
		if(!(limb.status & ORGAN_DEAD) && !limb.is_robotic())
			limb.necrotize(TRUE, TRUE)
		if(!HAS_TRAIT(limb, TRAIT_I_WANT_BRAINS_ORGAN))
			ADD_TRAIT(limb, TRAIT_I_WANT_BRAINS_ORGAN, ZOMBIE_TRAIT)
	return TRUE

/datum/disease/virus/zombie/proc/turn_instantly()
	if(!rot_all_limbs())
		return FALSE
	stage = max_stages
	SSticker.mode?.zombie_infected -= affected_mob
	return handle_rot()

/datum/disease/virus/zombie/proc/handle_rot()
	var/mob/living/carbon/human/human = affected_mob
	if(!istype(human))
		return FALSE
	for(var/obj/item/organ/external/limb as anything in human.bodyparts)
		if(!(limb.status & ORGAN_DEAD) && !limb.vital && !limb.is_robotic())
			limb.necrotize()
		if(!HAS_TRAIT(limb, TRAIT_I_WANT_BRAINS_ORGAN))
			ADD_TRAIT(limb, TRAIT_I_WANT_BRAINS_ORGAN, ZOMBIE_TRAIT)
			return FALSE

	for(var/obj/item/organ/external/limb as anything in human.bodyparts)
		if(!(limb.status & ORGAN_DEAD) && !limb.is_robotic())
			limb.necrotize(FALSE, TRUE)
		if(!HAS_TRAIT(limb, TRAIT_I_WANT_BRAINS_ORGAN))
			ADD_TRAIT(limb, TRAIT_I_WANT_BRAINS_ORGAN, ZOMBIE_TRAIT)
			return FALSE

	if(!HAS_TRAIT(affected_mob, TRAIT_I_WANT_BRAINS))
		affected_mob.AddComponent(/datum/component/zombie_regen)
		set_brains_trait(TRUE)
		affected_mob.med_hud_set_health()
		affected_mob.med_hud_set_status()
		affected_mob.update_hands_HUD()
		human.update_body()
		var/obj/item/organ/internal/zombietumor/tumor = new
		tumor.insert(affected_mob)
	if(affected_mob.mind && !affected_mob.mind.has_antag_datum(/datum/antagonist/zombie))
		if(HAS_TRAIT(affected_mob, TRAIT_PLAGUE_ZOMBIE))
			var/datum/antagonist/zombie/plague = new /datum/antagonist/zombie(plague_disease)
			plague.silent = TRUE
			plague.wiki_page_name = null
			affected_mob.mind.add_antag_datum(plague)
		else
			affected_mob.mind.add_antag_datum(/datum/antagonist/zombie)

	return TRUE

/datum/disease/virus/zombie/proc/set_brains_trait(enabled)
	var/mob/living/carbon/human/human = affected_mob
	var/list/previously_usable = list()
	if(istype(human))
		for(var/obj/item/organ/external/limb as anything in human.bodyparts)
			if(istype(limb, /obj/item/organ/external/hand) || istype(limb, /obj/item/organ/external/foot))
				previously_usable[limb] = limb.is_usable()

	if(enabled)
		ADD_TRAIT(affected_mob, TRAIT_I_WANT_BRAINS, ZOMBIE_TRAIT)
	else
		REMOVE_TRAIT(affected_mob, TRAIT_I_WANT_BRAINS, ZOMBIE_TRAIT)

	for(var/obj/item/organ/external/limb as anything in previously_usable)
		if(previously_usable[limb] == limb.is_usable())
			continue
		var/difference = limb.is_usable() ? 1 : -1
		if(istype(limb, /obj/item/organ/external/hand))
			human.set_usable_hands(human.usable_hands + difference, hand_index = limb.limb_zone)
		else
			human.set_usable_legs(human.usable_legs + difference)

/datum/disease/virus/zombie/proc/update_cure_stage()
	for(var/datum/reagent/zombie_cure/cure_reagent in affected_mob.reagents?.reagent_list)
		cure_stage = max(cure_stage, cure_reagent.cure_level)
	if(cure_stage)
		var/static/list/stages = list("Стабилизированная", "Ослабленная", "Угасающая", "Подавленная")
		name = "[stages[cure_stage]] некротическая чума"

/datum/disease/virus/zombie/has_cure()
	update_cure_stage()
	var/required_reagent = (stage + 1) / 2
	return cure_stage >= required_reagent

/datum/disease/virus/zombie/cure(id = type, need_immunity = TRUE)
	if(!affected_mob)
		return ..()
	var/obj/item/twohanded/required/zombie_claw/claws = affected_mob.get_active_hand()
	if(istype(claws))
		claws.attack_self(affected_mob)
	affected_mob.mind?.remove_antag_datum(/datum/antagonist/zombie)
	set_brains_trait(FALSE)
	SSticker.mode?.zombie_infected -= affected_mob
	var/mob/living/carbon/human/human = affected_mob
	if(istype(human))
		for(var/obj/item/organ/external/limb as anything in human.bodyparts)
			REMOVE_TRAIT(limb, TRAIT_I_WANT_BRAINS_ORGAN, ZOMBIE_TRAIT)
			if(!limb.is_robotic())
				limb.unnecrotize()
		for(var/obj/item/organ/internal/zombietumor/tumor in human.internal_organs)
			tumor.remove(human, ORGAN_MANIPULATION_NOEFFECT)
			qdel(tumor)
		human.update_body()
	qdel(affected_mob.GetComponent(/datum/component/zombie_regen))
	affected_mob.med_hud_set_health()
	affected_mob.med_hud_set_status()
	return ..()

/datum/disease/virus/zombie/wizard
	spread_flags = NON_CONTAGIOUS
	ignore_immunity = TRUE
	cure_text = "Антимагия"

/datum/disease/virus/zombie/wizard/cure(id = type, need_immunity = TRUE)
	return
