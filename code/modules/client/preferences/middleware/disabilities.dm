GLOBAL_LIST_INIT(preference_disabilities, list(
	list("flag" = DISABILITY_FLAG_WINGDINGS, "name" = "Инопланетная речь"),
	list("flag" = DISABILITY_FLAG_NEARSIGHTED, "name" = "Близорукость"),
	list("flag" = DISABILITY_FLAG_COLOURBLIND, "name" = "Дальтонизм"),
	list("flag" = DISABILITY_FLAG_BLIND, "name" = "Слепота"),
	list("flag" = DISABILITY_FLAG_DEAF, "name" = "Глухота"),
	list("flag" = DISABILITY_FLAG_MUTE, "name" = "Немота"),
	list("flag" = DISABILITY_FLAG_OBESITY, "name" = "Полнота"),
	list("flag" = DISABILITY_FLAG_NERVOUS, "name" = "Нервозность"),
	list("flag" = DISABILITY_FLAG_SWEDISH, "name" = "Шведский акцент"),
	list("flag" = DISABILITY_FLAG_AULD_IMPERIAL, "name" = "Староимпѣрская рѣчь"),
	list("flag" = DISABILITY_FLAG_LISP, "name" = "Шепелявость"),
	list("flag" = DISABILITY_FLAG_DIZZY, "name" = "Головокружение"),
	list("flag" = DISABILITY_FLAG_NICOTINE_ADDICT, "name" = "Зависимость от никотина"),
	list("flag" = DISABILITY_FLAG_TEA_ADDICT, "name" = "Зависимость от чая"),
	list("flag" = DISABILITY_FLAG_COFFEE_ADDICT, "name" = "Зависимость от кофе"),
	list("flag" = DISABILITY_FLAG_ALCOHOLE_ADDICT, "name" = "Зависимость от алкоголя"),
	list("flag" = DISABILITY_FLAG_PARAPLEGIA, "name" = "Параплегия"),
	list("flag" = DISABILITY_FLAG_APHASIA, "name" = "Афазия"),
	list("flag" = DISABILITY_FLAG_CATEARS, "name" = "Кошачьи уши"),
))

/datum/preferences/proc/apply_disabilities(mob/living/carbon/human/character)
	var/active = disabilities & ~character.dna.species.blacklisted_disabilities
	if(!active)
		return

	var/list/addictions = list(
		"[DISABILITY_FLAG_COFFEE_ADDICT]" = /datum/reagent/consumable/drink/coffee,
		"[DISABILITY_FLAG_TEA_ADDICT]" = /datum/reagent/consumable/drink/tea,
		"[DISABILITY_FLAG_NICOTINE_ADDICT]" = /datum/reagent/nicotine,
		"[DISABILITY_FLAG_ALCOHOLE_ADDICT]" = /datum/reagent/consumable/ethanol,
	)
	for(var/flag_text in addictions)
		if(!(active & text2num(flag_text)))
			continue
		var/reagent_type = addictions[flag_text]
		var/datum/reagent/addiction = new reagent_type
		addiction.last_addiction_dose = world.timeofday
		character.reagents.addiction_list.Add(addiction)

	var/list/gene_blocks = list(
		"[DISABILITY_FLAG_OBESITY]" = GLOB.obesityblock,
		"[DISABILITY_FLAG_NEARSIGHTED]" = GLOB.glassesblock,
		"[DISABILITY_FLAG_BLIND]" = GLOB.blindblock,
		"[DISABILITY_FLAG_DEAF]" = GLOB.deafblock,
		"[DISABILITY_FLAG_COLOURBLIND]" = GLOB.colourblindblock,
		"[DISABILITY_FLAG_MUTE]" = GLOB.muteblock,
		"[DISABILITY_FLAG_NERVOUS]" = GLOB.nervousblock,
		"[DISABILITY_FLAG_SWEDISH]" = GLOB.swedeblock,
		"[DISABILITY_FLAG_AULD_IMPERIAL]" = GLOB.auld_imperial_block,
		"[DISABILITY_FLAG_LISP]" = GLOB.lispblock,
		"[DISABILITY_FLAG_DIZZY]" = GLOB.dizzyblock,
		"[DISABILITY_FLAG_WINGDINGS]" = GLOB.wingdingsblock,
		"[DISABILITY_FLAG_PARAPLEGIA]" = GLOB.paraplegiablock,
		"[DISABILITY_FLAG_APHASIA]" = GLOB.aphasiablock,
		"[DISABILITY_FLAG_CATEARS]" = GLOB.cat_earsblock,
	)
	for(var/flag_text in gene_blocks)
		if(active & text2num(flag_text))
			character.force_gene_block(gene_blocks[flag_text], TRUE, TRUE)

	if(active & DISABILITY_FLAG_OBESITY)
		character.overeatduration = 600

/datum/preference_middleware/disabilities
	action_delegations = list(
		"toggle_disability" = PROC_REF(toggle_disability),
		"reset_disabilities" = PROC_REF(reset_disabilities),
	)

/datum/preference_middleware/disabilities/get_constant_data()
	return GLOB.preference_disabilities

/datum/preference_middleware/disabilities/get_ui_data(mob/user)
	var/datum/species/species = preferences.get_species_prototype()
	var/list/available = list()
	for(var/list/disability as anything in GLOB.preference_disabilities)
		if(!(species.blacklisted_disabilities & disability["flag"]))
			available += disability["flag"]
	return list(
		"disabilities" = preferences.disabilities,
		"available_disabilities" = available,
	)

/datum/preference_middleware/disabilities/proc/toggle_disability(list/params, mob/user)
	var/flag = text2num("[params["flag"]]")
	if(!flag || !(flag & DISABILITY_MAX))
		return FALSE
	preferences.disabilities ^= flag
	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/disabilities/proc/reset_disabilities(list/params, mob/user)
	preferences.disabilities = 0
	preferences.character_preview_view?.update_body()
	return TRUE
