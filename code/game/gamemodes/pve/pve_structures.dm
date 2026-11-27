#define PVE_CORE_ALERT_COOLDOWN (20 SECONDS)
#define PVE_REPAIR_AMOUNT 60
#define PVE_REPAIR_TIME (3 SECONDS)
#define PVE_ENGINEER_REPAIR_TIME (1 SECONDS)
#define PVE_MED_STATION_RANGE 2
#define PVE_MED_STATION_HEAL 3
#define PVE_MINE_DAMAGE 70
#define PVE_FLAMER_FUEL_PER_TILE 0.15
#define PVE_FLAMER_DAMAGE 6
#define PVE_FLAMER_BURN_DAMAGE 3
#define PVE_FLAMER_BURN_DURATION (4 SECONDS)
#define PVE_CORE_PULSE_COOLDOWN (3 SECONDS)
#define PVE_CORE_PULSE_BASE_RANGE 3
#define PVE_CORE_PULSE_DAMAGE 15
#define PVE_SPIKES_DAMAGE 14
#define PVE_SPIKES_WEAR 8
#define PVE_TESLA_COOLDOWN (2 SECONDS)
#define PVE_TESLA_RANGE 6
#define PVE_TESLA_DAMAGE 25

/proc/get_pve_mode()
	var/datum/game_mode/pve/mode = SSticker.mode
	return istype(mode) ? mode : null

/proc/is_pve_friendly_projectile(atom/movable/mover)
	if(!isprojectile(mover))
		return FALSE
	var/obj/projectile/proj = mover
	return !IS_PVE_ENEMY(proj.firer)

/proc/pve_repair_time(mob/user)
	var/datum/game_mode/pve/mode = get_pve_mode()
	var/datum/pve_class/user_class = mode?.get_player_class(user)
	return user_class?.id == PVE_CLASS_ENGINEER ? PVE_ENGINEER_REPAIR_TIME : PVE_REPAIR_TIME

/obj/structure/pve_core
	name = "beacon"
	desc = "Маяк держит красный туман на расстоянии от лагеря. Если он погаснет — оборона падёт. Его можно чинить сваркой."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "nexus-blue"
	anchored = TRUE
	density = TRUE
	max_integrity = 1500
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	light_range = 5
	light_power = 1.5
	light_color = "#7fd4ff"
	var/pulse_level = 0
	var/shield_until = 0
	COOLDOWN_DECLARE(alert_cooldown)
	COOLDOWN_DECLARE(pulse_cooldown)

/obj/structure/pve_core/get_ru_names()
	return alist(
		NOMINATIVE = "Маяк",
		GENITIVE = "Маяка",
		DATIVE = "Маяку",
		ACCUSATIVE = "Маяк",
		INSTRUMENTAL = "Маяком",
		PREPOSITIONAL = "Маяке",
	)

/obj/structure/pve_core/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/pve_core/examine(mob/user)
	. = ..()
	. += span_notice("Целостность: [round(obj_integrity / max_integrity * 100)]%.")
	if(pulse_level)
		. += span_notice("Пульс Маяка: уровень [pulse_level].")
	if(world.time < shield_until)
		. += span_notice("Маяк укрыт энергетическим щитом.")

/obj/structure/pve_core/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(world.time < shield_until)
		return
	return ..()

/obj/structure/pve_core/proc/raise_shield(duration)
	shield_until = world.time + duration
	add_filter("pve_shield", 2, outline_filter(2, "#7fd4ff"))
	playsound(src, 'sound/magic/charge.ogg', 70, TRUE)
	addtimer(CALLBACK(src, PROC_REF(drop_shield)), duration, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/structure/pve_core/proc/drop_shield()
	remove_filter("pve_shield")

/obj/structure/pve_core/proc/upgrade_pulse()
	pulse_level++
	START_PROCESSING(SSobj, src)

/obj/structure/pve_core/process(seconds_per_tick)
	if(!pulse_level || !COOLDOWN_FINISHED(src, pulse_cooldown))
		return
	COOLDOWN_START(src, pulse_cooldown, PVE_CORE_PULSE_COOLDOWN)
	var/zapped = FALSE
	for(var/mob/living/simple_animal/hostile/pve/enemy in range(PVE_CORE_PULSE_BASE_RANGE + pulse_level, src))
		if(enemy.stat == DEAD)
			continue
		Beam(enemy, icon_state = "lightning[rand(1, 12)]", icon = 'icons/effects/effects.dmi', time = 0.5 SECONDS)
		enemy.apply_damage(PVE_CORE_PULSE_DAMAGE * pulse_level, BURN)
		zapped = TRUE
	if(zapped)
		playsound(src, 'sound/magic/lightningbolt.ogg', 40, TRUE)

/obj/structure/pve_core/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_pve_friendly_projectile(mover))
		return TRUE

