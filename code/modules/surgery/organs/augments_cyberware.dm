#define SKELETON_HEALTH_BONUS 25

#define OPTICS_ZOOM_DISTANCE 7

#define BLOOD_PUMP_HEALTH_FRACTION 0.5
#define BLOOD_PUMP_SYNTHFLESH_AMOUNT 100

#define GORILLA_COMBO_STEP 0.95
#define GORILLA_COMBO_MIN_SPEED 0.4
#define GORILLA_COMBO_RESET_TIME (2 SECONDS)

#define MONOWIRE_SHOCK_TIME (1 SECONDS)

/obj/item/organ/internal/cyberimp/chest/reinforced_skeleton
	name = "reinforced skeleton implant"
	desc = "Углекомпозитный каркас, наращённый поверх собственных костей. Тело выдерживает больше травм, прежде чем сдаться."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "combat_coating"
	implant_overlay = null
	slot = INTERNAL_ORGAN_CHEST_SKELETON
	origin_tech = "materials=5;biotech=5;combat=3"

/obj/item/organ/internal/cyberimp/chest/reinforced_skeleton/get_ru_names()
	return alist(
		NOMINATIVE = "укреплённый скелет",
		GENITIVE = "укреплённого скелета",
		DATIVE = "укреплённому скелету",
		ACCUSATIVE = "укреплённый скелет",
		INSTRUMENTAL = "укреплённым скелетом",
		PREPOSITIONAL = "укреплённом скелете",
	)

