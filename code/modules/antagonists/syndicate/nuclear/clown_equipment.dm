#define BANANA_SHOES_MAX_CHARGE 3000
#define BANANA_SHOES_COST 100
#define BANANA_SHOES_RECHARGE 17

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat
	parent_type = /obj/item/clothing/shoes/clown_shoes/combat
	name = "mk-honk combat shoes"
	desc = "Боевые клоунские ботинки оставляют за собой банановую кожуру. Постепенно восстанавливают заряд и принимают бананиум для быстрой зарядки."
	icon = 'icons/obj/clown_ops.dmi'
	icon_state = "clown_prototype_off"
	onmob_sheets = list(ITEM_SLOT_FEET_STRING = 'icons/mob/clothing/clown_ops_feet.dmi')
	sprite_sheets = null
	armor = list(MELEE = 25, BULLET = 25, LASER = 25, ENERGY = 25, BOMB = 50, BIO = 50, FIRE = 90, ACID = 50)
	actions_types = list(/datum/action/item_action/toggle_banana_shoes)
	var/on = FALSE
	var/datum/component/material_container/bananium

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat/Initialize(mapload)
	. = ..()
	bananium = AddComponent(/datum/component/material_container, list(MAT_BANANIUM), 100 * MINERAL_MATERIAL_AMOUNT, TRUE, /obj/item/stack)
	bananium.insert_amount(BANANA_SHOES_MAX_CHARGE, MAT_BANANIUM)
	AddComponent(/datum/component/squeak, list('sound/items/bikehorn.ogg' = 1), 75, falloff_exponent = 20)
	RegisterSignal(src, COMSIG_SHOES_STEP_ACTION, PROC_REF(on_step))
	START_PROCESSING(SSobj, src)

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat/Destroy()
	STOP_PROCESSING(SSobj, src)
	UnregisterSignal(src, COMSIG_SHOES_STEP_ACTION)
	bananium = null
	return ..()

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat/process(seconds_per_tick)
	var/current_charge = bananium.amount(MAT_BANANIUM)
	if(current_charge < BANANA_SHOES_MAX_CHARGE)
		bananium.insert_amount(min(BANANA_SHOES_RECHARGE * seconds_per_tick, BANANA_SHOES_MAX_CHARGE - current_charge), MAT_BANANIUM)

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat/proc/on_step()
	SIGNAL_HANDLER
	if(!on || !ismob(loc))
		return
	if(!bananium.use_amount_type(BANANA_SHOES_COST, MAT_BANANIUM))
		on = FALSE
		update_appearance()
		return
	var/mob/wearer = loc
	new /obj/item/grown/bananapeel/specialpeel(get_step(wearer, REVERSE_DIR(wearer.dir)))

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat/attack_self(mob/user)
	ui_action_click(user)

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat/ui_action_click(mob/user, datum/action/action, leftclick)
	if(!on && bananium.amount(MAT_BANANIUM) < BANANA_SHOES_COST)
		balloon_alert(user, "нужен бананиум!")
		return
	on = !on
	balloon_alert(user, on ? "генератор включён" : "генератор выключен")
	update_appearance()

/obj/item/clothing/shoes/clown_shoes/banana_shoes/combat/update_icon_state()
	icon_state = "clown_prototype_[on ? "on" : "off"]"
	update_equipped_item(update_speedmods = FALSE)

/datum/action/item_action/toggle_banana_shoes
	name = "Генератор банановой кожуры"

#undef BANANA_SHOES_MAX_CHARGE
#undef BANANA_SHOES_COST
#undef BANANA_SHOES_RECHARGE

/obj/item/pneumatic_cannon/pie/selfcharge
	name = "banana cream pie cannon"
	desc = "Пирогомёт с генератором банановых кремовых пирогов. Вмещает двадцать пирогов и создаёт новый каждые две секунды."
	icon = 'icons/obj/clown_ops.dmi'
	icon_state = "piecannon"
	force = 10
	maxWeightClass = 20 * /obj/item/reagent_containers/food/snacks/pie::w_class
	var/mob/living/cannon_user
	var/datum/weakref/target_ref

