/datum/reagent/eldritch
	name = "Eldritch essence"
	id = "eldritch"
	description = "A strange liquid that defies physics."
	taste_description = "Ag'hsj'saje'sh"
	color = "#1f8016"
	metabolization_rate = 2.5 * REAGENTS_METABOLISM
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/eldritch/on_mob_life(mob/living/carbon/drinker)
	. = ..()
	if(IS_HERETIC_OR_MONSTER(drinker))
		drinker.AdjustAllImmobility(-40 * REM)
		drinker.adjustStaminaLoss(-10 * REM, updating_health = FALSE)
		drinker.adjustToxLoss(-2 * REM, updating_health = FALSE, forced = TRUE)
		drinker.adjustOxyLoss(-2 * REM, updating_health = FALSE)
		drinker.adjustBruteLoss(-2 * REM, updating_health = FALSE)
		drinker.adjustFireLoss(-2 * REM)
		if(drinker.blood_volume < BLOOD_VOLUME_NORMAL)
			drinker.blood_volume += 3 * REM
		return

	drinker.adjustOrganLoss(INTERNAL_ORGAN_BRAIN, 3 * REM, 150)
	drinker.adjustToxLoss(2 * REM, updating_health = FALSE)
	drinker.adjustFireLoss(2 * REM, updating_health = FALSE)
	drinker.adjustOxyLoss(2 * REM, updating_health = FALSE)
	drinker.adjustBruteLoss(2 * REM)

/datum/reagent/eldritch/reaction_turf(turf/exposed_turf, reac_volume, color)
	. = ..()
	if(!(reac_volume >= 1.5 || isplatingturf(exposed_turf)) || HAS_TRAIT(exposed_turf, TRAIT_RUSTY))
		return

	exposed_turf.rust_turf()

/datum/reagent/inverse/helgrasp
	name = "Helgrasp"
	description = "A forbidden drink that summons grasping hands."
	metabolization_rate = 1 * REM

/datum/reagent/inverse/helgrasp/on_mob_add(mob/living/affected_mob, amount)
	. = ..()
	to_chat(affected_mob, span_hierophant("You hear laughter as terrible hands reach for you."))
	playsound(affected_mob.loc, 'sound/effects/ahaha.ogg', 80, TRUE, -1)

/datum/reagent/inverse/helgrasp/on_mob_life(mob/living/carbon/affected_mob)
	. = ..()
	fire_curse_hand(affected_mob)

/datum/reagent/inverse/helgrasp/heretic
	name = "Mansus Grasp"
	description = "Someone's hand is at your throat..."
