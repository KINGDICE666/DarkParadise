/obj/item/organ/internal/cyberimp/arm
	name = "arm-mounted implant"
	desc = "Вы не должны это видеть! Сообщите администрации и создайте отчёт об ошибке."
	parent_organ_zone = BODY_ZONE_R_ARM
	slot = INTERNAL_ORGAN_R_ARM_DEVICE
	cyber_cost = 15
	icon_state = "implant-toolkit"
	w_class = WEIGHT_CLASS_NORMAL
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	abstract_type = /obj/item/organ/internal/cyberimp/arm
	/// A ref for the arm we're taking up. Mostly for the unregister signal upon removal
	var/obj/hand
	/// Used to store a list of all items inside, for multi-item implants.
	var/list/items_list = list()// I would use contents, but they shuffle on every activation/deactivation leading to interface inconsistencies.
	/// You can use this var for item path, it would be converted into an item on New().
	var/obj/item/active_item
	var/sound_on = 'sound/mecha/mechmove03.ogg'
	var/sound_off = 'sound/mecha/mechmove03.ogg'
	var/silent = FALSE

/obj/item/organ/internal/cyberimp/arm/get_ru_names()
	return alist(
		NOMINATIVE = "имплант руки",
		GENITIVE = "импланта руки",
		DATIVE = "импланту руки",
		ACCUSATIVE = "имплант руки",
		INSTRUMENTAL = "имплантом руки",
		PREPOSITIONAL = "импланте руки",
	)

/obj/item/organ/internal/cyberimp/arm/Initialize(mapload)
	. = ..()
	if(ispath(active_item))
		active_item = new active_item(src)

	update_transform()
	slot = parent_organ_zone + "_device"
	items_list = contents.Copy()

/obj/item/organ/internal/cyberimp/arm/Destroy()
	QDEL_NULL(active_item)
	QDEL_LIST(items_list)
	hand = null
	return ..()

/obj/item/organ/internal/cyberimp/arm/proc/update_transform()
	if(parent_organ_zone == BODY_ZONE_R_ARM)
		transform = null
	else // Mirroring the icon
		transform = matrix(-1, 0, 0, 0, 1, 0)

/obj/item/organ/internal/cyberimp/arm/examine(mob/user)
	. = ..()
	. += span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] собран для установки в [parent_organ_zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку.")
	. += span_notice("Его можно пересобрать отвёрткой.")

/obj/item/organ/internal/cyberimp/arm/screwdriver_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(parent_organ_zone == BODY_ZONE_R_ARM)
		parent_organ_zone = BODY_ZONE_L_ARM
	else
		parent_organ_zone = BODY_ZONE_R_ARM
	slot = parent_organ_zone + "_device"
	to_chat(user, span_notice("Вы перенастраиваете [declent_ru(ACCUSATIVE)] для установки в [parent_organ_zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку."))
	update_transform()

/obj/item/organ/internal/cyberimp/arm/get_ripper_settings()
	. = ..()
	. += list(list(
		"id" = "side",
		"name" = "Рука установки",
		"kind" = "choice",
		"value" = parent_organ_zone == BODY_ZONE_R_ARM ? "Правая" : "Левая",
		"options" = list("Правая", "Левая"),
	))
	. += list(list("id" = "silent", "name" = "Бесшумный режим", "kind" = "toggle", "value" = silent))

/obj/item/organ/internal/cyberimp/arm/set_ripper_setting(setting, value)
	switch(setting)
		if("silent")
			silent = !!value
			return TRUE
		if("side")
			var/new_zone = value == "Правая" ? BODY_ZONE_R_ARM : BODY_ZONE_L_ARM
			if(new_zone == parent_organ_zone)
				return FALSE
			var/mob/living/carbon/patient = owner
			if(patient)
				if(!patient.get_organ(new_zone) || patient.get_organ_slot(new_zone + "_device"))
					return FALSE
				remove(patient, ORGAN_MANIPULATION_NOEFFECT)
			parent_organ_zone = new_zone
			slot = parent_organ_zone + "_device"
			update_transform()
			if(patient)
				insert(patient, ORGAN_MANIPULATION_NOEFFECT)
			return TRUE
	return ..()

/obj/item/organ/internal/cyberimp/arm/insert(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	var/side = parent_organ_zone == BODY_ZONE_R_ARM ? BODY_ZONE_R_ARM : BODY_ZONE_L_ARM
	hand = owner.bodyparts_by_name[side]
	if(hand)
		RegisterSignal(hand, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_item_attack_self)) //If the limb gets an attack-self, open the menu. Only happens when hand is empty
		RegisterSignal(arm_owner, COMSIG_MOB_KEY_DROP_ITEM_DOWN, PROC_REF(dropkey)) //We're nodrop, but we'll watch for the drop hotkey anyway and then stow if possible.

/obj/item/organ/internal/cyberimp/arm/remove(mob/living/carbon/arm_owner, special = ORGAN_MANIPULATION_DEFAULT)
	Retract()
	if(hand)
		UnregisterSignal(hand, COMSIG_ITEM_ATTACK_SELF)
		UnregisterSignal(arm_owner, COMSIG_MOB_KEY_DROP_ITEM_DOWN)
	. = ..()

/obj/item/organ/internal/cyberimp/arm/proc/on_item_attack_self()
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(ui_action_click))

