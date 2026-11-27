/obj/item/organ/internal/ears
	name = "ears"
	desc = "Парный орган, отвечающий за аудиальное восприятие окружающей среды и получение информации о положении гуманоида в пространстве. Эти принадлежали человеку."
	gender = PLURAL
	icon_state = "ears"
	parent_organ_zone = BODY_ZONE_HEAD
	slot = INTERNAL_ORGAN_EARS
	var/bang_protect = HEARING_PROTECTION_NONE
	var/damage_multiplier = 1

/obj/item/organ/internal/ears/get_ru_names()
	return alist(
		NOMINATIVE = "уши человека",
		GENITIVE = "ушей человека",
		DATIVE = "ушам человека",
		ACCUSATIVE = "уши человека",
		INSTRUMENTAL = "ушами человека",
		PREPOSITIONAL = "ушах человека",
	)

/obj/item/organ/internal/ears/invincible/internal_receive_damage(amount, silent)
	return FALSE

/obj/item/organ/internal/ears/on_life()
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/C = owner

	if(!istype(C))
		return

	// If we have non-damage related deafness like mutations, quirks or clothing (earmuffs), don't bother processing here.
	// Ear healing from earmuffs or chems happen elsewhere
	if(HAS_TRAIT_NOT_FROM(owner, TRAIT_DEAF, EAR_DAMAGE))
		return

	if(is_dead())
		C.Deaf(2 SECONDS)
	else
		if((damage > 10) && prob(damage / 30))
			C.Deaf(8 SECONDS)

	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		if((H.l_ear && (H.l_ear.item_flags & HEALS_EARS)) || (H.r_ear && (H.r_ear.item_flags & HEALS_EARS)))
			H.AdjustDeaf(-1 SECONDS)
			heal_internal_damage(0.1)

/obj/item/organ/internal/ears/insert(mob/living/carbon/organ_owner, special)
	. = ..()
	if(!.)
		return
	REMOVE_TRAIT(organ_owner, TRAIT_DEAF, NO_EARS)
	RegisterSignal(organ_owner, COMSIG_MOB_SAY, PROC_REF(adjust_speech))

/obj/item/organ/internal/ears/remove(mob/living/carbon/organ_owner, special)
	. = ..()
	UnregisterSignal(organ_owner, COMSIG_MOB_SAY)
	// Do not apply with special flag, even if it would ultimately be redundant by new ears being hot-swapped in.
	// This is so we don't trip signal_addtrait when hot-swapping ears, which could cause inappropriate behavior like nuking sound effects.
	if(!special)
		ADD_TRAIT(organ_owner, TRAIT_DEAF, NO_EARS)

/obj/item/organ/internal/ears/has_damage()
	. = ..()
	if(.)
		return .
	if(owner.AmountDeaf())
		return TRUE

/obj/item/organ/internal/ears/surgeryize()
	owner?.SetDeaf(0)
	heal_internal_damage(100)

/obj/item/organ/internal/ears/proc/adjust_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	if(!HAS_TRAIT_FROM(owner, TRAIT_DEAF, EAR_DAMAGE) || HAS_TRAIT_NOT_FROM(owner, TRAIT_DEAF, EAR_DAMAGE))
		return

	var/message = speech_args[SPEECH_MESSAGE]
	message = replacetext(message, ". ", "! ")
	message = replacetext(message, "? ", "?! ")
	var/last_char = copytext_char(message, -1)
	if(last_char == "." && copytext_char(message, -2) != "..")
		message = copytext_char(message, 1, -1) + "!"
	else if(last_char == "?")
		message = copytext_char(message, 1, -1) + "?!"
	else if(last_char != "!" && last_char != ".")
		message += "!"

	speech_args[SPEECH_MESSAGE] = message
	return COMPONENT_UPPERCASE_SPEECH

/obj/item/organ/internal/ears/cybernetic
	name = "basic cybernetic ears"
	desc = "Простой кибернетический орган, имитирующий работу ушей."
	icon_state = "ears-c"
	origin_tech = "biotech=4"
	status = ORGAN_ROBOT
	damage_multiplier = 1.2
	pickup_sound = 'sound/items/handling/component_pickup.ogg'
	drop_sound = 'sound/items/handling/component_drop.ogg'

/obj/item/organ/internal/ears/cybernetic/get_ru_names()
	return alist(
		NOMINATIVE = "базовые кибернетические уши",
		GENITIVE = "базовых кибернетических ушей",
		DATIVE = "базовым кибернетическим ушам",
		ACCUSATIVE = "базовые кибернетические уши",
		INSTRUMENTAL = "базовыми кибернетическими ушами",
		PREPOSITIONAL = "базовых кибернетических ушах",
	)

