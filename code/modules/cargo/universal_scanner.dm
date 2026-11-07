#define SCAN_EXPORTS "export scanner"
#define SCAN_SALES_TAG "sales tagger"
#define PAPER_PER_SHEET 10

/obj/item/universal_scanner
	name = "universal scanner"
	desc = "Прибор для сверки предметов с экспортной базой \"Нанотрейзен\". В режиме долевой наклейки печатает штрихкоды, которые отдают часть выручки с продажи посылки владельцу счёта."
	icon = 'icons/obj/device.dmi'
	icon_state = SCAN_EXPORTS
	item_state = "electronic"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	item_flags = NOBLUDGEON
	materials = list(MAT_METAL = 1500, MAT_GLASS = 1000)
	var/scanning_mode = SCAN_EXPORTS
	var/paper_count = 10
	var/max_paper_count = 20
	var/datum/money_account/payments_account
	var/cut_multiplier = 0.5
	var/cut_max = 0.5
	var/cut_min = 0.01

/obj/item/universal_scanner/get_ru_names()
	return alist(
		NOMINATIVE = "универсальный сканер",
		GENITIVE = "универсального сканера",
		DATIVE = "универсальному сканеру",
		ACCUSATIVE = "универсальный сканер",
		INSTRUMENTAL = "универсальным сканером",
		PREPOSITIONAL = "универсальном сканере",
	)

/obj/item/universal_scanner/Destroy()
	payments_account = null
	return ..()

/obj/item/universal_scanner/attack_self(mob/user)
	var/static/list/modes = list(
		SCAN_EXPORTS = image(icon = 'icons/obj/device.dmi', icon_state = SCAN_EXPORTS),
		SCAN_SALES_TAG = image(icon = 'icons/obj/device.dmi', icon_state = SCAN_SALES_TAG),
	)
	var/choice = show_radial_menu(user, src, modes, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 36, require_near = TRUE)
	if(!choice || choice == scanning_mode)
		return
	scanning_mode = choice
	update_icon(UPDATE_ICON_STATE)
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	balloon_alert(user, choice == SCAN_EXPORTS ? "режим сканера экспорта" : "режим долевых наклеек")

/obj/item/universal_scanner/update_icon_state()
	icon_state = scanning_mode

/obj/item/universal_scanner/proc/check_menu(mob/living/user)
	return istype(user) && !user.incapacitated() && loc == user

/obj/item/universal_scanner/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isobj(interacting_with))
		return NONE
	if(scanning_mode == SCAN_EXPORTS)
		export_scan(interacting_with, user)
		return ITEM_INTERACT_SUCCESS
	if(istype(interacting_with, /obj/item/smallDelivery) || istype(interacting_with, /obj/structure/bigDelivery))
		tag_parcel(interacting_with, user)
		return ITEM_INTERACT_SUCCESS
	return NONE

/obj/item/universal_scanner/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(is_id_card(tool))
		var/obj/item/card/id/card = tool
		var/datum/money_account/account = get_account_from_card(card)
		if(!account)
			balloon_alert(user, "счёт не найден!")
			return ITEM_INTERACT_BLOCKING
		payments_account = account
		playsound(src, 'sound/machines/ping.ogg', 40, TRUE)
		to_chat(user, span_notice("[capitalize(declent_ru(NOMINATIVE))] привязан к счёту [account.owner_name]. Помечайте посылки, чтобы получать долю с продажи."))
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/paper))
		if(paper_count >= max_paper_count)
			balloon_alert(user, "бумага заполнена!")
			return ITEM_INTERACT_BLOCKING
		paper_count = min(paper_count + PAPER_PER_SHEET, max_paper_count)
		qdel(tool)
		balloon_alert(user, "бумага: [paper_count]/[max_paper_count]")
		return ITEM_INTERACT_SUCCESS

	return NONE

/obj/item/universal_scanner/click_alt(mob/user)
	if(scanning_mode != SCAN_SALES_TAG)
		return CLICK_ACTION_BLOCKING
	var/potential_cut = tgui_input_number(user, "Какую долю выручки получит владелец счёта?", "Доля ([round(cut_min * 100)]% – [round(cut_max * 100)]%)", round(cut_multiplier * 100), round(cut_max * 100), round(cut_min * 100))
	if(isnull(potential_cut) || QDELETED(src) || loc != user)
		return CLICK_ACTION_BLOCKING
	cut_multiplier = clamp(round(potential_cut / 100, cut_min), cut_min, cut_max)
	balloon_alert(user, "доля [round(cut_multiplier * 100)]%")
	return CLICK_ACTION_SUCCESS

