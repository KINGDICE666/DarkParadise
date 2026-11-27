/datum/reagent/consumable/drink/cold
	name = "Прохладительный напиток"
	adj_temp_cool = 5

/datum/reagent/consumable/drink/cold/tonic
	name = "Тоник"
	id = "tonic"
	description = "Вкус странный, но, по крайней мере, хинин держит Космическую Малярию на расстоянии."
	color = "#664300" // rgb: 102, 67, 0
	adj_dizzy = -10 SECONDS
	adj_drowsy = -6 SECONDS
	adj_sleepy = -4 SECONDS
	drink_icon = "glass_clear"
	drink_name = "стакан тоника"
	drink_desc = "Хинин на вкус не очень приятный, но, по крайней мере, он убережёт от Космической Малярии."
	taste_description = "горечи"

/datum/reagent/consumable/drink/cold/sodawater
	name = "Содовая вода"
	id = "sodawater"
	description = "Содовая, потрясно."
	color = "#619494" // rgb: 97, 148, 148
	adj_dizzy = -10 SECONDS
	adj_drowsy = -6 SECONDS
	drink_icon = "glass_clear"
	drink_name = "стакан газированный воды"
	drink_desc = "Газированная вода. Почему бы не сделать виски с содовой?"
	taste_description = "шипучей газировки"

/datum/reagent/consumable/drink/cold/ice
	name = "Лёд"
	id = "ice"
	description = "Замороженная вода. Не стоит жевать, если не хочешь повредить свои зубы."
	reagent_state = SOLID
	color = "#619494" // rgb: 97, 148, 148
	adj_temp_cool = 0
	drink_icon = "iceglass"
	drink_name = "стакан льда"
	drink_desc = "Вообще-то, вы должны положить туда ещё что-нибудь..."
	taste_description = "холодного льда"

/datum/reagent/consumable/drink/cold/ice/on_mob_life(mob/living/M)
	M.adjust_bodytemperature(-(5 * TEMPERATURE_DAMAGE_COEFFICIENT))
	return ..()

/datum/reagent/consumable/drink/cold/space_cola
	name = "Кола"
	id = "cola"
	description = "Освежающий напиток."
	color = "#100800" // rgb: 16, 8, 0
	adj_drowsy = -10 SECONDS
	drink_icon = "glass_brown"
	drink_name = "стакан колы"
	drink_desc = "Стакан освежающей КосмоКолы."
	taste_description = "колы"

// Space cola dissolves eldritch rust (tg) - douse a rusted wall/floor/object with it to strip the rust.
/datum/reagent/consumable/drink/cold/space_cola/reaction_turf(turf/exposed_turf, volume, color)
	. = ..()
	exposed_turf.clean_rust()

/datum/reagent/consumable/drink/cold/space_cola/reaction_obj(obj/exposed_obj, volume)
	. = ..()
	exposed_obj.clean_rust()

/datum/reagent/consumable/drink/cold/energy
	name = "Энергетический напиток"
	id = "energetik"
	description = "Освежающий напиток."
	color = "#a9c725"
	adj_drowsy = -6 SECONDS
	adj_sleepy = -4 SECONDS
	adj_dizzy = -10 SECONDS
	heart_rate_increase = 1
	minor_addiction = TRUE
	overdose_threshold = 45
	addiction_chance = 1
	addiction_threshold = 200
	drink_icon = "lemonglass"
	drink_name = "стакан энергетического напитка"
	drink_desc = "Стакан бодрящего энергетика."
	taste_description = "сладких фруктов"

/datum/reagent/consumable/drink/cold/energy/New()
	addict_supertype = /datum/reagent/consumable/drink/cold/energy

/datum/reagent/consumable/drink/cold/energy/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	update_flags |= M.adjustStaminaLoss(-1, FALSE)
	if(M.reagents.get_reagent_amount(/datum/reagent/consumable/drink/coffee) > 0)
		if(prob(0.5))
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				if(!H.undergoing_cardiac_arrest())
					H.set_heartattack(TRUE)
	if(locate(/datum/reagent/consumable/drink/cold/energy) in (M.reagents.reagent_list - src))
		if(prob(0.5))
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				if(!H.undergoing_cardiac_arrest())
					H.set_heartattack(TRUE)
	return ..() | update_flags

