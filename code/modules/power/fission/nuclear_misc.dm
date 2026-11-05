// MARK: Reactor Power Output

/obj/machinery/power/reactor_power
	name = "reactor output terminal"
	desc = "Пучок силовых кабелей, через который выработка реактора уходит в энергосеть."
	icon_state = "term"
	plane = FLOOR_PLANE
	layer = WIRE_TERMINAL_LAYER // A bit above wires
	resistance_flags = INDESTRUCTIBLE
	var/obj/machinery/atmospherics/fission_reactor/linked_reactor

/obj/machinery/power/reactor_power/get_ru_names()
	return alist(
		NOMINATIVE = "силовой терминал реактора",
		GENITIVE = "силового терминала реактора",
		DATIVE = "силовому терминалу реактора",
		ACCUSATIVE = "силовой терминал реактора",
		INSTRUMENTAL = "силовым терминалом реактора",
		PREPOSITIONAL = "силовом терминале реактора",
	)

/obj/machinery/power/reactor_power/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

// Needs lateload to prevent reactor not being initialized yet and thus not able to set the link.
/obj/machinery/power/reactor_power/LateInitialize()
	. = ..()
	linked_reactor = GLOB.main_fission_reactor

/obj/machinery/power/reactor_power/process()
	if(linked_reactor && linked_reactor.can_create_power)
		add_avail(max(linked_reactor.final_power, 0))

// MARK: Monitor

/obj/machinery/computer/fission_monitor
	name = "NGCR monitoring console"
	desc = "Пульт управления реактором NGCR: положение стержней, аварийная остановка, карта камер и журнал параметров. Управлять можно, только если реактор в прямой видимости."
	icon_keyboard = "power_key"
	icon_screen = "smmon_0"
	circuit = /obj/item/circuitboard/fission_monitor
	light_color = LIGHT_COLOR_YELLOW
	/// Last status of the active reactor for caching purposes
	var/last_status
	/// Reference to the active reactor
	var/obj/machinery/atmospherics/fission_reactor/active
	/// Is this monitor a controller? Affected by visibility from the reactor
	var/controller = TRUE

/obj/machinery/computer/fission_monitor/get_ru_names()
	return alist(
		NOMINATIVE = "пульт управления реактором",
		GENITIVE = "пульта управления реактором",
		DATIVE = "пульту управления реактором",
		ACCUSATIVE = "пульт управления реактором",
		INSTRUMENTAL = "пультом управления реактором",
		PREPOSITIONAL = "пульте управления реактором",
	)

/obj/machinery/computer/fission_monitor/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/fission_monitor/LateInitialize()
	. = ..()
	active = GLOB.main_fission_reactor
	determine_control()

/obj/machinery/computer/fission_monitor/Destroy()
	active = null
	return ..()

// This can normally never happen, but just in case.
/obj/machinery/computer/fission_monitor/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	determine_control()

/obj/machinery/computer/fission_monitor/proc/determine_control()
	if(!active)
		return
	if(active in oview(12, src))
		controller = TRUE
	else
		controller = FALSE

/obj/machinery/computer/fission_monitor/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/computer/fission_monitor/attack_hand(mob/user)
	add_fingerprint(user)
	if(stat & (BROKEN|NOPOWER))
		return
	ui_interact(user)

/obj/machinery/computer/fission_monitor/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/fission_monitor/process()
	if(stat & (NOPOWER|BROKEN))
		return FALSE

	if(active)
		var/new_status = active.get_status()
		if(last_status != new_status)
			last_status = new_status
			icon_screen = "smmon_[last_status]"
			update_icon()

	return TRUE

/obj/machinery/computer/fission_monitor/multitool_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!I.multitool_check_buffer(user))
		return
	var/obj/item/multitool/multitool = I
	if(istype(multitool.buffer, /obj/machinery/atmospherics/fission_reactor))
		active = multitool.buffer
		determine_control()
		to_chat(user, span_notice("Вы загружаете данные привязки в [declent_ru(ACCUSATIVE)]."))

/obj/machinery/computer/fission_monitor/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ReactorMonitor", name)
		ui.open()

	return TRUE

