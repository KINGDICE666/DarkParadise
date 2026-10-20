/obj/item/organ/internal/liver/resomi
	species_type = /datum/species/resomi
	name = "resomi liver"
	desc = "Печень резоми. Крошечная, но эффективно перерабатывает питательные вещества для поддержания быстрого метаболизма."

/obj/item/organ/internal/liver/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "печень резоми",
		GENITIVE = "печени резоми",
		DATIVE = "печени резоми",
		ACCUSATIVE = "печень резоми",
		INSTRUMENTAL = "печенью резоми",
		PREPOSITIONAL = "печени резоми",
	)

/obj/item/organ/internal/eyes/resomi
	species_type = /datum/species/resomi
	see_in_dark = 6 //6 in the game look like 5, how it wrote in wiki
	name = "resomi eyes"
	desc = "Пара глаз резоми, приспособленных улавливать мельчайшие движения на высокой скорости."

/obj/item/organ/internal/eyes/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "глаза резоми",
		GENITIVE = "глаз резоми",
		DATIVE = "глазам резоми",
		ACCUSATIVE = "глаза резоми",
		INSTRUMENTAL = "глазами резоми",
		PREPOSITIONAL = "глазах резоми",
	)

/obj/item/organ/internal/ears/resomi
	species_type = /datum/species/resomi
	name = "resomi ears"
	desc = "Слуховой аппарат резоми, управляющий всеми четырьмя внешними ушными раковинами."
	actions_types = list(/datum/action/item_action/organ_action/resomi_listen)

/obj/item/organ/internal/ears/resomi/insert(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(.)
		target.add_traits(list(TRAIT_GOOD_HEARING, TRAIT_WEAK_EARS), UNIQUE_TRAIT_SOURCE(src))

/obj/item/organ/internal/ears/resomi/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	target.remove_traits(list(TRAIT_GOOD_HEARING, TRAIT_WEAK_EARS), UNIQUE_TRAIT_SOURCE(src))
	target.remove_status_effect(STATUS_EFFECT_RESOMI_LISTENING)
	return ..()

/obj/item/organ/internal/ears/resomi/ui_action_click(mob/user, datum/action/action, leftclick)
	if(owner.has_status_effect(STATUS_EFFECT_RESOMI_LISTENING))
		owner.remove_status_effect(STATUS_EFFECT_RESOMI_LISTENING)
		return
	if(HAS_TRAIT(owner, TRAIT_DEAF))
		owner.balloon_alert(owner, "вы ничего не слышите!")
		return
	owner.apply_status_effect(STATUS_EFFECT_RESOMI_LISTENING)

/obj/item/organ/internal/ears/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "уши резоми",
		GENITIVE = "ушей резоми",
		DATIVE = "ушам резоми",
		ACCUSATIVE = "уши резоми",
		INSTRUMENTAL = "ушами резоми",
		PREPOSITIONAL = "ушах резоми",
	)

/obj/item/organ/internal/heart/resomi
	species_type = /datum/species/resomi
	name = "resomi heart"
	desc = "Сердце резоми. Бьётся невероятно часто, обеспечивая кровообращение в хрупком теле."

/obj/item/organ/internal/heart/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "сердце резоми",
		GENITIVE = "сердца резоми",
		DATIVE = "сердцу резоми",
		ACCUSATIVE = "сердце резоми",
		INSTRUMENTAL = "сердцем резоми",
		PREPOSITIONAL = "сердце резоми",
	)

/obj/item/organ/internal/brain/resomi
	species_type = /datum/species/resomi
	name = "resomi brain"
	desc = "Мозг резоми с плотной нейронной структурой, позволяющей быстро обрабатывать информацию."

/obj/item/organ/internal/brain/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "мозг резоми",
		GENITIVE = "мозга резоми",
		DATIVE = "мозгу резоми",
		ACCUSATIVE = "мозг резоми",
		INSTRUMENTAL = "мозгом резоми",
		PREPOSITIONAL = "мозге резоми",
	)