/datum/reagent/consumable/drink/cold/energy/overdose_process(mob/living/M, severity)
	if(volume > 45)
		M.Jitter(10 SECONDS)
	return list(0, STATUS_UPDATE_NONE)

/datum/reagent/consumable/drink/cold/energy/trop
	name = "Тропикал Энерджи"
	id = "trop_eng"
	taste_description = "манго и кокоса"

/datum/reagent/consumable/drink/cold/energy/milk
	name = "Милк Энерджи"
	id = "milk_eng"
	taste_description = "молока и таурина"

/datum/reagent/consumable/drink/cold/energy/grey
	name = "ГрейПауэр Энерджи"
	id = "grey_eng"
	color = "#9dc2d1"
	taste_description = "робаста"

/datum/reagent/consumable/drink/cold/nuka_cola
	name = "Нюка-кола"
	id = "nuka_cola"
	description = "Кола, кола никогда не меняется."
	color = "#100800" // rgb: 16, 8, 0
	adj_sleepy = -4 SECONDS
	drink_icon = "nuka_colaglass"
	drink_name = "Нюка-кола"
	drink_desc = "Don't cry, Don't raise your eye, It's only nuclear wasteland..."
	harmless = FALSE
	taste_description = "радиоактивной колы"

/datum/reagent/consumable/drink/cold/nuka_cola/on_mob_life(mob/living/user)
	var/update_flags = STATUS_UPDATE_NONE
	user.Jitter(40 SECONDS)
	user.Druggy(60 SECONDS)
	user.AdjustDizzy(10 SECONDS)
	user.SetDrowsy(0)
	if(!(user.dna && (user.dna.species.reagent_tag & ORGANIC)))
		user.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/nuka_cola)
	return ..() | update_flags

/datum/reagent/consumable/drink/cold/nuka_cola/on_mob_add(mob/living/user)
	. = ..()
	if(user.dna && (user.dna.species.reagent_tag & ORGANIC))
		user.add_movespeed_modifier(/datum/movespeed_modifier/reagent/nuka_cola)

/datum/reagent/consumable/drink/cold/nuka_cola/on_mob_delete(mob/living/user)
	. = ..()
	user.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/nuka_cola)

/datum/reagent/consumable/drink/cold/spacemountainwind
	name = "Космический Маунтин Винд"
	id = "spacemountainwind"
	description = "Проходит насквозь, словно космический ветер."
	color = "#102000" // rgb: 16, 32, 0
	adj_drowsy = -14 SECONDS
	adj_sleepy = -2 SECONDS
	drink_icon = "Space_mountain_wind_glass"
	drink_name = "стакан Космического Маунтин Винда"
	drink_desc = "Космический Маунтин Винд. Как вы знаете, в космосе нет гор, только ветер."
	taste_description = "лаймовой газировки"

/datum/reagent/consumable/drink/cold/dr_gibb
	name = "Доктор Гибб"
	id = "dr_gibb"
	description = "Освежающая смесь из 42 различных вкусов!"
	color = "#102000" // rgb: 16, 32, 0
	adj_drowsy = -12 SECONDS
	drink_icon = "dr_gibb_glass"
	drink_name = "стакан Доктора Гибба"
	drink_desc = "Доктор Гибб. Не так опасен, как может показаться."
	taste_description = "вишнёвой газировки"

/datum/reagent/consumable/drink/cold/space_up
	name = "Спейс-Ап"
	id = "space_up"
	description = "На вкус как дыра в обшивке у вас во рту. Да, звучит странно."
	color = "#202800" // rgb: 32, 40, 0
	adj_temp_cool = 8
	drink_icon = "space-up_glass"
	drink_name = "стакан Спейс-Апа"
	drink_desc = "Спейс-Ап. Держит вас в тонусе."
	taste_description = "лимонной газировки"

/datum/reagent/consumable/drink/cold/lemon_lime
	name = "Лимон-Лайм"
	description = "Терпкая газировка, состоящяя на 0,5% из натуральных цитрусовых!"
	id = "lemon_lime"
	color = "#878F00" // rgb: 135, 40, 0
	adj_temp_cool = 8
	taste_description = "цитрусовой газировки"

/datum/reagent/consumable/drink/cold/lemonade
	name = "Лимонад"
	description = "Если жизнь даёт вам лимоны..."
	id = "lemonade"
	color = "#FFFF00" // rgb: 255, 255, 0
	drink_icon = "lemonade"
	drink_name = "Лимонад"
	drink_desc = "Как в старые добрые..."
	taste_description = "лимонада"