/obj/machinery/computer/fission_monitor/proc/gas_ui_data(list/gases, list/effects)
	var/list/result = list()
	var/total_moles = 0
	for(var/gas, amount in gases)
		total_moles += amount
	if(!total_moles)
		return result
	for(var/gas, amount in gases)
		var/datum/reactor_gas_effect/effect = effects[gas]
		result += list(list(
			"name" = gas,
			"amount" = amount,
			"portion" = round(100 * amount / total_moles, 0.01),
			"desc" = effect?.desc,
		))
	return result

/obj/machinery/computer/fission_monitor/ui_data(mob/user)
	var/list/data = list()
	if(active?.stat & BROKEN)
		active = null
	data["connected"] = !!active
	if(!active)
		return data

	var/datum/gas_mixture/air = active.air_contents
	data["controlling"] = controller
	data["status"] = active.get_status()
	data["offline"] = active.offline
	data["starting_up"] = active.starting_up
	data["meltdown"] = active.final_countdown
	data["control_lockout"] = active.control_lockout
	data["integrity"] = active.get_reactor_integrity()
	data["power"] = round(active.final_power / (1 KILO WATTS), 1)
	data["temperature"] = round(air.temperature(), 0.1)
	data["pressure"] = round(air.return_pressure(), 0.1)
	data["coefficient"] = round(active.reactivity_multiplier, 0.01)
	data["heat_threshold"] = round(active.heat_damage_threshold)
	data["minimum_temp"] = active.minimum_operating_temp
	data["throttle"] = active.control_lockout ? 0 : 100 - active.desired_power
	data["rod_insertion"] = 100 - active.operating_power
	data["control_rods"] = active.control_rods_remaining
	data["venting"] = active.venting
	data["vent_lockout"] = active.vent_lockout
	data["scram_active"] = active.scram_active
	data["scram_hold"] = active.scram_hold
	data["scram_lock"] = round(COOLDOWN_TIMELEFT(active, scram_cooldown) / (1 SECONDS))
	data["history"] = active.history
	data["gases"] = gas_ui_data(air.get_interesting(), GLOB.reactor_coolant_effects)
	var/list/moderator_gases = (active.offline || active.starting_up) ? active.moderator_gas.get_interesting() : active.last_moderator_gases
	data["moderator_gases"] = gas_ui_data(moderator_gases, GLOB.reactor_moderator_effects)

	var/list/chambers = list()
	for(var/obj/machinery/atmospherics/reactor_chamber/chamber in active.connected_chambers)
		var/list/chamber_data = list(
			"x" = chamber.x - active.x,
			"y" = chamber.y - active.y,
			"state" = chamber.chamber_state,
			"welded" = chamber.welded,
			"operational" = chamber.operational,
			"requirements_met" = chamber.requirements_met,
			"enriching" = chamber.enriching,
		)
		var/obj/item/nuclear_rod/rod = chamber.held_rod
		if(rod)
			var/durability_mod = rod.get_durability_mod()
			var/list/requirement_names = list()
			for(var/requirement in rod.adjacent_requirements)
				requirement_names += nuclear_rod_ru_name(requirement)
			chamber_data["rod"] = DECLENT_RU_CAP(rod, NOMINATIVE)
			chamber_data["rod_class"] = rod.get_rod_class()
			chamber_data["durability"] = rod.max_durability == INFINITY ? 100 : round(rod.durability / rod.max_durability * 100, 0.1)
			chamber_data["power"] = chamber.operational ? round(chamber.power_total * durability_mod / (1 KILO WATTS), 0.1) : 0
			chamber_data["heat"] = round(chamber.heat_total * durability_mod, 0.1)
			chamber_data["power_mod"] = round(chamber.power_mod_total, 0.01)
			chamber_data["heat_mod"] = round(chamber.heat_mod_total, 0.01)
			chamber_data["requirements"] = requirement_names
			if(istype(rod, /obj/item/nuclear_rod/fuel))
				var/obj/item/nuclear_rod/fuel/fuel_rod = rod
				if(fuel_rod.power_enrich_result)
					chamber_data["power_enrich"] = round(fuel_rod.power_enrich_progress / fuel_rod.enrichment_cycles * 100)
				if(fuel_rod.heat_enrich_result)
					chamber_data["heat_enrich"] = round(fuel_rod.heat_enrich_progress / fuel_rod.enrichment_cycles * 100)
		chambers += list(chamber_data)
	data["chambers"] = chambers

	return data

