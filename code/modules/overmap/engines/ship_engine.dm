/obj/machinery/ship_engine
	name = "small ion engine"
	desc = "Компактный ионный двигатель. Толкает судно в любую сторону."
	icon = 'icons/turf/shuttle/misc.dmi'
	icon_state = "propulsion"
	anchored = TRUE
	appearance_flags = KEEP_TOGETHER
	density = TRUE
	opacity = TRUE
	resistance_flags = FIRE_PROOF
	max_integrity = 300
	use_power = NO_POWER_USE
	smoothing_groups = SMOOTH_GROUP_SHUTTLE_PARTS
	light_range = 2
	var/burn_light_range = 3
	var/burn_light_power = 2
	var/obj/overmap/entity/vessel
	var/on = TRUE
	var/thrust_limit = 1
	var/generated_thrust = OVERMAP_ENGINE_SMALL_THRUST
	var/active_pushes = NONE
	var/engine_board = /obj/item/circuitboard/ship_engine_ion
	var/firing = FALSE
	var/engine_size = 1
	var/burn_icon = 'icons/obj/machines/ship_engine.dmi'
	var/burn_state = "nozzle_burn"
	var/burn_sound_type = /datum/looping_sound/ship_engine/ion
	var/datum/looping_sound/burn_sound
	var/list/obj/structure/filler/fillers = list()
	var/overdrive = FALSE
	var/heat = 0
	var/overheated = FALSE
	var/next_exhaust_check = 0
	var/turning_burn = FALSE

/obj/machinery/ship_engine/get_ru_names()
	return alist(
		NOMINATIVE = "ионный двигатель корабля",
		GENITIVE = "ионного двигателя корабля",
		DATIVE = "ионному двигателю корабля",
		ACCUSATIVE = "ионный двигатель корабля",
		INSTRUMENTAL = "ионным двигателем корабля",
		PREPOSITIONAL = "ионном двигателе корабля",
	)

/obj/machinery/ship_engine/Initialize(mapload)
	. = ..()
	GLOB.ship_engines += src
	create_engine_parts()
	if(engine_size == 2)
		spawn_engine_fillers(list(EAST, NORTH, NORTHEAST))
	else if(engine_size == 3)
		spawn_engine_fillers(list(EAST, WEST, NORTH, SOUTH, SOUTHEAST, SOUTHWEST, NORTHEAST, NORTHWEST))
	if(SSovermap?.initialized)
		link_vessel()

/obj/machinery/ship_engine/Destroy()
	QDEL_LIST(fillers)
	QDEL_NULL(burn_sound)
	GLOB.ship_engines -= src
	vessel?.unregister_engine(src)
	vessel = null
	return ..()

/obj/machinery/ship_engine/CanAtmosPass(direction)
	return !density

/obj/machinery/ship_engine/shuttleRotate(rotation, params)
	setDir(angle2dir(rotation + dir2angle(dir)))

/obj/machinery/ship_engine/proc/link_vessel()
	var/obj/overmap/entity/resolved = SSovermap?.resolve_vessel(src)
	if(!resolved)
		return
	resolved.register_engine(src)

/obj/machinery/ship_engine/proc/can_burn()
	if(!on || overheated || (stat & BROKEN))
		return FALSE
	return fuel_available()

/obj/machinery/ship_engine/proc/get_thrust()
	if(!can_burn())
		return 0
	return generated_thrust * thrust_limit * overdrive_factor() * 4 * resource_fraction(OVERMAP_FLIGHT_TICK)

/obj/machinery/ship_engine/proc/apply_thrust(elapsed = 1 SECONDS)
	if(!can_burn())
		return 0
	var/thrust = get_thrust()
	if(!consume_fuel(elapsed * resource_fraction(elapsed)))
		return 0
	heat_engine(elapsed)
	burn_exhaust()
	return thrust

/obj/machinery/ship_engine/proc/toggle()
	on = !on
	update_icon(UPDATE_OVERLAYS)

/obj/machinery/ship_engine/proc/set_firing(new_firing, pushes = NONE)
	if(firing == new_firing && active_pushes == pushes)
		return
	var/turning = new_firing && vessel?.flight?.burn_turn
	if(turning && !turning_burn && isturf(loc))
		playsound(src, 'sound/machines/hiss.ogg', 20, TRUE, extrarange = -2)
	turning_burn = turning
	firing = new_firing
	active_pushes = pushes
	update_icon(UPDATE_OVERLAYS)
	if(!firing)
		set_light(src::light_range, src::light_power, src::light_color)
		burn_sound?.stop()
		return
	set_light(burn_light_range, burn_light_power, LIGHT_COLOR_BLUE)
	if(!isturf(loc))
		return
	if(!burn_sound)
		burn_sound = new burn_sound_type(src)
	burn_sound.start()

/obj/machinery/ship_engine/proc/get_status()
	if(stat & BROKEN)
		return "Повреждён"
	if(overheated)
		return "Перегрев, остывает"
	if(!on)
		return "Выключен"
	if(!fuel_available())
		return "Нет подачи плазмы"
	return "Готов"