/obj/structure/pve_core/proceed_attack_results(obj/item/item, mob/living/user, list/modifiers)
	if(IS_PVE_ENEMY(user))
		return ..()
	balloon_alert(user, "это наш Маяк!")
	return ATTACK_CHAIN_PROCEED

/obj/structure/pve_core/ex_act(severity, target)
	return

/obj/structure/pve_core/welder_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(obj_integrity >= max_integrity)
		balloon_alert(user, "ремонт не нужен")
		return
	if(!tool.tool_use_check(user, 0))
		return
	WELDER_ATTEMPT_REPAIR_MESSAGE
	if(!tool.use_tool(src, user, pve_repair_time(user), volume = tool.tool_volume))
		return
	WELDER_REPAIR_SUCCESS_MESSAGE
	repair_damage(PVE_REPAIR_AMOUNT)

/obj/structure/pve_core/on_update_integrity(old_value, new_value)
	. = ..()
	if(new_value >= old_value)
		return
	var/datum/game_mode/pve/mode = get_pve_mode()
	mode?.on_core_damaged(old_value - new_value)
	if(!COOLDOWN_FINISHED(src, alert_cooldown))
		return
	COOLDOWN_START(src, alert_cooldown, PVE_CORE_ALERT_COOLDOWN)
	mode?.broadcast(span_userdanger("Маяк атакован! Целостность: [round(new_value / max_integrity * 100)]%."), 'sound/misc/notice1.ogg')

/obj/structure/pve_core/obj_destruction(damage_flag)
	var/datum/game_mode/pve/mode = get_pve_mode()
	mode?.on_core_destroyed(src)
	return ..()

/obj/item/pve_deployable
	name = "deployable kit"
	desc = "Складной комплект. Используйте в руке, чтобы развернуть на месте."
	w_class = WEIGHT_CLASS_BULKY
	var/deploy_type
	var/deploy_time = 3 SECONDS
	var/deploying = FALSE

/obj/item/pve_deployable/Initialize(mapload)
	. = ..()
	var/atom/preview = deploy_type
	icon = initial(preview.icon)
	icon_state = initial(preview.icon_state)

/obj/item/pve_deployable/attack_self(mob/user)
	var/datum/game_mode/pve/mode = get_pve_mode()
	var/turf/deployment_turf = get_turf(user)
	if(!mode || user.z != mode.arena_z || deploying || loc != user)
		return
	if(!can_deploy_on(deployment_turf))
		balloon_alert(user, "нужно свободное место")
		return
	var/datum/pve_class/user_class = mode.get_player_class(user)
	if(user_class?.id != PVE_CLASS_ENGINEER)
		deploying = TRUE
		var/success = do_after(user, deploy_time, target = src)
		deploying = FALSE
		if(!success || loc != user || get_turf(user) != deployment_turf || !can_deploy_on(deployment_turf))
			return
	var/atom/deployed = new deploy_type(deployment_turf)
	on_deployed(deployed, user)
	playsound(deployment_turf, 'sound/items/deconstruct.ogg', 50, TRUE)
	qdel(src)

/obj/item/pve_deployable/proc/can_deploy_on(turf/deployment_turf)
	return !deployment_turf.is_blocked_turf(exclude_mobs = TRUE)

/obj/item/pve_deployable/proc/on_deployed(atom/deployed, mob/user)
	return

/obj/item/pve_deployable/barricade
	name = "barricade kit"
	desc = "Доски и гвозди для деревянной баррикады. Через неё можно стрелять, а враги вынуждены её ломать."
	deploy_type = /obj/structure/barricade/wooden
	deploy_time = 2 SECONDS

/obj/item/pve_deployable/barricade/get_ru_names()
	return alist(
		NOMINATIVE = "комплект баррикады",
		GENITIVE = "комплекта баррикады",
		DATIVE = "комплекту баррикады",
		ACCUSATIVE = "комплект баррикады",
		INSTRUMENTAL = "комплектом баррикады",
		PREPOSITIONAL = "комплекте баррикады",
	)

/obj/item/pve_deployable/sandbags
	name = "sandbag kit"
	desc = "Мешки с песком. Прочное укрытие, на которое можно забраться."
	deploy_type = /obj/structure/barricade/sandbags

