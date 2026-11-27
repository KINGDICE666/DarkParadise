#define MAP_DMM "dmm"
#define MAP_TGM "tgm"

#define MAPLOADING_CHECK_TICK \
	if(TICK_CHECK) { \
		if(defer_init) { \
			SSatoms.map_loader_stop(); \
			stoplag(); \
			SSatoms.map_loader_begin(); \
		} else { \
			stoplag(); \
		} \
	}

GLOBAL_VAR_INIT(use_preloader, FALSE)
GLOBAL_LIST_INIT(_preloader_attributes, null)
GLOBAL_VAR(_preloader_path)
GLOBAL_LIST_EMPTY(map_model_default)

/world/proc/preloader_setup(list/the_attributes, path)
	if(!length(the_attributes))
		return
	GLOB.use_preloader = TRUE
	GLOB._preloader_attributes = the_attributes
	GLOB._preloader_path = path

/world/proc/preloader_load(atom/what)
	GLOB.use_preloader = FALSE
	var/list/attributes = GLOB._preloader_attributes
	var/json_data = attributes["map_json_data"]
	if(json_data)
		json_data = dmm_decode(json_data)
		try
			what.deserialize(json_decode(json_data))
		catch(var/exception/deserialize_error)
			stack_trace("Bad json data: '[json_data]'")
			throw deserialize_error
	for(var/attribute in attributes)
		if(attribute == "map_json_data")
			continue
		var/value = attributes[attribute]
		if(isnull(value))
			continue
		if(islist(value))
			value = deep_copy_list(value)
		what.vars[attribute] = value

/datum/grid_set
	var/xcrd
	var/ycrd
	var/zcrd
	var/gridLines

/datum/parsed_map
	var/original_path
	var/map_format
	var/key_len = 0
	var/line_len = 0
	var/expanded_y = FALSE
	var/expanded_x = FALSE
	var/list/grid_models = list()
	var/list/gridSets = list()
	var/list/area/loaded_areas = list()
	var/list/modelCache
	var/list/parsed_bounds
	var/list/bounds
	var/defer_init = FALSE

	var/static/regex/dmm_regex = new(@'"([a-zA-Z]+)" = (?:\(\n|\()((?:.|\n)*?)\)\n(?!\t)|\((\d+),(\d+),(\d+)\) = \{"([a-zA-Z\n]*)"\}', "g")
	var/static/regex/matches_tgm = new(@'^"[A-z]*"[\s]*=[\s]*\([\s]*\n', "m")
	var/static/regex/var_edits_tgm = new(@'^\t([A-z0-9]*) = (.*?);?$')
	var/static/regex/model_path = new(@'(\/[^\{]*?(?:\{.*?\})?)(?:,|$)', "g")

/datum/parsed_map/proc/copy()
	build_cache()
	var/datum/parsed_map/newfriend = new()
	newfriend.original_path = original_path
	newfriend.map_format = map_format
	newfriend.key_len = key_len
	newfriend.line_len = line_len
	newfriend.grid_models = grid_models.Copy()
	newfriend.gridSets = gridSets.Copy()
	newfriend.modelCache = modelCache.Copy()
	newfriend.parsed_bounds = parsed_bounds.Copy()
	newfriend.bounds = parsed_bounds.Copy()
	return newfriend

/proc/load_map(
	dmm_file,
	x_offset = 1,
	y_offset = 1,
	z_offset = 0,
	crop_map = FALSE,
	measure_only = FALSE,
	no_changeturf = FALSE,
	x_lower = -INFINITY,
	x_upper = INFINITY,
	y_lower = -INFINITY,
	y_upper = INFINITY,
	z_lower = -INFINITY,
	z_upper = INFINITY,
	new_z = FALSE,
	defer_init = FALSE,
)
	var/map_key = "[dmm_file]"
	if(!(map_key in GLOB.cached_maps))
		GLOB.cached_maps[map_key] = new /datum/parsed_map(dmm_file)

	var/datum/parsed_map/parsed_map = GLOB.cached_maps[map_key]
	if(isnull(parsed_map.parsed_bounds))
		return parsed_map
	parsed_map = parsed_map.copy()
	if(!measure_only)
		parsed_map.load(x_offset, y_offset, z_offset, crop_map, no_changeturf, x_lower, x_upper, y_lower, y_upper, z_lower, z_upper, new_z, defer_init)
	return parsed_map

