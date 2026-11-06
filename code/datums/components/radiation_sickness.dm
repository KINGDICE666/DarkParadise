// Естественное выведение в радах в секунду. После лёгкой стадии организм сам не справляется.
#define RADIATION_RECOVERY_NONE 0.5
#define RADIATION_RECOVERY_MILD 0.15

/// Поглощённая человеком радиация и вызванная ею болезнь.
/// Стадия сразу следует за дозой, а симптомы догоняют её только после скрытого периода.
/datum/component/radiation_sickness
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Поглощённая доза в радах
	var/dose = 0
	/// Радиоактивная пыль на коже и одежде, добавляет дозу, пока её не смоют
	var/surface_contamination = 0
	/// Стадия по дозе
	var/stage = RADIATION_STAGE_NONE
	/// Стадия по симптомам
	var/manifested_stage = RADIATION_STAGE_NONE
	var/glowing = FALSE
	COOLDOWN_DECLARE(latent_period)

/datum/component/radiation_sickness/Initialize()
	if(!ishuman(parent) || HAS_TRAIT(parent, TRAIT_RADIMMUNE))
		return COMPONENT_INCOMPATIBLE

	START_PROCESSING(SSobj, src)

/datum/component/radiation_sickness/RegisterWithParent()
	RegisterSignal(parent, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_clean))
	RegisterSignal(parent, COMSIG_GEIGER_COUNTER_SCAN, PROC_REF(on_geiger_counter_scan))
	RegisterSignal(parent, COMSIG_LIVING_HEALTHSCAN, PROC_REF(on_healthscan))

/datum/component/radiation_sickness/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_COMPONENT_CLEAN_ACT,
		COMSIG_GEIGER_COUNTER_SCAN,
		COMSIG_LIVING_HEALTHSCAN,
	))

/datum/component/radiation_sickness/Destroy(force)
	var/mob/living/carbon/human/human = parent
	human.remove_filter("rad_glow")
	human.clear_alert(ALERT_IRRADIATED)
	REMOVE_TRAIT(human, TRAIT_IRRADIATED, UNIQUE_TRAIT_SOURCE(src))
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/component/radiation_sickness/proc/adjust_dose(amount)
	dose = clamp(dose + amount, 0, RADIATION_DOSE_MAXIMUM)
	var/new_stage = RADIATION_STAGE_FOR_DOSE(dose)
	if(new_stage == stage)
		return

	var/old_stage = stage
	stage = new_stage
	if(stage >= RADIATION_STAGE_MILD)
		ADD_TRAIT(parent, TRAIT_IRRADIATED, UNIQUE_TRAIT_SOURCE(src))
	else
		REMOVE_TRAIT(parent, TRAIT_IRRADIATED, UNIQUE_TRAIT_SOURCE(src))

	if(stage > old_stage)
		var/mob/living/carbon/human/human = parent
		human.investigate_log("reached radiation sickness stage [stage] with [round(dose)] rads.", INVESTIGATE_RADIATION)
		if(manifested_stage == old_stage)
			COOLDOWN_START(src, latent_period, RADIATION_LATENT_PERIOD / (stage - manifested_stage))

/datum/component/radiation_sickness/proc/adjust_surface(amount)
	surface_contamination = clamp(surface_contamination + amount, 0, RAD_SURFACE_MAXIMUM)

/datum/component/radiation_sickness/process(seconds_per_tick)
	var/mob/living/carbon/human/human = parent
	if(HAS_TRAIT(human, TRAIT_RADIMMUNE))
		qdel(src)
		return

	if(human.stat == DEAD)
		return

	if(surface_contamination)
		adjust_dose(surface_contamination * RAD_SURFACE_DOSE_FACTOR * seconds_per_tick)
		surface_contamination = max(surface_contamination - surface_contamination * RAD_SURFACE_DECAY_FACTOR * seconds_per_tick - 0.01, 0)

	SEND_SIGNAL(human, COMSIG_IRRADIATED_PROCESS, seconds_per_tick, dose)
	if(QDELETED(src))
		return

	switch(stage)
		if(RADIATION_STAGE_NONE)
			adjust_dose(-RADIATION_RECOVERY_NONE * seconds_per_tick)
		if(RADIATION_STAGE_MILD)
			adjust_dose(-RADIATION_RECOVERY_MILD * seconds_per_tick)

	if(dose <= 0 && !surface_contamination)
		qdel(src)
		return

	if(HAS_TRAIT(human, TRAIT_STASIS) || HAS_TRAIT(human, TRAIT_HALT_RADIATION_EFFECTS))
		return

	update_manifested_stage()
	human.dna?.species?.handle_radiation(human, manifested_stage, seconds_per_tick)

/datum/component/radiation_sickness/proc/update_manifested_stage()
	if(manifested_stage > stage)
		set_manifested_stage(stage)
		return

	if(manifested_stage == stage || !COOLDOWN_FINISHED(src, latent_period))
		return

	set_manifested_stage(manifested_stage + 1)
	if(manifested_stage < stage)
		COOLDOWN_START(src, latent_period, RADIATION_LATENT_PERIOD / (stage - manifested_stage))

