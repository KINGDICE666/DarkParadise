GLOBAL_LIST_EMPTY(ship_guns)

/obj/machinery/ship_gun
	name = "ship gun"
	desc = "Корабельное орудие. Управляется со штурвала или с консоли наводчика."
	icon = 'icons/obj/machines/turrets.dmi'
	icon_state = "gun_turret"
	anchored = TRUE
	density = TRUE
	max_integrity = 300
	idle_power_usage = 200
	resistance_flags = FIRE_PROOF
	var/projectile_type = /obj/projectile/bullet/ship_autocannon
	var/fire_sound = 'sound/weapons/gunshots/gunshot_mg.ogg'
	var/fire_delay = 2 SECONDS
	var/burst = 1
	var/burst_delay = 0
	var/arc = 90
	var/power_per_shot = 0
	var/ammo_type
	var/ammo = 0
	var/max_ammo = 0
	var/ammo_per_shot = 1
	var/point_defense = FALSE
	var/board_path
	var/weapon_kind = "autocannon"
	var/loader_id

/obj/machinery/ship_gun/Initialize(mapload)
	. = ..()
	if(board_path)
		component_parts = list(new board_path(src))
		var/obj/item/circuitboard/board = component_parts[1]
		for(var/part_type, count in board.req_components)
			if(ispath(part_type, /obj/item/stack))
				component_parts += new part_type(src, count)
			else
				for(var/index in 1 to count)
					component_parts += new part_type(src)
	if(mapload && max_ammo)
		ammo = max_ammo
	AddComponent(/datum/component/ship_weapon, arc = arc, automatic = FALSE)
	GLOB.ship_guns += src
	if(point_defense)
		START_PROCESSING(SSmachines, src)

/obj/machinery/ship_gun/Destroy()
	GLOB.ship_guns -= src
	return ..()

/obj/machinery/ship_gun/multitool_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(!max_ammo)
		balloon_alert(user, "нечего заряжать")
		return
	var/new_id = tgui_input_text(user, "ID зарядника, от которого орудие будет получать боезапас", "Привязка к заряднику", loader_id, max_length = MAX_NAME_LEN)
	if(isnull(new_id) || QDELETED(src) || !user.Adjacent(src))
		return
	loader_id = new_id || null
	balloon_alert(user, loader_id ? "привязано" : "привязка снята")

/obj/machinery/ship_gun/shuttleRotate(rotation, params)
	. = ..()
	SEND_SIGNAL(src, COMSIG_OVERMAP_WEAPON_ROTATED, rotation)

/obj/machinery/ship_gun/examine(mob/user)
	. = ..()
	if(max_ammo)
		. += span_notice("Боезапас: [ammo]/[max_ammo].")
		. += span_notice(loader_id ? "Привязано к заряднику «[loader_id]»." : "Мультитулом можно привязать к заряднику по ID.")
	if(power_per_shot)
		. += span_notice("Питается от APC отсека: [power_per_shot] Дж на выстрел.")

/obj/machinery/ship_gun/proc/can_fire()
	if(stat & (BROKEN|NOPOWER) || !anchored || panel_open)
		return FALSE
	if(max_ammo && ammo < ammo_per_shot)
		return FALSE
	return TRUE

/obj/machinery/ship_gun/proc/make_shot()
	if(!can_fire())
		playsound(src, 'sound/weapons/empty.ogg', 40, TRUE)
		return null
	if(max_ammo)
		ammo -= ammo_per_shot
	if(power_per_shot)
		use_power(power_per_shot)
	playsound(src, fire_sound, 60, TRUE, extrarange = 6)
	return new projectile_type(null)

/obj/machinery/ship_gun/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	if(!ammo_type || !istype(used, ammo_type))
		return ..()
	var/obj/item/ship_ammo/pack = used
	if(ammo >= max_ammo)
		balloon_alert(user, "заряжено полностью")
		return ITEM_INTERACT_BLOCKING
	if(!do_after(user, pack.load_time, src))
		return ITEM_INTERACT_BLOCKING
	if(QDELETED(pack) || ammo >= max_ammo)
		return ITEM_INTERACT_BLOCKING
	ammo = min(ammo + pack.rounds, max_ammo)
	playsound(src, 'sound/weapons/gun_interactions/rifle_load.ogg', 50, TRUE)
	balloon_alert(user, "заряжено")
	qdel(pack)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/ship_gun/wrench_act(mob/living/user, obj/item/tool)
	. = TRUE
	default_unfasten_wrench(user, tool)

