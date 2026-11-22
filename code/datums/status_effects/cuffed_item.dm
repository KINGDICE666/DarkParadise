#define CUFFS_REMOVAL_TIME_MULTIPLIER 1.5
#define CUFFS_ALERT_SCALE 0.8

/datum/status_effect/cuffed_item
	id = "cuffed_item"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = /atom/movable/screen/alert/status_effect/cuffed_item
	var/obj/item/cuffed
	var/obj/item/restraints/handcuffs/cuffs

/datum/status_effect/cuffed_item/on_creation(mob/living/new_owner, obj/item/cuffed, obj/item/restraints/handcuffs/cuffs)
	src.cuffed = cuffed
	src.cuffs = cuffs
	id = "cuffed_item_[cuffed.UID()]"
	. = ..()
	if(.)
		linked_alert.update_appearance(UPDATE_OVERLAYS)

/datum/status_effect/cuffed_item/on_apply()
	if(HAS_TRAIT_FROM(cuffed, TRAIT_NODROP, CUFFED_ITEM_TRAIT))
		cuffed = null
		cuffs = null
		return FALSE
	owner.temporarily_remove_item_from_inventory(cuffs, force = TRUE)
	if(!owner.is_in_hands(cuffed) && !owner.put_in_hands(cuffed))
		owner.put_in_hands(cuffs)
		cuffed = null
		cuffs = null
		return FALSE

	ADD_TRAIT(cuffed, TRAIT_NODROP, CUFFED_ITEM_TRAIT)

	RegisterSignals(cuffed, list(COMSIG_ITEM_DROPPED, COMSIG_MOVABLE_MOVED, COMSIG_QDELETING), PROC_REF(on_displaced))
	RegisterSignal(cuffed, COMSIG_ATOM_UPDATE_APPEARANCE, PROC_REF(on_item_update_appearance))
	RegisterSignal(cuffed, COMSIG_ATOM_EXAMINE, PROC_REF(cuffed_reminder))
	RegisterSignal(cuffed, COMSIG_TOPIC, PROC_REF(topic_handler))
	RegisterSignal(cuffed, COMSIG_ITEM_GET_STRIPPABLE_ALT_ACTIONS, PROC_REF(get_strippable_action))
	RegisterSignal(cuffed, COMSIG_ITEM_STRIPPABLE_ALT_ACTION, PROC_REF(do_strippable_action))

	RegisterSignals(cuffs, list(COMSIG_ITEM_EQUIPPED, COMSIG_MOVABLE_MOVED, COMSIG_QDELETING), PROC_REF(on_displaced))
	RegisterSignal(cuffs, COMSIG_ATOM_UPDATE_APPEARANCE, PROC_REF(on_item_update_appearance))

	RegisterSignal(owner, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(on_examine_more))

	add_attack_logs(owner, cuffed, "Bound to themselves with [cuffs]", ATKLOG_ALL)
	return TRUE

/datum/status_effect/cuffed_item/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_EXAMINE_MORE)
	if(cuffed)
		UnregisterSignal(cuffed, list(
			COMSIG_ITEM_DROPPED,
			COMSIG_MOVABLE_MOVED,
			COMSIG_QDELETING,
			COMSIG_ATOM_UPDATE_APPEARANCE,
			COMSIG_ATOM_EXAMINE,
			COMSIG_TOPIC,
			COMSIG_ITEM_GET_STRIPPABLE_ALT_ACTIONS,
			COMSIG_ITEM_STRIPPABLE_ALT_ACTION,
		))
		REMOVE_TRAIT(cuffed, TRAIT_NODROP, CUFFED_ITEM_TRAIT)
	cuffed = null

	if(cuffs)
		UnregisterSignal(cuffs, list(COMSIG_ITEM_EQUIPPED, COMSIG_MOVABLE_MOVED, COMSIG_QDELETING, COMSIG_ATOM_UPDATE_APPEARANCE))
	if(!QDELETED(cuffs))
		cuffs.on_uncuffed()
		if(!QDELETED(owner) && cuffs.loc == owner && !(cuffs in owner.get_equipped_items(INCLUDE_POCKETS | INCLUDE_HELD)))
			cuffs.forceMove(owner.drop_location())
	cuffs = null

