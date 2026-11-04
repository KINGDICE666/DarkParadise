/datum/bounty/item/mech/New()
	..()
	description = "Высшее руководство просит как можно скорее доставить меха \"[name]\". Отправьте его, чтобы получить крупную выплату."

/datum/bounty/item/mech/ripleymk2
	name = "АПЛУ МК-II \"Рипли\""
	reward = CARGO_CRATE_VALUE * 6.5
	wanted_types = list(/obj/mecha/working/ripley/mkii = TRUE)

/datum/bounty/item/mech/clarke
	name = "Кларк"
	reward = CARGO_CRATE_VALUE * 12
	wanted_types = list(/obj/mecha/working/clarke = TRUE)

/datum/bounty/item/mech/odysseus
	name = "Одиссей"
	reward = CARGO_CRATE_VALUE * 5.5
	wanted_types = list(/obj/mecha/medical/odysseus = TRUE)

/datum/bounty/item/mech/gygax
	name = "Гигакс"
	reward = CARGO_CRATE_VALUE * 28
	wanted_types = list(/obj/mecha/combat/gygax = TRUE)

/datum/bounty/item/mech/durand
	name = "Дюранд"
	reward = CARGO_CRATE_VALUE * 20
	wanted_types = list(/obj/mecha/combat/durand = TRUE)
