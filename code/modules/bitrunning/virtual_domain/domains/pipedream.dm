/datum/lazy_template/virtual_domain/pipedream
	name = "Фабрика мусоропроводов"
	cost = BITRUNNER_COST_LOW
	desc = "Заброшенная и кем-то обжитая фабрика по производству труб мусоропровода."
	difficulty = BITRUNNER_DIFFICULTY_LOW
	completion_loot = list(/obj/item/stack/cable_coil = 1)
	help_text = "Ещё недавно здесь кипела работа. Смена ушла в спешке, и с тех пор производство буквально в мусорке. Что-то разнесло это место — вот только что?"
	is_modular = TRUE
	key = LAZY_TEMPLATE_KEY_BITRUNNING_PIPEDREAM
	map_name = "pipedream"
	mob_modules = list(
		/datum/modular_mob_segment/hivebots,
		/datum/modular_mob_segment/hivebots_strong,
	)
	reward_points = BITRUNNER_REWARD_LOW
