/obj/item/twohanded/required/kokochalloween
	name = "тыква"
	desc = "Традиционно из них делают фонари в честь Хэллоуина."
	icon = 'icons/obj/halloween/pumpkins_and_decorations.dmi'
	icon_state = "pumpkin_1"
	item_state = "h_pumpkin"
	item_flags = NONE
	layer = BELOW_MOB_LAYER
	force = 5
	force_wielded = 5
	throwforce = 13
	throw_range = 1
	pickup_sound = SFX_PICK_UP
	light_on = FALSE
	light_system = OVERLAY_LIGHT
	var/s_colour
	/// List of loot entries formatted as list(item_type, chance).
	var/list/loot = list()
	var/cutted
	var/lighted
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/twohanded/required/kokochalloween/chimera
	name = "тыква-химера"
	icon_state = "pumpkin_alien"
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/twohanded/required/kokochalloween/chimera/Initialize(mapload)
	. = ..()
	switch(type)
		if(/obj/item/twohanded/required/kokochalloween/chimera/alien)
			desc = "Глаза без устали следят за тобой. Истина где-то рядом, а [span_alien("голод ещё ближе.")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/ghost)
			desc = "Прозрачный и безразличный сгусток чего-то липкого. [span_color("Каждый займёт его место.","#999999")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/devil)
			desc = "Жаждет обзавестись очередной душой. [span_red("Желательно двумя.")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/human)
			desc = "Человекосодержащий продукт, у него нет рта, но он должен кричать. [span_color("Вкусный. В приготовленном виде ещё вкуснее.", "#E6C280")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/vampire)
			desc = "Изо рта торчат острейшие клыки, которые так и норовят войти в чью-либо шею. Разрешение необязательно. [span_red("Может, оно и к лучшему?")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/heart)
			desc = "Походит на сердечко! Доля радости сегодня. [span_red("Ты не один.")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/kokoc)
			desc = "Кокосовая тыква! В простанородье - кототыква, за счёт внешнего вида. [span_yellow("Твой лучший друг! Неужели он заслуживает этого?")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/spider)
			desc = "Арахнотыква. Восемь лап - и столько же глаз. Обожает чай и всё, что с ним сввязано. [span_green("К сожалению, люди слишком большие для неё.")]"
		if(/obj/item/twohanded/required/kokochalloween/chimera/bluespace)
			desc = "Тыква синего пространства. Твой билет к счастью, либо к несчастью. Третьего не дано. [span_blue("По крайней мере, за пределами синего пространства.")]"

/obj/item/twohanded/required/kokochalloween/get_ru_names()
	return alist(
		NOMINATIVE = "тыква",
		GENITIVE = "тыквы",
		DATIVE = "тыкве",
		ACCUSATIVE = "тыкву",
		INSTRUMENTAL = "тыквой",
		PREPOSITIONAL = "тыкве",
	)

/obj/item/twohanded/required/kokochalloween/chimera/get_ru_names()
	return alist(
		NOMINATIVE = "тыква-химера",
		GENITIVE = "тыква-химеры",
		DATIVE = "тыква-химере",
		ACCUSATIVE = "тыква-химеру",
		INSTRUMENTAL = "тыква-химерой",
		PREPOSITIONAL = "тыква-химере",
	)

/obj/item/twohanded/required/kokochalloween/chimera/alien
	s_colour = "#FF00FF"
	loot = list(
		list(/obj/effect/decal/cleanable/blood/gibs/xeno, 100),
		list(/obj/item/multitool/abductor, 90),
		list(/obj/item/weldingtool/abductor, 90),
		list(/obj/item/stack/sheet/mineral/abductor/fifty, 50),
		list(/obj/effect/mob_spawn/human/abductor, 50),
	)

/obj/item/twohanded/required/kokochalloween/chimera/ghost
	icon_state = "pumpkin_ghost"
	s_colour = "#FFFFFF"
	loot = list(
		list(/obj/item/scrying, 100),
		list(/obj/item/reagent_containers/food/snacks/ectoplasm, 95),
		list(/obj/item/reagent_containers/food/snacks/ectoplasm, 95),
		list(/obj/item/reagent_containers/food/snacks/ectoplasm, 95),
	)

