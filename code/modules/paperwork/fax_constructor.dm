#define FAX_PRESETS_FILE "data/fax_presets.json"
#define FAX_MAX_PRESETS 100
#define FAX_MAX_SECTIONS 20
#define FAX_MAX_ROWS 20
#define FAX_MAX_STAMPS 10
#define FAX_MAX_UNDO_STEPS 30
#define FAX_MAX_LINE_LEN 256
#define FAX_MAX_TEXT_LEN 1800
#define FAX_MAX_PRESET_NAME_LEN 64
#define FAX_MAX_LOGO_BYTES (96 * 1024)
#define FAX_MIN_FONT_SIZE 8
#define FAX_MAX_FONT_SIZE 36
#define FAX_DEFAULT_TEXT_SIZE 14
#define FAX_DEFAULT_TITLE_SIZE 20
#define FAX_TITLE_SIZE_BONUS 4
#define FAX_PAPER_WIDTH 620
#define FAX_PAPER_HEIGHT 720
#define FAX_FIELD_MARKUP "<span class=\"paper_field\"></span>"
#define FAX_CUSTOM_LOGO_PLACEHOLDER "fax_custom_logo"
#define FAX_ALL_DEPARTMENTS "All Departments"
#define FAX_SEND_CANCEL "Отмена"
#define FAX_OVERWRITE_CONFIRM "Перезаписать"

GLOBAL_LIST(fax_custom_presets)
GLOBAL_LIST_EMPTY(fax_constructor_drafts)

/proc/get_fax_custom_presets()
	if(GLOB.fax_custom_presets)
		return GLOB.fax_custom_presets
	GLOB.fax_custom_presets = list()
	if(!fexists(FAX_PRESETS_FILE))
		return GLOB.fax_custom_presets
	var/presets_text = file2text(FAX_PRESETS_FILE)
	if(!rustg_json_is_valid(presets_text))
		stack_trace("[FAX_PRESETS_FILE] contains invalid JSON, custom fax presets were not loaded")
		return GLOB.fax_custom_presets
	var/list/loaded_presets = json_decode(presets_text)
	for(var/preset_name in loaded_presets)
		if(islist(loaded_presets[preset_name]))
			GLOB.fax_custom_presets[preset_name] = loaded_presets[preset_name]
	return GLOB.fax_custom_presets

/proc/save_fax_custom_presets()
	rustg_file_write(json_encode(get_fax_custom_presets()), FAX_PRESETS_FILE, "false")

/datum/fax_constructor
	var/list/draft
	var/custom_logo
	var/next_section_id = 1
	var/faxtype = "Administrator"
	var/sender_uid
	var/origin_fax_uid
	var/reply_to_uid
	var/destination
	var/notify_sender = TRUE
	var/sending = FALSE
	var/list/undo_history = list()
	var/list/redo_history = list()
	var/last_edit_key
	var/static/list/logos = list(
		"nt" = "ntlogo.png",
		"syndicate" = "syndielogo.png",
		"ussp" = "ussplogo.png",
		"solgov" = "solgovlogo.png",
		"custom" = null,
		"none" = null,
	)
	var/static/list/fonts = list(
		PEN_FONT,
		"Arial",
		"Tahoma",
		"Trebuchet MS",
		"Georgia",
		SIGNFONT,
		"Courier New",
		CRAYON_FONT,
		FOUNTAIN_PEN_FONT,
	)
	var/static/list/block_aligns = list("left", "center", "right")
	var/static/list/text_aligns = list("left", "center", "right", "justify")
	var/static/list/section_kinds = list("fields", "text")
	var/static/list/purposes = list(
		"universal" = "Универсальный",
		"signstamp" = "С подписью и печатью",
		"signstampfax" = "С ответом по факсу",
		"confidential" = "Конфиденциальный",
		"custom" = "Свой нижний колонтитул",
	)
	var/static/list/stamp_types = list(
		"cent" = "Центральное командование",
		"ok" = "Одобрено",
		"deny" = "Отказано",
		"BIGdeny" = "Большой отказ",
		"ploho" = "Плохо",
		"syndicate" = "Синдикат",
		"ussp" = "СССП",
		"solgov" = "ТСФ",
		"navcom" = "Навигационное командование",
		"cap" = "Капитан",
		"hop" = "Глава персонала",
		"hos" = "Глава службы безопасности",
		"ward" = "Смотритель",
		"ce" = "Главный инженер",
		"rd" = "Научный руководитель",
		"cmo" = "Главный врач",
		"qm" = "Квартирмейстер",
		"law" = "Адвокат",
		"rep" = "Представитель НТ",
		"magistrate" = "Магистрат",
		"taipan" = "Тайпан",
		"clown" = "Клоун",
		"mime" = "Мим",
	)

