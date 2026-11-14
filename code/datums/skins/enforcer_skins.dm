/datum/item_skin_data/enforcer
	item_path = /obj/item/gun/projectile/automatic/pistol/enforcer

/datum/item_skin_data/enforcer/grey_slide
	name = "Серый затвор"
	icon_state = "enforcer_grey"

/datum/item_skin_data/enforcer/red_slide
	name = "Красный затвор"
	icon_state = "enforcer_red"

/datum/item_skin_data/enforcer/green_slide
	name = "Зелёный затвор"
	icon_state = "enforcer_green"

/datum/item_skin_data/enforcer/tan_slide
	name = "Бежевый затвор"
	icon_state = "enforcer_tan"

/datum/item_skin_data/enforcer/black_slide
	name = "Чёрный затвор"
	icon_state = "enforcer_black"

/datum/item_skin_data/enforcer/green_handle
	name = "Зелёная рукоять"
	icon_state = "enforcer_greengrip"

/datum/item_skin_data/enforcer/tan_handle
	name = "Бежевая рукоять"
	icon_state = "enforcer_tangrip"

/datum/item_skin_data/enforcer/red_handle
	name = "Красная рукоять"
	icon_state = "enforcer_redgrip"

/datum/item_skin_data/enforcer/blowngrip
	name = "Деревянная рукоять"
	icon_state = "enforcer_browngrip"
	donation_tier = 1

/datum/item_skin_data/enforcer/silver
	name = "Серебрянный"
	icon_state = "enforcer_silver"
	donation_tier = 2

/datum/item_skin_data/enforcer/backgold
	name = "Черное золото"
	icon_state = "enforcer_blackgold"
	donation_tier = 3

/datum/item_skin_data/enforcer/gold
	name = "Золотой затвор"
	icon_state = "enforcer_gold"
	donation_tier = 4

/datum/item_skin_data/gun/cyberpunk_enforcer
	item_path = /obj/item/gun/projectile/automatic/pistol/enforcer
	fire_sound = 'sound/weapons/gunshots/nue_shoot.ogg'
	hide_magazine = TRUE

/datum/item_skin_data/gun/cyberpunk_enforcer/nue
	name = "Нуэ"
	icon = 'icons/obj/weapons/pistols_36x32.dmi'
	icon_state = "nue"
	donation_tier = 2
	attachable_offset = list(
		ATTACHMENT_SLOT_MUZZLE = list(ATTACHMENT_OFFSET_X = 25, ATTACHMENT_OFFSET_Y = 2),
		ATTACHMENT_SLOT_RAIL = list(ATTACHMENT_OFFSET_X = 0, ATTACHMENT_OFFSET_Y = 7),
		ATTACHMENT_SLOT_UNDER = list(ATTACHMENT_OFFSET_X = 11, ATTACHMENT_OFFSET_Y = -5),
	)

/datum/item_skin_data/gun/cyberpunk_enforcer/malorian
	name = "Малориан"
	icon = 'icons/obj/weapons/pistols_48x32.dmi'
	icon_state = "malorian"
	donation_tier = 4
	attachable_offset = list(
		ATTACHMENT_SLOT_MUZZLE = list(ATTACHMENT_OFFSET_X = 37, ATTACHMENT_OFFSET_Y = 2),
		ATTACHMENT_SLOT_RAIL = list(ATTACHMENT_OFFSET_X = 4, ATTACHMENT_OFFSET_Y = 9),
		ATTACHMENT_SLOT_UNDER = list(ATTACHMENT_OFFSET_X = 14, ATTACHMENT_OFFSET_Y = -5),
	)
