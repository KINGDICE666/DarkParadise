/datum/unit_test/garble_html/Run()
	var/html = "<span class='warning'>Ничто не остановит &amp; тебя</span><br><a href='byond://?src=1'>ссылка</a>"
	TEST_ASSERT_EQUAL(garble_html(html, 0), html, "garble_html() changed the text at zero probability")

	var/garbled = garble_html(html, 100)
	for(var/markup in list("<span class='warning'>", "&amp;", "</span><br><a href='byond://?src=1'>", "</a>"))
		TEST_ASSERT_SUBSTRING(garbled, markup)

	var/static/regex/markup_regex = regex(@"<[^>]*>|&#?\w+;", "g")
	var/garbled_text = replacetext(garbled, markup_regex, "")
	TEST_ASSERT_EQUAL(length_char(garbled_text), length_char(replacetext(html, markup_regex, "")), "garble_html() changed the length of the visible text")
	TEST_ASSERT_EQUAL(length(splittext(garbled_text, " ")), length(splittext(replacetext(html, markup_regex, ""), " ")), "garble_html() replaced spaces")
	for(var/glyph in list("б", "l", "!", " "))
		garbled_text = replacetext(garbled_text, glyph, "")
	TEST_ASSERT_EQUAL(garbled_text, "", "garble_html() left visible text untouched at full probability")

	var/quoted_attribute = "<span title='a > b'>текст</span>"
	TEST_ASSERT_SUBSTRING(garble_html(quoted_attribute, 100), "<span title='a > b'>")

	var/broken_utf8 = "[copytext("Жук", 1, 2)]<b>Жук</b>"
	TEST_ASSERT_EQUAL(garble_html(broken_utf8, 0), broken_utf8, "garble_html() changed broken UTF-8 at zero probability")
	var/garbled_broken = garble_html(broken_utf8, 100)
	TEST_ASSERT_SUBSTRING(garbled_broken, "<b>")
	TEST_ASSERT_SUBSTRING(garbled_broken, "</b>")

	var/sentence = "Ничто не сможет тебя остановить сегодня ночью"
	TEST_ASSERT_EQUAL(scramble_words(sentence, 0), sentence, "scramble_words() changed the text at zero probability")
	TEST_ASSERT_NOTEQUAL(scramble_words(repeat_string(10, "[sentence] "), 100), repeat_string(10, "[sentence] "), "scramble_words() left the text untouched at full probability")

	var/word_garbled = garble_html(html, 0, 100)
	for(var/markup in list("<span class='warning'>", "&amp;", "</span><br><a href='byond://?src=1'>", "</a>"))
		TEST_ASSERT_SUBSTRING(word_garbled, markup)
	var/long_html = "<b>[repeat_string(10, "[sentence] ")]</b>"
	TEST_ASSERT_NOTEQUAL(garble_html(long_html, 0, 100), long_html, "garble_html() did not pass word distortion through")

	for(var/attempt in 1 to 50)
		TEST_ASSERT(length(scramble_words("слово", 100)), "scramble_words() erased a single word")
	TEST_ASSERT_EQUAL(jointext(text2charlist("Жук!"), "|"), "Ж|у|к|!", "text2charlist() split characters incorrectly")

