#define PVE_CORE_REPAIR_AMOUNT 300
#define PVE_CORE_REINFORCE_AMOUNT 250
#define PVE_ARTILLERY_DAMAGE 80
#define PVE_ARTILLERY_BOSS_FACTOR 0.25

/datum/pve_product
	abstract_type = /datum/pve_product
	var/title
	var/description
	var/price = 0
	var/category
	var/obj/item/item_path
	var/amount = 1
	var/class_only
	var/limit = 0
	var/sold = 0
	var/once_per_wave = FALSE
	var/last_wave_bought = -1

/datum/pve_product/proc/get_price(datum/pve_class/buyer_class)
	return round(price * (buyer_class ? buyer_class.get_price_multiplier(category) : 1))

/datum/pve_product/proc/get_error(datum/game_mode/pve/mode, datum/pve_account/account)
	if(class_only && account.class_id != class_only)
		return "только для другого класса"
	if(limit && sold >= limit)
		return "распродано"
	if(once_per_wave && last_wave_bought == mode.wave)
		return "уже куплено в эту волну"
	return null

/datum/pve_product/proc/deliver(mob/living/user, datum/game_mode/pve/mode)
	for(var/i in 1 to amount)
		var/obj/item/item = new item_path(get_turf(user))
		user.put_in_hands(item)
	return TRUE

/datum/pve_product/proc/ui_entry()
	var/obj/item/preview = item_path
	return list(
		"id" = "[type]",
		"title" = title,
		"description" = description,
		"price" = price,
		"category" = category,
		"class_only" = class_only,
		"limit" = limit,
		"icon" = preview ? initial(preview.icon) : null,
		"icon_state" = preview ? initial(preview.icon_state) : null,
	)

/datum/pve_product/weapon
	abstract_type = /datum/pve_product/weapon
	category = PVE_CATEGORY_WEAPONS

/datum/pve_product/weapon/pistol
	title = "Пистолет 10 мм"
	description = "Надёжный пистолет на 8 патронов. Запасные магазины — в боеприпасах."
	price = 150
	item_path = /obj/item/gun/projectile/automatic/pistol

/datum/pve_product/weapon/mosin
	title = "Винтовка Мосина"
	description = "Мощный выстрел, ручная перезарядка. Заряжается обоймами по 5 патронов."
	price = 220
	item_path = /obj/item/gun/projectile/shotgun/boltaction

/datum/pve_product/weapon/shotgun
	title = "Помповый дробовик"
	description = "Картечь в упор разрывает призраков и мелочь. Заряжен."
	price = 300
	item_path = /obj/item/gun/projectile/shotgun/riot/buckshot

/datum/pve_product/weapon/laser
	title = "Лазерная винтовка"
	description = "Не нужны патроны — заряжайте в оружейной. Плавит каменных големов."
	price = 420
	item_path = /obj/item/gun/energy/laser

/datum/pve_product/weapon/fireaxe
	title = "Пожарный топор"
	description = "Двуручный топор. Страшен в ближнем бою."
	price = 250
	item_path = /obj/item/twohanded/fireaxe

/datum/pve_product/weapon/claymore
	title = "Клеймор"
	description = "Тяжёлый меч. Можно держать вместе со щитом."
	price = 400
	item_path = /obj/item/melee/claymore

/datum/pve_product/weapon/smg
	title = "Пистолет-пулемёт WT-550"
	description = "Скорострельный пистолет-пулемёт на 20 патронов."
	price = 550
	item_path = /obj/item/gun/projectile/automatic/smg/wt550

/datum/pve_product/weapon/combat_shotgun
	title = "Боевой дробовик"
	description = "Полуавтоматический дробовик с картечью. Сносит толпу."
	price = 900
	item_path = /obj/item/gun/projectile/shotgun/automatic/combat

/datum/pve_product/weapon/laser_cannon
	title = "Лазерная пушка"
	description = "Медленный, но сокрушительный лазер. Заряжайте в оружейной."
	price = 1100
	item_path = /obj/item/gun/energy/lasercannon

/datum/pve_product/weapon/pulse
	title = "Импульсный карабин"
	description = "Вершина огневой мощи. Для последних волн."
	price = 2800
	item_path = /obj/item/gun/energy/pulse/carbine

/datum/pve_product/weapon/m90
	title = "Карабин М-90"
	description = "Автоматический карабин штурмовика."
	price = 1200
	item_path = /obj/item/gun/projectile/automatic/m90
	class_only = PVE_CLASS_ASSAULT

