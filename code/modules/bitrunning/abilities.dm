/datum/action/avatar_domain_info
	name = "Информация о домене"
	desc = "Открыть инструктаж по текущему виртуальному домену."
	button_icon_state = "hotkey_help"
	show_to_observers = FALSE
	var/help_text

/datum/action/avatar_domain_info/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return

	ui_interact(owner)

/datum/action/avatar_domain_info/ui_state(mob/user)
	return GLOB.always_state

/datum/action/avatar_domain_info/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AvatarHelp", "Информация о домене")
		ui.open()

/datum/action/avatar_domain_info/ui_static_data(mob/user)
	return list("help_text" = help_text)
