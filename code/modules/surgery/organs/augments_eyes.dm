/obj/item/organ/internal/cyberimp/eyes
	name = "cybernetic eyes"
	desc = "Искусственные фоторецепторы со специальными функциями."
	icon_state = "eye_implant"
	implant_overlay = "eye_implant_overlay"
	slot = INTERNAL_ORGAN_EYE_SIGHT_DEVICE
	cyber_cost = 8
	parent_organ_zone = BODY_ZONE_PRECISE_EYES
	w_class = WEIGHT_CLASS_TINY

	var/vision_flags = 0
	var/see_in_dark = 0
	var/see_invisible = SEE_INVISIBLE_LIVING
	var/lighting_cutoff = LIGHTING_CUTOFF_VISIBLE
	var/list/color_cutoffs

	var/eye_colour = "#000000" // Should never be null
	var/flash_protect = FLASH_PROTECTION_NONE
	var/aug_message = "Ваше зрение улучшено!"
	var/vision_disabled = FALSE
	var/static/list/eye_colour_presets = list("#FF3C46", "#F3E600", "#5EF6FF", "#7DFF6A", "#B48CFF", "#FF8A00", "#FFFFFF", "#101010")

/obj/item/organ/internal/cyberimp/eyes/get_ru_names()
	return alist(
		NOMINATIVE = "глазной имплант",
		GENITIVE = "глазного импланта",
		DATIVE = "глазному импланту",
		ACCUSATIVE = "глазной имплант",
		INSTRUMENTAL = "глазным имплантом",
		PREPOSITIONAL = "глазном импланте",
	)

