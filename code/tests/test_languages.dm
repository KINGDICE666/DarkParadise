/obj/item/language_test_probe
	var/list/heard = list()

/obj/item/language_test_probe/Initialize(mapload)
	. = ..()
	become_hearing_sensitive(ROUNDSTART_TRAIT)

/obj/item/language_test_probe/Hear(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, list/spans, list/message_mods = list(), message_range)
	. = ..()
	heard += list(list(speaker, message_language, raw_message))

/datum/unit_test/language_species_swap/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.set_species(/datum/species/human)

	TEST_ASSERT(dummy.has_language(/datum/language/common, SPOKEN_LANGUAGE), "human does not speak common")
	TEST_ASSERT(dummy.has_language(/datum/language/human, SPOKEN_LANGUAGE), "human does not speak sol common")

	dummy.set_species(/datum/species/unathi)
	TEST_ASSERT(dummy.has_language(/datum/language/unathi, SPOKEN_LANGUAGE), "unathi does not speak sinta'unathi")
	TEST_ASSERT(!dummy.has_language(/datum/language/human, UNDERSTOOD_LANGUAGE), "species change kept the old species language")
	TEST_ASSERT_EQUAL(dummy.get_selected_language(), /datum/language/common, "unathi does not default to common")

	dummy.grant_language(/datum/language/piratespeak, source = LANGUAGE_MIND)
	dummy.set_species(/datum/species/human)
	TEST_ASSERT(dummy.has_language(/datum/language/piratespeak, SPOKEN_LANGUAGE), "species change removed a mind language")
	TEST_ASSERT(!dummy.has_language(/datum/language/unathi, UNDERSTOOD_LANGUAGE), "species change kept the old species language")

/datum/unit_test/language_mind_transfer/Run()
	var/mob/living/carbon/human/first_body = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second_body = allocate(/mob/living/carbon/human)
	first_body.mind_initialize()
	first_body.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)
	first_body.grant_language(/datum/language/clown, source = LANGUAGE_ATOM)

	first_body.mind.transfer_to(second_body)

	TEST_ASSERT(second_body.has_language(/datum/language/codespeak), "mind language did not follow the mind")
	TEST_ASSERT(!first_body.has_language(/datum/language/codespeak), "mind language stayed in the old body")
	TEST_ASSERT(first_body.has_language(/datum/language/clown), "atom language left the old body")
	TEST_ASSERT(!second_body.has_language(/datum/language/clown), "atom language followed the mind")

/datum/unit_test/language_lobby_transfer/Run()
	var/mob/new_player/lobby = allocate(/mob/new_player)
	var/mob/living/carbon/human/character = allocate(/mob/living/carbon/human)
	var/datum/mind/lobby_mind = new("language_test")
	lobby_mind.current = lobby
	lobby.mind = lobby_mind
	lobby.get_language_holder()
	character.grant_language(/datum/language/tajaran, source = LANGUAGE_MIND)

	lobby_mind.transfer_to(character)

	TEST_ASSERT(character.has_language(/datum/language/tajaran), "joining the round removed the preference language")
	TEST_ASSERT(!character.has_language(/datum/language/narsie), "joining the round granted the lobby languages")

/datum/unit_test/room_test/language_universal_transfer/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/shade/shade = allocate(/mob/living/simple_animal/shade)
	body.mind_initialize()

	body.mind.transfer_to(shade)

	TEST_ASSERT(shade.has_language(/datum/language/narsie), "universal mob lost its languages to the old body")
	TEST_ASSERT(!body.has_language(/datum/language/narsie), "old body received the universal languages")

/datum/unit_test/language_clone_record/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	subject.grant_language(/datum/language/codespeak, source = LANGUAGE_MIND)
	subject.grant_language(/datum/language/piratespeak, source = LANGUAGE_HAT)

	var/list/recorded = subject.get_language_holder().get_mind_languages()

	TEST_ASSERT(/datum/language/codespeak in recorded, "clone record lost a mind language")
	TEST_ASSERT(!(/datum/language/piratespeak in recorded), "clone record kept a temporary language")
	TEST_ASSERT(!(/datum/language/common in recorded), "clone record kept a species language")

