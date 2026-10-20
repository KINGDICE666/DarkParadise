///AI Upgrades

//Malf Picker
/obj/item/malf_upgrade
	name = "combat software upgrade"
	desc = "A highly illegal, highly dangerous upgrade for artificial intelligence units, granting them a variety of powers as well as the ability to hack APCs."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"

/obj/item/malf_upgrade/afterattack(atom/target, mob/user, proximity_flag, list/modifiers, status)
	var/mob/living/silicon/ai/ai_target = target

	if(!istype(ai_target))
		return

	if(ai_target.malf_picker)
		ai_target.malf_picker.processing_time += 50
		to_chat(ai_target, span_userdanger("[user] has attempted to upgrade you with combat software that you already possess. You gain 50 points to spend on Malfunction Modules instead."))
	else
		to_chat(ai_target, span_userdanger("[user] has upgraded you with combat software!"))
		ai_target.add_malf_picker()
	to_chat(user, span_notice("You upgrade [ai_target]. [src] is consumed in the process."))
	qdel(src)

//Lipreading
/obj/item/surveillance_upgrade
	name = "surveillance software upgrade"
	desc = "A software package that will allow an artificial intelligence to 'hear' from its cameras via lip reading."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"

/obj/item/surveillance_upgrade/afterattack(atom/target, mob/user, proximity_flag, list/modifiers, status)
	var/mob/living/silicon/ai/ai_target = target

	if(!istype(ai_target))
		return

	if(ai_target.eyeobj)
		ai_target.eyeobj.relay_speech = 1
		to_chat(ai_target, span_userdanger("[user] has upgraded you with surveillance software!"))
		to_chat(ai_target, "Via a combination of hidden microphones and lip reading software, you are able to use your cameras to listen in on conversations.")
	to_chat(user, span_notice("You upgrade [ai_target]. [src] is consumed in the process."))
	qdel(src)

/obj/item/ai_upgrade
	name = "parent ai upgrade"
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"
	item_state = "card-id"
	drop_sound = 'sound/items/handling/disk_drop.ogg'
	pickup_sound = 'sound/items/handling/disk_pickup.ogg'
	w_class = WEIGHT_CLASS_TINY

/obj/item/ai_upgrade/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(isAI(interacting_with))
		ai_upgrade_action(interacting_with, user)
		return ITEM_INTERACT_SUCCESS
	return NONE

/obj/item/ai_upgrade/proc/ai_upgrade_action(mob/living/silicon/ai/AI, mob/user)
	return

/obj/item/ai_upgrade/ai_program_reset
	name = "Program Reset Disk"
	desc = "Вставьте этот диск в ядро ИИ, чтобы полностью сбросить его программы."

/obj/item/ai_upgrade/ai_program_reset/get_ru_names()
	return alist(
		NOMINATIVE = "диск сброса программ",
		GENITIVE = "диска сброса программ",
		DATIVE = "диску сброса программ",
		ACCUSATIVE = "диск сброса программ",
		INSTRUMENTAL = "диском сброса программ",
		PREPOSITIONAL = "диске сброса программ",
	)

/obj/item/ai_upgrade/ai_program_reset/ai_upgrade_action(mob/living/silicon/ai/AI, mob/user)
	if(!istype(AI))
		return
	to_chat(user, span_notice("Вы сбрасываете программы ИИ [AI] до заводских настроек."))
	AI.reset_programs()

/obj/item/ai_upgrade/expanded_storage
	name = "expanded storage upgrade"
	desc = "Экспериментальное улучшение с маркировкой EX.ST. Содержит алгоритм сжатия процессов ИИ, освобождающий дополнительную память."

/obj/item/ai_upgrade/expanded_storage/get_ru_names()
	return alist(
		NOMINATIVE = "улучшение расширенного хранилища",
		GENITIVE = "улучшения расширенного хранилища",
		DATIVE = "улучшению расширенного хранилища",
		ACCUSATIVE = "улучшение расширенного хранилища",
		INSTRUMENTAL = "улучшением расширенного хранилища",
		PREPOSITIONAL = "улучшении расширенного хранилища",
	)

