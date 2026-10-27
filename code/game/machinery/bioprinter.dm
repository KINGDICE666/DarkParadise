#define BIOPRINTER_CAPACITY 200
#define BIOPRINTER_MEAT_YIELD 10
#define BIOPRINTER_PROTEIN_PER_MEAT 3
#define BIOPRINTER_ORGAN_COST 20
#define BIOPRINTER_HEART_COST 30
#define BIOPRINTER_PRINT_TIME (30 SECONDS)

/obj/machinery/bioprinter
	name = "organ bioprinter"
	desc = "Медицинский биопринтер. Перерабатывает сырое мясо в биомассу для печати ослабленных копий расовых органов."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "bioprinter"
	density = TRUE
	anchored = TRUE
	idle_power_usage = 40
	active_power_usage = 1000
	var/biomass = 0
	var/capacity = BIOPRINTER_CAPACITY
	var/print_speed = 1
	var/print_remaining = 0
	var/printing_species
	var/printing_slot
	var/selected_species = SPECIES_HUMAN
	var/static/list/organ_catalog = list()

/obj/machinery/bioprinter/get_ru_names()
	return alist(
		NOMINATIVE = "биопринтер органов",
		GENITIVE = "биопринтера органов",
		DATIVE = "биопринтеру органов",
		ACCUSATIVE = "биопринтер органов",
		INSTRUMENTAL = "биопринтером органов",
		PREPOSITIONAL = "биопринтере органов",
	)

/obj/machinery/bioprinter/Initialize(mapload)
	. = ..()
	component_parts = list(
		new /obj/item/circuitboard/bioprinter(null),
		new /obj/item/stock_parts/matter_bin(null),
		new /obj/item/stock_parts/manipulator(null),
		new /obj/item/stock_parts/scanning_module(null),
		new /obj/item/stack/sheet/glass(null),
		new /obj/item/stack/cable_coil(null, 2),
	)
	RefreshParts()
	if(length(organ_catalog))
		return
	var/list/available_species = assoc_to_keys(GLOB.all_species) & (list(SPECIES_HUMAN) | CONFIG_GET(str_list/playable_species))
	available_species.Swap(1, available_species.Find(SPECIES_HUMAN))
	for(var/species_name in available_species)
		var/datum/species/species = GLOB.all_species[species_name]
		var/list/recipes = list()
		for(var/slot in species.has_organ)
			var/organ_path = species.has_organ[slot]
			if(slot == INTERNAL_ORGAN_BRAIN || !ispath(organ_path, /obj/item/organ/internal) || ispath(organ_path, /obj/item/organ/internal/cyberimp))
				continue
			var/obj/item/organ/internal/organ = new organ_path(null)
			recipes[slot] = list(
				"slot" = slot,
				"name" = DECLENT_RU_CAP(organ, NOMINATIVE),
				"cost" = slot == INTERNAL_ORGAN_HEART ? BIOPRINTER_HEART_COST : BIOPRINTER_ORGAN_COST,
				"icon" = organ.icon,
				"icon_state" = organ.icon_state,
			)
			qdel(organ)
		if(length(recipes))
			organ_catalog[species_name] = recipes

/obj/machinery/bioprinter/RefreshParts()
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		capacity = BIOPRINTER_CAPACITY * bin.rating
	for(var/obj/item/stock_parts/manipulator/manipulator in component_parts)
		print_speed = manipulator.rating

