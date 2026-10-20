/datum/program_picker
	var/mob/living/silicon/ai/assigned_ai
	var/list/possible_programs
	var/memory = 3
	var/total_memory = 3
	var/bandwidth = 1
	var/total_bandwidth = 1
	var/nanites = 50
	var/max_nanites = 100
	var/temp

/datum/program_picker/New(mob/living/silicon/ai/A)
	if(!istype(A))
		return
	assigned_ai = A
	possible_programs = list()
	for(var/type in subtypesof(/datum/ai_program))
		var/datum/ai_program/program = new type
		if(program.power_type || program.upgrade)
			possible_programs += program

/datum/program_picker/Destroy(force)
	assigned_ai = null
	QDEL_LIST(possible_programs)
	return ..()

/datum/program_picker/proc/modify_resource(key, amount)
	switch(key)
		if("memory")
			memory += amount
			total_memory += amount
			if(memory < 0)
				refund_purchases()
		if("bandwidth")
			bandwidth += amount
			total_bandwidth += amount
			if(bandwidth < 0)
				refund_upgrades()

/datum/program_picker/proc/get_installed_programs()
	var/list/installed_programs = list()
	for(var/datum/ai_program/program in possible_programs)
		if(program.installed)
			installed_programs += program
	return installed_programs

/datum/program_picker/proc/refund_purchases()
	var/list/potential_losses = get_installed_programs()
	while(memory < 0)
		if(!length(potential_losses))
			return
		var/datum/ai_program/program = pick_n_take(potential_losses)
		program.uninstall(assigned_ai)

/datum/program_picker/proc/refund_upgrades()
	var/list/potential_losses = get_installed_programs()
	while(bandwidth < 0)
		if(!length(potential_losses))
			return
		var/datum/ai_program/program = pick_n_take(potential_losses)
		if(!program.upgrade_level)
			continue
		while(program.upgrade_level > 0 && bandwidth < 0)
			program.downgrade(assigned_ai)

/datum/program_picker/proc/reset_programs()
	var/list/programs = get_installed_programs()
	for(var/datum/ai_program/program in programs)
		program.uninstall(assigned_ai)

/datum/program_picker/ui_host(mob/user)
	return assigned_ai ? assigned_ai : src

/datum/program_picker/proc/spend_nanites(amount)
	if(nanites - amount < 0)
		return FALSE
	nanites -= amount
	return TRUE

/datum/program_picker/proc/refund_nanites(amount)
	nanites = min(max_nanites, nanites + amount)

/datum/program_picker/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AIProgramPicker", "Меню программ ИИ")
		ui.open()

/datum/program_picker/ui_data(mob/user)
	var/list/data = list()
	data["program_list"] = list()
	for(var/datum/ai_program/program in possible_programs)
		var/list/program_data = list(
			"name" = program.program_name,
			"UID" = program.UID(),
			"description" = program.description,
			"memory_cost" = program.cost,
			"installed" = program.installed,
			"upgrade_level" = program.upgrade_level,
			"is_passive" = program.upgrade
		)
		data["program_list"] += list(program_data)
	data["ai_info"] = list(
		"memory" = memory,
		"bandwidth" = bandwidth
	)
	return data

/datum/program_picker/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	. = FALSE

	if(!isAI(ui.user))
		return
	var/mob/living/silicon/ai/A = ui.user
	if(A.stat == DEAD)
		to_chat(A, span_warning("Вы мертвы!"))
		return

	switch(action)
		if("select")
			var/datum/ai_program/program = locateUID(params["uid"])
			if(!istype(program) || !(program in possible_programs))
				return FALSE
			if(!program.installed)
				if(program.cost > memory)
					to_chat(A, span_warning("Недостаточно памяти для этой программы."))
					return FALSE
				memory -= program.cost
				program.installed = TRUE
				SSblackbox.record_feedback("tally", "ai_program_install", 1, "[program.type]")

			if(!program.upgrade)
				var/datum/action/cooldown/ai_program/selected_program = locate(program.power_type) in A.actions
				if(selected_program)
					if(selected_program.spell_level >= selected_program.level_max)
						to_chat(A, span_warning("Эту программу больше нельзя улучшить."))
						return FALSE
					if(bandwidth < 1)
						to_chat(A, span_warning("Недостаточно пропускной способности для улучшения!"))
						return FALSE
					selected_program.spell_level++
					if(selected_program.spell_level >= selected_program.level_max)
						to_chat(A, span_notice("Программа улучшена до максимума."))
					selected_program.on_purchase_upgrade()
					program.upgrade(A)
					return TRUE

				var/datum/action/cooldown/ai_program/new_spell = new program.power_type(A)
				new_spell.program = program
				new_spell.desc_update()
				program.upgrade(A, first_install = TRUE)
				new_spell.Grant(A)
				to_chat(A, program.unlock_text)
				A.playsound_local(A, program.unlock_sound, 50, FALSE, use_reverb = FALSE)
				return TRUE

			if(program.upgrade_level >= program.max_level)
				to_chat(A, span_notice("Программа улучшена до максимума."))
				return FALSE
			if(!program.upgrade_level)
				program.upgrade(A, first_install = TRUE)
			else
				if(bandwidth < 1)
					to_chat(A, span_warning("Недостаточно пропускной способности для улучшения!"))
					return FALSE
				program.upgrade(A)
			to_chat(A, program.unlock_text)
			A.playsound_local(A, program.unlock_sound, 50, FALSE, use_reverb = FALSE)
			return TRUE

/datum/ai_program
	var/program_name
	var/description = ""
	var/program_id
	var/cost = 1
	var/nanite_cost = 0
	var/bandwidth_used = 0
	var/power_type = /datum/action/cooldown/ai_program
	var/upgrade = FALSE
	var/upgrade_level = 0
	var/max_level = 5
	var/unlock_text = span_notice_alt("Привет, мир!")
	var/unlock_sound
	var/cooldown = 30 SECONDS
	var/installed = FALSE
	var/external = FALSE