/obj/item/ai_upgrade/expanded_storage/ai_upgrade_action(mob/living/silicon/ai/AI, mob/user)
	if(!istype(AI))
		return
	to_chat(AI, span_notice("[user] устанавлива[PLUR_ET_YUT(user)] вам модуль расширенного хранилища. Получена дополнительная память!"))
	AI.program_picker.total_memory += 2
	AI.program_picker.memory += 2
	to_chat(user, span_notice("Вы улучшаете ИИ [AI]. [DECLENT_RU_CAP(src, NOMINATIVE)] расходуется."))
	qdel(src)

/obj/item/ai_upgrade/expanded_network
	name = "expanded network array upgrade"
	desc = "Экспериментальное улучшение с маркировкой EX.AR. Содержит алгоритм оптимизации сети ИИ, освобождающий дополнительную пропускную способность."

/obj/item/ai_upgrade/expanded_network/get_ru_names()
	return alist(
		NOMINATIVE = "улучшение сетевого массива",
		GENITIVE = "улучшения сетевого массива",
		DATIVE = "улучшению сетевого массива",
		ACCUSATIVE = "улучшение сетевого массива",
		INSTRUMENTAL = "улучшением сетевого массива",
		PREPOSITIONAL = "улучшении сетевого массива",
	)

/obj/item/ai_upgrade/expanded_network/ai_upgrade_action(mob/living/silicon/ai/AI, mob/user)
	if(!istype(AI))
		return
	to_chat(AI, span_notice("[user] устанавлива[PLUR_ET_YUT(user)] вам модуль расширенного сетевого массива. Получена дополнительная пропускная способность!"))
	AI.program_picker.total_bandwidth += 1
	AI.program_picker.bandwidth += 1
	to_chat(user, span_notice("Вы улучшаете ИИ [AI]. [DECLENT_RU_CAP(src, NOMINATIVE)] расходуется."))
	qdel(src)

/obj/item/ai_upgrade/expanded_tank
	name = "expanded nanite tank upgrade"
	desc = "Экспериментальное улучшение с маркировкой NA.TA. Содержит программу блюспейс-сжатия, немного увеличивающую запас нанитов ИИ."

/obj/item/ai_upgrade/expanded_tank/get_ru_names()
	return alist(
		NOMINATIVE = "улучшение нанитового резервуара",
		GENITIVE = "улучшения нанитового резервуара",
		DATIVE = "улучшению нанитового резервуара",
		ACCUSATIVE = "улучшение нанитового резервуара",
		INSTRUMENTAL = "улучшением нанитового резервуара",
		PREPOSITIONAL = "улучшении нанитового резервуара",
	)

/obj/item/ai_upgrade/expanded_tank/ai_upgrade_action(mob/living/silicon/ai/AI, mob/user)
	if(!istype(AI))
		return
	to_chat(AI, span_notice("[user] устанавлива[PLUR_ET_YUT(user)] вам модуль расширенного нанитового резервуара. Запас нанитов увеличен!"))
	AI.program_picker.max_nanites += 10
	to_chat(user, span_notice("Вы улучшаете ИИ [AI]. [DECLENT_RU_CAP(src, NOMINATIVE)] расходуется."))
	qdel(src)

/obj/item/ai_upgrade/expanded_fabricator
	name = "expanded nanite fabricator upgrade"
	desc = "Экспериментальное улучшение с маркировкой NA.FA. Содержит программу оптимизации нанитовых фабрикаторов ИИ, ускоряющую производство нанитов."

/obj/item/ai_upgrade/expanded_fabricator/get_ru_names()
	return alist(
		NOMINATIVE = "улучшение нанитового фабрикатора",
		GENITIVE = "улучшения нанитового фабрикатора",
		DATIVE = "улучшению нанитового фабрикатора",
		ACCUSATIVE = "улучшение нанитового фабрикатора",
		INSTRUMENTAL = "улучшением нанитового фабрикатора",
		PREPOSITIONAL = "улучшении нанитового фабрикатора",
	)

/obj/item/ai_upgrade/expanded_fabricator/ai_upgrade_action(mob/living/silicon/ai/AI, mob/user)
	if(!istype(AI))
		return
	to_chat(AI, span_notice("[user] устанавлива[PLUR_ET_YUT(user)] вам модуль расширенного нанитового фабрикатора. Производство нанитов ускорено!"))
	AI.nanite_regen += 0.5
	to_chat(user, span_notice("Вы улучшаете ИИ [AI]. [DECLENT_RU_CAP(src, NOMINATIVE)] расходуется."))
	qdel(src)
