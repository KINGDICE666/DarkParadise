#define SODA_FIZZINESS_THROWN 15
#define SODA_FIZZINESS_SHAKE 5
#define SODA_EXPLOSION_PRESSURE 67.458

// MARK: Base Can
/obj/item/reagent_containers/cup/soda_cans
	icon = 'icons/obj/drinks.dmi'
	container_type = NONE
	drink_type = SUGAR
	gender = FEMALE
	throwforce = 12
	var/is_plastic = 0
	var/fizziness = 0

/obj/item/reagent_containers/cup/soda_cans/Initialize(mapload, vol)
	. = ..()
	AddElement(/datum/element/atmos_sensitive, mapload)

/obj/item/reagent_containers/cup/soda_cans/get_short_name() // Override if `list_reagents` has more than 1 element.
	if(!length(reagents.reagent_list))
		return declent_ru(NOMINATIVE)
	var/datum/reagent/reagent = reagents.reagent_list[1]
	return reagent.name

/obj/item/reagent_containers/cup/soda_cans/examine(mob/user)
	. = ..()
	. += span_notice("<b>[is_drainable() ? "Открыто" : "Закрыто"]</b>")
	if(!is_drainable())
		. += span_notice("Используйте [EXAMINE_HINT("ПКМ")] в руке, чтобы встряхнуть!")

/obj/item/reagent_containers/cup/soda_cans/examine_more(mob/user)
	. = ..()
	if(!in_range(user, src))
		return
	if(fizziness > 30 && prob(fizziness * 2))
		. += span_notice("<i>Присмотревшись к [declent_ru(DATIVE)], вы замечаете кое-что...</i>")
		. += "\t[span_warning("От [declent_ru(GENITIVE)] веет угрожающей газированностью...")]"

/obj/item/reagent_containers/cup/soda_cans/suicide_act(mob/living/user)
	if(!reagents.total_volume)
		user.visible_message(span_warning("[user] пыта[PLUR_ET_YUT(user)]ся сделать большой глоток из [declent_ru(GENITIVE)]... Но там пусто!"))
		return SHAME
	if(!is_drainable())
		open_soda(user)
		sleep(1 SECONDS)
	user.visible_message(span_suicide("[user] дела[PLUR_ET_YUT(user)] большой глоток из [declent_ru(GENITIVE)]! Это похоже на попытку самоубийства!"))
	playsound(user, 'sound/items/drink.ogg', 80, TRUE)
	reagents.trans_to(user, reagents.total_volume)
	sleep(0.5 SECONDS)
	user.say(pick(
		"Вот «Обхитри Кубинца Пита» — это была игра.",
		"Все эти новомодные аркады слишком медленные. Я предпочитаю классику.",
		"Таких, как «Путь Ориона», больше не делают.",
		"Как говорится, худший день рыбалки на космокарпа лучше лучшего дня на работе.",
		"Таких старых добрых сингулярных двигателей больше не делают.",
	))

	if(ishuman(user))
		var/mob/living/carbon/human/drinker = user
		if(drinker.age >= 30)
			drinker.Stun(5 SECONDS)
			sleep(5 SECONDS)
			playsound(drinker, 'sound/items/drink.ogg', 80, TRUE)
			drinker.say(pick(
				"Ещё один день, ещё один кредит.",
				"Может, придержать акции?",
				"Диверсификация — это для молодёжи.",
				"Да, хорошие тогда были времена.",
			))
			return SHAME

	sleep(2 SECONDS)
	return TOXLOSS

/obj/item/reagent_containers/cup/soda_cans/proc/crush(atom/drop_loc)
	var/obj/item/trash/can/crushed_can = new /obj/item/trash/can(drop_loc)
	crushed_can.icon_state = icon_state
	//inherit material vars for recycling purposes
	crushed_can.is_glass = is_glass
	crushed_can.is_plastic = is_plastic
	if(is_glass)
		playsound(drop_loc, 'sound/effects/glassbr3.ogg', rand(10, 50), TRUE)
		crushed_can.name = "broken bottle"
	else
		playsound(drop_loc, 'sound/weapons/pierce.ogg', rand(10, 50), TRUE)
	return crushed_can

/obj/item/reagent_containers/cup/soda_cans/interact_with_atom(atom/target, mob/living/user, list/modifiers)
	if(!iscarbon(target) || reagents.total_volume || user.a_intent != INTENT_HARM || user.zone_selected != BODY_ZONE_HEAD)
		return ..()

	if(target == user)
		user.visible_message(
			span_warning("[user] смина[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)] своим лбом!"),
			span_notice("Вы сминаете [declent_ru(ACCUSATIVE)] своим лбом."),
		)
	else
		user.visible_message(
			span_warning("[user] смина[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)] о лоб [target.declent_ru(GENITIVE)]!"),
			span_notice("Вы сминаете [declent_ru(ACCUSATIVE)] о лоб [target.declent_ru(GENITIVE)]."),
		)
	crush(target.drop_location())
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/item/reagent_containers/cup/soda_cans/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/storage/bag/trash/cyborg))
		user.visible_message(
			span_notice("[user] засовыва[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)] в свой уплотнитель мусора."),
			span_notice("Вы засовываете [declent_ru(ACCUSATIVE)] в свой уплотнитель мусора."),
		)
		var/obj/item/trash/can/crushed_can = crush(user.loc)
		qdel(src)
		crushed_can.attackby(I, user, params)
		return ATTACK_CHAIN_BLOCKED_ALL
	return ..()

