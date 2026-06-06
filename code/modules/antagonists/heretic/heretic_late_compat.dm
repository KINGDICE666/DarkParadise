/proc/get_freeway_ranged_target_turf(atom/target_atom, direction, range, min_range = 0)
	var/result_loc = get_turf(target_atom)
	for(var/moved_len = 0; moved_len < range; moved_len++)
		var/turf/target_turf = get_ranged_target_turf(target_atom, direction, moved_len + 1)
		var/blocked = iswallturf(target_turf)
		var/checked = 0

		for(var/obj/checked_object in target_turf)
			if(checked++ > 20)
				break
			if(checked_object.density)
				blocked = TRUE
				break

		if(!blocked)
			result_loc = target_turf
			continue

		if(moved_len < min_range)
			return
		break

	return result_loc

/proc/is_jaunting(atom/movable/checked_atom)
	return istype(checked_atom?.loc, /obj/effect/dummy/spell_jaunt)

/proc/can_see(atom/source, atom/target, length = 5)
	return source?.can_see(target, length)

/datum/proc/AddElementTrait(trait, source, datum/element/eletype, ...)
	if(!ispath(eletype, /datum/element))
		CRASH("AddElementTrait called, but [eletype] is not of a /datum/element path")

	ADD_TRAIT(src, trait, source)
	if(HAS_TRAIT_NOT_FROM(src, trait, source))
		return

	var/list/arguments = list(eletype)
	if(length(args) > 3)
		arguments += args.Copy(4)

	_AddElement(arguments.Copy())
	var/datum/element/element = SSdcs.GetElement(arguments)
	element.RegisterSignal(src, SIGNAL_REMOVETRAIT(trait), TYPE_PROC_REF(/datum/element, _detach_on_trait_removed))

/datum/element/proc/_detach_on_trait_removed(datum/source, trait)
	SIGNAL_HANDLER
	Detach(source)
	UnregisterSignal(source, SIGNAL_REMOVETRAIT(trait))

/mob/living/proc/can_block_magic(magic_flags = MAGIC_RESISTANCE, charge_cost = 0)
	return FALSE

/mob/living/proc/unequip_everything()
	drop_all_held_items()
	return TRUE

/mob/living/proc/AdjustAllImmobility(amount, updating = TRUE)
	if(amount > 0)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, HERETIC_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, HERETIC_TRAIT)
	return TRUE

/mob/living/proc/adjustOrganLoss(slot, amount, maximum = INFINITY, required_organ_flag = NONE)
	return adjust_organ_loss(slot, amount, maximum, required_organ_flag)

/mob/living/proc/cause_hallucination(hallucination_type, key, duration, affects_us = TRUE, affects_others = FALSE)
	var/datum/hallucination/delusion/preset/preset = new hallucination_type()
	var/hallucination_duration = duration || preset.duration
	var/image/hallucination_image = preset.make_delusion_image(src)
	return new /obj/effect/hallucination/delusion(
		get_turf(src),
		src,
		duration = hallucination_duration,
		skip_nearby = !affects_others,
		custom_icon = hallucination_image?.icon_state,
		custom_icon_file = hallucination_image?.icon,
	)

/mob/living/proc/add_stun_absorption(source, message, self_message, examine_message, max_seconds_of_stuns_blocked, delete_after_passing_max, recharge_time)
	return

/mob/living/proc/CanSuccumb()
	return stat == UNCONSCIOUS

/mob/living/carbon/proc/get_covered_body_zones()
	return 0

/mob/living/carbon/proc/gain_trauma(datum/brain_trauma/trauma, resilience, ...)
	return FALSE

/mob/living/carbon/proc/cure_trauma_type(brain_trauma_type = /datum/brain_trauma, resilience)
	return FALSE

/mob/living/carbon/proc/get_held_items()
	return list(l_hand, r_hand)

/obj/projectile/proc/is_hostile_projectile(mob/living/target)
	return TRUE

/datum/reagent/proc/isroboticorgan(obj/item/organ/organ)
	return FALSE

/proc/isroboticorgan(obj/item/organ/organ)
	return FALSE

/datum/reality_smash_tracker/proc/is_centcomm(turf/location)
	return istype(get_area(location), /area/centcom)

/datum/gas_mixture/proc/return_temperature()
	return temperature()

/atom/proc/return_air()
	var/turf/location = get_turf(src)
	return location?.return_air()

/turf/return_air()
	return get_readonly_air()

/turf/simulated/proc/assume_air(datum/gas_mixture/giver)
	var/datum/gas_mixture/turf_air = private_unsafe_get_air()
	turf_air.merge(giver)

/turf/simulated/proc/air_update_turf()
	update_visuals()

/obj/proc/freeze_add()
	return TRUE

/obj/effect/dummy/spell_jaunt/proc/eject_jaunter()
	SEND_SIGNAL(src, COMSIG_MOB_EJECTED_FROM_JAUNT)
	qdel(src)


/datum/ai_controller/proc/set_blackboard_key(key, value)
	blackboard[key] = value
	SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_SET(key))

/datum/ai_controller/proc/set_blackboard_key_assoc(key, thing, value)
	if(!islist(blackboard[key]))
		blackboard[key] = list()
	var/list/associated = blackboard[key]
	associated[thing] = value

