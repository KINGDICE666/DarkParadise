#define CYBERPSYCHOSIS_UNIT_CHANCE 0.005
#define CYBERPSYCHOSIS_STAGE_TIME (4 MINUTES)
#define CYBERPSYCHOSIS_DAMAGE_RESISTANCE 30
#define CYBERPSYCHOSIS_STAMINA_MOD -0.1

/proc/get_cyberpsychosis_chance(overflow)
	if(overflow <= 0)
		return 0
	return round(100 * (1 - (1 - CYBERPSYCHOSIS_UNIT_CHANCE) ** overflow), 0.1)

/mob/living/carbon/proc/get_cyber_load()
	. = 0
	for(var/obj/item/organ/internal/cyberimp/implant in internal_organs)
		if(implant.is_robotic())
			. += implant.cyber_cost

/mob/living/carbon/proc/adjust_cyber_capacity(amount)
	cyber_capacity = clamp(cyber_capacity + amount, 0, CYBER_CAPACITY_MAX)

/mob/living/carbon/proc/is_cyber_overloaded()
	return get_cyber_load() > cyber_capacity

/mob/living/carbon/proc/roll_cyberpsychosis()
	if(!prob(get_cyberpsychosis_chance(get_cyber_load() - cyber_capacity)))
		return FALSE
	var/datum/status_effect/cyberpsychosis/psychosis = has_status_effect(/datum/status_effect/cyberpsychosis)
	if(psychosis)
		psychosis.advance_stage()
	else
		apply_status_effect(/datum/status_effect/cyberpsychosis)
	return TRUE

