#define BIOMONITOR_HISTORY_LENGTH 30
#define BIOMONITOR_THREADY_PULSE 250

/obj/item/organ/internal/cyberimp/brain/biomonitor
	name = "Vita-Link biomonitor implant"
	desc = "Нейроинтерфейс, выводящий на сетчатку полный отчёт о состоянии организма: расу, диету, голод, кровь, проблемы со здоровьем и установленные импланты."
	implant_color = "#00E5FF"
	slot = INTERNAL_ORGAN_BRAIN_BIOMONITOR
	cyber_cost = 6
	origin_tech = "materials=3;programming=4;biotech=4"
	actions_types = list(/datum/action/item_action/organ_action/biomonitor)
	ignore_cybernetic_restrictions = TRUE
	var/list/health_history = list()
	var/list/pulse_history = list()
	var/static/list/incompatible_species = list(SPECIES_NUCLEATION, SPECIES_MACHINEPERSON, SPECIES_PLASMAMAN)
	var/static/alist/food_type_names = alist(
		MEAT = "мясные блюда",
		VEGETABLES = "овощи",
		RAW = "сырую пищу",
		JUNKFOOD = "фастфуд",
		GRAIN = "злаки и выпечку",
		FRUIT = "фрукты",
		DAIRY = "молочные продукты",
		FRIED = "жареную пищу",
		ALCOHOL = "алкоголь",
		SUGAR = "сладости",
		EGG = "яйца",
		GROSS = "сомнительную еду",
		TOXIC = "токсичные продукты",
	)
	var/static/alist/material_names = alist(
		MATERIAL_CLASS_CLOTH = "ткань",
		MATERIAL_CLASS_TECH = "электронику",
		MATERIAL_CLASS_SOAP = "мыло",
	)

/datum/action/item_action/organ_action/biomonitor
	name = "Открыть биомонитор"

/obj/item/organ/internal/cyberimp/brain/biomonitor/get_ru_names()
	return alist(
		NOMINATIVE = "биомонитор \"Вита-Линк\"",
		GENITIVE = "биомонитора \"Вита-Линк\"",
		DATIVE = "биомонитору \"Вита-Линк\"",
		ACCUSATIVE = "биомонитор \"Вита-Линк\"",
		INSTRUMENTAL = "биомонитором \"Вита-Линк\"",
		PREPOSITIONAL = "биомониторе \"Вита-Линк\"",
	)

/obj/item/organ/internal/cyberimp/brain/biomonitor/can_insert(mob/living/user, mob/living/carbon/target, fail_message = "Данное устройство не предусмотрено для существ с подобной анатомией.")
	. = ..()
	if(!.)
		return
	if(ishuman(target) && !(target.dna.species.name in incompatible_species))
		return
	if(user && fail_message)
		to_chat(user, span_warning(fail_message))
	return FALSE

/obj/item/organ/internal/cyberimp/brain/biomonitor/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	SStgui.close_uis(src)
	health_history.Cut()
	pulse_history.Cut()
	return ..()

/obj/item/organ/internal/cyberimp/brain/biomonitor/on_life()
	. = ..()
	health_history += max(round(owner.health), 0)
	pulse_history += owner.pulse == PULSE_THREADY ? BIOMONITOR_THREADY_PULSE : text2num(owner.get_pulse(GETPULSE_TOOL))
	if(length(health_history) > BIOMONITOR_HISTORY_LENGTH)
		health_history.Cut(1, 2)
		pulse_history.Cut(1, 2)

/obj/item/organ/internal/cyberimp/brain/biomonitor/ui_action_click(mob/user, datum/action/action, leftclick)
	var/datum/tgui/open_ui = SStgui.get_open_ui(user, src)
	if(open_ui)
		open_ui.close()
		return
	ui_interact(user)

/obj/item/organ/internal/cyberimp/brain/biomonitor/ui_state(mob/user)
	return GLOB.conscious_state

/obj/item/organ/internal/cyberimp/brain/biomonitor/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "BioMonitor", DECLENT_RU_CAP(src, NOMINATIVE))
	if(ui.open())
		user.playsound_local(get_turf(user), 'sound/machines/terminal_on.ogg', 50, FALSE)

/obj/item/organ/internal/cyberimp/brain/biomonitor/ui_close(mob/user)
	user.playsound_local(get_turf(user), 'sound/machines/terminal_off.ogg', 50, FALSE)

