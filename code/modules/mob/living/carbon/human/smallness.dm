/mob/living/carbon/human/proc/can_hold_pickupable_mob(mob/living/target_mob)
	if(!target_mob || incapacitated() || HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return FALSE
	if(r_hand && l_hand)
		return FALSE
	return !HAS_TRAIT(src, TRAIT_SMALL_MOB)

/mob/living/carbon/human/proc/can_request_pick_up_from(mob/living/carbon/human/target_human)
	if(!target_human || !HAS_TRAIT(src, TRAIT_SMALL_MOB))
		return FALSE
	if(!can_be_picked_up(target_human))
		return FALSE
	return target_human.can_hold_pickupable_mob(src)

/mob/living/carbon/human/proc/offer_self_pick_up(mob/living/carbon/human/target_human)
	if(!can_request_pick_up_from(target_human))
		return FALSE
	target_human.throw_alert("take_pickupable_[UID()]", /atom/movable/screen/alert/take_pickupable_mob, new_master = src, alert_args = list(src))
	to_chat(src, span_notice("Вы попросили [target_human.declent_ru(ACCUSATIVE)] взять вас на руки."))
	return TRUE

/mob/living/carbon/human/proc/can_complete_grab_pickup(mob/living/target_mob)
	if(pulling != target_mob || grab_state != GRAB_AGGRESSIVE || stat != CONSCIOUS)
		return FALSE
	if(!Adjacent(target_mob) || !can_hold_pickupable_mob(target_mob))
		return FALSE
	return target_mob.can_be_picked_up(src)

/mob/living/carbon/human/proc/try_pick_up_grabbed_mob(mob/living/target_mob)
	if(!can_complete_grab_pickup(target_mob))
		return FALSE
	visible_message(
		span_notice("[src] начинает поднимать [target_mob.declent_ru(ACCUSATIVE)] на руки."),
		span_notice("Вы начинаете поднимать [target_mob.declent_ru(ACCUSATIVE)] на руки."),
	)
	if(!do_after(src, 2 SECONDS, target_mob, DA_IGNORE_HELD_ITEM | DA_IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(can_complete_grab_pickup), target_mob), max_interact_count = 1, cancel_on_max = TRUE))
		return TRUE
	if(can_complete_grab_pickup(target_mob))
		target_mob.get_scooped(src)
	return TRUE

/mob/living/carbon/human/proc/can_jump_on_back_of(mob/living/carbon/human/target_human)
	if(!target_human || target_human == src || !HAS_TRAIT(src, TRAIT_SMALL_MOB))
		return FALSE
	if(stat != CONSCIOUS || target_human.stat != CONSCIOUS || !Adjacent(target_human))
		return FALSE
	return !buckled

/mob/living/carbon/human/proc/try_jump_on_back(mob/living/carbon/human/target_human)
	if(!can_jump_on_back_of(target_human))
		return FALSE
	visible_message(
		span_notice("[src] готовится запрыгнуть [target_human.declent_ru(DATIVE)] на спину."),
		span_notice("Вы готовитесь запрыгнуть [target_human.declent_ru(DATIVE)] на спину."),
	)
	if(!do_after(src, 1 SECONDS, target_human, timed_action_flags = DA_IGNORE_HELD_ITEM | DA_IGNORE_LYING, extra_checks = CALLBACK(src, PROC_REF(can_jump_on_back_of), target_human), max_interact_count = 1, cancel_on_max = TRUE))
		return TRUE
	if(can_jump_on_back_of(target_human))
		target_human.buckle_mob(src, force = TRUE, check_loc = FALSE, buckle_mob_flags = RIDER_NEEDS_ARMS)
	return TRUE

/mob/living/carbon/human/proc/can_climb_into_storage(obj/item/storage/target_storage)
	var/static/list/storage_blacklist = typecacheof(list(
		/obj/item/storage/backpack/holding,
		/obj/item/storage/lockbox,
		/obj/item/storage/secure,
	))
	if(QDELETED(target_storage) || !HAS_TRAIT(src, TRAIT_SMALL_MOB) || is_type_in_typecache(target_storage, storage_blacklist))
		return FALSE
	if(!isturf(loc) || !isturf(target_storage.loc))
		return FALSE
	return Adjacent(target_storage)

/mob/living/carbon/human/proc/try_climb_into_storage(obj/item/storage/target_storage)
	if(!can_climb_into_storage(target_storage))
		return FALSE
	visible_message(
		span_notice("[src] начинает забираться в [target_storage.declent_ru(ACCUSATIVE)]."),
		span_notice("Вы начинаете забираться в [target_storage.declent_ru(ACCUSATIVE)]."),
	)
	if(!do_after(src, 2 SECONDS, target_storage, DA_IGNORE_HELD_ITEM | DA_IGNORE_LYING, extra_checks = CALLBACK(src, PROC_REF(can_climb_into_storage), target_storage), max_interact_count = 1, cancel_on_max = TRUE))
		return TRUE
	if(!can_climb_into_storage(target_storage))
		return TRUE
	var/obj/item/holder/holder_item = get_scooped()
	if(!target_storage.can_be_inserted(holder_item, stop_messages = TRUE))
		holder_item.release_contents()
		to_chat(src, span_warning("Вы не помещаетесь в [target_storage.declent_ru(ACCUSATIVE)]."))
		return TRUE
	target_storage.handle_item_insertion(holder_item, prevent_warning = TRUE)
	to_chat(src, span_notice("Вы забираетесь в [target_storage.declent_ru(ACCUSATIVE)]."))
	return TRUE

/mob/living/carbon/human/mouse_drop_dragged(atom/over_object, mob/user, src_location, over_location, params)
	if(user == src && isstorage(over_object))
		try_climb_into_storage(over_object)
		return
	return ..()

/atom/movable/screen/alert/take_pickupable_mob
	name = "Просится на ручки"
	desc = "Кто-то хочет, чтобы вы взяли его на руки."
	timeout = 15 SECONDS
	clickable_glow = TRUE
	click_master = FALSE
	var/requester_UID

/atom/movable/screen/alert/take_pickupable_mob/Initialize(mapload, mob/living/carbon/human/requester)
	. = ..()
	requester_UID = requester.UID()
	desc = "[DECLENT_RU_CAP(requester, NOMINATIVE)] просится к вам на руки. Нажмите, чтобы взять."

/atom/movable/screen/alert/take_pickupable_mob/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/requester = locateUID(requester_UID)
	var/mob/living/carbon/human/receiver = owner
	if(requester?.can_request_pick_up_from(receiver) && requester.Adjacent(receiver))
		requester.get_scooped(receiver)
	else
		to_chat(receiver, span_warning("Не получается взять на руки."))
	receiver.clear_alert("take_pickupable_[requester_UID]")

/atom/movable/screen/alert/pickupable_container
	name = "Вы в контейнере"
	desc = "Нажмите, чтобы открыть контейнер, в котором вы сидите."
	clickable_glow = TRUE
	click_master = FALSE

/atom/movable/screen/alert/pickupable_container/Click(location, control, params)
	. = ..()
	if(!.)
		return
	var/obj/item/storage/container = master_ref?.resolve()
	if(!container || usr.loc?.loc != container)
		return
	container.open(usr)
