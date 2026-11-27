/datum/bounty/item/engineering/emitter
	name = "Эмиттер"
	description = "Судя по числу расслоений в вашем секторе, в конструкции эмиттеров вашей станции может быть дефект. Отправьте нам один из ваших."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/machinery/power/emitter = TRUE)

/datum/bounty/item/engineering/hydro_tray
	name = "Гидропонный лоток"
	description = "Лаборанты пытаются снизить энергопотребление гидропонных лотков, но спалили последний. Соберёте нам новый?"
	reward = CARGO_CRATE_VALUE * 4
	wanted_types = list(/obj/machinery/hydroponics/constructable = TRUE)

/datum/bounty/item/engineering/cyborg_charger
	name = "Станция подзарядки"
	description = "Нам не хватает зарядных станций на все МЭКи. Отправьте нам одну из ваших."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/machinery/recharge_station = TRUE)

/datum/bounty/item/engineering/smes_unit
	name = "Накопитель энергии"
	description = "Нам нужно хранить больше энергии. Достаньте нам СМЕС."
	reward = CARGO_CRATE_VALUE * 6
	wanted_types = list(/obj/machinery/power/smes = TRUE)

/datum/bounty/item/engineering/pacman
	name = "Генератор П.А.К.М.А.Н."
	description = "У нашего резервного генератора перегорел предохранитель, срочно нужен новый."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/machinery/power/port_gen/pacman = TRUE)

/datum/bounty/item/engineering/field_gen
	name = "Генератор поля"
	description = "У одного из наших защитных генераторов истекла гарантия, нужен новый на замену."
	reward = CARGO_CRATE_VALUE * 6
	wanted_types = list(/obj/machinery/field/generator = TRUE)

/datum/bounty/item/engineering/tesla_coil
	name = "Катушка Теслы"
	description = "Счёт за электричество слишком велик, достаньте нам катушку Теслы, чтобы его компенсировать."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/machinery/power/energy_accumulator/tesla_coil = TRUE)

/datum/bounty/item/engineering/welding_tank
	name = "Бак сварочного топлива"
	description = "Инженерам нужно больше сварочного топлива, отправьте нам бак."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/structure/reagent_dispensers/fueltank = TRUE)

/datum/bounty/item/engineering/reflector
	name = "Отражатель"
	description = "Мы хотим, чтобы луч наших эмиттеров шёл длинным путём. Достаньте нам отражатель."
	reward = CARGO_CRATE_VALUE * 7
	wanted_types = list(/obj/structure/reflector = TRUE)