/obj/item/organ/internal/cyberimp/arm/emag_act()
	return 0

/obj/item/organ/internal/cyberimp/arm/emp_act(severity)
	if(emp_proof)
		return
	if(emp_shielded(severity))
		return
	if(prob(15/severity) && owner)
		to_chat(owner, span_warning("[declent_ru(NOMINATIVE)] поражён ЭМИ импульсом!"))
		// give the owner an idea about why his implant is glitching
		Retract()
	..()

/**
 * Called when the mob uses the "drop item" hotkey
 *
 * Items inside toolset implants have TRAIT_NODROP, but we can still use the drop item hotkey as a
 * quick way to store implant items. In this case, we check to make sure the user has the correct arm
 * selected, and that the item is actually owned by us, and then we'll hand off the rest to Retract()
**/
/obj/item/organ/internal/cyberimp/arm/proc/dropkey(mob/living/carbon/host)
	SIGNAL_HANDLER
	if(!host)
		return //How did we even get here
	var/obj/current_hand = host.hand ? host.get_organ(BODY_ZONE_L_ARM) : host.get_organ(BODY_ZONE_R_ARM)
	if(hand != current_hand)
		return //wrong hand
	// We should not react to the item when it's not in our hand,
	// it makes no sense and other items with something like TRAIT_NODROP might fuck us very badly
	if(!active_item || active_item != host.get_active_hand())
		return
	if(Retract())
		return COMPONENT_CANCEL_DROP

/obj/item/organ/internal/cyberimp/arm/proc/Retract()
	if(!active_item || (active_item in src))
		return FALSE

	owner.visible_message(span_notice("[owner] убира[PLUR_ET_YUT(owner)] [active_item.declent_ru(ACCUSATIVE)] обратно в [parent_organ_zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку."),
		span_notice("[DECLENT_RU_CAP(active_item, NOMINATIVE)] втягивается в вашу [parent_organ_zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку."),
		silent ? null : span_italics("Слышен короткий механический щелчок."))

	owner.drop_item_ground(active_item, force = TRUE, silent = TRUE)
	active_item.forceMove(src)
	active_item = null
	if(!silent)
		playsound(get_turf(owner), sound_off, 50, TRUE)
	return TRUE

/obj/item/organ/internal/cyberimp/arm/proc/Extend(obj/item/augment)
	if(!(augment in src))
		return

	active_item = augment

	ADD_TRAIT(active_item, TRAIT_NODROP, AUGMENT_TRAIT)
	active_item.resistance_flags = INDESTRUCTIBLE|LAVA_PROOF|FIRE_PROOF|UNACIDABLE|ACID_PROOF
	active_item.slot_flags = NONE
	active_item.w_class = WEIGHT_CLASS_HUGE
	active_item.materials = null

	var/arm_slot = (parent_organ_zone == BODY_ZONE_R_ARM ? ITEM_SLOT_HAND_RIGHT : ITEM_SLOT_HAND_LEFT)
	var/obj/item/arm_item = owner.get_item_by_slot(arm_slot)

	if(arm_item)
		if(!owner.drop_item_ground(arm_item))
			to_chat(owner, span_warning("[DECLENT_RU_CAP(arm_item, NOMINATIVE)] мешает [declent_ru(DATIVE)]!"))
			return
		else
			to_chat(owner, span_notice("Вы бросаете [arm_item.declent_ru(ACCUSATIVE)], чтобы активировать [declent_ru(ACCUSATIVE)]!"))

	if(parent_organ_zone == BODY_ZONE_R_ARM ? !owner.put_in_r_hand(active_item, silent = TRUE) : !owner.put_in_l_hand(active_item, silent = TRUE))
		to_chat(owner, span_warning("[DECLENT_RU_CAP(src, NOMINATIVE)] не срабатывает!"))
		return

	// Activate the hand that now holds our item.
	if(parent_organ_zone == BODY_ZONE_R_ARM ? owner.hand : !owner.hand)
		owner.swap_hand()

	owner.visible_message(span_notice("[owner] выдвига[PLUR_ET_YUT(owner)] [active_item.declent_ru(ACCUSATIVE)] из [parent_organ_zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки."),
		span_notice("Вы выдвигаете [active_item.declent_ru(ACCUSATIVE)] из [parent_organ_zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки."),
		silent ? null : span_italics("Слышен короткий механический звук."))
	if(!silent)
		playsound(get_turf(owner), sound_on, 50, TRUE)

/obj/item/organ/internal/cyberimp/arm/ui_action_click(mob/user, datum/action/action, leftclick)
	if(crit_fail || (!active_item && !length(contents)))
		to_chat(owner, span_warning("Имплант не отвечает. Похоже, он сломан..."))
		return

	// You can emag the arm-mounted implant by activating it while holding emag in it's hand.
	var/arm_slot = (parent_organ_zone == BODY_ZONE_R_ARM ? ITEM_SLOT_HAND_RIGHT : ITEM_SLOT_HAND_LEFT)
	if(istype(owner.get_item_by_slot(arm_slot), /obj/item/card/emag) && emag_act(owner))
		return

	if(!active_item || (active_item in src))
		active_item = null
		if(length(contents) == 1)
			Extend(contents[1])
		else
			radial_menu(owner)
	else
		Retract()