/obj/item/pve_deployable/sandbags/get_ru_names()
	return alist(
		NOMINATIVE = "комплект мешков с песком",
		GENITIVE = "комплекта мешков с песком",
		DATIVE = "комплекту мешков с песком",
		ACCUSATIVE = "комплект мешков с песком",
		INSTRUMENTAL = "комплектом мешков с песком",
		PREPOSITIONAL = "комплекте мешков с песком",
	)

/obj/item/pve_deployable/turret
	name = "turret kit"
	desc = "Автономная турель. Стреляет только по тварям, пули проходят сквозь союзников. Убийства турели засчитываются её владельцу."
	deploy_type = /obj/machinery/porta_turret/syndicate/pve

/obj/item/pve_deployable/turret/get_ru_names()
	return alist(
		NOMINATIVE = "комплект турели",
		GENITIVE = "комплекта турели",
		DATIVE = "комплекту турели",
		ACCUSATIVE = "комплект турели",
		INSTRUMENTAL = "комплектом турели",
		PREPOSITIONAL = "комплекте турели",
	)

/obj/item/pve_deployable/turret/on_deployed(atom/deployed, mob/user)
	var/obj/machinery/porta_turret/syndicate/pve/turret = deployed
	turret.owner_mind = WEAKREF(user.mind)

/obj/item/pve_deployable/turret/heavy
	name = "heavy turret kit"
	desc = "Тяжёлая турель: вдвое прочнее и бьёт сильнее обычной."
	deploy_type = /obj/machinery/porta_turret/syndicate/pve/heavy

/obj/item/pve_deployable/turret/heavy/get_ru_names()
	return alist(
		NOMINATIVE = "комплект тяжёлой турели",
		GENITIVE = "комплекта тяжёлой турели",
		DATIVE = "комплекту тяжёлой турели",
		ACCUSATIVE = "комплект тяжёлой турели",
		INSTRUMENTAL = "комплектом тяжёлой турели",
		PREPOSITIONAL = "комплекте тяжёлой турели",
	)

/obj/item/pve_deployable/med_station
	name = "med station kit"
	desc = "Полевая медстанция. Постепенно лечит всех союзников рядом с собой."
	deploy_type = /obj/structure/pve_med_station

/obj/item/pve_deployable/med_station/get_ru_names()
	return alist(
		NOMINATIVE = "комплект медстанции",
		GENITIVE = "комплекта медстанции",
		DATIVE = "комплекту медстанции",
		ACCUSATIVE = "комплект медстанции",
		INSTRUMENTAL = "комплектом медстанции",
		PREPOSITIONAL = "комплекте медстанции",
	)

/obj/item/pve_deployable/lamp
	name = "floodlight kit"
	desc = "Яркий прожектор. Незаменим, когда туман приносит ночь."
	deploy_type = /obj/structure/pve_lamp
	deploy_time = 1 SECONDS

/obj/item/pve_deployable/lamp/get_ru_names()
	return alist(
		NOMINATIVE = "комплект прожектора",
		GENITIVE = "комплекта прожектора",
		DATIVE = "комплекту прожектора",
		ACCUSATIVE = "комплект прожектора",
		INSTRUMENTAL = "комплектом прожектора",
		PREPOSITIONAL = "комплекте прожектора",
	)

/obj/item/pve_deployable/mine
	name = "fog mine"
	desc = "Мина, реагирующая только на тварей тумана. Взрыв задевает всех тварей рядом."
	deploy_type = /obj/effect/pve_mine
	deploy_time = 1 SECONDS
	w_class = WEIGHT_CLASS_SMALL

/obj/item/pve_deployable/mine/get_ru_names()
	return alist(
		NOMINATIVE = "мина тумана",
		GENITIVE = "мины тумана",
		DATIVE = "мине тумана",
		ACCUSATIVE = "мину тумана",
		INSTRUMENTAL = "миной тумана",
		PREPOSITIONAL = "мине тумана",
	)

/obj/item/pve_deployable/mine/can_deploy_on(turf/deployment_turf)
	return !(locate(/obj/effect/pve_mine) in deployment_turf) && ..()

/obj/item/pve_deployable/mine/on_deployed(atom/deployed, mob/user)
	var/obj/effect/pve_mine/mine = deployed
	mine.owner_mind = WEAKREF(user.mind)

/obj/item/pve_deployable/spikes
	name = "spike trap kit"
	desc = "Связка заострённых кольев. Вбитые в землю, ранят каждую тварь, что по ним пройдёт, и постепенно стачиваются."
	deploy_type = /obj/structure/pve_spikes
	deploy_time = 1 SECONDS
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/pve_deployable/spikes/get_ru_names()
	return alist(
		NOMINATIVE = "связка кольев",
		GENITIVE = "связки кольев",
		DATIVE = "связке кольев",
		ACCUSATIVE = "связку кольев",
		INSTRUMENTAL = "связкой кольев",
		PREPOSITIONAL = "связке кольев",
	)

