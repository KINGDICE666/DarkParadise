
/obj/item/chrono_eraser
	name = "Timestream Eradication Device"
	desc = "Плод запрещённых исследований хроно-блюспейса. Это устройство способно стереть существо из временного потока: его нет, никогда не было и никогда не будет."
	icon = 'icons/obj/chronos.dmi'
	icon_state = "chronobackpack"
	item_state = "backpack"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	slowdown = 1
	actions_types = list(/datum/action/item_action/equip_unequip_TED_Gun)
	var/obj/item/gun/energy/chrono_gun/projector
	var/list/erased_minds = list() //a collection of minds from the dead

/obj/item/chrono_eraser/get_ru_names()
	return alist(
		NOMINATIVE = "устройство T.E.D.",
		GENITIVE = "устройства T.E.D.",
		DATIVE = "устройству T.E.D.",
		ACCUSATIVE = "устройство T.E.D.",
		INSTRUMENTAL = "устройством T.E.D.",
		PREPOSITIONAL = "устройстве T.E.D.",
	)

/obj/item/chrono_eraser/proc/pass_mind(datum/mind/erased_mind)
	erased_minds += erased_mind

/obj/item/chrono_eraser/dropped(mob/user, slot, silent = FALSE)
	. = ..()
	QDEL_NULL(projector)

/obj/item/chrono_eraser/Destroy()
	QDEL_NULL(projector)
	return ..()

/obj/item/chrono_eraser/ui_action_click(mob/user, datum/action/action, leftclick)
	if(projector)
		QDEL_NULL(projector)
		playsound(user, 'sound/magic/blink.ogg', 30, TRUE, frequency = -1)
		return
	projector = new(user, src)
	if(!user.put_in_hands(projector))
		QDEL_NULL(projector)
		balloon_alert(user, "руки заняты!")
		return
	playsound(user, 'sound/magic/blink.ogg', 30, TRUE)

/obj/item/chrono_eraser/item_action_slot_check(slot, mob/user, datum/action/action)
	return slot & ITEM_SLOT_BACK

/obj/structure/chrono_field
	name = "eradication field"
	desc = "Аура энергии хроно-блюспейса."
	icon = 'icons/effects/effects.dmi'
	icon_state = "chronofield"
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	move_resist = INFINITY
	blend_mode = BLEND_ADD
	var/mob/living/captured
	var/datum/weakref/eraser_ref
	var/erase_started
	var/current_frame
	var/mutable_appearance/mob_underlay

/obj/structure/chrono_field/get_ru_names()
	return alist(
		NOMINATIVE = "поле стирания",
		GENITIVE = "поля стирания",
		DATIVE = "полю стирания",
		ACCUSATIVE = "поле стирания",
		INSTRUMENTAL = "полем стирания",
		PREPOSITIONAL = "поле стирания",
	)

/obj/structure/chrono_field/Initialize(mapload, mob/living/captured, obj/item/chrono_eraser/eraser)
	. = ..()
	if(!istype(captured))
		return INITIALIZE_HINT_QDEL
	src.captured = captured
	eraser_ref = WEAKREF(eraser)
	RegisterSignal(captured, COMSIG_QDELETING, PROC_REF(on_captured_deleted))
	captured.forceMove(src)
	captured.Paralyse(CHRONO_ERASE_TIME + 1 SECONDS)

	var/icon/mob_snapshot = getFlatIcon(captured)
	var/icon/cached_icon = new()
	for(var/i in 1 to CHRONO_FRAME_COUNT)
		var/icon/removing_frame = icon('icons/obj/chronos.dmi', "erasing", SOUTH, i)
		var/icon/mob_icon = icon(mob_snapshot)
		mob_icon.Blend(removing_frame, ICON_MULTIPLY)
		cached_icon.Insert(mob_icon, "frame[i]")
	mob_underlay = mutable_appearance(cached_icon, "frame1")
	set_frame(1)

	desc = "[initial(desc)] Внутри видно [captured.declent_ru(ACCUSATIVE)]."
	erase_started = world.time
	playsound(src, 'sound/magic/timeparadox2.ogg', 60, TRUE)
	START_PROCESSING(SSfastprocess, src)