/datum/unit_test/language_binary_listeners/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	allocate(/mob/camera)
	var/datum/saymode/binary/binary = SSradio.get_say_mode(/datum/saymode/binary)
	TEST_ASSERT(binary.handle_message(speaker, "Проверка") & SAYMODE_MESSAGE_HANDLED, "binary saymode did not handle the message")

/datum/unit_test/room_test/language_whisper_objects/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/obj/item/language_test_probe/near_probe = allocate(/obj/item/language_test_probe)
	var/obj/item/language_test_probe/far_probe = allocate(/obj/item/language_test_probe, locate(speaker.x + 3, speaker.y, speaker.z))

	speaker.whisper("Секрет")

	TEST_ASSERT_EQUAL(length(near_probe.heard), 1, "an adjacent object did not hear a whisper")
	TEST_ASSERT_EQUAL(length(far_probe.heard), 0, "a distant object heard a whisper")

/datum/unit_test/room_test/language_speech/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/obj/item/language_test_probe/probe = allocate(/obj/item/language_test_probe)
	speaker.set_species(/datum/species/unathi)

	probe.forceMove(speaker.loc)

	speaker.say("Привет")
	TEST_ASSERT_EQUAL(length(probe.heard), 1, "probe did not hear plain speech")
	var/list/heard = probe.heard[1]
	TEST_ASSERT_EQUAL(heard[2], /datum/language/common, "plain speech was not in the default language")
	TEST_ASSERT_EQUAL(heard[3], "Привет.", "plain speech text was changed")

	probe.heard.Cut()
	speaker.say(":o Шшш")
	TEST_ASSERT_EQUAL(length(probe.heard), 1, "probe did not hear keyed speech")
	heard = probe.heard[1]
	TEST_ASSERT_EQUAL(heard[2], /datum/language/unathi, "language key was not applied")
	TEST_ASSERT_EQUAL(heard[3], "Шшш.", "language key was not stripped")

	probe.heard.Cut()
	speaker.say(":j Мяу")
	heard = probe.heard[1]
	TEST_ASSERT_EQUAL(heard[2], /datum/language/common, "a language the speaker does not know was used")
	TEST_ASSERT_EQUAL(heard[3], "Мяу.", "an unknown language key was not stripped")

	probe.heard.Cut()
	ADD_TRAIT(speaker, TRAIT_CHANGELING_HIVEMIND, UID())
	speaker.say(":g Улей")
	TEST_ASSERT_EQUAL(length(probe.heard), 0, "hivemind speech was heard out loud")
	REMOVE_TRAIT(speaker, TRAIT_CHANGELING_HIVEMIND, UID())

/datum/unit_test/language_translation/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/listener = allocate(/mob/living/carbon/human)
	speaker.set_species(/datum/species/tajaran)
	listener.set_species(/datum/species/human)

	var/message = "Это тестовое сообщение."
	TEST_ASSERT_NOTEQUAL(listener.translate_language(speaker, /datum/language/tajaran, message), message, "unknown language was not scrambled")
	TEST_ASSERT_EQUAL(speaker.translate_language(speaker, /datum/language/tajaran, message), message, "known language was scrambled")

	var/datum/language/codespeak = GLOB.language_datum_instances[/datum/language/codespeak]
	TEST_ASSERT_NOTEQUAL(codespeak.scramble_paragraph(message), message, "codespeak was not scrambled")
	TEST_ASSERT(listener.has_partial_language(/datum/language/uncommon), "common does not give partial understanding of uncommon")

