/datum/atom_hud/alternate_appearance/basic/heretic

/datum/atom_hud/alternate_appearance/basic/heretic/mob_should_see(mob/viewer)
	return isheretic(viewer)

/obj/effect/decal/cleanable/blood/gibs/torso
	icon_state = "gibtorso"
	random_icon_states = null

/obj/effect/gibspawner/human/bodypartless
	gibtypes = list(
		/obj/effect/decal/cleanable/blood/gibs,
		/obj/effect/decal/cleanable/blood/gibs/core,
		/obj/effect/decal/cleanable/blood/gibs,
		/obj/effect/decal/cleanable/blood/gibs/core,
		/obj/effect/decal/cleanable/blood/gibs,
		/obj/effect/decal/cleanable/blood/gibs/torso,
	)
	gibamounts = list(1, 1, 1, 1, 1, 1)

/obj/effect/gibspawner/human/bodypartless/Initialize(mapload)
	gibdirections = list(list(NORTH, NORTHEAST, NORTHWEST), list(SOUTH, SOUTHEAST, SOUTHWEST), list(WEST, NORTHWEST, SOUTHWEST), list(EAST, NORTHEAST, SOUTHEAST), GLOB.alldirs, list())
	return ..()

/datum/hallucination/delusion/preset
	var/delusion_icon_file
	var/delusion_icon_state
	var/delusion_name
	var/duration = 30 SECONDS
	var/affects_us = TRUE
	var/affects_others = FALSE
	var/random_hallucination_weight = 1
	var/dynamic_delusion = FALSE
	var/mutable_appearance/delusion_appearance

/datum/hallucination/delusion/preset/proc/make_delusion_image(mob/over_who)
	return delusion_appearance || image(icon = delusion_icon_file, icon_state = delusion_icon_state)

/datum/hallucination/delusion/preset/moon
	delusion_icon_file = 'icons/mob/eldritch_mobs.dmi'
	delusion_icon_state = "moon_mass"
	delusion_name = "moon"
	duration = 15 SECONDS
	affects_others = TRUE
	random_hallucination_weight = 0

/datum/hallucination/delusion/preset/heretic
	dynamic_delusion = TRUE
	random_hallucination_weight = 0
	delusion_name = "Heretic"
	affects_others = TRUE
	affects_us = FALSE
	duration = 11 SECONDS

/datum/hallucination/delusion/preset/heretic/make_delusion_image(mob/over_who)
	delusion_appearance = mutable_appearance('icons/mob/eldritch_mobs.dmi', "moon_mass")
	return ..()

/datum/hallucination/delusion/preset/heretic/gate
	delusion_name = "Врата Разума"
	duration = 60 SECONDS
	affects_us = TRUE