/obj/item/reagent_containers/cup/soda_cans/bullet_act(obj/projectile/proj)
	. = ..()
	if(QDELETED(src))
		return
	if(!proj.damage || proj.damage_type != BRUTE)
		return
	var/obj/item/trash/can/crushed_can = crush(loc)
	var/atom/throw_target = get_edge_target_turf(crushed_can, pick(GLOB.alldirs))
	crushed_can.throw_at(throw_target, rand(1, 2), 7)
	qdel(src)

/obj/item/reagent_containers/cup/soda_cans/proc/open_soda(mob/user)
	if(prob(fizziness))
		user.visible_message(
			span_danger("[user] открыва[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)], и из неё с шипением бьёт струя!"),
			span_danger("Вы дёргаете за язычок [declent_ru(GENITIVE)], и вас окатывает потоком шипящей жидкости! А-а-а!!"),
		)
		burst_soda(user)
		return

	to_chat(user, span_notice("Вы открываете [declent_ru(ACCUSATIVE)] с приятным хлопком."))
	container_type |= OPENCONTAINER
	playsound(src, SFX_CAN_OPEN, 50, TRUE)
	throwforce = 0

/obj/item/reagent_containers/cup/soda_cans/proc/burst_soda(atom/target, hide_message = FALSE)
	if(!target)
		return

	playsound(src, 'sound/items/can/can_pop.ogg', 80, TRUE)
	if(!hide_message)
		visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] вскипает и обдаёт своим содержимым [target.declent_ru(ACCUSATIVE)]!"))
	container_type |= OPENCONTAINER
	reagents.reaction(target, REAGENT_TOUCH)
	reagents.clear_reagents()
	throwforce = 0

/obj/item/reagent_containers/cup/soda_cans/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(. || is_open_container() || !reagents.total_volume)
		return

	fizziness += SODA_FIZZINESS_THROWN
	if(!prob(fizziness))
		return

	burst_soda(hit_atom, hide_message = TRUE)
	visible_message(span_danger("[DECLENT_RU_CAP(src, NOMINATIVE)] лопается от удара о [hit_atom.declent_ru(ACCUSATIVE)], разбрызгивая всё вокруг!"))
	crush(loc)
	moveToNullspace()
	QDEL_IN(src, 1 SECONDS)

/obj/item/reagent_containers/cup/soda_cans/attack_self(mob/user)
	if(!is_drainable())
		open_soda(user)
		return
	return ..()

/obj/item/reagent_containers/cup/soda_cans/attack_self_secondary(mob/user, list/modifiers)
	if(!is_drainable())
		playsound(src, 'sound/items/can/can_shake.ogg', 50, TRUE)
		user.visible_message(
			span_danger("[user] встряхива[PLUR_ET_YUT(user)] [declent_ru(ACCUSATIVE)]!"),
			span_danger("Вы встряхиваете [declent_ru(ACCUSATIVE)]!"),
		)
		fizziness += SODA_FIZZINESS_SHAKE
		return
	return ..()

/obj/item/reagent_containers/cup/soda_cans/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return air.return_pressure() <= SODA_EXPLOSION_PRESSURE && !is_drainable()

/obj/item/reagent_containers/cup/soda_cans/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	if(reagents.total_volume && !is_drainable())
		burst_soda(loc)

#undef SODA_FIZZINESS_THROWN
#undef SODA_FIZZINESS_SHAKE
#undef SODA_EXPLOSION_PRESSURE

// MARK: Can Types
/obj/item/reagent_containers/cup/soda_cans/cola
	name = "space cola"
	desc = "Это кола. Нестареющая классика."
	icon_state = "cola"
	list_reagents = list("cola" = 30)

/obj/item/reagent_containers/cup/soda_cans/cola/get_ru_names()
	return alist(
		NOMINATIVE = "банка колы",
		GENITIVE = "банки колы",
		DATIVE = "банке колы",
		ACCUSATIVE = "банку колы",
		INSTRUMENTAL = "банкой колы",
		PREPOSITIONAL = "банке колы",
	)

/obj/item/reagent_containers/cup/soda_cans/energy
	name = "heart attack"
	desc = "Пока сердце вам не скажет - \"Моя остановка\"."
	icon_state = "heart_attack"
	item_state = "heart_attack"
	list_reagents = list("energetik" = 30)

/obj/item/reagent_containers/cup/soda_cans/energy/get_ru_names()
	return alist(
		NOMINATIVE = "банка энергетика \"Сердечный Приступ\"",
		GENITIVE = "банки энергетика \"Сердечный Приступ\"",
		DATIVE = "банке энергетика \"Сердечный Приступ\"",
		ACCUSATIVE = "банку энергетика \"Сердечный Приступ\"",
		INSTRUMENTAL = "банкой энергетика \"Сердечный Приступ\"",
		PREPOSITIONAL = "банке энергетика \"Сердечный Приступ\"",
	)

