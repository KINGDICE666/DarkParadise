/proc/station_is_ship()
	return SSmapping.map_datum?.station_ship

/obj/overmap/entity/station/ship
	movable = TRUE
	halted = FALSE
	wraparound = FALSE
	vessel_mass = OVERMAP_MASS_STATION
	max_speed = OVERMAP_FROM_DISPLAY(OVERMAP_TOP_SPEED_MAX)
	var/datum/overmap_bubble/home_space

/obj/overmap/entity/station/ship/Destroy()
	if(home_space?.anchor == src)
		home_space.anchor = null
	home_space = null
	if(SSovermap.station_entity == src)
		SSovermap.station_entity = null
	return ..()

/obj/overmap/entity/station/ship/add_overmap_components()
	. = ..()
	AddComponent(/datum/component/overmap_flight, TRUE)

/obj/overmap/entity/station/ship/in_free_flight()
	return status == OVERMAP_STATUS_OVERMAP && isturf(loc)

/obj/overmap/entity/station/ship/local_arrival_point(list/target, list/origin)
	return target

/obj/overmap/entity/station/ship/can_use_hyperrelays()
	return !EMERGENCY_ESCAPED_OR_ENDGAMED

/obj/overmap/entity/station/ship/finish_hyperrelay_jump(obj/overmap/entity/hyperrelay/from_relay)
	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		return
	. = ..()
	home_space?.sector = sector

/obj/overmap/entity/station/ship/proc/begin_centcom_jump()
	flight.release_pilot()
	flight.set_autopilot(FALSE)
	flight.stop_burn()
	jump_spool_end = 0
	jump_start_time = 0
	jump_origin = null
	jump_target = null
	speed[1] = 0
	speed[2] = 0
	halted = TRUE
	status = OVERMAP_STATUS_TRANSIT
	local_space = null
	start_hyperrelay_transit_fx()

/obj/overmap/entity/station/ship/proc/finish_centcom_jump(hijacked)
	var/site_id = hijacked ? OVERMAP_SITE_SYNDICATE : OVERMAP_SITE_CENTCOM
	var/obj/overmap/entity/service_site/destination = SSovermap.service_sites[site_id]
	var/turf/arrival = destination.sector.get_turf_near(destination.get_overmap_turf(), min_dist = 1, max_dist = 2)
	sector.remove_object(src)
	destination.sector.add_object(src, arrival)
	position = list(0, 0)
	home_space.sector = sector
	status = OVERMAP_STATUS_OVERMAP
	update_overmap_pixel()
	stop_hyperrelay_transit_fx()
	play_shuttle_sound('sound/effects/hyperspace_end.ogg')
	refresh_sensor_displays()

/obj/overmap/entity/station/ship/proc/station_listeners()
	. = list()
	for(var/mob/listener as anything in GLOB.player_list)
		var/turf/spot = get_turf(listener)
		if(spot && is_station_level(spot.z))
			. += listener

/obj/overmap/entity/station/ship/play_shuttle_sound(soundfile, volume = 100)
	if(!soundfile)
		return
	var/sound/clip = sound(soundfile)
	clip.volume = volume
	for(var/mob/listener as anything in station_listeners())
		SEND_SOUND(listener, clip)

/obj/overmap/entity/station/ship/shuttle_visible_message(text)
	for(var/mob/listener as anything in station_listeners())
		if(listener.stat != DEAD || isobserver(listener))
			to_chat(listener, text)

/obj/overmap/entity/station/ship/shake_shuttle(duration, strength)
	for(var/mob/living/listener in station_listeners())
		shake_camera(listener, duration, strength)

/obj/overmap/entity/station/ship/flicker_shuttle_lights()
	for(var/area/place as anything in SSmapping.existing_station_areas)
		for(var/obj/machinery/light/lamp in place)
			if(prob(30))
				lamp.flicker(rand(6, 10))

/obj/overmap/entity/station/ship/refresh_shuttle_parallax()
	for(var/mob/listener as anything in station_listeners())
		listener.update_parallax_contents()

/obj/overmap/entity/station/ship/set_shuttle_hyperspace_visuals(enabled)
	for(var/area/place as anything in SSmapping.existing_station_areas)
		place.parallax_movedir = enabled ? NORTH : NONE
	refresh_shuttle_parallax()