/obj/item/organ/internal/cyberimp/eyes/insert(mob/living/carbon/M, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	var/mob/living/carbon/human/H = M
	if(istype(H) && eye_colour)
		H.update_body() //Apply our eye colour to the target.
	if(aug_message && !special)
		to_chat(owner, span_notice("[aug_message]"))
	M.update_sight()

/obj/item/organ/internal/cyberimp/eyes/remove(mob/living/carbon/M, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	M.update_sight()

/obj/item/organ/internal/cyberimp/eyes/get_ripper_settings()
	. = ..()
	. += list(list(
		"id" = "eye_colour",
		"name" = "Цвет радужки",
		"kind" = "color",
		"value" = eye_colour,
		"options" = eye_colour_presets | initial(eye_colour),
	))
	if(initial(vision_flags) || initial(see_in_dark) || initial(lighting_cutoff) != LIGHTING_CUTOFF_VISIBLE)
		. += list(list("id" = "vision", "name" = "Режим зрения", "kind" = "toggle", "value" = !vision_disabled))

/obj/item/organ/internal/cyberimp/eyes/set_ripper_setting(setting, value)
	switch(setting)
		if("eye_colour")
			eye_colour = value
			var/mob/living/carbon/human/human_owner = owner
			if(istype(human_owner))
				human_owner.update_body()
			return TRUE
		if("vision")
			vision_disabled = !value
			apply_vision()
			return TRUE
	return ..()

/obj/item/organ/internal/cyberimp/eyes/on_block_changed()
	apply_vision()

/obj/item/organ/internal/cyberimp/eyes/proc/vision_active()
	return !vision_disabled && !blocked

/obj/item/organ/internal/cyberimp/eyes/proc/apply_vision()
	var/active = vision_active()
	vision_flags = active ? initial(vision_flags) : NONE
	see_in_dark = active ? initial(see_in_dark) : 0
	lighting_cutoff = active ? initial(lighting_cutoff) : LIGHTING_CUTOFF_VISIBLE
	owner?.update_sight()

/obj/item/organ/internal/cyberimp/eyes/proc/generate_icon(mob/living/carbon/human/HA)
	var/mob/living/carbon/human/H = HA
	if(!istype(H))
		H = owner
	var/icon/cybereyes_icon = new /icon('icons/mob/human_face.dmi', H.dna.species.eyes)
	cybereyes_icon.Blend(eye_colour, ICON_ADD) // Eye implants override native DNA eye color

	return cybereyes_icon

/obj/item/organ/internal/cyberimp/eyes/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF || !owner)
		return

	if(severity > 1)
		if(prob(10 * severity))
			return

	to_chat(owner, span_warning("Помехи застилают вам глаза!"))

	if(HAS_TRAIT(owner, TRAIT_ADVANCED_CYBERIMPLANTS))
		owner.EyeBlurry(1.5 SECONDS)
	else
		owner.flash_eyes(3, visual = TRUE)

/obj/item/organ/internal/cyberimp/eyes/meson
	name = "meson scanner implant"
	cyber_cost = 6
	desc = "Кибернетические глаза, показывающие устройство станции и, ну, всё остальное."
	eye_colour = "#199900"
	icon_state = "mesonhud_implant"
	implant_overlay = null
	origin_tech = "materials=4;engineering=4;biotech=4;magnets=4"
	vision_flags = SEE_TURFS
	lighting_cutoff = LIGHTING_CUTOFF_MEDIUM
	aug_message = "Внезапно вы понимаете, какой же на станции бардак..."

/obj/item/organ/internal/cyberimp/eyes/meson/get_ru_names()
	return alist(
		NOMINATIVE = "имплант мезонного сканера",
		GENITIVE = "импланта мезонного сканера",
		DATIVE = "импланту мезонного сканера",
		ACCUSATIVE = "имплант мезонного сканера",
		INSTRUMENTAL = "имплантом мезонного сканера",
		PREPOSITIONAL = "импланте мезонного сканера",
	)

/obj/item/organ/internal/cyberimp/eyes/meson/insert(mob/living/carbon/human/user_human, special = FALSE)
	if(vision_active())
		ADD_TRAIT(user_human, TRAIT_MESON_VISION, UNIQUE_TRAIT_SOURCE(src))
	return ..()

/obj/item/organ/internal/cyberimp/eyes/meson/apply_vision()
	if(owner)
		if(vision_active())
			ADD_TRAIT(owner, TRAIT_MESON_VISION, UNIQUE_TRAIT_SOURCE(src))
		else
			REMOVE_TRAIT(owner, TRAIT_MESON_VISION, UNIQUE_TRAIT_SOURCE(src))
	return ..()

/obj/item/organ/internal/cyberimp/eyes/meson/remove(mob/living/carbon/human/user_human, special = FALSE)
	REMOVE_TRAIT(user_human, TRAIT_MESON_VISION, UNIQUE_TRAIT_SOURCE(src))
	return ..()

/obj/item/organ/internal/cyberimp/eyes/xray
	name = "X-ray implant"
	cyber_cost = 25
	desc = "Глазные импланты, дающие рентгеновское зрение. Моргать бесполезно."
	icon_state = "eyes-c-xray"
	implant_overlay = null
	origin_tech = "materials=4;programming=4;biotech=7;magnets=4"
	vision_flags = SEE_MOBS | SEE_OBJS | SEE_TURFS
	see_in_dark = 8
	lighting_cutoff = LIGHTING_CUTOFF_HIGH

/obj/item/organ/internal/cyberimp/eyes/xray/get_ru_names()
	return alist(
		NOMINATIVE = "имплант рентгеновского зрения",
		GENITIVE = "импланта рентгеновского зрения",
		DATIVE = "импланту рентгеновского зрения",
		ACCUSATIVE = "имплант рентгеновского зрения",
		INSTRUMENTAL = "имплантом рентгеновского зрения",
		PREPOSITIONAL = "импланте рентгеновского зрения",
	)

/obj/item/organ/internal/cyberimp/eyes/thermals
	name = "Thermals implant"
	cyber_cost = 20
	desc = "Глазные импланты, дающие тепловое зрение. Вертикальные зрачки в комплекте."
	icon_state = "thermal_implant"
	implant_overlay = null
	eye_colour = "#FFCC00"
	vision_flags = SEE_MOBS
	lighting_cutoff = LIGHTING_CUTOFF_MEDIUM
	flash_protect = FLASH_PROTECTION_SENSITIVE
	origin_tech = "materials=5;programming=4;biotech=4;magnets=4"
	aug_message = "Куда ни глянь, всюду добыча..."

/obj/item/organ/internal/cyberimp/eyes/thermals/get_ru_names()
	return alist(
		NOMINATIVE = "имплант теплового зрения",
		GENITIVE = "импланта теплового зрения",
		DATIVE = "импланту теплового зрения",
		ACCUSATIVE = "имплант теплового зрения",
		INSTRUMENTAL = "имплантом теплового зрения",
		PREPOSITIONAL = "импланте теплового зрения",
	)

/obj/item/organ/internal/cyberimp/eyes/thermals/empproof
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/eyes/scope
	name = "Kaleido Optics eyes"
	desc = "Эти кибернетические глазные импланты позволят вам приближать далёкие объекты. Многие пользователи находят это дезориентирующим и им трудно взаимодействовать с предметами вблизи, когда имплант активен."
	icon_state = "eyes-c-kaleido"
	eye_colour = "#6f00ff"
	flash_protect = FLASH_PROTECTION_EXTRA_SENSITIVE
	origin_tech = "materials=5;programming=4;biotech=4;magnets=4"
	materials = list(MAT_METAL = 600, MAT_GLASS = 600)
	var/scope_range = 0.8 //Only used in initialize. Greatly nerfed zoom range, since you are not taking the time zoom delay the lwap has.
	var/active = FALSE

/obj/item/organ/internal/cyberimp/eyes/scope/get_ru_names()
	return alist(
		NOMINATIVE = "глазной имплант \"Калейдо Оптикс\"",
		GENITIVE = "глазного импланта \"Калейдо Оптикс\"",
		DATIVE = "глазному импланту \"Калейдо Оптикс\"",
		ACCUSATIVE = "глазной имплант \"Калейдо Оптикс\"",
		INSTRUMENTAL = "глазным имплантом \"Калейдо Оптикс\"",
		PREPOSITIONAL = "глазном импланте \"Калейдо Оптикс\"",
	)

/obj/item/organ/internal/cyberimp/eyes/scope/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/scope, zoom_method = ZOOM_METHOD_ITEM_ACTION, range_modifier = scope_range, item_action_type = /datum/action/item_action/organ_action/toggle, flags = SCOPE_CLICK_MIDDLE)

/obj/item/organ/internal/cyberimp/eyes/scope/insert(mob/living/carbon/human/M, special)
	. = ..()
	flash_protect = FLASH_PROTECTION_NONE //Resets it to none, so we can just flip to inital each time it is used.

/obj/item/organ/internal/cyberimp/eyes/scope/ui_action_click(mob/user, actiontype)
	active = !active
	if(active)
		flash_protect = initial(flash_protect)
	else
		flash_protect = FLASH_PROTECTION_NONE

