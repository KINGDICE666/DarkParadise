#define ADRENALINE_STUN_KEPT 0.5
#define ADRENALINE_SPEED_TIME (4 SECONDS)
#define ADRENALINE_CRASH_DELAY (60 SECONDS)
#define ADRENALINE_CRASH_WARNING (10 SECONDS)
#define ADRENALINE_CRASH_TIME (10 SECONDS)

#define PLATING_BRUTE_MOD 0.8
#define PLATING_EMP_LOCK_TIME (4 SECONDS)
#define PLATING_DEPLOY_COOLDOWN (30 SECONDS)

#define COGNITIVE_EMP_HALLUCINATION (30 SECONDS)
#define COGNITIVE_REBOOT_TIME (30 SECONDS)
#define COGNITIVE_DRUGGY_PURGE (5 SECONDS)

#define PAIN_LEVEL_NORMAL 0
#define PAIN_LEVEL_DULLED 25
#define PAIN_LEVEL_BLOCKED 60
#define PAIN_EMP_STAMINA 40

#define PALM_RANGE 5
#define PALM_COOLDOWN (2 SECONDS)
#define PALM_FLIGHT_TIME_PER_TILE (0.06 SECONDS)

#define PRINT_OPTION_RANDOM "Случайные отпечатки"
#define PRINT_OPTION_COPY "Скопировать у человека рядом"
#define PRINT_OPTION_RESTORE "Вернуть свои отпечатки"

#define SILENT_STEPS_TRAIT "silent_steps_implant"

/obj/item/organ/internal/cyberimp/proc/set_action_icon(new_state)
	for(var/datum/action/action as anything in actions)
		action.button_icon_state = new_state
		action.UpdateButtonIcon()

/datum/action/item_action/organ_action/augment
	button_icon = 'icons/hud/augment_actions.dmi'

/datum/movespeed_modifier/adrenaline_surge
	blacklisted_movetypes = (FLYING|FLOATING)
	conflicts_with = MOVE_CONFLICT_GOTTAGOFAST
	multiplicative_slowdown = -0.7

/datum/movespeed_modifier/subdermal_plating
	blacklisted_movetypes = (FLYING|FLOATING)
	multiplicative_slowdown = 0.45

/obj/item/organ/internal/cyberimp/chest/adrenaline
	name = "adrenaline surge implant"
	desc = "Железа экстренного выброса стимуляторов. Вдвое сокращает текущее оглушение и на четыре секунды ускоряет носителя, но через минуту организм расплачивается за рывок."
	implant_color = "#FF5A36"
	slot = INTERNAL_ORGAN_CHEST_ADRENALINE
	origin_tech = "materials=5;biotech=5;programming=4"
	actions_types = list(/datum/action/item_action/organ_action/augment/adrenaline)
	var/surge_pending = FALSE
	var/surge_timer

/datum/action/item_action/organ_action/augment/adrenaline
	name = "Адреналиновый рывок"
	button_icon_state = "adrenaline"

/obj/item/organ/internal/cyberimp/chest/adrenaline/get_ru_names()
	return alist(
		NOMINATIVE = "имплант адреналинового рывка",
		GENITIVE = "импланта адреналинового рывка",
		DATIVE = "импланту адреналинового рывка",
		ACCUSATIVE = "имплант адреналинового рывка",
		INSTRUMENTAL = "имплантом адреналинового рывка",
		PREPOSITIONAL = "импланте адреналинового рывка",
	)

/obj/item/organ/internal/cyberimp/chest/adrenaline/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	reset_surge()
	return ..()

/obj/item/organ/internal/cyberimp/chest/adrenaline/ui_action_click(mob/user, datum/action/action, leftclick)
	if(surge_pending)
		owner.balloon_alert(owner, "организм истощён!")
		return
	start_surge()

/obj/item/organ/internal/cyberimp/chest/adrenaline/emp_act(severity)
	if(!owner || emp_proof || emp_shielded(severity))
		return
	if(surge_pending)
		deltimer(surge_timer)
		crash()
		return
	start_surge()

