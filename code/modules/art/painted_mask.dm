#define PAINTED_MASK_WIDTH 14
#define PAINTED_MASK_HEIGHT 16
#define PAINTED_MASK_WORN_X 10
#define PAINTED_MASK_WORN_Y 17
#define PAINTED_MASK_SIDE_SHIFT 3
#define PAINTED_MASK_HELD_SCALE 2
#define PAINTED_MASK_HELD_X 3
#define PAINTED_MASK_HELD_Y 1
#define PAINTED_MASK_STATE "morutopia"
#define PAINTED_MASK_BLANK_ICON 'icons/blanks/32x32.dmi'

GLOBAL_LIST_INIT(painted_mask_blank_grid, init_painted_mask_blank_grid())

/proc/init_painted_mask_blank_grid()
	var/icon/source = icon(DEFAULT_ICON_WEAR_MASK, PAINTED_MASK_STATE, SOUTH)
	. = list()
	for(var/y in 1 to PAINTED_MASK_HEIGHT)
		var/list/row = list()
		for(var/x in 1 to PAINTED_MASK_WIDTH)
			var/pixel = source.GetPixel(PAINTED_MASK_WORN_X + x - 1, PAINTED_MASK_WORN_Y + PAINTED_MASK_HEIGHT - y)
			if(!pixel)
				row += "#00000000"
			else
				row += length(pixel) == 7 ? "[pixel]ff" : pixel
		. += list(row)

/obj/item/clothing/mask/painted
	name = "papier-mache mask"
	desc = "Гладкая заготовка из папье-маше. Разрисуйте её на свой вкус."
	icon_state = PAINTED_MASK_STATE
	item_state = "mime"
	flags_cover = MASKCOVERSEYES
	custom_price = PAYCHECK_CREW
	/// The sprite editor workspace that carries the face painted onto this mask
	var/datum/sprite_editor_workspace/workspace
	var/rebuild_timer

/obj/item/clothing/mask/painted/get_ru_names()
	return alist(
		NOMINATIVE = "маска из папье-маше",
		GENITIVE = "маски из папье-маше",
		DATIVE = "маске из папье-маше",
		ACCUSATIVE = "маску из папье-маше",
		INSTRUMENTAL = "маской из папье-маше",
		PREPOSITIONAL = "маске из папье-маше"
	)

/obj/item/clothing/mask/painted/Initialize(mapload)
	. = ..()
	workspace = new(
		PAINTED_MASK_WIDTH,
		PAINTED_MASK_HEIGHT,
		color_mode = SPRITE_EDITOR_COLOR_MODE_RGB,
		config_flags = NONE,
		tool_flags = SPRITE_EDITOR_TOOL_PENCIL | SPRITE_EDITOR_TOOL_BUCKET | SPRITE_EDITOR_TOOL_ERASER
	)
	var/list/blank_frame = workspace.layers[1]["data"]["[SOUTH]"]
	for(var/i in 1 to PAINTED_MASK_HEIGHT)
		var/list/blank_row = GLOB.painted_mask_blank_grid[i]
		blank_frame[i] = blank_row.Copy()
	RegisterSignal(workspace, COMSIG_SPRITE_EDITOR_VALIDATE_COLOR, PROC_REF(validate_color))

/obj/item/clothing/mask/painted/Destroy()
	deltimer(rebuild_timer)
	QDEL_NULL(workspace)
	return ..()

/obj/item/clothing/mask/painted/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/clothing/mask/painted/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	ui_interact(user)
	return ITEM_INTERACT_SUCCESS

/obj/item/clothing/mask/painted/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Canvas", name)
		ui.open()

/obj/item/clothing/mask/painted/ui_data(mob/user)
	var/list/editor_data = workspace.sprite_editor_ui_data()
	var/obj/item/implement = user.get_active_hand()
	var/implement_color = get_paint_tool_color(implement)
	var/can_change_implement_color = can_change_paint_tool_color(implement)

	if(implement_color)
		editor_data["serverSelectedColor"] = implement_color
		editor_data["serverPalette"] = get_paint_tool_palette(implement)
		editor_data["maxServerColors"] = get_paint_tool_palette_capacity(implement)
		editor_data["onSelectServerColor"] = "onSelectColor"
		editor_data["onAddServerColor"] = "onAddPaletteColor"
		editor_data["onRemoveServerColor"] = "onRemovePaletteColor"
		if(can_change_implement_color)
			editor_data["toolFlags"] |= SPRITE_EDITOR_TOOL_DROPPER

	return list(
		"editorData" = editor_data,
		"pixelsPerUnit" = 8,
		"finalized" = FALSE,
		"allowColorPicker" = can_change_implement_color,
		"editable" = !isnull(implement_color),
	)

