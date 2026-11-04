/datum/bounty/item/assistant/strange_object
	name = "Странный предмет"
	description = "\"Нанотрейзен\" заинтересовалась странными предметами. Найдите такой в техтоннелях и немедленно отправьте на ЦК."
	reward = CARGO_CRATE_VALUE * 2.4
	wanted_types = list(/obj/item/relic = TRUE)

/datum/bounty/item/assistant/stunprod
	name = "Оглушающая палка"
	description = "ЦК требуется оглушающая палка для работы с несогласными. Соберите её и отправьте."
	reward = CARGO_CRATE_VALUE * 2.6
	wanted_types = list(/obj/item/melee/baton/security/cattleprod = TRUE)

/datum/bounty/item/assistant/soap
	name = "Мыло"
	description = "Из душевых ЦК пропало мыло, и никто не знает, кто его взял. Восполните пропажу и станьте героем, который так нужен ЦК."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 3
	wanted_types = list(/obj/item/soap = TRUE)

/datum/bounty/item/assistant/spear
	name = "Копья"
	description = "Службе безопасности ЦК урезали бюджет. Вам заплатят, если вы отправите партию копий."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 5
	wanted_types = list(/obj/item/twohanded/spear = TRUE)

/datum/bounty/item/assistant/toolbox
	name = "Укомплектованный ящик для инструментов"
	description = "На ЦК не хватает робастности. Отправьте полностью укомплектованный ящик для инструментов: отвёртка, гаечный ключ, сварочный аппарат, лом, газоанализатор и кусачки."
	reward = CARGO_CRATE_VALUE * 4
	wanted_types = list(/obj/item/storage/toolbox = TRUE)
	var/static/list/static_packing_list = list(
		/obj/item/screwdriver,
		/obj/item/wrench,
		/obj/item/weldingtool,
		/obj/item/crowbar,
		/obj/item/analyzer,
		/obj/item/wirecutters,
	)

/datum/bounty/item/assistant/toolbox/applies_to(obj/shipped)
	var/list/packing_list = static_packing_list.Copy()
	for(var/obj/item_contents as anything in shipped.contents)
		for(var/match_type in packing_list)
			if(istype(item_contents, match_type))
				packing_list -= match_type
				break
		if(!length(packing_list))
			return ..()
	return FALSE

/datum/bounty/item/assistant/toolbox/ship(obj/shipped)
	. = ..()
	for(var/obj/object as anything in shipped.contents)
		if(!is_type_in_list(object, static_packing_list))
			object.forceMove(shipped.drop_location())

/datum/bounty/item/assistant/statue
	name = "Статуя"
	description = "ЦК хочет заказать статую для новой картинной галереи. Отправьте её, когда будет готова."
	reward = CARGO_CRATE_VALUE * 4
	wanted_types = list(/obj/structure/statue = TRUE)

/datum/bounty/item/assistant/clown_box
	name = "Коробка клоуна"
	description = "Вселенной нужен смех. Отправьте коробку клоуна."
	reward = CARGO_CRATE_VALUE * 3
	wanted_types = list(/obj/item/storage/box/clown = TRUE)

/datum/bounty/item/assistant/cheesiehonkers
	name = "Сырные хонкеры"
	description = "Видимо, компания, выпускающая сырные хонкеры, обанкротилась. ЦК хочет запастись ими, пока их не стало."
	reward = CARGO_CRATE_VALUE * 2.4
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/cheesiehonkers = TRUE)

/datum/bounty/item/assistant/baseball_bat
	name = "Бейсбольная бита"
	description = "На ЦК проходит бейсбольная неделя! Будьте добры, отправьте несколько бит, чтобы торжества могли начаться."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 5
	wanted_types = list(/obj/item/melee/baseball_bat = TRUE)

/datum/bounty/item/assistant/donut
	name = "Пончики"
	description = "Силы безопасности ЦК несут тяжёлые потери в боях с \"Синдикатом\". Отправьте пончики, чтобы поднять боевой дух."
	reward = CARGO_CRATE_VALUE * 6
	required_count = 6
	wanted_types = list(/obj/item/reagent_containers/food/snacks/donut = TRUE)

/datum/bounty/item/assistant/donkpocket
	name = "Донк-покеты"
	description = "Уведомление о безопасности потребителей: внимание. В партию донк-покетов попала опасная радиоактивная примесь. Отправьте все донк-покеты для безопасной утилизации."
	reward = CARGO_CRATE_VALUE * 6
	required_count = 10
	wanted_types = list(/obj/item/reagent_containers/food/snacks/donkpocket = TRUE)

/datum/bounty/item/assistant/monkey_hide
	name = "Обезьянья шкура"
	description = "Один из учёных ЦК интересуется проверкой продуктов на обезьянах, но ради этого делать их \"трупы\"... дорого. Нам нужна обезьянья шкура."
	reward = CARGO_CRATE_VALUE * 3
	wanted_types = list(/obj/item/stack/sheet/animalhide/monkey = TRUE)

