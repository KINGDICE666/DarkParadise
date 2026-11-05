/datum/export/organ
	abstract_type = /datum/export/organ
	include_subtypes = FALSE

/datum/export/organ/heart
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "сердца гуманоидов"
	export_types = list(/obj/item/organ/internal/heart)

/datum/export/organ/eyes
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "глаза гуманоидов"
	export_types = list(/obj/item/organ/internal/eyes)

/datum/export/organ/ears
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "уши гуманоидов"
	export_types = list(/obj/item/organ/internal/ears)

/datum/export/organ/liver
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "печень гуманоидов"
	export_types = list(/obj/item/organ/internal/liver)

/datum/export/organ/lungs
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "лёгкие гуманоидов"
	export_types = list(/obj/item/organ/internal/lungs)

/datum/export/organ/kidneys
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "почки гуманоидов"
	export_types = list(/obj/item/organ/internal/kidneys)

/datum/export/organ/appendix
	cost = CARGO_CRATE_VALUE * 0.05
	unit_name = "аппендиксы гуманоидов"
	export_types = list(/obj/item/organ/internal/appendix)

/datum/export/organ/unathi_tail
	cost = CARGO_CRATE_VALUE * 1.25
	unit_name = "хвосты унатхов"
	export_types = list(/obj/item/organ/external/tail/unathi)

/datum/export/organ/fur_tail
	cost = CARGO_CRATE_VALUE * 1.5
	unit_name = "пушистые хвосты"
	export_types = list(/obj/item/organ/external/tail/tajaran, /obj/item/organ/external/tail/vulpkanin)

/datum/export/organ/regenerative_core
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "регенеративные ядра"
	export_types = list(/obj/item/organ/internal/regenerative_core)
	include_subtypes = TRUE
