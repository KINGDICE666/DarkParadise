/datum/antagonist/nuclear_operative/clownop/inducted
	antag_menu_name = "Принятый в цирк оперативник"

/datum/antagonist/nuclear_operative/clownop/inducted/rename()
	return

/obj/item/implanter/induction_implant/clown
	name = "bio-chip implanter (syndicate circus)"
	gender = MALE
	desc = "Инъектор для регистрации участника цирка \"Синдиката\". Не является устройством промывания мозгов."
	imp = /obj/item/implant/nuclear_operative/clown

/obj/item/implanter/induction_implant/clown/get_ru_names()
	return alist(
		NOMINATIVE = "инъектор био-чипа цирка Синдиката",
		GENITIVE = "инъектора био-чипа цирка Синдиката",
		DATIVE = "инъектору био-чипа цирка Синдиката",
		ACCUSATIVE = "инъектор био-чипа цирка Синдиката",
		INSTRUMENTAL = "инъектором био-чипа цирка Синдиката",
		PREPOSITIONAL = "инъекторе био-чипа цирка Синдиката",
	)

/obj/item/implant/nuclear_operative/clown
	name = "syndicate circus bio-chip"
	gender = MALE
	desc = "Регистрирует владельца как участника отряда клоунов-оперативников."
	actions_types = null
	var/datum/weakref/operative_ref

/obj/item/implant/nuclear_operative/clown/get_ru_names()
	return alist(
		NOMINATIVE = "био-чип цирка Синдиката",
		GENITIVE = "био-чипа цирка Синдиката",
		DATIVE = "био-чипу цирка Синдиката",
		ACCUSATIVE = "био-чип цирка Синдиката",
		INSTRUMENTAL = "био-чипом цирка Синдиката",
		PREPOSITIONAL = "био-чипе цирка Синдиката",
	)

/obj/item/implant/nuclear_operative/clown/implant(mob/living/carbon/human/target, mob/user, force = FALSE)
	if(!target.mind || target.mind.has_antag_datum(/datum/antagonist/nuclear_operative))
		return FALSE
	. = ..()
	if(!.)
		return
	var/datum/antagonist/nuclear_operative/clownop/inducted/operative = target.mind.add_antag_datum(/datum/antagonist/nuclear_operative/clownop/inducted)
	operative_ref = WEAKREF(operative)
	to_chat(target, span_userdanger("Этот био-чип НЕ промывает мозги. Если Вы были обычным членом экипажа, добровольная или принудительная имплантация не разрешает Вам помогать оперативникам."))

/obj/item/implant/nuclear_operative/clown/removed(mob/living/carbon/human/source)
	var/datum/antagonist/operative = operative_ref?.resolve()
	operative_ref = null
	if(operative)
		qdel(operative)
	return ..()

/obj/item/storage/box/syndie_kit/induction_kit/clown
	name = "syndicate circus induction kit"
	desc = "Снаряжение и регистрационный био-чип для нового участника цирка. Био-чип не промывает мозги."
	max_combined_w_class = 60
	storage_slots = 20

/obj/item/storage/box/syndie_kit/induction_kit/clown/get_ru_names()
	return alist(
		NOMINATIVE = "набор вступления в цирк",
		GENITIVE = "набора вступления в цирк",
		DATIVE = "набору вступления в цирк",
		ACCUSATIVE = "набор вступления в цирк",
		INSTRUMENTAL = "набором вступления в цирк",
		PREPOSITIONAL = "наборе вступления в цирк",
	)

/obj/item/storage/box/syndie_kit/induction_kit/clown/populate_contents()
	var/obj/item/gun/gun = new /obj/item/gun/projectile/automatic/toy/pistol/riot/clandestine(src)
	var/obj/item/firing_pin/clown/ultra/pin = new
	pin.gun_insert(null, gun)
	new /obj/item/dnainjector/clumsymut(src)
	new /obj/item/reagent_containers/spray/waterflower/lube/super(src)
	new /obj/item/radio/headset/syndicate/alt(src)
	new /obj/item/card/id/syndicate(src)
	new /obj/item/clothing/suit/space/hardsuit/syndi/on(src)
	new /obj/item/tank/jetpack/oxygen/harness(src)
	new /obj/item/clothing/shoes/clown_shoes/combat(src)
	new /obj/item/clothing/under/syndicate(src)
	new /obj/item/clothing/gloves/combat(src)
	new /obj/item/implanter/induction_implant/clown(src)
	new /obj/item/implanter/tacmap/nuclear(src)

/obj/item/implanter/tacmap/nuclear
	name = "bio-chip implanter (operative minimap)"
	gender = MALE
	imp = /obj/item/implant/tacmap/nuclear

/obj/item/implanter/tacmap/nuclear/get_ru_names()
	return alist(
		NOMINATIVE = "инъектор био-чипа тактической карты",
		GENITIVE = "инъектора био-чипа тактической карты",
		DATIVE = "инъектору био-чипа тактической карты",
		ACCUSATIVE = "инъектор био-чипа тактической карты",
		INSTRUMENTAL = "инъектором био-чипа тактической карты",
		PREPOSITIONAL = "инъекторе био-чипа тактической карты",
	)

/obj/item/implant/explosive/macro/fake
	heavy = /obj/item/implant/explosive::heavy
	medium = /obj/item/implant/explosive::medium
	weak = /obj/item/implant/explosive::weak

/obj/item/implant/explosive/macro/fake/self_destruct()
	honkerblast(src, light_range = 8, medium_range = 4, heavy_range = 2)
	return ..()

/obj/item/implanter/explosive_macro/fake
	imp = /obj/item/implant/explosive/macro/fake

/proc/honkerblast(atom/origin, light_range = 1, medium_range = 0, heavy_range = 0)
	var/turf/origin_turf = get_turf(origin)
	playsound(origin_turf, 'sound/items/airhorn.ogg', 100, TRUE)
	for(var/mob/living/carbon/victim in hearers(max(light_range, medium_range, heavy_range), origin_turf))
		if(HAS_TRAIT(victim, TRAIT_DEAF))
			continue
		var/distance = get_dist(origin_turf, victim)
		if(distance <= heavy_range)
			victim.Paralyse(4 SECONDS)
			victim.Stun(10 SECONDS)
			victim.Stuttering(30 SECONDS)
			victim.Jitter(1000 SECONDS)
			victim.sound_damage(10, 30 SECONDS)
		else if(distance <= medium_range)
			victim.Paralyse(2 SECONDS)
			victim.Stun(5 SECONDS)
			victim.Jitter(500 SECONDS)
			victim.sound_damage(7, 20 SECONDS)
		else
			victim.Knockdown(2 SECONDS)
			victim.Jitter(200 SECONDS)
			victim.sound_damage(4, 10 SECONDS)
		to_chat(victim, span_userdanger("ХОНК!"))

/mob/living/carbon/proc/sound_damage(damage, deafen)
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return
	var/obj/item/organ/internal/ears/ears = get_organ_slot(INTERNAL_ORGAN_EARS)
	if(QDELETED(ears))
		return
	if(damage)
		ears.internal_receive_damage(damage)
	if(deafen)
		Deaf(deafen)
