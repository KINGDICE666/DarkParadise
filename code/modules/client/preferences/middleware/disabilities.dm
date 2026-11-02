#define DISABILITY_NEGATIVE -1
#define DISABILITY_NEUTRAL 0

GLOBAL_LIST_INIT(preference_disabilities, list(
	"wingdings" = list("flag" = DISABILITY_FLAG_WINGDINGS, "name" = "Инопланетная речь", "description" = "Ваша речь превращается в непонятные символы.", "icon" = "comment-slash", "value" = DISABILITY_NEGATIVE),
	"nearsighted" = list("flag" = DISABILITY_FLAG_NEARSIGHTED, "name" = "Близорукость", "description" = "Без очков вы плохо видите вдаль.", "icon" = "glasses", "value" = DISABILITY_NEGATIVE),
	"colourblind" = list("flag" = DISABILITY_FLAG_COLOURBLIND, "name" = "Дальтонизм", "description" = "Вы не различаете цвета.", "icon" = "palette", "value" = DISABILITY_NEGATIVE),
	"blind" = list("flag" = DISABILITY_FLAG_BLIND, "name" = "Слепота", "description" = "Вы полностью слепы.", "icon" = "eye-slash", "value" = DISABILITY_NEGATIVE),
	"deaf" = list("flag" = DISABILITY_FLAG_DEAF, "name" = "Глухота", "description" = "Вы ничего не слышите.", "icon" = "deaf", "value" = DISABILITY_NEGATIVE),
	"mute" = list("flag" = DISABILITY_FLAG_MUTE, "name" = "Немота", "description" = "Вы не можете говорить.", "icon" = "volume-mute", "value" = DISABILITY_NEGATIVE),
	"obesity" = list("flag" = DISABILITY_FLAG_OBESITY, "name" = "Полнота", "description" = "Вы страдаете от лишнего веса.", "icon" = "hamburger", "value" = DISABILITY_NEGATIVE),
	"nervous" = list("flag" = DISABILITY_FLAG_NERVOUS, "name" = "Нервозность", "description" = "От волнения вы начинаете заикаться.", "icon" = "grimace", "value" = DISABILITY_NEGATIVE),
	"swedish" = list("flag" = DISABILITY_FLAG_SWEDISH, "name" = "Шведский акцент", "description" = "Вы говорите с заметным шведским акцентом.", "icon" = "language", "value" = DISABILITY_NEUTRAL),
	"auld_imperial" = list("flag" = DISABILITY_FLAG_AULD_IMPERIAL, "name" = "Староимпѣрская рѣчь", "description" = "Вы изъясняетесь на старомодный манер.", "icon" = "scroll", "value" = DISABILITY_NEUTRAL),
	"lisp" = list("flag" = DISABILITY_FLAG_LISP, "name" = "Шепелявость", "description" = "Вы шепелявите.", "icon" = "comment-dots", "value" = DISABILITY_NEGATIVE),
	"dizzy" = list("flag" = DISABILITY_FLAG_DIZZY, "name" = "Головокружение", "description" = "Вас постоянно шатает.", "icon" = "dizzy", "value" = DISABILITY_NEGATIVE),
	"nicotine_addict" = list("flag" = DISABILITY_FLAG_NICOTINE_ADDICT, "name" = "Зависимость от никотина", "description" = "Без курева вам становится плохо.", "icon" = "smoking", "value" = DISABILITY_NEGATIVE),
	"tea_addict" = list("flag" = DISABILITY_FLAG_TEA_ADDICT, "name" = "Зависимость от чая", "description" = "Без чая вам становится плохо.", "icon" = "mug-hot", "value" = DISABILITY_NEGATIVE),
	"coffee_addict" = list("flag" = DISABILITY_FLAG_COFFEE_ADDICT, "name" = "Зависимость от кофе", "description" = "Без кофе вам становится плохо.", "icon" = "coffee", "value" = DISABILITY_NEGATIVE),
	"alcohol_addict" = list("flag" = DISABILITY_FLAG_ALCOHOLE_ADDICT, "name" = "Зависимость от алкоголя", "description" = "Без выпивки вам становится плохо.", "icon" = "wine-bottle", "value" = DISABILITY_NEGATIVE),
	"paraplegia" = list("flag" = DISABILITY_FLAG_PARAPLEGIA, "name" = "Параплегия", "description" = "Ваши ноги парализованы.", "icon" = "wheelchair", "value" = DISABILITY_NEGATIVE),
	"aphasia" = list("flag" = DISABILITY_FLAG_APHASIA, "name" = "Афазия", "description" = "Вы с трудом подбираете слова.", "icon" = "brain", "value" = DISABILITY_NEGATIVE),
	"catears" = list("flag" = DISABILITY_FLAG_CATEARS, "name" = "Кошачьи уши", "description" = "У вас кошачьи уши.", "icon" = "cat", "value" = DISABILITY_NEUTRAL),
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
		"give_quirk" = PROC_REF(give_quirk),
		"remove_quirk" = PROC_REF(remove_quirk),
	)

/datum/preference_middleware/disabilities/get_constant_data()
	var/list/quirk_info = list()
	for(var/disability_key in GLOB.preference_disabilities)
		var/list/disability = GLOB.preference_disabilities[disability_key]
		quirk_info[disability_key] = list(
			"name" = disability["name"],
			"description" = disability["description"],
			"icon" = disability["icon"],
			"value" = disability["value"],
			"customizable" = FALSE,
		)

	return list(
		"max_positive_quirks" = -1,
		"quirk_info" = quirk_info,
		"quirk_blacklist" = list(),
		"points_enabled" = FALSE,
	)

/datum/preference_middleware/disabilities/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	var/datum/species/species = preferences.get_species_prototype()
	var/list/selected_quirks = list()
	var/list/species_disallowed_quirks = list()
	for(var/disability_key in GLOB.preference_disabilities)
		var/flag = GLOB.preference_disabilities[disability_key]["flag"]
		if(preferences.disabilities & flag)
			selected_quirks += disability_key
		if(species.blacklisted_disabilities & flag)
			species_disallowed_quirks += disability_key

	return list(
		"selected_quirks" = selected_quirks,
		"species_disallowed_quirks" = species_disallowed_quirks,
		"default_quirk_balance" = 0,
	)

/datum/preference_middleware/disabilities/proc/give_quirk(list/params, mob/user)
	var/list/disability = GLOB.preference_disabilities[params["quirk"]]
	if(!disability)
		return FALSE
	var/datum/species/species = preferences.get_species_prototype()
	if(species.blacklisted_disabilities & disability["flag"])
		return FALSE
	preferences.disabilities |= disability["flag"]
	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/disabilities/proc/remove_quirk(list/params, mob/user)
	var/list/disability = GLOB.preference_disabilities[params["quirk"]]
	if(!disability)
		return FALSE
	preferences.disabilities &= ~disability["flag"]
	preferences.character_preview_view?.update_body()
	return TRUE

#undef DISABILITY_NEGATIVE
#undef DISABILITY_NEUTRAL
