GLOBAL_LIST_INIT(preference_limb_names, list(
	BODY_ZONE_CHEST = PREF_ORGANNAME_CHEST,
	BODY_ZONE_PRECISE_GROIN = PREF_ORGANNAME_GROIN,
	BODY_ZONE_HEAD = PREF_ORGANNAME_HEAD,
	BODY_ZONE_L_ARM = PREF_ORGANNAME_L_ARM,
	BODY_ZONE_R_ARM = PREF_ORGANNAME_R_ARM,
	BODY_ZONE_PRECISE_L_HAND = PREF_ORGANNAME_L_HAND,
	BODY_ZONE_PRECISE_R_HAND = PREF_ORGANNAME_R_HAND,
	BODY_ZONE_L_LEG = PREF_ORGANNAME_L_LEG,
	BODY_ZONE_R_LEG = PREF_ORGANNAME_R_LEG,
	BODY_ZONE_PRECISE_L_FOOT = PREF_ORGANNAME_L_FOOT,
	BODY_ZONE_PRECISE_R_FOOT = PREF_ORGANNAME_R_FOOT,
))

GLOBAL_LIST_INIT(preference_organ_names, list(
	INTERNAL_ORGAN_EYES = PREF_ORGANNAME_EYES,
	INTERNAL_ORGAN_EARS = PREF_ORGANNAME_EARS,
	INTERNAL_ORGAN_HEART = PREF_ORGANNAME_HEART,
	INTERNAL_ORGAN_LUNGS = PREF_ORGANNAME_LUNGS,
	INTERNAL_ORGAN_LIVER = PREF_ORGANNAME_LIVER,
	INTERNAL_ORGAN_KIDNEYS = PREF_ORGANNAME_KIDNEYS,
))

/datum/preference_middleware/limbs
	action_delegations = list(
		"edit_limb" = PROC_REF(edit_limb),
		"edit_organ" = PROC_REF(edit_organ),
		"ipc_loadout" = PROC_REF(ipc_loadout),
	)

/datum/preference_middleware/limbs/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	var/datum/species/species = preferences.get_species_prototype()
	var/full_prosthetics = species.bodyflags & ALL_RPARTS
	var/list/limbs = list()
	for(var/zone in GLOB.preference_limb_names)
		if(!full_prosthetics && (zone in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_HEAD)))
			continue
		limbs += list(list(
			"zone" = zone,
			"name" = GLOB.preference_limb_names[zone],
			"status" = describe_status(preferences.organ_data[zone], preferences.rlimb_data[zone]),
		))

	var/list/organs = list()
	if(species.name != SPECIES_SLIMEPERSON && species.name != SPECIES_MACHINEPERSON)
		for(var/slot in GLOB.preference_organ_names)
			organs += list(list(
				"zone" = slot,
				"name" = GLOB.preference_organ_names[slot],
				"status" = describe_status(preferences.organ_data[slot]),
			))

	return list(
		"limbs" = limbs,
		"organs" = organs,
		"ipc_loadout" = species.name == SPECIES_MACHINEPERSON,
	)

/datum/preference_middleware/limbs/post_set_preference(mob/user, preference, value)
	if(preference != "species")
		return
	preferences.organ_data = list()
	preferences.rlimb_data = list()
	preferences.write_preference(GLOB.preference_entries[/datum/preference/toggle/species_preference], FALSE)
	preferences.sanitize_character_preferences()
	preferences.character_preview_view?.update_body()

/datum/preference_middleware/limbs/proc/describe_status(status, company)
	switch(status)
		if(PREF_ORGANSTATUS_AMPUTATED_ENG)
			return PREF_ORGANSTATUS_AMPUTATED_RUS
		if(PREF_ORGANSTATUS_CYBORG_ENG)
			return company ? "[PREF_ORGANSTATUS_CYBERNETIC_RUS] ([company])" : PREF_ORGANSTATUS_CYBERNETIC_RUS
		if(PREF_ORGANSTATUS_CYBERNETIC_ENG)
			return PREF_ORGANSTATUS_CYBERNETIC_RUS
	return PREF_ORGANSTATUS_ORGANIC_RUS

