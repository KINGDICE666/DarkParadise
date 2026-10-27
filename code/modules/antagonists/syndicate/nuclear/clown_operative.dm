/datum/antagonist/nuclear_operative/clownop
	name = "Клоун-оперативник"
	antag_menu_name = "Клоун-оперативник"
	greet_name = "клоун-оперативник"
	default_team_type = /datum/team/nuclear_team/clown_ops
	race_equipment = list(SPECIES_OTHER = /datum/outfit/admin/syndicate/operative/nuclear/clownop)

/datum/antagonist/nuclear_operative/clownop/apply_innate_effects(mob/living/mob_override)
	. = ..()
	ADD_TRAIT(owner, TRAIT_NAIVE, UID())
	RegisterSignal(mob_override || owner.current, COMSIG_HUMAN_SUICIDE_ACT, PROC_REF(on_suicide))

/datum/antagonist/nuclear_operative/clownop/remove_innate_effects(mob/living/mob_override)
	REMOVE_TRAIT(owner, TRAIT_NAIVE, UID())
	UnregisterSignal(mob_override || owner.current, COMSIG_HUMAN_SUICIDE_ACT)
	return ..()

/datum/antagonist/nuclear_operative/clownop/proc/on_suicide(mob/living/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(suicide_cry), source)

/datum/antagonist/nuclear_operative/clownop/proc/suicide_cry(mob/living/operative)
	operative.say("С ДНЁМ РОЖДЕНИЯ!")

/datum/antagonist/nuclear_operative/clownop/equip()
	. = ..()
	var/mob/living/carbon/human/operative = owner.current
	if(!istype(operative))
		return
	var/obj/item/organ/internal/liver/liver = operative.get_organ_slot(INTERNAL_ORGAN_LIVER)
	if(liver)
		ADD_TRAIT(liver, TRAIT_COMEDY_METABOLISM, type)

/datum/antagonist/nuclear_operative/clownop/rename()
	owner.current.real_name = pick(GLOB.clown_names)

/datum/antagonist/nuclear_operative/clownop/leader
	name = "Командир клоунов-оперативников"
	antag_menu_name = "Командир клоунов-оперативников"
	greet_name = "командир клоунов-оперативников"
	race_equipment = list(SPECIES_OTHER = /datum/outfit/admin/syndicate/operative/nuclear/clownop/leader)

/datum/antagonist/nuclear_operative/clownop/leader/rename()
	owner.current.real_name = "[pick("Head Honker", "Slipmaster", "Clown King", "Honkbearer")] [pick(GLOB.clown_names)]"

/datum/antagonist/nuclear_operative/clownop/leader/footer_messages()
	var/list/messages = ..()
	messages.Add(span_notice("Вы командир отряда клоунов-оперативников. Ваша карта открывает шлюз в док с шаттлом. Согласуйте план с командой перед использованием объявления войны."))
	return messages

/datum/antagonist/nuclear_operative/clownop/reinf
	name = "Клоун-оперативник подкрепления"
	antag_menu_name = "Клоун-оперативник подкрепления"
	race_equipment = list(SPECIES_OTHER = /datum/outfit/admin/syndicate/operative/nuclear/clownop/reinf)

/datum/team/nuclear_team/clown_ops
	name = "Клоуны-оперативники"
	antag_datum_type = /datum/antagonist/nuclear_operative/clownop
	leader_antag_type = /datum/antagonist/nuclear_operative/clownop/leader
	reinforcement_antag_type = /datum/antagonist/nuclear_operative/clownop/reinf
	nuke_type = /obj/machinery/nuclearbomb/syndicate/bananium

/datum/team/nuclear_team/clown_ops/add_member(datum/mind/new_member, add_objectives)
	if(!leader && new_member.has_antag_datum(antag_datum_type))
		leader = new_member
	return ..()

