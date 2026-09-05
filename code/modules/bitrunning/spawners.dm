GLOBAL_LIST_INIT(virtual_pirate_names, list(
	"Black Bartholomew",
	"Bloody Kate",
	"Calico Reed",
	"Dead-Eye Morgan",
	"Grimy Pete",
	"Iron Hand Silas",
	"Mad Anne",
	"One-Eyed Jack",
	"Rotten Tom",
	"Salty Meg",
))

/obj/effect/mob_spawn/human/alive/virtual_domain
	name = "virtual domain sleeper"
	description = "Отыграйте защитника виртуального домена и не дайте битраннерам вынести приз."
	assignedrole = "Virtual Domain Actor"
	banType = ROLE_GLITCH
	var/antag = TRUE

/obj/effect/mob_spawn/human/alive/virtual_domain/get_ru_names()
	return alist(
		NOMINATIVE = "капсула виртуального домена",
		GENITIVE = "капсулы виртуального домена",
		DATIVE = "капсуле виртуального домена",
		ACCUSATIVE = "капсулу виртуального домена",
		INSTRUMENTAL = "капсулой виртуального домена",
		PREPOSITIONAL = "капсуле виртуального домена",
	)

/obj/effect/mob_spawn/human/alive/virtual_domain/create(mob/plr, flavour = TRUE, name, prefs = FALSE, _mob_name = FALSE, _mob_gender = FALSE, _mob_species = FALSE)
	var/datum/mind/possessor_mind = plr?.mind
	var/mob/living/spawned = ..()
	if(isnull(plr) || isnull(spawned))
		return spawned

	spawned.add_traits(list(TRAIT_TEMPORARY_BODY), INNATE_TRAIT)
	if(possessor_mind)
		spawned.AddComponent( \
			/datum/component/temporary_body, \
			old_mind = possessor_mind, \
			old_body = possessor_mind.current, \
			delete_on_death = TRUE, \
		)

	if(antag && spawned.mind)
		spawned.mind.add_antag_datum(/datum/antagonist/domain_actor)

	return spawned

/obj/effect/mob_spawn/human/alive/virtual_domain/pirate
	name = "virtual pirate remains"
	desc = "Груда неподвижных костей. Кажется, они в любой миг могут ожить."
	icon = 'icons/effects/blood.dmi'
	icon_state = "remains"
	density = FALSE
	mob_name = "Virtual Pirate"
	outfit = /datum/outfit/virtual_pirate
	flavour_text = "Вы — виртуальный пират. Йо-хо-хо! За вашей добычей явились сухопутные крысы. Остановите их!"

/obj/effect/mob_spawn/human/alive/virtual_domain/pirate/get_ru_names()
	return alist(
		NOMINATIVE = "останки виртуального пирата",
		GENITIVE = "останков виртуального пирата",
		DATIVE = "останкам виртуального пирата",
		ACCUSATIVE = "останки виртуального пирата",
		INSTRUMENTAL = "останками виртуального пирата",
		PREPOSITIONAL = "останках виртуального пирата",
	)

/obj/effect/mob_spawn/human/alive/virtual_domain/pirate/create(mob/plr, flavour = TRUE, name, prefs = FALSE, _mob_name = FALSE, _mob_gender = FALSE, _mob_species = FALSE)
	mob_name = pick(GLOB.virtual_pirate_names)
	return ..()

/datum/outfit/virtual_pirate
	name = "Virtual Pirate"
	uniform = /obj/item/clothing/under/pirate
	suit = /obj/item/clothing/suit/pirate_black
	head = /obj/item/clothing/head/pirate
	glasses = /obj/item/clothing/glasses/eyepatch
	shoes = /obj/item/clothing/shoes/jackboots
	id = /obj/item/card/id

/obj/effect/mob_spawn/human/alive/virtual_domain/syndie
	name = "virtual syndicate sleeper"
	desc = "Криокапсула с гербом Синдиката. Внутри кто-то шевелится."
	mob_name = "Syndicate Operative"
	outfit = /datum/outfit/virtual_syndicate
	flavour_text = "Ревут сирены! Нас берут на абордаж. Не дайте им забрать груз."

/obj/effect/mob_spawn/human/alive/virtual_domain/syndie/get_ru_names()
	return alist(
		NOMINATIVE = "капсула оперативника Синдиката",
		GENITIVE = "капсулы оперативника Синдиката",
		DATIVE = "капсуле оперативника Синдиката",
		ACCUSATIVE = "капсулу оперативника Синдиката",
		INSTRUMENTAL = "капсулой оперативника Синдиката",
		PREPOSITIONAL = "капсуле оперативника Синдиката",
	)

/datum/outfit/virtual_syndicate
	name = "Virtual Syndicate"
	uniform = /obj/item/clothing/under/syndicate
	back = /obj/item/storage/backpack
	gloves = /obj/item/clothing/gloves/color/black
	shoes = /obj/item/clothing/shoes/combat
	id = /obj/item/card/id/syndicate
	implants = list(/obj/item/implant/weapons_auth)
