#define NEURO_BASE_LINKS 2
#define NEURO_BASE_RANGE 7
#define NEURO_MAX_RANGE 30
#define NEURO_SCAN_LIMIT 16
#define NEURO_SCAN_RADIUS 14
#define NEURO_SCAN_REFRESH (2 SECONDS)
#define NEURO_LOG_LIMIT 6
#define NEURO_REBOOT_TIME (20 SECONDS)
#define NEURO_DECK_INSTALL_TIME (2 SECONDS)
#define NEURO_BOT_HACK_TIME (5 SECONDS)
#define NEURO_BREACH_TIME (3 SECONDS)
#define NEURO_OVERLOAD_TIME (3 SECONDS)
#define NEURO_OVERLOAD_DEVASTATION -1
#define NEURO_OVERLOAD_HEAVY -1
#define NEURO_OVERLOAD_LIGHT 1
#define NEURO_OVERLOAD_FLASH 2
#define NEURO_SHOCK_SECONDS 30
#define NEURO_TURRET_DISABLE_TIME (20 SECONDS)
#define NEURO_CAMERA_CHECK_TIME (2 SECONDS)
#define NEURO_APC_CHANNEL_OFF 0
#define NEURO_APC_CHANNEL_AUTO 3

#define NEURO_COST_MINOR 5
#define NEURO_COST_LOW 10
#define NEURO_COST_MEDIUM 20
#define NEURO_COST_HIGH 30
#define NEURO_COST_EXTREME 45

#define NEURO_FEATURE_BOLTS (1<<0)
#define NEURO_FEATURE_FIREWALL (1<<1)
#define NEURO_FEATURE_SCANNER (1<<2)
#define NEURO_FEATURE_LIGHTS (1<<3)
#define NEURO_FEATURE_BOTS (1<<4)
#define NEURO_FEATURE_BREACH (1<<5)
#define NEURO_FEATURE_SECURITY (1<<6)

#define NEURO_KIND_DOOR "door"
#define NEURO_KIND_CONSOLE "console"
#define NEURO_KIND_FIRELOCK "firelock"
#define NEURO_KIND_APC "apc"
#define NEURO_KIND_AIR_ALARM "air_alarm"
#define NEURO_KIND_VENDING "vending"
#define NEURO_KIND_INTERCOM "intercom"
#define NEURO_KIND_LIGHT "light"
#define NEURO_KIND_BOT "bot"
#define NEURO_KIND_CAMERA "camera"
#define NEURO_KIND_WEAPON "weapon"
#define NEURO_KIND_TURRET "turret"
#define NEURO_KIND_FLASHER "flasher"
#define NEURO_KIND_BUTTON "button"

/obj/item/cyberdeck_module
	name = "cyberdeck module"
	desc = "Программно-аппаратный модуль для кибердека."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "module_booster"
	w_class = WEIGHT_CLASS_TINY
	abstract_type = /obj/item/cyberdeck_module
	var/link_bonus = 0
	var/range_bonus = 0
	var/buffer_bonus = 0
	var/regen_bonus = 0
	var/feature = NONE
	var/summary

/obj/item/cyberdeck_module/examine(mob/user)
	. = ..()
	. += span_notice("Эффект: [summary].")

/obj/item/cyberdeck_module/booster
	name = "signal booster module"
	desc = "Усилитель сигнала нейросвязи."
	origin_tech = "programming=4;magnets=4"
	range_bonus = 7
	summary = "дальность связи +7 м"

/obj/item/cyberdeck_module/booster/get_ru_names()
	return alist(
		NOMINATIVE = "модуль усилителя сигнала",
		GENITIVE = "модуля усилителя сигнала",
		DATIVE = "модулю усилителя сигнала",
		ACCUSATIVE = "модуль усилителя сигнала",
		INSTRUMENTAL = "модулем усилителя сигнала",
		PREPOSITIONAL = "модуле усилителя сигнала",
	)

/obj/item/cyberdeck_module/multiplexer
	name = "multiplexer module"
	desc = "Мультиплексор: разделяет нейроканал на несколько независимых потоков."
	icon_state = "module_multiplexer"
	origin_tech = "programming=5;materials=4"
	link_bonus = 3
	summary = "устройств на связи +3"

/obj/item/cyberdeck_module/multiplexer/get_ru_names()
	return alist(
		NOMINATIVE = "модуль мультиплексора",
		GENITIVE = "модуля мультиплексора",
		DATIVE = "модулю мультиплексора",
		ACCUSATIVE = "модуль мультиплексора",
		INSTRUMENTAL = "модулем мультиплексора",
		PREPOSITIONAL = "модуле мультиплексора",
	)

/obj/item/cyberdeck_module/airlock_driver
	name = "airlock driver module"
	desc = "Драйвер шлюзов: даёт прямой доступ к механизму засовов подключённых дверей."
	icon_state = "module_airlock"
	origin_tech = "programming=4;engineering=4"
	feature = NEURO_FEATURE_BOLTS
	summary = "управление засовами шлюзов"

/obj/item/cyberdeck_module/airlock_driver/get_ru_names()
	return alist(
		NOMINATIVE = "модуль драйвера шлюзов",
		GENITIVE = "модуля драйвера шлюзов",
		DATIVE = "модулю драйвера шлюзов",
		ACCUSATIVE = "модуль драйвера шлюзов",
		INSTRUMENTAL = "модулем драйвера шлюзов",
		PREPOSITIONAL = "модуле драйвера шлюзов",
	)

/obj/item/cyberdeck_module/firewall
	name = "firewall module"
	desc = "Нейрофильтр: гасит электромагнитные наводки, прежде чем они дойдут до коры мозга."
	icon_state = "module_firewall"
	origin_tech = "programming=5;combat=4"
	feature = NEURO_FEATURE_FIREWALL
	summary = "защита нейроинтерфейса от ЭМИ"

/obj/item/cyberdeck_module/firewall/get_ru_names()
	return alist(
		NOMINATIVE = "модуль нейрофильтра",
		GENITIVE = "модуля нейрофильтра",
		DATIVE = "модулю нейрофильтра",
		ACCUSATIVE = "модуль нейрофильтра",
		INSTRUMENTAL = "модулем нейрофильтра",
		PREPOSITIONAL = "модуле нейрофильтра",
	)

/obj/item/cyberdeck_module/scanner
	name = "network scanner module"
	desc = "Сканер сети: находит устройства в радиусе связи, в том числе за стенами."
	icon_state = "module_scanner"
	origin_tech = "programming=5;magnets=5"
	feature = NEURO_FEATURE_SCANNER
	summary = "список устройств рядом, подключение без прямой видимости"

/obj/item/cyberdeck_module/scanner/get_ru_names()
	return alist(
		NOMINATIVE = "модуль сканера сети",
		GENITIVE = "модуля сканера сети",
		DATIVE = "модулю сканера сети",
		ACCUSATIVE = "модуль сканера сети",
		INSTRUMENTAL = "модулем сканера сети",
		PREPOSITIONAL = "модуле сканера сети",
	)

/obj/item/cyberdeck_module/light_driver
	name = "light driver module"
	desc = "Драйвер освещения: позволяет подключать лампы и переключать каждую по отдельности."
	icon_state = "module_light"
	origin_tech = "programming=5;powerstorage=4"
	feature = NEURO_FEATURE_LIGHTS
	summary = "управление отдельными лампами"

/obj/item/cyberdeck_module/light_driver/get_ru_names()
	return alist(
		NOMINATIVE = "модуль драйвера освещения",
		GENITIVE = "модуля драйвера освещения",
		DATIVE = "модулю драйвера освещения",
		ACCUSATIVE = "модуль драйвера освещения",
		INSTRUMENTAL = "модулем драйвера освещения",
		PREPOSITIONAL = "модуле драйвера освещения",
	)

/obj/item/cyberdeck_module/bot_link
	name = "bot link module"
	desc = "Перехватчик управления: взламывает протоколы станционных ботов. Защищённых ботов Синдиката не берёт."
	icon_state = "module_bot"
	origin_tech = "programming=6;magnets=5"
	feature = NEURO_FEATURE_BOTS
	summary = "взлом и управление станционными ботами"

/obj/item/cyberdeck_module/bot_link/get_ru_names()
	return alist(
		NOMINATIVE = "модуль перехвата ботов",
		GENITIVE = "модуля перехвата ботов",
		DATIVE = "модулю перехвата ботов",
		ACCUSATIVE = "модуль перехвата ботов",
		INSTRUMENTAL = "модулем перехвата ботов",
		PREPOSITIONAL = "модуле перехвата ботов",
	)

/obj/item/cyberdeck_module/buffer
	name = "buffer module"
	desc = "Накопитель нейроканала: сложные команды тратят буфер кибердека, а этот модуль увеличивает его и ускоряет восстановление."
	icon_state = "module_buffer"
	origin_tech = "programming=5;powerstorage=5"
	buffer_bonus = 30
	regen_bonus = 1
	summary = "буфер +30, восстановление +1 в секунду"

/obj/item/cyberdeck_module/buffer/get_ru_names()
	return alist(
		NOMINATIVE = "модуль буфера",
		GENITIVE = "модуля буфера",
		DATIVE = "модулю буфера",
		ACCUSATIVE = "модуль буфера",
		INSTRUMENTAL = "модулем буфера",
		PREPOSITIONAL = "модуле буфера",
	)

