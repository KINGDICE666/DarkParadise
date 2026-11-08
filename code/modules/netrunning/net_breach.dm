/datum/net_breach
	var/mob/living/basic/net_avatar/runner
	var/area/target_area
	var/tier
	var/buffer_size
	var/list/grid = list()
	var/list/used = list()
	var/list/buffer = list()
	var/list/daemons = list()
	var/axis_row = TRUE
	var/active_line = 1
	var/time_limit
	var/deadline
	var/timeout_timer
	var/finished = FALSE
	var/static/list/codes = list("1C", "55", "BD", "E9", "7A", "FF")

/datum/net_breach/New(mob/living/basic/net_avatar/runner, area/target_area, tier, buffer_size)
	src.runner = runner
	src.target_area = target_area
	src.tier = tier
	src.buffer_size = buffer_size
	build_grid(tier == NET_ICE_BLACK ? NET_BREACH_GRID_BLACK : NET_BREACH_GRID_STANDARD)
	time_limit = tier == NET_ICE_BLACK ? NET_BREACH_TIME_BLACK : NET_BREACH_TIME_STANDARD
	deadline = world.time + time_limit
	timeout_timer = addtimer(CALLBACK(src, PROC_REF(finish)), time_limit, TIMER_STOPPABLE)

/datum/net_breach/Destroy(force)
	finished = TRUE
	deltimer(timeout_timer)
	SStgui.close_uis(src)
	if(runner?.active_breach == src)
		runner.active_breach = null
	runner = null
	target_area = null
	return ..()

/datum/net_breach/proc/build_grid(grid_size)
	for(var/row in 1 to grid_size)
		var/list/line = list()
		var/list/flags = list()
		for(var/column in 1 to grid_size)
			line += pick(codes)
			flags += FALSE
		grid += list(line)
		used += list(flags)
	var/list/solution = carve_solution(grid_size)
	var/ice_length = tier == NET_ICE_BLACK ? NET_DAEMON_LENGTH_LONG : NET_DAEMON_LENGTH_SHORT
	add_daemon(NET_DAEMON_ICE, "Вскрыть лёд", "Открывает проход в зону.", solution, ice_length)
	add_daemon(NET_DAEMON_TRACE, "Стереть след", "Взлом не прибавит трассировку.", solution, NET_DAEMON_LENGTH_LONG)
	add_daemon(NET_DAEMON_HOLD, "Удержать проход", "Проход остаётся открытым вдвое дольше.", solution, NET_DAEMON_LENGTH_LONG)

/datum/net_breach/proc/carve_solution(grid_size)
	var/list/solution = list()
	var/list/taken = list()
	var/row = 1
	var/column = rand(1, grid_size)
	var/horizontal = FALSE
	for(var/step in 1 to buffer_size)
		if(step > 1)
			var/list/candidates = list()
			for(var/index in 1 to grid_size)
				if(!taken[horizontal ? "[row]-[index]" : "[index]-[column]"])
					candidates += index
			if(horizontal)
				column = pick(candidates)
			else
				row = pick(candidates)
			horizontal = !horizontal
		taken["[row]-[column]"] = TRUE
		var/list/line = grid[row]
		solution += line[column]
	return solution

/datum/net_breach/proc/add_daemon(id, name, desc, list/solution, sequence_length)
	sequence_length = min(sequence_length, buffer_size)
	var/offset = rand(0, buffer_size - sequence_length)
	daemons += list(list(
		"id" = id,
		"name" = name,
		"desc" = desc,
		"sequence" = solution.Copy(offset + 1, offset + sequence_length + 1),
		"done" = FALSE,
	))

/datum/net_breach/proc/select_cell(row, column)
	if(finished || length(buffer) >= buffer_size)
		return FALSE
	if(row < 1 || column < 1 || row > length(grid) || column > length(grid))
		return FALSE
	if(axis_row ? row != active_line : column != active_line)
		return FALSE
	var/list/flags = used[row]
	if(flags[column])
		return FALSE
	flags[column] = TRUE
	var/list/line = grid[row]
	buffer += line[column]
	active_line = axis_row ? column : row
	axis_row = !axis_row
	var/all_done = TRUE
	for(var/list/daemon as anything in daemons)
		if(!daemon["done"] && buffer_ends_with(daemon["sequence"]))
			daemon["done"] = TRUE
		if(!daemon["done"])
			all_done = FALSE
	if(all_done || length(buffer) >= buffer_size)
		finish()
	return TRUE

/datum/net_breach/proc/buffer_ends_with(list/sequence)
	var/offset = length(buffer) - length(sequence)
	if(offset < 0)
		return FALSE
	for(var/index in 1 to length(sequence))
		if(buffer[offset + index] != sequence[index])
			return FALSE
	return TRUE

/datum/net_breach/proc/finish(aborted = FALSE)
	if(finished)
		return
	finished = TRUE
	var/list/completed = list()
	for(var/list/daemon as anything in daemons)
		if(daemon["done"])
			completed += daemon["id"]
	runner?.on_breach_finished(src, completed, aborted)
	qdel(src)

/datum/net_breach/ui_state(mob/user)
	return GLOB.conscious_state

/datum/net_breach/ui_status(mob/user, datum/ui_state/state)
	if(user != runner)
		return UI_CLOSE
	return ..()

/datum/net_breach/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "BreachProtocol", "Протокол взлома")
	ui.open()
	user.playsound_local(get_turf(user), 'sound/machines/terminal_on.ogg', 50, FALSE)

/datum/net_breach/ui_close(mob/user)
	finish(aborted = TRUE)

/datum/net_breach/ui_data(mob/user)
	return list(
		"zone" = target_area.name,
		"black" = tier == NET_ICE_BLACK,
		"grid" = grid,
		"used" = used,
		"axis_row" = axis_row,
		"active" = active_line - 1,
		"buffer" = buffer,
		"buffer_size" = buffer_size,
		"daemons" = daemons,
		"time_left" = max(deadline - world.time, 0),
		"time_limit" = time_limit,
	)

/datum/net_breach/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	switch(action)
		if("pick")
			select_cell(text2num(params["row"]) + 1, text2num(params["column"]) + 1)
		if("complete")
			finish()
	return TRUE
