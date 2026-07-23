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
	var/datum/objective/rev_obj = new
	rev_obj.needs_target = FALSE
	rev_obj.owner = owner
	rev_obj.antag_menu_name = "Революция"
	rev_obj.explanation_text = "Вы или ваши сподвижники должны занять командные должности, отправив в отставку занимающий их экипаж"
	objectives += rev_obj

/datum/antagonist/rev/greet()
	return span_danger(span_fontsize3(" You are now a revolutionary! Follow orders given by revolution leaders. Do not harm your fellow freedom fighters. You can identify your comrades by the red \"R\" icons, and your leaders by the blue \"R\" icons."))

/datum/antagonist/rev/farewell()
	if(owner?.current && !silent)
		to_chat(owner.current, span_danger(span_fontsize3("<b>You have been brainwashed! You are no longer a revolutionary!</b>")))

/datum/antagonist/rev/finalize_antag()
	SEND_SOUND(owner.current, sound('sound/ambience/antag/revolutionary_tide.ogg'))

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
	. = ..()
	var/mob/living/user = mob_override || owner.current
	if(!(locate(/datum/action/innate/revolution_recruitment) in user.actions))
		var/datum/action/innate/revolution_recruitment/recruit = new
		recruit.Grant(user)

/datum/antagonist/rev/head/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/user = mob_override || owner.current
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

/datum/action/innate/revolution_recruitment/proc/choose_targets(mob/user = usr)
	var/list/validtargets = list()
	for(var/mob/living/carbon/human/M in view(user.client.view, get_turf(user)))
		if(M?.mind && M.stat == CONSCIOUS)
			if(M == user)
				continue
			if((M.mind.special_role == SPECIAL_ROLE_REV) || (M.mind.special_role == SPECIAL_ROLE_HEAD_REV))
				continue
			validtargets += M
	if(!length(validtargets))
		to_chat(usr, span_warning("There are no valid targets!"))
	var/mob/living/carbon/human/target = tgui_input_list(usr, "Choose a target for recruitment.", "Targeting", validtargets)
	return target

/datum/action/innate/revolution_recruitment/Activate()
	if(!(usr?.mind && usr.stat == CONSCIOUS))
		to_chat(usr, span_danger("You must be conscious."))
		return
	if(world.time < usr.mind.rev_cooldown)
		to_chat(usr, span_danger("You must wait between attempts."))
		return
	usr.mind.rev_cooldown = world.time + 50
	var/mob/living/carbon/human/recruit = choose_targets()
	if(!recruit)
		return
	log_admin("[key_name(usr)] attempted recruitment [key_name(recruit)] into the revolution.", usr)
	to_chat(usr, span_notice("<b>You are trying to recruit [recruit]: </b>"))
	if(ismindshielded(recruit) || (recruit.mind in SSticker.mode.get_living_heads()))
		to_chat(recruit, span_danger(span_fontsize4("You were asked to join the revolution, but for reasons you did not know, you refused.")))
		to_chat(usr, span_danger("\The [recruit] does not support the revolution!"))
		return
	var/choice = alert(recruit, "Do you want to join the revolution?", "Join the revolution", "Yes", "No")
	if(choice == "Yes")
		if(!(recruit?.mind && recruit.stat == CONSCIOUS))
			return
		if(usr.mind in SSticker.mode.head_revolutionaries)
			SSticker.mode.add_revolutionary(recruit.mind)
	if(choice == "No")
		to_chat(recruit, span_danger("You reject this traitorous cause!"))
		to_chat(usr, span_danger("\The [recruit] does not support the revolution!"))