/obj/item/organ/internal/cyberimp/chest/adrenaline/proc/start_surge()
	surge_pending = TRUE
	owner.SetStunned(owner.AmountStun() * ADRENALINE_STUN_KEPT, TRUE)
	owner.SetKnockdown(owner.AmountKnockdown() * ADRENALINE_STUN_KEPT, TRUE)
	owner.SetWeakened(owner.AmountWeakened() * ADRENALINE_STUN_KEPT, TRUE)
	owner.SetParalysis(owner.AmountParalyzed() * ADRENALINE_STUN_KEPT, TRUE)
	var/datum/status_effect/incapacitating/immobilized/immobilize = owner.IsImmobilized()
	if(immobilize)
		owner.SetImmobilized((immobilize.duration - world.time) * ADRENALINE_STUN_KEPT, TRUE)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/adrenaline_surge)
	playsound(owner, 'sound/effects/singlebeat.ogg', 50, TRUE)
	to_chat(owner, span_userdanger("Сердце бьёт как молот, и мышцы наливаются силой!"))
	set_action_icon("adrenaline_used")
	surge_timer = addtimer(CALLBACK(src, PROC_REF(end_surge)), ADRENALINE_SPEED_TIME, TIMER_STOPPABLE)

/obj/item/organ/internal/cyberimp/chest/adrenaline/proc/end_surge()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/adrenaline_surge)
	to_chat(owner, span_warning("Прилив сил спадает. Организм вот-вот потребует плату за рывок."))
	surge_timer = addtimer(CALLBACK(src, PROC_REF(warn_crash)), ADRENALINE_CRASH_DELAY - ADRENALINE_CRASH_WARNING, TIMER_STOPPABLE)

/obj/item/organ/internal/cyberimp/chest/adrenaline/proc/warn_crash()
	to_chat(owner, span_userdanger("В ушах нарастает звон, а ноги становятся ватными. Срочно найдите безопасное место!"))
	surge_timer = addtimer(CALLBACK(src, PROC_REF(crash)), ADRENALINE_CRASH_WARNING, TIMER_STOPPABLE)

/obj/item/organ/internal/cyberimp/chest/adrenaline/proc/crash()
	surge_pending = FALSE
	surge_timer = null
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/adrenaline_surge)
	set_action_icon("adrenaline")
	if(owner.stat == DEAD)
		return
	owner.Stun(ADRENALINE_CRASH_TIME, TRUE)
	owner.Confused(ADRENALINE_CRASH_TIME)
	owner.visible_message(
		span_danger("[DECLENT_RU_CAP(owner, NOMINATIVE)] вдруг обмяка[PLUR_ET_YUT(owner)] и едва держится на заплетающихся ногах!"),
		span_userdanger("Силы разом кончаются, а ноги заплетаются!"),
	)

/obj/item/organ/internal/cyberimp/chest/adrenaline/proc/reset_surge()
	if(surge_timer)
		deltimer(surge_timer)
		surge_timer = null
	surge_pending = FALSE
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/adrenaline_surge)
	set_action_icon("adrenaline")

/obj/item/organ/internal/cyberimp/chest/subdermal_plating
	name = "subdermal plating implant"
	desc = "Складные пластины под кожей. В боевом положении придают коже металлический отлив и гасят часть физического урона, но утяжеляют носителя и мешают повязкам и мазям. После складывания развернуть их снова можно только через тридцать секунд. При ЭМИ на несколько секунд сковывают движения."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "subdermal_plating"
	implant_overlay = null
	slot = INTERNAL_ORGAN_CHEST_PLATING
	origin_tech = "materials=5;biotech=4;combat=4"
	actions_types = list(/datum/action/item_action/organ_action/augment/subdermal_plating)
	var/plating_active = FALSE
	COOLDOWN_DECLARE(deploy_cooldown)

/datum/action/item_action/organ_action/augment/subdermal_plating
	name = "Переключить подкожную броню"
	button_icon_state = "plating"

/obj/item/organ/internal/cyberimp/chest/subdermal_plating/get_ru_names()
	return alist(
		NOMINATIVE = "подкожная броня",
		GENITIVE = "подкожной брони",
		DATIVE = "подкожной броне",
		ACCUSATIVE = "подкожную броню",
		INSTRUMENTAL = "подкожной бронёй",
		PREPOSITIONAL = "подкожной броне",
	)

/obj/item/organ/internal/cyberimp/chest/subdermal_plating/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	set_plating(FALSE)
	return ..()