/obj/item/reagent_containers/cup/soda_cans/energy/trop
	name = "tropical spasm"
	desc = "Почувствуйте бодрящий вкус тропических фруктов!"
	icon_state = "tropical_spasm"
	item_state = "tropical_spasm"
	list_reagents = list("trop_eng" = 30)

/obj/item/reagent_containers/cup/soda_cans/energy/trop/get_ru_names()
	return alist(
		NOMINATIVE = "банка энергетика \"Тропический Спазм\"",
		GENITIVE = "банки энергетика \"Тропический Спазм\"",
		DATIVE = "банке энергетика \"Тропический Спазм\"",
		ACCUSATIVE = "банку энергетика \"Тропический Спазм\"",
		INSTRUMENTAL = "банкой энергетика \"Тропический Спазм\"",
		PREPOSITIONAL = "банке энергетика \"Тропический Спазм\"",
	)

/obj/item/reagent_containers/cup/soda_cans/energy/milk
	name = "milk flow"
	desc = "Для самых профессиональных геймеров."
	icon_state = "milk_flow"
	item_state = "milk_flow"
	list_reagents = list("milk_eng" = 30)

/obj/item/reagent_containers/cup/soda_cans/energy/milk/get_ru_names()
	return alist(
		NOMINATIVE = "банка энергетика \"Молочный Удар\"",
		GENITIVE = "банки энергетика \"Молочный Удар\"",
		DATIVE = "банке энергетика \"Молочный Удар\"",
		ACCUSATIVE = "банку энергетика \"Молочный Удар\"",
		INSTRUMENTAL = "банкой энергетика \"Молочный Удар\"",
		PREPOSITIONAL = "банке энергетика \"Молочный Удар\"",
	)

/obj/item/reagent_containers/cup/soda_cans/energy/grey
	name = "GreyPower"
	desc = "Ваши руки будут гореть от \"Грей Энерджи\"."
	icon_state = "GreyPower"
	item_state = "GreyPower"
	list_reagents = list("grey_eng" = 30)

/obj/item/reagent_containers/cup/soda_cans/energy/grey/get_ru_names()
	return alist(
		NOMINATIVE = "банка энергетика \"Грей Энерджи\"",
		GENITIVE = "банки энергетика \"Грей Энерджи\"",
		DATIVE = "банке энергетика \"Грей Энерджи\"",
		ACCUSATIVE = "банку энергетика \"Грей Энерджи\"",
		INSTRUMENTAL = "банкой энергетика \"Грей Энерджи\"",
		PREPOSITIONAL = "банке энергетика \"Грей Энерджи\"",
	)

/obj/item/reagent_containers/cup/soda_cans/beer
	name = "space beer"
	desc = "Вода, солод и хмель — а больше и не требуется."
	icon_state = "beer"
	is_glass = 1
	list_reagents = list("beer" = 30)

/obj/item/reagent_containers/cup/soda_cans/beer/almost_empty
	list_reagents = list("beer" = 1)

/obj/item/reagent_containers/cup/soda_cans/beer/get_ru_names()
	return alist(
		NOMINATIVE = "бутылка пива",
		GENITIVE = "бутылки пива",
		DATIVE = "бутылке пива",
		ACCUSATIVE = "бутылку пива",
		INSTRUMENTAL = "бутылкой пива",
		PREPOSITIONAL = "бутылке пива",
	)

/obj/item/reagent_containers/cup/soda_cans/non_alcoholic_beer
	name = "non-alcoholic beer"
	desc = "Любимое пойло студентов и тех, кто за рулём."
	icon_state = "alcoholfreebeercan"
	list_reagents = list("noalco_beer" = 30)

/obj/item/reagent_containers/cup/soda_cans/non_alcoholic_beer/get_ru_names()
	return alist(
		NOMINATIVE = "бутылка безалкогольного пива",
		GENITIVE = "бутылки безалкогольного пива",
		DATIVE = "бутылке безалкогольного пива",
		ACCUSATIVE = "бутылку безалкогольного пива",
		INSTRUMENTAL = "бутылкой безалкогольного пива",
		PREPOSITIONAL = "бутылке безалкогольного пива",
	)

/obj/item/reagent_containers/cup/soda_cans/adminbooze
	name = "admin booze"
	desc = "Бутылированные слёзы Гриффона. Пить со всей осторожностью."
	icon_state = "adminbooze"
	is_glass = 1
	list_reagents = list("adminordrazine" = 5, "capsaicin" = 5, "methamphetamine"= 20, "thirteenloko" = 20)

/obj/item/reagent_containers/cup/soda_cans/adminbooze/get_ru_names()
	return alist(
		NOMINATIVE = "бутылка настойки \"Админово Пойло\"",
		GENITIVE = "бутылки настойки \"Админово Пойло\"",
		DATIVE = "бутылке настойки \"Админово Пойло\"",
		ACCUSATIVE = "бутылку настойки \"Админово Пойло\"",
		INSTRUMENTAL = "бутылкой настойки \"Админово Пойло\"",
		PREPOSITIONAL = "бутылке настойки \"Админово Пойло\"",
	)

/obj/item/reagent_containers/cup/soda_cans/madminmalt
	name = "madmin malt"
	desc = "Бутылированная эссенция ярости администрации. Пить с <i>ПРЕДЕЛЬНОЙ</i> осторожностью."
	icon_state = "madminmalt"
	is_glass = 1
	list_reagents = list("hell_water" = 20, "neurotoxin" = 15, "thirteenloko" = 15)

