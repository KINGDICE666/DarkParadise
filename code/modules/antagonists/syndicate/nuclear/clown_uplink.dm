/datum/uplink_item/clownops
	category = "Клоунское снаряжение"
	uplinktypes = list(UPLINK_TYPE_CLOWN_OPS)
	surplus = 0

/datum/uplink_item/clownops/pie_cannon
	name = "Банановый пирогомёт"
	desc = "Вмещает двадцать кремовых пирогов и создаёт новый каждые две секунды."
	item = /obj/item/pneumatic_cannon/pie/selfcharge
	cost = 50

/datum/uplink_item/clownops/bananashield
	name = "Бананиевый энергетический щит"
	desc = "Отражает энергетические снаряды. При броске сбивает с ног и возвращается владельцу. Включённый щит опасен \
		даже для противоскользящей обуви."
	item = /obj/item/shield/energy/bananium
	cost = 80

/datum/uplink_item/clownops/clownsword
	name = "Бананиевый энергетический меч"
	desc = "Не наносит урона, но заставляет поскользнуться при контакте. В неуклюжих руках сбивает с ног ударом и \
		броском, заставляя жертву уронить предметы."
	item = /obj/item/melee/energy/sword/bananium
	cost = 15

/datum/uplink_item/clownops/clownpins
	name = "Четыре ультрасмешных бойка"
	desc = "Заставляют оружие хонкать и разрешают стрельбу только клоунам и неуклюжим существам."
	item = /obj/item/storage/box/syndie_kit/clownpins
	cost = 5

/datum/uplink_item/clownops/superpins
	name = "Четыре суперультрасмешных бойка"
	desc = "Клоунские бойки с зарядом взрывчатки: оружие взорвётся в чужих руках."
	item = /obj/item/storage/box/syndie_kit/clownpins/super
	cost = 20

/datum/uplink_item/clownops/foamsmg
	name = "Игрушечный пистолет-пулемёт"
	desc = "Donksoft C-20r с магазином на двадцать усиленных пенных дротиков."
	item = /obj/item/gun/projectile/automatic/smg/c20r/toy/riot
	cost = 25

/datum/uplink_item/clownops/foammachinegun
	name = "Игрушечный пулемёт"
	desc = "Donksoft L6 SAW с магазином на пятьдесят усиленных пенных дротиков."
	item = /obj/item/gun/projectile/automatic/l6_saw/toy/riot
	cost = 50

/datum/uplink_item/clownops/bombanana
	name = "Бомбанан"
	desc = "После съедания кожура взрывается через пять секунд с силой мини-бомбы. Быстро выбросьте её!"
	item = /obj/item/reagent_containers/food/snacks/grown/banana/bombanana
	cost = 20

/datum/uplink_item/clownops/clown_bomb
	name = "Клоунская бомба"
	desc = "Маяк доставки большой клоунской бомбы. Таймер можно настроить, а бомбу — закрепить гаечным ключом."
	item = /obj/item/beacon/syndicate/bomb/clown
	cost = 75

/datum/uplink_item/clownops/tearstache
	name = "Газовая граната с усами"
	desc = "Слезоточивый газ и липкие усы. Усы на минуту мешают надеть другую маску. Клоунские и мимские маски защищают от усов."
	item = /obj/item/grenade/chem_grenade/teargas/moustache
	cost = 15

/datum/uplink_item/clownops/pinata
	name = "Набор боевой пиньяты"
	desc = "Пиньята с конфетами и взрывчаткой, а также два пояса для добычи."
	item = /obj/item/storage/box/syndie_kit/pinata
	cost = 60
	limited_stock = 1

/datum/uplink_item/clownops/reinforcement
	name = "Клоунское подкрепление"
	desc = "Маяк вызова дополнительного клоуна-оперативника с полным стартовым снаряжением и без телекристаллов."
	item = /obj/item/antag_spawner/nuke_ops/clown
	cost = 100
	refundable = TRUE

/datum/uplink_item/clownops/monkey_agent
	name = "Обезьяна-агент"
	desc = "Вызов обученной обезьяны, которая защищает хозяина, использует оборудование и понимает Общий язык, но не говорит на нём."
	item = /obj/item/antag_spawner/nuke_ops/monkey
	cost = 35
	refundable = TRUE

/datum/uplink_item/clownops/monkey_supplies
	name = "Припасы обезьяны-агента"
	desc = "Закрытый на сканер лапы набор оружия, боеприпасов и снаряжения для обезьяны."
	item = /obj/item/storage/box/syndie_kit/monkeycase
	cost = 20
	refundable = TRUE

/datum/uplink_item/clownops/honker
	name = "Dark H.O.N.K."
	desc = "Бронированный клоунский мех с HoNkER BlAsT 5000, бомбанановой мортирой и пусковой установкой газовых гранат с усами."
	item = /obj/mecha/combat/honker/dark/loaded
	cost = 400

/datum/uplink_item/clownops/banana_shoes
	name = "Боевые банановые ботинки"
	desc = "Защищают как боевые клоунские ботинки и оставляют позади банановые кожурки. Заряд восстанавливается \
		самостоятельно или пополняется бананиумом."
	item = /obj/item/clothing/shoes/clown_shoes/banana_shoes/combat
	cost = 30

/datum/uplink_item/clownops/anticlumsy
	name = "Инъектор против неуклюжести"
	desc = "Убирает врождённую неуклюжесть для особо точных номеров. Клоунские бойки продолжат узнавать Вашу клоунскую природу."
	item = /obj/item/dnainjector/anticlumsy
	cost = 10

/datum/uplink_item/clownops/induction_kit
	name = "Набор вступления в цирк"
	desc = "Био-чип регистрации, тактическая карта и снаряжение нового участника отряда. Био-чип не промывает мозги и \
		не меняет лояльность."
	item = /obj/item/storage/box/syndie_kit/induction_kit/clown
	cost = 50

/datum/uplink_item/clownops/fake_macrobomb
	name = "Фальшивая макробомба"
	desc = "Отсчитывает время как макробомба, но взрывается с силой микробомбы и оглушительным хонком."
	item = /obj/item/implanter/explosive_macro/fake
	cost = 20
