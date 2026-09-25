/datum/fit_step/proc/apply(datum/fit_context/context)
	return

/datum/fit_step/pixel_map/apply(datum/fit_context/context)
	var/list/map = context.pixel_map
	if(!length(map))
		return
	var/list/mapped = context.source.Copy()
	var/list/rows = new(context.height)
	var/list/vertical_rows = new(context.height)
	var/mapped_pixels = 0
	for(var/index in 1 to length(map))
		var/origin = map[index]
		if(isnull(origin))
			continue
		mapped_pixels++
		mapped[index] = origin ? context.source[origin] : null
		if(!origin)
			continue
		var/row = round((index - 1) / context.width) + 1
		if(round((origin - 1) / context.width) + 1 == row)
			rows[row] = TRUE
		else
			vertical_rows[row] = TRUE
	for(var/row in 1 to context.height)
		if(vertical_rows[row])
			rows[row] = FALSE
	var/list/corrected = mapped_pixels == length(mapped) ? mapped : refit(context.source, mapped, context.width, context.height, rows)
	for(var/index in 1 to length(map))
		if(!isnull(map[index]) || corrected[index] != mapped[index])
			context.working[index] = !isnull(map[index]) && !map[index] ? null : corrected[index]

/datum/fit_step/pixel_map/proc/refit(list/source, list/adapted, width, height, list/rows)
	var/list/counts = list()
	var/list/edges = list()
	var/list/light = list()
	for(var/list/grid in list(source, adapted))
		for(var/y in 1 to height)
			for(var/x in 1 to width)
				var/index = width * (y - 1) + x
				var/pixel = grid[index]
				if(!pixel)
					continue
				counts[pixel] = (counts[pixel] || 0) + 1
				if(isnull(light[pixel]))
					var/list/channels = rgb2num(pixel)
					light[pixel] = 299 * channels[1] + 587 * channels[2] + 114 * channels[3]
				if(x == 1 || x == width || y == 1 || y == height || !grid[index - 1] || !grid[index + 1] || !grid[index - width] || !grid[index + width])
					edges[pixel] = TRUE
	var/list/result = adapted.Copy()
	for(var/y in 1 to height)
		if(!rows[y])
			continue
		var/offset = width * (y - 1)
		var/source_first = 0
		var/source_last = 0
		var/target_first = 0
		var/target_last = 0
		for(var/x in 1 to width)
			if(source[offset + x])
				source_first ||= x
				source_last = x
			if(adapted[offset + x])
				target_first ||= x
				target_last = x
		if(!source_first || !target_first)
			continue
		var/list/original = source.Copy(offset + source_first, offset + source_last + 1)
		var/extra = target_last - target_first - (source_last - source_first)
		if(extra < 0 || extra > FIT_REFIT_MAX_GROWTH)
			continue
		var/list/rebuilt = original.Copy()
		if(extra)
			var/list/candidates = list()
			for(var/gap in 2 to length(original))
				var/left = original[gap - 1]
				var/right = original[gap]
				if(!left || !right)
					continue
				var/color = left
				var/cost = 0
				if(left != right)
					var/high = light[left] >= light[right] ? left : right
					var/low = high == left ? right : left
					color = counts[high] >= FIT_REFIT_COMMON_COLOR ? high : low
					cost = FIT_REFIT_COLOR_COST
				if(edges[color])
					cost += FIT_REFIT_EDGE_COST
				if(counts[color] < FIT_REFIT_RARE_COLOR)
					cost += FIT_REFIT_RARE_COST
				candidates += list(list(gap, color, cost))
			if(!length(candidates))
				continue
			var/list/insertions = new(length(original))
			for(var/number in 1 to extra)
				var/ideal = number * length(original) / (extra + 1)
				var/list/best
				var/best_cost = INFINITY
				var/best_distance = INFINITY
				for(var/list/candidate in candidates)
					var/distance = abs(candidate[1] - 1 - ideal)
					var/cost = candidate[3] + FIT_REFIT_DISTANCE_COST * distance
					if(cost < best_cost || (cost == best_cost && distance < best_distance))
						best = candidate
						best_cost = cost
						best_distance = distance
				var/list/at_gap = insertions[best[1]]
				if(!at_gap)
					at_gap = list()
					insertions[best[1]] = at_gap
				at_gap += best[2]
			rebuilt = list()
			for(var/index in 1 to length(original))
				var/list/at_gap = insertions[index]
				if(at_gap)
					rebuilt += at_gap
				rebuilt.len++
				rebuilt[length(rebuilt)] = original[index]
		for(var/index in 1 to length(rebuilt))
			if(rebuilt[index] || !adapted[offset + target_first + index - 1])
				continue
			var/left = index > 1 ? rebuilt[index - 1] : null
			var/right = index < length(rebuilt) ? rebuilt[index + 1] : null
			rebuilt[index] = left && right ? (light[left] >= light[right] ? left : right) : (left || right || adapted[offset + target_first + index - 1])
		for(var/index in 1 to length(rebuilt))
			result[offset + target_first + index - 1] = rebuilt[index]
	return result