/obj/item/organ/internal/cyberimp/eyes/scope/hardened
	name = "Hardened Kaleido Optics eyes"
	desc = "Эти кибернетические глазные импланты позволят вам приближать далёкие объекты. Многие пользователи находят это дезориентирующим и им трудно взаимодействовать с предметами вблизи, когда имплант активен. Эта пара была усилена для персонала специальных операций и обладает улучшенной функцией приближения."
	flash_protect = FLASH_PROTECTION_SENSITIVE
	origin_tech = "materials=6;programming=5;biotech=6;magnets=6;syndicate=3"
	scope_range = 1.25
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/eyes/scope/hardened/get_ru_names()
	return alist(
		NOMINATIVE = "укреплённый глазной имплант \"Калейдо Оптикс\"",
		GENITIVE = "укреплённого глазного импланта \"Калейдо Оптикс\"",
		DATIVE = "укреплённому глазному импланту \"Калейдо Оптикс\"",
		ACCUSATIVE = "укреплённый глазной имплант \"Калейдо Оптикс\"",
		INSTRUMENTAL = "укреплённым глазным имплантом \"Калейдо Оптикс\"",
		PREPOSITIONAL = "укреплённом глазном импланте \"Калейдо Оптикс\"",
	)

// HUD implants
/obj/item/organ/internal/cyberimp/eyes/hud
	name = "HUD implant"
	desc = "Кибернетические глаза, выводящие HUD поверх всего, что вы видите. Наверное."
	slot = INTERNAL_ORGAN_EYE_HUD_DEVICE
	cyber_cost = 6
	var/HUDType = 0
	var/hud_disabled = FALSE
	/// A list of extension kinds added to the examine text. Things like medical or security records.
	var/examine_extensions = EXAMINE_HUD_NONE

/obj/item/organ/internal/cyberimp/eyes/hud/get_ru_names()
	return alist(
		NOMINATIVE = "имплант HUD",
		GENITIVE = "импланта HUD",
		DATIVE = "импланту HUD",
		ACCUSATIVE = "имплант HUD",
		INSTRUMENTAL = "имплантом HUD",
		PREPOSITIONAL = "импланте HUD",
	)

/obj/item/organ/internal/cyberimp/eyes/hud/get_ripper_settings()
	. = ..()
	if(HUDType)
		. += list(list("id" = "hud", "name" = "Отображение HUD", "kind" = "toggle", "value" = !hud_disabled))

/obj/item/organ/internal/cyberimp/eyes/hud/set_ripper_setting(setting, value)
	if(setting != "hud" || !HUDType)
		return ..()
	hud_disabled = !value
	apply_hud()
	return TRUE

/obj/item/organ/internal/cyberimp/eyes/hud/on_block_changed()
	. = ..()
	apply_hud()

/obj/item/organ/internal/cyberimp/eyes/hud/proc/apply_hud()
	if(!owner || !HUDType)
		return
	var/datum/atom_hud/hud = GLOB.huds[HUDType]
	if(hud_disabled || blocked)
		hud.hide_from(owner)
	else
		hud.show_to(owner)

