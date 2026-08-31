/datum/lazy_template/virtual_domain/abandoned_outpost
	name = "Заброшенный аванпост"
	desc = "Законсервированный склад на окраине системы. Сторожевые карпы всё ещё патрулируют коридоры."
	key = LAZY_TEMPLATE_KEY_BITRUNNING_OUTPOST
	map_name = "abandoned_outpost"
	difficulty = BITRUNNER_DIFFICULTY_LOW
	help_text = "Зашифрованный контейнер стоит в дальнем хранилище. Дотащите его до площадки выдачи в убежище и уходите по лестнице."
	completion_loot = list(
		/obj/item/stack/sheet/metal = 20,
		/obj/item/stack/sheet/glass = 10,
	)
