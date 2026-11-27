/datum/export/mecha
	abstract_type = /datum/export/mecha
	include_subtypes = FALSE

/datum/export/mecha/ripley
	cost = CARGO_CRATE_VALUE * 2
	unit_name = "экзоскелеты «Рипли»"
	export_types = list(/obj/mecha/working/ripley, /obj/mecha/working/ripley/firefighter)

/datum/export/mecha/ripley_mk2
	cost = CARGO_CRATE_VALUE * 3
	unit_name = "экзоскелеты «Рипли» МК-II"
	export_types = list(/obj/mecha/working/ripley/mkii)

/datum/export/mecha/clarke
	cost = CARGO_CRATE_VALUE * 4
	unit_name = "экзоскелеты «Кларк»"
	export_types = list(/obj/mecha/working/clarke)

/datum/export/mecha/odysseus
	cost = CARGO_CRATE_VALUE * 2.5
	unit_name = "экзоскелеты «Одиссей»"
	export_types = list(/obj/mecha/medical/odysseus)

/datum/export/mecha/gygax
	cost = CARGO_CRATE_VALUE * 7.5
	unit_name = "экзоскелеты «Гигакс»"
	export_types = list(/obj/mecha/combat/gygax)

/datum/export/mecha/durand
	cost = CARGO_CRATE_VALUE * 6
	unit_name = "экзоскелеты «Дюранд»"
	export_types = list(/obj/mecha/combat/durand)
