#define FORENSIC_SCAN_RADIUS 3
#define FORENSIC_SCAN_TICK (0.25 SECONDS)
#define FORENSIC_SCAN_TICKS 12
#define FORENSIC_SCAN_TICKS_PER_RING 3
#define FORENSIC_SCAN_COOLDOWN (3 SECONDS)
#define FORENSIC_SCAN_REBOOT_TIME (20 SECONDS)
#define FORENSIC_COLOUR_FADE (0.5 SECONDS)
#define FORENSIC_TRACER_TIME_PER_TILE (0.05 SECONDS)
#define FORENSIC_TRACER_MIN_TIME (0.3 SECONDS)
#define FORENSIC_TRAJECTORY_PAUSE (0.25 SECONDS)
#define FORENSIC_MAX_TRAJECTORIES 6
#define FORENSIC_MAX_EVENTS 40

#define FORENSIC_PANEL_WIDTH 216
#define FORENSIC_PANEL_MARGIN 8
#define FORENSIC_PANEL_LINE_HEIGHT 10
#define FORENSIC_PANEL_PADDING 8
#define FORENSIC_PANEL_TOP_RESERVE 72
#define FORENSIC_PANEL_MAX_LINES 30
#define FORENSIC_SCROLL_STEP 2

#define FORENSIC_COLOUR_ACCENT "#4FC8FF"
#define FORENSIC_COLOUR_BRIGHT "#BEF2FF"
#define FORENSIC_COLOUR_BACKGROUND "#04162C"
#define FORENSIC_COLOUR_LABEL "#6FB7E6"
#define FORENSIC_COLOUR_TRAJECTORY "#FFD34F"
#define FORENSIC_COLOUR_MATCH "#7CFFB2"

/obj/item/organ/internal/cyberimp/eyes/forensic
	name = "detective scanner implant"
	desc = "Детективный глазной имплант: сканирует всё вокруг в радиусе трёх метров и выводит анализ улик прямо на сетчатку. Требует полной неподвижности."
	implant_color = "#2E9BFF"
	eye_colour = "#3AA9FF"
	slot = INTERNAL_ORGAN_EYE_FORENSIC
	cyber_cost = 10
	origin_tech = "materials=4;programming=5;biotech=4;magnets=4"
	aug_message = "В углу зрения вспыхивает и гаснет строка самодиагностики..."
	actions_types = list(/datum/action/item_action/organ_action/forensic_scan)
	var/datum/forensic_scan/active_scan
	COOLDOWN_DECLARE(scan_cooldown)

/datum/action/item_action/organ_action/forensic_scan
	name = "Сканировать место происшествия"
	button_icon = 'icons/hud/forensic_scan.dmi'
	button_icon_state = "action"

/obj/item/organ/internal/cyberimp/eyes/forensic/get_ru_names()
	return alist(
		NOMINATIVE = "детективный сканер",
		GENITIVE = "детективного сканера",
		DATIVE = "детективному сканеру",
		ACCUSATIVE = "детективный сканер",
		INSTRUMENTAL = "детективным сканером",
		PREPOSITIONAL = "детективном сканере",
	)

/obj/item/organ/internal/cyberimp/eyes/forensic/Destroy()
	QDEL_NULL(active_scan)
	return ..()

/obj/item/organ/internal/cyberimp/eyes/forensic/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	QDEL_NULL(active_scan)
	return ..()

/obj/item/organ/internal/cyberimp/eyes/forensic/emp_act(severity)
	if(!owner || emp_proof || emp_shielded(severity))
		return
	. = ..()
	QDEL_NULL(active_scan)
	crit_fail = TRUE
	addtimer(CALLBACK(src, PROC_REF(reboot)), FORENSIC_SCAN_REBOOT_TIME, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/organ/internal/cyberimp/eyes/forensic/proc/reboot()
	crit_fail = FALSE

/obj/item/organ/internal/cyberimp/eyes/forensic/ui_action_click(mob/user, datum/action/action, leftclick)
	if(active_scan)
		QDEL_NULL(active_scan)
		return
	if(crit_fail)
		owner.balloon_alert(owner, "сканер перезагружается!")
		return
	if(owner.is_blind())
		owner.balloon_alert(owner, "вы ничего не видите!")
		return
	if(!isturf(owner.loc))
		owner.balloon_alert(owner, "здесь нельзя сканировать!")
		return
	if(!COOLDOWN_FINISHED(src, scan_cooldown))
		owner.balloon_alert(owner, "сканер остывает!")
		return
	COOLDOWN_START(src, scan_cooldown, FORENSIC_SCAN_COOLDOWN)
	active_scan = new(src, owner)
	update_action_state()

/obj/item/organ/internal/cyberimp/eyes/forensic/proc/update_action_state()
	for(var/datum/action/action as anything in actions)
		action.button_icon_state = active_scan ? "action_active" : "action"
		action.UpdateButtonIcon()

/atom/movable/screen/forensic_scanlines
	icon = 'icons/hud/forensic_scan.dmi'
	icon_state = "scanlines"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = FULLSCREEN_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/forensic_progress
	icon = 'icons/hud/forensic_scan_panel.dmi'
	icon_state = "frame"
	screen_loc = "EAST-6,NORTH-1:16"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	maptext_x = 12
	maptext_y = 24
	maptext_width = 136
	maptext_height = 18
	var/progress = 0

/atom/movable/screen/forensic_progress/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "bar_[progress]")

