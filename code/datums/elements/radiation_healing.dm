#define BRUTE_HEAL_AMOUNT 2
#define BURN_HEAL_AMOUNT 2
#define INTERNAL_HEAL_AMOUNT 2
#define RADS_CONSUMED_PER_SECOND 5

/// Поглощённая доза не вызывает болезнь, а расходуется на лечение.
/datum/element/radiation_healing
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY

/datum/element/radiation_healing/Attach(datum/target)
	. = ..()

	if(!ishuman(target))
		return ELEMENT_INCOMPATIBLE

	ADD_TRAIT(target, TRAIT_HALT_RADIATION_EFFECTS, UNIQUE_TRAIT_SOURCE(src))

	RegisterSignal(target, COMSIG_IRRADIATED_PROCESS, PROC_REF(on_irradiation_process))

/datum/element/radiation_healing/Detach(datum/source)
	. = ..()
	REMOVE_TRAIT(source, TRAIT_HALT_RADIATION_EFFECTS, UNIQUE_TRAIT_SOURCE(src))
	UnregisterSignal(source, COMSIG_IRRADIATED_PROCESS)

/datum/element/radiation_healing/proc/on_irradiation_process(mob/living/carbon/human/human, seconds_per_tick, dose)
	SIGNAL_HANDLER

	if(dose <= 0)
		return

	process_radiation_healing(human, seconds_per_tick)
	human.adjust_radiation_dose(-RADS_CONSUMED_PER_SECOND * seconds_per_tick)

/datum/element/radiation_healing/proc/process_radiation_healing(mob/living/carbon/human/human, seconds_per_tick)
	var/heal_brute = 0
	var/heal_burn = 0

	if(human.getBruteLoss() > 0)
		heal_brute = BRUTE_HEAL_AMOUNT * seconds_per_tick

	if(human.getFireLoss() > 0)
		heal_burn = BURN_HEAL_AMOUNT * seconds_per_tick

	if(heal_brute > 0 || heal_burn > 0)
		human.heal_overall_damage(heal_brute, heal_burn)

	var/list/obj/item/organ/internal/int_damaged_organs = human.get_damaged_organs(flags = AFFECT_ORGANIC_INTERNAL_PARTS)
	if(length(int_damaged_organs))
		var/obj/item/organ/internal/organ = pick(int_damaged_organs)
		organ.unnecrotize()
		organ.heal_internal_damage(INTERNAL_HEAL_AMOUNT * seconds_per_tick)

	var/list/obj/item/organ/external/fractured_limbs = human.check_fractures()
	if(length(fractured_limbs))
		var/obj/item/organ/external/limb = pick(fractured_limbs)
		limb.mend_fracture()

#undef BRUTE_HEAL_AMOUNT
#undef BURN_HEAL_AMOUNT
#undef INTERNAL_HEAL_AMOUNT
#undef RADS_CONSUMED_PER_SECOND
