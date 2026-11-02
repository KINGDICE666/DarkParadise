/obj/item/antag_spawner/nuke_ops/clown
	name = "clown operative beacon"
	gender = MALE
	desc = "Одноразовый маяк подкрепления клоунов-оперативников."
	rolename = "клоуна-оперативника"

/obj/item/antag_spawner/nuke_ops/clown/get_ru_names()
	return alist(
		NOMINATIVE = "маяк клоунского подкрепления",
		GENITIVE = "маяка клоунского подкрепления",
		DATIVE = "маяку клоунского подкрепления",
		ACCUSATIVE = "маяк клоунского подкрепления",
		INSTRUMENTAL = "маяком клоунского подкрепления",
		PREPOSITIONAL = "маяке клоунского подкрепления",
	)

/obj/item/antag_spawner/nuke_ops/monkey
	name = "monkey agent beacon"
	gender = MALE
	desc = "Одноразовый маяк вызова специально обученной обезьяны-агента. Она понимает Общий, но разговаривает только \
		на обезьяньем языке."
	rolename = "обезьяну-агента"

/obj/item/antag_spawner/nuke_ops/monkey/get_ru_names()
	return alist(
		NOMINATIVE = "маяк обезьяны-агента",
		GENITIVE = "маяка обезьяны-агента",
		DATIVE = "маяку обезьяны-агента",
		ACCUSATIVE = "маяк обезьяны-агента",
		INSTRUMENTAL = "маяком обезьяны-агента",
		PREPOSITIONAL = "маяке обезьяны-агента",
	)

/obj/item/antag_spawner/nuke_ops/monkey/spawn_antag(client/player, turf/location, datum/mind/summoner)
	var/mob/living/carbon/human/agent = new(location)
	agent.set_species(/datum/species/monkey/syndicate)
	agent.possess_by_player(player.key)
	agent.real_name = pick("Agent Chimp", "Agent Bubbles", "Agent Bananas", "Agent Coco", "Agent Kong")
	var/datum/antagonist/syndicate_monkey/helper = new
	helper.master_ref = WEAKREF(summoner.current)
	agent.mind.add_antag_datum(helper)
	agent.equipOutfit(/datum/outfit/syndicate_monkey)

/datum/species/monkey/syndicate
	name = "Syndicate Monkey"
	has_fine_manipulation = TRUE
	can_craft = TRUE
	no_equip = list(ITEM_SLOT_GLOVES)

/datum/antagonist/syndicate_monkey
	name = "Обезьяна-агент"
	antag_menu_name = "Обезьяна-агент"
	job_rank = ROLE_OPERATIVE
	special_role = ROLE_OPERATIVE
	antag_hud_type = ANTAG_HUD_OPS
	antag_hud_name = "hudoperative"
	var/datum/weakref/master_ref

/datum/antagonist/syndicate_monkey/Destroy(force)
	master_ref = null
	return ..()

/datum/antagonist/syndicate_monkey/give_objectives()
	var/datum/objective/syndicate_monkey/objective = new
	objective.owner = owner
	objective.master_ref = master_ref
	objective.explanation_text = "Защищайте своего хозяина и выполняйте его приказы."
	objectives += objective

/datum/objective/syndicate_monkey
	var/datum/weakref/master_ref

/datum/objective/syndicate_monkey/check_completion()
	var/mob/living/master = master_ref?.resolve()
	return master && master.stat != DEAD

/datum/antagonist/syndicate_monkey/greet()
	return span_notice("Вы специально обученная обезьяна-агент. Защищайте своего хозяина и выполняйте его приказы. Вы понимаете Общий язык, но не можете говорить на нём.")

/datum/antagonist/syndicate_monkey/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/agent = mob_override || owner.current
	agent.faction |= "syndicate"
	agent.grant_language(/datum/language/common, UNDERSTOOD_LANGUAGE, source = UID())
	agent.add_blocked_language(/datum/language/common, SPOKEN_LANGUAGE, source = UID())
	RegisterSignal(agent, COMSIG_HUMAN_SPECIES_CHANGED, PROC_REF(on_species_changed))

