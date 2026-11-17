/*

	dmm_suite version 1.0
		Released January 30th, 2011.

	defines the object /dmm_suite
		- Provides the proc load_map()
			- Loads the specified map file onto the specified z-level.
		- provides the proc write_map()
			- Returns a text string of the map in dmm format
				ready for output to a file.
		- provides the proc save_map()
			- Returns a .dmm file if map is saved
			- Returns FALSE if map fails to save

	The dmm_suite provides saving and loading of map files in BYOND's native DMM map
	format. It approximates the map saving and loading processes of the Dream Maker
	and Dream Seeker programs so as to allow editing, saving, and loading of maps at
	runtime.

	------------------------

	To save a map at runtime, create an instance of /dmm_suite, and then call
	write_map(), which accepts three arguments:
		- A turf representing one corner of a three dimensional grid (Required).
		- Another turf representing the other corner of the same grid (Required).
		- Any, or a combination, of several bit flags (Optional, see documentation).

	The order in which the turfs are supplied does not matter, the /dmm_writer will
	determine the grid containing both, in much the same way as DM's block() function.
	write_map() will then return a string representing the saved map in dmm format;
	this string can then be saved to a file, or used for any other purose.

	------------------------

	To load a map at runtime, create an instance of /dmm_suite, and then call load_map(),
	which accepts two arguments:
		- A .dmm file to load (Required).
		- A number representing the z-level on which to start loading the map (Optional).

	The /dmm_suite will load the map file starting on the specified z-level. If no
	z-level	was specified, world.maxz will be increased so as to fit the map. Note
	that if you wish to load a map onto a z-level that already has objects on it,
	you will have to handle the removal of those objects. Otherwise the new map will
	simply load the new objects on top of the old ones.

	Also note that all type paths specified in the .dmm file must exist in the world's
	code, and that the /dmm_reader trusts that files to be loaded are in fact valid
	.dmm files. Errors in the .dmm format will cause runtime errors.

*/

GLOBAL_DATUM_INIT(maploader, /datum/dmm_suite, new())

/datum/dmm_suite
	var/static/quote = "\""
	var/static/regex/dmmRegex = new/regex({""(\[a-zA-Z]+)" = \\(((?:.|\n)*?)\\)\n(?!\t)|\\((\\d+),(\\d+),(\\d+)\\) = \\{"(\[a-zA-Z\n]*)"\\}"}, "g")
	var/static/regex/trimQuotesRegex = new/regex({"^\[\\s\n]+"?|"?\[\\s\n]+$|^"|"$"}, "g")
	var/static/regex/trimRegex = new/regex("^\[\\s\n]+|\[\\s\n]+$", "g")
	var/static/list/letter_digits = list(
		"a", "b", "c", "d", "e",
		"f", "g", "h", "i", "j",
		"k", "l", "m", "n", "o",
		"p", "q", "r", "s", "t",
		"u", "v", "w", "x", "y",
		"z",
		"A", "B", "C", "D", "E",
		"F", "G", "H", "I", "J",
		"K", "L", "M", "N", "O",
		"P", "Q", "R", "S", "T",
		"U", "V", "W", "X", "Y",
		"Z"
	)

/datum/dmm_suite/proc/load_map(dmm_file, x_offset = 0, y_offset = 0, z_offset = 0, shouldCropMap = FALSE, measureOnly = FALSE, defer_init = FALSE)
	var/datum/parsed_map/parsed = global.load_map(dmm_file, x_offset || 1, y_offset || 1, z_offset, crop_map = shouldCropMap, measure_only = measureOnly, defer_init = defer_init)
	return parsed.bounds

/datum/dmm_suite/proc/trim_text(what, trim_quotes = FALSE)
	if(trim_quotes)
		return trimQuotesRegex.Replace(what, "")
	else
		return trimRegex.Replace(what, "")

/datum/dmm_suite/proc/find_next_delimiter_position(text, initial_position = 0, delimiter = ",", opening_escape = quote, closing_escape = quote)
	var/position = initial_position
	var/next_delimiter = findtext(text, delimiter, position, 0)
	var/next_opening = findtext(text, opening_escape, position, 0)

	while((next_opening != 0) && (next_opening < next_delimiter))
		position = findtext(text, closing_escape, next_opening + 1, 0) + 1
		next_delimiter = findtext(text, delimiter, position, 0)
		next_opening = findtext(text, opening_escape, position, 0)

	return next_delimiter

/datum/dmm_suite/proc/readlist(text, delimiter = ",")
	var/list/to_return = list()

	var/delimiter_position
	var/old_position = 1

	do
		delimiter_position = find_next_delimiter_position(text, old_position, delimiter)

		var/equal_position = findtext(text, "=", old_position, delimiter_position)

		var/left_value = copytext(text, old_position, (equal_position ? equal_position : delimiter_position))
		old_position = delimiter_position + 1

		if(equal_position)
			left_value = trim_text(left_value, TRUE)
			var/trim_right = trim_text(copytext(text, equal_position + 1, delimiter_position))

			to_return[left_value] = parse_value(trim_right)

		else
			to_return += parse_value(trim_text(left_value))

	while(delimiter_position != 0)

	return to_return

/datum/dmm_suite/proc/parse_value(value_text)
	if(findtext(value_text, quote, 1, 2))
		var/endquote = findtext(value_text, quote, -1)
		if(!endquote)
			stack_trace("Terminating quote not found!")
		. = dmm_decode(copytext(value_text, 2, endquote))

	else if(isnum(text2num(value_text)))
		. = text2num(value_text)

	else if(value_text == "null")
		. = null

	else if(copytext(value_text, 1, 5) == "list")
		. = readlist(copytext(value_text, 6, LAZYLEN(value_text)))

	else if(copytext(value_text, 1, 2) == "'")
		. = WRAP_FILE(copytext(value_text, 2, LAZYLEN(value_text)))

	else if(ispath(text2path(value_text)))
		. = text2path(value_text)

	else
		. = value_text
