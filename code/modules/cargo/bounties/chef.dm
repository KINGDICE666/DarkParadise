/datum/bounty/item/chef/birthday_cake
	name = "Праздничный торт"
	description = "Скоро день рождения \"Нанотрейзен\"! Отправьте Центральному командованию праздничный торт!"
	reward = CARGO_CRATE_VALUE * 8
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/sliceable/birthdaycake = TRUE,
		/obj/item/reagent_containers/food/snacks/birthdaycakeslice = TRUE,
	)

/datum/bounty/item/chef/soup
	name = "Суп"
	description = "Чтобы подавить восстание бездомных, \"Нанотрейзен\" будет кормить супом всех низкооплачиваемых работников."

/datum/bounty/item/chef/soup/New()
	required_count = pick(2, 3, 4, 5)
	wanted_types = list(/obj/item/reagent_containers/food/snacks/soup = TRUE)
	reward = CARGO_CRATE_VALUE * required_count * 2
	description += " Отправьте нам [required_count] [declension_ru(required_count, "тарелку", "тарелки", "тарелок")] любого супа."
	..()

/datum/bounty/item/chef/popcorn
	name = "Пакеты попкорна"
	description = "Высшее руководство хочет устроить киновечер. Отправьте пакеты попкорна по такому случаю."
	reward = CARGO_CRATE_VALUE * 6
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/popcorn = TRUE)

/datum/bounty/item/chef/onionrings
	name = "Луковые кольца"
	description = "\"Нанотрейзен\" отмечает День Сатурна. Отправьте луковые кольца в знак поддержки станции."
	reward = CARGO_CRATE_VALUE * 6
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/onionrings = TRUE)

/datum/bounty/item/chef/icecreamsandwich
	name = "Сэндвичи с мороженым"
	description = "Высшее руководство без остановки требует сэндвичей с мороженым. Пожалуйста, отправьте несколько."
	reward = CARGO_CRATE_VALUE * 8
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/icecreamsandwich = TRUE)

/datum/bounty/item/chef/bread
	name = "Хлеб"
	description = "Проблемы с централизованным планированием взвинтили цены на хлеб. Отправьте хлеба, чтобы снять напряжение."
	reward = CARGO_CRATE_VALUE * 2
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/sliceable/bread = TRUE,
		/obj/item/reagent_containers/food/snacks/breadslice = TRUE,
		/obj/item/reagent_containers/food/snacks/bun = TRUE,
	)

/datum/bounty/item/chef/pie
	name = "Пирог"
	description = "3,14159? Нет! Руководству ЦК нужен съедобный пирог! Отправьте целый."
	reward = 3142
	wanted_types = list(/obj/item/reagent_containers/food/snacks/pie = TRUE)

/datum/bounty/item/chef/salad
	name = "Салаты"
	description = "Руководство ЦК взялось за здоровое питание. Ваш заказ — отправить салаты."
	reward = CARGO_CRATE_VALUE * 6
	required_count = 3
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/aesirsalad = TRUE,
		/obj/item/reagent_containers/food/snacks/herbsalad = TRUE,
		/obj/item/reagent_containers/food/snacks/validsalad = TRUE,
		/obj/item/reagent_containers/food/snacks/oliviersalad = TRUE,
		/obj/item/reagent_containers/food/snacks/vegisalad = TRUE,
		/obj/item/reagent_containers/food/snacks/junglesalad = TRUE,
		/obj/item/reagent_containers/food/snacks/delightsalad = TRUE,
		/obj/item/reagent_containers/food/snacks/customizable/cook/salad = TRUE,
	)

/datum/bounty/item/chef/carrotfries
	name = "Морковный фри"
	description = "Ночное зрение может стоить жизни! Заказ — партия морковного фри."
	reward = CARGO_CRATE_VALUE * 7
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/carrotfries = TRUE)

/datum/bounty/item/chef/superbite
	name = "Бургер \"Супер-кусь\""
	description = "Коммандер Таббс думает, что поставит мировой рекорд по поеданию на скорость. Ему нужен только бургер \"Супер-кусь\"."
	reward = CARGO_CRATE_VALUE * 24
	wanted_types = list(/obj/item/reagent_containers/food/snacks/superbiteburger = TRUE)