/datum/fax_constructor/New(mob/admin, mob/sender, obj/machinery/photocopier/faxmachine/origin_fax, faxtype, datum/reply_to)
	. = ..()
	if(faxtype)
		src.faxtype = faxtype
	sender_uid = sender?.UID()
	origin_fax_uid = origin_fax?.UID()
	reply_to_uid = reply_to?.UID()
	draft = normalize_draft(default_draft())
	var/list/saved_draft = LAZYACCESS(GLOB.fax_constructor_drafts, admin?.ckey)
	if(saved_draft && !origin_fax)
		draft = normalize_draft(saved_draft["draft"])
		custom_logo = saved_draft["custom_logo"]
		return
	switch(faxtype)
		if("Central Command")
			load_builtin_preset("cc_directive")
		if("Syndicate")
			load_builtin_preset("syndicate_directive")
		if("USSP Central Committee")
			load_builtin_preset("ussp_directive")
		else
			load_builtin_preset("nt_blank")

/datum/fax_constructor/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/fax_constructor/ui_close(mob/user)
	if(!origin_fax_uid && user?.ckey)
		GLOB.fax_constructor_drafts[user.ckey] = list("draft" = draft, "custom_logo" = custom_logo)
	qdel(src)

/datum/fax_constructor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FaxConstructor", "Конструктор бланков")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/fax_constructor/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/paper))

/datum/fax_constructor/ui_static_data(mob/user)
	. = list()
	.["custom_logo"] = custom_logo
	.["fonts"] = fonts
	.["purposes"] = options_for_ui(purposes)
	.["stamp_types"] = options_for_ui(stamp_types)
	.["max_sections"] = FAX_MAX_SECTIONS
	.["max_rows"] = FAX_MAX_ROWS
	.["max_stamps"] = FAX_MAX_STAMPS
	.["max_line_len"] = FAX_MAX_LINE_LEN
	.["max_text_len"] = FAX_MAX_TEXT_LEN
	.["max_fields"] = MAX_PAPER_FIELDS
	.["min_font_size"] = FAX_MIN_FONT_SIZE
	.["max_font_size"] = FAX_MAX_FONT_SIZE
	.["custom_presets"] = custom_presets_for_ui()
	var/list/builtin = list()
	var/list/presets = builtin_presets()
	for(var/preset_id in presets)
		var/list/preset = presets[preset_id]
		builtin += list(list(
			"id" = preset_id,
			"name" = preset["name"],
			"category" = preset["category"],
			"preview_html" = render_preview_of(builtin_draft(preset)),
		))
	.["builtin_presets"] = builtin

/datum/fax_constructor/ui_data(mob/user)
	. = list()
	var/obj/machinery/photocopier/faxmachine/origin_fax = locateUID(origin_fax_uid)
	var/mob/sender = locateUID(sender_uid)
	.["draft"] = draft
	.["preview_html"] = render_preview()
	.["field_count"] = length(splittext(render_body(FALSE), FAX_FIELD_MARKUP)) - 1
	.["destinations"] = available_destinations()
	.["destination"] = destination
	.["notify_sender"] = notify_sender
	.["faxtype"] = faxtype
	.["reply_department"] = origin_fax?.department
	.["reply_sender"] = sender?.name
	.["sending"] = sending
	.["can_undo"] = length(undo_history) > 0
	.["can_redo"] = length(redo_history) > 0

/datum/fax_constructor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	if(!check_rights(R_ADMIN))
		return

	return handle_action(action, params, ui, usr)

