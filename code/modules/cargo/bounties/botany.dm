/datum/bounty/item/botany
	reward = CARGO_CRATE_VALUE * 10
	var/multiplier = 0
	var/bonus_desc
	var/foodtype = "изысканное блюдо"

/datum/bounty/item/botany/New()
	..()
	description = "Шеф-повар Центрального командования хочет приготовить [foodtype]. Ему нужно: [name]. [bonus_desc]"
	name = capitalize(name)
	reward += multiplier * (CARGO_CRATE_VALUE * 2)
	required_count = rand(5, 10)

/datum/bounty/item/botany/ambrosia_vulgaris
	name = "листья амброзии вульгарис"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/ambrosia/vulgaris = TRUE)
	foodtype = "рагу"

/datum/bounty/item/botany/ambrosia_gaia
	name = "листья амброзии гайи"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/ambrosia/gaia = TRUE)
	multiplier = 4
	foodtype = "рагу"

/datum/bounty/item/botany/apple_golden
	name = "золотые яблоки"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/apple/gold = TRUE)
	multiplier = 4
	foodtype = "десерт"

/datum/bounty/item/botany/banana
	name = "бананы"
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/grown/banana = TRUE,
		/obj/item/reagent_containers/food/snacks/grown/banana/bluespace = FALSE,
	)
	foodtype = "банановый сплит"

/datum/bounty/item/botany/banana_bluespace
	name = "блюспейс-бананы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/banana/bluespace = TRUE)
	multiplier = 2
	foodtype = "банановый сплит"

/datum/bounty/item/botany/beans_koi
	name = "бобы кои"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/koibeans = TRUE)
	multiplier = 2

/datum/bounty/item/botany/berries_death
	name = "смертельные ягоды"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/berries/death = TRUE)
	multiplier = 2
	bonus_desc = "Он настаивает, что \"знает, что делает\"."
	foodtype = "сорбет"

/datum/bounty/item/botany/berries_glow
	name = "светящиеся ягоды"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/berries/glow = TRUE)
	multiplier = 2
	foodtype = "сорбет"

/datum/bounty/item/botany/cannabis
	name = "листья конопли"
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/grown/cannabis = TRUE,
		/obj/item/reagent_containers/food/snacks/grown/cannabis/white = FALSE,
		/obj/item/reagent_containers/food/snacks/grown/cannabis/death = FALSE,
		/obj/item/reagent_containers/food/snacks/grown/cannabis/ultimate = FALSE,
	)
	multiplier = 4
	bonus_desc = "Не упоминайте эту поставку при службе безопасности."
	foodtype = "партию \"кексов\""

/datum/bounty/item/botany/cannabis_white
	name = "листья травы жизни"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/cannabis/white = TRUE)
	multiplier = 6
	bonus_desc = "Не упоминайте эту поставку при службе безопасности."
	foodtype = "\"блюдо\""

/datum/bounty/item/botany/cannabis_death
	name = "листья травы смерти"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/cannabis/death = TRUE)
	multiplier = 6
	bonus_desc = "Не упоминайте эту поставку при службе безопасности."
	foodtype = "\"блюдо\""

/datum/bounty/item/botany/cannabis_ultimate
	name = "листья омега-травы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/cannabis/ultimate = TRUE)
	multiplier = 6
	bonus_desc = "Ни при каких обстоятельствах не упоминайте эту поставку при службе безопасности."
	foodtype = "партию \"брауни\""

/datum/bounty/item/botany/wheat
	name = "зёрна пшеницы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/wheat = TRUE)

/datum/bounty/item/botany/rice
	name = "зёрна риса"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/rice = TRUE)

/datum/bounty/item/botany/chili
	name = "перцы чили"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/chili = TRUE)

/datum/bounty/item/botany/ice_chili
	name = "ледяные перцы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/icepepper = TRUE)
	multiplier = 2

/datum/bounty/item/botany/ghost_chili
	name = "призрачные перцы чили"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/ghost_chili = TRUE)
	multiplier = 2

