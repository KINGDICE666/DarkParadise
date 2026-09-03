/obj/machinery/quantum_server/proc/collect_mutation_candidates()
	for(var/turf/tile as anything in domain_reservation.reserved_turfs)
		for(var/mob/living/creature in tile)
			if(creature.mind || creature.stat == DEAD)
				continue
			mutation_candidate_refs += WEAKREF(creature)

/obj/machinery/quantum_server/proc/get_mutation_target()
	while(length(mutation_candidate_refs))
		var/datum/weakref/candidate_ref = pick_n_take(mutation_candidate_refs)
		var/mob/living/candidate = candidate_ref.resolve()
		if(!QDELETED(candidate) && isnull(candidate.mind) && candidate.stat != DEAD)
			return candidate

/obj/machinery/quantum_server/proc/get_glitch_role()
	var/list/available = list()
	for(var/datum/antagonist/bitrunning_glitch/role as anything in subtypesof(/datum/antagonist/bitrunning_glitch))
		if(threat >= initial(role.threat))
			available += role

	if(!length(available))
		return

	var/datum/antagonist/bitrunning_glitch/chosen = pick(available)
	threat -= initial(chosen.threat) * 0.5
	return chosen

/obj/machinery/quantum_server/proc/setup_glitch()
	var/mob/living/mutation_target = get_mutation_target()
	if(isnull(mutation_target))
		return

	var/datum/antagonist/bitrunning_glitch/chosen_role = get_glitch_role()
	if(isnull(chosen_role))
		return

	mutation_target.create_digital_aura()

	var/list/mob/dead/observer/candidates = SSghost_spawns.poll_candidates(
		question = "Хотите сыграть за сбой виртуального домена? Вы вернётесь в своё тело, когда домен выгрузят.",
		role = ROLE_GLITCH,
		poll_time = 20 SECONDS,
		source = mutation_target,
		role_cleanname = initial(chosen_role.antag_menu_name),
	)

	if(!length(candidates))
		mutation_target.remove_digital_aura()
		return

	spawn_glitch(chosen_role, mutation_target, pick(candidates))

/obj/machinery/quantum_server/proc/spawn_glitch(datum/antagonist/bitrunning_glitch/chosen_role, mob/living/mutation_target, mob/dead/observer/ghost)
	if(QDELETED(mutation_target))
		return

	if(QDELETED(src) || isnull(generated_domain) || !is_operational())
		mutation_target.remove_digital_aura()
		return

	var/mob/living/carbon/human/glitch = new(mutation_target.loc)
	glitch.faction = mutation_target.faction.Copy()
	glitch.faction |= ROLE_GLITCH
	qdel(mutation_target)

	ghost.client?.prefs.copy_to(glitch)
	glitch.UpdateAppearance()
	glitch.add_traits(list(TRAIT_TEMPORARY_BODY), INNATE_TRAIT)
	if(ghost.mind)
		glitch.AddComponent( \
			/datum/component/temporary_body, \
			old_mind = ghost.mind, \
			old_body = ghost.mind.current, \
			delete_on_death = TRUE, \
		)

	glitch.possess_by_player(ghost.key)
	if(isnull(glitch.mind))
		glitch.mind_initialize()

	glitch.mind.add_antag_datum(chosen_role)
	glitch.AddComponent(/datum/component/virtual_entity)
	glitch.create_digital_aura()

	spawned_threat_refs += WEAKREF(glitch)
	playsound(glitch, 'sound/effects/phasein.ogg', 50, TRUE)
	message_admins("[key_name_admin(glitch)] was made into a bitrunning glitch at [ADMIN_JMP(src)].")

/obj/machinery/quantum_server/proc/notify_spawned_threats()
	for(var/datum/weakref/threat_ref as anything in spawned_threat_refs)
		var/mob/living/spawned_threat = threat_ref.resolve()
		if(isnull(spawned_threat?.mind) || spawned_threat.stat >= UNCONSCIOUS)
			continue

		spawned_threat.throw_alert(ALERT_BITRUNNER_RESET, /atom/movable/screen/alert/bitrunning/reset)
		to_chat(spawned_threat, span_userdanger("Вас пометили на удаление. Спасибо за службу."))