/obj/item/organ/internal/cyberimp/insert(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(. && cyber_cost && is_robotic() && (special == ORGAN_MANIPULATION_DEFAULT || special == ORGAN_MANIPULATION_TRANSPLANTATE))
		target.roll_cyberpsychosis()

/datum/status_effect/cyberpsychosis
	id = "cyberpsychosis"
	alert_type = null
	tick_interval = 2 SECONDS
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS
	on_remove_on_mob_delete = TRUE
	var/stage = 1
	var/next_stage_time = 0
	var/datum/weakref/psycho_mind
	var/static/list/stage_names = list("Сбой синхронизации", "Диссоциация", "Распад личности", "Киберпсихоз")
	var/static/list/whispers = list(
		"Плоть — это просто временный корпус.",
		"Сердце стучит слишком медленно. Его можно заменить.",
		"Вы ловите себя на том, что считаете чужие слабые места.",
		"Где-то в голове трещит статика.",
		"Чьи это руки? Ах да. Ваши. Пока что.",
		"Люди вокруг такие... мягкие.",
	)
	var/static/list/screams = list(
		"ОНИ ВСЕ ИЗ МЯСА!",
		"ТИШИНА. НУЖНА ТИШИНА.",
		"СОТРИ ИХ. СОТРИ ИХ ВСЕХ.",
		"ХРОМ НЕ ЛЖЁТ. ЛЮДИ ЛГУТ.",
	)

/datum/status_effect/cyberpsychosis/on_apply()
	if(!iscarbon(owner))
		return FALSE
	next_stage_time = world.time + CYBERPSYCHOSIS_STAGE_TIME
	to_chat(owner, span_warning("Импланты на мгновение рассинхронизируются с нервной системой. Что-то не так."))
	owner.playsound_local(get_turf(owner), 'sound/hallucinations/far_noise.ogg', 50, FALSE)
	return TRUE

/datum/status_effect/cyberpsychosis/on_remove()
	if(stage >= CYBERPSYCHOSIS_STAGE_PSYCHO)
		release_psycho()
	to_chat(owner, span_notice("Статика в голове стихает. Вы снова чувствуете своё тело."))

/datum/status_effect/cyberpsychosis/get_examine_text()
	if(stage >= CYBERPSYCHOSIS_STAGE_PSYCHO)
		return span_danger("[DECLENT_RU_CAP(owner, NOMINATIVE)] смотрит сквозь вас пустым взглядом, импланты под кожей мелко дрожат.")

/datum/status_effect/cyberpsychosis/proc/get_stage_name()
	return stage_names[stage]

/datum/status_effect/cyberpsychosis/tick(seconds_between_ticks)
	var/mob/living/carbon/carbon_owner = owner
	var/overloaded = carbon_owner.is_cyber_overloaded()
	if(stage >= CYBERPSYCHOSIS_STAGE_PSYCHO)
		if(!overloaded)
			qdel(src)
			return
		if(prob(3))
			to_chat(owner, span_userdanger(pick(screams)))
		return

	if(world.time >= next_stage_time)
		next_stage_time = world.time + CYBERPSYCHOSIS_STAGE_TIME
		if(overloaded)
			advance_stage()
		else
			regress_stage()
		return

	apply_stage_effects()

/datum/status_effect/cyberpsychosis/proc/apply_stage_effects()
	switch(stage)
		if(1)
			if(prob(3))
				to_chat(owner, span_warning(pick(whispers)))
				owner.Jitter(4 SECONDS)
		if(2)
			if(prob(4))
				to_chat(owner, span_warning(pick(whispers)))
			if(prob(3))
				owner.Hallucinate(30 SECONDS)
			if(prob(2))
				owner.emote("twitch")
		if(3)
			if(prob(5))
				to_chat(owner, span_danger(pick(whispers + screams)))
			if(prob(5))
				owner.Hallucinate(60 SECONDS)
			if(prob(3))
				owner.AdjustConfused(4 SECONDS)
				owner.Jitter(8 SECONDS)
			if(prob(2))
				owner.emote(pick("scream", "laugh"))

/datum/status_effect/cyberpsychosis/proc/advance_stage()
	if(stage >= CYBERPSYCHOSIS_STAGE_PSYCHO)
		return
	stage++
	next_stage_time = world.time + CYBERPSYCHOSIS_STAGE_TIME
	if(stage >= CYBERPSYCHOSIS_STAGE_PSYCHO)
		become_psycho()
		return
	to_chat(owner, span_danger("Импланты гудят громче. [get_stage_name()]."))
	owner.playsound_local(get_turf(owner), pick('sound/hallucinations/behind_you1.ogg', 'sound/hallucinations/i_see_you1.ogg', 'sound/hallucinations/im_here1.ogg'), 50, FALSE)

/datum/status_effect/cyberpsychosis/proc/regress_stage()
	stage--
	if(stage <= 0)
		qdel(src)
		return
	to_chat(owner, span_notice("Нагрузка в норме. Голоса в голове становятся тише."))

/datum/status_effect/cyberpsychosis/proc/become_psycho()
	var/mob/living/carbon/carbon_owner = owner
	carbon_owner.add_traits(list(TRAIT_CYBERPSYCHO, TRAIT_NO_PAIN, TRAIT_NO_PAIN_HUD), CYBERPSYCHOSIS_TRAIT)
	if(ishuman(carbon_owner))
		var/mob/living/carbon/human/human_owner = carbon_owner
		human_owner.physiology.damage_resistance += CYBERPSYCHOSIS_DAMAGE_RESISTANCE
		human_owner.physiology.stamina_mod *= CYBERPSYCHOSIS_STAMINA_MOD
	if(carbon_owner.cyber_capacity > CYBER_CAPACITY_BASE)
		carbon_owner.cyber_capacity = CYBER_CAPACITY_BASE
		to_chat(carbon_owner, span_warning("Чипы киберсовместимости в порту нейроадаптера сгорают с треском."))
	carbon_owner.visible_message(
		span_danger("[DECLENT_RU_CAP(carbon_owner, NOMINATIVE)] резко замирает, импланты под кожей вспыхивают, а взгляд становится пустым."),
		span_userdanger("Всё затихает. Остаётся только хром и цели."),
	)
	playsound(carbon_owner, 'sound/hallucinations/wail.ogg', 60, TRUE)
	if(carbon_owner.mind)
		psycho_mind = WEAKREF(carbon_owner.mind)
		carbon_owner.mind.add_antag_datum(/datum/antagonist/cyberpsycho)
	add_attack_logs(carbon_owner, carbon_owner, "became a cyberpsycho with cyber load [carbon_owner.get_cyber_load()] of [carbon_owner.cyber_capacity]", ATKLOG_FEW)

/datum/status_effect/cyberpsychosis/proc/release_psycho()
	var/datum/mind/mind = psycho_mind?.resolve()
	mind?.remove_antag_datum(/datum/antagonist/cyberpsycho)
	psycho_mind = null
	if(QDELETED(owner))
		return
	owner.remove_traits(list(TRAIT_CYBERPSYCHO, TRAIT_NO_PAIN, TRAIT_NO_PAIN_HUD), CYBERPSYCHOSIS_TRAIT)
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.physiology.damage_resistance -= CYBERPSYCHOSIS_DAMAGE_RESISTANCE
		human_owner.physiology.stamina_mod /= CYBERPSYCHOSIS_STAMINA_MOD

/datum/antagonist/cyberpsycho
	name = "Cyberpsycho"
	roundend_category = "киберпсихи"
	special_role = "Киберпсих"
	antag_menu_name = "Киберпсих"

/datum/antagonist/cyberpsycho/give_objectives()
	add_objective(/datum/objective/cyberpsycho)

/datum/antagonist/cyberpsycho/greet()
	return list(
		span_userdanger("Вы — киберпсих!"),
		span_danger("Перегруженные импланты выжгли в вас всё человеческое. Боль больше не важна. Убивайте всё живое."),
		span_notice("Психоз пройдёт, только если с вас снимут импланты до предела киберсовместимости."),
	)

/datum/antagonist/cyberpsycho/farewell()
	if(owner?.current)
		to_chat(owner.current, span_userdanger("Вы больше не киберпсих. Жажда убивать отступает."))

/datum/objective/cyberpsycho
	explanation_text = "Убивайте всё живое."
	antag_menu_name = "Резня"
	needs_target = FALSE
	completed = TRUE

#undef CYBERPSYCHOSIS_UNIT_CHANCE
#undef CYBERPSYCHOSIS_STAGE_TIME
#undef CYBERPSYCHOSIS_DAMAGE_RESISTANCE
#undef CYBERPSYCHOSIS_STAMINA_MOD