/obj/item/organ/internal/cyberimp/eyes/hud/insert(mob/living/carbon/M, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(HUDType && !hud_disabled && !blocked)
		var/datum/atom_hud/H = GLOB.huds[HUDType]
		H.show_to(M)

/obj/item/organ/internal/cyberimp/eyes/hud/remove(mob/living/carbon/M, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(HUDType)
		var/datum/atom_hud/H = GLOB.huds[HUDType]
		H.hide_from(M)

/obj/item/organ/internal/cyberimp/eyes/hud/medical
	name = "Medical HUD implant"
	desc = "Глазные импланты, выводящие медицинский HUD поверх всего, что вы видите."
	icon_state = "medhud_implant"
	implant_overlay = null
	eye_colour = "#0000D0"
	origin_tech = "materials=4;programming=4;biotech=4"
	aug_message = "Над головами людей вдруг появляются полоски здоровья..."
	HUDType = DATA_HUD_MEDICAL_ADVANCED
	examine_extensions = EXAMINE_HUD_MEDICAL

/obj/item/organ/internal/cyberimp/eyes/hud/medical/get_ru_names()
	return alist(
		NOMINATIVE = "имплант медицинского HUD",
		GENITIVE = "импланта медицинского HUD",
		DATIVE = "импланту медицинского HUD",
		ACCUSATIVE = "имплант медицинского HUD",
		INSTRUMENTAL = "имплантом медицинского HUD",
		PREPOSITIONAL = "импланте медицинского HUD",
	)

/obj/item/organ/internal/cyberimp/eyes/hud/diagnostic
	name = "Diagnostic HUD implant"
	desc = "Глазные импланты, выводящие диагностический HUD поверх всего, что вы видите."
	icon_state = "diagnosticalhud_implant"
	implant_overlay = null
	eye_colour = "#723E02"
	origin_tech = "materials=4;engineering=4;biotech=4"
	aug_message = "Вы видите диагностику окружающих синтетиков..."
	HUDType = DATA_HUD_DIAGNOSTIC

/obj/item/organ/internal/cyberimp/eyes/hud/diagnostic/get_ru_names()
	return alist(
		NOMINATIVE = "имплант диагностического HUD",
		GENITIVE = "импланта диагностического HUD",
		DATIVE = "импланту диагностического HUD",
		ACCUSATIVE = "имплант диагностического HUD",
		INSTRUMENTAL = "имплантом диагностического HUD",
		PREPOSITIONAL = "импланте диагностического HUD",
	)

/obj/item/organ/internal/cyberimp/eyes/hud/security
	name = "Security HUD implant"
	desc = "Глазные импланты, выводящие HUD охраны поверх всего, что вы видите."
	icon_state = "sechud_implant"
	implant_overlay = null
	eye_colour = "#D00000"
	origin_tech = "materials=4;programming=4;biotech=3;combat=3"
	aug_message = "Перед глазами всплывают значки должностей. А это не сертифицированный хирург..."
	HUDType = DATA_HUD_SECURITY_ADVANCED
	examine_extensions = EXAMINE_HUD_SECURITY_READ | EXAMINE_HUD_SECURITY_WRITE

/obj/item/organ/internal/cyberimp/eyes/hud/security/get_ru_names()
	return alist(
		NOMINATIVE = "имплант HUD охраны",
		GENITIVE = "импланта HUD охраны",
		DATIVE = "импланту HUD охраны",
		ACCUSATIVE = "имплант HUD охраны",
		INSTRUMENTAL = "имплантом HUD охраны",
		PREPOSITIONAL = "импланте HUD охраны",
	)

/obj/item/organ/internal/cyberimp/eyes/hud/hydroponic
	name = "Hydroponic HUD implant"
	desc = "Глазные импланты, выводящие ботанический HUD поверх всего, что вы видите."
	icon_state = "eye_implant_hydro"
	implant_overlay = null
	origin_tech = "materials=4;magnets=4;biotech=4"
	materials = list(MAT_METAL = 600, MAT_GLASS = 600, MAT_SILVER = 700, MAT_GOLD = 500)
	aug_message = "Вы высматриваете вокруг себя непластиковые растения..."
	HUDType = DATA_HUD_HYDROPONIC

/obj/item/organ/internal/cyberimp/eyes/hud/hydroponic/get_ru_names()
	return alist(
		NOMINATIVE = "имплант ботанического HUD",
		GENITIVE = "импланта ботанического HUD",
		DATIVE = "импланту ботанического HUD",
		ACCUSATIVE = "имплант ботанического HUD",
		INSTRUMENTAL = "имплантом ботанического HUD",
		PREPOSITIONAL = "импланте ботанического HUD",
	)

/obj/item/organ/internal/cyberimp/eyes/hud/science
	name = "Science HUD implant"
	desc = "Глазные импланты со встроенным анализатором предметов и реагентов."
	icon_state = "sciencehud_implant"
	item_state = "sciencehud_implant"
	implant_overlay = null
	eye_colour = "#923DAC"
	origin_tech = "materials=4;programming=4;biotech=4"
	aug_message = "Вы видите технологическую природу окружающих вещей."
	examine_extensions = EXAMINE_HUD_SCIENCE
	actions_types = list(/datum/action/item_action/toggle_research_scanner)

/obj/item/organ/internal/cyberimp/eyes/hud/science/get_ru_names()
	return alist(
		NOMINATIVE = "имплант научного HUD",
		GENITIVE = "импланта научного HUD",
		DATIVE = "импланту научного HUD",
		ACCUSATIVE = "имплант научного HUD",
		INSTRUMENTAL = "имплантом научного HUD",
		PREPOSITIONAL = "импланте научного HUD",
	)

// Welding shield implant
/obj/item/organ/internal/cyberimp/eyes/shield
	name = "welding shield implant"
	desc = "Реактивные микрощитки защищают глаза от сварки и вспышек, не мешая обзору."
	icon_state = "welding_implant"
	implant_overlay = null
	slot = INTERNAL_ORGAN_EYE_SHIELD_DEVICE
	cyber_cost = 10
	origin_tech = "materials=4;biotech=3;engineering=4;plasmatech=3"
	flash_protect = FLASH_PROTECTION_WELDER
	emp_proof = TRUE
	// Welding with thermals will still hurt your eyes a bit.

/obj/item/organ/internal/cyberimp/eyes/shield/get_ru_names()
	return alist(
		NOMINATIVE = "имплант сварочного щита",
		GENITIVE = "импланта сварочного щита",
		DATIVE = "импланту сварочного щита",
		ACCUSATIVE = "имплант сварочного щита",
		INSTRUMENTAL = "имплантом сварочного щита",
		PREPOSITIONAL = "импланте сварочного щита",
	)

/obj/item/organ/internal/cyberimp/eyes/hud/universal
	name = "universal HUD implant"
	desc = "Устанавливает подходящий вашей должности ИЛС имплант. Менее приоритетный, чем выбранные вручную импланты."
	icon_state = "universal_implant"
	implant_overlay = null
	aug_message = "Этот имплант не имеет смысла..."

/obj/item/organ/internal/cyberimp/eyes/hud/universal/get_ru_names()
	return alist(
		NOMINATIVE = "универсальный ИЛС имплант",
		GENITIVE = "универсального ИЛС импланта",
		DATIVE = "универсальному ИЛС импланту",
		ACCUSATIVE = "универсальный ИЛС имплант",
		INSTRUMENTAL = "универсальным ИЛС имплантом",
		PREPOSITIONAL = "универсальном ИЛС импланте",
	)

// MARK: mini map implant
/obj/item/organ/internal/cyberimp/eyes/map
	name = "citizen map implant"
	desc = "Имплант для постоянного отображения мини-карты в правом верхнем углу поля зрения пользователя с помощью технологии дополненной реальности."
	icon_state = "citizen_map_implant"
	implant_overlay = null
	eye_colour = "#4255e6"
	slot = INTERNAL_ORGAN_EYE_HUD_DEVICE
	cyber_cost = 4
	origin_tech = "materials=4;biotech=3;engineering=4;plasmatech=3"
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	var/active = FALSE
	/// Z level for draw
	var/current_z_level
	/// Last mini map redraw turf
	var/turf/current_turf
	/// The various images and icons for the map are stored in here, as well as the actual big map itself.
	var/datum/station_holomap/holomap_datum
	/// Global station map crop position x (bottom left)
	var/crop_x = 0
	/// Global station map crop position y (bottom left)
	var/crop_y = 0
	/// Global station map crop size
	var/crop_size = 80
	/// Markers auto refresh interval
	var/refresh_interval = 1 SECONDS
	/// Markers auto refresh timer id
	var/refresh_timer_id = null
	/// Current cropped minimap
	var/map_image = null
	/// Marker icons and pixel positions over the minimap
	var/list/markers = list()
	/// Cached marker icons
	var/static/list/marker_icon_cache = list()

/obj/item/organ/internal/cyberimp/eyes/map/get_ru_names()
	return alist(
		NOMINATIVE = "имплант гражданской карты",
		GENITIVE = "импланта гражданской карты",
		DATIVE = "импланту гражданской карты",
		ACCUSATIVE = "имплант гражданской карты",
		INSTRUMENTAL = "имплантом гражданской карты",
		PREPOSITIONAL = "импланте гражданской карты",
	)

/obj/item/organ/internal/cyberimp/eyes/map/Destroy()
	if(active && owner)
		hide_mini_map(owner)
	else
		stop_mini_map(owner)
	return ..()

/obj/item/organ/internal/cyberimp/eyes/map/remove(mob/living/carbon/target, special)
	. = ..()
	hide_mini_map(target)


/obj/item/organ/internal/cyberimp/eyes/map/proc/is_implanted_minimap_implant(mob/living/carbon/target, implant_type)
	var/obj/item/organ/internal/eye_implant = target.get_organ_slot(INTERNAL_ORGAN_EYE_HUD_DEVICE)
	return istype(eye_implant, implant_type)

/obj/item/organ/internal/cyberimp/eyes/map/ui_state(mob/user)
	return GLOB.not_incapacitated_state

/obj/item/organ/internal/cyberimp/eyes/map/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		if(QDELETED(user.client))
			return
		var/datum/tgui_window/window = user.client.tgui_windows[SKIN_MINIMAP_PANEL]
		if(!window)
			window = new /datum/tgui_window(user.client, SKIN_MINIMAP_PANEL)
		position_mini_map_window(user.client)
		ui = new(user, src, "MapImplant", name)
		ui.set_autoupdate(FALSE)
		if(ui.open(window))
			winset(user.client, SKIN_MINIMAP_PANEL_ELEM, "is-visible=true")

/obj/item/organ/internal/cyberimp/eyes/map/ui_close(mob/user)
	if(active)
		stop_mini_map(user)
	if(!QDELETED(user?.client))
		winset(user.client, SKIN_MINIMAP_PANEL_ELEM, "is-visible=false")

/obj/item/organ/internal/cyberimp/eyes/map/ui_data(mob/user)
	var/list/data = list()
	data["map"] = map_image
	data["markers"] = markers
	data["size"] = crop_size
	data["z"] = current_z_level
	return data

/obj/item/organ/internal/cyberimp/eyes/map/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "close")
		hide_mini_map(ui.user)
		return TRUE

/obj/item/organ/internal/cyberimp/eyes/map/proc/position_mini_map_window(client/target_client)
	if(!target_client)
		return
	var/map_size = winget(target_client, SKIN_MAPWINDOW, "size")
	var/list/size_parts = splittext(map_size, "x")
	if(length(size_parts) < 2)
		return
	var/window_width = text2num(size_parts[1])
	if(!window_width)
		return
	var/panel_x = max(8, window_width - MINIMAP_PANEL_WIDTH - 8)
	winset(target_client, SKIN_MINIMAP_PANEL_ELEM, "pos=[panel_x],8;size=[MINIMAP_PANEL_WIDTH]x[MINIMAP_PANEL_HEIGHT]")

/obj/item/organ/internal/cyberimp/eyes/map/ui_action_click(mob/user, datum/action/action, leftclick)
	if(active)
		hide_mini_map(user)
	else if(!show_mini_map(user))
		active = FALSE

/obj/item/organ/internal/cyberimp/eyes/map/proc/show_mini_map(mob/user)
	if(!user?.client)
		return FALSE

	stop_mini_map(user)
	active = TRUE
	current_z_level = user.z
	holomap_datum = new()
	setup_holomap(user)
	if(!holomap_datum)
		// Something is very wrong if we have to un-fuck ourselves here.
		stack_trace("Mini holomap at [user.name]([COORD(user)]) couldn't setup holomap_datum.")
		to_chat(user, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] сбоит и выдает сообщение: \"ОШИБКА: NTOS не отвечает.\""))
		active = FALSE
		return FALSE

	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(check_position))
	refresh_timer_id = addtimer(CALLBACK(src, PROC_REF(refresh_overlays), user), refresh_interval, TIMER_LOOP | TIMER_STOPPABLE)
	ui_interact(user)

	if(holomap_datum.bogus)
		to_chat(user, span_warning("Ошибка инициализации голокарты. Этот сектор пространства невозможно отобразить."))
	else
		to_chat(user, span_warning("В правом верхнем углу появляется голографическая проекция станции."))

	return TRUE