/obj/item/organ/internal/cyberimp/arm/proc/check_menu(mob/user)
	return (owner && owner == user && owner.stat != DEAD && (src in owner.internal_organs) && !active_item)

/obj/item/organ/internal/cyberimp/arm/proc/radial_menu(mob/user)
	var/list/choices = list()
	for(var/obj/I in items_list)
		choices["[I.name]"] = image(icon = I.icon, icon_state = I.icon_state)
	var/choice = show_radial_menu(owner, owner, choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user))
	if(!check_menu(user))
		return
	var/obj/item/selected
	for(var/obj/item in items_list)
		if(item.name == choice)
			selected = item
			break
	if(istype(selected) && (selected in contents))
		Extend(selected)

/obj/item/organ/internal/cyberimp/arm/gun/emp_act(severity)
	if(emp_proof)
		return
	if(emp_shielded(severity))
		return
	if(prob(30/severity) && owner && !crit_fail)
		Retract()
		owner.visible_message(span_danger("Из [parent_organ_zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки [owner.declent_ru(GENITIVE)] раздаётся громкий хлопок!"))
		playsound(get_turf(owner), 'sound/weapons/flashbang.ogg', 100, TRUE)
		to_chat(owner, span_userdanger("Внутри вашей [parent_organ_zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки что-то взрывается, имплант выходит из строя!"))
		owner.adjust_fire_stacks(20)
		owner.IgniteMob()
		owner.adjustFireLoss(25)
		crit_fail = 1
	else // The gun will still discharge anyway.
		..()

/obj/item/organ/internal/cyberimp/arm/gun/laser
	name = "arm-mounted laser implant"
	cyber_cost = 30
	desc = "Вариант ручной пушки, стреляющий смертоносными лазерными лучами. Ствол выдвигается из руки и прячется обратно, когда не нужен."
	icon_state = "arm_laser"
	origin_tech = "materials=4;combat=4;biotech=4;powerstorage=4"
	contents = newlist(/obj/item/gun/energy/laser/mounted)

/obj/item/organ/internal/cyberimp/arm/gun/laser/get_ru_names()
	return alist(
		NOMINATIVE = "имплант ручного лазера",
		GENITIVE = "импланта ручного лазера",
		DATIVE = "импланту ручного лазера",
		ACCUSATIVE = "имплант ручного лазера",
		INSTRUMENTAL = "имплантом ручного лазера",
		PREPOSITIONAL = "импланте ручного лазера",
	)

/obj/item/organ/internal/cyberimp/arm/gun/laser/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/gun/taser
	name = "arm-mounted taser implant"
	cyber_cost = 22
	desc = "Вариант ручной пушки, стреляющий электродами и зарядами дизейблера. Ствол выдвигается из руки и прячется обратно, когда не нужен."
	icon_state = "arm_taser"
	origin_tech = "materials=5;combat=5;biotech=4;powerstorage=4"
	contents = newlist(/obj/item/gun/energy/gun/advtaser/mounted)

/obj/item/organ/internal/cyberimp/arm/gun/taser/get_ru_names()
	return alist(
		NOMINATIVE = "имплант ручного тазера",
		GENITIVE = "импланта ручного тазера",
		DATIVE = "импланту ручного тазера",
		ACCUSATIVE = "имплант ручного тазера",
		INSTRUMENTAL = "имплантом ручного тазера",
		PREPOSITIONAL = "импланте ручного тазера",
	)

/obj/item/organ/internal/cyberimp/arm/gun/taser/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/toolset
	name = "integrated toolset implant"
	desc = "Урезанная версия инженерного набора киборга, встраиваемая в руку. Содержит все необходимые инструменты."
	origin_tech = "materials=3;engineering=4;biotech=3;powerstorage=4"
	contents = newlist(/obj/item/screwdriver/cyborg, /obj/item/wrench/cyborg, /obj/item/weldingtool/largetank/cyborg,
		/obj/item/crowbar/cyborg, /obj/item/wirecutters/cyborg, /obj/item/multitool/cyborg)
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/clothing/belts.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "utilitybelt")

/obj/item/organ/internal/cyberimp/arm/toolset/get_ru_names()
	return alist(
		NOMINATIVE = "имплант встроенных инструментов",
		GENITIVE = "импланта встроенных инструментов",
		DATIVE = "импланту встроенных инструментов",
		ACCUSATIVE = "имплант встроенных инструментов",
		INSTRUMENTAL = "имплантом встроенных инструментов",
		PREPOSITIONAL = "импланте встроенных инструментов",
	)

/obj/item/organ/internal/cyberimp/arm/toolset/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/toolset/emag_act(mob/user)
	if(!(locate(/obj/item/kitchen/knife/combat/cyborg) in items_list))
		if(user)
			to_chat(user, span_notice("Вы разблокируете встроенный нож [declent_ru(GENITIVE)]!"))
		items_list += new /obj/item/kitchen/knife/combat/cyborg(src)
		return TRUE
	return FALSE