/obj/item/reagent_containers/cup/soda_cans/madminmalt/get_ru_names()
	return alist(
		NOMINATIVE = "бутылка настойки \"Ярость Админа\"",
		GENITIVE = "бутылки настойки \"Ярость Админа\"",
		DATIVE = "бутылке настойки \"Ярость Админа\"",
		ACCUSATIVE = "бутылку настойки \"Ярость Админа\"",
		INSTRUMENTAL = "бутылкой настойки \"Ярость Админа\"",
		PREPOSITIONAL = "бутылке настойки \"Ярость Админа\"",
	)

/obj/item/reagent_containers/cup/soda_cans/badminbrew
	name = "badmin brew"
	desc = "Бутылированная эссенция со вкусом щитспавна и ужасных ивентов. Наверное, это вам пить не стоит."
	icon_state = "badminbrew"
	is_glass = 1
	list_reagents = list("mutagen" = 25, "charcoal" = 10, "thirteenloko" = 15)

/obj/item/reagent_containers/cup/soda_cans/badminbrew/get_ru_names()
	return alist(
		NOMINATIVE = "бутылка настойки \"Плохой Админ\"",
		GENITIVE = "бутылки настойки \"Плохой Админ\"",
		DATIVE = "бутылке настойки \"Плохой Админ\"",
		ACCUSATIVE = "бутылку настойки \"Плохой Админ\"",
		INSTRUMENTAL = "бутылкой настойки \"Плохой Админ\"",
		PREPOSITIONAL = "бутылке настойки \"Плохой Админ\"",
	)

/obj/item/reagent_containers/cup/soda_cans/ale
	name = "Tail Tells Tales Ale"
	desc = "К этикетке прикреплён хвостик, который тянется по всей длине банки. Если вы его оторвете, то сможете прочитать короткую легенду на его обратной стороне."
	icon_state = "alebottle"
	item_state = "beer"
	is_glass = 1
	list_reagents = list("ale" = 30)

/obj/item/reagent_containers/cup/soda_cans/ale/get_ru_names()
	return alist(
		NOMINATIVE = "бутылка эля \"Хвостатые Истории\"",
		GENITIVE = "бутылки эля \"Хвостатые Истории\"",
		DATIVE = "бутылке эля \"Хвостатые Истории\"",
		ACCUSATIVE = "бутылку эля \"Хвостатые Истории\"",
		INSTRUMENTAL = "бутылкой эля \"Хвостатые Истории\"",
		PREPOSITIONAL = "бутылке эля \"Хвостатые Истории\"",
	)

/obj/item/reagent_containers/cup/soda_cans/space_mountain_wind
	name = "Space Mountain Wind"
	desc = "Проходит насквозь, словно космический ветер."
	icon_state = "space_mountain_wind"
	list_reagents = list("spacemountainwind" = 30)

/obj/item/reagent_containers/cup/soda_cans/space_mountain_wind/get_ru_names()
	return alist(
		NOMINATIVE = "банка газировки \"Космический Маунтин Винд\"",
		GENITIVE = "банки газировки \"Космический Маунтин Винд\"",
		DATIVE = "банке газировки \"Космический Маунтин Винд\"",
		ACCUSATIVE = "банку газировки \"Космический Маунтин Винд\"",
		INSTRUMENTAL = "банкой газировки \"Космический Маунтин Винд\"",
		PREPOSITIONAL = "банке газировки \"Космический Маунтин Винд\"",
	)

/obj/item/reagent_containers/cup/soda_cans/thirteenloko
	name = "Thirteen Loko"
	desc = "Главный Врач предупредил, что употребление этого напитка может привести к судорогам, слепоте, опьянению или даже смерти. Пожалуйста, пейте осторожно."
	icon_state = "thirteen_loko"
	list_reagents = list("thirteenloko" = 25, "psilocybin" = 5)

/obj/item/reagent_containers/cup/soda_cans/thirteenloko/get_ru_names()
	return alist(
		NOMINATIVE = "банка алкогольной газировки \"Тринадцатый Локо\"",
		GENITIVE = "банки алкогольной газировки \"Тринадцатый Локо\"",
		DATIVE = "банке алкогольной газировки \"Тринадцатый Локо\"",
		ACCUSATIVE = "банку алкогольной газировки \"Тринадцатый Локо\"",
		INSTRUMENTAL = "банкой алкогольной газировки \"Тринадцатый Локо\"",
		PREPOSITIONAL = "банке алкогольной газировки \"Тринадцатый Локо\"",
	)

/obj/item/reagent_containers/cup/soda_cans/dr_gibb
	name = "Dr. Gibb"
	desc = "Освежающая смесь из 42 различных вкусов!"
	icon_state = "dr_gibb"
	list_reagents = list("dr_gibb" = 30)

/obj/item/reagent_containers/cup/soda_cans/dr_gibb/get_ru_names()
	return alist(
		NOMINATIVE = "банка газировки \"Доктор Гибб\"",
		GENITIVE = "банки газировки \"Доктор Гибб\"",
		DATIVE = "банке газировки \"Доктор Гибб\"",
		ACCUSATIVE = "банку газировки \"Доктор Гибб\"",
		INSTRUMENTAL = "банкой газировки \"Доктор Гибб\"",
		PREPOSITIONAL = "банке газировки \"Доктор Гибб\"",
	)