/obj/machinery/ship_gun/screwdriver_act(mob/living/user, obj/item/tool)
	if(anchored)
		return default_deconstruction_screwdriver(user, icon_state, icon_state, tool)
	if(tool.use_tool(src, user, volume = tool.tool_volume))
		setDir(turn(dir, -90))
		SEND_SIGNAL(src, COMSIG_OVERMAP_WEAPON_ROTATED, 0, dir)
	return TRUE

/obj/machinery/ship_gun/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/ship_gun/process()
	if(!point_defense || !can_fire())
		return
	var/datum/component/ship_weapon/weapon = GetComponent(/datum/component/ship_weapon)
	var/obj/overmap/entity/vessel = weapon?.host()
	if(!weapon?.automatic || !vessel?.sector)
		return
	var/list/point = weapon.world_position(vessel)
	if(!point)
		return
	for(var/datum/overmap_projectile/threat as anything in SSovermap.sector_projectiles)
		var/obj/projectile/bullet/ship_artillery/torpedo/payload = threat.payload
		if(!istype(payload) || threat.sector != vessel.sector || vessel.friendly_vessel(payload.overmap_firer_vessel))
			continue
		if((threat.world_x - point[1]) ** 2 + (threat.world_y - point[2]) ** 2 > OVERMAP_PD_RANGE ** 2)
			continue
		ammo = max(ammo - OVERMAP_PD_AMMO, 0)
		playsound(src, fire_sound, 50, TRUE, extrarange = 4)
		if(prob(OVERMAP_PD_CHANCE))
			SSovermap.show_sector_explosion(threat.sector, threat.world_x, threat.world_y)
			qdel(threat)
		return

/obj/overmap/entity/proc/friendly_vessel(obj/overmap/entity/other)
	return other && (other == src || other == docked_to || other == docked_ship || other.docked_to == src || other.docked_ship == src)

/obj/machinery/ship_gun/autocannon
	name = "ship autocannon"
	desc = "Скорострельная кинетическая пушка. В автоматическом режиме сбивает торпеды, подлетающие к кораблю."
	burst = 3
	burst_delay = 0.15 SECONDS
	fire_delay = 1.5 SECONDS
	arc = 120
	ammo_type = /obj/item/ship_ammo/autocannon
	max_ammo = 90
	point_defense = TRUE
	board_path = /obj/item/circuitboard/ship_gun/autocannon

/obj/machinery/ship_gun/autocannon/get_ru_names()
	return alist(
		NOMINATIVE = "корабельная автопушка",
		GENITIVE = "корабельной автопушки",
		DATIVE = "корабельной автопушке",
		ACCUSATIVE = "корабельную автопушку",
		INSTRUMENTAL = "корабельной автопушкой",
		PREPOSITIONAL = "корабельной автопушке",
	)

/obj/machinery/ship_gun/laser
	name = "ship laser"
	desc = "Энергетическое орудие без боезапаса. Тянет энергию из APC отсека и хорошо пробивает щиты."
	icon_state = "orange_target_prism"
	projectile_type = /obj/projectile/beam/ship_laser
	fire_sound = 'sound/overmap/laser_cannon_fire.ogg'
	fire_delay = 2.5 SECONDS
	arc = 90
	power_per_shot = 15000
	board_path = /obj/item/circuitboard/ship_gun/laser
	weapon_kind = "laser"

/obj/machinery/ship_gun/laser/get_ru_names()
	return alist(
		NOMINATIVE = "корабельный лазер",
		GENITIVE = "корабельного лазера",
		DATIVE = "корабельному лазеру",
		ACCUSATIVE = "корабельный лазер",
		INSTRUMENTAL = "корабельным лазером",
		PREPOSITIONAL = "корабельном лазере",
	)

/obj/machinery/ship_gun/railgun
	name = "ship railgun"
	desc = "Электромагнитное орудие. Болванка прошивает несколько переборок и почти не замечает щитов, но перезаряжается долго."
	icon = 'icons/obj/engines_and_power/singularity.dmi'
	icon_state = "emitter"
	color = "#9fd0ff"
	projectile_type = /obj/projectile/bullet/ship_railgun
	fire_sound = 'sound/overmap/railgun_fire.ogg'
	fire_delay = 8 SECONDS
	arc = 30
	power_per_shot = 40000
	ammo_type = /obj/item/ship_ammo/railgun
	max_ammo = 6
	board_path = /obj/item/circuitboard/ship_gun/railgun
	weapon_kind = "railgun"

/obj/machinery/ship_gun/railgun/Initialize(mapload)
	. = ..()
	var/matrix/flipped = matrix()
	flipped.Turn(180)
	transform = flipped

