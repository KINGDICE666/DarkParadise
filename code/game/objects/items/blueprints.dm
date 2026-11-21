// Used to edit areas.
#define AREA_ERRNONE 0
#define AREA_STATION 1
#define AREA_SPACE 2
#define AREA_SPECIAL 3
#define BLUEPRINTS_ZONE_STATION "station"
#define BLUEPRINTS_ZONE_SHUTTLE "shuttle"
#define BLUEPRINTS_DRAW_RANGE 12
#define BLUEPRINTS_MAX_DRAWN_TILES 300

/obj/item/areaeditor
	name = "area modification item"
	icon_state = "blueprints"
	attack_verb = list("атаковал", "стукнул", "ударил")
	/// Whether someone is currently using us
	var/currently_used = FALSE
	/// Fluff name for station in interaction window
	var/station_name_overrride
	/// More fluff description for interaction window
	var/fluffnotice = "Nobody's gonna read this stuff!"
	/// Whether item can be used to edit existing areas.
	var/allow_non_space_use = FALSE
	/// When using it to create a new area, this will be its type.
	var/new_area_type = /area

/obj/item/areaeditor/attack_self(mob/user)
	interact_prints(user)

/obj/item/areaeditor/dropped(mob/user, slot, silent = FALSE)
	. = ..()
	close_window(user, "blueprints")

/obj/item/areaeditor/proc/interact_prints(mob/user)
	add_fingerprint(user)
	. = "<body><html><head><title>[src]</title></head> \
				<h2>[isnull(station_name_overrride) ? "\"[station_name()]\"" : station_name_overrride ? "\"[station_name_overrride]\"" : null] [src.name]</h2> \
				<small>[fluffnotice]</small><hr>"
	switch(get_area_type())
		if(AREA_SPACE)
			. += "<p>According to the [src.name], you are now in an unclaimed territory.</p>"
			if(!allow_non_space_use)
				. += "<p><a href='byond://?src=[UID()];create_area=1'>Create or modify an existing area</a></p>"
		if(AREA_SPECIAL)
			. += "<p>This place is not noted on the [src.name].</p>"
	if(allow_non_space_use)
		. += "<p><a href='byond://?src=[UID()];create_area=1'>Create or modify an existing area</a></p>"

/obj/item/areaeditor/Topic(href, href_list)
	if(..())
		return TRUE
	if(usr != loc)
		close_window(usr, "blueprints")
		return TRUE
	if(href_list["create_area"])
		if(currently_used)
			return
		currently_used = TRUE
		create_area_wrapper(usr, new_area_type)
		if(QDELETED(src))
			return
		currently_used = FALSE
		interact_prints(usr)
		return TRUE

/obj/item/areaeditor/proc/create_area_wrapper(mob/user, new_area_type)
	return create_area(user, new_area_type)

/obj/item/areaeditor/proc/get_area_type(area/check_area)
	if(!check_area)
		check_area = get_area(usr)
	if(check_area.outdoors)
		return AREA_SPACE
	var/static/list/special_areas = typecacheof(list(
		/area/shuttle,
		/area/centcom/admin_room,
		/area/centcom,
		/area/centcom/tdome,
		/area/centcom/wizard_station,
	))
	if(is_type_in_typecache(check_area, special_areas))
		return AREA_SPECIAL
	return AREA_STATION

/obj/item/areaeditor/proc/edit_area(mob/user)
	var/area/user_area = get_area(user)
	var/prevname = "[sanitize(user_area.name)]"
	var/str = tgui_input_text(usr, "New area name:", "Blueprint Editing", prevname, MAX_NAME_LEN, encode = FALSE)
	if(!str || !length(str) || str == prevname) // Cancel
		return
	rename_area(user_area, str)
	to_chat(user, span_notice("You rename the '[prevname]' to '[str]'."))
	add_game_logs("has renamed [prevname] to [str]", user)
	interact_prints(user)
	return user_area

/obj/item/areaeditor/proc/rename_area(passed, new_name)
	var/area/our_area = get_area(passed)
	var/prevname = "[sanitize(our_area.name)]"
	set_area_machinery_title(our_area, new_name, prevname)
	our_area.name = new_name

	if(our_area.firedoors)
		for(var/obj/machinery/door/firedoor/firedoor as anything in our_area.firedoors)
			firedoor.CalculateAffectingAreas()

