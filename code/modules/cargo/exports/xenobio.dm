/datum/export/slime_extract_grey
	cost = CARGO_CRATE_VALUE * 0.05
	unit_name = "серые ядра слаймов"
	export_types = list(/obj/item/slime_extract/grey)

/datum/export/slime_extract_common
	cost = CARGO_CRATE_VALUE * 0.12
	unit_name = "обычные ядра слаймов"
	export_types = list(/obj/item/slime_extract/metal, /obj/item/slime_extract/orange, /obj/item/slime_extract/purple, /obj/item/slime_extract/blue)

/datum/export/slime_extract_uncommon
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "необычные ядра слаймов"
	export_types = list(/obj/item/slime_extract/gold, /obj/item/slime_extract/green, /obj/item/slime_extract/red, /obj/item/slime_extract/pink)

/datum/export/slime_extract_rare
	cost = CARGO_CRATE_VALUE * 0.28
	unit_name = "редкие ядра слаймов"
	export_types = list(/obj/item/slime_extract/silver, /obj/item/slime_extract/darkblue, /obj/item/slime_extract/darkpurple, /obj/item/slime_extract/yellow)

/datum/export/slime_extract_epic
	cost = CARGO_CRATE_VALUE * 0.44
	unit_name = "эпические ядра слаймов"
	export_types = list(
		/obj/item/slime_extract/black,
		/obj/item/slime_extract/cerulean,
		/obj/item/slime_extract/oil,
		/obj/item/slime_extract/sepia,
		/obj/item/slime_extract/pyrite,
		/obj/item/slime_extract/adamantine,
		/obj/item/slime_extract/lightpink,
		/obj/item/slime_extract/bluespace,
	)

/datum/export/slime_extract_rainbow
	cost = CARGO_CRATE_VALUE
	unit_name = "радужные ядра слаймов"
	export_types = list(/obj/item/slime_extract/rainbow)

/datum/export/slime_extract_charged
	cost = CARGO_CRATE_VALUE
	unit_name = "слаймовые батареи"
	export_types = list(/obj/item/stock_parts/cell/high/slime)
