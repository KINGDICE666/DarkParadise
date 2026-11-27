/datum/bounty/item/mining/goliath_steaks
	name = "Стейки из голиафа на лаве"
	description = "Адмирал Павлова объявила голодовку с тех пор, как столовая стала подавать только обезьян и обезьяньи субпродукты. Она требует стейков из голиафа, приготовленных на лаве."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/goliath_steak = TRUE)

/datum/bounty/item/mining/goliath_boat
	name = "Лодка из шкуры голиафа"
	description = "Коммандер Меньков хочет участвовать в ежегодной регате Лаваленда. Он просит ваших корабелов построить самую быструю лодку на свете."
	reward = CARGO_CRATE_VALUE * 20
	wanted_types = list(/obj/vehicle/ridden/lavaboat = TRUE)

/datum/bounty/item/mining/bone_oar
	name = "Костяные вёсла"
	description = "Коммандеру Менькову для регаты на Лаваленде нужны вёсла. Отправьте пару."
	reward = CARGO_CRATE_VALUE * 8
	required_count = 2
	wanted_types = list(/obj/item/oar = TRUE)

/datum/bounty/item/mining/bone_axe
	name = "Костяной топор"
	description = "Бродячие клоуны украли пожарные топоры станции 12. Отправьте ей костяной топор на замену."
	reward = CARGO_CRATE_VALUE * 15
	wanted_types = list(/obj/item/twohanded/fireaxe/boneaxe = TRUE)

/datum/bounty/item/mining/bone_armor
	name = "Костяная броня"
	description = "Станция 14 выделила своих унатхов добровольцами для испытания баллистической брони. Отправьте костяную броню."
	reward = CARGO_CRATE_VALUE * 10
	wanted_types = list(/obj/item/clothing/suit/armor/bone = TRUE)

/datum/bounty/item/mining/skull_helmet
	name = "Шлем-череп"
	description = "У главы службы безопасности станции 42 завтра день рождения! Мы хотим удивить её модным шлемом-черепом."
	reward = CARGO_CRATE_VALUE * 8
	wanted_types = list(/obj/item/clothing/head/helmet/skull = TRUE)

/datum/bounty/item/mining/bone_talisman
	name = "Костяные талисманы"
	description = "Директор исследований станции 14 утверждает, что языческие костяные талисманы защищают владельца. Отправьте ему несколько для проверки."
	reward = CARGO_CRATE_VALUE * 15
	required_count = 3
	wanted_types = list(/obj/item/clothing/accessory/necklace/talisman = TRUE)

/datum/bounty/item/mining/bone_dagger
	name = "Костяные кинжалы"
	description = "В столовой ЦК урезают бюджет. Отправьте костяные кинжалы, чтобы наш повар мог работать дальше."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 3
	wanted_types = list(/obj/item/kitchen/knife/combat/survival/bone = TRUE)

/datum/bounty/item/mining/polypore_mushroom
	name = "Грибная чаша"
	description = "Лейтенант Джеб уронил свою любимую грибную чашу. Подбодрите его новой, ладно?"
	reward = CARGO_CRATE_VALUE * 15
	wanted_types = list(/obj/item/reagent_containers/cup/glass/mushroom_bowl = TRUE)

/datum/bounty/item/mining/inocybe_mushroom
	name = "Шляпки грибов"
	description = "Наш ботаник утверждает, что может перегнать вкусный ликёр из абсолютно любого растения. Посмотрим, что он сделает со шляпками иноцибе."
	reward = CARGO_CRATE_VALUE * 9
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/ash_flora/mushroom_cap = TRUE)

/datum/bounty/item/mining/porcini_mushroom
	name = "Листья грибов"
	description = "Говорят, листья белых грибов обладают целебными свойствами. Наши учёные хотят это проверить."
	reward = CARGO_CRATE_VALUE * 9
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/ash_flora/mushroom_leaf = TRUE)
