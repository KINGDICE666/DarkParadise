#define ACCELERATED_DANCE_RHYTM 10


/obj/effect/proc_holder/spell/accelerated_dance
	name = "Ускоренный Танец"
	desc = "Сорваться в танец: ритм подскакивает, вы двигаетесь заметно быстрее, вдвое хуже \
			чувствуете усталость и вас нельзя сбить с ног. Когда танец кончится, тело потребует своё."
	action_background_icon = 'icons/mob/actions/backgrounds.dmi'
	action_background_icon_state = "bg_rhytm"
	overlay_icon_state = "bg_heretic_border"
	action_icon = 'icons/mob/actions/actions_ecult.dmi'
	action_icon_state = "accelerated_dance"

	school = SCHOOL_FORBIDDEN
	human_req = FALSE
	clothes_req = FALSE
	base_cooldown = 45 SECONDS
	invocation = "Т'НЦ'Й!"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = NONE


/obj/effect/proc_holder/spell/accelerated_dance/create_new_targeting()
	return new /datum/spell_targeting/self


/obj/effect/proc_holder/spell/accelerated_dance/valid_target(atom/cast_on)
	return isliving(cast_on)


/obj/effect/proc_holder/spell/accelerated_dance/cast(list/targets, mob/user = usr)
	. = ..()
	var/mob/living/cast_on = targets[1]
	var/datum/status_effect/heretic_passive/rhytm/beat = get_heretic_rhytm(cast_on)
	beat?.adjust_rhythm(ACCELERATED_DANCE_RHYTM)
	beat?.flourish()
	cast_on.emote("dance", ignore_cooldowns = TRUE)
	cast_on.apply_status_effect(/datum/status_effect/accelerated_dance)


#undef ACCELERATED_DANCE_RHYTM