/atom/movable/screen/forensic_progress/proc/set_state(new_progress, label)
	progress = new_progress
	maptext = MAPTEXT_PIXELLARI("<span style='color: [FORENSIC_COLOUR_BRIGHT]'>[label]</span>")
	update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/forensic_element
	screen_loc = "CENTER,CENTER"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = NO_CLIENT_COLOR|RESET_COLOR

/datum/forensic_scan
	var/obj/item/organ/internal/cyberimp/eyes/forensic/implant
	var/mob/living/carbon/human/owner
	var/client/viewer
	var/turf/origin
	var/view_width
	var/view_height
	var/visible_line_limit
	var/list/visible_rings = list()
	var/list/turf/revealed_tiles = list()
	var/list/image/tile_images = list()
	var/list/image/evidence_markers = list()
	var/list/image/corner_images = list()
	var/turf/hovered_tile
	var/panel_signature
	var/panel_side
	var/total_links = 0
	var/scroll_offset = 0
	var/links_signature
	var/list/timeline_events = list()
	var/list/identity_cache = list()
	var/turf/selected_tile
	var/trajectory_generation = 0
	var/refresh_timer
	var/scan_tick = 0
	var/atom/movable/screen/forensic_scanlines/scanlines
	var/atom/movable/screen/forensic_progress/progress_bar
	var/atom/movable/screen/forensic_element/panel
	var/atom/movable/screen/forensic_element/connector
	var/list/atom/movable/screen/link_elements = list()
	var/list/atom/movable/screen/trajectory_elements = list()

/datum/forensic_scan/New(obj/item/organ/internal/cyberimp/eyes/forensic/implant, mob/living/carbon/human/owner)
	src.implant = implant
	src.owner = owner
	viewer = owner.client
	origin = get_turf(owner)
	var/list/view_size = getviewsize(viewer.view)
	view_width = view_size[1]
	view_height = view_size[2]
	visible_line_limit = min(FORENSIC_PANEL_MAX_LINES, round((view_height * ICON_SIZE_Y - FORENSIC_PANEL_TOP_RESERVE - FORENSIC_PANEL_PADDING * 2) / FORENSIC_PANEL_LINE_HEIGHT))

	ADD_TRAIT(owner, TRAIT_FORENSIC_SCAN, UNIQUE_TRAIT_SOURCE(src))
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, UNIQUE_TRAIT_SOURCE(src))
	owner.update_client_colour(FORENSIC_COLOUR_FADE)
	RegisterSignal(owner, COMSIG_ATOM_MOUSE_ENTERED, PROC_REF(on_hover))
	RegisterSignal(owner, COMSIG_MOUSE_SCROLL_ON, PROC_REF(on_scroll))
	RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(on_click))
	RegisterSignals(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_LOGOUT), PROC_REF(abort_scan))
	RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))

	build_visible_rings()
	build_corners()
	scanlines = new
	SET_PLANE_EXPLICIT(scanlines, PLANE_TO_TRUE(scanlines.plane), owner)
	progress_bar = new
	viewer.screen += scanlines
	viewer.screen += progress_bar
	owner.visible_message(span_notice("Глаза [owner.declent_ru(GENITIVE)] загораются холодным синим светом."))
	owner.playsound_local(origin, 'sound/machines/scanning.ogg', 50, FALSE)
	advance_scan()

/datum/forensic_scan/Destroy()
	if(refresh_timer)
		deltimer(refresh_timer)
	clear_panel()
	clear_elements(link_elements)
	clear_elements(trajectory_elements)
	if(viewer)
		viewer.images -= tile_images
		viewer.images -= corner_images
		for(var/turf/tile as anything in evidence_markers)
			viewer.images -= evidence_markers[tile]
		viewer.screen -= scanlines
		viewer.screen -= progress_bar
	QDEL_NULL(scanlines)
	QDEL_NULL(progress_bar)
	tile_images.Cut()
	evidence_markers.Cut()
	corner_images.Cut()
	visible_rings.Cut()
	revealed_tiles.Cut()
	timeline_events.Cut()
	hovered_tile = null
	selected_tile = null
	origin = null
	viewer = null
	UnregisterSignal(owner, list(COMSIG_ATOM_MOUSE_ENTERED, COMSIG_MOUSE_SCROLL_ON, COMSIG_MOB_CLICKON, COMSIG_MOVABLE_MOVED, COMSIG_MOB_LOGOUT, COMSIG_MOB_STATCHANGE))
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, UNIQUE_TRAIT_SOURCE(src))
	REMOVE_TRAIT(owner, TRAIT_FORENSIC_SCAN, UNIQUE_TRAIT_SOURCE(src))
	owner.update_client_colour(FORENSIC_COLOUR_FADE)
	owner.playsound_local(get_turf(owner), 'sound/machines/terminal_off.ogg', 50, FALSE)
	owner = null
	implant.active_scan = null
	implant.update_action_state()
	implant = null
	return ..()