/obj/machinery/ship_gun/railgun/get_ru_names()
	return alist(
		NOMINATIVE = "корабельный рельсотрон",
		GENITIVE = "корабельного рельсотрона",
		DATIVE = "корабельному рельсотрону",
		ACCUSATIVE = "корабельный рельсотрон",
		INSTRUMENTAL = "корабельным рельсотроном",
		PREPOSITIONAL = "корабельном рельсотроне",
	)

/obj/machinery/ship_gun/torpedo
	name = "torpedo launcher"
	desc = "Пусковая труба для корабельных торпед. Торпеда летит медленно и может быть сбита, зато взрыв проламывает корпус."
	icon = 'icons/obj/engines_and_power/singularity.dmi'
	icon_state = "emitter"
	color = "#ff9a66"
	projectile_type = /obj/projectile/bullet/ship_artillery/torpedo
	fire_sound = 'sound/weapons/rocketlaunch.ogg'
	fire_delay = 6 SECONDS
	arc = 60
	ammo_type = /obj/item/ship_ammo/torpedo
	max_ammo = 2
	board_path = /obj/item/circuitboard/ship_gun/torpedo
	weapon_kind = "torpedo"

/obj/machinery/ship_gun/torpedo/get_ru_names()
	return alist(
		NOMINATIVE = "торпедный аппарат",
		GENITIVE = "торпедного аппарата",
		DATIVE = "торпедному аппарату",
		ACCUSATIVE = "торпедный аппарат",
		INSTRUMENTAL = "торпедным аппаратом",
		PREPOSITIONAL = "торпедном аппарате",
	)

/obj/projectile/bullet/ship_autocannon
	name = "autocannon shell"
	damage = 30
	armour_penetration = 20
	overmap_velocity = 70
	overmap_radar_visible = TRUE

/obj/projectile/beam/ship_laser
	name = "ship laser"
	icon_state = "heavylaser"
	damage = 45
	armour_penetration = 10
	overmap_velocity = 120
	overmap_radar_visible = TRUE
	ship_shield_factor = 1.5

/obj/projectile/bullet/ship_railgun
	name = "railgun slug"
	icon_state = "gauss"
	damage = 90
	armour_penetration = 60
	overmap_velocity = 160
	overmap_radar_visible = TRUE
	ship_penetrations = 4
	ship_penetration_chance = 100
	ship_penetration_decay = 0.8
	ship_shield_factor = 0.5
	ship_shield_pierce = TRUE

/obj/projectile/bullet/ship_artillery/torpedo
	name = "ship torpedo"
	icon_state = "84mm-he"
	damage = 150
	overmap_velocity = 25
	ship_penetrations = 0

/obj/projectile/bullet/ship_artillery/torpedo/detonate(turf/spot)
	if(detonated || !spot)
		return
	detonated = TRUE
	explosion(spot, devastation_range = 1, heavy_impact_range = 3, light_impact_range = 5, flash_range = 4, adminlog = TRUE, cause = "ship torpedo")
	qdel(src)

/obj/item/ship_ammo
	name = "ship ammunition"
	desc = "Боеприпасы для корабельного орудия."
	icon = 'icons/obj/weapons/ammo.dmi'
	icon_state = "ammobox_338"
	w_class = WEIGHT_CLASS_BULKY
	var/rounds = 1
	var/load_time = 2 SECONDS

/obj/item/ship_ammo/autocannon
	name = "autocannon ammo box"
	desc = "Короб с лентой снарядов для корабельной автопушки."
	rounds = 30

/obj/item/ship_ammo/autocannon/get_ru_names()
	return alist(
		NOMINATIVE = "короб снарядов автопушки",
		GENITIVE = "короба снарядов автопушки",
		DATIVE = "коробу снарядов автопушки",
		ACCUSATIVE = "короб снарядов автопушки",
		INSTRUMENTAL = "коробом снарядов автопушки",
		PREPOSITIONAL = "коробе снарядов автопушки",
	)

/obj/item/ship_ammo/railgun
	name = "railgun slugs"
	desc = "Кассета вольфрамовых болванок для рельсотрона."
	icon_state = "box_12.7"
	rounds = 3

/obj/item/ship_ammo/railgun/get_ru_names()
	return alist(
		NOMINATIVE = "кассета болванок рельсотрона",
		GENITIVE = "кассеты болванок рельсотрона",
		DATIVE = "кассете болванок рельсотрона",
		ACCUSATIVE = "кассету болванок рельсотрона",
		INSTRUMENTAL = "кассетой болванок рельсотрона",
		PREPOSITIONAL = "кассете болванок рельсотрона",
	)

/obj/item/ship_ammo/torpedo
	name = "ship torpedo"
	desc = "Корабельная торпеда. Тяжёлая — заряжать долго."
	icon_state = "84mm-he"
	w_class = WEIGHT_CLASS_HUGE
	load_time = 5 SECONDS

