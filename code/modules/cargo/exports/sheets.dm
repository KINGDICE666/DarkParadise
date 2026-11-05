/datum/export/stack
	abstract_type = /datum/export/stack
	k_hit_percentile = 0.2 / MAX_STACK_SIZE
	k_recovery_time = 8 MINUTES

/datum/export/stack/get_amount(obj/object)
	var/obj/item/stack/stack = object
	if(istype(stack))
		return stack.amount
	return 0

/datum/export/stack/hot_ice
	cost = CARGO_CRATE_VALUE * 0.8
	unit_name = "горячий лёд"
	export_types = list(/obj/item/stack/sheet/hot_ice)

/datum/export/stack/metal_hydrogen
	cost = CARGO_CRATE_VALUE * 1.05
	unit_name = "металлический водород"
	export_types = list(/obj/item/stack/sheet/mineral/metal_hydrogen)

/datum/export/stack/ammonia_crystals
	cost = CARGO_CRATE_VALUE * 0.125
	unit_name = "кристаллы аммиака"
	export_types = list(/obj/item/stack/ammonia_crystals)

/datum/export/stack/zaukerite
	cost = CARGO_CRATE_VALUE * 0.6
	unit_name = "заукерит"
	export_types = list(/obj/item/stack/sheet/mineral/zaukerite)

/datum/export/stack/plasteel
	cost = 30
	unit_name = "пласталь (листы)"
	export_types = list(/obj/item/stack/sheet/plasteel)

/datum/export/stack/rglass
	cost = 3
	unit_name = "армированное стекло (листы)"
	export_types = list(/obj/item/stack/sheet/rglass)

/datum/export/stack/plasmaglass
	cost = 15
	unit_name = "плазменное стекло (листы)"
	export_types = list(/obj/item/stack/sheet/plasmaglass, /obj/item/stack/sheet/plasmarglass)

/datum/export/stack/titaniumglass
	cost = 25
	unit_name = "титановое стекло (листы)"
	export_types = list(/obj/item/stack/sheet/titaniumglass, /obj/item/stack/sheet/plastitaniumglass)

/datum/export/stack/plastitanium
	cost = 60
	unit_name = "пластитан (листы)"
	export_types = list(/obj/item/stack/sheet/mineral/plastitanium)

/datum/export/stack/adamantine
	cost = 200
	unit_name = "адамантин (листы)"
	export_types = list(/obj/item/stack/sheet/mineral/adamantine)

/datum/export/stack/mythril
	cost = 500
	unit_name = "мифрил (листы)"
	export_types = list(/obj/item/stack/sheet/mineral/mythril)

/datum/export/stack/abductor
	cost = 400
	unit_name = "инопланетный сплав (листы)"
	export_types = list(/obj/item/stack/sheet/mineral/abductor, /obj/item/stack/sheet/abductorglass)

/datum/export/stack/wood
	cost = 3
	unit_name = "доски"
	export_types = list(/obj/item/stack/sheet/wood, /obj/item/stack/sheet/bamboo)

/datum/export/stack/sandstone
	unit_name = "песчаник (блоки)"
	export_types = list(/obj/item/stack/sheet/mineral/sandstone)

/datum/export/stack/cardboard
	unit_name = "картон (листы)"
	export_types = list(/obj/item/stack/sheet/cardboard)

/datum/export/stack/cloth
	cost = 5
	unit_name = "ткань (рулоны)"
	export_types = list(/obj/item/stack/sheet/cloth, /obj/item/stack/sheet/cotton)

/datum/export/stack/durathread
	cost = 70
	unit_name = "дюраткань (рулоны)"
	export_types = list(/obj/item/stack/sheet/durathread)

/datum/export/stack/leather
	cost = 15
	unit_name = "кожа"
	export_types = list(/obj/item/stack/sheet/leather, /obj/item/stack/sheet/fur)

/datum/export/stack/bone
	cost = 30
	unit_name = "кости и жилы"
	export_types = list(/obj/item/stack/sheet/bone, /obj/item/stack/sheet/sinew)

/datum/export/stack/brass
	cost = 40
	unit_name = "латунь (листы)"
	export_types = list(/obj/item/stack/sheet/brass)

/datum/export/stack/runed_metal
	cost = 40
	unit_name = "рунический металл (листы)"
	export_types = list(/obj/item/stack/sheet/runed_metal)

/datum/export/stack/cable
	cost = 0.2
	unit_name = "кабель (отрезки)"
	export_types = list(/obj/item/stack/cable_coil)

/datum/export/stack/monkey
	cost = CARGO_CRATE_VALUE * 0.25
	unit_name = "обезьяньи шкуры"
	export_types = list(/obj/item/stack/sheet/animalhide/monkey)

/datum/export/stack/human
	cost = CARGO_CRATE_VALUE * 0.5
	unit_name = "человеческая кожа"
	export_types = list(/obj/item/stack/sheet/animalhide/human)

/datum/export/stack/goliath_hide
	cost = CARGO_CRATE_VALUE
	unit_name = "шкуры голиафа"
	export_types = list(/obj/item/stack/sheet/animalhide/goliath_hide)

/datum/export/stack/ashdrake
	cost = CARGO_CRATE_VALUE * 4
	unit_name = "шкуры пепельного дрейка"
	export_types = list(/obj/item/stack/sheet/animalhide/ashdrake)

/datum/export/stack/cat
	cost = CARGO_CRATE_VALUE * 0.75
	unit_name = "кошачьи шкуры"
	export_types = list(/obj/item/stack/sheet/animalhide/cat)

/datum/export/stack/corgi
	cost = CARGO_CRATE_VALUE
	unit_name = "шкуры корги"
	export_types = list(/obj/item/stack/sheet/animalhide/corgi)

/datum/export/stack/lizard
	cost = CARGO_CRATE_VALUE * 0.75
	unit_name = "кожа ящера"
	export_types = list(/obj/item/stack/sheet/animalhide/lizard)

/datum/export/stack/xeno
	cost = CARGO_CRATE_VALUE * 2.5
	unit_name = "шкуры ксеноморфа"
	export_types = list(/obj/item/stack/sheet/animalhide/xeno, /obj/item/stack/sheet/xenochitin)

/datum/export/stack/hide
	cost = CARGO_CRATE_VALUE * 0.1
	unit_name = "шкуры животных"
	export_types = list(/obj/item/stack/sheet/animalhide/generic, /obj/item/stack/sheet/hairlesshide, /obj/item/stack/sheet/wetleather)
