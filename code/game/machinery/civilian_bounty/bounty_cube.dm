/obj/item/bounty_cube
	name = "bounty cube"
	desc = "Сжатый пакет твёрдосветовых данных с выполненной баунти. Продайте его через шаттл снабжения, чтобы получить награду!"
	icon = 'icons/obj/machines/civilian_bounty.dmi'
	icon_state = "bounty_cube"
	var/bounty_value = 0
	var/speed_bonus = 0.2
	var/holder_cut = BOUNTY_CUT_STANDARD
	var/nag_cooldown = 5 MINUTES
	var/nag_cooldown_multiplier = 1.25
	COOLDOWN_DECLARE(next_nag_time)
	var/bounty_holder
	var/bounty_holder_job
	var/bounty_name
	var/list/datum/money_account/bounty_holder_accounts

/obj/item/bounty_cube/get_ru_names()
	return alist(
		NOMINATIVE = "куб баунти",
		GENITIVE = "куба баунти",
		DATIVE = "кубу баунти",
		ACCUSATIVE = "куб баунти",
		INSTRUMENTAL = "кубом баунти",
		PREPOSITIONAL = "кубе баунти",
	)

/obj/item/bounty_cube/Destroy()
	STOP_PROCESSING(SSobj, src)
	bounty_holder_accounts = null
	return ..()

/obj/item/bounty_cube/examine(mob/user)
	. = ..()
	if(bounty_value)
		. += span_notice("Стоимость: <b>[bounty_value]</b> кр. Баунти \"[bounty_name]\", исполнитель: [bounty_holder] ([bounty_holder_job]).")
	if(speed_bonus)
		. += span_notice("До потери бонуса за быструю доставку (<b>[bounty_value * speed_bonus]</b> кр.) осталось <b>[DisplayTimeText(COOLDOWN_TIMELEFT(src, next_nag_time), 1)]</b>.")

/obj/item/bounty_cube/process(seconds_per_tick)
	if(!COOLDOWN_FINISHED(src, next_nag_time) || is_admin_level(z) || is_reserved_level(z))
		return

	var/nag_message = "Куб баунти стоимостью [bounty_value] кр. не отправлен: [get_area_name(src, TRUE)]."
	if(speed_bonus)
		nag_message += " Бонус за быструю доставку ([bounty_value * speed_bonus] кр.) потерян."
	radio_announce(nag_message, "Система баунти", SUP_FREQ, src)
	speed_bonus = 0

	for(var/datum/money_account/holder_account as anything in bounty_holder_accounts)
		holder_account.notify_pda_owner("<b>Баунти </b>\"[nag_message]\" (Невозможно Ответить)")

	nag_cooldown *= nag_cooldown_multiplier
	COOLDOWN_START(src, next_nag_time, nag_cooldown)

/obj/item/bounty_cube/proc/set_up(datum/bounty/my_bounty, obj/item/card/id/holder_id)
	bounty_value = my_bounty.get_bounty_reward()
	bounty_name = my_bounty.name
	bounty_holder = holder_id.registered_name
	bounty_holder_job = holder_id.assignment
	bounty_holder_accounts = my_bounty.contribution.Copy()

	name = "[bounty_value] cr [name]"
	AddComponent(/datum/component/pricetag, bounty_holder_accounts.Copy(), holder_cut, FALSE)

	START_PROCESSING(SSobj, src)
	COOLDOWN_START(src, next_nag_time, nag_cooldown)
	radio_announce("Создан куб баунти стоимостью [bounty_value] кр.: [get_area_name(src, TRUE)], [bounty_holder] ([bounty_holder_job]). Бонус за быструю доставку сгорит через [DisplayTimeText(nag_cooldown, 1)].", "Система баунти", SUP_FREQ, src)

/obj/item/bounty_cube/debug_cube
	name = "debug bounty cube"
	desc = "Используйте в руке, чтобы настроить куб на случайную баунти. Нужна ID-карта с привязанным счётом."
	var/configured = FALSE

/obj/item/bounty_cube/debug_cube/attack_self(mob/user)
	if(!isliving(user) || configured)
		return ..()
	var/obj/item/card/id/id_card = user.get_id_card()
	var/datum/money_account/account = id_card ? get_account_from_card(id_card) : null
	if(!account)
		to_chat(user, span_notice("Не удаётся обнаружить ваш счёт."))
		return ..()
	var/datum/bounty/debug_bounty = random_bounty()
	debug_bounty.contribution[account] = 1
	set_up(debug_bounty, id_card)
	qdel(debug_bounty)
	configured = TRUE
	return ..()
