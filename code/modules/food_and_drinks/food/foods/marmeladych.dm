#define MARMELADYCH_GUMMIES 7
#define MARMELADYCH_WIDTH 6
#define MARMELADYCH_PRICE 999

/obj/item/storage/box/marmeladych
	name = "Marmeladych sour mix"
	gender = FEMALE
	desc = "Пачка кислого мармелада \"Мармеладыч\". Семь мармеладок, три сомнительных спецэффекта. Активируйте пачку в руке, чтобы достать мармеладку."
	icon = 'icons/obj/food/marmeladych.dmi'
	icon_state = "marmeladych_pack"
	pixel_x = -16
	pixel_y = -16
	foldable = null
	can_hold = list(/obj/item/reagent_containers/food/snacks/candy/gummybear/marmeladych)

/obj/item/storage/box/marmeladych/get_ru_names()
	return alist(
		NOMINATIVE = "пачка мармелада \"Мармеладыч\"",
		GENITIVE = "пачки мармелада \"Мармеладыч\"",
		DATIVE = "пачке мармелада \"Мармеладыч\"",
		ACCUSATIVE = "пачку мармелада \"Мармеладыч\"",
		INSTRUMENTAL = "пачкой мармелада \"Мармеладыч\"",
		PREPOSITIONAL = "пачке мармелада \"Мармеладыч\"",
	)

/obj/item/storage/box/marmeladych/populate_contents()
	for(var/index in 1 to MARMELADYCH_GUMMIES)
		new /obj/item/reagent_containers/food/snacks/candy/gummybear/marmeladych(src)

/obj/item/storage/box/marmeladych/attack_self(mob/user)
	if(!length(contents))
		balloon_alert(user, "пачка пуста!")
		return
	var/obj/item/gummy = pick(contents)
	remove_from_storage(gummy, user.drop_location())
	user.put_in_hands(gummy)
	playsound(src, use_sound, 30, TRUE)

/obj/item/reagent_containers/food/snacks/candy/gummybear/marmeladych
	name = "Marmeladych gummy"
	gender = FEMALE
	desc = "Кислый мармеладный мишка. Может раздать ширины, посадить на самоходный унитаз или показать, что такое настоящая инфляция."
	bitesize = 7
	list_reagents = list("sugar" = 5, "nutriment" = 2)
	tastes = list("кислого мармелада" = 1)

/obj/item/reagent_containers/food/snacks/candy/gummybear/marmeladych/get_ru_names()
	return alist(
		NOMINATIVE = "мармеладка \"Мармеладыч\"",
		GENITIVE = "мармеладки \"Мармеладыч\"",
		DATIVE = "мармеладке \"Мармеладыч\"",
		ACCUSATIVE = "мармеладку \"Мармеладыч\"",
		INSTRUMENTAL = "мармеладкой \"Мармеладыч\"",
		PREPOSITIONAL = "мармеладке \"Мармеладыч\"",
	)

/obj/item/reagent_containers/food/snacks/candy/gummybear/marmeladych/Initialize(mapload)
	. = ..()
	icon_state = pick("gbear_red", "gbear_blue", "gbear_green", "gbear_yellow", "gbear_orange", "gbear_purple")

/obj/item/reagent_containers/food/snacks/candy/gummybear/marmeladych/Post_Consume(mob/living/eater)
	. = ..()
	eater.apply_status_effect(pick(STATUS_EFFECT_MARMELADYCH_WIDE, STATUS_EFFECT_MARMELADYCH_TOILET, STATUS_EFFECT_MARMELADYCH_INFLATION))

/datum/status_effect/marmeladych
	id = "marmeladych"
	duration = 2 MINUTES
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	on_remove_on_mob_delete = TRUE

/datum/status_effect/marmeladych/wide
	id = "marmeladych_wide"

/datum/status_effect/marmeladych/wide/on_apply()
	ADD_TRAIT(owner, TRAIT_FAT, UNIQUE_TRAIT_SOURCE(src))
	if(owner.lying_angle && owner.rotate_on_lying)
		owner.transform = owner.transform.Scale(1, MARMELADYCH_WIDTH)
	else
		owner.transform = owner.transform.Scale(MARMELADYCH_WIDTH, 1)
	to_chat(owner, span_userdanger("Мармеладыч раздал вам ШИРИНЫ! Теперь вас видно из соседнего отсека."))
	return TRUE