/datum/pve_product/weapon/saw
	title = "Пулемёт L6 SAW"
	description = "Пулемёт на 50 патронов. Держит проход в одиночку."
	price = 2200
	item_path = /obj/item/gun/projectile/automatic/l6_saw
	class_only = PVE_CLASS_ASSAULT

/datum/pve_product/weapon/sniper
	title = "Снайперская винтовка"
	description = "Пробивает любую тварь насквозь. Оружие стрелка."
	price = 1300
	item_path = /obj/item/gun/projectile/automatic/sniper_rifle
	class_only = PVE_CLASS_MARKSMAN

/datum/pve_product/weapon/flamethrower
	title = "Огнемёт"
	description = "Выжигает проход перед защитником. Осторожно со своими."
	price = 700
	item_path = /obj/item/flamethrower/full/tank
	class_only = PVE_CLASS_GUARDIAN

/datum/pve_product/ammo
	abstract_type = /datum/pve_product/ammo
	category = PVE_CATEGORY_AMMO

/datum/pve_product/ammo/pistol
	title = "Магазин 10 мм"
	description = "Для пистолета 10 мм."
	price = 40
	item_path = /obj/item/ammo_box/magazine/m10mm

/datum/pve_product/ammo/rifle
	title = "Обойма 7,62 мм"
	description = "Пять патронов для винтовки Мосина."
	price = 35
	item_path = /obj/item/ammo_box/speedloader/a762

/datum/pve_product/ammo/buckshot
	title = "Зарядник картечи"
	description = "Быстрое заряжание дробовика картечью."
	price = 50
	item_path = /obj/item/ammo_box/speedloader/shotgun/buck

/datum/pve_product/ammo/smg
	title = "Магазин WT-550"
	description = "20 патронов для пистолета-пулемёта."
	price = 70
	item_path = /obj/item/ammo_box/magazine/wt550m9

/datum/pve_product/ammo/m90
	title = "Магазин 5,56 мм"
	description = "Для карабина М-90."
	price = 110
	item_path = /obj/item/ammo_box/magazine/m556
	class_only = PVE_CLASS_ASSAULT

/datum/pve_product/ammo/saw
	title = "Короб для L6 SAW"
	description = "50 патронов для пулемёта."
	price = 280
	item_path = /obj/item/ammo_box/magazine/l6saw
	class_only = PVE_CLASS_ASSAULT

/datum/pve_product/ammo/sniper
	title = "Магазин снайперских патронов"
	description = "Для снайперской винтовки."
	price = 150
	item_path = /obj/item/ammo_box/magazine/sniper_rounds
	class_only = PVE_CLASS_MARKSMAN

/datum/pve_product/ammo/frag
	title = "Осколочная граната"
	description = "Разносит толпу. И союзников рядом с ней."
	price = 120
	item_path = /obj/item/grenade/frag

/datum/pve_product/armor
	abstract_type = /datum/pve_product/armor
	category = PVE_CATEGORY_ARMOR

/datum/pve_product/armor/vest
	title = "Бронежилет"
	description = "Базовая защита корпуса."
	price = 120
	item_path = /obj/item/clothing/suit/armor/vest

/datum/pve_product/armor/helmet
	title = "Шлем"
	description = "Базовая защита головы."
	price = 80
	item_path = /obj/item/clothing/head/helmet

/datum/pve_product/armor/riot
	title = "Антибунтовая броня"
	description = "Отличная защита от когтей и клыков."
	price = 300
	item_path = /obj/item/clothing/suit/armor/riot

/datum/pve_product/armor/riot_helmet
	title = "Антибунтовой шлем"
	description = "Отличная защита головы в ближнем бою."
	price = 150
	item_path = /obj/item/clothing/head/helmet/riot

/datum/pve_product/armor/heavy
	title = "Тяжёлая броня"
	description = "Максимальная защита ценой подвижности."
	price = 750
	item_path = /obj/item/clothing/suit/armor/heavy

/datum/pve_product/armor/gloves
	title = "Боевые перчатки"
	description = "Защищают руки."
	price = 60
	item_path = /obj/item/clothing/gloves/combat

/datum/pve_product/armor/flashlight
	title = "Тактический фонарь"
	description = "Пригодится, когда туман приносит ночь."
	price = 40
	item_path = /obj/item/flashlight/seclite

/datum/pve_product/armor/night_vision
	title = "Прибор ночного видения"
	description = "Видеть в темноте без фонаря."
	price = 350
	item_path = /obj/item/clothing/glasses/night