/obj/item/areaeditor/proc/set_area_machinery_title(area/check_area, title, oldtitle)
	if(!oldtitle) // or replacetext goes to infinite loop
		return

	//stuff tied to the area to rename
	var/static/list/to_rename = typecacheof(list(
		/obj/machinery/alarm,
		/obj/machinery/power/apc,
		/obj/machinery/atmospherics/unary/vent_scrubber,
		/obj/machinery/atmospherics/unary/vent_pump,
		/obj/machinery/door,
		/obj/machinery/firealarm,
		/obj/machinery/light_switch,
	))

	for(var/obj/machinery/machine as anything in typecache_filter_list(check_area.machinery_cache, to_rename))
		machine.name = replacetext(machine.name, oldtitle, title)

// Station Blueprints
/obj/item/areaeditor/blueprints
	name = "station blueprints"
	desc = "Blueprints of the station. There is a \"Classified\" stamp and several coffee stains on it."
	fluffnotice = "Property of Nanotrasen. For heads of staff only. Store in high-secure storage."
	resistance_flags = INDESTRUCTIBLE|LAVA_PROOF|FIRE_PROOF|ACID_PROOF
	allow_non_space_use = TRUE
	interaction_flags_atom = parent_type::interaction_flags_atom | INTERACT_ATOM_ALLOW_USER_LOCATION | INTERACT_ATOM_IGNORE_MOBILITY
	var/list/showing = list()
	var/client/viewing
	/// Viewing the wire legend
	var/legend = FALSE
	var/can_draw = TRUE
	var/zone_kind = BLUEPRINTS_ZONE_STATION
	var/list/draft_turfs = list()
	var/client/draft_viewer
	var/datum/click_intercept/blueprint_draft/drafting
	var/last_result

/obj/item/areaeditor/blueprints/Destroy()
	clear_viewer()
	stop_drafting()
	draft_turfs.Cut()
	return ..()

/obj/item/areaeditor/blueprints/interact_prints(mob/user)
	. = ..()
	if(!legend)
		var/area/user_area = get_area(user)
		if(get_area_type() == AREA_STATION)
			. += "<p>According to \the [src], you are now in <b>\"[sanitize(user_area.name)]\"</b>.</p>"
			. += "<p><a href='byond://?src=[UID()];edit_area=1'>Change area name</a></p>"
		. += "<p><a href='byond://?src=[UID()];view_legend=1'>View wire colour legend</a></p>"
		if(!viewing)
			. += "<p><a href='byond://?src=[UID()];view_blueprints=1'>View structural data</a></p>"
		else
			. += "<p><a href='byond://?src=[UID()];refresh=1'>Refresh structural data</a></p>"
			. += "<p><a href='byond://?src=[UID()];hide_blueprints=1'>Hide structural data</a></p>"
		if(can_draw)
			. += draft_controls(user)
	else
		if(legend == TRUE)
			. += "<a href='byond://?src=[UID()];exit_legend=1'><< Back</a>"
			. += view_wire_devices(user);
		else
			//legend is a wireset
			. += "<a href='byond://?src=[UID()];view_legend=1'><< Back</a>"
			. += view_wire_set(user, legend)
	var/datum/browser/popup = new(user, "blueprints", "[src]", 700, 500)
	popup.set_content(.)
	popup.open()
	onclose(user, "blueprints")

/obj/item/areaeditor/blueprints/Topic(href, href_list)
	if(..())
		return
	if(href_list["edit_area"])
		if(get_area_type() != AREA_STATION)
			return
		if(currently_used)
			return
		currently_used = TRUE
		edit_area(usr)
		if(QDELETED(src))
			return
		currently_used = FALSE
	if(href_list["exit_legend"])
		legend = FALSE
	if(href_list["view_legend"])
		legend = TRUE
	if(href_list["view_wireset"])
		legend = href_list["view_wireset"];
	if(href_list["view_blueprints"])
		set_viewer(usr, span_notice("You flip the blueprints over to view the complex information diagram."))
	if(href_list["hide_blueprints"])
		clear_viewer(usr,span_notice("You flip the blueprints over to view the simple information diagram."))
	if(href_list["refresh"])
		clear_viewer(usr)
		set_viewer(usr)
	if(can_draw)
		if(href_list["zone_kind"])
			set_zone_kind(href_list["zone_kind"])
		if(href_list["toggle_draft"])
			var/active = drafting?.holder
			stop_drafting()
			if(!active)
				start_drafting(usr)
		if(href_list["clear_draft"])
			clear_draft()
		if(href_list["mark_structure"])
			mark_structure(usr)
		if(href_list["apply_draft"] && !currently_used)
			currently_used = TRUE
			apply_draft(usr)
			if(QDELETED(src))
				return
			currently_used = FALSE

	interact_prints(usr)

