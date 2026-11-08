/obj/item/melee/energy/sword/bananium
	name = "bananium sword"
	gender = MALE
	desc = "Бананиевый энергетический меч. Не ранит, зато заставляет противника поскользнуться даже в противоскользящей обуви."
	icon_state = "e_sword"
	item_state = "e_sword"
	icon_state_on = "e_sword_on_bananium"
	item_color = "yellow"
	force_on = 0
	throwforce_on = 0
	heat = 0
	hitsound = null
	can_clumsy_use = TRUE
	COOLDOWN_DECLARE(next_trombone)

/obj/item/melee/energy/sword/bananium/get_ru_names()
	return alist(
		NOMINATIVE = "бананиевый меч",
		GENITIVE = "бананиевого меча",
		DATIVE = "бананиевому мечу",
		ACCUSATIVE = "бананиевый меч",
		INSTRUMENTAL = "бананиевым мечом",
		PREPOSITIONAL = "бананиевом мече",
	)

/obj/item/melee/energy/sword/bananium/Initialize(mapload)
	. = ..()
	configure_slipping(FALSE)

/obj/item/melee/energy/sword/bananium/proc/configure_slipping(clumsy)
	AddComponent(
		/datum/component/slippery, \
		knockdown = clumsy ? 8 SECONDS : 4 SECONDS, \
		lube_flags = SLIP_IGNORE_NO_SLIP_WATER|(clumsy ? SLIP_WHEN_LYING : NONE), \
		force_drop = clumsy, \
		slip_on_damage = clumsy, \
		can_slip_callback = CALLBACK(src, PROC_REF(is_active)), \
	)

/obj/item/melee/energy/sword/bananium/proc/is_active()
	return active

/obj/item/melee/energy/sword/bananium/equipped(mob/user, slot, initial)
	. = ..()
	configure_slipping((slot & ITEM_SLOT_HANDS) && HAS_TRAIT(user, TRAIT_CLUMSY))

/obj/item/melee/energy/sword/bananium/attack_self(mob/living/carbon/user)
	. = ..()
	hitsound = active ? 'sound/misc/slip.ogg' : null

/obj/item/melee/energy/sword/bananium/update_icon_state()
	item_state = active ? "e_sword_on_bananium" : "e_sword"
	return ..()