/datum/component/radiation_sickness/proc/set_manifested_stage(new_stage)
	var/mob/living/carbon/human/human = parent
	var/got_worse = new_stage > manifested_stage
	manifested_stage = new_stage

	var/static/list/stage_alerts = alist(
		RADIATION_STAGE_MILD = /atom/movable/screen/alert/irradiated,
		RADIATION_STAGE_MODERATE = /atom/movable/screen/alert/irradiated/moderate,
		RADIATION_STAGE_SEVERE = /atom/movable/screen/alert/irradiated/severe,
		RADIATION_STAGE_FATAL = /atom/movable/screen/alert/irradiated/fatal,
	)
	if(manifested_stage == RADIATION_STAGE_NONE)
		human.clear_alert(ALERT_IRRADIATED)
	else
		human.throw_alert(ALERT_IRRADIATED, stage_alerts[manifested_stage])

	var/should_glow = manifested_stage >= RADIATION_STAGE_SEVERE
	if(should_glow != glowing)
		glowing = should_glow
		if(glowing)
			create_radiation_glow(human)
		else
			human.remove_filter("rad_glow")

	if(!got_worse)
		return

	switch(manifested_stage)
		if(RADIATION_STAGE_MILD)
			to_chat(human, span_warning("Вас начинает подташнивать, а во рту появляется металлический привкус."))
		if(RADIATION_STAGE_MODERATE)
			to_chat(human, span_danger("Тело наливается слабостью, а кожа становится странно горячей."))
		if(RADIATION_STAGE_SEVERE)
			to_chat(human, span_userdanger("Кожа покрывается волдырями, вас бьёт озноб. С вами что-то очень не так!"))
		if(RADIATION_STAGE_FATAL)
			to_chat(human, span_userdanger("Внутри всё горит. Органы отказывают!"))

/datum/component/radiation_sickness/proc/on_clean(datum/source, clean_types)
	SIGNAL_HANDLER

	if(clean_types & CLEAN_TYPE_RADIATION)
		surface_contamination = 0

	return NONE

/datum/component/radiation_sickness/proc/get_stage_name()
	switch(stage)
		if(RADIATION_STAGE_NONE)
			return "без симптомов"
		if(RADIATION_STAGE_MILD)
			return "лёгкая"
		if(RADIATION_STAGE_MODERATE)
			return "средняя"
		if(RADIATION_STAGE_SEVERE)
			return "тяжёлая"
	return "смертельная"

/datum/component/radiation_sickness/proc/on_geiger_counter_scan(datum/source, mob/user, obj/item/geiger_counter/geiger_counter)
	SIGNAL_HANDLER

	to_chat(user, span_bolddanger("[icon2html(geiger_counter, user)] Поглощённая доза: [round(dose)] рад. Стадия лучевой болезни: [get_stage_name()]."))
	if(surface_contamination >= RAD_MINIMUM_DOSE)
		to_chat(user, span_warning("[icon2html(geiger_counter, user)] На коже и одежде радиоактивная пыль: нужен душ."))
	return COMSIG_GEIGER_COUNTER_SCAN_SUCCESSFUL

/datum/component/radiation_sickness/proc/on_healthscan(datum/source, list/scan_data, advanced, mob/user, mode, tochat)
	SIGNAL_HANDLER

	if(stage == RADIATION_STAGE_NONE && !surface_contamination)
		return

	if(stage > RADIATION_STAGE_NONE)
		scan_data += span_alert("Лучевая болезнь, стадия: [get_stage_name()]. Назначьте [/datum/reagent/medicine/potass_iodide::name] или [/datum/reagent/medicine/pen_acid::name].")
	if(advanced)
		scan_data += span_alert("Поглощённая доза: [round(dose)] рад.")
	if(surface_contamination >= RAD_MINIMUM_DOSE)
		scan_data += span_alert("На коже радиоактивная пыль. Пациенту нужен душ.")

/atom/movable/screen/alert/irradiated
	name = "Лучевая болезнь: лёгкая"
	desc = "Вы получили дозу радиации. Тошнота пройдёт, если держаться подальше от источника и смыть с себя пыль в душе."
	icon_state = "irradiated"

/atom/movable/screen/alert/irradiated/moderate
	name = "Лучевая болезнь: средняя"
	desc = "Организм сам уже не справится. Вам нужны йодид калия, пентетовая кислота или установка лучевой очистки."

/atom/movable/screen/alert/irradiated/severe
	name = "Лучевая болезнь: тяжёлая"
	desc = "Ожоги, кровотечения и мутации. Срочно в медбей!"

/atom/movable/screen/alert/irradiated/fatal
	name = "Лучевая болезнь: смертельная"
	desc = "Органы отказывают один за другим. Без интенсивного лечения вы умрёте."

#undef RADIATION_RECOVERY_NONE
#undef RADIATION_RECOVERY_MILD