/datum/antagonist/syndicate_monkey/remove_innate_effects(mob/living/mob_override)
	var/mob/living/agent = mob_override || owner.current
	agent.faction -= "syndicate"
	agent.remove_blocked_language(/datum/language/common, SPOKEN_LANGUAGE, source = UID())
	agent.remove_language(/datum/language/common, UNDERSTOOD_LANGUAGE, source = UID())
	UnregisterSignal(agent, COMSIG_HUMAN_SPECIES_CHANGED)
	return ..()

/datum/antagonist/syndicate_monkey/proc/on_species_changed(mob/living/agent)
	SIGNAL_HANDLER
	if(!is_monkeybasic(agent))
		agent.visible_message(span_bolddanger("[agent.declent_ru(NOMINATIVE)] стремительно раздува[PLUR_ET_YUT(agent)]ся от аллергической реакции!"))
		addtimer(CALLBACK(agent, TYPE_PROC_REF(/mob/living, gib)), 5 SECONDS)

/datum/outfit/syndicate_monkey
	name = "Syndicate Monkey Agent"
	head = /obj/item/clothing/head/fedora
	mask = /obj/item/clothing/mask/cigarette/syndicate
	uniform = /obj/item/clothing/under/syndicate
	l_pocket = /obj/item/reagent_containers/cup/soda_cans/energy
	r_pocket = /obj/item/storage/fancy/cigarettes/cigpack_syndicate
	belt = /obj/item/lighter
	r_hand = /obj/item/reagent_containers/food/snacks/grown/banana

/obj/item/storage/box/syndie_kit/monkeycase
	name = "monkey gun case"
	desc = "Набор оружия и припасов для обезьяны-агента. Замок открывается только после проверки обезьяньей лапы."
	var/paw_locked = TRUE
	max_combined_w_class = 60
	storage_slots = 12

/obj/item/storage/box/syndie_kit/monkeycase/get_ru_names()
	return alist(
		NOMINATIVE = "оружейный кейс обезьяны-агента",
		GENITIVE = "оружейного кейса обезьяны-агента",
		DATIVE = "оружейному кейсу обезьяны-агента",
		ACCUSATIVE = "оружейный кейс обезьяны-агента",
		INSTRUMENTAL = "оружейным кейсом обезьяны-агента",
		PREPOSITIONAL = "оружейном кейсе обезьяны-агента",
	)

/obj/item/storage/box/syndie_kit/monkeycase/check_uplink_validity()
	return paw_locked && ..()

/obj/item/storage/box/syndie_kit/monkeycase/show_to(mob/user, from_inv_observers = FALSE)
	if(!isobserver(user) && !unlock_for_monkey(user))
		return
	return ..()

/obj/item/storage/box/syndie_kit/monkeycase/mouse_drop_dragged(atom/over_object, mob/user, src_location, over_location, params)
	if(!unlock_for_monkey(user))
		return
	return ..()

/obj/item/storage/box/syndie_kit/monkeycase/attack_hand(mob/user)
	if(!unlock_for_monkey(user))
		return
	return ..()

/obj/item/storage/box/syndie_kit/monkeycase/attack_self(mob/user)
	if(!unlock_for_monkey(user))
		return
	return ..()

/obj/item/storage/box/syndie_kit/monkeycase/proc/unlock_for_monkey(mob/user)
	if(!paw_locked)
		return TRUE
	if(!is_monkeybasic(user))
		balloon_alert(user, "доступ запрещён!")
		return FALSE
	paw_locked = FALSE
	balloon_alert(user, "замок открыт")
	return TRUE