/datum/unit_test/language_definitions/Run()
	var/list/used_keys = list()
	for(var/datum/language/language as anything in GLOB.all_languages)
		var/key = language::key
		if(!key)
			continue
		TEST_ASSERT(!used_keys[key], "[language] reuses key [key] of [used_keys[key]]")
		used_keys[key] = language
		for(var/prefix in GLOB.say_prefixes)
			TEST_ASSERT(!GLOB.department_radio_keys["[prefix][key]"], "[language] key [key] collides with a radio key")
	for(var/key in SSradio.saymodes)
		TEST_ASSERT(!GLOB.language_keys[":[key]"], "saymode key [key] collides with a language key")

/datum/unit_test/room_test/language_aphasia/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/obj/item/language_test_probe/probe = allocate(/obj/item/language_test_probe)
	probe.forceMove(speaker.loc)

	speaker.gain_trauma(/datum/brain_trauma/severe/aphasia)
	TEST_ASSERT_EQUAL(speaker.get_selected_language(), /datum/language/aphasia, "severe aphasia did not switch speech to aphasia")
	TEST_ASSERT(!speaker.has_language(/datum/language/common, UNDERSTOOD_LANGUAGE), "severe aphasia did not block understanding common")
	speaker.say("Помогите")
	TEST_ASSERT_EQUAL(length(probe.heard), 1, "probe did not hear aphasic speech")
	var/list/heard = probe.heard[1]
	TEST_ASSERT_EQUAL(heard[2], /datum/language/aphasia, "aphasic speech was not in aphasia")

	speaker.cure_trauma_type(/datum/brain_trauma/severe/aphasia, TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT(!speaker.has_language(/datum/language/aphasia), "curing aphasia kept the aphasia language")
	TEST_ASSERT(speaker.has_language(/datum/language/common, UNDERSTOOD_LANGUAGE), "curing aphasia kept common blocked")
	TEST_ASSERT_EQUAL(speaker.get_selected_language(), /datum/language/common, "curing aphasia did not restore common speech")

	speaker.gain_trauma(/datum/brain_trauma/mild/hallucinations)
	TEST_ASSERT(speaker.has_language(/datum/language/aphasia, SPOKEN_LANGUAGE), "hallucinations did not grant aphasia")
	TEST_ASSERT_EQUAL(speaker.get_selected_language(), /datum/language/common, "hallucinations replaced the default language")
	speaker.cure_trauma_type(/datum/brain_trauma/mild/hallucinations, TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT(!speaker.has_language(/datum/language/aphasia), "curing hallucinations kept aphasia")

/datum/unit_test/language_temporary_sources/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)

	subject.Druggy(10 SECONDS)
	TEST_ASSERT(subject.has_language(/datum/language/beachbum, SPOKEN_LANGUAGE), "drugs did not grant beachbum")
	subject.SetDruggy(0)
	TEST_ASSERT(!subject.has_language(/datum/language/beachbum), "sobering up kept beachbum")

	var/obj/item/clothing/head/pirate/hat = allocate(/obj/item/clothing/head/pirate)
	subject.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD)
	TEST_ASSERT(subject.has_language(/datum/language/piratespeak, SPOKEN_LANGUAGE), "pirate hat did not grant piratespeak")
	qdel(hat)
	TEST_ASSERT(!subject.has_language(/datum/language/piratespeak), "destroyed pirate hat kept piratespeak")

	var/obj/item/mmi/robotic_brain/posibrain = allocate(/obj/item/mmi/robotic_brain)
	TEST_ASSERT(posibrain.brainmob.has_language(/datum/language/machine, SPOKEN_LANGUAGE), "positronic brain does not know machine")

/datum/unit_test/language_icons/Run()
	for(var/datum/language/language as anything in GLOB.all_languages)
		var/state = language::icon_state
		TEST_ASSERT(state, "[language] has no chat icon")
		TEST_ASSERT(icon_exists(language::icon, state), "[language] icon state [state] is missing")
