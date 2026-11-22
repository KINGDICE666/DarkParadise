/obj/item/sticker
	name = "sticker"
	desc = "Наклейка с сильным клеем на обратной стороне. Липнет ко всему!"
	icon = 'icons/obj/stickers.dmi'
	gender = FEMALE
	max_integrity = 50
	resistance_flags = FLAMMABLE
	throw_range = 3
	pressure_resistance = 0
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_TINY
	var/list/icon_states
	var/exclude_from_random = FALSE
	var/examine_text

/obj/item/sticker/Initialize(mapload)
	. = ..()
	if(length(icon_states))
		icon_state = pick(icon_states)
	AddElement(/datum/element/stickerable, 15, examine_text)

/obj/item/sticker/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка",
		GENITIVE = "наклейки",
		DATIVE = "наклейке",
		ACCUSATIVE = "наклейку",
		INSTRUMENTAL = "наклейкой",
		PREPOSITIONAL = "наклейке",
	)

/obj/item/sticker/smile
	name = "smiley sticker"
	icon_state = "smile"

/obj/item/sticker/smile/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка со смайликом",
		GENITIVE = "наклейки со смайликом",
		DATIVE = "наклейке со смайликом",
		ACCUSATIVE = "наклейку со смайликом",
		INSTRUMENTAL = "наклейкой со смайликом",
		PREPOSITIONAL = "наклейке со смайликом",
	)

/obj/item/sticker/frown
	name = "frowny sticker"
	icon_state = "frown"

/obj/item/sticker/frown/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с грустным смайликом",
		GENITIVE = "наклейки с грустным смайликом",
		DATIVE = "наклейке с грустным смайликом",
		ACCUSATIVE = "наклейку с грустным смайликом",
		INSTRUMENTAL = "наклейкой с грустным смайликом",
		PREPOSITIONAL = "наклейке с грустным смайликом",
	)

/obj/item/sticker/left_arrow
	name = "left arrow sticker"
	icon_state = "arrow-left"

/obj/item/sticker/left_arrow/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка со стрелкой влево",
		GENITIVE = "наклейки со стрелкой влево",
		DATIVE = "наклейке со стрелкой влево",
		ACCUSATIVE = "наклейку со стрелкой влево",
		INSTRUMENTAL = "наклейкой со стрелкой влево",
		PREPOSITIONAL = "наклейке со стрелкой влево",
	)

/obj/item/sticker/right_arrow
	name = "right arrow sticker"
	icon_state = "arrow-right"

/obj/item/sticker/right_arrow/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка со стрелкой вправо",
		GENITIVE = "наклейки со стрелкой вправо",
		DATIVE = "наклейке со стрелкой вправо",
		ACCUSATIVE = "наклейку со стрелкой вправо",
		INSTRUMENTAL = "наклейкой со стрелкой вправо",
		PREPOSITIONAL = "наклейке со стрелкой вправо",
	)

/obj/item/sticker/star
	name = "star sticker"
	icon_state = "star"

/obj/item/sticker/star/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка со звёздочкой",
		GENITIVE = "наклейки со звёздочкой",
		DATIVE = "наклейке со звёздочкой",
		ACCUSATIVE = "наклейку со звёздочкой",
		INSTRUMENTAL = "наклейкой со звёздочкой",
		PREPOSITIONAL = "наклейке со звёздочкой",
	)

/obj/item/sticker/heart
	name = "heart sticker"
	icon_state = "heart"

/obj/item/sticker/heart/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с сердечком",
		GENITIVE = "наклейки с сердечком",
		DATIVE = "наклейке с сердечком",
		ACCUSATIVE = "наклейку с сердечком",
		INSTRUMENTAL = "наклейкой с сердечком",
		PREPOSITIONAL = "наклейке с сердечком",
	)

/obj/item/sticker/googly
	name = "googly eye sticker"
	icon_state = "googly"
	icon_states = list("googly", "googly-alt")

/obj/item/sticker/googly/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с глазиком",
		GENITIVE = "наклейки с глазиком",
		DATIVE = "наклейке с глазиком",
		ACCUSATIVE = "наклейку с глазиком",
		INSTRUMENTAL = "наклейкой с глазиком",
		PREPOSITIONAL = "наклейке с глазиком",
	)

