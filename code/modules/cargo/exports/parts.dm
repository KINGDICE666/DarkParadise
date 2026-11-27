/datum/export/solar_assembly
	cost = CARGO_CRATE_VALUE * 0.025
	unit_name = "каркасы солнечных панелей"
	export_types = list(/obj/item/solar_assembly)

/datum/export/tracker_board
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "платы солнечных трекеров"
	export_types = list(/obj/item/tracker_electronics)

/datum/export/control_board
	cost = CARGO_CRATE_VALUE * 0.15
	unit_name = "платы консолей солнечных панелей"
	export_types = list(/obj/item/circuitboard/solar_control)

/datum/export/refill_canister
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "канистры пополнения торгоматов"
	export_types = list(/obj/item/vending_refill)

/datum/export/stock_part
	abstract_type = /datum/export/stock_part

/datum/export/stock_part/get_base_cost(obj/item/stock_parts/part)
	return cost * part.rating

/datum/export/stock_part/component
	cost = CARGO_CRATE_VALUE * 0.02
	unit_name = "компоненты машин"
	export_types = list(
		/obj/item/stock_parts/capacitor,
		/obj/item/stock_parts/scanning_module,
		/obj/item/stock_parts/manipulator,
		/obj/item/stock_parts/micro_laser,
		/obj/item/stock_parts/matter_bin,
	)

/datum/export/power_cell
	cost = CARGO_CRATE_VALUE * 0.05
	unit_name = "батареи"
	export_types = list(/obj/item/stock_parts/cell)
	exclude_types = list(/obj/item/stock_parts/cell/infinite, /obj/item/stock_parts/cell/high/slime)

/datum/export/power_cell/get_base_cost(obj/item/stock_parts/cell/cell)
	return round(cost * clamp(cell.maxcharge / 10000, 1, 8))