/obj/item/ship_ammo/torpedo/get_ru_names()
	return alist(
		NOMINATIVE = "корабельная торпеда",
		GENITIVE = "корабельной торпеды",
		DATIVE = "корабельной торпеде",
		ACCUSATIVE = "корабельную торпеду",
		INSTRUMENTAL = "корабельной торпедой",
		PREPOSITIONAL = "корабельной торпеде",
	)

/obj/item/circuitboard/ship_gun
	board_name = "Ship gun"
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_SECURITY

/obj/item/circuitboard/ship_gun/autocannon
	board_name = "Ship autocannon"
	build_path = /obj/machinery/ship_gun/autocannon
	req_components = list(/obj/item/stock_parts/manipulator = 2, /obj/item/stock_parts/matter_bin = 2, /obj/item/stack/sheet/plasteel = 5)

/obj/item/circuitboard/ship_gun/laser
	board_name = "Ship laser"
	build_path = /obj/machinery/ship_gun/laser
	req_components = list(/obj/item/stock_parts/micro_laser = 4, /obj/item/stock_parts/capacitor = 2, /obj/item/stack/cable_coil = 10)

/obj/item/circuitboard/ship_gun/railgun
	board_name = "Ship railgun"
	build_path = /obj/machinery/ship_gun/railgun
	req_components = list(/obj/item/stock_parts/capacitor = 4, /obj/item/stock_parts/manipulator = 2, /obj/item/stack/sheet/plasteel = 10)

/obj/item/circuitboard/ship_gun/torpedo
	board_name = "Torpedo launcher"
	build_path = /obj/machinery/ship_gun/torpedo
	req_components = list(/obj/item/stock_parts/manipulator = 2, /obj/item/stock_parts/matter_bin = 2, /obj/item/stack/sheet/plasteel = 10)

/datum/design/ship_gun_autocannon
	name = "Machine Board (Ship Autocannon)"
	desc = "Плата корабельной автопушки."
	id = "ship_gun_autocannon"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/ship_gun/autocannon
	materials = list(MAT_GLASS = 1000)
	req_tech = list(RESEARCH_TREE_COMBAT = 3, RESEARCH_TREE_ENGINEERING = 3)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_ENGINEERING)

/datum/design/ship_gun_autocannon/laser
	name = "Machine Board (Ship Laser)"
	desc = "Плата корабельного лазера."
	id = "ship_gun_laser"
	build_path = /obj/item/circuitboard/ship_gun/laser
	req_tech = list(RESEARCH_TREE_COMBAT = 4, RESEARCH_TREE_MAGNETS = 4)

/datum/design/ship_gun_autocannon/railgun
	name = "Machine Board (Ship Railgun)"
	desc = "Плата корабельного рельсотрона."
	id = "ship_gun_railgun"
	build_path = /obj/item/circuitboard/ship_gun/railgun
	req_tech = list(RESEARCH_TREE_COMBAT = 5, RESEARCH_TREE_MAGNETS = 5)

/datum/design/ship_gun_autocannon/torpedo
	name = "Machine Board (Torpedo Launcher)"
	desc = "Плата торпедного аппарата."
	id = "ship_gun_torpedo"
	build_path = /obj/item/circuitboard/ship_gun/torpedo
	req_tech = list(RESEARCH_TREE_COMBAT = 5, RESEARCH_TREE_ENGINEERING = 4)

/datum/design/ship_ammo_autocannon
	name = "Autocannon Ammo Box"
	desc = "Короб снарядов для корабельной автопушки."
	id = "ship_ammo_autocannon"
	build_type = PROTOLATHE
	build_path = /obj/item/ship_ammo/autocannon
	materials = list(MAT_METAL = 6000)
	req_tech = list(RESEARCH_TREE_COMBAT = 3)
	category = list(PROTOLATHE_CATEGORY_WEAPON)

/datum/design/ship_ammo_autocannon/railgun
	name = "Railgun Slugs"
	desc = "Кассета болванок для рельсотрона."
	id = "ship_ammo_railgun"
	build_path = /obj/item/ship_ammo/railgun
	materials = list(MAT_METAL = 4000, MAT_TITANIUM = 3000)
	req_tech = list(RESEARCH_TREE_COMBAT = 5)

/datum/design/ship_ammo_autocannon/torpedo
	name = "Ship Torpedo"
	desc = "Корабельная торпеда."
	id = "ship_ammo_torpedo"
	build_path = /obj/item/ship_ammo/torpedo
	materials = list(MAT_METAL = 8000, MAT_PLASMA = 4000)
	req_tech = list(RESEARCH_TREE_COMBAT = 5, RESEARCH_TREE_MATERIALS = 4)
