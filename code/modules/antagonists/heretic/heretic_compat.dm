/// Orders heretic knowledge by priority for shop/tree display.
/proc/cmp_heretic_knowledge(datum/heretic_knowledge/knowledge_a, datum/heretic_knowledge/knowledge_b)
	return initial(knowledge_b.priority) - initial(knowledge_a.priority)

/proc/dir2rustext_where(direction)
	return "на [dir2rustext(direction)]е"

/datum/objective/proc/update_explanation_text()
	return

/datum/game_mode
	var/list/heretics = list()

/datum/brain_trauma
	var/name
	var/scan_desc
	var/gain_text
	var/lose_text
	var/random_gain = TRUE

/obj/item/melee/cultblade
	var/free_use = FALSE

/datum/action
	var/icon_icon

/obj/structure/trap
	var/time_between_triggers
	var/sparks
	var/charges

/obj/structure/destructible
	var/break_sound
	var/break_message

/datum/ai_planning_subtree
	var/list/operational_datums = null

/datum/antagonist/proc/on_removal()
	return

/datum/antagonist/proc/add_team_hud(mob/target, antag_to_check)
	if(!target)
		return

	target.add_alt_appearance(
		/datum/atom_hud/alternate_appearance/basic/has_antagonist,
		"antag_team_hud_[UID()]",
		add_antag_hud(target),
		antag_to_check || type,
		get_team() && WEAKREF(get_team()),
	)

/**
 * Causes effects when the atom gets hit by a rust effect from heretics.
 *
 * Override this for custom behaviour on atoms that should react differently.
 */
/atom/proc/rust_heretic_act(rust_strength = 1)
	return

/// Wrapper proc that passes our mob's rust_strength to the target we are rusting.
/mob/proc/do_rust_heretic_act(atom/target)
	var/datum/antagonist/heretic/heretic_data = mind?.has_antag_datum(/datum/antagonist/heretic)
	target.rust_heretic_act(heretic_data?.rust_strength)

/mob/living/simple_animal/hostile/heretic_summon/rust_walker/do_rust_heretic_act(atom/target)
	target.rust_heretic_act(4)

/turf/rust_heretic_act(rust_strength = 1)
	rust_turf()
	name = initial(name)
	desc = initial(desc)

/obj/structure/rust_heretic_act(rust_strength = 1)
	take_damage(500, BRUTE, "melee", 1)
