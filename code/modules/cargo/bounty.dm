GLOBAL_LIST_EMPTY(shared_crew_bounties)

/datum/bounty
	var/name
	var/description
	var/claimed = FALSE
	var/high_priority = FALSE
	VAR_PROTECTED/reward = CARGO_CRATE_VALUE * 5
	var/allow_duplicate = FALSE
	var/global_exempt = FALSE
	var/list/contribution = list()
	var/unique = FALSE

/datum/bounty/Destroy(force)
	contribution = null
	return ..()

/datum/bounty/proc/can_claim()
	return FALSE

/datum/bounty/proc/applies_to(obj/shipped)
	return FALSE

/datum/bounty/proc/contribution_amount(obj/shipped)
	return 1

/datum/bounty/proc/ship(obj/shipped)
	return

/datum/bounty/proc/print_required()
	return ""

/datum/bounty/proc/get_bounty_reward()
	var/high_priority_mult = high_priority ? 1.5 : 1
	return reward * high_priority_mult * CIV_BOUNTY_REWARD_MULTIPLIER

/datum/bounty/proc/on_selected(obj/item/card/id/id_card)
	return

/datum/bounty/proc/on_claimed(obj/item/card/id/id_card)
	return

/datum/bounty/proc/on_reset(obj/item/card/id/id_card)
	return

/datum/bounty/proc/get_total()
	return

/datum/bounty/proc/get_max()
	return

/datum/bounty/proc/can_get()
	return TRUE

/proc/get_random_bounty_type(bounty_type)
	if(!bounty_type || bounty_type == CIV_JOB_RANDOM)
		bounty_type = rand(1, MAXIMUM_BOUNTY_JOBS)

	switch(bounty_type)
		if(CIV_JOB_BASIC)
			return pick(subtypesof(/datum/bounty/item/assistant))
		if(CIV_JOB_ROBO)
			return pick(subtypesof(/datum/bounty/item/mech))
		if(CIV_JOB_CHEF)
			return pick(subtypesof(/datum/bounty/item/chef))
		if(CIV_JOB_SEC)
			if(prob(75))
				return /datum/bounty/patrol
			return /datum/bounty/item/contraband
		if(CIV_JOB_DRINK)
			if(prob(50))
				return /datum/bounty/reagent/simple_drink
			return /datum/bounty/reagent/complex_drink
		if(CIV_JOB_CHEM)
			if(prob(50))
				return /datum/bounty/reagent/chemical_simple
			return /datum/bounty/reagent/chemical_complex
		if(CIV_JOB_MED_VIRO)
			if(prob(75))
				return pick(subtypesof(/datum/bounty/item/medical))
			return pick(subtypesof(/datum/bounty/virus))
		if(CIV_JOB_SCI)
			if(prob(50))
				return pick(subtypesof(/datum/bounty/item/science))
			return pick(subtypesof(/datum/bounty/item/slime))
		if(CIV_JOB_ENG)
			return pick(subtypesof(/datum/bounty/item/engineering))
		if(CIV_JOB_MINE)
			return pick(subtypesof(/datum/bounty/item/mining))
		if(CIV_JOB_MED)
			return pick(subtypesof(/datum/bounty/item/medical))
		if(CIV_JOB_GROW)
			return pick(subtypesof(/datum/bounty/item/botany))
		if(CIV_JOB_ATMOS)
			return pick(subtypesof(/datum/bounty/item/atmospherics))
		if(CIV_JOB_BITRUN)
			return pick(subtypesof(/datum/bounty/item/bitrunning))

	stack_trace("Failed to get random bounty type for input type [bounty_type]")

/proc/random_bounty(category = 0)
	while(TRUE)
		var/bounty_type = get_random_bounty_type(category)
		var/datum/bounty/new_bounty = new bounty_type
		if(new_bounty.can_get())
			return new_bounty
		qdel(new_bounty)

/datum/job/proc/generate_bounty_list(bounty_rolls = 3, assistant_failsafe = TRUE)
	var/list/rolling_list = list()
	if(assistant_failsafe)
		var/assistant_type = get_random_bounty_type(CIV_JOB_BASIC)
		var/datum/bounty/assistant_bounty = new assistant_type
		if(assistant_bounty.can_get())
			rolling_list += assistant_bounty
		else
			qdel(assistant_bounty)

	var/attempts = 20
	while(length(rolling_list) < bounty_rolls && attempts > 0)
		var/job_bounty_type = get_random_bounty_type(attempts <= 5 ? CIV_JOB_BASIC : bounty_types)
		var/datum/bounty/job_bounty = new job_bounty_type
		attempts -= 1
		if(!job_bounty.can_get() || has_duplicate_bounty(rolling_list, job_bounty))
			qdel(job_bounty)
			continue
		rolling_list += job_bounty

	return rolling_list

/datum/job/proc/has_duplicate_bounty(list/datum/bounty/bounty_list, datum/bounty/check_bounty)
	for(var/datum/bounty/existing as anything in bounty_list)
		if(existing.type != check_bounty.type)
			continue
		if(existing.allow_duplicate && check_bounty.allow_duplicate)
			continue
		return TRUE
	return FALSE
