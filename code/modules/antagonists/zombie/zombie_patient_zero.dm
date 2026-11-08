/datum/antagonist/zombie_patient_zero
	name = "Patient Zero"
	roundend_category = "Нулевыми пациентами"
	antag_menu_name = "Нулевой пациент"
	job_rank = ROLE_ZOMBIE
	special_role = SPECIAL_ROLE_ZOMBIE_PATIENT_ZERO
	antag_hud_type = ANTAG_HUD_ZOMBIE
	antag_hud_name = "hudzombie"
	clown_gain_text = "Что-то гниёт в вашей крови, и вам уже не до шуток."
	clown_removal_text = "Вы снова чувствуете себя смешнее."
	stinger_sound = 'sound/ambience/antag/zomboidalert.ogg'

/datum/antagonist/zombie_patient_zero/on_gain()
	. = ..()
	if(!.)
		return
	owner.AddSpell(new /datum/action/cooldown/spell/zombie_turn)

/datum/antagonist/zombie_patient_zero/Destroy(force)
	owner?.RemoveSpell(/datum/action/cooldown/spell/zombie_turn)
	return ..()

/datum/antagonist/zombie_patient_zero/add_owner_to_gamemode()
	SSticker.mode.zombie_patient_zeros |= owner

/datum/antagonist/zombie_patient_zero/remove_owner_from_gamemode()
	SSticker.mode?.zombie_patient_zeros -= owner

/datum/antagonist/zombie_patient_zero/greet()
	var/list/messages = list()
	messages.Add(span_zombie_userdanger("Вы — нулевой пациент!"))
	messages.Add(span_zombie("В вашей крови дремлет некротическая чума. Пока она спит, вы ничем не отличаетесь от остального экипажа, но стоит дать ей волю — и вы станете первым зомби на станции."))
	return messages

/datum/antagonist/zombie_patient_zero/finalize_antag()
	return "<br>[span_notice("Выберите удачный момент и нажмите «Обратиться». Обращение мгновенно и необратимо, а заразой от вас начнётся эпидемия.")]"

/datum/antagonist/zombie_patient_zero/give_objectives()
	add_objective(/datum/objective/zombie_outbreak)

/datum/antagonist/zombie_patient_zero/roundend_report_details()
	return list("Обращено в зомби: [count_outbreak_zombies()]")

/proc/count_outbreak_zombies()
	if(!SSticker.mode)
		return 0
	return length(SSticker.mode.zombies - SSticker.mode.zombie_patient_zeros)

/datum/objective/zombie_outbreak
	antag_menu_name = "Начать эпидемию"
	explanation_text = "Обратитесь в зомби, когда сочтёте нужным, и заразите как можно больше членов экипажа."
	needs_target = FALSE

/datum/objective/zombie_outbreak/check_completion()
	return count_outbreak_zombies() > 0

/datum/action/cooldown/spell/zombie_turn
	name = "Обратиться"
	desc = "Дать дремлющей чуме вырваться наружу и обратиться в зомби. Пути назад не будет."
	button_icon_state = "vampire_disease"
	background_icon_state = "bg_vampire"
	spell_requirements = SPELL_REQUIRES_HUMAN
	antimagic_flags = NONE
	cooldown_time = 2 SECONDS

/datum/action/cooldown/spell/zombie_turn/cast(atom/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(confirm_turn))

/datum/action/cooldown/spell/zombie_turn/proc/confirm_turn()
	if(tgui_alert(owner, "Обратиться в зомби? Пути назад не будет.", name, list("Да", "Нет")) != "Да")
		return
	if(QDELETED(src) || !ishuman(owner))
		return
	var/mob/living/carbon/human/patient = owner
	if(patient.stat == DEAD)
		return

	var/datum/disease/virus/zombie/infection = locate() in patient.diseases
	if(!infection)
		var/datum/disease/virus/zombie/zombie_virus = new
		infection = zombie_virus.Contract(patient)
	if(!infection)
		to_chat(patient, span_warning("Чума не может прижиться в этом теле."))
		return

	patient.visible_message(span_danger("Кожа [patient.declent_ru(GENITIVE)] темнеет и лопается, а из горла вырывается нечеловеческий вой!"), span_zombielarge("Голод... Мозги..."))
	playsound(patient, 'sound/voice/zombie_scream.ogg', 75, TRUE)
	if(!infection.turn_instantly())
		return
	log_game("[key_name(patient)] has turned into a zombie as patient zero.")
	patient.mind?.RemoveSpell(type)