/datum/fax_constructor/proc/handle_action(action, list/params, datum/tgui/ui, mob/user)
	switch(action)
		if("set_draft")
			remember_draft("draft:[params["key"]]")
			draft[params["key"]] = params["value"]
			draft = normalize_draft(draft)
			return TRUE
		if("toggle_stamp")
			remember_draft()
			var/list/stamps = draft["stamps"]
			if(params["stamp"] in stamps)
				stamps -= params["stamp"]
			else
				stamps += params["stamp"]
			draft = normalize_draft(draft)
			return TRUE
		if("add_section")
			var/list/sections = draft["sections"]
			if(length(sections) >= FAX_MAX_SECTIONS)
				return FALSE
			remember_draft()
			var/list/after_section = find_section(params["after"])
			sections.Insert(after_section ? sections.Find(after_section) + 1 : length(sections) + 1, list(new_section(params["kind"])))
			draft = normalize_draft(draft)
			return TRUE
		if("set_section")
			var/list/section = find_section(params["id"])
			if(!section)
				return FALSE
			remember_draft("section:[params["id"]]:[params["key"]]")
			section[params["key"]] = params["value"]
			draft = normalize_draft(draft)
			return TRUE
		if("style_all_sections")
			var/list/source_section = find_section(params["id"])
			if(!source_section)
				return FALSE
			remember_draft()
			for(var/list/section as anything in draft["sections"])
				for(var/style_key in clean_style(source_section))
					section[style_key] = source_section[style_key]
			return TRUE
		if("remove_section")
			var/list/section = find_section(params["id"])
			if(!section)
				return FALSE
			remember_draft()
			var/list/sections = draft["sections"]
			sections -= list(section)
			return TRUE
		if("duplicate_section")
			var/list/section = find_section(params["id"])
			var/list/sections = draft["sections"]
			if(!section || length(sections) >= FAX_MAX_SECTIONS)
				return FALSE
			remember_draft()
			var/list/section_copy = section.Copy()
			section_copy["id"] = null
			sections.Insert(sections.Find(section) + 1, list(section_copy))
			draft = normalize_draft(draft)
			return TRUE
		if("move_section")
			var/list/section = find_section(params["id"])
			if(!section)
				return FALSE
			remember_draft()
			var/list/sections = draft["sections"]
			return swap_with_neighbour(sections, sections.Find(section), params["direction"])
		if("reorder_section")
			var/list/section = find_section(params["id"])
			if(!section)
				return FALSE
			remember_draft()
			var/list/sections = draft["sections"]
			return move_within(sections, sections.Find(section), params["index"])
		if("add_row")
			var/list/section = find_section(params["id"])
			if(!section)
				return FALSE
			var/list/rows = section["rows"]
			if(length(rows) >= FAX_MAX_ROWS)
				return FALSE
			remember_draft()
			rows += list(list("label" = "Новое поле:", "hint" = "", "value" = ""))
			return TRUE
		if("set_row")
			var/list/row = find_row(find_section(params["id"]), params["index"])
			if(!row)
				return FALSE
			remember_draft("row:[params["id"]]:[params["index"]]:[params["key"]]")
			row[params["key"]] = params["value"]
			draft = normalize_draft(draft)
			return TRUE
		if("remove_row")
			var/list/section = find_section(params["id"])
			if(!find_row(section, params["index"]))
				return FALSE
			remember_draft()
			var/list/rows = section["rows"]
			rows.Cut(params["index"], params["index"] + 1)
			return TRUE
		if("reorder_row")
			var/list/section = find_section(params["id"])
			if(!find_row(section, params["index"]))
				return FALSE
			remember_draft()
			return move_within(section["rows"], params["index"], params["target"])
		if("undo")
			return step_history(undo_history, redo_history)
		if("redo")
			return step_history(redo_history, undo_history)
		if("new_draft")
			remember_draft()
			load_builtin_preset("nt_blank")
			return TRUE
		if("set_destination")
			if(params["destination"] in available_destinations())
				destination = params["destination"]
			return TRUE
		if("toggle_notify")
			notify_sender = !notify_sender
			return TRUE
		if("load_preset")
			remember_draft()
			var/old_logo = custom_logo
			if(params["builtin"])
				load_builtin_preset(params["id"])
			else
				load_custom_preset(params["id"])
			if(custom_logo != old_logo)
				ui?.send_update(list("custom_logo" = custom_logo))
			return TRUE
		if("save_preset")
			if(save_preset(user))
				ui?.send_update(list("custom_presets" = custom_presets_for_ui()))
			return TRUE
		if("delete_preset")
			var/list/presets = get_fax_custom_presets()
			if(!presets[params["id"]])
				return FALSE
			presets -= params["id"]
			save_fax_custom_presets()
			log_admin("[key_name(user)] deleted the fax preset '[params["id"]]'")
			message_admins("[key_name_admin(user)] deleted the fax preset '[html_encode(params["id"])]'")
			ui?.send_update(list("custom_presets" = custom_presets_for_ui()))
			return TRUE
		if("upload_logo")
			if(upload_logo(user))
				ui?.send_update(list("custom_logo" = custom_logo))
			return TRUE
		if("preview")
			var/obj/item/paper/preview_paper = build_paper()
			preview_paper.show_content(user, forceshow = TRUE)
			qdel(preview_paper)
			return FALSE
		if("create")
			var/obj/item/paper/created_paper = build_paper()
			created_paper.forceMove(get_turf(user))
			log_admin("[key_name(user)] created a paper form '[created_paper.name]' at [AREACOORD(user)]: [created_paper.info]")
			message_admins("[key_name_admin(user)] created a paper form '[created_paper.name]' at [ADMIN_COORDJMP(user)] (<a href='byond://?_src_=holder;AdminFaxView=[created_paper.UID()]'>VIEW</a>).")
			return FALSE
		if("send")
			send_fax(user)
			return TRUE

/datum/fax_constructor/proc/remember_draft(edit_key)
	if(edit_key && edit_key == last_edit_key)
		return
	last_edit_key = edit_key
	undo_history += list(normalize_draft(draft))
	if(length(undo_history) > FAX_MAX_UNDO_STEPS)
		undo_history.Cut(1, 2)
	redo_history.Cut()

/datum/fax_constructor/proc/step_history(list/from_history, list/to_history)
	if(!length(from_history))
		return FALSE
	last_edit_key = null
	to_history += list(draft)
	draft = from_history[length(from_history)]
	from_history.len--
	return TRUE

/datum/fax_constructor/proc/move_within(list/target_list, index, target_index)
	if(!isnum(target_index) || target_index < 1 || target_index > length(target_list) || target_index == index)
		return FALSE
	var/moved_entry = target_list[index]
	target_list.Cut(index, index + 1)
	target_list.Insert(target_index, list(moved_entry))
	return TRUE

