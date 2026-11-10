GLOBAL_LIST_EMPTY(net_tamper_log)

/datum/component/net_tamper
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/expire_timer
	var/blink_timer

/datum/component/net_tamper/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	blink_timer = addtimer(CALLBACK(src, PROC_REF(blink)), NET_TAMPER_BLINK_INTERVAL, TIMER_LOOP|TIMER_STOPPABLE)
	refresh()
	blink()

/datum/component/net_tamper/InheritComponent(datum/component/new_comp, i_am_original)
	refresh()

/datum/component/net_tamper/Destroy(force)
	deltimer(expire_timer)
	deltimer(blink_timer)
	UnregisterSignal(parent, COMSIG_ATOM_EXAMINE)
	return ..()

/datum/component/net_tamper/proc/refresh()
	deltimer(expire_timer)
	expire_timer = QDEL_IN_STOPPABLE(src, NET_TAMPER_DURATION)
	var/area/zone = get_area(parent)
	if(zone)
		GLOB.net_tamper_log[zone] = world.time

/datum/component/net_tamper/proc/blink()
	var/atom/movable/machine = parent
	if(!isturf(machine.loc))
		return
	new /obj/effect/temp_visual/net_tamper(machine.loc, machine)
	playsound(machine, 'sound/machines/twobeep.ogg', 15, TRUE, SILENCED_SOUND_EXTRARANGE)

/datum/component/net_tamper/proc/on_examine(atom/movable/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Диагностические индикаторы тревожно мигают: недавно здесь кто-то копался через Сеть.")

/obj/effect/temp_visual/net_tamper
	icon = 'icons/effects/netrunning.dmi'
	icon_state = "tamper"
	duration = 0.8 SECONDS
	layer = ABOVE_ALL_MOB_LAYER
	randomdir = FALSE

/obj/effect/temp_visual/net_tamper/Initialize(mapload, atom/movable/machine)
	. = ..()
	pixel_x = machine.pixel_x
	pixel_y = machine.pixel_y
	update_appearance(UPDATE_OVERLAYS)

/obj/effect/temp_visual/net_tamper/update_overlays()
	. = ..()
	. += emissive_appearance(icon, icon_state, src)

/obj/machinery/power/apc/examine(mob/user)
	. = ..()
	var/last_tamper = GLOB.net_tamper_log[get_area(src)]
	if(last_tamper && world.time - last_tamper < NET_TAMPER_DURATION)
		. += span_warning("Журнал трафика сектора показывает подозрительную сетевую активность за последние минуты.")

/datum/element/net_severed

/datum/element/net_severed/Attach(datum/target)
	. = ..()
	if(!ishuman(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(target, COMSIG_MOB_LOGIN, PROC_REF(on_login))

/datum/element/net_severed/Detach(datum/source)
	UnregisterSignal(source, list(COMSIG_ATOM_EXAMINE, COMSIG_MOB_LOGIN))
	return ..()

/datum/element/net_severed/proc/on_examine(mob/living/carbon/human/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Нейропорт на виске мигает красным, а взгляд пуст: сознание осталось в Сети, и связь с ним оборвана.")

/datum/element/net_severed/proc/on_login(mob/living/carbon/human/source)
	SIGNAL_HANDLER
	source.RemoveElement(/datum/element/net_severed)