/obj/item/twohanded/required/kokochalloween/chimera/devil
	icon_state = "pumpkin_devil"
	s_colour = "#FF0000"
	loot = list(
		list(/obj/item/nullrod/pitchfork, 100),
		list(/obj/item/veilrender/honkrender, 50),
	)

/obj/item/twohanded/required/kokochalloween/chimera/human
	icon_state = "pumpkin_chimera"
	s_colour = "#FF0000"
	loot = list(
		list(/obj/effect/decal/cleanable/blood/gibs/body, 100),
		list(/obj/item/reagent_containers/food/snacks/meat/humanoid/human, 95),
		list(/obj/item/reagent_containers/food/snacks/meat/humanoid/human, 95),
		list(/obj/item/reagent_containers/food/snacks/meat/humanoid/human, 95),
		list(/obj/item/reagent_containers/food/snacks/meat/humanoid/human, 95),
		list(/obj/item/reagent_containers/food/snacks/meat/humanoid/human, 95),
		list(/obj/item/organ/external/leg, 95),
		list(/obj/item/organ/external/arm/right, 95),
	)

/obj/item/twohanded/required/kokochalloween/chimera/vampire
	icon_state = "pumpkin_vampire"
	loot = list(
		list(/obj/item/clothing/suit/draculacoat, 100),
		list(/obj/item/reagent_containers/iv_bag/blood/OMinus, 100),
	)

/obj/item/twohanded/required/kokochalloween/chimera/heart
	icon_state = "pumpkin_heart"
	s_colour = "#FF0000"
	loot = list(
		list(/obj/item/organ/internal/heart, 100),
		list(/obj/item/reagent_containers/condiment/saltshaker, 100),
		list(/obj/item/organ/internal/heart/demon/slaughter, 20),
		)

/obj/item/twohanded/required/kokochalloween/chimera/kokoc
	icon_state = "pumpkin_kokoc"
	loot = list(
		list(/mob/living/simple_animal/pet/cat, 100),
		list(/obj/item/spellbook/oneuse/random, 100),
		list(/obj/item/reagent_containers/food/snacks/candy/taffy, 75),
		list(/obj/item/reagent_containers/food/snacks/candy/taffy, 75),
		list(/obj/item/reagent_containers/food/snacks/candy/taffy, 75),
	)

/obj/item/twohanded/required/kokochalloween/chimera/spider
	icon_state = "pumpkin_spider"
	loot = list(
		list(/mob/living/simple_animal/hostile/poison/giant_spider/nurse, 100),
		list(/obj/item/reagent_containers/food/snacks/monstermeat/spidereggs, 100),
		list(/obj/item/reagent_containers/cup/glass/tea, 100),
		list(/obj/structure/spider/spiderling, 75),
		list(/obj/structure/spider/spiderling, 75),
		list(/obj/structure/spider/spiderling, 75),
	)

/obj/item/twohanded/required/kokochalloween/chimera/bluespace
	icon_state = "pumpkin_bluespace"
	s_colour = "#0000FF"
	loot = list(
		list(/obj/item/stack/sheet/bluespace_crystal, 100),
	)

/obj/item/twohanded/required/kokochalloween/Initialize(mapload)
	. = ..()
	if(!istype(src, /obj/item/twohanded/required/kokochalloween/chimera))
		icon_state = "pumpkin_[rand(1,8)]"
		if(prob(20.26))
			var/chosen = pick(subtypesof(/obj/item/twohanded/required/kokochalloween/chimera))
			new chosen(loc)
			del(src)

/obj/item/twohanded/required/kokochalloween/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(..())
		return

	playsound(src, SFX_PUMPKIN_CRASH, vol=125)
	var/obj/effect/decal/cleanable/pumpkin_smash/smash = new /obj/effect/decal/cleanable/pumpkin_smash(loc)
	if(s_colour)
		smash.icon_state = "pumpkin_smash_gs"
		smash.color = s_colour
	get_loot()
	del(src)

/obj/item/twohanded/required/kokochalloween/proc/get_loot()
	if(loot)
		for(var/list/loot_entry in loot)
			var/gift = loot_entry[1]
			if(prob(loot_entry[2]))
				new gift(loc)

