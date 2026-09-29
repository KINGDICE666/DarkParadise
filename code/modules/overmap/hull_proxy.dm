#define HULL_PROXY_ORBIT_RADIUS 6
#define HULL_PROXY_ORBIT_PERIOD (30 SECONDS)
#define HULL_PROXY_ORBIT_STEPS 72
#define HULL_PROXY_STEP_DEGREES 3
#define HULL_PROXY_ROW_SPACING 12
#define HULL_PROXY_STEPPER_OFFSET 12
#define HULL_PROXY_SEAM_SCALE 1.03
#define HULL_PROXY_SHADING_SCALE 1.3
#define HULL_PROXY_LIGHT_COPY_INTERVAL (1 SECONDS)
#define HULL_PROXY_LIGHT_LAYER (LIGHTING_PRIMARY_LAYER + 1)
#define HULL_PROXY_SHADE_LAYER (FLOOR_EMISSIVE_START_LAYER - 0.01)

GLOBAL_LIST_EMPTY(hull_proxies)

/obj/effect/abstract/hull_proxy
	name = "hull proxy"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/obj/docking_port/mobile/source
	var/list/obj/effect/abstract/hull_proxy_tile/tiles = list()
	var/heading = 0

/obj/effect/abstract/hull_proxy_tile
	name = "hull proxy tile"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/base_x = 0
	var/base_y = 0
	var/turf/hull_turf
	var/obj/effect/abstract/hull_proxy_light/light_mask
	var/obj/effect/abstract/hull_proxy_shade/shade
	var/copied_light_state
	var/list/copied_light_color

/obj/effect/abstract/hull_proxy_light
	name = "hull proxy light"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = LIGHTING_PLANE
	layer = HULL_PROXY_LIGHT_LAYER
	appearance_flags = RESET_COLOR | RESET_ALPHA

/obj/effect/abstract/hull_proxy_shade
	name = "hull proxy shade"
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = EMISSIVE_PLANE
	layer = HULL_PROXY_SHADE_LAYER
	appearance_flags = RESET_COLOR | RESET_ALPHA

/obj/effect/abstract/hull_proxy/Initialize(mapload, obj/docking_port/mobile/source, heading, orbiting, stepping)
	. = ..()
	src.source = source
	src.heading = heading
	var/list/hull_turfs = list()
	for(var/turf/hull_turf as anything in source.return_turfs())
		if(source.shuttle_areas[get_area(hull_turf)])
			hull_turfs += hull_turf
	if(!length(hull_turfs))
		return INITIALIZE_HINT_QDEL
	var/min_x = world.maxx
	var/max_x = 1
	var/min_y = world.maxy
	var/max_y = 1
	for(var/turf/hull_turf as anything in hull_turfs)
		min_x = min(min_x, hull_turf.x)
		max_x = max(max_x, hull_turf.x)
		min_y = min(min_y, hull_turf.y)
		max_y = max(max_y, hull_turf.y)
	var/center_x = (min_x + max_x) / 2
	var/center_y = (min_y + max_y) / 2
	for(var/turf/hull_turf as anything in hull_turfs)
		var/obj/effect/abstract/hull_proxy_tile/tile = new(src)
		tile.base_x = (hull_turf.x - center_x) * ICON_SIZE_X
		tile.base_y = (hull_turf.y - center_y) * ICON_SIZE_Y
		tile.hull_turf = hull_turf
		tile.vis_contents += hull_turf
		tile.setup_shading(get_turf(src))
		tiles += tile
	vis_contents += tiles
	set_heading(heading)
	RegisterSignal(source, COMSIG_QDELETING, PROC_REF(on_source_deleted))
	GLOB.hull_proxies += src
	if(orbiting)
		start_orbit()
	if(stepping)
		addtimer(CALLBACK(src, PROC_REF(step_heading)), 1, TIMER_LOOP|TIMER_DELETE_ME)
	addtimer(CALLBACK(src, PROC_REF(refresh_light_copies)), HULL_PROXY_LIGHT_COPY_INTERVAL, TIMER_LOOP|TIMER_DELETE_ME)

