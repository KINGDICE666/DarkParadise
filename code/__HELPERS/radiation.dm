/// Whether or not it's possible for this atom to be irradiated
#define CAN_IRRADIATE(atom) (ishuman(##atom) || isitem(##atom))

/// Посылает импульс радиации с тайла источника.
/// rads это доза, которую незащищённый человек получает на соседнем тайле. Она падает с квадратом расстояния
/// и умножается на rad_insulation всего, что на пути.
/// Источник внутри чего-либо экранируется тем, в чём лежит.
/proc/radiation_pulse(atom/source, rads)
	if(!SSradiation.can_fire || rads <= 0 || HAS_TRAIT(source, TRAIT_BLOCK_RADIATION))
		return FALSE

	var/turf/source_turf = get_turf(source)
	if(isnull(source_turf))
		return FALSE

	rads *= get_containment_insulation(source)
	if(rads < RAD_MINIMUM_DOSE)
		return FALSE

	SSradiation.processing[source_turf] += rads
	SSradiation.source_names[source_turf] = source.name
	return TRUE

/// Перемножает изоляцию всего, внутри чего лежит атом
/proc/get_containment_insulation(atom/thing)
	. = RAD_NO_INSULATION
	for(var/atom/container = thing.loc; container && !isturf(container); container = container.loc)
		. *= container.rad_insulation

/// Возвращает воспринимаемую "опасность" дозы от одного импульса.
/// Возвращает дефайн PERCEIVED_RADIATION_DANGER_*, см. [code/__DEFINES/radiation.dm]
/proc/get_perceived_radiation_danger(rads)
	if(rads >= RAD_DANGER_DOSE_EXTREME)
		return PERCEIVED_RADIATION_DANGER_EXTREME
	if(rads >= RAD_DANGER_DOSE_HIGH)
		return PERCEIVED_RADIATION_DANGER_HIGH
	if(rads >= RAD_DANGER_DOSE_MEDIUM)
		return PERCEIVED_RADIATION_DANGER_MEDIUM
	return PERCEIVED_RADIATION_DANGER_LOW

/// A common proc used to send COMSIG_ATOM_PROPAGATE_RAD_PULSE to adjacent atoms
/// Only used for uranium (false/tram)walls to spread their radiation pulses
/atom/proc/propagate_radiation_pulse()
	for(var/atom/atom in orange(1, src))
		SEND_SIGNAL(atom, COMSIG_ATOM_PROPAGATE_RAD_PULSE, src)

/// Добавляет к поглощённой дозе без учёта защиты от внешнего излучения. Для того, что уже попало внутрь.
/mob/living/proc/adjust_radiation_dose(amount)
	return

/mob/living/carbon/human/adjust_radiation_dose(amount)
	if(HAS_TRAIT(src, TRAIT_RADIMMUNE))
		return

	var/datum/component/radiation_sickness/sickness = GetComponent(/datum/component/radiation_sickness)
	if(isnull(sickness))
		if(amount <= 0)
			return
		sickness = AddComponent(/datum/component/radiation_sickness)

	sickness.adjust_dose(amount)

/// Покрывает кожу радиоактивной пылью, которая добавляет дозу, пока её не смоют.
/mob/living/proc/adjust_surface_contamination(amount)
	return

/mob/living/carbon/human/adjust_surface_contamination(amount)
	if(HAS_TRAIT(src, TRAIT_RADIMMUNE))
		return

	amount *= 1 - get_radiation_protection()
	if(amount < RAD_MINIMUM_DOSE)
		return

	var/datum/component/radiation_sickness/sickness = GetComponent(/datum/component/radiation_sickness) || AddComponent(/datum/component/radiation_sickness)
	sickness.adjust_surface(amount)

/// Возвращает поглощённую дозу
/mob/living/proc/get_radiation_dose()
	return 0

/mob/living/carbon/human/get_radiation_dose()
	var/datum/component/radiation_sickness/sickness = GetComponent(/datum/component/radiation_sickness)
	return sickness ? sickness.dose : 0

/// Возвращает долю внешнего излучения, которую останавливает одежда, с весами по закрытым частям тела.
/mob/living/carbon/human/proc/get_radiation_protection()
	var/static/list/limb_weights = list(
		BODY_ZONE_HEAD = 0.25,
		BODY_ZONE_CHEST = 0.25,
		BODY_ZONE_PRECISE_GROIN = 0.1,
	)

	var/list/protective_clothing
	for(var/obj/item/clothing/worn in list(head, wear_mask, wear_suit, w_uniform, gloves, shoes))
		if(HAS_TRAIT(worn, TRAIT_RADIATION_PROTECTED_CLOTHING))
			LAZYADD(protective_clothing, worn)

	if(!protective_clothing)
		return 0

	var/total_weight = 0
	var/protected_weight = 0
	for(var/obj/item/organ/external/limb as anything in bodyparts)
		var/limb_weight = limb_weights[limb.limb_zone] || 0.05
		total_weight += limb_weight

		var/limb_protection = 0
		for(var/obj/item/clothing/worn as anything in protective_clothing)
			if(worn.body_parts_covered & limb.limb_body_flag)
				limb_protection = max(limb_protection, worn.rad_protection)

		protected_weight += limb_weight * limb_protection

	return total_weight ? protected_weight / total_weight : 0
