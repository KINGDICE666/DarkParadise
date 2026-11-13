/obj/machinery/computer/helm/proc/fire_target()
	var/obj/overmap/entity/target = locateUID(fire_target_uid)
	if(!istype(target) || QDELETED(target) || target == vessel || target.sector != vessel?.sector || !isturf(target.loc))
		fire_target_uid = null
		return null
	return target

/obj/machinery/computer/helm/proc/weapon_shot_speed(obj/gun)
	var/obj/machinery/ship_gun/cannon = gun
	if(istype(cannon))
		var/obj/projectile/shot_type = cannon.projectile_type
		return shot_type::overmap_velocity
	if(istype(gun, /obj/machinery/bsa))
		return /obj/projectile/bullet/ship_artillery::overmap_velocity
	return /obj/projectile::overmap_velocity

/obj/machinery/computer/helm/proc/fire_solution(obj/gun, obj/overmap/entity/target)
	var/list/data = list()
	if(!SEND_SIGNAL(gun, COMSIG_OVERMAP_WEAPON_QUERY, vessel, data) || !data["position"])
		return null
	var/list/origin = data["position"]
	var/target_x = target.get_world_x()
	var/target_y = target.get_world_y()
	var/obj/overmap/entity/carrier = vessel.docked_ship || vessel
	var/relative_x = (target.speed[1] - carrier.speed[1]) * OVERMAP_TILE_SPAN
	var/relative_y = (target.speed[2] - carrier.speed[2]) * OVERMAP_TILE_SPAN
	var/shot_speed = max(weapon_shot_speed(gun) / (1 SECONDS), 0.01)
	var/aim_x = target_x
	var/aim_y = target_y
	for(var/pass in 1 to OVERMAP_FIRE_SOLUTION_PASSES)
		var/travel = sqrt((aim_x - origin[1]) ** 2 + (aim_y - origin[2]) ** 2) / shot_speed
		aim_x = target_x + relative_x * travel
		aim_y = target_y + relative_y * travel
	return list(aim_x, aim_y)

/obj/machinery/computer/helm/proc/forward_aim(obj/gun)
	var/list/data = list()
	if(!SEND_SIGNAL(gun, COMSIG_OVERMAP_WEAPON_QUERY, vessel, data) || !data["position"])
		return null
	var/list/origin = data["position"]
	var/reach = OVERMAP_TILE_SPAN * (vessel.sector?.tile_travel || 1) * OVERMAP_FORWARD_FIRE_CELLS
	return list(origin[1] + sin(data["heading"]) * reach, origin[2] + cos(data["heading"]) * reach)

/obj/machinery/computer/helm/proc/fire_salvo(mob/user, list/point)
	var/obj/overmap/entity/target = fire_target()
	. = FALSE
	for(var/id in selected_weapons)
		var/obj/gun = locateUID(id)
		if(QDELETED(gun))
			continue
		var/list/aim = target ? fire_solution(gun, target) : (point || forward_aim(gun))
		if(!aim || !SEND_SIGNAL(gun, COMSIG_OVERMAP_WEAPON_CAN_AIM, vessel, aim[1], aim[2]))
			continue
		if(SEND_SIGNAL(gun, COMSIG_OVERMAP_WEAPON_FIRE, vessel, aim[1], aim[2], user))
			. = TRUE

/obj/machinery/computer/helm/proc/fire_control_data(list/data)
	var/obj/overmap/entity/target = vessel && fire_target()
	data["free_fire"] = free_fire
	data["fire_target"] = null
	if(target)
		var/span = OVERMAP_TILE_SPAN * (vessel.sector?.tile_travel || 1)
		data["fire_target"] = list(
			"id" = target.UID(),
			"name" = target.get_overmap_display_name(),
			"distance" = round(sqrt((target.get_world_x() - vessel.get_world_x()) ** 2 + (target.get_world_y() - vessel.get_world_y()) ** 2) / span, 0.1),
			"speed" = round(OVERMAP_DISPLAY_SPEED(target.get_speed()), 0.1),
			"shield" = target.shield_fraction(),
		)
	for(var/list/entry as anything in data["weapons"])
		var/obj/gun = locateUID(entry["id"])
		if(QDELETED(gun))
			continue
		entry["name"] = DECLENT_RU_CAP(gun, NOMINATIVE)
		var/obj/machinery/ship_gun/cannon = gun
		entry["cooldown_max"] = istype(cannon) ? cannon.fire_delay / (1 SECONDS) : 1
		entry["ready"] = entry["cooldown"] <= 0 && (!istype(cannon) || cannon.can_fire())
		entry["kind"] = istype(cannon) ? cannon.weapon_kind : (istype(gun, /obj/machinery/porta_turret) ? "turret" : "artillery")
		var/list/aim = target && fire_solution(gun, target)
		entry["in_arc"] = aim ? !!SEND_SIGNAL(gun, COMSIG_OVERMAP_WEAPON_CAN_AIM, vessel, aim[1], aim[2]) : null

/obj/machinery/computer/helm/process()
	. = ..()
	if(free_fire && vessel && length(selected_weapons) && !(stat & (NOPOWER|BROKEN)) && !vessel.is_programmed_locked() && fire_target())
		fire_salvo(null)

/obj/machinery/computer/helm/proc/fire_control_act(action, list/params, mob/user)
	switch(action)
		if("lock_target", "set_dest")
			var/obj/overmap/entity/target = locateUID(params["id"])
			if(!istype(target) || target == vessel || target.sector != vessel.sector)
				return TRUE
			fire_target_uid = target.UID()
			playsound(src, 'sound/machines/terminal_select.ogg', 30, TRUE)
		if("clear_target")
			fire_target_uid = null
		if("fire_salvo")
			var/point_x = text2num(params["x"])
			var/point_y = text2num(params["y"])
			if(!fire_salvo(user, isnum(point_x) && isnum(point_y) ? list(point_x, point_y) : null))
				to_chat(user, span_warning("Нет готовых орудий, способных достать цель."))
		if("toggle_free_fire")
			free_fire = !free_fire
			log_game("[key_name(user)] [free_fire ? "enabled" : "disabled"] free fire on [vessel.get_overmap_display_name()].")
	return TRUE
