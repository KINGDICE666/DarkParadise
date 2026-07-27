/datum/antagonist/wizard
	name = "Wizard"
	roundend_category = "Магами и Ведьмами"
	roundend_blackbox_key = "wizard"
	roundend_death_is_failure = TRUE
	job_rank = ROLE_WIZARD
	special_role = SPECIAL_ROLE_WIZARD
	antag_hud_type = ANTAG_HUD_WIZ
	antag_hud_name = "hudwizard"
	antag_menu_name = "Маг"
	wiki_page_name = "Wizard"
	russian_wiki_name = "Маг"
	give_objectives = FALSE
	stinger_sound = 'sound/ambience/antag/ragesmages.ogg'
	var/farewell_message = "You have been brainwashed! You are no longer a wizard."
	var/deconversion_log = "De-wizarded"

/datum/antagonist/wizard/Destroy(force)
	owner?.current?.spellremove(owner.current)
	return ..()

/datum/antagonist/wizard/add_owner_to_gamemode()
	SSticker.mode.wizards |= owner

/datum/antagonist/wizard/remove_owner_from_gamemode()
	SSticker.mode.wizards -= owner

/datum/antagonist/wizard/roundend_report_details()
	if(!LAZYLEN(owner.spell_list))
		return ..()
	var/list/spell_names = list()
	for(var/obj/effect/proc_holder/spell/spell as anything in owner.spell_list)
		spell_names += spell.name
	return list("<b>[owner.name] использовал заклинания:</b> [english_list(spell_names)]")

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
	user.faction -= "Station"
	user.faction |= "wizard"

/datum/antagonist/wizard/remove_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	user.faction -= "wizard"
	user.faction |= "Station"


/datum/antagonist/wizard/apprentice
	name = "Wizard Apprentice"
	roundend_category = "Учениками магов"
	special_role = SPECIAL_ROLE_WIZARD_APPRENTICE
	antag_hud_name = "apprentice"
	antag_menu_name = "Ученик мага"
	farewell_message = "You have been brainwashed! You are no longer a wizard-apprentice."
	deconversion_log = "De-apprentice-wizarded"

/datum/antagonist/wizard/apprentice/add_owner_to_gamemode()
	SSticker.mode.apprentices |= owner

/datum/antagonist/wizard/apprentice/remove_owner_from_gamemode()
	SSticker.mode.apprentices -= owner
