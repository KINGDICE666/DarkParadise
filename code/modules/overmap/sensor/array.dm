/obj/machinery/sensor_array
	name = "overmap sensor array"
	desc = "Антенна сканера карты системы. Без консоли управления почти бесполезна."
	icon = 'icons/obj/machines/overmap.dmi'
	icon_state = "sensor_short"
	anchored = TRUE
	density = TRUE
	idle_power_usage = 250
	active_power_usage = 2000
	var/obj/overmap/entity/vessel
	var/sensor_kind = OVERMAP_SENSOR_KIND_LONG
	var/on = TRUE
	var/sensor_board

/obj/machinery/sensor_array/get_ru_names()
	return alist(
		NOMINATIVE = "массив сенсоров",
		GENITIVE = "массива сенсоров",
		DATIVE = "массиву сенсоров",
		ACCUSATIVE = "массив сенсоров",
		INSTRUMENTAL = "массивом сенсоров",
		PREPOSITIONAL = "массиве сенсоров",
	)

/obj/machinery/sensor_array/Initialize(mapload)
	. = ..()
	GLOB.sensor_arrays += src
	if(sensor_board)
		create_board_parts(sensor_board)
	if(SSovermap?.initialized)
		link_vessel()
	update_icon()

/obj/machinery/sensor_array/Destroy()
	GLOB.sensor_arrays -= src
	vessel?.unregister_sensor_array(src)
	vessel = null
	return ..()

/obj/machinery/sensor_array/proc/link_vessel()
	var/obj/overmap/entity/resolved = SSovermap?.resolve_vessel(src)
	if(!resolved)
		return
	if(vessel && vessel != resolved)
		vessel.unregister_sensor_array(src)
	resolved.register_sensor_array(src)
	update_icon()

/obj/machinery/sensor_array/proc/is_ready()
	return on && !(stat & (NOPOWER|BROKEN))

/obj/machinery/sensor_array/proc/update_sensor_power()
	if(vessel && sensor_kind == OVERMAP_SENSOR_KIND_LONG && vessel.long_sensors_on && is_ready())
		use_power = ACTIVE_POWER_USE
	else if(vessel && sensor_kind == OVERMAP_SENSOR_KIND_SHORT && vessel.short_sensors_on && is_ready())
		use_power = ACTIVE_POWER_USE
	else
		use_power = IDLE_POWER_USE
	update_icon()

/obj/machinery/sensor_array/power_change(forced = FALSE)
	. = ..()
	vessel?.refresh_sensor_displays()
	update_sensor_power()

/obj/machinery/sensor_array/screwdriver_act(mob/living/user, obj/item/tool)
	if(!sensor_board)
		return FALSE
	return default_deconstruction_screwdriver(user, "[icon_state]", "[icon_state]", tool)

/obj/machinery/sensor_array/crowbar_act(mob/living/user, obj/item/tool)
	if(!sensor_board)
		return FALSE
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/sensor_array/attack_hand(mob/user)
	if(..())
		return TRUE
	on = !on
	to_chat(user, span_notice("[src] [on ? "включён" : "выключен"]."))
	vessel?.refresh_sensor_displays()
	update_sensor_power()

/obj/machinery/sensor_array/long_range
	sensor_board = /obj/item/circuitboard/sensor_array_long
	name = "long-range sensor array"
	desc = "Антенна дальнего действия. Позволяет видеть массивные объекты в большом радиусе. Не допускает точное сканирование. Может выдать позицию в секторе."
	icon_state = "sensor_long_off"

/obj/machinery/sensor_array/long_range/update_icon_state()
	if(!is_ready())
		icon_state = "sensor_long_off"
	else if(vessel?.long_sensors_on)
		icon_state = "sensor_long_on"
	else
		icon_state = "sensor_long_ready"

/obj/machinery/sensor_array/short_range
	sensor_board = /obj/item/circuitboard/sensor_array_short
	name = "short-range sensor array"
	desc = "Антенна короткого действия. Сканирует объекты на ближней дистанции. Не раскрывает судно и позволяет сканировать ближайшие объекты."
	sensor_kind = OVERMAP_SENSOR_KIND_SHORT
	idle_power_usage = 150
/obj/machinery/sensor_array/short_range/pod
	sensor_board = null
	name = "pod short-range sensors"
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	density = FALSE
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/machinery/sensor_array/short_range/pod/Initialize(mapload)
	. = ..()
	stat &= ~NOPOWER

/obj/machinery/sensor_array/short_range/pod/powered(chan)
	return TRUE

/obj/machinery/sensor_array/short_range/pod/is_ready()
	return TRUE

/obj/machinery/sensor_array/short_range/pod/link_vessel()
	var/obj/spacepod/craft = loc
	if(!isspacepod(craft) || !craft.overmap_vessel)
		return
	if(vessel && vessel != craft.overmap_vessel)
		vessel.unregister_sensor_array(src)
	vessel = craft.overmap_vessel
	vessel.register_sensor_array(src)

/obj/item/circuitboard/sensor_array_long
	board_name = "Long-range sensor array"
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/sensor_array/long_range
	origin_tech = "programming=3;magnets=3"
	req_components = list(/obj/item/stock_parts/scanning_module = 2, /obj/item/stock_parts/capacitor = 1, /obj/item/stack/cable_coil = 5)

/obj/item/circuitboard/sensor_array_short
	board_name = "Short-range sensor array"
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/sensor_array/short_range
	origin_tech = "programming=2;magnets=2"
	req_components = list(/obj/item/stock_parts/scanning_module = 1, /obj/item/stock_parts/capacitor = 1, /obj/item/stack/cable_coil = 5)

/datum/design/sensor_array_long
	name = "Machine Board (Long-range Sensor Array)"
	desc = "Плата массива сенсоров дальнего действия."
	id = "sensor_array_long"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/sensor_array_long
	materials = list(MAT_GLASS = 1000)
	req_tech = list(RESEARCH_TREE_PROGRAMMING = 3, RESEARCH_TREE_MAGNETS = 3)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_ENGINEERING)

/datum/design/sensor_array_short
	name = "Machine Board (Short-range Sensor Array)"
	desc = "Плата массива сенсоров ближнего действия."
	id = "sensor_array_short"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/sensor_array_short
	materials = list(MAT_GLASS = 1000)
	req_tech = list(RESEARCH_TREE_PROGRAMMING = 2, RESEARCH_TREE_MAGNETS = 2)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_ENGINEERING)