/obj/item/organ/internal/cyberimp/eyes/map/proc/setup_holomap(mob/user)
	if(!holomap_datum)
		return
	current_turf = get_turf(user)
	if(!current_turf)
		return
	crop_x = HOLOMAP_CENTER_X + current_turf.x - round(crop_size / 2)
	crop_y = HOLOMAP_CENTER_X + current_turf.y - round(crop_size / 2)
	var/list/crop_params = list(CROP_X1 = crop_x, CROP_Y1 = crop_y, CROP_X2 = crop_x + crop_size, CROP_Y2 = crop_y + crop_size)
	holomap_datum.initialize_holomap(current_turf, current_z_level, reinit_base_map = TRUE, show_legend = FALSE, crop = crop_params)
	update_map_image()
	update_map_markers(user)

/obj/item/organ/internal/cyberimp/eyes/map/proc/update_map_image()
	map_image = null
	if(holomap_datum?.map_icon)
		map_image = icon2base64(holomap_datum.map_icon)

/obj/item/organ/internal/cyberimp/eyes/map/proc/update_map_markers(mob/user)
	markers = list()
	if(!holomap_datum)
		return
	for(var/image/marker as anything in holomap_datum.create_overlays(handle_overlays(user)))
		var/list/icon_data = get_marker_icon(marker)
		if(!icon_data)
			continue
		markers += list(list(
			"frames" = icon_data["frames"],
			"x" = marker.pixel_x + marker.pixel_w,
			"y" = marker.pixel_y + marker.pixel_z,
			"w" = icon_data["width"],
			"h" = icon_data["height"],
			"duration" = icon_data["duration"],
			"is_self" = marker.icon_state == "you",
		))