/datum/ai_program/New()
	. = ..()
	if(nanite_cost)
		description += " Расход нанитов: [nanite_cost]."

/datum/ai_program/proc/upgrade(mob/living/silicon/ai/user, first_install = FALSE)
	if(!istype(user))
		return
	upgrade_level++
	if(!first_install)
		SSblackbox.record_feedback("tally", "ai_program_upgrade", 1, "[src.type]")
		bandwidth_used++
		user.program_picker.bandwidth--

/datum/ai_program/proc/downgrade(mob/living/silicon/ai/user)
	if(!istype(user))
		return
	upgrade_level--
	if(upgrade_level <= 0)
		uninstall(user)
		return
	to_chat(user, span_warning("Утеряны данные обновления программы: [src.program_name]!"))
	bandwidth_used--
	user.program_picker.bandwidth++
	if(!upgrade)
		var/datum/action/cooldown/ai_program/aspell = locate(power_type) in user.actions
		if(aspell)
			aspell.spell_level--
			aspell.on_purchase_upgrade()

/datum/ai_program/proc/uninstall(mob/living/silicon/ai/user)
	upgrade_level = 0
	installed = FALSE
	if(!istype(user))
		return
	user.program_picker.bandwidth += bandwidth_used
	bandwidth_used = 0
	user.program_picker.memory += cost
	to_chat(user, span_userdanger("Утеряны основные данные программы: [src.program_name]!"))
	if(!upgrade)
		var/datum/action/cooldown/ai_program/aspell = locate(power_type) in user.actions
		qdel(aspell)

/datum/action/innate/ai/choose_program
	name = "Выбор программ"
	desc = "Потратьте память и пропускную способность, чтобы получить различные способности."
	button_icon = 'icons/mob/ai.dmi'
	button_icon_state = "ai"
	auto_use_uses = FALSE

/datum/action/innate/ai/choose_program/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	if(isapc(owner_AI.loc))
		to_chat(owner_AI, span_warning("Ошибка: вычислительной мощности ЛКП недостаточно для работы программ!"))
		return
	if(istype(owner_AI.loc, /obj/item/aicard))
		to_chat(owner_AI, span_warning("Ошибка: вычислительной мощности интелкарты недостаточно для работы программ!"))
		return
	owner_AI.program_picker.ui_interact(owner_AI)

/datum/action/cooldown/ai_program
	name = "Программа ИИ"
	desc = "Вы не до конца уверены, что это делает, но оно очень бип-бупает."
	background_icon_state = "bg_tech_blue"
	check_flags = AB_CHECK_CONSCIOUS
	var/datum/ai_program/program
	var/spell_level = 0
	var/level_max = 4
	var/cooldown_min = 0
	var/selection_activated_message
	var/selection_deactivated_message

/datum/action/cooldown/ai_program/Destroy()
	program = null
	return ..()

/datum/action/cooldown/ai_program/Activate(atom/target)
	StartCooldown()
	if(owner.ckey)
		add_attack_logs(owner, target, "cast the spell [name]", ATKLOG_ALL)
	cast(target, owner)
	return TRUE

/datum/action/cooldown/ai_program/proc/cast(atom/target, mob/living/silicon/ai/user)
	return

/datum/action/cooldown/ai_program/proc/revert_cast()
	ResetCooldown()

/datum/action/cooldown/ai_program/proc/on_purchase_upgrade()
	return

/datum/action/cooldown/ai_program/proc/set_recharge_duration(new_duration)
	cooldown_time = new_duration
	if(next_use_time > world.time)
		StartCooldown()

/datum/action/cooldown/ai_program/proc/find_nearest_camera(atom/target)
	var/area/A = get_area(target)
	if(!istype(A))
		return
	var/closest_camera = null
	for(var/obj/machinery/camera/C in A)
		if(isnull(closest_camera))
			closest_camera = C
			continue
		if(get_dist(closest_camera, target) > get_dist(C, target))
			closest_camera = C
			continue
	return closest_camera

/datum/action/cooldown/ai_program/proc/desc_update()
	desc = initial(desc)
	if(program)
		desc += " Расход нанитов: [program.nanite_cost]."
	build_all_button_icons(UPDATE_BUTTON_NAME)

/datum/action/cooldown/ai_program/proc/camera_beam(target, icon_state, icon, time)
	var/obj/machinery/camera/C = find_nearest_camera(target)
	if(!istype(C))
		return
	C.Beam(target, icon_state = icon_state, icon = icon, time = time)

/datum/action/cooldown/ai_program/proc/check_camera_vision(mob/user, atom/target)
	var/turf/target_turf = get_turf(target)
	if(!GLOB.cameranet.checkTurfVis(target_turf))
		to_chat(user, span_warning("У вас нет обзора камер в этом месте!"))
		return FALSE
	return TRUE

/datum/action/cooldown/ai_program/ranged
	name = "Дистанционное действие ИИ"
	click_to_activate = TRUE
	ranged_mousepointer = 'icons/effects/mouse_pointers/mecha_mouse.dmi'
	selection_activated_message = span_notice_alt("Привет, мир!")
	selection_deactivated_message = span_danger_alt("Прощай, жестокий мир!")

/datum/action/cooldown/ai_program/ranged/set_click_ability(mob/on_who)
	. = ..()
	to_chat(on_who, selection_activated_message)

/datum/action/cooldown/ai_program/ranged/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(refund_cooldown)
		to_chat(on_who, selection_deactivated_message)

