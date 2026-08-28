// Мины повстанцев и их разминирование.
//
// Мина закопана: в мире она прозрачна и не видна никому. Кто её видит — решает не сама
// мина, а список зрителей: повстанцы видят всё поле всегда, морпех — только пока на нём
// сапёрные очки. Взрыватель при этом не разбирает своих и чужих: повстанец, забывший,
// где закопал, подорвётся на своей же мине.
//
// Видимость раздаётся ХУДом, а не невидимостью атома. Невидимость в BYOND — свойство
// самого объекта, одно на всех, а нам нужно по-разному разным игрокам.
//
// Именно ХУДом, а не своим списком картинок в client.images: клиент после реконнекта
// новый и список у него пустой, а ХУД мобу возвращается сам — /mob/Login() зовёт
// reload_huds(). Тот же датум сам следит за z-уровнями и снимает картинку удалённой
// мины по COMSIG_QDELETING. Свой ХУД, а не строка в GLOB.huds: у режима он один на
// раунд и категория в общем списке ему не нужна (uses_global_hud_category = FALSE).
//
// Снимается кусачками или мультитулом. Инструмент лежит в поясе у сапёров обеих сторон,
// остальным мину придётся обходить или накрывать взрывом: чужой взрыв её детонирует.

/// Категория ХУДа мин — ключ в hud_list самой мины.
#define MW_MINE_HUD "mw_mine_hud"

/datum/atom_hud/mw_mines
	hud_icons = list(MW_MINE_HUD)
	uses_global_hud_category = FALSE

GLOBAL_DATUM_INIT(mw_mine_hud, /datum/atom_hud/mw_mines, new)

/// Сколько закапывается мина.
#define MW_MINE_PLANT_TIME (4 SECONDS)
/// Сколько снимается чужая мина.
#define MW_MINE_DEFUSE_TIME (12 SECONDS)
/// Свою сапёр снимает быстрее: он знает, как она поставлена.
#define MW_MINE_OWN_DEFUSE_TIME (4 SECONDS)

// MARK: Мина в руках
/obj/item/mw_mine
	name = "противопехотная мина"
	desc = "Нажимная мина в пластиковом корпусе. Ставится на грунт, снимается кусачками или мультитулом."
	icon_state = "uglymine"
	item_state = "electronic"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/mw_mine/attack_self(mob/user)
	var/turf/ground = get_turf(user)
	if(!isfloorturf(ground))
		balloon_alert(user, "не тот грунт")
		return
	if(locate(/obj/effect/mine) in ground)
		balloon_alert(user, "здесь уже мина")
		return
	balloon_alert(user, "закапываем...")
	if(!do_after(user, MW_MINE_PLANT_TIME, user))
		return
	// За четыре секунды мину могли выронить, а на клетку — поставить вторую.
	if(loc != user || (locate(/obj/effect/mine) in ground))
		return
	var/obj/effect/mine/mw/mine = new(ground)
	mine.owner_faction = mountain_wars_faction(user)
	mine.planter_key = key_name(user)
	to_chat(user, span_notice("Вы устанавливаете [name]. Свои её не заденут."))
	qdel(src)

// MARK: Мина в грунте
/obj/effect/mine/mw
	name = "мина"
	desc = "Из грунта торчит только крышка взрывателя."
	layer = LOW_OBJ_LAYER
	// Сам объект прозрачен: картинку зрителям выдаёт marker. Клик по клетке при этом
	// проходит — иначе обезвредить мину было бы нечем, курсор её просто не находил бы.
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	/// Фракция, поставившая мину. На взрыватель не влияет — только на скорость снятия.
	var/owner_faction
	/// Кто ставил — строкой, для логов. Ссылку на моба тут держать незачем.
	var/planter_key
	/// Картинка для тех, кто мину видит.
	var/image/marker
	var/range_heavy = 1
	var/range_light = 3
	var/range_flash = 4