/obj/item/sticker/rev
	name = "blue R sticker"
	desc = "Наклейка группы FUCK THE SYSTEM, лучшей хардкор-панк-группы галактики."
	icon_state = "revhead"
	examine_text = "Здесь наклейка группы <b>FUCK THE SYSTEM</b>, лучшей хардкор-панк-группы галактики."

/obj/item/sticker/rev/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с синей буквой R",
		GENITIVE = "наклейки с синей буквой R",
		DATIVE = "наклейке с синей буквой R",
		ACCUSATIVE = "наклейку с синей буквой R",
		INSTRUMENTAL = "наклейкой с синей буквой R",
		PREPOSITIONAL = "наклейке с синей буквой R",
	)

/obj/item/sticker/pslime
	name = "slime plushie sticker"
	icon_state = "pslime"

/obj/item/sticker/pslime/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с плюшевым слаймом",
		GENITIVE = "наклейки с плюшевым слаймом",
		DATIVE = "наклейке с плюшевым слаймом",
		ACCUSATIVE = "наклейку с плюшевым слаймом",
		INSTRUMENTAL = "наклейкой с плюшевым слаймом",
		PREPOSITIONAL = "наклейке с плюшевым слаймом",
	)

/obj/item/sticker/pliz
	name = "lizard plushie sticker"
	icon_state = "plizard"

/obj/item/sticker/pliz/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с плюшевой ящерицей",
		GENITIVE = "наклейки с плюшевой ящерицей",
		DATIVE = "наклейке с плюшевой ящерицей",
		ACCUSATIVE = "наклейку с плюшевой ящерицей",
		INSTRUMENTAL = "наклейкой с плюшевой ящерицей",
		PREPOSITIONAL = "наклейке с плюшевой ящерицей",
	)

/obj/item/sticker/pbee
	name = "bee plushie sticker"
	icon_state = "pbee"

/obj/item/sticker/pbee/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с плюшевой пчелой",
		GENITIVE = "наклейки с плюшевой пчелой",
		DATIVE = "наклейке с плюшевой пчелой",
		ACCUSATIVE = "наклейку с плюшевой пчелой",
		INSTRUMENTAL = "наклейкой с плюшевой пчелой",
		PREPOSITIONAL = "наклейке с плюшевой пчелой",
	)

/obj/item/sticker/psnake
	name = "snake plushie sticker"
	icon_state = "psnake"

/obj/item/sticker/psnake/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с плюшевой змеёй",
		GENITIVE = "наклейки с плюшевой змеёй",
		DATIVE = "наклейке с плюшевой змеёй",
		ACCUSATIVE = "наклейку с плюшевой змеёй",
		INSTRUMENTAL = "наклейкой с плюшевой змеёй",
		PREPOSITIONAL = "наклейке с плюшевой змеёй",
	)

/obj/item/sticker/robot
	name = "bot sticker"
	icon_state = "tile"
	icon_states = list("tile", "medbot", "clean")

/obj/item/sticker/robot/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с ботом",
		GENITIVE = "наклейки с ботом",
		DATIVE = "наклейке с ботом",
		ACCUSATIVE = "наклейку с ботом",
		INSTRUMENTAL = "наклейкой с ботом",
		PREPOSITIONAL = "наклейке с ботом",
	)

/obj/item/sticker/toolbox
	name = "toolbox sticker"
	icon_state = "soul"

/obj/item/sticker/toolbox/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с ящиком для инструментов",
		GENITIVE = "наклейки с ящиком для инструментов",
		DATIVE = "наклейке с ящиком для инструментов",
		ACCUSATIVE = "наклейку с ящиком для инструментов",
		INSTRUMENTAL = "наклейкой с ящиком для инструментов",
		PREPOSITIONAL = "наклейке с ящиком для инструментов",
	)

/obj/item/sticker/chief_engineer
	name = "CE approved sticker"
	icon_state = "ce_approved"
	exclude_from_random = TRUE
	examine_text = "Здесь наклейка с <b>ПЕЧАТЬЮ ОДОБРЕНИЯ старшего инженера.</b>"

