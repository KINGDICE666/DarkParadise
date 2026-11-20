#define SENSOR_PASSIVE_RANGE 9
#define SENSOR_PASSIVE_QUALITY_CAP 60
#define SENSOR_PASSIVE_GAIN 11
#define SENSOR_HAYWIRE_TIME (1 MINUTES)
#define SENSOR_HAYWIRE_GHOSTS 4
#define SENSOR_ACTIVE_GAIN 20
#define SENSOR_LOCK_GAIN 40
#define SENSOR_TRACK_DECAY 8
#define SENSOR_SECTOR_REACH 1.7
#define SENSOR_SECTOR_HALF_ARC 30
#define SENSOR_CLUTTER_REACH 12
#define SENSOR_EMISSION_LOW 30
#define SENSOR_EMISSION_MED 55
#define SENSOR_EMISSION_HIGH 80
#define SENSOR_SHADOW_QUALITY_CAP 20
#define SENSOR_SHADOW_RANGE_ERROR 0.8
#define SENSOR_TRAIL_POINTS 8
#define SENSOR_SUPPRESSION_PER_DENSITY 20

/proc/overmap_mass_signature(mass)
	return clamp(round(25 * log(10, max(mass, 1)) - 20), 5, 100)

/proc/overmap_cell_point(obj/overmap/thing)
	var/turf/spot = thing?.get_overmap_turf()
	if(!spot)
		return null
	var/obj/overmap/holder = isturf(thing.loc) ? thing : thing.loc
	if(!istype(holder))
		holder = thing
	return list(spot.x + holder.position[1], spot.y + holder.position[2])

/proc/overmap_bearing(delta_x, delta_y)
	if(!delta_x && !delta_y)
		return 0
	return (round(450 - arctan(delta_x, delta_y)) + 360) % 360

/proc/overmap_angle_gap(first, second)
	var/gap = abs(first - second) % 360
	return gap > 180 ? 360 - gap : gap

/proc/overmap_kind_class(kind)
	switch(kind)
		if(OVERMAP_KIND_STATION)
			return "станция"
		if(OVERMAP_KIND_SHUTTLE)
			return "шаттл"
		if(OVERMAP_KIND_POD)
			return "капсула"
		if(OVERMAP_KIND_PORTAL)
			return "аномалия"
		if(OVERMAP_KIND_PLANET)
			return "планета"
		if(OVERMAP_KIND_RUIN)
			return "обломки"
		if(OVERMAP_KIND_RELAY)
			return "ретранслятор"
	return "объект"

/obj/overmap/proc/sensor_signature()
	var/list/signature = natural_sensor_signature()
	if(!isnull(sensor_ir))
		signature["ir"] = sensor_ir
	if(!isnull(sensor_em))
		signature["em"] = sensor_em
	if(!isnull(sensor_mass))
		signature["mass"] = sensor_mass
	return signature

/obj/overmap/proc/natural_sensor_signature()
	return list("ir" = 5, "em" = 0, "mass" = overmap_mass_signature(get_scan_mass()))

/obj/overmap/entity/natural_sensor_signature()
	var/firing = 0
	for(var/obj/machinery/ship_engine/engine as anything in engines)
		if(engine.firing)
			firing++
	var/ir = 10 + (length(engines) ? 70 * firing / length(engines) : 0) + (OVERMAP_SPEED_STOPPED(get_speed()) ? 0 : 10)
	var/em = 0
	if(is_overmap_visible())
		em += 35
	if(long_sensors_on)
		em += 45
	if(identity_distress)
		em += 25
	for(var/obj/machinery/ship_shield_generator/generator as anything in shield_generators())
		if(generator.active)
			em += 15
			break
	return list("ir" = clamp(round(ir), 0, 100), "em" = min(em, 100), "mass" = overmap_mass_signature(get_scan_mass()))

/datum/component/overmap_sensors/proc/passive_on()
	var/obj/overmap/entity/vessel = parent
	return vessel.short_sensors_on && has_working_sensor(OVERMAP_SENSOR_KIND_SHORT)