/obj/effect/mine/mw/Initialize(mapload)
	. = ..()
	// Картинка вешается на клетку, а не на саму мину. Мина прозрачна (alpha = 0), и
	// привязанная к ней метка не показывалась никому — включая тех, кто мину ставил.
	// Клетка видна всегда, а мина не ходит, так что привязка к ней ничего не теряет.
	marker = image(icon, loc, icon_state, layer)
	// Метка детектора, а не сама мина: в пыли её надо замечать издалека.
	marker.color = "#ff6a4a"
	marker.appearance_flags |= RESET_COLOR | RESET_ALPHA
	// Списки заполняем руками, без prepare_huds(): тот берёт кадр из общего icons/mob/hud.dmi
	// по hud_possible, а у метки свой — перекрашенный кадр самой мины.
	hud_list = list(MW_MINE_HUD = marker)
	active_hud_list = list(MW_MINE_HUD = marker)
	GLOB.mw_mine_hud.add_atom_to_hud(src)

/obj/effect/mine/mw/Destroy()
	// Метку у зрителей снимает сам ХУД: COMSIG_QDELETING рассылается до Destroy, и к
	// этой строке мина из ХУДа уже выписана. Здесь остаётся только отпустить ссылки.
	hud_list = null
	active_hud_list = null
	marker = null
	return ..()

/// Замечает ли боец эту мину. Кто не замечает — тот и потрогать её не может.
/obj/effect/mine/mw/proc/spotted_by(mob/user)
	return user && GLOB.mw_mine_hud.hud_users_all_z_levels[user]

// Чужой осмотр не должен выдавать мину: для не видящего под ногами просто грунт.
/obj/effect/mine/mw/examine(mob/user)
	if(!spotted_by(user))
		return list()
	. = ..()
	if(owner_faction && mountain_wars_faction(user) == owner_faction)
		. += span_notice("Мина ваша. Наступите — сработает так же, как на чужом.")
	. += span_warning("Обезвредить можно кусачками или мультитулом.")

// Родительский взрыватель смотрит на список faction у моба. Нам фракция безразлична:
// мина нажимная и своих не узнаёт, повстанцев спасает только то, что они её видят.
// А кроме пехоты на мину заезжает техника, и та вообще не моб.
//
// SIGNAL_HANDLER здесь не повторяем, хотя проц им и остаётся: макрос разворачивается в
// set SpacemanDMM_should_not_sleep, а такие настройки движок берёт только с первого
// объявления проца — оно у родителя. В переопределении dreamchecker считает это ошибкой.
/obj/effect/mine/mw/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	// По земле едет не сама машина, а её невидимый габарит.
	if(istype(arrived, /obj/vehicle/mw) || istype(arrived, /obj/mw_hitbox))
		INVOKE_ASYNC(src, PROC_REF(triggermine), arrived)
		return

	if(!isliving(arrived))
		return
	var/mob/living/walker = arrived
	if(walker.anchored || HAS_TRAIT(walker, TRAIT_WALLMOUNTED))
		return
	if(walker.movement_type & MOVETYPES_NOT_TOUCHING_GROUND)
		return
	INVOKE_ASYNC(src, PROC_REF(triggermine), walker)

/obj/effect/mine/mw/triggermine(atom/movable/victim)
	if(triggered)
		return
	triggered = TRUE
	visible_message(span_boldwarning("[victim] задевает мину!"))
	if(isliving(victim))
		add_attack_logs(victim, src, "Наступил на мину, поставленную [planter_key || "неизвестно кем"]")
	detonate()

/obj/effect/mine/mw/proc/detonate()
	if(QDELETED(src))
		return
	explosion(loc, heavy_impact_range = range_heavy, light_impact_range = range_light, flash_range = range_flash, cause = "Мина ([planter_key])")
	qdel(src)

// Чужой взрыв мину детонирует, а не просто стирает: артудар и граната — тоже способ
// разминировать проход, просто грубый.
//
// Через таймер, а не сразу. explosion() зовёт ex_act у всего в радиусе, и прямой вызов
// уложил бы цепное поле стеком вложенных взрывов: каждая мина подрывает соседок, не
// досчитав собственный радиус. Отложенный вызов раскладывает цепочку в очередь. Флаг
// стоит до таймера — второй раз ни одна мина сюда не зайдёт.
/obj/effect/mine/mw/ex_act(severity, target)
	if(triggered)
		return
	triggered = TRUE
	addtimer(CALLBACK(src, PROC_REF(detonate)), 1)