/obj/item/organ/internal/ears/cybernetic/upgraded
	name = "cybernetic ears"
	desc = "Кибернетические уши, превосходящие органические по своим характеристикам."
	icon_state = "ears-c-u"
	origin_tech = "biotech=5"
	damage_multiplier = 0.75

/obj/item/organ/internal/ears/cybernetic/upgraded/get_ru_names()
	return alist(
		NOMINATIVE = "кибернетические уши",
		GENITIVE = "кибернетических ушей",
		DATIVE = "кибернетическим ушам",
		ACCUSATIVE = "кибернетические уши",
		INSTRUMENTAL = "кибернетическими ушами",
		PREPOSITIONAL = "кибернетических ушах",
	)

/obj/item/organ/internal/ears/cybernetic/whisper
	name = "whisper-sensitive cybernetic ears"
	desc = "Позволяют легче расслышать шёпот. Однако делают владельца особенно уязвимым к громким звукам."
	icon_state = "ears-c-u"
	origin_tech = "biotech=6"
	damage_multiplier = 2
	organ_traits = list(TRAIT_GOOD_HEARING)

/obj/item/organ/internal/ears/cybernetic/whisper/get_ru_names()
	return alist(
		NOMINATIVE = "чувствительные к шёпоту кибернетические уши",
		GENITIVE = "чувствительных к шёпоту кибернетических ушей",
		DATIVE = "чувствительным к шёпоту кибернетическим ушам",
		ACCUSATIVE = "чувствительные к шёпоту кибернетические уши",
		INSTRUMENTAL = "чувствительными к шёпоту кибернетическими ушами",
		PREPOSITIONAL = "чувствительных к шёпоту кибернетических ушах",
	)

/obj/item/organ/internal/ears/cybernetic/volume
	name = "volume-adjusting cybernetic ears"
	desc = "Продвинутые кибернетические уши, способные приглушать громкие звуки и тем защищать владельца."
	icon_state = "ears-c-u"
	origin_tech = "biotech=6"
	damage_multiplier = 0.5
	bang_protect = HEARING_PROTECTION_MINOR

/obj/item/organ/internal/ears/cybernetic/volume/get_ru_names()
	return alist(
		NOMINATIVE = "кибернетические уши с регулировкой громкости",
		GENITIVE = "кибернетических ушей с регулировкой громкости",
		DATIVE = "кибернетическим ушам с регулировкой громкости",
		ACCUSATIVE = "кибернетические уши с регулировкой громкости",
		INSTRUMENTAL = "кибернетическими ушами с регулировкой громкости",
		PREPOSITIONAL = "кибернетических ушах с регулировкой громкости",
	)

/obj/item/organ/internal/ears/cybernetic/xray
	name = "wall-penetrating cybernetic ears"
	desc = "Благодаря чудесам современной инженерии позволяют слышать речь сквозь стены. Однако делают владельца особенно уязвимым к громким звукам."
	icon_state = "ears-c-u"
	origin_tech = "biotech=7"
	damage_multiplier = 2
	organ_traits = list(TRAIT_XRAY_HEARING)

/obj/item/organ/internal/ears/cybernetic/xray/get_ru_names()
	return alist(
		NOMINATIVE = "кибернетические уши, слышащие сквозь стены",
		GENITIVE = "кибернетических ушей, слышащих сквозь стены",
		DATIVE = "кибернетическим ушам, слышащим сквозь стены",
		ACCUSATIVE = "кибернетические уши, слышащие сквозь стены",
		INSTRUMENTAL = "кибернетическими ушами, слышащими сквозь стены",
		PREPOSITIONAL = "кибернетических ушах, слышащих сквозь стены",
	)

/obj/item/organ/internal/ears/cybernetic/cat
	name = "basic cybernetic cat ears"
	desc = "Простой кибернетический орган в форме кошачьих ушек, имитирующий работу ушей."
	icon_state = "ears-c-cat"
	damage_multiplier = 2.4
	var/inner_color = "#F0004A"

/obj/item/organ/internal/ears/cybernetic/cat/get_ru_names()
	return alist(
		NOMINATIVE = "базовые кибернетические кошачьи уши",
		GENITIVE = "базовых кибернетических кошачьих ушей",
		DATIVE = "базовым кибернетическим кошачьим ушам",
		ACCUSATIVE = "базовые кибернетические кошачьи уши",
		INSTRUMENTAL = "базовыми кибернетическими кошачьими ушами",
		PREPOSITIONAL = "базовых кибернетических кошачьих ушах",
	)

/obj/item/organ/internal/ears/cybernetic/cat/insert(mob/living/carbon/organ_owner, special)
	. = ..()
	if(. && ishuman(organ_owner))
		var/mob/living/carbon/human/human_owner = organ_owner
		human_owner.update_mutant_ears()

