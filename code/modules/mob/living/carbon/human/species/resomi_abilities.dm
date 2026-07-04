// ===================================================================
// RESOMI ABILITIES (HUD action buttons)
// Ported from SierraBay12 mods/resomi/code/body/abilities.dm
// ===================================================================

// --- Listen In (one-shot) ------------------------------------------
/datum/action/resomi
	button_icon = 'icons/mob/actions/actions.dmi'

/datum/action/resomi/listen_in
	name = "Listen In"
	desc = "Прислушаться к движению и шумам вокруг вас."
	button_icon_state = "predator_sense"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/resomi/listen_in/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!. || !ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	H.resomi_sonar_ping()

// --- Toggle Agility (table-hopping toggle) -------------------------
/datum/action/innate/resomi/toggle_agility
	name = "Toggle Agility"
	desc = "Начать/прекратить перепрыгивать через столы, перила и гидропонные лотки."
	button_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "genetic_jump"

/datum/action/innate/resomi/toggle_agility/Activate()
	active = TRUE
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.pass_flags |= PASSTABLE
		to_chat(H, span_notice("Теперь вы будете перебираться через столы/перила/лотки."))

/datum/action/innate/resomi/toggle_agility/Deactivate()
	active = FALSE
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.pass_flags &= ~PASSTABLE
		to_chat(H, span_notice("Теперь вы НЕ будете перебираться через столы/перила/лотки."))

// --- Listen In implementation --------------------------------------
/mob/living/carbon/human/proc/resomi_sonar_ping()
	if(incapacitated())
		to_chat(src, span_warning("Вам нужно прийти в себя, прежде чем использовать эту способность."))
		return
	if(HAS_TRAIT(src, TRAIT_DEAF))
		to_chat(src, span_warning("Вы сейчас, по сути, глухи!"))
		return

	to_chat(src, span_notice("Вы замираете, вслушиваясь в окружение..."))
	if(!do_after(src, 0.5 SECONDS, src))
		to_chat(src, span_notice("Чтобы вслушаться, нужно стоять на месте."))
		return

	var/heard_something = FALSE
	var/view_range = client ? client.view : world.view
	for(var/mob/living/creature in range(view_range, src))
		if(creature == src || creature.stat == DEAD)
			continue
		heard_something = TRUE
		new /obj/effect/temp_visual/sonar_ping(loc, src, creature)

		var/list/feedback = list("Слышны звуки движения ")
		var/direction = get_dir(src, creature)
		if(direction)
			feedback += "в направлении [dir2text(direction)], "
			switch(get_dist(src, creature) / view_range)
				if(0 to 0.2)
					feedback += "совсем рядом."
				if(0.2 to 0.4)
					feedback += "неподалёку."
				if(0.4 to 0.6)
					feedback += "на некотором отдалении."
				if(0.6 to 0.8)
					feedback += "поодаль."
				else
					feedback += "далеко."
		else
			feedback += "прямо на вас."
		to_chat(src, span_notice(jointext(feedback, null)))

	if(!heard_something)
		to_chat(src, span_notice("Вы не слышите никакого движения, кроме своего собственного."))