/obj/item/sticker/chief_engineer/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка \"Одобрено СИ\"",
		GENITIVE = "наклейки \"Одобрено СИ\"",
		DATIVE = "наклейке \"Одобрено СИ\"",
		ACCUSATIVE = "наклейку \"Одобрено СИ\"",
		INSTRUMENTAL = "наклейкой \"Одобрено СИ\"",
		PREPOSITIONAL = "наклейке \"Одобрено СИ\"",
	)

/obj/item/sticker/clown
	name = "clown sticker"
	icon_state = "honkman"

/obj/item/sticker/clown/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с клоуном",
		GENITIVE = "наклейки с клоуном",
		DATIVE = "наклейке с клоуном",
		ACCUSATIVE = "наклейку с клоуном",
		INSTRUMENTAL = "наклейкой с клоуном",
		PREPOSITIONAL = "наклейке с клоуном",
	)

/obj/item/sticker/mime
	name = "mime sticker"
	icon_state = "silentman"

/obj/item/sticker/mime/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с мимом",
		GENITIVE = "наклейки с мимом",
		DATIVE = "наклейке с мимом",
		ACCUSATIVE = "наклейку с мимом",
		INSTRUMENTAL = "наклейкой с мимом",
		PREPOSITIONAL = "наклейке с мимом",
	)

/obj/item/sticker/assistant
	name = "assistant sticker"
	icon_state = "tider"

/obj/item/sticker/assistant/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с ассистентом",
		GENITIVE = "наклейки с ассистентом",
		DATIVE = "наклейке с ассистентом",
		ACCUSATIVE = "наклейку с ассистентом",
		INSTRUMENTAL = "наклейкой с ассистентом",
		PREPOSITIONAL = "наклейке с ассистентом",
	)

/obj/item/sticker/skub
	name = "skub sticker"
	icon_state = "skub"
	examine_text = "Здесь наклейка с надписью <b>Скаб-прилив по всей станции!</b>"

/obj/item/sticker/skub/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка \"Скаб\"",
		GENITIVE = "наклейки \"Скаб\"",
		DATIVE = "наклейке \"Скаб\"",
		ACCUSATIVE = "наклейку \"Скаб\"",
		INSTRUMENTAL = "наклейкой \"Скаб\"",
		PREPOSITIONAL = "наклейке \"Скаб\"",
	)

/obj/item/sticker/anti_skub
	name = "anti-skub sticker"
	icon_state = "anti_skub"
	examine_text = "Здесь наклейка <b>против скаба</b>."

/obj/item/sticker/anti_skub/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка \"Против скаба\"",
		GENITIVE = "наклейки \"Против скаба\"",
		DATIVE = "наклейке \"Против скаба\"",
		ACCUSATIVE = "наклейку \"Против скаба\"",
		INSTRUMENTAL = "наклейкой \"Против скаба\"",
		PREPOSITIONAL = "наклейке \"Против скаба\"",
	)

/obj/item/sticker/syndicate
	name = "syndicate sticker"
	icon_state = "synd"
	exclude_from_random = TRUE

/obj/item/sticker/syndicate/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка Синдиката",
		GENITIVE = "наклейки Синдиката",
		DATIVE = "наклейке Синдиката",
		ACCUSATIVE = "наклейку Синдиката",
		INSTRUMENTAL = "наклейкой Синдиката",
		PREPOSITIONAL = "наклейке Синдиката",
	)

/obj/item/sticker/syndicate/c4
	name = "C-4 sticker"
	icon_state = "c4"

/obj/item/sticker/syndicate/c4/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с C-4",
		GENITIVE = "наклейки с C-4",
		DATIVE = "наклейке с C-4",
		ACCUSATIVE = "наклейку с C-4",
		INSTRUMENTAL = "наклейкой с C-4",
		PREPOSITIONAL = "наклейке с C-4",
	)

/obj/item/sticker/syndicate/bomb
	name = "syndicate bomb sticker"
	icon_state = "sbomb"

/obj/item/sticker/syndicate/bomb/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с бомбой Синдиката",
		GENITIVE = "наклейки с бомбой Синдиката",
		DATIVE = "наклейке с бомбой Синдиката",
		ACCUSATIVE = "наклейку с бомбой Синдиката",
		INSTRUMENTAL = "наклейкой с бомбой Синдиката",
		PREPOSITIONAL = "наклейке с бомбой Синдиката",
	)