/obj/item/cyberdeck_module/security
	name = "security driver module"
	desc = "Драйвер систем безопасности: подключает турели и вспышки. Команды проходят только при подходящем доступе."
	icon_state = "module_security"
	origin_tech = "programming=6;combat=5"
	feature = NEURO_FEATURE_SECURITY
	summary = "управление турелями и вспышками по доступу"

/obj/item/cyberdeck_module/security/get_ru_names()
	return alist(
		NOMINATIVE = "модуль драйвера безопасности",
		GENITIVE = "модуля драйвера безопасности",
		DATIVE = "модулю драйвера безопасности",
		ACCUSATIVE = "модуль драйвера безопасности",
		INSTRUMENTAL = "модулем драйвера безопасности",
		PREPOSITIONAL = "модуле драйвера безопасности",
	)

/obj/item/cyberdeck
	name = "cyberdeck"
	desc = "Вычислительный блок для нейроинтерфейса. Используйте в руке, чтобы подключить к своему нейропорту. Модули вставляются прямо в корпус, а извлекаются отвёрткой."
	icon = 'icons/obj/augments_extra.dmi'
	icon_state = "deck_standard"
	w_class = WEIGHT_CLASS_SMALL
	origin_tech = "programming=6;materials=6"
	var/built_in_features = NONE
	var/module_slots = 2
	var/link_bonus = 1
	var/range_bonus = 3
	var/buffer_capacity = 40
	var/buffer_regen = 1.5
	var/list/obj/item/cyberdeck_module/modules = list()

/obj/item/cyberdeck/get_ru_names()
	return alist(
		NOMINATIVE = "кибердек",
		GENITIVE = "кибердека",
		DATIVE = "кибердеку",
		ACCUSATIVE = "кибердек",
		INSTRUMENTAL = "кибердеком",
		PREPOSITIONAL = "кибердеке",
	)

/obj/item/cyberdeck/advanced
	name = "advanced cyberdeck"
	icon_state = "deck_advanced"
	origin_tech = "programming=6;materials=6;powerstorage=5"
	module_slots = 3
	link_bonus = 2
	range_bonus = 5
	buffer_capacity = 60
	buffer_regen = 2

/obj/item/cyberdeck/advanced/get_ru_names()
	return alist(
		NOMINATIVE = "продвинутый кибердек",
		GENITIVE = "продвинутого кибердека",
		DATIVE = "продвинутому кибердеку",
		ACCUSATIVE = "продвинутый кибердек",
		INSTRUMENTAL = "продвинутым кибердеком",
		PREPOSITIONAL = "продвинутом кибердеке",
	)

/obj/item/cyberdeck/elite
	name = "elite cyberdeck"
	icon_state = "deck_elite"
	origin_tech = "programming=7;materials=6;bluespace=5"
	module_slots = 5
	link_bonus = 3
	range_bonus = 7
	buffer_capacity = 90
	buffer_regen = 3

/obj/item/cyberdeck/elite/get_ru_names()
	return alist(
		NOMINATIVE = "элитный кибердек",
		GENITIVE = "элитного кибердека",
		DATIVE = "элитному кибердеку",
		ACCUSATIVE = "элитный кибердек",
		INSTRUMENTAL = "элитным кибердеком",
		PREPOSITIONAL = "элитном кибердеке",
	)

/obj/item/cyberdeck/syndicate
	name = "black cyberdeck"
	desc = "Кибердек без маркировки со встроенным взломщиком: вскрывает шлюзы и пускает по ним ток, снимает замки, гасит освещение отсеков, отключает турели и камеры, подглядывает через объективы, разряжает оружие на полу, срывает протоколы ботов, опрокидывает автоматы и перегружает те, что с едой и напитками."
	icon_state = "deck_syndicate"
	origin_tech = "programming=7;materials=6;syndicate=3"
	built_in_features = NEURO_FEATURE_BREACH
	module_slots = 4
	link_bonus = 3
	range_bonus = 7
	buffer_capacity = 100
	buffer_regen = 3.5

/obj/item/cyberdeck/syndicate/get_ru_names()
	return alist(
		NOMINATIVE = "чёрный кибердек",
		GENITIVE = "чёрного кибердека",
		DATIVE = "чёрному кибердеку",
		ACCUSATIVE = "чёрный кибердек",
		INSTRUMENTAL = "чёрным кибердеком",
		PREPOSITIONAL = "чёрном кибердеке",
	)

/obj/item/cyberdeck/Destroy()
	QDEL_LIST(modules)
	return ..()

/obj/item/cyberdeck/examine(mob/user)
	. = ..()
	. += span_notice("Занято слотов: [length(modules)] из [module_slots]. Устройств на связи: +[link_bonus], дальность: +[range_bonus] м. Буфер: [get_buffer_capacity()], восстановление: [get_buffer_regen()] в секунду.")
	for(var/obj/item/cyberdeck_module/module as anything in modules)
		. += span_notice("Установлен [module.declent_ru(NOMINATIVE)]: [module.summary].")

/obj/item/cyberdeck/attackby(obj/item/item, mob/user, params)
	if(!istype(item, /obj/item/cyberdeck_module))
		return ..()
	add_fingerprint(user)
	if(length(modules) >= module_slots)
		balloon_alert(user, "нет свободных слотов!")
		return ATTACK_CHAIN_PROCEED
	if(!user.drop_transfer_item_to_loc(item, src))
		return ..()
	modules += item
	balloon_alert(user, "модуль установлен")
	playsound(user, 'sound/machines/click.ogg', 50, TRUE)
	return ATTACK_CHAIN_BLOCKED_ALL

/obj/item/cyberdeck/screwdriver_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(!length(modules))
		balloon_alert(user, "модулей нет!")
		return
	if(!tool.use_tool(src, user, 0, volume = tool.tool_volume))
		return
	for(var/obj/item/cyberdeck_module/module as anything in modules.Copy())
		eject_module(module, user)
	balloon_alert(user, "модули извлечены")

/obj/item/cyberdeck/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/wearer = user
	var/obj/item/organ/internal/cyberimp/brain/neuro_interface/neuro = wearer.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEURO)
	if(!neuro)
		balloon_alert(user, "нет нейроинтерфейса!")
		return
	balloon_alert(user, "подключение к нейропорту...")
	if(!do_after(user, NEURO_DECK_INSTALL_TIME, user) || neuro.owner != user || loc != user)
		return
	neuro.install_deck(src)

/obj/item/cyberdeck/proc/get_buffer_capacity()
	. = buffer_capacity
	for(var/obj/item/cyberdeck_module/module as anything in modules)
		. += module.buffer_bonus

/obj/item/cyberdeck/proc/get_buffer_regen()
	. = buffer_regen
	for(var/obj/item/cyberdeck_module/module as anything in modules)
		. += module.regen_bonus

/obj/item/cyberdeck/proc/eject_module(obj/item/cyberdeck_module/module, mob/user)
	modules -= module
	module.forceMove(get_turf(user || src))
	user?.put_in_hands(module)

/obj/item/organ/internal/cyberimp/brain/neuro_interface
	name = "neuro-interface implant"
	desc = "Нейропорт, который связывает мозг с дверями и консолями по беспроводному каналу. Подключение идёт только в особом режиме и не мешает обычным действиям, а управление вынесено на отдельную панель. Кибердек добавляет новые типы устройств и буфер для сложных команд, а его модули расширяют возможности."
	implant_color = "#4FE3C1"
	slot = INTERNAL_ORGAN_BRAIN_NEURO
	origin_tech = "materials=4;programming=5;biotech=4;magnets=4"
	actions_types = list(
		/datum/action/item_action/organ_action/augment/neuro_panel,
		/datum/action/item_action/organ_action/augment/neuro_link,
	)
	var/obj/item/cyberdeck/deck
	var/list/atom/movable/linked_devices = list()
	// Цель взлома => list("start" = время начала, "end" = время конца), нужно для полосы прогресса на панели
	var/list/atom/movable/running_hacks = list()
	var/link_mode = FALSE
	var/list/image/link_markers = list()
	var/obj/machinery/camera/viewed_camera
	var/mob/living/net_operator
	var/buffer_charge = 0
	var/buffer_updated = 0
	var/list/event_log = list()
	var/list/cached_scan = list()
	var/static/list/food_vendor_types = list(
		/obj/machinery/vending/boozeomat,
		/obj/machinery/vending/chinese,
		/obj/machinery/vending/coffee,
		/obj/machinery/vending/cola,
		/obj/machinery/vending/snack,
		/obj/machinery/vending/sovietsoda,
		/obj/machinery/vending/sustenance,
	)
	var/static/list/all_kinds = list(
		NEURO_KIND_DOOR,
		NEURO_KIND_CONSOLE,
		NEURO_KIND_FIRELOCK,
		NEURO_KIND_BUTTON,
		NEURO_KIND_APC,
		NEURO_KIND_AIR_ALARM,
		NEURO_KIND_VENDING,
		NEURO_KIND_INTERCOM,
		NEURO_KIND_LIGHT,
		NEURO_KIND_BOT,
		NEURO_KIND_TURRET,
		NEURO_KIND_FLASHER,
		NEURO_KIND_CAMERA,
		NEURO_KIND_WEAPON,
	)
	COOLDOWN_DECLARE(scan_cooldown)