/datum/status_effect/cuffed_item/proc/on_examine_more(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/hand_name = owner.l_hand == cuffed ? "левой руке" : "правой руке"
	examine_list += span_warning("[DECLENT_RU_CAP(cuffed, NOMINATIVE)] прикован[GEND_A_O_Y(cuffed)] к [hand_name] [cuffs.declent_ru(INSTRUMENTAL)].")

/datum/status_effect/cuffed_item/proc/on_displaced(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/cuffed_item/proc/cuffed_reminder(obj/item/item, mob/user, list/examine_texts)
	SIGNAL_HANDLER
	if(user == owner)
		examine_texts += span_notice("[DECLENT_RU_CAP(item, NOMINATIVE)] прикован[GEND_A_O_Y(item)] к вам [cuffs.declent_ru(INSTRUMENTAL)]. Можно <a href='byond://?src=[item.UID()];remove_cuffs_item=1'>снять их</a>.")

/datum/status_effect/cuffed_item/proc/topic_handler(atom/source, user, href_list)
	SIGNAL_HANDLER
	if(user == owner && href_list["remove_cuffs_item"])
		INVOKE_ASYNC(src, PROC_REF(try_remove_cuffs), user)

/datum/status_effect/cuffed_item/proc/get_strippable_action(obj/item/source, atom/owner, mob/user, list/alt_actions)
	SIGNAL_HANDLER
	alt_actions += "remove_item_cuffs"

/datum/status_effect/cuffed_item/proc/do_strippable_action(obj/item/source, atom/owner, mob/user, action_key)
	SIGNAL_HANDLER
	if(action_key != "remove_item_cuffs" || source != cuffed || !isliving(user))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(try_remove_cuffs), user)
	return COMPONENT_ALT_ACTION_DONE

/datum/status_effect/cuffed_item/proc/try_remove_cuffs(mob/living/user)
	var/interaction_key = UID()
	if(LAZYACCESS(user.do_afters, interaction_key))
		return FALSE

	if(!(user.mobility_flags & MOBILITY_USE) || (user != owner && !owner.Adjacent(user)))
		owner.balloon_alert(user, "сейчас не выйдет!")
		return FALSE

	if(user != owner)
		owner.visible_message(
			span_notice("[user] пыта[PLUR_ET_UT(user)]ся снять [cuffs.declent_ru(ACCUSATIVE)], приковывающие [cuffed.declent_ru(ACCUSATIVE)] к [owner]."),
			span_warning("[user] пыта[PLUR_ET_UT(user)]ся снять [cuffs.declent_ru(ACCUSATIVE)], приковывающие к вам [cuffed.declent_ru(ACCUSATIVE)]."),
		)

	owner.balloon_alert(user, "снятие наручников...")
	playsound(owner, cuffs.cuffsound, 30, TRUE, -2)
	if(!do_after(user, cuffs.get_handcuff_time(user) * CUFFS_REMOVAL_TIME_MULTIPLIER, owner, interaction_key = interaction_key) || QDELETED(src))
		owner.balloon_alert(user, "прервано!")
		return FALSE

	if(user != owner)
		owner.visible_message(
			span_notice("[user] снима[PLUR_ET_UT(user)] [cuffs.declent_ru(ACCUSATIVE)], приковывающие [cuffed.declent_ru(ACCUSATIVE)] к [owner]."),
			span_warning("[user] снима[PLUR_ET_UT(user)] [cuffs.declent_ru(ACCUSATIVE)], приковывающие к вам [cuffed.declent_ru(ACCUSATIVE)]."),
		)

	add_attack_logs(user, owner, "Removed restraints binding [cuffed] to")

	var/obj/item/restraints/handcuffs/removed_cuffs = cuffs
	removed_cuffs.forceMove(owner.drop_location())
	user.put_in_hands(removed_cuffs)
	owner.balloon_alert(user, "наручники сняты")
	return TRUE

/datum/status_effect/cuffed_item/proc/on_item_update_appearance(datum/source)
	SIGNAL_HANDLER
	linked_alert?.update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/alert/status_effect/cuffed_item
	name = "Прикованный предмет"
	desc = "К вашей руке надёжно прикован предмет. Случайно его теперь точно не выронить. Нажмите, чтобы снять наручники."
	clickable_glow = TRUE
	click_master = FALSE

/atom/movable/screen/alert/status_effect/cuffed_item/update_overlays()
	. = ..()
	var/datum/status_effect/cuffed_item/effect = attached_effect
	if(!effect?.cuffed || !effect.cuffs)
		return
	. += add_atom_icon(effect.cuffed)
	var/mutable_appearance/cuffs_appearance = add_atom_icon(effect.cuffs)
	cuffs_appearance.transform *= CUFFS_ALERT_SCALE
	. += cuffs_appearance

/atom/movable/screen/alert/status_effect/cuffed_item/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/datum/status_effect/cuffed_item/effect = attached_effect
	INVOKE_ASYNC(effect, TYPE_PROC_REF(/datum/status_effect/cuffed_item, try_remove_cuffs), owner)

#undef CUFFS_REMOVAL_TIME_MULTIPLIER
#undef CUFFS_ALERT_SCALE
