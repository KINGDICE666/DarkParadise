#define BIOPRINTED_STRENGTH 0.5
#define BIOPRINTED_MATURATION (3 MINUTES)
#define BIOPRINTED_NUTRITION_PER_SECOND 0.25
#define BIOPRINTED_STARVATION_DAMAGE 0.1

/datum/component/bioprinted_organ
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/maturation_remaining = BIOPRINTED_MATURATION

/datum/component/bioprinted_organ/Initialize()
	if(!is_internal_organ(parent))
		return COMPONENT_INCOMPATIBLE
	var/obj/item/organ/internal/organ = parent
	organ.max_damage *= BIOPRINTED_STRENGTH
	organ.min_bruised_damage *= BIOPRINTED_STRENGTH
	organ.min_broken_damage *= BIOPRINTED_STRENGTH
	organ.tough = FALSE
	organ.sterile = FALSE
	organ.origin_tech = null
	organ.name += " (bioprinted)"
	var/alist/printed_names = alist()
	for(var/case_id in NOMINATIVE to PREPOSITIONAL)
		printed_names[case_id] = "[organ.declent_ru(case_id)] (биопечать)"
	organ.ru_names = printed_names

/datum/component/bioprinted_organ/RegisterWithParent()
	ADD_TRAIT(parent, TRAIT_BIOPRINTED_ORGAN, UNIQUE_TRAIT_SOURCE(src))
	ADD_TRAIT(parent, TRAIT_NO_CLONE_IN_EXPERIMENTATOR, UNIQUE_TRAIT_SOURCE(src))
	RegisterSignal(parent, COMSIG_ORGAN_IMPLANTED, PROC_REF(on_implanted))
	RegisterSignal(parent, COMSIG_ORGAN_REMOVED, PROC_REF(on_removed))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	var/obj/item/organ/internal/organ = parent
	if(!organ.owner && !organ.is_robotic())
		START_PROCESSING(SSobj, organ)

/datum/component/bioprinted_organ/UnregisterFromParent()
	STOP_PROCESSING(SSobj, src)
	REMOVE_TRAIT(parent, TRAIT_BIOPRINTED_ORGAN, UNIQUE_TRAIT_SOURCE(src))
	REMOVE_TRAIT(parent, TRAIT_NO_CLONE_IN_EXPERIMENTATOR, UNIQUE_TRAIT_SOURCE(src))
	UnregisterSignal(parent, list(COMSIG_ORGAN_IMPLANTED, COMSIG_ORGAN_REMOVED, COMSIG_ATOM_EXAMINE))

/datum/component/bioprinted_organ/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/component/bioprinted_organ/proc/on_implanted(obj/item/organ/internal/source, mob/living/carbon/receiver)
	SIGNAL_HANDLER
	maturation_remaining = BIOPRINTED_MATURATION
	if(!source.is_robotic())
		START_PROCESSING(SSobj, src)
		to_chat(receiver, span_notice("Пересаженный биопечатный орган начинает приживаться. В ближайшие три минуты вам потребуется дополнительное питание."))

/datum/component/bioprinted_organ/proc/on_removed(obj/item/organ/internal/source, mob/living/carbon/receiver)
	SIGNAL_HANDLER
	STOP_PROCESSING(SSobj, src)

/datum/component/bioprinted_organ/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/obj/item/organ/internal/organ = parent
	examine_list += span_notice("Биопечатная копия: прочность и пороги повреждений составляют 50% от исходных. Не принимается по заказам карго.")
	if(!organ.is_robotic())
		examine_list += span_notice("После каждой пересадки приживается три минуты, расходуя питание пациента. При голодании приживление останавливается, а орган получает повреждения.")

/datum/component/bioprinted_organ/process(seconds_per_tick)
	var/obj/item/organ/internal/organ = parent
	var/mob/living/carbon/human/receiver = organ.owner
	if(!receiver || organ.is_robotic())
		return PROCESS_KILL
	if(receiver.stat == DEAD || organ.is_dead() || HAS_TRAIT(receiver, TRAIT_STASIS) || receiver.bodytemperature < receiver.dna.species.cold_level_1)
		return
	if(receiver.nutrition < NUTRITION_LEVEL_STARVING)
		organ.internal_receive_damage(BIOPRINTED_STARVATION_DAMAGE * seconds_per_tick, silent = TRUE)
		return
	receiver.adjust_nutrition(-BIOPRINTED_NUTRITION_PER_SECOND * seconds_per_tick)
	maturation_remaining = max(0, maturation_remaining - seconds_per_tick SECONDS)
	if(maturation_remaining)
		return
	to_chat(receiver, span_notice("Биопечатный орган прижился. Повышенная потребность в питании прошла."))
	return PROCESS_KILL

#undef BIOPRINTED_STRENGTH
#undef BIOPRINTED_MATURATION
#undef BIOPRINTED_NUTRITION_PER_SECOND
#undef BIOPRINTED_STARVATION_DAMAGE
