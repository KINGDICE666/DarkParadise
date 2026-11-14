#define SKELETON_HEALTH_BONUS 25

#define OPTICS_ZOOM_DISTANCE 7
#define OPTICS_FULLSCREEN "kiroshi_optics"
#define OPTICS_SCAN_INTERVAL (1 SECONDS)
#define OPTICS_SCAN_RANGE (OPTICS_ZOOM_DISTANCE * 2)
#define OPTICS_MIN_TARGET_ALPHA 128

#define BLOOD_PUMP_HEALTH_FRACTION 0.5
#define BLOOD_PUMP_SYNTHFLESH_AMOUNT 100

#define GORILLA_COMBO_STEP 0.95
#define GORILLA_COMBO_MIN_SPEED 0.4
#define GORILLA_COMBO_RESET_TIME (2 SECONDS)
#define GORILLA_KNOCKBACK_RANGE 4
#define GORILLA_KNOCKBACK_SPEED 2
#define GORILLA_WALL_SLAM_DAMAGE 15
#define GORILLA_WALL_SLAM_KNOCKDOWN (2 SECONDS)

#define MONOWIRE_SHOCK_TIME (1 SECONDS)

#define SANDEVISTAN_FILTER "sandevistan"
#define SANDEVISTAN_STAMINA_MOD 0.1
#define SANDEVISTAN_CLICK_MOD 0.4
#define SANDEVISTAN_FULLSCREEN "sandevistan"
#define SANDEVISTAN_FLASH "sandevistan_flash"
#define SANDEVISTAN_EMP_GLITCH_CHANCE 50
#define SANDEVISTAN_HEAT_STRAIN 70
#define SANDEVISTAN_HEAT_CRITICAL 100
#define SANDEVISTAN_HEAT_LETHAL 120
#define SANDEVISTAN_HEAT_MAX 150
#define SANDEVISTAN_COOLING_TICK (1 SECONDS)
#define SANDEVISTAN_DASH_RANGE 2
#define SANDEVISTAN_MELEE_DODGE_CHANCE 50
#define SANDEVISTAN_ECHO_DELAY (0.2 SECONDS)
#define SANDEVISTAN_FINISHER_WINDOW (5 SECONDS)
#define SANDEVISTAN_FINISHER_KNOCKDOWN (3 SECONDS)
#define SANDEVISTAN_STRAIN_DAMAGE 20
#define SANDEVISTAN_STRAIN_BLOOD_LOSS 150
#define SANDEVISTAN_CRITICAL_TOX_DAMAGE 60
#define SANDEVISTAN_CRITICAL_BRAIN_DAMAGE 40
#define SANDEVISTAN_CRITICAL_BLEEDING_LIMBS 4
#define SANDEVISTAN_CRITICAL_BLOOD_LOSS 200
#define SANDEVISTAN_CRITICAL_CYANIDE 15
#define SANDEVISTAN_LETHAL_BRAIN_DAMAGE 70
#define SANDEVISTAN_LETHAL_TOX_DAMAGE 100
#define SANDEVISTAN_LETHAL_BLOOD_LOSS 300
#define SANDEVISTAN_LETHAL_OXY_DAMAGE 50

#define BERSERKER_FILTER "berserker"
#define BERSERKER_OUTLINE_COLOR "#FF2222"
#define BERSERKER_ATTACK_SPEED 0.5
#define BERSERKER_EMP_BRAIN_FRACTION 0.25

#define BALLISTIC_PROCESSOR_RICOCHET_CHANCE 70
#define BALLISTIC_PROCESSOR_RICOCHETS 2
#define BALLISTIC_PROCESSOR_AIM_RANGE 7
#define BALLISTIC_PROCESSOR_AIM_ANGLE 180

#define HAND_CANNON_VOLLEY_DELAY (0.5 SECONDS)

#define ANOMALOCK_FILTER "voltaic_overdrive"
#define ANOMALOCK_OUTLINE_COLOR "#639BFF"
#define ANOMALOCK_OVERDRIVE_TIME (30 SECONDS)
#define ANOMALOCK_OVERDRIVE_HEAL 5
#define ANOMALOCK_EMP_LIGHTNING_TIME (10 SECONDS)
#define ANOMALOCK_SURVIVAL_COOLDOWN (5 MINUTES)
#define ANOMALOCK_BLOOD_REGEN 10
#define ANOMALOCK_BATTERY_INTERVAL (20 SECONDS)
#define ANOMALOCK_BATTERY_FRACTION 0.1
#define ANOMALOCK_ZAP_RANGE 20
#define ANOMALOCK_ZAP_POWER 2.5e5
#define ANOMALOCK_ZAP_CUTOFF 1e3
#define ANOMALOCK_SELF_IMPLANT_TIME (5 SECONDS)
#define ANOMALOCK_SELF_IMPLANT_DAMAGE 100
#define ANOMALOCK_CORE_REMOVAL_TIME (3 SECONDS)
#define ANOMALOCK_MIN_CORE_TIER 2

/obj/item/organ/internal/cyberimp/chest/reinforced_skeleton
	name = "reinforced skeleton implant"
	desc = "Углекомпозитный каркас, наращённый поверх собственных костей. Тело выдерживает больше травм, прежде чем сдаться."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "combat_coating"
	implant_overlay = null
	slot = INTERNAL_ORGAN_CHEST_SKELETON
	cyber_cost = 25
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
	RegisterSignal(target, COMSIG_HUMAN_SPECIES_CHANGED, PROC_REF(on_species_changed))

/obj/item/organ/internal/cyberimp/chest/reinforced_skeleton/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	UnregisterSignal(target, COMSIG_HUMAN_SPECIES_CHANGED)
	target.maxHealth -= SKELETON_HEALTH_BONUS
	target.updatehealth("reinforced skeleton removed")
	return ..()

/obj/item/organ/internal/cyberimp/chest/reinforced_skeleton/proc/on_species_changed(mob/living/carbon/human/source, datum/species/old_species)
	SIGNAL_HANDLER
	source.maxHealth += SKELETON_HEALTH_BONUS
	source.updatehealth("reinforced skeleton kept through a species change")

/obj/item/organ/internal/cyberimp/chest/blood_pump
	name = "blood pump implant"
	desc = "Аварийная кровяная помпа. Когда здоровье носителя падает до половины, она сращивает раны синт-плотью и впрыскивает уголь. Заряды восстанавливаются со временем."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "blood_pump_sec"
	implant_overlay = null
	slot = INTERNAL_ORGAN_HEART_DRIVE
	cyber_cost = 20
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
	cyber_cost = 25
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

/atom/movable/screen/fullscreen/kiroshi
	icon = 'icons/hud/kiroshi_zoom.dmi'
	icon_state = "frame"
	color = "#5EF6FF"

/atom/movable/screen/fullscreen/kiroshi/militech
	color = "#FF3C46"

/atom/movable/screen/kiroshi_readout
	screen_loc = "WEST+1:4,NORTH-2:8"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = NO_CLIENT_COLOR|RESET_COLOR
	maptext_width = 320
	maptext_height = 48

/obj/item/organ/internal/cyberimp/eyes/optics
	name = "Kiroshi optics"
	desc = "Высокоточная оптика Kiroshi. По команде выдвигает линзы, приближает картинку и выводит на сетчатку прицельную сетку, дальномер и метки всех, кто попал в поле зрения."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "kirosi_seer"
	implant_overlay = null
	slot = INTERNAL_ORGAN_EYE_OPTICS
	cyber_cost = 10
	origin_tech = "materials=4;programming=4;biotech=4;combat=3"
	aug_message = "Мир на мгновение плывёт, пока линзы подстраивают фокус..."
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	var/zoomed = FALSE
	var/hud_color = "#5EF6FF"
	var/brand_text = "KIROSHI"
	var/fullscreen_type = /atom/movable/screen/fullscreen/kiroshi
	var/atom/movable/screen/kiroshi_readout/readout
	var/list/image/target_images = list()
	var/scan_timer

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

/obj/item/organ/internal/cyberimp/eyes/optics/on_block_changed()
	. = ..()
	if(blocked)
		set_zoom(FALSE)

/obj/item/organ/internal/cyberimp/eyes/optics/proc/set_zoom(new_state)
	if(zoomed == new_state)
		return
	zoomed = new_state
	if(zoomed)
		RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_dir_change))
		RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
		RegisterSignal(owner, COMSIG_MOB_LOGOUT, PROC_REF(drop_zoom))
		owner.client?.view_size.zoomOut(offset = OPTICS_ZOOM_DISTANCE, direction = owner.dir)
		start_hud()
	else
		UnregisterSignal(owner, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_MOB_STATCHANGE, COMSIG_MOB_LOGOUT))
		owner.client?.view_size.zoomIn()
		stop_hud()