/obj/machinery/computer/fission_monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	if((stat & (BROKEN|NOPOWER)) || !active)
		return

	if(!controller)
		visible_message(span_warning("Ошибка: реактор вне зоны лазерного наведения."))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		return

	switch(action)
		if("set_throttle")
			var/throttle = text2num(params["throttle"])
			if(isnull(throttle))
				return
			if(active.scram_active || !COOLDOWN_FINISHED(active, scram_cooldown))
				visible_message(span_warning("Ошибка: стержни заблокированы после аварийной остановки."))
				playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
				return
			var/new_power = 100 - clamp(round(throttle), 0, 100)
			if(!new_power && active.desired_power)
				active.investigate_log("[key_name(usr)] fully inserted the control rods at [active.operating_power]% operating power.", INVESTIGATE_REACTOR)
			if(new_power)
				active.scram_hold = FALSE
			active.desired_power = new_power
			return TRUE

		if("toggle_vent")
			if(active.vent_lockout)
				visible_message(span_warning("Ошибка: приводы клапана не отвечают. Закройте его вручную."))
				playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
				return
			active.venting = !active.venting
			return TRUE

		if("scram")
			return active.emergency_scram(usr)

// MARK: Slag

/obj/item/slag
	name = "corium slag"
	desc = "Глыба активного топлива, сплавленного с конструкциями реактора. Сильно фонит, держать подальше от людей."
	icon = 'icons/effects/effects.dmi'
	icon_state = "big_molten"
	move_resist = MOVE_FORCE_STRONG // Massive chunk of metal slag, shouldnt be moving it without carrying.
	w_class = WEIGHT_CLASS_HUGE
	force = 15
	throwforce = 10

/obj/item/slag/get_ru_names()
	return alist(
		NOMINATIVE = "кориумный шлак",
		GENITIVE = "кориумного шлака",
		DATIVE = "кориумному шлаку",
		ACCUSATIVE = "кориумный шлак",
		INSTRUMENTAL = "кориумным шлаком",
		PREPOSITIONAL = "кориумном шлаке",
	)

/obj/item/slag/Initialize(mapload)
	. = ..()
	//scatter_atom()
	AddElement(/datum/element/radioactive, 10, chance = 80)
	START_PROCESSING(SSprocessing, src)

/obj/item/slag/process()
	. = ..()
	radiation_pulse(src, 6, chance = 50)

// MARK: Starter Grenade

/obj/item/grenade/nuclear_starter
	name = "Neutronic Agitator"
	desc = "Нейтронная граната для принудительного запуска камер в радиусе трёх метров. Действует только на опущенные камеры со стержнями."

/obj/item/grenade/nuclear_starter/get_ru_names()
	return alist(
		NOMINATIVE = "нейтронный активатор",
		GENITIVE = "нейтронного активатора",
		DATIVE = "нейтронному активатору",
		ACCUSATIVE = "нейтронный активатор",
		INSTRUMENTAL = "нейтронным активатором",
		PREPOSITIONAL = "нейтронном активаторе",
	)

/obj/item/grenade/nuclear_starter/deconstruct(disassembled)
	qdel(src)

/obj/item/grenade/nuclear_starter/prime()
	playsound(src.loc, 'sound/weapons/bsg_explode.ogg', 50, TRUE, -3)
	var/obj/effect/temp_visual/neutronic/warp = new(loc)
	warp.pixel_x += 16
	warp.pixel_y += 16
	warp.transform = matrix().Scale(0.01, 0.01)
	animate(warp, time = 0.5 SECONDS, transform = matrix().Scale(1, 1))
	var/list/chamber_list = list()
	for(var/obj/machinery/atmospherics/reactor_chamber/chamber in range(3, loc))
		chamber_list += chamber
	for(var/obj/machinery/atmospherics/reactor_chamber/chamber in chamber_list)
		if(chamber.chamber_state == CHAMBER_DOWN && chamber.held_rod)
			chamber.operational = TRUE
			chamber.update_icon(UPDATE_OVERLAYS)
	for(var/obj/machinery/atmospherics/reactor_chamber/chamber in chamber_list)
		if(chamber.check_status())
			chamber.requirements_met = TRUE
		else
			chamber.requirements_met = FALSE
		chamber.update_icon(UPDATE_OVERLAYS)
	qdel(src)