/obj/item/pve_deployable/spikes/can_deploy_on(turf/deployment_turf)
	return !(locate(/obj/structure/pve_spikes) in deployment_turf) && ..()

/obj/item/pve_deployable/spikes/on_deployed(atom/deployed, mob/user)
	var/obj/structure/pve_spikes/spikes = deployed
	spikes.owner_mind = WEAKREF(user.mind)

/obj/item/pve_deployable/tesla
	name = "tesla coil kit"
	desc = "Разборная тесла-катушка. Бьёт молнией ближайшую тварь, убийства засчитываются владельцу."
	deploy_type = /obj/structure/pve_tesla_coil

/obj/item/pve_deployable/tesla/get_ru_names()
	return alist(
		NOMINATIVE = "комплект тесла-катушки",
		GENITIVE = "комплекта тесла-катушки",
		DATIVE = "комплекту тесла-катушки",
		ACCUSATIVE = "комплект тесла-катушки",
		INSTRUMENTAL = "комплектом тесла-катушки",
		PREPOSITIONAL = "комплекте тесла-катушки",
	)

/obj/item/pve_deployable/tesla/on_deployed(atom/deployed, mob/user)
	var/obj/structure/pve_tesla_coil/coil = deployed
	coil.owner_mind = WEAKREF(user.mind)

/obj/machinery/porta_turret/syndicate/pve
	name = "defense turret"
	desc = "Автономная турель защитников. Стреляет только по тварям тумана. Чинится сваркой."
	health = 150
	projectile = /obj/projectile/bullet/pve_turret
	eprojectile = /obj/projectile/bullet/pve_turret
	faction = PVE_FACTION_PLAYER
	req_access = list()
	controllock = TRUE
	shot_delay = 1 SECONDS
	scan_range = 8
	var/datum/weakref/owner_mind

/obj/machinery/porta_turret/syndicate/pve/get_ru_names()
	return alist(
		NOMINATIVE = "защитная турель",
		GENITIVE = "защитной турели",
		DATIVE = "защитной турели",
		ACCUSATIVE = "защитную турель",
		INSTRUMENTAL = "защитной турелью",
		PREPOSITIONAL = "защитной турели",
	)

/obj/machinery/porta_turret/syndicate/pve/Destroy()
	owner_mind = null
	return ..()

/obj/machinery/porta_turret/syndicate/pve/examine(mob/user)
	. = ..()
	. += span_notice("Прочность: [max(health, 0)]/[initial(health)].")

/obj/machinery/porta_turret/syndicate/pve/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_pve_friendly_projectile(mover))
		return TRUE

/obj/machinery/porta_turret/syndicate/pve/assess_living(mob/living/target)
	if(!IS_PVE_ENEMY(target) || target.stat == DEAD || get_dist(src, target) > scan_range)
		return TURRET_NOT_TARGET
	return TURRET_PRIORITY_TARGET

/obj/machinery/porta_turret/syndicate/pve/shoot(mob/living/target)
	var/obj/projectile/proj = new projectile(loc)
	playsound(loc, shot_sound, 75, TRUE)
	proj.firer_source_atom = src
	proj.preparePixelProjectile(target, loc)
	proj.fire()

/obj/machinery/porta_turret/syndicate/pve/die()
	. = ..()
	QDEL_IN(src, 5 SECONDS)

/obj/machinery/porta_turret/syndicate/pve/welder_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(stat & BROKEN)
		balloon_alert(user, "турель уничтожена")
		return
	if(health >= initial(health))
		balloon_alert(user, "ремонт не нужен")
		return
	if(!tool.tool_use_check(user, 0))
		return
	WELDER_ATTEMPT_REPAIR_MESSAGE
	if(!tool.use_tool(src, user, pve_repair_time(user), volume = tool.tool_volume))
		return
	WELDER_REPAIR_SUCCESS_MESSAGE
	health = min(initial(health), health + PVE_REPAIR_AMOUNT)

/obj/machinery/porta_turret/syndicate/pve/heavy
	name = "heavy defense turret"
	desc = "Тяжёлая турель защитников: прочная броня и мощные снаряды. Стреляет только по тварям тумана."
	health = 300
	projectile = /obj/projectile/bullet/pve_turret/heavy
	eprojectile = /obj/projectile/bullet/pve_turret/heavy
	shot_delay = 0.8 SECONDS
	scan_range = 9
	color = "#ffb080"