/datum/component/overmap_sensors/proc/passive_haywire()
	return world.time < haywire_until

/datum/component/overmap_sensors/proc/start_haywire()
	if(!passive_haywire())
		add_sensor_journal("Сбой пассивного массива: ЭМИ, ложные пеленги на минуту", "iff_lost", null, null, "bad")
	haywire_until = world.time + SENSOR_HAYWIRE_TIME
	refresh_sensor_displays()

/datum/component/overmap_sensors/proc/active_on()
	var/obj/overmap/entity/vessel = parent
	return vessel.long_sensors_on && has_working_sensor(OVERMAP_SENSOR_KIND_LONG)

/datum/component/overmap_sensors/proc/active_reach(list/signature)
	var/obj/overmap/entity/vessel = parent
	var/reach = OVERMAP_SENSOR_LONG_VIEW * (0.6 + 0.4 * signature["mass"] / 100)
	return isnull(vessel.sensor_sector_bearing) ? reach : reach * SENSOR_SECTOR_REACH

/datum/component/overmap_sensors/proc/in_active_beam(obj/overmap/other)
	var/obj/overmap/entity/vessel = parent
	var/list/here = overmap_cell_point(vessel)
	var/list/there = overmap_cell_point(other)
	if(!here || !there)
		return FALSE
	var/delta_x = there[1] - here[1]
	var/delta_y = there[2] - here[2]
	if(sqrt(delta_x ** 2 + delta_y ** 2) > active_reach(other.sensor_signature()))
		return FALSE
	if(isnull(vessel.sensor_sector_bearing))
		return TRUE
	return overmap_angle_gap(overmap_bearing(delta_x, delta_y), vessel.sensor_sector_bearing) <= SENSOR_SECTOR_HALF_ARC

/datum/component/overmap_sensors/proc/passive_reach(list/signature)
	return SENSOR_PASSIVE_RANGE * (0.5 + passive_gain / 100) * max(signature["ir"], signature["em"]) / 100

/datum/component/overmap_sensors/proc/track_source(obj/overmap/other, distance, list/signature)
	if(other.radar_shadow)
		return in_long_peel_range(other) ? "act" : null
	var/obj/overmap/entity/contact = other
	if(istype(contact) && contact.identity_distress)
		return "sos"
	if(other.visible_without_scanner)
		return "map"
	if(always_sees(other))
		return "iff"
	if(in_long_peel_range(other))
		return "act"
	if(in_short_view(other))
		return "short"
	if(passive_on() && distance <= passive_reach(signature))
		return "pas"
	return null

/datum/component/overmap_sensors/proc/update_tracks()
	var/obj/overmap/entity/vessel = parent
	var/elapsed = last_track_update ? (world.time - last_track_update) / (1 SECONDS) : 0
	last_track_update = world.time
	LAZYINITLIST(tracks)
	var/list/here = overmap_cell_point(vessel)
	var/list/seen = list()
	if(here && vessel.sector)
		for(var/obj/overmap/other as anything in vessel.sector.objects)
			if(QDELETED(other) || other == vessel || (other.hidden_from_contacts && !other.radar_shadow) || other.overmap_kind == OVERMAP_KIND_HAZARD || !isturf(other.loc))
				continue
			var/list/there = overmap_cell_point(other)
			if(!there)
				continue
			var/list/signature = other.sensor_signature()
			var/source = track_source(other, sqrt((there[1] - here[1]) ** 2 + (there[2] - here[2]) ** 2), signature)
			if(!source)
				continue
			var/uid = other.UID()
			seen[uid] = TRUE
			var/list/track = tracks[uid]
			if(!track)
				track = list("number" = next_track_number++, "first" = world.time, "quality" = 0)
				tracks[uid] = track
			track["seen"] = world.time
			track["source"] = source
			var/gain = SENSOR_ACTIVE_GAIN
			var/cap = 100
			if(source == "pas")
				gain = passive_haywire() ? 0 : SENSOR_PASSIVE_GAIN
				cap = SENSOR_PASSIVE_QUALITY_CAP
			if(uid == locked_uid)
				gain = SENSOR_LOCK_GAIN
			if(other.radar_shadow)
				cap = SENSOR_SHADOW_QUALITY_CAP
			if(source in list("map", "iff", "sos"))
				track["quality"] = 100
			else
				track["quality"] = min(cap, max(track["quality"], 5) + gain * elapsed)
			if(source == "pas" || other.radar_shadow)
				continue
			var/list/trail = track["trail"] || list()
			trail += list(there.Copy())
			if(length(trail) > SENSOR_TRAIL_POINTS)
				trail.Cut(1, 2)
			track["trail"] = trail
	for(var/uid in tracks)
		if(seen[uid])
			continue
		var/list/track = tracks[uid]
		track["source"] = "lost"
		track["quality"] = max(0, track["quality"] - SENSOR_TRACK_DECAY * elapsed)
		if(!track["quality"] || world.time - track["seen"] > OVERMAP_SENSOR_MEMORY_TIME)
			tracks -= uid
	if(locked_uid && (!seen[locked_uid] || tracks[locked_uid]?["source"] == "pas"))
		release_lock(TRUE)

