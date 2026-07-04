// ===================================================================
// RESOMI EMOTES
// Ported from SierraBay12 mods/resomi/code/body/emotes.dm
// Standard emote sounds (scream/cough/sneeze/laugh) are set on the
// species datum instead; these are the unique resomi vocalisations.
// ===================================================================

/datum/emote/living/carbon/human/resomi
	species_type_whitelist_typecache = list(/datum/species/resomi)

/datum/emote/living/carbon/human/resomi/chirp
	key = "chirp"
	key_third_person = "chirps"
	message = "чирика%(ет,ют)%."
	message_mime = "беззвучно приоткрыва%(ет,ют)% клюв."
	message_postfix = ", смотря на %t."
	message_param = EMOTE_PARAM_USE_POSTFIX
	emote_type = EMOTE_AUDIBLE|EMOTE_MOUTH
	muzzled_noises = list("приглушённые")
	sound = 'sound/voice/resomi/resomichirp.ogg'

/datum/emote/living/carbon/human/resomi/trill
	key = "trill"
	key_third_person = "trills"
	message = "изда%(ёт,ют)% трель!"
	message_mime = "искажа%(ет,ют)% клюв в странную форму."
	message_postfix = ", смотря на %t!"
	message_param = EMOTE_PARAM_USE_POSTFIX
	emote_type = EMOTE_AUDIBLE|EMOTE_MOUTH
	muzzled_noises = list("громкие")
	sound = 'sound/voice/resomi/resomitrill.ogg'

/datum/emote/living/carbon/human/resomi/warble
	key = "warble"
	key_third_person = "warbles"
	message = "изда%(ёт,ют)% переливчатую трель!"
	message_mime = "беззвучно раздува%(ет,ют)% горло."
	emote_type = EMOTE_AUDIBLE|EMOTE_MOUTH
	muzzled_noises = list("громкие")
	sound = 'sound/voice/resomi/warbles.ogg'

/datum/emote/living/carbon/human/resomi/wurble
	key = "wurble"
	key_third_person = "wurbles"
	message = "урч%(ит,ат)%."
	message_mime = "тихо перебира%(ет,ют)% перьями на горле."
	emote_type = EMOTE_AUDIBLE|EMOTE_MOUTH
	muzzled_noises = list("приглушённые")
	sound = 'sound/voice/resomi/wurble.ogg'