/obj/machinery/porta_turret/syndicate/pve/heavy/get_ru_names()
	return alist(
		NOMINATIVE = "тяжёлая турель",
		GENITIVE = "тяжёлой турели",
		DATIVE = "тяжёлой турели",
		ACCUSATIVE = "тяжёлую турель",
		INSTRUMENTAL = "тяжёлой турелью",
		PREPOSITIONAL = "тяжёлой турели",
	)

/obj/projectile/bullet/pve_turret
	damage = 20

/obj/projectile/bullet/pve_turret/prehit(atom/target)
	. = ..()
	nodamage = isliving(target) && !IS_PVE_ENEMY(target)
	forcedodge = nodamage

/obj/projectile/bullet/pve_turret/on_hit(atom/target, blocked = 0, hit_zone)
	if(isliving(target) && !IS_PVE_ENEMY(target))
		return -1
	return ..()

/obj/projectile/bullet/pve_turret/heavy
	damage = 35
	icon_state = "red_laser"

/obj/structure/pve_spikes
	name = "spike trap"
	desc = "Вбитые в землю заострённые колья. Ранят тварей, которые по ним проходят."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "trap-earth"
	anchored = TRUE
	layer = LOW_OBJ_LAYER
	max_integrity = 120
	var/datum/weakref/owner_mind

/obj/structure/pve_spikes/get_ru_names()
	return alist(
		NOMINATIVE = "колья",
		GENITIVE = "кольев",
		DATIVE = "кольям",
		ACCUSATIVE = "колья",
		INSTRUMENTAL = "кольями",
		PREPOSITIONAL = "кольях",
	)

/obj/structure/pve_spikes/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/pve_spikes/Destroy()
	owner_mind = null
	return ..()

/obj/structure/pve_spikes/examine(mob/user)
	. = ..()
	. += span_notice("Остриё сточено на [100 - round(obj_integrity / max_integrity * 100)]%.")

/obj/structure/pve_spikes/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!IS_PVE_ENEMY(arrived))
		return
	var/mob/living/simple_animal/hostile/pve/enemy = arrived
	if(enemy.stat == DEAD || enemy.mob_size <= MOB_SIZE_TINY)
		return
	if(owner_mind)
		enemy.last_hitter = owner_mind
		enemy.last_hit_melee = FALSE
	enemy.apply_damage(PVE_SPIKES_DAMAGE, BRUTE)
	playsound(src, 'sound/weapons/pierce.ogg', 30, TRUE)
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj, take_damage), PVE_SPIKES_WEAR, BRUTE, MELEE, FALSE)

/obj/structure/pve_tesla_coil
	name = "tesla coil"
	desc = "Катушка защитников. Бьёт молнией ближайшую тварь тумана. Чинится сваркой."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "defensepylon-blue"
	anchored = TRUE
	density = TRUE
	max_integrity = 200
	light_range = 2
	light_color = "#80c0ff"
	var/datum/weakref/owner_mind
	COOLDOWN_DECLARE(zap_cooldown)

/obj/structure/pve_tesla_coil/get_ru_names()
	return alist(
		NOMINATIVE = "тесла-катушка",
		GENITIVE = "тесла-катушки",
		DATIVE = "тесла-катушке",
		ACCUSATIVE = "тесла-катушку",
		INSTRUMENTAL = "тесла-катушкой",
		PREPOSITIONAL = "тесла-катушке",
	)

/obj/structure/pve_tesla_coil/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/pve_tesla_coil/Destroy()
	STOP_PROCESSING(SSobj, src)
	owner_mind = null
	return ..()

/obj/structure/pve_tesla_coil/examine(mob/user)
	. = ..()
	. += span_notice("Прочность: [obj_integrity]/[max_integrity].")

/obj/structure/pve_tesla_coil/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_pve_friendly_projectile(mover))
		return TRUE

/obj/structure/pve_tesla_coil/welder_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(obj_integrity >= max_integrity)
		balloon_alert(user, "ремонт не нужен")
		return
	if(!tool.tool_use_check(user, 0))
		return
	WELDER_ATTEMPT_REPAIR_MESSAGE
	if(!tool.use_tool(src, user, pve_repair_time(user), volume = tool.tool_volume))
		return
	WELDER_REPAIR_SUCCESS_MESSAGE
	repair_damage(PVE_REPAIR_AMOUNT)

