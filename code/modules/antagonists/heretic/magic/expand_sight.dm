// Action for Raw Prophets that boosts up or shrinks down their sight range.
/obj/effect/proc_holder/spell/view_range/expand_sight
	name = "Глаза что видели запретное"
	desc = "Позволяет значительно увеличивать дальность обзора, чтобы \
			видеть врагов с гораздо большего расстояния."
	action_icon = 'icons/mob/actions/actions_ecult.dmi'
	action_icon_state = "eye"
	action_background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	human_req = FALSE

/obj/effect/proc_holder/spell/view_range/expand_sight/cast(list/targets, mob/user = usr)
	var/list/expanded_view_ranges = list(
		"default",
		"17x17",
		"19x19",
		"21x21",
		"23x23",
		"25x25",
	)
	var/new_view = tgui_input_list(user, "Выберите область видимости:", "Видимость", expanded_view_ranges, "default")
	if(isnull(new_view) || !user.client)
		return
	if(new_view == "default")
		new_view = user.client.prefs.viewrange
	selected_view = new_view
	user.client.change_view(new_view)