/obj/item/organ/internal/cyberimp/eyes/optics/proc/start_hud()
	owner.overlay_fullscreen(OPTICS_FULLSCREEN, fullscreen_type)
	readout = new
	owner.client?.screen += readout
	owner.playsound_local(get_turf(owner), 'sound/machines/terminal_on.ogg', 25, FALSE)
	scan()

/obj/item/organ/internal/cyberimp/eyes/optics/proc/stop_hud()
	deltimer(scan_timer)
	scan_timer = null
	clear_targets()
	owner.clear_fullscreen(OPTICS_FULLSCREEN)
	owner.client?.screen -= readout
	QDEL_NULL(readout)

/obj/item/organ/internal/cyberimp/eyes/optics/proc/clear_targets()
	owner.client?.images -= target_images
	target_images.Cut()

/obj/item/organ/internal/cyberimp/eyes/optics/proc/scan()
	deltimer(scan_timer)
	scan_timer = addtimer(CALLBACK(src, PROC_REF(scan)), OPTICS_SCAN_INTERVAL, TIMER_STOPPABLE)
	clear_targets()
	if(!owner.client)
		return
	var/turf/focus = get_ranged_target_turf(owner, owner.dir, OPTICS_ZOOM_DISTANCE)
	for(var/mob/living/target in view(OPTICS_SCAN_RANGE, owner))
		if(target == owner || target.stat == DEAD || target.alpha < OPTICS_MIN_TARGET_ALPHA || get_dist(target, focus) > OPTICS_ZOOM_DISTANCE)
			continue
		target_images += make_marker(target)
	owner.client.images += target_images
	readout.maptext = MAPTEXT("<span style='color: [hud_color]'>[brand_text] // ОПТИЧЕСКИЙ ЗУМ x[OPTICS_ZOOM_DISTANCE]<br>Направление: [dir2rustext(owner.dir)]<br>Целей в поле: [length(target_images)]</span>")

/obj/item/organ/internal/cyberimp/eyes/optics/proc/make_marker(mob/living/target)
	var/image/marker = image('icons/hud/kiroshi_target.dmi', target, "target")
	SET_PLANE_EXPLICIT(marker, BALLOON_CHAT_PLANE, owner)
	marker.appearance_flags = RESET_ALPHA|RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|PIXEL_SCALE
	marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	marker.color = hud_color
	marker.maptext_width = 64
	marker.maptext_x = -16
	marker.maptext_y = -12
	marker.maptext = MAPTEXT("<span style='text-align: center'>[get_dist(owner, target)] м</span>")
	return marker

