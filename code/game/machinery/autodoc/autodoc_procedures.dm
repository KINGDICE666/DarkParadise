GLOBAL_LIST_INIT(autodoc_procedures, init_autodoc_procedures())

/proc/init_autodoc_procedures()
	. = list()
	var/static/list/procedure_order = list(
		/datum/autodoc_procedure/arterial_bleeding,
		/datum/autodoc_procedure/internal_bleeding,
		/datum/autodoc_procedure/bleeding,
		/datum/autodoc_procedure/embedded,
		/datum/autodoc_procedure/fracture,
		/datum/autodoc_procedure/limb_necrosis,
		/datum/autodoc_procedure/organ_necrosis,
		/datum/autodoc_procedure/organ_damage,
		/datum/autodoc_procedure/infection,
		/datum/autodoc_procedure/regeneration,
		/datum/autodoc_procedure/organ_extract,
		/datum/autodoc_procedure/organ_install,
		/datum/autodoc_procedure/organ_install/implant,
		/datum/autodoc_procedure/lobotomy,
	)
	for(var/datum/autodoc_procedure/procedure_type as anything in procedure_order)
		.[procedure_type::id] = new procedure_type

/datum/autodoc_procedure
	var/id
	var/name
	var/base_duration = 30 SECONDS
	var/base_cost = 10
	/// Инвазивная процедура может сорваться
	var/invasive = TRUE
	/// Лечение органа: без улучшений срывается почти всегда
	var/delicate = FALSE
	/// Лечит понемногу каждый тик и платит по факту, а не целиком при старте
	var/continuous = FALSE
	/// Предлагается диагностикой и кнопкой "Лечить всё"
	var/auto_queue = TRUE
	/// Цель лежит в лотке автодока, а не в пациенте
	var/from_tray = FALSE
	/// Модуль, без которого процедура недоступна
	var/required_module
	var/begin_sound

/datum/autodoc_procedure/proc/is_needed(obj/item/organ/organ, obj/machinery/autodoc/machine)
	return !organ.is_robotic()

/datum/autodoc_procedure/proc/get_duration(obj/item/organ/organ)
	return base_duration

/datum/autodoc_procedure/proc/get_cost(obj/item/organ/organ)
	return base_cost

/datum/autodoc_procedure/proc/perform(obj/item/organ/organ, obj/machinery/autodoc/machine)
	return

/datum/autodoc_procedure/proc/on_failure(obj/item/organ/organ)
	return

/datum/autodoc_procedure/arterial_bleeding
	id = "arterial_bleeding"
	name = "Сшивание артерии"
	begin_sound = 'sound/surgery/hemostat1.ogg'
	base_duration = 20 SECONDS