/datum/ai_program/rgb_lighting
	program_name = "RGB-подсветка"
	program_id = "rgb_lighting"
	description = "Перекрашивает лампу в выбранный цвет. При достаточно высоком уровне может перекрасить освещение всей комнаты, если выбрать ЛКП."
	nanite_cost = 5
	power_type = /datum/action/cooldown/ai_program/ranged/rgb_lighting
	unlock_text = "Установка RGB-подсветки завершена!"

/datum/action/cooldown/ai_program/ranged/rgb_lighting
	name = "RGB-подсветка"
	desc = "Меняет цвет выбранной лампы."
	button_icon = 'icons/effects/random_spawners.dmi'
	button_icon_state = "glowstick"
	cooldown_time = 30 SECONDS
	cooldown_min = 5 SECONDS
	level_max = 5
	selection_activated_message = span_notice_alt("Вы подключаетесь к контроллеру освещения станции...")
	selection_deactivated_message = span_notice_alt("Вы отменяете запрос к контроллеру освещения.")

/datum/action/cooldown/ai_program/ranged/rgb_lighting/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	if(!istype(target, /obj/machinery/light) && !isapc(target))
		to_chat(user, span_warning("Перекрашивать можно только лампы!"))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	var/color_picked = tgui_input_color(user, "Выберите цвет освещения.", "Цвет RGB-подсветки")
	if(!color_picked)
		user.program_picker.refund_nanites(program.nanite_cost)
		revert_cast()
		return
	var/list/picked_rgb = rgb2num(color_picked)
	var/list/hsl = rgb2hsl(picked_rgb[1], picked_rgb[2], picked_rgb[3])
	hsl[3] = max(hsl[3], 0.4)
	var/list/rgb = hsl2rgb(arglist(hsl))
	var/new_color = rgb(rgb[1], rgb[2], rgb[3])
	if(isapc(target))
		if(spell_level < 3)
			to_chat(user, span_warning("Подсистема окраски недостаточно мощна, чтобы перекрасить целую комнату!"))
			user.program_picker.refund_nanites(program.nanite_cost)
			revert_cast()
			return
		var/obj/machinery/power/apc/A = target
		for(var/obj/machinery/light/L in A.area)
			L.color = new_color
			L.brightness_color = new_color
			L.update(TRUE, TRUE)
	else
		var/obj/machinery/light/L = target
		L.color = new_color
		L.brightness_color = new_color
		L.update(TRUE, TRUE)
	user.play_sound_remote(target, 'sound/effects/spray.ogg', 50)
	camera_beam(target, "rped_upgrade", 'icons/effects/effects.dmi', 5)

/datum/action/cooldown/ai_program/ranged/rgb_lighting/on_purchase_upgrade()
	set_recharge_duration(max(initial(cooldown_time) - (spell_level * 5 SECONDS), cooldown_min))

/datum/ai_program/power_shunt
	program_name = "Шунт питания"
	program_id = "power_shunt"
	description = "Заряжает ЛКП, киборга или экзокостюм энергией прямо из вашего СМЕС!"
	nanite_cost = 20
	power_type = /datum/action/cooldown/ai_program/ranged/power_shunt
	unlock_text = "Установка шунта питания завершена!"

/datum/action/cooldown/ai_program/ranged/power_shunt
	name = "Шунт питания"
	desc = "Заряжает ЛКП, киборга или экзокостюм энергией прямо из вашего СМЕС."
	button_icon = 'icons/obj/engines_and_power/power.dmi'
	button_icon_state = "smes-o"
	cooldown_time = 120 SECONDS
	cooldown_min = 30 SECONDS
	level_max = 7
	selection_activated_message = span_notice_alt("Вы подключаетесь к энергосети станции...")
	selection_deactivated_message = span_notice_alt("Вы отключаетесь от энергосети.")
	var/power_sent = 2500

/datum/action/cooldown/ai_program/ranged/power_shunt/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	if(!isrobot(target) && !isapc(target) && !ismecha(target) && !ismachineperson(target))
		to_chat(user, span_warning("Заряжать можно только киборгов, экзокостюмы и ЛКП!"))
		revert_cast()
		return
	if(ismachineperson(target) && !user.universal_adapter)
		to_chat(user, span_warning("Программе не хватает нужного улучшения, чтобы заряжать КПБ!"))
		revert_cast()
		return
	var/obj/machinery/power/smes/power_source
	for(var/obj/machinery/power/smes/smes in get_area(user))
		if(smes.charge >= power_sent)
			power_source = smes
			break
	if(!power_source)
		to_chat(user, span_warning("Не найден СМЕС с достаточным зарядом!"))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	if(ismecha(target))
		var/obj/mecha/T = target
		T.cell?.give(power_sent)
	if(isrobot(target))
		var/mob/living/silicon/robot/T = target
		T.cell?.give(power_sent)
	if(isapc(target))
		var/obj/machinery/power/apc/T = target
		T.cell?.give(power_sent)
	if(ismachineperson(target))
		var/mob/living/carbon/human/T = target
		T.adjust_nutrition(clamp(user.adapter_efficiency * (power_sent / 10), 0, (NUTRITION_LEVEL_FULL - T.nutrition)))

	power_source.charge -= power_sent
	user.play_sound_remote(target, 'sound/goonstation/misc/fuse.ogg', 50)
	camera_beam(target, "rped_upgrade", 'icons/effects/effects.dmi', 5)

/datum/action/cooldown/ai_program/ranged/power_shunt/on_purchase_upgrade()
	power_sent = min(10000, 2500 + (spell_level * 2500))
	set_recharge_duration(max(initial(cooldown_time) - (max(spell_level - 3, 0) * 30 SECONDS), cooldown_min))

