#define CHRONO_ARRIVAL_RANDOM "Случайное место на станции"
#define CHRONO_ARRIVAL_ADMIN "Моё местоположение"

/client/proc/send_chrono_legionnaire()
	if(!SSticker)
		tgui_alert(src, "Игра ещё не началась!")
		return

	if(tgui_alert(src, "Вы хотите отправить хронолегионера на станцию?", "Подтверждение", list("Да", "Нет")) != "Да")
		return

	var/arrival_choice = tgui_alert(src, "Где появится хронолегионер?", "Место прибытия", list(CHRONO_ARRIVAL_RANDOM, CHRONO_ARRIVAL_ADMIN))
	if(!arrival_choice)
		return

	var/mission = tgui_input_text(src, "Укажите миссию хронолегионера.", "Укажите миссию", "Сотрите из временного потока тех, кто угрожает ходу истории.", encode = FALSE)
	if(!mission)
		return

	var/list/candidates = pick_candidates_all_types(src, 1, "Вы хотите сыграть за хронолегионера?", role_cleanname = "хронолегионер", reason = mission)
	if(!length(candidates))
		to_chat(src, span_warning("Никто не согласился."))
		return

	var/turf/arrival_turf = arrival_choice == CHRONO_ARRIVAL_ADMIN ? get_turf(mob) : get_safe_random_station_turf()
	if(!arrival_turf)
		to_chat(src, span_warning("Не удалось найти место прибытия."))
		return

	var/mob/candidate = pick(candidates)
	var/mob/living/carbon/human/legionnaire = new(arrival_turf)
	var/datum/preferences/appearance = new()
	appearance.write_preference(GLOB.preference_entries[/datum/preference/name/real_name], random_name(pick(MALE, FEMALE)))
	appearance.apply_prefs_to(legionnaire)
	legionnaire.dna.ready_dna(legionnaire)

	legionnaire.mind_initialize()
	legionnaire.mind.assigned_role = SPECIAL_ROLE_EVENTMISC
	legionnaire.mind.offstation_role = TRUE
	legionnaire.mind.add_antag_datum(/datum/antagonist/eventmisc)
	legionnaire.possess_by_player(candidate.key)
	legionnaire.equipOutfit(/datum/outfit/admin/chrono)

	to_chat(legionnaire, "<br>[span_danger("<b>[mission]</b>")]")
	legionnaire.mind.store_memory("<b>[mission]</b><br><br>")

	new /obj/effect/temp_visual/circle_wave/chrono(arrival_turf)
	playsound(arrival_turf, 'sound/magic/teleport_app.ogg', 50, TRUE)

	log_and_message_admins("sent a Chrono Legionnaire ([key_name_admin(legionnaire)]) to [ADMIN_VERBOSEJMP(arrival_turf)].")
	return TRUE

#undef CHRONO_ARRIVAL_RANDOM
#undef CHRONO_ARRIVAL_ADMIN