/obj/item/organ/internal/ears/cybernetic/cat/remove(mob/living/carbon/organ_owner, special)
	. = ..()
	if(ishuman(organ_owner))
		var/mob/living/carbon/human/human_owner = organ_owner
		human_owner.update_mutant_ears()

/obj/item/organ/internal/ears/cybernetic/cat/upgraded
	name = "cybernetic cat ears"
	desc = "Кибернетические кошачьи уши. Всё ещё уступают человеческим в прочности."
	icon_state = "ears-c-cat-u"
	origin_tech = "biotech=5"
	damage_multiplier = 1.5

/obj/item/organ/internal/ears/cybernetic/cat/upgraded/get_ru_names()
	return alist(
		NOMINATIVE = "кибернетические кошачьи уши",
		GENITIVE = "кибернетических кошачьих ушей",
		DATIVE = "кибернетическим кошачьим ушам",
		ACCUSATIVE = "кибернетические кошачьи уши",
		INSTRUMENTAL = "кибернетическими кошачьими ушами",
		PREPOSITIONAL = "кибернетических кошачьих ушах",
	)

/obj/item/organ/internal/ears/cybernetic/cat/volume
	name = "volume-adjusting cybernetic cat ears"
	desc = "Продвинутые кибернетические кошачьи уши, способные приглушать громкие звуки и тем защищать владельца."
	icon_state = "ears-c-cat-u2"
	origin_tech = "biotech=6"
	damage_multiplier = 1
	bang_protect = HEARING_PROTECTION_MINOR

/obj/item/organ/internal/ears/cybernetic/cat/volume/get_ru_names()
	return alist(
		NOMINATIVE = "кибернетические кошачьи уши с регулировкой громкости",
		GENITIVE = "кибернетических кошачьих ушей с регулировкой громкости",
		DATIVE = "кибернетическим кошачьим ушам с регулировкой громкости",
		ACCUSATIVE = "кибернетические кошачьи уши с регулировкой громкости",
		INSTRUMENTAL = "кибернетическими кошачьими ушами с регулировкой громкости",
		PREPOSITIONAL = "кибернетических кошачьих ушах с регулировкой громкости",
	)

/obj/item/organ/internal/ears/cybernetic/cat/whisper
	name = "whisper-sensitive cybernetic cat ears"
	desc = "Позволяют легче расслышать шёпот. Однако делают владельца крайне уязвимым к громким звукам."
	icon_state = "ears-c-cat-green"
	origin_tech = "biotech=6"
	damage_multiplier = 3
	organ_traits = list(TRAIT_GOOD_HEARING)
	inner_color = "#00D844"

/obj/item/organ/internal/ears/cybernetic/cat/whisper/get_ru_names()
	return alist(
		NOMINATIVE = "чувствительные к шёпоту кибернетические кошачьи уши",
		GENITIVE = "чувствительных к шёпоту кибернетических кошачьих ушей",
		DATIVE = "чувствительным к шёпоту кибернетическим кошачьим ушам",
		ACCUSATIVE = "чувствительные к шёпоту кибернетические кошачьи уши",
		INSTRUMENTAL = "чувствительными к шёпоту кибернетическими кошачьими ушами",
		PREPOSITIONAL = "чувствительных к шёпоту кибернетических кошачьих ушах",
	)

/obj/item/organ/internal/ears/cybernetic/cat/xray
	name = "wall-penetrating cybernetic cat ears"
	desc = "Благодаря чудесам современной кошачьей инженерии позволяют слышать речь сквозь стены. Однако делают владельца крайне уязвимым к громким звукам."
	icon_state = "ears-c-cat-blue"
	origin_tech = "biotech=7"
	damage_multiplier = 3
	organ_traits = list(TRAIT_XRAY_HEARING)
	inner_color = "#0079EA"

/obj/item/organ/internal/ears/cybernetic/cat/xray/get_ru_names()
	return alist(
		NOMINATIVE = "кибернетические кошачьи уши, слышащие сквозь стены",
		GENITIVE = "кибернетических кошачьих ушей, слышащих сквозь стены",
		DATIVE = "кибернетическим кошачьим ушам, слышащим сквозь стены",
		ACCUSATIVE = "кибернетические кошачьи уши, слышащие сквозь стены",
		INSTRUMENTAL = "кибернетическими кошачьими ушами, слышащими сквозь стены",
		PREPOSITIONAL = "кибернетических кошачьих ушах, слышащих сквозь стены",
	)

/obj/item/organ/internal/ears/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return

	internal_receive_damage(30)

	if(!iscarbon(owner))
		return

	var/mob/living/carbon/C = owner
	var/losstime = 120 SECONDS

	if(HAS_TRAIT(C, TRAIT_ADVANCED_CYBERIMPLANTS))
		losstime /= 3

	C.AdjustDeaf(losstime)