/datum/ai_program/repair_nanites
	program_name = "Ремонтные наниты"
	program_id = "repair_nanites"
	description = "Ремонтирует ЛКП, киборга или экзокостюм роем роботизированных наномашин!"
	cost = 2
	nanite_cost = 75
	power_type = /datum/action/cooldown/ai_program/ranged/repair_nanites
	unlock_text = "Установка прошивки ремонтных наномашин завершена!"

/datum/action/cooldown/ai_program/ranged/repair_nanites
	name = "Ремонтные наниты"
	desc = "Ремонтирует ЛКП, киборга или экзокостюм роем роботизированных наномашин!"
	button_icon = 'icons/obj/surgery.dmi'
	button_icon_state = "tube"
	cooldown_time = 150 SECONDS
	cooldown_min = 30 SECONDS
	level_max = 7
	selection_activated_message = span_notice_alt("Вы готовитесь отдать наномашинам приказ о ремонте...")
	selection_deactivated_message = span_notice_alt("Вы отменяете приказ.")

/datum/action/cooldown/ai_program/ranged/repair_nanites/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	if(!isrobot(target) && !isapc(target) && !ismecha(target) && !ismachineperson(target) && !isbot(target))
		to_chat(user, span_warning("Ремонтировать можно только киборгов, экзокостюмы и ЛКП!"))
		revert_cast()
		return
	if(ismachineperson(target) && !user.universal_adapter)
		to_chat(user, span_warning("Программе не хватает нужного улучшения, чтобы ремонтировать КПБ!"))
		revert_cast()
		return
	if(isbot(target) && spell_level < 2)
		to_chat(user, span_warning("Программа недостаточно улучшена, чтобы ремонтировать роботов!"))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	if(ismecha(target) || isapc(target))
		var/obj/T = target
		T.obj_integrity = min(T.max_integrity, T.obj_integrity + (T.max_integrity * (0.2 + min(0.3, (0.1 * spell_level)))))
	if(isrobot(target) || isbot(target))
		var/mob/living/T = target
		var/damage_healed = 20 + (min(30, (10 * spell_level)))
		T.heal_overall_damage(damage_healed, damage_healed)
	if(ismachineperson(target))
		var/mob/living/carbon/human/T = target
		var/damage_healed = user.adapter_efficiency * (20 + (min(30, (10 * spell_level))))
		T.heal_overall_damage(damage_healed, damage_healed, TRUE, FALSE, TRUE)
	user.play_sound_remote(target, 'sound/goonstation/misc/fuse.ogg', 50)
	camera_beam(target, "medbeam", 'icons/effects/beam.dmi', 10)

/datum/action/cooldown/ai_program/ranged/repair_nanites/on_purchase_upgrade()
	set_recharge_duration(max(initial(cooldown_time) - (max(spell_level - 3, 0) * 30 SECONDS), cooldown_min))

/datum/ai_program/universal_adapter
	program_name = "Универсальный адаптер"
	program_id = "universal_adapter"
	description = "Улучшенная прошивка позволяет применять шунт питания и ремонтные наниты к КПБ с половинной эффективностью."
	unlock_text = "Установка универсального адаптера завершена!"
	upgrade = TRUE

/datum/ai_program/universal_adapter/upgrade(mob/living/silicon/ai/user, first_install = FALSE)
	..()
	if(!istype(user))
		return
	user.universal_adapter = TRUE
	user.adapter_efficiency = 0.5 + (0.1 * upgrade_level)
	installed = TRUE

/datum/ai_program/universal_adapter/downgrade(mob/living/silicon/ai/user)
	..()
	if(!istype(user))
		return
	user.adapter_efficiency = 0.5 + (0.1 * upgrade_level)

/datum/ai_program/universal_adapter/uninstall(mob/living/silicon/ai/user)
	..()
	if(!istype(user))
		return
	user.adapter_efficiency = 0.5
	user.universal_adapter = FALSE

/datum/ai_program/airlock_restoration
	program_name = "Восстановление шлюзов"
	program_id = "airlock_restoration"
	description = "Чинит провода шлюза, если провод управления ИИ не перерезан."
	cost = 2
	nanite_cost = 25
	power_type = /datum/action/cooldown/ai_program/ranged/airlock_restoration
	unlock_text = "Установка прошивки ремонта и управления шлюзами завершена!"

/datum/action/cooldown/ai_program/ranged/airlock_restoration
	name = "Восстановление шлюзов"
	desc = "Чинит провода шлюза, у которого цел провод управления ИИ."
	button_icon = 'icons/obj/doors/doorint.dmi'
	button_icon_state = "door_closed"
	cooldown_time = 60 SECONDS
	cooldown_min = 60 SECONDS
	level_max = 5
	selection_activated_message = span_notice_alt("Вы готовитесь направить ремонтные наниты к шлюзу...")
	selection_deactivated_message = span_notice_alt("Вы отменяете запрос.")

/datum/action/cooldown/ai_program/ranged/airlock_restoration/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	var/obj/machinery/door/airlock/airlock = target
	if(!istype(airlock))
		to_chat(user, span_warning("Ремонтировать можно только шлюзы!"))
		revert_cast()
		return
	if(airlock.wires.is_cut(WIRE_AI_CONTROL))
		to_chat(user, span_warning("Ошибка: нет соединения со шлюзом!"))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	var/turf/T = get_turf(airlock)
	var/duration = (6 - spell_level) SECONDS
	user.playsound_local(user, 'sound/items/deconstruct.ogg', 50, FALSE, use_reverb = FALSE)
	camera_beam(airlock, "rped_upgrade", 'icons/effects/effects.dmi', 5)
	var/obj/effect/temp_visual/rcd_effect/spawning_effect = new(T)
	spawning_effect.duration = duration
	QDEL_IN(spawning_effect, duration)
	if(do_after(user, duration, airlock, DEFAULT_DOAFTER_IGNORE|DA_IGNORE_TARGET_LOC_CHANGE, interaction_key = airlock, max_interact_count = 1))
		airlock.wires.repair()
		playsound(T, 'sound/items/deconstruct.ogg', 100, TRUE)
		if(spell_level >= 5)
			airlock.emagged = FALSE