/obj/machinery/ship_engine/update_overlays()
	. = ..()
	if(firing)
		for(var/push in GLOB.cardinal)
			if(!(active_pushes & push))
				continue
			. += exhaust_overlay(mutable_appearance(burn_icon, burn_state, appearance_flags = PIXEL_SCALE), REVERSE_DIR(push))
			. += exhaust_overlay(emissive_appearance(burn_icon, burn_state, src, appearance_flags = PIXEL_SCALE), REVERSE_DIR(push))
	if(icon != 'icons/obj/machines/ship_engine.dmi')
		return
	if(can_burn())
		. += mutable_appearance(icon, "nozzle_idle")

/obj/machinery/ship_engine/proc/exhaust_overlay(mutable_appearance/flame, exhaust_dir = dir)
	var/flame_scale = 1 + (engine_size - 1) / 2
	var/reach = (engine_size + flame_scale) * ICON_SIZE_X / 2
	flame.dir = exhaust_dir
	flame.pixel_w = (engine_size - 1) * ICON_SIZE_X / 2 + (!!(exhaust_dir & EAST) - !!(exhaust_dir & WEST)) * reach
	flame.pixel_z = (engine_size - 1) * ICON_SIZE_Y / 2 + (!!(exhaust_dir & NORTH) - !!(exhaust_dir & SOUTH)) * reach
	if(flame_scale != 1)
		flame.transform = matrix().Scale(flame_scale)
	return flame

/obj/machinery/ship_engine/proc/spawn_engine_fillers(list/dirs)
	for(var/direct in dirs)
		var/turf/spot = get_step(src, direct)
		if(!spot)
			continue
		var/obj/structure/filler/piece = new(spot)
		piece.parent = src
		fillers += piece

/obj/machinery/ship_engine/small

/obj/machinery/ship_engine/large
	name = "large ion engine"
	desc = "Тяжёлый ионный двигатель. Даёт большую тягу для самых больших судов."
	icon = 'icons/obj/2x2.dmi'
	icon_state = "large_engine"
	appearance_flags = LONG_GLIDE | KEEP_TOGETHER
	light_range = 3
	burn_light_range = 4
	generated_thrust = OVERMAP_ENGINE_LARGE_THRUST
	engine_size = 2
	engine_board = /obj/item/circuitboard/ship_engine_ion/large
	burn_sound_type = /datum/looping_sound/ship_engine/heavy

/obj/machinery/ship_engine/large/get_ru_names()
	return alist(
		NOMINATIVE = "большой ионный двигатель корабля",
		GENITIVE = "большого ионного двигателя корабля",
		DATIVE = "большому ионному двигателю корабля",
		ACCUSATIVE = "большой ионный двигатель корабля",
		INSTRUMENTAL = "большим ионным двигателем корабля",
		PREPOSITIONAL = "большом ионном двигателе корабля",
	)

/obj/machinery/ship_engine/huge
	name = "huge advanced engine"
	desc = "Гигантский блюспейс-двигатель. Сконструирован для передвижения самых огромных космических объектов."
	icon = 'icons/obj/3x3.dmi'
	icon_state = "huge_engine"
	pixel_x = -32
	pixel_y = -32
	appearance_flags = LONG_GLIDE | KEEP_TOGETHER
	light_range = 3
	burn_light_range = 5
	generated_thrust = OVERMAP_ENGINE_LARGE_THRUST
	engine_size = 3
	engine_board = null
	burn_sound_type = /datum/looping_sound/ship_engine/heavy

/obj/machinery/ship_engine/huge/get_ru_names()
	return alist(
		NOMINATIVE = "огромный продвинутый двигатель корабля",
		GENITIVE = "огромного продвинутого двигателя корабля",
		DATIVE = "огромному продвинутому двигателю корабля",
		ACCUSATIVE = "огромный продвинутый двигатель корабля",
		INSTRUMENTAL = "огромным продвинутым двигателем корабля",
		PREPOSITIONAL = "огромном продвинутом двигателе корабля",
	)

/obj/machinery/ship_engine/virtual
	name = "virtual overmap drive"
	desc = "Служебный двигатель автопилота."
	generated_thrust = 40
	density = FALSE
	opacity = FALSE
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	light_power = 0
	burn_light_power = 0
	engine_board = null
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/machinery/ship_engine/virtual/Initialize(mapload)
	. = ..()
	stat &= ~NOPOWER

/obj/machinery/ship_engine/virtual/powered(chan)
	return TRUE

/obj/machinery/ship_engine/virtual/link_vessel()
	return

/obj/machinery/ship_engine/virtual/can_burn()
	return on && !(stat & BROKEN)

/obj/machinery/ship_engine/proc/create_engine_parts()
	if(!engine_board)
		return
	component_parts = list()
	var/obj/item/circuitboard/board = new engine_board(src)
	component_parts += board
	for(var/part_type, count in board.req_components)
		if(ispath(part_type, /obj/item/stack))
			component_parts += new part_type(src, count)
		else
			for(var/index in 1 to count)
				component_parts += new part_type(src)
