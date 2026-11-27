/datum/bounty/item
	var/required_count = 1
	var/shipped_count = 0
	var/list/wanted_types
	var/include_subtypes = TRUE

/datum/bounty/item/New()
	..()
	wanted_types = string_assoc_list(zebra_typecacheof(wanted_types, only_root_path = !include_subtypes))

/datum/bounty/item/print_required()
	return "[shipped_count]/[required_count]"

/datum/bounty/item/can_claim()
	return shipped_count >= required_count

/datum/bounty/item/applies_to(obj/shipped)
	if(!is_type_in_typecache(shipped, wanted_types))
		return FALSE
	if(shipped.flags & HOLOGRAM)
		return FALSE
	return shipped_count < required_count

/datum/bounty/item/ship(obj/shipped)
	if(!applies_to(shipped))
		return FALSE
	if(isstack(shipped))
		var/obj/item/stack/shipped_stack = shipped
		shipped_count += shipped_stack.amount
	else
		shipped_count += 1
	return TRUE

/datum/bounty/item/get_total()
	return shipped_count

/datum/bounty/item/get_max()
	return required_count

/obj/item/bounty_voucher
	name = "bounty voucher"
	desc = "Сертификат на ОДНУ БЕСПЛАТНУЮ БАУНТИ на ваш выбор! Вау!"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper_words"

/obj/item/bounty_voucher/get_ru_names()
	return alist(
		NOMINATIVE = "ваучер на баунти",
		GENITIVE = "ваучера на баунти",
		DATIVE = "ваучеру на баунти",
		ACCUSATIVE = "ваучер на баунти",
		INSTRUMENTAL = "ваучером на баунти",
		PREPOSITIONAL = "ваучере на баунти",
	)

/obj/item/bounty_voucher/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	var/obj/item/card/id/id_card = user.get_id_card()
	var/datum/money_account/account = id_card ? get_account_from_card(id_card) : null
	if(!account)
		return
	var/datum/bounty/choice = tgui_input_list(user, "Выберите баунти.", "Новая баунти", subtypesof(/datum/bounty))
	if(!choice)
		return
	account.set_bounty(new choice, id_card)
	balloon_alert(user, "баунти получена!")
	playsound(src, 'sound/items/coinflip.ogg', 30, TRUE)
	qdel(src)

/obj/item/bounty_voucher/stationwide
	name = "stationwide bounty voucher"
	desc = "Сертификат на ОДНУ БЕСПЛАТНУЮ БАУНТИ на ваш выбор! Для всех! Ого!"
	color = "#ff8800"

/obj/item/bounty_voucher/stationwide/get_ru_names()
	return alist(
		NOMINATIVE = "станционный ваучер на баунти",
		GENITIVE = "станционного ваучера на баунти",
		DATIVE = "станционному ваучеру на баунти",
		ACCUSATIVE = "станционный ваучер на баунти",
		INSTRUMENTAL = "станционным ваучером на баунти",
		PREPOSITIONAL = "станционном ваучере на баунти",
	)

/obj/item/bounty_voucher/stationwide/attack_self(mob/user)
	if(!isliving(user))
		return
	var/datum/bounty/choice = tgui_input_list(user, "Выберите баунти.", "Новая баунти", subtypesof(/datum/bounty))
	if(!choice)
		return
	if(initial(choice.global_exempt))
		to_chat(user, span_warning("Эта баунти не может быть общей, выберите другую!"))
		return
	GLOB.shared_crew_bounties += new choice
	balloon_alert(user, "баунти выдана экипажу!")
	playsound(src, 'sound/items/coinflip.ogg', 30, TRUE)
	qdel(src)
