/datum/action/cooldown/spell/zombie_claws
	name = "Когти зомби"
	desc = "Выпустить или убрать когти, которыми можно рвать и заражать других."
	button_icon_state = "vampire_claws"
	background_icon_state = "bg_vampire"
	spell_requirements = SPELL_REQUIRES_HUMAN
	antimagic_flags = NONE
	var/list/our_claws = list()
	var/infection_stage = 1
	var/disease

/datum/action/cooldown/spell/zombie_claws/Destroy()
	QDEL_LIST(our_claws)
	return ..()

/datum/action/cooldown/spell/zombie_claws/Grant(mob/grant_to)
	. = ..()
	if(!owner)
		return
	RegisterSignals(owner, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_SWAP_HANDS), PROC_REF(update_status_on_signal), override = TRUE)

/datum/action/cooldown/spell/zombie_claws/Remove(mob/living/remove_from)
	UnregisterSignal(remove_from, COMSIG_MOB_SWAP_HANDS)
	return ..()

/datum/action/cooldown/spell/zombie_claws/cast(atom/cast_on)
	. = ..()
	if(dispel())
		return

	var/obj/item/twohanded/required/zombie_claw/claws
	if(HAS_TRAIT(owner, TRAIT_PLAGUE_ZOMBIE))
		claws = new /obj/item/twohanded/required/zombie_claw/plague_claw(owner.loc, src, disease)
	else
		claws = new /obj/item/twohanded/required/zombie_claw(owner.loc, src)
		claws.infection_stage = infection_stage

	if(owner.put_in_hands(claws))
		our_claws += claws
	else
		qdel(claws)
		to_chat(owner, span_zombie_warning("У нас нет когтей..."))

/datum/action/cooldown/spell/zombie_claws/proc/dispel()
	var/obj/item/twohanded/required/zombie_claw/claw = owner.is_type_in_hands(/obj/item/twohanded/required/zombie_claw)
	if(claw)
		qdel(claw)
		return TRUE
	return FALSE

/datum/action/cooldown/spell/zombie_claws/can_cast_spell(feedback = TRUE)
	if(owner.get_active_hand() && !owner.is_type_in_hands(/obj/item/twohanded/required/zombie_claw))
		return FALSE
	return ..()

/datum/action/cooldown/spell/zombie_claws/plague_claws
	name = "Чумные когти"
	desc = "Выпустить или убрать когти, которыми можно рвать других и заражать их смертельными болезнями."

/obj/item/twohanded/required/zombie_claw
	name = "claws"
	desc = "Когти, растущие из ваших гниющих рук. Идеально подходят, чтобы вскрывать черепа и добираться до мозгов."
	icon = 'icons/effects/vampire_effects.dmi'
	icon_state = "vamp_claws"
	w_class = WEIGHT_CLASS_BULKY
	item_flags = ABSTRACT|DROPDEL
	gender = PLURAL
	force = 21
	force_wielded = 21
	attack_effect_override = ATTACK_EFFECT_CLAW
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("полоснул", "порезал", "разорвал", "растерзал", "поцарапал", "искромсал")
	sprite_sheets_inhand = list(SPECIES_VOX = 'icons/mob/clothing/species/vox/held.dmi', SPECIES_DRASK = 'icons/mob/clothing/species/drask/held.dmi')
	var/datum/action/cooldown/spell/zombie_claws/parent_spell
	var/force_weak = 10
	var/infection_stage = 1
	var/claw_disease

/obj/item/twohanded/required/zombie_claw/get_ru_names()
	return alist(
		NOMINATIVE = "когти",
		GENITIVE = "когтей",
		DATIVE = "когтям",
		ACCUSATIVE = "когти",
		INSTRUMENTAL = "когтями",
		PREPOSITIONAL = "когтях",
	)

/obj/item/twohanded/required/zombie_claw/Initialize(mapload, new_parent_spell)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)
	if(new_parent_spell)
		parent_spell = new_parent_spell
		RegisterSignal(parent_spell.owner, COMSIG_MOB_KEY_DROP_ITEM_DOWN, PROC_REF(dispel))