/obj/structure/pve_tesla_coil/process(seconds_per_tick)
	if(!COOLDOWN_FINISHED(src, zap_cooldown))
		return
	var/mob/living/simple_animal/hostile/pve/closest
	var/closest_distance = PVE_TESLA_RANGE + 1
	for(var/mob/living/simple_animal/hostile/pve/enemy in view(PVE_TESLA_RANGE, src))
		var/distance = get_dist(src, enemy)
		if(enemy.stat != DEAD && distance < closest_distance)
			closest = enemy
			closest_distance = distance
	if(!closest)
		return
	COOLDOWN_START(src, zap_cooldown, PVE_TESLA_COOLDOWN)
	flick("defensepylonattack-blue", src)
	Beam(closest, icon_state = "lightning[rand(1, 12)]", icon = 'icons/effects/effects.dmi', time = 0.5 SECONDS)
	playsound(src, 'sound/magic/lightningbolt.ogg', 40, TRUE)
	if(owner_mind)
		closest.last_hitter = owner_mind
		closest.last_hit_melee = FALSE
	closest.apply_damage(PVE_TESLA_DAMAGE, BURN)

/obj/structure/pve_med_station
	name = "field med station"
	desc = "Полевая медстанция. Лечит союзников в радиусе двух шагов."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "fountain-blue"
	anchored = TRUE
	density = TRUE
	max_integrity = 150
	light_range = 2
	light_color = "#80F5FF"

/obj/structure/pve_med_station/get_ru_names()
	return alist(
		NOMINATIVE = "полевая медстанция",
		GENITIVE = "полевой медстанции",
		DATIVE = "полевой медстанции",
		ACCUSATIVE = "полевую медстанцию",
		INSTRUMENTAL = "полевой медстанцией",
		PREPOSITIONAL = "полевой медстанции",
	)

/obj/structure/pve_med_station/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/pve_med_station/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/pve_med_station/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_pve_friendly_projectile(mover))
		return TRUE

/obj/structure/pve_med_station/process(seconds_per_tick)
	for(var/mob/living/carbon/human/patient in range(PVE_MED_STATION_RANGE, src))
		if(patient.stat == DEAD || (!patient.getBruteLoss() && !patient.getFireLoss()))
			continue
		patient.heal_overall_damage(PVE_MED_STATION_HEAL, PVE_MED_STATION_HEAL)
		if(prob(30))
			new /obj/effect/temp_visual/heal(get_turf(patient), "#80F5FF")

/obj/structure/pve_lamp
	name = "floodlight"
	desc = "Переносной прожектор, разгоняющий туман и темноту."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "floodlight_on"
	anchored = TRUE
	max_integrity = 60
	light_range = 7
	light_power = 2
	light_color = "#fff2d0"

/obj/structure/pve_lamp/get_ru_names()
	return alist(
		NOMINATIVE = "прожектор",
		GENITIVE = "прожектора",
		DATIVE = "прожектору",
		ACCUSATIVE = "прожектор",
		INSTRUMENTAL = "прожектором",
		PREPOSITIONAL = "прожекторе",
	)

/obj/effect/pve_mine
	name = "fog mine"
	desc = "Мина, реагирующая только на тварей тумана."
	icon = 'icons/obj/items.dmi'
	icon_state = "uglyminearmed"
	layer = LOW_OBJ_LAYER
	var/datum/weakref/owner_mind

/obj/effect/pve_mine/get_ru_names()
	return alist(
		NOMINATIVE = "мина тумана",
		GENITIVE = "мины тумана",
		DATIVE = "мине тумана",
		ACCUSATIVE = "мину тумана",
		INSTRUMENTAL = "миной тумана",
		PREPOSITIONAL = "мине тумана",
	)

/obj/effect/pve_mine/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/pve_mine/Destroy()
	owner_mind = null
	return ..()

/obj/effect/pve_mine/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!IS_PVE_ENEMY(arrived))
		return
	var/mob/living/simple_animal/hostile/pve/enemy = arrived
	if(enemy.stat == DEAD)
		return
	INVOKE_ASYNC(src, PROC_REF(detonate))

/obj/effect/pve_mine/proc/detonate()
	var/turf/center = get_turf(src)
	new /obj/effect/temp_visual/explosion(center, 1, null, TRUE)
	playsound(center, 'sound/effects/explosion1.ogg', 80, TRUE)
	for(var/mob/living/simple_animal/hostile/pve/enemy in range(1, center))
		if(enemy.stat == DEAD)
			continue
		if(owner_mind)
			enemy.last_hitter = owner_mind
		enemy.apply_damage(PVE_MINE_DAMAGE, BRUTE)
	qdel(src)

