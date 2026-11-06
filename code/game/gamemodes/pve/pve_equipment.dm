/datum/outfit/pve
	name = "PvE Survivor"
	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/color/black
	back = /obj/item/storage/backpack
	id = /obj/item/card/id
	l_hand = /obj/item/melee/baseball_bat
	r_pocket = /obj/item/kitchen/knife
	backpack_contents = list(/obj/item/stack/medical/bruise_pack = 1)

/datum/outfit/pve/pre_equip(mob/living/carbon/human/human, visualsOnly = FALSE)
	. = ..()
	human.dna.species.before_equip_job(SSjobs.GetJob(JOB_TITLE_CIVILIAN), human, visualsOnly)

/datum/outfit/pve/post_equip(mob/living/carbon/human/human, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return
	human.dna.species.after_equip_job(SSjobs.GetJob(JOB_TITLE_CIVILIAN), human, visualsOnly)
	var/obj/item/card/id/card = human.wear_id
	if(istype(card))
		card.registered_name = human.real_name
		card.assignment = "Боец PvE"
		card.update_label()
	var/datum/game_mode/pve/mode = SSticker.mode
	if(istype(mode))
		if(human.z != mode.arena_z)
			human.forceMove(pick(GLOB.start_override))
		mode.register_player(human)

/obj/machinery/computer/pve_shop
	name = "PvE supply terminal"
	desc = "Снабжение защитников коридора. Кредиты начисляются за зачищенные волны."
	use_power = NO_POWER_USE
	resistance_flags = INDESTRUCTIBLE
	var/static/list/products = list(
		"bandages" = list("name" = "Бинты", "price" = 25, "path" = /obj/item/stack/medical/bruise_pack),
		"ointment" = list("name" = "Мазь от ожогов", "price" = 25, "path" = /obj/item/stack/medical/ointment),
		"firstaid" = list("name" = "Аптечка", "price" = 100, "path" = /obj/item/storage/firstaid/regular),
		"injector" = list("name" = "Экстренный автоинъектор", "price" = 75, "path" = /obj/item/reagent_containers/hypospray/autoinjector),
		"armor" = list("name" = "Бронежилет", "price" = 200, "path" = /obj/item/clothing/suit/armor/vest),
		"helmet" = list("name" = "Шлем", "price" = 100, "path" = /obj/item/clothing/head/helmet),
		"shotgun" = list("name" = "Дробовик", "price" = 300, "path" = /obj/item/gun/projectile/shotgun),
		"shells" = list("name" = "Коробка дроби", "price" = 60, "path" = /obj/item/ammo_box/shotgun/buck),
		"laser" = list("name" = "Лазерный карабин", "price" = 500, "path" = /obj/item/gun/energy/laser),
		"turret" = list("name" = "Комплект турели", "price" = 800, "path" = /obj/item/pve_turret_kit),
	)

/obj/machinery/computer/pve_shop/get_ru_names()
	return alist(
		NOMINATIVE = "терминал снабжения PvE",
		GENITIVE = "терминала снабжения PvE",
		DATIVE = "терминалу снабжения PvE",
		ACCUSATIVE = "терминал снабжения PvE",
		INSTRUMENTAL = "терминалом снабжения PvE",
		PREPOSITIONAL = "терминале снабжения PvE",
	)

/obj/machinery/computer/pve_shop/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PveShop", "Снабжение PvE")
		ui.open()

/obj/machinery/computer/pve_shop/ui_data(mob/user)
	var/list/data = list("available" = FALSE)
	var/datum/game_mode/pve/mode = SSticker.mode
	if(!istype(mode) || mode.arena_z != z)
		return data
	var/datum/pve_account/account = mode.player_accounts[user.mind?.UID()]
	if(!account || account.mind_ref?.resolve() != user.mind)
		return data
	data["available"] = TRUE
	data["finished"] = mode.finished
	data["credits"] = account.credits
	data["score"] = account.score
	data["wave"] = mode.wave
	data["completed"] = mode.completed_waves
	data["active"] = mode.wave_active
	data["enemies"] = length(mode.active_enemies) + mode.enemies_to_spawn
	data["seconds"] = max(0, round((mode.next_wave - world.time) / (1 SECONDS)))
	data["survivors"] = length(mode.living_players())
	return data

/obj/machinery/computer/pve_shop/ui_static_data(mob/user)
	var/list/items = list()
	for(var/product_id in products)
		var/list/product = products[product_id]
		items += list(list("id" = product_id, "name" = product["name"], "price" = product["price"]))
	return list("products" = items)

/obj/machinery/computer/pve_shop/ui_act(action, list/params)
	if(..())
		return
	if(action == "buy")
		return purchase(usr, params["id"])

/obj/machinery/computer/pve_shop/proc/purchase(mob/living/user, product_id)
	var/datum/game_mode/pve/mode = SSticker.mode
	if(!istype(mode) || mode.finished || mode.arena_z != z)
		return FALSE
	if(!istype(user) || user.stat != CONSCIOUS || user.incapacitated() || !Adjacent(user))
		return FALSE
	var/datum/pve_account/account = mode.player_accounts[user.mind?.UID()]
	var/list/product = products[product_id]
	if(!account || account.mind_ref?.resolve() != user.mind || !product)
		return FALSE
	var/price = product["price"]
	if(account.credits < price)
		balloon_alert(user, "недостаточно кредитов")
		return FALSE
	account.credits -= price
	var/item_type = product["path"]
	var/obj/item/item = new item_type(get_turf(user))
	user.put_in_hands(item)
	balloon_alert(user, "покупка выдана")
	return TRUE

/obj/item/pve_turret_kit
	name = "PvE turret kit"
	desc = "Развёртывается в автономную турель за три секунды. Атакует только противников волн. Используйте в руке на свободном участке арены."
	icon = 'icons/obj/storage/boxes.dmi'
	icon_state = "box"
	var/deploying = FALSE

/obj/item/pve_turret_kit/get_ru_names()
	return alist(
		NOMINATIVE = "комплект турели PvE",
		GENITIVE = "комплекта турели PvE",
		DATIVE = "комплекту турели PvE",
		ACCUSATIVE = "комплект турели PvE",
		INSTRUMENTAL = "комплектом турели PvE",
		PREPOSITIONAL = "комплекте турели PvE",
	)

/obj/item/pve_turret_kit/attack_self(mob/user)
	var/datum/game_mode/pve/mode = SSticker.mode
	var/turf/deployment_turf = get_turf(user)
	if(!istype(mode) || mode.finished || user.z != mode.arena_z || deploying || loc != user)
		return
	if(deployment_turf.is_blocked_turf(exclude_mobs = TRUE))
		balloon_alert(user, "нужно свободное место")
		return
	deploying = TRUE
	if(!do_after(user, 3 SECONDS, target = src))
		deploying = FALSE
		return
	deploying = FALSE
	if(loc != user || get_turf(user) != deployment_turf || mode.finished || deployment_turf.is_blocked_turf(exclude_mobs = TRUE))
		return
	new /obj/machinery/porta_turret/syndicate/pve(deployment_turf)
	qdel(src)

/obj/machinery/porta_turret/syndicate/pve
	name = "PvE defense turret"
	desc = "Автономная турель защитников коридора. Атакует только противников волн."
	health = 150
	projectile = /obj/projectile/bullet/pve_turret
	eprojectile = /obj/projectile/bullet/pve_turret
	faction = "pve_players"
	req_access = list()
	controllock = TRUE
	shot_delay = 1 SECONDS

/obj/machinery/porta_turret/syndicate/pve/get_ru_names()
	return alist(
		NOMINATIVE = "защитная турель PvE",
		GENITIVE = "защитной турели PvE",
		DATIVE = "защитной турели PvE",
		ACCUSATIVE = "защитную турель PvE",
		INSTRUMENTAL = "защитной турелью PvE",
		PREPOSITIONAL = "защитной турели PvE",
	)

/obj/machinery/porta_turret/syndicate/pve/assess_living(mob/living/target)
	if(!istype(target, /mob/living/simple_animal/hostile/carp/pve) || target.stat == DEAD)
		return TURRET_NOT_TARGET
	return TURRET_PRIORITY_TARGET

/obj/projectile/bullet/pve_turret
	damage = 20

/obj/projectile/bullet/pve_turret/prehit(atom/target)
	. = ..()
	nodamage = isliving(target) && !istype(target, /mob/living/simple_animal/hostile/carp/pve)
	forcedodge = nodamage

/obj/projectile/bullet/pve_turret/on_hit(atom/target, blocked = 0, hit_zone)
	if(isliving(target) && !istype(target, /mob/living/simple_animal/hostile/carp/pve))
		return -1
	return ..()
