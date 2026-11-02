/datum/personal_crafting
	var/busy
	var/display_craftable_only = FALSE
	var/display_compact = TRUE

/*	This is what procs do:
	get_environment - gets a list of things accessable for crafting by user
	get_surroundings - takes a list of things and makes a list of key-types to values-amounts of said type in the list
	check_contents - takes a recipe and a key-type list and checks if said recipe can be done with available stuff
	check_tools - takes recipe, a key-type list, and a user and checks if there are enough tools to do the stuff, checks bugs one level deep
	construct_item - takes a recipe and a user, call all the checking procs, calls do_after, checks all the things again, calls requirements_deletion, creates result, calls CheckParts of said result with argument being list returned by deel_reqs
	requirements_deletion - takes recipe and a user, loops over the recipes reqs var and tries to find everything in the list make by get_environment and delete it/add to parts list, then returns the said list
*/

/proc/check_contents(list/reqs, list/chem_catalysts, list/blacklist, list/contents)
	contents = contents["other"]
	main_loop:
		for(var/A in reqs)
			var/needed_amount = reqs[A]
			for(var/B in contents)
				if(ispath(B, A))
					if(blacklist.Find(B))
						continue
					if(contents[B] >= reqs[A])
						continue main_loop
					else
						needed_amount -= contents[B]
						if(needed_amount <= 0)
							continue main_loop
						else
							continue
			return 0
	for(var/A in chem_catalysts)
		if(contents[A] < chem_catalysts[A])
			return 0
	return 1

/proc/get_environment(mob/user)
	. = list()
	. += user.r_hand
	. += user.l_hand
	if(!isturf(user.loc))
		return
	var/list/L = block(get_step(user, SOUTHWEST), get_step(user, NORTHEAST))
	for(var/A in L)
		var/turf/T = A
		if(T.Adjacent(user))
			for(var/B in T)
				var/atom/movable/AM = B
				if(AM.flags & HOLOGRAM)
					continue
				. += AM
	for(var/slot in list(ITEM_SLOT_POCKET_RIGHT, ITEM_SLOT_POCKET_LEFT))
		. += user.get_item_by_slot(slot)

/proc/get_surroundings(mob/user)
	. = list()
	.["other"] = list() //paths go in here
	.["toolsother"] = list() // items go in here
	for(var/obj/item/I in get_environment(user))
		if(I.flags & HOLOGRAM)
			continue
		if(isstack(I))
			var/obj/item/stack/S = I
			.["other"][I.type] += S.amount
		else
			if(is_reagent_container(I))
				var/obj/item/reagent_containers/RC = I
				if(RC.is_drainable())
					for(var/datum/reagent/A in RC.reagents.reagent_list)
						.["other"][A.type] += A.volume
			.["other"][I.type] += 1
		.["toolsother"][I] += 1

/proc/check_tools(mob/user, list/tools, list/contents)
	if(!length(tools)) //does not run if no tools are needed
		return TRUE
	var/list/possible_tools = list()
	var/list/tools_used = list()
	for(var/obj/item/I in user.contents) //searchs the inventory of the mob
		if(isstorage(I))
			for(var/obj/item/SI in I.contents)
				if(SI.tool_behaviour) //filters for tool behaviours
					possible_tools += SI
		if(I.tool_behaviour)
			possible_tools += I

	possible_tools |= contents["toolsother"] // this add contents to possible_tools
	main_loop: // checks if all tools found are usable with the recipe
		for(var/A in tools)
			for(var/obj/item/I in possible_tools)
				if(A == I.tool_behaviour)
					tools_used += I
					continue main_loop
			return FALSE
	for(var/obj/item/T in tools_used)
		if(!T.tool_start_check(null, user, 0)) //Check if all our tools are valid for their use
			return FALSE
	return TRUE

/proc/check_pathtools(mob/user, list/pathtools, list/contents)
	if(!length(pathtools)) //does not run if no tools are needed
		return TRUE
	var/list/other_possible_tools = list()
	for(var/obj/item/I in user.contents) // searchs the inventory of the mob
		if(isstorage(I))
			for(var/obj/item/SI in I.contents)
				other_possible_tools += SI.type	// filters type paths
		other_possible_tools += I.type

	other_possible_tools |= contents["other"] // this adds contents to the other_possible_tools
	main_loop: // checks if all tools found are usable with the recipe
		for(var/A in pathtools)
			for(var/I in other_possible_tools)
				if(ispath(I,A))
					continue main_loop
			return FALSE
	return TRUE