/datum/fax_constructor/proc/new_section(kind)
	switch(kind)
		if("fields")
			return fields_section("Новый блок", list(field_row("Новое поле:")))
		if("applicant")
			return applicant_section("Основная информация")
		if("signatures")
			return signatures_section(list("Время:", "Подпись заявителя:", "Подпись главы персонала:"))
	return text_section("Новый блок", "", fillable = TRUE)

/datum/fax_constructor/proc/custom_presets_for_ui()
	. = list()
	var/list/stored_presets = get_fax_custom_presets()
	for(var/preset_name in stored_presets)
		var/list/preset = stored_presets[preset_name]
		. += list(list("name" = preset_name, "author" = preset["author"], "preview_html" = preset["preview_html"]))

/datum/fax_constructor/proc/render_preview()
	return "[render_header(TRUE)][render_body(TRUE)][render_footer()][render_stamps()]"

/datum/fax_constructor/proc/render_preview_of(list/raw_draft)
	var/list/current_draft = draft
	draft = normalize_draft(raw_draft)
	. = render_preview()
	draft = current_draft

/datum/fax_constructor/proc/builtin_draft(list/preset)
	. = default_draft()
	var/list/overrides = preset["draft"]
	for(var/key in overrides)
		.[key] = overrides[key]

/datum/fax_constructor/proc/available_destinations()
	return GLOB.alldepartments + GLOB.hidden_departments + GLOB.hidden_ussp + FAX_ALL_DEPARTMENTS

/datum/fax_constructor/proc/options_for_ui(list/options)
	. = list()
	for(var/option in options)
		. += list(list("value" = option, "label" = options[option]))

/datum/fax_constructor/proc/find_section(section_id)
	for(var/list/section as anything in draft["sections"])
		if(section["id"] == section_id)
			return section

/datum/fax_constructor/proc/find_row(list/section, index)
	if(!section || !isnum(index) || index < 1 || index > length(section["rows"]))
		return null
	return section["rows"][index]

/datum/fax_constructor/proc/swap_with_neighbour(list/target_list, index, direction)
	var/neighbour = index + (direction == "up" ? -1 : 1)
	if(neighbour < 1 || neighbour > length(target_list))
		return FALSE
	target_list.Swap(index, neighbour)
	return TRUE

/datum/fax_constructor/proc/clean_text(value, max_length = FAX_MAX_LINE_LEN)
	return istext(value) ? copytext_char(value, 1, max_length + 1) : ""

/datum/fax_constructor/proc/clean_choice(value, list/allowed, fallback)
	return (value in allowed) ? value : fallback

/datum/fax_constructor/proc/clean_list(value)
	return islist(value) ? value : list()

/datum/fax_constructor/proc/clean_style(list/raw, default_size = FAX_DEFAULT_TEXT_SIZE)
	return list(
		"font" = clean_choice(raw["font"], fonts, PEN_FONT),
		"size" = isnum(raw["size"]) ? clamp(round(raw["size"]), FAX_MIN_FONT_SIZE, FAX_MAX_FONT_SIZE) : default_size,
		"color" = sanitize_hexcolor(raw["color"], default = "#000000"),
		"bold" = !!raw["bold"],
		"italic" = !!raw["italic"],
		"underline" = !!raw["underline"],
		"strike" = !!raw["strike"],
	)

/datum/fax_constructor/proc/normalize_draft(list/raw)
	. = clean_style(raw, FAX_DEFAULT_TITLE_SIZE)
	.["logo"] = clean_choice(raw["logo"], logos, "nt")
	.["align"] = clean_choice(raw["align"], block_aligns, "left")
	.["text_align"] = clean_choice(raw["text_align"], text_aligns, "left")
	.["purpose"] = clean_choice(raw["purpose"], purposes, "universal")
	for(var/key in list("form_id", "title", "organization", "category", "notice", "sender_name", "stamp_text"))
		.[key] = clean_text(raw[key])
	.["footer_text"] = clean_text(raw["footer_text"], FAX_MAX_TEXT_LEN)

	var/list/stamps = list()
	for(var/stamp in clean_list(raw["stamps"]))
		if((stamp in stamp_types) && length(stamps) < FAX_MAX_STAMPS)
			stamps |= stamp
	.["stamps"] = stamps

	var/list/sections = list()
	for(var/raw_section in clean_list(raw["sections"]))
		if(islist(raw_section) && length(sections) < FAX_MAX_SECTIONS)
			sections += list(normalize_section(raw_section))
	.["sections"] = sections

/datum/fax_constructor/proc/normalize_section(list/raw)
	. = clean_style(raw, FAX_DEFAULT_TEXT_SIZE)
	if(isnum(raw["id"]))
		.["id"] = raw["id"]
		next_section_id = max(next_section_id, raw["id"] + 1)
	else
		.["id"] = next_section_id++
	.["kind"] = clean_choice(raw["kind"], section_kinds, "text")
	.["title"] = clean_text(raw["title"])
	.["title_align"] = clean_choice(raw["title_align"], text_aligns, "center")
	.["text_align"] = clean_choice(raw["text_align"], text_aligns, "left")
	.["text"] = clean_text(raw["text"], FAX_MAX_TEXT_LEN)
	.["divider"] = !!raw["divider"]
	.["fillable"] = !!raw["fillable"]

	var/list/rows = list()
	for(var/list/raw_row in clean_list(raw["rows"]))
		if(length(rows) < FAX_MAX_ROWS)
			rows += list(list(
				"label" = clean_text(raw_row["label"]),
				"hint" = clean_text(raw_row["hint"]),
				"value" = clean_text(raw_row["value"]),
			))
	.["rows"] = rows

