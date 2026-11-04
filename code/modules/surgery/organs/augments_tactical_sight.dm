#define TACTICAL_SIGHT_MAX_RANGE 20
#define TACTICAL_COLOUR_CLEAR "#66FF9C"
#define TACTICAL_COLOUR_TARGET "#FF5A4F"
#define TACTICAL_COLOUR_BLOCKED "#FFC24F"
#define TACTICAL_COLOUR_TEXT "#BEF2FF"
#define TACTICAL_LINE_THICKNESS 1
#define TACTICAL_LINE_ALPHA 170
#define TACTICAL_BUCKLED_SPREAD 45
#define TACTICAL_RETICLE_BASE_RADIUS 12
#define TACTICAL_RETICLE_MIN_RADIUS 8
#define TACTICAL_RETICLE_MAX_RADIUS 64

/obj/item/organ/internal/cyberimp/eyes/tactical_sight
	name = "tactical sight implant"
	desc = "Глазной баллистический вычислитель. Пока в руке оружие, рисует на сетчатке траекторию выстрела до первой преграды и показывает остаток боезапаса. Включается и выключается по желанию."
	implant_color = "#FF5A4F"
	eye_colour = "#FF6A5F"
	slot = INTERNAL_ORGAN_EYE_TACTICAL
	origin_tech = "materials=4;programming=5;biotech=4;combat=4"
	aug_message = "В центре зрения на мгновение вспыхивает прицельная сетка..."
	actions_types = list(/datum/action/item_action/organ_action/augment/tactical_sight)
	var/datum/tactical_sight/active_sight

/datum/action/item_action/organ_action/augment/tactical_sight
	name = "Переключить тактический прицел"
	button_icon_state = "sight"

/obj/item/organ/internal/cyberimp/eyes/tactical_sight/get_ru_names()
	return alist(
		NOMINATIVE = "тактический прицел",
		GENITIVE = "тактического прицела",
		DATIVE = "тактическому прицелу",
		ACCUSATIVE = "тактический прицел",
		INSTRUMENTAL = "тактическим прицелом",
		PREPOSITIONAL = "тактическом прицеле",
	)

/obj/item/organ/internal/cyberimp/eyes/tactical_sight/Destroy()
	QDEL_NULL(active_sight)
	return ..()

/obj/item/organ/internal/cyberimp/eyes/tactical_sight/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	QDEL_NULL(active_sight)
	return ..()

/obj/item/organ/internal/cyberimp/eyes/tactical_sight/emp_act(severity)
	if(!owner || emp_proof || emp_shielded(severity))
		return
	. = ..()
	QDEL_NULL(active_sight)

/obj/item/organ/internal/cyberimp/eyes/tactical_sight/ui_action_click(mob/user, datum/action/action, leftclick)
	if(active_sight)
		QDEL_NULL(active_sight)
		owner.balloon_alert(owner, "прицел выключен")
		return
	if(!owner.client)
		return
	active_sight = new(src, owner)
	set_action_icon("sight_active")
	owner.balloon_alert(owner, "прицел включён")

/atom/movable/screen/tactical_ammo
	screen_loc = "CENTER-2,SOUTH+1"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = NO_CLIENT_COLOR|RESET_COLOR
	maptext_width = 160
	maptext_height = 16

/datum/tactical_sight
	var/obj/item/organ/internal/cyberimp/eyes/tactical_sight/implant
	var/mob/living/carbon/owner
	var/client/viewer
	var/turf/hovered_tile
	var/atom/movable/screen/tactical_ammo/ammo_display
	var/image/line_image
	var/image/end_image
	var/line_signature
	var/ammo_text

/datum/tactical_sight/New(obj/item/organ/internal/cyberimp/eyes/tactical_sight/implant, mob/living/carbon/owner)
	src.implant = implant
	src.owner = owner
	viewer = owner.client
	ammo_display = new
	viewer.screen += ammo_display
	RegisterSignal(owner, COMSIG_ATOM_MOUSE_ENTERED, PROC_REF(on_hover))
	RegisterSignal(owner, COMSIG_MOB_LOGOUT, PROC_REF(on_logout))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
	START_PROCESSING(SSfastprocess, src)

/datum/tactical_sight/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	clear_line()
	if(viewer)
		viewer.screen -= ammo_display
	QDEL_NULL(ammo_display)
	UnregisterSignal(owner, list(COMSIG_ATOM_MOUSE_ENTERED, COMSIG_MOB_LOGOUT, COMSIG_MOVABLE_MOVED))
	hovered_tile = null
	viewer = null
	owner = null
	implant.active_sight = null
	implant.set_action_icon("sight")
	implant = null
	return ..()