/obj/item/organ/internal/cyberimp/arm/atmostoolset
	name = "integrated atmos toolset implant"
	desc = "Урезанная версия инженерного набора киборга, встраиваемая в руку. Содержит все инструменты, нужные атмосферному технику."
	icon_state = "atmos_arm_implant"
	origin_tech = "materials=3;engineering=4;biotech=3;powerstorage=4"
	contents = newlist(/obj/item/holosign_creator/atmos, /obj/item/rpd, /obj/item/analyzer, /obj/item/destTagger, /obj/item/extinguisher/mini,
		/obj/item/pipe_painter, /obj/item/wrench/cyborg, /obj/item/weldingtool/largetank/cyborg)
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/tools.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "rpd")

/obj/item/organ/internal/cyberimp/arm/atmostoolset/get_ru_names()
	return alist(
		NOMINATIVE = "имплант атмосферных инструментов",
		GENITIVE = "импланта атмосферных инструментов",
		DATIVE = "импланту атмосферных инструментов",
		ACCUSATIVE = "имплант атмосферных инструментов",
		INSTRUMENTAL = "имплантом атмосферных инструментов",
		PREPOSITIONAL = "импланте атмосферных инструментов",
	)

/obj/item/organ/internal/cyberimp/arm/atmostoolset/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/hacking
	name = "hacking arm implant"
	cyber_cost = 18
	desc = "Небольшой имплант руки с продвинутой отвёрткой, кусачками и мультитулом для инженеров и полевой модификации техники. Вопреки названию, вполне легален."
	origin_tech = "materials=3;engineering=4;biotech=3;powerstorage=4;abductor=3"
	contents = newlist(/obj/item/screwdriver/cyborg, /obj/item/wirecutters/cyborg, /obj/item/multitool/abductor)
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/device.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "hacktool")

/obj/item/organ/internal/cyberimp/arm/hacking/get_ru_names()
	return alist(
		NOMINATIVE = "имплант взломщика",
		GENITIVE = "импланта взломщика",
		DATIVE = "импланту взломщика",
		ACCUSATIVE = "имплант взломщика",
		INSTRUMENTAL = "имплантом взломщика",
		PREPOSITIONAL = "импланте взломщика",
	)

/obj/item/organ/internal/cyberimp/arm/hacking/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/esword
	name = "arm-mounted energy blade"
	cyber_cost = 35
	desc = "Нелегальный и крайне опасный имплант, проецирующий смертоносный клинок из концентрированной энергии."
	contents = newlist(/obj/item/melee/energy/blade/hardlight)
	origin_tech = "materials=4;combat=5;biotech=3;powerstorage=2;syndicate=5"

/obj/item/organ/internal/cyberimp/arm/esword/get_ru_names()
	return alist(
		NOMINATIVE = "имплант энергоклинка",
		GENITIVE = "импланта энергоклинка",
		DATIVE = "импланту энергоклинка",
		ACCUSATIVE = "имплант энергоклинка",
		INSTRUMENTAL = "имплантом энергоклинка",
		PREPOSITIONAL = "импланте энергоклинка",
	)

/obj/item/organ/internal/cyberimp/arm/medibeam
	name = "integrated medical beamgun"
	cyber_cost = 20
	desc = "Кибернетический имплант, позволяющий проецировать лечащий луч из ладони."
	contents = newlist(/obj/item/gun/medbeam)
	origin_tech = "materials=5;combat=2;biotech=5;powerstorage=4;syndicate=1"
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/chronos.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "chronogun")

/obj/item/organ/internal/cyberimp/arm/medibeam/get_ru_names()
	return alist(
		NOMINATIVE = "имплант медицинского луча",
		GENITIVE = "импланта медицинского луча",
		DATIVE = "импланту медицинского луча",
		ACCUSATIVE = "имплант медицинского луча",
		INSTRUMENTAL = "имплантом медицинского луча",
		PREPOSITIONAL = "импланте медицинского луча",
	)

/obj/item/organ/internal/cyberimp/arm/flash
	name = "integrated high-intensity photon projector" //Why not
	cyber_cost = 12
	desc = "Встроенный в руку проектор, работающий как мощная вспышка."
	contents = newlist(/obj/item/flash/armimplant)
	origin_tech = "materials=4;combat=3;biotech=4;magnets=4;powerstorage=3"
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/device.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "flash")

/obj/item/organ/internal/cyberimp/arm/flash/get_ru_names()
	return alist(
		NOMINATIVE = "имплант фотонного проектора",
		GENITIVE = "импланта фотонного проектора",
		DATIVE = "импланту фотонного проектора",
		ACCUSATIVE = "имплант фотонного проектора",
		INSTRUMENTAL = "имплантом фотонного проектора",
		PREPOSITIONAL = "импланте фотонного проектора",
	)

/obj/item/organ/internal/cyberimp/arm/flash/Initialize(mapload)
	. = ..()
	if(locate(/obj/item/flash/armimplant) in items_list)
		var/obj/item/flash/armimplant/F = locate(/obj/item/flash/armimplant) in items_list
		F.I = src

