/**
 * Maximum pressure a canister can withstand is 9.2e13 kPa at a minimum of 2.7K which would contain a horrifying 4,098,150,709.4 moles.
 * We don't want players making that much credits so we limit the total amount earned to MAX_GAS_CREDITS
*/
/datum/export/gas_canister
	cost = CARGO_CRATE_VALUE * 0.05 //Base cost of canister. You get more for nice gases inside.
	unit_name = "газовые канистры"
	export_types = list(/obj/machinery/portable_atmospherics/canister)

/datum/export/gas_canister/get_base_cost(obj/machinery/portable_atmospherics/canister/canister)
	var/datum/gas_mixture/canister_mix = canister.return_obj_air()
	if(!canister_mix.total_moles())
		return 0

	var/static/list/gases_to_check = list(
		TLV_BZ = 1,
		TLV_NITRIUM = 1,
		TLV_HYPERNOBLIUM = 1,
		TLV_MIASMA = 1,
		TLV_TRITIUM = 1,
		TLV_PLUOXIUM = 1,
		TLV_FREON = 1,
		TLV_H2 = 1,
		TLV_HELIUM = 1,
		TLV_PROTO_NITRATE = 1,
		TLV_ZAUKER = 1,
		TLV_HEALIUM = 1,
		TLV_ANTINOBLIUM = 1,
		TLV_HALON = 1,
	)

	var/worth = cost
	for(var/gas_id, amount in canister_mix.get_interesting())
		if(!(gas_id in gases_to_check))
			continue
		worth += get_gas_value(gas_id, amount)
		if(worth > MAX_GAS_CREDITS)
			worth = MAX_GAS_CREDITS
			break

	return worth

/datum/export/gas_canister/proc/get_gas_value(gas_id, moles)

	return ROUND_UP(GLOB.gas_meta[gas_id][META_BASE_VALUE] * moles)

/datum/export/crate
	cost = CARGO_CRATE_REFUND
	k_elasticity = 0
	unit_name = "возвращённые ящики"
	export_types = list(/obj/structure/closet/crate)
	exclude_types = list(
		/obj/structure/closet/crate/large,
		/obj/structure/closet/crate/wooden,
		/obj/structure/closet/crate/necropolis,
	)

/datum/export/crate/large
	cost = CARGO_CRATE_REFUND * 0.3
	unit_name = "большие деревянные ящики"
	export_types = list(/obj/structure/closet/crate/large, /obj/structure/ore_box)
	exclude_types = list()

/datum/export/crate/wooden
	cost = CARGO_CRATE_REFUND * 0.75
	unit_name = "деревянные ящики"
	export_types = list(/obj/structure/closet/crate/wooden, /obj/structure/closet/coffin)
	exclude_types = list(/obj/structure/closet/coffin/vampire)

/datum/export/crate/cardboard
	cost = CARGO_CRATE_REFUND * 0.3
	unit_name = "картонные коробки"
	export_types = list(/obj/structure/closet/cardboard)
	exclude_types = list()

/datum/export/reagent_dispenser
	abstract_type = /datum/export/reagent_dispenser
	cost = CARGO_CRATE_VALUE * 0.2
	var/contents_cost = CARGO_CRATE_VALUE * 0.3

/datum/export/reagent_dispenser/get_base_cost(obj/structure/reagent_dispensers/dispenser)
	return ..() + round(contents_cost * (dispenser.reagents.total_volume / dispenser.reagents.maximum_volume))

/datum/export/reagent_dispenser/water
	unit_name = "баки с водой"
	export_types = list(/obj/structure/reagent_dispensers/watertank)
	contents_cost = CARGO_CRATE_VALUE * 0.15

/datum/export/reagent_dispenser/fuel
	unit_name = "топливные баки"
	export_types = list(/obj/structure/reagent_dispensers/fueltank)
	exclude_types = list(/obj/structure/reagent_dispensers/fueltank/chem)

/datum/export/reagent_dispenser/beer_keg
	unit_name = "пивные кеги"
	contents_cost = CARGO_CRATE_VALUE * 3.5
	export_types = list(/obj/structure/reagent_dispensers/beerkeg)
	exclude_types = list(/obj/structure/reagent_dispensers/beerkeg/nuke)

/datum/export/pipedispenser
	cost = CARGO_CRATE_VALUE * 2.5
	unit_name = "раздатчики труб"
	export_types = list(/obj/machinery/pipedispenser)

/datum/export/emitter
	cost = CARGO_CRATE_VALUE
	unit_name = "эмиттеры"
	export_types = list(/obj/machinery/power/emitter)

/datum/export/field_generator
	cost = CARGO_CRATE_VALUE * 1.25
	unit_name = "генераторы поля"
	export_types = list(/obj/machinery/field/generator)

/datum/export/supermatter
	cost = CARGO_CRATE_VALUE * 16
	unit_name = "осколки суперматерии"
	export_types = list(/obj/machinery/power/supermatter_crystal/shard)

/datum/export/shield_generator
	cost = CARGO_CRATE_VALUE * 0.35
	unit_name = "генераторы щитов"
	export_types = list(/obj/machinery/shieldgen, /obj/machinery/shieldwallgen)

/datum/export/portable_generator
	cost = CARGO_CRATE_VALUE * 1.5
	unit_name = "портативные генераторы"
	export_types = list(/obj/machinery/power/port_gen/pacman)

/datum/export/portable_atmospherics
	cost = CARGO_CRATE_VALUE * 0.75
	unit_name = "портативные насосы и скрубберы"
	export_types = list(/obj/machinery/portable_atmospherics/pump, /obj/machinery/portable_atmospherics/scrubber)

/datum/export/space_heater
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "обогреватели"
	export_types = list(/obj/machinery/space_heater)

/datum/export/iv
	cost = CARGO_CRATE_VALUE * 0.25
	unit_name = "капельницы"
	export_types = list(/obj/machinery/iv_drip)

/datum/export/barrier
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "барьеры службы безопасности"
	export_types = list(/obj/item/grenade/barrier, /obj/structure/barricade/security)