/datum/component/overmap_sensors/proc/try_lock(uid)
	var/obj/overmap/entity/vessel = parent
	var/obj/overmap/target = locateUID(uid)
	if(!istype(target) || QDELETED(target))
		return "Цель потеряна."
	if(!active_on())
		return "Активный радар выключен."
	if(!(in_long_peel_range(target) || in_short_view(target)))
		return "Цель вне луча активного радара."
	if(target.radar_shadow)
		var/list/track = tracks?[uid]
		if(track && !track["lock_failed"])
			track["lock_failed"] = TRUE
			add_sensor_journal("Срыв захвата: T-[num2text(track["number"])], отражение нестабильно", "iff_lost")
		return "Срыв захвата: отражение нестабильно."
	locked_uid = uid
	var/obj/overmap/entity/victim = target
	if(istype(victim) && victim.sensor_pack)
		victim.add_sensor_journal("Захват: нас ведёт радар [vessel.get_overmap_display_name()]", "scanned_by", vessel.get_overmap_turf(), vessel.get_overmap_display_name(), "bad")
	return TRUE

/datum/component/overmap_sensors/proc/release_lock(lost = FALSE)
	if(!locked_uid)
		return
	if(lost)
		var/list/track = tracks?[locked_uid]
		add_sensor_journal("Захват сорван: T-[track ? num2text(track["number"]) : "?"]", "iff_lost")
	locked_uid = null

/datum/component/overmap_sensors/proc/emission_report()
	var/obj/overmap/entity/vessel = parent
	var/list/signature = vessel.sensor_signature()
	var/peak = max(signature["ir"], signature["em"])
	var/level = "ТИШИНА"
	if(peak >= SENSOR_EMISSION_HIGH)
		level = "ВЫСОКАЯ"
	else if(peak >= SENSOR_EMISSION_MED)
		level = "СРЕДНЯЯ"
	else if(peak >= SENSOR_EMISSION_LOW)
		level = "НИЗКАЯ"
	signature["level"] = level
	return signature

/datum/component/overmap_sensors/proc/track_class(obj/overmap/other, list/track, list/signature, identified)
	var/true_class = overmap_kind_class(other.overmap_kind)
	if(other.overmap_kind == OVERMAP_KIND_SHUTTLE)
		true_class = "[signature["mass"] < 45 ? "малый" : signature["mass"] < 70 ? "средний" : "тяжёлый"] [true_class]"
	if(identified)
		return list(list("label" = true_class, "chance" = 100))
	var/chance = clamp(round(30 + track["quality"] * 0.65), 30, 95)
	if(other.sensor_label)
		return list(list("label" = other.sensor_label, "chance" = chance))
	var/static/list/decoys = list("обломки", "малый шаттл", "грузовой шаттл", "капсула", "станция")
	var/decoy = decoys[(hex2num(copytext(md5(other.UID()), 1, 3)) % length(decoys)) + 1]
	if(decoy == true_class)
		decoy = "объект"
	return list(list("label" = true_class, "chance" = chance), list("label" = decoy, "chance" = round((100 - chance) * 0.7)))

