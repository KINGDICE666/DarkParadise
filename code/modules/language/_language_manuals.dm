/obj/item/language_manual
	name = "language manual"
	icon = 'icons/obj/library.dmi'
	icon_state = "book2"
	w_class = WEIGHT_CLASS_SMALL
	var/charges = 1
	var/datum/language/language = /datum/language/common
	var/flavour_text = "ваш разум внезапно наполняется кодовыми словами и ответами на них"

/obj/item/language_manual/get_ru_names()
	return alist(
		NOMINATIVE = "учебник языка",
		GENITIVE = "учебника языка",
		DATIVE = "учебнику языка",
		ACCUSATIVE = "учебник языка",
		INSTRUMENTAL = "учебником языка",
		PREPOSITIONAL = "учебнике языка",
	)

/obj/item/language_manual/attack_self(mob/living/user)
	if(!isliving(user))
		return

	if(user.has_language(language))
		to_chat(user, span_boldwarning("Вы начинаете листать [declent_ru(ACCUSATIVE)], но вы уже знаете [initial(language.name)]."))
		return

	to_chat(user, span_bolddanger("Вы начинаете листать [declent_ru(ACCUSATIVE)], и [flavour_text]."))

	user.grant_language(language, source = LANGUAGE_MIND)
	user.remove_blocked_language(language, source = LANGUAGE_ALL)

	use_charge(user)

/obj/item/language_manual/attack(mob/living/target, mob/living/user, list/modifiers, def_zone, skip_attack_anim = FALSE)
	if(!istype(target) || !istype(user))
		return ATTACK_CHAIN_PROCEED
	if(target == user)
		attack_self(user)
		return ATTACK_CHAIN_PROCEED_SUCCESS

	playsound(loc, SFX_PUNCH, 25, TRUE, -1)

	if(target.stat == DEAD)
		target.visible_message(span_danger("[user] шлёпа[PLUR_ET_YUT(user)] безжизненное тело [target] [declent_ru(INSTRUMENTAL)]."), span_userdanger("[user] шлёпа[PLUR_ET_YUT(user)] ваше безжизненное тело [declent_ru(INSTRUMENTAL)]."), span_hear("Вы слышите шлепки."))
	else if(target.has_language(language))
		target.visible_message(span_danger("[user] бь[PLUR_ET_YUT(user)] [target] по голове [declent_ru(INSTRUMENTAL)]!"), span_userdanger("[user] бь[PLUR_ET_YUT(user)] вас по голове [declent_ru(INSTRUMENTAL)]!"), span_hear("Вы слышите шлепки."))
	else
		target.visible_message(span_notice("[user] обуча[PLUR_ET_YUT(user)] [target], колотя по голове [declent_ru(INSTRUMENTAL)]!"), span_boldnotice("Когда [user] бь[PLUR_ET_YUT(user)] вас [declent_ru(INSTRUMENTAL)], [flavour_text]."), span_hear("Вы слышите шлепки."))
		target.grant_language(language, source = LANGUAGE_MIND)
		use_charge(user)
	return ATTACK_CHAIN_PROCEED_SUCCESS

/obj/item/language_manual/proc/use_charge(mob/user)
	charges--
	if(charges)
		return
	user.visible_message(span_notice("Обложка книги в руках [user] начинает меняться! Книга выскальзывает у [GEND_HIS_HER(user)] из рук!"), span_warning("Обложка и содержимое [declent_ru(GENITIVE)] начинают меняться! Книга выскальзывает у вас из рук!"))
	new /obj/item/book(get_turf(src))
	qdel(src)

/obj/item/language_manual/codespeak_manual
	name = "codespeak manual"
	desc = "Надпись на обложке гласит: «Кодовый язык™ — защитите свои переговоры метафорами настолько вычурными, что они кажутся случайными!»"
	language = /datum/language/codespeak

/obj/item/language_manual/codespeak_manual/get_ru_names()
	return alist(
		NOMINATIVE = "учебник кодового языка",
		GENITIVE = "учебника кодового языка",
		DATIVE = "учебнику кодового языка",
		ACCUSATIVE = "учебник кодового языка",
		INSTRUMENTAL = "учебником кодового языка",
		PREPOSITIONAL = "учебнике кодового языка",
	)

/obj/item/language_manual/codespeak_manual/unlimited
	name = "deluxe codespeak manual"
	charges = INFINITY

/obj/item/language_manual/codespeak_manual/unlimited/get_ru_names()
	return alist(
		NOMINATIVE = "подарочный учебник кодового языка",
		GENITIVE = "подарочного учебника кодового языка",
		DATIVE = "подарочному учебнику кодового языка",
		ACCUSATIVE = "подарочный учебник кодового языка",
		INSTRUMENTAL = "подарочным учебником кодового языка",
		PREPOSITIONAL = "подарочном учебнике кодового языка",
	)

/obj/item/language_manual/piratespeak
	name = "Captain Pete's Guide to Pirate Lingo"
	desc = "Книга со всеми знаниями, жаргоном и словечками, нужными, чтобы говорить как настоящий морской волк."
	language = /datum/language/piratespeak
	flavour_text = "тысяча чертей! Вы чувствуете себя куда меньшей сухопутной крысой"
	charges = 5

/obj/item/language_manual/piratespeak/get_ru_names()
	return alist(
		NOMINATIVE = "пиратский разговорник капитана Пита",
		GENITIVE = "пиратского разговорника капитана Пита",
		DATIVE = "пиратскому разговорнику капитана Пита",
		ACCUSATIVE = "пиратский разговорник капитана Пита",
		INSTRUMENTAL = "пиратским разговорником капитана Пита",
		PREPOSITIONAL = "пиратском разговорнике капитана Пита",
	)

/obj/item/language_manual/dronespeak_manual
	name = "dronespeak manual"
	desc = "Надпись на обложке гласит: «Понимая язык дронов — упражнение в бессмысленности». Книга целиком написана двоичным кодом, вряд ли кто-то кроме синтетиков её поймёт."
	icon_state = "drone_manual"
	language = /datum/language/drone
	flavour_text = "стрёкот дронов внезапно обретает смысл"
	charges = INFINITY

/obj/item/language_manual/dronespeak_manual/get_ru_names()
	return alist(
		NOMINATIVE = "учебник языка дронов",
		GENITIVE = "учебника языка дронов",
		DATIVE = "учебнику языка дронов",
		ACCUSATIVE = "учебник языка дронов",
		INSTRUMENTAL = "учебником языка дронов",
		PREPOSITIONAL = "учебнике языка дронов",
	)

/obj/item/language_manual/dronespeak_manual/attack(mob/living/target, mob/living/user, list/modifiers, def_zone, skip_attack_anim = FALSE)
	if(!(isdrone(target) || issilicon(target)))
		target.visible_message(span_danger("[user] бь[PLUR_ET_YUT(user)] [target] по голове [declent_ru(INSTRUMENTAL)]!"), span_userdanger("[user] бь[PLUR_ET_YUT(user)] вас по голове [declent_ru(INSTRUMENTAL)]!"), span_hear("Вы слышите шлепки."))
		return ATTACK_CHAIN_PROCEED_SUCCESS

	return ..()

/obj/item/language_manual/dronespeak_manual/attack_self(mob/living/user)
	if(!(isdrone(user) || issilicon(user)))
		to_chat(user, span_danger("Вы бьёте себя по голове [declent_ru(INSTRUMENTAL)]!"))
		return

	return ..()