/obj/effect/abstract/hull_proxy/Destroy()
	GLOB.hull_proxies -= src
	vis_contents.Cut()
	QDEL_LIST(tiles)
	source = null
	return ..()

/obj/effect/abstract/hull_proxy_tile/Destroy()
	vis_contents.Cut()
	QDEL_NULL(light_mask)
	QDEL_NULL(shade)
	hull_turf = null
	copied_light_color = null
	return ..()

/obj/effect/abstract/hull_proxy/proc/on_source_deleted()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/abstract/hull_proxy_tile/proc/setup_shading(turf/viewer_turf)
	var/matrix/shading_scale = matrix()
	shading_scale.Scale(HULL_PROXY_SHADING_SCALE)
	shade = new(src)
	SET_PLANE_EXPLICIT(shade, EMISSIVE_PLANE, viewer_turf)
	shade.color = GLOB.em_block_color
	shade.transform = shading_scale
	vis_contents += shade
	if(!hull_turf.lighting_object)
		return
	light_mask = new(src)
	SET_PLANE_EXPLICIT(light_mask, LIGHTING_PLANE, viewer_turf)
	light_mask.transform = shading_scale
	copy_light()
	vis_contents += light_mask

/obj/effect/abstract/hull_proxy_tile/proc/copy_light()
	var/atom/movable/lighting_object/source_light = hull_turf.lighting_object
	if(!light_mask || !source_light)
		return
	var/list/light_color = source_light.color
	if(copied_light_state == source_light.icon_state && copied_light_color ~= light_color)
		return
	copied_light_state = source_light.icon_state
	copied_light_color = light_color
	var/mutable_appearance/light_copy = new(source_light)
	light_copy.plane = light_mask.plane
	light_copy.layer = HULL_PROXY_LIGHT_LAYER
	light_copy.appearance_flags = RESET_COLOR | RESET_ALPHA
	light_copy.invisibility = 0
	light_copy.transform = light_mask.transform
	light_mask.appearance = light_copy

/obj/effect/abstract/hull_proxy/proc/refresh_light_copies()
	for(var/obj/effect/abstract/hull_proxy_tile/tile as anything in tiles)
		tile.copy_light()

/obj/effect/abstract/hull_proxy/proc/set_heading(new_heading, time)
	heading = new_heading
	for(var/obj/effect/abstract/hull_proxy_tile/tile as anything in tiles)
		if(time)
			animate(tile, pixel_x = tile.rotated_x(heading), pixel_y = tile.rotated_y(heading), transform = tile.rotated_transform(heading), time = time)
		else
			tile.pixel_x = tile.rotated_x(heading)
			tile.pixel_y = tile.rotated_y(heading)
			tile.transform = tile.rotated_transform(heading)

/obj/effect/abstract/hull_proxy/proc/step_heading()
	set_heading((heading + HULL_PROXY_STEP_DEGREES) % 360, 1)

/obj/effect/abstract/hull_proxy/proc/start_orbit()
	var/step_time = HULL_PROXY_ORBIT_PERIOD / HULL_PROXY_ORBIT_STEPS
	pixel_w = orbit_offset_x(0)
	pixel_z = orbit_offset_y(0)
	for(var/step in 1 to HULL_PROXY_ORBIT_STEPS)
		var/angle = step * 360 / HULL_PROXY_ORBIT_STEPS
		if(step == 1)
			animate(src, pixel_w = orbit_offset_x(angle), pixel_z = orbit_offset_y(angle), time = step_time, loop = -1)
		else
			animate(pixel_w = orbit_offset_x(angle), pixel_z = orbit_offset_y(angle), time = step_time)
	for(var/obj/effect/abstract/hull_proxy_tile/tile as anything in tiles)
		tile.start_spin(step_time)

/obj/effect/abstract/hull_proxy/proc/orbit_offset_x(angle)
	return HULL_PROXY_ORBIT_RADIUS * ICON_SIZE_X * cos(angle)

/obj/effect/abstract/hull_proxy/proc/orbit_offset_y(angle)
	return HULL_PROXY_ORBIT_RADIUS * ICON_SIZE_Y * sin(angle)

