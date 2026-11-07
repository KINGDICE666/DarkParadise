#define DENY_SOUND_COOLDOWN (2 SECONDS)

/datum/element/deliver_first
	element_flags = ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	var/department
	var/payment
	COOLDOWN_DECLARE(deny_cooldown)

/datum/element/deliver_first/Attach(datum/target, department, payment)
	. = ..()
	if(!iscloset(target))
		return ELEMENT_INCOMPATIBLE
	src.department = department
	src.payment = payment
	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(target, COMSIG_ATOM_EMAG_ACT, PROC_REF(on_emag))
	RegisterSignal(target, COMSIG_CLOSET_POST_OPEN, PROC_REF(on_post_open))
	ADD_TRAIT(target, TRAIT_BANNED_FROM_CARGO_SHUTTLE, UNIQUE_TRAIT_SOURCE(src))
	area_check(target)

/datum/element/deliver_first/Detach(datum/target)
	. = ..()
	REMOVE_TRAIT(target, TRAIT_BANNED_FROM_CARGO_SHUTTLE, UNIQUE_TRAIT_SOURCE(src))
	UnregisterSignal(target, list(
		COMSIG_ATOM_EXAMINE,
		COMSIG_MOVABLE_MOVED,
		COMSIG_ATOM_EMAG_ACT,
		COMSIG_CLOSET_PRE_OPEN,
		COMSIG_CLOSET_POST_OPEN,
	))

/datum/element/deliver_first/proc/on_examine(obj/structure/closet/target, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Замок доставки не даст открыть [target.declent_ru(ACCUSATIVE)], пока груз не доставят в отдел «[GLOB.station_departments_ru[department]]».")
	examine_list += span_warning("Пока груз не вскрыт, его нельзя отправить обратно шаттлом снабжения.")

/datum/element/deliver_first/proc/area_check(obj/structure/closet/target)
	if(is_type_in_list(get_area(target), GLOB.department_order_areas[department]))
		UnregisterSignal(target, COMSIG_CLOSET_PRE_OPEN)
		return TRUE
	RegisterSignal(target, COMSIG_CLOSET_PRE_OPEN, PROC_REF(on_pre_open), override = TRUE)
	return FALSE

/datum/element/deliver_first/proc/on_moved(obj/structure/closet/target, atom/oldloc, direction)
	SIGNAL_HANDLER
	area_check(target)

/datum/element/deliver_first/proc/on_emag(obj/structure/closet/target, mob/emagger)
	SIGNAL_HANDLER
	if(emagger)
		target.balloon_alert(emagger, "замок доставки взломан")
	remove_lock(target)

/datum/element/deliver_first/proc/on_pre_open(obj/structure/closet/target, mob/living/user, force)
	SIGNAL_HANDLER
	if(force)
		return NONE
	if(user)
		target.balloon_alert(user, "сначала доставьте в отдел!")
	if(COOLDOWN_FINISHED(src, deny_cooldown))
		playsound(target, 'sound/machines/buzz-two.ogg', 30, TRUE)
		COOLDOWN_START(src, deny_cooldown, DENY_SOUND_COOLDOWN)
	return BLOCK_OPEN

/datum/element/deliver_first/proc/on_post_open(obj/structure/closet/target, mob/living/user, force)
	SIGNAL_HANDLER
	if(area_check(target))
		SSshuttle.cargo_money_account.credit(payment, "Доставка заказа отдела «[GLOB.station_departments_ru[department]]»", "Терминал Бизель №[rand(111,333)]", SSshuttle.cargo_money_account.owner_name)
	remove_lock(target)

/datum/element/deliver_first/proc/remove_lock(obj/structure/closet/target)
	target.visible_message(span_notice("Замок доставки на [target.declent_ru(PREPOSITIONAL)] самоуничтожается, рассыпая искры!"))
	do_sparks(4, FALSE, target)
	target.RemoveElement(/datum/element/deliver_first, department, payment)

#undef DENY_SOUND_COOLDOWN