/obj/item/organ/internal/lungs/resomi
	species_type = /datum/species/resomi
	name = "resomi lungs"
	desc = "Пара лёгких резоми, приспособленных поглощать кислород даже в разреженной холодной атмосфере."

/obj/item/organ/internal/lungs/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "лёгкие резоми",
		GENITIVE = "лёгких резоми",
		DATIVE = "лёгким резоми",
		ACCUSATIVE = "лёгкие резоми",
		INSTRUMENTAL = "лёгкими резоми",
		PREPOSITIONAL = "лёгких резоми",
	)

/obj/item/organ/internal/kidneys/resomi
	species_type = /datum/species/resomi
	name = "resomi kidneys"
	desc = "Пара маленьких почек резоми, особенно уязвимых для токсинов."

/obj/item/organ/internal/kidneys/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "почки резоми",
		GENITIVE = "почек резоми",
		DATIVE = "почкам резоми",
		ACCUSATIVE = "почки резоми",
		INSTRUMENTAL = "почками резоми",
		PREPOSITIONAL = "почках резоми",
	)

/obj/item/organ/internal/appendix/resomi
	species_type = /datum/species/resomi
	name = "resomi appendix"
	desc = "Рудиментарный аппендикс резоми, сохранившийся от предков, питавшихся более грубой пищей."

/obj/item/organ/internal/appendix/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "аппендикс резоми",
		GENITIVE = "аппендикса резоми",
		DATIVE = "аппендиксу резоми",
		ACCUSATIVE = "аппендикс резоми",
		INSTRUMENTAL = "аппендиксом резоми",
		PREPOSITIONAL = "аппендиксе резоми",
	)

/obj/item/organ/external/tail/resomi
	species_type = /datum/species/resomi
	name = "resomi tail"
	desc = "Хвост. Этот принадлежал резоми."
	force_icon = 'icons/mob/sprite_accessories/resomi/resomi_tail.dmi'
	icon_name = "resomitail_s"

/obj/item/organ/external/tail/resomi/get_healthdoll_state()
	return "resomitail"

/obj/item/organ/external/tail/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "хвост резоми",
		GENITIVE = "хвоста резоми",
		DATIVE = "хвосту резоми",
		ACCUSATIVE = "хвост резоми",
		INSTRUMENTAL = "хвостом резоми",
		PREPOSITIONAL = "хвосте резоми",
	)

/datum/action/item_action/organ_action/resomi_listen
	name = "Прислушаться"
	desc = "Замедлиться и вслушаться в окружение: движение существ, упавшие предметы и прочие звуки за стенами и в темноте отмечаются на экране."
	button_icon_state = "resomi_listen"

#define RESOMI_LISTEN_WAVE_START_SCALE 0.1
#define RESOMI_LISTEN_WAVE_END_SCALE 5

/obj/effect/temp_visual/sonar_ping/listen_wave
	real_icon_state = "circle_wave"
	duration = 1 SECONDS

/obj/effect/temp_visual/sonar_ping/listen_wave/Initialize(mapload, mob/living/looker, atom/center)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	modsuit_image.icon = 'icons/effects/64x64.dmi'
	modsuit_image.pixel_w = -(ICON_SIZE_X / 2)
	modsuit_image.pixel_z = -(ICON_SIZE_Y / 2)
	modsuit_image.color = COLOR_CYAN
	modsuit_image.transform = matrix().Scale(RESOMI_LISTEN_WAVE_START_SCALE)
	animate(modsuit_image, transform = matrix().Scale(RESOMI_LISTEN_WAVE_END_SCALE), alpha = 0, time = duration, easing = SINE_EASING | EASE_OUT)

#undef RESOMI_LISTEN_WAVE_START_SCALE
#undef RESOMI_LISTEN_WAVE_END_SCALE