/obj/item/melee/energy/sword/bananium/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	if(!istype(used, /obj/item/melee/energy/sword/bananium))
		return ..()
	if(COOLDOWN_FINISHED(src, next_trombone))
		COOLDOWN_START(src, next_trombone, 5 SECONDS)
		balloon_alert(user, "не соединяются!")
		playsound(src, 'sound/misc/sadtrombone.ogg', 50, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/item/melee/energy/sword/bananium/suicide_act(mob/living/user)
	if(!active)
		attack_self(user)
	user.visible_message(span_suicide("[user.declent_ru(NOMINATIVE)] пыта[PLUR_ET_YUT(user)]ся заколоть себя [declent_ru(INSTRUMENTAL)], но лезвие безвредно соскальзывает!"))
	return SHAME

/obj/item/shield/energy/bananium
	name = "bananium energy shield"
	gender = MALE
	desc = "Бананиевый щит отражает энергетические снаряды, сбивает противников с ног и возвращается после броска. Не \
		наступайте на включённый щит!"
	icon_state = "bananaeshield"
	item_state = "bananaeshield"
	force = 0
	throwforce = 0
	throw_speed = 1
	can_clumsy_use = TRUE
	hitsound = 'sound/misc/slip.ogg'

/obj/item/shield/energy/bananium/get_ru_names()
	return alist(
		NOMINATIVE = "бананиевый энергетический щит",
		GENITIVE = "бананиевого энергетического щита",
		DATIVE = "бананиевому энергетическому щиту",
		ACCUSATIVE = "бананиевый энергетический щит",
		INSTRUMENTAL = "бананиевым энергетическим щитом",
		PREPOSITIONAL = "бананиевом энергетическом щите",
	)

/obj/item/shield/energy/bananium/toggle(mob/living/carbon/human/user, forced)
	. = ..()
	force = 0
	throwforce = 0
	throw_speed = 1
	if(active)
		AddComponent(
			/datum/component/slippery, \
			knockdown = 6 SECONDS, \
			lube_flags = SLIP_IGNORE_NO_SLIP_WATER, \
			slip_on_damage = TRUE, \
			can_slip_callback = CALLBACK(src, PROC_REF(is_active)), \
		)
		AddComponent(
			/datum/component/boomerang, \
			throw_range + (HAS_TRAIT(user, TRAIT_CLUMSY) ? 2 : 1), \
			HAS_TRAIT(user, TRAIT_CLUMSY), \
		)
	else
		qdel(GetComponent(/datum/component/slippery))
		qdel(GetComponent(/datum/component/boomerang))

/obj/item/shield/energy/bananium/proc/is_active()
	return active

/obj/item/shield/energy/bananium/equipped(mob/user, slot, initial)
	. = ..()
	if(active && (slot & ITEM_SLOT_HANDS))
		qdel(GetComponent(/datum/component/boomerang))
		AddComponent(
			/datum/component/boomerang, \
			throw_range + (HAS_TRAIT(user, TRAIT_CLUMSY) ? 2 : 1), \
			HAS_TRAIT(user, TRAIT_CLUMSY), \
		)

/obj/item/shield/energy/bananium/update_icon_state()
	icon_state = "bananaeshield[active ? "_on" : ""]"
	item_state = icon_state

/obj/item/shield/energy/bananium/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text, final_block_chance, damage, attack_type)
	. = ..()
	if(active && attack_type == ITEM_ATTACK && prob(50))
		playsound(src, 'sound/weapons/parry.ogg', 50, TRUE)
		return TRUE

/obj/item/seeds/banana/bombanana
	name = "bombanana seed pack"
	gender = FEMALE
	desc = "Семена взрывных бананов. Созревшие плоды передайте клоуну."
	plantname = "Bombanana Tree"
	product = /obj/item/reagent_containers/food/snacks/grown/banana/bombanana
	mutatelist = list()
	reagents_add = list("vitamin" = 0.1)

/obj/item/seeds/banana/bombanana/get_ru_names()
	return alist(
		NOMINATIVE = "пачка семян бомбанана",
		GENITIVE = "пачки семян бомбанана",
		DATIVE = "пачке семян бомбанана",
		ACCUSATIVE = "пачку семян бомбанана",
		INSTRUMENTAL = "пачкой семян бомбанана",
		PREPOSITIONAL = "пачке семян бомбанана",
	)

/obj/item/reagent_containers/food/snacks/grown/banana/bombanana
	name = "bombanana"
	gender = MALE
	desc = "Банан со взрывным вкусом. После еды немедленно выбросьте кожуру!"
	seed = /obj/item/seeds/banana/bombanana
	trash = /obj/item/grown/bananapeel/bombanana
	tastes = list("взрывчатка" = 10)

/obj/item/reagent_containers/food/snacks/grown/banana/bombanana/get_ru_names()
	return alist(
		NOMINATIVE = "бомбанан",
		GENITIVE = "бомбанана",
		DATIVE = "бомбанану",
		ACCUSATIVE = "бомбанан",
		INSTRUMENTAL = "бомбананом",
		PREPOSITIONAL = "бомбанане",
	)

/obj/item/reagent_containers/food/snacks/grown/banana/bombanana/On_Consume(mob/eater, mob/user)
	if(reagents.total_volume <= 0)
		add_attack_logs(user, eater, "Ate or fed a bombanana, creating a live explosive peel", ATKLOG_FEW)
	return ..()

