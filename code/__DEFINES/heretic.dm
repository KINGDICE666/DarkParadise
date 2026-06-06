// Heretic path defines.
#define PATH_START "Start Path"
#define PATH_SIDE "Side Path"
#define PATH_ASH "Ash Path"
#define PATH_RUST "Rust Path"
#define PATH_FLESH "Flesh Path"
#define PATH_VOID "Void Path"
#define PATH_BLADE "Blade Path"
#define PATH_COSMIC "Cosmic Path"
#define PATH_LOCK "Lock Path"
#define PATH_MOON "Moon Path"

// Heretic knowledge tree defines.
#define HKT_NEXT "next"
#define HKT_BAN "ban"
#define HKT_DEPTH "depth"
#define HKT_ROUTE "route"
#define HKT_UI_BGR "ui_bgr"

/// Defines are used in /proc/has_living_heart() to report if the heretic has no heart period, no living heart, or has a living heart.
#define HERETIC_NO_HEART_ORGAN -1
#define HERETIC_NO_LIVING_HEART 0
#define HERETIC_HAS_LIVING_HEART 1

/// A define used in ritual priority for heretics.
#define MAX_KNOWLEDGE_PRIORITY 100

#define FACTION_HERETIC "heretic"
#define FACTION_HOSTILE "hostile"

/// Checks if the passed mob can become a heretic ghoul.
/// - Must be a human (type, not species)
/// - Skeletons cannot be husked (they are snowflaked instead of having a trait)
/// - Monkeys are monkeys, not quite human (balance reasons)
#define IS_VALID_GHOUL_MOB(mob) (ishuman(mob) && !isskeleton(mob) && !ismonkey(mob))

/// JSON string file for all of our heretic influence flavors.
#define HERETIC_INFLUENCE_FILE "heretic_influences.json"

// Compatibility defines used by tg-derived heretic spell code.
#define SCHOOL_UNSET "unset"
#define SCHOOL_HOLY "holy"
#define SCHOOL_PSYCHIC "psychic"
#define SCHOOL_MIME "mime"
#define SCHOOL_RESTORATION "restoration"
#define SCHOOL_EVOCATION "evocation"
#define SCHOOL_TRANSMUTATION "transmutation"
#define SCHOOL_TRANSLOCATION "translocation"
#define SCHOOL_CONJURATION "conjuration"
#define SCHOOL_NECROMANCY "necromancy"
#define SCHOOL_FORBIDDEN "forbidden"
#define SCHOOL_SANGUINE "sanguine"

#define INVOCATION_NONE "none"
#define INVOCATION_SHOUT "shout"
#define INVOCATION_WHISPER "whisper"
#define INVOCATION_EMOTE "emote"

#define SPELL_REQUIRES_WIZARD_GARB (1 << 0)
#define SPELL_REQUIRES_HUMAN (1 << 1)
#define SPELL_CASTABLE_AS_BRAIN (1 << 2)
#define SPELL_REQUIRES_NO_ANTIMAGIC (1 << 4)
#define SPELL_REQUIRES_STATION (1 << 5)
#define SPELL_REQUIRES_MIND (1 << 6)
#define SPELL_REQUIRES_MIME_VOW (1 << 7)
#define SPELL_CASTABLE_WITHOUT_INVOCATION (1 << 8)
#define SPELL_NO_FEEDBACK (1 << 1)
#define SPELL_NO_IMMEDIATE_COOLDOWN (1 << 2)

#define MAGIC_RESISTANCE (1 << 0)
#define MAGIC_RESISTANCE_MIND (1 << 1)
#define MAGIC_RESISTANCE_HOLY (1 << 2)

#define SPELL_CANCEL_CAST (1 << 0)
#define CAN_ACT_IN_STASIS (1 << 3)
#define COMPONENT_AFTERATTACK_STOP COMPONENT_NO_AFTERATTACK
#define SILENCE_SACRIFICE_MESSAGE (1 << 0)
#define DUST_SACRIFICE (1 << 1)
#define LADDER_TRAVEL_BLOCK (1 << 0)
#define COMPONENT_CANT_Z_MOVE (1 << 0)
#define COMPONENT_CAST_HANDLESS (1 << 0)
#define COMPONENT_CANT_STRIP (1 << 0)
#define ACCESS_DISALLOWED (1 << 1)
#define ATTACKER_STAMINA_ATTACK (1 << 0)
#define ATTACKER_DAMAGING_ATTACK (1 << 1)
#define ATTACKER_SHOVING (1 << 2)

#define BB_TARGETED_ACTION "BB_TARGETED_action"
#define BB_GENERIC_ACTION "BB_generic_action"
#define BB_BASIC_MOB_HAS_TARGET_TIME "BB_basic_mob_has_target_time"
#define BB_BASIC_MOB_EXECUTION_TARGET "BB_basic_execution_target"
#define FOOTSTEP_MOB_RUST "footstep_rust"
#define TRAUMA_RESILIENCE_MAGIC 5
#define HAND_REPLACEMENT_TRAIT "magic-hand"
#define IS_LEFT_INDEX(value) (value % 2 != 0)
#define SLEEPING "sleeping"
#define IRRADIATE "irradiate"
#define around_player "CENTER-1,CENTER-1"
#define SSmove_manager GLOB.move_manager
#define ADD_KEEP_TOGETHER(x, source) x.appearance_flags |= KEEP_TOGETHER
#define GET_TARGETING_STRATEGY(targeting_type) (ispath(targeting_type) ? new targeting_type : targeting_type)

#define AI_BEHAVIOR_REQUIRE_MOVEMENT (1<<0)
#define AI_BEHAVIOR_REQUIRE_REACH (1<<1)
#define AI_BEHAVIOR_MOVE_AND_PERFORM (1<<2)
#define AI_BEHAVIOR_KEEP_MOVE_TARGET_ON_FINISH (1<<3)
#define AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION (1<<4)
#define AI_BEHAVIOR_DELAY (1<<0)
#define AI_BEHAVIOR_SUCCEEDED (1<<1)
#define AI_BEHAVIOR_FAILED (1<<2)
#define AI_BEHAVIOR_INSTANT (NONE)

#define HAUNTED_ITEM_ATTACK_HAUNT_CHANCE 10
#define HAUNTED_ITEM_ESCAPE_GRASP_CHANCE 20
#define HAUNTED_ITEM_TELEPORT_CHANCE 4
#define HAUNTED_ITEM_AGGRO_ADDITION 2
#define BB_TO_HAUNT_LIST "BB_to_haunt_list"
#define BB_HAUNT_TARGET "BB_haunt_target"
#define BB_HAUNTED_THROW_ATTEMPT_COUNT "BB_haunted_throw_attempt_count"
#define BB_LIKES_EQUIPPER "BB_likes_equipper"
#define BB_ACTIVE_PET_COMMAND "BB_active_pet_command"
#define BB_PET_TARGETING_DATUM "BB_pet_targeting_datum"
#define BB_FRIENDS_LIST "BB_friends_list"
#define BB_CURRENT_PET_TARGET "BB_current_pet_target"
#define BB_PET_TARGETING_STRATEGY "BB_pet_targeting"
#define BB_OWNER_SELF_HARM_RESPONSES "BB_self_harm_responses"
#define BB_TARGET_MINIMUM_STAT "BB_target_minimum_stat"
#define BB_OBSTACLE_TARGETING_WHITELIST "BB_obstacle_targeting_whitelist"
#define BB_SHAPESHIFT_ACTION "BB_shapeshift_action"
