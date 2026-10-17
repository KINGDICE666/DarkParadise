/datum/species/human
	name = SPECIES_HUMAN
	name_plural = "Humans"
	ru_genitive = "человека"
	primitive_form = /datum/species/monkey
	language = LANGUAGE_SOL_COMMON
	inherent_traits = list(
		TRAIT_HAS_LIPS,
		TRAIT_HAS_REGENERATION,
	)
	skinned_type = /obj/item/stack/sheet/animalhide/human
	clothing_flags = HAS_UNDERWEAR | HAS_UNDERSHIRT | HAS_SOCKS
	bodyflags = HAS_SKIN_TONE | HAS_BODY_MARKINGS | HAS_HAIR
	blood_species = "Human"
	can_be_pale = TRUE
	blurb = "Люди — мягкокожие гуманоиды с Земли и самый распространённый вид на станциях Nanotrasen. Выдающихся сильных \
	сторон у них нет, как нет и заметных слабостей, а почти всё снаряжение корпорации шьётся именно под \
	людей.<br/><br/>Родина человечества — Земля в Солнечной системе. Века тяжёлой промышленности превратили её в \
	отравленную пустошь с токсичными водоёмами и почти непригодным для дыхания воздухом, и лишь в 26-м веке \
	правительство Солнечной системы вложило огромные средства в восстановление её атмосферы и биосферы. За пять \
	столетий люди расселились по множеству колоний и станций глубокого космоса.<br/><br/>Люди ценят \
	индивидуальность, свободу и равноправие и с детства привыкают мыслить масштабно. Их общесолнечный язык \
	сложился в начале 2100-х из смеси китайского, английского и других земных языков, а человеческая культура \
	проникла почти во все уголки освоенной галактики: банку космической колы можно найти где угодно, от Могеса до \
	Аурума.<br/><br/>Транс-Солнечная Федерация удерживает власть над разбросанными колониями, но могущественные \
	корпорации, повальная кибер- и биоаугментация и тайные организации делают жизнь в большинстве человеческих \
	миров по меньшей мере беспокойной."

	meat_type = /obj/item/reagent_containers/food/snacks/meat/humanoid/human

	reagent_tag = ORGANIC
	//Has standard darksight of 2.

/datum/species/human/gain_muscles(mob/living/target, datum/strength_level/default, max_level, can_become_stronger)
	..(target, target.gender == FEMALE ? default.prev_level : default, max_level, can_become_stronger)
