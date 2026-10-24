#define THRUSTER_OVERHANG 8

/obj/machinery/ship_engine
	name = "small engine"
	desc = "Компактный двигатель. Даёт небольшую тягу, которой достаточно для комфортного передвижения на малых судах."
	icon = 'icons/turf/shuttle/misc.dmi'
	icon_state = "propulsion"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	idle_power_usage = 500
	active_power_usage = 2000
	resistance_flags = INDESTRUCTIBLE
	smoothing_groups = SMOOTH_GROUP_SHUTTLE_PARTS
	light_range = 2
	var/burn_light_range = 3
	var/burn_light_power = 2
	var/obj/overmap/entity/vessel
	var/on = TRUE
	var/thrust_limit = 1
	var/generated_thrust = OVERMAP_ENGINE_SMALL_THRUST
	var/omnidirectional = FALSE
	var/firing = FALSE
	var/engine_size = 1
	var/burn_icon = 'icons/obj/machines/ship_engine.dmi'
	var/burn_state = "nozzle_burn"
	var/burn_sound_type = /datum/looping_sound/ship_engine
	var/datum/looping_sound/burn_sound
	var/list/obj/structure/filler/fillers = list()

/obj/machinery/ship_engine/get_ru_names()
	return alist(
		NOMINATIVE = "двигатель корабля",
		GENITIVE = "двигателя корабля",
		DATIVE = "двигателю корабля",
		ACCUSATIVE = "двигатель корабля",
		INSTRUMENTAL = "двигателем корабля",
		PREPOSITIONAL = "двигателе корабля",
	)

/obj/machinery/ship_engine/Initialize(mapload)
	. = ..()
	GLOB.ship_engines += src
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
	if(!on || (stat & (BROKEN|NOPOWER)))
		return FALSE
	return TRUE

/obj/machinery/ship_engine/proc/get_thrust()
	if(!can_burn())
		return 0
	return generated_thrust * thrust_limit

/obj/machinery/ship_engine/proc/apply_thrust()
	if(!can_burn())
		return 0
	if(use_power != NO_POWER_USE)
		use_power(active_power_usage)
	return get_thrust()

/obj/machinery/ship_engine/proc/toggle()
	on = !on
	update_icon(UPDATE_OVERLAYS)

/obj/machinery/ship_engine/proc/set_firing(new_firing)
	if(firing == new_firing)
		return
	firing = new_firing
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
	if(stat & NOPOWER)
		return "Нет питания"
	if(!on)
		return "Выключен"
	return "Готов"

/obj/machinery/ship_engine/update_overlays()
	. = ..()
	if(firing)
		. += exhaust_overlay(mutable_appearance(burn_icon, burn_state, appearance_flags = PIXEL_SCALE))
		. += exhaust_overlay(emissive_appearance(burn_icon, burn_state, src, appearance_flags = PIXEL_SCALE))
	if(icon != 'icons/obj/machines/ship_engine.dmi')
		return
	if(on && !(stat & (BROKEN|NOPOWER)))
		. += mutable_appearance(icon, "nozzle_idle")

/obj/machinery/ship_engine/proc/exhaust_overlay(mutable_appearance/flame)
	var/flame_scale = 1 + (engine_size - 1) / 2
	var/reach = (engine_size + flame_scale) * ICON_SIZE_X / 2
	flame.dir = dir
	flame.pixel_w = (engine_size - 1) * ICON_SIZE_X / 2 + (!!(dir & EAST) - !!(dir & WEST)) * reach
	flame.pixel_z = (engine_size - 1) * ICON_SIZE_Y / 2 + (!!(dir & NORTH) - !!(dir & SOUTH)) * reach
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

/obj/structure/filler/CanAtmosPass(direction)
	if(istype(parent, /obj/machinery/ship_engine))
		return FALSE
	return TRUE

/obj/machinery/ship_engine/small

/obj/machinery/ship_engine/large
	name = "large engine"
	desc = "Тяжёлый двигатель. Даёт большое количество тяги для перелётов на самых больших судах."
	icon = 'icons/obj/2x2.dmi'
	icon_state = "large_engine"
	appearance_flags = LONG_GLIDE
	light_range = 3
	burn_light_range = 4
	generated_thrust = OVERMAP_ENGINE_LARGE_THRUST
	idle_power_usage = 1500
	active_power_usage = 6000
	engine_size = 2

/obj/machinery/ship_engine/large/Initialize(mapload)
	. = ..()
	spawn_engine_fillers(list(EAST, NORTH, NORTHEAST))

/obj/machinery/ship_engine/large/get_ru_names()
	return alist(
		NOMINATIVE = "большой двигатель корабля",
		GENITIVE = "большого двигателя корабля",
		DATIVE = "большому двигателю корабля",
		ACCUSATIVE = "большой двигатель корабля",
		INSTRUMENTAL = "большим двигателем корабля",
		PREPOSITIONAL = "большом двигателе корабля",
	)