/obj/item/reagent_containers/cup/soda_cans/starkist
	name = "Star-kist"
	desc = "Вкус звёзд в жидком виде. И тунца..?"
	icon_state = "starkist"
	list_reagents = list("brownstar" = 30)

/obj/item/reagent_containers/cup/soda_cans/starkist/get_ru_names()
	return alist(
		NOMINATIVE = "банка газировки \"Стар-Кист\"",
		GENITIVE = "банки газировки \"Стар-Кист\"",
		DATIVE = "банке газировки \"Стар-Кист\"",
		ACCUSATIVE = "банку газировки \"Стар-Кист\"",
		INSTRUMENTAL = "банкой газировки \"Стар-Кист\"",
		PREPOSITIONAL = "банке газировки \"Стар-Кист\"",
	)

/obj/item/reagent_containers/cup/soda_cans/space_up
	name = "Space-Up"
	desc = "На вкус как дыра в обшивке у вас во рту. Да, звучит странно."
	icon_state = "space-up"
	list_reagents = list("space_up" = 30)

/obj/item/reagent_containers/cup/soda_cans/space_up/get_ru_names()
	return alist(
		NOMINATIVE = "банка газировки \"Спейс-Ап\"",
		GENITIVE = "банки газировки \"Спейс-Ап\"",
		DATIVE = "банке газировки \"Спейс-Ап\"",
		ACCUSATIVE = "банку газировки \"Спейс-Ап\"",
		INSTRUMENTAL = "банкой газировки \"Спейс-Ап\"",
		PREPOSITIONAL = "банке газировки \"Спейс-Ап\"",
	)

/obj/item/reagent_containers/cup/soda_cans/lemon_lime
	name = "Lemon-Lime"
	desc = "Терпкая газировка, состоящяя на 0,5% из натуральных цитрусовых!"
	icon_state = "lemon-lime"
	list_reagents = list("lemon_lime" = 30)

/obj/item/reagent_containers/cup/soda_cans/lemon_lime/get_ru_names()
	return alist(
		NOMINATIVE = "банка газировки \"Лимон-Лайм\"",
		GENITIVE = "банки газировки \"Лимон-Лайм\"",
		DATIVE = "банке газировки \"Лимон-Лайм\"",
		ACCUSATIVE = "банку газировки \"Лимон-Лайм\"",
		INSTRUMENTAL = "банкой газировки \"Лимон-Лайм\"",
		PREPOSITIONAL = "банке газировки \"Лимон-Лайм\"",
	)

/obj/item/reagent_containers/cup/soda_cans/iced_tea
	name = "Vrisk Serket Iced Tea"
	desc = "Этот сладкий, освежающий вкус южной земли. Так вот откуда он, да? Южная Земля, верно?"
	icon_state = "ice_tea_can"
	list_reagents = list("icetea" = 30)

/obj/item/reagent_containers/cup/soda_cans/iced_tea/get_ru_names()
	return alist(
		NOMINATIVE = "банка чая со льдом \"Вриск Секретный\"",
		GENITIVE = "банки чая со льдом \"Вриск Секретный\"",
		DATIVE = "банке чая со льдом \"Вриск Секретный\"",
		ACCUSATIVE = "банку чая со льдом \"Вриск Секретный\"",
		INSTRUMENTAL = "банкой чая со льдом \"Вриск Секретный\"",
		PREPOSITIONAL = "банке чая со льдом \"Вриск Секретный\"",
	)

/obj/item/reagent_containers/cup/soda_cans/grape_juice
	name = "Refreshing Purple Grapel Juice"
	desc = "500 страниц правил о том, как начать драку с этим соком!"
	icon_state = "purple_can"
	list_reagents = list("grapejuice" = 30)
/obj/item/reagent_containers/cup/soda_cans/grape_juice/get_ru_names()
	return alist(
		NOMINATIVE = "банка виноградного сока \"Освежающе-Фиолетовый\"",
		GENITIVE = "банки виноградного сока \"Освежающе-Фиолетовый\"",
		DATIVE = "банке виноградного сока \"Освежающе-Фиолетовый\"",
		ACCUSATIVE = "банку виноградного сока \"Освежающе-Фиолетовый\"",
		INSTRUMENTAL = "банкой виноградного сока \"Освежающе-Фиолетовый\"",
		PREPOSITIONAL = "банке виноградного сока \"Освежающе-Фиолетовый\"",
	)

/obj/item/reagent_containers/cup/soda_cans/tonic
	name = "T-Borg's Tonic Water"
	desc = "Вкус странный, но, по крайней мере, хинин держит Космическую Малярию на расстоянии."
	icon_state = "tonic"
	list_reagents = list("tonic" = 50)

/obj/item/reagent_containers/cup/soda_cans/tonic/get_ru_names()
	return alist(
		NOMINATIVE = "банка тоника \"Т-Борг\"",
		GENITIVE = "банки тоника \"Т-Борг\"",
		DATIVE = "банке тоника \"Т-Борг\"",
		ACCUSATIVE = "банку тоника \"Т-Борг\"",
		INSTRUMENTAL = "банкой тоника \"Т-Борг\"",
		PREPOSITIONAL = "банке тоника \"Т-Борг\"",
	)

