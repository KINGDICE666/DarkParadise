/datum/disease/virus/beesease/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/fluspanish/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/kingstons_advanced/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/dna_retrovirus/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/tuberculosis/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/wizarditis/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/anxiety/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/grut_gut
	name = "Грутовый живот"
	agent = "Eruca Stomachum"
	desc = "Пропитанная магией болезнь, создающая в желудке ОПАСНО высокое давление желчи."
	stage_prob = 5
	spread_flags = AIRBORNE
	cures = list("stabilizing_agent")
	severity = DISEASE_SEVERITY_DANGEROUS
	virus_heal_resistant = TRUE

/datum/disease/virus/grut_gut/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/grut_gut/stage_act()
	if(!..())
		return FALSE

	switch(stage)
		if(1)
			if(prob(3))
				to_chat(affected_mob, span_danger("Вы чувствуете странное в животе."))
		if(2)
			if(prob(3))
				to_chat(affected_mob, span_danger("Вас пучит."))
			if(prob(2))
				to_chat(affected_mob, span_danger("Вы чувствуете неприятное давление в животе."))
		if(3)
			if(prob(3))
				to_chat(affected_mob, span_danger("Вы чувствуете неприятное давление в животе."))
			if(prob(2))
				affected_mob.emote("burp")
			if(prob(1))
				affected_mob.emote("groan")
		if(4)
			if(prob(1))
				affected_mob.fakevomit(no_text = TRUE)
				affected_mob.adjust_nutrition(-rand(3, 5))
			if(prob(2))
				affected_mob.emote("burp")
			if(prob(3))
				to_chat(affected_mob, span_danger("Вас ужасно пучит."))
			if(prob(2))
				to_chat(affected_mob, span_danger("В груди раздаётся глубокое бульканье."))
		if(5)
			if(prob(2))
				affected_mob.custom_emote(EMOTE_AUDIBLE, "громко рыга[PLUR_ET_YUT(affected_mob)]!")
			if(prob(1))
				affected_mob.emote("burp")
			if(prob(1))
				affected_mob.emote("groan")
			if(prob(3))
				to_chat(affected_mob, span_danger("Живот просто убивает вас!"))
			if(prob(3))
				to_chat(affected_mob, span_danger("Ваш живот яростно бурлит и клокочет!"))
			if(prob(2) && affected_mob.nutrition >= 100 && iscarbon(affected_mob))
				var/mob/living/carbon/carbon = affected_mob
				carbon.adjustBruteLoss(5)
				carbon.vomit(6, NONE, 0, 7, FALSE)
				carbon.visible_message(
					span_danger("[carbon] блю[PLUR_ET_YUT(carbon)] с такой силой, что [GEND_HIS_HER(carbon)] отбрасывает назад!"),
					span_userdanger("Вас извергает потоком магической желчи с такой силой, что вас отбрасывает!"),
					span_warning("Вы слышите, как кого-то обильно рвёт."),
				)
				do_fling()

/datum/disease/virus/grut_gut/proc/do_fling()
	var/fling_dir = REVERSE_DIR(affected_mob.dir)
	var/turf/general_direction = get_edge_target_turf(affected_mob, fling_dir)
	affected_mob.throw_at(general_direction, 200, 3)

/datum/disease/virus/wand_rot
	name = "Палочковая гниль"
	agent = "Nasum Magicum"
	desc = "Пропитанная магией болезнь, превращающая волоски в носу в крошечные волшебные палочки. Избегайте раздражителей носа."
	stage_prob = 5
	spread_flags = AIRBORNE
	cures = list("acetaldehyde")
	severity = DISEASE_SEVERITY_DANGEROUS
	virus_heal_resistant = TRUE