/obj/item/organ/internal/cyberimp/arm/flash/Extend(obj/item/item)
	. = ..()
	active_item.set_light_range(7)
	active_item.set_light_on(TRUE)

/obj/item/organ/internal/cyberimp/arm/flash/Retract()
	if(!active_item || (active_item in src))
		return FALSE
	active_item.set_light_on(FALSE)
	return ..()

/obj/item/organ/internal/cyberimp/arm/baton
	name = "arm electrification implant"
	cyber_cost = 20
	desc = "Нелегальный боевой имплант, позволяющий бить электрошоком прямо из руки."
	contents = newlist(/obj/item/borg/stun)
	origin_tech = "materials=3;combat=5;biotech=4;powerstorage=4;syndicate=3"

/obj/item/organ/internal/cyberimp/arm/baton/get_ru_names()
	return alist(
		NOMINATIVE = "имплант электрошоковой руки",
		GENITIVE = "импланта электрошоковой руки",
		DATIVE = "импланту электрошоковой руки",
		ACCUSATIVE = "имплант электрошоковой руки",
		INSTRUMENTAL = "имплантом электрошоковой руки",
		PREPOSITIONAL = "импланте электрошоковой руки",
	)

/obj/item/organ/internal/cyberimp/arm/combat
	name = "combat cybernetics implant"
	cyber_cost = 40
	desc = "Мощный кибернетический имплант с боевыми модулями, встроенными в руку."
	contents = newlist(/obj/item/melee/energy/blade/hardlight, /obj/item/gun/medbeam, /obj/item/borg/stun, /obj/item/flash/armimplant)
	origin_tech = "materials=5;combat=7;biotech=5;powerstorage=5;syndicate=6;programming=5"

/obj/item/organ/internal/cyberimp/arm/combat/get_ru_names()
	return alist(
		NOMINATIVE = "имплант боевой кибернетики",
		GENITIVE = "импланта боевой кибернетики",
		DATIVE = "импланту боевой кибернетики",
		ACCUSATIVE = "имплант боевой кибернетики",
		INSTRUMENTAL = "имплантом боевой кибернетики",
		PREPOSITIONAL = "импланте боевой кибернетики",
	)

/obj/item/organ/internal/cyberimp/arm/combat/Initialize(mapload)
	. = ..()
	if(locate(/obj/item/flash/armimplant) in items_list)
		var/obj/item/flash/armimplant/F = locate(/obj/item/flash/armimplant) in items_list
		F.I = src

/obj/item/organ/internal/cyberimp/arm/combat/centcom
	name = "NT specops cybernetics implant"
	desc = "Чрезвычайно мощный кибернетический имплант с боевыми и вспомогательными модулями спецподразделений НТ."
	contents = newlist(/obj/item/gun/energy/pulse/pistol/m1911, /obj/item/door_remote/omni, /obj/item/melee/energy/blade/hardlight, /obj/item/reagent_containers/hypospray/combat/nanites, /obj/item/gun/medbeam, /obj/item/borg/stun, /obj/item/implanter/mindshield, /obj/item/flash/armimplant)
	icon = 'icons/obj/weapons/energy.dmi'
	icon_state = "m1911"
	emp_proof = 1

/obj/item/organ/internal/cyberimp/arm/combat/centcom/get_ru_names()
	return alist(
		NOMINATIVE = "имплант боевой кибернетики спецназа НТ",
		GENITIVE = "импланта боевой кибернетики спецназа НТ",
		DATIVE = "импланту боевой кибернетики спецназа НТ",
		ACCUSATIVE = "имплант боевой кибернетики спецназа НТ",
		INSTRUMENTAL = "имплантом боевой кибернетики спецназа НТ",
		PREPOSITIONAL = "импланте боевой кибернетики спецназа НТ",
	)

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade
	cyber_cost = 30
	sound_on = 'sound/weapons/wristblades_on.ogg'
	sound_off = 'sound/weapons/wristblades_off.ogg'

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/horlex
	name = "hidden blade implant"
	desc = "Клинок, спрятанный прямо под кожей. Связан напрямую с мозгом и выскакивает по первой мысли."
	contents = newlist(/obj/item/melee/mantisblade)
	origin_tech = "materials=6;combat=6;biotech=6;syndicate=4;programming=5;"
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/surgery.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "syndie_mantis")
	icon_state = "syndie_mantis"
	emp_proof = TRUE

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/horlex/get_ru_names()
	return alist(
		NOMINATIVE = "имплант скрытого клинка \"Хорлекс\"",
		GENITIVE = "импланта скрытого клинка \"Хорлекс\"",
		DATIVE = "импланту скрытого клинка \"Хорлекс\"",
		ACCUSATIVE = "имплант скрытого клинка \"Хорлекс\"",
		INSTRUMENTAL = "имплантом скрытого клинка \"Хорлекс\"",
		PREPOSITIONAL = "импланте скрытого клинка \"Хорлекс\"",
	)

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/horlex/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/shellguard
	name = "hidden blade implant"
	desc = "Клинок, спрятанный прямо под кожей. Связан напрямую с мозгом и выскакивает по первой мысли."
	contents = newlist(/obj/item/melee/mantisblade/shellguard)
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/surgery.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "mantis")
	origin_tech = "materials=6;combat=6;biotech=6;programming=5;"
	icon_state = "mantis"

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/shellguard/get_ru_names()
	return alist(
		NOMINATIVE = "имплант скрытого клинка \"Шеллгард\"",
		GENITIVE = "импланта скрытого клинка \"Шеллгард\"",
		DATIVE = "импланту скрытого клинка \"Шеллгард\"",
		ACCUSATIVE = "имплант скрытого клинка \"Шеллгард\"",
		INSTRUMENTAL = "имплантом скрытого клинка \"Шеллгард\"",
		PREPOSITIONAL = "импланте скрытого клинка \"Шеллгард\"",
	)

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/shellguard/l
	parent_organ_zone = BODY_ZONE_L_ARM

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/emp_act(severity)
	if(emp_shielded(severity))
		return
	..()

	if(crit_fail || emp_proof)
		return
	crit_fail = TRUE
	Retract()
	addtimer(CALLBACK(src, PROC_REF(reboot)), 10 SECONDS)

