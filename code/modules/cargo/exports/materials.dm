#define ORE_EXPORT_MULTIPLIER 0.8

/datum/export/material
	abstract_type = /datum/export/material
	k_hit_percentile = 0.2 / MAX_STACK_SIZE
	k_recovery_time = 8 MINUTES
	var/material_id

/datum/export/material/get_base_cost(obj/item/exported_item)
	if(sales_market != EXPORT_MARKET_STATION)
		return cost
	return SSstock_market.get_price(material_id)

/datum/export/material/get_amount(obj/item/exported_item)
	if(!isitem(exported_item))
		return 0
	var/amount = LAZYACCESS(exported_item.materials, material_id)
	if(!amount)
		return 0
	if(isstack(exported_item))
		var/obj/item/stack/stack = exported_item
		amount *= stack.amount
	if(istype(exported_item, /obj/item/stack/ore))
		amount *= ORE_EXPORT_MULTIPLIER
	return amount / MINERAL_MATERIAL_AMOUNT

/datum/export/material/sell_object(obj/sold_item, datum/export_report/report, dry_run, apply_elastic)
	. = ..()
	if(!. || dry_run || sales_market != EXPORT_MARKET_STATION)
		return
	SSstock_market.on_material_sold(material_id, get_amount(sold_item))

/datum/export/material/metal
	unit_name = "сталь (листы)"
	material_id = MAT_METAL
	export_types = list(/obj/item/stack/sheet/metal, /obj/item/stack/ore/iron, /obj/item/stack/rods, /obj/item/coin/iron)

/datum/export/material/glass
	unit_name = "стекло (листы)"
	material_id = MAT_GLASS
	export_types = list(/obj/item/stack/sheet/glass, /obj/item/stack/ore/glass, /obj/item/shard)

/datum/export/material/silver
	unit_name = "серебро (листы)"
	material_id = MAT_SILVER
	export_types = list(/obj/item/stack/sheet/mineral/silver, /obj/item/stack/ore/silver, /obj/item/coin/silver)

/datum/export/material/gold
	unit_name = "золото (листы)"
	material_id = MAT_GOLD
	export_types = list(/obj/item/stack/sheet/mineral/gold, /obj/item/stack/ore/gold, /obj/item/coin/gold)

/datum/export/material/titanium
	unit_name = "титан (листы)"
	material_id = MAT_TITANIUM
	export_types = list(/obj/item/stack/sheet/mineral/titanium, /obj/item/stack/ore/titanium)

/datum/export/material/uranium
	unit_name = "уран (листы)"
	material_id = MAT_URANIUM
	export_types = list(/obj/item/stack/sheet/mineral/uranium, /obj/item/stack/ore/uranium, /obj/item/coin/uranium)

/datum/export/material/plasma
	unit_name = "твёрдая плазма (листы)"
	material_id = MAT_PLASMA
	export_types = list(/obj/item/stack/sheet/mineral/plasma, /obj/item/stack/ore/plasma, /obj/item/coin/plasma)

/datum/export/material/diamond
	unit_name = "алмазы (листы)"
	material_id = MAT_DIAMOND
	export_types = list(/obj/item/stack/sheet/mineral/diamond, /obj/item/stack/ore/diamond, /obj/item/coin/diamond)

/datum/export/material/bluespace
	unit_name = "блюспейс-кристаллы"
	material_id = MAT_BLUESPACE
	export_types = list(/obj/item/stack/sheet/bluespace_crystal, /obj/item/stack/ore/bluespace_crystal)

/datum/export/material/bananium
	unit_name = "бананиум (листы)"
	material_id = MAT_BANANIUM
	export_types = list(/obj/item/stack/sheet/mineral/bananium, /obj/item/stack/ore/bananium, /obj/item/coin/clown)

/datum/export/material/tranquillite
	unit_name = "транквилит (листы)"
	material_id = MAT_TRANQUILLITE
	export_types = list(/obj/item/stack/sheet/mineral/tranquillite, /obj/item/stack/ore/tranquillite, /obj/item/coin/mime)

/datum/export/material/plastic
	unit_name = "пластик (листы)"
	material_id = MAT_PLASTIC
	export_types = list(/obj/item/stack/sheet/plastic)

#undef ORE_EXPORT_MULTIPLIER