/obj/effect/temp_visual/neutronic
	icon = 'icons/effects/light_352.dmi'
	icon_state = "light"
	plane = DISPLACEMENT_PLANE
	appearance_flags = PIXEL_SCALE|LONG_GLIDE
	duration = 0.5 SECONDS
	pixel_x = -176
	pixel_y = -176

// MARK: Rad Proof Pool

/turf/simulated/floor/plasteel/reactor_pool
	name = "holding pool"
	desc = "Бассейн выдержки для стержней. Вода гасит их излучение и смывает радиацию с того, кто в неё зашёл."
	icon = 'icons/obj/fission/pool.dmi'
	icon_state = "pool_round"
	footstep = FOOTSTEP_WATER
	barefootstep = FOOTSTEP_WATER
	clawfootstep = FOOTSTEP_WATER
	heavyfootstep = FOOTSTEP_WATER
	/// Holds our pool controller
	var/obj/machinery/poolcontroller/linkedcontroller
	/// Holds our effect overlay
	var/obj/item/effect/pool_overlay/effect
	/// Whether the immerse element has been added yet or not
	var/immerse_added = FALSE

/turf/simulated/floor/plasteel/reactor_pool/get_ru_names()
	return alist(
		NOMINATIVE = "бассейн выдержки",
		GENITIVE = "бассейна выдержки",
		DATIVE = "бассейну выдержки",
		ACCUSATIVE = "бассейн выдержки",
		INSTRUMENTAL = "бассейном выдержки",
		PREPOSITIONAL = "бассейне выдержки",
	)

/turf/simulated/floor/plasteel/reactor_pool/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_INITIALIZED_ON, PROC_REF(initialized_on))
	RegisterSignal(src, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, PROC_REF(on_atom_inited))
	RegisterSignal(src, COMSIG_TURF_CHANGE, PROC_REF(drop_immerse_hooks))
	AddElement(/datum/element/watery_tile)
	return INITIALIZE_HINT_LATELOAD

/turf/simulated/floor/plasteel/reactor_pool/LateInitialize()
	. = ..()
	effect = new(src)