// Возврат — битфлаги цепочки атаки, не TRUE/FALSE: BLOCKED_ALL означает «удар разобран
// здесь, afterattack не нужен». На неснятой мине afterattack ещё и выдал бы её тому, кто
// её не видит: инструмент отзывается на цель, которой для игрока нет.
/obj/effect/mine/mw/attackby(obj/item/tool, mob/user, params)
	// Не видит — нечего и трогать: для него это пустая клетка, и щёлкать по ней
	// инструментом в поисках мин смысла нет.
	if(!spotted_by(user))
		return ATTACK_CHAIN_BLOCKED_ALL
	if(!iswirecutter(tool) && !ismultitool(tool))
		return ..()
	var/own = owner_faction && mountain_wars_faction(user) == owner_faction
	balloon_alert(user, own ? "снимаем..." : "обезвреживаем...")
	if(!do_after(user, own ? MW_MINE_OWN_DEFUSE_TIME : MW_MINE_DEFUSE_TIME, src))
		balloon_alert(user, "не дали закончить")
		return ATTACK_CHAIN_BLOCKED_ALL
	if(QDELETED(src))
		return ATTACK_CHAIN_BLOCKED_ALL
	// Мина уходит в руки целой: её можно унести и переставить уже под бывшего хозяина.
	var/obj/item/mw_mine/spoils = new(get_turf(user))
	user.put_in_hands(spoils)
	visible_message(span_notice("[user] обезвреживает [name]."))
	qdel(src)
	return ATTACK_CHAIN_BLOCKED_ALL

// MARK: Кто видит поле
// Зритель — моб, а не ckey: ХУД держит своих по мобам и сам возвращает картинки после
// реконнекта. Смена тела (смерть, гост, респавн) проходит через mw_refresh_mine_vision,
// её и хватает.
/// Включить или выключить игроку метки мин.
/proc/mw_mine_vision(mob/watcher, seeing)
	if(!watcher)
		return
	var/datum/atom_hud/hud = GLOB.mw_mine_hud
	if(!seeing)
		hud.hide_from(watcher, TRUE)
		return
	// show_to() на уже показанном ХУДе просто накручивает счётчик источников, и снять
	// его потом одним hide_from не вышло бы. Проверка счётчика делает вызов идемпотентным
	// — а зовут его каждую секунду на каждого госта, см. respawn.dm.
	if(!hud.hud_users_all_z_levels[watcher])
		hud.show_to(watcher)

/// Пересчитать видимость по бойцу: повстанцам поле видно всегда, морпеху — пока на нём
/// сапёрные очки. Вызывается при выдаче роли и при снятии очков.
/proc/mw_refresh_mine_vision(mob/body)
	if(!body)
		return
	var/sees = mountain_wars_faction(body) == JOB_TITLE_MW_INSURGENT
	if(!sees && ishuman(body))
		var/mob/living/carbon/human/soldier = body
		sees = istype(soldier.glasses, /obj/item/clothing/glasses/mw_sapper)
	mw_mine_vision(body, sees)

// MARK: Сапёрные очки
/obj/item/clothing/glasses/mw_sapper
	name = "сапёрные очки"
	desc = "Индукционный детектор в оправе. Металл под грунтом подсвечивается прямо в поле зрения — закопанную мину видно до того, как на неё наступят."
	icon_state = "thermal"
	item_state = "thermal"

/obj/item/clothing/glasses/mw_sapper/equipped(mob/user, slot, initial)
	. = ..()
	if(slot & ITEM_SLOT_EYES)
		mw_mine_vision(user, TRUE)

/obj/item/clothing/glasses/mw_sapper/dropped(mob/user, slot, silent = FALSE)
	. = ..()
	// Не гасим вслепую: очки мог носить повстанец, а он видит поле и без них.
	if(slot & ITEM_SLOT_EYES)
		mw_refresh_mine_vision(user)

#undef MW_MINE_HUD
#undef MW_MINE_PLANT_TIME
#undef MW_MINE_DEFUSE_TIME
#undef MW_MINE_OWN_DEFUSE_TIME