/datum/autodoc_procedure/arterial_bleeding/is_needed(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	return ..() && isexternalorgan(limb) && limb.has_arterial_bleeding()

/datum/autodoc_procedure/arterial_bleeding/perform(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	limb.stop_arterial_bleeding()

/datum/autodoc_procedure/internal_bleeding
	id = "internal_bleeding"
	name = "Устранение внутреннего кровотечения"
	begin_sound = 'sound/surgery/hemostat2.ogg'
	base_cost = 15

/datum/autodoc_procedure/internal_bleeding/is_needed(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	return ..() && isexternalorgan(limb) && limb.has_internal_bleeding()

/datum/autodoc_procedure/internal_bleeding/perform(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	limb.stop_internal_bleeding()

/datum/autodoc_procedure/bleeding
	id = "bleeding"
	name = "Наложение швов"
	begin_sound = 'sound/surgery/retractor1.ogg'
	base_duration = 10 SECONDS
	base_cost = 5
	invasive = FALSE

/datum/autodoc_procedure/bleeding/is_needed(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	return ..() && isexternalorgan(limb) && limb.bleeding_amount > 0 && !limb.has_arterial_bleeding()

/datum/autodoc_procedure/bleeding/perform(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	limb.stop_bleeding()

/datum/autodoc_procedure/embedded
	id = "embedded"
	name = "Извлечение инородных тел"
	begin_sound = 'sound/surgery/scalpel1.ogg'
	base_duration = 15 SECONDS
	base_cost = 5

/datum/autodoc_procedure/embedded/is_needed(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	return ..() && isexternalorgan(limb) && LAZYLEN(limb.embedded_objects)

/datum/autodoc_procedure/embedded/perform(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	limb.remove_all_embedded_objects(machine.loc)

/datum/autodoc_procedure/fracture
	id = "fracture"
	name = "Сращивание перелома"
	begin_sound = 'sound/surgery/bonesetter.ogg'
	base_duration = 20 SECONDS

/datum/autodoc_procedure/fracture/is_needed(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	return ..() && isexternalorgan(limb) && limb.has_fracture()

/datum/autodoc_procedure/fracture/get_duration(obj/item/organ/external/limb)
	return base_duration * limb.fracture.power

/datum/autodoc_procedure/fracture/get_cost(obj/item/organ/external/limb)
	return base_cost * limb.fracture.power

/datum/autodoc_procedure/fracture/perform(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	limb.mend_fracture()

/datum/autodoc_procedure/limb_necrosis
	id = "limb_necrosis"
	name = "Удаление некроза"
	begin_sound = 'sound/surgery/scalpel2.ogg'
	base_duration = 60 SECONDS
	base_cost = 40

/datum/autodoc_procedure/limb_necrosis/is_needed(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	return ..() && isexternalorgan(limb) && limb.is_dead()

/datum/autodoc_procedure/limb_necrosis/perform(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	limb.germ_level = 0
	limb.unnecrotize()

/datum/autodoc_procedure/organ_necrosis
	id = "organ_necrosis"
	name = "Реанимация тканей органа"
	begin_sound = 'sound/surgery/organ1.ogg'
	base_duration = 60 SECONDS
	base_cost = 40
	delicate = TRUE
	required_module = AUTODOC_MODULE_ORGANS

/datum/autodoc_procedure/organ_necrosis/is_needed(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	return ..() && is_internal_organ(organ) && !is_internal_organ_brain(organ) && organ.is_dead()

/datum/autodoc_procedure/organ_necrosis/perform(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	organ.germ_level = 0
	organ.unnecrotize()
	organ.heal_internal_damage(organ.damage * 0.5)

/datum/autodoc_procedure/organ_damage
	id = "organ_damage"
	name = "Восстановление органа"
	begin_sound = 'sound/surgery/organ1.ogg'
	delicate = TRUE
	required_module = AUTODOC_MODULE_ORGANS

/datum/autodoc_procedure/organ_damage/is_needed(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	return ..() && is_internal_organ(organ) && !organ.is_dead() && organ.damage > 0

/datum/autodoc_procedure/organ_damage/get_cost(obj/item/organ/internal/organ)
	return base_cost + CEILING(organ.damage * 0.5, 1)

/datum/autodoc_procedure/organ_damage/perform(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	organ.heal_internal_damage(organ.damage)
	organ.surgeryize()
	if(is_internal_organ_brain(organ))
		var/obj/item/organ/internal/brain/brain = organ
		brain.cure_all_traumas(TRAUMA_RESILIENCE_SURGERY)

/datum/autodoc_procedure/infection
	id = "infection"
	name = "Санация"
	begin_sound = 'sound/surgery/scalpel1.ogg'
	base_duration = 20 SECONDS

/datum/autodoc_procedure/infection/is_needed(obj/item/organ/organ, obj/machinery/autodoc/machine)
	return ..() && organ.germ_level >= INFECTION_LEVEL_ONE

/datum/autodoc_procedure/infection/perform(obj/item/organ/organ, obj/machinery/autodoc/machine)
	organ.germ_level = 0

/datum/autodoc_procedure/regeneration
	id = "regeneration"
	name = "Регенерация тканей"
	invasive = FALSE
	continuous = TRUE

/datum/autodoc_procedure/regeneration/is_needed(obj/item/organ/external/limb, obj/machinery/autodoc/machine)
	return ..() && isexternalorgan(limb) && (limb.brute_dam + limb.burn_dam) > 0

/datum/autodoc_procedure/regeneration/get_duration(obj/item/organ/external/limb)
	return ((limb.brute_dam + limb.burn_dam) / AUTODOC_REGENERATION_RATE) SECONDS

/datum/autodoc_procedure/regeneration/get_cost(obj/item/organ/external/limb)
	return (limb.brute_dam + limb.burn_dam) / AUTODOC_DAMAGE_PER_UNIT

/// Возвращает, сколько урона реально зажило
/datum/autodoc_procedure/regeneration/proc/regenerate(obj/item/organ/external/limb, heal_budget)
	var/damage_before = limb.brute_dam + limb.burn_dam
	var/brute_healed = min(limb.brute_dam, heal_budget)
	var/burn_healed = min(limb.burn_dam, heal_budget - brute_healed)
	if(limb.heal_damage(brute_healed, burn_healed))
		limb.owner.UpdateDamageIcon()
	return damage_before - (limb.brute_dam + limb.burn_dam)

/datum/autodoc_procedure/organ_extract
	id = "organ_extract"
	name = "Извлечение органа"
	begin_sound = 'sound/surgery/saw1.ogg'
	base_duration = 20 SECONDS
	auto_queue = FALSE

/datum/autodoc_procedure/organ_extract/is_needed(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	return is_internal_organ(organ) && organ.owner == machine.occupant && !is_internal_organ_brain(organ) && !organ.unremovable

/datum/autodoc_procedure/organ_extract/perform(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	var/mob/living/carbon/human/patient = organ.owner
	var/obj/item/organ/internal/extracted = organ.remove(patient)
	if(!QDELETED(extracted))
		machine.store_organ(extracted)
	patient.update_icons()

/datum/autodoc_procedure/organ_install
	id = "organ_install"
	name = "Установка органа"
	begin_sound = 'sound/surgery/retractor2.ogg'
	base_cost = 15
	auto_queue = FALSE
	from_tray = TRUE
	/// Устанавливает кибернетические импланты, а не обычные органы
	var/installs_implants = FALSE

/datum/autodoc_procedure/organ_install/is_needed(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	var/mob/living/carbon/human/patient = machine.occupant
	if(!patient || !is_internal_organ(organ) || organ.owner || organ.loc != machine || is_internal_organ_brain(organ))
		return FALSE
	if(istype(organ, /obj/item/organ/internal/cyberimp) != installs_implants)
		return FALSE
	if(organ.damage > organ.max_damage * 0.75 || !organ.can_insert(null, patient, FALSE))
		return FALSE
	if(istype(organ, /obj/item/organ/internal/cyberimp) && HAS_TRAIT(patient, TRAIT_NO_CYBERIMPLANTS))
		return FALSE
	if(organ.status == ORGAN_ROBOT && HAS_TRAIT(patient, TRAIT_NO_ROBOPARTS))
		return FALSE
	var/obj/item/organ/internal/replaced = patient.get_organ_slot(organ.slot)
	if(replaced?.unremovable)
		return FALSE
	return !isnull(patient.get_organ(check_zone(organ.parent_organ_zone)))

/datum/autodoc_procedure/organ_install/perform(obj/item/organ/internal/organ, obj/machinery/autodoc/machine)
	var/mob/living/carbon/human/patient = machine.occupant
	var/obj/item/organ/internal/replaced = patient.get_organ_slot(organ.slot)
	machine.organ_tray -= organ
	var/obj/item/organ/internal/removed = replaced?.remove(patient, ORGAN_MANIPULATION_NOEFFECT)
	if(!QDELETED(removed))
		machine.store_organ(removed)
	organ.safe_replace(patient)
	patient.update_icons()

/datum/autodoc_procedure/organ_install/implant
	id = "implant_install"
	name = "Установка импланта"
	base_cost = 20
	required_module = AUTODOC_MODULE_IMPLANTS
	installs_implants = TRUE

/datum/autodoc_procedure/lobotomy
	id = "lobotomy"
	name = "Лоботомия"
	begin_sound = 'sound/surgery/scalpel1.ogg'
	base_duration = 60 SECONDS
	base_cost = 30
	delicate = TRUE
	auto_queue = FALSE
	required_module = AUTODOC_MODULE_LOBOTOMY

/datum/autodoc_procedure/lobotomy/is_needed(obj/item/organ/internal/brain/brain, obj/machinery/autodoc/machine)
	return is_internal_organ_brain(brain) && brain.owner == machine.occupant && !brain.is_robotic()

/datum/autodoc_procedure/lobotomy/perform(obj/item/organ/internal/brain/brain, obj/machinery/autodoc/machine)
	brain.cure_all_traumas(TRAUMA_RESILIENCE_LOBOTOMY)
	if(prob(75))
		brain.gain_lobotomy_side_effect()

/datum/autodoc_procedure/lobotomy/on_failure(obj/item/organ/internal/brain/brain)
	brain.owner?.apply_damage(80, BRAIN)
	brain.gain_lobotomy_side_effect()

/obj/item/disk/autodoc_module
	abstract_type = /obj/item/disk/autodoc_module
	icon_state = "datadisk2"
	origin_tech = "programming=6;biotech=6;engineering=6"
	var/module_id
	var/display_name
	var/description

/obj/item/disk/autodoc_module/organs
	name = "autodoc module disk (organ repair)"
	desc = "Диск с модулем автодока. Открывает восстановление органов и лечение мозга."
	module_id = AUTODOC_MODULE_ORGANS
	display_name = "Восстановление органов"
	description = "Лечение органов и мозга, реанимация омертвевших тканей."

/obj/item/disk/autodoc_module/organs/get_ru_names()
	return alist(
		NOMINATIVE = "диск автодока (восстановление органов)",
		GENITIVE = "диска автодока (восстановление органов)",
		DATIVE = "диску автодока (восстановление органов)",
		ACCUSATIVE = "диск автодока (восстановление органов)",
		INSTRUMENTAL = "диском автодока (восстановление органов)",
		PREPOSITIONAL = "диске автодока (восстановление органов)",
	)

/obj/item/disk/autodoc_module/lobotomy
	name = "autodoc module disk (lobotomy)"
	desc = "Диск с модулем автодока. Открывает лоботомию."
	module_id = AUTODOC_MODULE_LOBOTOMY
	display_name = "Лоботомия"
	description = "Снимает самые стойкие травмы мозга, но часто оставляет новые."

/obj/item/disk/autodoc_module/lobotomy/get_ru_names()
	return alist(
		NOMINATIVE = "диск автодока (лоботомия)",
		GENITIVE = "диска автодока (лоботомия)",
		DATIVE = "диску автодока (лоботомия)",
		ACCUSATIVE = "диск автодока (лоботомия)",
		INSTRUMENTAL = "диском автодока (лоботомия)",
		PREPOSITIONAL = "диске автодока (лоботомия)",
	)

/obj/item/disk/autodoc_module/implants
	name = "autodoc module disk (implants)"
	desc = "Диск с модулем автодока. Открывает установку кибернетических имплантов."
	module_id = AUTODOC_MODULE_IMPLANTS
	display_name = "Установка имплантов"
	description = "Установка кибернетических имплантов из лотка."

/obj/item/disk/autodoc_module/implants/get_ru_names()
	return alist(
		NOMINATIVE = "диск автодока (импланты)",
		GENITIVE = "диска автодока (импланты)",
		DATIVE = "диску автодока (импланты)",
		ACCUSATIVE = "диск автодока (импланты)",
		INSTRUMENTAL = "диском автодока (импланты)",
		PREPOSITIONAL = "диске автодока (импланты)",
	)

/obj/item/disk/autodoc_module/xenophysiology
	name = "autodoc module disk (xenophysiology)"
	desc = "Диск с модулем автодока. Учит манипуляторы работать с унатхи и плазменами."
	module_id = AUTODOC_MODULE_XENOPHYSIOLOGY
	display_name = "Нестандартная физиология"
	description = "Позволяет принимать и оперировать унатхи и плазменов."

/obj/item/disk/autodoc_module/xenophysiology/get_ru_names()
	return alist(
		NOMINATIVE = "диск автодока (нестандартная физиология)",
		GENITIVE = "диска автодока (нестандартная физиология)",
		DATIVE = "диску автодока (нестандартная физиология)",
		ACCUSATIVE = "диск автодока (нестандартная физиология)",
		INSTRUMENTAL = "диском автодока (нестандартная физиология)",
		PREPOSITIONAL = "диске автодока (нестандартная физиология)",
	)

/datum/autodoc_order
	var/datum/autodoc_procedure/procedure
	var/datum/weakref/organ_ref
	var/organ_name
	var/duration = 0
	var/cost = 0
	/// Шанс срыва фиксируется при оплате вместе с длительностью
	var/failure_chance = 0
	var/elapsed = 0
	var/paid = FALSE

/datum/autodoc_order/New(datum/autodoc_procedure/procedure, obj/item/organ/organ)
	src.procedure = procedure
	organ_ref = WEAKREF(organ)
	organ_name = organ.declent_ru(NOMINATIVE)

/datum/autodoc_order/Destroy(force)
	procedure = null
	organ_ref = null
	return ..()

/datum/autodoc_order/proc/get_organ(mob/living/carbon/human/patient)
	var/obj/item/organ/organ = organ_ref?.resolve()
	if(QDELETED(organ))
		return null
	if(!procedure.from_tray && organ.owner != patient)
		return null
	return organ

/datum/autodoc_order/proc/targets(datum/autodoc_procedure/other_procedure, obj/item/organ/organ)
	return procedure == other_procedure && organ_ref?.resolve() == organ
