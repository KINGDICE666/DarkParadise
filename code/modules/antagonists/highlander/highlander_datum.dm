/datum/antagonist/highlander
	name = "Highlander"
	roundend_category = "highlanders"
	show_in_roundend = FALSE
	special_role = SPECIAL_ROLE_HIGHLANDER
	antag_menu_name = "Хайлендер"

/datum/antagonist/highlander/add_owner_to_gamemode()
	SSticker.mode.traitors |= owner

/datum/antagonist/highlander/remove_owner_from_gamemode()
	SSticker.mode.traitors -= owner

/datum/antagonist/highlander/give_objectives()
	add_objective(/datum/objective/hijack)

/datum/antagonist/highlander/greet()
	return list("<b>You are a Highlander. Kill all other Highlanders. There can be only one.</b>")