/obj/item/storage/box/syndie_kit/monkeycase/populate_contents()
	switch(rand(1, 3))
		if(1)
			new /obj/item/gun/projectile/automatic/smg/mini_uzi/chimpgun(src)
			new /obj/item/ammo_box/magazine/uzim9mm(src)
			new /obj/item/ammo_box/magazine/uzim9mm(src)
			new /obj/item/kitchen/knife(src)
		if(2)
			new /obj/item/gun/projectile/automatic/tommygun/chimpgun(src)
			new /obj/item/ammo_box/magazine/tommygunm45(src)
			new /obj/item/ammo_box/magazine/tommygunm45(src)
			new /obj/item/kitchen/knife(src)
		if(3)
			new /obj/item/gun/projectile/automatic/pistol/m1911/chimpgun(src)
			new /obj/item/ammo_box/magazine/m45(src)
			new /obj/item/ammo_box/magazine/m45(src)
			new /obj/item/kitchen/knife(src)
			new /obj/item/reagent_containers/food/snacks/grown/banana/bunch/monkeybomb(src)
	new /obj/item/reagent_containers/food/snacks/grown/banana/bunch/monkeybomb(src)
	new /obj/item/storage/backpack(src)

/obj/mecha/combat/honker/dark
	name = "Dark H.O.N.K"
	gender = MALE
	desc = "Боевая модель экзокостюма \"Dark H.O.N.K.\" с усиленной бронёй и клоунским вооружением."
	icon_state = "darkhonker"
	initial_icon = "darkhonker"
	ui_theme = "syndicate"
	max_integrity = 300
	armor = list(MELEE = 40, BULLET = 40, LASER = 50, ENERGY = 35, BOMB = 20, FIRE = 100, ACID = 100)
	max_temperature = 35000
	operation_req_access = list(ACCESS_SYNDICATE)
	wreckage = /obj/structure/mecha_wreckage/honker/dark

/obj/mecha/combat/honker/dark/get_ru_names()
	return alist(
		NOMINATIVE = "боевой экзокостюм \"Dark H.O.N.K.\"",
		GENITIVE = "боевого экзокостюма \"Dark H.O.N.K.\"",
		DATIVE = "боевому экзокостюму \"Dark H.O.N.K.\"",
		ACCUSATIVE = "боевой экзокостюм \"Dark H.O.N.K.\"",
		INSTRUMENTAL = "боевым экзокостюмом \"Dark H.O.N.K.\"",
		PREPOSITIONAL = "боевом экзокостюме \"Dark H.O.N.K.\"",
	)

/obj/mecha/combat/honker/dark/loaded/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/equipment = new /obj/item/mecha_parts/mecha_equipment/weapon/honker(src)
	equipment.attach(src, MECH_HAND_LEFT)
	equipment = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar/bombanana(src)
	equipment.attach(src, MECH_HAND_RIGHT)
	equipment = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/tearstache(src)
	equipment.attach(src, MECH_HAND_RIGHT)
	QDEL_NULL(cell)
	cell = new /obj/item/stock_parts/cell/hyper(src)

/obj/structure/mecha_wreckage/honker/dark
	name = "Dark H.O.N.K wreckage"
	gender = PLURAL
	icon_state = "darkhonker-broken"