/datum/component/overmap_sensors/proc/build_tracks_data()
	. = list()
	var/obj/overmap/entity/vessel = parent
	var/list/here = overmap_cell_point(vessel)
	if(!here || !length(tracks))
		return
	for(var/uid in tracks)
		var/obj/overmap/other = locateUID(uid)
		if(!istype(other) || QDELETED(other))
			continue
		var/list/track = tracks[uid]
		var/list/there = overmap_cell_point(other)
		if(!there)
			continue
		var/list/signature = other.sensor_signature()
		var/source = track["source"]
		var/precise = source != "pas" && source != "lost"
		var/delta_x = there[1] - here[1]
		var/delta_y = there[2] - here[2]
		var/distance = sqrt(delta_x ** 2 + delta_y ** 2)
		if(other.radar_shadow)
			. += list(list(
				"ref" = uid,
				"id" = "T-[num2text(track["number"])]",
				"kind" = "unknown",
				"source" = source,
				"bearing" = (overmap_bearing(delta_x, delta_y) + rand(-3, 3) + 360) % 360,
				"range" = round(distance + (rand() - 0.5) * SENSOR_SHADOW_RANGE_ERROR, 0.01),
				"range_err" = SENSOR_SHADOW_RANGE_ERROR,
				"quality" = round(track["quality"]),
				"age" = round((world.time - track["first"]) / (1 SECONDS)),
				"shadow" = TRUE,
				"classes" = list(),
			))
			continue
		var/identified = display_identified(other)
		var/list/trail = list()
		for(var/list/point as anything in track["trail"])
			trail += list(list(overmap_bearing(point[1] - here[1], point[2] - here[2]), round(sqrt((point[1] - here[1]) ** 2 + (point[2] - here[2]) ** 2), 0.01)))
		var/list/entry = list(
			"ref" = uid,
			"id" = "T-[num2text(track["number"])]",
			"name" = identified ? other.get_overmap_display_name() : null,
			"kind" = identified ? other.overmap_kind : "unknown",
			"source" = source,
			"bearing" = overmap_bearing(delta_x, delta_y),
			"range" = round(distance, 0.01),
			"quality" = round(track["quality"]),
			"age" = round((world.time - track["first"]) / (1 SECONDS)),
			"ir" = signature["ir"],
			"em" = signature["em"],
			"mass" = signature["mass"],
			"locked" = uid == locked_uid,
			"can_scan" = can_short_scan(other),
			"classes" = track_class(other, track, signature, identified),
			"trail" = trail,
		)
		if(!precise)
			entry["range_err"] = round(distance * (0.6 - track["quality"] / 200), 0.1)
			if(passive_haywire())
				entry["bearing"] = (entry["bearing"] + rand(-40, 40) + 360) % 360
				entry["range_err"] = round(entry["range_err"] * 2 + 1, 0.1)
		else
			var/velocity_x = other.speed[1] - vessel.speed[1]
			var/velocity_y = other.speed[2] - vessel.speed[2]
			var/speed_sq = velocity_x ** 2 + velocity_y ** 2
			entry["speed"] = round(OVERMAP_DISPLAY_SPEED(other.get_speed()), 0.01)
			entry["heading"] = other.get_heading_angle()
			entry["transponder"] = other.is_overmap_visible()
			if(distance && speed_sq)
				var/along = delta_x * velocity_x + delta_y * velocity_y
				entry["closing"] = round(OVERMAP_DISPLAY_SPEED(along / distance), 0.01)
				var/cpa_time = -along / speed_sq
				if(cpa_time > 0)
					entry["cpa"] = round(sqrt((delta_x + velocity_x * cpa_time) ** 2 + (delta_y + velocity_y * cpa_time) ** 2), 0.01)
					entry["cpa_time"] = round(cpa_time / (1 SECONDS))
					entry["cpa_bearing"] = overmap_bearing(delta_x + velocity_x * cpa_time, delta_y + velocity_y * cpa_time)
		. += list(entry)
	if(!passive_haywire() || !passive_on())
		return
	for(var/ghost in 1 to SENSOR_HAYWIRE_GHOSTS)
		. += list(list(
			"ref" = "ghost_[ghost]",
			"id" = "T-??",
			"kind" = "unknown",
			"source" = "pas",
			"bearing" = rand(0, 359),
			"range" = rand(2, 8),
			"range_err" = rand(2, 4),
			"quality" = rand(5, 20),
			"age" = 0,
			"ir" = rand(30, 90),
			"em" = rand(0, 60),
			"mass" = rand(10, 60),
			"ghost" = TRUE,
			"classes" = list(list("label" = "помеха?", "chance" = rand(20, 50))),
		))