/obj/item/reagent_containers/cup/soda_cans/sodawater
	name = "soda water"
	desc = "Вода с газами. Освежает и приятно щекочет во рту."
	icon_state = "sodawater"
	list_reagents = list("sodawater" = 50)

/obj/item/reagent_containers/cup/soda_cans/sodawater/get_ru_names()
	return alist(
		NOMINATIVE = "банка содовой",
		GENITIVE = "банки содовой",
		DATIVE = "банке содовой",
		ACCUSATIVE = "банку содовой",
		INSTRUMENTAL = "банкой содовой",
		PREPOSITIONAL = "банке содовой",
	)

/obj/item/reagent_containers/cup/soda_cans/synthanol
	name = "Beep's Classic Synthanol"
	desc = "Бухло для КПБ. Что бы там не находилось внутри, им нравится."
	icon_state = "synthanolcan"
	list_reagents = list("synthanol" = 50)

/obj/item/reagent_containers/cup/soda_cans/synthanol/get_ru_names()
	return alist(
		NOMINATIVE = "банка синтанола \"Биб Классический\"",
		GENITIVE = "банки синтанола \"Биб Классический\"",
		DATIVE = "банке синтанола \"Биб Классический\"",
		ACCUSATIVE = "банку синтанола \"Биб Классический\"",
		INSTRUMENTAL = "банкой синтанола \"Биб Классический\"",
		PREPOSITIONAL = "банке синтанола \"Биб Классический\"",
	)

/obj/item/reagent_containers/cup/soda_cans/sol_dry
	name = "Sol Dry"
	desc = "Может, от этого вашему животику станет лучше. А может, и нет."
	icon_state = "sol_dry"
	list_reagents = list("sol_dry" = 30)

/obj/item/reagent_containers/cup/soda_cans/sol_dry/get_ru_names()
	return alist(
		NOMINATIVE = "банка \"Сол Драй\"",
		GENITIVE = "банки \"Сол Драй\"",
		DATIVE = "банке \"Сол Драй\"",
		ACCUSATIVE = "банку \"Сол Драй\"",
		INSTRUMENTAL = "банкой \"Сол Драй\"",
		PREPOSITIONAL = "банке \"Сол Драй\"",
	)

/obj/item/reagent_containers/cup/soda_cans/pwr_game
	name = "Pwr Game"
	desc = "Единственный напиток с той СИЛОЙ, которой жаждут настоящие геймеры. Когда геймер говорит о геймерском топливе, он имеет в виду буквально это."
	icon_state = "purple_can"
	list_reagents = list("pwr_game" = 30)

/obj/item/reagent_containers/cup/soda_cans/pwr_game/get_ru_names()
	return alist(
		NOMINATIVE = "банка \"Пвр Гейм\"",
		GENITIVE = "банки \"Пвр Гейм\"",
		DATIVE = "банке \"Пвр Гейм\"",
		ACCUSATIVE = "банку \"Пвр Гейм\"",
		INSTRUMENTAL = "банкой \"Пвр Гейм\"",
		PREPOSITIONAL = "банке \"Пвр Гейм\"",
	)

/obj/item/reagent_containers/cup/soda_cans/shamblers
	name = "Shambler's juice"
	desc = "~Взболтай-ка мне Сока Шамблера!~"
	icon_state = "shamblers"
	list_reagents = list("shamblers" = 30)
	drink_type = SUGAR|JUNKFOOD

/obj/item/reagent_containers/cup/soda_cans/shamblers/get_ru_names()
	return alist(
		NOMINATIVE = "банка \"Сока Шамблера\"",
		GENITIVE = "банки \"Сока Шамблера\"",
		DATIVE = "банке \"Сока Шамблера\"",
		ACCUSATIVE = "банку \"Сока Шамблера\"",
		INSTRUMENTAL = "банкой \"Сока Шамблера\"",
		PREPOSITIONAL = "банке \"Сока Шамблера\"",
	)

/obj/item/reagent_containers/cup/soda_cans/shamblers/eldritch
	name = "Shambler's juice Eldritch Energy!"
	desc = "~С'О'К!~"
	icon_state = "shamblerseldritch"
	list_reagents = list("shamblers" = 30, "eldritch" = 5)

/obj/item/reagent_containers/cup/soda_cans/shamblers/eldritch/get_ru_names()
	return alist(
		NOMINATIVE = "банка \"Сока Шамблера: Потусторонняя Энергия!\"",
		GENITIVE = "банки \"Сока Шамблера: Потусторонняя Энергия!\"",
		DATIVE = "банке \"Сока Шамблера: Потусторонняя Энергия!\"",
		ACCUSATIVE = "банку \"Сока Шамблера: Потусторонняя Энергия!\"",
		INSTRUMENTAL = "банкой \"Сока Шамблера: Потусторонняя Энергия!\"",
		PREPOSITIONAL = "банке \"Сока Шамблера: Потусторонняя Энергия!\"",
	)

