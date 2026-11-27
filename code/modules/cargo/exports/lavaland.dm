/datum/export/lavaland
	abstract_type = /datum/export/lavaland

/datum/export/lavaland/minor
	cost = CARGO_CRATE_VALUE * 20
	unit_name = "малые артефакты Лаваленда"
	export_types = list(
		/obj/item/immortality_talisman,
		/obj/item/book_of_babel,
		/obj/item/wisp_lantern,
		/obj/item/organ/internal/cyberimp/arm/katana,
		/obj/item/organ/internal/heart/cursed/wizard,
		/obj/item/ship_in_a_bottle,
		/obj/item/jacobs_ladder,
		/obj/item/borg/upgrade/modkit/lifesteal,
		/obj/item/clothing/glasses/hud/godeye,
		/obj/item/shared_storage,
		/obj/item/gun/magic/hook,
		/obj/item/voodoo,
		/obj/item/eflowers,
		/obj/item/rune_scimmy,
	)

/datum/export/lavaland/major
	cost = CARGO_CRATE_VALUE * 40
	unit_name = "ценные артефакты Лаваленда"
	export_types = list(
		/obj/item/dragons_blood,
		/obj/item/lava_staff,
		/obj/item/melee/ghost_sword,
		/obj/item/prisoncube,
		/obj/item/rod_of_asclepius,
	)

/datum/export/lavaland/megafauna
	cost = CARGO_CRATE_VALUE * 80
	unit_name = "трофеи мегафауны"
	export_types = list(
		/obj/item/hierophant_club,
		/obj/item/melee/energy/cleaving_saw,
		/obj/item/organ/internal/vocal_cords/colossus,
		/obj/machinery/anomalous_crystal,
		/obj/item/mayhem,
		/obj/item/soulscythe,
		/obj/item/storm_staff,
		/obj/item/clothing/suit/space/hostile_environment,
	)

/datum/export/lavaland/gem
	cost = CARGO_CRATE_VALUE
	unit_name = "драгоценные камни"
	k_elasticity = 0
	export_types = list(/obj/item/gem)

/datum/export/lavaland/gem/get_base_cost(obj/item/gem/stone)
	return cost * stone.sell_multiplier
