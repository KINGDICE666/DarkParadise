/obj/item/antag_spawner/nuke_ops/clown
	name = "clown operative beacon"
	desc = "Одноразовый маяк подкрепления клоунов-оперативников."
	rolename = "клоуна-оперативника"

/obj/item/antag_spawner/nuke_ops/monkey
	name = "monkey agent beacon"
	desc = "Одноразовый маяк вызова специально обученной обезьяны-агента. Она понимает Общий, но разговаривает только на обезьяньем языке."
	rolename = "обезьяну-агента"

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
		agent.visible_message(span_bolddanger("[agent] стремительно раздува[PLUR_ET_YUT(agent)]тся от аллергической реакции!"))
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
	desc = "Боевая модель HONK, окрашенная в чёрный для максимального веселья."
	icon = 'icons/obj/mecha/dark_honker.dmi'
	icon_state = "darkhonker"
	initial_icon = "darkhonker"
	ui_theme = "syndicate"
	max_integrity = 300
	armor = list(MELEE = 40, BULLET = 40, LASER = 50, ENERGY = 35, BOMB = 20, FIRE = 100, ACID = 100)
	max_temperature = 35000
	operation_req_access = list(ACCESS_SYNDICATE)
	wreckage = /obj/structure/mecha_wreckage/honker/dark

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
	icon = 'icons/obj/mecha/dark_honker.dmi'
	icon_state = "darkhonker-broken"

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar/bombanana
	name = "bombanana mortar"
	desc = "Меховая пусковая установка взрывных банановых кожурок."
	projectile = /obj/item/grown/bananapeel/bombanana

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/flashbang/tearstache
	name = "tear-stache launcher"
	desc = "Меховая пусковая установка газовых гранат с липкими усами."
	projectile = /obj/item/grenade/chem_grenade/teargas/moustache
	module_type = MECH_EQUIPMENT_CLOWN

/obj/item/beacon/syndicate/bomb/clown
	name = "clown bomb beacon"
	desc = "Одноразовый маяк доставки клоунской бомбы."
	bomb = /obj/machinery/syndicatebomb/badmin/clown/operative

/obj/machinery/syndicatebomb/badmin/clown/operative
	payload = /obj/item/bombcore/badmin/summon/clown/operative

/obj/item/bombcore/badmin/summon/clown/operative
	amt_summon = 50

/obj/item/reagent_containers/food/snacks/grown/banana/bunch/monkeybomb
	name = "banana bunch"
	desc = "Гроздь бананов. Обезьяна знает, как устроить с её помощью громкую шутку."
	icon = 'icons/obj/clown_ops.dmi'
	icon_state = "banana_bunch"
	var/ripening = FALSE

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

/obj/item/gun/projectile/automatic/smg/mini_uzi/chimpgun/Initialize(mapload)
	. = ..()
	var/obj/item/firing_pin/monkey/pin = new
	pin.gun_insert(null, src)

/obj/item/gun/projectile/automatic/tommygun/chimpgun
	name = "Typewriter"
	desc = "Было лучшее время, было ХУДШЕСТЬ времён! Ты глупая обезьяна!"
	damage_mod = 0.4

/obj/item/gun/projectile/automatic/tommygun/chimpgun/Initialize(mapload)
	. = ..()
	var/obj/item/firing_pin/monkey/pin = new
	pin.gun_insert(null, src)

/obj/item/gun/projectile/automatic/pistol/m1911/chimpgun
	name = "CH1M911"
	desc = "Для обезьяньего мафиози. Использует патроны .45 и отчётливо пахнет бананами."
	damage_mod = 0.5

/obj/item/gun/projectile/automatic/pistol/m1911/chimpgun/Initialize(mapload)
	. = ..()
	var/obj/item/firing_pin/monkey/pin = new
	pin.gun_insert(null, src)