/obj/item/twohanded/required/kokochalloween/chimera/bluespace/get_loot()
	. = ..()
	var/s_obj = pick(subtypesof(/obj/item))
	new s_obj(loc)

/obj/item/twohanded/required/kokochalloween/attackby(obj/item/item, mob/living/user, list/modifiers)
	. = ..()
	if(!istype(src, /obj/item/twohanded/required/kokochalloween/chimera) && item.sharp && !cutted)
		if(do_after(user, 4 SECONDS))
			playsound(src,'sound/weapons/knife_holster/throat_slice.ogg')
			user.visible_message(span_danger("[user] обрабатыва[PLUR_YOT_YUT(user)] тыкву, доставая мякоть."))
			cutted = TRUE
			icon_state = "c[copytext(icon_state, length(icon_state))]"
	var/obj/item/candle/candle = item
	if(!istype(src, /obj/item/twohanded/required/kokochalloween/chimera) && cutted && !lighted)
		if(candle.lit)
			if(do_after(user, 2 SECONDS))
				playsound(src, SFX_PICK_UP)
				user.visible_message(span_danger("[user] вставля[PLUR_YOT_YUT(user)] свечу в тыкву."))
				lighted = TRUE
				icon_state = "l[copytext(icon_state, length(icon_state))]"
				var/l_range_init = 4
				var/l_power_init = 1.2
				set_light_range_power_color(l_range_init, l_power_init, LIGHT_COLOR_BRIGHT_YELLOW)
				set_light_on(TRUE)
				if(user.drop_item_ground(candle, force = TRUE))
					qdel(candle)
		else
			to_chat(user, "Свеча не горит!")

/obj/effect/decal/cleanable/pumpkin_smash
	name = "тыквенное смузи"
	desc = "Выглядит аппетитно."
	icon = 'icons/obj/halloween/pumpkins_and_decorations.dmi'
	icon_state = "pumpkin_smash"

/obj/effect/decal/cleanable/pumpkin_field
	name = "бахча"
	desc = "На подобных растут тыквы и арбузы. Конкретно эта иссохла."
	icon = 'icons/obj/halloween/pumpkins_and_decorations.dmi'
	icon_state = "pumpkin_field"

/obj/structure/halloween_decorations
	name = "праздничные наклейки"
	icon = 'icons/obj/halloween/pumpkins_and_decorations.dmi'
	max_integrity = 24
	layer = 3.21
	anchored = TRUE

/obj/structure/halloween_decorations/Initialize(mapload)
	. = ..()
	icon_state = "window_decor[rand(1,6)]"

/obj/structure/halloween_decorations/wirecutter_act(mob/living/user, obj/item/wirecutters/I)
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	deconstruct()

/obj/structure/halloween_decorations/wrench_act(mob/living/user, obj/item/wrench/I)
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	set_anchored(!anchored)

/obj/item/storage/halloween
	name = "ведёрко для конфет"
	desc = "В форме тыквы!"
	icon = 'icons/obj/halloween/pumpkins_and_decorations.dmi'
	icon_state = "bucket"
	storage_slots = 9
	can_hold = list(/obj/item/reagent_containers/food/snacks/candy)
	drop_sound = 'sound/items/handling/cardboard_box/cardboardbox_drop.ogg'
	pickup_sound =  'sound/items/handling/cardboard_box/cardboardbox_pickup.ogg'
	use_sound = 'sound/items/handling/cardboard_box_rustle.ogg'

/obj/item/storage/halloween/populate_contents()
	var/list/candy_types = subtypesof(/obj/item/reagent_containers/food/snacks/candy)
	candy_types -= list(
		/obj/item/reagent_containers/food/snacks/candy/mre,
		/obj/item/reagent_containers/food/snacks/candy/candycane,
		/obj/item/reagent_containers/food/snacks/candy/gummybear/poison,
		/obj/item/reagent_containers/food/snacks/candy/gummyworm/poison,
		/obj/item/reagent_containers/food/snacks/candy/jellybean/poison,
		/obj/item/reagent_containers/food/snacks/candy/cotton/poison,
		/obj/item/reagent_containers/food/snacks/candy/cotton/bad_rainbow,
	)

	var/candy_count = rand(4, 7)
	for(var/i in 1 to candy_count)
		var/candy_type = pick(candy_types)
		new candy_type(src)