/datum/bounty/item/chef/poppypretzel
	name = "Крендель с маком"
	description = "Центральному командованию нужен повод уволить главу кадров. Отправьте крендель с маком, чтобы он провалил тест на наркотики."
	reward = CARGO_CRATE_VALUE * 6
	wanted_types = list(/obj/item/reagent_containers/food/snacks/poppypretzel = TRUE)

/datum/bounty/item/chef/cubancarp
	name = "Кубинский карп"
	description = "В честь рождения Кастро XXVII отправьте на ЦК одного кубинского карпа."
	reward = CARGO_CRATE_VALUE * 16
	wanted_types = list(/obj/item/reagent_containers/food/snacks/cubancarp = TRUE)

/datum/bounty/item/chef/hotdog
	name = "Хот-дог"
	description = "\"Нанотрейзен\" проводит дегустацию, чтобы выбрать лучший рецепт хот-дога. Отправьте версию вашей станции для участия."
	reward = CARGO_CRATE_VALUE * 16
	wanted_types = list(/obj/item/reagent_containers/food/snacks/hotdog = TRUE)

/datum/bounty/item/chef/eggplantparm
	name = "Баклажаны пармиджана"
	description = "На ЦК приезжает знаменитый певец, и по контракту ему подают только баклажаны пармиджана. Отправьте немного, пожалуйста!"
	reward = CARGO_CRATE_VALUE * 7
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/eggplantparm = TRUE)

/datum/bounty/item/chef/muffin
	name = "Маффины"
	description = "На ЦК приехал Маффинщик, но забыл свои маффины! Ваш заказ — исправить это."
	reward = CARGO_CRATE_VALUE * 6
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/muffin = TRUE)

/datum/bounty/item/chef/chawanmushi
	name = "Тяванмуси"
	description = "\"Нанотрейзен\" хочет улучшить отношения с дочерней компанией \"Джапанотрейзен\". Немедленно отправьте тяванмуси."
	reward = CARGO_CRATE_VALUE * 16
	wanted_types = list(/obj/item/reagent_containers/food/snacks/chawanmushi = TRUE)

/datum/bounty/item/chef/kebab
	name = "Кебабы"
	description = "Убрать весь кебаб со станции, вы лучшая еда. Отправьте на ЦК, чтобы убрать из помещений."
	reward = CARGO_CRATE_VALUE * 7
	required_count = 3
	wanted_types = list(
		/obj/item/reagent_containers/food/snacks/kabob = TRUE,
		/obj/item/reagent_containers/food/snacks/monkeykabob = TRUE,
		/obj/item/reagent_containers/food/snacks/tofukabob = TRUE,
		/obj/item/reagent_containers/food/snacks/customizable/cook/kebab = TRUE,
	)

/datum/bounty/item/chef/soylentgreen
	name = "Зелёный сойлент"
	description = "На ЦК слышали много хорошего о продукте \"Зелёный сойлент\" и хотели бы его попробовать. Если угодите им, ждите приятного бонуса."
	reward = CARGO_CRATE_VALUE * 10
	wanted_types = list(/obj/item/reagent_containers/food/snacks/soylentgreen = TRUE)

/datum/bounty/item/chef/pancakes
	name = "Блинчики"
	description = "В \"Нанотрейзен\" сотрудники — это семья. А что любят семьи? Блинчики. Отправьте чёртову дюжину."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 13
	wanted_types = list(/obj/item/reagent_containers/food/snacks/pancake = TRUE)

/datum/bounty/item/chef/corgifarming
	name = "Шкуры корги"
	description = "Космической яхте адмирала Вайнштейна нужна новая обивка. Дюжина шкур корги подойдёт как нельзя лучше."
	reward = CARGO_CRATE_VALUE * 60
	required_count = 12
	wanted_types = list(/obj/item/stack/sheet/animalhide/corgi = TRUE)

/datum/bounty/item/chef/pickles
	name = "Соленья"
	description = "Отделу контроля продуктов не хватает солений, чтобы как следует оценить разные виды крепкого алкоголя."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 7
	wanted_types = list(/obj/item/reagent_containers/food/snacks/pickles = TRUE)