/obj/item/pve_credit_chip
	name = "credit chip"
	desc = "Чип с кредитами защитников. Используйте в руке, чтобы зачислить на свой счёт."
	icon = 'icons/goonstation/objects/money.dmi'
	icon_state = "cashgreen"
	w_class = WEIGHT_CLASS_TINY
	var/value = 50

/obj/item/pve_credit_chip/get_ru_names()
	return alist(
		NOMINATIVE = "кредитный чип",
		GENITIVE = "кредитного чипа",
		DATIVE = "кредитному чипу",
		ACCUSATIVE = "кредитный чип",
		INSTRUMENTAL = "кредитным чипом",
		PREPOSITIONAL = "кредитном чипе",
	)

/obj/item/pve_credit_chip/Initialize(mapload, value)
	. = ..()
	if(value)
		src.value = value

/obj/item/pve_credit_chip/examine(mob/user)
	. = ..()
	. += span_notice("На чипе [value] кредитов.")

/obj/item/pve_credit_chip/attack_self(mob/user)
	var/datum/game_mode/pve/mode = get_pve_mode()
	var/datum/pve_account/account = mode?.get_account(user)
	if(!account)
		balloon_alert(user, "нет счёта")
		return
	account.add_credits(value)
	balloon_alert(user, "+[value] кредитов")
	playsound(user, 'sound/machines/ping.ogg', 40, TRUE)
	qdel(src)

/obj/structure/closet/crate/freezer/pve_rations
	name = "ration freezer"

/obj/structure/closet/crate/freezer/pve_rations/populate_contents()
	for(var/i in 1 to 2)
		new /obj/item/storage/box/donkpockets(src)
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/food/snacks/cheeseburger(src)
		new /obj/item/reagent_containers/food/snacks/chips(src)
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/cup/beaker/waterbottle(src)

/obj/structure/closet/crate/medical/pve
	name = "medbay supplies"

/obj/structure/closet/crate/medical/pve/populate_contents()
	new /obj/item/storage/firstaid/brute(src)
	new /obj/item/storage/firstaid/fire(src)
	new /obj/item/storage/firstaid/toxin(src)
	new /obj/item/storage/box/bodybags(src)
	new /obj/item/storage/box/syringes(src)
	new /obj/item/storage/pill_bottle/charcoal(src)
	for(var/i in 1 to 2)
		new /obj/item/roller(src)
		new /obj/item/reagent_containers/iv_bag/blood/OMinus(src)
		new /obj/item/reagent_containers/food/pill/patch/styptic(src)
		new /obj/item/reagent_containers/food/pill/patch/silver_sulf(src)

/obj/structure/closet/crate/engineering/pve
	name = "construction supplies"

/obj/structure/closet/crate/engineering/pve/populate_contents()
	new /obj/item/stack/sheet/glass/fifty(src)
	new /obj/item/stack/rods/fifty(src)
	for(var/i in 1 to 2)
		new /obj/item/stack/cable_coil(src)
		new /obj/item/clothing/gloves/color/yellow(src)
		new /obj/item/pve_deployable/barricade(src)

/obj/structure/closet/crate/pve_ammo
	name = "ammo crate"

/obj/structure/closet/crate/pve_ammo/populate_contents()
	for(var/i in 1 to 2)
		new /obj/item/ammo_box/magazine/m10mm(src)
		new /obj/item/ammo_box/speedloader/a762(src)
		new /obj/item/ammo_box/speedloader/shotgun/buck(src)
	for(var/i in 1 to 4)
		new /obj/item/flashlight/flare(src)

/obj/structure/closet/supplypod/bluespacepod/pve_drop
	style = /datum/pod_style/seethrough
	explosionSize = list(0, 0, 0, 0)
	delays = list(POD_TRANSIT = 6 SECONDS, POD_FALLING = 2 SECONDS, POD_OPENING = 1 SECONDS, POD_LEAVING = 0)

/obj/item/flamethrower/full/tank/pve
	desc = "Огнемёт защитника. Пламя цепляется только за тварей тумана."

/obj/item/flamethrower/full/tank/pve/get_ru_names()
	return alist(
		NOMINATIVE = "огнемёт",
		GENITIVE = "огнемёта",
		DATIVE = "огнемёту",
		ACCUSATIVE = "огнемёт",
		INSTRUMENTAL = "огнемётом",
		PREPOSITIONAL = "огнемёте",
	)

