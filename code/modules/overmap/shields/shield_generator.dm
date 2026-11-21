GLOBAL_LIST_EMPTY(ship_shield_generators)

/obj/machinery/ship_shield_generator
	name = "ship shield generator"
	desc = "Проецирует энергетический пузырь вокруг корпуса корабля. Принимает на себя снаряды, удары угроз и излучение, пока не иссякнет заряд."
	icon = 'icons/obj/objects.dmi'
	icon_state = "shieldoff"
	anchored = TRUE
	density = TRUE
	max_integrity = 250
	idle_power_usage = 500
	active_power_usage = 8000
	resistance_flags = FIRE_PROOF
	var/active = TRUE
	var/charge = 0
	var/max_charge = OVERMAP_SHIELD_CAPACITY
	var/regen_rate = OVERMAP_SHIELD_REGEN
	var/regen_after = 0
	var/board_path = /obj/item/circuitboard/ship_shield_generator

/obj/machinery/ship_shield_generator/get_ru_names()
	return alist(
		NOMINATIVE = "генератор корабельного щита",
		GENITIVE = "генератора корабельного щита",
		DATIVE = "генератору корабельного щита",
		ACCUSATIVE = "генератор корабельного щита",
		INSTRUMENTAL = "генератором корабельного щита",
		PREPOSITIONAL = "генераторе корабельного щита",
	)

/obj/machinery/ship_shield_generator/Initialize(mapload)
	. = ..()
	GLOB.ship_shield_generators += src
	component_parts = list(new board_path(src))
	var/obj/item/circuitboard/board = component_parts[1]
	for(var/part_type, count in board.req_components)
		if(ispath(part_type, /obj/item/stack))
			component_parts += new part_type(src, count)
		else
			for(var/index in 1 to count)
				component_parts += new part_type(src)
	START_PROCESSING(SSmachines, src)
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/ship_shield_generator/Destroy()
	GLOB.ship_shield_generators -= src
	var/obj/overmap/entity/vessel = SSovermap?.resolve_vessel(src)
	if(vessel)
		LAZYREMOVE(vessel.shield_generators_cache, src)
		vessel.shield_generators_until = 0
		vessel.update_shield_halo()
	return ..()

/obj/machinery/ship_shield_generator/update_icon_state()
	var/on = online()
	icon_state = "shield[on && charge > 0 ? "on" : "off"][(stat & BROKEN) ? "br" : ""]"

/obj/machinery/ship_shield_generator/proc/online()
	return active && anchored && !(stat & (NOPOWER|BROKEN))

/obj/machinery/ship_shield_generator/proc/available_charge()
	return online() ? charge : 0

/obj/machinery/ship_shield_generator/process()
	var/obj/overmap/entity/vessel = SSovermap.resolve_vessel(src)
	vessel?.update_shield_halo()
	if(!online())
		if(charge > 0)
			charge = max(charge - max_charge * OVERMAP_SHIELD_DECAY * SSMACHINES_DT, 0)
			update_icon(UPDATE_ICON_STATE)
		update_use_power(IDLE_POWER_USE)
		return
	if(world.time < regen_after || charge >= max_charge)
		update_use_power(charge >= max_charge ? IDLE_POWER_USE : ACTIVE_POWER_USE)
		return
	var/was_empty = charge <= 0
	charge = min(charge + regen_rate * SSMACHINES_DT, max_charge)
	update_use_power(ACTIVE_POWER_USE)
	if(was_empty)
		playsound(src, 'sound/machines/terminal_on.ogg', 40, TRUE)
		update_icon(UPDATE_ICON_STATE)

/obj/machinery/ship_shield_generator/proc/drain(amount)
	var/taken = min(amount, available_charge())
	if(taken <= 0)
		return 0
	charge -= taken
	regen_after = world.time + OVERMAP_SHIELD_REGEN_DELAY
	if(charge <= 0)
		charge = 0
		playsound(src, 'sound/machines/engine_alert1.ogg', 50, TRUE)
		visible_message(span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] трещит и сбрасывает щит!"))
		update_icon(UPDATE_ICON_STATE)
	return taken

/obj/machinery/ship_shield_generator/proc/toggle(mob/user)
	active = !active
	if(!active)
		charge = 0
	update_icon(UPDATE_ICON_STATE)
	if(user)
		log_game("[key_name(user)] turned [active ? "on" : "off"] [src] at [AREACOORD(src)].")