/datum/pve_product/armor/thermal
	title = "Тепловизор"
	description = "Видеть тварей сквозь стены и туман."
	price = 600
	item_path = /obj/item/clothing/glasses/thermal
	class_only = PVE_CLASS_MARKSMAN

/datum/pve_product/medicine
	abstract_type = /datum/pve_product/medicine
	category = PVE_CATEGORY_MEDICINE

/datum/pve_product/medicine/bruise_pack
	title = "Бинты"
	description = "Останавливают кровь и лечат ушибы."
	price = 25
	item_path = /obj/item/stack/medical/bruise_pack

/datum/pve_product/medicine/ointment
	title = "Мазь от ожогов"
	description = "Лечит ожоги от кислоты и снарядов."
	price = 25
	item_path = /obj/item/stack/medical/ointment

/datum/pve_product/medicine/splint
	title = "Шина"
	description = "Для переломов."
	price = 20
	item_path = /obj/item/stack/medical/splint

/datum/pve_product/medicine/advanced_bruise_pack
	title = "Продвинутый набор от травм"
	description = "Быстро лечит тяжёлые раны."
	price = 70
	item_path = /obj/item/stack/medical/bruise_pack/advanced

/datum/pve_product/medicine/advanced_ointment
	title = "Продвинутый набор от ожогов"
	description = "Быстро лечит тяжёлые ожоги."
	price = 70
	item_path = /obj/item/stack/medical/ointment/advanced

/datum/pve_product/medicine/epinephrine
	title = "Автоинъектор адреналина"
	description = "Стабилизирует умирающего товарища."
	price = 40
	item_path = /obj/item/reagent_containers/hypospray/autoinjector

/datum/pve_product/medicine/firstaid
	title = "Аптечка"
	description = "Стандартный набор первой помощи."
	price = 150
	item_path = /obj/item/storage/firstaid/regular

/datum/pve_product/medicine/advanced_firstaid
	title = "Продвинутая аптечка"
	description = "Набор для серьёзных ранений."
	price = 300
	item_path = /obj/item/storage/firstaid/adv

/datum/pve_product/medicine/survival
	title = "Медипен выживания"
	description = "Мощная смесь, поднимающая на ноги почти из любого состояния."
	price = 200
	item_path = /obj/item/reagent_containers/hypospray/autoinjector/survival

/datum/pve_product/medicine/stimpack
	title = "Стимпак"
	description = "Ненадолго ускоряет и придаёт сил."
	price = 150
	item_path = /obj/item/reagent_containers/hypospray/autoinjector/stimpack

/datum/pve_product/medicine/health_hud
	title = "Медицинский HUD"
	description = "Показывает здоровье союзников."
	price = 80
	item_path = /obj/item/clothing/glasses/hud/health

/datum/pve_product/medicine/defibrillator
	title = "Компактный дефибриллятор"
	description = "Возвращает павших прямо в бою."
	price = 450
	item_path = /obj/item/defibrillator/compact/loaded
	class_only = PVE_CLASS_MEDIC

/datum/pve_product/medicine/medbeam
	title = "Медицинский лучемёт"
	description = "Непрерывно лечит союзника на расстоянии."
	price = 1500
	item_path = /obj/item/gun/medbeam
	class_only = PVE_CLASS_MEDIC

/datum/pve_product/structure
	abstract_type = /datum/pve_product/structure
	category = PVE_CATEGORY_STRUCTURES

/datum/pve_product/structure/barricade
	title = "Деревянная баррикада"
	description = "Укрытие, через которое можно стрелять. Пятью досками превращается в стену."
	price = 50
	item_path = /obj/item/pve_deployable/barricade

/datum/pve_product/structure/sandbags
	title = "Мешки с песком"
	description = "Прочное укрытие, держит удар громилы."
	price = 90
	item_path = /obj/item/pve_deployable/sandbags

/datum/pve_product/structure/barrier
	title = "Барьерная граната"
	description = "Разворачивает металлические барьеры."
	price = 150
	item_path = /obj/item/grenade/barrier

/datum/pve_product/structure/mine
	title = "Мина тумана"
	description = "Взрывается под тварями, не трогая своих."
	price = 60
	item_path = /obj/item/pve_deployable/mine

/datum/pve_product/structure/lamp
	title = "Прожектор"
	description = "Освещает поле боя ночью."
	price = 60
	item_path = /obj/item/pve_deployable/lamp