/obj/structure/mecha_wreckage/honker/dark/get_ru_names()
	return alist(
		NOMINATIVE = "обломки экзокостюма \"Dark H.O.N.K.\"",
		GENITIVE = "обломков экзокостюма \"Dark H.O.N.K.\"",
		DATIVE = "обломкам экзокостюма \"Dark H.O.N.K.\"",
		ACCUSATIVE = "обломки экзокостюма \"Dark H.O.N.K.\"",
		INSTRUMENTAL = "обломками экзокостюма \"Dark H.O.N.K.\"",
		PREPOSITIONAL = "обломках экзокостюма \"Dark H.O.N.K.\"",
	)

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar/bombanana
	name = "bombanana mortar"
	gender = FEMALE
	desc = "Установка для стрельбы взрывными банановыми кожурками. Монтируется на экзокостюм."
	projectile = /obj/item/grown/bananapeel/bombanana

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar/bombanana/get_ru_names()
	return alist(
		NOMINATIVE = "бомбанановая мортира",
		GENITIVE = "бомбанановой мортиры",
		DATIVE = "бомбанановой мортире",
		ACCUSATIVE = "бомбанановую мортиру",
		INSTRUMENTAL = "бомбанановой мортирой",
		PREPOSITIONAL = "бомбанановой мортире",
	)

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/tearstache
	name = "tear-stache launcher"
	gender = MALE
	desc = "Установка для стрельбы газовыми гранатами с липкими усами. Монтируется на экзокостюм."
	projectile = /obj/item/grenade/chem_grenade/teargas/moustache
	module_type = MECH_EQUIPMENT_CLOWN

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/tearstache/get_ru_names()
	return alist(
		NOMINATIVE = "усатый гранатомёт",
		GENITIVE = "усатого гранатомёта",
		DATIVE = "усатому гранатомёту",
		ACCUSATIVE = "усатый гранатомёт",
		INSTRUMENTAL = "усатым гранатомётом",
		PREPOSITIONAL = "усатом гранатомёте",
	)

/obj/item/beacon/syndicate/bomb/clown
	name = "clown bomb beacon"
	gender = MALE
	desc = "Одноразовый маяк доставки клоунской бомбы."
	bomb = /obj/machinery/syndicatebomb/badmin/clown/operative

/obj/item/beacon/syndicate/bomb/clown/get_ru_names()
	return alist(
		NOMINATIVE = "маяк клоунской бомбы",
		GENITIVE = "маяка клоунской бомбы",
		DATIVE = "маяку клоунской бомбы",
		ACCUSATIVE = "маяк клоунской бомбы",
		INSTRUMENTAL = "маяком клоунской бомбы",
		PREPOSITIONAL = "маяке клоунской бомбы",
	)

/obj/machinery/syndicatebomb/badmin/clown/operative
	gender = FEMALE
	desc = "Клоунская бомба с таймером. Изнутри доносятся подозрительные хонки."
	payload = /obj/item/bombcore/badmin/summon/clown/operative

/obj/machinery/syndicatebomb/badmin/clown/operative/get_ru_names()
	return alist(
		NOMINATIVE = "клоунская бомба",
		GENITIVE = "клоунской бомбы",
		DATIVE = "клоунской бомбе",
		ACCUSATIVE = "клоунскую бомбу",
		INSTRUMENTAL = "клоунской бомбой",
		PREPOSITIONAL = "клоунской бомбе",
	)

/obj/item/bombcore/badmin/summon/clown/operative
	name = "clown bomb payload"
	gender = MALE
	desc = "Заряд для клоунской бомбы. Внутри что-то шевелится."
	amt_summon = 50

/obj/item/bombcore/badmin/summon/clown/operative/get_ru_names()
	return alist(
		NOMINATIVE = "заряд клоунской бомбы",
		GENITIVE = "заряда клоунской бомбы",
		DATIVE = "заряду клоунской бомбы",
		ACCUSATIVE = "заряд клоунской бомбы",
		INSTRUMENTAL = "зарядом клоунской бомбы",
		PREPOSITIONAL = "заряде клоунской бомбы",
	)

/obj/item/reagent_containers/food/snacks/grown/banana/bunch/monkeybomb
	name = "banana bunch"
	gender = FEMALE
	desc = "Гроздь бананов. Обезьяна знает, как устроить с её помощью громкую шутку."
	icon_state = "banana_bunch"
	var/ripening = FALSE

/obj/item/reagent_containers/food/snacks/grown/banana/bunch/monkeybomb/get_ru_names()
	return alist(
		NOMINATIVE = "гроздь бананов",
		GENITIVE = "грозди бананов",
		DATIVE = "грозди бананов",
		ACCUSATIVE = "гроздь бананов",
		INSTRUMENTAL = "гроздью бананов",
		PREPOSITIONAL = "грозди бананов",
	)

