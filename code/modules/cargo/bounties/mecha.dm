/datum/bounty/item/mech
	wanted_types = list(/obj/item/mecha_diagnostic = TRUE)
	var/required_data

/datum/bounty/item/mech/New()
	..()
	description = "Высшее руководство просит как можно скорее прислать голодиагностику меха \"[name]\". <b>Голодиагностику</b> можно создать изнутри нового меха. Отправьте её, чтобы получить крупную выплату."

/datum/bounty/item/mech/applies_to(obj/shipped)
	if(!..())
		return FALSE
	var/obj/item/mecha_diagnostic/diagnostic_sheet = shipped
	return ispath(diagnostic_sheet.mech_type, required_data)

/datum/bounty/item/mech/ripleymk2
	name = "АПЛУ МК-II \"Рипли\""
	reward = CARGO_CRATE_VALUE * 6.5
	required_data = /obj/mecha/working/ripley/mkii

/datum/bounty/item/mech/clarke
	name = "Кларк"
	reward = CARGO_CRATE_VALUE * 12
	required_data = /obj/mecha/working/clarke

/datum/bounty/item/mech/odysseus
	name = "Одиссей"
	reward = CARGO_CRATE_VALUE * 5.5
	required_data = /obj/mecha/medical/odysseus

/datum/bounty/item/mech/gygax
	name = "Гигакс"
	reward = CARGO_CRATE_VALUE * 28
	required_data = /obj/mecha/combat/gygax

/datum/bounty/item/mech/durand
	name = "Дюранд"
	reward = CARGO_CRATE_VALUE * 20
	required_data = /obj/mecha/combat/durand