/datum/outfit/admin/syndicate/operative/nuclear/clownop
	name = "Clown Operative"
	back = /obj/item/storage/backpack/clown
	mask = /obj/item/clothing/mask/gas/clown_hat/clownops
	shoes = /obj/item/clothing/shoes/clown_shoes/combat
	belt = /obj/item/gun/projectile/automatic/toy/pistol/riot/clandestine
	l_pocket = /obj/item/bikehorn
	r_pocket = /obj/item/radio/uplink/nuclear/clownop
	implants = list(/obj/item/implant/sad_trombone, /obj/item/implant/tacmap/nuclear)
	backpack_contents = list(
		/obj/item/storage/box/survival/survival_syndi = 1,
		/obj/item/ammo_box/magazine/toy/pistol/riot = 2,
		/obj/item/reagent_containers/spray/waterflower/lube/super = 1,
		/obj/item/mod/skin_applier/honkerative = 1,
		/obj/item/crowbar/red = 1,
		/obj/item/grenade/plastic/c4 = 1,
		/obj/item/reagent_containers/food/snacks/syndidonkpocket = 1,
		/obj/item/flashlight = 1,
	)
	var/id_rank = JOB_TITLE_CLOWN_OPERATIVE

/datum/outfit/admin/syndicate/operative/nuclear/clownop/pre_equip(mob/living/carbon/human/human, visualsOnly = FALSE)
	. = ..()
	switch(human.dna.species.name)
		if(SPECIES_VOX)
			r_hand = /obj/item/tank/internals/emergency_oxygen/double/vox
			internals_slot = ITEM_SLOT_HAND_RIGHT
		if(SPECIES_PLASMAMAN)
			uniform = /obj/item/clothing/under/plasmaman/syndie
			head = /obj/item/clothing/head/helmet/space/plasmaman/syndie
			r_hand = /obj/item/tank/internals/plasmaman
			internals_slot = ITEM_SLOT_HAND_RIGHT
			backpack_contents[/obj/item/extinguisher_refill] = 2