/obj/item/pneumatic_cannon/pie/selfcharge/get_ru_names()
	return alist(NOMINATIVE = "банановый пирогомёт", GENITIVE = "бананового пирогомёта", DATIVE = "банановому пирогомёту", ACCUSATIVE = "банановый пирогомёт", INSTRUMENTAL = "банановым пирогомётом", PREPOSITIONAL = "банановом пирогомёте")

/obj/item/pneumatic_cannon/pie/selfcharge/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatedfire/autofire, auto_fire_shot_delay = CLICK_CD_RANGE, fire_mode = GUN_FIREMODE_AUTOMATIC, callback_fire = CALLBACK(src, PROC_REF(fire_pie)))
	START_PROCESSING(SSobj, src)

/obj/item/pneumatic_cannon/pie/selfcharge/Destroy()
	STOP_PROCESSING(SSobj, src)
	clear_user()
	return ..()

/obj/item/pneumatic_cannon/pie/selfcharge/equipped(mob/user, slot, initial)
	. = ..()
	clear_user()
	if(!(slot & ITEM_SLOT_HANDS) || !isliving(user))
		return
	cannon_user = user
	RegisterSignal(user, COMSIG_MOB_MOUSEDOWN, PROC_REF(start_firing))
	RegisterSignal(user, COMSIG_MOB_MOUSEUP, PROC_REF(stop_firing))
	RegisterSignal(user, COMSIG_QDELETING, PROC_REF(clear_user))

/obj/item/pneumatic_cannon/pie/selfcharge/dropped(mob/user, slot, silent)
	clear_user()
	return ..()

/obj/item/pneumatic_cannon/pie/selfcharge/proc/clear_user()
	SIGNAL_HANDLER
	SEND_SIGNAL(src, COMSIG_GUN_STOP_FIRE)
	target_ref = null
	if(cannon_user)
		UnregisterSignal(cannon_user, list(COMSIG_MOB_MOUSEDOWN, COMSIG_MOB_MOUSEUP, COMSIG_QDELETING))
	cannon_user = null

