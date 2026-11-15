/mob/living/silicon/ai/attack_alien(mob/living/carbon/alien/humanoid/M)
	if(!SSticker)
		to_chat(M, "You cannot attack people before the game has started.")
		return
	..()

/mob/living/silicon/ai/attack_slime(mob/living/simple_animal/slime/user)
	return //immune to slimes

/mob/living/silicon/ai/adjust_slot_machine_lose_effect()
	if(prob(EMAGGED_SLOT_MACHINE_GIB_CHANCE))
		to_chat(src, span_warningbig("Критическая неудача!<br>Неизвестная сила заставляет вас отключиться."))
		src.death() // AI gib cause no body ghost error
		return TRUE
	to_chat(src, span_warning("Неудача! [src.name] получает видимые повреждения."))
	src.adjustBruteLoss(rand(15, 20))
	return FALSE

/mob/living/silicon/ai/adjustBruteLoss(amount = 0, updating_health = TRUE, def_zone = null, blocked = 0, forced = FALSE, used_weapon = null, sharp = FALSE, silent = FALSE, affect_robotic = TRUE,)
	. = ..()
	if(amount < 0)
		return
	if(!deployed_shell)
		return
	to_chat(deployed_shell, span_warningbig("ТРЕВОГА: ЗАФИКСИРОВАНО ПОВРЕЖДЕНИЕ ЯДРА"))
	SEND_SOUND(deployed_shell, 'sound/machines/engine_alert1.ogg')

/mob/living/silicon/ai/adjustFireLoss(amount, updating_health = TRUE, def_zone = null, blocked = 0, forced = FALSE, used_weapon = null, sharp = FALSE, silent = FALSE, affect_robotic = TRUE,)
	. = ..()
	if(amount < 0)
		return
	if(!deployed_shell)
		return
	to_chat(deployed_shell, span_warningbig("ТРЕВОГА: ЗАФИКСИРОВАНО ПОВРЕЖДЕНИЕ ЯДРА"))
	SEND_SOUND(deployed_shell, 'sound/machines/engine_alert1.ogg')

/mob/living/silicon/ai/emp_act(severity)
	. = ..()
	if(deployed_shell)
		disconnect_shell()

#define CORE_INTEGRITY_WARNING 50
#define CORE_INTEGRITY_CRITICAL 25
#define REMOTE_DAMAGE_REPORT_COOLDOWN (3 SECONDS)

/mob/living/silicon/ai/proc/get_integrity_percent()
	return clamp(round(health / maxHealth * 100), 0, 100)

/mob/living/silicon/ai/proc/show_remote_integrity(mob/living/remote_body)
	var/integrity = get_integrity_percent()
	var/severity = 1
	if(integrity <= CORE_INTEGRITY_CRITICAL)
		severity = 3
	else if(integrity <= CORE_INTEGRITY_WARNING)
		severity = 2

	var/atom/movable/screen/alert/integrity_alert = remote_body.throw_alert(ALERT_AI_CORE_INTEGRITY, /atom/movable/screen/alert/ai_core_integrity, severity)
	integrity_alert?.desc = "Урон удалённого тела передаётся ядру ИИ. Целостность ядра: [integrity]%. На нуле связь будет разорвана."

/mob/living/silicon/ai/proc/report_remote_damage(mob/living/remote_body, old_integrity)
	show_remote_integrity(remote_body)
	var/new_integrity = get_integrity_percent()
	for(var/threshold in list(CORE_INTEGRITY_CRITICAL, CORE_INTEGRITY_WARNING))
		if(old_integrity > threshold && new_integrity <= threshold)
			remote_body.playsound_local(get_turf(remote_body), 'sound/machines/terminal_alert.ogg', 50, TRUE)
			to_chat(remote_body, span_userdanger("Целостность ядра упала до [new_integrity]%! Отступите или ищите выход."))
			COOLDOWN_START(src, remote_damage_report, REMOTE_DAMAGE_REPORT_COOLDOWN)
			return

	if(!COOLDOWN_FINISHED(src, remote_damage_report))
		return

	COOLDOWN_START(src, remote_damage_report, REMOTE_DAMAGE_REPORT_COOLDOWN)
	to_chat(remote_body, span_warning("Ядро ИИ получает урон. Целостность ядра: [new_integrity]%."))

#undef CORE_INTEGRITY_WARNING
#undef CORE_INTEGRITY_CRITICAL
#undef REMOTE_DAMAGE_REPORT_COOLDOWN
