/particles/net_drip
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = "dot"
	color = NET_PARTICLE_COLOR
	width = 64
	height = 96
	count = 40
	spawning = 1.5
	lifespan = 1.2 SECONDS
	fade = 0.8 SECONDS
	position = generator(GEN_BOX, list(-9, -14), list(9, 12), UNIFORM_RAND)
	velocity = list(0, -0.6)
	gravity = list(0, -0.04)

/mob/living/basic/net_avatar
	name = "net avatar"
	real_name = "net avatar"
	desc = "Отпечаток сознания нетраннера в Сети: алый силуэт, стекающий вниз потоком данных."
	icon = 'icons/effects/netrunning.dmi'
	icon_state = "avatar"
	icon_living = "avatar"
	invisibility = INVISIBILITY_NETRUNNER
	see_invisible = SEE_INVISIBLE_NETRUNNER
	lighting_cutoff = LIGHTING_CUTOFF_HIGH
	density = FALSE
	pass_flags = PASSTABLE|PASSGRILLE|PASSMOB
	status_flags = NONE
	basic_mob_flags = DEL_ON_DEATH
	maxHealth = 100
	health = 100
	speed = 0
	melee_damage = 10
	melee_damage_type = BURN
	attack_verb_continuous = "рассекает кодом"
	attack_verb_simple = "рассекли кодом"
	attack_sound = 'sound/effects/sparks4.ogg'
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	unsuitable_atmos_damage = 0
	affects_by_temperature = FALSE
	speak_emote = list("транслирует")
	bubble_icon = "machine"
	var/list/body_overlays = list()
	var/area/home_area
	var/obj/item/radio/intercom/tapped_intercom
	var/tap_timer
	var/obj/effect/overlay/net_hologram/projection
	var/datum/net_breach/active_breach
	var/list/breached_areas = list()
	var/list/image/ice_images = list()
	var/trace = 0
	var/trace_updated = 0
	var/last_health = 0
	var/last_hurt = 0
	var/static/list/combat_hacks = list(
		NET_HACK_SHORT_CIRCUIT = list("name" = "Короткое замыкание", "cost" = 10, "upload" = 1 SECONDS, "black" = FALSE),
		NET_HACK_OVERHEAT = list("name" = "Перегрев", "cost" = 15, "upload" = 1.5 SECONDS, "black" = FALSE),
		NET_HACK_OPTICS = list("name" = "Сбой оптики", "cost" = 10, "upload" = 1 SECONDS, "black" = FALSE),
		NET_HACK_REBOOT = list("name" = "Перезагрузка системы", "cost" = 20, "upload" = 2 SECONDS, "black" = FALSE),
		NET_HACK_SYNAPSE = list("name" = "Синапсовый выжигатель", "cost" = 30, "upload" = 3 SECONDS, "black" = TRUE),
	)
	var/static/list/cyberware_hacks = list(
		NET_WARE_OPTICS = list("name" = "Погасить кибер-глаза", "cost" = 10, "upload" = 1.5 SECONDS, "requires" = /obj/item/organ/internal/cyberimp/eyes),
		NET_WARE_ARM = list("name" = "Отказ ручного импланта", "cost" = 15, "upload" = 2 SECONDS, "requires" = /obj/item/organ/internal/cyberimp/arm),
		NET_WARE_OVERHEAT = list("name" = "Перегрев импланта", "cost" = 15, "upload" = 2 SECONDS, "requires" = /obj/item/organ/internal/cyberimp),
		NET_WARE_SYNAPSE = list("name" = "Помехи в нейропорту", "cost" = 20, "upload" = 2.5 SECONDS, "requires" = /obj/item/organ/internal/cyberimp/brain),
		NET_WARE_NEURO = list("name" = "Обнулить нейроинтерфейс", "cost" = 20, "upload" = 2 SECONDS, "requires" = /obj/item/organ/internal/cyberimp/brain/neuro_interface),
	)
	COOLDOWN_DECLARE(conduit_cooldown)
	COOLDOWN_DECLARE(ice_notice)

/mob/living/basic/net_avatar/Initialize(mapload)
	. = ..()
	appearance_flags |= NO_CLIENT_COLOR|KEEP_TOGETHER
	ADD_TRAIT(src, TRAIT_MOVE_FLYING, NETRUNNING_TRAIT)
	particles = new /particles/net_drip
	add_filter("net_tint", 1, color_matrix_filter(MATRIX_NET_AVATAR))
	add_filter("net_glow", 2, outline_filter(1, NET_AVATAR_GLOW))
	add_filter("net_glitch", 3, wave_filter(x = 1, size = 1))
	animate(get_filter("net_glitch"), offset = 32, time = 4 SECONDS, loop = -1)
	RegisterSignal(src, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_pre_move))
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/mob/living/basic/net_avatar/Destroy()
	QDEL_NULL(active_breach)
	stop_tap()
	stop_projection()
	breached_areas.Cut()
	ice_images.Cut()
	QDEL_NULL(particles)
	body_overlays.Cut()
	return ..()

/mob/living/basic/net_avatar/get_ru_names()
	return alist(
		NOMINATIVE = "аватар Сети",
		GENITIVE = "аватара Сети",
		DATIVE = "аватару Сети",
		ACCUSATIVE = "аватара Сети",
		INSTRUMENTAL = "аватаром Сети",
		PREPOSITIONAL = "аватаре Сети",
	)