/obj/item/areaeditor/blueprints/proc/draft_controls(mob/user)
	var/shuttle = zone_kind == BLUEPRINTS_ZONE_SHUTTLE
	. = "<hr><h3>Разметка зон</h3>"
	var/area/here = get_area(user)
	if(istype(here, /area/shuttle/custom))
		. += "<p>Вы на шаттле <b>«[html_encode(here.name)]»</b>. Отмеченные вплотную к нему клетки будут к нему пристроены.</p>"
	. += "<p>Тип зоны: <a href='byond://?src=[UID()];zone_kind=[BLUEPRINTS_ZONE_STATION]'>[shuttle ? "Станция" : "<b>\[Станция\]</b>"]</a> | <a href='byond://?src=[UID()];zone_kind=[BLUEPRINTS_ZONE_SHUTTLE]'>[shuttle ? "<b>\[Шаттл\]</b>" : "Шаттл"]</a></p>"
	if(shuttle)
		. += "<p><small>Встаньте на пол своей постройки и нажмите «Отметить постройку целиком»: весь корпус со стенами отметится сам. Постройка должна стоять в открытом космосе и не касаться станции.</small></p>"
		. += "<p><a href='byond://?src=[UID()];mark_structure=1'>Отметить постройку целиком</a></p>"
	. += "<p>Отмечено клеток: [length(draft_turfs)]</p>"
	. += "<p><a href='byond://?src=[UID()];toggle_draft=1'>[drafting?.holder ? "Закончить ручную разметку" : "Ручная разметка"]</a></p>"
	if(drafting?.holder)
		. += "<p><small>ЛКМ — отметить клетку, ПКМ — снять отметку, Shift+ЛКМ — отметить прямоугольник от последней отмеченной клетки.</small></p>"
	if(length(draft_turfs))
		. += "<p><a href='byond://?src=[UID()];apply_draft=1'>[shuttle ? "Зарегистрировать шаттл" : "Создать зону"] из разметки</a></p>"
		. += "<p><a href='byond://?src=[UID()];clear_draft=1'>Очистить разметку</a></p>"
	if(last_result)
		. += "<p><b>[html_encode(last_result)]</b></p>"

/obj/item/areaeditor/blueprints/proc/report_draft(mob/user, text, success = FALSE)
	last_result = text
	to_chat(user, success ? span_notice(text) : span_warning(text))

/obj/item/areaeditor/blueprints/proc/mark_structure(mob/user)
	var/turf/origin = get_turf(user)
	if(!origin || isspaceturf(origin))
		report_draft(user, "Встаньте на пол постройки, которую хотите отметить.")
		return
	var/list/found = list()
	found[origin] = TRUE
	var/list/queue = list(origin)
	while(length(queue) && length(found) <= OVERMAP_CUSTOM_SHUTTLE_MAX_TILES)
		var/turf/current = queue[length(queue)]
		queue.len--
		for(var/direction in GLOB.cardinal)
			var/turf/next = get_step(current, direction)
			if(!next || found[next] || isspaceturf(next))
				continue
			found[next] = TRUE
			queue += next
	if(length(found) > OVERMAP_CUSTOM_SHUTTLE_MAX_TILES)
		report_draft(user, "Постройка больше [OVERMAP_CUSTOM_SHUTTLE_MAX_TILES] клеток. Похоже, она соединена со станцией.")
		return
	if(!drafting?.holder)
		stop_drafting()
		start_drafting(user)
	clear_draft()
	for(var/turf/tile as anything in found)
		mark_turf(tile)
	report_draft(user, "Отмечено клеток постройки: [length(draft_turfs)].", TRUE)

/obj/item/areaeditor/blueprints/proc/set_zone_kind(kind)
	zone_kind = kind == BLUEPRINTS_ZONE_SHUTTLE ? BLUEPRINTS_ZONE_SHUTTLE : BLUEPRINTS_ZONE_STATION
	for(var/turf/tile as anything in draft_turfs)
		var/image/marker = draft_turfs[tile]
		marker.icon_state = draft_marker_state()

