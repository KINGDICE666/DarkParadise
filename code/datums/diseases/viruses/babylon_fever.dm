/datum/disease/virus/babylonian_fever
	name = "Вавилонская лихорадка"
	agent = "Возбудитель вавилонской лихорадки"
	desc = "Если не лечить, заражённый окажется в состоянии дезориентации и забудет все известные ему языки."
	max_stages = 3
	spread_flags = AIRBORNE
	visibility_flags = HIDDEN_HUD
	cure_text = "Маннитол и Митоколид"
	cures = list("mannitol", "mitocholide")
	cure_prob = 30
	permeability_mod = 0.75
	severity = DISEASE_SEVERITY_MEDIUM

	var/list/blocked_languages

/datum/disease/virus/babylonian_fever/Contract(mob/living/M, act_type, is_carrier, need_protection_check, zone)
	var/datum/disease/virus/babylonian_fever/disease = ..()

	if(!disease)
		return FALSE

	disease.block_languages()

	ADD_TRAIT(disease.affected_mob, TRAIT_NO_BABEL, UNIQUE_TRAIT_SOURCE(disease))

/datum/disease/virus/babylonian_fever/stage_act()
	if(!..())
		return FALSE
	switch(stage)
		if(2, 3)
			if(prob(stage))
				affected_mob.adjustBrainLoss(0.5)
				affected_mob.say(pick(
					"Ммм... гхм...",
					"А-а-а... эээ...",
					"Брр... бл... бл...",
					"Гх... гх... гх...",
					"Ааа... ааа... ааа...",
					"Ух... ух... ух...",
					"Хм... хм... хм...",
					"Шш... шш... шш...",
					"Ыы... ыы... ыы...",
					"Оо... оо... оо...",
					"Уээ... Уэээ... УЭЭЭЭ...",
					"Ээ... ээ... ээ...",
					"Ии... ии... ии...",
					"Двести... двадцать..."\
					)
				)

	return TRUE

/datum/disease/virus/babylonian_fever/Destroy()
	if(affected_mob)
		if(LAZYLEN(blocked_languages))
			affected_mob.remove_blocked_language(blocked_languages, ALL, UID())
		REMOVE_TRAIT(affected_mob, TRAIT_NO_BABEL, UNIQUE_TRAIT_SOURCE(src))

	LAZYNULL(blocked_languages)

	return ..()

/datum/disease/virus/babylonian_fever/proc/block_languages()
	var/list/datum/language/secured_languages = list()
	var/obj/item/organ/internal/cyberimp/mouth/translator/translator = affected_mob.get_organ_slot(INTERNAL_ORGAN_SPEECH_TRANSLATOR)
	if(translator?.active)
		secured_languages |= translator.given_languages

	for(var/datum/language/language as anything in GLOB.all_languages)
		if(language::flags & LANGUAGE_NOBABEL)
			continue
		if(language in secured_languages)
			continue
		LAZYADD(blocked_languages, language)

	affected_mob.add_blocked_language(blocked_languages, ALL, UID())