/datum/fit_step/cover_parts
	var/list/part_groups = list(list("torso_m"), list("groin_m"), list("l_leg", "r_leg"), list("l_arm", "r_arm"))
	var/list/bare_states = list("head_m", "l_hand", "r_hand")
	var/list/reference_masks
	var/list/target_masks

/datum/fit_step/cover_parts/apply(datum/fit_context/context)
	var/datum/species_fit/profile = context.profile
	var/key = "[context.fit_dir]"
	if(!reference_masks)
		reference_masks = list()
		target_masks = list()
		for(var/fit_dir in GLOB.cardinal)
			var/list/reference_parts = list()
			var/list/target_parts = list()
			var/list/reference_bare = profile.build_mask(profile.reference_sheet, bare_states, fit_dir)
			var/list/target_bare = profile.build_mask(profile.target_sheet, bare_states, fit_dir)
			for(var/list/part_states in part_groups)
				var/list/reference_mask = profile.build_mask(profile.reference_sheet, part_states, fit_dir)
				var/list/target_mask = profile.build_mask(profile.target_sheet, part_states, fit_dir)
				for(var/index in 1 to length(reference_mask))
					if(reference_bare[index])
						reference_mask[index] = null
					if(target_bare[index])
						target_mask[index] = null
				reference_parts += list(reference_mask)
				target_parts += list(target_mask)
			reference_masks["[fit_dir]"] = reference_parts
			target_masks["[fit_dir]"] = target_parts
	var/list/snapshot = context.working.Copy()
	var/list/reference_parts = reference_masks[key]
	var/list/target_parts = target_masks[key]
	for(var/part in 1 to length(target_parts))
		if(profile.covered_share(context.source, reference_parts[part]) < FIT_COVER_PART_SHARE)
			continue
		cover_mask(context, reference_parts[part], target_parts[part], snapshot)

/datum/fit_step/cover_parts/proc/cover_mask(datum/fit_context/context, list/reference_mask, list/target_mask, list/snapshot)
	for(var/index in 1 to length(target_mask))
		if(!target_mask[index] || snapshot[index])
			continue
		var/x = (index - 1) % context.width + 1
		for(var/distance in 1 to FIT_COVER_PART_REACH)
			var/left = x - distance >= 1 ? snapshot[index - distance] : null
			var/right = x + distance <= context.width ? snapshot[index + distance] : null
			if(left || right)
				context.working[index] = left || right
				break

/datum/fit_step/cover_parts/extremities
	part_groups = list(list("l_hand"), list("r_hand"), list("l_foot"), list("r_foot"))
	bare_states = list("head_m")