/datum/fax_constructor/proc/pencode(text)
	return admin_pencode_to_html(html_encode(text), null, null, TRUE, TRUE, TRUE, PEN_FONT, SIGNFONT, CRAYON_FONT, TRUE)

/datum/fax_constructor/proc/base_style(list/style, align)
	return "font-family:[style["font"]];color:[style["color"]];text-align:[align]"

/datum/fax_constructor/proc/full_style(list/style, align)
	var/list/decorations = list()
	if(style["underline"])
		decorations += "underline"
	if(style["strike"])
		decorations += "line-through"
	. = "[base_style(style, align)];font-size:[style["size"]]px"
	if(style["bold"])
		. += ";font-weight:bold"
	if(style["italic"])
		. += ";font-style:italic"
	if(length(decorations))
		. += ";text-decoration:[jointext(decorations, " ")]"

/datum/fax_constructor/proc/render_logo(preview)
	var/logo_file = logos[draft["logo"]]
	if(logo_file)
		return "<img src='[logo_file]' style='max-width:200px;max-height:135px'>"
	if(draft["logo"] != "custom" || !custom_logo)
		return ""
	return "<img src='[preview ? FAX_CUSTOM_LOGO_PLACEHOLDER : "data:image/png;base64,[custom_logo]"]' style='max-width:200px;max-height:135px'>"

/datum/fax_constructor/proc/render_header(preview)
	var/base = base_style(draft, draft["text_align"])
	var/small_rule = "font-size:11px"
	var/list/lines = list()
	var/is_confidential = draft["purpose"] == "confidential"
	if(draft["form_id"] || is_confidential)
		lines += "<div style='[base];[small_rule]'>[pencode(draft["form_id"])][is_confidential ? " \[КОНФИДЕНЦИАЛЬНО\]" : ""]</div>"
	if(draft["title"])
		lines += "<div style='[full_style(draft, draft["text_align"])]'>[pencode(draft["title"])]</div>"
	if(draft["organization"] || draft["category"])
		lines += "<table style='width:100%;margin-top:6px'><tr><td style='[base]'>[pencode(draft["organization"])]</td><td style='[base_style(draft, "right")];width:30%;vertical-align:top'>[pencode(draft["category"])]</td></tr></table>"

	var/logo_html = render_logo(preview)
	var/header_text = jointext(lines, "")
	var/logo_cell = "<td style='width:1%;vertical-align:top;padding:0 10px'>[logo_html]</td>"
	var/text_cell = "<td style='vertical-align:top'>[header_text]</td>"
	var/list/html = list()
	if(!logo_html)
		html += header_text
	else
		switch(draft["align"])
			if("center")
				html += "<div style='text-align:center'>[logo_html]</div>[header_text]"
			if("right")
				html += "<table style='width:100%'><tr>[text_cell][logo_cell]</tr></table>"
			else
				html += "<table style='width:100%'><tr>[logo_cell][text_cell]</tr></table>"
	if(draft["notice"])
		html += "<div style='[base_style(draft, "center")];[small_rule];margin-top:6px'>[pencode(draft["notice"])]</div>"
	if(!logo_html && !header_text && !draft["notice"])
		return ""
	return "<div[preview ? " data-section='header'" : ""]>[jointext(html, "")]</div>"

/datum/fax_constructor/proc/render_section(list/section, preview)
	var/content_style = full_style(section, section["text_align"])
	var/list/html = list()
	if(section["divider"])
		html += "<hr>"
	if(section["title"])
		html += "<div style='[base_style(section, section["title_align"])];font-size:[section["size"] + FAX_TITLE_SIZE_BONUS]px;font-weight:bold;margin:8px 0'>[pencode(section["title"])]</div>"
	if(section["kind"] == "fields")
		html += "<table style='width:100%'>"
		for(var/list/row as anything in section["rows"])
			var/hint = row["hint"] ? "<br><font size=\"1\">[pencode(row["hint"])]</font>" : ""
			html += "<tr><td style='[content_style];width:45%;vertical-align:top'>[pencode(row["label"])][hint]</td><td style='[content_style];vertical-align:top'>[row["value"] ? pencode(row["value"]) : FAX_FIELD_MARKUP]</td></tr>"
		html += "</table>"
	else
		html += "<div style='[content_style]'>[pencode(section["text"])][section["fillable"] ? FAX_FIELD_MARKUP : ""]</div>"
	return "<div[preview ? " data-section='[section["id"]]'" : ""]>[jointext(html, "")]</div>"

/datum/fax_constructor/proc/render_body(preview)
	. = ""
	for(var/list/section as anything in draft["sections"])
		. += render_section(section, preview)