/datum/action/cooldown/ai_program/ranged/airlock_restoration/on_purchase_upgrade()
	if(spell_level == 5)
		desc += " Версия прошивки позволяет устранять повреждения от криптографического секвенсора."
		build_all_button_icons(UPDATE_BUTTON_NAME)

/datum/ai_program/extinguishing_system
	program_name = "Автоматическое пожаротушение"
	program_id = "extinguishing_system"
	description = "Отправляет к цели сгусток нанофроста, быстро гасящий плазменные пожары."
	nanite_cost = 50
	power_type = /datum/action/cooldown/ai_program/ranged/extinguishing_system
	unlock_text = "Синтезатор нанофроста запущен."

/datum/action/cooldown/ai_program/ranged/extinguishing_system
	name = "Автоматическое пожаротушение"
	desc = "Отправляет к цели сгусток нанофроста, быстро гасящий плазменные пожары."
	button_icon = 'icons/effects/effects.dmi'
	button_icon_state = "frozen_smoke_capsule"
	cooldown_time = 60 SECONDS
	cooldown_min = 30 SECONDS
	level_max = 3
	selection_activated_message = span_notice_alt("Вы готовитесь синтезировать сгусток нанофроста...")
	selection_deactivated_message = span_notice_alt("Вы даёте нанофросту рассеяться.")

/datum/action/cooldown/ai_program/ranged/extinguishing_system/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	var/turf/target_turf = get_turf(target)
	if(!check_camera_vision(user, target_turf))
		revert_cast()
		return
	if(!isturf(target_turf))
		to_chat(user, span_warning("Сюда нельзя отправить нанофрост!"))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	var/obj/effect/nanofrost_container/nanofrost = new /obj/effect/nanofrost_container(target_turf)
	log_game("[key_name(user)] used Nanofrost at [get_area(target_turf)] ([target_turf.x], [target_turf.y], [target_turf.z]).")
	user.play_sound_remote(target_turf, 'sound/items/syringeproj.ogg', 40)
	camera_beam(target_turf, "rped_upgrade", 'icons/effects/effects.dmi', 5)
	addtimer(CALLBACK(nanofrost, TYPE_PROC_REF(/obj/effect/nanofrost_container, Smoke)), 5 SECONDS)

/datum/action/cooldown/ai_program/ranged/extinguishing_system/on_purchase_upgrade()
	set_recharge_duration(max(initial(cooldown_time) - (spell_level * 15 SECONDS), cooldown_min))

/datum/ai_program/bluespace_miner
	program_name = "Блюспейс-майнер"
	program_id = "bluespace_miner"
	description = "Вы подключаетесь к миниатюрному блюспейс-сборщику, который приносит доход на счёт научного отдела ценой роста энергопотребления вашего ядра."
	unlock_text = "Установка блюспейс-майнера завершена!"
	upgrade = TRUE

/datum/ai_program/bluespace_miner/upgrade(mob/living/silicon/ai/user, first_install = FALSE)
	..()
	if(!istype(user))
		return
	user.bluespace_miner_rate = 100 + (100 * upgrade_level)
	user.next_payout = 10 MINUTES + world.time
	user.bluespace_miner = TRUE
	installed = TRUE

/datum/ai_program/bluespace_miner/downgrade(mob/living/silicon/ai/user)
	..()
	if(!istype(user))
		return
	user.bluespace_miner_rate = 100 + (100 * upgrade_level)

/datum/ai_program/bluespace_miner/uninstall(mob/living/silicon/ai/user)
	..()
	if(!istype(user))
		return
	user.bluespace_miner_rate = 100
	user.bluespace_miner = FALSE

/datum/ai_program/multimarket_analyser
	program_name = "Анализ рынков"
	program_id = "multimarket_analyser"
	description = "Вы подключаетесь к цифровой торговой площадке и сверяете цены всех заказов станции, находя лучшие предложения! Ящики в отделе снабжения дешевеют!"
	unlock_text = "Обнаружена онлайн-площадка... подключено!"
	max_level = 6
	upgrade = TRUE

/datum/ai_program/multimarket_analyser/upgrade(mob/living/silicon/ai/user, first_install = FALSE)
	..()
	if(!istype(user))
		return
	user.market_price_modifier = 0.95 - (0.05 * upgrade_level)
	installed = TRUE
	SSshuttle.refresh_supply_prices()

/datum/ai_program/multimarket_analyser/downgrade(mob/living/silicon/ai/user)
	..()
	if(!installed || !istype(user))
		return
	user.market_price_modifier = 0.95 - (0.05 * upgrade_level)
	SSshuttle.refresh_supply_prices()

/datum/ai_program/multimarket_analyser/uninstall(mob/living/silicon/ai/user)
	..()
	if(!istype(user))
		return
	user.market_price_modifier = 1
	SSshuttle.refresh_supply_prices()

/datum/ai_program/light_repair
	program_name = "Синтезатор ламп"
	program_id = "light_repair"
	description = "Заменяет повреждённые или отсутствующие лампы."
	nanite_cost = 5
	power_type = /datum/action/cooldown/ai_program/ranged/light_repair
	unlock_text = "Конфигурация заменителя ламп установлена."

