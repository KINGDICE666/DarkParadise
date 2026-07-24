GLOBAL_LIST_EMPTY(swarmer_radial_cache)

/**
 * Datum used in /mob/living/simple_animal/hostile/swarmer/combat mob
 *
 * Handles changing projectile vars and handles radial swap menu
 */
/datum/swarmer_proj_mode
	/// Our swarmer
	var/mob/living/simple_animal/hostile/swarmer/swarmer
	/// Cooldown of projectiles in this mode
	var/cooldown
	/// Amount of projectiles in this mode
	var/amount = 1
	/// Rapid fire delay in this mode
	var/rapid_fire_delay = 0
	/// Rapid fire spread
	var/rapid_fire_spread = 0
	/// Type of projectile in this mode
	var/proj_type = /obj/projectile/beam/disabler/swarmer
	/// Sound of shooting projectiles in this mode
	var/sound = 'sound/weapons/taser2.ogg'

/datum/swarmer_proj_mode/Destroy(force)
	swarmer = null
	return ..()

/// Links the mode to a swarmer
/datum/swarmer_proj_mode/proc/link_mode(mob/living/simple_animal/hostile/swarmer/linked_swarmer)
	swarmer = linked_swarmer

/// Applies the mode to swarmer
/datum/swarmer_proj_mode/proc/apply_mode()
	swarmer.projectiletype = proj_type
	swarmer.ranged_cooldown_time = cooldown
	swarmer.rapid_fire_delay = rapid_fire_delay
	swarmer.rapid_spread = rapid_fire_spread
	swarmer.rapid = amount
	swarmer.projectilesound = sound

/// Builds and returns radial menu data for mode switching
/datum/swarmer_proj_mode/proc/build_radial_data()
	var/list/other_modes = list()
	var/list/name_to_mode_type = list()
	for(var/mode_type in (subtypesof(/datum/swarmer_proj_mode) - type))
		var/datum/swarmer_proj_mode/mode = mode_type
		var/obj/projectile/projectile = mode::proj_type
		name_to_mode_type[projectile::name] = mode_type
		other_modes[projectile::name] = image(icon = projectile::icon, icon_state = projectile::icon_state)

	return list(other_modes, name_to_mode_type)

/// Shows radial menu and returns path of chosen mode
/datum/swarmer_proj_mode/proc/swap_radial_menu_to_path()
	if(!GLOB.swarmer_radial_cache[type])
		GLOB.swarmer_radial_cache[type] = build_radial_data()

	var/list/other_modes = GLOB.swarmer_radial_cache[type][1]
	var/list/name_to_mode_type = GLOB.swarmer_radial_cache[type][2]

	var/choice = show_radial_menu(swarmer, swarmer, other_modes)
	if(!choice)
		return
	return name_to_mode_type[choice]

/datum/swarmer_proj_mode/general
	cooldown = SWARMER_NORMAL_PROJECTILE_COOLDOWN
	proj_type = /obj/projectile/beam/disabler/swarmer/generalist

/datum/swarmer_proj_mode/double
	cooldown = SWARMER_DOUBLE_PROJECTILE_COOLDOWN
	proj_type = /obj/projectile/beam/disabler/swarmer/double
	amount = 2
	rapid_fire_delay = 0.2 SECONDS
	rapid_fire_spread = 5

/datum/swarmer_proj_mode/strong
	cooldown = SWARMER_STRONG_PROJECTILE_COOLDOWN
	proj_type = /obj/projectile/beam/disabler/swarmer/empowered

/datum/swarmer_proj_mode/sabotage
	cooldown = SWARMER_SABOTAGE_PROJECTILE_COOLDOWN
	proj_type = /obj/projectile/beam/disabler/swarmer/sabotage
