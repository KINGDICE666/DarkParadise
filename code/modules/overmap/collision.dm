#define OVERMAP_RAM_RESTITUTION 0.3
#define OVERMAP_RAM_PUSH_OUT 0.5
#define OVERMAP_RAM_LIGHT_SPEED 2
#define OVERMAP_RAM_HEAVY_SPEED 6
#define OVERMAP_RAM_DEVASTATING_SPEED 12
#define OVERMAP_RAM_KNOCKDOWN_SPEED 3
#define OVERMAP_RAM_MAX_BLASTS 3
#define OVERMAP_RAM_MAX_THROW 4
#define OVERMAP_RAM_DAMAGE_COOLDOWN (1 SECONDS)

/obj/overmap/entity/proc/remember_pose()
	last_world_x = get_world_x()
	last_world_y = get_world_y()
	last_facing = get_facing()

/obj/overmap/entity/proc/restore_pose()
	flight.angular_velocity = 0
	flight.set_facing(last_facing)
	set_world_position(last_world_x, last_world_y)

/obj/overmap/entity/proc/push_out(normal_x, normal_y)
	flight.angular_velocity = 0
	set_world_position(get_world_x() + normal_x * OVERMAP_RAM_PUSH_OUT, get_world_y() + normal_y * OVERMAP_RAM_PUSH_OUT)

/obj/overmap/entity/proc/contacts_with_ship(obj/overmap/entity/other)
	. = list()
	for(var/turf/hull_turf as anything in hull_turfs)
		var/list/spot = hull_to_world(hull_turf.x, hull_turf.y)
		var/turf/other_turf = other.hull_turf_at(spot[1], spot[2])
		if(other_turf)
			. += list(list(hull_turf, other_turf, spot))

/obj/overmap/entity/proc/contacts_with_space(datum/overmap_bubble/space)
	. = list()
	for(var/turf/hull_turf as anything in hull_turfs)
		var/list/spot = hull_to_world(hull_turf.x, hull_turf.y)
		var/turf/space_turf = space.turf_at(spot[1], spot[2])
		if(space_turf && (!isspaceturf(space_turf) || space_turf.is_blocked_turf(exclude_mobs = TRUE)))
			. += list(list(hull_turf, space_turf, spot))

/obj/overmap/entity/proc/collide(list/contacts, obj/overmap/entity/other)
	var/contact_x = 0
	var/contact_y = 0
	for(var/list/contact as anything in contacts)
		var/list/spot = contact[3]
		contact_x += spot[1]
		contact_y += spot[2]
	contact_x /= length(contacts)
	contact_y /= length(contacts)
	var/normal_x = get_world_x() - contact_x
	var/normal_y = get_world_y() - contact_y
	var/normal_length = sqrt(normal_x ** 2 + normal_y ** 2)
	if(!normal_length)
		normal_x = -speed[1]
		normal_y = -speed[2]
		normal_length = sqrt(normal_x ** 2 + normal_y ** 2) || 1
	normal_x /= normal_length
	normal_y /= normal_length
	var/relative_x = speed[1] - (other ? other.speed[1] : 0)
	var/relative_y = speed[2] - (other ? other.speed[2] : 0)
	var/approach = relative_x * normal_x + relative_y * normal_y
	if(approach >= 0)
		push_out(normal_x, normal_y)
		other?.push_out(-normal_x, -normal_y)
		return
	restore_pose()
	other?.restore_pose()
	var/impact_speed = -approach * OVERMAP_TILE_SPAN * (1 SECONDS)
	var/inverse_mass = 1 / max(total_mass(), 1) + (other ? 1 / max(other.total_mass(), 1) : 0)
	var/impulse = (1 + OVERMAP_RAM_RESTITUTION) * approach / inverse_mass
	speed[1] -= impulse / max(total_mass(), 1) * normal_x
	speed[2] -= impulse / max(total_mass(), 1) * normal_y
	if(other)
		other.speed[1] += impulse / max(other.total_mass(), 1) * normal_x
		other.speed[2] += impulse / max(other.total_mass(), 1) * normal_y
	if(impact_speed < OVERMAP_RAM_LIGHT_SPEED || world.time < next_ram_damage)
		return
	next_ram_damage = world.time + OVERMAP_RAM_DAMAGE_COOLDOWN
	if(other)
		other.next_ram_damage = next_ram_damage
	log_game("Overmap collision: [get_overmap_display_name()] hit [other ? other.get_overmap_display_name() : "station structures"] at [round(impact_speed, 0.1)] m/s")
	ram_damage(contacts, impact_speed)
	feel_impact(impact_speed, -normal_x, -normal_y)
	other?.feel_impact(impact_speed, normal_x, normal_y)