/obj/item/twohanded/required/zombie_claw/proc/dispel(mob/user)
	SIGNAL_HANDLER
	if(user.get_active_hand() != src)
		return
	qdel(src)
	return COMPONENT_CANCEL_DROP

/obj/item/twohanded/required/zombie_claw/Destroy()
	if(parent_spell)
		UnregisterSignal(parent_spell.owner, COMSIG_MOB_KEY_DROP_ITEM_DOWN)
		parent_spell.our_claws -= src
		parent_spell = null
	return ..()

/obj/item/twohanded/required/zombie_claw/pre_attackby(atom/target, mob/living/user, modifiers)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_PLAGUE_ZOMBIE))
		return
	force = user.reagents.has_reagent("zombiecure2") ? force_weak : force_wielded

/obj/item/twohanded/required/zombie_claw/afterattack(atom/target, mob/user, proximity_flag, list/modifiers, status)
	if(!proximity_flag)
		return
	if(!ishuman(target) || ismachineperson(target))
		return
	var/mob/living/carbon/human/attack_target = target

	if(HAS_TRAIT(user, TRAIT_PLAGUE_ZOMBIE))
		try_virus_infect(attack_target, user)
		return
	try_infect(attack_target, user)

	var/obj/item/organ/internal/brain/eat_brain = attack_target.get_organ_slot(INTERNAL_ORGAN_BRAIN)
	if(!eat_brain)
		return
	var/obj/item/organ/external/brain_holder = attack_target.get_organ(eat_brain.parent_organ_zone)
	if(!brain_holder || brain_holder.open || brain_holder.limb_zone != user.zone_selected)
		return

	if(brain_holder.brute_dam + brain_holder.burn_dam <= brain_holder.max_damage - 5)
		return

	if(attack_target.getarmor(brain_holder, MELEE) > 0)
		to_chat(user, span_zombie_warning("Мозги [attack_target] защищены."))
		return

	var/encased_name = brain_holder.encased ? brain_holder.encased : brain_holder.declent_ru(ACCUSATIVE)
	to_chat(attack_target, span_userdanger("Когти [user] впиваются в [GEND_YOUR(brain_holder)] [brain_holder.declent_ru(ACCUSATIVE)]!"))
	user.visible_message(span_danger("[user] впива[PLUR_ET_YUT(user)]ся когтями в [brain_holder.declent_ru(ACCUSATIVE)] [attack_target]!"), span_zombie_danger("Мы вгрызаемся в [encased_name] [attack_target]..."))
	playsound(user, 'sound/weapons/armblade.ogg', 50, TRUE)
	if(!do_after(user, 3 SECONDS, attack_target))
		return

	playsound(user.loc, 'sound/misc/moist_impact.ogg', 50, TRUE)
	brain_holder.fracture()

	brain_holder.open = ORGAN_ORGANIC_ENCASED_OPEN
	to_chat(attack_target, span_userdanger("Ваш[GEND_A_E_I(brain_holder)] [brain_holder.declent_ru(NOMINATIVE)] жестоко вскрыт[GEND_A_O_Y(brain_holder)]!"))
	user.visible_message(span_danger("[user] жестоко разрыва[PLUR_ET_YUT(user)] [brain_holder.declent_ru(ACCUSATIVE)] [attack_target]!"), span_zombie_danger("Мы вскрываем [brain_holder.declent_ru(ACCUSATIVE)] [attack_target]!"))

