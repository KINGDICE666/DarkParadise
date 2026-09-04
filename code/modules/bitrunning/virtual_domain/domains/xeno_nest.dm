/datum/lazy_template/virtual_domain/xeno_nest
	name = "Гнездо ксеноморфов"
	desc = "Выработанный астероид, который облюбовал чужой улей. Королева не терпит гостей."
	key = LAZY_TEMPLATE_KEY_BITRUNNING_XENO_NEST
	map_name = "xeno_nest"
	cost = BITRUNNER_COST_LOW
	difficulty = BITRUNNER_DIFFICULTY_LOW
	reward_points = BITRUNNER_REWARD_LOW
	help_text = "Контейнер лежит в дальних пещерах. Улей просыпается, стоит подойти ближе, так что не тяните время."
	completion_loot = list(
		/obj/item/stack/sheet/mineral/plasma = 10,
		/obj/item/stack/sheet/metal = 20,
	)
	secondary_loot = list(
		/obj/item/stock_parts/manipulator/nano = 1,
		/obj/item/storage/firstaid/adv = 1,
	)