/obj/machinery/ship_engine/huge
	name = "huge engine"
	desc = "Гигантский блюспейс-двигатель. Сконструирован для передвижения самых огромных космических объектов."
	icon = 'icons/obj/3x3.dmi'
	icon_state = "huge_engine"
	pixel_x = -32
	pixel_y = -32
	appearance_flags = LONG_GLIDE
	light_range = 3
	burn_light_range = 5
	generated_thrust = OVERMAP_ENGINE_LARGE_THRUST
	idle_power_usage = 1500
	active_power_usage = 6000
	engine_size = 3

/obj/machinery/ship_engine/huge/Initialize(mapload)
	. = ..()
	spawn_engine_fillers(list(EAST, WEST, NORTH, SOUTH, SOUTHEAST, SOUTHWEST, NORTHEAST, NORTHWEST))

/obj/machinery/ship_engine/huge/get_ru_names()
	return alist(
		NOMINATIVE = "огромный двигатель корабля",
		GENITIVE = "огромного двигателя корабля",
		DATIVE = "огромному двигателю корабля",
		ACCUSATIVE = "огромный двигатель корабля",
		INSTRUMENTAL = "огромным двигателем корабля",
		PREPOSITIONAL = "огромном двигателе корабля",
	)

/obj/machinery/ship_engine/infinite
	name = "test infinite engine"
	desc = "Тестовый двигатель без расхода топлива и энергии. Всегда даёт тягу, пока включён."
	icon = 'icons/obj/machines/ship_engine.dmi'
	icon_state = "nozzle"
	opacity = FALSE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	generated_thrust = 80
	omnidirectional = TRUE

/obj/machinery/ship_engine/infinite/can_burn()
	return on && !(stat & BROKEN)

/obj/machinery/ship_engine/virtual
	name = "virtual overmap drive"
	desc = "Служебный двигатель автопилота."
	generated_thrust = 40
	omnidirectional = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	density = FALSE
	opacity = FALSE
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	light_power = 0
	burn_light_power = 0
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

/obj/machinery/ship_engine/thruster
	name = "maneuvering thruster"
	desc = "Маленькое сопло на внешней обшивке. Слабо толкает корабль в свою сторону и помогает ему поворачивать."
	icon = 'icons/obj/machines/ship_thruster.dmi'
	icon_state = "thruster"
	layer = ABOVE_WINDOW_LAYER
	density = FALSE
	opacity = FALSE
	smoothing_groups = null
	light_power = 0
	burn_light_power = 0
	idle_power_usage = 50
	active_power_usage = 400
	generated_thrust = OVERMAP_ENGINE_THRUSTER_THRUST
	burn_icon = 'icons/obj/machines/ship_thruster.dmi'
	burn_state = "thruster_burn"
	burn_sound_type = /datum/looping_sound/ship_engine/thruster

/obj/machinery/ship_engine/thruster/get_ru_names()
	return alist(
		NOMINATIVE = "маневровый двигатель",
		GENITIVE = "маневрового двигателя",
		DATIVE = "маневровому двигателю",
		ACCUSATIVE = "маневровый двигатель",
		INSTRUMENTAL = "маневровым двигателем",
		PREPOSITIONAL = "маневровом двигателе",
	)

/obj/machinery/ship_engine/thruster/Initialize(mapload)
	. = ..()
	stick_out()

/obj/machinery/ship_engine/thruster/setDir(newdir)
	. = ..()
	stick_out()

/obj/machinery/ship_engine/thruster/proc/stick_out()
	pixel_x = (!!(dir & EAST) - !!(dir & WEST)) * THRUSTER_OVERHANG
	pixel_y = (!!(dir & NORTH) - !!(dir & SOUTH)) * THRUSTER_OVERHANG

/datum/looping_sound/ship_engine
	start_sound = 'sound/machines/engine/engine_start.ogg'
	start_length = 0.3 SECONDS
	mid_sounds = list('sound/machines/engine/engine_mid1.ogg' = 1)
	mid_length = 0.3 SECONDS
	end_sound = 'sound/machines/engine/engine_end.ogg'
	volume = 25
	extra_range = 6
	pressure_affected = FALSE
	use_sound_tokens = TRUE

/datum/looping_sound/ship_engine/thruster
	volume = 12
	extra_range = 2

/obj/effect/spawner/overmap_test_kit
	name = "overmap test kit"
	icon = OVERMAP_ICON_FILE
	icon_state = "ship"

/obj/effect/spawner/overmap_test_kit/Initialize(mapload)
	. = ..()
	var/turf/here = get_turf(src)
	if(here)
		new /obj/machinery/computer/helm(here)
		new /obj/machinery/ship_engine/infinite(get_step(here, WEST) || here)
		new /obj/machinery/transponder(get_step(here, SOUTH) || here)
		new /obj/machinery/computer/sensors(get_step(here, NORTH) || here)
		new /obj/machinery/sensor_array/long_range(get_step(here, NORTHEAST) || here)
		new /obj/machinery/sensor_array/short_range(get_step(here, NORTHWEST) || here)
	return INITIALIZE_HINT_QDEL

#undef THRUSTER_OVERHANG
