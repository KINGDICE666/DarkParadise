#define HEART_RESONANCE_DURATION (1 MINUTES)


/obj/effect/proc_holder/spell/aoe/heart_resonance
	name = "Резонанс Сердец"
	desc = "Связывает все сердца поблизости с вашим на минуту. Пока связь держится, каждое \
			ваше сердцебиение бьёт по всему живому вокруг, а чужой страх поднимает ваш ритм."
	action_background_icon = 'icons/mob/actions/backgrounds.dmi'
	action_background_icon_state = "bg_rhytm"
	overlay_icon_state = "bg_heretic_border"
	action_icon = 'icons/mob/actions/actions_ecult.dmi'
	action_icon_state = "heart_resonance"
	sound = 'sound/magic/heretic/rhytm/timpan2.ogg'

	school = SCHOOL_FORBIDDEN
	human_req = FALSE
	clothes_req = FALSE
	base_cooldown = 90 SECONDS

	invocation = "'ДН' С'РДЦ' Н' В'С'Х"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = NONE
	aoe_range = 2


/obj/effect/proc_holder/spell/aoe/heart_resonance/create_new_targeting()
	return new /datum/spell_targeting/self


/obj/effect/proc_holder/spell/aoe/heart_resonance/valid_target(atom/cast_on)
	return !isnull(get_heretic_rhytm(cast_on))


/obj/effect/proc_holder/spell/aoe/heart_resonance/cast(list/targets, mob/user = usr)
	. = ..()
	var/mob/living/caster = action.owner || user
	var/datum/status_effect/heretic_passive/rhytm/beat = get_heretic_rhytm(caster)
	if(!beat)
		return

	beat.pulse_until = world.time + HEART_RESONANCE_DURATION
	new /obj/effect/temp_visual/resonant_pulse(get_turf(caster))
	to_chat(caster, span_hierophant("Все сердца вокруг сбиваются на ваш такт."))

	for(var/mob/living/nearby_mob in view(aoe_range, caster))
		if(nearby_mob == caster || IS_HERETIC_OR_MONSTER(nearby_mob))
			continue
		to_chat(nearby_mob, span_userdanger("Ваше сердце сбивается и начинает биться в чужом такте!"))


#undef HEART_RESONANCE_DURATION