/obj/item/organ/internal/cyberimp/eyes/map/proc/get_marker_icon(image/marker)
	if(!marker?.icon || !marker.icon_state)
		return null
	var/cache_key = "[marker.icon]:[marker.icon_state]:[marker.dir || SOUTH]"
	if(!marker_icon_cache[cache_key])
		var/frame_count = 1
		var/duration = 0.1
		var/list/metadata = icon_metadata(marker.icon)
		if(islist(metadata) && islist(metadata["states"]))
			for(var/list/state_data as anything in metadata["states"])
				if(state_data["name"] != marker.icon_state)
					continue
				var/list/delays = state_data["delay"]
				if(islist(delays) && length(delays))
					frame_count = length(delays)
					duration = 0
					for(var/delay in delays)
						duration += delay
					duration = max(duration / 10, 0.1)
				break

		var/list/frame_icons = list()
		var/frame_width = 0
		var/frame_height = 0
		for(var/frame_index in 1 to frame_count)
			var/icon/frame_icon = icon(marker.icon, marker.icon_state, marker.dir || SOUTH, frame_index)
			if(!frame_width)
				frame_width = frame_icon.Width()
				frame_height = frame_icon.Height()
			frame_icons += icon2base64(frame_icon)

		marker_icon_cache[cache_key] = list(
			"frames" = frame_icons,
			"width" = frame_width,
			"height" = frame_height,
			"duration" = duration,
		)
	return marker_icon_cache[cache_key]


/obj/item/organ/internal/cyberimp/eyes/map/proc/handle_overlays(mob/user)
	// Each entry in this list contains the text for the legend, and the icon and icon_state use. Null or non-existent icon_state ignore hiding logic.
	// If an entry contains an icon,
	var/list/legend = list() //+ GLOB.holomap_default_legend

	var/list/z_transitions = SSholomaps.holomap_z_transitions["[current_z_level]"]
	if(length(z_transitions))
		legend += z_transitions
	return legend

/obj/item/organ/internal/cyberimp/eyes/map/proc/create_overlay_icon(icon_name, turf/target_loc, list/output)
	if(target_loc.z != current_z_level || !is_in_crop_area(target_loc))
		return
	var/image/overlay_icon = image('icons/misc/8x8.dmi', icon_state = icon_name)
	overlay_icon.pixel_w = HOLOMAP_CENTER_X + target_loc.x - crop_x - 1
	overlay_icon.pixel_z = HOLOMAP_CENTER_Y + target_loc.y - crop_y - 1
	output += overlay_icon

/obj/item/organ/internal/cyberimp/eyes/map/proc/create_overlays_entry(list/overlays, name, icon_name, list/markers)
	if(!length(markers))
		return
	overlays[name] = list("icon" = image('icons/misc/8x8.dmi', icon_state = icon_name), "markers" = markers)

/obj/item/organ/internal/cyberimp/eyes/map/proc/is_in_crop_area(turf/target)
	return target.x >= (current_turf.x - crop_size / 2)  && target.x <= (current_turf.x + crop_size / 2)\
		&& target.y >= (current_turf.y - crop_size / 2)  && target.y <= (current_turf.y + crop_size / 2)


/obj/item/organ/internal/cyberimp/eyes/map/proc/check_position(mob/moved_mob)
	SIGNAL_HANDLER

	if(!active || !moved_mob?.client)
		return

	current_z_level = moved_mob.z
	setup_holomap(moved_mob)
	SStgui.update_uis(src)

