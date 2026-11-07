/obj/item/circuitboard/ship_engine_ion
	board_name = "Small ion engine"
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/ship_engine
	req_components = list(/obj/item/stock_parts/capacitor = 2, /obj/item/stock_parts/micro_laser = 1, /obj/item/stack/cable_coil = 5)

/obj/item/circuitboard/ship_engine_ion/large
	board_name = "Large ion engine"
	build_path = /obj/machinery/ship_engine/large
	req_components = list(/obj/item/stock_parts/capacitor = 4, /obj/item/stock_parts/micro_laser = 2, /obj/item/stack/cable_coil = 10)

/obj/item/circuitboard/ship_engine_plasma
	board_name = "Small plasma engine"
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/ship_engine/plasma
	req_components = list(/obj/item/stock_parts/matter_bin = 2, /obj/item/stock_parts/micro_laser = 2, /obj/item/stack/cable_coil = 5)

/obj/item/circuitboard/ship_engine_plasma/large
	board_name = "Large plasma engine"
	build_path = /obj/machinery/ship_engine/plasma/large
	req_components = list(/obj/item/stock_parts/matter_bin = 4, /obj/item/stock_parts/micro_laser = 4, /obj/item/stack/cable_coil = 10)

/datum/design/ship_engine_ion
	id = "ship_engine_ion"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/ship_engine_ion
	materials = list(MAT_GLASS = 1000)
	req_tech = list(RESEARCH_TREE_PROGRAMMING = 2, RESEARCH_TREE_POWERSTORAGE = 2)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_ENGINEERING)

/datum/design/ship_engine_ion/large
	id = "ship_engine_ion_large"
	build_path = /obj/item/circuitboard/ship_engine_ion/large

/datum/design/ship_engine_plasma
	id = "ship_engine_plasma"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/ship_engine_plasma
	materials = list(MAT_GLASS = 1000)
	req_tech = list(RESEARCH_TREE_PROGRAMMING = 2, RESEARCH_TREE_PLASMA = 3)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_ENGINEERING)

/datum/design/ship_engine_plasma/large
	id = "ship_engine_plasma_large"
	build_path = /obj/item/circuitboard/ship_engine_plasma/large
