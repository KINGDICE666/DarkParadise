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
	SET_PLANE_EXPLICIT(mask, ABOVE_GAME_PLANE, target)
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

/mob/living/basic/net_avatar/proc/apply_net_sight()
	var/static/list/plane_looks = list(
		list(FLOOR_PLANE, MATRIX_NET_FLOOR, FALSE),
		list(WALL_PLANE, MATRIX_NET_WALL, TRUE),
		list(BELOW_GAME_PLANE, MATRIX_NET_OBJECT, TRUE),
		list(GAME_PLANE, MATRIX_NET_OBJECT, TRUE),
	)
	for(var/list/look as anything in plane_looks)
		for(var/atom/movable/screen/plane_master/master as anything in hud_used?.get_true_plane_masters(look[1]))
			master.add_filter(NET_VISION_FILTER, 1, color_matrix_filter(look[2]))
			if(look[3])
				master.add_filter(NET_VISION_EDGE_FILTER, 2, outline_filter(1, NET_EDGE_COLOR))

/mob/living/basic/net_avatar/proc/refresh_marks()
	if(!client)
		return
	var/list/seen = list()
	for(var/obj/thing in view(NET_MARK_RANGE, src))
		var/is_door = is_net_door(thing)
		if(!is_door && !is_net_node(thing))
			continue
		seen[thing] = TRUE
		if(node_marks[thing])
			continue
		var/image/mark = image('icons/effects/netrunning.dmi', thing, "node_mark")
		mark.color = is_door ? NET_DOOR_MARK_COLOR : NET_NODE_MARK_COLOR
		mark.appearance_flags = RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM|KEEP_APART
		mark.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		SET_PLANE_EXPLICIT(mark, ABOVE_GAME_PLANE, thing)
		node_marks[thing] = mark
		client.images += mark
		RegisterSignal(thing, COMSIG_QDELETING, PROC_REF(drop_mark))
	for(var/obj/marked as anything in node_marks)
		if(!seen[marked])
			drop_mark(marked)

/mob/living/basic/net_avatar/proc/drop_mark(obj/marked)
	SIGNAL_HANDLER
	client?.images -= node_marks[marked]
	node_marks -= marked
	UnregisterSignal(marked, COMSIG_QDELETING)

/mob/living/basic/net_avatar/proc/clear_marks()
	for(var/obj/marked as anything in node_marks)
		canon_client?.images -= node_marks[marked]
		UnregisterSignal(marked, COMSIG_QDELETING)
	node_marks.Cut()
