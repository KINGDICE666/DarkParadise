/// Heretic signals

#define COMSIG_GET_DREAMS "get_dreams"
#define COMSIG_LIVING_CULT_SACRIFICED "living_cult_sacrificed"
#define COMSIG_MOB_BEFORE_SPELL_CAST "mob_spell_pre_cast"
#define COMSIG_MOB_SPELL_ACTIVATED "mob_spell_active"
#define COMSIG_ORGAN_BEING_REPLACED "organ_being_replaced"
#define COMSIG_ORGAN_SURGICALLY_REMOVED "organ_surgically_removed"
#define COMSIG_CAN_Z_MOVE "can_z_move"
#define COMSIG_LADDER_TRAVEL "ladder_travel"
#define COMSIG_MOVABLE_POST_TELEPORT "movable_post_teleport"
#define COMSIG_ATOM_WAS_ATTACKED "atom_was_attacked"
#define COMSIG_ATOM_ATTACKEDBY COMSIG_ATOM_ATTACKBY
#define COMSIG_PARENT_ATTACKBY COMSIG_ATOM_ATTACKBY
#define COMSIG_ATOM_ATTACK_MECH "atom_attack_mech"
#define COMSIG_TOUCH_HANDLESS_CAST "touch_handless_cast"
#define COMSIG_PARENT_EXAMINE COMSIG_ATOM_EXAMINE
#define COMSIG_ON_HIT_EFFECT "on_hit_effect"
#define COMSIG_LIVING_WALL_BUMP "living_wall_bump"
#define COMSIG_LIVING_WALL_EXITED "living_wall_exited"
#define COMSIG_ATOM_HOLYATTACK "atom_holyattack"
#define COMSIG_BEING_STRIPPED "being_stripped"
#define COMSIG_CARBON_CUFF_PREVENT "carbon_cuff_prevent"
#define COMSIG_MOB_TRIED_ACCESS "mob_tried_access"
#define COMSIG_CARBON_POST_ATTACH_LIMB "carbon_post_attach_limb"
#define COMSIG_CARBON_POST_REMOVE_LIMB "carbon_post_remove_limb"
#define COMSIG_MOB_EQUIPPED_ITEM "mob_equipped_item"
#define COMSIG_MOB_ENSLAVED_TO "mob_enslaved_to"
#define COMSIG_MOB_EJECTED_FROM_JAUNT "spell_mob_eject_jaunt"
#define COMSIG_ITEM_HARVESTED_SOMEBODY "item_harvested_somebody"
#define COMSIG_MINDSHIELD_IMPLANTED "mindshield_implanted"
#define COMSIG_MOB_GAINED_CHAIN_TAIL "living_gained_chain_tail"
#define COMSIG_MOB_LOST_CHAIN_TAIL "living_detached_chain_tail"
#define COMSIG_MOB_CHAIN_CONTRACT "living_chain_contracted"
#define COMSIG_LIVING_ADJUST_BRUTE_DAMAGE "living_adjust_brute_damage"
#define COMSIG_LIVING_ADJUST_BURN_DAMAGE "living_adjust_burn_damage"
#define COMSIG_LIVING_ADJUST_OXY_DAMAGE "living_adjust_oxy_damage"
#define COMSIG_LIVING_ADJUST_TOX_DAMAGE "living_adjust_tox_damage"
#define COMSIG_LIVING_ADJUST_STAMINA_DAMAGE "living_adjust_stamina_damage"
#define COMSIG_CARBON_LIMB_DAMAGED "carbon_limb_damaged"
#define COMSIG_LIVING_BEFRIENDED "living_befriended"
#define COMSIG_LIVING_UNFRIENDED "living_unfriended"
#define COMSIG_ATOM_RELAYMOVE "atom_relaymove"
#define COMSIG_BIBLE_SMACKED "bible_smacked"
#define COMSIG_LEASH_FORCE_TELEPORT "leash_force_teleport"
#define COMSIG_LEASH_PATH_STARTED "leash_path_started"
#define COMSIG_LEASH_PATH_COMPLETE "leash_path_complete"
#define COMSIG_OBJ_UNFREEZE "obj_unfreeze"
#define COMSIG_AI_BLACKBOARD_KEY_SET(blackboard_key) ("ai_blackboard_key_set_" + blackboard_key)
#define COMSIG_AI_BLACKBOARD_KEY_CLEARED(blackboard_key) ("ai_blackboard_key_cleared_" + blackboard_key)
#define COMSIG_END_BIBLE_CHAIN (1 << 0)
#define COMSIG_BLOCK_RELAYMOVE (1 << 0)
#define COMPONENT_IGNORE_CHANGE (1 << 0)
#define COMPONENT_PREVENT_LIMB_DAMAGE (1 << 0)

/// From /obj/effect/proc_holder/spell/touch/mansus_grasp/cast_on_hand_hit : (mob/living/source, mob/living/target)
#define COMSIG_HERETIC_MANSUS_GRASP_ATTACK "mansus_grasp_attack"
	/// Default behavior is to use the hand, so return this to blocks the mansus fist from being consumed after use.
	#define COMPONENT_BLOCK_HAND_USE (1<<0)
/// From /obj/effect/proc_holder/spell/touch/mansus_grasp/cast_on_secondary_hand_hit : (mob/living/source, atom/target)
#define COMSIG_HERETIC_MANSUS_GRASP_ATTACK_SECONDARY "mansus_grasp_attack_secondary"
	/// Default behavior is to continue attack chain and do nothing else, so return this to use up the hand after use.
	#define COMPONENT_USE_HAND (1<<0)

/// From /obj/item/melee/sickly_blade/afterattack : (mob/living/source, mob/living/target)
#define COMSIG_HERETIC_BLADE_ATTACK "blade_attack"
/// From /obj/item/melee/sickly_blade/ranged_interact_with_atom (without proximity) : (mob/living/source, mob/living/target)
#define COMSIG_HERETIC_RANGED_BLADE_ATTACK "ranged_blade_attack"

/// From /obj/projectile/bullet/strilka310/lionhunter/on_hit : (mob/living/source, mob/living/target)
#define COMSIG_LIONHUNTER_ON_HIT "lionhunter_on_hit"

/// For [/datum/status_effect/protective_blades] to signal when it is triggered
#define COMSIG_BLADE_BARRIER_TRIGGERED "blade_barrier_triggered"
