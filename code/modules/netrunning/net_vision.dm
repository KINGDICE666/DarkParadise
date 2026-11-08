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
		UnregisterSignal(masked, COMSIG_QDELETING)
	masks.Cut()

/datum/net_vision/proc/add_mask(mob/target)
	if(isnetavatar(target) || isbot(target) || masks[target])
		return
	var/image/mask = image(loc = target)
	mask.override = TRUE
	masks[target] = mask
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(on_masked_deleted))
	for(var/client/viewer as anything in viewers)
		viewer.images += mask

/datum/net_vision/proc/on_mob_created(datum/source, mob/created)
	SIGNAL_HANDLER
	add_mask(created)

/datum/net_vision/proc/on_masked_deleted(mob/source)
	SIGNAL_HANDLER
	var/image/mask = masks[source]
	masks -= source
	for(var/client/viewer as anything in viewers)
		viewer.images -= mask
