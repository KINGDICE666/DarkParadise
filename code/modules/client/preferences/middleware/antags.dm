#define ANTAGONIST_PREVIEW_ZOOM_SIZE 115
#define ANTAGONIST_PREVIEW_SHIFT_WEST 8
#define ANTAGONIST_PREVIEW_SHIFT_SOUTH 30
#define ANTAGONIST_PREVIEW_SPRITE_FIT 84

GLOBAL_LIST_INIT(antag_preference_icons, list(
	ROLE_ABDUCTOR = /mob/living/simple_animal/hostile/abductor,
	ROLE_BLOB = /obj/structure/blob/normal,
	ROLE_CHANGELING = /obj/item/melee/changeling/arm_blade,
	ROLE_BORER = /mob/living/simple_animal/borer,
	ROLE_CULTIST = /obj/item/melee/cultblade,
	ROLE_CLOCKER = /mob/living/simple_animal/hostile/clockwork/marauder,
	ROLE_DEMON = /mob/living/simple_animal/demon/slaughter,
	ROLE_DEVIL = /mob/living/carbon/true_devil,
	ROLE_GLITCH = /mob/living/basic/netguardian,
	ROLE_GSPIDER = /mob/living/simple_animal/hostile/poison/giant_spider,
	ROLE_GUARDIAN = /mob/living/simple_animal/hostile/guardian,
	ROLE_HERETIC = /obj/item/codex_cicatrix,
	ROLE_ELITE = /mob/living/simple_animal/hostile/asteroid/elite/legionnaire,
	ROLE_MALF_AI = /obj/structure/AIcore,
	ROLE_ESCAPING_PRISONER = /datum/outfit/prisoner,
	ROLE_MORPH = /mob/living/simple_animal/hostile/morph,
	ROLE_OPERATIVE = /obj/machinery/nuclearbomb,
	ROLE_PAI = /obj/item/paicard,
	ROLE_POSIBRAIN = /obj/item/mmi/robotic_brain/positronic,
	ROLE_REVENANT = /mob/living/simple_animal/revenant,
	ROLE_REV = /obj/item/flash,
	ROLE_SENTIENT = /mob/living/simple_animal/pet/dog/corgi,
	ROLE_SHADOWLING = /datum/outfit,
	ROLE_SPACE_DRAGON = /mob/living/simple_animal/hostile/space_dragon,
	ROLE_NINJA = /obj/item/clothing/mask/gas/space_ninja,
	ROLE_TERROR_SPIDER = /mob/living/simple_animal/hostile/poison/terror_spider/queen,
	ROLE_THIEF = /datum/outfit/antag_preview/thief,
	ROLE_THUNDERDOME = /datum/outfit/thunderdome,
	ROLE_TRADER = /datum/outfit/admin/sol_trader,
	ROLE_TRAITOR = /obj/item/card/emag,
	ROLE_VAMPIRE = /datum/outfit/admin/ancient_vampire,
	ROLE_VOX_RAIDER = /datum/outfit/vox/raider,
	ROLE_WIZARD = /obj/item/clothing/head/wizard,
	ROLE_ALIEN = /mob/living/carbon/alien/humanoid/hunter,
	ROLE_BINGLE = /mob/living/simple_animal/hostile/bingle,
))

GLOBAL_LIST_INIT(antag_preference_species, list(
	ROLE_SHADOWLING = /datum/species/shadow/ling,
	ROLE_VOX_RAIDER = /datum/species/vox,
))

/datum/outfit/antag_preview/thief
	name = "Thief (Preview only)"
	uniform = /obj/item/clothing/under/color/black
	gloves = /obj/item/clothing/gloves/color/black/thief
	mask = /obj/item/clothing/mask/balaclava
	shoes = /obj/item/clothing/shoes/color/black

/datum/preference_middleware/antags
	action_delegations = list(
		"set_antags" = PROC_REF(set_antags),
	)

/datum/preference_middleware/antags/get_ui_static_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	var/list/selected_antags = list()
	for(var/antag in preferences.be_special)
		selected_antags += serialize_antag_name(antag)

	var/list/antag_bans = list()
	var/list/antag_days_left = list()
	var/list/antag_playtime_left = list()
	var/banned_from_all = jobban_isbanned(user, ROLE_SYNDICATE)
	for(var/role in GLOB.special_roles)
		var/antag_key = serialize_antag_name(role)
		if(banned_from_all || jobban_isbanned(user, role))
			antag_bans += antag_key
			continue
		var/days_left = available_in_days_antag(user.client, role)
		if(days_left)
			antag_days_left[antag_key] = days_left
		var/playtime_left = role_available_in_playtime(user.client, role)
		if(playtime_left)
			antag_playtime_left[antag_key] = playtime_left

	return list(
		"selected_antags" = selected_antags,
		"antag_bans" = antag_bans,
		"antag_days_left" = antag_days_left,
		"antag_playtime_left" = antag_playtime_left,
	)

