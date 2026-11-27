/datum/bounty/item/slime
	reward = CARGO_CRATE_VALUE * 6

/datum/bounty/item/slime/New()
	..()
	description = "Глава научного отдела \"Нанотрейзен\" охотится за редким и экзотическим образцом: [name]. За находку назначена награда."
	reward += rand(0, 4) * 500

/datum/bounty/item/slime/green
	name = "Экстракт зелёного слайма"
	wanted_types = list(/obj/item/slime_extract/green = TRUE)

/datum/bounty/item/slime/pink
	name = "Экстракт розового слайма"
	wanted_types = list(/obj/item/slime_extract/pink = TRUE)

/datum/bounty/item/slime/gold
	name = "Экстракт золотого слайма"
	wanted_types = list(/obj/item/slime_extract/gold = TRUE)

/datum/bounty/item/slime/oil
	name = "Экстракт масляного слайма"
	wanted_types = list(/obj/item/slime_extract/oil = TRUE)

/datum/bounty/item/slime/black
	name = "Экстракт чёрного слайма"
	wanted_types = list(/obj/item/slime_extract/black = TRUE)

/datum/bounty/item/slime/lightpink
	name = "Экстракт светло-розового слайма"
	wanted_types = list(/obj/item/slime_extract/lightpink = TRUE)

/datum/bounty/item/slime/adamantine
	name = "Экстракт адамантинового слайма"
	wanted_types = list(/obj/item/slime_extract/adamantine = TRUE)

/datum/bounty/item/slime/rainbow
	name = "Экстракт радужного слайма"
	wanted_types = list(/obj/item/slime_extract/rainbow = TRUE)
