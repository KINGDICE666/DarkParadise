/obj/item/firing_pin
	name = "electronic firing pin"
	desc = "Электронный боёк, проверяющий владельца оружия."
	icon = 'icons/obj/clown_ops.dmi'
	icon_state = "firing_pin"
	w_class = WEIGHT_CLASS_TINY
	var/obj/item/gun/gun
	var/selfdestruct = FALSE
	var/previous_clumsy_check

/obj/item/firing_pin/get_ru_names()
	return alist(NOMINATIVE = "электронный боёк", GENITIVE = "электронного бойка", DATIVE = "электронному бойку", ACCUSATIVE = "электронный боёк", INSTRUMENTAL = "электронным бойком", PREPOSITIONAL = "электронном бойке")

/obj/item/firing_pin/Destroy()
	gun_remove()
	return ..()

/obj/item/firing_pin/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isgun(interacting_with))
		return NONE
	var/obj/item/gun/target_gun = interacting_with
	var/obj/item/firing_pin/old_pin = locate() in target_gun
	if(!user.drop_transfer_item_to_loc(src, target_gun))
		return ITEM_INTERACT_BLOCKING
	if(old_pin && old_pin != src)
		old_pin.gun_remove()
		old_pin.forceMove(target_gun.drop_location())
	gun_insert(user, target_gun)
	balloon_alert(user, "боёк установлен")
	return ITEM_INTERACT_SUCCESS

/obj/item/firing_pin/proc/gun_insert(mob/living/user, obj/item/gun/new_gun)
	gun = new_gun
	forceMove(gun)
	previous_clumsy_check = gun.clumsy_check
	gun.clumsy_check = FALSE
	RegisterSignal(gun, COMSIG_GUN_CHECK_CAN_SHOOT, PROC_REF(check_user))
	RegisterSignal(gun, COMSIG_ATOM_TOOL_ACT(TOOL_SCREWDRIVER), PROC_REF(on_screwdriver))

/obj/item/firing_pin/proc/gun_remove()
	if(!gun)
		return
	UnregisterSignal(gun, list(COMSIG_GUN_CHECK_CAN_SHOOT, COMSIG_ATOM_TOOL_ACT(TOOL_SCREWDRIVER)))
	gun.clumsy_check = previous_clumsy_check
	gun = null

/obj/item/firing_pin/proc/on_screwdriver(datum/source, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(remove_with_tool), user, tool)
	return ITEM_INTERACT_SUCCESS

/obj/item/firing_pin/proc/remove_with_tool(mob/living/user, obj/item/tool)
	if(!tool.use_tool(gun, user, 2 SECONDS, volume = tool.tool_volume) || !gun)
		return
	var/turf/drop_turf = gun.drop_location()
	gun_remove()
	forceMove(drop_turf)
	user.put_in_hands(src)
	balloon_alert(user, "боёк снят")

/obj/item/firing_pin/proc/check_user(datum/source, mob/living/user)
	SIGNAL_HANDLER
	if(!user || pin_auth(user))
		return NONE
	balloon_alert(user, "хонк!")
	if(selfdestruct)
		selfdestruct = FALSE
		INVOKE_ASYNC(src, PROC_REF(explode_gun), user)
	return GUN_CHECK_CANCEL_ATTACK

/obj/item/firing_pin/proc/pin_auth(mob/living/user)
	return TRUE

/obj/item/firing_pin/proc/explode_gun(mob/living/user)
	add_attack_logs(user, gun, "Triggered a self-destructing clown firing pin", ATKLOG_FEW)
	explosion(src, devastation_range = -1, light_impact_range = 2, flash_range = 3, cause = src)
	qdel(gun)

/obj/item/firing_pin/clown/ultra
	name = "ultra hilarious firing pin"
	desc = "Боёк разрешает стрельбу только клоунам и неуклюжим существам. Каждая попытка выстрела сопровождается хонком."
	color = COLOR_YELLOW

/obj/item/firing_pin/clown/ultra/pin_auth(mob/living/user)
	playsound(gun, 'sound/items/bikehorn.ogg', 50, TRUE)
	return HAS_TRAIT(user, TRAIT_CLUMSY) || HAS_MIND_TRAIT(user, TRAIT_NAIVE)

/obj/item/firing_pin/clown/ultra/selfdestruct
	name = "super ultra hilarious firing pin"
	desc = "Клоунский боёк с нитробананиевым зарядом. Оружие взорвётся, если им воспользуется кто-то без клоунской природы или неуклюжести."
	selfdestruct = TRUE

/obj/item/storage/box/syndie_kit/clownpins
	name = "ultra hilarious firing pin box"
	desc = "Четыре клоунских бойка для огнестрельного оружия."
	var/pin_type = /obj/item/firing_pin/clown/ultra

/obj/item/storage/box/syndie_kit/clownpins/populate_contents()
	for(var/index in 1 to 4)
		new pin_type(src)

/obj/item/storage/box/syndie_kit/clownpins/super
	name = "super ultra hilarious firing pin box"
	pin_type = /obj/item/firing_pin/clown/ultra/selfdestruct

/obj/item/firing_pin/monkey
	name = "simian firing pin"
	desc = "Боёк для обезьяньей лапы."

/obj/item/firing_pin/monkey/pin_auth(mob/living/user)
	return is_monkeybasic(user)
