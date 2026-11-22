#define PORTAL_MAX_DURATION 1000000
#define PORTAL_MAX_ENTRIES 10000000
#define PORTAL_MAX_DMI_BYTES (16 * 1024 * 1024)

/datum/buildmode_portal_settings
	var/sprite = 'icons/obj/weapons/portal_gun.dmi'
	var/sprite_name = "Rick-style"
	var/sprite_state = "portal"
	var/instability = TRUE
	var/effects = TRUE
	/// Seconds. Zero represents an unlimited duration.
	var/duration = 0
	/// Zero represents an unlimited number of entries.
	var/limit = 0
	var/allow_characters = TRUE
	var/allow_animals = TRUE
	var/allow_mechs = TRUE
	var/allow_items = TRUE
	var/count_cargo = FALSE
	var/bring_dragged = FALSE
	var/preview_sprite
	var/preview_state
	var/sprite_preview

/datum/buildmode_portal_settings/proc/get_sprite_preview()
	if(preview_sprite == sprite && preview_state == sprite_state)
		return sprite_preview
	preview_sprite = sprite
	preview_state = sprite_state
	var/icon/preview = icon(sprite, sprite_state, dir = SOUTH, frame = 1)
	if(!isicon(preview))
		sprite_preview = null
		return null
	var/size = max(preview.Width(), preview.Height())
	if(size > 96)
		preview.Scale(max(1, round(preview.Width() * 96 / size)), max(1, round(preview.Height() * 96 / size)))
	sprite_preview = icon2base64(preview)
	return sprite_preview

/datum/buildmode_portal_settings/New(datum/buildmode_portal_settings/source)
	. = ..()
	if(!source)
		return
	sprite = source.sprite
	sprite_name = source.sprite_name
	sprite_state = source.sprite_state
	instability = source.instability
	effects = source.effects
	duration = source.duration
	limit = source.limit
	allow_characters = source.allow_characters
	allow_animals = source.allow_animals
	allow_mechs = source.allow_mechs
	allow_items = source.allow_items
	count_cargo = source.count_cargo
	bring_dragged = source.bring_dragged

/datum/buildmode_portal_settings/proc/allows_entry(atom/movable/traveler)
	if(isanimal(traveler))
		return allow_animals
	if(isliving(traveler))
		return allow_characters
	if(ismecha(traveler))
		return allow_mechs
	return isitem(traveler) && allow_items

/obj/effect/portal/rick/buildmode
	force_teleport = TRUE
	ignore_tele_proof_area_setting = TRUE
	var/datum/buildmode_portal_settings/settings
	var/datum/weakref/partner_ref
	var/lifespan_timer
	var/entries_used = 0
	var/traversing = FALSE

/obj/effect/portal/rick/buildmode/Initialize(mapload, turf/target = null, obj/creation_object = null, lifespan = 30 SECONDS, mob/creation_mob = null, create_sparks = FALSE, datum/buildmode_portal_settings/config)
	. = ..()
	apply_settings(config)

/obj/effect/portal/rick/buildmode/Destroy()
	if(lifespan_timer)
		deltimer(lifespan_timer)
		lifespan_timer = null
	var/obj/effect/portal/rick/buildmode/partner = partner_ref?.resolve()
	partner_ref = null
	if(!QDELETED(partner))
		partner.partner_ref = null
		qdel(partner)
	QDEL_NULL(settings)
	return ..()

/obj/effect/portal/rick/buildmode/proc/apply_settings(datum/buildmode_portal_settings/source)
	QDEL_NULL(settings)
	settings = new(source)
	refresh_settings()

/obj/effect/portal/rick/buildmode/proc/refresh_settings()
	icon = settings.sprite
	base_icon_state = settings.sprite_state
	entry_effects = settings.effects
	ignore_bluespace_interference = !settings.instability
	update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)

/obj/effect/portal/rick/buildmode/update_overlays()
	if("[base_icon_state]_lightmask" in icon_states(icon))
		return ..()
	return list()

/obj/effect/portal/rick/buildmode/proc/restart_lifespan()
	if(lifespan_timer)
		deltimer(lifespan_timer)
		lifespan_timer = null
	if(target && settings.duration)
		lifespan_timer = QDEL_IN_STOPPABLE(src, settings.duration SECONDS)

/obj/effect/portal/rick/buildmode/can_teleport(atom/movable/mover, silent = FALSE)
	return ..() && settings?.allows_entry(mover)