/obj/item/organ/internal/cyberimp/eyes/optics/proc/on_dir_change(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	owner.client?.view_size.zoomOut(offset = OPTICS_ZOOM_DISTANCE, direction = new_dir)
	scan()

/obj/item/organ/internal/cyberimp/eyes/optics/proc/on_stat_change(datum/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat != CONSCIOUS)
		set_zoom(FALSE)

/obj/item/organ/internal/cyberimp/eyes/optics/proc/drop_zoom(datum/source)
	SIGNAL_HANDLER
	set_zoom(FALSE)

/obj/item/organ/internal/cyberimp/eyes/optics/militech
	name = "Militech optical suite"
	cyber_cost = 14
	desc = "Боевая оптика Militech. Приближает картинку, выводит на сетчатку боевую сетку с метками целей и гасит ослепляющие вспышки."
	icon_state = "kirosi_basilisk"
	origin_tech = "materials=5;programming=5;biotech=4;combat=5;syndicate=2"
	flash_protect = FLASH_PROTECTION_FLASH
	hud_color = "#FF3C46"
	brand_text = "MILITECH"
	fullscreen_type = /atom/movable/screen/fullscreen/kiroshi/militech

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
	cyber_cost = 30
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
	if(weapon || crit_fail || blocked || !is_active_arm())
		return
	deltas += punch_bonus
	punch_landed()

/obj/item/organ/internal/cyberimp/arm/gorilla/proc/punch_landed()
	return

/obj/item/organ/internal/cyberimp/arm/gorilla/proc/on_alt_click(mob/living/carbon/source, atom/target)
	SIGNAL_HANDLER
	if(!is_airlock(target) || crit_fail || blocked || !is_active_arm() || source.get_active_hand())
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
	cyber_cost = 35
	desc = "Агентская версия рук гориллы. Удар кулаком отшвыривает человека на несколько метров, а о стену бьёт ещё больнее. Обычные стёкла разлетаются с одного удара, шлюзы распахиваются от кулака, а каждый удачный удар ускоряет следующий."
	icon_state = "implant_gorilla_arms"
	origin_tech = "materials=6;biotech=5;combat=6;syndicate=3"
	punch_bonus = 8
	var/combo_speed = 1
	var/combo_timer
	var/datum/weakref/punch_target
	var/static/list/plasma_glass = list(/obj/item/stack/sheet/plasmaglass, /obj/item/stack/sheet/plasmarglass)

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

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/insert(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(.)
		RegisterSignal(arm_owner, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/remove(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	UnregisterSignal(arm_owner, COMSIG_LIVING_UNARMED_ATTACK)
	punch_target = null
	deltimer(combo_timer)
	set_combo_speed(1)
	return ..()

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/punch_landed()
	set_combo_speed(max(GORILLA_COMBO_MIN_SPEED, combo_speed * GORILLA_COMBO_STEP))
	combo_timer = addtimer(CALLBACK(src, PROC_REF(set_combo_speed), 1), GORILLA_COMBO_RESET_TIME, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)
	var/mob/living/target = punch_target?.resolve()
	punch_target = null
	if(can_knock_back(target))
		addtimer(CALLBACK(src, PROC_REF(knock_back), target), 1)

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/can_knock_back(mob/living/target)
	if(!target || target.anchored || target.mob_size > MOB_SIZE_HUMAN || target.move_resist > MOVE_RESIST_DEFAULT)
		return FALSE
	return (target.status_flags & CANPUSH) && !HAS_TRAIT(target, TRAIT_PUSHIMMUNE)

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/can_smash_window(obj/structure/window/window)
	return !(window.glass_type in plasma_glass) && !(window.resistance_flags & INDESTRUCTIBLE)

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/on_unarmed_attack(mob/living/carbon/source, atom/target, proximity_flag, list/modifiers)
	SIGNAL_HANDLER
	punch_target = null
	if(!proximity_flag || source.a_intent != INTENT_HARM || crit_fail || blocked || !is_active_arm())
		return NONE
	if(isliving(target))
		punch_target = WEAKREF(target)
		return NONE
	if(is_window(target))
		var/obj/structure/window/window = target
		if(!can_smash_window(window))
			return NONE
		source.do_attack_animation(window)
		source.changeNext_move(CLICK_CD_MELEE)
		source.visible_message(span_danger("[DECLENT_RU_CAP(source, NOMINATIVE)] выбива[PLUR_ET_YUT(source)] [window.declent_ru(ACCUSATIVE)] одним ударом кулака!"))
		window.deconstruct(FALSE)
		return COMPONENT_CANCEL_ATTACK_CHAIN
	if(is_airlock(target))
		var/obj/machinery/door/airlock/airlock = target
		if(!airlock.density || airlock.operating)
			return NONE
		source.do_attack_animation(airlock)
		source.changeNext_move(CLICK_CD_MELEE)
		INVOKE_ASYNC(src, PROC_REF(punch_airlock), airlock)
		return COMPONENT_CANCEL_ATTACK_CHAIN
	return NONE

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/punch_airlock(obj/machinery/door/airlock/airlock)
	if(airlock.welded)
		owner.balloon_alert(owner, "заварено!")
		return
	if(airlock.locked)
		owner.balloon_alert(owner, "болты опущены!")
		return
	if(airlock.isElectrified() && airlock.shock_user(owner, 100))
		return
	playsound(airlock, 'sound/effects/bang.ogg', 70, TRUE)
	owner.visible_message(span_danger("[DECLENT_RU_CAP(owner, NOMINATIVE)] бь[PLUR_ET_YUT(owner)] кулаком в [airlock.declent_ru(ACCUSATIVE)], и створки разъезжаются!"))
	airlock.open(TRUE)

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/knock_back(mob/living/target)
	if(QDELETED(target) || QDELETED(owner))
		return
	var/turf/landing = get_ranged_target_turf(target, get_dir(owner, target), GORILLA_KNOCKBACK_RANGE)
	RegisterSignal(target, COMSIG_MOVABLE_IMPACT, PROC_REF(on_knockback_impact), override = TRUE)
	target.throw_at(landing, GORILLA_KNOCKBACK_RANGE, GORILLA_KNOCKBACK_SPEED, owner, callback = CALLBACK(src, PROC_REF(end_knockback), target))

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/end_knockback(mob/living/target)
	UnregisterSignal(target, COMSIG_MOVABLE_IMPACT)

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/on_knockback_impact(mob/living/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(is_window(hit_atom))
		var/obj/structure/window/window = hit_atom
		if(can_smash_window(window))
			window.deconstruct(FALSE)
			return COMPONENT_MOVABLE_IMPACT_NEVERMIND
	if(!iswallturf(hit_atom) && !(isobj(hit_atom) && hit_atom.density))
		return
	source.apply_damage(GORILLA_WALL_SLAM_DAMAGE, BRUTE)
	source.Weaken(GORILLA_WALL_SLAM_KNOCKDOWN)
	shake_camera(source, 2, 2)
	playsound(source, 'sound/effects/meteorimpact.ogg', 50, TRUE)
	source.visible_message(span_danger("[DECLENT_RU_CAP(source, NOMINATIVE)] с хрустом влета[PLUR_ET_YUT(source)] в [hit_atom.declent_ru(ACCUSATIVE)]!"))

/obj/item/organ/internal/cyberimp/arm/gorilla/militech/proc/set_combo_speed(new_speed)
	if(combo_speed == new_speed || !owner)
		return
	owner.next_move_modifier *= new_speed / combo_speed
	combo_speed = new_speed

/obj/item/organ/internal/cyberimp/arm/monowire
	name = "monowire implant"
	cyber_cost = 30
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
	cyber_cost = 35
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
	if(user.a_intent == INTENT_GRAB && can_choke(target, user) && choke(target, user))
		return ATTACK_CHAIN_PROCEED_SUCCESS
	. = ..()
	if(ATTACK_CHAIN_SUCCESS_CHECK(.) && prob(shock_chance))
		shock(target, user)

/obj/item/melee/monowire/proc/can_choke(mob/living/target, mob/living/user)
	if(!ishuman(target) || target == user || user.pulling == target || !user.Adjacent(target))
		return FALSE
	return IS_HORIZONTAL(target) || target.dir == user.dir

/obj/item/melee/monowire/proc/choke(mob/living/carbon/human/target, mob/living/user)
	var/wire_hand = user.hand
	var/grabbed = target.grabbedby(user, supress_message = TRUE)
	if(user.hand != wire_hand)
		user.swap_hand()
	if(!grabbed)
		return FALSE
	target.grippedby(user, grab_state_override = GRAB_NECK)
	target.AdjustSilence(2 SECONDS)
	playsound(target, 'sound/weapons/cablecuff.ogg', 15, TRUE, -1)
	target.visible_message(
		span_danger("[DECLENT_RU_CAP(user, NOMINATIVE)] захлёстыва[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)] на шее [target.declent_ru(GENITIVE)]!"),
		span_userdanger("[DECLENT_RU_CAP(user, NOMINATIVE)] захлёстыва[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)] на вашей шее, и вы не можете вымолвить ни слова!"),
		span_italics("Слышна возня и скрип натянутой проволоки!"),
	)
	add_attack_logs(user, target, "neck grabbed with [src]")
	return TRUE

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

/datum/movespeed_modifier/sandevistan
	flags = IGNORE_NOSLOW
	blacklisted_movetypes = FLOATING
	multiplicative_slowdown = -1.1

/datum/actionspeed_modifier/sandevistan
	multiplicative_slowdown = -0.5

/atom/movable/screen/fullscreen/sandevistan
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	plane = LIGHTING_PLANE
	layer = LIGHTING_ABOVE_ALL + 1
	blend_mode = BLEND_MULTIPLY
	color = "#9FFFD9"

/obj/effect/temp_visual/decoy/fading/sandevistan
	duration = 3

/obj/effect/temp_visual/decoy/fading/sandevistan/Initialize(mapload, atom/mimiced_atom, trail_color)
	. = ..()
	if(trail_color)
		color = trail_color

/obj/item/organ/internal/cyberimp/brain/sandevistan
	name = "Sandevistan"
	desc = "Нейроимплант, на несколько секунд разгоняющий нервную систему: носитель срывается с места, уходит от пуль и ударов, а его остаточный образ бьёт вслед за ним. Перезарядки нет, предел задаёт только перегрев, и перегретое тело рано или поздно не выдерживает."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "qian-ti_sandevistan"
	implant_overlay = null
	slot = INTERNAL_ORGAN_BRAIN_SANDEVISTAN
	cyber_cost = 45
	origin_tech = "materials=5;programming=5;biotech=5;combat=4"
	actions_types = list(/datum/action/item_action/organ_action/use)
	worn_state = "sandevistan"
	worn_lights_state = "sandevistan_lights"
	worn_color = "#00FFFF"
	var/duration = 6 SECONDS
	var/heat_per_use = 40
	var/cooling_rate = 1
	var/echo_damage_mod = 0.4
	var/outline_color = "#00FFFF"
	var/trail_color
	var/active = FALSE
	var/overheat = 0
	var/finisher_ready = FALSE
	var/active_timer
	var/cooling_timer
	var/finisher_timer

/obj/item/organ/internal/cyberimp/brain/sandevistan/get_ru_names()
	return alist(
		NOMINATIVE = "Сандевистан",
		GENITIVE = "Сандевистана",
		DATIVE = "Сандевистану",
		ACCUSATIVE = "Сандевистан",
		INSTRUMENTAL = "Сандевистаном",
		PREPOSITIONAL = "Сандевистане",
	)

/obj/item/organ/internal/cyberimp/brain/sandevistan/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	deltimer(active_timer)
	deltimer(cooling_timer)
	cooling_timer = null
	set_active(FALSE)
	disarm_finisher()
	overheat = 0
	update_heat_display()
	return ..()

/obj/item/organ/internal/cyberimp/brain/sandevistan/emp_act(severity)
	. = ..()
	if(!.)
		return
	end_activation()
	if(!prob(SANDEVISTAN_EMP_GLITCH_CHANCE / severity))
		return
	add_heat(max(SANDEVISTAN_HEAT_STRAIN - overheat, 0))
	to_chat(owner, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] бешено сбоит от ЭМИ!"))

/obj/item/organ/internal/cyberimp/brain/sandevistan/ui_action_click(mob/user, datum/action/action, leftclick)
	if(active)
		owner.balloon_alert(owner, "уже работает!")
		return
	add_heat(heat_per_use)
	set_active(TRUE)
	active_timer = addtimer(CALLBACK(src, PROC_REF(end_activation)), duration, TIMER_STOPPABLE)
	dash()
	if(overheat >= SANDEVISTAN_HEAT_CRITICAL)
		critical_overload()
	else if(overheat >= SANDEVISTAN_HEAT_STRAIN)
		strain()

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/set_active(new_state)
	if(active == new_state)
		return
	active = new_state
	var/mob/living/carbon/human/human_owner = owner
	if(active)
		disarm_finisher()
		owner.add_movespeed_modifier(/datum/movespeed_modifier/sandevistan)
		owner.add_filter(SANDEVISTAN_FILTER, 2, outline_filter(1, outline_color))
		if(istype(human_owner))
			human_owner.physiology.stamina_mod *= SANDEVISTAN_STAMINA_MOD
		RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(leave_trail))
		owner.add_actionspeed_modifier(/datum/actionspeed_modifier/sandevistan)
		owner.next_move_modifier *= SANDEVISTAN_CLICK_MOD
		RegisterSignal(owner, COMSIG_HUMAN_TRY_DEFLECT_BULLET, PROC_REF(slip_projectile))
		RegisterSignal(owner, COMSIG_HUMAN_CHECK_SHIELDS, PROC_REF(dodge_melee))
		RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack), override = TRUE)
		RegisterSignal(owner, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack), override = TRUE)
		owner.overlay_fullscreen(SANDEVISTAN_FLASH, /atom/movable/screen/fullscreen/flash)
		owner.clear_fullscreen(SANDEVISTAN_FLASH, 3)
		owner.overlay_fullscreen(SANDEVISTAN_FULLSCREEN, /atom/movable/screen/fullscreen/sandevistan)
		worn_glow = TRUE
		update_worn_overlay()
		playsound(owner, 'sound/effects/sandevistan/activate.ogg', 60, TRUE)
		to_chat(owner, span_notice("Зрение обостряется, и время вокруг будто замедляется."))
		return
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/sandevistan)
	owner.remove_filter(SANDEVISTAN_FILTER)
	if(istype(human_owner))
		human_owner.physiology.stamina_mod /= SANDEVISTAN_STAMINA_MOD
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_HUMAN_TRY_DEFLECT_BULLET, COMSIG_HUMAN_CHECK_SHIELDS))
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/sandevistan)
	owner.next_move_modifier /= SANDEVISTAN_CLICK_MOD
	owner.clear_fullscreen(SANDEVISTAN_FULLSCREEN, 5)
	worn_glow = FALSE
	update_worn_overlay()
	playsound(owner, 'sound/effects/sandevistan/deactivate.ogg', 50, TRUE)
	to_chat(owner, span_warning("Мир снова обретает обычную скорость: [declent_ru(NOMINATIVE)] отключается."))

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/add_heat(amount)
	overheat = clamp(overheat + amount, 0, SANDEVISTAN_HEAT_MAX)
	update_heat_display()
	if(overheat && !cooling_timer)
		cooling_timer = addtimer(CALLBACK(src, PROC_REF(cool_tick)), SANDEVISTAN_COOLING_TICK, TIMER_STOPPABLE)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/cool_tick()
	cooling_timer = null
	if(!active)
		overheat = max(overheat - cooling_rate, 0)
		update_heat_display()
	if(overheat)
		cooling_timer = addtimer(CALLBACK(src, PROC_REF(cool_tick)), SANDEVISTAN_COOLING_TICK, TIMER_STOPPABLE)
	else if(owner)
		to_chat(owner, span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] остывает."))

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/update_heat_display()
	var/heat_color = "#00FFFF"
	if(overheat >= SANDEVISTAN_HEAT_CRITICAL)
		heat_color = "#FF3C46"
	else if(overheat >= SANDEVISTAN_HEAT_STRAIN)
		heat_color = "#FFA53C"
	for(var/datum/action/action as anything in actions)
		action.status_text = overheat ? "<b><font color='[heat_color]'>[round(overheat)]%</font></b>" : null
		action.build_all_button_icons(UPDATE_BUTTON_STATUS)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/dash()
	if(owner.buckled || owner.pulledby || owner.legcuffed || owner.body_position == LYING_DOWN || owner.incapacitated() || HAS_TRAIT(owner, TRAIT_IMMOBILIZED))
		return
	for(var/i in 1 to SANDEVISTAN_DASH_RANGE)
		if(!step(owner, owner.dir))
			return

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/slip_projectile(mob/living/carbon/human/source, obj/projectile/hitting_projectile, def_zone)
	SIGNAL_HANDLER
	if(hitting_projectile && has_active_sandevistan(hitting_projectile.firer))
		return NONE
	new /obj/effect/temp_visual/decoy/fading/sandevistan(get_turf(source), source, trail_color || outline_color)
	playsound(source, 'sound/effects/sandevistan/dodge.ogg', 40, TRUE)
	return COMPONENT_BULLET_DEFLECTED

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/dodge_melee(mob/living/carbon/human/source, atom/movable/hitby, attack_text, armour_penetration, damage, attack_type)
	SIGNAL_HANDLER
	if(!(attack_type & (ITEM_ATTACK|UNARMED_ATTACK|LEAP_ATTACK)) || source.body_position == LYING_DOWN || source.incapacitated())
		return NONE
	if(has_active_sandevistan(get_attacker(hitby)) || !prob(SANDEVISTAN_MELEE_DODGE_CHANCE))
		return NONE
	new /obj/effect/temp_visual/decoy/fading/sandevistan(get_turf(source), source, trail_color || outline_color)
	playsound(source, 'sound/effects/sandevistan/dodge.ogg', 40, TRUE)
	source.visible_message(span_danger("[DECLENT_RU_CAP(source, NOMINATIVE)] смазыва[PLUR_ET_YUT(source)]ся в движении, и удар проходит сквозь остаточный образ!"))
	return SHIELD_BLOCK

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/get_attacker(atom/movable/hitby)
	if(isprojectile(hitby))
		var/obj/projectile/projectile = hitby
		return projectile.firer
	if(isitem(hitby))
		return hitby.loc
	return hitby

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/has_active_sandevistan(mob/living/carbon/attacker)
	if(!iscarbon(attacker))
		return FALSE
	var/obj/item/organ/internal/cyberimp/brain/sandevistan/other = attacker.get_organ_slot(INTERNAL_ORGAN_BRAIN_SANDEVISTAN)
	return istype(other) && other.active

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/on_item_attack(mob/living/source, atom/target, list/modifiers, def_zone)
	SIGNAL_HANDLER
	if(!isliving(target) || target == source)
		return
	var/obj/item/weapon = source.get_active_hand()
	if(weapon)
		melee_hit(target, weapon.force, weapon.damtype, weapon.hitsound || 'sound/weapons/genhit1.ogg')

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/on_unarmed_attack(mob/living/carbon/source, atom/target, proximity_flag, list/modifiers)
	SIGNAL_HANDLER
	if(!proximity_flag || source.a_intent != INTENT_HARM || !isliving(target) || target == source || source.can_grab_attack(target, proximity_flag))
		return NONE
	var/mob/living/carbon/human/human_source = source
	var/damage = istype(human_source) ? rand(human_source.dna.species.punchdamagelow, human_source.dna.species.punchdamagehigh) : 0
	melee_hit(target, damage, BRUTE, 'sound/weapons/punch1.ogg')
	return NONE

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/melee_hit(mob/living/target, damage, damage_type, hit_sound)
	if(damage <= 0 || HAS_TRAIT(owner, TRAIT_PACIFISM) || GLOB.pacifism_after_gt)
		return
	if(active)
		addtimer(CALLBACK(src, PROC_REF(echo_strike), target, round(damage * echo_damage_mod), damage_type, hit_sound), SANDEVISTAN_ECHO_DELAY)
		return
	if(!finisher_ready)
		return
	disarm_finisher()
	addtimer(CALLBACK(src, PROC_REF(finish_strike), target), SANDEVISTAN_ECHO_DELAY)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/echo_strike(mob/living/target, damage, damage_type, hit_sound)
	if(QDELETED(target) || QDELETED(owner) || !owner.Adjacent(target))
		return
	new /obj/effect/temp_visual/decoy/fading/sandevistan(get_turf(owner), owner, trail_color || outline_color)
	owner.do_attack_animation(target)
	if(is_strike_blocked(target, damage))
		return
	var/zone = owner.zone_selected
	target.apply_damage(damage, damage_type, zone, target.run_armor_check(zone, MELEE))
	playsound(target, hit_sound, 40, TRUE)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/is_strike_blocked(mob/living/target, damage)
	var/mob/living/carbon/human/human_target = target
	return istype(human_target) && human_target.check_shields(owner, damage, "удар остаточного образа", UNARMED_ATTACK)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/finish_strike(mob/living/target)
	if(QDELETED(target) || QDELETED(owner) || !owner.Adjacent(target))
		return
	if(is_strike_blocked(target, 0))
		return
	target.Knockdown(SANDEVISTAN_FINISHER_KNOCKDOWN)
	shake_camera(target, 3, 2)
	playsound(target, 'sound/effects/sandevistan/dodge.ogg', 50, TRUE)
	owner.visible_message(span_danger("[DECLENT_RU_CAP(owner, NOMINATIVE)] выход[PLUR_IT_YAT(owner)] из разгона сокрушительным ударом и сбива[PLUR_ET_YUT(owner)] [target.declent_ru(ACCUSATIVE)] с ног!"))

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/arm_finisher()
	finisher_ready = TRUE
	finisher_timer = addtimer(CALLBACK(src, PROC_REF(disarm_finisher)), SANDEVISTAN_FINISHER_WINDOW, TIMER_STOPPABLE)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/disarm_finisher()
	finisher_ready = FALSE
	deltimer(finisher_timer)
	finisher_timer = null
	if(owner && !active)
		UnregisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_UNARMED_ATTACK))

