#define TRANSIT_TUBES_PER_TURF 2

/obj/structure/c_transit_tube
	name = "unattached transit tube"
	desc = "Неприкреплённый сегмент транзитной трубы."
	icon = 'icons/obj/pipes_and_stuff/not_atmos/transit_tube.dmi'
	icon_state = "straight"
	layer = LOW_ITEM_LAYER
	var/flipped = FALSE
	var/build_type = /obj/structure/transit_tube
	var/flipped_build_type

/obj/structure/c_transit_tube/get_ru_names()
	return alist(
		NOMINATIVE = "неприкреплённая транзитная труба",
		GENITIVE = "неприкреплённой транзитной трубы",
		DATIVE = "неприкреплённой транзитной трубе",
		ACCUSATIVE = "неприкреплённую транзитную трубу",
		INSTRUMENTAL = "неприкреплённой транзитной трубой",
		PREPOSITIONAL = "неприкреплённой транзитной трубе",
	)

/obj/structure/c_transit_tube/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/simple_rotation)

/obj/structure/c_transit_tube/proc/can_wrench_in_loc(mob/user)
	var/existing_tubes = 0
	for(var/obj/structure/transit_tube/tube in get_turf(src))
		existing_tubes++
		if(existing_tubes >= TRANSIT_TUBES_PER_TURF)
			to_chat(user, span_warning("Сюда больше не поместится транзитных труб!"))
			return FALSE
	return TRUE

/obj/structure/c_transit_tube/proc/rotate()
	setDir(turn(dir, ROTATION_CLOCKWISE))

/obj/structure/c_transit_tube/proc/flip()
	if(!flipped_build_type)
		setDir(turn(dir, ROTATION_FLIP))
		return
	var/old_build_type = build_type
	build_type = flipped_build_type
	flipped_build_type = old_build_type
	flipped = !flipped
	icon_state = "[base_icon_state][flipped]"

/obj/structure/c_transit_tube/wrench_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!isturf(loc) || !can_wrench_in_loc(user))
		return
	to_chat(user, span_notice("Вы начинаете прикреплять [declent_ru(ACCUSATIVE)]..."))
	if(!I.use_tool(src, user, TRANSIT_TUBE_WRENCH_TIME, volume = I.tool_volume, extra_checks = CALLBACK(src, PROC_REF(can_wrench_in_loc), user)))
		return
	to_chat(user, span_notice("Вы прикрепляете [declent_ru(ACCUSATIVE)]."))
	var/obj/structure/transit_tube/tube = new build_type(loc, dir)
	transfer_fingerprints_to(tube)
	qdel(src)

/obj/structure/c_transit_tube/rpd_act(mob/user, obj/item/rpd/our_rpd, mode)
	. = TRUE
	switch(mode)
		if(RPD_ROTATE_MODE)
			rotate()
		if(RPD_FLIP_MODE)
			flip()
		if(RPD_DELETE_MODE)
			our_rpd.delete_single_pipe(user, src)
		else
			return ..()

/obj/structure/c_transit_tube/station
	name = "unattached through station"
	icon = 'icons/obj/pipes_and_stuff/not_atmos/transit_tube_station.dmi'
	icon_state = "closed_station0"
	base_icon_state = "closed_station"
	build_type = /obj/structure/transit_tube/station
	flipped_build_type = /obj/structure/transit_tube/station/flipped

/obj/structure/c_transit_tube/station/get_ru_names()
	return alist(
		NOMINATIVE = "неприкреплённая транзитная станция",
		GENITIVE = "неприкреплённой транзитной станции",
		DATIVE = "неприкреплённой транзитной станции",
		ACCUSATIVE = "неприкреплённую транзитную станцию",
		INSTRUMENTAL = "неприкреплённой транзитной станцией",
		PREPOSITIONAL = "неприкреплённой транзитной станции",
	)

/obj/structure/c_transit_tube/station/flipped
	icon_state = "closed_station1"
	flipped = TRUE
	build_type = /obj/structure/transit_tube/station/flipped
	flipped_build_type = /obj/structure/transit_tube/station

