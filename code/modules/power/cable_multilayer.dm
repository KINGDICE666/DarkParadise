/obj/structure/cable/multilayer
	name = "multilayer cable hub"
	desc = "Узел, соединяющий проводку разных слоёв на одном тайле."
	icon = 'icons/obj/engines_and_power/power.dmi'
	icon_state = "cable_bridge"
	layer = WIRE_LAYER - 0.02
	color = CABLE_HEX_COLOR_WHITE

/obj/structure/cable/multilayer/get_ru_names()
	return alist(
		NOMINATIVE = "многослойный узел проводки",
		GENITIVE = "многослойного узла проводки",
		DATIVE = "многослойному узлу проводки",
		ACCUSATIVE = "многослойный узел проводки",
		INSTRUMENTAL = "многослойным узлом проводки",
		PREPOSITIONAL = "многослойном узле проводки",
	)

/obj/structure/cable/multilayer/connected
	cable_layer = CABLE_LAYER_1 | CABLE_LAYER_2 | CABLE_LAYER_3

/obj/structure/cable/multilayer/Initialize(mapload)
	. = ..()
	d1 = 0
	update_appearance(UPDATE_OVERLAYS)

/obj/structure/cable/multilayer/adjust_cable_layer()
	return

/obj/structure/cable/multilayer/update_icon_state()
	return

/obj/structure/cable/multilayer/update_overlays()
	. = ..()
	var/static/list/layer_offsets = list(
		"[CABLE_LAYER_1]" = list(CABLE_LAYER_OFFSET, CABLE_HEX_COLOR_YELLOW),
		"[CABLE_LAYER_2]" = list(0, CABLE_HEX_COLOR_RED),
		"[CABLE_LAYER_3]" = list(-CABLE_LAYER_OFFSET, CABLE_HEX_COLOR_BLUE),
	)
	for(var/layer_key in layer_offsets)
		if(!(cable_layer & text2num(layer_key)))
			continue
		var/list/layer_look = layer_offsets[layer_key]
		var/mutable_appearance/node = mutable_appearance('icons/obj/engines_and_power/power_cond/layer_cable.dmi', "node_all")
		node.color = layer_look[2]
		node.transform = TRANSLATE_MATRIX(layer_look[1], layer_look[1])
		node.appearance_flags |= RESET_COLOR
		. += node

/obj/structure/cable/multilayer/get_connections(powernetless_only = 0)
	return power_list(loc, src, 0, powernetless_only)

/obj/structure/cable/multilayer/cut_cable_from_powernet(remove = TRUE)
	var/turf/hub_turf = loc
	if(!hub_turf)
		return
	var/list/neighbours = power_list(hub_turf, src, 0, cable_only = TRUE)
	var/datum/powernet/old_powernet = powernet
	if(remove)
		loc = null
	powernet.remove_cable(src)
	SSmachines.deferred_powernet_rebuilds |= neighbours
	for(var/obj/machinery/power/machine in hub_turf)
		if(machine.powernet != old_powernet)
			continue
		if(!machine.connect_to_network())
			machine.disconnect_from_network()

/obj/structure/cable/multilayer/attack_robot(mob/user, list/modifiers)
	return attack_hand(user)

/obj/structure/cable/multilayer/attack_hand(mob/user)
	if(HAS_TRAIT(src, TRAIT_UNDERFLOOR) || !user.IsAdvancedToolUser())
		return ..()
	var/static/list/layer_choices = list(
		CABLE_LAYER_1_NAME = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-yellow"),
		CABLE_LAYER_2_NAME = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-red"),
		CABLE_LAYER_3_NAME = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-blue"),
	)
	var/static/list/layer_by_name = list(
		CABLE_LAYER_1_NAME = CABLE_LAYER_1,
		CABLE_LAYER_2_NAME = CABLE_LAYER_2,
		CABLE_LAYER_3_NAME = CABLE_LAYER_3,
	)
	var/choice = show_radial_menu(user, src, layer_choices, require_near = TRUE)
	if(!choice || QDELETED(src))
		return TRUE
	var/toggled_layer = layer_by_name[choice]
	toggle_layer(toggled_layer)
	balloon_alert(user, cable_layer & toggled_layer ? "слой подключён" : "слой отключён")
	return TRUE

/obj/structure/cable/multilayer/proc/toggle_layer(toggled_layer)
	var/list/affected = power_list(loc, src, 0, cable_only = TRUE)
	cable_layer ^= toggled_layer
	affected |= power_list(loc, src, 0, cable_only = TRUE)
	affected |= src
	var/list/rebuilt_powernets = list()
	for(var/obj/structure/cable/start_cable as anything in affected)
		if(start_cable.powernet in rebuilt_powernets)
			continue
		var/datum/powernet/new_powernet = new()
		propagate_network(start_cable, new_powernet)
		rebuilt_powernets += new_powernet
	update_appearance(UPDATE_OVERLAYS)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CABLE_UPDATED, loc)
