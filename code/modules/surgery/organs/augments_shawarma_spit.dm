#define SHAWARMA_SPIT_COOK_TIME (10 SECONDS)

/obj/item/organ/internal/cyberimp/chest/shawarma_spit
	name = "shawarma spit implant"
	desc = "Вращающийся вертел с нагревателем, закреплённый на позвоночнике и выведенный за плечо. Прожаривает любое сырое мясо прямо на носителе, без соли, перца и гриля. Запах жареного мяса прилагается."
	icon = 'icons/obj/shawarma_spit.dmi'
	icon_state = "shawarma_spit"
	implant_overlay = null
	slot = INTERNAL_ORGAN_CHEST_SPIT
	cyber_cost = 8
	origin_tech = "materials=2;biotech=3;powerstorage=2"
	actions_types = list(/datum/action/item_action/organ_action/shawarma_spit)
	var/obj/item/reagent_containers/food/snacks/mounted_food
	var/cook_timer
	var/static/list/grilled_results = zebra_typecacheof(list(
		/obj/item/reagent_containers/food/snacks/meat = /obj/item/reagent_containers/food/snacks/meatsteak,
		/obj/item/reagent_containers/food/snacks/meat/bird = /obj/item/reagent_containers/food/snacks/birdsteak,
		/obj/item/reagent_containers/food/snacks/monstermeat = /obj/item/reagent_containers/food/snacks/roasted_meat,
		/obj/item/reagent_containers/food/snacks/monstermeat/goliath = /obj/item/reagent_containers/food/snacks/goliath_steak,
		/obj/item/reagent_containers/food/snacks/monstermeat/goldgrub = /obj/item/reagent_containers/food/snacks/goldgrubmeat,
		/obj/item/reagent_containers/food/snacks/monstermeat/spiderleg = /obj/item/reagent_containers/food/snacks/roasted_spiderleg,
		/obj/item/reagent_containers/food/snacks/monstermeat/spidereggs = null,
		/obj/item/reagent_containers/food/snacks/rawcutlet = /obj/item/reagent_containers/food/snacks/cutlet,
		/obj/item/reagent_containers/food/snacks/raw_bacon = /obj/item/reagent_containers/food/snacks/bacon,
		/obj/item/reagent_containers/food/snacks/salmonmeat = /obj/item/reagent_containers/food/snacks/salmonsteak,
		/obj/item/reagent_containers/food/snacks/carpmeat = /obj/item/reagent_containers/food/snacks/roasted_meat,
		/obj/item/reagent_containers/food/snacks/catfishmeat = /obj/item/reagent_containers/food/snacks/roasted_meat,
		/obj/item/reagent_containers/food/snacks/crayfish_raw = /obj/item/reagent_containers/food/snacks/crayfish_cooked,
		/obj/item/reagent_containers/food/snacks/crayfish_raw_small = /obj/item/reagent_containers/food/snacks/crayfish_cooked_small,
	), single_value = FALSE, clear_nulls = TRUE)

/datum/action/item_action/organ_action/shawarma_spit
	name = "Вертел для шаурмы"
	check_flags = AB_CHECK_INCAPACITATED|AB_CHECK_HANDS_BLOCKED|AB_CHECK_CONSCIOUS

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/get_ru_names()
	return alist(
		NOMINATIVE = "имплант-вертел для шаурмы",
		GENITIVE = "импланта-вертела для шаурмы",
		DATIVE = "импланту-вертелу для шаурмы",
		ACCUSATIVE = "имплант-вертел для шаурмы",
		INSTRUMENTAL = "имплантом-вертелом для шаурмы",
		PREPOSITIONAL = "импланте-вертеле для шаурмы",
	)

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(!. || !mounted_food)
		return
	var/turf/drop_turf = get_turf(target)
	if(drop_turf)
		mounted_food.forceMove(drop_turf)
	else
		qdel(mounted_food)

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone != mounted_food)
		return
	mounted_food = null
	deltimer(cook_timer)
	cook_timer = null
	update_spit_overlay()

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/render()
	var/spit_state = "spit_empty"
	if(mounted_food)
		spit_state = cook_timer ? "spit_cooking" : "spit_done"
	return mutable_appearance('icons/mob/shawarma_spit.dmi', spit_state, layer = -HEAD_ACCESSORY_LAYER)

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/ui_action_click(mob/user, datum/action/action, leftclick)
	if(!mounted_food)
		mount_food(user)
		return
	if(cook_timer)
		owner.balloon_alert(user, "ещё жарится!")
		return
	owner.visible_message(
		span_notice("[owner.declent_ru(NOMINATIVE)] снима[PLUR_ET_YUT(owner)] с вертела [mounted_food.declent_ru(ACCUSATIVE)]."),
		span_notice("Вы снимаете с вертела [mounted_food.declent_ru(ACCUSATIVE)]."),
	)
	user.put_in_hands(mounted_food)

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/proc/mount_food(mob/user)
	var/obj/item/raw_food = user.get_active_hand()
	if(!raw_food || !grilled_results[raw_food.type])
		owner.balloon_alert(user, "нужно сырое мясо в руке!")
		return
	if(!user.drop_transfer_item_to_loc(raw_food, src))
		return
	mounted_food = raw_food
	cook_timer = addtimer(CALLBACK(src, PROC_REF(finish_cooking)), SHAWARMA_SPIT_COOK_TIME, TIMER_STOPPABLE)
	owner.visible_message(
		span_notice("[owner.declent_ru(NOMINATIVE)] насажива[PLUR_ET_YUT(owner)] на вертел [raw_food.declent_ru(ACCUSATIVE)]."),
		span_notice("Вы насаживаете на вертел [raw_food.declent_ru(ACCUSATIVE)]."),
	)
	update_spit_overlay()

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/proc/finish_cooking()
	cook_timer = null
	var/grilled_type = grilled_results[mounted_food.type]
	var/obj/item/reagent_containers/food/snacks/grilled_food = new grilled_type(src)
	mounted_food.reagents.del_reagent("nutriment")
	mounted_food.reagents.trans_to(grilled_food, mounted_food.reagents.total_volume, no_react = TRUE)
	qdel(mounted_food)
	mounted_food = grilled_food
	playsound(owner, 'sound/machines/ding.ogg', 50, TRUE)
	owner.balloon_alert(owner, "мясо готово")
	update_spit_overlay()

/obj/item/organ/internal/cyberimp/chest/shawarma_spit/proc/update_spit_overlay()
	var/mob/living/carbon/human/human_owner = owner
	if(istype(human_owner))
		human_owner.update_int_organs()

#undef SHAWARMA_SPIT_COOK_TIME
