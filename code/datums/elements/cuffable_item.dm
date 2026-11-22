/datum/element/cuffable_item

/datum/element/cuffable_item/Attach(datum/target)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE

	var/obj/item/item_target = target
	item_target.flags |= HAS_CONTEXTUAL_SCREENTIPS
	RegisterSignal(item_target, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(on_examine_more))
	RegisterSignal(item_target, COMSIG_ATOM_ITEM_INTERACTION_SECONDARY, PROC_REF(item_interaction))
	RegisterSignal(item_target, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, PROC_REF(on_requesting_context_from_item))

/datum/element/cuffable_item/Detach(datum/source, ...)
	UnregisterSignal(source, list(
		COMSIG_ATOM_EXAMINE_MORE,
		COMSIG_ATOM_ITEM_INTERACTION_SECONDARY,
		COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM,
	))
	return ..()

/datum/element/cuffable_item/proc/on_examine_more(obj/item/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(isrobot(user) || source.anchored)
		return
	examine_list += span_notice("[DECLENT_RU_CAP(source, ACCUSATIVE)] можно приковать к запястью наручниками...")

/datum/element/cuffable_item/proc/on_requesting_context_from_item(datum/source, list/context, obj/item/held_item, mob/user)
	SIGNAL_HANDLER
	var/obj/item/restraints/handcuffs/cuffs = held_item
	if(!istype(cuffs) || cuffs.used)
		return NONE
	context[SCREENTIP_CONTEXT_RMB] = "Приковать к запястью"
	return CONTEXTUAL_SCREENTIP_SET

/datum/element/cuffable_item/proc/item_interaction(obj/item/source, mob/living/user, obj/item/tool, list/modifiers)
	SIGNAL_HANDLER
	if(!istype(tool, /obj/item/restraints/handcuffs) || isrobot(user) || source.anchored || !source.Adjacent(user))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(apply_cuffs), source, user, tool)
	return ITEM_INTERACT_SUCCESS

/datum/element/cuffable_item/proc/apply_cuffs(obj/item/source, mob/living/user, obj/item/restraints/handcuffs/cuffs)
	if(cuffs.used || DOING_INTERACTION_WITH_TARGET(user, source))
		return

	if(HAS_TRAIT_FROM(source, TRAIT_NODROP, CUFFED_ITEM_TRAIT))
		source.balloon_alert(user, "уже прикован!")
		return

	if(cuffs.handcuffs_clumsiness_check(user))
		return

	source.balloon_alert(user, "приковывание...")
	playsound(source, cuffs.cuffsound, 30, TRUE, -2)
	if(!do_after(user, cuffs.get_handcuff_time(user), source))
		return

	if(user.apply_status_effect(/datum/status_effect/cuffed_item, source, cuffs))
		source.balloon_alert(user, "прикован к запястью")
		return

	source.balloon_alert(user, "не удалось приковать!")