/datum/component/overmap_sensors/proc/build_clutter_data()
	. = list()
	var/obj/overmap/entity/vessel = parent
	var/list/here = overmap_cell_point(vessel)
	if(!here || !vessel.sector || !(passive_on() || active_on()))
		return
	for(var/obj/overmap/feature/hazard/hazard in vessel.sector.objects)
		var/list/there = overmap_cell_point(hazard)
		if(!there)
			continue
		var/delta_x = there[1] - here[1]
		var/delta_y = there[2] - here[2]
		var/distance = sqrt(delta_x ** 2 + delta_y ** 2)
		if(distance > SENSOR_CLUTTER_REACH || hazard.hazard_density * SENSOR_SUPPRESSION_PER_DENSITY < clutter_suppression)
			continue
		. += list(list("bearing" = overmap_bearing(delta_x, delta_y), "range" = round(distance, 0.01), "density" = hazard.hazard_density, "name" = hazard.name))

/datum/component/overmap_sensors/proc/status_report()
	var/obj/overmap/entity/vessel = parent
	var/list/status = list()
	status["passive"] = !passive_on() ? "off" : passive_haywire() ? "haywire" : "ok"
	status["active"] = active_on() ? "on" : "off"
	status["lock"] = locked_uid ? "T-[num2text(tracks?[locked_uid]?["number"])]" : null
	status["haywire"] = passive_haywire() ? round((haywire_until - world.time) / (1 SECONDS)) : null
	var/painted = FALSE
	for(var/obj/overmap/entity/other in vessel.sector?.objects)
		if(other != vessel && other.sensor_pack?.locked_uid == vessel.UID())
			painted = TRUE
			break
	status["painted"] = painted ? "lock" : sees_any_foreign_peel() ? "radar" : null
	var/list/lost = list()
	for(var/uid in tracks)
		var/obj/overmap/other = locateUID(uid)
		if(tracks[uid]["source"] == "lost" || (istype(other) && other.radar_shadow))
			lost += "T-[num2text(tracks[uid]["number"])]"
	status["lost"] = length(lost) ? jointext(lost, ", ") : null
	return status

#undef SENSOR_PASSIVE_RANGE
#undef SENSOR_SHADOW_QUALITY_CAP
#undef SENSOR_SHADOW_RANGE_ERROR
#undef SENSOR_TRAIL_POINTS
#undef SENSOR_SUPPRESSION_PER_DENSITY
#undef SENSOR_PASSIVE_QUALITY_CAP
#undef SENSOR_PASSIVE_GAIN
#undef SENSOR_HAYWIRE_TIME
#undef SENSOR_HAYWIRE_GHOSTS
#undef SENSOR_ACTIVE_GAIN
#undef SENSOR_LOCK_GAIN
#undef SENSOR_TRACK_DECAY
#undef SENSOR_SECTOR_REACH
#undef SENSOR_SECTOR_HALF_ARC
#undef SENSOR_CLUTTER_REACH
#undef SENSOR_EMISSION_LOW
#undef SENSOR_EMISSION_MED
#undef SENSOR_EMISSION_HIGH
