/obj/item/organ/internal/cyberimp/brain/neuroadapter
	name = "neuroadapter implant"
	desc = "Стандартный нейроадаптер экипажа. Передаёт показатели носителя на консоли мониторинга и служит портом для чипов киберсовместимости."
	implant_color = "#FCEE0A"
	slot = INTERNAL_ORGAN_BRAIN_NEUROADAPTER
	cyber_cost = 0
	origin_tech = "materials=2;programming=3;biotech=2"
	actions_types = list(/datum/action/item_action/organ_action/neuroadapter_sensors)
	ignore_cybernetic_restrictions = TRUE
	var/sensor_mode = SUIT_SENSOR_OFF
	var/static/list/sensor_modes = list("Выключены", "Бинарный режим", "Мониторинг жизненных показателей", "Полный мониторинг")
	var/static/alist/sensor_messages = alist(
		SUIT_SENSOR_OFF = "Вы отключаете датчики нейроадаптера.",
		SUIT_SENSOR_BINARY = "Теперь нейроадаптер будет сообщать, живы вы или мертвы.",
		SUIT_SENSOR_VITAL = "Теперь нейроадаптер будет передавать ваши жизненные показатели.",
		SUIT_SENSOR_TRACKING = "Теперь нейроадаптер будет передавать ваши жизненные показатели и местоположение.",
	)

/datum/action/item_action/organ_action/neuroadapter_sensors
	name = "Датчики нейроадаптера"

/obj/item/organ/internal/cyberimp/brain/neuroadapter/get_ru_names()
	return alist(
		NOMINATIVE = "нейроадаптер",
		GENITIVE = "нейроадаптера",
		DATIVE = "нейроадаптеру",
		ACCUSATIVE = "нейроадаптер",
		INSTRUMENTAL = "нейроадаптером",
		PREPOSITIONAL = "нейроадаптере",
	)

/obj/item/organ/internal/cyberimp/brain/neuroadapter/Initialize(mapload)
	. = ..()
	sensor_mode = rand(SUIT_SENSOR_OFF, SUIT_SENSOR_TRACKING)

/obj/item/organ/internal/cyberimp/brain/neuroadapter/insert(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(.)
		target.update_suit_sensors()

/obj/item/organ/internal/cyberimp/brain/neuroadapter/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	target?.update_suit_sensors()

/obj/item/organ/internal/cyberimp/brain/neuroadapter/emp_act(severity)
	return

/obj/item/organ/internal/cyberimp/brain/neuroadapter/examine(mob/user)
	. = ..()
	. += span_notice("Датчики: [sensor_modes[sensor_mode + 1]].")

/obj/item/organ/internal/cyberimp/brain/neuroadapter/get_ripper_settings()
	. = ..()
	. += list(list(
		"id" = "sensors",
		"name" = "Режим датчиков",
		"kind" = "choice",
		"value" = sensor_modes[sensor_mode + 1],
		"options" = sensor_modes,
	))

/obj/item/organ/internal/cyberimp/brain/neuroadapter/set_ripper_setting(setting, value)
	if(setting != "sensors" || !(value in sensor_modes))
		return ..()
	sensor_mode = sensor_modes.Find(value) - 1
	owner?.update_suit_sensors()
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuroadapter/ui_action_click(mob/user, datum/action/action, leftclick)
	var/new_mode = tgui_input_list(owner, "Выберите режим работы датчиков:", "Датчики нейроадаптера", sensor_modes, sensor_modes[sensor_mode + 1])
	if(isnull(new_mode) || QDELETED(owner) || owner.incapacitated())
		return
	sensor_mode = sensor_modes.Find(new_mode) - 1
	to_chat(owner, span_notice(sensor_messages[sensor_mode]))
	owner.update_suit_sensors()

/obj/item/cyber_capacity_chip
	name = "cybercapacity chip"
	desc = "Чип расширения киберсовместимости. Вставляется в порт нейроадаптера и навсегда поднимает предел нагрузки имплантов."
	icon = 'icons/obj/module.dmi'
	icon_state = "circuit_chip"
	w_class = WEIGHT_CLASS_TINY
	origin_tech = "programming=6;biotech=5;materials=5"

/obj/item/cyber_capacity_chip/get_ru_names()
	return alist(
		NOMINATIVE = "чип киберсовместимости",
		GENITIVE = "чипа киберсовместимости",
		DATIVE = "чипу киберсовместимости",
		ACCUSATIVE = "чип киберсовместимости",
		INSTRUMENTAL = "чипом киберсовместимости",
		PREPOSITIONAL = "чипе киберсовместимости",
	)

/obj/item/cyber_capacity_chip/examine(mob/user)
	. = ..()
	. += span_notice("Увеличивает киберсовместимость на [CYBER_CAPACITY_CHIP_BONUS], но не выше [CYBER_CAPACITY_MAX].")

/obj/item/cyber_capacity_chip/attack_self(mob/user)
	. = ..()
	if(. || !iscarbon(user))
		return
	var/mob/living/carbon/carbon_user = user
	if(!carbon_user.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEUROADAPTER))
		balloon_alert(user, "нет нейроадаптера!")
		return
	if(carbon_user.cyber_capacity >= CYBER_CAPACITY_MAX)
		balloon_alert(user, "предел совместимости!")
		return
	carbon_user.adjust_cyber_capacity(CYBER_CAPACITY_CHIP_BONUS)
	playsound(user, 'sound/machines/terminal_insert_disc.ogg', 50, TRUE)
	to_chat(user, span_notice("Вы вставляете [declent_ru(ACCUSATIVE)] в порт нейроадаптера. Киберсовместимость: [carbon_user.cyber_capacity]/[CYBER_CAPACITY_MAX]."))
	qdel(src)
