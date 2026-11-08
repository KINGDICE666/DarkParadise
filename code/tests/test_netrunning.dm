/datum/unit_test/room_test/netrunning

/datum/unit_test/room_test/netrunning/proc/new_runner(turf/spawn_turf)
	var/mob/living/carbon/human/runner = allocate(/mob/living/carbon/human, spawn_turf)
	runner.mind_initialize()
	return runner

/datum/unit_test/room_test/netrunning/proc/new_pod(x_offset)
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/machinery/netpod/pod = allocate(/obj/machinery/netpod, locate(anchor.x + x_offset, anchor.y, anchor.z))
	pod.net_mode = TRUE
	return pod

/datum/unit_test/room_test/netrunning/proc/jack_in(mob/living/carbon/human/runner, obj/machinery/netpod/pod)
	var/datum/mind/runner_mind = runner.mind
	if(pod.occupant != runner)
		runner.forceMove(pod)
		pod.occupant = runner
		pod.state_open = FALSE
	pod.start_net_session(runner)
	return runner_mind.current

/datum/unit_test/room_test/netrunning/proc/solve_breach(datum/net_breach/breach, list/sequence, list/picks, list/buffer, axis_row, line)
	if(buffer_contains(buffer, sequence))
		return picks
	if(length(buffer) >= breach.buffer_size)
		return null
	for(var/index in 1 to length(breach.grid))
		var/row = axis_row ? line : index
		var/column = axis_row ? index : line
		var/key = "[row]-[column]"
		if(key in picks)
			continue
		var/list/grid_line = breach.grid[row]
		var/list/result = solve_breach(breach, sequence, picks + key, buffer + grid_line[column], !axis_row, axis_row ? column : row)
		if(result)
			return result
	return null

/datum/unit_test/room_test/netrunning/proc/buffer_contains(list/buffer, list/sequence)
	for(var/offset in 0 to length(buffer) - length(sequence))
		var/matched = TRUE
		for(var/index in 1 to length(sequence))
			if(buffer[offset + index] != sequence[index])
				matched = FALSE
				break
		if(matched)
			return TRUE
	return FALSE