/obj/item/areaeditor/blueprints/proc/draft_marker_state()
	return zone_kind == BLUEPRINTS_ZONE_SHUTTLE ? "red" : "blue"

/obj/item/areaeditor/blueprints/proc/draft_markers()
	. = list()
	for(var/turf/tile as anything in draft_turfs)
		. += draft_turfs[tile]

/obj/item/areaeditor/blueprints/proc/start_drafting(mob/user)
	if(!user.client)
		return
	if(user.client.click_intercept)
		to_chat(user, span_warning("Сначала закончите текущее действие."))
		return
	drafting = new(user.client, src)
	draft_viewer = user.client
	draft_viewer.images |= draft_markers()
	to_chat(user, span_notice("Вы начинаете разметку зоны."))

/obj/item/areaeditor/blueprints/proc/stop_drafting()
	QDEL_NULL(drafting)
	if(draft_viewer)
		draft_viewer.images -= draft_markers()
		draft_viewer = null

/obj/item/areaeditor/blueprints/proc/mark_turf(turf/tile)
	if(draft_turfs[tile] || length(draft_turfs) >= OVERMAP_CUSTOM_SHUTTLE_MAX_TILES)
		return
	var/image/marker = image('icons/effects/alphacolors.dmi', tile, draft_marker_state())
	SET_PLANE_EXPLICIT(marker, ABOVE_LIGHTING_PLANE, tile)
	draft_turfs[tile] = marker
	draft_viewer?.images += marker

/obj/item/areaeditor/blueprints/proc/unmark_turf(turf/tile)
	var/image/marker = draft_turfs[tile]
	if(!marker)
		return
	draft_viewer?.images -= marker
	draft_turfs -= tile

/obj/item/areaeditor/blueprints/proc/clear_draft()
	draft_viewer?.images -= draft_markers()
	draft_turfs.Cut()

/obj/item/areaeditor/blueprints/proc/apply_draft(mob/user)
	var/list/turfs = draft_turfs.Copy()
	if(!length(turfs))
		return
	if(zone_kind == BLUEPRINTS_ZONE_SHUTTLE)
		var/area/shuttle/custom/extending = custom_shuttle_near(turfs)
		var/problem = custom_shuttle_problem(turfs, extending)
		if(problem)
			report_draft(user, problem)
			return
		if(extending)
			problem = SSovermap.extend_custom_shuttle(user, extending, turfs)
			if(problem)
				report_draft(user, problem)
				return
			clear_draft()
			report_draft(user, "Шаттл «[extending.name]» достроен.", TRUE)
			add_game_logs("extended custom shuttle [extending.name] by [length(turfs)] tiles at [AREACOORD(user)]", user)
			return
		var/shuttle_name = tgui_input_text(user, "Название шаттла:", "Регистрация шаттла", max_length = MAX_NAME_LEN, encode = FALSE)
		if(!shuttle_name || QDELETED(src) || loc != user)
			return
		problem = custom_shuttle_problem(turfs, custom_shuttle_near(turfs))
		if(problem)
			report_draft(user, problem)
			return
		var/area/shuttle/custom/hull = assign_area_turfs(user, turfs, /area/shuttle/custom, force_new = TRUE, preset_name = shuttle_name)
		if(!hull)
			return
		clear_draft()
		if(!SSovermap.commission_custom_shuttle(hull, turfs))
			report_draft(user, "Зона шаттла создана, но внести его в реестр полётов не удалось.")
			return
		report_draft(user, "Шаттл «[hull.name]» внесён в реестр. Поставьте штурвал и двигатели, чтобы на нём летать.", TRUE)
		add_game_logs("registered custom shuttle [hull.name] ([length(turfs)] tiles) at [AREACOORD(user)]", user)
		return
	if(length(turfs) > BLUEPRINTS_MAX_DRAWN_TILES)
		report_draft(user, "Зона станции не может быть больше [BLUEPRINTS_MAX_DRAWN_TILES] клеток.")
		return
	for(var/turf/tile as anything in turfs)
		var/area/place = get_area(tile)
		if(isspaceturf(tile) || is_area_shuttle(place))
			report_draft(user, "В разметке есть открытый космос или шаттл.")
			return
		if(!isspacearea(place) && (!place.requires_power || place.tele_proof || place.no_teleportlocs))
			report_draft(user, "Разметка задевает защищённую зону «[place.name]».")
			return
	if(assign_area_turfs(user, turfs, new_area_type))
		clear_draft()
		last_result = null