/datum/fax_constructor/proc/render_footer()
	switch(draft["purpose"])
		if("signstamp")
			return /obj/item/paper/form::footer_signstamp
		if("signstampfax")
			return /obj/item/paper/form::footer_signstampfax
		if("confidential")
			return /obj/item/paper/form::footer_confidential
		if("custom")
			return "<br><font face=\"[PEN_FONT]\" color=black><hr><center><font size=\"1\">[pencode(draft["footer_text"])]</font></center></font>"

/datum/fax_constructor/proc/render_stamps()
	if(!length(draft["stamps"]) && !draft["stamp_text"])
		return ""
	. = "<div data-section='stamps'><hr>"
	for(var/stamp in draft["stamps"])
		. += "<img src='large_stamp-[stamp].png'>"
	if(draft["stamp_text"])
		. += "<i>[html_encode(draft["stamp_text"])]</i>"
	. += "</div>"

/datum/fax_constructor/proc/build_paper()
	var/obj/item/paper/paper = new(null)
	var/title = trim(strip_html_properly(pencode(draft["title"])))
	if(!title)
		title = "paper"
	paper.name = draft["sender_name"] ? "[html_encode(draft["sender_name"])]- [title]" : title
	paper.header = render_header(FALSE)
	paper.info = render_body(FALSE)
	paper.footer = render_footer()
	paper.paper_width = FAX_PAPER_WIDTH
	paper.paper_height = FAX_PAPER_HEIGHT
	if(draft["logo"] == "ussp")
		paper.language = /datum/language/com_srus
	paper.populatefields()
	paper.updateinfolinks()
	paper.update_icon(UPDATE_ICON_STATE)
	for(var/stamp in draft["stamps"])
		paper.stamp(/obj/item/stamp/centcom, special_stamped = "<img src='large_stamp-[stamp].png'>", special_icon_state = "stamp-[stamp]")
	if(draft["stamp_text"])
		paper.stamp(/obj/item/stamp, special_stamped = "<i>[html_encode(draft["stamp_text"])]</i>", special_icon_state = "stamp-text")
	return paper

/datum/fax_constructor/proc/send_fax(mob/user)
	if(sending)
		return
	var/obj/machinery/photocopier/faxmachine/fax = locateUID(origin_fax_uid)
	if(origin_fax_uid && !fax)
		to_chat(user, span_warning("Факс отправителя больше не существует."), confidential = TRUE)
		return
	if(!fax && !destination)
		to_chat(user, span_warning("Сначала выберите получателя."), confidential = TRUE)
		return

	sending = TRUE
	if(!fax && destination != FAX_ALL_DEPARTMENTS)
		for(var/obj/machinery/photocopier/faxmachine/department_fax as anything in GLOB.allfaxes)
			if(department_fax.department == destination)
				fax = department_fax

	var/mob/sender = locateUID(sender_uid)
	user.client.holder.transmit_admin_fax(build_paper(), origin_fax_uid ? null : destination, fax, faxtype, locateUID(reply_to_uid), sender, notify_sender)
	sending = FALSE

/datum/fax_constructor/proc/upload_logo(mob/user)
	var/uploaded = input(user, "Выберите PNG-файл (до [FAX_MAX_LOGO_BYTES / 1024] КБ).", "Логотип бланка") as null|file
	if(!uploaded || QDELETED(src))
		return FALSE
	if(LOWER_TEXT(copytext("[uploaded]", -4)) != ".png" || length(uploaded) > FAX_MAX_LOGO_BYTES)
		to_chat(user, span_warning("Нужен PNG-файл размером до [FAX_MAX_LOGO_BYTES / 1024] КБ."), confidential = TRUE)
		return FALSE
	var/encoded_logo = encode_logo(uploaded)
	if(!encoded_logo)
		to_chat(user, span_warning("Не удалось прочитать изображение."), confidential = TRUE)
		return FALSE
	custom_logo = encoded_logo
	draft["logo"] = "custom"
	log_admin("[key_name(user)] uploaded a custom fax logo ([uploaded])")
	return TRUE

/datum/fax_constructor/proc/encode_logo(logo_file)
	var/icon/logo_icon
	try
		logo_icon = icon(logo_file)
	catch
		return null
	if(!isicon(logo_icon) || !logo_icon.Width())
		return null
	var/encoded_logo = icon2base64(logo_icon)
	return is_valid_logo(encoded_logo) ? encoded_logo : null

/datum/fax_constructor/proc/is_valid_logo(encoded_logo)
	var/static/regex/base64_regex = regex(@"^[A-Za-z0-9+/=]+$")
	return istext(encoded_logo) && length(encoded_logo) <= FAX_MAX_LOGO_BYTES * 2 && base64_regex.Find(encoded_logo)

/datum/fax_constructor/proc/load_builtin_preset(preset_id)
	var/list/presets = builtin_presets()
	var/list/preset = presets[preset_id]
	if(preset)
		draft = normalize_draft(builtin_draft(preset))