/datum/personal_crafting/proc/construct_item(mob/user, datum/crafting_recipe/R)
	var/list/contents = get_surroundings(user)
	var/send_feedback = 1
	if(!check_contents(R.reqs, R.chem_catalysts, R.blacklist, contents))
		return ", missing component."
	if(!check_tools(user, R.tools, contents))
		return ", missing tool."
	if(!check_pathtools(user, R.pathtools, contents))
		return ", missing tool."

	if(!do_after(user, R.time, user))
		return "."
	contents = get_surroundings(user)

	if(!check_contents(R.reqs, R.chem_catalysts, R.blacklist, contents))
		return ", missing component."
	if(!check_tools(user, R.tools, contents))
		return ", missing tool."
	if(!check_pathtools(user, R.pathtools, contents))
		return ", missing tool."

	var/list/parts = requirements_deletion(R.reqs, R.blacklist, R.parts, user)
	if(!parts)
		return ", missing component."

	var/result_list = R.result
	if(!islist(result_list))
		result_list = list(result_list)
	for(var/result in result_list)
		var/atom/movable/I = new result(get_turf(user.loc))
		I.add_fingerprint(user)
		user.investigate_log("[key_name_log(user)] crafted [I]", INVESTIGATE_CRAFTING)
		I.CheckParts(parts, R)
		if(isitem(I))
			user.put_in_hands(I)

		if(send_feedback)
			SSblackbox.record_feedback("tally", "object_crafted", 1, I.type)
	return 0

/proc/requirements_deletion(list/reqs, list/blacklist, list/parts, mob/user)
	var/list/surroundings = get_environment(user)
	var/list/parts_used = list()
	var/list/reagent_containers_for_deletion = list()
	var/list/item_stacks_for_deletion = list()
	for(var/atom/movable/thing in surroundings)
		if(thing.type in blacklist)
			surroundings -= thing

	for(var/thing in reqs)
		var/needed_amount = reqs[thing]
		if(ispath(thing, /datum/reagent))
			var/datum/reagent/part_reagent = locate(thing) in parts_used
			if(!part_reagent)
				part_reagent = new thing()
				parts_used += part_reagent

			for(var/obj/item/reagent_containers/container in surroundings)
				var/datum/reagent/contained_reagent = container.reagents.get_reagent(thing)
				if(!contained_reagent)
					continue

				var/extracted_amount = min(contained_reagent.volume, needed_amount)
				if(reagent_containers_for_deletion[container] == null)
					reagent_containers_for_deletion[container] = list()

				reagent_containers_for_deletion[container][contained_reagent] = extracted_amount

				part_reagent.volume += extracted_amount
				part_reagent.data += contained_reagent.data
				needed_amount -= extracted_amount
				if(needed_amount <= 0)
					break

			if(needed_amount > 0)
				stack_trace("While crafting requirements_deletion, some of [thing] went missing (still need [needed_amount])!")
				continue // ignore the error, and continue crafting for player's benefit

		else if(ispath(thing, /obj/item/stack))
			var/obj/item/stack/part_stack = locate(thing) in parts_used
			if(!part_stack)
				part_stack = new thing()
				part_stack.amount = 0
				parts_used += part_stack

			for(var/obj/item/stack/item_stack in (surroundings - item_stacks_for_deletion))
				if(!istype(item_stack, thing))
					continue

				var/extracted_amount = min(item_stack.amount, needed_amount)
				item_stacks_for_deletion[item_stack] = extracted_amount
				part_stack.amount += extracted_amount
				needed_amount -= extracted_amount
				if(needed_amount <= 0)
					break

			if(needed_amount > 0)
				stack_trace("While crafting requirements_deletion, some of [thing] went missing (still need [needed_amount])!")
				continue

		else
			for(var/i in 1 to needed_amount)
				var/atom/movable/part_atom = locate(thing) in (surroundings - parts_used)
				if(!part_atom)
					stack_trace("While crafting requirements_deletion, the [thing] went missing!")
					continue
				parts_used += part_atom

	for(var/obj/item/reagent_containers/container_to_clear as anything in reagent_containers_for_deletion)
		for(var/datum/reagent/reagent_to_delete as anything in reagent_containers_for_deletion[container_to_clear])
			var/amount_to_delete = reagent_containers_for_deletion[container_to_clear][reagent_to_delete]

			if(amount_to_delete < reagent_to_delete.volume)
				reagent_to_delete.volume -= amount_to_delete
			else
				container_to_clear.reagents.reagent_list -= reagent_to_delete
			container_to_clear.reagents.conditional_update(container_to_clear)
			container_to_clear.update_icon()

	for(var/obj/item/stack/stack_to_delete as anything in item_stacks_for_deletion)
		var/amount_to_delete = item_stacks_for_deletion[stack_to_delete]
		stack_to_delete.use(amount_to_delete)

	// Sort out the used parts into the ones we need to return (denoted by parts),
	// and the ones we need to delete (the rest of reqs)
	var/parts_returned = list()
	for(var/part_path in parts)
		for(var/i in 1 to parts[part_path])
			var/part = locate(part_path) in parts_used
			if(!part)
				stack_trace("Part [part_path] went missing")
			parts_returned += part
			parts_used -= part
	QDEL_LIST(parts_used)

	return parts_returned

/datum/personal_crafting/ui_state(mob/user)
	return GLOB.not_incapacitated_state

/datum/personal_crafting/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PersonalCrafting", "Крафт")
		ui.open()

/datum/personal_crafting/proc/close(mob/user)
	var/datum/tgui/ui = SStgui.get_open_ui(user, src, "main")
	if(ui)
		ui.close()

/datum/personal_crafting/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/crafting),
	)

