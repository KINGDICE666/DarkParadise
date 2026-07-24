/// From /mob/living/simple_animal/hostile/swarmer, sent by swarmer to swarmer_team datum
#define COMSIG_SWARMER_TRY_PROCESS_ORGANIC_ITEM "swarmer_try_process_organic"
/// From /datum/team/swarmer_team, sent by team to organic processer structure
#define COMSIG_SWARMER_PROCESS_ORGANIC_ITEM_CHECK "swarmer_process_organic_check"

/// From /mob/living/simple_animal/hostile/swarmer, sent by swarmer to swarmer_team datum
#define COMSIG_SWARMER_TRY_ANALYZE_MOB "swarmer_try_process_mob"
/// From /datum/team/swarmer_team, sent by team to organic analyzer structure
#define COMSIG_SWARMER_ANALYZE_MOB_CHECK "swarmer_process_mob_check"

/// From /obj/structure/swarmer/resource_storage, sent to swarmer_team on init
#define COMSIG_SWARMER_STORAGE_INITIALIZED "swarmer_storage_initialized"
/// From /obj/structure/swarmer/resource_storage, sent to swarmer_team on destroy
#define COMSIG_SWARMER_STORAGE_DESTROYED "swarmer_storage_destroyed"

/// From /obj/structure/swarmer/core, sent from core to team on init
#define COMSIG_SWARMER_CORE_INITIALIZED "swarmer_core_initialized"
/// From /obj/structure/swarmer/core, sent from core to team on mega-swarmer spawn
#define COMSIG_MEGA_SWARMER_CORE_SPAWN "mega_swarmer_core_spawn"