/obj/effect/abstract/hull_proxy_tile/proc/start_spin(step_time)
	for(var/step in 1 to HULL_PROXY_ORBIT_STEPS)
		var/angle = step * 360 / HULL_PROXY_ORBIT_STEPS
		if(step == 1)
			animate(src, pixel_x = rotated_x(angle), pixel_y = rotated_y(angle), transform = rotated_transform(angle), time = step_time, loop = -1)
		else
			animate(pixel_x = rotated_x(angle), pixel_y = rotated_y(angle), transform = rotated_transform(angle), time = step_time)

/obj/effect/abstract/hull_proxy_tile/proc/rotated_x(angle)
	return base_x * cos(angle) - base_y * sin(angle)

/obj/effect/abstract/hull_proxy_tile/proc/rotated_y(angle)
	return base_x * sin(angle) + base_y * cos(angle)

/obj/effect/abstract/hull_proxy_tile/proc/rotated_transform(angle)
	var/matrix/rotation = matrix()
	rotation.Scale(HULL_PROXY_SEAM_SCALE)
	rotation.Turn(-angle)
	return rotation

ADMIN_VERB(hull_proxy_test, R_DEBUG, "Hull Proxy Test", "Живые зеркала шаттла: неподвижные под углом, пошаговое вращение и орбита.", ADMIN_CATEGORY_DEBUG)
	if(length(GLOB.hull_proxies))
		QDEL_LIST(GLOB.hull_proxies)
		to_chat(user, span_notice("Зеркала шаттлов удалены."))
		return
	var/list/choices = list()
	for(var/obj/docking_port/mobile/port as anything in SSshuttle.mobile)
		choices["[port.name] ([port.id])"] = port
	var/choice = tgui_input_list(user.mob, "Какой шаттл отзеркалить?", "Hull Proxy Test", choices)
	if(!choice)
		return
	var/obj/docking_port/mobile/port = choices[choice]
	if(QDELETED(port))
		return
	if(tgui_alert(user.mob, "Погасить лампы на самом шаттле, чтобы было видно тень?", "Hull Proxy Test", list("Да", "Нет")) == "Да")
		for(var/turf/hull_turf as anything in port.return_turfs())
			if(!port.shuttle_areas[get_area(hull_turf)])
				continue
			for(var/obj/machinery/light/lamp in hull_turf)
				lamp.seton(FALSE)
	var/turf/center = get_turf(user.mob)
	var/start_time = REALTIMEOFDAY
	var/list/row_angles = list(0, 30, 45)
	for(var/index in 1 to length(row_angles))
		var/turf/row_spot = locate(center.x + index * HULL_PROXY_ROW_SPACING, center.y, center.z)
		if(row_spot)
			new /obj/effect/abstract/hull_proxy(row_spot, port, row_angles[index], FALSE, FALSE)
	var/turf/stepper_spot = locate(center.x, center.y + HULL_PROXY_STEPPER_OFFSET, center.z)
	if(stepper_spot)
		new /obj/effect/abstract/hull_proxy(stepper_spot, port, 0, FALSE, TRUE)
	new /obj/effect/abstract/hull_proxy(center, port, 0, TRUE, FALSE)
	to_chat(user, span_notice("Зеркала [choice]: [length(GLOB.hull_proxies)] шт., собраны за [(REALTIMEOFDAY - start_time) / 10] с. Восточнее — неподвижные под 0/30/45°, севернее — пошаговое вращение, вокруг вас — орбита."))
	BLACKBOX_LOG_ADMIN_VERB("Hull Proxy Test")

#undef HULL_PROXY_ORBIT_RADIUS
#undef HULL_PROXY_ORBIT_PERIOD
#undef HULL_PROXY_ORBIT_STEPS
#undef HULL_PROXY_STEP_DEGREES
#undef HULL_PROXY_ROW_SPACING
#undef HULL_PROXY_STEPPER_OFFSET
#undef HULL_PROXY_SEAM_SCALE
#undef HULL_PROXY_SHADING_SCALE
#undef HULL_PROXY_LIGHT_COPY_INTERVAL
#undef HULL_PROXY_LIGHT_LAYER
#undef HULL_PROXY_SHADE_LAYER