/obj/machinery/ship_shield_generator/attack_hand(mob/user)
	if(..())
		return TRUE
	toggle(user)
	balloon_alert(user, active ? "щит включён" : "щит выключен")
	return TRUE

/obj/machinery/ship_shield_generator/examine(mob/user)
	. = ..()
	. += span_notice("Заряд щита: [round(charge)]/[max_charge]. [active ? "Включён" : "Выключен"].")

/obj/machinery/ship_shield_generator/wrench_act(mob/living/user, obj/item/tool)
	. = TRUE
	default_unfasten_wrench(user, tool)
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/ship_shield_generator/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, icon_state, icon_state, tool)

/obj/machinery/ship_shield_generator/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/overmap/entity/proc/shield_generators()
	if(world.time < shield_generators_until && shield_generators_cache)
		return shield_generators_cache
	shield_generators_until = world.time + OVERMAP_SHIELD_CACHE_TIME
	shield_generators_cache = list()
	for(var/obj/machinery/ship_shield_generator/generator as anything in GLOB.ship_shield_generators)
		if(SSovermap.resolve_vessel(generator) == src)
			shield_generators_cache += generator
	return shield_generators_cache

/obj/overmap/entity/proc/shield_charge()
	. = 0
	for(var/obj/machinery/ship_shield_generator/generator as anything in shield_generators())
		if(!QDELETED(generator))
			. += generator.available_charge()

/obj/overmap/entity/proc/shield_capacity()
	. = 0
	for(var/obj/machinery/ship_shield_generator/generator as anything in shield_generators())
		if(!QDELETED(generator) && generator.online())
			. += generator.max_charge

/obj/overmap/entity/proc/shield_fraction()
	var/capacity = shield_capacity()
	return capacity ? round(shield_charge() / capacity, 0.01) : 0

/obj/overmap/entity/proc/shield_absorb(amount)
	if(amount <= 0)
		return 0
	var/left = amount
	for(var/obj/machinery/ship_shield_generator/generator as anything in shield_generators())
		if(QDELETED(generator))
			continue
		left -= generator.drain(left)
		if(left <= 0)
			return 0
	return left

/obj/overmap/entity/proc/shield_flash(turf/spot)
	if(!spot)
		return
	new /obj/effect/temp_visual/ship_shield_hit(spot)
	playsound(spot, 'sound/effects/empulse.ogg', 35, TRUE, extrarange = 4)

/obj/overmap/entity/proc/shield_intercept(obj/projectile/payload, turf/spot)
	var/damage = max(payload.damage * payload.ship_shield_factor, 1)
	var/left = shield_absorb(damage)
	if(left == damage)
		return FALSE
	shield_flash(spot)
	flash_shield_halo()
	if(payload.ship_shield_pierce)
		payload.damage *= OVERMAP_SHIELD_PIERCE_KEEP
		return FALSE
	if(left <= 0)
		return TRUE
	payload.damage *= left / damage
	return FALSE

/obj/overmap/entity/proc/shield_block_hazard(obj/overmap/feature/hazard/hazard)
	if(!hazard.shield_cost || shield_absorb(hazard.shield_cost) >= hazard.shield_cost)
		return FALSE
	shield_flash(overmap_vessel_structure_turf(src))
	return TRUE

/obj/effect/temp_visual/ship_shield_hit
	name = "shield flare"
	icon_state = "shield-old"
	duration = 0.6 SECONDS
	color = "#7fc8ff"
	alpha = 200

/obj/item/circuitboard/ship_shield_generator
	board_name = "Ship shield generator"
	board_type = "machine"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/ship_shield_generator
	req_components = list(/obj/item/stock_parts/capacitor = 4, /obj/item/stock_parts/micro_laser = 2, /obj/item/stack/cable_coil = 10, /obj/item/stack/sheet/plasteel = 5)

/datum/design/ship_shield_generator
	name = "Machine Board (Ship Shield Generator)"
	desc = "Плата генератора корабельного щита."
	id = "ship_shield_generator"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/ship_shield_generator
	materials = list(MAT_GLASS = 1000, MAT_GOLD = 500)
	req_tech = list(RESEARCH_TREE_MAGNETS = 4, RESEARCH_TREE_POWERSTORAGE = 4)
	category = list(CIRCUIT_IMPRINTER_CATEGORY_ENGINEERING)