/obj/item/organ/internal/cyberimp/arm/toolset/mantisblade/proc/reboot()
	crit_fail = FALSE

/obj/item/organ/internal/cyberimp/arm/surgery
	name = "Inugami toolset implant"
	desc = "Набор хирургических инструментов, спрятанный за потайной панелью на руке пользователя."
	icon = 'icons/map_icons/items/_item.dmi'
	post_init_icon_state = "armimp"
	icon_state = "/obj/item/organ/internal/cyberimp/arm/surgery"
	item_state = "armimp"
	greyscale_config = /datum/greyscale_config/armimp
	greyscale_config_inhand_left = /datum/greyscale_config/armimp_inhand_left
	greyscale_config_inhand_right = /datum/greyscale_config/armimp_inhand_right
	greyscale_colors = "#ffffff#269a9d#269a9d#269a9d"
	contents = newlist(
		/obj/item/retractor/augment,
		/obj/item/hemostat/augment,
		/obj/item/cautery/augment,
		/obj/item/bonesetter/augment,
		/obj/item/scalpel/augment,
		/obj/item/circular_saw/augment,
		/obj/item/bonegel/augment,
		/obj/item/FixOVein/augment,
		/obj/item/surgicaldrill/augment,
		)
	origin_tech = "materials=3;engineering=3;biotech=3;programming=2;magnets=3"
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/storage.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "duffel-med")

/obj/item/organ/internal/cyberimp/arm/surgery/get_ru_names()
	return alist(
		NOMINATIVE = "имплант хирургических инструментов",
		GENITIVE = "импланта хирургических инструментов",
		DATIVE = "импланту хирургических инструментов",
		ACCUSATIVE = "имплант хирургических инструментов",
		INSTRUMENTAL = "имплантом хирургических инструментов",
		PREPOSITIONAL = "импланте хирургических инструментов",
	)

/obj/item/organ/internal/cyberimp/arm/surgery/adv
	desc = "Набор лазерных хирургических инструментов, спрятанный за потайной панелью на руке пользователя. Новейшая разработка Inugami!"
	icon_state = "/obj/item/organ/internal/cyberimp/arm/surgery/adv"
	greyscale_colors = "#ffffff#89d640#89d640#89d640"
	contents = newlist(
		/obj/item/scalpel/laser/laser3,
		/obj/item/hemostat/laser,
		/obj/item/retractor/laser,
		/obj/item/surgicaldrill/laser,
		/obj/item/circular_saw/laser,
		/obj/item/bonesetter/laser,
		/obj/item/bonegel,
		/obj/item/FixOVein,
		)
	origin_tech = "materials=5;biotech=3;magnets=4"
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "surgerykit_advanced")

/obj/item/organ/internal/cyberimp/arm/surgery/adv/get_ru_names()
	return alist(
		NOMINATIVE = "имплант Inugami",
		GENITIVE = "импланта Inugami",
		DATIVE = "импланту Inugami",
		ACCUSATIVE = "имплант Inugami",
		INSTRUMENTAL = "имплантом Inugami",
		PREPOSITIONAL = "импланте Inugami",
	)

/obj/item/organ/internal/cyberimp/arm/surgery/adv/ert
	name = "NT-Med toolset implant"
	desc = "Набор хирургических инструментов для военных нужд, спрятанный за потайной панелью на руке пользователя. Крайне редкая модель, используется военными врачами корпорации Nanotrasen."
	icon_state = "/obj/item/organ/internal/cyberimp/arm/surgery/adv/ert"
	greyscale_colors = "#8f8a8a#89d640#89d640#89d640"
	contents = newlist(
		/obj/item/bodyanalyzer/advanced,
		/obj/item/scalpel/laser/manager,
		/obj/item/surgicaldrill/laser,
		/obj/item/circular_saw/laser,
		/obj/item/bonesetter/laser,
		/obj/item/bonegel,
		/obj/item/FixOVein,
		)
	origin_tech = "materials=8;biotech=4;magnets=5;programming=4"
	emp_proof = 1