/datum/ai_controller/proc/add_blackboard_key_assoc(key, thing, value)
	if(!islist(blackboard[key]))
		blackboard[key] = list()
	var/list/associated = blackboard[key]
	associated[thing] += value

/datum/ai_controller/proc/remove_thing_from_blackboard_key(key, thing)
	if(islist(blackboard[key]))
		var/list/associated = blackboard[key]
		associated -= thing

/datum/ai_controller/proc/clear_blackboard_key(key)
	blackboard -= key
	SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_CLEARED(key))

/datum/ai_controller/proc/blackboard_key_exists(key)
	return !isnull(blackboard[key])

/datum/ai_behavior/proc/set_movement_target(datum/ai_controller/controller, target, datum/ai_movement/new_movement_type)
	controller.current_movement_target = target
	if(new_movement_type)
		controller.change_ai_movement_type(new_movement_type)

/datum/radial_menu/persistent
	var/uniqueid
	var/datum/callback/select_proc_callback

/datum/radial_menu/persistent/Destroy(force)
	if(uniqueid)
		GLOB.radial_menus -= uniqueid
	return ..()

/datum/radial_menu/persistent/proc/change_choices(list/choices, tooltips = FALSE, keep_same_page = TRUE)
	set_choices(choices)
	update_screen_objects()

/datum/radial_menu/persistent/element_chosen(choice_id, mob/user)
	. = ..()
	select_proc_callback?.Invoke(selected_choice, null)

/mob/living/simple_animal/hostile/construct
	var/seeking
	var/mob/construct_master = null

/proc/is_phase_allowed(z_level)
	return TRUE

/obj/item/organ/external/proc/dismember(dam_type = BRUTE, silent = TRUE)
	qdel(src)
	return TRUE

/obj/item/organ/proc/set_organ_damage(amount = 0, silent = 0)
	damage = amount
	return TRUE

/mob/living/proc/mob_light2(range, power, color, duration, light_type = /obj/effect/dummy/lighting_obj/moblight)
	set_light(range, power, color)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, set_light), 0), duration)

/obj/item/melee/touch_attack/proc/remove_hand_with_no_refund(mob/holder)
	if(holder)
		holder.drop_item_ground(src, force = TRUE)
	qdel(src)

/obj/item/proc/visual_equipped(mob/living/carbon/human/user, slot)
	return

/obj/item/proc/pick_painting_tool_color(mob/living/carbon/human/user, default_color)
	var/chosen_color = input(user, "Pick new color", "[src]", default_color) as color|null
	if(!chosen_color || QDELETED(src) || IS_DEAD_OR_INCAP(user) || !user.is_holding(src))
		return
	set_painting_tool_color(chosen_color)

/obj/item/proc/set_painting_tool_color(chosen_color)
	SEND_SIGNAL(src, COMSIG_PAINTING_TOOL_SET_COLOR, chosen_color)

/atom/proc/bicon()
	return icon2html(src, viewers(src))

/atom/proc/get_examine_time()
	return 0 SECONDS

/datum/crafting_recipe/proc/spawn_result(list/result_list, mob/user)
	for(var/result in result_list)
		var/count = result_list[result]
		for(var/i in 1 to count)
			new result(get_turf(user))

/obj/structure/trap/proc/on_entered(datum/source, atom/movable/victim)
	if(isliving(victim))
		trap_effect(victim)

/obj/structure/trap/proc/trap_effect(mob/living/victim)
	return

/mob/living/carbon/human/proc/needs_heart()
	return TRUE

/obj/proc/container_resist(mob/living/user)
	return container_resist_act(user)

/obj/proc/unfreeze()
	SEND_SIGNAL(src, COMSIG_OBJ_UNFREEZE)

/obj/effect/proc_holder/spell/proc/on_spell_loss(mob/user = usr)
	return

/obj/effect/proc_holder/spell/proc/can_add(mob/granted)
	return TRUE

/obj/effect/proc_holder/spell/proc/get_things_to_cast_on(mob/user)
	return targeting.choose_targets(user, src)

/obj/effect/proc_holder/spell/aoe/get_things_to_cast_on(atom/center, radius_override)
	return targeting.choose_targets(action.owner, src, null, center)

/obj/effect/proc_holder/spell/proc/update_status_on_signal()
	return action?.update_status_on_signal()

/obj/effect/proc_holder/spell/pointed/proc/on_activation(mob/on_who)
	return

/obj/effect/proc_holder/spell/pointed/proc/aim_assist(mob/living/clicker, atom/target)
	if(!isturf(target))
		return

	return locate(/mob/living/carbon/human) in target || locate(/mob/living) in target

/obj/effect/proc_holder/spell/shapeshift/proc/create_shapeshift_mob(atom/loc)
	return new shapeshift_type(loc)

/obj/effect/proc_holder/spell/jaunt/proc/is_jaunting(mob/living/target)
	return is_jaunting(target)

/obj/effect/proc_holder/spell/pointed/projectile/proc/fire_projectile(atom/target)
	current_amount--
	return TRUE

/obj/effect/proc_holder/spell/pointed/projectile/proc/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	return to_fire

/obj/effect/dummy/spell_jaunt
	var/mob/living/jaunter

/obj/effect/lock_portal/proc/is_phase_allowed(atom/movable/mover)
	return TRUE

/datum/status_effect/freon/lasting
	id = "lasting_frozen"
	duration = -1
