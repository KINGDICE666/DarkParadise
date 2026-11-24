#define PVE_FINAL_WAVE 20
#define PVE_BOSS_WAVE_INTERVAL 5

#define PVE_FACTION_ENEMY "pve_enemies"
#define PVE_FACTION_PLAYER "pve_players"

#define PVE_CLASS_ASSAULT "assault"
#define PVE_CLASS_MEDIC "medic"
#define PVE_CLASS_ENGINEER "engineer"
#define PVE_CLASS_MARKSMAN "marksman"
#define PVE_CLASS_GUARDIAN "guardian"

#define PVE_CATEGORY_WEAPONS "weapons"
#define PVE_CATEGORY_AMMO "ammo"
#define PVE_CATEGORY_ARMOR "armor"
#define PVE_CATEGORY_MEDICINE "medicine"
#define PVE_CATEGORY_STRUCTURES "structures"
#define PVE_CATEGORY_SUPPORT "support"
#define PVE_CATEGORY_UPGRADES "upgrades"

#define PVE_MUTATOR_NIGHT "night"
#define PVE_MUTATOR_FRENZY "frenzy"
#define PVE_MUTATOR_HORDE "horde"
#define PVE_MUTATOR_BLOOD_MOON "blood_moon"
#define PVE_MUTATOR_IRONHIDE "ironhide"
#define PVE_MUTATOR_REGEN "regen"
#define PVE_MUTATOR_GOLD "gold"

#define PVE_UPGRADE_TOUGHNESS "toughness"
#define PVE_UPGRADE_RESILIENCE "resilience"
#define PVE_UPGRADE_SPRINT "sprint"
#define PVE_UPGRADE_LOOTER "looter"

#define IS_PVE_ENEMY(thing) istype(thing, /mob/living/simple_animal/hostile/pve)