/obj/item/organ/internal/cyberimp/brain/sandevistan/on_block_changed()
	if(!blocked)
		return
	deltimer(active_timer)
	set_active(FALSE)
	disarm_finisher()

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/end_activation()
	if(!active)
		return
	set_active(FALSE)
	arm_finisher()
	if(overheat >= SANDEVISTAN_HEAT_LETHAL)
		flatline()

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/leave_trail(mob/living/source, atom/old_loc, movement_dir)
	SIGNAL_HANDLER
	if(!isturf(old_loc))
		return
	var/obj/effect/temp_visual/decoy/fading/sandevistan/afterimage = new(old_loc, source, trail_color)
	afterimage.setDir(movement_dir)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/strain()
	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner))
		return
	to_chat(human_owner, span_warning("Тело ломит от повторного разгона!"))
	shake_camera(human_owner, 5, 3)
	human_owner.Jitter(15 SECONDS)
	human_owner.drop_from_hands()
	var/obj/item/organ/external/chest = human_owner.get_organ(BODY_ZONE_CHEST)
	chest?.internal_bleeding()
	human_owner.apply_damage(SANDEVISTAN_STRAIN_DAMAGE, BRUTE, BODY_ZONE_CHEST)
	human_owner.blood_volume = max(human_owner.blood_volume - SANDEVISTAN_STRAIN_BLOOD_LOSS, 0)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/critical_overload()
	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner))
		return
	to_chat(human_owner, span_userdanger("Кибернетика уходит в критическую перегрузку!"))
	shake_camera(human_owner, 10, 6)
	human_owner.Jitter(30 SECONDS)
	human_owner.EyeBlurry(10 SECONDS)
	human_owner.adjustToxLoss(SANDEVISTAN_CRITICAL_TOX_DAMAGE)
	human_owner.adjustBrainLoss(SANDEVISTAN_CRITICAL_BRAIN_DAMAGE)
	for(var/i in 1 to SANDEVISTAN_CRITICAL_BLEEDING_LIMBS)
		var/obj/item/organ/external/limb = pick(human_owner.bodyparts)
		limb.internal_bleeding()
	human_owner.blood_volume = max(human_owner.blood_volume - SANDEVISTAN_CRITICAL_BLOOD_LOSS, 0)
	human_owner.reagents.add_reagent("cyanide", SANDEVISTAN_CRITICAL_CYANIDE)

