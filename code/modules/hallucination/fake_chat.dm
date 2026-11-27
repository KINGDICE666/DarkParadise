/// Fake chat hallucination. Sends a fake message to the hallucinator's chat.
/datum/hallucination/chat
	random_hallucination_weight = 4
	hallucination_tier = HALLUCINATION_TIER_COMMON

	/// If TRUE, the message is forced to go over the shared radio. Set to New().
	var/force_radio
	/// If set, forces this message to be selected rather than the auto-generated one.
	var/specific_message

/datum/hallucination/chat/New(mob/living/hallucinator, force_radio = FALSE, specific_message)
	src.force_radio = force_radio
	src.specific_message = specific_message
	return ..()

/datum/hallucination/chat/start()
	if(hallucinator.incapacitated)
		return FALSE

	var/mob/living/carbon/human/speaker
	var/datum/language/understood_language

	if(!force_radio)
		var/list/valid_humans = list()
		var/list/valid_corpses = list()
		for(var/mob/living/carbon/nearby_human in view(hallucinator))
			if(nearby_human == hallucinator)
				continue
			if(nearby_human.stat == DEAD)
				valid_corpses += nearby_human
				continue
			valid_humans += nearby_human

		for(var/mob/living/carbon/nearby_human in shuffle(valid_humans))
			speaker = nearby_human
			break

		if(isnull(speaker) && length(valid_corpses))
			speaker = pick(valid_corpses)

	var/is_radio = force_radio || isnull(speaker)
	if(is_radio)
		for(var/mob/living/carbon/human/crew_member in shuffle(GLOB.human_list))
			if(crew_member == hallucinator || !crew_member.mind)
				continue
			speaker = crew_member
			break

	if(isnull(speaker))
		return

	understood_language = hallucinator.get_random_understood_language()
	var/chosen = specific_message
	if(!chosen)
		if(is_radio)
			chosen = pick(list(
				"Помогите!",
				"Ксеноморфы!",
				"Синга вышла!",
				"Они взвели нюку!",
				"Клоун стащил ядерку!",
				"П-пом-могите!",
				"Нашел труп [hallucinator.name] в туалете.",
				"[hallucinator.name] [pick("вампир", "генокрад", "культист")]!",
				"Вызывайте шаттл!",
				"ИИ взломан!",
				"[hallucinator.name] мы идём за тобой!",
			))
		else
			chosen = pick(list(
				"Я слежу за тобой.",
				"Ты ведь знаешь, что я вижу тебя сквозь стены?",
				"[hallucinator.name]!",
				"Уйди!",
				"Ну и нахуй ты это сделал?",
				"Ты слышал это?",
				"Ты че делаешь?",
				"Почему?",
				"Отдай!",
				"Хонк!",
				"ПОМОГИТЕ!!",
				"БЕГИТЕ!!",
				"УБЕЙТЕ МЕНЯ!",
				"А вот и наша цель...",
				"Через 5 минут в дормах.",
				"Я убью тебя!",
				"Пошёл нахуй!",
				"Что ты наделал?",
				"EI NATH!!",
				"O bidai nabora se'sma!",
			))

	chosen = capitalize(chosen)

	feedback_details += "Type: [is_radio ? "Radio" : "Talk"], Source: [speaker.real_name], Message: [chosen]"

	if(!is_radio)
		hallucinator.Hear(speaker, understood_language, chosen, null, null, null, list(), list(), INFINITY)
	else
		hallucinator.Hear(speaker, understood_language, chosen, PUB_FREQ, null, null, list(), list(), INFINITY)

	qdel(src)
	return TRUE