/datum/click_intercept/blueprint_draft
	var/obj/item/areaeditor/blueprints/prints
	var/turf/last_marked

/datum/click_intercept/blueprint_draft/New(client/C, obj/item/areaeditor/blueprints/prints)
	src.prints = prints
	return ..()

/datum/click_intercept/blueprint_draft/Destroy()
	if(prints?.drafting == src)
		prints.drafting = null
	prints = null
	last_marked = null
	return ..()

/datum/click_intercept/blueprint_draft/InterceptClickOn(mob/user, params, atom/object)
	if(QDELETED(prints) || prints.loc != user)
		prints?.stop_drafting()
		if(!QDELETED(src))
			quit()
		return TRUE
	if(!isturf(object) && !isturf(object.loc))
		return FALSE
	var/turf/spot = get_turf(object)
	if(spot.z != user.z || get_dist(user, spot) > BLUEPRINTS_DRAW_RANGE)
		return TRUE
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		prints.unmark_turf(spot)
		return TRUE
	if(LAZYACCESS(modifiers, SHIFT_CLICK) && last_marked?.z == spot.z)
		for(var/turf/tile as anything in block(last_marked, spot))
			prints.mark_turf(tile)
	else
		prints.mark_turf(spot)
	last_marked = spot
	return TRUE

/obj/item/areaeditor/blueprints/proc/get_images(turf/central_turf, viewsize)
	. = list()
	var/list/dimensions = getviewsize(viewsize)
	var/horizontal_radius = dimensions[1] / 2
	var/vertical_radius = dimensions[2] / 2
	for(var/turf/nearby_turf as anything in RECT_TURFS(horizontal_radius, vertical_radius, central_turf))
		if(nearby_turf.blueprint_data)
			. += nearby_turf.blueprint_data

/obj/item/areaeditor/blueprints/proc/set_viewer(mob/user, message = "")
	if(user?.client)
		if(viewing)
			clear_viewer()
		viewing = user.client
		showing = get_images(get_turf(viewing.eye || user), viewing.view)
		viewing.images |= showing
		if(message)
			to_chat(user, message)

/obj/item/areaeditor/blueprints/proc/clear_viewer(mob/user, message = "")
	if(viewing)
		viewing.images -= showing
		viewing = null
	showing.Cut()
	if(message)
		to_chat(user, message)

/obj/item/areaeditor/blueprints/dropped(mob/user, slot, silent = FALSE)
	. = ..()
	clear_viewer()
	stop_drafting()
	legend = FALSE

/obj/item/areaeditor/blueprints/proc/view_wire_devices(mob/user)
	var/message = "<br>You examine the wire legend.<br>"
	for(var/wireset in GLOB.wire_color_directory)
		message += "<br><a href='byond://?src=[UID()];view_wireset=[wireset]'>[GLOB.wire_name_directory[wireset]]</a>"
	message += "</p>"
	return message

/obj/item/areaeditor/blueprints/proc/view_wire_set(mob/user, wireset)
	//for some reason you can't use wireset directly as a derefencer so this is the next best :/
	for(var/device in GLOB.wire_color_directory)
		if("[device]" == wireset) //I know... don't change it...
			var/message = "<p><b>[GLOB.wire_name_directory[device]]:</b>"
			for(var/Col in GLOB.wire_color_directory[device])
				var/wire_name = GLOB.wire_color_directory[device][Col]
				if(!findtext(wire_name, WIRE_DUD_PREFIX)) //don't show duds
					message += "<p><span style='color: [Col]'>[Col]</span>: [wire_name]</p>"
			message += "</p>"
			return message
	return ""

//Blueprint Subtypes

/obj/item/areaeditor/blueprints/ce/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/high_value_item)

/obj/item/areaeditor/blueprints/cyborg
	name = "station schematics"
	desc = "A digital copy of the station blueprints stored in your memory."
	fluffnotice = "Intellectual Property of Nanotrasen. For use in engineering cyborgs only. Wipe from memory upon departure from the station."
	allow_non_space_use = FALSE