/datum/bounty/item/botany/citrus_lime
	name = "лаймы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/citrus/lime = TRUE)
	foodtype = "сорбет"

/datum/bounty/item/botany/citrus_lemon
	name = "лимоны"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/citrus/lemon = TRUE)
	foodtype = "сорбет"

/datum/bounty/item/botany/citrus_oranges
	name = "апельсины"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/citrus/orange = TRUE)
	bonus_desc = "Не присылайте лимоны или лаймы."
	foodtype = "сорбет"

/datum/bounty/item/botany/eggplant
	name = "баклажаны"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/eggplant = TRUE)
	bonus_desc = "Не путать с яйцерастениями."

/datum/bounty/item/botany/eggplant_eggy
	name = "яйцерастения"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/shell/eggy = TRUE)
	bonus_desc = "Не путать с баклажанами."
	multiplier = 2

/datum/bounty/item/botany/kudzu
	name = "стручки кудзу"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/kudzupod = TRUE)
	bonus_desc = "Хранить в сухом тёмном месте."
	multiplier = 4

/datum/bounty/item/botany/watermelon
	name = "арбузы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/watermelon = TRUE)
	foodtype = "десерт"

/datum/bounty/item/botany/watermelon_holy
	name = "святые дыни"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/holymelon = TRUE)
	multiplier = 2
	foodtype = "десерт"

/datum/bounty/item/botany/glowshroom
	name = "светогрибы"
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/grown/mushroom/glowshroom = TRUE,
		/obj/item/reagent_containers/food/snacks/grown/mushroom/glowshroom/glowcap = FALSE,
		/obj/item/reagent_containers/food/snacks/grown/mushroom/glowshroom/shadowshroom = FALSE,
	)
	foodtype = "омлет"

/datum/bounty/item/botany/glowshroom_cap
	name = "светошляпки"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/mushroom/glowshroom/glowcap = TRUE)
	multiplier = 2
	foodtype = "омлет"

/datum/bounty/item/botany/glowshroom_shadow
	name = "теневые грибы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/mushroom/glowshroom/shadowshroom = TRUE)
	multiplier = 2
	foodtype = "омлет"

/datum/bounty/item/botany/nettles_death
	name = "смертельная крапива"
	wanted_types = list(/obj/item/grown/nettle/death = TRUE)
	multiplier = 2
	bonus_desc = "Работайте с ней в защите."
	foodtype = "сыр"

/datum/bounty/item/botany/pineapples
	name = "ананасы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/pineapple = TRUE)
	bonus_desc = "Не для употребления людьми."
	foodtype = "пепельницу"

/datum/bounty/item/botany/tomato
	name = "помидоры"
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/grown/tomato = TRUE,
		/obj/item/reagent_containers/food/snacks/grown/tomato/blue = FALSE,
	)

/datum/bounty/item/botany/tomato_bluespace
	name = "блюспейс-помидоры"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/tomato/blue/bluespace = TRUE)
	multiplier = 4

/datum/bounty/item/botany/oatz
	name = "овёс"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/oat = TRUE)
	multiplier = 2
	foodtype = "овсянку"
	bonus_desc = "Приседания и овсянка. А овёс у нас кончился."

/datum/bounty/item/botany/bonfire
	name = "горящий костёр"
	description = "Наши обогреватели сломались, и грузчики Центрального командования мёрзнут. Вырастите брёвна и отправьте горящий костёр, чтобы их согреть."
	wanted_types = list(/obj/structure/bonfire = TRUE)

/datum/bounty/item/botany/bonfire/New()
	var/static_description = description
	..()
	description = static_description

/datum/bounty/item/botany/bonfire/applies_to(obj/shipped)
	if(!..())
		return FALSE
	var/obj/structure/bonfire/bonfire = shipped
	return bonfire.burning

/datum/bounty/item/botany/cucumber
	name = "огурцы"
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/cucumber = TRUE)
