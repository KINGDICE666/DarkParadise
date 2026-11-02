/datum/preference_middleware/lobby_layout
	action_delegations = list(
		"edit_lobby_layout" = PROC_REF(edit_lobby_layout),
	)

/datum/preference_middleware/lobby_layout/get_ui_data(mob/user)
	return list("lobby_layout_editable" = istype(user.hud_used, /datum/hud/new_player))

/datum/preference_middleware/lobby_layout/proc/edit_lobby_layout(list/params, mob/user)
	var/datum/hud/new_player/lobby_hud = user.hud_used
	if(!istype(lobby_hud))
		return FALSE
	SStgui.close_uis(preferences)
	lobby_hud.start_layout_editing()
	return FALSE
