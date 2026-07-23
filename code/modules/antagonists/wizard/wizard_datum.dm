/datum/antagonist/wizard
	name = "Wizard"
	roundend_category = "wizards"
	show_in_roundend = FALSE
	job_rank = ROLE_WIZARD
	special_role = SPECIAL_ROLE_WIZARD
	antag_hud_type = ANTAG_HUD_WIZ
	antag_hud_name = "hudwizard"
	antag_menu_name = "Маг"
	wiki_page_name = "Wizard"
	russian_wiki_name = "Маг"
	give_objectives = FALSE
	var/farewell_message = "You have been brainwashed! You are no longer a wizard."
	var/deconversion_log = "De-wizarded"

/datum/antagonist/wizard/Destroy(force)
	owner?.current?.spellremove(owner.current)
	return ..()

/datum/antagonist/wizard/add_owner_to_gamemode()
	SSticker.mode.wizards |= owner

/datum/antagonist/wizard/remove_owner_from_gamemode()
	SSticker.mode.wizards -= owner

/datum/antagonist/wizard/greet()
	return SSticker.mode.greet_wizard()

/datum/antagonist/wizard/farewell()
	if(!owner?.current || silent)
		return
	if(issilicon(owner.current))
		to_chat(owner.current, span_userdanger("You have been turned into a robot! You can feel your magical powers fading away..."))
		return
	to_chat(owner.current, span_userdanger(farewell_message))

/datum/antagonist/wizard/apply_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	user.faction = list("wizard")

/datum/antagonist/wizard/remove_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	user.faction = list("Station")

/datum/antagonist/wizard/finalize_antag()
	addtimer(CALLBACK(owner.current, TYPE_PROC_REF(/mob, playsound_local), null, 'sound/ambience/antag/ragesmages.ogg', 100, FALSE), 3 SECONDS)


/datum/antagonist/wizard/apprentice
	name = "Wizard Apprentice"
	special_role = SPECIAL_ROLE_WIZARD_APPRENTICE
	antag_hud_name = "apprentice"
	antag_menu_name = "Ученик мага"
	farewell_message = "You have been brainwashed! You are no longer a wizard-apprentice."
	deconversion_log = "De-apprentice-wizarded"

/datum/antagonist/wizard/apprentice/add_owner_to_gamemode()
	SSticker.mode.apprentices |= owner

/datum/antagonist/wizard/apprentice/remove_owner_from_gamemode()
	SSticker.mode.apprentices -= owner
