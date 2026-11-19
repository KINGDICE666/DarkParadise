#define HORIZON_JUMP_FLASH_TIME (2 SECONDS)

/obj/overmap/entity/proc/in_event_horizon()
	if(!horizon_seen_at || world.time - horizon_seen_at > OVERMAP_HORIZON_GRACE)
		return FALSE
	return in_free_flight() || (istype(src, /obj/overmap/entity/station/ship) && isturf(loc))

/obj/overmap/entity/proc/horizon_jump()
	if(horizon_jumping)
		return "Гиперпривод уже работает."
	if(!in_event_horizon())
		return "Корабль не находится за горизонтом событий."
	horizon_jumping = TRUE
	horizon_seen_at = null
	var/datum/overmap_sector/unknown = SSovermap.create_unknown_sector()
	var/turf/spot = unknown?.get_random_open_turf()
	horizon_jumping = FALSE
	if(QDELETED(src))
		return FALSE
	if(!spot)
		return "Гиперпривод не смог найти точку выхода."
	var/datum/overmap_sector/old_sector = sector
	speed[1] = 0
	speed[2] = 0
	move_to_sector(unknown, spot)
	log_game("Overmap vessel [name] jumped out of a black hole in [old_sector?.id] into [unknown.id].")
	play_shuttle_sound('sound/effects/hyperspace_end.ogg')
	for(var/mob/living/crew as anything in overmap_vessel_crew(src))
		crew.remove_status_effect(/datum/status_effect/event_horizon)
		crew.flash_eyes(visual = TRUE)
		shake_camera(crew, HORIZON_JUMP_FLASH_TIME, 3)
		to_chat(crew, span_boldnotice("Вспышка — и корабль выбрасывает в пространство, которого нет ни на одной карте."))
	announce_sensor_event("Слепой прыжок за горизонт событий: [get_overmap_display_name()] → «[unknown.name]»", "info")
	return TRUE

/datum/overmap_sector/wilderness/unknown
	name = "Неизвестный сектор"
	id = "unknown"
	parallax_stars = "stars_plasma"
	parallax_tint = list(1.8, 0.45, 0.85)
	engine_dampening = TRUE
	centcom_blackout = TRUE

/datum/controller/subsystem/overmap/proc/create_unknown_sector()
	if(unknown_sector)
		return unknown_sector
	if(unknown_sector_building)
		UNTIL(!unknown_sector_building)
		return unknown_sector
	unknown_sector_building = TRUE
	var/datum/overmap_sector/wilderness/unknown/sector = new("unknown", "Неизвестный сектор [pick("Ω", "Σ", "Ψ", "Ξ")]-[rand(100, 999)]")
	sectors[sector.id] = sector
	sector_order |= sector
	sector.populate_roundstart()
	unknown_sector = sector
	unknown_sector_building = FALSE
	bump_galaxy()
	return unknown_sector

/proc/centcom_blackout()
	return !!SSovermap?.station_entity?.sector?.centcom_blackout

/datum/status_effect/event_horizon
	id = "event_horizon"
	status_type = STATUS_EFFECT_REFRESH
	duration = OVERMAP_HORIZON_GRACE
	tick_interval = -1
	alert_type = null

/datum/status_effect/event_horizon/on_apply()
	owner.client?.colour_transition(COLOR_MATRIX_GRAYSCALE)
	return TRUE

/datum/status_effect/event_horizon/on_remove()
	owner.update_client_colour()

/mob/living/get_screen_colour()
	. = ..()
	if(!. && has_status_effect(/datum/status_effect/event_horizon))
		return COLOR_MATRIX_GRAYSCALE

#undef HORIZON_JUMP_FLASH_TIME
