GLOBAL_DATUM_INIT(net_vision, /datum/net_vision, new)

/datum/net_vision
	var/list/client/viewers = list()
	var/list/image/masks = list()

/datum/net_vision/proc/show_to(client/viewer)
	if(!length(viewers))
		start_tracking()
	viewers |= viewer
	for(var/mob/masked as anything in masks)
		viewer.images |= masks[masked]

/datum/net_vision/proc/hide_from(client/viewer)
	viewers -= viewer
	for(var/mob/masked as anything in masks)
		viewer.images -= masks[masked]
	if(!length(viewers))
		stop_tracking()

/datum/net_vision/proc/start_tracking()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))
	for(var/mob/existing as anything in GLOB.mob_list)
		add_mask(existing)

/datum/net_vision/proc/stop_tracking()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED)
	for(var/mob/masked as anything in masks)
		UnregisterSignal(masked, list(COMSIG_QDELETING, COMSIG_CARBON_GAIN_ORGAN, COMSIG_CARBON_LOSE_ORGAN))
	masks.Cut()

/datum/net_vision/proc/add_mask(mob/target)
	if(isnetavatar(target) || isbot(target) || masks[target])
		return
	var/image/mask = image(loc = target)
	mask.override = TRUE
	mask.appearance_flags = RESET_COLOR|NO_CLIENT_COLOR
	masks[target] = mask
	update_echo(target)
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(on_masked_deleted))
	if(iscarbon(target))
		RegisterSignals(target, list(COMSIG_CARBON_GAIN_ORGAN, COMSIG_CARBON_LOSE_ORGAN), PROC_REF(on_organs_changed))
	for(var/client/viewer as anything in viewers)
		viewer.images += mask

/datum/net_vision/proc/update_echo(mob/target)
	var/image/mask = masks[target]
	if(!mask)
		return
	var/has_echo = has_net_cyberware(target)
	mask.icon = has_echo ? 'icons/effects/netrunning.dmi' : null
	mask.icon_state = has_echo ? "echo" : null

/datum/net_vision/proc/on_organs_changed(mob/living/carbon/source, obj/item/organ/organ)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(update_echo), source), 0)

/datum/net_vision/proc/on_mob_created(datum/source, mob/created)
	SIGNAL_HANDLER
	add_mask(created)

/datum/net_vision/proc/on_masked_deleted(mob/source)
	SIGNAL_HANDLER
	var/image/mask = masks[source]
	masks -= source
	for(var/client/viewer as anything in viewers)
		viewer.images -= mask
