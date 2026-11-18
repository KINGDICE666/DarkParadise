/obj/machinery/shipyard_loader
	name = "shipyard material loader"
	desc = "Приёмник материалов верфи. Принимает листы металла, стекла и плазмы для постройки кораблей."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "unloader"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/machinery/shipyard_loader/get_ru_names()
	return alist(
		NOMINATIVE = "загрузчик верфи",
		GENITIVE = "загрузчика верфи",
		DATIVE = "загрузчику верфи",
		ACCUSATIVE = "загрузчик верфи",
		INSTRUMENTAL = "загрузчиком верфи",
		PREPOSITIONAL = "загрузчике верфи",
	)

/obj/machinery/shipyard_loader/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/material_container, list(MAT_METAL, MAT_GLASS, MAT_PLASMA), SHIPYARD_LOADER_CAPACITY, TRUE, /obj/item/stack/sheet, null, CALLBACK(src, PROC_REF(on_material_insert)))

/obj/machinery/shipyard_loader/proc/on_material_insert(type_inserted, id_inserted, amount_inserted)
	playsound(src, 'sound/items/rped.ogg', 30, TRUE)
	flick("unloader", src)

/obj/machinery/shipyard_loader/proc/sheets(material_id)
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	return materials.amount2sheet(materials.amount(material_id))

/obj/machinery/shipyard_loader/proc/has_sheets(metal, glass, plasma)
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	return materials.has_materials(list(MAT_METAL = metal * MINERAL_MATERIAL_AMOUNT, MAT_GLASS = glass * MINERAL_MATERIAL_AMOUNT, MAT_PLASMA = plasma * MINERAL_MATERIAL_AMOUNT))

/obj/machinery/shipyard_loader/proc/add_sheets(metal, glass, plasma)
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	materials.insert_amount(metal * MINERAL_MATERIAL_AMOUNT, MAT_METAL)
	materials.insert_amount(glass * MINERAL_MATERIAL_AMOUNT, MAT_GLASS)
	materials.insert_amount(plasma * MINERAL_MATERIAL_AMOUNT, MAT_PLASMA)

/obj/machinery/shipyard_loader/proc/use_sheets(metal, glass, plasma)
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	materials.use_amount(list(MAT_METAL = metal * MINERAL_MATERIAL_AMOUNT, MAT_GLASS = glass * MINERAL_MATERIAL_AMOUNT, MAT_PLASMA = plasma * MINERAL_MATERIAL_AMOUNT))