/datum/action/cooldown/ai_program/ranged/light_repair
	name = "Синтезатор ламп"
	desc = "Заменяет повреждённые или отсутствующие лампы."
	button_icon = 'icons/obj/janitor.dmi'
	button_icon_state = "lightreplacer0"
	cooldown_time = 30 SECONDS
	cooldown_min = 5 SECONDS
	level_max = 5
	selection_activated_message = span_notice_alt("Вы готовитесь синтезировать лампу...")
	selection_deactivated_message = span_notice_alt("Вы отменяете запрос.")

/datum/action/cooldown/ai_program/ranged/light_repair/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	var/turf/target_turf = get_turf(target)
	if(!check_camera_vision(user, target_turf))
		revert_cast()
		return
	var/repaired = FALSE
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	for(var/obj/machinery/light/light in target_turf.contents)
		if(light.status == LIGHT_OK)
			continue
		light.status = LIGHT_OK
		light.switchcount = 0
		light.emagged = FALSE
		light.on = light.has_power()
		light.update(TRUE, TRUE)
		user.play_sound_remote(light, 'sound/machines/ding.ogg', 50)
		camera_beam(light, "rped_upgrade", 'icons/effects/effects.dmi', 5)
		repaired = TRUE

	if(!repaired)
		to_chat(user, span_warning("Чинить можно только лампы!"))
		user.program_picker.refund_nanites(program.nanite_cost)
		revert_cast()
		return

/datum/action/cooldown/ai_program/ranged/light_repair/on_purchase_upgrade()
	set_recharge_duration(max(initial(cooldown_time) - (spell_level * 5 SECONDS), cooldown_min))

/datum/ai_program/nanosurgeon_deployment
	program_name = "Нанохирурги"
	program_id = "nanosurgeon_deployment"
	description = "Лечит члена экипажа роем роботизированных наномашин!"
	cost = 3
	nanite_cost = 75
	power_type = /datum/action/cooldown/ai_program/ranged/nanosurgeon_deployment
	unlock_text = "Установка прошивки хирургических наномашин завершена!"

/datum/action/cooldown/ai_program/ranged/nanosurgeon_deployment
	name = "Нанохирурги"
	desc = "Лечит члена экипажа роем роботизированных наномашин!"
	button_icon = 'icons/obj/surgery.dmi'
	button_icon_state = "scalpel_laser1_on"
	cooldown_time = 150 SECONDS
	cooldown_min = 30 SECONDS
	level_max = 10
	selection_activated_message = span_notice_alt("Вы готовитесь приказать наномашинам лечить органику...")
	selection_deactivated_message = span_notice_alt("Вы отменяете приказ.")

/datum/action/cooldown/ai_program/ranged/nanosurgeon_deployment/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	var/mob/living/carbon/human/patient = target
	if(!istype(patient) || ismachineperson(patient))
		to_chat(user, span_warning("Лечить можно только органический экипаж!"))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	user.play_sound_remote(patient, 'sound/magic/magic_block.ogg', 50)
	camera_beam(patient, "medbeam", 'icons/effects/beam.dmi', 5 SECONDS)
	var/allow_moving = FALSE
	if(spell_level == level_max)
		allow_moving = TRUE
		to_chat(patient, span_notice("Вы чувствуете, как из ближайшей камеры к вам струится поток лечебных нанитов."))
	else
		to_chat(patient, span_notice("Вы чувствуете, как из ближайшей камеры к вам струится поток лечебных нанитов. Не двигайтесь, чтобы они сработали!"))
	var/doafter_flags = DEFAULT_DOAFTER_IGNORE
	if(allow_moving)
		doafter_flags |= DA_IGNORE_TARGET_LOC_CHANGE
	if(!do_after(user, 5 SECONDS, patient, doafter_flags))
		user.program_picker.refund_nanites(program.nanite_cost)
		revert_cast()
		return
	if(!check_camera_vision(user, patient))
		user.program_picker.refund_nanites(program.nanite_cost)
		revert_cast()
		return
	var/damage_healed = 20 + (min(30, (10 * spell_level)))
	patient.heal_overall_damage(damage_healed, damage_healed)
	if(spell_level >= 5)
		for(var/obj/item/organ/external/limb as anything in patient.bodyparts)
			if(prob(10 * spell_level))
				limb.mend_fracture()
				limb.stop_internal_bleeding()

/datum/action/cooldown/ai_program/ranged/nanosurgeon_deployment/on_purchase_upgrade()
	set_recharge_duration(max(initial(cooldown_time) - (max(spell_level - 3, 0) * 30 SECONDS), cooldown_min))

/datum/ai_program/enhanced_doors
	program_name = "Улучшенное управление шлюзами"
	program_id = "enhanced_doors"
	description = "Вы улучшаете подпрограммы управления шлюзами и быстрее взламываете шлюзы с отключённым управлением ИИ: на 15% за каждый уровень."
	unlock_text = "Шлюзы подключены и оптимизированы. Вы чувствуете себя как дома."
	upgrade = TRUE

/datum/ai_program/enhanced_doors/upgrade(mob/living/silicon/ai/user, first_install = FALSE)
	..()
	if(!istype(user))
		return
	user.airlock_hack_modifier = 1 - (upgrade_level * 0.15)
	installed = TRUE

/datum/ai_program/enhanced_doors/downgrade(mob/living/silicon/ai/user)
	..()
	user.airlock_hack_modifier = 1 - (upgrade_level * 0.15)

/datum/ai_program/enhanced_doors/uninstall(mob/living/silicon/ai/user)
	..()
	user.airlock_hack_modifier = 1

/datum/ai_program/research_subsystem
	program_name = "Экспериментальные исследования"
	program_id = "research_subsystem"
	description = "Ваши процессоры вращают центрифуги и изучают результаты. Вы открываете новый уровень исследований в случайной области."
	cost = 5
	max_level = 10
	unlock_text = "Установка подмодуля исследований завершена. Автоматический сбор данных включён."
	upgrade = TRUE