/datum/pve_product/structure/flare
	title = "Сигнальный факел"
	description = "Дешёвый свет, который можно бросить вперёд."
	price = 15
	item_path = /obj/item/flashlight/flare

/datum/pve_product/structure/med_station
	title = "Полевая медстанция"
	description = "Лечит всех союзников рядом."
	price = 450
	item_path = /obj/item/pve_deployable/med_station

/datum/pve_product/structure/metal
	title = "Сталь, 50 листов"
	description = "Для стен, решёток и всего, что придумает инженер."
	price = 120
	item_path = /obj/item/stack/sheet/metal/fifty

/datum/pve_product/structure/wood
	title = "Доски, 50 штук"
	description = "Укрепляют баррикады до деревянных стен."
	price = 80
	item_path = /obj/item/stack/sheet/wood/fifty

/datum/pve_product/structure/welder
	title = "Большой сварочный аппарат"
	description = "Чинит Маяк, турели и металлические барьеры."
	price = 60
	item_path = /obj/item/weldingtool/largetank

/datum/pve_product/structure/turret
	title = "Турель"
	description = "Автономная турель. Её убийства приносят кредиты владельцу."
	price = 500
	item_path = /obj/item/pve_deployable/turret
	class_only = PVE_CLASS_ENGINEER

/datum/pve_product/structure/heavy_turret
	title = "Тяжёлая турель"
	description = "Вдвое прочнее и бьёт сильнее обычной."
	price = 1100
	item_path = /obj/item/pve_deployable/turret/heavy
	class_only = PVE_CLASS_ENGINEER

/datum/pve_product/support
	abstract_type = /datum/pve_product/support
	category = PVE_CATEGORY_SUPPORT

/datum/pve_product/support/core_repair
	title = "Ремонт Маяка"
	description = "Восстанавливает Маяку 300 единиц целостности."
	price = 300

/datum/pve_product/support/core_repair/deliver(mob/living/user, datum/game_mode/pve/mode)
	if(!mode.core || mode.core.obj_integrity >= mode.core.max_integrity)
		return FALSE
	mode.core.repair_damage(PVE_CORE_REPAIR_AMOUNT)
	mode.broadcast(span_notice("[user.real_name] оплачивает ремонт Маяка."))
	return TRUE

/datum/pve_product/support/core_reinforce
	title = "Укрепление Маяка"
	description = "Увеличивает прочность Маяка на 250 навсегда."
	price = 700
	limit = 4

/datum/pve_product/support/core_reinforce/deliver(mob/living/user, datum/game_mode/pve/mode)
	if(!mode.core)
		return FALSE
	mode.core.modify_max_integrity(mode.core.max_integrity + PVE_CORE_REINFORCE_AMOUNT)
	mode.core.repair_damage(PVE_CORE_REINFORCE_AMOUNT)
	mode.broadcast(span_notice("[user.real_name] укрепляет Маяк."))
	return TRUE

/datum/pve_product/support/artillery
	title = "Артиллерийский удар"
	description = "Накрывает всех тварей на поле. Боссы получают лишь четверть урона. Раз в волну."
	price = 1200
	once_per_wave = TRUE

/datum/pve_product/support/artillery/get_error(datum/game_mode/pve/mode, datum/pve_account/account)
	if(!mode.wave_active)
		return "волна ещё не началась"
	return ..()

/datum/pve_product/support/artillery/deliver(mob/living/user, datum/game_mode/pve/mode)
	mode.broadcast(span_boldannounceic("[user.real_name] вызывает артиллерийский удар!"), 'sound/effects/explosion_distant.ogg')
	for(var/mob/living/simple_animal/hostile/pve/enemy as anything in mode.active_enemies)
		if(enemy.stat == DEAD || istype(get_area(enemy), /area/pve/base))
			continue
		new /obj/effect/temp_visual/explosion(get_turf(enemy), 1, null, TRUE)
		enemy.last_hitter = WEAKREF(user.mind)
		var/damage = PVE_ARTILLERY_DAMAGE
		if(istype(enemy, /mob/living/simple_animal/hostile/pve/boss))
			damage *= PVE_ARTILLERY_BOSS_FACTOR
		enemy.apply_damage(damage, BRUTE)
	return TRUE

/datum/pve_product/support/supply_drop
	title = "Сброс снабжения"
	description = "Капсула с припасами упадёт где-то на поле. Успейте забрать."
	price = 350

/datum/pve_product/support/supply_drop/deliver(mob/living/user, datum/game_mode/pve/mode)
	return mode.launch_supply_drop()