/obj/item/flamethrower/full/tank/pve/default_ignite(turf/target, release_amount = 0.05)
	if(!ptank || ptank.air_contents.toxins() < PVE_FLAMER_FUEL_PER_TILE)
		return
	ptank.air_contents.remove(PVE_FLAMER_FUEL_PER_TILE)
	new /obj/effect/temp_visual/fire(target)
	var/mob/living/shooter = loc
	for(var/mob/living/simple_animal/hostile/pve/enemy in target)
		if(enemy.stat == DEAD)
			continue
		if(istype(shooter))
			enemy.note_attacker(shooter)
		enemy.apply_damage(PVE_FLAMER_DAMAGE, BURN)
		enemy.apply_status_effect(/datum/status_effect/pve_burning)

/datum/status_effect/pve_burning
	id = "pve_burning"
	duration = PVE_FLAMER_BURN_DURATION
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	var/static/mutable_appearance/fire_overlay = mutable_appearance('icons/mob/OnFire.dmi', "human_generic_burn")

/datum/status_effect/pve_burning/on_apply()
	owner.add_overlay(fire_overlay)
	return TRUE

/datum/status_effect/pve_burning/on_remove()
	owner.cut_overlay(fire_overlay)

/datum/status_effect/pve_burning/tick(seconds_between_ticks)
	if(owner.stat == DEAD)
		qdel(src)
		return
	owner.apply_damage(PVE_FLAMER_BURN_DAMAGE, BURN)

/obj/item/paper/pve_guide
	name = "defense briefing"
	info = {"<center><h2>Оборона Маяка</h2></center>
<p>Из красного тумана справа идут волны тварей. Ваша задача — продержаться <b>20 волн</b> и убить Пожирателя тумана.</p>
<h3>Как играть</h3>
<ul>
<li>Между волнами есть время на подготовку. Нажмите на табло вверху экрана, чтобы отметиться готовым — когда готовы все, волна начнётся раньше.</li>
<li>Кредиты дают за убийства (тому, кто нанёс последний удар) и за каждую отбитую волну. Тратьте их в терминалах отделов.</li>
<li>Оружейная — оружие, патроны, броня. Медбей — медикаменты. Инженерная — баррикады, турели, мины, прожекторы. Штаб — поддержка всей команды.</li>
<li>Погибшие возвращаются в строй после окончания волны. Поражение — если погибнут все или падёт Маяк.</li>
<li>В зоне отдыха и медбее раны затягиваются сами, на кровати — быстрее.</li>
<li>Туман гнезда справа ядовит. Не задерживайтесь там без противогаза.</li>
<li>Почти каждая волна приносит <b>контракт</b>: выполните условие — и вся команда получит премию.</li>
<li>Разведка заранее сообщает, какой мутатор ждёт следующую волну. Готовьтесь к нему.</li>
<li>Твари иногда роняют кредитные чипы и припасы, а элита — всегда. Не забывайте их подбирать.</li>
<li>В терминале штаба продаются личные тренировки: они остаются с вами до конца раунда, даже после гибели.</li>
</ul>
<h3>Враги</h3>
<ul>
<li><b>Голем</b> почти неуязвим к пулям и клинкам — берите лазеры.</li>
<li><b>Призрак</b> наоборот, энергию не замечает — берите дробовики и сталь.</li>
<li><b>Шаман</b> лечит сородичей, <b>пузырь</b> взрывается рядом с целью.</li>
<li><b>Носитель</b> лопается роем мышей, <b>скрытень</b> почти невидим издалека, <b>вожак</b> воем приводит стаю в ярость.</li>
<li><b>Светоч тумана</b> не нападает и убегает. Поймайте его до того, как он ускользнёт, — награда велика.</li>
<li>Каждая пятая волна — босс.</li>
</ul>"}

#undef PVE_CORE_ALERT_COOLDOWN
#undef PVE_REPAIR_AMOUNT
#undef PVE_REPAIR_TIME
#undef PVE_ENGINEER_REPAIR_TIME
#undef PVE_MED_STATION_RANGE
#undef PVE_MED_STATION_HEAL
#undef PVE_MINE_DAMAGE
#undef PVE_FLAMER_FUEL_PER_TILE
#undef PVE_FLAMER_DAMAGE
#undef PVE_FLAMER_BURN_DAMAGE
#undef PVE_FLAMER_BURN_DURATION
#undef PVE_CORE_PULSE_COOLDOWN
#undef PVE_CORE_PULSE_BASE_RANGE
#undef PVE_CORE_PULSE_DAMAGE
#undef PVE_SPIKES_DAMAGE
#undef PVE_SPIKES_WEAR
#undef PVE_TESLA_COOLDOWN
#undef PVE_TESLA_RANGE
#undef PVE_TESLA_DAMAGE