/datum/unit_test/perception_distortion/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), 0, "a healthy human perceives distorted text")
	TEST_ASSERT_EQUAL(patient.distort_perceived_text("проверка"), "проверка", "a healthy human perceives distorted text")

	patient.Stun(5 SECONDS)
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), PERCEPTION_DISTORTION_STUN, "a stunned human got the wrong distortion")
	patient.SetStunned(0)

	patient.enter_stamcrit()
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), PERCEPTION_DISTORTION_STUN, "a human in stamina crit got the wrong distortion")
	patient.remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), STAMINA_TRAIT)
	patient.setStaminaLoss(0)

	patient.setBrainLoss(BRAIN_DAMAGE_MILD)
	patient.cure_all_traumas(TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), 0, "mild brain damage already distorts text")

	patient.setBrainLoss(BRAIN_DAMAGE_APHASIA - 1)
	patient.cure_all_traumas(TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT(patient.get_perception_distortion() <= PERCEPTION_DISTORTION_MILD_BRAIN_DAMAGE, "brain damage below the aphasia threshold distorts too much")
	TEST_ASSERT_EQUAL(patient.get_word_distortion(), 0, "brain damage below the aphasia threshold scrambles words")

	patient.setBrainLoss(BRAIN_DAMAGE_SEVERE)
	patient.cure_all_traumas(TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), PERCEPTION_DISTORTION_BRAIN_DAMAGE, "severe brain damage got the wrong distortion")
	TEST_ASSERT_EQUAL(patient.get_word_distortion(), WORD_DISTORTION_BRAIN_DAMAGE, "severe brain damage got the wrong word distortion")
	patient.setBrainLoss(0)

	patient.gain_trauma(/datum/brain_trauma/severe/pacifism, TRAUMA_RESILIENCE_LOBOTOMY)
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), 0, "a trauma that surgery cannot cure distorts text")
	patient.gain_trauma(/datum/brain_trauma/hypnosis, null, "проверка")
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), 0, "hypnosis distorts text")
	patient.gain_trauma(/datum/brain_trauma/mild/stuttering)
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), PERCEPTION_DISTORTION_BASIC_TRAUMA, "a trauma cured by medicine got the wrong distortion")
	patient.gain_trauma(/datum/brain_trauma/severe/mute)
	TEST_ASSERT_EQUAL(patient.get_perception_distortion(), PERCEPTION_DISTORTION_SURGERY_TRAUMA, "a trauma cured by surgery got the wrong distortion")
	patient.cure_all_traumas(TRAUMA_RESILIENCE_ABSOLUTE)

	var/obj/item/organ/internal/brain/brain = patient.get_organ_slot(INTERNAL_ORGAN_BRAIN)
	brain.transfer_identity(patient)
	TEST_ASSERT_EQUAL(brain.brainmob.get_perception_distortion(), 0, "a healthy removed brain perceives distorted text")
	brain.damage = BRAIN_DAMAGE_SEVERE
	TEST_ASSERT_EQUAL(brain.brainmob.get_perception_distortion(), PERCEPTION_DISTORTION_BRAIN_DAMAGE, "a damaged removed brain got the wrong distortion")
	TEST_ASSERT_EQUAL(brain.brainmob.get_word_distortion(), WORD_DISTORTION_BRAIN_DAMAGE, "a damaged removed brain got the wrong word distortion")
	brain.damage = 0

	patient.Stun(5 SECONDS)
	patient.death()
	TEST_ASSERT_EQUAL(patient.distort_perceived_text("проверка"), "проверка", "a dead mob perceives distorted text")

/datum/unit_test/perceived_chat_message/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.Stun(5 SECONDS)
	patient.setBrainLoss(BRAIN_DAMAGE_SEVERE)

	var/html = span_notice(repeat_string(30, "проверкасвязи"))
	var/list/message = list("html" = html)
	var/list/perceived = SSchat.get_perceived_message(patient, message, FALSE)
	TEST_ASSERT_NOTEQUAL(perceived["html"], html, "an in-character message was not distorted")
	TEST_ASSERT_EQUAL(message["html"], html, "distortion modified the shared message data")

	TEST_ASSERT(SSchat.get_perceived_message(patient, message, TRUE) == message, "a confidential message was distorted")
	TEST_ASSERT(SSchat.get_perceived_message(src, message, FALSE) == message, "a message to a non-mob target was distorted")
	for(var/exempt_type in list(MESSAGE_TYPE_OOC, MESSAGE_TYPE_SYSTEM, MESSAGE_TYPE_ADMINPM, MESSAGE_TYPE_DEADCHAT))
		var/list/typed_message = list("html" = html, "type" = exempt_type)
		TEST_ASSERT(SSchat.get_perceived_message(patient, typed_message, FALSE) == typed_message, "a [exempt_type] message was distorted")
