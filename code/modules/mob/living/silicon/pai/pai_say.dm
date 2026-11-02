/mob/living/silicon/pai/say(
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
	if(QDELETED(src) || stat == DEAD)
		return
	if(silence_time)
		to_chat(src, span_warning("Коммуникационные цепи всё ещё перегружены!"))
		return
	return ..()

/mob/living/silicon/pai/get_whisper_loc()
	if(loc == card)			// currently in its card?
		var/atom/movable/whisper_loc = card
		if(is_pda(card.loc)) // Step up 1 level if in a PDA
			whisper_loc = card.loc
		if(isliving(whisper_loc.loc))
			return whisper_loc.loc	// allow a pai being held or in pocket to whisper
		else
			return whisper_loc		// allow a pai in its card to whisper
	return ..()

