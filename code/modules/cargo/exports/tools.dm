/datum/export/toolbox
	cost = CARGO_CRATE_VALUE * 0.01
	unit_name = "ящики с инструментами"
	export_types = list(/obj/item/storage/toolbox)

/datum/export/screwdriver
	unit_name = "отвёртки"
	export_types = list(/obj/item/screwdriver)
	include_subtypes = FALSE

/datum/export/wrench
	unit_name = "гаечные ключи"
	export_types = list(/obj/item/wrench)
	include_subtypes = FALSE

/datum/export/crowbar
	unit_name = "ломы"
	export_types = list(/obj/item/crowbar)
	include_subtypes = FALSE

/datum/export/wirecutters
	unit_name = "кусачки"
	export_types = list(/obj/item/wirecutters)
	include_subtypes = FALSE

/datum/export/weldingtool
	cost = CARGO_CRATE_VALUE * 0.01
	unit_name = "сварочные аппараты"
	export_types = list(/obj/item/weldingtool)
	include_subtypes = FALSE

/datum/export/weldingtool/emergency
	cost = CARGO_CRATE_VALUE * 0.005
	unit_name = "аварийные сварочные аппараты"
	export_types = list(/obj/item/weldingtool/mini)

/datum/export/weldingtool/industrial
	cost = CARGO_CRATE_VALUE * 0.02
	unit_name = "промышленные сварочные аппараты"
	export_types = list(/obj/item/weldingtool/largetank, /obj/item/weldingtool/hugetank)

/datum/export/weldingtool/experimental
	cost = CARGO_CRATE_VALUE * 0.45
	unit_name = "экспериментальные сварочные аппараты"
	export_types = list(/obj/item/weldingtool/experimental)

/datum/export/extinguisher
	cost = CARGO_CRATE_VALUE * 0.025
	unit_name = "огнетушители"
	export_types = list(/obj/item/extinguisher)
	include_subtypes = FALSE

/datum/export/extinguisher/mini
	cost = CARGO_CRATE_VALUE * 0.005
	unit_name = "карманные огнетушители"
	export_types = list(/obj/item/extinguisher/mini)

/datum/export/flashlight
	cost = CARGO_CRATE_VALUE * 0.01
	unit_name = "фонарики"
	export_types = list(/obj/item/flashlight)
	include_subtypes = FALSE

/datum/export/flashlight/flare
	cost = CARGO_CRATE_VALUE * 0.005
	unit_name = "фальшфейеры"
	export_types = list(/obj/item/flashlight/flare)

/datum/export/flashlight/seclite
	cost = CARGO_CRATE_VALUE * 0.02
	unit_name = "тактические фонари"
	export_types = list(/obj/item/flashlight/seclite)

/datum/export/analyzer
	cost = CARGO_CRATE_VALUE * 0.01
	unit_name = "газоанализаторы"
	export_types = list(/obj/item/analyzer)

/datum/export/t_scanner
	cost = CARGO_CRATE_VALUE * 0.01
	unit_name = "Т-сканеры"
	export_types = list(/obj/item/t_scanner)

/datum/export/radio
	cost = CARGO_CRATE_VALUE * 0.01
	unit_name = "рации"
	export_types = list(/obj/item/radio)
	exclude_types = list(/obj/item/radio/headset, /obj/item/radio/intercom, /obj/item/radio/borg)

/datum/export/jawsoflife
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "челюсти жизни"
	export_types = list(/obj/item/crowbar/power)

/datum/export/handdrill
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "ручные дрели"
	export_types = list(/obj/item/screwdriver/power)

/datum/export/rsf
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "РСФ"
	export_types = list(/obj/item/rsf)

/datum/export/rcd
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "РЦД"
	export_types = list(/obj/item/rcd)
	include_subtypes = FALSE

/datum/export/rcd_ammo
	cost = CARGO_CRATE_VALUE * 0.3
	unit_name = "картриджи РЦД"
	export_types = list(/obj/item/rcd_ammo)

/datum/export/rpd
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "РПД"
	export_types = list(/obj/item/rpd)
	include_subtypes = FALSE

/datum/export/soap
	cost = CARGO_CRATE_VALUE * 0.375
	unit_name = "мыло"
	export_types = list(/obj/item/soap)
	exclude_types = list(/obj/item/soap/ducttape)

/datum/export/candle
	cost = CARGO_CRATE_VALUE * 0.06
	unit_name = "свечи"
	export_types = list(/obj/item/candle)
	exclude_types = list(/obj/item/candle/eternal)