/obj/effect/portal/rick/buildmode/teleport(atom/movable/traveler)
	if(traversing || !can_teleport(traveler))
		return FALSE

	var/mob/living/character = isliving(traveler) ? traveler : null
	var/atom/movable/dragged = settings.bring_dragged ? traveler.pulling : null
	if(dragged && (dragged.anchored || !isturf(dragged.loc) || !traveler.Adjacent(dragged) || !can_teleport(dragged) || HAS_TRAIT(dragged, TRAIT_NO_TELEPORT)))
		dragged = null
	var/atom/drag_origin = dragged?.loc

	var/cost = 1
	var/cargo_cost = 0
	if(settings.count_cargo)
		cost += length(character?.get_all_gear())
		cargo_cost = !!dragged
		if(isliving(dragged))
			var/mob/living/dragged_character = dragged
			cargo_cost += length(dragged_character.get_all_gear())
	if(settings.limit && entries_used + cost + cargo_cost > settings.limit)
		if(character)
			to_chat(character, span_warning("The portal has too few uses left for this crossing."))
		return FALSE

	traversing = TRUE
	var/turf/origin = get_turf(traveler)
	. = ..()
	if(QDELETED(src))
		return .
	var/turf/arrival = get_turf(traveler)
	if(!. || !arrival || origin == arrival)
		traversing = FALSE
		return FALSE

	if(!QDELETED(dragged) && dragged.loc == drag_origin)
		if(do_teleport(dragged, arrival, bypass_area_flag = ignore_tele_proof_area_setting, ignore_bluespace_interference = TRUE, no_effects = TRUE) && get_turf(dragged) == arrival)
			cost += cargo_cost
	if(QDELETED(src))
		return TRUE
	traversing = FALSE
	if(settings.limit)
		entries_used += cost
		if(entries_used >= settings.limit)
			qdel(src)

/datum/buildmode_mode/link/ui_state(mob/user)
	return ADMIN_STATE(R_BUILDMODE)

/datum/buildmode_mode/link/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BuildModePortal", "Link Portal Settings")
		ui.open()

/datum/buildmode_mode/link/proc/portal_sprites()
	var/static/list/sprites = list(
		"Rick-style" = list('icons/obj/weapons/portal_gun.dmi', "portal"),
		"Bluespace" = list('icons/obj/stationobjs.dmi', "portal"),
		"Redspace" = list('icons/obj/stationobjs.dmi', "portal-syndicate"),
		"Wormhole projector (blue)" = list('icons/obj/stationobjs.dmi', "portal-projector0"),
		"Wormhole projector (orange)" = list('icons/obj/stationobjs.dmi', "portal-projector1"),
		"Wormhole" = list('icons/obj/objects.dmi', "anom"),
		"Jaunt tunnel" = list('icons/effects/effects.dmi', "bhole3"),
		"Heretic lock portal" = list('icons/effects/eldritch.dmi', "realitycrack"),
		"Carp rift" = list('icons/obj/carp_rift.dmi', "carp_rift"),
		"Carp rift (spawning)" = list('icons/obj/carp_rift.dmi', "carp_rift_carpspawn"),
		"Carp rift (charged)" = list('icons/obj/carp_rift.dmi', "carp_rift_charged"),
		"Cascade exit rift" = list('icons/effects/224x224.dmi', "reality"),
		"Bluespace research rift" = list('icons/obj/engines_and_power/singularity.dmi', "singularity_fog"),
	)
	return sprites

/datum/buildmode_mode/link/ui_static_data(mob/user)
	return list("presets" = assoc_to_keys(portal_sprites()), "maxDuration" = PORTAL_MAX_DURATION, "maxEntries" = PORTAL_MAX_ENTRIES)

/datum/buildmode_mode/link/ui_data(mob/user)
	var/obj/effect/portal/rick/buildmode/portal = editing_portal_ref?.resolve()
	var/datum/buildmode_portal_settings/settings = portal ? portal.settings : portal_defaults
	// Build a regular list for JSON serialization instead of sending the icon_states() result directly.
	var/list/sprite_states = list()
	for(var/sprite_state in icon_states(settings.sprite))
		sprite_states.Add(sprite_state)
	return list(
		"editing" = !!editing_portal_ref,
		"missing" = !!editing_portal_ref && !portal,
		"location" = portal ? AREACOORD(portal) : null,
		"clipboard" = !!portal_clipboard,
		"sprite" = settings.sprite_name,
		"spriteState" = settings.sprite_state,
		"spritePreview" = settings.get_sprite_preview(),
		"spriteStates" = sprite_states,
		"instability" = settings.instability,
		"effects" = settings.effects,
		"duration" = settings.duration,
		"limit" = settings.limit,
		"used" = portal?.entries_used,
		"allowCharacters" = settings.allow_characters,
		"allowAnimals" = settings.allow_animals,
		"allowMechs" = settings.allow_mechs,
		"allowItems" = settings.allow_items,
		"countCargo" = settings.count_cargo,
		"bringDragged" = settings.bring_dragged,
	)

