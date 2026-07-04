// ===================================================================
// RESOMI SPECIAL MECHANICS
//   - can't fire heavy (large-calibre) weapons
//   - can be scooped into a hand / bag (holder mechanic)
// ===================================================================

// --- Heavy weapon restriction --------------------------------------
/mob/living/carbon/human/can_use_guns(obj/item/gun/gun)
	. = ..()
	if(. && gun.weapon_weight >= WEAPON_HEAVY && is_species(src, /datum/species/resomi))
		to_chat(src, span_warning("[gun] слишком велик и тяжёл для ваших лап — вы не можете из него стрелять!"))
		return FALSE

// --- Being picked up -----------------------------------------------
/obj/item/holder/resomi
	name = "resomi"
	desc = "Небольшой пернатый резоми, свернувшийся у вас в руках."
	icon = 'icons/mob/human_races/r_resomi.dmi'
	icon_state = "torso_m"

// Drag your own resomi onto another human to ask them to scoop you up.
/mob/living/carbon/human/mouse_drop_dragged(atom/over_object, mob/user, src_location, over_location, params)
	if(user == src && holder_type && ishuman(over_object) && over_object != src && is_species(src, /datum/species/resomi))
		var/mob/living/carbon/human/grabber = over_object
		switch(tgui_alert(grabber, "[src] хочет забраться к вам на руки. Поднять?", "Взять на руки", list("Да", "Нет")))
			if("Да")
				if(!grabber.IsReachableBy(src))
					to_chat(src, span_warning("Нужно оставаться в пределах досягаемости, чтобы вас подняли."))
					return
				get_scooped(grabber)
			if("Нет")
				to_chat(src, span_warning("[grabber] решил[GEND_A_O_I(grabber)] не поднимать вас."))
		return
	return ..()

// Make the held/pocketed item actually look like the little resomi (base
// get_scooped copies the blank human base sprite, which is invisible).
/mob/living/carbon/human/get_scooped(mob/living/carbon/grabber)
	. = ..()
	if(istype(., /obj/item/holder) && is_species(src, /datum/species/resomi))
		var/obj/item/holder/holder = .
		// Small enough to stuff into a backpack.
		holder.w_class = WEIGHT_CLASS_SMALL
		holder.appearance = appearance
		holder.layer = initial(holder.layer)
		holder.plane = initial(holder.plane)
		holder.pixel_x = 0
		holder.pixel_y = 0