/obj/item/reagent_containers/cup/soda_cans/wellcheers
	name = "Wellcheers Juice"
	desc = "Странный фиолетовый напиток с запахом морской воды. Где-то вдалеке слышны чайки."
	icon_state = "wellcheers"
	list_reagents = list("wellcheers" = 30)
	drink_type = SUGAR|JUNKFOOD

/obj/item/reagent_containers/cup/soda_cans/wellcheers/get_ru_names()
	return alist(
		NOMINATIVE = "банка сока \"Веллчирс\"",
		GENITIVE = "банки сока \"Веллчирс\"",
		DATIVE = "банке сока \"Веллчирс\"",
		ACCUSATIVE = "банку сока \"Веллчирс\"",
		INSTRUMENTAL = "банкой сока \"Веллчирс\"",
		PREPOSITIONAL = "банке сока \"Веллчирс\"",
	)

/obj/item/reagent_containers/cup/soda_cans/grey_bull
	name = "Grey Bull"
	desc = "Грей Булл окрыляет перчатками!"
	icon_state = "energy_drink"
	list_reagents = list("grey_bull" = 20)
	drink_type = SUGAR|JUNKFOOD

/obj/item/reagent_containers/cup/soda_cans/grey_bull/get_ru_names()
	return alist(
		NOMINATIVE = "банка \"Грей Булл\"",
		GENITIVE = "банки \"Грей Булл\"",
		DATIVE = "банке \"Грей Булл\"",
		ACCUSATIVE = "банку \"Грей Булл\"",
		INSTRUMENTAL = "банкой \"Грей Булл\"",
		PREPOSITIONAL = "банке \"Грей Булл\"",
	)

/obj/item/reagent_containers/cup/soda_cans/monkey_energy
	name = "Monkey Energy"
	desc = "Выпусти обезьяну наружу!"
	icon_state = "monkey_energy"
	list_reagents = list("monkey_energy" = 50)
	drink_type = SUGAR|JUNKFOOD

/obj/item/reagent_containers/cup/soda_cans/monkey_energy/get_ru_names()
	return alist(
		NOMINATIVE = "банка \"Манки Энерджи\"",
		GENITIVE = "банки \"Манки Энерджи\"",
		DATIVE = "банке \"Манки Энерджи\"",
		ACCUSATIVE = "банку \"Манки Энерджи\"",
		INSTRUMENTAL = "банкой \"Манки Энерджи\"",
		PREPOSITIONAL = "банке \"Манки Энерджи\"",
	)

/obj/item/reagent_containers/cup/soda_cans/volt_energy
	name = "24-Volt Energy"
	desc = "Подзарядись с 24-Вольт Энерджи!"
	icon_state = "volt_energy"
	list_reagents = list("volt_energy" = 30)
	drink_type = SUGAR|JUNKFOOD

/obj/item/reagent_containers/cup/soda_cans/volt_energy/get_ru_names()
	return alist(
		NOMINATIVE = "банка \"24-Вольт Энерджи\"",
		GENITIVE = "банки \"24-Вольт Энерджи\"",
		DATIVE = "банке \"24-Вольт Энерджи\"",
		ACCUSATIVE = "банку \"24-Вольт Энерджи\"",
		INSTRUMENTAL = "банкой \"24-Вольт Энерджи\"",
		PREPOSITIONAL = "банке \"24-Вольт Энерджи\"",
	)

/obj/item/reagent_containers/cup/soda_cans/melon_soda
	name = "Kansumi Melon Soda"
	desc = "Любимая дынная газировка Японии, теперь в банке!"
	icon_state = "melon_soda"
	list_reagents = list("melon_soda" = 30)
	drink_type = SUGAR|JUNKFOOD

/obj/item/reagent_containers/cup/soda_cans/melon_soda/get_ru_names()
	return alist(
		NOMINATIVE = "банка дынной газировки \"Кансуми\"",
		GENITIVE = "банки дынной газировки \"Кансуми\"",
		DATIVE = "банке дынной газировки \"Кансуми\"",
		ACCUSATIVE = "банку дынной газировки \"Кансуми\"",
		INSTRUMENTAL = "банкой дынной газировки \"Кансуми\"",
		PREPOSITIONAL = "банке дынной газировки \"Кансуми\"",
	)

/obj/item/reagent_containers/cup/soda_cans/air
	name = "canned air"
	desc = "Дефицита воздуха нет. Не пить."
	icon_state = "air"
	item_state = "sodawater"
	list_reagents = list("nitrogen" = 24, "oxygen" = 6)
	drink_type = NONE

/obj/item/reagent_containers/cup/soda_cans/air/get_ru_names()
	return alist(
		NOMINATIVE = "консервированный воздух",
		GENITIVE = "консервированного воздуха",
		DATIVE = "консервированному воздуху",
		ACCUSATIVE = "консервированный воздух",
		INSTRUMENTAL = "консервированным воздухом",
		PREPOSITIONAL = "консервированном воздухе",
	)

/obj/item/reagent_containers/cup/soda_cans/beer/rice
	name = "rice beer"
	desc = "Лёгкое рисовое лагерное пиво, популярное на Марсе. По Закону о чистоте пива 1516 года считается преступлением против баварцев."
	icon_state = "ebisu"
	is_glass = FALSE
	list_reagents = list("rice_beer" = 40)
	drink_type = GRAIN