/datum/reagent/consumable/drink/cold/kiraspecial
	name = "Кира Спешл"
	description = "Да здравствует парень, которого все принимали за девушку. Бака!"
	id = "kiraspecial"
	color = "#CCCC99" // rgb: 204, 204, 153
	drink_icon = "kiraspecial"
	drink_name = "Кира Спешл"
	drink_desc = "Да здравствует парень, которого все принимали за девушку. Бака!"
	taste_description = "цитрусовой газировки"

/datum/reagent/consumable/drink/cold/brownstar
	name = "Браун Стар"
	description = "Это не то, чем кажется..."
	id = "brownstar"
	color = "#9F3400" // rgb: 159, 052, 000
	adj_temp_cool = 2
	drink_icon = "brownstar"
	drink_name = "Браун Стар"
	drink_desc = "Это не то, чем кажется..."
	taste_description = "апельсиновой газировки"

/datum/reagent/consumable/drink/cold/milkshake
	name = "Молочный коктейль"
	description = "Великолепная леденящая мозг смесь."
	id = "milkshake"
	color = "#AEE5E4" // rgb" 174, 229, 228
	adj_temp_cool = 9
	drink_icon = "milkshake"
	drink_name = "Молочный коктейль"
	drink_desc = "Великолепная леденящая мозг смесь."
	taste_description = "молочного коктейля"

/datum/reagent/consumable/drink/cold/rewriter
	name = "Переписчик"
	description = "Тайна святилища Библиотекаря..."
	id = "rewriter"
	color = "#485000" // rgb:72, 080, 0
	drink_icon = "rewriter"
	drink_name = "Переписчик"
	drink_desc = "Тайна святилища Библиотекаря..."
	taste_description = "кофейной газировки"

/datum/reagent/consumable/drink/cold/rewriter/on_mob_life(mob/living/M)
	M.Jitter(10 SECONDS)
	return ..()

/datum/reagent/consumable/drink/cold/zaza
	name = "Заза"
	description = "От напитка исходит стойкий запах вишни. Изумительно."
	id = "zaza"
	color = "#b10023" // rgb:177, 0, 35
	drink_icon = "zaza"
	drink_name = "стакан Зазы"
	drink_desc = "Стакан, наполненный вишнёвым напитком, для отличной Заза-пятницы."
	taste_description = "восхитительной вишнёвой газировки"
	var/alternate_taste_description = "неприятной приторно-сладкой воды"
	var/healamount = 0.5

/datum/reagent/consumable/drink/cold/zaza/on_mob_life(mob/living/user)
	var/update_flags = STATUS_UPDATE_NONE
	if(ishuman(user) && prob(40))
		update_flags |= user.adjustBruteLoss(-healamount, FALSE, affect_robotic = FALSE)
		update_flags |= user.adjustFireLoss(-healamount, FALSE, affect_robotic = FALSE)
	return ..() | update_flags

/datum/reagent/consumable/drink/cold/zaza/taste_amplification(mob/living/user)
	. = list()
	var/taste_desc = ismindshielded(user) ? alternate_taste_description : taste_description
	var/taste_amount = volume * taste_mult
	.[taste_desc] = taste_amount

/datum/reagent/consumable/drink/cold/zaza/fizzy
	name = "Шипучая Заза"
	description = "От пузырящегося напитка исходит стойкий запах вишни. Изумительно."
	color = "#f30028" // rgb:243, 0, 40
	id = "zazafizzy"
	drink_icon = "zaza_fizzy"
	drink_desc = "Стакан, наполненный вишнёвым напитком, для отличной Заза-пятницы. Теперь с пузырьками!"
	taste_description = "восхитительной шипучей вишнёвой газировки"
	alternate_taste_description = "неприятной приторно-сладкой газированной воды"
	healamount = 0.25

/datum/reagent/consumable/drink/cold/sol_dry
	name = "Сол Драй"
	id = "sol_dry"
	description = "Мягкий успокаивающий напиток из имбиря."
	color = "#f7d26a"
	drink_icon = "soldry"
	drink_name = "стакан Сол Драй"
	drink_desc = "Мягкий успокаивающий напиток из имбиря."
	taste_description = "сладких имбирных пряностей"