/obj/structure/chrono_field/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	if(captured)
		UnregisterSignal(captured, COMSIG_QDELETING)
		captured = null
	for(var/atom/movable/thing as anything in contents)
		thing.forceMove(loc)
	mob_underlay = null
	return ..()

/obj/structure/chrono_field/proc/on_captured_deleted(datum/source)
	SIGNAL_HANDLER
	captured = null
	qdel(src)

/obj/structure/chrono_field/process(seconds_per_tick)
	if(captured.loc != src)
		qdel(src)
		return
	var/progress = (world.time - erase_started) / CHRONO_ERASE_TIME
	if(progress >= 1)
		erase()
		return
	set_frame(clamp(ceil(progress * CHRONO_FRAME_COUNT), 1, CHRONO_FRAME_COUNT))

/obj/structure/chrono_field/proc/set_frame(frame)
	if(frame == current_frame)
		return
	current_frame = frame
	mob_underlay.icon_state = "frame[frame]"
	underlays = list(mob_underlay)

/obj/structure/chrono_field/proc/erase()
	var/mob/living/victim = captured
	UnregisterSignal(victim, COMSIG_QDELETING)
	captured = null
	to_chat(victim, span_boldnotice("Когда последние частицы вашего существа стираются из времени, вы заново переживаете самое счастливое своё воспоминание. Вам хорошо..."))
	visible_message(span_danger("[DECLENT_RU_CAP(victim, NOMINATIVE)] исчеза[PLUR_ET_YUT(victim)], словно никогда и не существовал[GEND_A_O_I(victim)]."))
	var/mob/dead/observer/ghost = victim.ghostize()
	if(victim.mind)
		if(ghost)
			ghost.mind = null
		var/obj/item/chrono_eraser/eraser = eraser_ref?.resolve()
		eraser?.pass_mind(victim.mind)
	new /obj/effect/temp_visual/circle_wave/chrono(loc)
	playsound(src, 'sound/effects/phasein.ogg', 60, TRUE)
	qdel(victim)
	qdel(src)

/obj/structure/chrono_field/has_prints()
	return FALSE

/obj/structure/chrono_field/return_obj_air()
	//we always have nominal air and temperature
	RETURN_TYPE(/datum/gas_mixture)
	var/datum/gas_mixture/gas_mixture = new
	gas_mixture.set_oxygen(MOLES_O2STANDARD)
	gas_mixture.set_nitrogen(MOLES_N2STANDARD)
	gas_mixture.set_temperature(T20C)
	return gas_mixture

/obj/structure/chrono_field/Move(atom/newloc, direct = NONE, glide_size_override = 0, update_dir = TRUE)
	return FALSE

/obj/structure/chrono_field/singularity_act()
	return

/obj/structure/chrono_field/ex_act()
	return

/obj/structure/chrono_field/blob_act(obj/structure/blob/B)
	return

/obj/structure/holosign/barrier/atmos/chrono
	name = "temporal seal"
	desc = "Застывший во времени след стёртой стены. Пропускает людей и предметы, но не выпускает воздух."
	color = COLOR_CYAN
	max_integrity = 200
	resistance_flags = FIRE_PROOF | FREEZE_PROOF | ACID_PROOF | UNACIDABLE

/obj/structure/holosign/barrier/atmos/chrono/get_ru_names()
	return alist(
		NOMINATIVE = "временная печать",
		GENITIVE = "временной печати",
		DATIVE = "временной печати",
		ACCUSATIVE = "временную печать",
		INSTRUMENTAL = "временной печатью",
		PREPOSITIONAL = "временной печати",
	)

/obj/effect/temp_visual/circle_wave/chrono
	color = COLOR_CYAN
	duration = 0.6 SECONDS