/obj/item/organ/internal/cyberimp/eyes/map/proc/refresh_overlays(mob/user)
	if(!active || !user?.client || !holomap_datum)
		return
	update_map_markers(user)
	SStgui.update_uis(src)

/obj/item/organ/internal/cyberimp/eyes/map/proc/hide_mini_map(mob/user)
	stop_mini_map(user)
	if(!user)
		return
	to_chat(user, span_interface("Мини-карта исчезает."))
	var/datum/tgui/ui = SStgui.get_open_ui(user, src)
	if(ui)
		ui.close(TRUE)
	if(!QDELETED(user.client))
		winset(user.client, SKIN_MINIMAP_PANEL_ELEM, "is-visible=false")

/obj/item/organ/internal/cyberimp/eyes/map/proc/stop_mini_map(mob/user)
	if(refresh_timer_id)
		deltimer(refresh_timer_id)
		refresh_timer_id = null
	if(user && !QDELETED(user))
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	active = FALSE
	current_turf = null
	map_image = null
	markers = list()
	QDEL_NULL(holomap_datum)


/obj/item/organ/internal/cyberimp/eyes/map/security
	name = "security map implant "
	desc = "Имплант для постоянного отображения мини-карты в правом верхнем углу поля зрения пользователя с помощью технологии дополненной реальности. Показывает владельцев импланта защиты разума."
	icon_state = "security_map_implant"
	eye_colour = "#e41618"

/obj/item/organ/internal/cyberimp/eyes/map/security/get_ru_names()
	return alist(
		NOMINATIVE = "имплант карты охраны",
		GENITIVE = "импланта карты охраны",
		DATIVE = "импланту карты охраны",
		ACCUSATIVE = "имплант карты охраны",
		INSTRUMENTAL = "имплантом карты охраны",
		PREPOSITIONAL = "импланте карты охраны",
	)

/obj/item/organ/internal/cyberimp/eyes/map/security/handle_overlays(mob/user)
	var/list/extra_overlays = ..()
	if(holomap_datum.bogus)
		return extra_overlays

	var/list/mindshields = list()
	for(var/mob/living/carbon/human/check as anything in GLOB.human_list)
		if(check == user)
			continue
		if(!ismindshielded(check) && !is_implanted_minimap_implant(check, /obj/item/organ/internal/cyberimp/eyes/map/security))
			continue
		var/turf/check_turf = get_turf(check)
		create_overlay_icon("security", check_turf, mindshields)

	create_overlays_entry(extra_overlays, "Mindshields", icon_name = "security", markers = mindshields)
	return extra_overlays


/obj/item/organ/internal/cyberimp/eyes/map/ert
	name = "special reaction team map implant "
	desc = "Имплант для постоянного отображения мини-карты в правом верхнем углу поля зрения пользователя с помощью технологии дополненной реальности. Показывает членов ОБР."
	icon_state = "security_map_implant"
	eye_colour = "#e41618"

/obj/item/organ/internal/cyberimp/eyes/map/ert/get_ru_names()
	return alist(
		NOMINATIVE = "имплант карты ОБР",
		GENITIVE = "импланта карты ОБР",
		DATIVE = "импланту карты ОБР",
		ACCUSATIVE = "имплант карты ОБР",
		INSTRUMENTAL = "имплантом карты ОБР",
		PREPOSITIONAL = "импланте карты ОБР",
	)

/obj/item/organ/internal/cyberimp/eyes/map/ert/handle_overlays(mob/user)
	var/list/extra_overlays = ..()
	if(holomap_datum.bogus)
		return extra_overlays

	var/list/mindshields = list()
	var/list/ert_mindshieds = list()
	for(var/mob/living/carbon/human/check as anything in GLOB.human_list)
		if(check == user)
			continue
		var/turf/check_turf = get_turf(check)
		if(isertmindshielded(check) || is_implanted_minimap_implant(check, /obj/item/organ/internal/cyberimp/eyes/map/ert))
			create_overlay_icon("ert", check_turf, ert_mindshieds)
		else if(ismindshielded(check) || is_implanted_minimap_implant(check, /obj/item/organ/internal/cyberimp/eyes/map/security))
			create_overlay_icon("security", check_turf, mindshields)

	create_overlays_entry(extra_overlays, "ERT Members", icon_name = "ert", markers = ert_mindshieds)
	create_overlays_entry(extra_overlays, "Mindshields", icon_name = "security", markers = mindshields)
	return extra_overlays

/obj/item/organ/internal/cyberimp/eyes/map/medical
	name = "medical map implant "
	desc = "Имплант для постоянного отображения мини-карты в правом верхнем углу поля зрения пользователя с помощью технологии дополненной реальности. Показывает медицинские датчики и критическе состояния."
	icon_state = "medical_map_implant"
	eye_colour = "#00e3e3"

/obj/item/organ/internal/cyberimp/eyes/map/medical/get_ru_names()
	return alist(
		NOMINATIVE = "имплант медицинской карты",
		GENITIVE = "импланта медицинской карты",
		DATIVE = "импланту медицинской карты",
		ACCUSATIVE = "имплант медицинской карты",
		INSTRUMENTAL = "имплантом медицинской карты",
		PREPOSITIONAL = "импланте медицинской карты",
	)