/datum/preference_middleware/limbs/proc/reset_head_appearance()
	for(var/preference_type in list(
		/datum/preference/choiced/accessory/head_accessory,
		/datum/preference/choiced/accessory/alt_head,
		/datum/preference/choiced/accessory/hair,
		/datum/preference/choiced/accessory/facial_hair,
		/datum/preference/choiced/accessory/marking/head,
	))
		var/datum/preference/choiced/accessory/preference = GLOB.preference_entries[preference_type]
		preferences.write_preference(preference, preference.none_value)

/datum/preference_middleware/limbs/proc/finish_edit()
	preferences.sanitize_character_preferences()
	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/limbs/proc/edit_limb(list/params, mob/user)
	var/limb = params["zone"]
	if(!(limb in GLOB.preference_limb_names))
		return FALSE
	var/datum/species/species = preferences.get_species_prototype()
	var/full_prosthetics = species.bodyflags & ALL_RPARTS
	var/limb_name = GLOB.preference_limb_names[limb]
	var/second_limb
	var/third_limb
	var/no_amputate = FALSE
	switch(limb)
		if(BODY_ZONE_CHEST)
			second_limb = BODY_ZONE_PRECISE_GROIN
			no_amputate = TRUE
		if(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_HEAD)
			no_amputate = TRUE
		if(BODY_ZONE_L_LEG)
			second_limb = BODY_ZONE_PRECISE_L_FOOT
		if(BODY_ZONE_R_LEG)
			second_limb = BODY_ZONE_PRECISE_R_FOOT
		if(BODY_ZONE_L_ARM)
			second_limb = BODY_ZONE_PRECISE_L_HAND
		if(BODY_ZONE_R_ARM)
			second_limb = BODY_ZONE_PRECISE_R_HAND
		if(BODY_ZONE_PRECISE_L_FOOT)
			third_limb = full_prosthetics ? null : BODY_ZONE_L_LEG
		if(BODY_ZONE_PRECISE_R_FOOT)
			third_limb = full_prosthetics ? null : BODY_ZONE_R_LEG
		if(BODY_ZONE_PRECISE_L_HAND)
			third_limb = full_prosthetics ? null : BODY_ZONE_L_ARM
		if(BODY_ZONE_PRECISE_R_HAND)
			third_limb = full_prosthetics ? null : BODY_ZONE_R_ARM

	if(!full_prosthetics && (limb in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_HEAD)))
		return FALSE

	var/list/valid_states = list(PREF_ORGANSTATUS_ORGANIC_RUS, PREF_ORGANSTATUS_CYBERNETIC_RUS)
	if(!no_amputate)
		valid_states += PREF_ORGANSTATUS_AMPUTATED_RUS
	if(TRAIT_NO_ROBOPARTS in species.inherent_traits)
		valid_states -= PREF_ORGANSTATUS_CYBERNETIC_RUS

	var/new_state = tgui_input_list(user, "Выберите желаемое состояние части тела", "[limb_name] — изменение состояния", valid_states)
	if(!new_state)
		return FALSE

	switch(new_state)
		if(PREF_ORGANSTATUS_ORGANIC_RUS)
			if(limb == BODY_ZONE_HEAD)
				reset_head_appearance()
			preferences.organ_data[limb] = null
			preferences.rlimb_data[limb] = null
			if(third_limb)
				preferences.organ_data[third_limb] = null
				preferences.rlimb_data[third_limb] = null
		if(PREF_ORGANSTATUS_AMPUTATED_RUS)
			preferences.organ_data[limb] = PREF_ORGANSTATUS_AMPUTATED_ENG
			preferences.rlimb_data[limb] = null
			if(second_limb)
				preferences.organ_data[second_limb] = PREF_ORGANSTATUS_AMPUTATED_ENG
				preferences.rlimb_data[second_limb] = null
		if(PREF_ORGANSTATUS_CYBERNETIC_RUS)
			var/list/robolimb_companies = list()
			for(var/limb_type in typesof(/datum/robolimb))
				var/datum/robolimb/robolimb = new limb_type
				if(!robolimb.unavailable_at_chargen && (limb in robolimb.parts) && robolimb.has_subtypes && (species.name in robolimb.species_allowed))
					robolimb_companies[robolimb.company] = robolimb

			var/choice = tgui_input_list(user, "Выберите фирму-изготовителя для кибернетической части тела", "[limb_name] — выбор фирмы-изготовителя", robolimb_companies)
			if(!choice)
				return FALSE
			var/datum/robolimb/company = GLOB.all_robolimbs[choice]
			var/subchoice
			var/in_model = FALSE
			if(company.has_subtypes == 1)
				var/list/robolimb_models = list()
				for(var/limb_type in typesof(company))
					var/datum/robolimb/model = new limb_type
					if(!(limb in model.parts))
						continue
					robolimb_models[model.company] = model
					if(length(robolimb_models) == 1)
						subchoice = model.company
					if(second_limb in model.parts)
						in_model = TRUE
				if(length(robolimb_models) > 1)
					subchoice = tgui_input_list(user, "Выберите модель \"[choice]\" для части тела", "[limb_name] — выбор модели", robolimb_models)
				if(subchoice)
					choice = subchoice
			if(limb == BODY_ZONE_HEAD)
				reset_head_appearance()
			preferences.rlimb_data[limb] = choice
			preferences.organ_data[limb] = PREF_ORGANSTATUS_CYBORG_ENG
			if(second_limb && (!subchoice || in_model))
				preferences.rlimb_data[second_limb] = choice
				preferences.organ_data[second_limb] = PREF_ORGANSTATUS_CYBORG_ENG

	return finish_edit()