/obj/machinery/bioprinter/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/machinery/bioprinter/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	if(istype(used, /obj/item/storage/part_replacer))
		if(printing_slot)
			balloon_alert(user, "идёт печать!")
			return ITEM_INTERACT_BLOCKING
		if(exchange_parts(user, used))
			return ITEM_INTERACT_SUCCESS
	if(!istype(used, /obj/item/reagent_containers/food/snacks/meat))
		return ..()
	if(!is_operational() || panel_open)
		balloon_alert(user, "аппарат недоступен!")
		return ITEM_INTERACT_BLOCKING
	var/protein = used.reagents.get_reagent_amount("protein")
	var/biomass_gain = protein / BIOPRINTER_PROTEIN_PER_MEAT * BIOPRINTER_MEAT_YIELD
	if(biomass_gain <= 0)
		balloon_alert(user, "нет пригодного белка!")
		return ITEM_INTERACT_BLOCKING
	if(biomass + biomass_gain > capacity)
		balloon_alert(user, "хранилище заполнено!")
		return ITEM_INTERACT_BLOCKING
	if(!user.drop_transfer_item_to_loc(used, src))
		return ITEM_INTERACT_BLOCKING
	biomass += biomass_gain
	qdel(used)
	add_fingerprint(user)
	playsound(src, 'sound/machines/blender.ogg', 40, TRUE)
	SStgui.update_uis(src)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/bioprinter/screwdriver_act(mob/living/user, obj/item/tool)
	if(!default_deconstruction_screwdriver(user, "bioprinter", "bioprinter", tool))
		return FALSE
	update_use_power(panel_open || !printing_slot ? IDLE_POWER_USE : ACTIVE_POWER_USE)
	SStgui.update_uis(src)
	return TRUE

/obj/machinery/bioprinter/welder_act(mob/living/user, obj/item/tool)
	if(!panel_open)
		balloon_alert(user, "сначала откройте панель!")
		return TRUE
	default_welder_repair(user, tool)
	return TRUE

/obj/machinery/bioprinter/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/bioprinter/wrench_act(mob/living/user, obj/item/tool)
	if(printing_slot)
		balloon_alert(user, "идёт печать!")
		return TRUE
	return default_unfasten_wrench(user, tool)

/obj/machinery/bioprinter/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Bioprinter", declent_ru(NOMINATIVE))
		ui.open()

/obj/machinery/bioprinter/ui_static_data(mob/user)
	var/list/species_list = list()
	for(var/species_name in organ_catalog)
		species_list += list(list("id" = species_name, "name" = capitalize(GET_RU_SPECIES_NAME(species_name))))
	return list("species" = species_list)

/obj/machinery/bioprinter/ui_data(mob/user)
	var/list/products = list()
	for(var/slot in organ_catalog[selected_species])
		products += list(organ_catalog[selected_species][slot])
	return list(
		"biomass" = biomass,
		"capacity" = capacity,
		"selected_species" = selected_species,
		"products" = products,
		"printing" = !!printing_slot,
		"remaining" = round(print_remaining / (1 SECONDS)),
		"available" = is_operational() && !panel_open,
	)

/obj/machinery/bioprinter/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(!is_operational() || panel_open || printing_slot)
		return FALSE
	switch(action)
		if("species")
			if(!(params["species"] in organ_catalog))
				return FALSE
			selected_species = params["species"]
			return TRUE
		if("print")
			return start_printing(params["slot"])

/obj/machinery/bioprinter/proc/start_printing(slot)
	if(!is_operational() || panel_open || printing_slot)
		return FALSE
	var/list/recipe = organ_catalog[selected_species]?[slot]
	if(!recipe || biomass < recipe["cost"])
		return FALSE
	biomass -= recipe["cost"]
	printing_species = selected_species
	printing_slot = slot
	print_remaining = BIOPRINTER_PRINT_TIME / print_speed
	update_use_power(ACTIVE_POWER_USE)
	return TRUE

/obj/machinery/bioprinter/process(seconds_per_tick)
	if(!printing_slot || !is_operational() || panel_open)
		return
	print_remaining = max(0, print_remaining - seconds_per_tick SECONDS)
	if(print_remaining)
		SStgui.update_uis(src)
		return
	var/datum/species/species = GLOB.all_species[printing_species]
	var/organ_path = species.has_organ[printing_slot]
	var/obj/item/organ/internal/organ = new organ_path(get_turf(src))
	organ.species_type = species.type
	organ.update_DNA(update_blood = FALSE, randomize = TRUE)
	organ.AddComponent(/datum/component/bioprinted_organ)
	printing_species = null
	printing_slot = null
	update_use_power(IDLE_POWER_USE)
	playsound(src, 'sound/machines/ping.ogg', 40, TRUE)
	SStgui.update_uis(src)

#undef BIOPRINTER_CAPACITY
#undef BIOPRINTER_MEAT_YIELD
#undef BIOPRINTER_PROTEIN_PER_MEAT
#undef BIOPRINTER_ORGAN_COST
#undef BIOPRINTER_HEART_COST
#undef BIOPRINTER_PRINT_TIME
