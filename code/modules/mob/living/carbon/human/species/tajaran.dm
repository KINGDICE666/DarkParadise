/datum/species/tajaran
	name = SPECIES_TAJARAN
	name_plural = "Tajaran"
	ru_genitive = "таярана"
	icobase = 'icons/mob/human_races/r_tajaran.dmi'
	deform = 'icons/mob/human_races/r_def_tajaran.dmi'
	species_language_holder = /datum/language_holder/tajaran
	tail = "tajtail"
	skinned_type = /obj/item/stack/sheet/fur
	unarmed_type = /datum/unarmed_attack/claws

	blurb = "Таяраны — гуманоиды, похожие на земных кошачьих, с планеты Адомай. Они отлично видят в темноте, дерутся \
	когтями и легко переносят холод, но плохо выносят жару и терпеть не могут воду.<br/><br/>Адомай — планета с \
	разнообразным климатом и скудными запасами воды, одна из двух землеподобных планет у пары звёзд С’рандарр и \
	Месса. Сотни лет таяраны были рабами технологически развитых пришельцев, которых они называют Рабовладельцами, \
	и добывали для них ресурсы в многочисленных шахтах.<br/><br/>Освободившись в войне за свободу, таяраны вышли в \
	космос при поддержке людей и скреллов. Их общество держится на кланах и великих домах, каждый из которых взял \
	на себя свою роль во внутренней и внешней политике. Долгое время почти все таяраны были неграмотны, поэтому \
	историю и чувства они передавали в песнях, и музыка до сих пор занимает важное место в их \
	культуре.<br/><br/>Говорят таяраны на сик’таире, с характерным раскатистым «р». Живут они недолго — в среднем \
	около 46 лет."

	cold_level_1 = 240
	cold_level_2 = 180
	cold_level_3 = 100

	heat_level_1 = 340
	heat_level_2 = 380
	heat_level_3 = 440

	primitive_form = /datum/species/monkey/tajaran

	inherent_traits = list(
		TRAIT_HAS_LIPS,
		TRAIT_HAS_REGENERATION,
		TRAIT_WATER_HATER,
	)
	clothing_flags = HAS_UNDERWEAR | HAS_UNDERSHIRT | HAS_SOCKS
	bodyflags = HAS_TAIL | HAS_HEAD_ACCESSORY | HAS_MARKINGS | HAS_SKIN_COLOR | TAIL_WAGGING | HAS_HAIR
	taste_sensitivity = TASTE_SENSITIVITY_SHARP
	reagent_tag = ORGANIC

	blood_species = "Tajaran"
	flesh_color = "#b5a69b"
	base_color = "#424242"
	butt_sprite = "tajaran"

	has_organ = list(
		INTERNAL_ORGAN_HEART = /obj/item/organ/internal/heart/tajaran,
		INTERNAL_ORGAN_LUNGS = /obj/item/organ/internal/lungs/tajaran,
		INTERNAL_ORGAN_LIVER = /obj/item/organ/internal/liver/tajaran,
		INTERNAL_ORGAN_KIDNEYS = /obj/item/organ/internal/kidneys/tajaran,
		INTERNAL_ORGAN_BRAIN = /obj/item/organ/internal/brain/tajaran,
		INTERNAL_ORGAN_APPENDIX = /obj/item/organ/internal/appendix,
		INTERNAL_ORGAN_EYES = /obj/item/organ/internal/eyes/tajaran,
		INTERNAL_ORGAN_EARS = /obj/item/organ/internal/ears/tajaran,
	)

	meat_type = /obj/item/reagent_containers/food/snacks/meat/humanoid/tajaran

	has_limbs = list(
		BODY_ZONE_CHEST = list("path" = /obj/item/organ/external/chest),
		BODY_ZONE_PRECISE_GROIN = list("path" = /obj/item/organ/external/groin),
		BODY_ZONE_HEAD = list("path" = /obj/item/organ/external/head),
		BODY_ZONE_L_ARM = list("path" = /obj/item/organ/external/arm),
		BODY_ZONE_R_ARM = list("path" = /obj/item/organ/external/arm/right),
		BODY_ZONE_L_LEG = list("path" = /obj/item/organ/external/leg),
		BODY_ZONE_R_LEG = list("path" = /obj/item/organ/external/leg/right),
		BODY_ZONE_PRECISE_L_HAND = list("path" = /obj/item/organ/external/hand),
		BODY_ZONE_PRECISE_R_HAND = list("path" = /obj/item/organ/external/hand/right),
		BODY_ZONE_PRECISE_L_FOOT = list("path" = /obj/item/organ/external/foot),
		BODY_ZONE_PRECISE_R_FOOT = list("path" = /obj/item/organ/external/foot/right),
		BODY_ZONE_TAIL = list("path" = /obj/item/organ/external/tail/tajaran),
	)

	allowed_consumed_mobs = list(
		/mob/living/simple_animal/mouse, /mob/living/simple_animal/chick, /mob/living/simple_animal/butterfly, \
		/mob/living/simple_animal/parrot, /mob/living/simple_animal/tribble
	)

	suicide_messages = list(
		"пытается откусить себе язык!",
		"вонзает когти себе в глазницы!",
		"сворачивает себе шею!",
		"задерживает дыхание!")

	disliked_food = VEGETABLES | FRUIT | GRAIN | GROSS
	liked_food = MEAT | RAW | DAIRY | EGG

	age_sheet = list(
		SPECIES_AGE_MIN = 11,
		SPECIES_AGE_MAX = 44,
		JOB_MIN_AGE_HIGH_ED = 19,
		JOB_MIN_AGE_COMMAND = 19,
	)

	autohiss_basic_map = list(
		"r" = list("rr", "rrr", "rrrr"),
		"р" = list("рр", "ррр", "рррр"),
	)
	autohiss_exempt = list(/datum/language/tajaran)


/datum/species/tajaran/handle_death(gibbed, mob/living/carbon/human/H)
	H.stop_tail_wagging()

/datum/species/tajaran/handle_reagents(mob/living/carbon/human/H, datum/reagent/R)
	if(R.id == "moonlin")
		H.reagents.add_reagent("psilocybin",(0.5))
		return TRUE
	return ..()

/datum/species/tajaran/compressor_grind(location)
	new /obj/item/reagent_containers/food/snacks/tajaroni(location)
