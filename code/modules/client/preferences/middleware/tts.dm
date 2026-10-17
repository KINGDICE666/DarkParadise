#define TTS_PREVIEW_COOLDOWN (0.5 SECONDS)

/datum/preference_middleware/tts
	action_delegations = list(
		"open_tts_explorer" = PROC_REF(open_tts_explorer),
		"play_voice" = PROC_REF(play_voice),
	)
	var/datum/ui_module/tts_seeds_explorer/tts_explorer
	COOLDOWN_DECLARE(tts_test_cooldown)

/datum/preference_middleware/tts/Destroy()
	QDEL_NULL(tts_explorer)
	return ..()

/datum/preference_middleware/tts/proc/open_tts_explorer(list/params, mob/user)
	if(!tts_explorer)
		tts_explorer = new
	tts_explorer.ui_interact(user)
	return FALSE

/datum/preference_middleware/tts/proc/play_voice(list/params, mob/user)
	var/seed_name = preferences.read_preference(/datum/preference/tts_seed)
	if(!seed_name || !COOLDOWN_FINISHED(src, tts_test_cooldown))
		return FALSE
	COOLDOWN_START(src, tts_test_cooldown, TTS_PREVIEW_COOLDOWN)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(tts_cast), null, user, "Так звучит мой голос.", seed_name, FALSE)
	return FALSE

#undef TTS_PREVIEW_COOLDOWN
