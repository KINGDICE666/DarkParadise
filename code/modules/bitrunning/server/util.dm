#define FORGE_SEARCH_RANGE 4

/obj/machinery/quantum_server/proc/cool_off()
	is_ready = TRUE
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	update_appearance()

/obj/machinery/quantum_server/proc/sever_connections()
	if(!length(avatar_connection_refs))
		return

	SEND_SIGNAL(src, COMSIG_BITRUNNER_QSRV_SEVER)

/obj/machinery/quantum_server/proc/spark_at_location(atom/target)
	playsound(target, 'sound/effects/phasein.ogg', 50, TRUE)
	do_sparks(5, FALSE, get_turf(target))

/obj/machinery/quantum_server/proc/validate_turf(turf/chosen_turf)
	if(!chosen_turf.is_blocked_turf())
		return chosen_turf

	for(var/turf/tile in get_adjacent_open_turfs(chosen_turf))
		if(!tile.is_blocked_turf())
			return tile

/obj/machinery/quantum_server/proc/attempt_spawn_cache(list/turf/possible_turfs)
	if(!length(possible_turfs))
		stack_trace("vdom: no cache spawns found on [generated_domain.key]")
		return FALSE

	shuffle_inplace(possible_turfs)

	for(var/turf/tile as anything in possible_turfs)
		var/turf/chosen_turf = validate_turf(tile)
		if(isnull(chosen_turf))
			continue

		new /obj/structure/closet/crate/secure/bitrunning/encrypted(chosen_turf)
		return TRUE

	stack_trace("vdom: every cache spawn on [generated_domain.key] was blocked")
	return FALSE

/obj/machinery/quantum_server/proc/get_random_nearby_forge()
	var/list/obj/machinery/byteforge/nearby_forges = list()
	for(var/obj/machinery/byteforge/forge in oview(FORGE_SEARCH_RANGE, src))
		nearby_forges += forge

	if(!length(nearby_forges))
		return

	return pick(nearby_forges)

/obj/machinery/quantum_server/proc/get_avatar_destination()
	if(retries_spent >= length(exit_turfs))
		return

	var/turf/exit_tile
	for(var/turf/tile as anything in exit_turfs)
		if(locate(/obj/structure/hololadder) in tile)
			continue
		exit_tile = tile
		break

	if(isnull(exit_tile))
		return

	retries_spent += 1
	return new /obj/structure/hololadder(exit_tile, src)

/obj/machinery/quantum_server/proc/start_new_connection(mob/living/carbon/human/pilot)
	var/obj/structure/hololadder/entry_point = get_avatar_destination()
	if(isnull(entry_point))
		return

	return generate_avatar(get_turf(entry_point), pilot)

/obj/machinery/quantum_server/proc/generate_avatar(turf/destination, mob/living/carbon/human/pilot)
	var/mob/living/carbon/human/avatar = new(destination)
	pilot.dna.transfer_identity(avatar)
	avatar.equipOutfit(generated_domain.forced_outfit || /datum/outfit/bit_avatar)
	avatar.rename_character(null, pick(GLOB.hacker_aliases))
	return avatar

/obj/machinery/quantum_server/proc/get_random_domain_id()
	var/list/datum/lazy_template/virtual_domain/available = list()
	for(var/datum/lazy_template/virtual_domain/domain as anything in get_virtual_domains())
		if(domain.cost <= points)
			available += domain

	if(!length(available))
		return

	var/datum/lazy_template/virtual_domain/selected = pick(available)
	return selected.key

/obj/machinery/quantum_server/proc/on_goal_turf_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(!istype(arrived, /obj/structure/closet/crate/secure/bitrunning/encrypted))
		return

	var/obj/machinery/byteforge/chosen_forge = get_random_nearby_forge()
	if(isnull(chosen_forge))
		return

	generate_loot(arrived, chosen_forge)

#undef FORGE_SEARCH_RANGE