/datum/pve_product/support/rally
	title = "Сбор павших"
	description = "Немедленно возвращает в строй всех погибших. Раз в волну."
	price = 800
	once_per_wave = TRUE

/datum/pve_product/support/rally/deliver(mob/living/user, datum/game_mode/pve/mode)
	if(!mode.respawn_dead())
		return FALSE
	mode.broadcast(span_boldannounceic("[user.real_name] возвращает павших в строй!"), 'sound/misc/notice2.ogg')
	return TRUE

/obj/machinery/computer/pve_shop
	name = "supply terminal"
	desc = "Терминал снабжения защитников. Принимает кредиты, заработанные в бою."
	use_power = NO_POWER_USE
	resistance_flags = INDESTRUCTIBLE
	icon_screen = "supply"
	var/terminal_title = "Снабжение"
	var/list/categories = list()

/obj/machinery/computer/pve_shop/get_ru_names()
	return alist(
		NOMINATIVE = "терминал снабжения",
		GENITIVE = "терминала снабжения",
		DATIVE = "терминалу снабжения",
		ACCUSATIVE = "терминал снабжения",
		INSTRUMENTAL = "терминалом снабжения",
		PREPOSITIONAL = "терминале снабжения",
	)

/obj/machinery/computer/pve_shop/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_pve_friendly_projectile(mover))
		return TRUE

/obj/machinery/computer/pve_shop/attack_hand(mob/user)
	if(..())
		return TRUE
	ui_interact(user)
	return TRUE

/obj/machinery/computer/pve_shop/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PveShop", terminal_title)
		ui.open()

/obj/machinery/computer/pve_shop/ui_static_data(mob/user)
	var/list/data = list()
	var/datum/game_mode/pve/mode = get_pve_mode()
	if(!mode)
		return data
	var/list/product_entries = list()
	for(var/product_id in mode.products)
		var/datum/pve_product/product = mode.products[product_id]
		if(product.category in categories)
			product_entries += list(product.ui_entry())
	var/list/class_entries = list()
	for(var/class_id in mode.classes)
		var/datum/pve_class/player_class = mode.classes[class_id]
		class_entries += list(list(
			"id" = player_class.id,
			"title" = player_class.title,
			"description" = player_class.description,
		))
	data["products"] = product_entries
	data["categories"] = categories
	data["classes"] = class_entries
	data["final_wave"] = PVE_FINAL_WAVE
	return data

/obj/machinery/computer/pve_shop/ui_data(mob/user)
	var/list/data = list("available" = FALSE)
	var/datum/game_mode/pve/mode = get_pve_mode()
	var/datum/pve_account/account = mode?.get_account(user)
	if(!account || mode.arena_z != z)
		return data
	var/datum/pve_class/player_class = mode.classes[account.class_id]
	var/list/discounts = list()
	for(var/category in categories)
		discounts[category] = player_class ? player_class.get_price_multiplier(category) : 1
	var/list/sold_out = list()
	for(var/product_id in mode.products)
		var/datum/pve_product/product = mode.products[product_id]
		if(!(product.category in categories))
			continue
		var/error = product.get_error(mode, account)
		if(error)
			sold_out[product_id] = error
	var/list/team = list()
	for(var/account_key in mode.player_accounts)
		var/datum/pve_account/teammate = mode.player_accounts[account_key]
		var/datum/pve_class/teammate_class = mode.classes[teammate.class_id]
		var/mob/living/teammate_body = teammate.get_body()
		team += list(list(
			"key" = account_key,
			"name" = teammate.player_name,
			"class" = teammate_class?.title || "без класса",
			"alive" = teammate_body?.stat != DEAD && teammate_body?.z == mode.arena_z,
			"credits" = teammate.credits,
			"kills" = teammate.kills,
			"ready" = teammate.ready,
			"self" = teammate == account,
		))
	data["available"] = TRUE
	data["finished"] = mode.finished
	data["credits"] = account.credits
	data["kills"] = account.kills
	data["class_id"] = account.class_id
	data["class_title"] = player_class?.title
	data["ready"] = account.ready
	data["wave"] = mode.wave
	data["active"] = mode.wave_active
	data["enemies"] = mode.enemies_remaining()
	data["seconds"] = max(0, round((mode.next_wave_time - world.time) / (1 SECONDS)))
	data["mutator"] = mode.current_mutator_title()
	data["core"] = mode.core ? round(mode.core.obj_integrity / mode.core.max_integrity * 100) : 0
	data["discounts"] = discounts
	data["unavailable"] = sold_out
	data["team"] = team
	return data