/obj/item/sticker/syndicate/apc
	name = "broken APC sticker"
	icon_state = "milf"

/obj/item/sticker/syndicate/apc/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка со сломанным ЛКП",
		GENITIVE = "наклейки со сломанным ЛКП",
		DATIVE = "наклейке со сломанным ЛКП",
		ACCUSATIVE = "наклейку со сломанным ЛКП",
		INSTRUMENTAL = "наклейкой со сломанным ЛКП",
		PREPOSITIONAL = "наклейке со сломанным ЛКП",
	)

/obj/item/sticker/syndicate/larva
	name = "larva sticker"
	icon_state = "larva"

/obj/item/sticker/syndicate/larva/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с личинкой",
		GENITIVE = "наклейки с личинкой",
		DATIVE = "наклейке с личинкой",
		ACCUSATIVE = "наклейку с личинкой",
		INSTRUMENTAL = "наклейкой с личинкой",
		PREPOSITIONAL = "наклейке с личинкой",
	)

/obj/item/sticker/syndicate/cult
	name = "bloody paper sticker"
	icon_state = "cult"

/obj/item/sticker/syndicate/cult/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с окровавленной бумагой",
		GENITIVE = "наклейки с окровавленной бумагой",
		DATIVE = "наклейке с окровавленной бумагой",
		ACCUSATIVE = "наклейку с окровавленной бумагой",
		INSTRUMENTAL = "наклейкой с окровавленной бумагой",
		PREPOSITIONAL = "наклейке с окровавленной бумагой",
	)

/obj/item/sticker/syndicate/flash
	name = "flash sticker"
	icon_state = "flash"

/obj/item/sticker/syndicate/flash/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка со вспышкой",
		GENITIVE = "наклейки со вспышкой",
		DATIVE = "наклейке со вспышкой",
		ACCUSATIVE = "наклейку со вспышкой",
		INSTRUMENTAL = "наклейкой со вспышкой",
		PREPOSITIONAL = "наклейке со вспышкой",
	)

/obj/item/sticker/syndicate/op
	name = "operative sticker"
	icon_state = "newcop"

/obj/item/sticker/syndicate/op/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с оперативником",
		GENITIVE = "наклейки с оперативником",
		DATIVE = "наклейке с оперативником",
		ACCUSATIVE = "наклейку с оперативником",
		INSTRUMENTAL = "наклейкой с оперативником",
		PREPOSITIONAL = "наклейке с оперативником",
	)

/obj/item/sticker/syndicate/trap
	name = "bear trap sticker"
	icon_state = "trap"

/obj/item/sticker/syndicate/trap/get_ru_names()
	return alist(
		NOMINATIVE = "наклейка с медвежьим капканом",
		GENITIVE = "наклейки с медвежьим капканом",
		DATIVE = "наклейке с медвежьим капканом",
		ACCUSATIVE = "наклейку с медвежьим капканом",
		INSTRUMENTAL = "наклейкой с медвежьим капканом",
		PREPOSITIONAL = "наклейке с медвежьим капканом",
	)

/obj/item/sticker/purity_seal
	name = "purity seal"
	desc = "Присмотревшись, вы понимаете, что это всего лишь штампованная наклейка. Видимо, главное — святость."
	icon_state = "purity_seal_1"

/obj/item/sticker/purity_seal/get_ru_names()
	return alist(
		NOMINATIVE = "печать чистоты",
		GENITIVE = "печати чистоты",
		DATIVE = "печати чистоты",
		ACCUSATIVE = "печать чистоты",
		INSTRUMENTAL = "печатью чистоты",
		PREPOSITIONAL = "печати чистоты",
	)

/obj/item/sticker/purity_seal/purity_seal_2
	icon_state = "purity_seal_2"

/obj/item/storage/box/stickers
	name = "sticker pack"
	desc = "Набор отклеиваемых наклеек. Отклеиваемых? Вот развод!<br>На обороте крупными буквами напечатано: <b>НЕ ДАВАТЬ КЛОУНУ!</b>"
	icon = 'icons/obj/stickers.dmi'
	icon_state = "stickerpack"
	gender = MALE
	w_class = WEIGHT_CLASS_TINY
	storage_slots = 8
	max_w_class = WEIGHT_CLASS_TINY
	can_hold = list(/obj/item/sticker)
	foldable = null
	var/illustration
	var/static/list/pack_labels = list(
		"smile",
		"frown",
		"heart",
		"silentman",
		"tider",
		"star",
	)

