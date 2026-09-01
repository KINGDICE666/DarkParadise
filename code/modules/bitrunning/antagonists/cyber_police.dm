/datum/antagonist/bitrunning_glitch/cyber_police
	name = "Cyber Police"
	antag_menu_name = "Кибер-полицейский"

/datum/antagonist/bitrunning_glitch/cyber_police/on_gain()
	. = ..()
	convert_agent()

	var/datum/martial_art/the_sleeping_carp/carp = new
	carp.teach(owner.current)

/datum/outfit/cyber_police
	name = "Cyber Police"
	uniform = /obj/item/clothing/under/suit_jacket/really_black
	shoes = /obj/item/clothing/shoes/laceup
	gloves = /obj/item/clothing/gloves/color/black
	glasses = /obj/item/clothing/glasses/sunglasses
	id = /obj/item/card/id

/datum/antagonist/bitrunning_glitch/cyber_tac
	name = "Cyber Tactical"
	antag_menu_name = "Кибер-спецназовец"
	threat = BITRUNNER_THREAT_CYBER_TAC
	outfit = /datum/outfit/cyber_police/tactical

/datum/antagonist/bitrunning_glitch/cyber_tac/on_gain()
	. = ..()
	convert_agent()

/datum/outfit/cyber_police/tactical
	name = "Cyber Tactical"
	head = /obj/item/clothing/head/helmet
	suit = /obj/item/clothing/suit/armor/vest
	back = /obj/item/storage/backpack/security
	l_hand = /obj/item/gun/projectile/automatic/aks74u
	backpack_contents = list(
		/obj/item/ammo_box/magazine/aks74u = 2,
	)