/datum/personal_crafting/ui_data(mob/user)
	var/list/data = list()
	data["busy"] = busy
	data["display_craftable_only"] = display_craftable_only
	data["display_compact"] = display_compact

	var/list/surroundings = get_surroundings(user)
	var/list/craftability = list()
	for(var/datum/crafting_recipe/recipe as anything in get_visible_recipes(user))
		if(check_contents(recipe.reqs, recipe.chem_catalysts, recipe.blacklist, surroundings))
			craftability[recipe.UID()] = TRUE

	data["craftability"] = craftability
	return data

/datum/personal_crafting/ui_static_data(mob/user)
	var/list/data = list()
	var/list/material_occurences = list()

	data["recipes"] = list()
	data["categories"] = list()

	for(var/datum/crafting_recipe/recipe as anything in get_visible_recipes(user))
		if(recipe.category)
			data["categories"] |= recipe.category

		for(var/req in recipe.reqs)
			material_occurences[req] += 1
		for(var/req in recipe.chem_catalysts)
			material_occurences[req] += 1

		data["recipes"] += list(build_recipe_data(recipe))

	var/list/datums = GLOB.crafting_recipes_datums
	var/datum/asset/spritesheet_batched/sheet = get_asset_datum(/datum/asset/spritesheet_batched/crafting)

	data["atom_data"] = list()
	data["icon_data"] = list()
	for(var/atom_id in 1 to length(datums))
		var/datum_path = datums[atom_id]
		var/atom_name = ""
		if(ispath(datum_path, /atom))
			var/atom/atom_path = datum_path
			atom_name = atom_path::name
		else if(ispath(datum_path, /datum/reagent))
			var/datum/reagent/reagent_path = datum_path
			atom_name = reagent_path::name

		data["atom_data"] += list(list(
			"name" = atom_name,
			"is_reagent" = ispath(datum_path, /datum/reagent),
		))

		var/icon_size = sheet.icon_size_id("a[atom_id]")
		if(icon_size && !endswith(icon_size, "32x32"))
			data["icon_data"]["[atom_id]"] = "[icon_size] a[atom_id]"

	data["material_occurences"] = list()
	for(var/material in material_occurences)
		if(material_occurences[material] == 1)
			continue
		data["material_occurences"] += list(list(
			"atom_id" = "[datums.Find(material)]",
			"occurences" = material_occurences[material],
		))

	return data

/datum/personal_crafting/proc/get_visible_recipes(mob/user)
	. = list()
	for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
		if(recipe.always_availible || (recipe.type in user.mind?.learned_recipes))
			. += recipe

/datum/personal_crafting/ui_act(action, list/params)
	if(..())
		return

	. = TRUE

	switch(action)
		if("make")
			if(busy)
				return
			var/datum/crafting_recipe/recipe = locateUID(params["recipe"])
			if(!istype(recipe) || !(recipe in get_visible_recipes(usr)))
				return
			busy = TRUE
			SStgui.update_uis(src)
			var/fail_msg = construct_item(usr, recipe)
			if(!fail_msg)
				to_chat(usr, span_notice("[recipe.name] constructed."))
				if(recipe.alert_admins_on_craft)
					message_admins("[key_name_admin(usr)] has created a [recipe.name] at [ADMIN_COORDJMP(usr)]")
			else
				to_chat(usr, span_warning("Construction failed[fail_msg]"))
			busy = FALSE
			SStgui.update_uis(src)

		if("toggle_recipes")
			display_craftable_only = !display_craftable_only

		if("toggle_compact")
			display_compact = !display_compact

/datum/personal_crafting/proc/build_recipe_data(datum/crafting_recipe/recipe)
	var/list/data = list()
	var/list/datums = GLOB.crafting_recipes_datums

	var/list/results = islist(recipe.result) ? recipe.result : list(recipe.result)
	var/atom/result_path = results[1]

	data["ref"] = recipe.UID()
	data["id"] = datums.Find(result_path)
	data["category"] = recipe.category
	data["subcategory"] = recipe.subcategory
	data["name"] = length(results) > 1 ? "[recipe.name] [length(results)]x" : recipe.name

	if(ispath(result_path, /atom))
		data["desc"] = result_path::desc

	if(length(recipe.tools))
		data["tool_behaviors"] = recipe.tools
	if(length(recipe.pathtools))
		data["tool_paths"] = list()
		for(var/req_atom in recipe.pathtools)
			data["tool_paths"] += datums.Find(req_atom)

	data["reqs"] = list()
	for(var/req_atom in recipe.reqs)
		data["reqs"]["[datums.Find(req_atom)]"] = recipe.reqs[req_atom]

	if(length(recipe.chem_catalysts))
		data["chem_catalysts"] = list()
		for(var/req_atom in recipe.chem_catalysts)
			data["chem_catalysts"]["[datums.Find(req_atom)]"] = recipe.chem_catalysts[req_atom]

	return data

//Mind helpers

/datum/mind/proc/teach_crafting_recipe(R)
	if(!learned_recipes)
		learned_recipes = list()
	learned_recipes |= R