/obj/item/universal_scanner/CtrlClick(mob/user)
	if(scanning_mode != SCAN_SALES_TAG || loc != user || !payments_account)
		return ..()
	payments_account = null
	balloon_alert(user, "счёт отвязан")

/obj/item/universal_scanner/examine(mob/user)
	. = ..()
	. += span_notice("Осталось наклеек: [paper_count]/[max_paper_count]. Пополняется бумагой.")
	if(scanning_mode == SCAN_SALES_TAG)
		. += span_notice("Доля владельца счёта с продажи: [round(cut_multiplier * 100)]%. <b>Alt-клик</b>, чтобы изменить.")
		if(payments_account)
			. += span_notice("Привязан счёт [payments_account.owner_name]. <b>Ctrl-клик</b>, чтобы отвязать.")
		else
			. += span_notice("Проведите ID-картой, чтобы привязать счёт.")

/obj/item/universal_scanner/proc/export_scan(obj/target, mob/user)
	var/datum/export_report/report = export_item_and_contents(target, dry_run = TRUE)
	var/price = counterlist_sum(report.total_value)
	var/target_name = target.declent_ru(NOMINATIVE)
	var/message
	if(!report.all_contents_scannable && !price)
		message = "[capitalize(target_name)]: стоимость определить не удалось."
	else if(price)
		message = "[capitalize(target_name)][length(target.contents) ? " с содержимым" : ""]: экспортная стоимость <b>[price]</b> кр.[report.all_contents_scannable ? "" : " Часть груза не поддаётся оценке, итог может отличаться."]"
	else
		message = "[capitalize(target_name)]: экспортной ценности нет."
	to_chat(user, price ? span_notice(message) : span_warning(message))
	if(price)
		playsound(src, 'sound/machines/terminal_select.ogg', 50, TRUE)

/obj/item/universal_scanner/proc/tag_parcel(obj/parcel, mob/user)
	if(!payments_account)
		balloon_alert(user, "сначала проведите ID-картой!")
		return
	if(paper_count <= 0)
		balloon_alert(user, "нет бумаги!")
		return
	var/obj/item/barcode/new_barcode = new(src)
	new_barcode.payments_account = payments_account
	new_barcode.cut_multiplier = cut_multiplier
	if(!new_barcode.attach_to(parcel, user))
		qdel(new_barcode)
		return
	paper_count--

/obj/item/barcode
	name = "barcode tag"
	desc = "Маленькая наклейка, привязанная к счёту. Наклейте на упакованную посылку, чтобы владелец счёта получил долю выручки с её продажи."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "barcode"
	w_class = WEIGHT_CLASS_TINY
	var/datum/money_account/payments_account
	var/cut_multiplier = 0.5

/obj/item/barcode/get_ru_names()
	return alist(
		NOMINATIVE = "штрихкод",
		GENITIVE = "штрихкода",
		DATIVE = "штрихкоду",
		ACCUSATIVE = "штрихкод",
		INSTRUMENTAL = "штрихкодом",
		PREPOSITIONAL = "штрихкоде",
	)

/obj/item/barcode/Destroy()
	payments_account = null
	return ..()

/obj/item/barcode/examine(mob/user)
	. = ..()
	if(payments_account)
		. += span_notice("Выплата [round(cut_multiplier * 100)]% выручки на счёт [payments_account.owner_name].")

/obj/item/barcode/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!istype(interacting_with, /obj/item/smallDelivery) && !istype(interacting_with, /obj/structure/bigDelivery))
		return NONE
	attach_to(interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/barcode/proc/attach_to(obj/parcel, mob/user)
	if(HAS_TRAIT(parcel, TRAIT_HAS_BARCODE))
		balloon_alert(user, "уже есть штрихкод!")
		return FALSE
	if(!payments_account)
		balloon_alert(user, "штрихкод недействителен!")
		return FALSE
	if(loc == user && !user.drop_item_ground(src))
		return FALSE
	forceMove(parcel)
	ADD_TRAIT(parcel, TRAIT_HAS_BARCODE, UID())
	for(var/obj/wrapped_item in parcel.get_all_contents() - parcel - src)
		wrapped_item.AddComponent(/datum/component/pricetag, list(payments_account), cut_multiplier)
	user.visible_message(span_notice("[user] наклеива[PLUR_ET_YUT(user)] штрихкод на [parcel.declent_ru(ACCUSATIVE)]."), span_notice("Вы наклеиваете штрихкод на [parcel.declent_ru(ACCUSATIVE)]."))
	return TRUE

#undef SCAN_EXPORTS
#undef SCAN_SALES_TAG
#undef PAPER_PER_SHEET