/obj/item/organ/internal/cyberimp/brain/biomonitor/ui_data(mob/user)
	if(!ishuman(owner))
		return list()

	var/datum/species/species = owner.dna.species
	return list(
		"name" = owner.real_name,
		"species" = capitalize(GET_RU_SPECIES_NAME(species.name)),
		"scan" = medical_scan_results(owner),
		"exotic_blood" = !!species.exotic_blood,
		"nutrition" = get_nutrition_data(),
		"diet" = get_diet_summary(species),
		"implants" = get_implants_data(),
		"cyber" = list(
			"capacity" = owner.cyber_capacity,
			"load" = owner.get_cyber_load(),
			"max" = CYBER_CAPACITY_MAX,
		),
		"health_history" = health_history,
		"pulse_history" = pulse_history,
		"history_length" = BIOMONITOR_HISTORY_LENGTH,
	)

/obj/item/organ/internal/cyberimp/brain/biomonitor/proc/get_diet_summary(datum/species/species)
	. = list()
	var/liked = get_flag_names(species.liked_food & ~(species.toxic_food | species.disliked_food), food_type_names)
	if(liked)
		. += list(list("text" = "Организм лучше всего принимает [liked].", "tone" = "good"))
	var/disliked = get_flag_names(species.disliked_food & ~species.toxic_food, food_type_names)
	if(disliked)
		. += list(list("text" = "Без удовольствия воспримет [disliked].", "tone" = "average"))
	var/toxic = get_flag_names(species.toxic_food, food_type_names)
	if(toxic)
		. += list(list("text" = "Плохо переносит [toxic]: возможны тошнота и рвота.", "tone" = "bad"))
	var/special = get_flag_names(species.special_diet, material_names)
	if(special)
		. += list(list("text" = "Также способен переваривать [special].", "tone" = ""))
	if(isdiona(owner))
		. += list(list("text" = "Основное питание получает от света, через фотосинтез.", "tone" = ""))
	if(!length(.))
		. += list(list("text" = "Особых пищевых предпочтений нет.", "tone" = ""))

/obj/item/organ/internal/cyberimp/brain/biomonitor/proc/get_flag_names(flags, alist/names)
	var/list/matched = list()
	for(var/flag, label in names)
		if(flags & flag)
			matched += label
	return length(matched) ? russian_list(matched) : null

/obj/item/organ/internal/cyberimp/brain/biomonitor/proc/get_nutrition_data()
	if(HAS_TRAIT(owner, TRAIT_NO_HUNGER))
		return list("required" = FALSE)

	var/state
	var/severity = "good"
	switch(owner.nutrition)
		if(NUTRITION_LEVEL_FULL to INFINITY)
			state = "Переедание"
			severity = "average"
		if(NUTRITION_LEVEL_WELL_FED to NUTRITION_LEVEL_FULL)
			state = "Полная сытость"
		if(NUTRITION_LEVEL_FED to NUTRITION_LEVEL_WELL_FED)
			state = "Сытость"
		if(NUTRITION_LEVEL_HUNGRY to NUTRITION_LEVEL_FED)
			state = "Норма"
		if(NUTRITION_LEVEL_STARVING to NUTRITION_LEVEL_HUNGRY)
			state = "Голод"
			severity = "average"
		else
			state = "Истощение"
			severity = "bad"

	return list(
		"required" = TRUE,
		"value" = owner.nutrition,
		"max" = NUTRITION_LEVEL_FAT,
		"state" = state,
		"severity" = severity,
	)

/obj/item/organ/internal/cyberimp/brain/biomonitor/proc/get_implants_data()
	. = list()
	for(var/obj/item/organ/internal/cyberimp/implant in owner.internal_organs)
		. += list(list(
			"name" = DECLENT_RU_CAP(implant, NOMINATIVE),
			"kind" = "Кибернетика",
			"status" = implant.crit_fail ? "Сбой" : "В норме",
			"failed" = !!implant.crit_fail,
			"cost" = implant.cyber_cost,
		))

	for(var/obj/item/implant/chip in owner.contents)
		var/status = "Готов"
		if(chip.uses == 0)
			status = "Разряжен"
		else if(chip.uses > 0)
			status = "Зарядов: [chip.uses]"
		else if(chip.activated == BIOCHIP_ACTIVATED_PASSIVE)
			status = "Активен"
		. += list(list(
			"name" = DECLENT_RU_CAP(chip, NOMINATIVE),
			"kind" = "Био-чип",
			"status" = status,
			"failed" = chip.uses == 0,
		))

#undef BIOMONITOR_HISTORY_LENGTH
#undef BIOMONITOR_THREADY_PULSE