/obj/item/organ/internal/cyberimp/chest/subdermal_plating/ui_action_click(mob/user, datum/action/action, leftclick)
	if(!ishuman(owner))
		return
	if(!plating_active && !COOLDOWN_FINISHED(src, deploy_cooldown))
		owner.balloon_alert(owner, "перезапуск через [ceil(COOLDOWN_TIMELEFT(src, deploy_cooldown) / (1 SECONDS))] сек")
		return
	set_plating(!plating_active)
	playsound(owner, 'sound/mecha/mechmove03.ogg', 30, TRUE)
	owner.balloon_alert(owner, plating_active ? "броня развёрнута" : "броня сложена")

/obj/item/organ/internal/cyberimp/chest/subdermal_plating/emp_act(severity)
	if(!owner || !plating_active || emp_proof || emp_shielded(severity))
		return
	owner.Immobilize(PLATING_EMP_LOCK_TIME, TRUE)
	to_chat(owner, span_userdanger("Пластины под кожей заклинивает, и вы не можете пошевелиться!"))

/obj/item/organ/internal/cyberimp/chest/subdermal_plating/proc/set_plating(new_state)
	if(plating_active == new_state)
		return
	var/mob/living/carbon/human/wearer = owner
	plating_active = new_state
	if(!wearer.physiology)
		return
	if(plating_active)
		wearer.physiology.brute_mod *= PLATING_BRUTE_MOD
		wearer.add_movespeed_modifier(/datum/movespeed_modifier/subdermal_plating)
		ADD_TRAIT(wearer, TRAIT_SUBDERMAL_PLATING, UNIQUE_TRAIT_SOURCE(src))
	else
		wearer.physiology.brute_mod /= PLATING_BRUTE_MOD
		wearer.remove_movespeed_modifier(/datum/movespeed_modifier/subdermal_plating)
		REMOVE_TRAIT(wearer, TRAIT_SUBDERMAL_PLATING, UNIQUE_TRAIT_SOURCE(src))
		COOLDOWN_START(src, deploy_cooldown, PLATING_DEPLOY_COOLDOWN)
	wearer.update_body()
	set_action_icon(plating_active ? "plating_active" : "plating")

/obj/item/organ/internal/cyberimp/leg/silent_steps
	name = "silent steps implant"
	desc = "Демпферы в стопах глушат шаги и не дают оставлять кровавые следы. Работают только парой, по одному на каждую ногу. Переключаются по желанию."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "silent_steps"
	implant_type = "silent_steps"
	origin_tech = "materials=3;biotech=4;programming=3"
	var/datum/action/silent_steps/toggle_action

/obj/item/organ/internal/cyberimp/leg/silent_steps/l
	parent_organ_zone = BODY_ZONE_L_LEG

/obj/item/organ/internal/cyberimp/leg/silent_steps/get_ru_names()
	return alist(
		NOMINATIVE = "глушитель шагов",
		GENITIVE = "глушителя шагов",
		DATIVE = "глушителю шагов",
		ACCUSATIVE = "глушитель шагов",
		INSTRUMENTAL = "глушителем шагов",
		PREPOSITIONAL = "глушителе шагов",
	)

/obj/item/organ/internal/cyberimp/leg/silent_steps/AddEffect()
	var/obj/item/organ/internal/cyberimp/leg/silent_steps/right_leg = owner.get_organ_slot(INTERNAL_ORGAN_R_LEG_DEVICE)
	if(right_leg.toggle_action)
		return
	right_leg.toggle_action = new(right_leg)
	right_leg.toggle_action.Grant(owner)

/obj/item/organ/internal/cyberimp/leg/silent_steps/RemoveEffect()
	var/obj/item/organ/internal/cyberimp/leg/silent_steps/right_leg = owner.get_organ_slot(INTERNAL_ORGAN_R_LEG_DEVICE)
	if(istype(right_leg) && right_leg.toggle_action)
		right_leg.toggle_action.set_silent(FALSE)
		right_leg.toggle_action.Remove(owner)
		QDEL_NULL(right_leg.toggle_action)

/obj/item/organ/internal/cyberimp/leg/silent_steps/emp_act(severity)
	if(!owner || emp_proof || emp_shielded(severity))
		return
	. = ..()
	toggle_action?.set_silent(FALSE)

