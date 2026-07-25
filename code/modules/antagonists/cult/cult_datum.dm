/datum/antagonist/cult
	name = "Cultist"
	roundend_category = "cultists"
	show_in_roundend = FALSE
	job_rank = ROLE_CULTIST
	special_role = SPECIAL_ROLE_CULTIST
	antag_hud_type = ANTAG_HUD_CULT
	antag_hud_name = "hudcultist"
	antag_menu_name = "Культист"
	clown_gain_text = "A dark power has allowed you to overcome your clownish nature, letting you wield weapons without harming yourself."
	stinger_sound = 'sound/ambience/antag/bloodcult.ogg'

/datum/antagonist/cult/Destroy(force)
	if(owner?.current)
		for(var/datum/action/innate/cult/action in owner.current.actions)
			qdel(action)
	return ..()

/datum/antagonist/cult/get_antag_menu_name()
	return "Культист [SSticker.cultdat.entity_name]"

/datum/antagonist/cult/add_owner_to_gamemode()
	SSticker.mode.cult |= owner

/datum/antagonist/cult/remove_owner_from_gamemode()
	SSticker.mode.cult -= owner

/datum/antagonist/cult/give_objectives()
	add_objective(/datum/objective/servecult)

/datum/antagonist/cult/greet()
	return CULT_GREETING

/datum/antagonist/cult/farewell()
	if(owner?.current && !silent)
		owner.current.visible_message(
			span_cult("[owner.current] looks like [owner.current.p_they()] just reverted to [owner.current.p_their()] old faith!"),
			span_userdanger("An unfamiliar white light flashes through your mind, cleansing the taint of [SSticker.cultdat ? SSticker.cultdat.entity_title1 : "Nar'Sie"] and the memories of your time as their servant with it."),
		)

/datum/antagonist/cult/apply_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	user.faction |= "cult"
	ADD_TRAIT(user, TRAIT_HEALS_FROM_CULT_PYLONS, CULT_TRAIT)
	if(iscarbon(user))
		user.AddElement(/datum/element/halo_attach, GLOB.halo_overlays["cult"], GLOB.halo_callbacks["cult"])
	if(SSticker.mode.cult_risen)
		SSticker.mode.rise(user)
		if(SSticker.mode.cult_ascendant)
			SSticker.mode.ascend(user)

/datum/antagonist/cult/remove_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	user.faction -= "cult"
	REMOVE_TRAIT(user, TRAIT_HEALS_FROM_CULT_PYLONS, CULT_TRAIT)
	user.RemoveElement(/datum/element/halo_attach)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		REMOVE_TRAIT(human_user, TRAIT_RED_EYES, CULT_TRAIT)
		human_user.change_eye_color(human_user.original_eye_color, FALSE)
		human_user.update_eyes()
		human_user.remove_overlay(HALO_LAYER)
		human_user.update_body()

/datum/antagonist/cult/finalize_antag()
	var/datum/action/innate/cult/comm/communion = new
	communion.Grant(owner.current)
	var/datum/action/innate/cult/check_progress/progress = new
	progress.Grant(owner.current)
	if(ishuman(owner.current))
		var/datum/action/innate/cult/blood_magic/magic = new
		magic.Grant(owner.current)
		var/datum/action/innate/cult/use_dagger/dagger = new
		dagger.Grant(owner.current)
	owner.current.update_action_buttons(TRUE)
