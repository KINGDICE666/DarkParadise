#define PVE_MEDIC_AURA_RANGE 3
#define PVE_MEDIC_AURA_HEAL 1.5
#define PVE_GUARDIAN_DAMAGE_MOD 0.7

/datum/pve_class
	var/id
	var/title
	var/description
	var/obj/item/emblem
	var/list/kit = list()
	var/list/discounts = list()
	var/bounty_multiplier = 1

/datum/pve_class/proc/get_price_multiplier(category)
	return discounts[category] || 1

/datum/pve_class/proc/equip(mob/living/carbon/human/player)
	for(var/item_path in kit)
		for(var/i in 1 to (kit[item_path] || 1))
			var/obj/item/item = new item_path(get_turf(player))
			if(!player.equip_to_appropriate_slot(item) && !player.put_in_hands(item))
				player.equip_or_collect(item, ITEM_SLOT_BACK)
	apply_perks(player)

/datum/pve_class/proc/apply_perks(mob/living/carbon/human/player)
	return

/datum/pve_class/proc/class_process(mob/living/carbon/human/player, list/mob/living/carbon/human/allies)
	return

/datum/pve_class/proc/radial_choice()
	var/datum/radial_menu_choice/choice = new
	choice.image = image(initial(emblem.icon), initial(emblem.icon_state))
	choice.name = title
	choice.info = description
	return choice

/datum/pve_class/assault
	id = PVE_CLASS_ASSAULT
	title = "Штурмовик"
	description = "Передовая линия обороны. Пистолет, бронежилет и шлем с самого начала, скидка 25% на оружие и патроны, доступ к карабину М-90 и пулемёту L6."
	emblem = /obj/item/gun/projectile/automatic/m90
	kit = list(
		/obj/item/clothing/suit/armor/vest = 1,
		/obj/item/clothing/head/helmet = 1,
		/obj/item/gun/projectile/automatic/pistol = 1,
		/obj/item/ammo_box/magazine/m10mm = 2,
		/obj/item/kitchen/knife/combat = 1,
	)
	discounts = list(
		PVE_CATEGORY_WEAPONS = 0.75,
		PVE_CATEGORY_AMMO = 0.75,
	)

/datum/pve_class/medic
	id = PVE_CLASS_MEDIC
	title = "Медик"
	description = "Держит команду на ногах. Рядом с медиком союзники постепенно лечатся, медикаменты на 40% дешевле, доступны дефибриллятор и медицинский лучемёт."
	emblem = /obj/item/storage/firstaid/regular
	kit = list(
		/obj/item/clothing/glasses/hud/health = 1,
		/obj/item/storage/firstaid/regular = 1,
		/obj/item/gun/energy/laser/retro = 1,
		/obj/item/stack/medical/bruise_pack/advanced = 1,
	)
	discounts = list(
		PVE_CATEGORY_MEDICINE = 0.6,
	)

/datum/pve_class/medic/class_process(mob/living/carbon/human/player, list/mob/living/carbon/human/allies)
	for(var/mob/living/carbon/human/ally as anything in allies)
		if(ally == player || ally.stat == DEAD || get_dist(ally, player) > PVE_MEDIC_AURA_RANGE)
			continue
		if(!ally.getBruteLoss() && !ally.getFireLoss())
			continue
		ally.heal_overall_damage(PVE_MEDIC_AURA_HEAL, PVE_MEDIC_AURA_HEAL)
		if(prob(25))
			new /obj/effect/temp_visual/heal(get_turf(ally), "#80F5FF")

/datum/pve_class/engineer
	id = PVE_CLASS_ENGINEER
	title = "Инженер"
	description = "Строит оборону. Сооружения на 35% дешевле и разворачиваются мгновенно, только инженер покупает турели. Сваркой быстро чинит Маяк и турели."
	emblem = /obj/item/storage/toolbox/mechanical
	kit = list(
		/obj/item/storage/belt/utility/full = 1,
		/obj/item/clothing/glasses/welding = 1,
		/obj/item/gun/projectile/shotgun/riot/buckshot = 1,
		/obj/item/pve_deployable/barricade = 2,
		/obj/item/stack/sheet/metal/fifty = 1,
	)
	discounts = list(
		PVE_CATEGORY_STRUCTURES = 0.65,
	)

/datum/pve_class/marksman
	id = PVE_CLASS_MARKSMAN
	title = "Стрелок"
	description = "Убивает издалека. Винтовка Мосина с обоймами, на 30% больше кредитов за убийства, доступ к снайперской винтовке и тепловизору."
	emblem = /obj/item/gun/projectile/automatic/sniper_rifle
	kit = list(
		/obj/item/gun/projectile/shotgun/boltaction = 1,
		/obj/item/ammo_box/speedloader/a762 = 3,
		/obj/item/flashlight/seclite = 1,
	)
	discounts = list(
		PVE_CATEGORY_AMMO = 0.8,
	)
	bounty_multiplier = 1.3

/datum/pve_class/guardian
	id = PVE_CLASS_GUARDIAN
	title = "Защитник"
	description = "Держит проход в рукопашной. Антибунтовая броня, щит и клеймор, получает на 30% меньше урона, броня дешевле на 30%, доступ к огнемёту."
	emblem = /obj/item/shield/riot
	kit = list(
		/obj/item/clothing/suit/armor/riot = 1,
		/obj/item/clothing/head/helmet/riot = 1,
		/obj/item/shield/riot = 1,
		/obj/item/melee/claymore = 1,
	)
	discounts = list(
		PVE_CATEGORY_ARMOR = 0.7,
	)

/datum/pve_class/guardian/apply_perks(mob/living/carbon/human/player)
	player.physiology.brute_mod *= PVE_GUARDIAN_DAMAGE_MOD
	player.physiology.burn_mod *= PVE_GUARDIAN_DAMAGE_MOD

#undef PVE_MEDIC_AURA_RANGE
#undef PVE_MEDIC_AURA_HEAL
#undef PVE_GUARDIAN_DAMAGE_MOD

/datum/outfit/pve
	name = "PvE Defender"
	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/jackboots
	back = /obj/item/storage/backpack
	id = /obj/item/card/id
	l_pocket = /obj/item/flashlight
	backpack_contents = list(/obj/item/stack/medical/bruise_pack = 1)

/datum/outfit/pve/pre_equip(mob/living/carbon/human/human, visualsOnly = FALSE)
	. = ..()
	human.dna.species.before_equip_job(SSjobs.GetJob(JOB_TITLE_CIVILIAN), human, visualsOnly)

/datum/outfit/pve/post_equip(mob/living/carbon/human/human, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return
	human.dna.species.after_equip_job(SSjobs.GetJob(JOB_TITLE_CIVILIAN), human, visualsOnly)
	var/obj/item/card/id/card = human.wear_id
	if(istype(card))
		card.registered_name = human.real_name
		card.assignment = "Защитник Маяка"
		card.update_label()
	var/datum/game_mode/pve/mode = get_pve_mode()
	if(!mode)
		return
	if(human.z != mode.arena_z)
		human.forceMove(pick(mode.player_spawns))
	mode.register_player(human)
