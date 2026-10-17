/datum/unit_test/preference_keys_unique

/datum/unit_test/preference_keys_unique/Run()
	var/list/seen = list()
	for(var/datum/preference/preference_type as anything in valid_subtypesof(/datum/preference))
		var/key = preference_type::savefile_key
		TEST_ASSERT(key, "[preference_type] has no savefile_key")
		TEST_ASSERT(!(key in seen), "[preference_type] reuses savefile_key [key] of [seen[key]]")
		seen[key] = preference_type

/datum/unit_test/preference_constant_data

/datum/unit_test/preference_constant_data/Run()
	for(var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		preference.compile_constant_data()
	var/datum/asset/json/preferences/asset = get_asset_datum(/datum/asset/json/preferences)
	TEST_ASSERT(length(asset.generate()), "preferences.json is empty")

/datum/unit_test/preference_random_characters

/datum/unit_test/preference_random_characters/Run()
	var/datum/preference/choiced/species/species_preference = GLOB.preference_entries[/datum/preference/choiced/species]
	for(var/species_name in species_preference.get_choices())
		var/datum/preferences/preferences = new
		TEST_ASSERT(preferences.write_preference(species_preference, species_name), "couldn't select species [species_name]")
		preferences.randomise_appearance_prefs()
		for(var/datum/preference/preference as anything in get_preferences_in_priority_order())
			if(preference.savefile_identifier != PREFERENCE_CHARACTER)
				continue
			var/value = preferences.read_preference(preference.type)
			TEST_ASSERT(preference.is_valid(value, preferences), "[species_name]: [preference.type] holds invalid value [value]")

		var/mob/living/carbon/human/dummy/dummy = allocate(/mob/living/carbon/human/dummy)
		preferences.apply_prefs_to(dummy)
		if(species_name != SPECIES_GOLEM_RANDOM)
			TEST_ASSERT_EQUAL(dummy.dna.species.name, species_name, "apply_prefs_to didn't set the species")
		TEST_ASSERT_EQUAL(dummy.real_name, preferences.read_preference(/datum/preference/name/real_name), "apply_prefs_to didn't set the name")

/datum/unit_test/preference_column_roundtrip

/datum/unit_test/preference_column_roundtrip/Run()
	var/datum/preferences/preferences = new
	preferences.write_preference(GLOB.preference_entries[/datum/preference/numeric/hair_gradient_offset_x], 5)
	preferences.write_preference(GLOB.preference_entries[/datum/preference/numeric/hair_gradient_offset_y], -3)
	preferences.write_preference(GLOB.preference_entries[/datum/preference/color/marking/body], "#123456")
	var/list/columns = pack_character_columns(preferences.character_data)
	TEST_ASSERT_EQUAL(columns["hair_gradient_offset"], "5,-3", "gradient offsets weren't packed")
	TEST_ASSERT(findtext(columns["marking_colours"], "123456"), "marking colours weren't packed")
	var/list/unpacked = unpack_character_columns(columns)
	TEST_ASSERT_EQUAL(unpacked["hair_gradient_offset_x"], 5, "gradient offset x didn't survive the roundtrip")
	TEST_ASSERT_EQUAL(unpacked["hair_gradient_offset_y"], -3, "gradient offset y didn't survive the roundtrip")
	TEST_ASSERT_EQUAL(unpacked["body_marking_colour"], "#123456", "body marking colour didn't survive the roundtrip")
	for(var/key in unpacked)
		TEST_ASSERT(GLOB.preference_entries_by_key[key], "unpacked unknown key [key]")

/datum/unit_test/preference_preview_rebuilds_body

/datum/unit_test/preference_preview_rebuilds_body/Run()
	var/datum/preferences/preferences = new
	var/atom/movable/screen/map_view/char_preview/preview = allocate(/atom/movable/screen/map_view/char_preview, null, null, preferences)
	preferences.organ_data[BODY_ZONE_L_ARM] = PREF_ORGANSTATUS_AMPUTATED_ENG
	preview.update_body()
	TEST_ASSERT_NULL(preview.body.bodyparts_by_name[BODY_ZONE_L_ARM], "the preview kept an amputated arm")
	preferences.organ_data[BODY_ZONE_L_ARM] = null
	preview.update_body()
	TEST_ASSERT_NOTNULL(preview.body.bodyparts_by_name[BODY_ZONE_L_ARM], "the preview didn't regrow the arm after it was set back to organic")

/datum/unit_test/preference_job_levels

/datum/unit_test/preference_job_levels/Run()
	var/datum/preferences/preferences = new
	var/datum/job/engineer = SSjobs.GetJob(JOB_TITLE_ENGINEER)
	var/datum/job/doctor = SSjobs.GetJob(JOB_TITLE_DOCTOR)
	var/datum/job/civilian = SSjobs.GetJob(JOB_TITLE_CIVILIAN)
	var/datum/job/prisoner = SSjobs.GetJob(JOB_TITLE_PRISONER)

	TEST_ASSERT(preferences.set_job_preference_level(engineer, JP_HIGH), "couldn't set engineer to high")
	TEST_ASSERT(preferences.set_job_preference_level(doctor, JP_HIGH), "couldn't set doctor to high")
	TEST_ASSERT_EQUAL(preferences.get_job_preference_level(doctor), JP_HIGH, "doctor isn't high")
	TEST_ASSERT_EQUAL(preferences.get_job_preference_level(engineer), JP_MEDIUM, "engineer wasn't demoted to medium")
	TEST_ASSERT(preferences.GetJobDepartment(doctor, 1) & doctor.flag, "legacy high lookup lost the doctor")

	preferences.set_job_preference_level(engineer, null)
	TEST_ASSERT_NULL(preferences.get_job_preference_level(engineer), "engineer wasn't cleared")

	preferences.set_job_preference_level(civilian, JP_LOW)
	preferences.set_job_preference_level(prisoner, JP_LOW)
	TEST_ASSERT_NULL(preferences.get_job_preference_level(civilian), "exclusive jobs stacked")
	TEST_ASSERT_EQUAL(preferences.get_job_preference_level(prisoner), JP_LOW, "prisoner isn't selected")

/datum/unit_test/preference_skin_tone_presets

/datum/unit_test/preference_skin_tone_presets/Run()
	var/datum/preferences/preferences = new
	var/datum/preference/numeric/skin_tone/skin_tone = GLOB.preference_entries[/datum/preference/numeric/skin_tone]
	TEST_ASSERT_EQUAL(skin_tone.deserialize(-22, preferences), -30, "skin tone wasn't snapped to the nearest preset")
	TEST_ASSERT(!skin_tone.is_valid(-22, preferences), "a tone between presets was accepted")
	preferences.write_preference(GLOB.preference_entries[/datum/preference/choiced/species], SPECIES_VOX)
	TEST_ASSERT_EQUAL(skin_tone.deserialize(3, preferences), 3, "icon skin tone was snapped to a preset")

/datum/unit_test/preference_hair_gradient_previews

/datum/unit_test/preference_hair_gradient_previews/Run()
	var/datum/preferences/preferences = new
	preferences.write_preference(GLOB.preference_entries[/datum/preference/choiced/accessory/hair], "Very Long Hair")
	preferences.write_preference(GLOB.preference_entries[/datum/preference/color/hair_gradient_color], "#ff0000")
	var/atom/movable/screen/map_view/char_preview/preview = allocate(/atom/movable/screen/map_view/char_preview, null, null, preferences)
	preferences.character_preview_view = preview
	preview.update_body()
	var/datum/preference_middleware/hair_gradient/middleware = locate() in preferences.middleware
	middleware.preview_open = TRUE
	var/list/previews = middleware.get_ui_data()["hair_gradient_previews"]
	TEST_ASSERT_EQUAL(length(previews), length(SSaccessories.hair_gradients_list), "not every gradient got a preview")
	TEST_ASSERT_NOTEQUAL(previews["Fade Up"], previews["None"], "the gradient didn't change the preview")