/obj/structure/c_transit_tube/station/reverse
	name = "unattached terminus station"
	icon_state = "closed_terminus0"
	base_icon_state = "closed_terminus"
	build_type = /obj/structure/transit_tube/station/reverse
	flipped_build_type = /obj/structure/transit_tube/station/reverse/flipped

/obj/structure/c_transit_tube/station/reverse/flipped
	icon_state = "closed_terminus1"
	flipped = TRUE
	build_type = /obj/structure/transit_tube/station/reverse/flipped
	flipped_build_type = /obj/structure/transit_tube/station/reverse

/obj/structure/c_transit_tube/station/dispenser
	name = "unattached dispenser station"
	icon_state = "open_dispenser0"
	base_icon_state = "open_dispenser"
	build_type = /obj/structure/transit_tube/station/dispenser
	flipped_build_type = /obj/structure/transit_tube/station/dispenser/flipped

/obj/structure/c_transit_tube/station/dispenser/flipped
	icon_state = "open_dispenser1"
	flipped = TRUE
	build_type = /obj/structure/transit_tube/station/dispenser/flipped
	flipped_build_type = /obj/structure/transit_tube/station/dispenser

/obj/structure/c_transit_tube/station/dispenser/reverse
	name = "unattached terminus dispenser station"
	icon_state = "open_terminusdispenser0"
	base_icon_state = "open_terminusdispenser"
	build_type = /obj/structure/transit_tube/station/dispenser/reverse
	flipped_build_type = /obj/structure/transit_tube/station/dispenser/reverse/flipped

/obj/structure/c_transit_tube/station/dispenser/reverse/flipped
	icon_state = "open_terminusdispenser1"
	flipped = TRUE
	build_type = /obj/structure/transit_tube/station/dispenser/reverse/flipped
	flipped_build_type = /obj/structure/transit_tube/station/dispenser/reverse

/obj/structure/c_transit_tube/crossing
	icon_state = "crossing"
	build_type = /obj/structure/transit_tube/crossing

/obj/structure/c_transit_tube/diagonal
	icon_state = "diagonal"
	build_type = /obj/structure/transit_tube/diagonal

/obj/structure/c_transit_tube/diagonal/crossing
	icon_state = "diagonal_crossing"
	build_type = /obj/structure/transit_tube/diagonal/crossing

/obj/structure/c_transit_tube/curved
	icon_state = "curved0"
	base_icon_state = "curved"
	build_type = /obj/structure/transit_tube/curved
	flipped_build_type = /obj/structure/transit_tube/curved/flipped

/obj/structure/c_transit_tube/curved/flipped
	icon_state = "curved1"
	flipped = TRUE
	build_type = /obj/structure/transit_tube/curved/flipped
	flipped_build_type = /obj/structure/transit_tube/curved

/obj/structure/c_transit_tube/junction
	icon_state = "junction0"
	base_icon_state = "junction"
	build_type = /obj/structure/transit_tube/junction
	flipped_build_type = /obj/structure/transit_tube/junction/flipped

/obj/structure/c_transit_tube/junction/flipped
	icon_state = "junction1"
	flipped = TRUE
	build_type = /obj/structure/transit_tube/junction/flipped
	flipped_build_type = /obj/structure/transit_tube/junction

/obj/structure/c_transit_tube_pod
	name = "unattached transit tube pod"
	desc = "Наверное, её можно <b>затащить</b> в открытую транзитную станцию."
	icon = 'icons/obj/pipes_and_stuff/not_atmos/transit_tube_pod.dmi'
	icon_state = "pod"

/obj/structure/c_transit_tube_pod/get_ru_names()
	return alist(
		NOMINATIVE = "неприкреплённая транзитная капсула",
		GENITIVE = "неприкреплённой транзитной капсулы",
		DATIVE = "неприкреплённой транзитной капсуле",
		ACCUSATIVE = "неприкреплённую транзитную капсулу",
		INSTRUMENTAL = "неприкреплённой транзитной капсулой",
		PREPOSITIONAL = "неприкреплённой транзитной капсуле",
	)

/obj/structure/c_transit_tube_pod/rpd_act(mob/user, obj/item/rpd/our_rpd, mode)
	if(mode != RPD_DELETE_MODE)
		return ..()
	our_rpd.delete_single_pipe(user, src)
	return TRUE

#undef TRANSIT_TUBES_PER_TURF
