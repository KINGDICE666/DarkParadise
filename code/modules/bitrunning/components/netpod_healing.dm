#define NETPOD_HEAL_AMOUNT 4

/datum/component/netpod_healing

/datum/component/netpod_healing/Initialize(obj/machinery/netpod/pod)
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignals(pod, list(COMSIG_QDELETING, COMSIG_BITRUNNER_NETPOD_OPENED), PROC_REF(on_remove))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_remove))

	ADD_TRAIT(parent, TRAIT_STASIS, NETPOD_TRAIT)
	START_PROCESSING(SSdcs, src)

/datum/component/netpod_healing/Destroy(force)
	STOP_PROCESSING(SSdcs, src)
	REMOVE_TRAIT(parent, TRAIT_STASIS, NETPOD_TRAIT)
	return ..()

/datum/component/netpod_healing/process(seconds_per_tick)
	var/mob/living/carbon/pilot = parent
	var/healing = NETPOD_HEAL_AMOUNT * seconds_per_tick

	pilot.adjustBruteLoss(-healing, updating_health = FALSE)
	pilot.adjustFireLoss(-healing, updating_health = FALSE)
	pilot.adjustToxLoss(-healing, updating_health = FALSE)
	pilot.updatehealth()

	if(pilot.blood_volume < BLOOD_VOLUME_NORMAL)
		pilot.blood_volume = min(pilot.blood_volume + healing, BLOOD_VOLUME_NORMAL)

/datum/component/netpod_healing/proc/on_remove(datum/source)
	SIGNAL_HANDLER

	qdel(src)

#undef NETPOD_HEAL_AMOUNT