/datum/action/item_action/organ_action/augment/neuro_panel
	name = "Панель нейроинтерфейса"
	button_icon_state = "neuro_panel"

/datum/action/item_action/organ_action/augment/neuro_link
	name = "Режим подключения устройств"
	button_icon_state = "neuro_link"

/obj/item/organ/internal/cyberimp/brain/neuro_interface/get_ru_names()
	return alist(
		NOMINATIVE = "нейроинтерфейс",
		GENITIVE = "нейроинтерфейса",
		DATIVE = "нейроинтерфейсу",
		ACCUSATIVE = "нейроинтерфейс",
		INSTRUMENTAL = "нейроинтерфейсом",
		PREPOSITIONAL = "нейроинтерфейсе",
	)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/Destroy()
	SStgui.close_uis(src)
	clear_links()
	QDEL_NULL(deck)
	return ..()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	SStgui.close_uis(src)
	set_link_mode(FALSE)
	clear_links()
	return ..()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/emp_act(severity)
	if(has_feature(NEURO_FEATURE_FIREWALL))
		return
	. = ..()
	if(!.)
		return
	force_reboot()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/force_reboot()
	crit_fail = TRUE
	set_link_mode(FALSE)
	clear_links()
	reset_buffer()
	addtimer(CALLBACK(src, PROC_REF(reboot)), NEURO_REBOOT_TIME, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/reboot()
	crit_fail = FALSE
	if(owner)
		to_chat(owner, span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] завершает перезагрузку."))

/obj/item/organ/internal/cyberimp/brain/neuro_interface/ui_action_click(mob/user, datum/action/action, leftclick)
	if(crit_fail)
		notify_operator("нейропорт перезагружается!")
		return
	if(istype(action, /datum/action/item_action/organ_action/augment/neuro_link))
		set_link_mode(!link_mode)
		notify_operator(link_mode ? "режим подключения" : "режим подключения выключен")
		return
	var/datum/tgui/open_ui = SStgui.get_open_ui(user, src)
	if(open_ui)
		open_ui.close()
		return
	ui_interact(user)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/log_event(text, bad = FALSE)
	event_log += list(list("time" = station_time_timestamp("hh:mm"), "text" = text, "bad" = bad))
	if(length(event_log) > NEURO_LOG_LIMIT)
		event_log.Cut(1, 2)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/neuro_alert(text)
	notify_operator(text)
	log_event(text, bad = TRUE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/get_operator()
	return net_operator || owner

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/notify_operator(text)
	var/mob/living/operator = get_operator()
	operator.balloon_alert(operator, text)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/set_net_operator(mob/living/new_operator)
	stop_camera_view()
	SStgui.close_uis(src)
	var/mob/living/old_operator = get_operator()
	old_operator?.client?.images -= link_markers
	net_operator = new_operator
	refresh_markers()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/get_link_limit()
	. = NEURO_BASE_LINKS
	if(!deck)
		return
	. += deck.link_bonus
	for(var/obj/item/cyberdeck_module/module as anything in deck.modules)
		. += module.link_bonus

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/get_link_range()
	. = NEURO_BASE_RANGE
	if(deck)
		. += deck.range_bonus
		for(var/obj/item/cyberdeck_module/module as anything in deck.modules)
			. += module.range_bonus
	return min(., NEURO_MAX_RANGE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/has_feature(feature)
	if(!deck)
		return FALSE
	if(deck.built_in_features & feature)
		return TRUE
	for(var/obj/item/cyberdeck_module/module as anything in deck.modules)
		if(module.feature & feature)
			return TRUE
	return FALSE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/get_breach_buffer_bonus()
	if(!deck)
		return 0
	return has_feature(NEURO_FEATURE_BREACH) ? NET_BREACH_BUFFER_BLACK_DECK : NET_BREACH_BUFFER_DECK

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/has_black_deck()
	return has_feature(NEURO_FEATURE_BREACH)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/has_firewall()
	return has_feature(NEURO_FEATURE_FIREWALL)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/get_avatar_integrity_bonus()
	if(!deck)
		return 0
	return has_black_deck() ? NET_INTEGRITY_BLACK_DECK : NET_INTEGRITY_DECK

// Буфер восстанавливается лениво: заряд считается по прошедшему времени, поэтому имплант не висит в обработке
/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/get_buffer()
	if(!deck)
		return 0
	var/restored = (world.time - buffer_updated) / (1 SECONDS) * deck.get_buffer_regen()
	return min(buffer_charge + restored, deck.get_buffer_capacity())

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/spend_buffer(amount)
	buffer_charge = get_buffer() - amount
	buffer_updated = world.time

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/reset_buffer()
	buffer_charge = 0
	buffer_updated = world.time

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/get_device_kind(atom/thing)
	if(is_airlock(thing) || istype(thing, /obj/machinery/door/window))
		return NEURO_KIND_DOOR
	if(istype(thing, /obj/machinery/door/firedoor))
		return NEURO_KIND_FIRELOCK
	if(istype(thing, /obj/machinery/computer))
		return NEURO_KIND_CONSOLE
	if(isapc(thing))
		return NEURO_KIND_APC
	if(istype(thing, /obj/machinery/alarm))
		return NEURO_KIND_AIR_ALARM
	if(istype(thing, /obj/machinery/vending))
		return NEURO_KIND_VENDING
	if(istype(thing, /obj/item/radio/intercom))
		return NEURO_KIND_INTERCOM
	if(istype(thing, /obj/machinery/door_control))
		return NEURO_KIND_BUTTON
	if(istype(thing, /obj/machinery/light))
		return NEURO_KIND_LIGHT
	if(isbot(thing))
		return NEURO_KIND_BOT
	if(istype(thing, /obj/machinery/porta_turret))
		return NEURO_KIND_TURRET
	if(istype(thing, /obj/machinery/flasher))
		return NEURO_KIND_FLASHER
	if(istype(thing, /obj/machinery/camera))
		return NEURO_KIND_CAMERA
	if(isgun(thing))
		return NEURO_KIND_WEAPON
	return null

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/kind_available(kind)
	if(net_operator)
		return TRUE
	switch(kind)
		if(NEURO_KIND_DOOR, NEURO_KIND_CONSOLE)
			return TRUE
		if(NEURO_KIND_FIRELOCK, NEURO_KIND_APC, NEURO_KIND_AIR_ALARM, NEURO_KIND_VENDING, NEURO_KIND_INTERCOM, NEURO_KIND_BUTTON)
			return !!deck
		if(NEURO_KIND_LIGHT)
			return has_feature(NEURO_FEATURE_LIGHTS|NEURO_FEATURE_BREACH)
		if(NEURO_KIND_BOT)
			return has_feature(NEURO_FEATURE_BOTS)
		if(NEURO_KIND_CAMERA, NEURO_KIND_WEAPON)
			return has_feature(NEURO_FEATURE_BREACH)
		if(NEURO_KIND_TURRET, NEURO_KIND_FLASHER)
			return has_feature(NEURO_FEATURE_BREACH|NEURO_FEATURE_SECURITY)
	return FALSE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/in_signal_range(atom/device)
	var/turf/here = get_turf(get_operator())
	var/turf/there = get_turf(device)
	return !crit_fail && here && there && here.z == there.z && get_dist(here, there) <= get_link_range()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/can_remote_use(atom/device)
	return (device in linked_devices) && in_signal_range(device)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/bot_is_protected(mob/living/simple_animal/bot/bot)
	return ("syndicate" in bot.faction) || findtext("[bot.type]", "syndi") || bot.remote_disabled

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/link_device(atom/movable/device)
	if((device in linked_devices) || (device in running_hacks))
		return FALSE
	var/kind = get_device_kind(device)
	if(!kind)
		neuro_alert("устройство не поддерживается!")
		return FALSE
	if(!kind_available(kind))
		neuro_alert(deck ? "нужен другой модуль!" : "нужен кибердек!")
		return FALSE
	if(kind == NEURO_KIND_WEAPON && !isturf(device.loc))
		neuro_alert("оружие должно лежать на полу!")
		return FALSE
	if(kind == NEURO_KIND_TURRET)
		var/obj/machinery/porta_turret/turret = device
		if(!turret.emp_vulnerable)
			neuro_alert("защищённый протокол!")
			return FALSE
	if(length(linked_devices) >= get_link_limit())
		neuro_alert("все каналы заняты!")
		return FALSE
	if(!in_signal_range(device))
		neuro_alert("слишком далеко!")
		return FALSE
	if(!has_feature(NEURO_FEATURE_SCANNER) && !(device in view(get_link_range(), get_operator())))
		neuro_alert("нет прямой видимости!")
		return FALSE
	if(kind == NEURO_KIND_BOT)
		return start_bot_hack(device)
	add_link(device)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/add_link(atom/movable/device)
	linked_devices += device
	RegisterSignal(device, COMSIG_QDELETING, PROC_REF(on_device_deleted), override = TRUE)
	COOLDOWN_RESET(src, scan_cooldown)
	refresh_markers()
	log_event("Подключено: [DECLENT_RU_CAP(device, NOMINATIVE)]")
	var/mob/living/operator = get_operator()
	operator.playsound_local(get_turf(operator), 'sound/machines/twobeep.ogg', 40, FALSE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/start_hack(atom/movable/target, duration)
	running_hacks[target] = list("start" = world.time, "end" = world.time + duration)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/start_bot_hack(mob/living/simple_animal/bot/bot)
	if(bot_is_protected(bot))
		neuro_alert("защищённый протокол!")
		return FALSE
	start_hack(bot, NEURO_BOT_HACK_TIME)
	RegisterSignal(bot, COMSIG_QDELETING, PROC_REF(on_device_deleted), override = TRUE)
	notify_operator("взлом начат")
	addtimer(CALLBACK(src, PROC_REF(finish_bot_hack), bot), NEURO_BOT_HACK_TIME)
	return FALSE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/finish_bot_hack(mob/living/simple_animal/bot/bot)
	if(!(bot in running_hacks))
		return
	running_hacks -= bot
	if(!owner)
		UnregisterSignal(bot, COMSIG_QDELETING)
		return
	if(!in_signal_range(bot) || length(linked_devices) >= get_link_limit())
		UnregisterSignal(bot, COMSIG_QDELETING)
		neuro_alert("взлом сорван!")
		return
	add_misc_logs(owner, "Hacked [bot] with [src]")
	add_link(bot)
	notify_operator("бот взломан")

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/unlink_device(atom/movable/device)
	UnregisterSignal(device, COMSIG_QDELETING)
	linked_devices -= device
	running_hacks -= device
	if(device == viewed_camera)
		stop_camera_view()
	COOLDOWN_RESET(src, scan_cooldown)
	if(owner)
		refresh_markers()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/on_device_deleted(atom/movable/source)
	SIGNAL_HANDLER
	unlink_device(source)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/clear_links()
	for(var/atom/movable/device as anything in linked_devices + running_hacks)
		unlink_device(device)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/trim_links()
	for(var/atom/movable/device as anything in linked_devices.Copy())
		if(!kind_available(get_device_kind(device)))
			unlink_device(device)
	var/limit = get_link_limit()
	while(length(linked_devices) > limit)
		unlink_device(linked_devices[length(linked_devices)])

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/install_deck(obj/item/cyberdeck/new_deck)
	var/obj/item/cyberdeck/old_deck = deck
	if(!owner.drop_transfer_item_to_loc(new_deck, src))
		return FALSE
	deck = new_deck
	if(old_deck)
		old_deck.forceMove(get_turf(owner))
		owner.put_in_hands(old_deck)
	reset_buffer()
	trim_links()
	log_event("Кибердек подключён: [DECLENT_RU_CAP(new_deck, NOMINATIVE)]")
	owner.balloon_alert(owner, "кибердек подключён")
	owner.playsound_local(get_turf(owner), 'sound/machines/ping.ogg', 40, FALSE)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/eject_deck()
	if(!deck)
		return
	var/obj/item/cyberdeck/old_deck = deck
	deck = null
	old_deck.forceMove(get_turf(owner))
	owner.put_in_hands(old_deck)
	reset_buffer()
	trim_links()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/set_link_mode(new_state)
	if(link_mode == new_state)
		return
	link_mode = new_state
	if(link_mode)
		RegisterSignal(owner, COMSIG_MOB_CLICKON, PROC_REF(on_link_click))
	else
		UnregisterSignal(owner, COMSIG_MOB_CLICKON)
	refresh_markers()
	set_link_action_icon()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/set_link_action_icon()
	for(var/datum/action/item_action/organ_action/augment/neuro_link/action in actions)
		action.button_icon_state = link_mode ? "neuro_link_active" : "neuro_link"
		action.UpdateButtonIcon()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/refresh_markers()
	var/mob/living/operator = get_operator()
	operator.client?.images -= link_markers
	link_markers.Cut()
	if(!link_mode || !operator.client)
		return
	for(var/atom/movable/device as anything in linked_devices)
		var/image/marker = image('icons/hud/forensic_scan.dmi', device, "marker_active")
		SET_PLANE_EXPLICIT(marker, BALLOON_CHAT_PLANE, device)
		marker.appearance_flags = RESET_ALPHA|RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|PIXEL_SCALE
		marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		marker.color = implant_color
		link_markers += marker
	operator.client.images += link_markers

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/resolve_device(atom/target)
	if(get_device_kind(target))
		return target
	if(!isturf(target))
		return null
	for(var/atom/movable/thing as anything in target)
		if(get_device_kind(thing))
			return thing
	return null

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/on_link_click(datum/source, atom/target, list/modifiers)
	SIGNAL_HANDLER
	if(is_screen_atom(target) || LAZYACCESS(modifiers, SHIFT_CLICK))
		return NONE
	var/atom/movable/device = resolve_device(target)
	if(!device)
		owner.balloon_alert(owner, "это не устройство")
		return COMSIG_MOB_CANCEL_CLICKON
	if((device in linked_devices) || (device in running_hacks))
		unlink_device(device)
		device.balloon_alert(owner, "отключено")
		return COMSIG_MOB_CANCEL_CLICKON
	if(link_device(device))
		device.balloon_alert(owner, "подключено")
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_door(obj/machinery/door/door)
	if(door.operating || door.emagged || HAS_TRAIT(door, TRAIT_CMAGGED))
		neuro_alert("дверь не отвечает!")
		return FALSE
	if(is_airlock(door))
		var/obj/machinery/door/airlock/airlock = door
		if(!airlock.canAIControl())
			neuro_alert("нет связи с дверью!")
			return FALSE
		if(airlock.locked || airlock.welded)
			neuro_alert("дверь заблокирована!")
			return FALSE
	if(!door.allowed(owner))
		neuro_alert("нет доступа!")
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, do_animate), "deny")
		return FALSE
	door.add_hiddenprint(owner)
	if(door.density)
		door.open()
	else
		door.close()
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_firelock(obj/machinery/door/firedoor/firelock)
	if(firelock.operating || firelock.welded)
		neuro_alert("шлюз не отвечает!")
		return FALSE
	if(firelock.active_alarm && firelock.density && !has_feature(NEURO_FEATURE_BREACH))
		neuro_alert("сработала тревога!")
		return FALSE
	if(!firelock.allowed(owner))
		neuro_alert("нет доступа!")
		return FALSE
	if(firelock.density)
		firelock.open()
	else
		firelock.close()
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_bolts(obj/machinery/door/airlock/airlock)
	if(!airlock.canAIControl() || airlock.wires.is_cut(WIRE_DOOR_BOLTS))
		neuro_alert("нет связи с засовами!")
		return FALSE
	if(!airlock.allowed(owner))
		neuro_alert("нет доступа!")
		return FALSE
	if(airlock.locked)
		return airlock.unlock()
	if(!airlock.lock())
		return FALSE
	add_misc_logs(owner, "Bolted [airlock] with [src]")
	airlock.add_hiddenprint(owner)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_emergency_access(obj/machinery/door/airlock/airlock)
	if(!airlock.canAIControl())
		neuro_alert("нет связи с дверью!")
		return FALSE
	if(!airlock.allowed(owner))
		neuro_alert("нет доступа!")
		return FALSE
	airlock.emergency = !airlock.emergency
	airlock.update_icon()
	airlock.add_hiddenprint(owner)
	add_misc_logs(owner, "Set emergency access of [airlock] to [airlock.emergency] with [src]")
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/start_breach(obj/machinery/door/door)
	if(door in running_hacks)
		neuro_alert("взлом уже идёт!")
		return FALSE
	if(door.emagged || HAS_TRAIT(door, TRAIT_CMAGGED))
		neuro_alert("дверь не отвечает!")
		return FALSE
	if(is_airlock(door))
		var/obj/machinery/door/airlock/airlock = door
		if(airlock.welded)
			neuro_alert("дверь заварена!")
			return FALSE
	start_hack(door, NEURO_BREACH_TIME)
	notify_operator("взлом шлюза...")
	addtimer(CALLBACK(src, PROC_REF(finish_breach), door), NEURO_BREACH_TIME)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/finish_breach(obj/machinery/door/door)
	if(!(door in running_hacks))
		return
	running_hacks -= door
	if(QDELETED(door) || !owner || !can_remote_use(door))
		return
	add_misc_logs(owner, "Breached [door] with [src]")
	door.add_hiddenprint(owner)
	log_event("Шлюз вскрыт: [DECLENT_RU_CAP(door, NOMINATIVE)]")
	if(is_airlock(door))
		var/obj/machinery/door/airlock/airlock = door
		airlock.unlock(TRUE)
		airlock.open(TRUE)
		return
	var/obj/machinery/door/window/windoor = door
	windoor.open(TRUE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/electrify_door(obj/machinery/door/airlock/airlock)
	if(airlock.wires.is_cut(WIRE_ELECTRIFY) || !airlock.arePowerSystemsOn())
		neuro_alert("контур не отвечает!")
		return FALSE
	airlock.electrify(NEURO_SHOCK_SECONDS, owner)
	airlock.add_hiddenprint(owner)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/unelectrify_door(obj/machinery/door/airlock/airlock)
	if(airlock.wires.is_cut(WIRE_ELECTRIFY))
		neuro_alert("контур не отвечает!")
		return FALSE
	airlock.electrify(0, owner)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_door_safety(obj/machinery/door/airlock/airlock)
	if(airlock.wires.is_cut(WIRE_SAFETY) || airlock.wires.is_cut(WIRE_SPEED))
		neuro_alert("контур не отвечает!")
		return FALSE
	airlock.safe = !airlock.safe
	airlock.normalspeed = airlock.safe
	airlock.add_hiddenprint(owner)
	add_attack_logs(owner, airlock, "[airlock.safe ? "restored" : "disabled"] door safeties with [src]")
	return TRUE

// Команды АПЦ и датчику воздуха: мимо закрытого замка проходит только доступ владельца или встроенный взломщик
/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/can_command_interface(obj/machinery/machine, locked, ai_disabled)
	if(ai_disabled || (machine.stat & (NOPOWER|BROKEN)))
		neuro_alert("устройство не отвечает!")
		return FALSE
	if(locked && !machine.allowed(owner) && !has_feature(NEURO_FEATURE_BREACH))
		neuro_alert("нет доступа!")
		return FALSE
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_lock(obj/machinery/device)
	if(isapc(device))
		var/obj/machinery/power/apc/apc = device
		return apc.togglelock(owner)
	var/obj/machinery/alarm/alarm = device
	var/was_locked = alarm.locked
	alarm.togglelock(owner)
	return alarm.locked != was_locked

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/breach_lock(obj/machinery/device)
	add_misc_logs(owner, "Unlocked [device] with [src]")
	if(isapc(device))
		var/obj/machinery/power/apc/apc = device
		apc.locked = FALSE
		apc.update_icon()
		return TRUE
	var/obj/machinery/alarm/alarm = device
	alarm.locked = FALSE
	alarm.update_icon()
	SStgui.update_uis(alarm)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_area_lighting(obj/machinery/power/apc/apc)
	if(!can_command_interface(apc, apc.locked, apc.aidisabled))
		return FALSE
	apc.lighting_channel = apc.setsubsystem(apc.lighting_channel ? NEURO_APC_CHANNEL_OFF : NEURO_APC_CHANNEL_AUTO)
	apc.update()
	apc.update_icon()
	add_misc_logs(owner, "Set lighting channel of [apc] to [apc.lighting_channel] with [src]")
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_apc_breaker(obj/machinery/power/apc/apc)
	if(!can_command_interface(apc, apc.locked, apc.aidisabled))
		return FALSE
	apc.toggle_breaker(owner)
	add_misc_logs(owner, "Toggled breaker of [apc] with [src]")
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/overload_apc_lighting(obj/machinery/power/apc/apc)
	if(!apc.operating || apc.shorted || !apc.cell || (apc.stat & BROKEN))
		neuro_alert("устройство не отвечает!")
		return FALSE
	add_attack_logs(owner, apc, "overloaded lighting with [src]")
	INVOKE_ASYNC(apc, TYPE_PROC_REF(/obj/machinery/power/apc, overload_lighting))
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/set_alarm_mode(obj/machinery/alarm/alarm, new_mode)
	if(!can_command_interface(alarm, alarm.locked, alarm.aidisabled))
		return FALSE
	alarm.mode = new_mode
	alarm.apply_mode()
	alarm.update_icon()
	SStgui.update_uis(alarm)
	add_misc_logs(owner, "Set mode of [alarm] to [new_mode] with [src]")
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_vendor_contraband(obj/machinery/vending/vendor)
	vendor.extended_inventory = !vendor.extended_inventory
	SStgui.update_uis(vendor)
	add_misc_logs(owner, "Toggled hidden stock of [vendor] with [src]")
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/tilt_vendor(obj/machinery/vending/vendor)
	if(vendor.tilted || !vendor.tiltable || (vendor.resistance_flags & INDESTRUCTIBLE))
		neuro_alert("автомат не поддаётся!")
		return FALSE
	var/mob/living/victim = locate() in orange(1, vendor)
	add_attack_logs(owner, victim || vendor, "tilted [vendor] with [src]")
	vendor.tilt(victim, from_combat = TRUE)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/start_overload(obj/machinery/vending/vendor)
	if(vendor.stat & BROKEN)
		neuro_alert("автомат сломан!")
		return FALSE
	if(vendor in running_hacks)
		neuro_alert("перегрузка уже идёт!")
		return FALSE
	start_hack(vendor, NEURO_OVERLOAD_TIME)
	add_attack_logs(owner, vendor, "overloaded with [src]")
	do_sparks(3, TRUE, vendor)
	vendor.visible_message(span_warning("[DECLENT_RU_CAP(vendor, NOMINATIVE)] трещит и начинает дымиться!"))
	addtimer(CALLBACK(src, PROC_REF(finish_overload), vendor), NEURO_OVERLOAD_TIME)
	return TRUE

// Запал нельзя отменить отключением, а проверка поломки не даст взорвать один автомат дважды
/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/finish_overload(obj/machinery/vending/vendor)
	running_hacks -= vendor
	if(QDELETED(vendor) || (vendor.stat & BROKEN))
		return
	var/turf/epicenter = get_turf(vendor)
	vendor.obj_break(MELEE)
	explosion(epicenter, NEURO_OVERLOAD_DEVASTATION, NEURO_OVERLOAD_HEAVY, NEURO_OVERLOAD_LIGHT, NEURO_OVERLOAD_FLASH, cause = "neuro-interface overload")

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_light(obj/machinery/light/light)
	if(light.status != LIGHT_OK)
		neuro_alert("лампа неисправна!")
		return FALSE
	light.seton(!light.on)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_bot(mob/living/simple_animal/bot/bot)
	if(bot.on)
		bot.turn_off()
		return TRUE
	bot.turn_on()
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/call_bot(mob/living/simple_animal/bot/bot)
	bot.call_bot(owner, get_turf(get_operator()), FALSE)
	if(bot.calling_ai == owner)
		return TRUE
	neuro_alert("нет маршрута!")
	return FALSE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_bot_patrol(mob/living/simple_animal/bot/bot)
	bot.bot_reset()
	bot.auto_patrol = !bot.auto_patrol
	return TRUE

// Первый вызов emag_act только снимает блокировку, поэтому панель открываем вручную и срываем протоколы за один проход
/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/subvert_bot(mob/living/simple_animal/bot/bot)
	add_attack_logs(owner, bot, "subverted with [src]")
	var/was_open = bot.open
	bot.locked = FALSE
	bot.open = TRUE
	bot.emag_act(owner)
	bot.open = was_open
	unlink_device(bot)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_camera_view(obj/machinery/camera/camera)
	if(viewed_camera == camera)
		stop_camera_view()
		return TRUE
	if(!camera.can_use())
		neuro_alert("камера не работает!")
		return FALSE
	stop_camera_view()
	viewed_camera = camera
	var/mob/living/operator = get_operator()
	operator.reset_perspective(camera)
	RegisterSignal(operator, COMSIG_MOVABLE_MOVED, PROC_REF(on_viewer_moved))
	RegisterSignal(operator, COMSIG_MOB_STATCHANGE, PROC_REF(on_viewer_stat_change))
	addtimer(CALLBACK(src, PROC_REF(check_camera_view), camera), NEURO_CAMERA_CHECK_TIME)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/stop_camera_view()
	if(!viewed_camera)
		return
	viewed_camera = null
	var/mob/living/operator = get_operator()
	if(!operator)
		return
	UnregisterSignal(operator, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_STATCHANGE))
	operator.reset_perspective(null)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/check_camera_view(obj/machinery/camera/camera)
	if(viewed_camera != camera)
		return
	var/mob/living/operator = get_operator()
	if(QDELETED(camera) || !operator?.client || !camera.can_use() || !in_signal_range(camera) || operator.client.eye != camera)
		stop_camera_view()
		return
	addtimer(CALLBACK(src, PROC_REF(check_camera_view), camera), NEURO_CAMERA_CHECK_TIME)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/on_viewer_moved(datum/source)
	SIGNAL_HANDLER
	stop_camera_view()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/on_viewer_stat_change(datum/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat != CONSCIOUS)
		stop_camera_view()

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_camera_power(obj/machinery/camera/camera)
	add_misc_logs(owner, "Toggled [camera] with [src]")
	camera.toggle_cam(owner, displaymessage = FALSE)
	camera.add_hiddenprint(owner)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/disable_camera(obj/machinery/camera/camera)
	if(camera.wires.is_all_cut())
		neuro_alert("провода уже повреждены!")
		return FALSE
	add_misc_logs(owner, "Cut the wires of [camera] with [src]")
	camera.wires.cut_all()
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/sabotage_weapon(obj/item/gun/weapon)
	if(!isturf(weapon.loc))
		neuro_alert("оружие не на полу!")
		return FALSE
	if(isenergygun(weapon))
		add_misc_logs(owner, "Sabotaged [weapon] with [src]")
		var/obj/item/gun/energy/energy_weapon = weapon
		energy_weapon.cell?.use(energy_weapon.cell.charge)
		energy_weapon.update_icon()
		return TRUE
	if(!is_projectilegun(weapon))
		neuro_alert("оружие не поддаётся!")
		return FALSE
	add_misc_logs(owner, "Sabotaged [weapon] with [src]")
	var/obj/item/gun/projectile/ballistic = weapon
	if(ballistic.chambered)
		ballistic.chambered.forceMove(weapon.loc)
		ballistic.chambered = null
	if(istype(ballistic.magazine, /obj/item/ammo_box/magazine/internal))
		for(var/obj/item/ammo_casing/casing as anything in ballistic.magazine.stored_ammo)
			casing.forceMove(weapon.loc)
		ballistic.magazine.stored_ammo.Cut()
	else if(ballistic.magazine)
		ballistic.magazine.forceMove(weapon.loc)
		ballistic.magazine = null
	ballistic.update_icon()
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/toggle_turret(obj/machinery/porta_turret/turret)
	if(turret.HasController())
		neuro_alert("турель управляется с пульта!")
		return FALSE
	if(!turret.allowed(owner))
		neuro_alert("нет доступа!")
		return FALSE
	turret.enabled = !turret.enabled
	add_misc_logs(owner, "Set [turret] enabled to [turret.enabled] with [src]")
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/disable_turret(obj/machinery/porta_turret/turret)
	if(!turret.enabled)
		neuro_alert("турель уже отключена!")
		return FALSE
	add_attack_logs(owner, turret, "disabled with [src]")
	turret.enabled = FALSE
	addtimer(VARSET_CALLBACK(turret, enabled, TRUE), NEURO_TURRET_DISABLE_TIME, TIMER_DELETE_ME)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/scramble_turret(obj/machinery/porta_turret/turret)
	add_attack_logs(owner, turret, "scrambled with [src]")
	INVOKE_ASYNC(turret, TYPE_PROC_REF(/atom, emag_act), owner)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/fire_flasher(obj/machinery/flasher/flasher)
	if(!has_feature(NEURO_FEATURE_BREACH) && !(ACCESS_SECURITY in owner.get_access()))
		neuro_alert("нет доступа!")
		return FALSE
	if(flasher.disable || !flasher.powered())
		neuro_alert("вспышка не отвечает!")
		return FALSE
	if(!COOLDOWN_FINISHED(flasher, flash_cooldown))
		neuro_alert("вспышка заряжается!")
		return FALSE
	add_attack_logs(owner, flasher, "fired with [src]")
	flasher.flash()
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/press_button(obj/machinery/door_control/button)
	if(button.stat & (NOPOWER|BROKEN))
		neuro_alert("кнопка не отвечает!")
		return FALSE
	if(!button.allowed(owner))
		neuro_alert("нет доступа!")
		return FALSE
	button.attack_hand(owner)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/bypass_button(obj/machinery/door_control/button)
	if(button.stat & (NOPOWER|BROKEN))
		neuro_alert("кнопка не отвечает!")
		return FALSE
	if(!(button.device || button.constructed))
		button.build_device()
	if(!button.device)
		neuro_alert("кнопка не отвечает!")
		return FALSE
	add_misc_logs(owner, "Bypassed [button] with [src]")
	button.animate_activation()
	INVOKE_ASYNC(button.device, TYPE_PROC_REF(/obj/item/assembly, activate))
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/open_remote_ui(atom/movable/device)
	if(ismachinery(device))
		var/obj/machinery/machine = device
		if(machine.stat & (NOPOWER|BROKEN))
			neuro_alert("устройство отключено!")
			return FALSE
	var/mob/living/operator = get_operator()
	device.ui_interact(operator)
	if(!SStgui.get_open_ui(operator, device))
		device.attack_hand(operator)
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/ui_state(mob/user)
	return GLOB.conscious_state

/obj/item/organ/internal/cyberimp/brain/neuro_interface/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "NeuroInterface", DECLENT_RU_CAP(src, NOMINATIVE))
	if(ui.open())
		user.playsound_local(get_turf(user), 'sound/machines/terminal_on.ogg', 50, FALSE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/ui_close(mob/user)
	user.playsound_local(get_turf(user), 'sound/machines/terminal_off.ogg', 50, FALSE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/device_button(id, label, icon, cost = 0, danger = FALSE)
	return list(list("id" = id, "label" = label, "icon" = icon, "cost" = cost, "danger" = danger))

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/status_tag(text, tone)
	return list(list("text" = text, "tone" = tone))

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/device_tags(atom/movable/device, kind)
	. = list()
	switch(kind)
		if(NEURO_KIND_DOOR)
			var/obj/machinery/door/door = device
			. += status_tag(door.density ? "Закрыта" : "Открыта")
			if(is_airlock(door))
				var/obj/machinery/door/airlock/airlock = door
				if(airlock.locked)
					. += status_tag("Засов опущен", "warn")
				if(airlock.welded)
					. += status_tag("Заварена", "warn")
				if(airlock.emergency)
					. += status_tag("Аварийный доступ", "warn")
				if(airlock.isElectrified())
					. += status_tag("Под током", "bad")
				if(!airlock.safe)
					. += status_tag("Без защиты створок", "bad")
				if(!airlock.arePowerSystemsOn())
					. += status_tag("Нет питания", "bad")
		if(NEURO_KIND_FIRELOCK)
			var/obj/machinery/door/firedoor/firelock = device
			. += status_tag(firelock.density ? "Закрыт" : "Открыт")
			if(firelock.active_alarm)
				. += status_tag("Тревога", "bad")
		if(NEURO_KIND_APC)
			var/obj/machinery/power/apc/apc = device
			. += status_tag(apc.cell ? "Заряд [round(apc.cell.percent())]%" : "Нет батареи", apc.cell ? null : "bad")
			. += status_tag(apc.operating ? "Рубильник вкл" : "Рубильник выкл", apc.operating ? "good" : "bad")
			. += status_tag(apc.lighting_channel ? "Свет вкл" : "Свет выкл", apc.lighting_channel ? null : "warn")
			. += status_tag(apc.locked ? "Замок закрыт" : "Замок открыт", apc.locked ? null : "warn")
		if(NEURO_KIND_AIR_ALARM)
			var/obj/machinery/alarm/alarm = device
			var/turf/alarm_turf = get_turf(alarm)
			var/datum/gas_mixture/air = alarm_turf?.get_readonly_air()
			if(air)
				. += status_tag("[round(air.return_pressure())] кПа")
				. += status_tag("[round(air.temperature() - T0C)] °C")
			. += status_tag(alarm.danger_level ? "Опасно" : "Норма", alarm.danger_level ? "bad" : "good")
			if(alarm.mode == AALARM_MODE_PANIC)
				. += status_tag("Откачка", "bad")
			else if(alarm.mode == AALARM_MODE_OFF)
				. += status_tag("Вентиляция выкл", "bad")
			. += status_tag(alarm.locked ? "Замок закрыт" : "Замок открыт", alarm.locked ? null : "warn")
		if(NEURO_KIND_VENDING)
			var/obj/machinery/vending/vendor = device
			if(vendor.tilted)
				. += status_tag("Опрокинут", "warn")
			if(vendor.extended_inventory)
				. += status_tag("Скрытый ассортимент", "warn")
		if(NEURO_KIND_INTERCOM)
			var/obj/item/radio/intercom/intercom = device
			. += status_tag("[format_frequency(intercom.get_frequency())] кГц")
			. += status_tag(intercom.get_broadcasting() ? "Микрофон вкл" : "Микрофон выкл", intercom.get_broadcasting() ? "warn" : null)
			. += status_tag(intercom.get_listening() ? "Динамик вкл" : "Динамик выкл")
		if(NEURO_KIND_LIGHT)
			var/obj/machinery/light/light = device
			if(light.status == LIGHT_OK)
				. += status_tag(light.on ? "Горит" : "Выключена", light.on ? "good" : null)
			else
				. += status_tag("Неисправна", "bad")
		if(NEURO_KIND_BOT)
			var/mob/living/simple_animal/bot/bot = device
			. += status_tag(bot.on ? "Активен" : "Отключён", bot.on ? "good" : null)
			if(bot.on && bot.mode && bot.mode <= length(bot.mode_name))
				. += status_tag(bot.mode_name[bot.mode])
			if(bot.auto_patrol)
				. += status_tag("Патруль")
		if(NEURO_KIND_TURRET)
			var/obj/machinery/porta_turret/turret = device
			. += status_tag(turret.enabled ? "Включена" : "Отключена", turret.enabled ? "bad" : "good")
			if(turret.lethal)
				. += status_tag("Боевой режим", "bad")
			if(turret.emagged)
				. += status_tag("Распознавание сбито", "warn")
		if(NEURO_KIND_FLASHER)
			var/obj/machinery/flasher/flasher = device
			. += status_tag(COOLDOWN_FINISHED(flasher, flash_cooldown) ? "Готова" : "Заряжается", COOLDOWN_FINISHED(flasher, flash_cooldown) ? "good" : "warn")
		if(NEURO_KIND_CAMERA)
			var/obj/machinery/camera/camera = device
			. += status_tag(camera.can_use() ? "В сети" : "Не работает", camera.can_use() ? "good" : "bad")
			if(viewed_camera == camera)
				. += status_tag("Идёт просмотр", "warn")
		if(NEURO_KIND_WEAPON)
			. += status_tag(isturf(device.loc) ? "Лежит на полу" : "Вне досягаемости", isturf(device.loc) ? null : "bad")
	if(ismachinery(device))
		var/obj/machinery/machine = device
		if(machine.stat & (NOPOWER|BROKEN))
			. += status_tag("Отключено", "bad")
		else if(!length(.))
			. += status_tag("В сети", "good")
	else if(!length(.))
		. += status_tag("В сети", "good")

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/device_buttons(atom/movable/device, kind)
	. = list()
	var/breach = has_feature(NEURO_FEATURE_BREACH)
	switch(kind)
		if(NEURO_KIND_DOOR)
			var/obj/machinery/door/door = device
			var/obj/machinery/door/airlock/airlock = is_airlock(door) ? door : null
			. += device_button("door_toggle", door.density ? "Открыть" : "Закрыть", door.density ? "door-open" : "door-closed")
			if(airlock && has_feature(NEURO_FEATURE_BOLTS))
				. += device_button("door_bolts", airlock.locked ? "Поднять засов" : "Опустить засов", airlock.locked ? "unlock" : "lock", NEURO_COST_MINOR)
				. += device_button("door_emergency", airlock.emergency ? "Закрыть аварийный доступ" : "Аварийный доступ", "life-ring", NEURO_COST_MINOR)
			if(breach)
				. += device_button("door_breach", "Вскрыть", "bolt", NEURO_COST_HIGH, TRUE)
				if(airlock)
					if(airlock.isElectrified())
						. += device_button("door_unshock", "Снять ток", "plug")
					else
						. += device_button("door_shock", "Пустить ток", "bolt-lightning", NEURO_COST_HIGH, TRUE)
					. += device_button("door_safety", airlock.safe ? "Снять защиту створок" : "Вернуть защиту створок", "skull", NEURO_COST_MEDIUM, TRUE)
		if(NEURO_KIND_FIRELOCK)
			var/obj/machinery/door/firedoor/firelock = device
			. += device_button("firelock_toggle", firelock.density ? "Открыть" : "Закрыть", firelock.density ? "door-open" : "door-closed")
		if(NEURO_KIND_BUTTON)
			var/obj/machinery/door_control/button = device
			if(!button.open)
				. += device_button("button_press", "Нажать", "hand-pointer")
				if(breach)
					. += device_button("button_bypass", "Нажать в обход доступа", "bolt", NEURO_COST_MEDIUM, TRUE)
		if(NEURO_KIND_APC)
			var/obj/machinery/power/apc/apc = device
			. += device_button("open_ui", "Интерфейс", "terminal")
			. += device_button("lock_toggle", "Замок по доступу", "id-card")
			if(has_feature(NEURO_FEATURE_LIGHTS|NEURO_FEATURE_BREACH))
				. += device_button("apc_lighting", apc.lighting_channel ? "Погасить отсек" : "Зажечь отсек", "lightbulb", NEURO_COST_LOW)
			. += device_button("apc_breaker", apc.operating ? "Выключить рубильник" : "Включить рубильник", "power-off", NEURO_COST_LOW)
			if(breach)
				if(apc.locked)
					. += device_button("lock_breach", "Снять замок", "bolt", NEURO_COST_MEDIUM, TRUE)
				. += device_button("apc_overload", "Перегрузить освещение", "explosion", NEURO_COST_HIGH, TRUE)
		if(NEURO_KIND_AIR_ALARM)
			var/obj/machinery/alarm/alarm = device
			. += device_button("open_ui", "Интерфейс", "terminal")
			. += device_button("lock_toggle", "Замок по доступу", "id-card")
			if(alarm.mode != AALARM_MODE_FILTERING)
				. += device_button("alarm_filtering", "Обычный режим", "wind", NEURO_COST_MINOR)
			if(alarm.mode != AALARM_MODE_PANIC)
				. += device_button("alarm_panic", "Откачать воздух", "fan", NEURO_COST_LOW)
			if(breach)
				if(alarm.locked)
					. += device_button("lock_breach", "Снять замок", "bolt", NEURO_COST_MEDIUM, TRUE)
				if(alarm.mode != AALARM_MODE_OFF)
					. += device_button("alarm_off", "Отключить вентиляцию", "ban", NEURO_COST_MEDIUM, TRUE)
		if(NEURO_KIND_CONSOLE)
			. += device_button("open_ui", "Интерфейс", "terminal")
		if(NEURO_KIND_INTERCOM)
			var/obj/item/radio/intercom/intercom = device
			. += device_button("open_ui", "Интерфейс", "terminal")
			. += device_button("intercom_mic", intercom.get_broadcasting() ? "Выключить микрофон" : "Включить микрофон", "microphone")
			. += device_button("intercom_speaker", intercom.get_listening() ? "Выключить динамик" : "Включить динамик", "volume-high")
		if(NEURO_KIND_VENDING)
			var/obj/machinery/vending/vendor = device
			. += device_button("open_ui", "Интерфейс", "terminal")
			if(breach)
				. += device_button("vending_contraband", vendor.extended_inventory ? "Скрыть ассортимент" : "Открыть скрытый ассортимент", "box-open", NEURO_COST_MEDIUM, TRUE)
				if(!vendor.tilted)
					. += device_button("vending_tilt", "Опрокинуть", "arrow-down", NEURO_COST_HIGH, TRUE)
				if(is_type_in_list(vendor, food_vendor_types))
					. += device_button("vending_overload", "Перегрузить", "bomb", NEURO_COST_EXTREME, TRUE)
		if(NEURO_KIND_LIGHT)
			var/obj/machinery/light/light = device
			if(light.status == LIGHT_OK)
				. += device_button("light_toggle", light.on ? "Выключить" : "Включить", "lightbulb")
				if(light.on)
					. += device_button("light_flicker", "Заставить мигать", "wand-magic-sparkles", NEURO_COST_MINOR)
				if(breach)
					. += device_button("light_break", "Взорвать лампу", "burst", NEURO_COST_LOW, TRUE)
		if(NEURO_KIND_BOT)
			var/mob/living/simple_animal/bot/bot = device
			. += device_button("bot_toggle", bot.on ? "Отключить" : "Включить", "power-off")
			. += device_button("bot_call", "Вызвать к себе", "location-arrow", NEURO_COST_LOW)
			. += device_button("bot_patrol", bot.auto_patrol ? "Снять с патруля" : "Отправить в патруль", "route")
			if(breach && bot.emagged != 2)
				. += device_button("bot_subvert", "Сорвать протоколы", "skull-crossbones", NEURO_COST_EXTREME, TRUE)
		if(NEURO_KIND_TURRET)
			var/obj/machinery/porta_turret/turret = device
			if(has_feature(NEURO_FEATURE_SECURITY))
				. += device_button("turret_power", turret.enabled ? "Выключить" : "Включить", "power-off", NEURO_COST_LOW)
			if(breach)
				if(turret.enabled)
					. += device_button("turret_disable", "Вырубить на 20 секунд", "plug-circle-xmark", NEURO_COST_HIGH, TRUE)
				if(!turret.emagged)
					. += device_button("turret_scramble", "Сбить распознавание", "crosshairs", NEURO_COST_EXTREME, TRUE)
		if(NEURO_KIND_FLASHER)
			. += device_button("flasher_fire", "Вспышка", "sun", NEURO_COST_LOW, TRUE)
		if(NEURO_KIND_CAMERA)
			var/obj/machinery/camera/camera = device
			if(viewed_camera == camera)
				. += device_button("camera_view", "Закрыть обзор", "eye-slash")
			else
				. += device_button("camera_view", "Смотреть", "eye", NEURO_COST_LOW)
			if(!camera.wires.is_all_cut())
				. += device_button("camera_power", camera.status ? "Отключить" : "Включить", "power-off", NEURO_COST_MEDIUM, TRUE)
				. += device_button("camera_disable", "Перерезать провода", "video-slash", NEURO_COST_MEDIUM, TRUE)
		if(NEURO_KIND_WEAPON)
			. += device_button("weapon_sabotage", "Вывести из строя", "ban", NEURO_COST_MEDIUM, TRUE)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/device_data(atom/movable/device)
	var/kind = get_device_kind(device)
	return list(
		"uid" = device.UID(),
		"name" = DECLENT_RU_CAP(device, NOMINATIVE),
		"kind" = kind,
		"tags" = device_tags(device, kind),
		"distance" = max(get_dist(get_turf(get_operator()), device), 0),
		"reachable" = in_signal_range(device),
		"direction" = dir2rustext(get_dir(get_turf(get_operator()), device)),
		"buttons" = device_buttons(device, kind),
	)

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/nearby_devices()
	if(!has_feature(NEURO_FEATURE_SCANNER))
		return list()
	if(!COOLDOWN_FINISHED(src, scan_cooldown))
		return cached_scan
	COOLDOWN_START(src, scan_cooldown, NEURO_SCAN_REFRESH)
	cached_scan = list()
	var/static/list/hidden_kinds = list(NEURO_KIND_LIGHT, NEURO_KIND_CAMERA, NEURO_KIND_WEAPON)
	for(var/atom/movable/device in range(min(get_link_range(), NEURO_SCAN_RADIUS), get_turf(get_operator())))
		var/kind = get_device_kind(device)
		if(!kind || (kind in hidden_kinds) || !kind_available(kind) || (device in linked_devices))
			continue
		cached_scan += list(list(
			"uid" = device.UID(),
			"name" = DECLENT_RU_CAP(device, NOMINATIVE),
			"kind" = kind,
			"distance" = max(get_dist(get_turf(get_operator()), device), 0),
			"direction" = dir2rustext(get_dir(get_turf(get_operator()), device)),
		))
		if(length(cached_scan) >= NEURO_SCAN_LIMIT)
			break
	return cached_scan

/obj/item/organ/internal/cyberimp/brain/neuro_interface/ui_data(mob/user)
	var/list/devices = list()
	for(var/atom/movable/device as anything in linked_devices)
		devices += list(device_data(device))
	var/list/hacks = list()
	for(var/atom/movable/target as anything in running_hacks)
		var/list/timing = running_hacks[target]
		hacks += list(list(
			"uid" = target.UID(),
			"name" = DECLENT_RU_CAP(target, NOMINATIVE),
			"progress" = clamp((world.time - timing["start"]) / (timing["end"] - timing["start"]), 0, 1),
		))
	var/list/deck_data
	if(deck)
		var/list/module_data = list()
		for(var/obj/item/cyberdeck_module/module as anything in deck.modules)
			module_data += list(list(
				"uid" = module.UID(),
				"name" = DECLENT_RU_CAP(module, NOMINATIVE),
				"summary" = module.summary,
			))
		deck_data = list(
			"name" = DECLENT_RU_CAP(deck, NOMINATIVE),
			"black" = !!(deck.built_in_features & NEURO_FEATURE_BREACH),
			"slots" = deck.module_slots,
			"modules" = module_data,
		)
	var/list/kinds = list()
	for(var/kind in all_kinds)
		if(kind_available(kind))
			kinds += kind
	return list(
		"links_used" = length(linked_devices),
		"links_max" = get_link_limit(),
		"range" = get_link_range(),
		"link_mode" = link_mode,
		"rebooting" = crit_fail,
		"scanner" = has_feature(NEURO_FEATURE_SCANNER),
		"buffer" = round(get_buffer()),
		"buffer_max" = deck ? deck.get_buffer_capacity() : 0,
		"buffer_regen" = deck ? deck.get_buffer_regen() : 0,
		"deck" = deck_data,
		"kinds" = kinds,
		"devices" = devices,
		"hacks" = hacks,
		"nearby" = nearby_devices(),
		"log" = event_log,
	)

// Панель предлагает только то, что доступно прямо сейчас: сверка с кнопками не даёт поддельному запросу запустить чужое действие
/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/run_device_action(atom/movable/device, action_id)
	if(isnetavatar(net_operator))
		var/mob/living/basic/net_avatar/avatar = net_operator
		if(avatar.is_ice_blocked(get_area(device)))
			neuro_alert("узел закрыт льдом!")
			return FALSE
	var/list/chosen
	for(var/list/button as anything in device_buttons(device, get_device_kind(device)))
		if(button["id"] == action_id)
			chosen = button
			break
	if(!chosen)
		return FALSE
	if(chosen["cost"] > get_buffer())
		neuro_alert("мало буфера!")
		return FALSE
	var/device_name = DECLENT_RU_CAP(device, NOMINATIVE)
	if(!perform_device_action(device, action_id))
		return FALSE
	spend_buffer(chosen["cost"])
	log_event("[chosen["label"]]: [device_name]")
	return TRUE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/proc/perform_device_action(atom/movable/device, action_id)
	switch(action_id)
		if("door_toggle")
			return toggle_door(device)
		if("door_bolts")
			return toggle_bolts(device)
		if("door_emergency")
			return toggle_emergency_access(device)
		if("door_breach")
			return start_breach(device)
		if("door_shock")
			return electrify_door(device)
		if("door_unshock")
			return unelectrify_door(device)
		if("door_safety")
			return toggle_door_safety(device)
		if("firelock_toggle")
			return toggle_firelock(device)
		if("button_press")
			return press_button(device)
		if("button_bypass")
			return bypass_button(device)
		if("open_ui")
			return open_remote_ui(device)
		if("lock_toggle")
			return toggle_lock(device)
		if("lock_breach")
			return breach_lock(device)
		if("apc_lighting")
			return toggle_area_lighting(device)
		if("apc_breaker")
			return toggle_apc_breaker(device)
		if("apc_overload")
			return overload_apc_lighting(device)
		if("alarm_filtering")
			return set_alarm_mode(device, AALARM_MODE_FILTERING)
		if("alarm_panic")
			return set_alarm_mode(device, AALARM_MODE_PANIC)
		if("alarm_off")
			return set_alarm_mode(device, AALARM_MODE_OFF)
		if("intercom_mic")
			var/obj/item/radio/intercom/intercom = device
			intercom.set_broadcasting(!intercom.get_broadcasting())
			SStgui.update_uis(intercom)
			return TRUE
		if("intercom_speaker")
			var/obj/item/radio/intercom/intercom = device
			intercom.set_listening(!intercom.get_listening())
			SStgui.update_uis(intercom)
			return TRUE
		if("vending_contraband")
			return toggle_vendor_contraband(device)
		if("vending_tilt")
			return tilt_vendor(device)
		if("vending_overload")
			return start_overload(device)
		if("light_toggle")
			return toggle_light(device)
		if("light_flicker")
			var/obj/machinery/light/light = device
			return light.flicker()
		if("light_break")
			var/obj/machinery/light/light = device
			add_misc_logs(owner, "Blew [light] with [src]")
			light.break_light_tube(FALSE, TRUE)
			return TRUE
		if("bot_toggle")
			return toggle_bot(device)
		if("bot_call")
			return call_bot(device)
		if("bot_patrol")
			return toggle_bot_patrol(device)
		if("bot_subvert")
			return subvert_bot(device)
		if("turret_power")
			return toggle_turret(device)
		if("turret_disable")
			return disable_turret(device)
		if("turret_scramble")
			return scramble_turret(device)
		if("flasher_fire")
			return fire_flasher(device)
		if("camera_view")
			return toggle_camera_view(device)
		if("camera_power")
			return toggle_camera_power(device)
		if("camera_disable")
			return disable_camera(device)
		if("weapon_sabotage")
			return sabotage_weapon(device)
	return FALSE

/obj/item/organ/internal/cyberimp/brain/neuro_interface/ui_act(action, params)
	if(..() || crit_fail || !owner)
		return
	switch(action)
		if("toggle_link_mode")
			set_link_mode(!link_mode)
			return TRUE
		if("eject_deck")
			eject_deck()
			return TRUE
		if("eject_module")
			if(!deck)
				return
			var/obj/item/cyberdeck_module/module = locateUID(params["uid"])
			if(!(module in deck.modules))
				return
			deck.eject_module(module, owner)
			trim_links()
			return TRUE
	var/atom/movable/device = locateUID(params["uid"])
	if(!istype(device))
		return
	if(action == "link")
		link_device(device)
		return TRUE
	if(!(device in linked_devices))
		return
	if(action == "unlink")
		unlink_device(device)
		return TRUE
	if(action != "device_action")
		return
	if(!in_signal_range(device))
		neuro_alert("нет сигнала!")
		return TRUE
	run_device_action(device, params["id"])
	return TRUE

#undef NEURO_BASE_LINKS
#undef NEURO_BASE_RANGE
#undef NEURO_MAX_RANGE
#undef NEURO_SCAN_LIMIT
#undef NEURO_SCAN_RADIUS
#undef NEURO_SCAN_REFRESH
#undef NEURO_LOG_LIMIT
#undef NEURO_REBOOT_TIME
#undef NEURO_DECK_INSTALL_TIME
#undef NEURO_BOT_HACK_TIME
#undef NEURO_BREACH_TIME
#undef NEURO_OVERLOAD_TIME
#undef NEURO_OVERLOAD_DEVASTATION
#undef NEURO_OVERLOAD_HEAVY
#undef NEURO_OVERLOAD_LIGHT
#undef NEURO_OVERLOAD_FLASH
#undef NEURO_SHOCK_SECONDS
#undef NEURO_TURRET_DISABLE_TIME
#undef NEURO_CAMERA_CHECK_TIME
#undef NEURO_APC_CHANNEL_OFF
#undef NEURO_APC_CHANNEL_AUTO

#undef NEURO_COST_MINOR
#undef NEURO_COST_LOW
#undef NEURO_COST_MEDIUM
#undef NEURO_COST_HIGH
#undef NEURO_COST_EXTREME

#undef NEURO_FEATURE_BOLTS
#undef NEURO_FEATURE_FIREWALL
#undef NEURO_FEATURE_SCANNER
#undef NEURO_FEATURE_LIGHTS
#undef NEURO_FEATURE_BOTS
#undef NEURO_FEATURE_BREACH
#undef NEURO_FEATURE_SECURITY

#undef NEURO_KIND_DOOR
#undef NEURO_KIND_CONSOLE
#undef NEURO_KIND_FIRELOCK
#undef NEURO_KIND_APC
#undef NEURO_KIND_AIR_ALARM
#undef NEURO_KIND_VENDING
#undef NEURO_KIND_INTERCOM
#undef NEURO_KIND_LIGHT
#undef NEURO_KIND_BOT
#undef NEURO_KIND_CAMERA
#undef NEURO_KIND_WEAPON
#undef NEURO_KIND_TURRET
#undef NEURO_KIND_FLASHER
#undef NEURO_KIND_BUTTON
