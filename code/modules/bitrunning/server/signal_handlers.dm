/obj/machinery/quantum_server/proc/on_template_loaded(datum/lazy_template/source, list/created_atoms)
	SIGNAL_HANDLER

	UnregisterSignal(source, COMSIG_LAZY_TEMPLATE_LOADED)

	for(var/thing in created_atoms)
		if(ismegafauna(thing))
			var/mob/living/simple_animal/hostile/megafauna/boss = thing
			boss.make_virtual_megafauna()
			continue

		if(isliving(thing))
			mutation_candidate_refs += WEAKREF(thing)
			continue

		if(istype(thing, /obj/machinery/suit_storage_unit))
			var/obj/machinery/suit_storage_unit/storage = thing
			storage.locked = FALSE

/obj/machinery/quantum_server/proc/on_goal_turf_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(!istype(arrived, /obj/structure/closet/crate/secure/bitrunning/encrypted) && !istype(arrived, /obj/item/storage/lockbox/bitrunning/encrypted))
		return

	var/obj/machinery/byteforge/chosen_forge = get_random_nearby_forge()
	if(isnull(chosen_forge))
		return

	if(istype(arrived, /obj/item/storage/lockbox/bitrunning/encrypted))
		generate_secondary_loot(arrived, chosen_forge)
		return

	generate_loot(arrived, chosen_forge)

/obj/machinery/quantum_server/proc/on_threat_created(datum/source, mob/living/threat)
	SIGNAL_HANDLER

	spawned_threat_refs += WEAKREF(threat)
