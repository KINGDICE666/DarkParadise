#define ORE_MULTIPLIER_IRON 3
#define ORE_MULTIPLIER_GLASS 2
#define ORE_MULTIPLIER_PLASMA 1
#define ORE_MULTIPLIER_SILVER 0.7
#define ORE_MULTIPLIER_GOLD 0.6
#define ORE_MULTIPLIER_URANIUM 0.4
#define ORE_MULTIPLIER_DIAMOND 0.3

/obj/structure/closet/crate/secure/bitrunning
	name = "bitrunning cache"
	desc = "Контейнер, собранный из чистых данных."

/obj/structure/closet/crate/secure/bitrunning/get_ru_names()
	return alist(
		NOMINATIVE = "контейнер битраннера",
		GENITIVE = "контейнера битраннера",
		DATIVE = "контейнеру битраннера",
		ACCUSATIVE = "контейнер битраннера",
		INSTRUMENTAL = "контейнером битраннера",
		PREPOSITIONAL = "контейнере битраннера",
	)

/obj/structure/closet/crate/secure/bitrunning/encrypted
	name = "encrypted cache"
	desc = "Зашифрован. Чтобы вскрыть его, нужно дотащить контейнер до площадки выдачи."
	can_be_emaged = FALSE
	damage_deflection = 30
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/closet/crate/secure/bitrunning/encrypted/get_ru_names()
	return alist(
		NOMINATIVE = "зашифрованный контейнер",
		GENITIVE = "зашифрованного контейнера",
		DATIVE = "зашифрованному контейнеру",
		ACCUSATIVE = "зашифрованный контейнер",
		INSTRUMENTAL = "зашифрованным контейнером",
		PREPOSITIONAL = "зашифрованном контейнере",
	)

/obj/structure/closet/crate/secure/bitrunning/encrypted/togglelock(mob/living/user)
	balloon_alert(user, "шифрование не поддаётся!")
	return FALSE

/obj/structure/closet/crate/secure/bitrunning/decrypted
	name = "decrypted cache"
	desc = "Скомпилирован из виртуального домена. Награда удачливого битраннера."
	locked = FALSE

/obj/structure/closet/crate/secure/bitrunning/decrypted/get_ru_names()
	return alist(
		NOMINATIVE = "расшифрованный контейнер",
		GENITIVE = "расшифрованного контейнера",
		DATIVE = "расшифрованному контейнеру",
		ACCUSATIVE = "расшифрованный контейнер",
		INSTRUMENTAL = "расшифрованным контейнером",
		PREPOSITIONAL = "расшифрованном контейнере",
	)

/obj/structure/closet/crate/secure/bitrunning/decrypted/Initialize(mapload, datum/lazy_template/virtual_domain/completed_domain, rewards_multiplier = 1)
	. = ..()
	playsound(src, 'sound/effects/phasein.ogg', 50, TRUE)

	if(isnull(completed_domain))
		return

	fill_with_rewards(completed_domain, rewards_multiplier)

/obj/structure/closet/crate/secure/bitrunning/decrypted/proc/fill_with_rewards(datum/lazy_template/virtual_domain/completed_domain, rewards_multiplier)
	var/reward_points = completed_domain.reward_points

	for(var/path in completed_domain.completion_loot)
		for(var/count in 1 to completed_domain.completion_loot[path])
			new path(src)

	new /obj/item/stack/ore/iron(src, calculate_ore_amount(reward_points, rewards_multiplier, ORE_MULTIPLIER_IRON))
	new /obj/item/stack/ore/glass(src, calculate_ore_amount(reward_points, rewards_multiplier, ORE_MULTIPLIER_GLASS))

	if(reward_points > 1)
		new /obj/item/stack/ore/silver(src, calculate_ore_amount(reward_points, rewards_multiplier, ORE_MULTIPLIER_SILVER))

	if(reward_points > 2)
		new /obj/item/stack/ore/plasma(src, calculate_ore_amount(reward_points, rewards_multiplier, ORE_MULTIPLIER_PLASMA))
		new /obj/item/stack/ore/gold(src, calculate_ore_amount(reward_points, rewards_multiplier, ORE_MULTIPLIER_GOLD))
		new /obj/item/stack/ore/uranium(src, calculate_ore_amount(reward_points, rewards_multiplier, ORE_MULTIPLIER_URANIUM))

	if(reward_points > 3)
		new /obj/item/stack/ore/diamond(src, calculate_ore_amount(reward_points, rewards_multiplier, ORE_MULTIPLIER_DIAMOND))

/obj/structure/closet/crate/secure/bitrunning/decrypted/proc/calculate_ore_amount(reward_points, rewards_multiplier, ore_multiplier)
	var/base = rewards_multiplier + reward_points
	var/random_sum = (rand() + 0.5) * base
	return max(round(random_sum * ore_multiplier), 1)

#undef ORE_MULTIPLIER_IRON
#undef ORE_MULTIPLIER_GLASS
#undef ORE_MULTIPLIER_PLASMA
#undef ORE_MULTIPLIER_SILVER
#undef ORE_MULTIPLIER_GOLD
#undef ORE_MULTIPLIER_URANIUM
#undef ORE_MULTIPLIER_DIAMOND