/datum/unit_test/room_test/netrunning/Run()
	var/obj/machinery/netpod/pod = new_pod(0)
	var/mob/living/carbon/human/runner = new_runner(run_loc_floor_top_right)
	var/datum/mind/runner_mind = runner.mind
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = allocate(/obj/item/organ/internal/cyberimp/brain/neuro_interface)
	neuro.insert(runner)

	var/mob/living/basic/net_avatar/avatar = jack_in(runner, pod)
	TEST_ASSERT(isnetavatar(avatar), "the mind did not move into a net avatar")
	TEST_ASSERT_NULL(runner.mind, "the body kept its mind while jacked in")
	TEST_ASSERT(pod.connected, "the pod did not register the Net connection")
	TEST_ASSERT(length(avatar.body_overlays), "the avatar did not copy the body's appearance")
	TEST_ASSERT_EQUAL(avatar.invisibility, INVISIBILITY_NETRUNNER, "the avatar is visible to the crew")

	var/datum/component/net_connection/connection = avatar.GetComponent(/datum/component/net_connection)
	TEST_ASSERT_EQUAL(connection.neuro, neuro, "the Net session did not pick up the runner's neuro-interface")
	TEST_ASSERT_EQUAL(neuro.get_operator(), avatar, "the neuro-interface is still driven by the sleeping body")
	TEST_ASSERT(islist(avatar.get_access()), "the avatar could not borrow the body's access")

	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/item/radio/intercom/intercom = allocate(/obj/item/radio/intercom, locate(anchor.x + 1, anchor.y + 1, anchor.z))
	var/list/intercom_actions = avatar.get_native_actions(intercom)
	TEST_ASSERT_EQUAL(length(intercom_actions), 2, "an intercom did not offer speaking and tapping")
	avatar.toggle_tap(intercom)
	TEST_ASSERT_EQUAL(avatar.tapped_intercom, intercom, "the intercom tap did not start")
	avatar.toggle_tap(intercom)
	TEST_ASSERT_NULL(avatar.tapped_intercom, "the intercom tap did not stop")

	var/obj/machinery/hologram/holopad/pad = allocate(/obj/machinery/hologram/holopad, locate(anchor.x + 1, anchor.y, anchor.z))
	avatar.toggle_projection(pad)
	TEST_ASSERT_NOTNULL(avatar.projection, "the holopad did not project the avatar")
	TEST_ASSERT_EQUAL(avatar.projection.invisibility, INVISIBILITY_NONE, "the projected hologram is hidden from the crew")
	var/obj/effect/overlay/net_hologram/hologram = avatar.projection
	avatar.toggle_projection(pad)
	TEST_ASSERT(QDELETED(hologram), "the hologram outlived its projection")

	TEST_ASSERT_EQUAL(GLOB.net_ice_areas[/area/station/command/vault], NET_ICE_BLACK, "the vault is not guarded by black ICE")
	TEST_ASSERT_EQUAL(GLOB.net_ice_areas[/area/station/security/lobby], NET_ICE_NONE, "the security lobby is guarded by ICE")
	TEST_ASSERT_EQUAL(GLOB.net_ice_areas[/area/station/command/bridge], NET_ICE_STANDARD, "the bridge is not guarded by ICE")

	var/area/test_area = get_area(avatar)
	var/datum/net_breach/breach = new(avatar, test_area, NET_ICE_STANDARD, NET_BREACH_BASE_BUFFER)
	avatar.active_breach = breach
	var/list/ice_daemon = breach.daemons[1]
	var/list/picks = solve_breach(breach, ice_daemon["sequence"], list(), list(), TRUE, 1)
	TEST_ASSERT(length(picks), "the breach generator built a matrix without a solution")
	for(var/key in picks)
		var/list/cell = splittext(key, "-")
		breach.select_cell(text2num(cell[1]), text2num(cell[2]))
	breach.finish()
	TEST_ASSERT(avatar.breached_areas[test_area] > world.time, "solving the breach protocol did not open the ICE")
	TEST_ASSERT(QDELETED(breach), "the breach protocol outlived its result")

	var/health_before = avatar.health
	var/trace_before = avatar.get_trace()
	breach = new(avatar, test_area, NET_ICE_BLACK, NET_BREACH_BASE_BUFFER)
	avatar.active_breach = breach
	breach.finish()
	TEST_ASSERT(avatar.health < health_before, "failing against black ICE did not burn the avatar")
	TEST_ASSERT(avatar.get_trace() > trace_before, "failing the breach protocol did not raise the trace")

	avatar.add_trace(NET_TRACE_MAX)
	TEST_ASSERT_EQUAL(avatar.get_trace(), 0, "a completed trace did not reset")

	connection.jack_out()
	TEST_ASSERT_NULL(neuro.net_operator, "the neuro-interface kept the avatar as its operator after jacking out")
	TEST_ASSERT_EQUAL(runner.mind, runner_mind, "jacking out did not return the mind to the body")
	TEST_ASSERT(QDELETED(avatar), "the avatar outlived a clean jack out")
	TEST_ASSERT(!pod.connected, "the pod stayed connected after a clean jack out")

	avatar = jack_in(runner, pod)
	connection = avatar.GetComponent(/datum/component/net_connection)
	pod.open_machine()
	TEST_ASSERT(connection.lost, "pulling the body out of the pod did not trap the runner")
	TEST_ASSERT_EQUAL(avatar.mind, runner_mind, "the trapped runner's mind left the Net")
	TEST_ASSERT_NULL(runner.mind, "the abandoned body got its mind back")
	TEST_ASSERT_NULL(connection.jack_out_action, "the trapped runner can still jack out")
	qdel(avatar)

	var/obj/machinery/netpod/flatline_pod = new_pod(1)
	var/mob/living/carbon/human/victim = new_runner(run_loc_floor_top_right)
	var/datum/mind/victim_mind = victim.mind
	avatar = jack_in(victim, flatline_pod)
	avatar.death()
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "dying in the Net did not kill the body")
	TEST_ASSERT_EQUAL(victim.mind, victim_mind, "the flatlined mind did not return to its body")

	var/obj/machinery/netpod/body_pod = new_pod(2)
	var/mob/living/carbon/human/sleeper = new_runner(run_loc_floor_top_right)
	avatar = jack_in(sleeper, body_pod)
	sleeper.death()
	TEST_ASSERT(QDELETED(avatar), "the avatar survived the death of its body")
