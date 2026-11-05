/datum/export/sec_helmet
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "шлемы"
	export_types = list(/obj/item/clothing/head/helmet, /obj/item/clothing/head/helmet/riot)
	include_subtypes = FALSE

/datum/export/sec_armor
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "бронежилеты"
	export_types = list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/riot)
	include_subtypes = FALSE

/datum/export/riot_shield
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "щиты"
	export_types = list(/obj/item/shield/riot)
	include_subtypes = FALSE

/datum/export/breath_mask
	cost = CARGO_CRATE_VALUE * 0.01
	unit_name = "дыхательные маски"
	export_types = list(/obj/item/clothing/mask/breath)

/datum/export/gas_mask
	cost = CARGO_CRATE_VALUE * 0.05
	unit_name = "противогазы"
	export_types = list(/obj/item/clothing/mask/gas)
	include_subtypes = FALSE

/datum/export/helmet_space
	cost = CARGO_CRATE_VALUE * 0.15
	unit_name = "космические шлемы"
	export_types = list(/obj/item/clothing/head/helmet/space, /obj/item/clothing/head/helmet/space/eva, /obj/item/clothing/head/helmet/space/nasavoid)
	include_subtypes = FALSE

/datum/export/suit_space
	cost = CARGO_CRATE_VALUE * 0.3
	unit_name = "скафандры"
	export_types = list(/obj/item/clothing/suit/space, /obj/item/clothing/suit/space/eva, /obj/item/clothing/suit/space/nasavoid)
	include_subtypes = FALSE

/datum/export/syndiehelmet_space
	cost = CARGO_CRATE_VALUE * 0.3
	unit_name = "космические шлемы Синдиката"
	export_types = list(/obj/item/clothing/head/helmet/space/syndicate)

/datum/export/syndiesuit_space
	cost = CARGO_CRATE_VALUE * 0.6
	unit_name = "скафандры Синдиката"
	export_types = list(/obj/item/clothing/suit/space/syndicate)

/datum/export/hardsuit_helmet
	cost = CARGO_CRATE_VALUE * 0.75
	unit_name = "шлемы укреплённых скафандров"
	export_types = list(
		/obj/item/clothing/head/helmet/space/hardsuit/engine,
		/obj/item/clothing/head/helmet/space/hardsuit/mining,
		/obj/item/clothing/head/helmet/space/hardsuit/medical,
		/obj/item/clothing/head/helmet/space/hardsuit/security,
	)

/datum/export/hardsuit
	cost = CARGO_CRATE_VALUE * 2
	unit_name = "укреплённые скафандры"
	export_types = list(
		/obj/item/clothing/suit/space/hardsuit/engine,
		/obj/item/clothing/suit/space/hardsuit/mining,
		/obj/item/clothing/suit/space/hardsuit/medical,
		/obj/item/clothing/suit/space/hardsuit/security,
	)

/datum/export/hardsuit_syndicate
	cost = CARGO_CRATE_VALUE * 10
	unit_name = "укреплённые скафандры Синдиката"
	export_types = list(/obj/item/clothing/suit/space/hardsuit/syndi)

/datum/export/radhelmet
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "капюшоны радиационной защиты"
	export_types = list(/obj/item/clothing/head/radiation)

/datum/export/radsuit
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "костюмы радиационной защиты"
	export_types = list(/obj/item/clothing/suit/radiation)

/datum/export/biohood
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "капюшоны биозащиты"
	export_types = list(/obj/item/clothing/head/bio_hood)

/datum/export/biosuit
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "костюмы биозащиты"
	export_types = list(/obj/item/clothing/suit/bio_suit)

/datum/export/bombhelmet
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "шлемы сапёра"
	export_types = list(/obj/item/clothing/head/bomb_hood)

/datum/export/bombsuit
	cost = CARGO_CRATE_VALUE * 0.2
	unit_name = "костюмы сапёра"
	export_types = list(/obj/item/clothing/suit/bomb_suit)

/datum/export/lizardboots
	cost = CARGO_CRATE_VALUE * 0.7
	unit_name = "сапоги из кожи ящера"
	export_types = list(/obj/item/clothing/shoes/cowboy/lizard)
	include_subtypes = FALSE

/datum/export/bilton
	cost = CARGO_CRATE_VALUE * 5
	unit_name = "ковбойские сапоги «Билтон»"
	export_types = list(/obj/item/clothing/shoes/cowboy/fancy)

/datum/export/zippo
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "зажигалки «Зиппо»"
	export_types = list(/obj/item/lighter/zippo)
	include_subtypes = FALSE
