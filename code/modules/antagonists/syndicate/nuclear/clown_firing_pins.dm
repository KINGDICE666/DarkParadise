#define CLOWN_FIRING_PIN_BOX_SIZE 4

/obj/item/firing_pin/clown/ultra
	name = "ultra hilarious firing pin"
	desc = "Боёк разрешает стрельбу только клоунам и неуклюжим существам. Каждая попытка выстрела сопровождается хонком."
	color = COLOR_YELLOW

/obj/item/firing_pin/clown/ultra/get_ru_names()
	return alist(
		NOMINATIVE = "ультрасмешной боёк",
		GENITIVE = "ультрасмешного бойка",
		DATIVE = "ультрасмешному бойку",
		ACCUSATIVE = "ультрасмешной боёк",
		INSTRUMENTAL = "ультрасмешным бойком",
		PREPOSITIONAL = "ультрасмешном бойке",
	)

/obj/item/firing_pin/clown/ultra/pin_auth(mob/living/user)
	playsound(gun, 'sound/items/bikehorn.ogg', 50, TRUE)
	return HAS_TRAIT(user, TRAIT_CLUMSY) || HAS_MIND_TRAIT(user, TRAIT_NAIVE)

/obj/item/firing_pin/clown/ultra/selfdestruct
	name = "super ultra hilarious firing pin"
	desc = "Клоунский боёк с нитробананиевым зарядом. Оружие взорвётся, если им воспользуется кто-то без клоунской \
		природы или неуклюжести."
	selfdestruct = TRUE

/obj/item/firing_pin/clown/ultra/selfdestruct/get_ru_names()
	return alist(
		NOMINATIVE = "суперультрасмешной боёк",
		GENITIVE = "суперультрасмешного бойка",
		DATIVE = "суперультрасмешному бойку",
		ACCUSATIVE = "суперультрасмешной боёк",
		INSTRUMENTAL = "суперультрасмешным бойком",
		PREPOSITIONAL = "суперультрасмешном бойке",
	)

/obj/item/storage/box/syndie_kit/clownpins
	name = "ultra hilarious firing pin box"
	gender = FEMALE
	desc = "Четыре клоунских бойка для огнестрельного оружия."
	var/pin_type = /obj/item/firing_pin/clown/ultra

/obj/item/storage/box/syndie_kit/clownpins/get_ru_names()
	return alist(
		NOMINATIVE = "коробка ультрасмешных бойков",
		GENITIVE = "коробки ультрасмешных бойков",
		DATIVE = "коробке ультрасмешных бойков",
		ACCUSATIVE = "коробку ультрасмешных бойков",
		INSTRUMENTAL = "коробкой ультрасмешных бойков",
		PREPOSITIONAL = "коробке ультрасмешных бойков",
	)

/obj/item/storage/box/syndie_kit/clownpins/populate_contents()
	for(var/index in 1 to CLOWN_FIRING_PIN_BOX_SIZE)
		new pin_type(src)

/obj/item/storage/box/syndie_kit/clownpins/super
	name = "super ultra hilarious firing pin box"
	pin_type = /obj/item/firing_pin/clown/ultra/selfdestruct

/obj/item/storage/box/syndie_kit/clownpins/super/get_ru_names()
	return alist(
		NOMINATIVE = "коробка суперультрасмешных бойков",
		GENITIVE = "коробки суперультрасмешных бойков",
		DATIVE = "коробке суперультрасмешных бойков",
		ACCUSATIVE = "коробку суперультрасмешных бойков",
		INSTRUMENTAL = "коробкой суперультрасмешных бойков",
		PREPOSITIONAL = "коробке суперультрасмешных бойков",
	)

/obj/item/firing_pin/monkey
	name = "simian firing pin"
	desc = "Боёк для обезьяньей лапы."

/obj/item/firing_pin/monkey/get_ru_names()
	return alist(
		NOMINATIVE = "обезьяний боёк",
		GENITIVE = "обезьяньего бойка",
		DATIVE = "обезьяньему бойку",
		ACCUSATIVE = "обезьяний боёк",
		INSTRUMENTAL = "обезьяньим бойком",
		PREPOSITIONAL = "обезьяньем бойке",
	)

/obj/item/firing_pin/monkey/pin_auth(mob/living/user)
	return is_monkeybasic(user)

#undef CLOWN_FIRING_PIN_BOX_SIZE