/obj/item/organ/internal/cyberimp/arm/surgery/adv/ert/get_ru_names()
	return alist(
		NOMINATIVE = "имплант NT-Med",
		GENITIVE = "импланта NT-Med",
		DATIVE = "импланту NT-Med",
		ACCUSATIVE = "имплант NT-Med",
		INSTRUMENTAL = "имплантом NT-Med",
		PREPOSITIONAL = "импланте NT-Med",
	)

/obj/item/organ/internal/cyberimp/arm/surgery/alien
	name = "alien surgical toolset implant"
	desc = "Набор экспериментальных хирургических инструментов, спрятанный за потайной панелью на руке пользователя."
	icon_state = "/obj/item/organ/internal/cyberimp/arm/surgery/alien"
	greyscale_colors = "#848fe6#8b045c#5005d4#7e79ad"
	contents = newlist(
		/obj/item/scalpel/alien,
		/obj/item/hemostat/alien,
		/obj/item/retractor/alien,
		/obj/item/circular_saw/alien,
		/obj/item/surgicaldrill/alien,
		/obj/item/cautery/alien,
		/obj/item/bonegel/alien,
		/obj/item/bonesetter/alien,
		/obj/item/FixOVein/alien,
		)
	origin_tech = "materials=4;biotech=3;abductor=2"
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "surgerykit_alien")

/obj/item/organ/internal/cyberimp/arm/surgery/alien/get_ru_names()
	return alist(
		NOMINATIVE = "инородный имплант",
		GENITIVE = "инородного импланта",
		DATIVE = "инородному импланту",
		ACCUSATIVE = "инородный имплант",
		INSTRUMENTAL = "инородным имплантом",
		PREPOSITIONAL = "инородном импланте",
	)

/obj/item/organ/internal/cyberimp/arm/janitorial
	name = "janitorial toolset implant"
	desc = "Набор уборочных инструментов, спрятанный за потайной панелью в руке."
	icon_state = "janitor_arm_implant"
	contents = newlist(/obj/item/mop/advanced, /obj/item/soap, /obj/item/lightreplacer, /obj/item/holosign_creator/janitor, /obj/item/melee/flyswatter, /obj/item/reagent_containers/spray/cleaner/safety)
	origin_tech = "materials=3;engineering=4;biotech=3"
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/clothing/belts.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "janibelt")

/obj/item/organ/internal/cyberimp/arm/janitorial/get_ru_names()
	return alist(
		NOMINATIVE = "имплант уборочных инструментов",
		GENITIVE = "импланта уборочных инструментов",
		DATIVE = "импланту уборочных инструментов",
		ACCUSATIVE = "имплант уборочных инструментов",
		INSTRUMENTAL = "имплантом уборочных инструментов",
		PREPOSITIONAL = "импланте уборочных инструментов",
	)

/obj/item/organ/internal/cyberimp/arm/janitorial/l
	parent_organ_zone = BODY_ZONE_L_ARM
	slot = INTERNAL_ORGAN_L_ARM_DEVICE

/obj/item/organ/internal/cyberimp/arm/botanical
	name = "botanical toolset implant"
	desc = "Набор садовых инструментов, спрятанный за потайной панелью в руке."
	icon_state = "botanical_arm_implant"
	contents = newlist(/obj/item/plant_analyzer, /obj/item/cultivator, /obj/item/hatchet, /obj/item/shovel/spade, /obj/item/wirecutters, /obj/item/wrench)
	origin_tech = "materials=3;engineering=4;biotech=3"
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/clothing/belts.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "botanybelt")

/obj/item/organ/internal/cyberimp/arm/botanical/get_ru_names()
	return alist(
		NOMINATIVE = "имплант садовых инструментов",
		GENITIVE = "импланта садовых инструментов",
		DATIVE = "импланту садовых инструментов",
		ACCUSATIVE = "имплант садовых инструментов",
		INSTRUMENTAL = "имплантом садовых инструментов",
		PREPOSITIONAL = "импланте садовых инструментов",
	)

/obj/item/organ/internal/cyberimp/arm/botanical/l
	parent_organ_zone = BODY_ZONE_L_ARM
	slot = INTERNAL_ORGAN_L_ARM_DEVICE

// lets make IPCs even *more* vulnerable to EMPs!
/obj/item/organ/internal/cyberimp/arm/power_cord
	species_type = /datum/species/machine
	name = "APC-compatible power adapter implant"
	cyber_cost = 4
	desc = "Имплант, который обычно ставят КПБ, чтобы подзаряжаться от окружающих источников энергии."
	origin_tech = "materials=3;biotech=2;powerstorage=3"
	contents = newlist(/obj/item/apc_powercord)

/obj/item/organ/internal/cyberimp/arm/power_cord/get_ru_names()
	return alist(
		NOMINATIVE = "имплант силового адаптера",
		GENITIVE = "импланта силового адаптера",
		DATIVE = "импланту силового адаптера",
		ACCUSATIVE = "имплант силового адаптера",
		INSTRUMENTAL = "имплантом силового адаптера",
		PREPOSITIONAL = "импланте силового адаптера",
	)

/obj/item/organ/internal/cyberimp/arm/power_cord/emp_act(severity)
	// To allow repair via nanopaste/screwdriver
	// also so IPCs don't also catch on fire and fall even more apart upon EMP
	if(emp_proof)
		return
	if(emp_shielded(severity))
		return
	damage = 1
	crit_fail = TRUE