/obj/item/organ/internal/cyberimp/brain/sandevistan/proc/flatline()
	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner) || human_owner.stat == DEAD)
		return
	human_owner.adjustBrainLoss(SANDEVISTAN_LETHAL_BRAIN_DAMAGE)
	human_owner.adjustToxLoss(SANDEVISTAN_LETHAL_TOX_DAMAGE)
	human_owner.blood_volume = max(human_owner.blood_volume - SANDEVISTAN_LETHAL_BLOOD_LOSS, 0)
	human_owner.visible_message(
		span_danger("[DECLENT_RU_CAP(human_owner, NOMINATIVE)] вдруг пада[PLUR_ET_YUT(human_owner)] без сил: кибернетика отключается с треском!"),
		span_userdanger("Тело не выдерживает катастрофической перегрузки!"),
	)
	human_owner.Weaken(10 SECONDS)
	if(human_owner.blood_volume <= BLOOD_VOLUME_SURVIVE)
		human_owner.adjustOxyLoss(SANDEVISTAN_LETHAL_OXY_DAMAGE)

/obj/item/organ/internal/cyberimp/brain/sandevistan/cybersun
	name = "Cybersun Sandevistan"
	cyber_cost = 55
	desc = "Военный Сандевистан Cybersun. Греется медленнее и остывает быстрее, а остаточный образ бьёт сильнее, но конец у перегрева тот же."
	icon_state = "militech_sandevistan"
	origin_tech = "materials=6;programming=6;biotech=6;combat=6;syndicate=3"
	worn_color = "#C2185B"
	heat_per_use = 25
	cooling_rate = 1.5
	echo_damage_mod = 0.6
	outline_color = "#C2185B"
	trail_color = "#C2185B"

/obj/item/organ/internal/cyberimp/brain/sandevistan/cybersun/get_ru_names()
	return alist(
		NOMINATIVE = "Сандевистан Cybersun",
		GENITIVE = "Сандевистана Cybersun",
		DATIVE = "Сандевистану Cybersun",
		ACCUSATIVE = "Сандевистан Cybersun",
		INSTRUMENTAL = "Сандевистаном Cybersun",
		PREPOSITIONAL = "Сандевистане Cybersun",
	)

/obj/item/organ/internal/cyberimp/brain/berserker
	name = "Berserker implant"
	desc = "Боевой имплант, затапливающий организм стимуляторами. На время носитель держит удар и бьёт вдвое чаще, но не может стрелять. Стоит на месте Сандевистана."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "moore_berserker"
	implant_overlay = null
	slot = INTERNAL_ORGAN_BRAIN_SANDEVISTAN
	cyber_cost = 45
	origin_tech = "materials=5;programming=5;biotech=5;combat=5"
	actions_types = list(/datum/action/item_action/organ_action/use)
	var/duration = 25 SECONDS
	var/cooldown = 60 SECONDS
	var/armor_bonus = 60
	var/active = FALSE
	var/active_timer
	var/emp_shield_timer
	COOLDOWN_DECLARE(use_cooldown)

/obj/item/organ/internal/cyberimp/brain/berserker/get_ru_names()
	return alist(
		NOMINATIVE = "имплант Берсерк",
		GENITIVE = "импланта Берсерк",
		DATIVE = "импланту Берсерк",
		ACCUSATIVE = "имплант Берсерк",
		INSTRUMENTAL = "имплантом Берсерк",
		PREPOSITIONAL = "импланте Берсерк",
	)

/obj/item/organ/internal/cyberimp/brain/berserker/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	deltimer(active_timer)
	deltimer(emp_shield_timer)
	set_active(FALSE)
	emp_proof = initial(emp_proof)
	return ..()

/obj/item/organ/internal/cyberimp/brain/berserker/emp_act(severity)
	. = ..()
	if(!.)
		return
	deltimer(active_timer)
	set_active(FALSE)
	owner.adjustBrainLoss(BRAIN_DAMAGE_DEATH * BERSERKER_EMP_BRAIN_FRACTION)
	COOLDOWN_START(src, use_cooldown, cooldown)
	emp_proof = TRUE
	emp_shield_timer = addtimer(CALLBACK(src, PROC_REF(drop_emp_shield)), cooldown, TIMER_STOPPABLE)
	owner.visible_message(
		span_danger("[DECLENT_RU_CAP(owner, NOMINATIVE)] бьётся в судорогах: [declent_ru(NOMINATIVE)] перегружается!"),
		span_userdanger("ЭМИ выжигает [declent_ru(ACCUSATIVE)]! Заряд потерян, а в голове всё плывёт."),
	)

/obj/item/organ/internal/cyberimp/brain/berserker/ui_action_click(mob/user, datum/action/action, leftclick)
	if(active)
		owner.balloon_alert(owner, "уже работает!")
		return
	if(!COOLDOWN_FINISHED(src, use_cooldown))
		owner.balloon_alert(owner, "перезарядка: [round(COOLDOWN_TIMELEFT(src, use_cooldown) / (1 SECONDS))] с")
		return
	COOLDOWN_START(src, use_cooldown, cooldown)
	set_active(TRUE)
	active_timer = addtimer(CALLBACK(src, PROC_REF(set_active), FALSE), duration, TIMER_STOPPABLE)

/obj/item/organ/internal/cyberimp/brain/berserker/on_block_changed()
	if(blocked)
		deltimer(active_timer)
		set_active(FALSE)

/obj/item/organ/internal/cyberimp/brain/berserker/proc/set_active(new_state)
	var/mob/living/carbon/human/human_owner = owner
	if(active == new_state || !istype(human_owner))
		return
	active = new_state
	var/armor_change = active ? armor_bonus : -armor_bonus
	human_owner.physiology.armor = human_owner.physiology.armor.modifyRating(melee_value = armor_change, bullet_value = armor_change, laser_value = armor_change)
	if(active)
		human_owner.next_move_modifier *= BERSERKER_ATTACK_SPEED
		ADD_TRAIT(human_owner, TRAIT_NO_GUNS, UNIQUE_TRAIT_SOURCE(src))
		human_owner.add_filter(BERSERKER_FILTER, 2, outline_filter(1, BERSERKER_OUTLINE_COLOR))
		to_chat(human_owner, span_notice("Вы впадаете в боевое безумие! Кажется, вас ничто не остановит!"))
		return
	human_owner.next_move_modifier /= BERSERKER_ATTACK_SPEED
	REMOVE_TRAIT(human_owner, TRAIT_NO_GUNS, UNIQUE_TRAIT_SOURCE(src))
	human_owner.remove_filter(BERSERKER_FILTER)
	to_chat(human_owner, span_warning("Боевое безумие отступает..."))

/obj/item/organ/internal/cyberimp/brain/berserker/proc/drop_emp_shield()
	emp_proof = initial(emp_proof)
	if(owner)
		to_chat(owner, span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] перезарядился, и защита от ЭМИ отключается."))

