/datum/preference/choiced/species
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "species"
	priority = PREFERENCE_PRIORITY_SPECIES
	randomize_by_default = FALSE

/datum/preference/choiced/species/init_possible_values()
	return assoc_to_keys(GLOB.all_species)

/datum/preference/choiced/species/get_valid_choices(datum/preferences/preferences)
	if(!preferences.parent || check_rights_for(preferences.parent, R_ADMIN))
		return get_choices()
	var/list/values = list(SPECIES_HUMAN)
	for(var/species_name in CONFIG_GET(str_list/playable_species))
		if(GLOB.all_species[species_name])
			values |= species_name
	return values

/datum/preference/choiced/species/deserialize(input, datum/preferences/preferences)
	return sanitize_inlist(input, get_choices(), create_default_value())

/datum/preference/choiced/species/create_default_value()
	return SPECIES_HUMAN

/datum/preference/choiced/species/create_random_value(datum/preferences/preferences)
	return pick(get_valid_choices(preferences))

/datum/preference/choiced/species/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/datum/species/species = GLOB.all_species[value]
	target.set_species(species.type)

/datum/preference/choiced/species/compile_constant_data()
	var/list/data = list()
	for(var/species_name in get_choices())
		var/datum/species/species = GLOB.all_species[species_name]
		var/list/paragraphs = list()
		for(var/paragraph in splittext(species.blurb, "<br/>"))
			if(trim(paragraph))
				paragraphs += trim(paragraph)
		data[species_name] = list(
			"name" = capitalize(GET_RU_SPECIES_NAME(species.name)),
			"desc" = paragraphs[1],
			"lore" = paragraphs.Copy(2),
			"icon" = sanitize_css_class_name("[species.type]"),
			"use_skintones" = !!(species.bodyflags & (HAS_SKIN_TONE|HAS_ICON_SKIN_TONE)),
			"sexes" = species.has_gender,
			"enabled_features" = list(),
			"perks" = species.get_species_perks(),
			"diet" = null,
		)
	return data

#define SPECIES_POSITIVE_PERK "positive"
#define SPECIES_NEGATIVE_PERK "negative"
#define SPECIES_NEUTRAL_PERK "neutral"
#define SPECIES_DEFAULT_COLD_LEVEL 260
#define SPECIES_DEFAULT_HEAT_LEVEL 360

