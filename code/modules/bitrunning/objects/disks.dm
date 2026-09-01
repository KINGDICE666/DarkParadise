/obj/item/disk/bitrunning
	name = "bitrunning program"
	desc = "Диск с исходным кодом. Его нужно принести с собой в нетпод."
	abstract_type = /obj/item/disk/bitrunning
	var/choice_made
	var/list/selectable
	var/selected_path

/obj/item/disk/bitrunning/Initialize(mapload)
	. = ..()
	icon_state = "datadisk[rand(0, 6)]"
	AddComponent(/datum/component/loads_avatar_gear, CALLBACK(src, PROC_REF(load_onto_avatar)))

/obj/item/disk/bitrunning/get_ru_names()
	return alist(
		NOMINATIVE = "программа битраннера",
		GENITIVE = "программы битраннера",
		DATIVE = "программе битраннера",
		ACCUSATIVE = "программу битраннера",
		INSTRUMENTAL = "программой битраннера",
		PREPOSITIONAL = "программе битраннера",
	)

/obj/item/disk/bitrunning/examine(mob/user)
	. = ..()
	if(isnull(choice_made))
		. += span_notice("Запись ещё не выбрана. Активируйте диск в руке.")
		return

	. += span_notice("Записано: <b>[choice_made]</b>. Перезаписать нельзя.")

/obj/item/disk/bitrunning/attack_self(mob/user)
	if(choice_made)
		balloon_alert(user, "диск уже записан!")
		return

	var/choice = tgui_input_list(user, "Что записать на диск?", "Программа битраннера", selectable)
	if(isnull(choice) || !user.is_in_hands(src))
		return

	selected_path = selectable[choice]
	choice_made = choice
	balloon_alert(user, "записано")
	playsound(user, 'sound/items/pshoom.ogg', 30, TRUE)

/obj/item/disk/bitrunning/proc/load_onto_avatar(mob/living/carbon/human/pilot, mob/living/carbon/human/avatar, domain_flags)
	return NONE

/obj/item/disk/bitrunning/item
	abstract_type = /obj/item/disk/bitrunning/item
	desc = "Диск с исходным кодом. Подгружает предмет в виртуальный домен."

/obj/item/disk/bitrunning/item/load_onto_avatar(mob/living/carbon/human/pilot, mob/living/carbon/human/avatar, domain_flags)
	if(domain_flags & DOMAIN_FORBIDS_ITEMS)
		return BITRUNNER_GEAR_LOAD_BLOCKED

	if(isnull(selected_path))
		return BITRUNNER_GEAR_LOAD_FAILED

	avatar.put_in_hands(new selected_path(avatar.loc))
	return NONE

/obj/item/disk/bitrunning/item/tier1
	name = "bitrunning program: simple gear"
	selectable = list(
		"Медицинский луч" = /obj/item/gun/medbeam,
		"Заряд C-4" = /obj/item/grenade/plastic/c4,
		"Резонатор" = /obj/item/resonator,
	)

/obj/item/disk/bitrunning/item/tier2
	name = "bitrunning program: complex gear"
	selectable = list(
		"Люксовый медипен" = /obj/item/reagent_containers/hypospray/autoinjector/survival/luxury,
		"Пистолет" = /obj/item/gun/projectile/automatic/pistol,
		"Бронежилет" = /obj/item/clothing/suit/armor/vest,
	)

/obj/item/disk/bitrunning/item/tier3
	name = "bitrunning program: advanced gear"
	selectable = list(
		"Ядерный энергопистолет" = /obj/item/gun/energy/gun/nuclear,
		"Двойной энергомеч" = /obj/item/twohanded/dualsaber,
		"Синди-минибомба" = /obj/item/grenade/syndieminibomb,
	)

/obj/item/disk/bitrunning/ability
	abstract_type = /obj/item/disk/bitrunning/ability
	desc = "Диск с исходным кодом. Подгружает способность в виртуальный домен. Повторные способности игнорируются."

/obj/item/disk/bitrunning/ability/load_onto_avatar(mob/living/carbon/human/pilot, mob/living/carbon/human/avatar, domain_flags)
	if(domain_flags & DOMAIN_FORBIDS_ABILITIES)
		return BITRUNNER_GEAR_LOAD_BLOCKED

	if(isnull(selected_path))
		return BITRUNNER_GEAR_LOAD_FAILED

	if(locate(selected_path) in avatar.mob_spell_list)
		return BITRUNNER_GEAR_LOAD_FAILED

	avatar.AddSpell(new selected_path)
	return NONE

/obj/item/disk/bitrunning/ability/tier1
	name = "bitrunning program: basic abilities"
	selectable = list(
		"Мигание" = /obj/effect/proc_holder/spell/turf_teleport/blink,
		"Целительное касание" = /obj/effect/proc_holder/spell/touch/healtouch,
	)

/obj/item/disk/bitrunning/ability/tier2
	name = "bitrunning program: complex abilities"
	selectable = list(
		"Огненный шар" = /obj/effect/proc_holder/spell/fireball,
		"Силовая стена" = /obj/effect/proc_holder/spell/forcewall,
		"Волшебная ракета" = /obj/effect/proc_holder/spell/projectile/magic_missile,
	)

/obj/item/disk/bitrunning/ability/tier3
	name = "bitrunning program: elite abilities"
	selectable = list(
		"Молния" = /obj/effect/proc_holder/spell/charge_up/bounce/lightning,
		"Остановка времени" = /obj/effect/proc_holder/spell/aoe/conjure/timestop,
	)
