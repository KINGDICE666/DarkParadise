/obj/machinery/nuclearbomb/syndicate/bananium
	name = "bananium fission explosive"
	gender = FEMALE
	desc = "Бананиевая боеголовка. Похоже, обратный отсчёт ведётся до начала представления."
	icon_state = "bananiumbomb_base"
	cinematic_type = CLOWN_NUKE

/obj/machinery/nuclearbomb/syndicate/bananium/get_ru_names()
	return alist(
		NOMINATIVE = "бананиевая боеголовка",
		GENITIVE = "бананиевой боеголовки",
		DATIVE = "бананиевой боеголовке",
		ACCUSATIVE = "бананиевую боеголовку",
		INSTRUMENTAL = "бананиевой боеголовкой",
		PREPOSITIONAL = "бананиевой боеголовке",
	)

/obj/machinery/nuclearbomb/syndicate/bananium/update_icon_state()
	if(exploded)
		icon_state = "bananiumbomb_exploding"
	else if(timing)
		icon_state = "bananiumbomb_timing"
	else
		icon_state = "bananiumbomb_base"

/obj/machinery/nuclearbomb/syndicate/bananium/update_overlays()
	return list()

/obj/machinery/nuclearbomb/syndicate/bananium/explode()
	if(!core)
		timing = FALSE
		safety = TRUE
		update_appearance()
		playsound(src, 'sound/misc/sadtrombone.ogg', 100, TRUE)
		visible_message(span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] издаёт печальный тромбонный звук: ядро отсутствует."))
		return
	return ..()

/obj/machinery/nuclearbomb/syndicate/bananium/nuke_effects()
	for(var/mob/living/carbon/human/victim in GLOB.human_list)
		if(is_station_level(victim.z))
			make_into_clown(victim)
		CHECK_TICK

/obj/machinery/nuclearbomb/syndicate/bananium/get_detonation_message(off_station)
	if(off_station)
		return span_bold("Вдали раздался оглушительный ХОНК. Представление прошло мимо станции!")
	return span_bold("Станция превращена в цирк бананиевой боеголовкой! ХОНК!")

/proc/make_into_clown(mob/living/carbon/human/victim)
	if(!istype(victim))
		return
	victim.Stun(1 SECONDS)
	var/alist/clown_slots = alist(
		ITEM_SLOT_CLOTH_INNER = /obj/item/clothing/under/rank/clown,
		ITEM_SLOT_FEET = /obj/item/clothing/shoes/clown_shoes,
		ITEM_SLOT_MASK = /obj/item/clothing/mask/gas/clown_hat,
	)
	for(var/slot, clothing_type in clown_slots)
		var/obj/item/current_item = victim.get_item_by_slot(slot)
		if(current_item && !victim.drop_item_ground(current_item))
			continue
		var/obj/item/clothing/clown_item = new clothing_type(victim)
		ADD_TRAIT(clown_item, TRAIT_NODROP, CLOWN_NUKE)
		victim.equip_to_slot_or_del(clown_item, slot)
	victim.force_gene_block(GLOB.clumsyblock, TRUE)
	victim.gain_trauma(/datum/brain_trauma/mild/phobia/clowns, TRAUMA_RESILIENCE_LOBOTOMY)