/datum/fax_constructor/proc/load_custom_preset(preset_name)
	var/list/presets = get_fax_custom_presets()
	var/list/preset = presets[preset_name]
	if(!preset)
		return
	draft = normalize_draft(clean_list(preset["draft"]))
	if(is_valid_logo(preset["custom_logo"]))
		custom_logo = preset["custom_logo"]

/datum/fax_constructor/proc/save_preset(mob/user)
	var/preset_name = tgui_input_text(user, "Название шаблона:", "Сохранить шаблон", draft["title"], max_length = FAX_MAX_PRESET_NAME_LEN, encode = FALSE)
	preset_name = trim(preset_name)
	if(!preset_name || QDELETED(src))
		return
	var/list/presets = get_fax_custom_presets()
	if(presets[preset_name])
		if(tgui_alert(user, "Шаблон «[preset_name]» уже существует. Перезаписать?", "Сохранить шаблон", list(FAX_OVERWRITE_CONFIRM, FAX_SEND_CANCEL)) != FAX_OVERWRITE_CONFIRM || QDELETED(src))
			return
	else if(length(presets) >= FAX_MAX_PRESETS)
		to_chat(user, span_warning("Достигнут предел в [FAX_MAX_PRESETS] шаблонов, удалите ненужные."), confidential = TRUE)
		return
	presets[preset_name] = list(
		"author" = user.ckey,
		"draft" = normalize_draft(draft),
		"custom_logo" = draft["logo"] == "custom" ? custom_logo : null,
		"preview_html" = render_preview(),
	)
	save_fax_custom_presets()
	log_admin("[key_name(user)] saved the fax preset '[preset_name]'")
	message_admins("[key_name_admin(user)] saved the fax preset '[html_encode(preset_name)]'")
	return TRUE

/datum/fax_constructor/proc/default_draft()
	return list(
		"logo" = "nt",
		"align" = "left",
		"text_align" = "left",
		"font" = PEN_FONT,
		"size" = FAX_DEFAULT_TITLE_SIZE,
		"color" = "#000000",
		"bold" = TRUE,
		"purpose" = "universal",
		"form_id" = "Форма NT",
		"title" = "Пустой бланк для любых целей",
		"organization" = "Научная станция \"Нанотрейзен\" \"\[station\]\"",
		"category" = "Общие формы",
		"notice" = "Перед заполнением прочтите от начала до конца | Во всех PDA имеется ручка",
		"sections" = list(),
		"stamps" = list(),
	)

/datum/fax_constructor/proc/fields_section(title, list/rows)
	return list("kind" = "fields", "title" = title, "divider" = TRUE, "rows" = rows)

/datum/fax_constructor/proc/text_section(title, text, fillable = FALSE, divider = TRUE)
	return list("kind" = "text", "title" = title, "text" = text, "fillable" = fillable, "divider" = divider)

/datum/fax_constructor/proc/field_row(label, hint)
	return list("label" = label, "hint" = hint)

/datum/fax_constructor/proc/applicant_section(title)
	return fields_section(title, list(
		field_row("Имя заявителя:", "Полностью и без ошибок"),
		field_row("Номер аккаунта заявителя:", "Эта информация есть в ваших заметках"),
		field_row("Текущая должность:", "Указано на ID карте"),
	))

/datum/fax_constructor/proc/signatures_section(list/labels)
	var/list/rows = list()
	for(var/label in labels)
		rows += list(field_row(label))
	return fields_section("Подписи и штампы", rows)

/datum/fax_constructor/proc/directive_draft(logo, form_id, title, organization, sender_name, stamp, text)
	return list(
		"logo" = logo,
		"align" = "center",
		"text_align" = "center",
		"form_id" = form_id,
		"title" = title,
		"organization" = organization,
		"category" = "",
		"notice" = "",
		"sender_name" = sender_name,
		"stamps" = list(stamp),
		"sections" = list(text_section("", text)),
	)