/datum/outfit/admin/syndicate/operative/nuclear/clownop/post_equip(mob/living/carbon/human/human, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return
	human.grant_language(/datum/language/clown)
	human.force_gene_block(GLOB.clumsyblock, TRUE)
	var/obj/item/gun/gun = human.belt
	if(istype(gun))
		var/obj/item/firing_pin/clown/ultra/pin = new
		pin.gun_insert(null, gun)
	var/obj/item/card/id/card = human.wear_id
	if(istype(card))
		card.rank = id_rank
		card.assignment = get_job_title_ru(id_rank)
		card.update_label()
	human.update_hud_set()

/datum/outfit/admin/syndicate/operative/nuclear/clownop/leader
	name = "Clown Operative Leader"
	id_access = JOB_TITLE_SYNDICATE_OPERATIVE_LEADER
	id_rank = JOB_TITLE_CLOWN_OPERATIVE_LEADER
	l_hand = /obj/item/nuclear_challenge/clownops
	implants = list(/obj/item/implant/sad_trombone, /obj/item/implant/tacmap/nuclear/leader)

/datum/outfit/admin/syndicate/operative/nuclear/clownop/reinf
	name = "Clown Operative Reinforcement"
	uplink_uses = 0

/obj/item/clothing/mask/gas/clown_hat/clownops
	name = "tactical clown wig and mask"
	desc = "Тактический клоунский парик с маской. Защищает от вспышек, перцового газа и огня."
	flash_protect = FLASH_PROTECTION_FLASH
	resistance_flags = FIRE_PROOF
	flags_cover = MASKCOVERSEYES|PEPPERPROOF

/obj/item/clothing/mask/gas/clown_hat/clownops/get_ru_names()
	return alist(
		NOMINATIVE = "тактический клоунский парик с маской",
		GENITIVE = "тактического клоунского парика с маской",
		DATIVE = "тактическому клоунскому парику с маской",
		ACCUSATIVE = "тактический клоунский парик с маской",
		INSTRUMENTAL = "тактическим клоунским париком с маской",
		PREPOSITIONAL = "тактическом клоунском парике с маской",
	)

/obj/item/clothing/mask/gas/clown_hat/clownops/mask_action(mob/user)
	return

/obj/item/clothing/shoes/clown_shoes/combat
	name = "combat clown shoes"
	desc = "Боевые клоунские ботинки. Защищают ноги и не дают поскользнуться на воде и банановой кожуре. Скрипят на полную мощность."
	clothing_traits = list(TRAIT_NO_SLIP_WATER)
	slowdown = SHOES_SLOWDOWN
	body_parts_covered = FEET|LEGS
	armor = list(MELEE = 25, BULLET = 25, LASER = 25, ENERGY = 25, BOMB = 50, BIO = 90, FIRE = 70, ACID = 50)
	strip_delay = 7 SECONDS
	resistance_flags = NONE
	can_cut_open = TRUE

/obj/item/clothing/shoes/clown_shoes/combat/get_ru_names()
	return alist(
		NOMINATIVE = "боевые клоунские ботинки",
		GENITIVE = "боевых клоунских ботинок",
		DATIVE = "боевым клоунским ботинкам",
		ACCUSATIVE = "боевые клоунские ботинки",
		INSTRUMENTAL = "боевыми клоунскими ботинками",
		PREPOSITIONAL = "боевых клоунских ботинках",
	)

/obj/item/reagent_containers/spray/waterflower/lube
	desc = "Невинный на первый взгляд подсолнух... со скользкой изюминкой."
	amount_per_transfer_from_this = 3
	spray_maxrange = 1
	spray_currentrange = 1
	volume = 30
	list_reagents = list("lube" = 30)

/obj/item/gun/projectile/automatic/toy/pistol/riot/clandestine
	damage_mod = 1.4
	stamina_mod = 1.4

/obj/item/mod/skin_applier/honkerative
	name = "Honkerative MOD skin applier"
	gender = MALE
	desc = "Одноразовый комплект для перекраски модульного экзокостюма \"Синдиката\" в цвета клоунов-оперативников."
	skin = MOD_VARIANT_HONKERATIVE
	compatible_theme = /datum/mod_theme/syndicate

/obj/item/mod/skin_applier/honkerative/get_ru_names()
	return alist(
		NOMINATIVE = "набор покраски МЭК \"Honkerative\"",
		GENITIVE = "набора покраски МЭК \"Honkerative\"",
		DATIVE = "набору покраски МЭК \"Honkerative\"",
		ACCUSATIVE = "набор покраски МЭК \"Honkerative\"",
		INSTRUMENTAL = "набором покраски МЭК \"Honkerative\"",
		PREPOSITIONAL = "наборе покраски МЭК \"Honkerative\"",
	)

/obj/item/radio/uplink/nuclear/clownop/choose_uplink()
	return UPLINK_TYPE_CLOWN_OPS

/obj/item/nuclear_challenge/clownops
	desc = "Объявление войны клоунов-оперативников. Предупреждает станцию о представлении и привлекает дополнительное \
		финансирование для клоунского аплинка."
	announcement_sound = 'sound/announcer/clownops.ogg'

/obj/item/nuclear_challenge/clownops/get_ru_names()
	return alist(
		NOMINATIVE = "объявление войны клоунов",
		GENITIVE = "объявления войны клоунов",
		DATIVE = "объявлению войны клоунов",
		ACCUSATIVE = "объявление войны клоунов",
		INSTRUMENTAL = "объявлением войны клоунов",
		PREPOSITIONAL = "объявлении войны клоунов",
	)

/obj/item/reagent_containers/spray/waterflower/lube/super
	list_reagents = list("superlube" = 30)

/datum/reagent/lube/superlube
	name = "Супер-смазка"
	id = "superlube"
	description = "Усовершенствованная космическая смазка, запрещённая после особенно скользкого происшествия."

/datum/reagent/lube/superlube/reaction_turf(turf/simulated/target, volume)
	if(volume >= 1 && istype(target))
		target.MakeSlippery(TURF_WET_SUPERLUBE, 120 SECONDS)