/obj/item/pneumatic_cannon/pie/selfcharge/proc/start_firing(datum/source, atom/object, turf/location, control, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	if(modifiers[SHIFT_CLICK] || modifiers[CTRL_CLICK] || modifiers[ALT_CLICK] || modifiers[RIGHT_CLICK] || modifiers[MIDDLE_CLICK])
		return
	if(!cannon_user.is_in_active_hand(src) || cannon_user.in_throw_mode || cannon_user.incapacitated() || !cannon_user.loc?.allow_click())
		return
	if(!isturf(object) && !isturf(object?.loc))
		return
	if(get_dist(cannon_user, object) <= 1 && cannon_user.a_intent == INTENT_HARM)
		return
	target_ref = WEAKREF(object)
	SEND_SIGNAL(src, COMSIG_GUN_FIRE)

/obj/item/pneumatic_cannon/pie/selfcharge/proc/stop_firing()
	SIGNAL_HANDLER
	SEND_SIGNAL(src, COMSIG_GUN_STOP_FIRE)
	target_ref = null

/obj/item/pneumatic_cannon/pie/selfcharge/proc/fire_pie()
	var/atom/target = target_ref?.resolve()
	if(!target || !cannon_user || !cannon_user.is_in_active_hand(src) || cannon_user.incapacitated() || cannon_user.in_throw_mode || !length(loadedItems))
		return NONE
	Fire(cannon_user, target)
	return AUTOFIRE_CONTINUE

/obj/item/pneumatic_cannon/pie/selfcharge/afterattack(atom/target, mob/user, proximity_flag, list/modifiers, status)
	return

/obj/item/pneumatic_cannon/pie/selfcharge/examine(mob/user)
	. = list(desc, span_notice("Заряжено пирогов: [length(loadedItems)] из 20. Удерживайте левую кнопку мыши для стрельбы."))

/obj/item/pneumatic_cannon/pie/selfcharge/wrench_act(mob/living/user, obj/item/tool)
	return FALSE

/obj/item/pneumatic_cannon/pie/selfcharge/process()
	if(length(loadedItems) >= 20)
		return
	var/obj/item/reagent_containers/food/snacks/pie/pie = new(src)
	loadedItems += pie
	loadedWeightClass += pie.w_class

/obj/item/pneumatic_cannon/pie/selfcharge/attackby(obj/item/used, mob/user, params)
	if(!istype(used, /obj/item/reagent_containers/food/snacks/pie))
		return ATTACK_CHAIN_PROCEED
	return ..()

/obj/item/pneumatic_cannon/pie/selfcharge/Fire(mob/living/carbon/human/user, atom/target)
	if(!length(loadedItems))
		balloon_alert(user, "нет пирогов!")
		return
	var/obj/item/pie = loadedItems[1]
	loadedItems.Cut(1, 2)
	loadedWeightClass -= pie.w_class
	pie.forceMove(get_turf(src))
	pie.throw_at(target, 15, 2, user)
	playsound(src, 'sound/weapons/sonic_jackhammer.ogg', 50, TRUE)
	user.changeNext_move(CLICK_CD_RANGE)

/obj/item/pinata/syndie
	name = "weapons grade pinata assembly kit"
	desc = "Набор для установки пиньяты, полной конфет и взрывчатки. Используйте в руке, чтобы установить."
	icon = 'icons/obj/clown_ops.dmi'
	icon_state = "pinata_syndie"

/obj/item/pinata/syndie/attack_self(mob/user)
	if(!do_after(user, 4 SECONDS, get_turf(user)))
		return
	new /obj/structure/pinata/syndie(get_turf(user))
	qdel(src)

/obj/structure/pinata/syndie
	name = "syndicate corgi pinata"
	desc = "Пиньята в форме корги. Лупите оружием с уроном не меньше десяти, чтобы получить угощение."
	icon = 'icons/obj/clown_ops.dmi'
	icon_state = "pinata_syndie_placed"
	anchored = TRUE
	var/list/candy_options = list(
		/obj/item/reagent_containers/food/snacks/candy,
		/obj/item/reagent_containers/food/snacks/chocolatebar,
		/obj/item/reagent_containers/food/snacks/candy/sucker/lollipop,
		/obj/item/reagent_containers/food/snacks/candy/gum,
		/obj/item/reagent_containers/food/snacks/candy/jawbreaker,
		/obj/item/grenade/plastic/c4,
		/obj/item/grenade/clusterbuster/soap,
		/obj/item/grenade/empgrenade,
		/obj/item/grenade/frag,
		/obj/item/grenade/syndieminibomb,
	)

/obj/structure/pinata/syndie/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)
	if(damage_amount >= 10 && damage_type == BRUTE && prob(40 + damage_amount))
		var/candy_type = pick(candy_options)
		new candy_type(get_turf(src))
	return ..()

/obj/structure/pinata/syndie/obj_destruction(damage_flag)
	for(var/index in 1 to 2)
		var/candy_type = pick(candy_options)
		new candy_type(get_turf(src))
	return ..()

/obj/item/storage/box/syndie_kit/pinata
	name = "weapons grade pinata kit"
	desc = "Боевая пиньята и два пояса для её содержимого."

/obj/item/storage/box/syndie_kit/pinata/populate_contents()
	new /obj/item/pinata/syndie(src)
	new /obj/item/storage/belt/grenade(src)
	new /obj/item/storage/belt/military(src)

/obj/item/grenade/clusterbuster/soap
	name = "Slipocalypse"
	desc = "Кассетная граната с мылом Синдиката."
	payload = /obj/item/grenade/spawnergrenade/syndiesoap

/obj/item/grenade/spawnergrenade/syndiesoap
	name = "soap delivery grenade"
	desc = "Доставляет особо скользкое мыло."
	spawner_type = /obj/item/soap/syndie
	deliveryamt = 5