/obj/item/organ/internal/cyberimp/brain/berserker/militech
	name = "Militech Berserker implant"
	cyber_cost = 55
	desc = "Берсерк Militech. Держит удар ещё лучше и действует дольше, а перезаряжается быстрее."
	icon_state = "militech_berserker"
	origin_tech = "materials=6;programming=6;biotech=6;combat=6;syndicate=3"
	duration = 35 SECONDS
	cooldown = 45 SECONDS
	armor_bonus = 80

/obj/item/organ/internal/cyberimp/brain/berserker/militech/get_ru_names()
	return alist(
		NOMINATIVE = "имплант Берсерк Militech",
		GENITIVE = "импланта Берсерк Militech",
		DATIVE = "импланту Берсерк Militech",
		ACCUSATIVE = "имплант Берсерк Militech",
		INSTRUMENTAL = "имплантом Берсерк Militech",
		PREPOSITIONAL = "импланте Берсерк Militech",
	)

/obj/item/organ/internal/cyberimp/arm/ballistic_processor
	name = "ballistic processor implant"
	cyber_cost = 18
	desc = "Баллистический сопроцессор, связанный с нервами руки. Пули носителя чаще рикошетят от стен и после отскока сами доводятся на ближайшую цель."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "ballistic_coprocessor"
	origin_tech = "materials=5;programming=6;combat=6"
	actions_types = null

/obj/item/organ/internal/cyberimp/arm/ballistic_processor/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/ballistic_processor/get_ru_names()
	return alist(
		NOMINATIVE = "баллистический процессор",
		GENITIVE = "баллистического процессора",
		DATIVE = "баллистическому процессору",
		ACCUSATIVE = "баллистический процессор",
		INSTRUMENTAL = "баллистическим процессором",
		PREPOSITIONAL = "баллистическом процессоре",
	)

