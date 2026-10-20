/datum/asset/spritesheet_batched/crafting
	name = "crafting"

/datum/asset/spritesheet_batched/crafting/create_spritesheets()
	var/id = 1
	for(var/datum in GLOB.crafting_recipes_datums)
		add_atom_icon(datum, id++)
	add_tool_icons()

/datum/asset/spritesheet_batched/crafting/proc/add_atom_icon(ingredient_typepath, id)
	if(ispath(ingredient_typepath, /datum/reagent))
		insert_icon("a[id]", get_reagent_icon(ingredient_typepath))
		return
	if(!ispath(ingredient_typepath, /atom))
		return
	var/atom/atom_path = ingredient_typepath
	var/icon_state = atom_path::icon_state
	if(ispath(atom_path, /obj))
		var/obj/obj_path = atom_path
		icon_state = obj_path::icon_state_preview || icon_state
	var/datum/greyscale_config/config = SSgreyscale.configurations["[atom_path::greyscale_config]"]
	if(config && atom_path::greyscale_colors && ((atom_path::post_init_icon_state || atom_path::icon_state) in config.icon_states))
		insert_icon("a[id]", gags_to_universal_icon(atom_path))
		return
	if(icon_exists(atom_path::icon, icon_state))
		insert_icon("a[id]", uni_icon(atom_path::icon, icon_state, color = atom_path::color))
		return
	insert_icon("a[id]", uni_icon('icons/effects/random_spawners.dmi', "questionmark"))

/datum/asset/spritesheet_batched/crafting/proc/get_reagent_icon(datum/reagent/reagent_path)
	if(icon_exists('icons/obj/drinks.dmi', reagent_path::drink_icon))
		return uni_icon('icons/obj/drinks.dmi', reagent_path::drink_icon)
	var/obj/item/reagent_containers/cup/beaker/beaker_path = /obj/item/reagent_containers/cup/beaker
	var/datum/universal_icon/beaker_icon = uni_icon(beaker_path::icon, beaker_path::icon_state)
	beaker_icon.blend_icon(uni_icon(beaker_path::fill_icon, "[beaker_path::icon_state]50", color = reagent_path::color), ICON_OVERLAY)
	return beaker_icon

/datum/asset/spritesheet_batched/crafting/proc/add_tool_icons()
	var/list/tool_items = list(
		TOOL_CROWBAR = /obj/item/crowbar,
		TOOL_MULTITOOL = /obj/item/multitool,
		TOOL_SCREWDRIVER = /obj/item/screwdriver,
		TOOL_WIRECUTTER = /obj/item/wirecutters,
		TOOL_WRENCH = /obj/item/wrench,
		TOOL_WELDER = /obj/item/weldingtool,
		TOOL_ANALYZER = /obj/item/analyzer,
		TOOL_MINING = /obj/item/pickaxe/mini,
		TOOL_RETRACTOR = /obj/item/retractor,
		TOOL_HEMOSTAT = /obj/item/hemostat,
		TOOL_CAUTERY = /obj/item/cautery,
		TOOL_DRILL = /obj/item/surgicaldrill,
		TOOL_SCALPEL = /obj/item/scalpel,
		TOOL_SAW = /obj/item/circular_saw,
		TOOL_BONESET = /obj/item/bonesetter,
	)

	for(var/tool in tool_items)
		insert_icon(tool, get_display_icon_for(tool_items[tool]))
