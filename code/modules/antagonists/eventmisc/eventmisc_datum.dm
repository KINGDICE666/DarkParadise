/datum/antagonist/eventmisc
	name = "Event Role"
	roundend_category = "event roles"
	show_in_roundend = FALSE
	special_role = SPECIAL_ROLE_EVENTMISC
	antag_menu_name = "Ивентроль"
	antag_hud_type = ANTAG_HUD_EVENTMISC
	antag_hud_name = "hudevent"
	give_objectives = FALSE
	replace_banned = FALSE
	silent = TRUE

/datum/antagonist/eventmisc/add_owner_to_gamemode()
	SSticker.mode.eventmiscs |= owner

/datum/antagonist/eventmisc/remove_owner_from_gamemode()
	SSticker.mode.eventmiscs -= owner


/datum/antagonist/eventmisc/syndicate
	name = "Syndicate Event Role"
	antag_menu_name = "Ивентроль \"Синдиката\""

/datum/antagonist/eventmisc/syndicate/add_owner_to_gamemode()
	..()
	SSticker.mode.traitors |= owner

/datum/antagonist/eventmisc/syndicate/remove_owner_from_gamemode()
	..()
	SSticker.mode.traitors -= owner
