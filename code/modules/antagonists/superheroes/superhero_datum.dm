/datum/antagonist/superhero
	name = "Superhero"
	roundend_category = "superheroes"
	show_in_roundend = FALSE
	special_role = SPECIAL_ROLE_SUPER
	antag_menu_name = "Супергерой"
	give_objectives = FALSE
	replace_banned = FALSE
	silent = TRUE

/datum/antagonist/superhero/add_owner_to_gamemode()
	SSticker.mode.superheroes |= owner

/datum/antagonist/superhero/remove_owner_from_gamemode()
	SSticker.mode.superheroes -= owner


/datum/antagonist/superhero/supervillain
	name = "Supervillain"
	roundend_category = "supervillains"
	antag_menu_name = "Суперзлодей"

/datum/antagonist/superhero/supervillain/add_owner_to_gamemode()
	SSticker.mode.supervillains |= owner

/datum/antagonist/superhero/supervillain/remove_owner_from_gamemode()
	SSticker.mode.supervillains -= owner


/datum/antagonist/greyshirt
	name = "Greyshirt"
	roundend_category = "greyshirts"
	show_in_roundend = FALSE
	special_role = SPECIAL_ROLE_GREYSHIRT
	antag_menu_name = "Грейтайд"
	give_objectives = FALSE
	replace_banned = FALSE
	var/datum/mind/boss

/datum/antagonist/greyshirt/Destroy(force)
	boss = null
	return ..()

/datum/antagonist/greyshirt/add_owner_to_gamemode()
	SSticker.mode.greyshirts |= owner

/datum/antagonist/greyshirt/remove_owner_from_gamemode()
	SSticker.mode.greyshirts -= owner

/datum/antagonist/greyshirt/greet()
	var/mob/living/leader = boss.current
	var/list/messages = list()
	messages.Add(span_deadsay("<b>You have decided to enroll as a henchman for [leader]. You are now part of the feared 'Greyshirts'.</b>"))
	messages.Add(span_deadsay("<b>You must follow the orders of [leader], and help [leader.p_them()] succeed in [leader.p_their()] dastardly schemes."))
	messages.Add(span_deadsay("You may not harm other Greyshirt or [leader]. However, you do not need to obey other Greyshirts."))
	return messages
