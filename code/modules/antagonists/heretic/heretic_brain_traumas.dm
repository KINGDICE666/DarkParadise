/datum/brain_trauma
	var/resilience
	var/desc
	var/mob/living/owner

/datum/brain_trauma/proc/on_gain()
	return

/datum/brain_trauma/proc/on_life(seconds_per_tick, times_fired)
	return

/datum/brain_trauma/proc/on_lose()
	return

/datum/brain_trauma/severe
	abstract_type = /datum/brain_trauma/severe

/datum/brain_trauma/severe/flesh_desire
	name = "Flesh desire"
	desc = "The patient is fixated on raw meat and organs."
	scan_desc = "moderate food behavior disorder"
	gain_text = "You crave flesh."
	lose_text = "Your tastes return to normal."
	random_gain = FALSE
	var/hunger_rate = 15

/datum/brain_trauma/severe/flesh_desire/on_gain()
	ADD_TRAIT(owner, TRAIT_FLESH_DESIRE, UID())
	return ..()

/datum/brain_trauma/severe/flesh_desire/on_life(seconds_per_tick, times_fired)
	owner?.adjust_nutrition(-hunger_rate * HUNGER_FACTOR)

/datum/brain_trauma/severe/flesh_desire/on_lose()
	REMOVE_TRAIT(owner, TRAIT_FLESH_DESIRE, UID())
	return ..()
