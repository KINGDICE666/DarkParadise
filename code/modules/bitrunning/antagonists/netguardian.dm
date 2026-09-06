/datum/antagonist/bitrunning_glitch/netguardian
	name = "NetGuardian Prime"
	antag_menu_name = "НетГвардеец"
	threat = BITRUNNER_THREAT_NETGUARDIAN

/mob/living/basic/netguardian
	name = "netguardian prime"
	desc = "Последняя линия обороны от органического вторжения. Кажется, он вам не рад."
	icon = 'icons/mob/netguardian.dmi'
	icon_state = "netguardian"
	icon_living = "netguardian"
	icon_dead = "crash"
	base_pixel_x = -8
	base_pixel_y = -8
	pixel_x = -8
	pixel_y = -8
	gender = NEUTER
	mob_size = MOB_SIZE_LARGE
	health = 500
	maxHealth = 500
	melee_damage = 55
	obj_damage = 60
	armour_penetration = 30
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_verb_continuous = "просверливает"
	attack_verb_simple = "просверлили"
	attack_sound = 'sound/weapons/drill.ogg'
	speak_emote = list("заявляет")
	faction = list("boss", "hivebot", "hostile", "spiders", "alien", "syndicate", ROLE_GLITCH)
	minimum_survivable_temperature = TCMB
	maximum_survivable_temperature = INFINITY
	unsuitable_atmos_damage = 0
	ai_controller = /datum/ai_controller/basic_controller/netguardian

/mob/living/basic/netguardian/get_ru_names()
	return alist(
		NOMINATIVE = "нетгвардеец прайм",
		GENITIVE = "нетгвардейца прайм",
		DATIVE = "нетгвардейцу прайм",
		ACCUSATIVE = "нетгвардейца прайм",
		INSTRUMENTAL = "нетгвардейцем прайм",
		PREPOSITIONAL = "нетгвардейце прайм",
	)

/mob/living/basic/netguardian/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ranged_attacks, /obj/item/ammo_casing/c46x30mm, 'sound/weapons/gunshots/1c20.ogg')

	var/obj/effect/proc_holder/spell/netguardian_rockets/rockets = new
	AddSpell(rockets)
	ai_controller.set_blackboard_key(BB_TARGETED_ACTION, rockets)
	update_icon(UPDATE_OVERLAYS)

/mob/living/basic/netguardian/death(gibbed)
	do_sparks(3, FALSE, src)
	playsound(src, 'sound/mecha/weapdestr.ogg', 100, TRUE)
	return ..()

/mob/living/basic/netguardian/update_overlays()
	. = ..()
	if(stat == DEAD)
		return

	. += emissive_appearance(icon, "netguardian_emissive", src)

/obj/effect/proc_holder/spell/netguardian_rockets
	name = "2E Rocket Launcher"
	desc = "Накрывает цель залпом ракет."
	base_cooldown = 30 SECONDS
	clothes_req = FALSE
	human_req = FALSE
	action_icon_state = "explosion"
	var/rocket_type = /obj/projectile/bullet/a84mm_he
	var/shot_count = 3
	var/shot_spread = 15

/obj/effect/proc_holder/spell/netguardian_rockets/create_new_targeting()
	var/datum/spell_targeting/clicked_atom/targeting = new
	targeting.range = 12
	return targeting

/obj/effect/proc_holder/spell/netguardian_rockets/cast(list/targets, mob/living/user = usr)
	var/atom/target = targets[1]
	if(isnull(target))
		return FALSE

	playsound(user, 'sound/mecha/skyfall_power_up.ogg', 120, TRUE)
	user.say("цель захвачена.")

	var/list/warning_overlays = list(
		mutable_appearance(user.icon, "scan"),
		mutable_appearance(user.icon, "rockets"),
		emissive_appearance(user.icon, "scan", user),
	)
	user.add_overlay(warning_overlays)

	. = do_after(user, 1.5 SECONDS, target = user)
	user.cut_overlay(warning_overlays)
	if(!.)
		return FALSE

	var/base_angle = get_angle(user, target)
	for(var/shot in 1 to shot_count)
		var/obj/projectile/rocket = new rocket_type(get_turf(user))
		rocket.current = get_turf(user)
		rocket.original = target
		rocket.firer = user
		rocket.preparePixelProjectile(target, user)
		rocket.fire(base_angle + rand(-shot_spread, shot_spread))

	return TRUE

/datum/ai_controller/basic_controller/netguardian
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targetting_datum/basic,
	)
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/targeted_mob_ability/continue_planning,
		/datum/ai_planning_subtree/basic_ranged_attack_subtree/netguardian,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/datum/ai_planning_subtree/basic_ranged_attack_subtree/netguardian
	ranged_attack_behavior = /datum/ai_behavior/basic_ranged_attack/netguardian

/datum/ai_behavior/basic_ranged_attack/netguardian
	action_cooldown = 1 SECONDS