/datum/preference_middleware/antags/get_ui_assets()
	return list(get_asset_datum(/datum/asset/spritesheet_batched/antagonists))

/datum/preference_middleware/antags/proc/set_antags(list/params, mob/user)
	var/list/serialized_antags = get_serialized_antags()
	var/list/antags = list()
	for(var/sent_antag in params["antags"])
		var/special_role = serialized_antags[sent_antag]
		if(special_role)
			antags += special_role

	if(params["toggled"])
		preferences.be_special |= antags
	else
		preferences.be_special -= antags

	return FALSE

/datum/preference_middleware/antags/proc/get_serialized_antags()
	var/static/list/serialized_antags
	if(isnull(serialized_antags))
		serialized_antags = list()
		for(var/special_role in GLOB.special_roles)
			serialized_antags[serialize_antag_name(special_role)] = special_role
	return serialized_antags

/proc/serialize_antag_name(antag_name)
	return LOWER_TEXT(sanitize_css_class_name(antag_name))

/datum/asset/spritesheet_batched/antagonists
	name = "antagonists"

/datum/asset/spritesheet_batched/antagonists/create_spritesheets()
	for(var/role in GLOB.antag_preference_icons)
		var/icon_key = serialize_antag_name(role)
		var/icon_state = sanitize_css_class_name(role)
		if(icon_exists(ANTAGONIST_PREVIEW_ICON_FILE, icon_state))
			insert_icon(icon_key, uni_icon(ANTAGONIST_PREVIEW_ICON_FILE, icon_state))
			continue
		var/preview_source = GLOB.antag_preference_icons[role]
		var/datum/universal_icon/preview
		if(ispath(preview_source, /datum/outfit))
			preview = render_outfit_preview(preview_source, GLOB.antag_preference_species[role])
		else
			preview = render_sprite_preview(preview_source)
		if(preview)
			insert_icon(icon_key, preview)

/datum/asset/spritesheet_batched/antagonists/proc/render_outfit_preview(datum/outfit/outfit, datum/species/species)
	var/mob/living/carbon/human/dummy/dummy = new
	if(species)
		dummy.set_species(species)
	dummy.equipOutfit(outfit, visualsOnly = TRUE)
	dummy.regenerate_icons()
	var/datum/universal_icon/preview = get_flat_uni_icon(dummy)
	qdel(dummy)
	preview.scale(ANTAGONIST_PREVIEW_ZOOM_SIZE, ANTAGONIST_PREVIEW_ZOOM_SIZE)
	preview.shift(WEST, ANTAGONIST_PREVIEW_SHIFT_WEST)
	preview.shift(SOUTH, ANTAGONIST_PREVIEW_SHIFT_SOUTH)
	preview.crop(1, 1, ANTAGONIST_PREVIEW_ICON_SIZE, ANTAGONIST_PREVIEW_ICON_SIZE)
	return preview

/datum/asset/spritesheet_batched/antagonists/proc/render_sprite_preview(atom/atom_path)
	var/datum/universal_icon/sprite = get_display_icon_for(atom_path)
	if(!sprite)
		return
	var/icon/flat = icon(sprite.icon_file, sprite.icon_state, SOUTH, 1)
	var/left = flat.Width()
	var/bottom = flat.Height()
	var/right = 0
	var/top = 0
	for(var/x in 1 to flat.Width())
		for(var/y in 1 to flat.Height())
			if(isnull(flat.GetPixel(x, y)))
				continue
			left = min(left, x)
			right = max(right, x)
			bottom = min(bottom, y)
			top = max(top, y)
	if(!right)
		return
	var/zoom = ANTAGONIST_PREVIEW_SPRITE_FIT / max(right - left + 1, top - bottom + 1)
	var/width = round((right - left + 1) * zoom, 1)
	var/height = round((top - bottom + 1) * zoom, 1)
	sprite.crop(left, bottom, right, top)
	sprite.scale(width, height)
	var/datum/universal_icon/preview = uni_icon('icons/blanks/96x96.dmi', "nothing")
	preview.blend_icon(sprite, ICON_OVERLAY, 1 + round((ANTAGONIST_PREVIEW_ICON_SIZE - width) / 2), 1 + round((ANTAGONIST_PREVIEW_ICON_SIZE - height) / 2))
	return preview

#undef ANTAGONIST_PREVIEW_ZOOM_SIZE
#undef ANTAGONIST_PREVIEW_SHIFT_WEST
#undef ANTAGONIST_PREVIEW_SHIFT_SOUTH
#undef ANTAGONIST_PREVIEW_SPRITE_FIT
