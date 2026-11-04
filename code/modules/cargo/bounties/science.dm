/datum/bounty/item/science/relic
	name = "Устройства, открытые на экспериментаторе"
	description = "Пс-с, только ассистентам не говорите, но мы сбиваем цену на их \"странные предметы\". Выудите такой и отправьте нам, предварительно изучив его на экспериментаторе."
	reward = CARGO_CRATE_VALUE * 8
	wanted_types = list(/obj/item/relic = TRUE)

/datum/bounty/item/science/relic/applies_to(obj/shipped)
	if(!..())
		return FALSE
	var/obj/item/relic/experiment = shipped
	return experiment.revealed

/datum/bounty/item/science/pda
	name = "КПК"
	description = "Оказалось, NTNet всё-таки не мода. Отправьте несколько КПК, чтобы помочь нам освоить новейшие технологии."
	reward = CARGO_CRATE_VALUE * 6
	required_count = 4
	wanted_types = list(/obj/item/pda = TRUE)

/datum/bounty/item/science/anomaly_extract
	name = "Аномальный экстракт"
	description = "Нашим исследователям нужен аномальный экстракт для изучения. Отправьте один, пожалуйста."
	reward = CARGO_CRATE_VALUE * 20
	wanted_types = list(/obj/item/anomaly_extract = TRUE)