/obj/item/twohanded/required/zombie_claw/proc/try_infect(mob/living/carbon/human/target, mob/living/user)
	if(HAS_TRAIT(user, TRAIT_NON_INFECTIOUS_ZOMBIE))
		return
	if(!(user.zone_selected in list(BODY_ZONE_CHEST, BODY_ZONE_HEAD)))
		to_chat(user, span_zombie_warning("Наша зараза не распространится, если не задеть голову или грудь."))
		return
	if(HAS_TRAIT(target, TRAIT_PIERCEIMMUNE))
		return
	if(target.reagents.has_reagent("zombiecure1") || target.reagents.has_reagent("spaceacillin"))
		return
	var/obj/item/organ/external/affecting = target.get_organ(user.zone_selected)
	if(!affecting || affecting.is_robotic())
		return
	if(prob(3 * target.getarmor(user.zone_selected, MELEE)) || prob(50))
		return

	if(!target.HasDisease(/datum/disease/virus/zombie))
		var/datum/disease/virus/zombie/zombie_virus = new
		if(!zombie_virus.Contract(target))
			return
	playsound(user.loc, 'sound/misc/moist_impact.ogg', 50, TRUE)
	make_bleed(target, affecting)
	for(var/datum/disease/virus/zombie/zombie_virus in target.diseases)
		zombie_virus.stage = max(zombie_virus.stage, infection_stage)

/obj/item/twohanded/required/zombie_claw/proc/try_virus_infect(mob/living/carbon/human/target, mob/living/user)
	if(!claw_disease)
		return
	if(!target.HasDisease(claw_disease))
		var/datum/disease/plague = new claw_disease
		plague.Contract(target)
	else if(prob(40))
		for(var/datum/disease/disease as anything in target.diseases)
			if(disease.type == claw_disease && disease.stage < disease.max_stages)
				disease.stage++
	make_bleed(target, target.get_organ(user.zone_selected))

/obj/item/twohanded/required/zombie_claw/proc/make_bleed(mob/living/carbon/human/target, obj/item/organ/external/affecting)
	if(!affecting || affecting.is_robotic())
		return
	affecting.bleeding_amount = max(5, affecting.bleeding_amount + 1)
	target.add_bleeding_bodypart(affecting)

/obj/item/twohanded/required/zombie_claw/attack_self(mob/user)
	qdel(src)

/obj/item/twohanded/required/zombie_claw/plague_claw
	name = "plague claws"
	desc = "Когти, растущие из ваших гниющих рук и сочащиеся смрадной сукровицей. Идеально подходят, чтобы рвать кости и плоть во имя вашего хозяина."
	armour_penetration = 15
	force = 13
	force_wielded = 13

/obj/item/twohanded/required/zombie_claw/plague_claw/get_ru_names()
	return alist(
		NOMINATIVE = "чумные когти",
		GENITIVE = "чумных когтей",
		DATIVE = "чумным когтям",
		ACCUSATIVE = "чумные когти",
		INSTRUMENTAL = "чумными когтями",
		PREPOSITIONAL = "чумных когтях",
	)

/obj/item/twohanded/required/zombie_claw/plague_claw/Initialize(mapload, new_parent_spell, disease)
	. = ..()
	claw_disease = disease

/datum/action/cooldown/spell/pointed/zombie_leap
	name = "Яростный прыжок"
	desc = "На мгновение снять ограничения с мышц и совершить огромный прыжок к цели."
	button_icon_state = "mutate"
	background_icon_state = "bg_vampire"
	spell_requirements = SPELL_REQUIRES_HUMAN
	antimagic_flags = NONE
	cooldown_time = 60 SECONDS
	aim_assist = FALSE
	active_msg = "Вы готовитесь к прыжку."
	deactive_msg = "Вы расслабляете мышцы."

/datum/action/cooldown/spell/pointed/zombie_leap/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/zombie_leap/can_cast_spell(feedback = TRUE)
	var/mob/living/caster = owner
	if(caster.body_position == LYING_DOWN)
		return FALSE
	return ..()

/datum/action/cooldown/spell/pointed/zombie_leap/cast(atom/cast_on)
	. = ..()
	var/mob/living/caster = owner
	playsound(caster, 'sound/voice/zombie_leap.ogg', 80, FALSE)
	caster.apply_status_effect(STATUS_EFFECT_CHARGING)
	caster.throw_at(cast_on, 5, 1, caster, FALSE, callback = CALLBACK(caster, TYPE_PROC_REF(/mob/living, remove_status_effect), STATUS_EFFECT_CHARGING))