/datum/species/proc/get_species_perks()
	var/list/perks = list(
		SPECIES_POSITIVE_PERK = list(),
		SPECIES_NEUTRAL_PERK = list(),
		SPECIES_NEGATIVE_PERK = list(),
	)

	add_modifier_perk(perks, brute_mod, "band-aid", "Травмы", "травм")
	add_modifier_perk(perks, burn_mod, "burn", "Ожоги", "ожогов")
	add_modifier_perk(perks, tox_mod, "biohazard", "Токсины", "токсинов")
	add_modifier_perk(perks, oxy_mod, "lungs", "Удушье", "удушья")
	add_modifier_perk(perks, siemens_coeff, "bolt", "Электричество", "ударов током")
	add_modifier_perk(perks, hunger_drain_mod, "utensils", "Голод", "голода")

	if(heatmod > 1 || heat_level_1 < SPECIES_DEFAULT_HEAT_LEVEL)
		add_perk(perks, SPECIES_NEGATIVE_PERK, "temperature-high", "Уязвимость к жаре", "Плохо переносит высокие температуры.")
	else if(heatmod < 1 || heat_level_1 > SPECIES_DEFAULT_HEAT_LEVEL)
		add_perk(perks, SPECIES_POSITIVE_PERK, "thermometer-empty", "Стойкость к жаре", "Хорошо переносит высокие температуры.")

	if(coldmod > 1 || cold_level_1 > SPECIES_DEFAULT_COLD_LEVEL)
		add_perk(perks, SPECIES_NEGATIVE_PERK, "temperature-low", "Уязвимость к холоду", "Плохо переносит низкие температуры.")
	else if(coldmod < 1 || cold_level_1 < SPECIES_DEFAULT_COLD_LEVEL)
		add_perk(perks, SPECIES_POSITIVE_PERK, "thermometer-empty", "Стойкость к холоду", "Хорошо переносит низкие температуры.")

	if(speed_mod > 0)
		add_perk(perks, SPECIES_NEGATIVE_PERK, "shoe-prints", "Медлительность", "Передвигается медленнее остальных.")
	else if(speed_mod < 0)
		add_perk(perks, SPECIES_POSITIVE_PERK, "running", "Быстрота", "Передвигается быстрее остальных.")

	switch(breathid)
		if("n2")
			add_perk(perks, SPECIES_NEUTRAL_PERK, "lungs", "Дышит азотом", "Для дыхания нужен азот, а не кислород.")
		if("tox")
			add_perk(perks, SPECIES_NEUTRAL_PERK, "lungs", "Дышит плазмой", "Для дыхания нужна плазма, а не кислород.")

	if(exotic_blood)
		add_perk(perks, SPECIES_NEUTRAL_PERK, "tint", "Особая кровь", "Необычная кровь усложняет переливание.")

	var/static/list/trait_perks = list(
		TRAIT_NO_BREATH = list(SPECIES_POSITIVE_PERK, "wind", "Не дышит", "Не нуждается в дыхании."),
		TRAIT_NO_BLOOD = list(SPECIES_POSITIVE_PERK, "tint-slash", "Без крови", "Не имеет крови и не страдает от кровопотери."),
		TRAIT_RADIMMUNE = list(SPECIES_POSITIVE_PERK, "radiation", "Иммунитет к радиации", "Радиация не причиняет вреда."),
		TRAIT_VIRUSIMMUNE = list(SPECIES_POSITIVE_PERK, "virus-slash", "Иммунитет к болезням", "Не заражается вирусами."),
		TRAIT_NO_PAIN = list(SPECIES_POSITIVE_PERK, "user-shield", "Не чувствует боли", "Боль не мешает действовать."),
		TRAIT_PIERCEIMMUNE = list(SPECIES_POSITIVE_PERK, "syringe", "Прочная кожа", "Шприцы и уколы не пробивают кожу."),
		TRAIT_HAS_REGENERATION = list(SPECIES_POSITIVE_PERK, "heart", "Регенерация", "Раны затягиваются сами собой."),
		TRAIT_NO_HUNGER = list(SPECIES_POSITIVE_PERK, "hamburger", "Не голодает", "Не нуждается в еде."),
		TRAIT_VENTCRAWLER_NUDE = list(SPECIES_POSITIVE_PERK, "route", "Ползает по трубам", "Может пролезать в вентиляцию без одежды."),
		TRAIT_NO_GUNS = list(SPECIES_NEGATIVE_PERK, "ban", "Не стреляет", "Не может пользоваться огнестрельным оружием."),
		TRAIT_NO_DNA = list(SPECIES_NEUTRAL_PERK, "dna", "Без ДНК", "Генетика на них не действует."),
		TRAIT_WATERBREATH = list(SPECIES_NEUTRAL_PERK, "fish", "Дышит водой", "Может дышать под водой."),
	)
	for(var/trait in inherent_traits)
		var/list/perk = trait_perks[trait]
		if(perk)
			add_perk(perks, perk[1], perk[2], perk[3], perk[4])

	return perks

/datum/species/proc/add_modifier_perk(list/perks, modifier, icon, name, vulnerable_to)
	if(modifier > 1)
		add_perk(perks, SPECIES_NEGATIVE_PERK, icon, "[name]: уязвимость", "Сильнее страдает от [vulnerable_to].")
	else if(modifier < 1)
		add_perk(perks, SPECIES_POSITIVE_PERK, "shield-alt", "[name]: стойкость", "Меньше страдает от [vulnerable_to].")

/datum/species/proc/add_perk(list/perks, perk_type, icon, name, description)
	perks[perk_type] += list(list(
		"ui_icon" = icon,
		"name" = name,
		"description" = description,
	))

#undef SPECIES_POSITIVE_PERK
#undef SPECIES_NEGATIVE_PERK
#undef SPECIES_NEUTRAL_PERK
#undef SPECIES_DEFAULT_COLD_LEVEL
#undef SPECIES_DEFAULT_HEAT_LEVEL