/datum/reagent/consumable/drink/cold/sol_dry/on_mob_life(mob/living/M)
	M.AdjustDisgust(-5 SECONDS)
	return ..()

/datum/reagent/consumable/drink/cold/pwr_game
	name = "Пвр Гейм"
	id = "pwr_game"
	description = "Единственный напиток с той СИЛОЙ, которой жаждут настоящие геймеры."
	color = "#9385bf"
	drink_icon = "pwrgame"
	drink_name = "стакан Пвр Гейма"
	drink_desc = "Отлично сочетается с салатом Влада."
	taste_description = "сладко-солёной кислинки"

/datum/reagent/consumable/drink/cold/shamblers
	name = "Сок Шамблера"
	id = "shamblers"
	description = "~Взболтай-ка мне Сока Шамблера!~"
	color = "#f00060"
	drink_icon = "shamblerjuice"
	drink_name = "стакан Сока Шамблера"
	drink_desc = "Ммм, шамблерно."
	taste_description = "газированной металлической шипучки"

/datum/reagent/consumable/drink/cold/wellcheers
	name = "Веллчирс"
	id = "wellcheers"
	description = "Странный фиолетовый напиток с запахом морской воды. Где-то вдалеке слышны чайки."
	color = "#762399"
	adj_drowsy = 3 SECONDS
	taste_description = "винограда и свежего открытого моря"

/datum/reagent/consumable/drink/cold/wellcheers/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	update_flags |= M.adjustBruteLoss(-1, FALSE)
	return ..() | update_flags

/datum/reagent/consumable/drink/cold/grey_bull
	name = "Грей Булл"
	id = "grey_bull"
	description = "Грей Булл окрыляет перчатками!"
	color = "#EEFF00"
	adj_dizzy = 2 SECONDS
	adj_sleepy = -4 SECONDS
	metabolized_traits = list(TRAIT_SHOCKIMMUNE)
	drink_icon = "grey_bull_glass"
	drink_name = "стакан Грей Булла"
	drink_desc = "Как ни странно, он не серый."
	taste_description = "газированного масла"

/datum/reagent/consumable/drink/cold/grey_bull/on_mob_life(mob/living/M)
	M.Jitter(40 SECONDS)
	M.SetDrowsy(0)
	return ..()

/datum/reagent/consumable/drink/cold/monkey_energy
	name = "Манки Энерджи"
	id = "monkey_energy"
	description = "Единственный напиток, который выпустит наружу вашу внутреннюю обезьяну."
	color = "#f39b03"
	adj_dizzy = 2 SECONDS
	adj_sleepy = -4 SECONDS
	drink_icon = "monkey_energy_glass"
	drink_name = "стакан Манки Энерджи"
	drink_desc = "Обезьяну выпустить можно, но без хлопка банки?"
	taste_description = "барбекю и ностальгии"

/datum/reagent/consumable/drink/cold/monkey_energy/on_mob_life(mob/living/M)
	M.Jitter(80 SECONDS)
	M.SetDrowsy(0)
	return ..()

/datum/reagent/consumable/drink/cold/monkey_energy/on_mob_add(mob/living/M)
	. = ..()
	if(ismonkey(M))
		M.add_movespeed_modifier(/datum/movespeed_modifier/reagent/monkey_energy)

/datum/reagent/consumable/drink/cold/monkey_energy/on_mob_delete(mob/living/M)
	. = ..()
	M.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/monkey_energy)

/datum/reagent/consumable/drink/cold/volt_energy
	name = "24-Вольт Энерджи"
	id = "volt_energy"
	description = "Электрический энергетик с искусственными красителями и ароматизаторами, со вкусом фонарного фрукта."
	color = "#99E550"
	drink_icon = "volt_energy_glass"
	drink_name = "стакан 24-Вольт Энерджи"
	drink_desc = "Резкий, кислый, электризующий!"
	taste_description = "кислой груши"

/datum/reagent/consumable/drink/cold/melon_soda
	name = "Дынная газировка"
	id = "melon_soda"
	description = "Неоново-зелёный глоток ностальгии."
	color = "#6FEB48"
	drink_icon = "melon_soda_glass"
	drink_name = "стакан дынной газировки"
	drink_desc = "Ею наслаждаются японские дети и тридцатилетние фанаты Японии."
	taste_description = "шипучей дыни"