/datum/disease/virus/wand_rot/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/wand_rot/stage_act()
	if(!..())
		return FALSE

	switch(stage)
		if(1)
			if(prob(2))
				affected_mob.emote("sniff")
		if(2)
			if(prob(3))
				affected_mob.emote("sniff")
			if(prob(3))
				to_chat(affected_mob, span_danger("В носу и горле неприятно пересохло."))
		if(3)
			if(prob(2))
				affected_mob.emote("cough")
			if(prob(3))
				affected_mob.emote("sniff")
			if(prob(3))
				to_chat(affected_mob, span_danger("В носу и горле неприятно пересохло."))
		if(4)
			if(prob(2))
				affected_mob.emote("cough")
			if(prob(3))
				affected_mob.emote("sneeze")
			if(prob(3))
				to_chat(affected_mob, span_danger("Горло жжёт и чешется!"))
		if(5)
			if(prob(2))
				affected_mob.emote("cough")
			if(prob(2))
				to_chat(affected_mob, span_danger("Кажется, нос вот-вот сгорит прямо на лице!"))
				affected_mob.adjustFireLoss(5)
			if(prob(3))
				affected_mob.emote("sniff")
			if(prob(1))
				affected_mob.emote("sneeze")
				addtimer(CALLBACK(src, PROC_REF(sneeze_fireball)), 0.2 SECONDS)

/datum/disease/virus/wand_rot/proc/sneeze_fireball()
	if(QDELETED(affected_mob))
		return
	var/turf/target_tile = get_edge_target_turf(affected_mob, pick(GLOB.alldirs))
	var/obj/projectile/magic/fireball/fireball = new(affected_mob.loc)
	fireball.current = get_turf(affected_mob)
	fireball.original = target_tile
	fireball.firer = affected_mob
	fireball.preparePixelProjectile(target_tile, affected_mob)
	fireball.fire()
	playsound(affected_mob, 'sound/magic/fireball.ogg', 50, TRUE)

/datum/disease/virus/mystic_malaise
	name = "Мистическое недомогание"
	agent = "Spatio Ventrem"
	desc = "Пропитанная магией болезнь, поселяющаяся в кишечнике и превращающая желудочный сок в космическую материю."
	stage_prob = 5
	spread_flags = AIRBORNE
	cures = list("liquid_dark_matter")
	severity = DISEASE_SEVERITY_DANGEROUS
	virus_heal_resistant = TRUE

/datum/disease/virus/mystic_malaise/wizard_variant
	spread_flags = NON_CONTAGIOUS

/datum/disease/virus/mystic_malaise/stage_act()
	if(!..())
		return FALSE

	switch(stage)
		if(1)
			if(prob(2))
				to_chat(affected_mob, span_danger("Вас подташнивает."))
		if(2)
			if(prob(3))
				to_chat(affected_mob, span_danger("У вас болит живот."))
		if(3)
			if(prob(3))
				to_chat(affected_mob, span_danger("Вы чувствуете, как внутри растёт пустота."))
			if(prob(2))
				affected_mob.emote("cough")
		if(4)
			if(prob(3))
				to_chat(affected_mob, span_danger("Кажется, грудь вот-вот провалится внутрь!"))
			if(prob(2))
				affected_mob.emote("cough")
			if(prob(2))
				affected_mob.emote("groan")
		if(5)
			if(prob(2))
				affected_mob.AdjustConfused(5 SECONDS)
				var/turf/current_turf = get_turf(affected_mob)
				playsound(current_turf, 'sound/effects/splat.ogg', 50, TRUE)
				if(!isspaceturf(current_turf))
					new /obj/effect/decal/cleanable/vomit/spacematter(current_turf)

/obj/effect/decal/cleanable/vomit/spacematter
	name = "spacematter vomit"
	desc = "Несмотря на опасность, оно ослепительно красиво. Но лучше бы от этого держаться подальше."
	icon_state = "vomitnebula_1"
	random_icon_states = list("vomitnebula_1", "vomitnebula_2", "vomitnebula_3", "vomitnebula_4")
	var/time_to_live

/obj/effect/decal/cleanable/vomit/spacematter/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSprocessing, src)
	time_to_live = world.time + 15 SECONDS

/obj/effect/decal/cleanable/vomit/spacematter/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/effect/decal/cleanable/vomit/spacematter/process()
	var/datum/milla_safe/spacematter_vomit_process/milla = new()
	milla.invoke_async(src)
	if(world.time >= time_to_live)
		visible_message(span_danger("[src] испаряется в ничто!"))
		qdel(src)

/datum/milla_safe/spacematter_vomit_process

/datum/milla_safe/spacematter_vomit_process/on_run(obj/effect/decal/cleanable/vomit/spacematter/splatter)
	var/turf/tile = get_turf(splatter)
	if(!tile)
		return
	var/datum/gas_mixture/environment = get_turf_air(tile)
	var/removed_moles = environment.total_moles() * (1500 / environment.volume)
	environment.remove(removed_moles)