/obj/item/areaeditor/blueprints/slime
	name = "cerulean prints"
	desc = "A one use set of blueprints made of jelly like organic material. Extends the reach of the management console."
	color = "#2956B2"
	allow_non_space_use = FALSE
	can_draw = FALSE

/obj/item/areaeditor/blueprints/slime/create_area_wrapper(mob/user, new_area_type)
	. = ..()
	if(.)
		qdel(src)

/obj/item/areaeditor/blueprints/slime/edit_area(mob/user)
	var/area/edited_area = ..()
	if(!edited_area)
		return
	for(var/turf/turf in edited_area.contents)
		turf.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		turf.add_atom_colour("#2956B2", FIXED_COLOUR_PRIORITY)
	edited_area.xenobiology_compatible = TRUE
	qdel(src)

//One-use area creation permits.
/obj/item/areaeditor/permit
	name = "construction permit"
	icon_state = "permit"
	desc = "This is a one-use permit that allows the user to officially declare a built room as an addition to the station."
	fluffnotice = "Nanotrasen Engineering requires all on-station construction projects to be approved by a head of staff, as detailed in Nanotrasen Company Regulation 512-C (Mid-Shift Modifications to Company Property). \
						By submitting this form, you accept any fines, fees, or personal injury/death that may occur during construction."
	w_class = WEIGHT_CLASS_TINY

/obj/item/areaeditor/permit/create_area_wrapper(mob/user, new_area_type)
	. = ..()
	if(.)
		qdel(src)

/obj/item/areaeditor/permit/interact_prints(mob/user)
	. = ..()
	var/area/user_area = get_area(user)
	if(get_area_type() == AREA_STATION)
		. += "<p>According to the [src], you are now in <b>\"[sanitize(user_area.name)]\"</b>.</p>"
	var/datum/browser/popup = new(user, "blueprints", "[src]", 700, 500)
	popup.set_content(.)
	popup.open()
	onclose(user, "blueprints")

//One-use syndicate permits. Sprites by ElGood
/obj/item/areaeditor/permit/syndicate
	name = "syndicate construction permit"
	icon_state = "permit_syndie"
	desc = "This is a one-use permit that allows the user to officially declare a built room as a property of the syndicate"
	fluffnotice = "Intellectual Property of the Syndicate. Syndicate Engineering requires all construction projects to be approved by an officer of sufficient authority, as detailed in Syndicate RaMSS Anti-Nanotrasen Company Regulation F##K-NT-027. \
					By submitting this form, you accept any fines, fees, or personal injury/death that may occur during construction."
	station_name_overrride = "RaMSS Taipan"
	new_area_type = /area/syndicate/unpowered/syndicate_space_base

// Basic area creation blueprints.
/obj/item/areaeditor/create_area_only
	name = "construction blueprints"
	desc = "Used to define new areas in space."

/obj/item/areaeditor/create_area_only/interact_prints(mob/user)
	. = ..()
	var/area/user_area = get_area(user)
	if(get_area_type() == AREA_STATION)
		. += "<p>According to the [src], you are now in <b>\"[sanitize(user_area.name)]\"</b>.</p>"
	var/datum/browser/popup = new(user, "blueprints", "[src]", 700, 500)
	popup.set_content(.)
	popup.open()
	onclose(user, "blueprints")

//Free golem blueprints
/obj/item/areaeditor/create_area_only/golem
	name = "Golem Land Claim"
	station_name_overrride = ""
	fluffnotice = "Praise the Liberator!"

//Blueprint for Theta station
/obj/item/areaeditor/create_area_only/theta
	station_name_overrride = "Theta Station"
	fluffnotice = "Метеорито-стойкая станция, даем гарантию на 200 лет!"

//Blueprint for Gorky17 station
/obj/item/areaeditor/create_area_only/gorky17
	station_name_overrride = "Gorky17 Station"
	fluffnotice = "Секретные чертежи передого фронтира Горький17"

//Blueprint for USSP station
/obj/item/areaeditor/create_area_only/ussp
	station_name_overrride = "USSP Station"
	fluffnotice = "В случае поломки — смотри сюда"

#undef AREA_ERRNONE
#undef AREA_STATION
#undef AREA_SPACE
#undef AREA_SPECIAL
#undef BLUEPRINTS_ZONE_STATION
#undef BLUEPRINTS_ZONE_SHUTTLE
#undef BLUEPRINTS_DRAW_RANGE
#undef BLUEPRINTS_MAX_DRAWN_TILES

