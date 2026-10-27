/datum/component/zombie_regen

/datum/component/zombie_regen/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	START_PROCESSING(SSprocessing, src)

/datum/component/zombie_regen/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/datum/component/zombie_regen/process()
	var/mob/living/carbon/human/zomboid = parent
	if(zomboid.suiciding)
		return
	var/turf/current_turf = get_turf(zomboid)
	var/healing_factor = max(1, 6 * (1 - current_turf.get_lumcount()))
	if(HAS_TRAIT(zomboid, TRAIT_PLAGUE_ZOMBIE))
		healing_factor *= 1.6
	if(zomboid.reagents.has_reagent("zombiecure3"))
		healing_factor /= 3
	if(zomboid.stat == DEAD)
		healing_factor *= 2
	zomboid.heal_overall_damage(healing_factor, healing_factor)
	zomboid.adjustBrainLoss(-healing_factor)
	var/robotic_limb_brute = 0
	var/robotic_limb_burn = 0
	for(var/obj/item/organ/external/limb as anything in zomboid.get_damaged_organs(TRUE, TRUE))
		if(limb.is_robotic())
			robotic_limb_brute += limb.brute_dam
			robotic_limb_burn += limb.burn_dam
	if(zomboid.stat == DEAD && (zomboid.getBruteLoss() - robotic_limb_brute) <= 1 && (zomboid.getFireLoss() - robotic_limb_burn) <= 1 && (zomboid.timeofdeath + 15 SECONDS <= world.time))
		var/datum/reagent/the_cure = zomboid.reagents.has_reagent("zombiecure4")
		if(the_cure)
			zomboid.reagents.remove_reagent("zombiecure4", the_cure.metabolization_rate * zomboid.metabolism_efficiency)
			return
		zombie_rejuv()
		to_chat(zomboid, span_zombielarge("Мы... Пробуждаемся..."))
		zomboid.notify_ghost_cloning("Ваше тело зомби снова восстало, вернитесь в него, чтобы продолжить пиршество!", source = zomboid)

	if(zomboid.stat != CONSCIOUS || HAS_TRAIT(zomboid, TRAIT_HANDS_BLOCKED))
		return
	if(zomboid.client || isLivingSSD(zomboid))
		return
	if(HAS_TRAIT(zomboid, TRAIT_PLAGUE_ZOMBIE))
		return
	if((zomboid.last_known_ckey || HAS_TRAIT(zomboid, TRAIT_NPC_ZOMBIE)) && !zomboid.key)
		mindless_hunger()

/datum/component/zombie_regen/proc/zombie_rejuv()
	var/mob/living/carbon/human/zomboid = parent
	zomboid.setToxLoss(0)
	zomboid.setOxyLoss(0)
	zomboid.setCloneLoss(0)
	zomboid.setBrainLoss(0)
	zomboid.setStaminaLoss(0)
	zomboid.SetSleeping(0)
	zomboid.SetParalysis(0, TRUE)
	zomboid.SetStunned(0, TRUE)
	zomboid.SetWeakened(0, TRUE)
	zomboid.SetSlowed(0)
	zomboid.SetImmobilized(0)
	zomboid.SetKnockdown(0)
	zomboid.SetLoseBreath(0)
	zomboid.SetDizzy(0)
	zomboid.SetJitter(0)
	zomboid.SetStuttering(0)
	zomboid.SetConfused(0)
	zomboid.SetDrowsy(0)
	zomboid.cure_radiation()
	zomboid.SetDruggy(0)
	zomboid.SetHallucinate(0)
	zomboid.set_bodytemperature(BODYTEMP_NORMAL)
	zomboid.CureBlind()
	zomboid.CureNearsighted()
	zomboid.CureMute()
	zomboid.CureDeaf()
	zomboid.CureEpilepsy()
	zomboid.CureCoughing()
	zomboid.CureNervous()
	zomboid.SetEyeBlind(0)
	zomboid.SetEyeBlurry(0)
	zomboid.SetDeaf(0)
	zomboid.heal_overall_damage(1000, 1000)
	zomboid.ExtinguishMob()
	zomboid.fire_stacks = 0
	zomboid.on_fire = 0
	zomboid.suiciding = FALSE
	zomboid.set_nutrition(max(zomboid.nutrition, NUTRITION_LEVEL_HUNGRY))
	if(zomboid.buckled)
		zomboid.buckled.unbuckle_mob(zomboid, force = TRUE)

	for(var/organ_slot in list(INTERNAL_ORGAN_HEART, INTERNAL_ORGAN_LUNGS))
		var/organ_type = zomboid.dna.species.has_organ[organ_slot]
		if(!zomboid.get_organ_slot(organ_slot) && organ_type)
			var/obj/item/organ/internal/new_organ = new organ_type()
			new_organ.insert(zomboid)

	zomboid.set_heartattack(FALSE)
	zomboid.restore_blood()
	zomboid.decaylevel = 0
	zomboid.remove_all_embedded_objects()

	zomboid.restore_all_organs()
	if(zomboid.stat == DEAD)
		zomboid.update_revive()
	else if(zomboid.stat == UNCONSCIOUS)
		zomboid.set_stat(CONSCIOUS)

	zomboid.update_fire()
	zomboid.regenerate_icons()
	zomboid.update_eyes()

	for(var/datum/disease/critical/crit in zomboid.diseases)
		crit.cure()

/datum/component/zombie_regen/proc/mindless_hunger()
	var/mob/living/carbon/human/zomboid = parent
	var/list/targets = list()
	for(var/mob/living/carbon/human/target in view(6, zomboid))
		if(target.stat == CONSCIOUS && !HAS_TRAIT(target, TRAIT_I_WANT_BRAINS))
			targets |= target
			if(zomboid.Adjacent(target))
				break

	var/target
	if(length(targets))
		target = pick(targets)

	if(zomboid.Adjacent(target) && safe_active_hand(zomboid))
		if(!zomboid.get_active_hand())
			zomboid.put_in_hands(new /obj/item/twohanded/required/zombie_claw())
		zomboid.a_intent = INTENT_HARM
		zomboid.ClickOn(target)
		return

	if(!target && prob(90))
		return

	var/targetted_direction = pick(GLOB.cardinal)
	if(target)
		targetted_direction = get_dir(zomboid, target)

	var/delay = zomboid.cached_multiplicative_slowdown
	if(ISDIAGONALDIR(targetted_direction))
		delay *= sqrt(2)
	zomboid.set_glide_size(DELAY_TO_GLIDE_SIZE(delay))
	step(zomboid, targetted_direction)

/datum/component/zombie_regen/proc/safe_active_hand(mob/living/carbon/human/zomboid)
	if(zomboid.get_organ(zomboid.hand ? BODY_ZONE_PRECISE_L_HAND : BODY_ZONE_PRECISE_R_HAND))
		return TRUE
	zomboid.swap_hand()
	if(zomboid.get_organ(zomboid.hand ? BODY_ZONE_PRECISE_L_HAND : BODY_ZONE_PRECISE_R_HAND))
		return TRUE
	return FALSE
