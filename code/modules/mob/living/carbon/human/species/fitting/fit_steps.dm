/datum/fit_step/proc/apply(datum/fit_context/context)
	return

/datum/fit_step/mark_bare_skin/apply(datum/fit_context/context)
	var/list/reference_mask = context.reference_mask()
	var/list/target_mask = context.target_mask()
	var/list/dirty = new(context.height)
	for(var/y in 1 to context.height)
		var/row_offset = context.width * (y - 1)
		for(var/x in 1 to context.width)
			var/index = row_offset + x
			if(target_mask[index] && !reference_mask[index] && !context.working[index])
				dirty[y] = TRUE
				break
	context.dirty_rows = dirty

/datum/fit_step/warp/apply(datum/fit_context/context)
	var/list/warped = context.working.Copy()
	for(var/y in 1 to context.height)
		if(context.dirty_rows && !context.dirty_rows[y])
			continue
		var/row_offset = context.width * (y - 1)
		for(var/x in 1 to context.width)
			warped[row_offset + x] = context.working[row_offset + context.warp_map[row_offset + x]]
	context.working = warped

/datum/fit_step/edge_repair/apply(datum/fit_context/context)
	for(var/y in 1 to context.height)
		if(context.dirty_rows && !context.dirty_rows[y])
			continue
		var/row_offset = context.width * (y - 1)
		for(var/list/run in row_runs(context.working, row_offset, context.width))
			var/from_column = context.warp_map[row_offset + run[1]]
			var/to_column = context.warp_map[row_offset + run[2]]
			while(from_column > 1 && context.source[row_offset + from_column - 1])
				from_column--
			while(to_column < context.width && context.source[row_offset + to_column + 1])
				to_column++
			var/new_width = run[2] - run[1] + 1
			if(new_width <= to_column - from_column + 1)
				continue
			var/list/columns = rebuild_run(context.source, row_offset, from_column, to_column, new_width)
			for(var/offset in 1 to length(columns))
				if(!columns[offset])
					continue
				context.working[row_offset + run[1] + offset - 1] = columns[offset]

/datum/fit_step/edge_repair/proc/row_runs(list/pixels, row_offset, width)
	var/list/found = list()
	var/start = 0
	for(var/x in 1 to width)
		if(pixels[row_offset + x])
			if(!start)
				start = x
		else if(start)
			found += list(list(start, x - 1))
			start = 0
	if(start)
		found += list(list(start, width))
	return found

/datum/fit_step/edge_repair/proc/rebuild_run(list/pixels, row_offset, from_column, to_column, target_width)
	var/list/colors = list()
	var/list/counts = list()
	for(var/x in from_column to to_column)
		var/pixel = pixels[row_offset + x]
		if(length(colors) && colors[length(colors)] == pixel)
			counts[length(counts)]++
			continue
		colors.len++
		colors[length(colors)] = pixel
		counts += 1
	stretch_segments(colors, counts, target_width - (to_column - from_column + 1))
	var/list/rebuilt = new(target_width)
	var/index = 1
	for(var/segment in 1 to length(colors))
		for(var/repeat in 1 to counts[segment])
			rebuilt[index++] = colors[segment]
	return rebuilt

/datum/fit_step/edge_repair/proc/stretch_segments(list/colors, list/counts, extra)
	if(extra <= 0)
		return
	var/first = length(counts) > 2 ? 2 : 1
	var/last = length(counts) > 2 ? length(counts) - 1 : length(counts)
	var/weight = 0
	for(var/segment in first to last)
		weight += counts[segment]
	if(!weight)
		counts[max(round(length(counts) / 2), 1)] += extra
		return
	var/given = 0
	var/list/remainders = new(length(counts))
	for(var/segment in first to last)
		var/share = round(extra * counts[segment] / weight)
		remainders[segment] = (extra * counts[segment]) % weight
		counts[segment] += share
		given += share
	while(given < extra)
		var/best = 0
		for(var/segment in first to last)
			if(!best || remainders[segment] > remainders[best])
				best = segment
		counts[best]++
		remainders[best] = -1
		given++

/datum/fit_step/span_remap/apply(datum/fit_context/context)
	if(!context.span_map)
		return
	var/list/remapped = context.working.Copy()
	for(var/y in 1 to context.height)
		var/row_offset = context.width * (y - 1)
		for(var/x in 1 to context.width)
			var/index = row_offset + x
			var/source_row = context.span_map[index]
			if(!source_row)
				continue
			remapped[index] = context.working[context.width * (source_row - 1) + x]
	context.working = remapped

/datum/fit_step/vertical_warp/apply(datum/fit_context/context)
	if(!context.row_map)
		return
	var/list/stretched = context.working.Copy()
	for(var/y in 1 to context.height)
		var/row_offset = context.width * (y - 1)
		for(var/x in 1 to context.width)
			var/index = row_offset + x
			var/source_row = context.row_map[index]
			if(!source_row || context.working[index])
				continue
			stretched[index] = context.working[context.width * (source_row - 1) + x]
	context.working = stretched

/datum/fit_step/cover_skin/apply(datum/fit_context/context)
	var/list/reference_mask = context.reference_mask()
	var/list/target_mask = context.target_mask()
	for(var/y in 1 to context.height)
		var/row_offset = context.width * (y - 1)
		for(var/x in 1 to context.width)
			var/index = row_offset + x
			if(context.working[index] || !target_mask[index] || reference_mask[index])
				continue
			if(x > 1 && context.working[index - 1])
				context.working[index] = context.working[index - 1]
			else if(x < context.width && context.working[index + 1])
				context.working[index] = context.working[index + 1]

/datum/fit_step/keep_solid/apply(datum/fit_context/context)
	for(var/index in 1 to length(context.working))
		if(context.working[index] || !context.source[index])
			continue
		if(context.span_map?[index] && !holed(context, index))
			continue
		context.working[index] = context.source[index]

/datum/fit_step/keep_solid/proc/holed(datum/fit_context/context, index)
	var/tier = context.pixel_tier[index]
	var/above = index - context.width
	var/below = index + context.width
	if(above >= 1 && context.working[above] && context.pixel_tier[above] == tier)
		return TRUE
	if(below <= length(context.working) && context.working[below] && context.pixel_tier[below] == tier)
		return TRUE
	return FALSE

/datum/fit_step/trim/apply(datum/fit_context/context)
	var/list/shrunk = context.shrunk_mask()
	for(var/index in 1 to length(context.working))
		if(shrunk[index])
			context.working[index] = null