/datum/action/silent_steps
	name = "Переключить глушитель шагов"
	button_icon = 'icons/hud/augment_actions.dmi'
	button_icon_state = "steps"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/silent_steps/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/new_state = !HAS_TRAIT_FROM(owner, TRAIT_SILENT_FOOTSTEPS, SILENT_STEPS_TRAIT)
	set_silent(new_state)
	owner.balloon_alert(owner, new_state ? "шаги заглушены" : "шаги слышны")

/datum/action/silent_steps/proc/set_silent(new_state)
	if(!owner)
		return
	if(new_state)
		owner.add_traits(list(TRAIT_SILENT_FOOTSTEPS, TRAIT_NO_FOOTPRINTS), SILENT_STEPS_TRAIT)
	else
		owner.remove_traits(list(TRAIT_SILENT_FOOTSTEPS, TRAIT_NO_FOOTPRINTS), SILENT_STEPS_TRAIT)
	button_icon_state = new_state ? "steps_active" : "steps"
	UpdateButtonIcon()

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer
	name = "cognitive stabilizer implant"
	desc = "Фильтрует ложные сигналы в коре мозга: подавляет галлюцинации, психоактивные вещества и лёгкие психические расстройства. При ЭМИ на время отключается и сам вызывает видения."
	implant_color = "#B48CFF"
	slot = INTERNAL_ORGAN_BRAIN_COGNITIVE
	origin_tech = "materials=4;biotech=5;programming=5"

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/get_ru_names()
	return alist(
		NOMINATIVE = "когнитивный стабилизатор",
		GENITIVE = "когнитивного стабилизатора",
		DATIVE = "когнитивному стабилизатору",
		ACCUSATIVE = "когнитивный стабилизатор",
		INSTRUMENTAL = "когнитивным стабилизатором",
		PREPOSITIONAL = "когнитивном стабилизаторе",
	)

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/insert(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(!.)
		return
	if(!crit_fail)
		enable_protection()

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	disable_protection()
	return ..()

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/on_life()
	..()
	if(!crit_fail)
		owner.AdjustDruggy(-COGNITIVE_DRUGGY_PURGE)

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/emp_act(severity)
	. = ..()
	if(!.)
		return
	crit_fail = TRUE
	disable_protection()
	owner.Hallucinate(COGNITIVE_EMP_HALLUCINATION)
	to_chat(owner, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] сбоит, и мир вокруг начинает плыть!"))
	addtimer(CALLBACK(src, PROC_REF(reboot)), COGNITIVE_REBOOT_TIME, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/proc/reboot()
	crit_fail = FALSE
	if(owner)
		enable_protection()

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/proc/enable_protection()
	owner.add_traits(list(TRAIT_COGNITIVE_STABILIZED, TRAIT_MADNESS_IMMUNE), UNIQUE_TRAIT_SOURCE(src))
	owner.SetHallucinate(0)

/obj/item/organ/internal/cyberimp/brain/cognitive_stabilizer/proc/disable_protection()
	owner.remove_traits(list(TRAIT_COGNITIVE_STABILIZED, TRAIT_MADNESS_IMMUNE), UNIQUE_TRAIT_SOURCE(src))

/obj/item/organ/internal/cyberimp/brain/pain_regulator
	name = "pain regulator implant"
	desc = "Перехватывает болевые сигналы и позволяет вручную задать чувствительность. На полной блокировке вы перестаёте понимать, насколько серьёзно ранены. ЭМИ сбрасывает настройку и вызывает болевой шок."
	implant_color = "#FF4FA3"
	slot = INTERNAL_ORGAN_BRAIN_PAIN
	origin_tech = "materials=5;biotech=6;programming=5"
	actions_types = list(/datum/action/item_action/organ_action/augment/pain_regulator)
	var/pain_level = PAIN_LEVEL_NORMAL

/datum/action/item_action/organ_action/augment/pain_regulator
	name = "Настроить чувствительность к боли"
	button_icon_state = "pain_normal"

/obj/item/organ/internal/cyberimp/brain/pain_regulator/get_ru_names()
	return alist(
		NOMINATIVE = "регулятор боли",
		GENITIVE = "регулятора боли",
		DATIVE = "регулятору боли",
		ACCUSATIVE = "регулятор боли",
		INSTRUMENTAL = "регулятором боли",
		PREPOSITIONAL = "регуляторе боли",
	)

/obj/item/organ/internal/cyberimp/brain/pain_regulator/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	set_pain_level(PAIN_LEVEL_NORMAL)
	return ..()

/obj/item/organ/internal/cyberimp/brain/pain_regulator/ui_action_click(mob/user, datum/action/action, leftclick)
	switch(pain_level)
		if(PAIN_LEVEL_NORMAL)
			set_pain_level(PAIN_LEVEL_DULLED)
			owner.balloon_alert(owner, "боль притуплена")
		if(PAIN_LEVEL_DULLED)
			set_pain_level(PAIN_LEVEL_BLOCKED)
			owner.balloon_alert(owner, "боль заблокирована")
		else
			set_pain_level(PAIN_LEVEL_NORMAL)
			owner.balloon_alert(owner, "обычная чувствительность")

/obj/item/organ/internal/cyberimp/brain/pain_regulator/emp_act(severity)
	. = ..()
	if(!.)
		return
	set_pain_level(PAIN_LEVEL_NORMAL)
	owner.adjustStaminaLoss(PAIN_EMP_STAMINA)
	to_chat(owner, span_userdanger("Вся заглушённая боль разом обрушивается на вас!"))

/obj/item/organ/internal/cyberimp/brain/pain_regulator/proc/set_pain_level(new_level)
	pain_level = new_level
	owner.implant_shock_reduction = pain_level
	if(pain_level == PAIN_LEVEL_BLOCKED)
		ADD_TRAIT(owner, TRAIT_NO_PAIN_HUD, UNIQUE_TRAIT_SOURCE(src))
	else
		REMOVE_TRAIT(owner, TRAIT_NO_PAIN_HUD, UNIQUE_TRAIT_SOURCE(src))
	switch(pain_level)
		if(PAIN_LEVEL_DULLED)
			set_action_icon("pain_dulled")
		if(PAIN_LEVEL_BLOCKED)
			set_action_icon("pain_blocked")
		else
			set_action_icon("pain_normal")
	owner.update_damage_hud()

/obj/item/organ/internal/cyberimp/fingerprint_synth
	name = "fingerprint synthesizer implant"
	desc = "Микропрофилировщик под кожей пальцев. Меняет папиллярный узор на случайный или снятый с другого человека. Перчатки всё так же скрывают отпечатки, а ЭМИ сбрасывает узор на настоящий."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "fingerprint_synth"
	parent_organ_zone = BODY_ZONE_R_ARM
	slot = INTERNAL_ORGAN_FINGERPRINT_SYNTH
	w_class = WEIGHT_CLASS_TINY
	origin_tech = "materials=4;biotech=5;programming=4;syndicate=2"
	actions_types = list(/datum/action/item_action/organ_action/augment/fingerprint_synth)

/datum/action/item_action/organ_action/augment/fingerprint_synth
	name = "Изменить отпечатки"
	button_icon_state = "fingerprint"

/obj/item/organ/internal/cyberimp/fingerprint_synth/get_ru_names()
	return alist(
		NOMINATIVE = "синтезатор отпечатков",
		GENITIVE = "синтезатора отпечатков",
		DATIVE = "синтезатору отпечатков",
		ACCUSATIVE = "синтезатор отпечатков",
		INSTRUMENTAL = "синтезатором отпечатков",
		PREPOSITIONAL = "синтезаторе отпечатков",
	)

/obj/item/organ/internal/cyberimp/fingerprint_synth/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	set_print(null)
	return ..()

/obj/item/organ/internal/cyberimp/fingerprint_synth/emp_act(severity)
	if(!owner || emp_proof || emp_shielded(severity))
		return
	set_print(null)
	to_chat(owner, span_warning("Кончики пальцев покалывает: узор возвращается к настоящему."))

/obj/item/organ/internal/cyberimp/fingerprint_synth/ui_action_click(mob/user, datum/action/action, leftclick)
	var/choice = tgui_input_list(owner, "Какой узор нанести?", DECLENT_RU_CAP(src, NOMINATIVE), list(PRINT_OPTION_RANDOM, PRINT_OPTION_COPY, PRINT_OPTION_RESTORE))
	if(!choice || !owner || owner.incapacitated())
		return
	switch(choice)
		if(PRINT_OPTION_RANDOM)
			set_print(md5("[world.time][rand(1, 1000000)][owner.real_name]"))
			owner.balloon_alert(owner, "узор изменён")
		if(PRINT_OPTION_COPY)
			copy_print()
		if(PRINT_OPTION_RESTORE)
			set_print(null)
			owner.balloon_alert(owner, "узор восстановлен")

/obj/item/organ/internal/cyberimp/fingerprint_synth/proc/copy_print()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/candidate in orange(1, owner))
		if(!HAS_TRAIT(candidate, TRAIT_NO_FINGERPRINTS) && candidate.get_full_print())
			candidates[candidate.name] = candidate
	if(!length(candidates))
		owner.balloon_alert(owner, "рядом никого нет!")
		return
	var/picked_name = tgui_input_list(owner, "С кого снять узор?", DECLENT_RU_CAP(src, NOMINATIVE), candidates)
	var/mob/living/carbon/human/donor = candidates[picked_name]
	if(!owner || !donor || owner.incapacitated() || !owner.Adjacent(donor))
		return
	set_print(donor.get_full_print())
	owner.balloon_alert(owner, "узор скопирован")

/obj/item/organ/internal/cyberimp/fingerprint_synth/proc/set_print(new_print)
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/wearer = owner
	wearer.implant_fingerprint = new_print

/obj/effect/temp_visual/magnet_pull
	randomdir = FALSE

/obj/effect/temp_visual/magnet_pull/Initialize(mapload, obj/item/pulled_item, atom/destination, flight_time)
	duration = flight_time
	. = ..()
	appearance = pulled_item.appearance
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	animate(src, pixel_x = (destination.x - x) * ICON_SIZE_X, pixel_y = (destination.y - y) * ICON_SIZE_Y, time = flight_time)

/obj/item/organ/internal/cyberimp/arm/magnetic_palm
	name = "magnetic palm implant"
	desc = "Электромагнит в ладони. Пока включён, притягивает с пяти метров лежащие инструменты, листы металла и пластали, стержни, плитку, кабель, наручники и гильзы прямо в пустую руку с имплантом."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "magnetic_palm"
	origin_tech = "materials=3;magnets=4;biotech=3"
	actions_types = list(/datum/action/item_action/organ_action/augment/magnetic_palm)
	var/palm_active = FALSE
	var/static/list/magnetic_types = list(
		/obj/item/ammo_casing,
		/obj/item/restraints/handcuffs,
		/obj/item/stack/cable_coil,
		/obj/item/stack/rods,
		/obj/item/stack/sheet/metal,
		/obj/item/stack/sheet/plasteel,
		/obj/item/stack/tile/plasteel,
	)
	var/obj/item/pulled_item
	COOLDOWN_DECLARE(pull_cooldown)

/datum/action/item_action/organ_action/augment/magnetic_palm
	name = "Переключить магнитную ладонь"
	button_icon_state = "magnet"

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/get_ru_names()
	return alist(
		NOMINATIVE = "магнитная ладонь",
		GENITIVE = "магнитной ладони",
		DATIVE = "магнитной ладони",
		ACCUSATIVE = "магнитную ладонь",
		INSTRUMENTAL = "магнитной ладонью",
		PREPOSITIONAL = "магнитной ладони",
	)

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/Destroy()
	drop_pulled_item()
	return ..()

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/remove(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	set_palm(FALSE)
	drop_pulled_item()
	return ..()

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/ui_action_click(mob/user, datum/action/action, leftclick)
	set_palm(!palm_active)
	owner.balloon_alert(owner, palm_active ? "магнит включён" : "магнит выключен")

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/emp_act(severity)
	if(!owner || emp_proof || emp_shielded(severity))
		return
	set_palm(FALSE)
	to_chat(owner, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] отключается от электромагнитного импульса!"))

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/set_palm(new_state)
	if(palm_active == new_state)
		return
	palm_active = new_state
	if(palm_active)
		RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(on_click))
	else
		UnregisterSignal(owner, COMSIG_MOB_CLICKON)
	set_action_icon(palm_active ? "magnet_active" : "magnet")

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/is_magnetic(obj/item/thing)
	if(thing.anchored || thing.w_class > WEIGHT_CLASS_NORMAL)
		return FALSE
	if(is_type_in_list(thing, magnetic_types))
		return TRUE
	return thing.tool_behaviour && (thing.flags & CONDUCT)

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/palm_is_ready()
	if(!COOLDOWN_FINISHED(src, pull_cooldown) || pulled_item)
		return FALSE
	if(owner.incapacitated() || HAS_TRAIT(owner, TRAIT_HANDS_BLOCKED))
		return FALSE
	var/active_hand_is_palm = owner.hand ? parent_organ_zone == BODY_ZONE_L_ARM : parent_organ_zone == BODY_ZONE_R_ARM
	return active_hand_is_palm && !owner.get_active_hand()

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/on_click(datum/source, atom/target, list/modifiers)
	SIGNAL_HANDLER
	if(LAZYACCESS(modifiers, SHIFT_CLICK) || LAZYACCESS(modifiers, CTRL_CLICK) || LAZYACCESS(modifiers, ALT_CLICK) || LAZYACCESS(modifiers, RIGHT_CLICK) || LAZYACCESS(modifiers, MIDDLE_CLICK))
		return NONE
	if(HAS_TRAIT(owner, TRAIT_FORENSIC_SCAN) || !isitem(target) || !isturf(target.loc) || !is_magnetic(target) || !palm_is_ready())
		return NONE
	var/distance = get_dist(owner, target)
	if(distance < 2 || distance > PALM_RANGE || !(target in view(PALM_RANGE, owner)) || !path_is_clear(target))
		return NONE
	start_pull(target)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/path_is_clear(obj/item/thing)
	var/turf/start = get_turf(owner)
	var/turf/end = get_turf(thing)
	for(var/turf/tile as anything in get_line(start, end) - start - end)
		if(tile.density)
			return FALSE
		for(var/obj/blocker in tile)
			if(blocker.density && !(blocker.pass_flags_self & PASSTABLE))
				return FALSE
	return TRUE

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/start_pull(obj/item/thing)
	COOLDOWN_START(src, pull_cooldown, PALM_COOLDOWN)
	var/flight_time = get_dist(owner, thing) * PALM_FLIGHT_TIME_PER_TILE
	new /obj/effect/temp_visual/magnet_pull(thing.loc, thing, owner, flight_time)
	playsound(owner, 'sound/effects/servostep.ogg', 50, TRUE)
	pulled_item = thing
	RegisterSignal(pulled_item, COMSIG_QDELETING, PROC_REF(on_pulled_deleted))
	pulled_item.forceMove(src)
	addtimer(CALLBACK(src, PROC_REF(finish_pull)), flight_time)

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/on_pulled_deleted(datum/source)
	SIGNAL_HANDLER
	pulled_item = null

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/finish_pull()
	if(!pulled_item)
		return
	var/obj/item/caught_item = pulled_item
	release_pulled_item()
	var/caught = parent_organ_zone == BODY_ZONE_R_ARM ? owner?.put_in_r_hand(caught_item, silent = TRUE) : owner?.put_in_l_hand(caught_item, silent = TRUE)
	if(!caught)
		drop_or_delete(caught_item)

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/release_pulled_item()
	UnregisterSignal(pulled_item, COMSIG_QDELETING)
	pulled_item = null

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/drop_pulled_item()
	if(!pulled_item)
		return
	var/obj/item/dropped_item = pulled_item
	release_pulled_item()
	drop_or_delete(dropped_item)

/obj/item/organ/internal/cyberimp/arm/magnetic_palm/proc/drop_or_delete(obj/item/thing)
	var/turf/landing = get_turf(owner || src)
	if(landing)
		thing.forceMove(landing)
	else
		qdel(thing)

#undef ADRENALINE_STUN_KEPT
#undef ADRENALINE_SPEED_TIME
#undef ADRENALINE_CRASH_DELAY
#undef ADRENALINE_CRASH_WARNING
#undef ADRENALINE_CRASH_TIME

#undef PLATING_BRUTE_MOD
#undef PLATING_EMP_LOCK_TIME
#undef PLATING_DEPLOY_COOLDOWN

#undef COGNITIVE_EMP_HALLUCINATION
#undef COGNITIVE_REBOOT_TIME
#undef COGNITIVE_DRUGGY_PURGE

#undef PAIN_LEVEL_NORMAL
#undef PAIN_LEVEL_DULLED
#undef PAIN_LEVEL_BLOCKED
#undef PAIN_EMP_STAMINA

#undef PALM_RANGE
#undef PALM_COOLDOWN
#undef PALM_FLIGHT_TIME_PER_TILE

#undef PRINT_OPTION_RANDOM
#undef PRINT_OPTION_COPY
#undef PRINT_OPTION_RESTORE

#undef SILENT_STEPS_TRAIT