/obj/item/storage/box/stickers/get_ru_names()
	return alist(
		NOMINATIVE = "набор наклеек",
		GENITIVE = "набора наклеек",
		DATIVE = "набору наклеек",
		ACCUSATIVE = "набор наклеек",
		INSTRUMENTAL = "набором наклеек",
		PREPOSITIONAL = "наборе наклеек",
	)

/obj/item/storage/box/stickers/Initialize(mapload)
	. = ..()
	if(isnull(illustration))
		illustration = pick(pack_labels)
	update_appearance(UPDATE_OVERLAYS)

/obj/item/storage/box/stickers/update_overlays()
	. = ..()
	if(illustration)
		. += illustration

/obj/item/storage/box/stickers/populate_contents()
	var/static/list/non_contraband
	if(isnull(non_contraband))
		non_contraband = list()
		for(var/obj/item/sticker/sticker_type as anything in subtypesof(/obj/item/sticker))
			if(!sticker_type::exclude_from_random)
				non_contraband += sticker_type

	for(var/i in 1 to rand(4, 8))
		var/sticker_type = pick(non_contraband)
		new sticker_type(src)

/obj/item/storage/box/stickers/googly
	name = "googly eye sticker pack"
	desc = "Превратите что угодно в нечто смутно живое!"
	illustration = "googly-alt"

/obj/item/storage/box/stickers/googly/get_ru_names()
	return alist(
		NOMINATIVE = "набор наклеек с глазиками",
		GENITIVE = "набора наклеек с глазиками",
		DATIVE = "набору наклеек с глазиками",
		ACCUSATIVE = "набор наклеек с глазиками",
		INSTRUMENTAL = "набором наклеек с глазиками",
		PREPOSITIONAL = "наборе наклеек с глазиками",
	)

/obj/item/storage/box/stickers/googly/populate_contents()
	for(var/i in 1 to 6)
		new /obj/item/sticker/googly(src)

/obj/item/storage/box/stickers/chief_engineer
	name = "CE approved sticker pack"
	desc = "Сообщите экипажу одной из этих наклеек, что штуковина в коридоре СОВЕРШЕННО БЕЗОПАСНА!"
	illustration = "label_ce"

/obj/item/storage/box/stickers/chief_engineer/get_ru_names()
	return alist(
		NOMINATIVE = "набор наклеек \"Одобрено СИ\"",
		GENITIVE = "набора наклеек \"Одобрено СИ\"",
		DATIVE = "набору наклеек \"Одобрено СИ\"",
		ACCUSATIVE = "набор наклеек \"Одобрено СИ\"",
		INSTRUMENTAL = "набором наклеек \"Одобрено СИ\"",
		PREPOSITIONAL = "наборе наклеек \"Одобрено СИ\"",
	)

/obj/item/storage/box/stickers/chief_engineer/populate_contents()
	for(var/i in 1 to 3)
		new /obj/item/sticker/chief_engineer(src)

/obj/item/storage/box/stickers/syndie_kit/populate_contents()
	var/list/sticker_types = subtypesof(/obj/item/sticker/syndicate)
	for(var/i in 1 to storage_slots)
		var/sticker_type = pick(sticker_types)
		new sticker_type(src)

/obj/item/storage/box/purity_seal_box
	name = "box of purity seals"
	desc = "Коробка с несколькими освящёнными печатями чистоты."
	gender = FEMALE

/obj/item/storage/box/purity_seal_box/get_ru_names()
	return alist(
		NOMINATIVE = "коробка печатей чистоты",
		GENITIVE = "коробки печатей чистоты",
		DATIVE = "коробке печатей чистоты",
		ACCUSATIVE = "коробку печатей чистоты",
		INSTRUMENTAL = "коробкой печатей чистоты",
		PREPOSITIONAL = "коробке печатей чистоты",
	)

/obj/item/storage/box/purity_seal_box/populate_contents()
	for(var/i in 1 to 4)
		new /obj/item/sticker/purity_seal(src)
		new /obj/item/sticker/purity_seal/purity_seal_2(src)