/obj/machinery/computer/pve_shop/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	var/datum/game_mode/pve/mode = get_pve_mode()
	var/datum/pve_account/account = mode?.get_account(user)
	if(!account || mode.finished)
		return
	switch(action)
		if("buy")
			return purchase(user, params["id"])
		if("ready")
			mode.toggle_ready(account)
			return TRUE
		if("choose_class")
			mode.choose_class(account, params["class"])
			return TRUE
		if("transfer")
			return mode.transfer_credits(account, params["key"], text2num(params["amount"]))

/obj/machinery/computer/pve_shop/proc/purchase(mob/living/user, product_id)
	var/datum/game_mode/pve/mode = get_pve_mode()
	if(!mode || mode.finished || mode.arena_z != z)
		return FALSE
	if(!istype(user) || user.stat != CONSCIOUS || user.incapacitated() || !Adjacent(user))
		return FALSE
	var/datum/pve_account/account = mode.get_account(user)
	var/datum/pve_product/product = mode.products[product_id]
	if(!account || !product || !(product.category in categories))
		return FALSE
	var/error = product.get_error(mode, account)
	if(error)
		balloon_alert(user, error)
		return FALSE
	var/price = product.get_price(mode.classes[account.class_id])
	if(account.credits < price)
		balloon_alert(user, "недостаточно кредитов")
		return FALSE
	if(!product.deliver(user, mode))
		balloon_alert(user, "сейчас недоступно")
		return FALSE
	account.credits -= price
	product.sold++
	product.last_wave_bought = mode.wave
	playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
	balloon_alert(user, "куплено")
	return TRUE

/obj/machinery/computer/pve_shop/armory
	name = "armory terminal"
	terminal_title = "Оружейная"
	icon_screen = "security"
	categories = list(PVE_CATEGORY_WEAPONS, PVE_CATEGORY_AMMO, PVE_CATEGORY_ARMOR)

/obj/machinery/computer/pve_shop/armory/get_ru_names()
	return alist(
		NOMINATIVE = "терминал оружейной",
		GENITIVE = "терминала оружейной",
		DATIVE = "терминалу оружейной",
		ACCUSATIVE = "терминал оружейной",
		INSTRUMENTAL = "терминалом оружейной",
		PREPOSITIONAL = "терминале оружейной",
	)

/obj/machinery/computer/pve_shop/medical
	name = "medbay terminal"
	terminal_title = "Медбей"
	icon_screen = "medcomp"
	categories = list(PVE_CATEGORY_MEDICINE)

/obj/machinery/computer/pve_shop/medical/get_ru_names()
	return alist(
		NOMINATIVE = "терминал медбея",
		GENITIVE = "терминала медбея",
		DATIVE = "терминалу медбея",
		ACCUSATIVE = "терминал медбея",
		INSTRUMENTAL = "терминалом медбея",
		PREPOSITIONAL = "терминале медбея",
	)

/obj/machinery/computer/pve_shop/engineering
	name = "engineering terminal"
	terminal_title = "Инженерная"
	icon_screen = "power"
	categories = list(PVE_CATEGORY_STRUCTURES)

/obj/machinery/computer/pve_shop/engineering/get_ru_names()
	return alist(
		NOMINATIVE = "терминал инженерной",
		GENITIVE = "терминала инженерной",
		DATIVE = "терминалу инженерной",
		ACCUSATIVE = "терминал инженерной",
		INSTRUMENTAL = "терминалом инженерной",
		PREPOSITIONAL = "терминале инженерной",
	)

/obj/machinery/computer/pve_shop/command
	name = "command terminal"
	terminal_title = "Штаб"
	icon_screen = "comm"
	categories = list(PVE_CATEGORY_SUPPORT)

/obj/machinery/computer/pve_shop/command/get_ru_names()
	return alist(
		NOMINATIVE = "терминал штаба",
		GENITIVE = "терминала штаба",
		DATIVE = "терминалу штаба",
		ACCUSATIVE = "терминал штаба",
		INSTRUMENTAL = "терминалом штаба",
		PREPOSITIONAL = "терминале штаба",
	)

#undef PVE_CORE_REPAIR_AMOUNT
#undef PVE_CORE_REINFORCE_AMOUNT
#undef PVE_ARTILLERY_DAMAGE
#undef PVE_ARTILLERY_BOSS_FACTOR
