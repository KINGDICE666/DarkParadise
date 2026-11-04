/datum/unit_test/fax_constructor

/datum/unit_test/fax_constructor/Run()
	var/datum/fax_constructor/constructor = allocate(/datum/fax_constructor)

	var/list/presets = constructor.builtin_presets()
	for(var/preset_id in presets)
		constructor.load_builtin_preset(preset_id)
		var/obj/item/paper/preset_paper = constructor.build_paper()
		TEST_ASSERT(preset_paper.name, "Preset [preset_id] built a paper with no name")
		TEST_ASSERT_EQUAL(preset_paper.fields, length(splittext(preset_paper.info, "<span class=\"paper_field\">")) - 1, "Preset [preset_id] lost track of its fields")
		TEST_ASSERT_EQUAL(LAZYLEN(preset_paper.stamped), length(constructor.draft["stamps"]), "Preset [preset_id] lost its stamps")
		for(var/section_key in list("\[b\]", "\[field\]", "\[station\]"))
			TEST_ASSERT_NOT(findtext(preset_paper.info, section_key), "Preset [preset_id] left pencode [section_key] unparsed")
		qdel(preset_paper)

	var/list/hostile_draft = constructor.default_draft()
	hostile_draft["font"] = "Verdana;background:url(evil)"
	hostile_draft["color"] = "red;background:url(evil)"
	hostile_draft["size"] = 9000
	hostile_draft["logo"] = "' onerror='evil"
	hostile_draft["align"] = "' onclick='evil"
	hostile_draft["title"] = "<script>evil()</script>"
	hostile_draft["stamps"] = list("cent", "' onerror='evil")
	hostile_draft["stamp_text"] = "<script>evil()</script>"
	hostile_draft["sections"] = list(
		list("kind" = "text", "title" = "<img src=evil>", "text" = "<script>evil()</script>", "text_align" = "';evil"),
		list("kind" = "fields", "rows" = list(list("label" = "<b>evil</b>", "hint" = "<i>evil</i>", "value" = "<u>evil</u>"))),
		"not a section",
	)
	constructor.draft = constructor.normalize_draft(hostile_draft)
	TEST_ASSERT_EQUAL(constructor.draft["font"], PEN_FONT, "Unknown font was not rejected")
	TEST_ASSERT_EQUAL(constructor.draft["size"], 36, "Font size was not clamped")
	TEST_ASSERT_EQUAL(constructor.draft["logo"], "nt", "Unknown logo was not rejected")
	TEST_ASSERT_EQUAL(length(constructor.draft["stamps"]), 1, "Unknown stamp was not rejected")
	TEST_ASSERT_EQUAL(length(constructor.draft["sections"]), 2, "Malformed section was not dropped")

	var/obj/item/paper/hostile_paper = constructor.build_paper()
	var/hostile_html = "[hostile_paper.header][hostile_paper.info][hostile_paper.stamps]"
	for(var/forbidden in list("<script", "<img src=evil", "<b>evil", "<i>evil", "<u>evil", "url(evil", "onerror", "onclick", "';evil"))
		TEST_ASSERT_NOT(findtext(hostile_html, forbidden), "Rendered paper contains [forbidden]")
	qdel(hostile_paper)

	var/encoded_logo = constructor.encode_logo(file("icons/misc/paper_icons/ntlogo.png"))
	TEST_ASSERT(findtextEx(encoded_logo, "iVBORw0KGgo") == 1, "PNG upload was not encoded as a PNG")
	TEST_ASSERT_NULL(constructor.encode_logo(file("code/__DEFINES/say.dm")), "A non-image upload was accepted as a logo")
	TEST_ASSERT_NOT(constructor.is_valid_logo("'><script>"), "A logo with markup passed validation")

	constructor.custom_logo = encoded_logo
	constructor.draft["logo"] = "custom"
	TEST_ASSERT_NOT(findtextEx(constructor.render_header(TRUE), encoded_logo), "The preview carries the logo bytes in every update")
	TEST_ASSERT_SUBSTRING(constructor.render_header(FALSE), "data:image/png;base64,[encoded_logo]")

	constructor.load_builtin_preset("nt_blank")
	var/list/stored_draft = json_decode(json_encode(constructor.draft))
	var/stored_html = constructor.render_body(FALSE)
	constructor.draft = constructor.normalize_draft(stored_draft)
	TEST_ASSERT_EQUAL(constructor.render_body(FALSE), stored_html, "A preset changed after a save and load round trip")

	GLOB.fax_custom_presets = list("test" = list("author" = "tester", "draft" = stored_draft, "custom_logo" = encoded_logo))
	constructor.custom_logo = null
	constructor.load_custom_preset("test")
	TEST_ASSERT_EQUAL(constructor.custom_logo, encoded_logo, "A saved preset lost its logo")
	TEST_ASSERT_EQUAL(constructor.render_body(FALSE), stored_html, "A saved preset did not load back")
	GLOB.fax_custom_presets["bad"] = list("draft" = "not a draft", "custom_logo" = "'><script>")
	constructor.custom_logo = null
	constructor.load_custom_preset("bad")
	TEST_ASSERT_NULL(constructor.custom_logo, "A malformed preset logo was accepted")
	GLOB.fax_custom_presets = null

	constructor.load_builtin_preset("nt_blank")
	var/list/sections = constructor.draft["sections"]
	var/start_count = length(sections)
	var/first_id = sections[1]["id"]
	TEST_ASSERT(constructor.handle_action("add_section", list("kind" = "fields", "after" = first_id)), "add_section failed")
	sections = constructor.draft["sections"]
	TEST_ASSERT_EQUAL(length(sections), start_count + 1, "add_section did not add a block")
	var/new_id = sections[2]["id"]
	TEST_ASSERT_EQUAL(length(sections[2]["rows"]), 1, "A new fields block has no field")
	TEST_ASSERT(constructor.handle_action("add_row", list("id" = new_id)), "add_row failed")
	TEST_ASSERT(constructor.handle_action("set_row", list("id" = new_id, "index" = 2, "key" = "label", "value" = "Второе:")), "set_row failed")
	TEST_ASSERT(constructor.handle_action("reorder_row", list("id" = new_id, "index" = 2, "target" = 1)), "reorder_row failed")
	var/list/edited_section = constructor.find_section(new_id)
	TEST_ASSERT_EQUAL(edited_section["rows"][1]["label"], "Второе:", "reorder_row did not move the field")
	TEST_ASSERT_NOT(constructor.handle_action("reorder_row", list("id" = new_id, "index" = 1, "target" = 9)), "reorder_row accepted a target out of range")
	TEST_ASSERT_NOT(constructor.handle_action("remove_row", list("id" = new_id, "index" = 9)), "remove_row accepted an index out of range")
	TEST_ASSERT(constructor.handle_action("remove_row", list("id" = new_id, "index" = 1)), "remove_row failed")
	edited_section = constructor.find_section(new_id)
	TEST_ASSERT_EQUAL(length(edited_section["rows"]), 1, "remove_row did not remove the field")
	TEST_ASSERT(constructor.handle_action("set_section", list("id" = new_id, "key" = "title", "value" = "Тест")), "set_section failed")
	TEST_ASSERT(constructor.handle_action("duplicate_section", list("id" = new_id)), "duplicate_section failed")
	sections = constructor.draft["sections"]
	TEST_ASSERT_EQUAL(length(sections), start_count + 2, "duplicate_section did not add a block")
	TEST_ASSERT(sections[3]["id"] != new_id, "A duplicated block reused its source id")
	TEST_ASSERT_EQUAL(sections[3]["title"], "Тест", "A duplicated block lost its content")
	TEST_ASSERT(constructor.handle_action("reorder_section", list("id" = new_id, "index" = length(sections))), "reorder_section failed")
	sections = constructor.draft["sections"]
	TEST_ASSERT_EQUAL(sections[length(sections)]["id"], new_id, "reorder_section did not move the block")
	TEST_ASSERT(constructor.handle_action("move_section", list("id" = new_id, "direction" = "up")), "move_section failed")
	sections = constructor.draft["sections"]
	TEST_ASSERT_EQUAL(sections[length(sections) - 1]["id"], new_id, "move_section did not move the block")
	TEST_ASSERT(constructor.handle_action("set_section", list("id" = new_id, "key" = "size", "value" = 22)), "set_section size failed")
	TEST_ASSERT(constructor.handle_action("style_all_sections", list("id" = new_id)), "style_all_sections failed")
	sections = constructor.draft["sections"]
	TEST_ASSERT_EQUAL(sections[1]["size"], 22, "style_all_sections did not copy the style")
	TEST_ASSERT(constructor.handle_action("remove_section", list("id" = new_id)), "remove_section failed")
	TEST_ASSERT_NULL(constructor.find_section(new_id), "remove_section did not remove the block")

	TEST_ASSERT(constructor.handle_action("toggle_stamp", list("stamp" = "cent")), "toggle_stamp failed")
	TEST_ASSERT("cent" in constructor.draft["stamps"], "toggle_stamp did not add the stamp")
	TEST_ASSERT(constructor.handle_action("toggle_stamp", list("stamp" = "cent")), "toggle_stamp failed")
	TEST_ASSERT_NOT("cent" in constructor.draft["stamps"], "toggle_stamp did not remove the stamp")
	TEST_ASSERT(constructor.handle_action("toggle_stamp", list("stamp" = "evil")), "toggle_stamp failed")
	TEST_ASSERT_NOT("evil" in constructor.draft["stamps"], "toggle_stamp accepted an unknown stamp")
	TEST_ASSERT(constructor.handle_action("set_destination", list("destination" = "not a department")), "set_destination failed")
	TEST_ASSERT_NULL(constructor.destination, "set_destination accepted an unknown department")

	constructor.undo_history.Cut()
	constructor.redo_history.Cut()
	constructor.last_edit_key = null
	var/title_before = constructor.draft["title"]
	TEST_ASSERT_NOT(constructor.handle_action("undo", list()), "undo worked with an empty history")
	constructor.handle_action("set_draft", list("key" = "title", "value" = "Пер"))
	constructor.handle_action("set_draft", list("key" = "title", "value" = "Первый"))
	TEST_ASSERT_EQUAL(length(constructor.undo_history), 1, "Typing into one field was not merged into one undo step")
	constructor.handle_action("set_draft", list("key" = "organization", "value" = "Другая"))
	TEST_ASSERT_EQUAL(length(constructor.undo_history), 2, "Editing another field did not start a new undo step")
	TEST_ASSERT(constructor.handle_action("undo", list()), "undo failed")
	TEST_ASSERT_EQUAL(constructor.draft["title"], "Первый", "undo reverted too much")
	TEST_ASSERT(constructor.handle_action("undo", list()), "undo failed")
	TEST_ASSERT_EQUAL(constructor.draft["title"], title_before, "undo did not restore the title")
	TEST_ASSERT(constructor.handle_action("redo", list()), "redo failed")
	TEST_ASSERT_EQUAL(constructor.draft["title"], "Первый", "redo did not restore the title")
	constructor.handle_action("set_draft", list("key" = "title", "value" = "Новая правка"))
	TEST_ASSERT_NOT(constructor.handle_action("redo", list()), "A new edit did not clear the redo history")
	for(var/step in 1 to 40)
		constructor.handle_action("toggle_stamp", list("stamp" = "ok"))
	TEST_ASSERT(length(constructor.undo_history) <= 30, "The undo history grew past its limit")

	TEST_ASSERT(constructor.handle_action("set_draft", list("key" = "sections", "value" = "junk")), "set_draft failed")
	TEST_ASSERT_EQUAL(length(constructor.draft["sections"]), 0, "Junk sections were not dropped")
	TEST_ASSERT(constructor.handle_action("undo", list()), "undo failed")
	TEST_ASSERT(length(constructor.draft["sections"]), "undo did not bring the sections back")
	TEST_ASSERT(constructor.handle_action("load_preset", list("id" = "cc_directive", "builtin" = TRUE)), "load_preset failed")
	TEST_ASSERT_EQUAL(constructor.draft["title"], "Директива Центрального командования", "load_preset did not load the preset")
	TEST_ASSERT(constructor.handle_action("new_draft", list()), "new_draft failed")
	TEST_ASSERT_SUBSTRING(constructor.ui_data(null)["preview_html"], "data-section='header'")
	TEST_ASSERT(length(constructor.ui_static_data(null)["builtin_presets"]), "No built-in presets reach the interface")

	var/mob/living/carbon/human/admin = allocate(/mob/living/carbon/human)
	admin.ckey = "faxtestadmin"
	constructor.handle_action("set_draft", list("key" = "title", "value" = "Черновик"))
	constructor.ui_close(admin)
	var/datum/fax_constructor/reopened = allocate(/datum/fax_constructor, admin)
	TEST_ASSERT_EQUAL(reopened.draft["title"], "Черновик", "The draft was not restored after closing the window")
	GLOB.fax_constructor_drafts -= "faxtestadmin"
	admin.ckey = null