/obj/item/organ/internal/cyberimp/chest/reinforced_skeleton/insert(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(!.)
		return
	target.maxHealth += SKELETON_HEALTH_BONUS
	target.updatehealth("reinforced skeleton inserted")

/obj/item/organ/internal/cyberimp/chest/reinforced_skeleton/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	target.maxHealth -= SKELETON_HEALTH_BONUS
	target.updatehealth("reinforced skeleton removed")
	return ..()

/obj/item/organ/internal/cyberimp/chest/blood_pump
	name = "blood pump implant"
	desc = "Аварийная кровяная помпа. Когда здоровье носителя падает до половины, она сращивает раны синт-плотью и впрыскивает уголь. Заряды восстанавливаются со временем."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "blood_pump_sec"
	implant_overlay = null
	slot = INTERNAL_ORGAN_HEART_DRIVE
	origin_tech = "materials=5;biotech=5;programming=4"
	var/max_charges = 2
	var/charges = 2
	var/recharge_time = 150 SECONDS
	var/use_delay = 15 SECONDS
	var/list/injected_reagents = list("charcoal" = 5)
	COOLDOWN_DECLARE(recharge_cooldown)
	COOLDOWN_DECLARE(use_cooldown)

/obj/item/organ/internal/cyberimp/chest/blood_pump/get_ru_names()
	return alist(
		NOMINATIVE = "кровяная помпа",
		GENITIVE = "кровяной помпы",
		DATIVE = "кровяной помпе",
		ACCUSATIVE = "кровяную помпу",
		INSTRUMENTAL = "кровяной помпой",
		PREPOSITIONAL = "кровяной помпе",
	)

/obj/item/organ/internal/cyberimp/chest/blood_pump/on_life()
	if(charges < max_charges && COOLDOWN_FINISHED(src, recharge_cooldown))
		charges++
		COOLDOWN_START(src, recharge_cooldown, recharge_time)
	if(!charges || !COOLDOWN_FINISHED(src, use_cooldown) || owner.suiciding)
		return
	if(owner.health > owner.maxHealth * BLOOD_PUMP_HEALTH_FRACTION)
		return
	pump()

/obj/item/organ/internal/cyberimp/chest/blood_pump/proc/pump()
	charges--
	COOLDOWN_START(src, recharge_cooldown, recharge_time)
	COOLDOWN_START(src, use_cooldown, use_delay)
	var/datum/reagent/synthflesh = GLOB.chemical_reagents_list["synthflesh"]
	synthflesh.reaction_mob(owner, REAGENT_TOUCH, BLOOD_PUMP_SYNTHFLESH_AMOUNT, FALSE)
	for(var/reagent_id in injected_reagents)
		owner.reagents.add_reagent(reagent_id, injected_reagents[reagent_id])
	playsound(owner, 'sound/effects/singlebeat.ogg', 50, TRUE)
	to_chat(owner, span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] гонит по венам аварийную смесь, и раны начинают затягиваться."))

/obj/item/organ/internal/cyberimp/chest/blood_pump/militech
	name = "Militech blood pump implant"
	desc = "Боевая версия кровяной помпы от Militech. Когда здоровье носителя падает до половины, сращивает раны синт-плотью и впрыскивает стимуляторы. Держит три заряда, но восстанавливает их дольше."
	icon_state = "blood_pump"
	origin_tech = "materials=6;biotech=6;programming=5;syndicate=3"
	max_charges = 3
	charges = 3
	recharge_time = 300 SECONDS
	use_delay = 30 SECONDS
	injected_reagents = list("stimulants" = 2)

/obj/item/organ/internal/cyberimp/chest/blood_pump/militech/get_ru_names()
	return alist(
		NOMINATIVE = "кровяная помпа Militech",
		GENITIVE = "кровяной помпы Militech",
		DATIVE = "кровяной помпе Militech",
		ACCUSATIVE = "кровяную помпу Militech",
		INSTRUMENTAL = "кровяной помпой Militech",
		PREPOSITIONAL = "кровяной помпе Militech",
	)

/obj/item/organ/internal/cyberimp/eyes/optics
	name = "Kiroshi optics"
	desc = "Высокоточная оптика Kiroshi. По команде выдвигает линзы и даёт приближение, как у снайперского прицела."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "kirosi_seer"
	implant_overlay = null
	slot = INTERNAL_ORGAN_EYE_OPTICS
	origin_tech = "materials=4;programming=4;biotech=4;combat=3"
	aug_message = "Мир на мгновение плывёт, пока линзы подстраивают фокус..."
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	var/zoomed = FALSE

/obj/item/organ/internal/cyberimp/eyes/optics/get_ru_names()
	return alist(
		NOMINATIVE = "оптика Kiroshi",
		GENITIVE = "оптики Kiroshi",
		DATIVE = "оптике Kiroshi",
		ACCUSATIVE = "оптику Kiroshi",
		INSTRUMENTAL = "оптикой Kiroshi",
		PREPOSITIONAL = "оптике Kiroshi",
	)

/obj/item/organ/internal/cyberimp/eyes/optics/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	set_zoom(FALSE)
	return ..()

/obj/item/organ/internal/cyberimp/eyes/optics/emp_act(severity)
	if(!owner || emp_proof || emp_shielded(severity))
		return
	set_zoom(FALSE)
	return ..()

/obj/item/organ/internal/cyberimp/eyes/optics/ui_action_click(mob/user, datum/action/action, leftclick)
	set_zoom(!zoomed)

/obj/item/organ/internal/cyberimp/eyes/optics/proc/set_zoom(new_state)
	if(zoomed == new_state)
		return
	zoomed = new_state
	if(zoomed)
		RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_dir_change))
		owner.client?.view_size.zoomOut(offset = OPTICS_ZOOM_DISTANCE, direction = owner.dir)
	else
		UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)
		owner.client?.view_size.zoomIn()