/obj/overmap/entity/proc/ram_damage(list/contacts, impact_speed)
	var/devastation = impact_speed >= OVERMAP_RAM_DEVASTATING_SPEED ? 1 : 0
	var/heavy = impact_speed >= OVERMAP_RAM_HEAVY_SPEED ? 1 : 0
	var/light = 1 + devastation + heavy
	var/blasts = 0
	for(var/list/contact as anything in shuffle(contacts.Copy()))
		if(++blasts > OVERMAP_RAM_MAX_BLASTS)
			break
		for(var/turf/struck as anything in list(contact[1], contact[2]))
			explosion(struck, devastation, heavy, light, 0, adminlog = FALSE, cause = "overmap collision")

/obj/overmap/entity/proc/feel_impact(impact_speed, push_x, push_y)
	play_shuttle_sound('sound/effects/meteorimpact.ogg')
	shake_shuttle(min(impact_speed, 10), clamp(round(impact_speed / OVERMAP_RAM_HEAVY_SPEED), 1, 3))
	if(impact_speed < OVERMAP_RAM_KNOCKDOWN_SPEED)
		return
	var/facing = get_facing()
	var/throw_dir = angle2dir(delta_to_angle(push_x * cos(facing) - push_y * sin(facing), push_x * sin(facing) + push_y * cos(facing)))
	var/throw_range = clamp(round(impact_speed / OVERMAP_RAM_KNOCKDOWN_SPEED), 1, OVERMAP_RAM_MAX_THROW)
	for(var/area/place as anything in shuttle.shuttle_areas)
		for(var/mob/living/passenger in place)
			if(passenger.buckled)
				continue
			passenger.Knockdown(2 SECONDS)
			passenger.throw_at(get_ranged_target_turf(passenger, throw_dir, throw_range), throw_range, 1)

/datum/controller/subsystem/overmap/proc/process_collisions(list/flying)
	for(var/obj/overmap/entity/vessel as anything in flying)
		if(vessel.local_space && !vessel.docked_ship)
			var/list/station_contacts = vessel.contacts_with_space(vessel.local_space)
			if(length(station_contacts))
				vessel.collide(station_contacts)
	for(var/index in 1 to length(flying))
		var/obj/overmap/entity/vessel = flying[index]
		for(var/other_index in index + 1 to length(flying))
			var/obj/overmap/entity/other = flying[other_index]
			if(other.sector != vessel.sector || vessel.docked_ship == other || other.docked_ship == vessel)
				continue
			if(sqrt((vessel.get_world_x() - other.get_world_x()) ** 2 + (vessel.get_world_y() - other.get_world_y()) ** 2) > vessel.hull_radius + other.hull_radius)
				continue
			var/list/contacts = vessel.contacts_with_ship(other)
			if(length(contacts))
				vessel.collide(contacts, other)
	for(var/obj/overmap/entity/vessel as anything in flying)
		vessel.remember_pose()

/obj/projectile/proc/cross_frames(angle_offset)
	set_angle(SIMPLIFY_DEGREES(Angle + angle_offset))

#undef OVERMAP_RAM_RESTITUTION
#undef OVERMAP_RAM_PUSH_OUT
#undef OVERMAP_RAM_LIGHT_SPEED
#undef OVERMAP_RAM_HEAVY_SPEED
#undef OVERMAP_RAM_DEVASTATING_SPEED
#undef OVERMAP_RAM_KNOCKDOWN_SPEED
#undef OVERMAP_RAM_MAX_BLASTS
#undef OVERMAP_RAM_MAX_THROW
#undef OVERMAP_RAM_DAMAGE_COOLDOWN
