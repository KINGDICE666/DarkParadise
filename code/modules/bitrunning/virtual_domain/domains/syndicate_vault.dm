/datum/lazy_template/virtual_domain/syndicate_vault
	name = "Схрон Синдиката"
	desc = "Пограничный форпост Синдиката. Оперативники держат периметр и стреляют первыми."
	key = LAZY_TEMPLATE_KEY_BITRUNNING_SYNDICATE_VAULT
	map_name = "syndicate_vault"
	cost = BITRUNNER_COST_MEDIUM
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	reward_points = BITRUNNER_REWARD_MEDIUM
	help_text = "Контейнер заперт в одном из внутренних хранилищ. Стрелки простреливают коридоры насквозь, держитесь укрытий."
	completion_loot = list(
		/obj/item/stack/sheet/mineral/silver = 10,
		/obj/item/stack/sheet/mineral/gold = 5,
	)
	secondary_loot = list(
		/obj/item/stock_parts/scanning_module/phasic = 1,
		/obj/item/clothing/glasses/night = 1,
	)