/mob/living/basic/net_avatar/Login()
	. = ..()
	if(!client)
		return
	GLOB.net_vision.show_to(client)
	overlay_fullscreen(NET_GRID_SCREEN, /atom/movable/screen/fullscreen/net_grid)
	update_client_colour(0)
	refresh_ice()

/mob/living/basic/net_avatar/Logout()
	if(canon_client)
		GLOB.net_vision.hide_from(canon_client)
		canon_client.colour_transition(null, 0)
		canon_client.images -= ice_images
	clear_fullscreen(NET_GRID_SCREEN, FALSE)
	return ..()

/mob/living/basic/net_avatar/Life(delta_time, times_fired)
	. = ..()
	update_trace_alert()
	defragment()

/mob/living/basic/net_avatar/get_screen_colour()
	return MATRIX_NET_VISION

/mob/living/basic/net_avatar/update_overlays()
	. = ..()
	. += body_overlays

/mob/living/basic/net_avatar/proc/copy_body(mob/living/carbon/human/body)
	name = body.real_name
	real_name = body.real_name
	gender = body.gender
	copy_languages(body, LANGUAGE_ATOM)
	icon = null
	body_overlays = body.overlays.Copy()
	var/mutable_appearance/smear = new
	smear.overlays = body_overlays
	smear.transform = matrix(1, 0, 0, 0, 1.35, -6)
	smear.alpha = 90
	smear.layer = -100
	smear.filters = motion_blur_filter(0, 3)
	body_overlays.Insert(1, smear)
	update_appearance(UPDATE_OVERLAYS)

/mob/living/basic/net_avatar/send_speech(message, message_range = 6, obj/source = src, bubble_type = bubble_icon, list/spans, datum/language/message_language = null, list/message_mods = list(), forced = null)
	var/list/bubble_recipients = list()
	for(var/mob/listener in get_hearers_in_view(message_range, source))
		if(!isnetavatar(listener) && !isobserver(listener))
			continue
		if(!(listener.Hear(src, message_language, message, null, null, null, spans, message_mods, message_range) & HEAR_HEARD))
			continue
		if(listener.client)
			bubble_recipients += listener.client
	if(length(bubble_recipients))
		speech_bubble("[bubble_type][say_test(message)]", src, bubble_recipients)
	projection?.atom_say(message)

/mob/living/basic/net_avatar/Hear(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, list/spans, list/message_mods = list(), message_range = 0)
	if(!isnetavatar(speaker))
		return NONE
	return ..()

/mob/living/basic/net_avatar/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	if(!isnetavatar(Proj.firer))
		return -1
	return ..()

/mob/living/basic/net_avatar/ex_act(severity, target, origin)
	return

/mob/living/basic/net_avatar/fire_act(exposed_temperature, exposed_volume)
	return

/mob/living/basic/net_avatar/emp_act(severity)
	adjustFireLoss(NET_EMP_DAMAGE / severity)
	to_chat(src, span_userdanger("Электромагнитный импульс рвёт поток данных!"))

/mob/living/basic/net_avatar/death(gibbed)
	new /obj/effect/temp_visual/net_dissolve(loc, src)
	return ..()

/mob/living/basic/net_avatar/OnUnarmedAttack(atom/target, proximity_flag, list/modifiers)
	if(isnetavatar(target) && !LAZYACCESS(modifiers, RIGHT_CLICK))
		return melee_attack(target)
	net_interact(target, modifiers)

/mob/living/basic/net_avatar/RangedAttack(atom/target, list/modifiers)
	net_interact(target, modifiers)

/mob/living/basic/net_avatar/Bump(atom/bumped)
	if(is_net_door(bumped))
		INVOKE_ASYNC(src, PROC_REF(net_toggle_door), bumped)

/mob/living/basic/net_avatar/start_pulling(atom/movable/pulled_atom, state, force = pull_force, supress_message = FALSE)
	return FALSE

/mob/living/basic/net_avatar/emote(emote_key, type_override = null, message = null, intentional = FALSE, force_silence = FALSE, ignore_cooldowns = FALSE)
	return FALSE

/mob/living/basic/net_avatar/add_splatter_floor(turf/splatter_turf, small_drip, shift_x, shift_y, amt)
	return

/mob/living/basic/net_avatar/get_access()
	var/datum/component/net_connection/connection = GetComponent(/datum/component/net_connection)
	return connection?.body?.get_access() || list()

/mob/living/basic/net_avatar/default_can_use_topic(src_object)
	. = shared_ui_interaction(src_object)
	if(. < UI_INTERACTIVE)
		return
	if(ismovable(src_object) && can_reach_node(src_object) && !is_ice_blocked(get_area(src_object)))
		return UI_INTERACTIVE
	return UI_CLOSE

/atom/movable/screen/fullscreen/net_grid
	icon = 'icons/effects/netrunning.dmi'
	icon_state = "net_grid"
	screen_loc = "WEST,SOUTH to EAST,NORTH"

/obj/effect/temp_visual/net_dissolve
	randomdir = FALSE

/obj/effect/temp_visual/net_dissolve/Initialize(mapload, mob/living/basic/net_avatar/avatar)
	. = ..()
	appearance = avatar.appearance
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	animate(src, alpha = 0, transform = matrix(1.4, 0, 0, 0, 0.1, -12), time = duration, easing = QUAD_EASING|EASE_IN)

/obj/effect/temp_visual/net_glitch
	icon = 'icons/effects/netrunning.dmi'
	icon_state = "glitch"
	duration = 0.6 SECONDS
	layer = ABOVE_ALL_MOB_LAYER
	randomdir = FALSE
