#define CHRONOSUIT_ACTIVATION_COOLDOWN (2 SECONDS)
#define CHRONOSUIT_DEACTIVATION_COOLDOWN (3 SECONDS)
#define CHRONOSUIT_PHASE_TIME (0.7 SECONDS)
#define CHRONOSUIT_DASH_COOLDOWN (8 SECONDS)
#define CHRONOSUIT_DASH_RANGE 5
#define CHRONOSUIT_DASH_STEP_DELAY (0.1 SECONDS)
#define CHRONOSUIT_DASH_HEIGHT 12
#define CHRONOSUIT_REPULSE_RANGE 2
#define CHRONOSUIT_REPULSE_THROW_RANGE 7
#define CHRONOSUIT_REPULSE_THROW_SPEED 2
#define CHRONOSUIT_REPULSE_KNOCKDOWN (2 SECONDS)

/obj/item/clothing/head/helmet/space/chronos
	name = "Chronosuit Helmet"
	desc = "Белый шлем с непрозрачным синим визором."
	icon_state = "chronohelmet"
	item_state = "chronohelmet"
	slowdown = 1
	armor = list(MELEE = 70, BULLET = 70, LASER = 70, ENERGY = 70, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/obj/item/clothing/suit/space/chronos/suit

/obj/item/clothing/head/helmet/space/chronos/get_ru_names()
	return alist(
		NOMINATIVE = "шлем хронокостюма",
		GENITIVE = "шлема хронокостюма",
		DATIVE = "шлему хронокостюма",
		ACCUSATIVE = "шлем хронокостюма",
		INSTRUMENTAL = "шлемом хронокостюма",
		PREPOSITIONAL = "шлеме хронокостюма",
	)

/obj/item/clothing/head/helmet/space/chronos/dropped(mob/user, slot, silent = FALSE)
	suit?.deactivate()
	return ..()

/obj/item/clothing/head/helmet/space/chronos/Destroy()
	suit?.deactivate()
	return ..()

/obj/item/clothing/suit/space/chronos
	name = "Chronosuit"
	desc = "Продвинутый скафандр с технологиями телепортации и защиты от временного сжатия."
	icon_state = "chronosuit"
	item_state = "chronosuit"
	actions_types = list(/datum/action/item_action/toggle, /datum/action/item_action/chrono_shield, /datum/action/item_action/chrono_dash)
	armor = list(MELEE = 70, BULLET = 70, LASER = 70, ENERGY = 70, BOMB = 50, BIO = 100, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/obj/item/clothing/head/helmet/space/chronos/helmet
	var/obj/effect/chronos_cam/camera
	var/obj/effect/chrono_phase/phase
	var/mob/living/carbon/human/wearer
	var/activated = FALSE
	var/static/list/dash_traits = list(TRAIT_MOVE_PHASING, TRAIT_IMMOBILIZED, TRAIT_IGNORE_ELEVATION)
	COOLDOWN_DECLARE(dash_cooldown)

/obj/item/clothing/suit/space/chronos/get_ru_names()
	return alist(
		NOMINATIVE = "хронокостюм",
		GENITIVE = "хронокостюма",
		DATIVE = "хронокостюму",
		ACCUSATIVE = "хронокостюм",
		INSTRUMENTAL = "хронокостюмом",
		PREPOSITIONAL = "хронокостюме",
	)

/obj/item/clothing/suit/space/chronos/item_action_slot_check(slot, mob/user, datum/action/action)
	return slot & ITEM_SLOT_CLOTH_OUTER

/obj/item/clothing/suit/space/chronos/ui_action_click(mob/user, datum/action/action, leftclick)
	if(istype(action, /datum/action/item_action/chrono_shield))
		toggle_shield(user)
		return
	if(istype(action, /datum/action/item_action/chrono_dash))
		dash(user)
		return
	if(cooldown > world.time || phase)
		balloon_alert(user, "системы перезагружаются!")
		return
	if(activated)
		deactivate()
	else
		activate(user)

/obj/item/clothing/suit/space/chronos/dropped(mob/living/user, slot, silent = FALSE)
	deactivate()
	user.remove_status_effect(/datum/status_effect/chrono_aura/shield)
	return ..()

/obj/item/clothing/suit/space/chronos/Destroy()
	deactivate()
	if(isliving(loc))
		end_dash(loc)
	return ..()

/obj/item/clothing/suit/space/chronos/emp_act(severity)
	. = ..()
	if(!ishuman(loc))
		return
	var/mob/living/carbon/human/user = loc
	user.remove_status_effect(/datum/status_effect/chrono_aura/shield)
	if(severity != EMP_HEAVY || !activated)
		return
	to_chat(user, span_userdanger("Обнаружен электромагнитный импульс, системы отключаются для сохранения целостности..."))
	deactivate()

/obj/item/clothing/suit/space/chronos/proc/new_camera()
	QDEL_NULL(camera)
	camera = new(get_turf(wearer), wearer)
	wearer.remote_control = camera

/obj/item/clothing/suit/space/chronos/proc/chronowalk()
	var/turf/from_turf = get_turf(wearer)
	if(phase || wearer.stat != CONSCIOUS || !from_turf)
		return
	wearer.ExtinguishMob()
	phase = new(from_turf, wearer)
	wearer.reset_perspective(camera)
	flick("chronophase", phase)
	playsound(from_turf, 'sound/magic/teleport_diss.ogg', 30, TRUE)
	addtimer(CALLBACK(src, PROC_REF(chronowalk_arrive)), CHRONOSUIT_PHASE_TIME)

/obj/item/clothing/suit/space/chronos/proc/chronowalk_arrive()
	if(!phase)
		return
	var/turf/to_turf = get_turf(camera)
	if(to_turf)
		phase.abstract_move(to_turf)
		flick("chronounphase", phase)
		playsound(to_turf, 'sound/magic/teleport_app.ogg', 30, TRUE)
	else
		flick("chronostuck", phase)
	addtimer(CALLBACK(src, PROC_REF(chronowalk_finish)), CHRONOSUIT_PHASE_TIME)

/obj/item/clothing/suit/space/chronos/proc/chronowalk_finish()
	QDEL_NULL(phase)
	wearer?.reset_perspective(camera)

/obj/item/clothing/suit/space/chronos/process(seconds_per_tick)
	if(wearer.wear_suit != src)
		deactivate()
		return
	if(wearer.remote_control != camera)
		new_camera()
		return
	if(!phase && get_turf(camera) != get_turf(wearer))
		chronowalk()

/obj/item/clothing/suit/space/chronos/proc/activate(mob/living/carbon/human/user)
	if(activated || user.wear_suit != src)
		return
	cooldown = world.time + CHRONOSUIT_ACTIVATION_COOLDOWN
	to_chat(user, "\nChronosuitMK4 login: root")
	to_chat(user, "Password:\n")
	to_chat(user, "root@ChronosuitMK4# chronowalk4 --start\n")
	if(!istype(user.head, /obj/item/clothing/head/helmet/space/chronos))
		to_chat(user, "\[ [span_red("fail")] \] Mounting /dev/helmet")
		to_chat(user, span_red("<b>FATAL: </b>Unable to locate /dev/helmet. <b>Aborting...</b>"))
		return
	to_chat(user, "\[ [span_green("ok")] \] Mounting /dev/helmet")
	helmet = user.head
	helmet.suit = src
	ADD_TRAIT(helmet, TRAIT_NODROP, CHRONOSUIT_TRAIT)
	ADD_TRAIT(src, TRAIT_NODROP, CHRONOSUIT_TRAIT)
	to_chat(user, "\[ [span_green("ok")] \] Starting brainwave scanner")
	to_chat(user, "\[ [span_green("ok")] \] Starting ui display driver")
	to_chat(user, "\[ [span_green("ok")] \] Initializing chronowalk4-view")
	wearer = user
	activated = TRUE
	new_camera()
	playsound(user, 'sound/effects/phasein.ogg', 40, TRUE)
	START_PROCESSING(SSfastprocess, src)

/obj/item/clothing/suit/space/chronos/proc/deactivate()
	if(!activated)
		return
	activated = FALSE
	STOP_PROCESSING(SSfastprocess, src)
	QDEL_NULL(phase)
	to_chat(wearer, "\nroot@ChronosuitMK4# chronowalk4 --stop\n")
	if(camera)
		to_chat(wearer, "\[ [span_orange("ok")] \] Sending TERM signal to chronowalk4-view")
		QDEL_NULL(camera)
	if(helmet)
		to_chat(wearer, "\[ [span_orange("ok")] \] Stopping ui display driver")
		to_chat(wearer, "\[ [span_orange("ok")] \] Stopping brainwave scanner")
		to_chat(wearer, "\[ [span_orange("ok")] \] Unmounting /dev/helmet")
		REMOVE_TRAIT(helmet, TRAIT_NODROP, CHRONOSUIT_TRAIT)
		helmet.suit = null
		helmet = null
	to_chat(wearer, "logout")
	REMOVE_TRAIT(src, TRAIT_NODROP, CHRONOSUIT_TRAIT)
	playsound(wearer, 'sound/effects/phasein.ogg', 40, TRUE, frequency = -1)
	cooldown = world.time + CHRONOSUIT_DEACTIVATION_COOLDOWN
	wearer = null

/obj/item/clothing/suit/space/chronos/proc/toggle_shield(mob/living/carbon/human/user)
	if(user.has_status_effect(/datum/status_effect/chrono_aura/shield))
		user.remove_status_effect(/datum/status_effect/chrono_aura/shield)
		return
	user.apply_status_effect(/datum/status_effect/chrono_aura/shield)

/obj/item/clothing/suit/space/chronos/proc/dash(mob/living/carbon/human/user)
	if(activated)
		balloon_alert(user, "недоступно в хронопотоке!")
		return
	if(!COOLDOWN_FINISHED(src, dash_cooldown))
		balloon_alert(user, "перезарядка!")
		return
	if(user.buckled || !isturf(user.loc))
		return
	var/list/path = list()
	var/landing_step = 0
	var/turf/next_turf = user.loc
	for(var/step in 1 to CHRONOSUIT_DASH_RANGE)
		next_turf = get_step(next_turf, user.dir)
		if(!next_turf)
			break
		path += next_turf
		if(!next_turf.is_blocked_turf(exclude_mobs = TRUE))
			landing_step = step
	if(!landing_step)
		balloon_alert(user, "некуда прыгнуть!")
		return
	path.Cut(landing_step + 1)
	COOLDOWN_START(src, dash_cooldown, CHRONOSUIT_DASH_COOLDOWN)
	user.stop_pulling()
	user.add_traits(dash_traits, CHRONOSUIT_TRAIT)
	user.add_offsets(CHRONOSUIT_TRAIT, z_add = CHRONOSUIT_DASH_HEIGHT)
	new /obj/effect/temp_visual/circle_wave/chrono(user.loc)
	playsound(user, 'sound/effects/whoosh.ogg', 50, TRUE)
	dash_step(user, path)

/obj/item/clothing/suit/space/chronos/proc/dash_step(mob/living/carbon/human/user, list/path)
	if(QDELETED(user))
		return
	if(!length(path))
		dash_landed(user)
		return
	var/turf/next_turf = popleft(path)
	new /obj/effect/temp_visual/decoy/fading/chrono_trail(user.loc, user)
	if(!user.Move(next_turf, get_dir(user, next_turf), DELAY_TO_GLIDE_SIZE(CHRONOSUIT_DASH_STEP_DELAY)))
		user.forceMove(next_turf)
	addtimer(CALLBACK(src, PROC_REF(dash_step), user, path), CHRONOSUIT_DASH_STEP_DELAY)

/obj/item/clothing/suit/space/chronos/proc/end_dash(mob/living/user)
	user.remove_traits(dash_traits, CHRONOSUIT_TRAIT)
	user.remove_offsets(CHRONOSUIT_TRAIT)

/obj/item/clothing/suit/space/chronos/proc/dash_landed(mob/living/carbon/human/user)
	end_dash(user)
	var/turf/landing_turf = get_turf(user)
	playsound(landing_turf, 'sound/magic/repulse.ogg', 60, TRUE)
	new /obj/effect/temp_visual/shockwave(landing_turf, CHRONOSUIT_REPULSE_RANGE)
	for(var/atom/movable/thing in orange(CHRONOSUIT_REPULSE_RANGE, landing_turf))
		if(thing == user || thing.anchored || thing.move_resist == INFINITY || iseffect(thing) || isprojectile(thing))
			continue
		if(!isliving(thing) && !isobj(thing))
			continue
		var/throw_dir = get_dir(landing_turf, thing) || pick(GLOB.alldirs)
		new /obj/effect/temp_visual/gravpush(get_turf(thing), throw_dir)
		if(isliving(thing))
			var/mob/living/victim = thing
			victim.Weaken(CHRONOSUIT_REPULSE_KNOCKDOWN)
			add_attack_logs(user, victim, "repulsed with [src]")
		thing.throw_at(get_edge_target_turf(thing, throw_dir), CHRONOSUIT_REPULSE_THROW_RANGE, CHRONOSUIT_REPULSE_THROW_SPEED, user)

/datum/status_effect/chrono_aura
	id = "chrono_aura"
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null
	var/aura_state
	var/aura_blend_mode = BLEND_DEFAULT
	var/aura_sound
	var/mutable_appearance/aura_overlay

/datum/status_effect/chrono_aura/on_apply()
	aura_overlay = mutable_appearance('icons/effects/effects.dmi', aura_state, MOB_LAYER + 0.01)
	aura_overlay.blend_mode = aura_blend_mode
	RegisterSignal(owner, COMSIG_HUMAN_REGENERATE_ICONS, PROC_REF(apply_aura_overlay))
	apply_aura_overlay()
	playsound(owner, aura_sound, 40, TRUE)
	return TRUE

/datum/status_effect/chrono_aura/on_remove()
	UnregisterSignal(owner, COMSIG_HUMAN_REGENERATE_ICONS)
	owner.cut_overlay(aura_overlay)
	aura_overlay = null

/datum/status_effect/chrono_aura/proc/apply_aura_overlay()
	SIGNAL_HANDLER
	owner.cut_overlay(aura_overlay)
	owner.add_overlay(aura_overlay)

/datum/status_effect/chrono_aura/shield
	id = "chrono_shield"
	aura_state = "shield-grey"
	aura_sound = 'sound/magic/charge.ogg'

/datum/status_effect/chrono_aura/shield/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_HUMAN_TRY_DEFLECT_BULLET, PROC_REF(deflect_projectile))

/datum/status_effect/chrono_aura/shield/on_remove()
	. = ..()
	UnregisterSignal(owner, COMSIG_HUMAN_TRY_DEFLECT_BULLET)
	playsound(owner, aura_sound, 40, TRUE, frequency = -1)

/datum/status_effect/chrono_aura/shield/proc/deflect_projectile(mob/living/carbon/human/source, obj/projectile/hitting_projectile, def_zone)
	SIGNAL_HANDLER
	if(hitting_projectile.reflectability == REFLECTABILITY_NEVER)
		return NONE
	source.visible_message(
		span_danger("Временной щит [source.declent_ru(GENITIVE)] отклоняет [hitting_projectile.declent_ru(ACCUSATIVE)]!"),
		span_userdanger("Ваш временной щит отклоняет [hitting_projectile.declent_ru(ACCUSATIVE)]!"),
	)
	playsound(source, pick('sound/effects/void_deflect1.ogg', 'sound/effects/void_deflect2.ogg', 'sound/effects/void_deflect3.ogg'), 60, TRUE)
	hitting_projectile.firer = source
	hitting_projectile.set_angle(rand(0, 360))
	return COMPONENT_BULLET_DEFLECTED

/obj/effect/chrono_phase
	name = "phasing"
	icon = 'icons/mob/mob.dmi'
	icon_state = "chronostuck"
	density = TRUE
	layer = FLY_LAYER

/obj/effect/chrono_phase/Initialize(mapload, mob/living/phaser)
	. = ..()
	if(!istype(phaser))
		return INITIALIZE_HINT_QDEL
	name = "phasing [phaser.name]"
	phaser.forceMove(src)

/obj/effect/chrono_phase/Destroy()
	for(var/atom/movable/thing as anything in contents)
		thing.forceMove(loc)
	return ..()

/obj/effect/chronos_cam
	name = "Chronosuit View"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/mob/holder

/obj/effect/chronos_cam/Initialize(mapload, mob/holder)
	. = ..()
	src.holder = holder

/obj/effect/chronos_cam/singularity_act()
	return

/obj/effect/chronos_cam/singularity_pull(atom/singularity, current_size)
	return

/obj/effect/chronos_cam/relaymove(mob/user, direction)
	if(!holder)
		qdel(src)
		return
	if(user != holder)
		return
	if(user.client?.eye != src)
		user.reset_perspective(src)
	var/turf/step = get_step(src, direction)
	if(step)
		abstract_move(step)

/obj/effect/chronos_cam/Destroy()
	if(holder)
		if(holder.remote_control == src)
			holder.remote_control = null
		if(holder.client?.eye == src)
			holder.reset_perspective()
		holder = null
	return ..()

#undef CHRONOSUIT_ACTIVATION_COOLDOWN
#undef CHRONOSUIT_DEACTIVATION_COOLDOWN
#undef CHRONOSUIT_PHASE_TIME
#undef CHRONOSUIT_DASH_COOLDOWN
#undef CHRONOSUIT_DASH_RANGE
#undef CHRONOSUIT_DASH_STEP_DELAY
#undef CHRONOSUIT_DASH_HEIGHT
#undef CHRONOSUIT_REPULSE_RANGE
#undef CHRONOSUIT_REPULSE_THROW_RANGE
#undef CHRONOSUIT_REPULSE_THROW_SPEED
#undef CHRONOSUIT_REPULSE_KNOCKDOWN