/datum/status_effect/marmeladych/wide/on_remove()
	REMOVE_TRAIT(owner, TRAIT_FAT, UNIQUE_TRAIT_SOURCE(src))
	if(owner.lying_angle && owner.rotate_on_lying)
		owner.transform = owner.transform.Scale(1, 1 / MARMELADYCH_WIDTH)
	else
		owner.transform = owner.transform.Scale(1 / MARMELADYCH_WIDTH, 1)

/datum/status_effect/marmeladych/toilet
	id = "marmeladych_toilet"
	var/obj/vehicle/ridden/marmeladych_toilet/toilet

/datum/status_effect/marmeladych/toilet/on_apply()
	if(!isturf(owner.loc))
		return FALSE
	toilet = new(owner.loc)
	if(owner.buckled)
		owner.buckled.unbuckle_mob(owner, force = TRUE)
	if(!toilet.buckle_mob(owner, force = TRUE))
		QDEL_NULL(toilet)
		return FALSE
	to_chat(owner, span_notice("Ваш трон прибыл! Управляйте унитазом клавишами движения; нажмите на него, чтобы слезть."))
	return TRUE

/datum/status_effect/marmeladych/toilet/refresh(effect, ...)
	. = ..()
	QDEL_NULL(toilet)
	if(!on_apply())
		qdel(src)

/datum/status_effect/marmeladych/toilet/Destroy()
	QDEL_NULL(toilet)
	return ..()

/datum/status_effect/marmeladych/inflation
	id = "marmeladych_inflation"

/datum/status_effect/marmeladych/inflation/on_apply()
	RegisterSignal(owner, COMSIG_MOB_TGUI_CONFIG, PROC_REF(inflate_prices))
	SStgui.update_user_uis(owner)
	to_chat(owner, span_userdanger("Цены кусаются! Кажется, теперь всё стоит [MARMELADYCH_PRICE] кредитов."))
	return TRUE

/datum/status_effect/marmeladych/inflation/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_TGUI_CONFIG)
	if(!QDELETED(owner))
		SStgui.update_user_uis(owner)

/datum/status_effect/marmeladych/inflation/proc/inflate_prices(mob/source, list/config)
	SIGNAL_HANDLER
	config["credit_price_override"] = MARMELADYCH_PRICE

/obj/vehicle/ridden/marmeladych_toilet
	name = "Marmeladych toilet"
	desc = "Самоходный фарфоровый трон. Чтобы поехать, сядьте на него и используйте клавиши движения. Чтобы слезть, нажмите на унитаз."
	icon = 'icons/obj/watercloset.dmi'
	icon_state = "toilet10"
	max_integrity = 100
	pass_flags_self = NONE

/obj/vehicle/ridden/marmeladych_toilet/get_ru_names()
	return alist(
		NOMINATIVE = "самоходный унитаз",
		GENITIVE = "самоходного унитаза",
		DATIVE = "самоходному унитазу",
		ACCUSATIVE = "самоходный унитаз",
		INSTRUMENTAL = "самоходным унитазом",
		PREPOSITIONAL = "самоходном унитазе",
	)

/obj/vehicle/ridden/marmeladych_toilet/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/marmeladych_toilet)

/datum/component/riding/vehicle/marmeladych_toilet
	vehicle_move_delay = 1.5
	ride_check_flags = RIDER_NEEDS_LEGS | UNBUCKLE_DISABLED_RIDER

/datum/component/riding/vehicle/marmeladych_toilet/handle_specials()
	. = ..()
	set_riding_offsets(RIDING_OFFSET_ALL, list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 4), TEXT_EAST = list(0, 4), TEXT_WEST = list(0, 4)))
	set_vehicle_dir_layer(NORTH, OBJ_LAYER)
	set_vehicle_dir_layer(SOUTH, OBJ_LAYER)
	set_vehicle_dir_layer(EAST, OBJ_LAYER)
	set_vehicle_dir_layer(WEST, OBJ_LAYER)

#undef MARMELADYCH_GUMMIES
#undef MARMELADYCH_WIDTH
#undef MARMELADYCH_PRICE