/obj/item/grown/bananapeel/bombanana
	desc = "Банановая кожура. Почему она пищит?"
	seed = /obj/item/seeds/banana/bombanana
	var/obj/item/grenade/syndieminibomb/bomb

/obj/item/grown/bananapeel/bombanana/get_ru_names()
	return alist(
		NOMINATIVE = "кожура бомбанана",
		GENITIVE = "кожуры бомбанана",
		DATIVE = "кожуре бомбанана",
		ACCUSATIVE = "кожуру бомбанана",
		INSTRUMENTAL = "кожурой бомбанана",
		PREPOSITIONAL = "кожуре бомбанана",
	)

/obj/item/grown/bananapeel/bombanana/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/slippery, 5 SECONDS)
	bomb = new(src)
	bomb.name = "bombanana peel"
	bomb.arm_grenade(iscarbon(loc) ? loc : null, 5 SECONDS, msg = FALSE)

/obj/item/grown/bananapeel/bombanana/Destroy()
	QDEL_NULL(bomb)
	return ..()

/obj/item/grown/bananapeel/bombanana/suicide_act(mob/living/user)
	bomb.arm_grenade(user, 0, msg = FALSE)
	return BRUTELOSS

/obj/item/grenade/chem_grenade/teargas/moustache
	name = "tear-stache grenade"
	desc = "Газовая граната, разбрасывающая липкие усы. Они не отклеятся в течение минуты. Маски клоунов и мимов защищены от усов."
	icon_state = "moustacheg"

/obj/item/grenade/chem_grenade/teargas/moustache/get_ru_names()
	return alist(
		NOMINATIVE = "усатая газовая граната",
		GENITIVE = "усатой газовой гранаты",
		DATIVE = "усатой газовой гранате",
		ACCUSATIVE = "усатую газовую гранату",
		INSTRUMENTAL = "усатой газовой гранатой",
		PREPOSITIONAL = "усатой газовой гранате",
	)

/obj/item/grenade/chem_grenade/teargas/moustache/clown_check(mob/living/user)
	if(!HAS_TRAIT(user, TRAIT_CLUMSY))
		to_chat(user, span_warning("Вы выдернули чеку. На ней розовая лента с надписью \"ХОНК\"!"))
		arm_grenade(user, 0.5 SECONDS, msg = FALSE)
		return FALSE
	return TRUE

/obj/item/grenade/chem_grenade/teargas/moustache/prime(mob/user)
	var/turf/source_turf = get_turf(src)
	for(var/mob/living/carbon/human/victim in view(6, source_turf))
		if(istype(victim.wear_mask, /obj/item/clothing/mask/gas/clown_hat) || istype(victim.wear_mask, /obj/item/clothing/mask/gas/mime))
			continue
		if(victim.wear_mask && !victim.drop_item_ground(victim.wear_mask))
			continue
		victim.equip_to_slot_or_del(new /obj/item/clothing/mask/fakemoustache/sticky(victim), ITEM_SLOT_MASK)
	return ..()

/obj/item/clothing/mask/fakemoustache/sticky
	name = "sticky fake moustache"
	gender = PLURAL
	desc = "Накладные усы с очень липким клеем. Придётся подождать минуту."

/obj/item/clothing/mask/fakemoustache/sticky/get_ru_names()
	return alist(
		NOMINATIVE = "липкие накладные усы",
		GENITIVE = "липких накладных усов",
		DATIVE = "липким накладным усам",
		ACCUSATIVE = "липкие накладные усы",
		INSTRUMENTAL = "липкими накладными усами",
		PREPOSITIONAL = "липких накладных усах",
	)

/obj/item/clothing/mask/fakemoustache/sticky/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, INNATE_TRAIT)
	addtimer(CALLBACK(src, PROC_REF(unstick)), 1 MINUTES)

/obj/item/clothing/mask/fakemoustache/sticky/proc/unstick()
	REMOVE_TRAIT(src, TRAIT_NODROP, INNATE_TRAIT)
