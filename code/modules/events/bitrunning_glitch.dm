/datum/event/bitrunning_glitch

/datum/event/bitrunning_glitch/start()
	INVOKE_ASYNC(src, PROC_REF(wrapped_start))

/datum/event/bitrunning_glitch/proc/wrapped_start()
	var/list/obj/machinery/quantum_server/loaded_servers = list()
	for(var/obj/machinery/quantum_server/server as anything in SSmachines.get_by_type(/obj/machinery/quantum_server))
		if(isnull(server.generated_domain) || !server.is_operational() || !length(server.mutation_candidate_refs))
			continue
		loaded_servers += server

	if(!length(loaded_servers))
		log_and_message_admins("Random event attempted to spawn a bitrunning glitch, but no quantum server had a running domain.")
		var/datum/event_container/moderate_container = SSevents.event_containers[EVENT_LEVEL_MODERATE]
		moderate_container.next_event_time = world.time + 1 MINUTES
		return kill()

	var/obj/machinery/quantum_server/unlucky_server = pick(loaded_servers)
	unlucky_server.setup_glitch()
