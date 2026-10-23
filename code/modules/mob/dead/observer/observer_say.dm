/mob/dead/observer/say(
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
	message = sanitize(copytext_char(message, 1, MAX_MESSAGE_LEN))

	if(!message)
		return

	client?.check_say_flood(5)
	return say_dead(message)

/mob/dead/observer/compose_track_href(atom/movable/speaker, speaker_name, radio_freq, list/message_mods)
	var/atom/movable/virtualspeaker/virtual_speaker = speaker
	var/atom/follow_target = istype(virtual_speaker) ? (virtual_speaker.follow_target || virtual_speaker.source) : speaker
	return "([ghost_follow_link(follow_target, ghost = src)])"

/mob/dead/observer/compose_name(atom/movable/speaker, radio_freq, list/message_mods)
	var/speaker_name = ..()
	var/mob/speaker_mob = speaker.GetSource() || speaker
	if(!istype(speaker_mob) || isAI(speaker_mob))
		return speaker_name
	var/atom/movable/virtualspeaker/virtual_speaker = speaker
	var/shown_name = istype(virtual_speaker) ? (virtual_speaker.check_name || speaker_name) : speaker_name
	if(!speaker_mob.real_name || shown_name == speaker_mob.real_name)
		return speaker_name
	return "[speaker_mob.real_name] ([speaker_name])"
