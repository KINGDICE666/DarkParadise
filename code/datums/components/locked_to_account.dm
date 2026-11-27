#define DENY_SOUND_COOLDOWN (2 SECONDS)

/datum/component/locked_to_account
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/datum/money_account/buyer_account
	COOLDOWN_DECLARE(deny_cooldown)

/datum/component/locked_to_account/Initialize(datum/money_account/buyer_account)
	. = ..()
	if(!iscloset(parent))
		return COMPONENT_INCOMPATIBLE
	src.buyer_account = buyer_account

/datum/component/locked_to_account/InheritComponent(datum/component/locked_to_account/new_comp, i_am_original, datum/money_account/buyer_account)
	src.buyer_account = buyer_account

/datum/component/locked_to_account/Destroy(force)
	buyer_account = null
	return ..()

/datum/component/locked_to_account/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_ATOM_EMAG_ACT, PROC_REF(on_emag))
	RegisterSignal(parent, COMSIG_CLOSET_PRE_OPEN, PROC_REF(on_pre_open))

/datum/component/locked_to_account/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ATOM_EXAMINE,
		COMSIG_ATOM_EMAG_ACT,
		COMSIG_CLOSET_PRE_OPEN,
	))

/datum/component/locked_to_account/proc/on_examine(obj/structure/closet/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Замок счёта не даст открыть [source.declent_ru(ACCUSATIVE)] никому, кроме покупателя — [buyer_account.owner_name].")

/datum/component/locked_to_account/proc/on_pre_open(obj/structure/closet/source, mob/living/user, force)
	SIGNAL_HANDLER
	if(force)
		return NONE

	if(isnull(user))
		return BLOCK_OPEN

	var/obj/item/card/id/id_card = user.get_id_card()
	if(isnull(id_card))
		deny(source, user, "нет ID-карты!")
		return BLOCK_OPEN

	if(id_card.associated_account_number != buyer_account.account_number)
		deny(source, user, "счёт не совпадает!")
		return BLOCK_OPEN

	source.add_fingerprint(user)
	remove_lock(source, user)
	return NONE

/datum/component/locked_to_account/proc/deny(obj/structure/closet/source, mob/living/user, message)
	source.balloon_alert(user, message)
	if(COOLDOWN_FINISHED(src, deny_cooldown))
		playsound(source, 'sound/machines/buzz-two.ogg', 30, TRUE)
		COOLDOWN_START(src, deny_cooldown, DENY_SOUND_COOLDOWN)

/datum/component/locked_to_account/proc/on_emag(obj/structure/closet/source, mob/emagger)
	SIGNAL_HANDLER
	if(emagger)
		source.balloon_alert(emagger, "замок счёта взломан")
	remove_lock(source)

/datum/component/locked_to_account/proc/remove_lock(obj/structure/closet/source)
	source.visible_message(span_notice("Замок счёта на [source.declent_ru(PREPOSITIONAL)] отключается с тихим щелчком."))
	source.update_appearance()
	qdel(src)

#undef DENY_SOUND_COOLDOWN
