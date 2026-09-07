/datum/action/avatar_domain_info
	name = "Информация о домене"
	desc = "Открыть инструктаж по текущему виртуальному домену."
	button_icon_state = "hotkey_help"
	show_to_observers = FALSE
	var/help_text

/datum/action/avatar_domain_info/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return

	ui_interact(owner)

/datum/action/avatar_domain_info/ui_state(mob/user)
	return GLOB.always_state

/datum/action/avatar_domain_info/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AvatarHelp", "Информация о домене")
		ui.open()

/datum/action/avatar_domain_info/ui_static_data(mob/user)
	return list("help_text" = help_text)

/obj/effect/proc_holder/spell/aoe/conjure/bitrunner_cheese
	name = "Summon Cheese"
	desc = "Создаёт девять головок сыра вокруг заклинателя."
	base_cooldown = 1 MINUTES
	clothes_req = FALSE
	human_req = FALSE
	spell_requirements = NONE
	invocation = "PL'YR DOT PL'CTM' OOO'B'ABEE G!"
	invocation_type = "shout"
	aoe_range = 1
	summon_amt = 9
	summon_type = list(/obj/item/reagent_containers/food/snacks/sliceable/cheesewheel)
	delay = 0
	cast_sound = 'sound/magic/summonitems_generic.ogg'

/obj/effect/proc_holder/spell/bitrunner_heal
	name = "Lesser Heal"
	desc = "Исцеляет по 10 единиц физических повреждений и ожогов заклинателя."
	clothes_req = FALSE
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC
	invocation = "Victus sano!"
	invocation_type = "whisper"
	sound = 'sound/magic/staff_healing.ogg'
	var/brute_to_heal = 10
	var/burn_to_heal = 10

/obj/effect/proc_holder/spell/bitrunner_heal/create_new_targeting()
	return new /datum/spell_targeting/self

/obj/effect/proc_holder/spell/bitrunner_heal/cast(list/targets, mob/living/user = usr)
	user.adjustBruteLoss(-brute_to_heal, updating_health = FALSE)
	user.adjustFireLoss(-burn_to_heal, updating_health = FALSE)
	user.updatehealth()
	user.visible_message(span_notice("[user] окутывается мягким светом."), span_notice("Вы окутываете себя целительным светом."))
	return TRUE

/obj/effect/proc_holder/spell/shapeshift/bitrunner_polar_bear
	name = "Polar Bear Form"
	desc = "Превращает вас в белого медведя."
	invocation = "*roar"
	invocation_type = "none"
	spell_requirements = NONE
	shapeshift_type = /mob/living/simple_animal/hostile/bear/polar/bitrunner
	possible_shapes = list(/mob/living/simple_animal/hostile/bear/polar/bitrunner)

/mob/living/simple_animal/hostile/bear/polar/bitrunner
	name = "magic polar bear"
	desc = "Белый медведь с необычайно осмысленным взглядом."
	health = 300
	maxHealth = 300
	obj_damage = 40
	melee_damage_lower = 25
	melee_damage_upper = 25
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	faction = list("neutral")

/mob/living/simple_animal/hostile/bear/polar/bitrunner/get_ru_names()
	return alist(
		NOMINATIVE = "волшебный белый медведь",
		GENITIVE = "волшебного белого медведя",
		DATIVE = "волшебному белому медведю",
		ACCUSATIVE = "волшебного белого медведя",
		INSTRUMENTAL = "волшебным белым медведем",
		PREPOSITIONAL = "волшебном белом медведе",
	)

/obj/effect/proc_holder/spell/fireball/bitrunner_lightning
	name = "Lightning Bolt"
	desc = "Выпускает молнию, перескакивающую между целями без оглушения."
	base_cooldown = 10 SECONDS
	invocation = "P'WAH, UNLIM'TED P'WAH!"
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC
	fireball_type = /obj/projectile/magic/bitrunner_lightning
	action_icon_state = "lightning"
	sound = 'sound/magic/lightningbolt.ogg'
	selection_activated_message = span_notice_alt("Ваши руки наливаются древним электричеством! <b>Кликните по цели левой кнопкой!</b>")
	selection_deactivated_message = span_notice_alt("Вы позволяете энергии утечь обратно...")

/obj/effect/proc_holder/spell/fireball/bitrunner_lightning/update_icon_state()
	if(!action)
		return
	action.button_icon_state = action_icon_state
	action.UpdateButtonIcon()

/obj/projectile/magic/bitrunner_lightning
	name = "lightning bolt"
	icon_state = "spark"
	damage = 15
	damage_type = BURN
	nodamage = FALSE
	speed = 0.2
	var/datum/beam/lightning_chain

/obj/projectile/magic/bitrunner_lightning/get_ru_names()
	return alist(
		NOMINATIVE = "молния",
		GENITIVE = "молнии",
		DATIVE = "молнии",
		ACCUSATIVE = "молнию",
		INSTRUMENTAL = "молнией",
		PREPOSITIONAL = "молнии",
	)

/obj/projectile/magic/bitrunner_lightning/fire(setAngle)
	if(firer)
		lightning_chain = firer.Beam(src, icon_state = "lightning[rand(1, 12)]", icon = 'icons/effects/effects.dmi')
	return ..()

/obj/projectile/magic/bitrunner_lightning/on_hit(atom/target, blocked = 0)
	. = ..()
	var/list/shocked_targets = list()
	if(firer)
		shocked_targets[firer] = TRUE
	tesla_zap(src, zap_range = 15, power = 20000, cutoff = 1000, zap_flags = ZAP_MOB_DAMAGE, shocked_targets = shocked_targets)

/obj/projectile/magic/bitrunner_lightning/Destroy()
	QDEL_NULL(lightning_chain)
	return ..()
