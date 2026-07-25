/datum/antagonist/rev
	name = "Revolutionary"
	roundend_category = "revolutionaries"
	show_in_roundend = FALSE
	job_rank = ROLE_REV
	special_role = SPECIAL_ROLE_REV
	antag_hud_type = ANTAG_HUD_REV
	antag_hud_name = "hudrevolutionary"
	antag_menu_name = "Революционер"
	clown_gain_text = "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself."
	clown_removal_text = "You lose your training and return to your own clumsy, clownish self."
	stinger_sound = 'sound/ambience/antag/revolutionary_tide.ogg'

/datum/antagonist/rev/can_be_owned(datum/mind/new_owner)
	var/datum/mind/tested = new_owner || owner
	if(tested in SSticker.mode.get_living_heads())
		return FALSE
	return ..()

/datum/antagonist/rev/add_owner_to_gamemode()
	SSticker.mode.revolutionaries |= owner

/datum/antagonist/rev/remove_owner_from_gamemode()
	SSticker.mode.revolutionaries -= owner

/datum/antagonist/rev/give_objectives()
	add_objective(/datum/objective/revolution)

/datum/antagonist/rev/greet()
	return span_danger(span_fontsize3(" You are now a revolutionary! Follow orders given by revolution leaders. Do not harm your fellow freedom fighters. You can identify your comrades by the red \"R\" icons, and your leaders by the blue \"R\" icons."))

/datum/antagonist/rev/farewell()
	if(owner?.current && !silent)
		to_chat(owner.current, span_danger(span_fontsize3("<b>You have been brainwashed! You are no longer a revolutionary!</b>")))

/datum/antagonist/rev/proc/promote()
	var/datum/mind/old_owner = owner
	silent = TRUE
	owner.remove_antag_datum(/datum/antagonist/rev)
	old_owner.add_antag_datum(/datum/antagonist/rev/head)


/datum/antagonist/rev/head
	name = "Head Revolutionary"
	special_role = SPECIAL_ROLE_HEAD_REV
	antag_hud_name = "hudheadrevolutionary"
	antag_menu_name = "Глава революции"

/datum/antagonist/rev/head/add_owner_to_gamemode()
	SSticker.mode.head_revolutionaries |= owner

/datum/antagonist/rev/head/remove_owner_from_gamemode()
	SSticker.mode.head_revolutionaries -= owner

/datum/antagonist/rev/head/greet()
	return span_danger("You are a member of the revolutionaries' leadership!")

/datum/antagonist/rev/head/apply_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	if(locate(/datum/action/innate/revolution_recruitment) in user.actions)
		return
	var/datum/action/innate/revolution_recruitment/recruit = new
	recruit.Grant(user)

/datum/antagonist/rev/head/remove_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	var/datum/action/innate/revolution_recruitment/recruit = locate() in user.actions
	if(recruit)
		qdel(recruit)

/datum/antagonist/rev/head/finalize_antag()
	. = ..()
	SSticker.mode.equip_revolutionary(owner.current)

/datum/antagonist/rev/head/proc/demote()
	var/datum/mind/old_owner = owner
	silent = TRUE
	owner.remove_antag_datum(/datum/antagonist/rev/head)
	old_owner.add_antag_datum(/datum/antagonist/rev)


/datum/action/innate/revolution_recruitment
	name = "Recruitment"
	button_icon_state = "genetic_mindscan"
	background_icon_state = "bg_vampire_old"
	COOLDOWN_DECLARE(recruitment_cooldown)

/datum/action/innate/revolution_recruitment/proc/choose_target()
	var/list/valid_targets = list()
	for(var/mob/living/carbon/human/candidate in view(owner.client.view, get_turf(owner)))
		if(candidate == owner || !candidate.mind || candidate.stat != CONSCIOUS)
			continue
		if(candidate.mind.has_antag_datum(/datum/antagonist/rev))
			continue
		valid_targets += candidate
	if(!length(valid_targets))
		to_chat(owner, span_warning("There are no valid targets!"))
		return
	return tgui_input_list(owner, "Choose a target for recruitment.", "Targeting", valid_targets)

/datum/action/innate/revolution_recruitment/Activate()
	if(owner.stat != CONSCIOUS)
		to_chat(owner, span_danger("You must be conscious."))
		return
	if(!COOLDOWN_FINISHED(src, recruitment_cooldown))
		to_chat(owner, span_danger("You must wait between attempts."))
		return
	COOLDOWN_START(src, recruitment_cooldown, 5 SECONDS)
	var/mob/living/carbon/human/recruit = choose_target()
	if(!recruit)
		return
	log_admin("[key_name(owner)] attempted recruitment [key_name(recruit)] into the revolution.", owner)
	to_chat(owner, span_notice("<b>You are trying to recruit [recruit]: </b>"))
	if(ismindshielded(recruit) || (recruit.mind in SSticker.mode.get_living_heads()))
		to_chat(recruit, span_danger(span_fontsize4("You were asked to join the revolution, but for reasons you did not know, you refused.")))
		to_chat(owner, span_danger("\The [recruit] does not support the revolution!"))
		return
	var/choice = tgui_alert(recruit, "Do you want to join the revolution?", "Join the revolution", list("Yes", "No"))
	if(choice == "No")
		to_chat(recruit, span_danger("You reject this traitorous cause!"))
		to_chat(owner, span_danger("\The [recruit] does not support the revolution!"))
		return
	if(choice != "Yes" || QDELETED(recruit) || recruit.stat != CONSCIOUS)
		return
	if(owner.mind?.has_antag_datum(/datum/antagonist/rev/head))
		SSticker.mode.add_revolutionary(recruit.mind)
