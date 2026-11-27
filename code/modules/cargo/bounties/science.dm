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

/datum/bounty/item/science/ref_anomaly
	name = "Очищенное блюспейс-ядро"
	description = "Нам нужно блюспейс-ядро, чтобы собрать сумку хранения. Отправьте одно, пожалуйста."
	reward = CARGO_CRATE_VALUE * 20
	wanted_types = list(/obj/item/assembly/signaler/core/bluespace = TRUE)

/datum/bounty/item/science/ref_anomaly/applies_to(obj/shipped)
	if(!..())
		return FALSE
	var/obj/item/assembly/signaler/core/anomaly_core = shipped
	return anomaly_core.tier >= 2

/datum/bounty/item/science/ref_anomaly/flux
	name = "Очищенное энергетическое ядро"
	description = "Мы пытаемся собрать тесла-пушку против моли. Отправьте энергетическое ядро, пожалуйста."
	wanted_types = list(/obj/item/assembly/signaler/core/energetic = TRUE)

/datum/bounty/item/science/ref_anomaly/pyro
	name = "Очищенное атмосферное ядро"
	description = "Нам нужно изучить очищенное атмосферное ядро, пожалуйста, отправьте одно."
	wanted_types = list(/obj/item/assembly/signaler/core/atmospheric = TRUE)

/datum/bounty/item/science/ref_anomaly/grav
	name = "Очищенное гравитационное ядро"
	description = "Центральный отдел исследований пытается научить мехов летать, отправьте гравитационное ядро."
	wanted_types = list(/obj/item/assembly/signaler/core/gravitational = TRUE)

/datum/bounty/item/science/ref_anomaly/vortex
	name = "Очищенное вихревое ядро"
	description = "Мы собираемся бросить вихревое ядро в червоточину и посмотреть, что будет. Отправьте одно."
	wanted_types = list(/obj/item/assembly/signaler/core/vortex = TRUE)