/datum/parsed_map/New(tfile)
	if(isnull(tfile))
		return
	if(isfile(tfile))
		original_path = "[tfile]"
		var/last_char = copytext(original_path, -1)
		if(last_char == "/" || last_char == "\\")
			log_debug("Attempted to load map template without filename (Attempted [original_path])")
			return
		var/file_text
		if(fexists("[copytext(original_path, 1, -4)].jsonc"))
			file_text = mapmanip_read_dmm(original_path)
		if(!file_text)
			file_text = WRAP_FILE2TEXT(tfile)
		tfile = file_text
	if(!length(tfile))
		CRASH("Map path '[original_path]' does not exist!")

	src.bounds = parsed_bounds = list(1.#INF, 1.#INF, 1.#INF, -1.#INF, -1.#INF, -1.#INF)

	if(findtext(tfile, matches_tgm))
		map_format = MAP_TGM
	else
		map_format = MAP_DMM

	var/list/bounds = src.bounds
	var/list/grid_models = src.grid_models
	var/key_len = src.key_len
	var/line_len = src.line_len

	var/stored_index = 1
	var/list/regexOutput
	while(dmm_regex.Find(tfile, stored_index))
		stored_index = dmm_regex.next
		regexOutput = dmm_regex.group

		if(regexOutput[1])
			var/key = regexOutput[1]
			if(grid_models[key])
				continue
			if(key_len != length(key))
				if(!key_len)
					key_len = length(key)
				else
					CRASH("Inconsistent key length in DMM")
			grid_models[key] = regexOutput[2]

		else if(regexOutput[3])
			if(!key_len)
				CRASH("Coords before model definition in DMM")

			var/curr_x = text2num(regexOutput[3])
			var/curr_y = text2num(regexOutput[4])
			var/curr_z = text2num(regexOutput[5])

			var/datum/grid_set/gridSet = new
			gridSet.xcrd = curr_x
			gridSet.ycrd = curr_y
			gridSet.zcrd = curr_z

			bounds[MAP_MINX] = min(bounds[MAP_MINX], curr_x)
			bounds[MAP_MINZ] = min(bounds[MAP_MINZ], curr_z)
			bounds[MAP_MAXZ] = max(bounds[MAP_MAXZ], curr_z)

			var/list/gridLines = splittext(regexOutput[6], "\n")
			gridSet.gridLines = gridLines

			var/leadingBlanks = 0
			while(leadingBlanks < length(gridLines) && gridLines[++leadingBlanks] == "")
			if(leadingBlanks > 1)
				gridLines.Cut(1, leadingBlanks)

			if(!length(gridLines))
				continue

			gridSets += gridSet

			if(gridLines[length(gridLines)] == "")
				gridLines.Cut(length(gridLines))

			bounds[MAP_MINY] = min(bounds[MAP_MINY], gridSet.ycrd)
			gridSet.ycrd += length(gridLines) - 1
			bounds[MAP_MAXY] = max(bounds[MAP_MAXY], gridSet.ycrd)

			if(!line_len)
				line_len = length(gridLines[1])

			var/maxx = curr_x
			if(length(gridLines))
				maxx = max(maxx, curr_x + line_len / key_len - 1)

			bounds[MAP_MAXX] = max(bounds[MAP_MAXX], maxx)
		CHECK_TICK

	if(bounds[MAP_MINX] == 1.#INF)
		src.bounds = null

	parsed_bounds = src.bounds
	src.key_len = key_len
	src.line_len = line_len

/datum/parsed_map/proc/filter_grid_sets_based_on_z_bounds(lower_z, upper_z)
	var/list/filtered_sets = list()
	for(var/datum/grid_set/grid_set as anything in gridSets)
		if(grid_set.zcrd < lower_z)
			continue
		if(grid_set.zcrd > upper_z)
			continue
		filtered_sets += grid_set
	return filtered_sets

/datum/parsed_map/proc/load(x_offset = 1, y_offset = 1, z_offset = 0, crop_map = FALSE, no_changeturf = FALSE, x_lower = -INFINITY, x_upper = INFINITY, y_lower = -INFINITY, y_upper = INFINITY, z_lower = -INFINITY, z_upper = INFINITY, new_z = FALSE, defer_init = FALSE)
	if(!z_offset)
		z_offset = world.maxz + 1
	var/watch = start_watch()
	src.defer_init = defer_init
	if(defer_init)
		SSatoms.map_loader_begin()

	var/successful = FALSE
	try
		switch(map_format)
			if(MAP_TGM)
				successful = _tgm_load(x_offset, y_offset, z_offset, crop_map, no_changeturf, x_lower, x_upper, y_lower, y_upper, z_lower, z_upper, new_z)
			else
				successful = _dmm_load(x_offset, y_offset, z_offset, crop_map, no_changeturf, x_lower, x_upper, y_lower, y_upper, z_lower, z_upper, new_z)
	catch(var/exception/load_error)
		GLOB.use_preloader = FALSE
		if(defer_init)
			SSatoms.map_loader_stop()
		throw load_error

	GLOB.use_preloader = FALSE
	log_debug("Loaded map in [stop_watch(watch)]s.")

	var/last_z = min(z_offset + parsed_bounds[MAP_MAXZ] - parsed_bounds[MAP_MINZ], world.maxz)
	if(new_z)
		for(var/z_index in z_offset to last_z)
			SSmapping.build_area_turfs(z_index)

	if(no_changeturf)
		for(var/z_index in z_offset to last_z)
			var/datum/space_level/level = GLOB.space_manager.get_zlev(z_index)
			level.build_space_destination_arrays()
	else if(bounds[MAP_MINX] != 1.#INF)
		var/list/turfs = block(
			bounds[MAP_MINX], bounds[MAP_MINY], bounds[MAP_MINZ],
			bounds[MAP_MAXX], bounds[MAP_MAXY], bounds[MAP_MAXZ]
		)
		for(var/turf/turf as anything in turfs)
			turf.AfterChange(CHANGETURF_IGNORE_AIR|CHANGETURF_KEEP_CABLING)
			MAPLOADING_CHECK_TICK

	if(defer_init)
		SSatoms.map_loader_stop()

	if(expanded_x || expanded_y)
		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_EXPANDED_WORLD_BOUNDS, expanded_x, expanded_y)

	return successful

/datum/parsed_map/proc/expand_z_levels(z_upper_parsed, crop_map)
	if(z_upper_parsed <= world.maxz || crop_map)
		return
	GLOB.space_manager.increase_max_zlevel_to(z_upper_parsed)

/datum/parsed_map/proc/_tgm_load(x_offset, y_offset, z_offset, crop_map, no_changeturf, x_lower, x_upper, y_lower, y_upper, z_lower, z_upper, new_z)
	PRIVATE_PROC(TRUE)
	var/list/modelCache = build_cache(no_changeturf)
	var/space_key = modelCache[SPACE_KEY]
	var/list/bounds
	src.bounds = bounds = list(1.#INF, 1.#INF, 1.#INF, -1.#INF, -1.#INF, -1.#INF)

	var/y_relative_to_absolute = y_offset - 1
	var/x_relative_to_absolute = x_offset - 1

	var/datum/grid_set/first_column = gridSets[1]
	var/relative_y = first_column.ycrd
	var/highest_y = relative_y + y_relative_to_absolute

	if(!crop_map && highest_y > world.maxy)
		if(new_z)
			world.increase_max_y(highest_y, map_load_z_cutoff = z_offset - 1)
		else
			world.increase_max_y(highest_y)
		expanded_y = TRUE

	var/y_skip_above = min(world.maxy - y_relative_to_absolute, y_upper, relative_y)
	var/y_starting_skip = relative_y - y_skip_above
	highest_y -= y_starting_skip

	var/line_count = length(first_column.gridLines)
	var/lowest_y = relative_y - (line_count - 1)
	var/y_ending_skip = max(max(y_lower, 1 - y_relative_to_absolute) - lowest_y, 0)

	var/x_delta_with = x_upper
	if(crop_map)
		x_delta_with = min(x_delta_with, world.maxx)

	var/datum/grid_set/last_column = gridSets[length(gridSets)]
	var/final_x = last_column.xcrd + x_relative_to_absolute

	if(final_x > x_delta_with)
		var/delta = max(final_x - x_delta_with, 0)
		final_x -= delta
	if(final_x > world.maxx && !crop_map)
		if(new_z)
			world.increase_max_x(final_x, map_load_z_cutoff = z_offset - 1)
		else
			world.increase_max_x(final_x)
		expanded_x = TRUE

	var/lowest_x = max(x_lower, 1 - x_relative_to_absolute)

	var/grid_z_offset = z_offset - 1
	var/z_upper_set = z_upper < INFINITY
	var/z_lower_set = z_lower > -INFINITY

	var/map_bounds_z_max = last_column.zcrd
	var/z_upper_parsed = map_bounds_z_max + z_offset - 1
	if(z_upper_set)
		z_upper_parsed -= map_bounds_z_max - z_upper
	if(z_lower_set)
		var/offset_amount = z_lower - 1
		z_upper_parsed -= offset_amount
		grid_z_offset -= offset_amount

	var/list/target_grid_sets = gridSets
	if(z_lower_set || z_upper_set)
		target_grid_sets = filter_grid_sets_based_on_z_bounds(z_lower, z_upper)

	expand_z_levels(z_upper_parsed, crop_map)

	for(var/datum/grid_set/gset as anything in target_grid_sets)
		var/true_xcrd = gset.xcrd + x_relative_to_absolute

		if(final_x < true_xcrd || lowest_x > gset.xcrd)
			continue

		var/zcrd = gset.zcrd + grid_z_offset
		if(zcrd > world.maxz)
			continue

		var/first_found = FALSE
		var/first_y = 0
		var/last_y = 0

		var/ycrd = highest_y
		for(var/i in 1 + y_starting_skip to line_count - y_ending_skip)
			if(gset.gridLines[i] == space_key && no_changeturf)
				ycrd--
				MAPLOADING_CHECK_TICK
				continue

			var/list/cache = modelCache[gset.gridLines[i]]
			if(!cache)
				CRASH("Undefined model key in DMM: [gset.gridLines[i]]. Map file: [original_path].")
			build_coordinate(cache, locate(true_xcrd, ycrd, zcrd), no_changeturf, new_z)

			if(!first_found)
				first_found = TRUE
				first_y = ycrd
			last_y = ycrd
			ycrd--
			MAPLOADING_CHECK_TICK

		if(first_found)
			bounds[MAP_MINX] = min(bounds[MAP_MINX], true_xcrd)
			bounds[MAP_MINY] = min(bounds[MAP_MINY], last_y)
			bounds[MAP_MINZ] = min(bounds[MAP_MINZ], zcrd)
			bounds[MAP_MAXX] = max(bounds[MAP_MAXX], true_xcrd)
			bounds[MAP_MAXY] = max(bounds[MAP_MAXY], first_y)
			bounds[MAP_MAXZ] = max(bounds[MAP_MAXZ], zcrd)
	return TRUE

/datum/parsed_map/proc/_dmm_load(x_offset, y_offset, z_offset, crop_map, no_changeturf, x_lower, x_upper, y_lower, y_upper, z_lower, z_upper, new_z)
	PRIVATE_PROC(TRUE)
	var/list/modelCache = build_cache(no_changeturf)
	var/space_key = modelCache[SPACE_KEY]
	var/list/bounds
	var/key_len = src.key_len
	src.bounds = bounds = list(1.#INF, 1.#INF, 1.#INF, -1.#INF, -1.#INF, -1.#INF)

	var/y_relative_to_absolute = y_offset - 1
	var/x_relative_to_absolute = x_offset - 1
	var/line_len = src.line_len

	var/grid_z_offset = z_offset - 1
	var/z_upper_set = z_upper < INFINITY
	var/z_lower_set = z_lower > -INFINITY

	var/map_bounds_z_max = 1
	for(var/datum/grid_set/grid_set as anything in gridSets)
		map_bounds_z_max = max(map_bounds_z_max, grid_set.zcrd)

	var/z_upper_parsed = map_bounds_z_max + z_offset - 1
	if(z_upper_set)
		z_upper_parsed -= map_bounds_z_max - z_upper
	if(z_lower_set)
		var/offset_amount = z_lower - 1
		z_upper_parsed -= offset_amount
		grid_z_offset -= offset_amount

	var/list/target_grid_sets = gridSets
	if(z_lower_set || z_upper_set)
		target_grid_sets = filter_grid_sets_based_on_z_bounds(z_lower, z_upper)

	expand_z_levels(z_upper_parsed, crop_map)

	for(var/datum/grid_set/gset as anything in target_grid_sets)
		var/relative_x = gset.xcrd
		var/relative_y = gset.ycrd
		var/true_xcrd = relative_x + x_relative_to_absolute
		var/ycrd = relative_y + y_relative_to_absolute
		var/zcrd = gset.zcrd + grid_z_offset
		if(zcrd > world.maxz)
			continue
		if(!crop_map && ycrd > world.maxy)
			if(new_z)
				world.increase_max_y(ycrd, map_load_z_cutoff = z_offset - 1)
			else
				world.increase_max_y(ycrd)
			expanded_y = TRUE

		var/y_skip_above = min(world.maxy - y_relative_to_absolute, y_upper, relative_y)
		var/y_starting_skip = relative_y - y_skip_above
		ycrd -= y_starting_skip

		var/line_count = length(gset.gridLines)
		var/lowest_y = relative_y - (line_count - 1)
		var/y_ending_skip = max(max(y_lower, 1 - y_relative_to_absolute) - lowest_y, 0)

		var/starting_x_delta = max(max(x_lower, 1 - x_relative_to_absolute) - relative_x, 0)
		var/x_starting_skip = starting_x_delta * key_len
		true_xcrd += starting_x_delta

		var/x_target = line_len - key_len + 1
		var/x_step_count = ROUND_UP(x_target / key_len)
		var/final_x = relative_x + (x_step_count - 1)
		var/x_delta_with = x_upper
		if(crop_map)
			x_delta_with = min(x_delta_with, world.maxx)
		if(final_x > x_delta_with)
			var/delta = max(final_x - x_delta_with, 0)
			x_step_count -= delta
			final_x -= delta
			x_target = x_step_count * key_len
		if(final_x > world.maxx && !crop_map)
			if(new_z)
				world.increase_max_x(final_x, map_load_z_cutoff = z_offset - 1)
			else
				world.increase_max_x(final_x)
			expanded_x = TRUE

		var/first_found = FALSE
		var/first_x = 0
		var/first_y = 0
		var/last_x = 0
		var/last_y = 0

		for(var/i in 1 + y_starting_skip to line_count - y_ending_skip)
			var/line = gset.gridLines[i]

			var/xcrd = true_xcrd
			for(var/tpos in 1 + x_starting_skip to x_target step key_len)
				var/model_key = copytext(line, tpos, tpos + key_len)
				if(model_key == space_key && no_changeturf)
					MAPLOADING_CHECK_TICK
					++xcrd
					continue
				var/list/cache = modelCache[model_key]
				if(!cache)
					CRASH("Undefined model key in DMM: [model_key]. Map file: [original_path].")
				build_coordinate(cache, locate(xcrd, ycrd, zcrd), no_changeturf, new_z)

				if(!first_found)
					first_found = TRUE
					first_x = xcrd
					first_y = ycrd
				last_x = xcrd
				last_y = ycrd
				MAPLOADING_CHECK_TICK
				++xcrd
			ycrd--
			MAPLOADING_CHECK_TICK

		if(first_found)
			bounds[MAP_MINX] = min(bounds[MAP_MINX], first_x)
			bounds[MAP_MINY] = min(bounds[MAP_MINY], last_y)
			bounds[MAP_MINZ] = min(bounds[MAP_MINZ], zcrd)
			bounds[MAP_MAXX] = max(bounds[MAP_MAXX], last_x)
			bounds[MAP_MAXY] = max(bounds[MAP_MAXY], first_y)
			bounds[MAP_MAXZ] = max(bounds[MAP_MAXZ], zcrd)

	return TRUE

/datum/parsed_map/proc/build_cache(no_changeturf)
	if(map_format == MAP_TGM)
		return tgm_build_cache(no_changeturf)
	return dmm_build_cache(no_changeturf)

/datum/parsed_map/proc/tgm_build_cache(no_changeturf)
	if(modelCache)
		return modelCache
	. = modelCache = list()
	var/list/grid_models = src.grid_models
	var/set_space = FALSE
	var/static/list/default_list = GLOB.map_model_default
	var/static/list/wrapped_default_list = list(default_list)

	var/path_to_init = ""
	var/list/current_attributes
	var/editing = FALSE
	for(var/model_key in grid_models)
		var/list/lines = splittext(grid_models[model_key], "\n")
		var/list/members = list()
		var/list/members_attributes = list()

		for(var/line in lines)
			MAPLOADING_CHECK_TICK

			switch(line[length(line)])
				if(";")
					add_var_edit(line, current_attributes)
					continue
				if("{")
					editing = TRUE
					current_attributes = list()
					members_attributes += list(current_attributes)
					path_to_init = copytext(line, 1, -1)
				if(",")
					if(editing)
						editing = FALSE
						continue
					members_attributes += wrapped_default_list
					path_to_init = copytext(line, 1, -1)
				if("}")
					if(editing && line != "\t}")
						add_var_edit(line, current_attributes)
						continue
					if(editing)
						editing = FALSE
						continue
					stack_trace("Ended a line on just a }, with no ongoing edit in [original_path]")
				else
					if(editing)
						add_var_edit(line, current_attributes)
						continue

					members_attributes += wrapped_default_list
					path_to_init = line

			var/atom_def = text2path(path_to_init)
			if(!ispath(atom_def, /atom))
				members_attributes.len--
				stack_trace("Bad path: [path_to_init] | Model key: [model_key] | Map file: [original_path]")
				continue
			members += atom_def

		if(!set_space \
			&& no_changeturf \
			&& members_attributes.len == 2 \
			&& members.len == 2 \
			&& members_attributes[1] == default_list \
			&& members_attributes[2] == default_list \
			&& members[2] == world.area \
			&& members[1] == world.turf
		)
			set_space = TRUE
			.[SPACE_KEY] = model_key
			continue

		.[model_key] = list(members, members_attributes)
	return .

/datum/parsed_map/proc/add_var_edit(line, list/attributes)
	var_edits_tgm.Find(line)
	var/value = parse_constant(var_edits_tgm.group[2])
	if(istext(value))
		value = apply_text_macros(value)
	attributes[var_edits_tgm.group[1]] = value

/datum/parsed_map/proc/dmm_build_cache(no_changeturf)
	if(modelCache)
		return modelCache
	. = modelCache = list()
	var/list/grid_models = src.grid_models
	var/set_space = FALSE
	var/static/list/default_list = GLOB.map_model_default
	for(var/model_key in grid_models)
		var/list/members = list()
		var/list/members_attributes = list()

		var/model = grid_models[model_key]
		var/model_index = 1
		while(model_path.Find(model, model_index))
			var/variables_start = 0
			var/member_string = model_path.group[1]
			model_index = model_path.next
			if(member_string[length(member_string)] == "}")
				variables_start = findtext(member_string, "{")

			var/path_text = trim(copytext(member_string, 1, variables_start))
			var/atom_def = text2path(path_text)

			if(!ispath(atom_def, /atom))
				stack_trace("Bad path: [path_text] | Model key: [model_key] | Map file: [original_path]")
				continue
			members += atom_def

			var/list/fields = default_list
			if(variables_start)
				member_string = copytext(member_string, variables_start + length(member_string[variables_start]), -length(copytext_char(member_string, -1)))
				fields = readlist(member_string, ";")
				for(var/field in fields)
					var/value = fields[field]
					if(istext(value))
						fields[field] = apply_text_macros(value)

			members_attributes += list(fields)
			MAPLOADING_CHECK_TICK

		if(!set_space \
			&& no_changeturf \
			&& members.len == 2 \
			&& members_attributes.len == 2 \
			&& length(members_attributes[1]) == 0 \
			&& length(members_attributes[2]) == 0 \
			&& (world.area in members) \
			&& (world.turf in members))
			set_space = TRUE
			.[SPACE_KEY] = model_key
			continue

		.[model_key] = list(members, members_attributes)
	return .

/datum/parsed_map/proc/build_coordinate(list/model, turf/crds, no_changeturf, new_z)
	if(!crds)
		return
	var/index
	var/list/members = model[1]
	var/list/members_attributes = model[2]

	var/static/list/default_list = GLOB.map_model_default

	index = members.len
	var/area/old_area
	if(members[index] != /area/template_noop)
		if(members_attributes[index] != default_list)
			world.preloader_setup(members_attributes[index], members[index])
		var/area/area_instance = loaded_areas[members[index]]
		if(!area_instance)
			var/area_type = members[index]
			area_instance = GLOB.areas_by_type[area_type]
			if(!area_instance)
				area_instance = new area_type(null)
				if(!area_instance)
					CRASH("[area_type] failed to be new'd, what'd you do?")
			loaded_areas[area_type] = area_instance

		if(!new_z)
			old_area = crds.loc
			LISTASSERTLEN(old_area.turfs_to_uncontain_by_zlevel, crds.z, list())
			LISTASSERTLEN(area_instance.turfs_by_zlevel, crds.z, list())
			old_area.turfs_to_uncontain_by_zlevel[crds.z] += crds
			area_instance.turfs_by_zlevel[crds.z] += crds
		area_instance.contents.Add(crds)

		if(GLOB.use_preloader)
			world.preloader_load(area_instance)

	index--
	var/atom/instance
	if(members[index] != /turf/template_noop)
		var/turf_path = members[index]
		if(turf_path == /turf/simulated/floor/lava/lava_land_surface)
			turf_path = SSmapping.lavaland_theme?.primary_turf_type
		if(turf_path)
			if(members_attributes[index] != default_list)
				world.preloader_setup(members_attributes[index], turf_path)

			if(no_changeturf)
				instance = create_atom(turf_path, crds)
			else
				instance = crds.ChangeTurf(turf_path, defer_change = TRUE, keep_icon = FALSE, copy_existing_baseturf = FALSE)

			if(GLOB.use_preloader && instance)
				world.preloader_load(instance)
	else if(!no_changeturf && old_area)
		crds.on_change_area(old_area, crds.loc)
	MAPLOADING_CHECK_TICK

	for(var/atom_index in 1 to index - 1)
		if(members_attributes[atom_index] != default_list)
			world.preloader_setup(members_attributes[atom_index], members[atom_index])

		instance = create_atom(members[atom_index], crds)

		if(GLOB.use_preloader && instance)
			world.preloader_load(instance)
		MAPLOADING_CHECK_TICK

/datum/parsed_map/proc/create_atom(path, crds)
	set waitfor = FALSE
	. = new path (crds)

/datum/parsed_map/proc/find_next_delimiter_position(text as text, initial_position as num, delimiter = ",", opening_escape = "\"", closing_escape = "\"")
	var/position = initial_position
	var/next_delimiter = findtext(text, delimiter, position, 0)
	var/next_opening = findtext(text, opening_escape, position, 0)

	while((next_opening != 0) && (next_opening < next_delimiter))
		position = findtext(text, closing_escape, next_opening + 1, 0) + 1
		next_delimiter = findtext(text, delimiter, position, 0)
		next_opening = findtext(text, opening_escape, position, 0)

	return next_delimiter

/datum/parsed_map/proc/readlist(text as text, delimiter = ",")
	. = list()
	if(!text)
		return

	var/position
	var/old_position = 1
	while(position != 0)
		position = find_next_delimiter_position(text, old_position, delimiter)

		var/equal_position = find_next_delimiter_position(text, old_position, "=")
		var/trim_left = trim(copytext(text, old_position, (equal_position ? equal_position : position)))
		if(!trim_left)
			if(position)
				old_position = position + length(text[position])
			continue

		var/is_simple = TRUE
		var/trim_right = trim_left
		if(equal_position)
			trim_right = trim(copytext(text, equal_position + length(text[equal_position]), position))
			is_simple = FALSE

		if(copytext(trim_right, 1, 6) == "list(")
			var/start_index = is_simple ? old_position : equal_position + length(text[equal_position])
			var/opening_count = 0
			var/closing_count = 0
			var/index = start_index
			var/begin = FALSE
			while(!begin || (opening_count != closing_count))
				var/char = text[index]
				if(char == "(")
					opening_count += 1
					begin = TRUE
				else if(char == ")")
					closing_count += 1
				index += length(char)
			trim_right = trim(copytext(text, start_index, index))
			if(is_simple)
				trim_left = trim_right
			if(index >= length(text))
				position = 0
			else
				old_position = index + length(text[index])
		else if(position)
			old_position = position + length(text[position])

		var/left_constant = parse_constant(trim_left)
		if(is_simple)
			. += list(left_constant)
		else
			.[left_constant] = parse_constant(trim_right)

/datum/parsed_map/proc/parse_constant(text)
	if(!text)
		return ""

	var/num = text2num(text)
	if(isnum(num))
		return num

	if(text[1] == "\"")
		return unescape_string(copytext(text, 2, -1))

	if(copytext(text, 1, 3) == "{\"")
		return unescape_string(copytext(text, 3, -2))

	if(copytext(text, 1, 6) == "list(")
		return readlist(copytext(text, 6, -1))

	var/path = text2path(text)
	if(ispath(path))
		return path

	if(text[1] == "'")
		return file(copytext_char(text, 2, -1))

	if(text == "null")
		return null

	return text

/datum/parsed_map/proc/unescape_string(text)
	if(findtext(text, "\\\""))
		text = replacetext(text, "\\\"", "\"")
	return dmm_decode(text)

/datum/parsed_map/Destroy()
	..()
	parsed_bounds?.Cut()
	bounds?.Cut()
	grid_models.Cut()
	gridSets.Cut()
	return QDEL_HINT_HARDDEL_NOW

/area/template_noop
	name = "Area Passthrough"

/turf/template_noop
	name = "Turf Passthrough"
	icon_state = "noop" // now turf passthrought won't mess with other structures like lattice or plates in space on ruin maps in map editor. it was too much annoyng before the change. noop icon added in areas.dmi as well
	init_air = FALSE

#undef MAP_DMM
#undef MAP_TGM
#undef MAPLOADING_CHECK_TICK