/obj/item/clothing/mask/painted/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	var/obj/item/implement = user.get_active_hand()
	var/datum/component/palette/palette_comp = implement?.GetComponent(/datum/component/palette)
	switch(action)
		if("spriteEditorCommand")
			. = TRUE
			if(params["command"] != "transaction")
				return

			if(!workspace.new_transaction(params["transaction"]))
				return

			rebuild_timer = addtimer(CALLBACK(src, PROC_REF(rebuild_art)), 1 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE)

		if("onSelectColor")
			. = TRUE
			implement?.set_painting_tool_color(copytext(params["color"], 1, 8))

		if("onAddPaletteColor")
			. = TRUE
			if(!palette_comp || length(palette_comp.colors) >= palette_comp.max_colors)
				return
			palette_comp.colors += copytext(params["color"], 1, 8)

		if("onRemovePaletteColor")
			. = TRUE
			if(!palette_comp)
				return
			var/color_index = params["index"]
			palette_comp.colors.Cut(color_index, color_index + 1)

		if("finalize")
			. = TRUE
			rebuild_art()
			SStgui.close_uis(src)

/obj/item/clothing/mask/painted/proc/validate_color(_source, paint_color)
	SIGNAL_HANDLER
	paint_color = copytext(paint_color, 1, 8)
	var/obj/item/implement = usr.get_active_hand()
	if(!implement || !((get_paint_tool_color(implement) == paint_color) || (paint_color in get_paint_tool_palette(implement))))
		return COLOR_IS_INVALID

/obj/item/clothing/mask/painted/proc/rebuild_art()
	var/icon/art = workspace.to_icon()
	if(!isicon(art))
		return

	var/icon/front = icon(PAINTED_MASK_BLANK_ICON, "nothing")
	front.Blend(art, ICON_OVERLAY, PAINTED_MASK_WORN_X, PAINTED_MASK_WORN_Y)

	var/icon/east = icon(DEFAULT_ICON_WEAR_MASK, PAINTED_MASK_STATE, EAST)
	var/icon/profile_silhouette = new(east)
	profile_silhouette.Blend("#ffffff", ICON_ADD)
	var/icon/profile_art = icon(PAINTED_MASK_BLANK_ICON, "nothing")
	profile_art.Blend(art, ICON_OVERLAY, PAINTED_MASK_WORN_X + PAINTED_MASK_SIDE_SHIFT, PAINTED_MASK_WORN_Y)
	profile_art.Blend(profile_silhouette, ICON_MULTIPLY)
	east.Blend(profile_art, ICON_OVERLAY)
	var/icon/west = new(east)
	west.Flip(WEST)

	var/icon/worn = icon(PAINTED_MASK_BLANK_ICON, "nothing")
	worn.Insert(front, PAINTED_MASK_STATE, dir = SOUTH)
	worn.Insert(icon(DEFAULT_ICON_WEAR_MASK, PAINTED_MASK_STATE, NORTH), PAINTED_MASK_STATE, dir = NORTH)
	worn.Insert(east, PAINTED_MASK_STATE, dir = EAST)
	worn.Insert(west, PAINTED_MASK_STATE, dir = WEST)
	onmob_sheets[ITEM_SLOT_MASK_STRING] = fcopy_rsc(worn)

	art.Scale(PAINTED_MASK_WIDTH * PAINTED_MASK_HELD_SCALE, PAINTED_MASK_HEIGHT * PAINTED_MASK_HELD_SCALE)
	var/icon/enlarged = icon(PAINTED_MASK_BLANK_ICON, "nothing")
	enlarged.Blend(art, ICON_OVERLAY, PAINTED_MASK_HELD_X, PAINTED_MASK_HELD_Y)
	var/icon/held = icon(PAINTED_MASK_BLANK_ICON, "nothing")
	held.Insert(enlarged, PAINTED_MASK_STATE)
	icon = fcopy_rsc(held)

	update_appearance()
	update_equipped_item()

#undef PAINTED_MASK_WIDTH
#undef PAINTED_MASK_HEIGHT
#undef PAINTED_MASK_WORN_X
#undef PAINTED_MASK_WORN_Y
#undef PAINTED_MASK_SIDE_SHIFT
#undef PAINTED_MASK_HELD_SCALE
#undef PAINTED_MASK_HELD_X
#undef PAINTED_MASK_HELD_Y
#undef PAINTED_MASK_STATE
#undef PAINTED_MASK_BLANK_ICON