/datum/tactical_sight/proc/on_logout(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/tactical_sight/proc/on_hover(datum/source, atom/hovered)
	SIGNAL_HANDLER
	if(is_screen_atom(hovered))
		return
	hovered_tile = get_turf(hovered)
	refresh_sight()

/datum/tactical_sight/proc/on_owner_moved(datum/source)
	SIGNAL_HANDLER
	refresh_sight()

/datum/tactical_sight/process(seconds_per_tick)
	refresh_sight()

/datum/tactical_sight/proc/refresh_sight()
	var/obj/item/gun/held_gun = owner.get_active_hand()
	if(!istype(held_gun) || owner.stat != CONSCIOUS)
		clear_line()
		update_ammo(null)
		return
	update_ammo(held_gun)
	update_line(held_gun)

/datum/tactical_sight/proc/update_ammo(obj/item/gun/held_gun)
	var/new_text = held_gun ? get_ammo_text(held_gun) : null
	if(new_text == ammo_text)
		return
	ammo_text = new_text
	ammo_display.maptext = new_text ? MAPTEXT("<span style='color: [TACTICAL_COLOUR_TEXT]; text-align: center'>[new_text]</span>") : null

/datum/tactical_sight/proc/get_ammo_text(obj/item/gun/held_gun)
	if(is_projectilegun(held_gun))
		var/obj/item/gun/projectile/ballistic_gun = held_gun
		var/capacity = ballistic_gun.magazine?.max_ammo
		var/rounds = ballistic_gun.get_ammo(countchambered = TRUE, countempties = FALSE)
		return capacity ? "Патроны: [rounds] / [capacity]" : "Патроны: [rounds]"
	if(isenergygun(held_gun))
		var/obj/item/gun/energy/energy_gun = held_gun
		if(!energy_gun.cell)
			return "Заряд: нет батареи"
		var/shots = energy_gun.get_display_ammo_count()
		return isnull(shots) ? "Заряд: неизвестно" : "Выстрелов: [shots]"
	return "Боезапас: неизвестно"

/datum/tactical_sight/proc/update_line(obj/item/gun/held_gun)
	var/turf/start = get_turf(owner)
	if(!start || !hovered_tile || hovered_tile == start || hovered_tile.z != start.z)
		clear_line()
		return
	var/list/path = trace_path(start, held_gun.chambered?.BB)
	var/turf/end_tile = path[1]
	var/end_colour = path[2]
	var/end_x = (end_tile.x - start.x) * ICON_SIZE_X
	var/end_y = (end_tile.y - start.y) * ICON_SIZE_Y
	var/radius = get_reticle_radius(held_gun, get_dist(start, end_tile))
	var/signature = "[end_x],[end_y],[end_colour],[radius]"
	if(signature == line_signature)
		return
	line_signature = signature
	if(!line_image)
		line_image = make_sight_image('icons/effects/alphacolors.dmi', "white", TACTICAL_LINE_ALPHA)
		end_image = make_sight_image('icons/hud/tactical_sight.dmi', "reticle", 255)
		viewer.images += line_image
		viewer.images += end_image
	var/matrix/reticle_transform = matrix()
	reticle_transform.Scale(radius / TACTICAL_RETICLE_BASE_RADIUS)
	reticle_transform.Translate(end_x, end_y)
	line_image.transform = line_matrix(0, 0, end_x, end_y, TACTICAL_LINE_THICKNESS)
	line_image.color = end_colour
	end_image.transform = reticle_transform
	end_image.color = end_colour

/datum/tactical_sight/proc/get_reticle_radius(obj/item/gun/held_gun, distance)
	var/spread = held_gun.bonus_spread + (held_gun.chambered?.variance || 0) + owner.get_fracture_spread_bonus(owner.l_hand == held_gun)
	if(owner.buckled)
		spread += TACTICAL_BUCKLED_SPREAD
	return round(clamp(tan(spread / 2) * distance * ICON_SIZE_X, TACTICAL_RETICLE_MIN_RADIUS, TACTICAL_RETICLE_MAX_RADIUS))

/datum/tactical_sight/proc/trace_path(turf/start, obj/projectile/bullet)
	var/turf/previous = start
	var/flight_range = min(bullet?.range || TACTICAL_SIGHT_MAX_RANGE, TACTICAL_SIGHT_MAX_RANGE)
	var/steps = 0
	for(var/turf/tile as anything in get_line(start, hovered_tile) - start)
		steps++
		if(steps > flight_range)
			return list(previous, TACTICAL_COLOUR_BLOCKED)
		if(tile.density)
			return list(previous, TACTICAL_COLOUR_BLOCKED)
		for(var/atom/movable/thing as anything in tile)
			if(!thing.density || thing == owner)
				continue
			if(isliving(thing))
				return list(tile, TACTICAL_COLOUR_TARGET)
			if(!bullet || !thing.CanPass(bullet, get_dir(tile, previous)))
				return list(previous, TACTICAL_COLOUR_BLOCKED)
		previous = tile
	return list(previous, TACTICAL_COLOUR_CLEAR)

/datum/tactical_sight/proc/make_sight_image(icon_file, state, image_alpha)
	var/image/sight_image = image(icon_file, owner, state)
	SET_PLANE_EXPLICIT(sight_image, BALLOON_CHAT_PLANE, owner)
	sight_image.appearance_flags = RESET_ALPHA|RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|PIXEL_SCALE
	sight_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	sight_image.alpha = image_alpha
	return sight_image

/datum/tactical_sight/proc/clear_line()
	line_signature = null
	if(viewer)
		viewer.images -= line_image
		viewer.images -= end_image
	line_image = null
	end_image = null

#undef TACTICAL_SIGHT_MAX_RANGE
#undef TACTICAL_COLOUR_CLEAR
#undef TACTICAL_COLOUR_TARGET
#undef TACTICAL_COLOUR_BLOCKED
#undef TACTICAL_COLOUR_TEXT
#undef TACTICAL_LINE_THICKNESS
#undef TACTICAL_LINE_ALPHA
#undef TACTICAL_BUCKLED_SPREAD
#undef TACTICAL_RETICLE_BASE_RADIUS
#undef TACTICAL_RETICLE_MIN_RADIUS
#undef TACTICAL_RETICLE_MAX_RADIUS
