/datum/export/weapon
	abstract_type = /datum/export/weapon
	include_subtypes = FALSE

/datum/export/weapon/baton
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "электродубинки"
	export_types = list(/obj/item/melee/baton/security)
	exclude_types = list(/obj/item/melee/baton/security/cattleprod)
	include_subtypes = TRUE

/datum/export/weapon/knife
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "боевые ножи"
	export_types = list(/obj/item/kitchen/knife/combat)

/datum/export/weapon/taser
	cost = CARGO_CRATE_VALUE * 0.4
	unit_name = "продвинутые тазеры"
	export_types = list(/obj/item/gun/energy/gun/advtaser)

/datum/export/weapon/laser
	cost = CARGO_CRATE_VALUE
	unit_name = "лазерные винтовки"
	export_types = list(/obj/item/gun/energy/laser, /obj/item/gun/energy/laser/retro)

/datum/export/weapon/disabler
	cost = CARGO_CRATE_VALUE * 0.25
	unit_name = "усмирители"
	export_types = list(/obj/item/gun/energy/disabler)

/datum/export/weapon/energy_gun
	cost = CARGO_CRATE_VALUE * 0.75
	unit_name = "энергетические винтовки"
	export_types = list(/obj/item/gun/energy/gun)

/datum/export/weapon/mini_energy_gun
	cost = CARGO_CRATE_VALUE * 0.3
	unit_name = "энергетические пистолеты"
	export_types = list(/obj/item/gun/energy/gun/mini)

/datum/export/weapon/ion_rifle
	cost = CARGO_CRATE_VALUE * 2
	unit_name = "ионные винтовки"
	export_types = list(/obj/item/gun/energy/ionrifle, /obj/item/gun/energy/ionrifle/carbine)

/datum/export/weapon/xray
	cost = CARGO_CRATE_VALUE * 3
	unit_name = "рентгеновские лазеры"
	export_types = list(/obj/item/gun/energy/xray)

/datum/export/weapon/lasercannon
	cost = CARGO_CRATE_VALUE * 3
	unit_name = "лазерные пушки"
	export_types = list(/obj/item/gun/energy/lasercannon)

/datum/export/weapon/shotgun
	cost = CARGO_CRATE_VALUE * 1.5
	unit_name = "боевые дробовики"
	export_types = list(/obj/item/gun/projectile/shotgun/automatic/combat)

/datum/export/weapon/riot_shotgun
	cost = CARGO_CRATE_VALUE
	unit_name = "помповые дробовики"
	export_types = list(/obj/item/gun/projectile/shotgun/riot)

/datum/export/weapon/wt550
	cost = CARGO_CRATE_VALUE * 1.5
	unit_name = "пистолеты-пулемёты WT-550"
	export_types = list(/obj/item/gun/projectile/automatic/smg/wt550)

/datum/export/weapon/flashbang
	cost = CARGO_CRATE_VALUE * 0.025
	unit_name = "светошумовые гранаты"
	export_types = list(/obj/item/grenade/flashbang)

/datum/export/weapon/teargas
	cost = CARGO_CRATE_VALUE * 0.025
	unit_name = "гранаты со слезоточивым газом"
	export_types = list(/obj/item/grenade/chem_grenade/teargas)

/datum/export/weapon/flash
	cost = CARGO_CRATE_VALUE * 0.025
	unit_name = "вспышки"
	export_types = list(/obj/item/flash)

/datum/export/weapon/handcuffs
	cost = CARGO_CRATE_VALUE * 0.015
	unit_name = "наручники"
	export_types = list(/obj/item/restraints/handcuffs)