/datum/fit_step/cover_parts/extremities/cover_mask(datum/fit_context/context, list/reference_mask, list/target_mask, list/snapshot)
	var/list/reference_rows = context.profile.mask_rows(reference_mask)
	var/list/target_rows = context.profile.mask_rows(target_mask)
	for(var/row in 1 to length(target_rows))
		var/y = target_rows[row]
		var/from_y = reference_rows[1 + round((row - 1) * (length(reference_rows) - 1) / max(1, length(target_rows) - 1), 1)]
		var/list/reference_columns = list()
		var/list/target_columns = list()
		for(var/x in 1 to context.width)
			if(reference_mask[context.width * (from_y - 1) + x])
				reference_columns += x
			if(target_mask[context.width * (y - 1) + x])
				target_columns += x
		for(var/column in 1 to length(target_columns))
			var/index = context.width * (y - 1) + target_columns[column]
			if(snapshot[index])
				continue
			var/from_x = reference_columns[1 + round((column - 1) * (length(reference_columns) - 1) / max(1, length(target_columns) - 1), 1)]
			context.working[index] = context.source[context.width * (from_y - 1) + from_x]

/datum/fit_step/proc/clear_added(datum/fit_context/context, list/mask)
	for(var/index in 1 to length(mask))
		if(mask[index] && !context.source[index])
			context.working[index] = null

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
			if(to_column < from_column)
				continue
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

/datum/fit_step/head_warp/apply(datum/fit_context/context)
	if(!context.warps_head)
		return
	var/list/head_shift = context.head_shift()
	var/list/shifted = context.working.Copy()
	for(var/y in 1 to context.height)
		var/shift = head_shift[y]
		if(!shift)
			continue
		var/row_offset = context.width * (y - 1)
		for(var/x in 1 to context.width)
			var/column = x - shift
			shifted[row_offset + x] = (column >= 1 && column <= context.width) ? context.working[row_offset + column] : null
	context.working = shifted

/datum/fit_step/trim/apply(datum/fit_context/context)
	clear_added(context, context.shrunk_mask())

/datum/fit_step/head_trim/apply(datum/fit_context/context)
	if(context.dresses_head)
		return
	clear_added(context, context.target_head_mask())

/datum/fit_step/bare_part_trim/apply(datum/fit_context/context)
	var/list/target_parts = context.target_bare_masks()
	for(var/part in 1 to length(target_parts))
		if(context.dressed_parts[part])
			continue
		clear_added(context, target_parts[part])

/datum/fit_step/head_offset
	var/list/offsets
	var/list/uncovered_masks

/datum/fit_step/head_offset/apply(datum/fit_context/context)
	var/key = "[context.fit_dir]"
	if(!offsets)
		build_offsets(context.profile)
	var/list/offset = offsets[key]
	var/list/shifted = new(length(context.working))
	for(var/y in 1 to context.height)
		var/from_y = y - offset[2]
		if(from_y < 1 || from_y > context.height)
			continue
		for(var/x in 1 to context.width)
			var/from_x = x - offset[1]
			if(offset[3] && from_x > offset[3])
				from_x--
			if(from_x < 1 || from_x > context.width)
				continue
			shifted[context.width * (y - 1) + x] = context.working[context.width * (from_y - 1) + from_x]
	context.working = shifted.Copy()
	var/list/uncovered = uncovered_masks[key]
	for(var/index in 1 to length(uncovered))
		if(!uncovered[index] || shifted[index])
			continue
		var/x = (index - 1) % context.width + 1
		if(x > 1 && shifted[index - 1])
			context.working[index] = shifted[index - 1]
		else if(x < context.width && shifted[index + 1])
			context.working[index] = shifted[index + 1]
	var/head_first = offset[4]
	var/head_last = offset[5]
	var/garment_first = context.width
	var/garment_last = 1
	for(var/index in 1 to length(context.working))
		if(!context.working[index])
			continue
		var/x = (index - 1) % context.width + 1
		garment_first = min(garment_first, x)
		garment_last = max(garment_last, x)
	var/rim = offset[3] ? FIT_HEADWEAR_RIM_WIDTH : 0
	var/left_overhang = max(0, head_first - garment_first)
	var/right_overhang = max(0, garment_last - head_last)
	var/brim_first = head_first - (left_overhang > rim ? CEILING(left_overhang * FIT_HEADWEAR_BRIM_SCALE, 1) : 0)
	var/brim_last = head_last + (right_overhang > rim ? CEILING(right_overhang * FIT_HEADWEAR_BRIM_SCALE, 1) : 0)
	if(garment_first >= brim_first && garment_last <= brim_last)
		return
	var/list/clamped = context.working.Copy()
	for(var/y in 1 to context.height)
		var/row_offset = context.width * (y - 1)
		for(var/x in 1 to context.width)
			var/from_x = x
			if(x < brim_first || x > brim_last)
				from_x = 0
			else if(x < head_first && garment_first < brim_first)
				from_x = head_first - round((head_first - x) * (head_first - garment_first) / (head_first - brim_first), 1)
			else if(x > head_last && garment_last > brim_last)
				from_x = head_last + round((x - head_last) * (garment_last - head_last) / (brim_last - head_last), 1)
			clamped[row_offset + x] = from_x ? context.working[row_offset + from_x] : null
	context.working = clamped

