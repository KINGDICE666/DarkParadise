/datum/lazy_template/virtual_domain/gondola_asteroid
	name = "Астероид гондол"
	desc = "Астероид, на котором вырос щедрый лес гондол. Мирное место."
	help_text = "Какой чудесный лес. Ящик с добычей стоит посреди карты. Хм... он не сдвигается. А вот гондолы таскают его без труда. Наверняка есть способ сдвинуть его самому."
	key = LAZY_TEMPLATE_KEY_BITRUNNING_GONDOLA_ASTEROID
	map_name = "gondola_asteroid"
	domain_flags = DOMAIN_NO_NOHIT_BONUS

/obj/structure/closet/crate/secure/bitrunning/encrypted/gondola
	move_resist = MOVE_FORCE_STRONG

/mob/living/simple_animal/pet/gondola/virtual_domain
	health = 50
	maxHealth = 50
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