/obj/item/organ/internal/cyberimp/arm/ballistic_processor/insert(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(!.)
		return
	RegisterSignal(arm_owner, COMSIG_PROJECTILE_BEFORE_FIRE, PROC_REF(on_fire))

/obj/item/organ/internal/cyberimp/arm/ballistic_processor/remove(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	UnregisterSignal(arm_owner, COMSIG_PROJECTILE_BEFORE_FIRE)
	return ..()

/obj/item/organ/internal/cyberimp/arm/ballistic_processor/ui_action_click(mob/user, datum/action/action, leftclick)
	return

/obj/item/organ/internal/cyberimp/arm/ballistic_processor/proc/on_fire(mob/living/source, obj/projectile/projectile, atom/original_target)
	SIGNAL_HANDLER
	if(crit_fail || projectile.flag != BULLET || !projectile.ricochets_max)
		return
	projectile.ricochet_chance = max(projectile.ricochet_chance, BALLISTIC_PROCESSOR_RICOCHET_CHANCE)
	projectile.ricochets_max = max(projectile.ricochets_max, BALLISTIC_PROCESSOR_RICOCHETS)
	projectile.ricochet_auto_aim_range = BALLISTIC_PROCESSOR_AIM_RANGE
	projectile.ricochet_auto_aim_angle = BALLISTIC_PROCESSOR_AIM_ANGLE

/obj/item/organ/internal/cyberimp/arm/hand_cannon
	name = "hand cannon implant"
	cyber_cost = 30
	desc = "Компактный разрывной пусковик, встроенный в предплечье. Ствол выдвигается из руки и прячется обратно, когда не нужен."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "implant_projectile_launcher_sec"
	origin_tech = "materials=5;combat=6;biotech=4;powerstorage=4"
	contents = newlist(/obj/item/gun/energy/hand_cannon)

/obj/item/organ/internal/cyberimp/arm/hand_cannon/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/hand_cannon/get_ru_names()
	return alist(
		NOMINATIVE = "имплант ручной пушки",
		GENITIVE = "импланта ручной пушки",
		DATIVE = "импланту ручной пушки",
		ACCUSATIVE = "имплант ручной пушки",
		INSTRUMENTAL = "имплантом ручной пушки",
		PREPOSITIONAL = "импланте ручной пушки",
	)

/obj/item/organ/internal/cyberimp/arm/hand_cannon/emp_act(severity)
	if(emp_proof || emp_shielded(severity) || !owner)
		return
	var/obj/item/gun/energy/hand_cannon/cannon = locate() in items_list
	if(cannon?.can_shoot(owner))
		INVOKE_ASYNC(cannon, TYPE_PROC_REF(/obj/item/gun/energy/hand_cannon, misfire), owner)
	return ..()

/obj/item/organ/internal/cyberimp/arm/hand_cannon/militech
	name = "Militech hand cannon implant"
	cyber_cost = 35
	desc = "Ручная пушка Militech. Вместо одного тяжёлого заряда даёт очередь из трёх малых и перезаряжается втрое быстрее."
	icon_state = "implant_projectile_launcher"
	origin_tech = "materials=6;combat=6;biotech=5;powerstorage=5;syndicate=3"
	contents = newlist(/obj/item/gun/energy/hand_cannon/militech)

/obj/item/organ/internal/cyberimp/arm/hand_cannon/militech/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/hand_cannon/militech/get_ru_names()
	return alist(
		NOMINATIVE = "имплант ручной пушки Militech",
		GENITIVE = "импланта ручной пушки Militech",
		DATIVE = "импланту ручной пушки Militech",
		ACCUSATIVE = "имплант ручной пушки Militech",
		INSTRUMENTAL = "имплантом ручной пушки Militech",
		PREPOSITIONAL = "импланте ручной пушки Militech",
	)

/obj/item/gun/energy/hand_cannon
	name = "hand cannon"
	desc = "Встроенный в руку разрывной пусковик. Перед выстрелом заряжается полторы секунды, после — долго перезаряжается."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "implant_projectile_launcher_sec_laser"
	item_state = "projectile_launcher"
	lefthand_file = 'icons/mob/inhands/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/melee_righthand.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/hand_cannon)
	cell_type = /obj/item/stock_parts/cell/emproof
	can_charge = FALSE
	can_add_sibyl_system = FALSE
	unique_rename = FALSE
	w_class = WEIGHT_CLASS_BULKY
	windup_delay = 1.5 SECONDS
	windup_sound = 'sound/machines/defib_charge.ogg'
	var/volley_size = 1
	var/volley_shots = 0
	var/reload_time = 30 SECONDS
	var/reload_timer

/obj/item/gun/energy/hand_cannon/get_ru_names()
	return alist(
		NOMINATIVE = "ручная пушка",
		GENITIVE = "ручной пушки",
		DATIVE = "ручной пушке",
		ACCUSATIVE = "ручную пушку",
		INSTRUMENTAL = "ручной пушкой",
		PREPOSITIONAL = "ручной пушке",
	)

/obj/item/gun/energy/hand_cannon/Destroy()
	deltimer(reload_timer)
	return ..()

/obj/item/gun/energy/hand_cannon/emp_act(severity)
	return

/obj/item/gun/energy/hand_cannon/on_windup_check()
	if(volley_shots)
		return TRUE
	return ..()

/obj/item/gun/energy/hand_cannon/process_fire(zone_override)
	var/atom/volley_target = target
	var/mob/living/shooter = gun_user
	. = ..()
	if(!.)
		if(volley_shots)
			volley_shots = 0
			start_reload()
		return
	if(++volley_shots < volley_size)
		addtimer(CALLBACK(src, PROC_REF(fast_fire), volley_target, shooter), HAND_CANNON_VOLLEY_DELAY)
		return
	volley_shots = 0
	start_reload()

/obj/item/gun/energy/hand_cannon/proc/misfire(mob/living/victim)
	var/obj/item/ammo_casing/energy/hand_cannon/shot = ammo_type[select]
	var/obj/projectile/bullet/hand_cannon/charge = shot.projectile_type
	victim.visible_message(
		span_danger("В руке [victim.declent_ru(GENITIVE)] сама срабатывает [declent_ru(NOMINATIVE)]!"),
		span_userdanger("[DECLENT_RU_CAP(src, NOMINATIVE)] срабатывает от ЭМИ прямо вам под ноги!"),
	)
	explosion(get_turf(victim), devastation_range = -1, heavy_impact_range = -1, light_impact_range = initial(charge.blast_range), cause = src)
	start_reload()

/obj/item/gun/energy/hand_cannon/proc/start_reload()
	cell.use(cell.charge)
	update_icon()
	reload_timer = addtimer(CALLBACK(src, PROC_REF(reload)), reload_time, TIMER_STOPPABLE)

/obj/item/gun/energy/hand_cannon/proc/reload()
	reload_timer = null
	cell.give(cell.maxcharge)
	on_recharge()
	update_icon()
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	if(ismob(loc))
		loc.balloon_alert(loc, "пушка заряжена")

/obj/item/gun/energy/hand_cannon/militech
	name = "Militech hand cannon"
	icon_state = "implant_projectile_launcher_laser"
	ammo_type = list(/obj/item/ammo_casing/energy/hand_cannon/militech)
	volley_size = 3
	reload_time = 10 SECONDS

/obj/item/gun/energy/hand_cannon/militech/get_ru_names()
	return alist(
		NOMINATIVE = "ручная пушка Militech",
		GENITIVE = "ручной пушки Militech",
		DATIVE = "ручной пушке Militech",
		ACCUSATIVE = "ручную пушку Militech",
		INSTRUMENTAL = "ручной пушкой Militech",
		PREPOSITIONAL = "ручной пушке Militech",
	)

/obj/item/ammo_casing/energy/hand_cannon
	projectile_type = /obj/projectile/bullet/hand_cannon
	fire_sound = 'sound/weapons/rocketlaunch.ogg'

/obj/item/ammo_casing/energy/hand_cannon/militech
	projectile_type = /obj/projectile/bullet/hand_cannon/mini
	fire_sound = 'sound/weapons/grenadelaunch.ogg'

/obj/projectile/bullet/hand_cannon
	name = "explosive charge"
	icon_state = "bolter"
	range = 15
	ricochets_max = 0
	var/blast_range = 2

/obj/projectile/bullet/hand_cannon/get_ru_names()
	return alist(
		NOMINATIVE = "разрывной заряд",
		GENITIVE = "разрывного заряда",
		DATIVE = "разрывному заряду",
		ACCUSATIVE = "разрывной заряд",
		INSTRUMENTAL = "разрывным зарядом",
		PREPOSITIONAL = "разрывном заряде",
	)

/obj/projectile/bullet/hand_cannon/on_hit(atom/target, blocked = 0, hit_zone)
	. = ..()
	explosion(target, devastation_range = -1, heavy_impact_range = -1, light_impact_range = blast_range, cause = src)

/obj/projectile/bullet/hand_cannon/mini
	name = "mini explosive charge"
	damage = 25
	range = 12
	blast_range = 1

/obj/projectile/bullet/hand_cannon/mini/get_ru_names()
	return alist(
		NOMINATIVE = "малый разрывной заряд",
		GENITIVE = "малого разрывного заряда",
		DATIVE = "малому разрывному заряду",
		ACCUSATIVE = "малый разрывной заряд",
		INSTRUMENTAL = "малым разрывным зарядом",
		PREPOSITIONAL = "малом разрывном заряде",
	)

/obj/item/organ/internal/heart/cybernetic/anomalock
	name = "voltaic combat cyberheart"
	desc = "Передовое кибернетическое сердце, созданное для отрядов смерти НТ и позже рассекреченное. Вольтаическая технология держит тело на ногах в безнадёжной ситуации и отводит энергию аномалии, полностью защищая носителя от ударов током и ЭМИ. Без ядра энергетической аномалии не работает."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "anomalock_heart"
	item_state = "heart-on"
	origin_tech = "materials=6;biotech=6;powerstorage=6"
	var/obj/item/assembly/signaler/core/energetic/core
	var/mutable_appearance/lightning_overlay
	var/lightning_timer
	COOLDOWN_DECLARE(survival_cooldown)
	COOLDOWN_DECLARE(battery_cooldown)

/obj/item/organ/internal/heart/cybernetic/anomalock/get_ru_names()
	return alist(
		NOMINATIVE = "вольтаическое боевое кибер-сердце",
		GENITIVE = "вольтаического боевого кибер-сердца",
		DATIVE = "вольтаическому боевому кибер-сердцу",
		ACCUSATIVE = "вольтаическое боевое кибер-сердце",
		INSTRUMENTAL = "вольтаическим боевым кибер-сердцем",
		PREPOSITIONAL = "вольтаическом боевом кибер-сердце",
	)

/obj/item/organ/internal/heart/cybernetic/anomalock/Destroy()
	QDEL_NULL(core)
	return ..()

/obj/item/organ/internal/heart/cybernetic/anomalock/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone != core)
		return
	core = null
	update_icon(UPDATE_ICON_STATE)

/obj/item/organ/internal/heart/cybernetic/anomalock/update_icon_state()
	icon_state = "anomalock_heart[core ? "-core" : ""]"

/obj/item/organ/internal/heart/cybernetic/anomalock/insert(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(!. || !core)
		return
	ADD_TRAIT(target, TRAIT_SHOCKIMMUNE, UNIQUE_TRAIT_SOURCE(src))
	ADD_TRAIT(target, TRAIT_EMP_IMMUNE, UNIQUE_TRAIT_SOURCE(src))
	RegisterSignal(target, COMSIG_ATOM_EMP_ACT, PROC_REF(on_emp))
	show_lightning(ANOMALOCK_OVERDRIVE_TIME)
	playsound(target, 'sound/magic/lightning_chargeup.ogg', 40, TRUE)

/obj/item/organ/internal/heart/cybernetic/anomalock/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	REMOVE_TRAIT(target, TRAIT_SHOCKIMMUNE, UNIQUE_TRAIT_SOURCE(src))
	REMOVE_TRAIT(target, TRAIT_EMP_IMMUNE, UNIQUE_TRAIT_SOURCE(src))
	UnregisterSignal(target, COMSIG_ATOM_EMP_ACT)
	deltimer(lightning_timer)
	hide_lightning()
	. = ..()
	if(core && !special)
		tesla_zap(source = target, zap_range = ANOMALOCK_ZAP_RANGE, power = ANOMALOCK_ZAP_POWER, cutoff = ANOMALOCK_ZAP_CUTOFF)

/obj/item/organ/internal/heart/cybernetic/anomalock/on_life()
	. = ..()
	if(!core)
		return
	if(owner.blood_volume < BLOOD_VOLUME_NORMAL)
		owner.blood_volume = min(owner.blood_volume + ANOMALOCK_BLOOD_REGEN, BLOOD_VOLUME_NORMAL)
	if(owner.health <= HEALTH_THRESHOLD_CRIT && COOLDOWN_FINISHED(src, survival_cooldown))
		overdrive()
	if(!COOLDOWN_FINISHED(src, battery_cooldown))
		return
	COOLDOWN_START(src, battery_cooldown, ANOMALOCK_BATTERY_INTERVAL)
	var/list/batteries = list()
	for(var/obj/item/stock_parts/cell/cell in owner.get_all_contents())
		if(cell.charge < cell.maxcharge)
			batteries += cell
	if(!length(batteries))
		return
	var/obj/item/stock_parts/cell/picked = pick(batteries)
	picked.give(picked.maxcharge * ANOMALOCK_BATTERY_FRACTION)

/obj/item/organ/internal/heart/cybernetic/anomalock/attack_self(mob/user)
	var/mob/living/carbon/human/human_user = user
	if(!core || !istype(human_user))
		return ..()
	human_user.balloon_alert(human_user, "будет больно...")
	to_chat(human_user, span_userdanger("Чёрные кибервены рвут кожу и тянут сердце в грудную клетку. Кажется, это плохая идея..."))
	if(!do_after(human_user, ANOMALOCK_SELF_IMPLANT_TIME, human_user))
		return
	var/obj/item/organ/internal/old_heart = human_user.get_organ_slot(INTERNAL_ORGAN_HEART)
	if(!human_user.temporarily_remove_item_from_inventory(src))
		return
	playsound(human_user, 'sound/weapons/slice.ogg', 100, TRUE)
	insert(human_user)
	old_heart?.forceMove(human_user.drop_location())
	human_user.apply_damage(ANOMALOCK_SELF_IMPLANT_DAMAGE, BRUTE, BODY_ZONE_CHEST)
	INVOKE_ASYNC(human_user, TYPE_PROC_REF(/mob, emote), "scream")

/obj/item/organ/internal/heart/cybernetic/anomalock/attackby(obj/item/item, mob/living/user, list/modifiers)
	var/obj/item/assembly/signaler/core/energetic/new_core = item
	if(!istype(new_core) || new_core.tier < ANOMALOCK_MIN_CORE_TIER)
		return ..()
	if(core)
		balloon_alert(user, "ядро уже стоит!")
		return ATTACK_CHAIN_BLOCKED_ALL
	if(!user.transfer_item_to_loc(new_core, src))
		return ATTACK_CHAIN_BLOCKED_ALL
	core = new_core
	balloon_alert(user, "ядро установлено")
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	update_icon(UPDATE_ICON_STATE)
	return ATTACK_CHAIN_BLOCKED_ALL

/obj/item/organ/internal/heart/cybernetic/anomalock/screwdriver_act(mob/user, obj/item/I)
	. = TRUE
	if(!core)
		balloon_alert(user, "ядра нет!")
		return
	balloon_alert(user, "извлечение ядра...")
	if(!I.use_tool(src, user, ANOMALOCK_CORE_REMOVAL_TIME, volume = I.tool_volume))
		return
	var/obj/item/assembly/signaler/core/energetic/removed_core = core
	removed_core.forceMove(drop_location())
	user.put_in_hands(removed_core)
	balloon_alert(user, "ядро извлечено")

/obj/item/organ/internal/heart/cybernetic/anomalock/proc/on_emp(datum/source, severity)
	SIGNAL_HANDLER
	show_lightning(ANOMALOCK_EMP_LIGHTNING_TIME)

/obj/item/organ/internal/heart/cybernetic/anomalock/proc/show_lightning(time_to_last)
	if(!lightning_overlay)
		lightning_overlay = mutable_appearance('icons/effects/anomalock_lightning.dmi', "lightning")
		owner.add_overlay(lightning_overlay)
	lightning_timer = addtimer(CALLBACK(src, PROC_REF(hide_lightning)), time_to_last, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

/obj/item/organ/internal/heart/cybernetic/anomalock/proc/hide_lightning()
	if(!lightning_overlay)
		return
	owner?.cut_overlay(lightning_overlay)
	lightning_overlay = null

/obj/item/organ/internal/heart/cybernetic/anomalock/proc/overdrive()
	COOLDOWN_START(src, survival_cooldown, ANOMALOCK_SURVIVAL_COOLDOWN)
	owner.apply_status_effect(/datum/status_effect/voltaic_overdrive)
	show_lightning(ANOMALOCK_OVERDRIVE_TIME)
	addtimer(CALLBACK(src, PROC_REF(notify_ready)), ANOMALOCK_SURVIVAL_COOLDOWN)

/obj/item/organ/internal/heart/cybernetic/anomalock/proc/notify_ready()
	if(!owner)
		return
	owner.balloon_alert(owner, "сердце снова крепнет")
	playsound(owner, 'sound/magic/lightning_chargeup.ogg', 40, TRUE)

/obj/item/organ/internal/heart/cybernetic/anomalock/prebuilt/Initialize(mapload)
	. = ..()
	core = new /obj/item/assembly/signaler/core/energetic/tier2(src)
	update_icon(UPDATE_ICON_STATE)

/datum/status_effect/voltaic_overdrive
	id = "voltaic_overdrive"
	duration = ANOMALOCK_OVERDRIVE_TIME
	alert_type = /atom/movable/screen/alert/status_effect/voltaic_overdrive

/datum/status_effect/voltaic_overdrive/on_apply()
	owner.add_traits(list(TRAIT_NOSOFTCRIT, TRAIT_NOHARDCRIT, TRAIT_NO_PAIN, TRAIT_IGNOREDAMAGESLOWDOWN), TRAIT_STATUS_EFFECT(id))
	owner.add_filter(ANOMALOCK_FILTER, 2, outline_filter(1, ANOMALOCK_OUTLINE_COLOR))
	to_chat(owner, span_userdanger("По мышцам разливается вольтаическая энергия! Сейчас или никогда!"))
	return TRUE

/datum/status_effect/voltaic_overdrive/tick(seconds_between_ticks)
	if(owner.health > HEALTH_THRESHOLD_CRIT)
		return
	owner.heal_overall_damage(ANOMALOCK_OVERDRIVE_HEAL, ANOMALOCK_OVERDRIVE_HEAL)
	owner.adjustOxyLoss(-ANOMALOCK_OVERDRIVE_HEAL)
	owner.adjustToxLoss(-ANOMALOCK_OVERDRIVE_HEAL)

/datum/status_effect/voltaic_overdrive/on_remove()
	owner.remove_traits(list(TRAIT_NOSOFTCRIT, TRAIT_NOHARDCRIT, TRAIT_NO_PAIN, TRAIT_IGNOREDAMAGESLOWDOWN), TRAIT_STATUS_EFFECT(id))
	owner.remove_filter(ANOMALOCK_FILTER)
	owner.balloon_alert(owner, "сердце слабеет")

/atom/movable/screen/alert/status_effect/voltaic_overdrive
	name = "Вольтаический разгон"
	desc = "Вольтаическая энергия держит тело на ногах. Через 30 секунд она иссякнет!"
	icon = 'icons/mob/anomalock_alert.dmi'
	icon_state = "anomalock_heart"

#undef SKELETON_HEALTH_BONUS

#undef OPTICS_ZOOM_DISTANCE
#undef OPTICS_FULLSCREEN
#undef OPTICS_SCAN_INTERVAL
#undef OPTICS_SCAN_RANGE
#undef OPTICS_MIN_TARGET_ALPHA

#undef BLOOD_PUMP_HEALTH_FRACTION
#undef BLOOD_PUMP_SYNTHFLESH_AMOUNT

#undef GORILLA_COMBO_STEP
#undef GORILLA_COMBO_MIN_SPEED
#undef GORILLA_COMBO_RESET_TIME
#undef GORILLA_KNOCKBACK_RANGE
#undef GORILLA_KNOCKBACK_SPEED
#undef GORILLA_WALL_SLAM_DAMAGE
#undef GORILLA_WALL_SLAM_KNOCKDOWN

#undef MONOWIRE_SHOCK_TIME

#undef SANDEVISTAN_FILTER
#undef SANDEVISTAN_STAMINA_MOD
#undef SANDEVISTAN_CLICK_MOD
#undef SANDEVISTAN_FULLSCREEN
#undef SANDEVISTAN_FLASH
#undef SANDEVISTAN_EMP_GLITCH_CHANCE
#undef SANDEVISTAN_HEAT_STRAIN
#undef SANDEVISTAN_HEAT_CRITICAL
#undef SANDEVISTAN_HEAT_LETHAL
#undef SANDEVISTAN_HEAT_MAX
#undef SANDEVISTAN_COOLING_TICK
#undef SANDEVISTAN_DASH_RANGE
#undef SANDEVISTAN_MELEE_DODGE_CHANCE
#undef SANDEVISTAN_ECHO_DELAY
#undef SANDEVISTAN_FINISHER_WINDOW
#undef SANDEVISTAN_FINISHER_KNOCKDOWN
#undef SANDEVISTAN_STRAIN_DAMAGE
#undef SANDEVISTAN_STRAIN_BLOOD_LOSS
#undef SANDEVISTAN_CRITICAL_TOX_DAMAGE
#undef SANDEVISTAN_CRITICAL_BRAIN_DAMAGE
#undef SANDEVISTAN_CRITICAL_BLEEDING_LIMBS
#undef SANDEVISTAN_CRITICAL_BLOOD_LOSS
#undef SANDEVISTAN_CRITICAL_CYANIDE
#undef SANDEVISTAN_LETHAL_BRAIN_DAMAGE
#undef SANDEVISTAN_LETHAL_TOX_DAMAGE
#undef SANDEVISTAN_LETHAL_BLOOD_LOSS
#undef SANDEVISTAN_LETHAL_OXY_DAMAGE

#undef BERSERKER_FILTER
#undef BERSERKER_OUTLINE_COLOR
#undef BERSERKER_ATTACK_SPEED
#undef BERSERKER_EMP_BRAIN_FRACTION

#undef BALLISTIC_PROCESSOR_RICOCHET_CHANCE
#undef BALLISTIC_PROCESSOR_RICOCHETS
#undef BALLISTIC_PROCESSOR_AIM_RANGE
#undef BALLISTIC_PROCESSOR_AIM_ANGLE

#undef HAND_CANNON_VOLLEY_DELAY

#undef ANOMALOCK_FILTER
#undef ANOMALOCK_OUTLINE_COLOR
#undef ANOMALOCK_OVERDRIVE_TIME
#undef ANOMALOCK_OVERDRIVE_HEAL
#undef ANOMALOCK_EMP_LIGHTNING_TIME
#undef ANOMALOCK_SURVIVAL_COOLDOWN
#undef ANOMALOCK_BLOOD_REGEN
#undef ANOMALOCK_BATTERY_INTERVAL
#undef ANOMALOCK_BATTERY_FRACTION
#undef ANOMALOCK_ZAP_RANGE
#undef ANOMALOCK_ZAP_POWER
#undef ANOMALOCK_ZAP_CUTOFF
#undef ANOMALOCK_SELF_IMPLANT_TIME
#undef ANOMALOCK_SELF_IMPLANT_DAMAGE
#undef ANOMALOCK_CORE_REMOVAL_TIME
#undef ANOMALOCK_MIN_CORE_TIER