/obj/item/organ/internal/cyberimp/arm/power_cord/surgeryize()
	if(crit_fail && owner)
		to_chat(owner, span_notice("[DECLENT_RU_CAP(src, NOMINATIVE)] снова работает."))
	crit_fail = FALSE

/obj/item/apc_powercord
	name = "power cable"
	desc = "Вставьте в ближайший ЛКП, чтобы подзарядиться от него."
	icon = 'icons/obj/engines_and_power/power.dmi'
	icon_state = "wire1"
	item_flags = NOBLUDGEON
	var/drawing_power = FALSE

/obj/item/apc_powercord/afterattack(atom/target, mob/user, proximity_flag, list/modifiers, status)
	if(!isapc(target) || !ishuman(user) || !proximity_flag)
		return ..()
	if(drawing_power)
		to_chat(user, span_warning("Вы уже заряжаетесь."))
		return
	user.changeNext_move(attack_speed)
	var/obj/machinery/power/apc/A = target
	var/mob/living/carbon/human/H = user
	if(H.get_int_organ(/obj/item/organ/internal/cell))
		if(A.emagged || A.stat & BROKEN)
			do_sparks(3, TRUE, A)
			to_chat(H, span_warning("Ток ЛКП скачет и повреждает ваш корпус!"))
			H.adjustFireLoss(10)
		else if(A.cell && A.cell.charge > 0)
			if(H.nutrition >= NUTRITION_LEVEL_WELL_FED)
				to_chat(user, span_warning("Вы уже полностью заряжены!"))
			else
				INVOKE_ASYNC(src, PROC_REF(powerdraw_loop), A, H)
		else
			to_chat(user, span_warning("В этом ЛКП нет заряда."))
	else
		to_chat(user, span_warning("Вам некуда запасать заряд: нет батареи!"))

/obj/item/apc_powercord/proc/powerdraw_loop(obj/machinery/power/apc/A, mob/living/carbon/human/H)
	H.visible_message(span_notice("[H] вставля[PLUR_ET_YUT(H)] силовой разъём в [A.declent_ru(ACCUSATIVE)]."), span_notice("Вы начинаете заряжаться от [A.declent_ru(GENITIVE)]."))
	drawing_power = TRUE
	while(do_after(H, 1 SECONDS, A))
		if(loc != H)
			to_chat(H, span_warning("Во время зарядки разъём нужно держать выдвинутым!"))
			break
		if(A.cell.charge == 0)
			to_chat(H, span_warning("В [A.declent_ru(PREPOSITIONAL)] закончился заряд."))
			break
		A.charging = APC_IS_CHARGING
		if(A.cell.charge >= 500)
			H.adjust_nutrition(50)
			A.cell.charge -= 500
			to_chat(H, span_notice("Вы перекачиваете часть заряда себе."))
		else
			H.adjust_nutrition(A.cell.charge * 0.1)
			A.cell.charge = 0
			to_chat(H, span_notice("Вы выкачиваете из [A.declent_ru(GENITIVE)] остатки заряда."))
			break
		if(H.nutrition > NUTRITION_LEVEL_WELL_FED)
			to_chat(H, span_notice("Вы полностью заряжены."))
			break
	H.visible_message(span_notice("[H] отключа[PLUR_ET_YUT(H)]ся от [A.declent_ru(GENITIVE)]."), span_notice("Вы отключаетесь от [A.declent_ru(GENITIVE)]."))
	drawing_power = FALSE

/obj/item/organ/internal/cyberimp/arm/telebaton
	name = "telebaton implant"
	cyber_cost = 18
	desc = "Имплант телескопической дубинки. Делает ровно то, что обещает."

	contents = newlist(/obj/item/melee/baton)
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/items.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "baton")

/obj/item/organ/internal/cyberimp/arm/telebaton/get_ru_names()
	return alist(
		NOMINATIVE = "имплант телескопической дубинки",
		GENITIVE = "импланта телескопической дубинки",
		DATIVE = "импланту телескопической дубинки",
		ACCUSATIVE = "имплант телескопической дубинки",
		INSTRUMENTAL = "имплантом телескопической дубинки",
		PREPOSITIONAL = "импланте телескопической дубинки",
	)

/obj/item/organ/internal/cyberimp/arm/advmop
	name = "advanced mop implant"
	desc = "Имплант продвинутой швабры. Делает ровно то, что обещает."

	contents = newlist(/obj/item/mop/advanced)
	action_icon = list(/datum/action/item_action/organ_action/toggle = 'icons/obj/janitor.dmi')
	action_icon_state = list(/datum/action/item_action/organ_action/toggle = "advmop")

/obj/item/organ/internal/cyberimp/arm/advmop/get_ru_names()
	return alist(
		NOMINATIVE = "имплант продвинутой швабры",
		GENITIVE = "импланта продвинутой швабры",
		DATIVE = "импланту продвинутой швабры",
		ACCUSATIVE = "имплант продвинутой швабры",
		INSTRUMENTAL = "имплантом продвинутой швабры",
		PREPOSITIONAL = "импланте продвинутой швабры",
	)