/datum/ai_program/research_subsystem/upgrade(mob/living/silicon/ai/user, first_install = FALSE)
	..()
	if(!istype(user))
		return
	user.research_level = upgrade_level
	user.research_time = 10 MINUTES - (30 SECONDS * upgrade_level)
	if(first_install)
		user.last_research_time = 10 MINUTES - (30 SECONDS * upgrade_level)
	user.research_subsystem = TRUE
	installed = TRUE

/datum/ai_program/research_subsystem/downgrade(mob/living/silicon/ai/user)
	..()
	if(!istype(user))
		return
	user.research_level = upgrade_level
	user.research_time = 10 MINUTES - (30 SECONDS * upgrade_level)

/datum/ai_program/research_subsystem/uninstall(mob/living/silicon/ai/user)
	..()
	if(!istype(user))
		return
	user.research_time = 10 MINUTES
	user.research_subsystem = FALSE

/datum/ai_program/emergency_sealant
	program_name = "Аварийный герметик"
	program_id = "emergency_sealant"
	description = "Покрывает область металлической пеной, быстро заделывая пробоины в корпусе."
	cost = 2
	nanite_cost = 50
	power_type = /datum/action/cooldown/ai_program/ranged/emergency_sealant
	unlock_text = "Синтезатор металлической пены запущен."

/datum/action/cooldown/ai_program/ranged/emergency_sealant
	name = "Аварийный герметик"
	desc = "Покрывает область металлической пеной, быстро заделывая пробоины в корпусе."
	button_icon = 'icons/obj/structures.dmi'
	button_icon_state = "reinforced"
	cooldown_time = 180 SECONDS
	cooldown_min = 30 SECONDS
	level_max = 5
	selection_activated_message = span_notice_alt("Вы наполняете баллон металлической пеной...")
	selection_deactivated_message = span_notice_alt("Вы растворяете неиспользованный баллон.")

/datum/action/cooldown/ai_program/ranged/emergency_sealant/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	user.play_sound_remote(target, 'sound/effects/bubbles2.ogg', 50)
	new /obj/effect/temp_visual/ai_sealant(get_turf(target))
	addtimer(CALLBACK(src, PROC_REF(do_metal_foam), get_turf(target)), 10 SECONDS)

/datum/action/cooldown/ai_program/ranged/emergency_sealant/proc/do_metal_foam(turf/target)
	camera_beam(target, "rped_upgrade", 'icons/effects/effects.dmi', 15)
	var/datum/effect_system/fluid_spread/foam/metal/foam = new()
	foam.set_up(range = 2, location = target)
	foam.start()

/datum/action/cooldown/ai_program/ranged/emergency_sealant/on_purchase_upgrade()
	set_recharge_duration(max(initial(cooldown_time) - (spell_level * 30 SECONDS), cooldown_min))

/datum/ai_program/holosign_displayer
	program_name = "Проектор голознаков"
	program_id = "holosign_displayer"
	description = "Проецирует голографический знак, предупреждающий экипаж о возможной опасности."
	nanite_cost = 10
	power_type = /datum/action/cooldown/ai_program/ranged/holosign_displayer
	unlock_text = "Голографический проектор запущен."

/datum/action/cooldown/ai_program/ranged/holosign_displayer
	name = "Проектор голознаков"
	desc = "Проецирует голографический знак, предупреждающий экипаж о возможной опасности."
	button_icon = 'icons/obj/device.dmi'
	button_icon_state = "signmaker"
	cooldown_time = 30 SECONDS
	cooldown_min = 30 SECONDS
	level_max = 8
	selection_activated_message = span_notice_alt("Вы запускаете проектор...")
	selection_deactivated_message = span_notice_alt("Вы останавливаете проектор.")
	var/static/list/sign_choices = list(
		"Инженерный барьер" = /obj/structure/holosign/barrier/engineering,
		"Барьер охраны" = /obj/structure/holosign/barrier,
		"Мокрый пол" = /obj/structure/holosign/wetsign,
	)

/datum/action/cooldown/ai_program/ranged/holosign_displayer/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	var/sign_id = tgui_input_list(user, "Выберите голознак!", "ИИ", sign_choices)
	if(!sign_id)
		return
	var/sign_type = sign_choices[sign_id]
	if(!sign_type)
		revert_cast()
		return
	var/obj/structure/holosign/sign = new sign_type(get_turf(target), src)
	addtimer(CALLBACK(src, PROC_REF(sign_timer_complete), sign), (60 + 30 * spell_level) SECONDS, TIMER_UNIQUE)
	user.play_sound_remote(target, 'sound/machines/click.ogg', 20)
	camera_beam(target, "rped_upgrade", 'icons/effects/effects.dmi', 5)

/datum/action/cooldown/ai_program/ranged/holosign_displayer/proc/sign_timer_complete(obj/structure/holosign/sign)
	if(QDELETED(sign))
		return
	playsound(sign.loc, 'sound/machines/chime.ogg', 20, 1)
	qdel(sign)

/datum/ai_program/honk_subsystem
	program_name = "Хонк-подсистема"
	program_id = "honk_subsystem"
	description = "Загружает программу с Clowns.NT, позволяющую по запросу воспроизводить звук велосипедного гудка."
	nanite_cost = 5
	power_type = /datum/action/cooldown/ai_program/ranged/honk_subsystem
	unlock_text = "Honker.exe установлен."

/datum/action/cooldown/ai_program/ranged/honk_subsystem
	name = "Хонк-подсистема"
	desc = "Загружает программу с Clowns.NT, позволяющую по запросу воспроизводить звук велосипедного гудка."
	button_icon = 'icons/obj/items.dmi'
	button_icon_state = "bike_horn"
	cooldown_time = 30 SECONDS
	cooldown_min = 15 SECONDS
	level_max = 10
	selection_activated_message = span_notice_alt("Вы готовитесь хонкнуть...")
	selection_deactivated_message = span_notice_alt("Вы снижаете уровень юмора в своих подсистемах.")

