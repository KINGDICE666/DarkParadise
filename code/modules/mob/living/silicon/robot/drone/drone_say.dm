/mob/living/silicon/robot/drone/whisper(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language, ignore_spam = FALSE, forced, filterproof)
	say(message, language = language) //drones do not get to whisper, only speak normally
	return TRUE