/obj/item/organ/internal/cyberimp/eyes/map/medical/handle_overlays(mob/user)
	var/list/extra_overlays = ..()
	if(holomap_datum.bogus)
		return extra_overlays

	var/list/death_bodies = list()
	var/list/critical_states = list()
	var/list/medical_sensors = list()
	for(var/mob/living/carbon/human/check as anything in GLOB.human_list)
		if(check == user)
			continue
		var/turf/check_turf = get_turf(check)
		if(check.is_dead())
			create_overlay_icon("death_body", check_turf, death_bodies)
		else if(check.is_in_crit())
			create_overlay_icon("critical_state", check_turf, critical_states)
		else if(hassensorlevel(check, SUIT_SENSOR_TRACKING))
			create_overlay_icon("medical_sensor", check_turf, medical_sensors)

	create_overlays_entry(extra_overlays, "Death bodies", icon_name = "death_body", markers = death_bodies)
	create_overlays_entry(extra_overlays, "Critical states", icon_name = "critical_state", markers = critical_states)
	create_overlays_entry(extra_overlays, "Medical sensors", icon_name = "medical_sensor", markers = medical_sensors)
	return extra_overlays


/obj/item/organ/internal/cyberimp/eyes/map/fire
	name = "fire map implant "
	desc = "Имплант для постоянного отображения мини-карты в правом верхнем углу поля зрения пользователя с помощью технологии дополненной реальности. Показывает отсеки с активной пожарной сигнализацией."
	icon_state = "fire_map_implant"
	eye_colour = "#0abd33"

/obj/item/organ/internal/cyberimp/eyes/map/fire/get_ru_names()
	return alist(
		NOMINATIVE = "имплант пожарной карты",
		GENITIVE = "импланта пожарной карты",
		DATIVE = "импланту пожарной карты",
		ACCUSATIVE = "имплант пожарной карты",
		INSTRUMENTAL = "имплантом пожарной карты",
		PREPOSITIONAL = "импланте пожарной карты",
	)

/obj/item/organ/internal/cyberimp/eyes/map/fire/handle_overlays(mob/user)
	var/list/extra_overlays = ..()
	if(holomap_datum.bogus)
		return extra_overlays

	var/list/fire_alarms = list()
	for(var/obj/machinery/firealarm/alarm as anything in GLOB.station_fire_alarms["[current_z_level]"])
		if(!alarm?.myArea?.fire)
			continue
		var/alarm_turf = get_turf(alarm)
		create_overlay_icon("fire_marker", alarm_turf, fire_alarms)

	var/list/air_alarms = list()
	for(var/obj/machinery/alarm/air_alarm in GLOB.air_alarms)
		var/area/alarms = get_area(air_alarm)
		if(alarms?.atmosalm == ATMOS_ALARM_NONE)
			continue
		var/alarm_turf = get_turf(air_alarm)
		create_overlay_icon("atmos_marker", alarm_turf, air_alarms)

	create_overlays_entry(extra_overlays, "Fire Alarms", icon_name = "fire_marker", markers = fire_alarms)
	create_overlays_entry(extra_overlays, "Air Alarms", icon_name = "atmos_marker", markers = air_alarms)
	return extra_overlays


/obj/item/organ/internal/cyberimp/eyes/map/nuke
	name = "nuke ops map implant "
	desc = "Имплант для постоянного отображения мини-карты в правом верхнем углу поля зрения пользователя с помощью технологии дополненной реальности. Показывает членов вашего отряда и остальных живых целей. Также показывает где находится диск."
	icon_state = "nuke_map_implant"
	eye_colour = "#292929"

/obj/item/organ/internal/cyberimp/eyes/map/nuke/get_ru_names()
	return alist(
		NOMINATIVE = "имплант карты ядерных оперативников",
		GENITIVE = "импланта карты ядерных оперативников",
		DATIVE = "импланту карты ядерных оперативников",
		ACCUSATIVE = "имплант карты ядерных оперативников",
		INSTRUMENTAL = "имплантом карты ядерных оперативников",
		PREPOSITIONAL = "импланте карты ядерных оперативников",
	)

/obj/item/organ/internal/cyberimp/eyes/map/nuke/handle_overlays(mob/user)
	var/list/extra_overlays = ..()
	if(holomap_datum.bogus)
		return extra_overlays

	var/datum/antagonist/nuclear_operative/user_operative = user.mind?.has_antag_datum(/datum/antagonist/nuclear_operative)
	var/list/teammates = list()
	var/list/crew_members = list()
	for(var/mob/living/carbon/human/check as anything in GLOB.human_list)
		if(check == user)
			continue
		var/turf/check_turf = get_turf(check)
		var/datum/antagonist/nuclear_operative/check_operative = check.mind?.has_antag_datum(/datum/antagonist/nuclear_operative)
		if(check_operative && (!user_operative || check_operative.nuclear_team == user_operative.nuclear_team))
			create_overlay_icon("nuker", check_turf, teammates)
		else if(!check.is_dead())
			create_overlay_icon("crew", check_turf, crew_members)

	var/list/nuclear_disks = list()
	for(var/obj/item/disk/nuclear/the_disk in GLOB.poi_list)
		var/turf/disk_location = get_turf(the_disk)
		create_overlay_icon("nuclear_disk", disk_location, nuclear_disks)

	create_overlays_entry(extra_overlays, "Teammates", icon_name = "nuker", markers = teammates)
	create_overlays_entry(extra_overlays, "Crew members", icon_name = "crew", markers = crew_members)
	create_overlays_entry(extra_overlays, "Nuclear authentification disk", icon_name = "nuclear_disk", markers = nuclear_disks)
	return extra_overlays