///We lazily add the immerse element when something is spawned or crosses this turf and not before.
/turf/simulated/floor/plasteel/reactor_pool/proc/drop_immerse_hooks(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(src, list(COMSIG_ATOM_INITIALIZED_ON, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, COMSIG_TURF_CHANGE))

/turf/simulated/floor/plasteel/reactor_pool/proc/on_atom_inited(datum/source, atom/movable/movable)
	SIGNAL_HANDLER
	UnregisterSignal(src, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON)
	make_immersed(movable)

///Makes this turf immersable, return true if we actually did anything so child procs don't have to repeat our checks
/turf/simulated/floor/plasteel/reactor_pool/proc/make_immersed(atom/movable/triggering_atom)
	if(immerse_added || is_type_in_typecache(triggering_atom, GLOB.immerse_ignored_movable))
		return FALSE
	AddElement(/datum/element/immerse, "immerse", 180)
	immerse_added = TRUE
	return TRUE

/turf/simulated/floor/plasteel/reactor_pool/crowbar_act(mob/user, obj/item/I)
	return

/turf/simulated/floor/plasteel/reactor_pool/proc/initialized_on(atom/A)
	SIGNAL_HANDLER // COMSIG_ATOM_INITIALIZED_ON
	if(!linkedcontroller)
		return
	if(istype(A, /obj/effect/decal/cleanable)) // Better a typecheck than looping through thousands of turfs everyday
		linkedcontroller.decalinpool += A

/turf/simulated/floor/plasteel/reactor_pool/Entered(atom/movable/AM, atom/OldLoc)
	. = ..()
	make_immersed(AM)
	if(!linkedcontroller)
		return
	if(ismob(AM))
		linkedcontroller.mobinpool += AM

/turf/simulated/floor/plasteel/reactor_pool/Exited(atom/movable/AM, direction)
	. = ..()
	if(!linkedcontroller)
		return
	if(ismob(AM))
		linkedcontroller.mobinpool -= AM

/turf/simulated/floor/plasteel/reactor_pool/ChangeTurf(turf/simulated/floor/T, defer_change = FALSE, keep_icon = TRUE, after_flags = NONE, copy_existing_baseturf = TRUE)
	QDEL_NULL(effect)
	return ..()

/turf/simulated/floor/plasteel/reactor_pool/Destroy()
	QDEL_NULL(effect)
	UnregisterSignal(src, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON)
	return ..()

/turf/simulated/floor/plasteel/reactor_pool/wall
	icon_state = "pool_wall_round"

/turf/simulated/floor/plasteel/reactor_pool/wall/ladder
	icon_state = "ladder_wall_round"

/turf/simulated/floor/plasteel/reactor_pool/wall/filter
	icon_state = "filter_wall_round"

/turf/simulated/floor/plasteel/reactor_pool/square
	icon_state = "pool_sharp_square"

/obj/structure/railing/pool_lining
	name = "pool lining"
	icon = 'icons/obj/fission/pool.dmi'
	icon_state = "poolborder"
	flags = ON_BORDER | NODECONSTRUCT | INDESTRUCTIBLE
	max_integrity = 200

/obj/structure/railing/pool_lining/ex_act(severity)
	if(severity == EXPLODE_HEAVY || severity == EXPLODE_DEVASTATE)
		qdel(src)

/obj/item/effect/pool_overlay
	name = "holding pool"
	desc = "water"
	icon = 'icons/misc/beach.dmi'
	icon_state = "seadeep"
	alpha = 75
	layer = ABOVE_ALL_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

/obj/structure/railing/corner/pool_corner
	name = "pool lining"
	icon = 'icons/obj/fission/pool.dmi'
	icon_state = "bordercorner"

/obj/structure/railing/corner/pool_corner/inner
	icon_state = "innercorner"

/obj/machinery/poolcontroller/invisible/nuclear
	srange = 6
	deep_water = TRUE

/obj/machinery/poolcontroller/invisible/nuclear/Initialize(mapload)
	var/contents_loop = linked_area
	if(!linked_area)
		contents_loop = range(srange, src)

	for(var/turf/simulated/floor/plasteel/reactor_pool/T in contents_loop)
		T.linkedcontroller = src
		linkedturfs += T
	return ..()

/obj/machinery/poolcontroller/invisible/nuclear/Destroy()
	for(var/turf/simulated/floor/plasteel/reactor_pool/W in linkedturfs)
		if(W.linkedcontroller == src)
			W.linkedcontroller = null
	return ..()

/obj/machinery/poolcontroller/invisible/nuclear/processMob()
	for(var/mob/M in mobinpool)
		if(!istype(get_turf(M), /turf/simulated/floor/plasteel/reactor_pool))
			mobinpool -= M
			continue

		M.wash_tg(CLEAN_RAD|CLEAN_WASH)

		if(isliving(M))
			var/mob/living/L = M
			L.ExtinguishMob()
			L.adjust_fire_stacks(-20) //Douse ourselves with water to avoid fire more easily

		if(ishuman(M))
			handleDrowning(M)

// MARK: Fab upgrade

/obj/item/rod_fabricator_upgrade
	name = "Nuclear Fabricator Upgrade"
	desc = "Диск с продвинутыми чертежами стержней. Вставляется в фабрикатор ядерных стержней и открывает высокоуровневые разработки."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk5"
	drop_sound = 'sound/items/handling/disk_drop.ogg'
	pickup_sound =  'sound/items/handling/disk_pickup.ogg'

/obj/item/rod_fabricator_upgrade/get_ru_names()
	return alist(
		NOMINATIVE = "диск улучшения фабрикатора стержней",
		GENITIVE = "диска улучшения фабрикатора стержней",
		DATIVE = "диску улучшения фабрикатора стержней",
		ACCUSATIVE = "диск улучшения фабрикатора стержней",
		INSTRUMENTAL = "диском улучшения фабрикатора стержней",
		PREPOSITIONAL = "диске улучшения фабрикатора стержней",
	)

// MARK: Chamber Doors

/obj/effect/temp_visual/chamber_closing
	icon = 'icons/obj/fission/reactor_chamber.dmi'
	icon_state = "doors_closing"
	duration = 0.7 SECONDS
	layer = ABOVE_ALL_MOB_LAYER + 0.03