/datum/fit_step/head_offset/proc/build_offsets(datum/species_fit/profile)
	offsets = list()
	uncovered_masks = list()
	for(var/fit_dir in GLOB.cardinal)
		var/key = "[fit_dir]"
		var/list/reference = profile.reference_head_masks[key]
		var/list/target = profile.target_head_masks[key]
		var/list/reference_box = mask_box(reference, profile.width)
		var/list/target_box = mask_box(target, profile.width)
		var/offset_x = target_box[1] - reference_box[1]
		var/offset_y = target_box[2] - reference_box[2]
		var/split_x = 0
		if(target_box[3] - target_box[1] == reference_box[3] - reference_box[1] + 1)
			split_x = (reference_box[1] + reference_box[3]) / 2
		offsets[key] = list(offset_x, offset_y, split_x, target_box[1], target_box[3])
		var/list/uncovered = new(length(target))
		for(var/index in 1 to length(target))
			if(!target[index])
				continue
			var/x = (index - 1) % profile.width + 1 - offset_x
			if(split_x && x > split_x)
				x--
			var/y = round((index - 1) / profile.width) + 1 - offset_y
			if(x < 1 || x > profile.width || y < 1 || y > profile.height || !reference[profile.width * (y - 1) + x])
				uncovered[index] = TRUE
		uncovered_masks[key] = uncovered

/datum/fit_step/proc/mask_box(list/mask, width)
	var/first_x = INFINITY
	var/last_x = 0
	var/top_y = 0
	for(var/index in 1 to length(mask))
		if(!mask[index])
			continue
		var/x = (index - 1) % width + 1
		first_x = min(first_x, x)
		last_x = max(last_x, x)
		top_y = max(top_y, round((index - 1) / width) + 1)
	return list(first_x, top_y, last_x)

/datum/fit_step/foot_fit
	var/list/foot_groups