/datum/action/cooldown/ai_program/ranged/honk_subsystem/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	if(spell_level >= 10)
		user.play_sound_remote(target, 'sound/items/airhorn.ogg', 50)
	else
		user.play_sound_remote(target, 'sound/items/bikehorn.ogg', 50)

/datum/action/cooldown/ai_program/ranged/honk_subsystem/on_purchase_upgrade()
	set_recharge_duration(max(initial(cooldown_time) - (spell_level * 15 SECONDS), cooldown_min))

/datum/ai_program/enhanced_tracker
	program_name = "Улучшенное слежение"
	program_id = "enhanced_tracker"
	description = "Новая прошивка камер автоматически оповещает, когда интересующая персона попадает в обзор камер."
	cost = 5
	power_type = /datum/action/cooldown/ai_program/enhanced_tracker
	unlock_text = "Программа пометки и слежения запущена."
	max_level = 8

/datum/ai_program/enhanced_tracker/upgrade(mob/living/silicon/ai/user, first_install = FALSE)
	..()
	if(!istype(user))
		return
	user.enhanced_tracking = TRUE
	user.alarms_listend_for |= "Tracking"
	user.enhanced_tracking_delay = initial(user.enhanced_tracking_delay) - (upgrade_level * 1 SECONDS)

/datum/ai_program/enhanced_tracker/downgrade(mob/living/silicon/ai/user)
	..()
	user.enhanced_tracking_delay = initial(user.enhanced_tracking_delay) - (upgrade_level * 1 SECONDS)

/datum/ai_program/enhanced_tracker/uninstall(mob/living/silicon/ai/user)
	..()
	user.enhanced_tracking = FALSE
	user.alarms_listend_for -= "Tracking"
	user.enhanced_tracking_delay = initial(user.enhanced_tracking_delay)

/datum/action/cooldown/ai_program/enhanced_tracker
	name = "Улучшенное слежение"
	desc = "Выберите цель, чтобы получать оповещения о её появлении на камерах."
	button_icon = 'icons/obj/items.dmi'
	button_icon_state = "videocam"
	cooldown_time = 10 SECONDS
	cooldown_min = 10 SECONDS
	level_max = 8

/datum/action/cooldown/ai_program/enhanced_tracker/cast(atom/target, mob/living/silicon/ai/user)
	if(!istype(user))
		return
	var/target_name = tgui_input_list(user, "Выберите цель для слежения...", "ИИ", user.trackable_mobs())
	if(!target_name)
		user.set_tracked_mob(null)
		return
	user.set_tracked_mob(isnull(user.track.humans[target_name]) ? user.track.others[target_name] : user.track.humans[target_name])

/mob/living/silicon/ai/proc/set_tracked_mob(mob/new_target)
	if(tracked_mob)
		UnregisterSignal(tracked_mob, COMSIG_QDELETING)
	tracked_mob = new_target
	if(tracked_mob)
		RegisterSignal(tracked_mob, COMSIG_QDELETING, PROC_REF(on_tracked_mob_deleted))

/mob/living/silicon/ai/proc/on_tracked_mob_deleted(datum/source)
	SIGNAL_HANDLER
	tracked_mob = null

/mob/living/silicon/ai/proc/raise_tracking_alert(area/A, mob/target)
	var/obj/machinery/camera/closest_camera
	for(var/obj/machinery/camera/C in A)
		if(isnull(closest_camera))
			closest_camera = C
			continue
		if(get_dist(closest_camera, target) > get_dist(C, target))
			closest_camera = C
			continue
	if(!closest_camera)
		return
	closest_camera.visible_message(span_warning("На камере вспыхивает фиолетовый огонёк!"))
	if(GLOB.alarm_manager.trigger_alarm("Tracking", A, A.cameras, closest_camera))
		addtimer(CALLBACK(GLOB.alarm_manager, TYPE_PROC_REF(/datum/alarm_manager, cancel_alarm), "Tracking", A, closest_camera), 1 MINUTES)

/mob/living/silicon/ai/proc/reset_tracker_cooldown()
	tracker_alert_cooldown = FALSE

/datum/ai_program/pointer
	program_name = "Голоуказатель"
	program_id = "holopointer"
	description = "Проецирует голограмму, чтобы предупредить или подозвать экипаж."
	nanite_cost = 5
	power_type = /datum/action/cooldown/ai_program/ranged/pointer
	unlock_text = "Голоизлучатели запущены."

/datum/action/cooldown/ai_program/ranged/pointer
	name = "Голоуказатель"
	desc = "Проецирует голограмму, чтобы предупредить или подозвать экипаж."
	button_icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	button_icon_state = "target_circle"
	cooldown_time = 15 SECONDS
	cooldown_min = 15 SECONDS
	level_max = 1
	selection_activated_message = span_notice_alt("Вы готовитесь спроецировать голограмму...")
	selection_deactivated_message = span_notice_alt("Вы выключаете проектор.")

/datum/action/cooldown/ai_program/ranged/pointer/cast(atom/target, mob/living/silicon/ai/user)
	if(!target)
		to_chat(user, span_warning("Нет подходящей цели!"))
		revert_cast()
		return
	if(!check_camera_vision(user, target))
		revert_cast()
		return
	if(!user.program_picker.spend_nanites(program.nanite_cost))
		to_chat(user, span_warning("Недостаточно нанитов!"))
		revert_cast()
		return
	new /obj/effect/temp_visual/ai_pointer(get_turf(target))