/datum/fax_constructor/proc/builtin_presets()
	var/static/list/nt_signatures = list("Время:", "Подпись заявителя:", "Подпись главы персонала:", "Подпись (дополнительная):")
	var/cc_name = command_name()
	return list(
		"nt_blank" = list(
			"name" = "Пустой бланк",
			"category" = "Бланки станции",
			"draft" = list("sections" = list(
				applicant_section("Основная информация"),
				text_section("Заявление", "", fillable = TRUE),
				signatures_section(nt_signatures),
			)),
		),
		"nt_order" = list(
			"name" = "Приказ",
			"category" = "Бланки станции",
			"draft" = list(
				"form_id" = "Форма NT-COM-ORDER",
				"title" = "Приказ",
				"category" = "Главы станции",
				"purpose" = "signstampfax",
				"sections" = list(
					text_section("", "Я, \[field\], в должности \[field\], приказываю:\n\n", fillable = TRUE),
					signatures_section(list("Подпись инициатора:", "Время подписания приказа:", "Дата подписания приказа:")),
				),
			),
		),
		"nt_incident" = list(
			"name" = "Отчёт об инциденте",
			"category" = "Бланки станции",
			"draft" = list(
				"form_id" = "Форма NT-E-112",
				"title" = "Экстренное письмо",
				"notice" = "Форма предназначена только для экстренного использования.",
				"purpose" = "signstamp",
				"sections" = list(
					applicant_section("Основная информация"),
					text_section("Отчёт о ситуации", "", fillable = TRUE),
					signatures_section(list("Время:", "Подпись уполномоченного лица:", "Должность уполномоченного лица:")),
				),
			),
		),
		"cc_directive" = list(
			"name" = "Директива",
			"category" = "Центральное командование",
			"draft" = directive_draft("nt", "Форма NT-CC-DRV", "Директива Центрального командования", cc_name, cc_name, "cent", "Экипажу \[station\] предписывается:\n\n"),
		),
		"cc_status_request" = list(
			"name" = "Запрос отчёта о станции",
			"category" = "Центральное командование",
			"draft" = list(
				"form_id" = "Форма NT-CC-REQ",
				"title" = "Запрос отчёта о ситуации на станции",
				"organization" = cc_name,
				"category" = "Центральное командование",
				"sender_name" = cc_name,
				"purpose" = "signstampfax",
				"stamps" = list("cent"),
				"sections" = list(
					fields_section("Текущая обстановка", list(
						field_row("Код станции:"),
						field_row("Активные угрозы:"),
						field_row("Потери среди экипажа:"),
						field_row("Повреждения станции:"),
						field_row("Дополнительная информация:"),
					)),
					signatures_section(list("Время:", "Подпись уполномоченного лица:", "Должность уполномоченного лица:")),
				),
			),
		),
		"cc_granted" = list(
			"name" = "Запрос одобрен",
			"category" = "Центральное командование",
			"draft" = directive_draft("nt", "Форма NT-CC-ANS", "Решение по запросу: одобрено", cc_name, cc_name, "ok", "Ваш запрос рассмотрен и \[b\]одобрен\[/b\].\n\nКомментарий: "),
		),
		"cc_denied" = list(
			"name" = "Запрос отклонён",
			"category" = "Центральное командование",
			"draft" = directive_draft("nt", "Форма NT-CC-ANS", "Решение по запросу: отклонено", cc_name, cc_name, "deny", "Ваш запрос рассмотрен и \[b\]отклонён\[/b\].\n\nПричина: "),
		),
		"cc_confidential" = list(
			"name" = "Конфиденциальное сообщение",
			"category" = "Центральное командование",
			"draft" = list(
				"form_id" = "Форма NT-CC-CONF",
				"title" = "Конфиденциальное сообщение",
				"organization" = cc_name,
				"category" = "Только для получателя",
				"notice" = "",
				"sender_name" = cc_name,
				"purpose" = "confidential",
				"stamps" = list("cent"),
				"sections" = list(text_section("", "")),
			),
		),
		"syndicate_directive" = list(
			"name" = "Директива Синдиката",
			"category" = "Другие организации",
			"draft" = directive_draft("syndicate", "", "Директива", "Синдикат", "UNKNOWN", "syndicate", "Агент, вам предписывается:\n\n"),
		),
		"ussp_directive" = list(
			"name" = "Директива СССП",
			"category" = "Другие организации",
			"draft" = directive_draft("ussp", "", "Директива", "Народный комиссариат космических станций и планетоидов СССП", "Первый секретарь народного комиссара космических станций и планетоидов СССП", "ussp", "Товарищи, вам предписывается:\n\n"),
		),
		"solgov_note" = list(
			"name" = "Нота ТСФ",
			"category" = "Другие организации",
			"draft" = directive_draft("solgov", "", "Дипломатическая нота", "Транс-Солнечная Федерация", "Транс-Солнечная Федерация", "solgov", "Настоящим уведомляем \[station\]:\n\n"),
		),
		"empty" = list(
			"name" = "Чистый лист",
			"category" = "Другие организации",
			"draft" = list(
				"logo" = "none",
				"form_id" = "",
				"title" = "",
				"organization" = "",
				"category" = "",
				"notice" = "",
				"sections" = list(text_section("", "", divider = FALSE)),
			),
		),
	)

#undef FAX_PRESETS_FILE
#undef FAX_MAX_PRESETS
#undef FAX_MAX_SECTIONS
#undef FAX_MAX_ROWS
#undef FAX_MAX_STAMPS
#undef FAX_MAX_UNDO_STEPS
#undef FAX_MAX_LINE_LEN
#undef FAX_MAX_TEXT_LEN
#undef FAX_MAX_PRESET_NAME_LEN
#undef FAX_MAX_LOGO_BYTES
#undef FAX_MIN_FONT_SIZE
#undef FAX_MAX_FONT_SIZE
#undef FAX_DEFAULT_TEXT_SIZE
#undef FAX_DEFAULT_TITLE_SIZE
#undef FAX_TITLE_SIZE_BONUS
#undef FAX_PAPER_WIDTH
#undef FAX_PAPER_HEIGHT
#undef FAX_FIELD_MARKUP
#undef FAX_CUSTOM_LOGO_PLACEHOLDER
#undef FAX_ALL_DEPARTMENTS
#undef FAX_SEND_CANCEL
#undef FAX_OVERWRITE_CONFIRM