/datum/buildmode_mode/link/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..() || ui.user.client != BM?.holder || BM.mode != src)
		return FALSE
	if(action == "defaults")
		editing_portal_ref = null
		return TRUE
	var/datum/weakref/context = editing_portal_ref
	var/obj/effect/portal/rick/buildmode/portal = context?.resolve()
	if(context && !portal)
		return FALSE
	var/datum/buildmode_portal_settings/settings = portal ? portal.settings : portal_defaults

	switch(action)
		if("upload")
			var/uploaded = input(ui.user, "Choose a DMI from your local game files.", "Portal Sprite") as null|file
			if(!uploaded || QDELETED(src) || QDELETED(ui) || QDELETED(settings) || editing_portal_ref != context || ui.user.client != BM?.holder || !check_rights(R_BUILDMODE, FALSE, ui.user))
				return FALSE
			if(LOWER_TEXT(copytext("[uploaded]", -4)) != ".dmi" || length(uploaded) > PORTAL_MAX_DMI_BYTES)
				to_chat(ui.user, span_warning("Select a DMI file up to 16 MiB."))
				return FALSE
			var/list/states
			try
				states = icon_states(uploaded)
			catch
				states = null
			if(!length(states))
				to_chat(ui.user, span_warning("That DMI has no readable icon states."))
				return FALSE
			settings.sprite = fcopy_rsc(uploaded)
			settings.sprite_name = "[uploaded]"
			settings.sprite_state = states[1]
		if("preset")
			var/name = params["value"]
			var/list/presets = portal_sprites()
			if(!istext(name) || !(name in presets))
				return FALSE
			var/list/sprite = presets[name]
			settings.sprite = sprite[1]
			settings.sprite_state = sprite[2]
			settings.sprite_name = name
		if("state")
			var/new_state = params["value"]
			if(!istext(new_state) || !(new_state in icon_states(settings.sprite)))
				return FALSE
			settings.sprite_state = new_state
		if("duration", "limit")
			var/value = params["value"]
			if(!IS_FINITE(value) || value < 0)
				return FALSE
			if(action == "duration")
				settings.duration = clamp(round(value), 0, PORTAL_MAX_DURATION)
				portal?.restart_lifespan()
			else
				settings.limit = clamp(round(value), 0, PORTAL_MAX_ENTRIES)
				if(portal)
					portal.entries_used = 0
		if("instability")
			settings.instability = !settings.instability
		if("effects")
			settings.effects = !settings.effects
		if("allow_characters")
			settings.allow_characters = !settings.allow_characters
		if("allow_animals")
			settings.allow_animals = !settings.allow_animals
		if("allow_mechs")
			settings.allow_mechs = !settings.allow_mechs
		if("allow_items")
			settings.allow_items = !settings.allow_items
		if("count_cargo")
			settings.count_cargo = !settings.count_cargo
		if("bring_dragged")
			settings.bring_dragged = !settings.bring_dragged
		if("copy")
			QDEL_NULL(portal_clipboard)
			portal_clipboard = new(settings)
			return TRUE
		if("paste")
			if(!portal_clipboard)
				return FALSE
			if(portal)
				portal.apply_settings(portal_clipboard)
				portal.entries_used = 0
				portal.restart_lifespan()
			else
				QDEL_NULL(portal_defaults)
				portal_defaults = new(portal_clipboard)
		if("close")
			if(!portal)
				return FALSE
			close_portal(ui.user, portal)
			return TRUE
		else
			return FALSE

	if(portal)
		portal.refresh_settings()
		log_admin("Build Mode: [key_name(ui.user)] changed portal settings ([action]) at [AREACOORD(portal)].")
	return TRUE

#undef PORTAL_MAX_DURATION
#undef PORTAL_MAX_ENTRIES
#undef PORTAL_MAX_DMI_BYTES
