/datum/bounty/item/medical/heart
	name = "Сердце"
	description = "Коммандер Джонсон в критическом состоянии после очередного сердечного приступа. Врачи говорят, ему срочно нужно новое сердце. Отправьте его, живо! Кибернетическое тоже возьмём, но только улучшенное."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(
		/obj/item/organ/internal/heart = TRUE,
		/obj/item/organ/internal/heart/cybernetic = FALSE,
		/obj/item/organ/internal/heart/cybernetic/upgraded = TRUE,
		/obj/item/organ/internal/heart/gland = FALSE,
		/obj/item/organ/internal/heart/demon = FALSE,
		/obj/item/organ/internal/heart/cursed = FALSE,
	)

/datum/bounty/item/medical/lung
	name = "Лёгкие"
	description = "После недавнего взрыва на Центральном командовании у многих сотрудников пробиты лёгкие. Отправьте запасные, и вас вознаградят. Кибернетические тоже возьмём, но только улучшенные."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 3
	wanted_types = list(
		/obj/item/organ/internal/lungs = TRUE,
		/obj/item/organ/internal/lungs/cybernetic = FALSE,
		/obj/item/organ/internal/lungs/cybernetic/upgraded = TRUE,
	)

/datum/bounty/item/medical/appendix
	name = "Аппендикс"
	description = "Шеф Гибб с Центрального командования хочет приготовить блюдо из особого деликатеса — аппендикса. Если отправите, он заплатит."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/item/organ/internal/appendix = TRUE)

/datum/bounty/item/medical/ears
	name = "Уши"
	description = "Несколько сотрудников станции 12 оглохли из-за несанкционированной клоунады. Отправьте им новые органические уши."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 3
	wanted_types = list(
		/obj/item/organ/internal/ears = TRUE,
		/obj/item/organ/internal/ears/cybernetic = FALSE,
		/obj/item/organ/internal/ears/microphone = FALSE,
	)

/datum/bounty/item/medical/liver
	name = "Печень"
	description = "После встречи с послами Третьего Советского Союза несколько высокопоставленных дипломатов ЦК госпитализированы с печёночной недостаточностью. Поможете? Кибернетическую тоже возьмём, но только улучшенную."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 3
	wanted_types = list(
		/obj/item/organ/internal/liver = TRUE,
		/obj/item/organ/internal/liver/cybernetic = FALSE,
		/obj/item/organ/internal/liver/cybernetic/upgraded = TRUE,
	)

/datum/bounty/item/medical/eye
	name = "Органические глаза"
	description = "Директор исследований станции 5 Виллем просит несколько пар неробототехнических глаз. Не задавайте вопросов, просто отправьте."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 3
	wanted_types = list(
		/obj/item/organ/internal/eyes = TRUE,
		/obj/item/organ/internal/eyes/cybernetic = FALSE,
		/obj/item/organ/internal/eyes/optical_sensor = FALSE,
	)

/datum/bounty/item/medical/chainsaw
	name = "Бензопила"
	description = "Главврач на ЦК не может оперировать големов. Она просит одну бензопилу, пожалуйста."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/item/twohanded/chainsaw = TRUE)

/datum/bounty/item/medical/surgerycomp
	name = "Хирургический компьютер"
	description = "После очередного взрыва на ежегодном сырном фестивале ЦК у нас гора раненых. Пожалуйста, отправьте новый хирургический компьютер."
	reward = CARGO_CRATE_VALUE * 12
	wanted_types = list(/obj/machinery/computer/operating = TRUE)

/datum/bounty/item/medical/surgerytable
	name = "Операционный стол"
	description = "После недавнего наплыва заражённых сотрудников стало ясно, что одних масок мало. А вот серебряные операционные столы могут помочь — отправьте нам один."
	reward = CARGO_CRATE_VALUE * 6
	wanted_types = list(/obj/machinery/optable = TRUE)