/obj/item/reagent_containers/cup/soda_cans/beer/rice/Initialize(mapload, vol)
	. = ..()
	var/brand = pick("Ebisu Super Dry", "Shimauma Ichiban", "Moonlabor Malt's")
	name = brand
	switch(brand)
		if("Ebisu Super Dry")
			icon_state = "ebisu"
			desc = "Любимая марка рисового пива на Марсе вот уже 200 лет."
		if("Shimauma Ichiban")
			icon_state = "shimauma"
			desc = "Самая заурядная марка рисового пива на Марсе. Не так популярна, как Эбису, но уютно устроилась на втором месте."
		if("Moonlabor Malt's")
			icon_state = "moonlabor"
			desc = "Марка рисового пива-аутсайдер с Марса. По неизвестным причинам популярна у якудзы."
	ru_names = alist(
		NOMINATIVE = "банка пива \"[brand]\"",
		GENITIVE = "банки пива \"[brand]\"",
		DATIVE = "банке пива \"[brand]\"",
		ACCUSATIVE = "банку пива \"[brand]\"",
		INSTRUMENTAL = "банкой пива \"[brand]\"",
		PREPOSITIONAL = "банке пива \"[brand]\"",
	)

/obj/item/reagent_containers/cup/soda_cans/beer/rice/get_ru_names()
	return alist(
		NOMINATIVE = "банка рисового пива",
		GENITIVE = "банки рисового пива",
		DATIVE = "банке рисового пива",
		ACCUSATIVE = "банку рисового пива",
		INSTRUMENTAL = "банкой рисового пива",
		PREPOSITIONAL = "банке рисового пива",
	)

/obj/item/reagent_containers/cup/soda_cans/random
	name = "random soda can"
	icon_state = "cola"

/obj/item/reagent_containers/cup/soda_cans/random/Initialize(mapload, vol)
	. = ..()
	var/static/list/excluded_cans = typesof(/obj/item/reagent_containers/cup/soda_cans/bottler) + list(
		/obj/item/reagent_containers/cup/soda_cans/random,
		/obj/item/reagent_containers/cup/soda_cans/adminbooze,
		/obj/item/reagent_containers/cup/soda_cans/madminmalt,
		/obj/item/reagent_containers/cup/soda_cans/badminbrew,
		/obj/item/reagent_containers/cup/soda_cans/beer/almost_empty,
	)
	var/can_type = pick(subtypesof(/obj/item/reagent_containers/cup/soda_cans) - excluded_cans)
	new can_type(loc)
	return INITIALIZE_HINT_QDEL

// MARK: Bottler Stuff
/obj/item/reagent_containers/cup/soda_cans/bottler
	name = "generic beverage container"
	desc = "Это даже не должно быть заспавненным. Позор тебе, педаль."
	icon_state = "glass_bottle"
	fill_icon_thresholds = list(1, 10, 20, 30, 40, 50)

/obj/item/reagent_containers/cup/soda_cans/bottler/get_ru_names()
	return alist(
		NOMINATIVE = "ёмкость для стандартного напитка",
		GENITIVE = "ёмкости для стандартного напитка",
		DATIVE = "ёмкости для стандартного напитка",
		ACCUSATIVE = "ёмкость для стандартного напитка",
		INSTRUMENTAL = "ёмкостью для стандартного напитка",
		PREPOSITIONAL = "ёмкости для стандартного напитка",
	)

/obj/item/reagent_containers/cup/soda_cans/bottler/glass_bottle
	name = "glass bottle"
	desc = "Стеклянная бутылка, подходящая для напитков."
	is_glass = 1

/obj/item/reagent_containers/cup/soda_cans/bottler/glass_bottle/get_ru_names()
	return alist(
		NOMINATIVE = "стеклянная бутылка",
		GENITIVE = "стеклянной бутылки",
		DATIVE = "стеклянной бутылке",
		ACCUSATIVE = "стеклянную бутылку",
		INSTRUMENTAL = "стеклянной бутылкой",
		PREPOSITIONAL = "стеклянной бутылке",
	)

/obj/item/reagent_containers/cup/soda_cans/bottler/plastic_bottle
	name = "plastic bottle"
	desc = "Пластиковая бутылка, подходящая для напитков."
	icon_state = "plastic_bottle"
	is_plastic = 1

/obj/item/reagent_containers/cup/soda_cans/bottler/plastic_bottle/get_ru_names()
	return alist(
		NOMINATIVE = "пластиковая бутылка",
		GENITIVE = "пластиковой бутылки",
		DATIVE = "пластиковой бутылке",
		ACCUSATIVE = "пластиковую бутылку",
		INSTRUMENTAL = "пластиковой бутылкой",
		PREPOSITIONAL = "пластиковой бутылке",
	)

/obj/item/reagent_containers/cup/soda_cans/bottler/metal_can
	name = "metal can"
	desc = "A metal can suitable for beverages."
	icon_state = "metal_can"

/obj/item/reagent_containers/cup/soda_cans/bottler/metal_can/get_ru_names()
	return alist(
		NOMINATIVE = "металлическая банка",
		GENITIVE = "металлической банки",
		DATIVE = "металлической банке",
		ACCUSATIVE = "металлическую банку",
		INSTRUMENTAL = "металлической банкой",
		PREPOSITIONAL = "металлической банке",
	)
