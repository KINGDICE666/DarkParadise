/datum/lazy_template/virtual_domain/ashen_lair
	name = "Пепельное логово"
	desc = "Зал некрополя под лавовым полем. В его центре дремлет пепельный дракон."
	key = LAZY_TEMPLATE_KEY_BITRUNNING_ASHEN_LAIR
	map_name = "ashen_lair"
	cost = BITRUNNER_COST_HIGH
	difficulty = BITRUNNER_DIFFICULTY_HIGH
	reward_points = BITRUNNER_REWARD_HIGH
	help_text = "Дракон просыпается сразу. Контейнеры лежат по краям зала, добраться до них можно только в обход."
	completion_loot = list(
		/obj/item/stack/sheet/mineral/diamond = 5,
		/obj/item/stack/sheet/mineral/gold = 10,
	)
	secondary_loot = list(
		/obj/item/stock_parts/manipulator/femto = 1,
		/obj/item/stock_parts/capacitor/super = 1,
	)