/datum/forensic_scan/proc/abort_scan(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/forensic_scan/proc/on_stat_change(datum/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat != CONSCIOUS)
		qdel(src)

/datum/forensic_scan/proc/build_visible_rings()
	for(var/ring in 0 to FORENSIC_SCAN_RADIUS)
		visible_rings += list(list())
	for(var/turf/tile as anything in RANGE_TURFS(FORENSIC_SCAN_RADIUS, origin))
		if(tile_is_visible(tile))
			visible_rings[max(get_dist(origin, tile), 0) + 1] += tile

/datum/forensic_scan/proc/tile_is_visible(turf/tile)
	var/turf/previous = origin
	for(var/turf/next as anything in get_line(origin, tile) - origin)
		if(tile_edge_blocks(previous, get_dir(previous, next)) || tile_edge_blocks(next, get_dir(next, previous)))
			return FALSE
		if(next != tile && tile_core_blocks(next))
			return FALSE
		previous = next
	return TRUE

/datum/forensic_scan/proc/tile_core_blocks(turf/tile)
	if(tile.density || tile.opacity)
		return TRUE
	for(var/obj/blocker in tile)
		if(blocker.opacity)
			return TRUE
		if((is_window(blocker) || is_door(blocker)) && blocker.density && !(blocker.flags & ON_BORDER))
			return TRUE
	return FALSE

/datum/forensic_scan/proc/tile_edge_blocks(turf/tile, direction)
	for(var/obj/blocker in tile)
		if(!(blocker.flags & ON_BORDER) || !blocker.density || !(blocker.dir & direction))
			continue
		if(is_window(blocker) || is_door(blocker))
			return TRUE
	return FALSE

/datum/forensic_scan/proc/build_corners()
	var/static/list/corner_directions = list(NORTHWEST, NORTHEAST, SOUTHWEST, SOUTHEAST)
	for(var/direction in corner_directions)
		var/horizontal = (direction & EAST) ? FORENSIC_SCAN_RADIUS : -FORENSIC_SCAN_RADIUS
		var/vertical = (direction & NORTH) ? FORENSIC_SCAN_RADIUS : -FORENSIC_SCAN_RADIUS
		var/turf/corner_tile = locate(origin.x + horizontal, origin.y + vertical, origin.z)
		if(!corner_tile)
			continue
		var/image/corner = make_scan_image("corner_[direction]", corner_tile)
		corner_images += corner
		viewer.images += corner
		animate(corner, alpha = 255, time = 0.5 SECONDS)

/datum/forensic_scan/proc/make_scan_image(state, turf/tile)
	var/image/scan_image = image('icons/hud/forensic_scan.dmi', tile, state)
	SET_PLANE_EXPLICIT(scan_image, BALLOON_CHAT_PLANE, tile)
	scan_image.appearance_flags = RESET_ALPHA|RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|PIXEL_SCALE
	scan_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	scan_image.alpha = 0
	return scan_image

/datum/forensic_scan/proc/advance_scan()
	if(QDELETED(src))
		return
	if(!(scan_tick % FORENSIC_SCAN_TICKS_PER_RING))
		reveal_ring(scan_tick / FORENSIC_SCAN_TICKS_PER_RING + 1)
	progress_bar.set_state(scan_tick, "СКАНИРОВАНИЕ...")
	scan_tick++
	if(scan_tick > FORENSIC_SCAN_TICKS)
		finish_scan()
		return
	addtimer(CALLBACK(src, PROC_REF(advance_scan)), FORENSIC_SCAN_TICK)

/datum/forensic_scan/proc/reveal_ring(ring)
	if(ring > length(visible_rings))
		return
	for(var/turf/tile as anything in visible_rings[ring])
		var/image/tile_image = make_scan_image("grid", tile)
		tile_images += tile_image
		viewer.images += tile_image
		animate(tile_image, alpha = 255, time = 0.1 SECONDS)
		animate(alpha = 150, time = 0.5 SECONDS)
		revealed_tiles += tile
	refresh_evidence()

/datum/forensic_scan/proc/finish_scan()
	owner.playsound_local(origin, 'sound/machines/terminal_success.ogg', 40, FALSE)
	refresh_evidence()
	refresh_timer = addtimer(CALLBACK(src, PROC_REF(refresh_evidence)), 1 SECONDS, TIMER_LOOP|TIMER_STOPPABLE)

/datum/forensic_scan/proc/refresh_evidence()
	if(QDELETED(src))
		return
	if(owner.is_blind())
		qdel(src)
		return

	var/evidence_count = 0
	timeline_events.Cut()
	for(var/turf/tile as anything in revealed_tiles)
		var/marker_colour
		for(var/datum/forensic_report/report as anything in collect_reports(tile))
			timeline_events += report.events
			if(report.marked)
				evidence_count++
				marker_colour ||= report.colour
		set_marker(tile, marker_colour)
	sortTim(timeline_events, GLOBAL_PROC_REF(cmp_forensic_event))

	if(scan_tick > FORENSIC_SCAN_TICKS)
		progress_bar.set_state(FORENSIC_SCAN_TICKS, "АНАЛИЗ. УЛИК: [evidence_count]")
	update_links()
	update_panel()

/datum/forensic_scan/proc/set_marker(turf/tile, marker_colour)
	var/image/marker = evidence_markers[tile]
	if(!marker_colour)
		if(marker)
			viewer.images -= marker
			evidence_markers -= tile
		return
	var/marker_state = tile == hovered_tile ? "marker_active" : "marker"
	if(!marker)
		marker = make_scan_image(marker_state, tile)
		marker.color = marker_colour
		evidence_markers[tile] = marker
		viewer.images += marker
		animate(marker, alpha = 255, time = 0.2 SECONDS)
		return
	marker.color = marker_colour
	if(marker.icon_state != marker_state)
		marker.icon_state = marker_state

/datum/forensic_scan/proc/collect_reports(turf/tile)
	. = list()
	var/datum/forensic_report/tile_report = tile.get_forensic_report()
	if(tile_report)
		. += tile_report
	for(var/atom/movable/thing as anything in tile)
		if(thing.invisibility > owner.see_invisible)
			continue
		var/datum/forensic_report/report = thing.get_forensic_report()
		if(!report)
			continue
		if(ismob(thing))
			. = list(report) + .
		else
			. += report

/datum/forensic_scan/proc/on_hover(datum/source, atom/hovered)
	SIGNAL_HANDLER
	var/turf/new_tile = isturf(hovered) ? hovered : hovered.loc
	if(!(new_tile in revealed_tiles))
		new_tile = null
	if(new_tile == hovered_tile)
		return
	var/turf/old_tile = hovered_tile
	hovered_tile = new_tile
	scroll_offset = 0
	if(old_tile && evidence_markers[old_tile])
		var/image/old_marker = evidence_markers[old_tile]
		old_marker.icon_state = "marker"
	if(hovered_tile && evidence_markers[hovered_tile])
		var/image/new_marker = evidence_markers[hovered_tile]
		new_marker.icon_state = "marker_active"
		owner.playsound_local(origin, 'sound/machines/terminal_select.ogg', 25, FALSE)
	update_links()
	update_panel()

/datum/forensic_scan/proc/on_scroll(datum/source, atom/hovered_atom, delta_x, delta_y, params)
	SIGNAL_HANDLER
	scroll_offset += delta_y > 0 ? -FORENSIC_SCROLL_STEP : FORENSIC_SCROLL_STEP
	update_panel()

/datum/forensic_scan/proc/on_click(datum/source, atom/target, list/modifiers)
	SIGNAL_HANDLER
	if(is_screen_atom(target) || LAZYACCESS(modifiers, SHIFT_CLICK))
		return NONE
	var/turf/tile = isturf(target) ? target : target.loc
	if(!isturf(tile))
		return NONE
	if(tile in revealed_tiles)
		select_tile(tile)
	return COMSIG_MOB_CANCEL_CLICKON

/datum/forensic_scan/proc/select_tile(turf/tile)
	var/was_selected = tile == selected_tile
	clear_elements(trajectory_elements)
	trajectory_generation++
	selected_tile = null
	if(was_selected)
		return
	var/list/queue = list()
	for(var/datum/forensic_report/report as anything in collect_reports(tile))
		for(var/list/trajectory as anything in report.trajectories)
			var/turf/start = trajectory["start"]
			var/turf/end = trajectory["end"]
			if(length(queue) < FORENSIC_MAX_TRAJECTORIES && start.z == origin.z && end.z == origin.z)
				queue += list(trajectory)
	if(!length(queue))
		return
	selected_tile = tile
	owner.playsound_local(origin, 'sound/machines/terminal_prompt_confirm.ogg', 40, FALSE)
	play_trajectory(queue, trajectory_generation)

/datum/forensic_scan/proc/play_trajectory(list/queue, generation)
	if(QDELETED(src) || generation != trajectory_generation || !length(queue))
		return
	var/list/trajectory = queue[1]
	queue.Cut(1, 2)
	var/turf/start = trajectory["start"]
	var/turf/end = trajectory["end"]
	var/start_x = (start.x - origin.x) * ICON_SIZE_X
	var/start_y = (start.y - origin.y) * ICON_SIZE_Y
	var/end_x = (end.x - origin.x) * ICON_SIZE_X
	var/end_y = (end.y - origin.y) * ICON_SIZE_Y
	var/distance = max(get_dist(start, end), 0)
	var/zone_edge = (FORENSIC_SCAN_RADIUS + 0.5) * ICON_SIZE_X
	var/shooter_in_zone = abs(start_x) <= zone_edge && abs(start_y) <= zone_edge
	var/impact_in_zone = abs(end_x) <= zone_edge && abs(end_y) <= zone_edge
	var/list/clipped = clip_line_to_zone(start_x, start_y, end_x, end_y, zone_edge)
	if(!clipped)
		play_trajectory(queue, generation)
		return
	start_x = clipped[1]
	start_y = clipped[2]
	end_x = clipped[3]
	end_y = clipped[4]
	var/visible_tiles = sqrt((end_x - start_x) ** 2 + (end_y - start_y) ** 2) / ICON_SIZE_X
	var/flight_time = max(visible_tiles * FORENSIC_TRACER_TIME_PER_TILE, FORENSIC_TRACER_MIN_TIME)

	var/atom/movable/screen/forensic_element/shooter = make_icon_element(shooter_in_zone ? "shooter" : null, start_x, start_y)
	var/shooter_note = shooter_in_zone ? "" : "<br>Стрелок вне зоны: [dir2rustext(get_dir(end, start))]"
	shooter.maptext = MAPTEXT("<span style='color: [FORENSIC_COLOUR_TRAJECTORY]; text-align: center'>[trajectory["weapon"]]<br>[station_time_timestamp("hh:mm:ss", trajectory["time"])] · [distance] м[shooter_note]</span>")
	shooter.maptext_width = ICON_SIZE_X * 5
	shooter.maptext_height = ICON_SIZE_Y * 2
	shooter.maptext_x = -ICON_SIZE_X * 2
	shooter.maptext_y = -ICON_SIZE_Y * 2 + 8
	animate(shooter, alpha = 255, time = 0.2 SECONDS)

	var/atom/movable/screen/forensic_element/glow = make_line(start_x, start_y, end_x, end_y, 3, FORENSIC_COLOUR_TRAJECTORY, 70)
	var/atom/movable/screen/forensic_element/core = make_line(start_x, start_y, end_x, end_y, 1, FORENSIC_COLOUR_TRAJECTORY, 255)
	grow_line(glow, start_x, start_y, end_x, end_y, 3, flight_time)
	grow_line(core, start_x, start_y, end_x, end_y, 1, flight_time)

	var/atom/movable/screen/forensic_element/tracer = make_line(start_x, start_y, start_x + (end_x - start_x) * 0.01, start_y + (end_y - start_y) * 0.01, 3, "#FFFFFF", 255)
	var/matrix/tracer_end = line_matrix(end_x - (end_x - start_x) * 0.01, end_y - (end_y - start_y) * 0.01, end_x, end_y, 3)
	animate(tracer, transform = tracer_end, time = flight_time)
	animate(alpha = 0, time = 0.1 SECONDS)

	owner.playsound_local(origin, 'sound/machines/terminal_processing.ogg', 25, FALSE)
	addtimer(CALLBACK(src, PROC_REF(finish_trajectory), queue, generation, end_x, end_y, impact_in_zone), flight_time)

/datum/forensic_scan/proc/finish_trajectory(list/queue, generation, end_x, end_y, impact_in_zone)
	if(QDELETED(src) || generation != trajectory_generation)
		return
	if(impact_in_zone)
		var/atom/movable/screen/forensic_element/impact = make_icon_element("impact", end_x, end_y)
		animate(impact, alpha = 255, time = 0.1 SECONDS)
		owner.playsound_local(origin, 'sound/machines/terminal_alert.ogg', 20, FALSE)
	addtimer(CALLBACK(src, PROC_REF(play_trajectory), queue, generation), FORENSIC_TRAJECTORY_PAUSE)

/datum/forensic_scan/proc/clip_line_to_zone(start_x, start_y, end_x, end_y, zone_edge)
	var/delta_x = end_x - start_x
	var/delta_y = end_y - start_y
	var/entry = 0
	var/leave = 1
	var/list/directions = list(-delta_x, delta_x, -delta_y, delta_y)
	var/list/margins = list(start_x + zone_edge, zone_edge - start_x, start_y + zone_edge, zone_edge - start_y)
	for(var/index in 1 to 4)
		var/direction = directions[index]
		if(!direction)
			if(margins[index] < 0)
				return null
			continue
		var/fraction = margins[index] / direction
		if(direction < 0)
			entry = max(entry, fraction)
		else
			leave = min(leave, fraction)
	if(entry > leave)
		return null
	return list(start_x + delta_x * entry, start_y + delta_y * entry, start_x + delta_x * leave, start_y + delta_y * leave)

/datum/forensic_scan/proc/make_icon_element(state, element_x, element_y)
	var/atom/movable/screen/forensic_element/element = new
	element.icon = 'icons/hud/forensic_scan.dmi'
	element.icon_state = state
	element.alpha = 0
	element.transform = matrix(1, 0, element_x, 0, 1, element_y)
	viewer.screen += element
	trajectory_elements += element
	return element

/proc/line_matrix(start_x, start_y, end_x, end_y, thickness)
	var/delta_x = end_x - start_x
	var/delta_y = end_y - start_y
	var/length = max(sqrt(delta_x * delta_x + delta_y * delta_y), 1)
	var/matrix/result = matrix()
	result.Scale(length / ICON_SIZE_X, thickness / ICON_SIZE_Y)
	result.Turn(-ATAN2(delta_x, delta_y))
	result.Translate((start_x + end_x) / 2, (start_y + end_y) / 2)
	return result

/datum/forensic_scan/proc/make_line(start_x, start_y, end_x, end_y, thickness, line_colour, line_alpha, list/container)
	var/atom/movable/screen/forensic_element/line = new
	line.icon = 'icons/effects/alphacolors.dmi'
	line.icon_state = "white"
	line.color = line_colour
	line.alpha = line_alpha
	line.transform = line_matrix(start_x, start_y, end_x, end_y, thickness)
	viewer.screen += line
	if(container)
		container += line
	else
		trajectory_elements += line
	return line

/datum/forensic_scan/proc/grow_line(atom/movable/screen/forensic_element/line, start_x, start_y, end_x, end_y, thickness, grow_time)
	var/matrix/final_transform = line.transform
	line.transform = line_matrix(start_x, start_y, start_x + (end_x - start_x) * 0.01, start_y + (end_y - start_y) * 0.01, thickness)
	animate(line, transform = final_transform, time = grow_time)

/datum/forensic_scan/proc/clear_elements(list/elements)
	if(viewer)
		viewer.screen -= elements
	QDEL_LIST(elements)

/datum/forensic_scan/proc/update_links()
	var/list/matched_tiles = list()
	if(hovered_tile)
		var/list/hovered_keys = list()
		for(var/datum/forensic_report/report as anything in collect_reports(hovered_tile))
			hovered_keys |= report.dna_keys
			hovered_keys |= report.print_keys
			hovered_keys |= report.weapon_keys
		if(length(hovered_keys))
			for(var/turf/tile as anything in revealed_tiles)
				if(tile != hovered_tile && tile_matches_keys(tile, hovered_keys))
					matched_tiles += tile
	total_links = length(matched_tiles)
	var/list/tile_names = list("[hovered_tile?.x],[hovered_tile?.y]")
	for(var/turf/tile as anything in matched_tiles)
		tile_names += "[tile.x],[tile.y]"
	var/signature = jointext(tile_names, ";")
	if(signature == links_signature)
		return
	links_signature = signature
	clear_elements(link_elements)
	for(var/turf/tile as anything in matched_tiles)
		var/start_x = (hovered_tile.x - origin.x) * ICON_SIZE_X
		var/start_y = (hovered_tile.y - origin.y) * ICON_SIZE_Y
		var/end_x = (tile.x - origin.x) * ICON_SIZE_X
		var/end_y = (tile.y - origin.y) * ICON_SIZE_Y
		var/atom/movable/screen/forensic_element/line = make_line(start_x, start_y, end_x, end_y, 1, FORENSIC_COLOUR_MATCH, 200, link_elements)
		grow_line(line, start_x, start_y, end_x, end_y, 1, 0.2 SECONDS)

/datum/forensic_scan/proc/tile_matches_keys(turf/tile, list/keys)
	for(var/datum/forensic_report/report as anything in collect_reports(tile))
		if(length(keys & report.dna_keys) || length(keys & report.print_keys) || length(keys & report.weapon_keys))
			return TRUE
	return FALSE

/datum/forensic_scan/proc/identify(key, record_group, field)
	if(!(key in identity_cache))
		identity_cache[key] = null
		for(var/datum/data/record/record as anything in record_group)
			if(record.fields[field] == key)
				identity_cache[key] = record.fields["name"]
				break
	return identity_cache[key]

/datum/forensic_scan/proc/hover_entries()
	. = list()
	for(var/datum/forensic_report/report as anything in collect_reports(hovered_tile))
		. += list(list("<span style='color: [report.colour]'>АНАЛИЗ // [uppertext(report.title)]</span>", 1))
		for(var/index in 1 to length(report.lines))
			. += list(list(report.lines[index], report.line_weights[index]))
		for(var/dna in report.dna_keys)
			var/dna_owner = identify(dna, GLOB.data_core.medical, "b_dna")
			if(dna_owner)
				. += list(list(identity_line("ДНК принадлежит", dna_owner), forensic_line_weight(length_char(dna_owner) + 17)))
		for(var/print in report.print_keys)
			var/print_owner = identify(print, GLOB.data_core.general, "fingerprint")
			if(print_owner)
				. += list(list(identity_line("Отпечатки", print_owner), forensic_line_weight(length_char(print_owner) + 11)))
		if(length(report.trajectories))
			. += list(list("<span style='color: [FORENSIC_COLOUR_TRAJECTORY]'>ЛКМ: реконструкция выстрела</span>", 1))
		. += list(list("", 1))
	if(total_links && length(.))
		. += list(list("<span style='color: [FORENSIC_COLOUR_MATCH]'>Связанных улик в зоне: [total_links]</span>", 1))

/datum/forensic_scan/proc/identity_line(label, identity)
	return "<span style='color: [FORENSIC_COLOUR_MATCH]'>[label]: [identity]</span>"

/datum/forensic_scan/proc/timeline_entries()
	. = list()
	if(scan_tick <= FORENSIC_SCAN_TICKS || !length(timeline_events))
		return
	. += list(list("<span style='color: [FORENSIC_COLOUR_BRIGHT]'>ХРОНОЛОГИЯ СОБЫТИЙ</span>", 1))
	. += list(list("", 1))
	var/shown = 0
	for(var/list/event as anything in timeline_events)
		if(shown == FORENSIC_MAX_EVENTS)
			break
		var/text = event["text"]
		. += list(list("<span style='color: [FORENSIC_COLOUR_LABEL]'>[station_time_timestamp("hh:mm:ss", event["time"])]</span> [text]", forensic_line_weight(length_char(text) + 9)))
		shown++

/datum/forensic_scan/proc/update_panel()
	var/list/entries = hovered_tile ? hover_entries() : list()
	var/showing_tile = length(entries) > 0
	if(!showing_tile)
		entries = timeline_entries()
	if(!length(entries))
		clear_panel()
		panel_signature = null
		return

	var/total_weight = 0
	for(var/list/entry as anything in entries)
		total_weight += entry[2]
	var/needs_scroll = total_weight > visible_line_limit
	var/line_budget = needs_scroll ? visible_line_limit - 1 : visible_line_limit
	scroll_offset = clamp(scroll_offset, 0, max(length(entries) - 1, 0))
	if(!needs_scroll)
		scroll_offset = 0

	var/list/shown_lines = list()
	var/used_weight = 0
	var/last_shown = scroll_offset
	for(var/index in (scroll_offset + 1) to length(entries))
		var/list/entry = entries[index]
		if(used_weight + entry[2] > line_budget)
			break
		shown_lines += entry[1]
		used_weight += entry[2]
		last_shown = index
	while(needs_scroll && last_shown == length(entries) && scroll_offset > 0)
		var/list/previous = entries[scroll_offset]
		if(used_weight + previous[2] > line_budget)
			break
		shown_lines.Insert(1, previous[1])
		used_weight += previous[2]
		scroll_offset--
	if(needs_scroll)
		shown_lines += "<span style='color: [FORENSIC_COLOUR_ACCENT]'>Колесо мыши: [last_shown] из [length(entries)]</span>"
		used_weight++

	var/opens_left = showing_tile && hovered_tile.x > origin.x
	var/text = jointext(shown_lines, "<br>")
	var/signature = "[showing_tile]|[hovered_tile?.x],[hovered_tile?.y]|[opens_left]|[used_weight]|[scroll_offset]|[text]"
	if(signature == panel_signature)
		return
	var/same_owner = !isnull(panel) && panel_side == opens_left
	panel_signature = signature
	panel_side = opens_left
	build_panel(text, used_weight, opens_left, same_owner, needs_scroll, scroll_offset, length(entries), last_shown, showing_tile)

/datum/forensic_scan/proc/clear_panel()
	if(viewer)
		viewer.screen -= panel
		viewer.screen -= connector
	QDEL_NULL(panel)
	QDEL_NULL(connector)

/datum/forensic_scan/proc/build_panel(text, line_count, opens_left, keep_position, needs_scroll, first_hidden, entry_count, last_shown, showing_tile)
	clear_panel()
	var/panel_height = line_count * FORENSIC_PANEL_LINE_HEIGHT + FORENSIC_PANEL_PADDING
	var/half_width = view_width * ICON_SIZE_X / 2
	var/panel_x = opens_left ? -half_width + FORENSIC_PANEL_MARGIN : half_width - FORENSIC_PANEL_MARGIN - FORENSIC_PANEL_WIDTH
	var/panel_top = view_height * ICON_SIZE_Y / 2 - FORENSIC_PANEL_TOP_RESERVE
	var/panel_y = panel_top - panel_height

	panel = new
	panel.appearance_flags |= KEEP_TOGETHER
	var/list/parts = list()
	parts += panel_rect(panel_x, panel_y, FORENSIC_PANEL_WIDTH, panel_height, FORENSIC_COLOUR_BACKGROUND, 225)
	parts += panel_rect(panel_x, panel_top - 2, FORENSIC_PANEL_WIDTH, 2, FORENSIC_COLOUR_BRIGHT, 255)
	parts += panel_rect(panel_x, panel_y, FORENSIC_PANEL_WIDTH, 1, FORENSIC_COLOUR_ACCENT, 160)
	parts += panel_rect(panel_x, panel_y, 1, panel_height, FORENSIC_COLOUR_ACCENT, 160)
	parts += panel_rect(panel_x + FORENSIC_PANEL_WIDTH - 1, panel_y, 1, panel_height, FORENSIC_COLOUR_ACCENT, 160)
	parts += panel_rect(panel_x, panel_y, 8, 2, FORENSIC_COLOUR_BRIGHT, 255)
	parts += panel_rect(panel_x + FORENSIC_PANEL_WIDTH - 8, panel_y, 8, 2, FORENSIC_COLOUR_BRIGHT, 255)
	if(needs_scroll)
		var/track_x = panel_x + FORENSIC_PANEL_WIDTH - 5
		var/track_height = panel_height - 8
		var/thumb_height = max(round(track_height * (last_shown - first_hidden) / entry_count), 6)
		var/thumb_top = panel_top - 4 - round(track_height * first_hidden / entry_count)
		parts += panel_rect(track_x, panel_y + 4, 2, track_height, FORENSIC_COLOUR_ACCENT, 60)
		parts += panel_rect(track_x, max(thumb_top - thumb_height, panel_y + 4), 2, thumb_height, FORENSIC_COLOUR_BRIGHT, 255)

	var/mutable_appearance/text_holder = mutable_appearance()
	text_holder.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	text_holder.maptext = MAPTEXT("<span style='color: #DCF4FF'>[text]</span>")
	text_holder.maptext_x = panel_x + FORENSIC_PANEL_MARGIN + ICON_SIZE_X / 2
	text_holder.maptext_y = panel_y + ICON_SIZE_Y / 2
	text_holder.maptext_width = FORENSIC_PANEL_WIDTH - FORENSIC_PANEL_MARGIN * 2 - 4
	text_holder.maptext_height = panel_height + 2
	parts += text_holder
	panel.overlays = parts
	viewer.screen += panel

	if(showing_tile)
		var/edge_x = opens_left ? panel_x + FORENSIC_PANEL_WIDTH : panel_x
		var/tile_x = (hovered_tile.x - origin.x) * ICON_SIZE_X
		var/tile_y = (hovered_tile.y - origin.y) * ICON_SIZE_Y
		connector = make_line(tile_x, tile_y, edge_x, panel_top - 1, 1, FORENSIC_COLOUR_BRIGHT, 180, list())

	if(keep_position)
		return
	panel.alpha = 0
	panel.pixel_x = opens_left ? -8 : 8
	animate(panel, alpha = 255, pixel_x = 0, time = 0.15 SECONDS, easing = SINE_EASING|EASE_OUT)

/datum/forensic_scan/proc/panel_rect(rect_x, rect_y, rect_width, rect_height, rect_colour, rect_alpha)
	var/mutable_appearance/rect = mutable_appearance('icons/effects/alphacolors.dmi', "white", alpha = rect_alpha, appearance_flags = PIXEL_SCALE)
	rect.color = rect_colour
	rect.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	rect.transform = matrix(rect_width / ICON_SIZE_X, 0, rect_x + rect_width / 2, 0, rect_height / ICON_SIZE_Y, rect_y + rect_height / 2)
	return rect

#undef FORENSIC_SCAN_RADIUS
#undef FORENSIC_SCAN_TICK
#undef FORENSIC_SCAN_TICKS
#undef FORENSIC_SCAN_TICKS_PER_RING
#undef FORENSIC_SCAN_COOLDOWN
#undef FORENSIC_SCAN_REBOOT_TIME
#undef FORENSIC_COLOUR_FADE
#undef FORENSIC_TRACER_TIME_PER_TILE
#undef FORENSIC_TRACER_MIN_TIME
#undef FORENSIC_TRAJECTORY_PAUSE
#undef FORENSIC_MAX_TRAJECTORIES
#undef FORENSIC_MAX_EVENTS
#undef FORENSIC_PANEL_WIDTH
#undef FORENSIC_PANEL_MARGIN
#undef FORENSIC_PANEL_LINE_HEIGHT
#undef FORENSIC_PANEL_PADDING
#undef FORENSIC_PANEL_TOP_RESERVE
#undef FORENSIC_PANEL_MAX_LINES
#undef FORENSIC_SCROLL_STEP
#undef FORENSIC_COLOUR_ACCENT
#undef FORENSIC_COLOUR_BRIGHT
#undef FORENSIC_COLOUR_BACKGROUND
#undef FORENSIC_COLOUR_LABEL
#undef FORENSIC_COLOUR_TRAJECTORY
#undef FORENSIC_COLOUR_MATCH