/datum/preference_middleware/limbs/proc/edit_organ(list/params, mob/user)
	var/organ = params["zone"]
	if(!(organ in GLOB.preference_organ_names))
		return FALSE
	var/datum/species/species = preferences.get_species_prototype()
	var/list/allowed_states = list(PREF_ORGANSTATUS_ORGANIC_RUS, PREF_ORGANSTATUS_CYBERNETIC_RUS)
	if(TRAIT_NO_ROBOPARTS in species.inherent_traits)
		allowed_states -= PREF_ORGANSTATUS_CYBERNETIC_RUS
	var/new_state = tgui_input_list(user, "Выберите желаемое состояние органа", GLOB.preference_organ_names[organ], allowed_states)
	if(!new_state)
		return FALSE
	preferences.organ_data[organ] = new_state == PREF_ORGANSTATUS_CYBERNETIC_RUS ? PREF_ORGANSTATUS_CYBERNETIC_ENG : null
	return finish_edit()

/datum/preference_middleware/limbs/proc/ipc_loadout(list/params, mob/user)
	var/datum/species/species = preferences.get_species_prototype()
	if(species.name != SPECIES_MACHINEPERSON)
		return FALSE
	var/list/robolimb_companies = list()
	for(var/limb_type in typesof(/datum/robolimb))
		var/datum/robolimb/robolimb = new limb_type
		if(!robolimb.unavailable_at_chargen && robolimb.has_subtypes && (species.name in robolimb.species_allowed))
			robolimb_companies[robolimb.company] = robolimb
	var/choice = tgui_input_list(user, "Выберите фирму-производителя оболочки", "Модель оболочки", robolimb_companies)
	if(!choice)
		return FALSE
	reset_head_appearance()
	for(var/limb in GLOB.preference_limb_names)
		preferences.rlimb_data[limb] = choice
		preferences.organ_data[limb] = PREF_ORGANSTATUS_CYBORG_ENG
	return finish_edit()