/datum/bounty/item/assistant/dead_mice
	name = "Мёртвые мыши"
	description = "На станции 14 кончились замороженные мыши. Отправьте свежих, чтобы их уборщик не устроил забастовку."
	reward = CARGO_CRATE_VALUE * 10
	required_count = 5
	wanted_types = list(/obj/item/reagent_containers/food/snacks/meat/mouse = TRUE)

/datum/bounty/item/assistant/comfy_chair
	name = "Мягкие кресла"
	description = "Командир Пэт недоволен своим креслом. Он утверждает, что оно отбивает ему спину. Отправьте ему кресла поудобнее."
	reward = CARGO_CRATE_VALUE * 3
	required_count = 5
	wanted_types = list(/obj/structure/chair/comfy = TRUE)

/datum/bounty/item/assistant/geranium
	name = "Герани"
	description = "У командира Зота большие планы на свидание с офицером Оливией. Отправьте ему герани, чтобы он мог её впечатлить."
	reward = CARGO_CRATE_VALUE * 8
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/geranium = TRUE)
	include_subtypes = FALSE

/datum/bounty/item/assistant/poppy
	name = "Маки"
	description = "Командир Зот хочет свалить с ног офицера Оливию. Отправьте ему маков для романтического жеста."
	reward = CARGO_CRATE_VALUE * 2
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/grown/poppy = TRUE)
	include_subtypes = FALSE

/datum/bounty/item/assistant/potted_plants
	name = "Растения в горшках"
	description = "ЦК хочет украсить станцию 14. Отправьте растения в горшках."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 3
	wanted_types = list(
		/obj/item/twohanded/required/kirbyplants = TRUE,
		/obj/item/twohanded/required/kirbyplants/dead = FALSE,
	)

/datum/bounty/item/assistant/monkey_cubes
	name = "Обезьяньи кубики"
	description = "Из-за недавней генетической аварии ЦК нужны новые обезьяны. Ваша задача — отправить обезьяньи кубики."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 3
	wanted_types = list(/obj/item/reagent_containers/food/snacks/monkeycube = TRUE)

/datum/bounty/item/assistant/ied
	name = "Самодельная взрывчатка"
	description = "Лучшая на \"Нанотрейзен\" тюрьма для заключённых-изгоев проходит тренинг персонала. Отправьте несколько самодельных взрывных устройств для практики обезвреживания."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 3
	wanted_types = list(/obj/item/grenade/iedcasing = TRUE)

/datum/bounty/item/assistant/corgimeat
	name = "Сырое мясо корги"
	description = "Связной \"Синдиката\" требует доказательств, что ваш капитан съел своего корги. Отправьте сырое мясо корги."
	reward = CARGO_CRATE_VALUE * 6
	wanted_types = list(/obj/item/reagent_containers/food/snacks/meat/corgi = TRUE)

/datum/bounty/item/assistant/toys
	name = "Игрушки из автомата"
	description = "В штаб-квартиру Института \"Нанотрейзен\" приезжают важные гости с детьми. Отправьте игрушек, чтобы их занять."
	reward = CARGO_CRATE_VALUE * 8
	required_count = 5
	wanted_types = list(/obj/item/toy = TRUE)

/datum/bounty/item/assistant/paper_bin
	name = "Лотки для бумаги"
	description = "Наш отдел финансов теряет бумагу быстрее, чем успевает её заказать. Отправьте пять лотков для бумаги."
	reward = CARGO_CRATE_VALUE * 5
	required_count = 5
	wanted_types = list(/obj/item/paper_bin = TRUE)

/datum/bounty/item/assistant/crayons
	name = "Мелки"
	description = "Дети доктора Джонса снова съели все мелки. Отправьте свои, а мы им что-нибудь объясним."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 8
	wanted_types = list(/obj/item/toy/crayon = TRUE)

/datum/bounty/item/assistant/water_tank
	name = "Бак с водой"
	description = "Нам нужно больше воды для гидропоники. Найдите бак с водой и отправьте его."
	reward = CARGO_CRATE_VALUE * 5
	wanted_types = list(/obj/structure/reagent_dispensers/watertank = TRUE)

/datum/bounty/item/assistant/pneumatic_cannon
	name = "Пневматическая пушка"
	description = "Предлагаемое улучшение ЦК: \"Тривиальный способ обезвредить бомбу — вышвырнуть её подальше\". Отправьте пневматическую пушку для испытаний."
	reward = CARGO_CRATE_VALUE * 4
	wanted_types = list(/obj/item/pneumatic_cannon/ghetto = TRUE)

/datum/bounty/item/assistant/improvised_shells
	name = "Самодельные патроны"
	description = "Наши войска на передовой отбиваются от монстров с дробовиками и мусорными патронами. Отправьте самодельные патроны."
	reward = CARGO_CRATE_VALUE * 4
	required_count = 5
	wanted_types = list(/obj/item/ammo_casing/shotgun/improvised = TRUE)

/datum/bounty/item/assistant/flamethrower
	name = "Огнемёт"
	description = "У нас нашествие моли. Отправьте огнемёт, чтобы разобраться с ситуацией."
	reward = CARGO_CRATE_VALUE * 4
	wanted_types = list(/obj/item/flamethrower = TRUE)
