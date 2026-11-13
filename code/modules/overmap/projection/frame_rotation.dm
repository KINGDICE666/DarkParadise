/obj/overmap/entity/proc/frame_facing()
	return shuttle ? get_facing() : 0

/obj/overmap/entity/proc/radar_facing()
	return free_flight_view ? get_facing() : 0

/obj/overmap/entity/station/ship/frame_facing()
	return get_facing()

/obj/overmap/entity/station/ship/radar_facing()
	return get_facing()

/datum/overmap_bubble/proc/frame_facing()
	return static_level && host ? host.frame_facing() : 0

/datum/overmap_bubble/proc/relative_facing(angle)
	return angle - frame_facing()

/datum/overmap_bubble/proc/relative_turns(obj/overmap/entity/vessel)
	return round(relative_facing(vessel.get_facing()) / 90, 1) * 90

/datum/overmap_bubble/proc/world_box(min_x, min_y, max_x, max_y)
	var/list/corners = list(to_world(min_x, min_y), to_world(min_x, max_y), to_world(max_x, min_y), to_world(max_x, max_y))
	var/list/first = corners[1]
	var/list/box = list(first[1], first[2], first[1], first[2])
	for(var/list/corner as anything in corners)
		box[1] = min(box[1], corner[1])
		box[2] = min(box[2], corner[2])
		box[3] = max(box[3], corner[1])
		box[4] = max(box[4], corner[2])
	return box

/datum/controller/subsystem/overmap/proc/frame_heading(datum/owner)
	var/obj/overmap/entity/vessel = owner
	if(istype(vessel))
		return vessel.get_facing()
	var/datum/overmap_bubble/bubble = owner
	return istype(bubble) ? bubble.frame_facing() : 0