/datum/fit_step/foot_fit/apply(datum/fit_context/context)
	if(!foot_groups)
		build_groups(context.profile)
	var/list/fitted = new(length(context.working))
	for(var/list/group in foot_groups["[context.fit_dir]"])
		var/reference_first = group[1]
		var/reference_last = group[2]
		var/target_first = group[3]
		var/target_last = group[4]
		var/low = group[5]
		var/high = group[6]
		var/paired = group[7]
		var/list/target_mask = group[9]
		var/covers_foot = context.profile.covered_share(context.source, group[8]) >= FIT_COVER_PART_SHARE
		var/scale = (target_last - target_first + 1) / (reference_last - reference_first + 1)
		for(var/y in 1 to context.height)
			var/row_offset = context.width * (y - 1)
			var/garment_first = 0
			var/garment_last = 0
			for(var/x in low to high)
				if(context.working[row_offset + x])
					garment_first ||= x
					garment_last = x
			if(!garment_first)
				continue
			var/fitted_first = garment_first + target_first - reference_first
			var/fitted_last = garment_last + target_last - reference_last
			if(paired)
				if(garment_first < reference_first)
					fitted_first = target_first - 1 - floor((reference_first - garment_first) * scale)
				else
					fitted_first = target_first + round((garment_first - reference_first) * scale, 1)
				if(garment_last > reference_last)
					fitted_last = target_last + 1 + floor((garment_last - reference_last) * scale)
				else
					fitted_last = target_last - round((reference_last - garment_last) * scale, 1)
			if(covers_foot)
				for(var/x in target_first to target_last)
					if(target_mask[row_offset + x])
						fitted_first = min(fitted_first, x)
						fitted_last = max(fitted_last, x)
			fitted_first = max(low, fitted_first)
			fitted_last = min(high, fitted_last)
			for(var/x in fitted_first to fitted_last)
				var/from_x = fitted_last == fitted_first ? garment_first : garment_first + round((x - fitted_first) * (garment_last - garment_first) / (fitted_last - fitted_first), 1)
				var/pixel = context.working[row_offset + from_x]
				if(!pixel && from_x > garment_first)
					pixel = context.working[row_offset + from_x - 1]
				if(!pixel && from_x < garment_last)
					pixel = context.working[row_offset + from_x + 1]
				if(pixel)
					fitted[row_offset + x] = pixel
	var/top_row = 0
	for(var/index in 1 to length(fitted))
		if(fitted[index])
			top_row = round((index - 1) / context.width) + 1
	var/squashed_top = max(min(top_row, FIT_SHOE_MIN_ROWS), round(top_row * FIT_SHOE_HEIGHT_SCALE, 1))
	var/list/squashed = new(length(fitted))
	for(var/y in 1 to squashed_top)
		var/from_y = squashed_top == 1 ? 1 : 1 + round((y - 1) * (top_row - 1) / (squashed_top - 1), 1)
		for(var/x in 1 to context.width)
			squashed[context.width * (y - 1) + x] = fitted[context.width * (from_y - 1) + x]
	context.working = squashed

/datum/fit_step/foot_fit/proc/build_groups(datum/species_fit/profile)
	foot_groups = list()
	var/half = profile.width / 2
	for(var/fit_dir in list(NORTH, SOUTH))
		var/list/groups = list()
		for(var/foot in list("l_foot", "r_foot"))
			var/list/reference_mask = profile.build_mask(profile.reference_sheet, list(foot), fit_dir)
			var/list/target_mask = profile.build_mask(profile.target_sheet, list(foot), fit_dir)
			var/list/reference_box = mask_box(reference_mask, profile.width)
			var/list/target_box = mask_box(target_mask, profile.width)
			var/left_side = reference_box[1] <= half
			groups += list(list(reference_box[1], reference_box[3], target_box[1], target_box[3], left_side ? 1 : half + 1, left_side ? half : profile.width, TRUE, reference_mask, target_mask))
		foot_groups["[fit_dir]"] = groups
	for(var/fit_dir in list(EAST, WEST))
		var/list/reference_mask = profile.build_mask(profile.reference_sheet, list("l_foot", "r_foot"), fit_dir)
		var/list/target_mask = profile.build_mask(profile.target_sheet, list("l_foot", "r_foot"), fit_dir)
		var/list/reference_box = mask_box(reference_mask, profile.width)
		var/list/target_box = mask_box(target_mask, profile.width)
		foot_groups["[fit_dir]"] = list(list(reference_box[1], reference_box[3], target_box[1], target_box[3], 1, profile.width, FALSE, reference_mask, target_mask))