/obj/item/reagent_containers/food/snacks/grown/banana/bunch/monkeybomb/attack_self(mob/user)
	if(ripening)
		return
	if(!is_monkeybasic(user))
		balloon_alert(user, "нужна обезьянья лапа!")
		return
	ripening = TRUE
	add_attack_logs(user, src, "Armed a monkey banana sound bomb", ATKLOG_FEW)
	playsound(src, 'sound/weapons/armbomb.ogg', 75, TRUE)
	addtimer(CALLBACK(src, PROC_REF(burst)), 3 SECONDS)

/obj/item/reagent_containers/food/snacks/grown/banana/bunch/monkeybomb/proc/burst()
	honkerblast(src, light_range = 3, medium_range = 1)
	for(var/mob/viewer in viewers(6, get_turf(src)))
		shake_camera(viewer, 3, 5)
	var/obj/effect/decal/cleanable/plant_smudge/smudge = new(get_turf(src))
	smudge.color = COLOR_YELLOW
	qdel(src)

/obj/item/gun/projectile/automatic/smg/mini_uzi/chimpgun
	name = "MONK-10"
	desc = "Разработано обезьянами Синдиката для обезьян Синдиката. Использует патроны 9 мм."
	damage_mod = 0.4

/obj/item/gun/projectile/automatic/smg/mini_uzi/chimpgun/get_ru_names()
	return alist(
		NOMINATIVE = "пистолет-пулемёт MONK-10",
		GENITIVE = "пистолета-пулемёта MONK-10",
		DATIVE = "пистолету-пулемёту MONK-10",
		ACCUSATIVE = "пистолет-пулемёт MONK-10",
		INSTRUMENTAL = "пистолетом-пулемётом MONK-10",
		PREPOSITIONAL = "пистолете-пулемёте MONK-10",
	)

/obj/item/gun/projectile/automatic/smg/mini_uzi/chimpgun/Initialize(mapload)
	. = ..()
	var/obj/item/firing_pin/monkey/pin = new
	pin.gun_insert(null, src)

/obj/item/gun/projectile/automatic/tommygun/chimpgun
	name = "Typewriter"
	gender = MALE
	desc = "Было лучшее время, было ХУДШЕСТЬ времён! Ты глупая обезьяна!"
	damage_mod = 0.4

/obj/item/gun/projectile/automatic/tommygun/chimpgun/get_ru_names()
	return alist(
		NOMINATIVE = "пистолет-пулемёт \"Печатная машинка\"",
		GENITIVE = "пистолета-пулемёта \"Печатная машинка\"",
		DATIVE = "пистолету-пулемёту \"Печатная машинка\"",
		ACCUSATIVE = "пистолет-пулемёт \"Печатная машинка\"",
		INSTRUMENTAL = "пистолетом-пулемётом \"Печатная машинка\"",
		PREPOSITIONAL = "пистолете-пулемёте \"Печатная машинка\"",
	)

/obj/item/gun/projectile/automatic/tommygun/chimpgun/Initialize(mapload)
	. = ..()
	var/obj/item/firing_pin/monkey/pin = new
	pin.gun_insert(null, src)

/obj/item/gun/projectile/automatic/pistol/m1911/chimpgun
	name = "CH1M911"
	desc = "Для обезьяньего мафиози. Использует патроны .45 и отчётливо пахнет бананами."
	damage_mod = 0.5

/obj/item/gun/projectile/automatic/pistol/m1911/chimpgun/get_ru_names()
	return alist(
		NOMINATIVE = "пистолет CH1M911",
		GENITIVE = "пистолета CH1M911",
		DATIVE = "пистолету CH1M911",
		ACCUSATIVE = "пистолет CH1M911",
		INSTRUMENTAL = "пистолетом CH1M911",
		PREPOSITIONAL = "пистолете CH1M911",
	)

/obj/item/gun/projectile/automatic/pistol/m1911/chimpgun/Initialize(mapload)
	. = ..()
	var/obj/item/firing_pin/monkey/pin = new
	pin.gun_insert(null, src)
