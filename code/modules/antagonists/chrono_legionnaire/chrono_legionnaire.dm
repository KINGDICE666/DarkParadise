/datum/antagonist/chrono_legionnaire
	name = "Chrono Legionnaire"
	roundend_category = "Хронолегионерами"
	antag_menu_name = "Хронолегионер"
	special_role = SPECIAL_ROLE_EVENTMISC
	antag_hud_type = ANTAG_HUD_EVENTMISC
	antag_hud_name = "hudevent"
	replace_banned = FALSE
	var/mission
	var/datum/mind/erase_target
	var/random_erase_target = FALSE
	var/datum/action/innate/chrono_panel/panel_action

/datum/antagonist/chrono_legionnaire/Destroy(force)
	QDEL_NULL(panel_action)
	erase_target = null
	return ..()

/datum/antagonist/chrono_legionnaire/on_gain()
	antag_memory = "<b>Миссия хронолегионера:</b> [mission]<br>"
	return ..()

/datum/antagonist/chrono_legionnaire/give_objectives()
	if(erase_target)
		add_objective(/datum/objective/chrono_erase, target_override = erase_target)
	else if(random_erase_target)
		add_objective(/datum/objective/chrono_erase)
	erase_target = null

/datum/antagonist/chrono_legionnaire/greet()
	var/list/messages = list()
	messages += span_userdanger("Вы — хронолегионер!")
	messages += span_notice("Вы прибыли, чтобы исправить ход истории. Ваше снаряжение способно стереть человека из временного потока.")
	messages += span_danger("<b>Миссия:</b> [mission]")
	messages += span_notice("Кнопка \"Хронопанель\" показывает миссию и цели. Когда цели выполнены, через неё можно покинуть эту реальность.")
	return messages

/datum/antagonist/chrono_legionnaire/apply_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	if(!panel_action)
		panel_action = new(src)
	panel_action.Grant(user)
	return user

/datum/antagonist/chrono_legionnaire/remove_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	panel_action?.Remove(user)
	return user

/datum/antagonist/chrono_legionnaire/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChronoLegionnaire", "Хронопанель")
		ui.open()

/datum/antagonist/chrono_legionnaire/ui_status(mob/user, datum/ui_state/state)
	if(user != owner.current || user.stat == DEAD)
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/antagonist/chrono_legionnaire/ui_data(mob/user)
	var/list/data = list()
	data["mission"] = mission
	var/list/objectives_data = list()
	for(var/datum/objective/objective as anything in objectives)
		objectives_data += list(list(
			"explanation" = objective.explanation_text,
			"complete" = objective.check_completion(),
		))
	data["objectives"] = objectives_data
	var/list/erased = list()
	for(var/datum/mind/erased_mind as anything in GLOB.chrono_erased_minds)
		erased += erased_mind.name
	data["erased"] = erased
	data["can_leave"] = can_leave()
	return data

/datum/antagonist/chrono_legionnaire/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "leave_reality")
		leave_reality()
		return TRUE

/datum/antagonist/chrono_legionnaire/proc/can_leave()
	for(var/datum/objective/objective as anything in objectives)
		if(!objective.check_completion())
			return FALSE
	return TRUE

/datum/antagonist/chrono_legionnaire/proc/leave_reality()
	var/mob/living/legionnaire = owner.current
	if(legionnaire.stat != CONSCIOUS || !can_leave())
		return
	var/turf/exit_turf = get_turf(legionnaire)
	legionnaire.visible_message(
		span_notice("[DECLENT_RU_CAP(legionnaire, NOMINATIVE)] растворя[PLUR_ET_YUT(legionnaire)]ся во временном потоке."),
		span_notice("Вы покидаете эту реальность."),
	)
	new /obj/effect/temp_visual/chronophase(exit_turf)
	playsound(exit_turf, 'sound/magic/teleport_diss.ogg', 50, TRUE)
	log_and_message_admins("has left reality as a Chrono Legionnaire at [ADMIN_VERBOSEJMP(exit_turf)].")
	legionnaire.ghostize()
	qdel(legionnaire)

/datum/objective/chrono_erase
	name = "Erase from the timestream"
	antag_menu_name = "Стереть из временного потока"
	martyr_compatible = TRUE

/datum/objective/chrono_erase/find_target(list/target_blacklist)
	. = ..()
	update_explanation_text()

/datum/objective/chrono_erase/on_add_objective(datum/mind/new_owner)
	update_explanation_text()

/datum/objective/chrono_erase/update_explanation_text()
	if(target?.current)
		explanation_text = "Сотрите [target.current.real_name], [target.assigned_role], из временного потока."

/datum/objective/chrono_erase/check_completion()
	return !target?.current || (target in GLOB.chrono_erased_minds)

/datum/action/innate/chrono_panel
	name = "Хронопанель"
	desc = "Миссия, цели и уход из этой реальности."
	button_icon_state = "spacetime"

/datum/action/innate/chrono_panel/Activate()
	var/datum/antagonist/chrono_legionnaire/legionnaire_datum = target
	legionnaire_datum.ui_interact(owner)