/obj/item/organ/internal/cyberimp/eyes/optics/proc/on_dir_change(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	owner.client?.view_size.zoomOut(offset = OPTICS_ZOOM_DISTANCE, direction = new_dir)

/obj/item/organ/internal/cyberimp/eyes/optics/militech
	name = "Militech optical suite"
	desc = "Боевая оптика Militech. Даёт приближение, как у снайперского прицела, и гасит ослепляющие вспышки."
	icon_state = "kirosi_basilisk"
	origin_tech = "materials=5;programming=5;biotech=4;combat=5;syndicate=2"
	flash_protect = FLASH_PROTECTION_FLASH

/obj/item/organ/internal/cyberimp/eyes/optics/militech/get_ru_names()
	return alist(
		NOMINATIVE = "оптика Militech",
		GENITIVE = "оптики Militech",
		DATIVE = "оптике Militech",
		ACCUSATIVE = "оптику Militech",
		INSTRUMENTAL = "оптикой Militech",
		PREPOSITIONAL = "оптике Militech",
	)

/obj/item/organ/internal/cyberimp/arm/gorilla
	name = "gorilla arms implant"
	desc = "Усиленные миомерные приводы в руке. Удары кулаком этой рукой бьют сильнее, пустой рукой можно разжать шлюз альт-кликом, а стабилизаторы полностью гасят отдачу оружия."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "implant_gorilla_arms_sec"
	origin_tech = "materials=5;biotech=4;combat=5"
	actions_types = null
	var/punch_bonus = 5
	var/door_force_time = 4 SECONDS

/obj/item/organ/internal/cyberimp/arm/gorilla/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/gorilla/get_ru_names()
	return alist(
		NOMINATIVE = "руки гориллы",
		GENITIVE = "рук гориллы",
		DATIVE = "рукам гориллы",
		ACCUSATIVE = "руки гориллы",
		INSTRUMENTAL = "руками гориллы",
		PREPOSITIONAL = "руках гориллы",
	)

/obj/item/organ/internal/cyberimp/arm/gorilla/insert(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(!.)
		return
	RegisterSignal(arm_owner, COMSIG_GET_MELEE_DAMAGE_DELTAS, PROC_REF(on_punch))
	RegisterSignal(arm_owner, COMSIG_MOB_ALTCLICKON, PROC_REF(on_alt_click))
	ADD_TRAIT(arm_owner, TRAIT_NO_RECOIL, UNIQUE_TRAIT_SOURCE(src))

/obj/item/organ/internal/cyberimp/arm/gorilla/remove(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	UnregisterSignal(arm_owner, list(COMSIG_GET_MELEE_DAMAGE_DELTAS, COMSIG_MOB_ALTCLICKON))
	REMOVE_TRAIT(arm_owner, TRAIT_NO_RECOIL, UNIQUE_TRAIT_SOURCE(src))
	return ..()

/obj/item/organ/internal/cyberimp/arm/gorilla/ui_action_click(mob/user, datum/action/action, leftclick)
	return

/obj/item/organ/internal/cyberimp/arm/gorilla/proc/is_active_arm()
	return owner.hand ? parent_organ_zone == BODY_ZONE_L_ARM : parent_organ_zone == BODY_ZONE_R_ARM

/obj/item/organ/internal/cyberimp/arm/gorilla/proc/on_punch(mob/living/user, list/deltas, obj/item/weapon)
	SIGNAL_HANDLER
	if(weapon || crit_fail || !is_active_arm())
		return
	deltas += punch_bonus
	punch_landed()

/obj/item/organ/internal/cyberimp/arm/gorilla/proc/punch_landed()
	return

/obj/item/organ/internal/cyberimp/arm/gorilla/proc/on_alt_click(mob/living/carbon/source, atom/target)
	SIGNAL_HANDLER
	if(!is_airlock(target) || crit_fail || !is_active_arm() || source.get_active_hand())
		return NONE
	if(source.incapacitated() || HAS_TRAIT(source, TRAIT_HANDS_BLOCKED) || !source.Adjacent(target))
		return NONE
	var/obj/machinery/door/airlock/airlock = target
	if(!airlock.density || airlock.operating)
		return NONE
	INVOKE_ASYNC(src, PROC_REF(force_airlock), airlock)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/organ/internal/cyberimp/arm/gorilla/proc/force_airlock(obj/machinery/door/airlock/airlock)
	if(airlock.welded)
		owner.balloon_alert(owner, "заварено!")
		return
	if(airlock.locked)
		owner.balloon_alert(owner, "болты опущены!")
		return
	if(!airlock.arePowerSystemsOn())
		airlock.open(TRUE)
		return
	if(airlock.isElectrified() && airlock.shock_user(owner, 100))
		return
	owner.visible_message(
		span_danger("[DECLENT_RU_CAP(owner, NOMINATIVE)] впива[PLUR_ET_YUT(owner)]ся пальцами в [airlock.declent_ru(ACCUSATIVE)] и тян[PLUR_ET_UT(owner)] створки в стороны!"),
		span_notice("Вы впиваетесь пальцами в [airlock.declent_ru(ACCUSATIVE)] и тянете створки в стороны..."),
	)
	playsound(airlock, 'sound/machines/airlock_alien_prying.ogg', 100, TRUE)
	if(do_after(owner, door_force_time, airlock, max_interact_count = 1, category = DA_CAT_TOOL) && !airlock.open(TRUE) && airlock.density)
		owner.balloon_alert(owner, "не поддаётся!")

/obj/item/organ/internal/cyberimp/arm/gorilla/militech
	name = "Militech gorilla arms implant"
	desc = "Агентская версия рук гориллы. Бьёт сильнее, быстрее разжимает шлюзы, а каждый удачный удар кулаком этой рукой ускоряет следующий."
	icon_state = "implant_gorilla_arms"
	origin_tech = "materials=6;biotech=5;combat=6;syndicate=3"
	punch_bonus = 8
	door_force_time = 3 SECONDS
	var/combo_speed = 1
	var/combo_timer

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/get_ru_names()
	return alist(
		NOMINATIVE = "руки гориллы Militech",
		GENITIVE = "рук гориллы Militech",
		DATIVE = "рукам гориллы Militech",
		ACCUSATIVE = "руки гориллы Militech",
		INSTRUMENTAL = "руками гориллы Militech",
		PREPOSITIONAL = "руках гориллы Militech",
	)

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/remove(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	deltimer(combo_timer)
	set_combo_speed(1)
	return ..()

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/punch_landed()
	set_combo_speed(max(GORILLA_COMBO_MIN_SPEED, combo_speed * GORILLA_COMBO_STEP))
	combo_timer = addtimer(CALLBACK(src, PROC_REF(set_combo_speed), 1), GORILLA_COMBO_RESET_TIME, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/set_combo_speed(new_speed)
	if(combo_speed == new_speed || !owner)
		return
	owner.next_move_modifier *= new_speed / combo_speed
	combo_speed = new_speed

/obj/item/organ/internal/cyberimp/arm/monowire
	name = "monowire implant"
	desc = "Мономолекулярная нить, спрятанная в предплечье. Достаёт цель через клетку, а со спины или по лежачему захватывает за шею."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "implant_mono_wire_sec"
	origin_tech = "materials=5;biotech=4;combat=5"
	contents = newlist(/obj/item/melee/monowire)

/obj/item/organ/internal/cyberimp/arm/monowire/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/monowire/get_ru_names()
	return alist(
		NOMINATIVE = "имплант моноструны",
		GENITIVE = "импланта моноструны",
		DATIVE = "импланту моноструны",
		ACCUSATIVE = "имплант моноструны",
		INSTRUMENTAL = "имплантом моноструны",
		PREPOSITIONAL = "импланте моноструны",
	)

/obj/item/organ/internal/cyberimp/arm/monowire/militech
	name = "Militech monowire implant"
	desc = "Агентская моноструна Militech. Бьёт сильнее и дальше, а по нити иногда проходит оглушающий разряд."
	icon_state = "implant_mono_wire"
	origin_tech = "materials=6;biotech=5;combat=6;syndicate=3"
	contents = newlist(/obj/item/melee/monowire/militech)

/obj/item/organ/internal/cyberimp/arm/monowire/militech/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/monowire/militech/get_ru_names()
	return alist(
		NOMINATIVE = "имплант моноструны Militech",
		GENITIVE = "импланта моноструны Militech",
		DATIVE = "импланту моноструны Militech",
		ACCUSATIVE = "имплант моноструны Militech",
		INSTRUMENTAL = "имплантом моноструны Militech",
		PREPOSITIONAL = "импланте моноструны Militech",
	)

/obj/item/melee/monowire
	name = "monowire"
	desc = "Почти невидимая мономолекулярная нить. Режет плоть с хирургической точностью и достаёт цель через клетку."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "implant_mono_wire_sec"
	item_state = "mono_wire"
	force = 13
	reach = 2
	sharp = TRUE
	w_class = WEIGHT_CLASS_BULKY
	attack_verb = list("полоснул", "рассёк")
	hitsound = 'sound/weapons/bladeslice.ogg'
	var/shock_chance = 0

/obj/item/melee/monowire/get_ru_names()
	return alist(
		NOMINATIVE = "моноструна",
		GENITIVE = "моноструны",
		DATIVE = "моноструне",
		ACCUSATIVE = "моноструну",
		INSTRUMENTAL = "моноструной",
		PREPOSITIONAL = "моноструне",
	)

/obj/item/melee/monowire/attack(mob/living/target, mob/living/user, list/modifiers, def_zone, skip_attack_anim = FALSE)
	if(user.a_intent == INTENT_GRAB && can_choke(target, user))
		choke(target, user)
		return ATTACK_CHAIN_PROCEED_SUCCESS
	. = ..()
	if(ATTACK_CHAIN_SUCCESS_CHECK(.) && prob(shock_chance))
		shock(target, user)

/obj/item/melee/monowire/proc/can_choke(mob/living/target, mob/living/user)
	if(!ishuman(target) || target == user || user.pulling == target || !user.Adjacent(target))
		return FALSE
	return IS_HORIZONTAL(target) || target.dir == user.dir

/obj/item/melee/monowire/proc/choke(mob/living/carbon/human/target, mob/living/user)
	if(!target.grabbedby(user, supress_message = TRUE))
		return
	target.grippedby(user, grab_state_override = GRAB_NECK)
	target.AdjustSilence(2 SECONDS)
	playsound(target, 'sound/weapons/cablecuff.ogg', 15, TRUE, -1)
	target.visible_message(
		span_danger("[DECLENT_RU_CAP(user, NOMINATIVE)] захлёстыва[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)] на шее [target.declent_ru(GENITIVE)]!"),
		span_userdanger("[DECLENT_RU_CAP(user, NOMINATIVE)] захлёстыва[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)] на вашей шее, и вы не можете вымолвить ни слова!"),
		span_italics("Слышна возня и скрип натянутой проволоки!"),
	)
	add_attack_logs(user, target, "neck grabbed with [src]")

/obj/item/melee/monowire/proc/shock(mob/living/target, mob/living/user)
	target.Weaken(MONOWIRE_SHOCK_TIME)
	target.Jitter(MONOWIRE_SHOCK_TIME * 2)
	do_sparks(3, FALSE, target)
	playsound(target, 'sound/weapons/egloves.ogg', 50, TRUE, -1)
	target.visible_message(
		span_danger("По [declent_ru(DATIVE)] в руке [user.declent_ru(GENITIVE)] проходит разряд и бьёт [target.declent_ru(ACCUSATIVE)] током!"),
		span_userdanger("По [declent_ru(DATIVE)] в руке [user.declent_ru(GENITIVE)] проходит разряд и бьёт вас током!"),
	)
	add_attack_logs(user, target, "shocked with [src]")

/obj/item/melee/monowire/militech
	name = "Militech monowire"
	icon_state = "implant_mono_wire"
	force = 18
	reach = 3
	shock_chance = 10

/obj/item/melee/monowire/militech/get_ru_names()
	return alist(
		NOMINATIVE = "моноструна Militech",
		GENITIVE = "моноструны Militech",
		DATIVE = "моноструне Militech",
		ACCUSATIVE = "моноструну Militech",
		INSTRUMENTAL = "моноструной Militech",
		PREPOSITIONAL = "моноструне Militech",
	)

#undef SKELETON_HEALTH_BONUS

#undef OPTICS_ZOOM_DISTANCE

#undef BLOOD_PUMP_HEALTH_FRACTION
#undef BLOOD_PUMP_SYNTHFLESH_AMOUNT

#undef GORILLA_COMBO_STEP
#undef GORILLA_COMBO_MIN_SPEED
#undef GORILLA_COMBO_RESET_TIME

#undef MONOWIRE_SHOCK_TIME
