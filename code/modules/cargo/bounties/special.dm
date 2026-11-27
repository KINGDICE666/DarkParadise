/datum/bounty/item/special
	unique = TRUE

/datum/bounty/item/special/alien_organs
	name = "Органы ксеноморфов"
	description = "\"Нанотрейзен\" интересуется биологией ксеноморфов. Отправьте набор органов, и вас щедро вознаградят."
	reward = CARGO_CRATE_VALUE * 50
	required_count = 3
	wanted_types = list(
		/obj/item/organ/internal/brain/xeno = TRUE,
		/obj/item/organ/internal/xenos = TRUE,
		/obj/item/organ/internal/body_egg/alien_embryo = TRUE,
	)

/datum/bounty/item/special/syndicate_documents
	name = "Документы \"Синдиката\""
	description = "Сведения о \"Синдикате\" высоко ценятся на ЦК. Если найдёте документы \"Синдиката\", отправьте их. Вы можете спасти жизни."
	reward = CARGO_CRATE_VALUE * 30
	wanted_types = list(/obj/item/documents/syndicate = TRUE)

/datum/bounty/item/special/adamantine
	name = "Адамантин"
	description = "Отделу аномальных материалов \"Нанотрейзен\" отчаянно нужен адамантин. Отправьте крупную партию, и мы не останемся в долгу."
	reward = CARGO_CRATE_VALUE * 70
	required_count = 10
	wanted_types = list(/obj/item/stack/sheet/mineral/adamantine = TRUE)
