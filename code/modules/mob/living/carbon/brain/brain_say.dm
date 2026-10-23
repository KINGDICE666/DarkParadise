/mob/living/carbon/brain/say(
	message,
	bubble_type,
	list/spans = list(),
	sanitize = TRUE,
	datum/language/language,
	ignore_spam = FALSE,
	forced,
	filterproof = FALSE,
	message_range = 7,
	datum/saymode/saymode,
	list/message_mods = list(),
)
	if(stat == DEAD)
		return ..()
	if(!can_speak(warning = TRUE))
		return

	if(prob(emp_damage * 4))
		if(prob(10)) //10% chance to drop the message entirely
			return

		message = Gibberish(message, (emp_damage*6))//scrambles the message, gets worse when emp_damage is higher

	return ..()

/mob/living/carbon/brain/can_speak(warning = FALSE)
	. = ..()

	if(!is_mmi(container))
		. = FALSE
	else if(istype(container, /obj/item/mmi/robotic_brain))
		var/obj/item/mmi/robotic_brain/R = container
		if(R?.silenced)
			if(warning)
				to_chat(usr, span_warning("You cannot speak, as your internal speaker is turned off."))
			. = FALSE

/mob/living/carbon/brain/radio(message, list/message_mods = list(), list/spans, language)
	. = ..()
	if(!message_mods[MODE_HEADSET] || !is_mmi(container))
		return .
	var/obj/item/mmi/brain_container = container
	if(brain_container.mecha?.radio)
		if(brain_container.mecha.radio.talk_into(src, message, null, spans, language, message_mods))
			return NOPASS
	else if(brain_container.radio?.talk_into(src, message, null, spans, language, message_mods))
		return NOPASS
	return .
