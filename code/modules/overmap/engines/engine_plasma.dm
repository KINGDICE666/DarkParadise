#define PLASMA_ENGINE_SHEET_FUEL 20
#define PLASMA_ENGINE_ORE_FUEL 10
#define PLASMA_ENGINE_RECONNECT_DELAY (5 SECONDS)

/obj/machinery/ship_engine/plasma
	name = "small plasma engine"
	desc = "Малый плазменный двигатель. Работает на плазме из трубы, подключённой с тыльной стороны, или на листах и руде плазмы, загруженных во внутренний бак."
	icon = 'icons/obj/machines/ship_engine.dmi'
	icon_state = "nozzle"
	color = "#ffb677"
	opacity = FALSE
	generated_thrust = OVERMAP_ENGINE_SMALL_THRUST * 3
	var/fuel_rate = 1
	var/stored_fuel = 0
	var/max_stored_fuel = 200
	var/next_reconnect = 0
	var/obj/machinery/atmospherics/unary/ship_engine_feed/fuel_port
	engine_board = /obj/item/circuitboard/ship_engine_plasma
	burn_sound_type = /datum/looping_sound/ship_engine/plasma
	exhaust_kind = "plasma"
	exhaust_light_color = LIGHT_COLOR_ORANGE
	exhaust_particle_color = "#ffb070"

/obj/machinery/ship_engine/plasma/get_ru_names()
	return alist(
		NOMINATIVE = "плазменный двигатель корабля",
		GENITIVE = "плазменного двигателя корабля",
		DATIVE = "плазменному двигателю корабля",
		ACCUSATIVE = "плазменный двигатель корабля",
		INSTRUMENTAL = "плазменным двигателем корабля",
		PREPOSITIONAL = "плазменном двигателе корабля",
	)

/obj/machinery/ship_engine/plasma/Initialize(mapload)
	. = ..()
	fuel_port = new(get_turf(src), src)

/obj/machinery/ship_engine/plasma/Destroy()
	QDEL_NULL(fuel_port)
	return ..()

/obj/machinery/ship_engine/plasma/proc/piped_fuel()
	if(!fuel_port)
		return 0
	if(!fuel_port.node && world.time >= next_reconnect)
		next_reconnect = world.time + PLASMA_ENGINE_RECONNECT_DELAY
		fuel_port.connect_supply()
	if(!fuel_port.node)
		return 0
	return fuel_port.air_contents?.toxins() || 0

/obj/machinery/ship_engine/plasma/fuel_available()
	return stored_fuel > 0 || piped_fuel() > 0

/obj/machinery/ship_engine/plasma/resource_fraction(elapsed)
	var/cost = fuel_rate * thrust_limit * elapsed / (1 SECONDS)
	return clamp((piped_fuel() + stored_fuel) / max(cost, 0.001), 0, 1)

/obj/machinery/ship_engine/plasma/consume_fuel(elapsed)
	var/cost = fuel_rate * thrust_limit * elapsed / (1 SECONDS)
	var/from_pipe = min(piped_fuel(), cost)
	if(from_pipe > 0)
		fuel_port.air_contents.set_toxins(fuel_port.air_contents.toxins() - from_pipe)
		if(fuel_port.parent)
			fuel_port.parent.update = TRUE
	var/left = cost - from_pipe
	if(left <= 0)
		return TRUE
	if(stored_fuel < left)
		stored_fuel = 0
		return FALSE
	stored_fuel -= left
	return TRUE

/obj/machinery/ship_engine/plasma/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	var/per_unit
	if(istype(used, /obj/item/stack/sheet/mineral/plasma))
		per_unit = PLASMA_ENGINE_SHEET_FUEL
	else if(istype(used, /obj/item/stack/ore/plasma))
		per_unit = PLASMA_ENGINE_ORE_FUEL
	else
		return ..()
	var/obj/item/stack/fuel = used
	var/room = round((max_stored_fuel - stored_fuel) / per_unit)
	if(room <= 0)
		balloon_alert(user, "бак полон")
		return ITEM_INTERACT_BLOCKING
	var/amount = min(room, fuel.get_amount())
	if(!fuel.use(amount))
		return ITEM_INTERACT_BLOCKING
	stored_fuel += amount * per_unit
	balloon_alert(user, "бак: [round(stored_fuel)]/[max_stored_fuel]")
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/ship_engine/plasma/examine(mob/user)
	. = ..()
	. += span_notice("Плазма в трубе: [round(fuel_port?.node ? fuel_port.air_contents?.toxins() || 0 : 0, 0.01)] моль[fuel_port?.node ? "" : " (труба не подключена)"]. Подача трубы: [dir2text(REVERSE_DIR(dir))].")
	. += span_notice("Внутренний бак: [round(stored_fuel)]/[max_stored_fuel]. Загружайте листы или руду плазмы рукой. Расход: [fuel_rate] моль/с при полной тяге.")

/obj/machinery/ship_engine/plasma/large
	name = "large plasma engine"
	desc = "Большой плазменный двигатель. Трубная подача плазмы с тыльной стороны."
	icon = 'icons/obj/2x2.dmi'
	icon_state = "large_engine"
	engine_size = 2
	max_integrity = 800
	generated_thrust = OVERMAP_ENGINE_LARGE_THRUST * 3
	fuel_rate = 3
	max_stored_fuel = 600
	engine_board = /obj/item/circuitboard/ship_engine_plasma/large

/obj/machinery/ship_engine/plasma/large/get_ru_names()
	return alist(
		NOMINATIVE = "большой плазменный двигатель корабля",
		GENITIVE = "большого плазменного двигателя корабля",
		DATIVE = "большому плазменному двигателю корабля",
		ACCUSATIVE = "большой плазменный двигатель корабля",
		INSTRUMENTAL = "большим плазменным двигателем корабля",
		PREPOSITIONAL = "большом плазменном двигателе корабля",
	)

/obj/machinery/atmospherics/unary/ship_engine_feed
	name = "engine plasma inlet"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_HIDE
	use_power = NO_POWER_USE
	vent_movement = NONE
	var/obj/machinery/ship_engine/plasma/engine

/obj/machinery/atmospherics/unary/ship_engine_feed/Initialize(mapload, obj/machinery/ship_engine/plasma/engine)
	src.engine = engine
	dir = REVERSE_DIR(engine.dir)
	. = ..()
	if(SSair.initialized)
		connect_supply()

/obj/machinery/atmospherics/unary/ship_engine_feed/Destroy()
	if(engine?.fuel_port == src)
		engine.fuel_port = null
	engine = null
	return ..()

/obj/machinery/atmospherics/unary/ship_engine_feed/shuttleRotate(rotation, params)
	. = ..()
	initialize_directions = dir

/obj/machinery/atmospherics/unary/ship_engine_feed/proc/set_inlet_direction(new_direction)
	if(dir == new_direction)
		return
	if(node)
		node.disconnect(src)
	node = null
	nullifyPipenet(parent)
	setDir(new_direction)
	initialize_directions = dir
	connect_supply()

/obj/machinery/atmospherics/unary/ship_engine_feed/proc/connect_supply()
	atmos_init()
	if(node)
		node.atmos_init()
		node.build_network(TRUE)
		var/datum/pipeline/network = node.returnPipenet(src)
		if(network)
			network.addMember(src, node)
	build_network(TRUE)

#undef PLASMA_ENGINE_SHEET_FUEL
#undef PLASMA_ENGINE_ORE_FUEL
#undef PLASMA_ENGINE_RECONNECT_DELAY
