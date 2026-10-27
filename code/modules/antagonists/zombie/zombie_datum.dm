/datum/antagonist/zombie
	name = "Zombie"
	roundend_category = "Зомби"
	antag_hud_name = "hudzombie"
	antag_hud_type = ANTAG_HUD_ZOMBIE
	special_role = SPECIAL_ROLE_ZOMBIE
	antag_menu_name = "Зомби"
	clown_gain_text = "М-Мозгиии... Хонк..."
	clown_removal_text = "Вы снова чувствуете себя смешнее."
	stinger_sound = 'sound/ambience/antag/zomboidalert.ogg'
	var/static/list/zombie_traits = list(TRAIT_ABSTRACT_HANDS, TRAIT_NO_BREATH)
	var/datum/unarmed_attack/claws/claw_attack
	var/chosen_disease

/datum/antagonist/zombie/New(chosen_plague)
	chosen_disease = chosen_plague
	..()

/datum/antagonist/zombie/on_gain()
	. = ..()
	if(!.)
		return
	if(HAS_TRAIT(owner.current, TRAIT_PLAGUE_ZOMBIE))
		var/datum/action/cooldown/spell/zombie_claws/plague_claws/plague_claws = new
		plague_claws.disease = chosen_disease
		owner.AddSpell(plague_claws)
		owner.AddSpell(new /datum/action/cooldown/spell/pointed/zombie_leap)
	else
		owner.AddSpell(new /datum/action/cooldown/spell/zombie_claws)
	claw_attack = new

/datum/antagonist/zombie/Destroy(force)
	if(owner)
		owner.RemoveSpell(/datum/action/cooldown/spell/zombie_claws/plague_claws)
		owner.RemoveSpell(/datum/action/cooldown/spell/pointed/zombie_leap)
		owner.RemoveSpell(/datum/action/cooldown/spell/zombie_claws)
	QDEL_NULL(claw_attack)
	return ..()

/datum/antagonist/zombie/add_owner_to_gamemode()
	SSticker.mode.zombies |= owner

/datum/antagonist/zombie/remove_owner_from_gamemode()
	SSticker.mode?.zombies -= owner

/datum/antagonist/zombie/greet()
	var/list/messages = list()
	. = messages
	if(HAS_TRAIT(owner.current, TRAIT_PLAGUE_ZOMBIE))
		return
	messages.Add(span_zombie_userdanger("Мы — зомби!"))
	messages.Add(span_zombie("Вы чувствуете, как останавливается ваше сердце, но что-то не так... жизнь не покинула ваше изломанное тело. Вы ощущаете лишь глубокий и неутолимый голод, который не остановит даже смерть."))

/datum/antagonist/zombie/finalize_antag()
	if(HAS_TRAIT(owner.current, TRAIT_PLAGUE_ZOMBIE))
		return
	return "<br>[span_notice("Когтями можно выламывать двери и раскалывать повреждённые черепа. Когда голова вскрыта, ешьте мозги пустой рукой. Также можно агрессивно схватить жертву и ударить её, чтобы укусить и заразить. Вы медленно лечитесь, а в темноте — быстрее. После смерти вы постепенно восстановитесь и вновь поднимитесь.")]"

/datum/antagonist/zombie/apply_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	user.add_blocked_language(GLOB.all_languages - /datum/language/zombie, source = LANGUAGE_ZOMBIE)
	user.grant_language(/datum/language/zombie, source = LANGUAGE_ZOMBIE)
	if(!HAS_TRAIT(user, TRAIT_PLAGUE_ZOMBIE))
		user.extinguish_light()
	for(var/trait in zombie_traits)
		ADD_TRAIT(user, trait, ZOMBIE_TRAIT)
	user.add_movespeed_modifier(/datum/movespeed_modifier/zombie)
	if(!user.HasDisease(/datum/disease/virus/zombie))
		var/datum/disease/virus/zombie/zombie_virus = new
		var/datum/disease/virus/zombie/contracted = zombie_virus.Contract(user)
		if(contracted)
			contracted.stage = 7

	if(ishuman(user))
		var/mob/living/carbon/human/human = user
		human.physiology.stamina_mod *= 0.5

/datum/antagonist/zombie/remove_innate_effects(mob/living/mob_override)
	var/mob/living/user = ..()
	for(var/trait in zombie_traits)
		REMOVE_TRAIT(user, trait, ZOMBIE_TRAIT)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/zombie)
	user.remove_blocked_language(GLOB.all_languages, source = LANGUAGE_ZOMBIE)
	user.remove_language(/datum/language/zombie, source = LANGUAGE_ZOMBIE)

	if(ishuman(user))
		var/mob/living/carbon/human/human = user
		human.physiology.stamina_mod /= 0.5

/datum/antagonist/zombie/on_body_transfer(mob/living/old_body, mob/living/new_body)
	if(!new_body.HasDisease(/datum/disease/virus/zombie))
		owner.remove_antag_datum(/datum/antagonist/zombie)
		return
	return ..()

/datum/antagonist/zombie/give_objectives()
	if(HAS_TRAIT(owner.current, TRAIT_PLAGUE_ZOMBIE))
		return
	add_objective(/datum/objective/zombie)
