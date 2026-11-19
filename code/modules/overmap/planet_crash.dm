#define PLANET_CRASH_STALL_GRACE (5 SECONDS)
#define PLANET_CRASH_BOUNCE_SPEED 60
#define PLANET_CRASH_DESCENT_TIME (14 SECONDS)
#define PLANET_CRASH_CLOUDS_AT (3 SECONDS)
#define PLANET_CRASH_GROUND_AT (8 SECONDS)
#define PLANET_CRASH_CLOUDS_FADE_AT (10 SECONDS)
#define PLANET_CRASH_CLOUD_CYCLE (1.6 SECONDS)
#define PLANET_CRASH_WIND_EVERY 4
#define PLANET_CRASH_SITE_TRIES 60
#define PLANET_CRASH_SITE_EDGE 12
#define PLANET_CRASH_SITE_BAD_SHARE 0.15
#define PLANET_CRASH_SITE_NEAR_TRIES 30
#define PLANET_CRASH_SITE_NEAR_SPREAD 24
#define PLANET_CRASH_HAZE_SCALE 3
#define PLANET_CRASH_CLOUD_FAR 0.8
#define PLANET_CRASH_CLOUD_NEAR 4
#define PLANET_CRASH_SKY_SHIFT -224
#define PLANET_CRASH_EMBER_SHARE 3
#define PLANET_CRASH_BLASTS 7
#define PLANET_CRASH_DUST_PUFFS 6
#define PLANET_CRASH_DAMAGE 50
#define PLANET_CRASH_KNOCKDOWN (12 SECONDS)
#define PLANET_CRASH_BUCKLED_KNOCKDOWN (2 SECONDS)
#define PLANET_FLYOVER_HAZE_ALPHA 60
#define PLANET_FLYOVER_ENTRY_TIME (3 SECONDS)
#define PLANET_GROUND_CHUNK 16
#define PLANET_GROUND_REACH 20
#define PLANET_GROUND_REFRESH (2 MINUTES)
#define PLANET_SHADOW_ALPHA 110
#define PLANET_SHADOW_BLUR 3
#define PLANET_FLYOVER_ROAR_EVERY 3
#define PLANET_FLYOVER_ROAR_RANGE 25
#define PLANET_SURFACE_DROP_RANGE 6
#define PLANET_GROUND_ACTOR_RANGE 24
#define PLANET_CLOUD_TILE 480
#define PLANET_CLOUD_PARALLAX 1.4
#define PLANET_CLOUD_ALPHA 120
#define PLANET_GROUND_GRADE list(0.92, 0.06, 0.02, 0.07, 0.8, 0.04, 0.02, 0.04, 0.68, 0.04, 0.01, 0)

/obj/overmap/planet/proc/capture_derelicts(elapsed)
	var/turf/origin = loc
	if(!sector || !isturf(origin) || !outpost || !surface_z())
		return
	var/span = OVERMAP_TILE_SPAN * sector.tile_travel
	var/center_x = (origin.x + (footprint - 1) / 2) * span
	var/center_y = (origin.y + (footprint - 1) / 2) * span
	var/pull_reach = (footprint / 2 + pull_range) * span
	for(var/obj/overmap/entity/vessel as anything in SSovermap.vessels)
		if(QDELETED(vessel) || vessel.planet_crash || vessel.overmap_kind != OVERMAP_KIND_SHUTTLE || vessel.overmap_pod)
			continue
		var/airborne = vessel.sector == sector && vessel.in_free_flight()
		var/world_x = vessel.get_world_x()
		var/world_y = vessel.get_world_y()
		var/over_planet = airborne && covers_world(world_x, world_y)
		var/powered = vessel.has_working_engines()
		if(airborne)
			sector_tick(vessel, powered)
		if(over_planet && powered)
			vessel.planet_stall_at = null
			if(!vessel.planet_flyover)
				new /datum/planet_sky/flyover(vessel, src)
			continue
		if(over_planet && vessel.planet_flyover)
			if(isnull(vessel.planet_stall_at))
				vessel.planet_stall_at = world.time
				vessel.overmap_shuttle?.play_area_sound('sound/effects/creak1.ogg')
				for(var/mob/living/crew in overmap_shuttle_crew(vessel))
					to_chat(crew, span_userdanger("Двигатели заглохли! Если их не запустить, корабль рухнет на [declent_ru(ACCUSATIVE)]!"))
			if(world.time - vessel.planet_stall_at < PLANET_CRASH_STALL_GRACE)
				continue
		QDEL_NULL(vessel.planet_flyover)
		vessel.planet_stall_at = null
		if(over_planet)
			new /datum/planet_sky/crash(vessel, src)
			continue
		if(!airborne)
			continue
		var/delta_x = center_x - world_x
		var/delta_y = center_y - world_y
		var/distance = sqrt(delta_x ** 2 + delta_y ** 2)
		if(powered || distance > pull_reach || !distance)
			LAZYREMOVE(crash_warned, vessel.UID())
			continue
		if(!LAZYACCESS(crash_warned, vessel.UID()))
			LAZYSET(crash_warned, vessel.UID(), TRUE)
			vessel.overmap_shuttle?.play_area_sound('sound/effects/creak1.ogg')
			for(var/mob/living/crew in overmap_shuttle_crew(vessel))
				to_chat(crew, span_warning("Двигатели молчат, и корабль затягивает гравитация [declent_ru(GENITIVE)]!"))
		var/push = OVERMAP_FROM_DISPLAY(pull_accel) * elapsed / (1 SECONDS)
		vessel.speed[1] += push * delta_x / distance
		vessel.speed[2] += push * delta_y / distance

/obj/overmap/planet/proc/push_away(obj/overmap/entity/vessel, display_speed)
	var/turf/origin = loc
	var/span = OVERMAP_TILE_SPAN * sector.tile_travel
	var/delta_x = vessel.get_world_x() - (origin.x + (footprint - 1) / 2) * span
	var/delta_y = vessel.get_world_y() - (origin.y + (footprint - 1) / 2) * span
	var/distance = max(sqrt(delta_x ** 2 + delta_y ** 2), 1)
	vessel.speed[1] = OVERMAP_FROM_DISPLAY(display_speed) * delta_x / distance
	vessel.speed[2] = OVERMAP_FROM_DISPLAY(display_speed) * delta_y / distance

/obj/overmap/planet/proc/surface_point(world_x, world_y)
	var/turf/origin = loc
	var/span = OVERMAP_TILE_SPAN * sector.tile_travel
	var/width = footprint * span
	return list((world.maxx + 1) / 2 + (world_x - (origin.x - 0.5 + footprint / 2) * span) * world.maxx / width, (world.maxy + 1) / 2 + (world_y - (origin.y - 0.5 + footprint / 2) * span) * world.maxy / width)

/obj/overmap/planet/proc/surface_turf_at(world_x, world_y, offset_x = 0, offset_y = 0)
	var/list/surface_levels = surface_levels()
	if(!sector || !length(surface_levels))
		return null
	var/list/point = surface_point(world_x, world_y)
	var/turf/below = locate(round(point[1] + offset_x), round(point[2] + offset_y), surface_levels[1])
	if(!below)
		return null
	for(var/turf/candidate as anything in RANGE_TURFS(PLANET_SURFACE_DROP_RANGE, below))
		if(!candidate.density && !ismineralturf(candidate) && !ischasm(candidate))
			return candidate

/obj/overmap/planet/proc/ground_chunk(chunk_x, chunk_y, surface_z)
	var/key = "[chunk_x],[chunk_y]"
	var/atom/movable/planet_ground_chunk/chunk = LAZYACCESS(ground_chunks, key)
	if(!chunk)
		chunk = new
		chunk.pixel_w = chunk_x * PLANET_GROUND_CHUNK * world.icon_size
		chunk.pixel_z = chunk_y * PLANET_GROUND_CHUNK * world.icon_size
		LAZYSET(ground_chunks, key, chunk)
	if(!chunk.painted_at || world.time - chunk.painted_at > PLANET_GROUND_REFRESH)
		INVOKE_ASYNC(chunk, TYPE_PROC_REF(/atom/movable/planet_ground_chunk, paint), chunk_x * PLANET_GROUND_CHUNK + 1, chunk_y * PLANET_GROUND_CHUNK + 1, surface_z)
	return chunk

/obj/overmap/planet/proc/fill_ground(atom/movable/screen/planet_crash/ground/holder, focus_x, focus_y)
	var/list/surface_levels = surface_levels()
	if(!length(surface_levels))
		return
	var/last_x = CEILING(world.maxx / PLANET_GROUND_CHUNK, 1) - 1
	var/last_y = CEILING(world.maxy / PLANET_GROUND_CHUNK, 1) - 1
	var/low_x = max(floor((focus_x - PLANET_GROUND_REACH - 1) / PLANET_GROUND_CHUNK), 0)
	var/low_y = max(floor((focus_y - PLANET_GROUND_REACH - 1) / PLANET_GROUND_CHUNK), 0)
	var/high_x = min(floor((focus_x + PLANET_GROUND_REACH - 1) / PLANET_GROUND_CHUNK), last_x)
	var/high_y = min(floor((focus_y + PLANET_GROUND_REACH - 1) / PLANET_GROUND_CHUNK), last_y)
	var/key = "[low_x],[low_y],[high_x],[high_y]"
	if(holder.chunk_key == key)
		return
	holder.chunk_key = key
	holder.vis_contents.Cut()
	if(low_x > high_x || low_y > high_y)
		return
	for(var/chunk_x in low_x to high_x)
		for(var/chunk_y in low_y to high_y)
			holder.vis_contents += ground_chunk(chunk_x, chunk_y, surface_levels[1])
	if(!ground_actors)
		ground_actors = new
	holder.vis_contents += ground_actors

/obj/overmap/planet/proc/refresh_actors(focus_x, focus_y, time)
	var/list/surface_levels = surface_levels()
	if(!length(surface_levels))
		return
	if(!ground_actors)
		ground_actors = new
	var/list/seen = list()
	for(var/mob/living/creature as anything in GLOB.mob_living_list)
		if(creature.z != surface_levels[1] || !isturf(creature.loc) || creature.invisibility > SEE_INVISIBLE_LIVING)
			continue
		if(abs(creature.x - focus_x) > PLANET_GROUND_ACTOR_RANGE || abs(creature.y - focus_y) > PLANET_GROUND_ACTOR_RANGE)
			continue
		var/key = creature.UID()
		seen[key] = TRUE
		var/atom/movable/planet_ground_actor/proxy = LAZYACCESS(actor_proxies, key)
		if(!proxy)
			proxy = new
			LAZYSET(actor_proxies, key, proxy)
			ground_actors.vis_contents += proxy
		proxy.mirror(creature, time)
	for(var/key in actor_proxies?.Copy())
		if(seen[key])
			continue
		var/atom/movable/planet_ground_actor/proxy = actor_proxies[key]
		ground_actors.vis_contents -= proxy
		LAZYREMOVE(actor_proxies, key)
		qdel(proxy)

/proc/overmap_shuttle_crew(obj/overmap/entity/vessel)
	. = list()
	var/obj/docking_port/mobile/shuttle = vessel?.shuttle
	if(!shuttle)
		return
	for(var/mob/living/crew in GLOB.mob_living_list)
		if(get_area(crew) in shuttle.shuttle_areas)
			. += crew

/proc/planet_ground_matrix(icon_width, icon_height, focus_x, focus_y, scale, angle)
	var/center_x = icon_width / 2
	var/center_y = icon_height / 2
	var/matrix/view = matrix()
	view.Scale(scale)
	view.Turn(-angle)
	var/reach_x = center_x - focus_x
	var/reach_y = center_y - focus_y
	view.Translate(view.a * reach_x + view.b * reach_y + world.icon_size / 2 - center_x, view.d * reach_x + view.e * reach_y + world.icon_size / 2 - center_y)
	return view

/datum/planet_sky
	var/obj/overmap/entity/vessel
	var/obj/overmap/planet/planet
	var/list/mob/viewers = list()
	var/list/atom/movable/screen/planet_crash/screens = list()
	var/list/ground_holders = list()
	var/list/cloud_holders = list()
	var/list/atom/movable/planet_cloud_tile/cloud_tiles
	var/drifting_clouds = FALSE
	var/ground_fade = 1 SECONDS
	var/atom/movable/screen/planet_crash/haze

/datum/planet_sky/New(obj/overmap/entity/vessel, obj/overmap/planet/planet)
	src.vessel = vessel
	src.planet = planet
	RegisterSignal(vessel, COMSIG_QDELETING, PROC_REF(on_vessel_deleted))
	haze = new(null, null, "haze")
	screens += haze
	START_PROCESSING(SSprocessing, src)

/datum/planet_sky/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	for(var/mob/viewer as anything in viewers.Copy())
		forget_viewer(viewer)
	QDEL_LIST(screens)
	QDEL_LIST(cloud_tiles)
	haze = null
	if(vessel)
		UnregisterSignal(vessel, COMSIG_QDELETING)
	vessel = null
	planet = null
	return ..()

/datum/planet_sky/proc/on_vessel_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/planet_sky/proc/refresh_viewers()
	var/list/wanted = list()
	for(var/mob/viewer as anything in GLOB.player_list)
		if(viewer.client && (get_area(viewer) in vessel.shuttle.shuttle_areas))
			wanted += viewer
	for(var/mob/viewer as anything in viewers - wanted)
		forget_viewer(viewer)
	for(var/mob/viewer as anything in wanted - viewers)
		viewers += viewer
		viewer.client.screen += screens

/datum/planet_sky/proc/forget_viewer(mob/viewer)
	viewers -= viewer
	var/atom/movable/screen/planet_crash/ground/holder = ground_holders[viewer]
	var/atom/movable/screen/planet_crash/ground/clouds = cloud_holders[viewer]
	ground_holders -= viewer
	cloud_holders -= viewer
	viewer.client?.screen -= screens
	for(var/atom/movable/screen/planet_crash/ground/layer as anything in list(holder, clouds))
		if(!layer)
			continue
		viewer.client?.screen -= layer
		layer.vis_contents.Cut()
		qdel(layer)

/datum/planet_sky/proc/ground_focus(turf/eye)
	return null

/datum/planet_sky/proc/aim_viewer(client/watcher, elapsed)
	var/mob/viewer = watcher.mob
	var/turf/eye = get_turf(watcher.eye)
	if(!eye || !(viewer in viewers))
		return
	var/list/focus = ground_focus(eye)
	if(!focus)
		return
	var/matrix/view = planet_ground_matrix(world.icon_size, world.icon_size, (focus[1] - 1) * world.icon_size + world.icon_size / 2, (focus[2] - 1) * world.icon_size + world.icon_size / 2, 1, focus[3])
	var/atom/movable/screen/planet_crash/ground/holder = ground_holders[viewer]
	if(!holder)
		holder = new(null, null, null)
		holder.color = PLANET_GROUND_GRADE
		ground_holders[viewer] = holder
		holder.transform = view
		holder.shown_at = world.time
		watcher.screen += holder
	planet.fill_ground(holder, focus[1], focus[2])
	animate(holder, transform = view, alpha = min(255, 255 * (world.time + elapsed - holder.shown_at) / ground_fade), time = elapsed)
	if(drifting_clouds)
		drift_clouds(watcher, focus, elapsed)

/datum/planet_sky/proc/drift_clouds(client/watcher, list/focus, elapsed)
	var/mob/viewer = watcher.mob
	var/atom/movable/screen/planet_crash/ground/clouds = cloud_holders[viewer]
	if(!clouds)
		if(!cloud_tiles)
			cloud_tiles = list()
			for(var/tile_x in -1 to 1)
				for(var/tile_y in -1 to 1)
					var/atom/movable/planet_cloud_tile/tile = new
					tile.icon_state = planet.cloud_state
					tile.pixel_w = tile_x * PLANET_CLOUD_TILE
					tile.pixel_z = tile_y * PLANET_CLOUD_TILE
					cloud_tiles += tile
		clouds = new(null, null, null)
		clouds.layer = 41.5
		clouds.vis_contents += cloud_tiles
		clouds.shown_at = world.time
		cloud_holders[viewer] = clouds
		watcher.screen += clouds
	var/drift_x = ((focus[1] - 1) * world.icon_size) * PLANET_CLOUD_PARALLAX
	var/drift_y = ((focus[2] - 1) * world.icon_size) * PLANET_CLOUD_PARALLAX
	drift_x -= floor(drift_x / PLANET_CLOUD_TILE) * PLANET_CLOUD_TILE
	drift_y -= floor(drift_y / PLANET_CLOUD_TILE) * PLANET_CLOUD_TILE
	var/matrix/view = planet_ground_matrix(world.icon_size, world.icon_size, drift_x, drift_y, 1, focus[3])
	var/wrapped = !isnull(clouds.chunk_key) && (abs(drift_x - clouds.chunk_key[1]) > PLANET_CLOUD_TILE / 2 || abs(drift_y - clouds.chunk_key[2]) > PLANET_CLOUD_TILE / 2)
	clouds.chunk_key = list(drift_x, drift_y)
	if(wrapped)
		clouds.transform = view
		return
	animate(clouds, transform = view, alpha = min(PLANET_CLOUD_ALPHA, PLANET_CLOUD_ALPHA * (world.time + elapsed - clouds.shown_at) / ground_fade), time = elapsed)

/datum/planet_sky/flyover
	ground_fade = PLANET_FLYOVER_ENTRY_TIME
	drifting_clouds = TRUE
	var/obj/effect/planet_flyover_shadow/shadow
	var/ticks = 0

/datum/planet_sky/flyover/New(obj/overmap/entity/vessel, obj/overmap/planet/planet)
	. = ..()
	vessel.planet_flyover = src
	animate(haze, alpha = PLANET_FLYOVER_HAZE_ALPHA, time = PLANET_FLYOVER_ENTRY_TIME)
	shadow = new(null, vessel.shuttle)
	shadow.surface_z = planet.surface_z()
	vessel.overmap_shuttle?.play_area_sound('sound/effects/wind/wind_2_1.ogg')
	for(var/mob/living/crew in overmap_shuttle_crew(vessel))
		to_chat(crew, span_warning("Корабль входит в атмосферу [planet.declent_ru(GENITIVE)]. Шагнёте за борт — упадёте на поверхность!"))
	refresh_viewers()

/datum/planet_sky/flyover/Destroy()
	if(vessel?.planet_flyover == src)
		vessel.planet_flyover = null
	QDEL_NULL(shadow)
	return ..()

/datum/planet_sky/flyover/process(seconds_per_tick)
	if(QDELETED(vessel) || !vessel.in_free_flight())
		qdel(src)
		return PROCESS_KILL
	refresh_viewers()
	ticks++
	var/list/point = planet.surface_point(vessel.get_world_x(), vessel.get_world_y())
	planet.refresh_actors(point[1], point[2], seconds_per_tick * (1 SECONDS))
	var/turf/below = shadow.glide_to(point[1], point[2], vessel.get_facing(), seconds_per_tick * (1 SECONDS))
	if(below && ticks % PLANET_FLYOVER_ROAR_EVERY == 1)
		playsound(below, pick('sound/ambience/earth_rumble/earth_rumble_distant1.ogg', 'sound/ambience/earth_rumble/earth_rumble_distant2.ogg', 'sound/ambience/earth_rumble/earth_rumble_distant3.ogg'), 80, TRUE, PLANET_FLYOVER_ROAR_RANGE)
		playsound(below, 'sound/machines/engine/engine_mid1.ogg', 50, TRUE, PLANET_FLYOVER_ROAR_RANGE)

/datum/planet_sky/flyover/ground_focus(turf/eye)
	var/list/eye_world = vessel.hull_to_world(eye.x, eye.y)
	var/world_x = vessel.get_world_x()
	var/world_y = vessel.get_world_y()
	var/list/point = planet.surface_point(world_x, world_y)
	return list(point[1] + eye_world[1] - world_x, point[2] + eye_world[2] - world_y, vessel.get_facing())

/datum/planet_sky/crash
	var/started_at
	ground_fade = PLANET_CRASH_DESCENT_TIME - PLANET_CRASH_GROUND_AT
	var/turf/site
	var/searching = TRUE
	var/clouds_started = FALSE
	var/clouds_faded = FALSE
	var/ticks = 0
	var/list/obj/effect/planet_crash_heat/heat = list()
	var/atom/movable/screen/planet_crash/cloud_near
	var/atom/movable/screen/planet_crash/cloud_far

/datum/planet_sky/crash/New(obj/overmap/entity/vessel, obj/overmap/planet/planet)
	. = ..()
	vessel.planet_crash = src
	started_at = world.time
	vessel.speed[1] = 0
	vessel.speed[2] = 0
	vessel.halted = TRUE
	cloud_far = new(null, null, "clouds_b")
	cloud_near = new(null, null, "clouds_a")
	screens += list(cloud_far, cloud_near)
	animate(haze, alpha = 210, time = PLANET_CRASH_CLOUDS_AT)
	ignite_hull()
	vessel.overmap_shuttle?.play_area_sound('sound/effects/hyperspace_begin.ogg')
	vessel.announce_sensor_event("Неуправляемый вход в атмосферу: [vessel.get_overmap_display_name()]", "dock")
	for(var/mob/living/crew in overmap_shuttle_crew(vessel))
		to_chat(crew, span_userdanger("Корабль входит в атмосферу [planet.declent_ru(GENITIVE)]! Держитесь крепче!"))
	INVOKE_ASYNC(src, PROC_REF(prepare_site))

/datum/planet_sky/crash/Destroy()
	QDEL_LIST(heat)
	if(vessel)
		if(vessel.planet_crash == src)
			vessel.planet_crash = null
		if(vessel.in_free_flight())
			vessel.halted = FALSE
	cloud_near = null
	cloud_far = null
	site = null
	return ..()

/datum/planet_sky/crash/proc/prepare_site()
	site = find_site()
	searching = FALSE

/datum/planet_sky/crash/ground_focus(turf/eye)
	if(!site || world.time - started_at < PLANET_CRASH_GROUND_AT)
		return null
	var/obj/docking_port/mobile/shuttle = vessel.shuttle
	return list(site.x + eye.x - shuttle.x, site.y + eye.y - shuttle.y, 0)

/datum/planet_sky/crash/proc/find_site()
	var/obj/docking_port/mobile/shuttle = vessel?.shuttle
	var/list/surface_levels = planet.surface_levels()
	if(!shuttle || !length(surface_levels))
		return null
	var/surface_z = surface_levels[1]
	var/turf/best
	var/best_bad = INFINITY
	var/list/below = planet.surface_point(vessel.get_world_x(), vessel.get_world_y())
	var/below_on_map = below[1] >= 1 && below[1] <= world.maxx && below[2] >= 1 && below[2] <= world.maxy
	for(var/attempt in 1 to PLANET_CRASH_SITE_TRIES)
		CHECK_TICK
		if(QDELETED(src) || QDELETED(shuttle))
			return null
		var/turf/candidate
		if(below_on_map && attempt <= PLANET_CRASH_SITE_NEAR_TRIES)
			candidate = locate(clamp(round(below[1]) + rand(-PLANET_CRASH_SITE_NEAR_SPREAD, PLANET_CRASH_SITE_NEAR_SPREAD), PLANET_CRASH_SITE_EDGE, world.maxx - PLANET_CRASH_SITE_EDGE), clamp(round(below[2]) + rand(-PLANET_CRASH_SITE_NEAR_SPREAD, PLANET_CRASH_SITE_NEAR_SPREAD), PLANET_CRASH_SITE_EDGE, world.maxy - PLANET_CRASH_SITE_EDGE), surface_z)
		else
			candidate = locate(rand(PLANET_CRASH_SITE_EDGE, world.maxx - PLANET_CRASH_SITE_EDGE), rand(PLANET_CRASH_SITE_EDGE, world.maxy - PLANET_CRASH_SITE_EDGE), surface_z)
		if(!candidate)
			continue
		var/list/bounds = shuttle.return_coords(candidate.x, candidate.y, shuttle.dir)
		var/min_x = min(bounds[1], bounds[3])
		var/min_y = min(bounds[2], bounds[4])
		var/max_x = max(bounds[1], bounds[3])
		var/max_y = max(bounds[2], bounds[4])
		if(min_x < PLANET_CRASH_SITE_EDGE || min_y < PLANET_CRASH_SITE_EDGE || max_x > world.maxx - PLANET_CRASH_SITE_EDGE || max_y > world.maxy - PLANET_CRASH_SITE_EDGE)
			continue
		if(length(SSshuttle.get_dock_overlap(min_x, min_y, max_x, max_y, surface_z)))
			continue
		var/bad = 0
		var/total = 0
		for(var/turf/spot as anything in block(min_x, min_y, surface_z, max_x, max_y, surface_z))
			total++
			if(!istype(spot.loc, planet.surface_area_type) || ischasm(spot))
				bad = INFINITY
				break
			if(overmap_lavaland_landing_blocked(spot))
				bad++
		if(bad == INFINITY)
			continue
		if(bad <= total * PLANET_CRASH_SITE_BAD_SHARE)
			return candidate
		if(bad < best_bad)
			best = candidate
			best_bad = bad
	return best

/datum/planet_sky/crash/process(seconds_per_tick)
	if(QDELETED(vessel) || !vessel.in_free_flight())
		qdel(src)
		return PROCESS_KILL
	ticks++
	var/elapsed = world.time - started_at
	if(elapsed >= PLANET_CRASH_DESCENT_TIME && !searching)
		impact()
		return PROCESS_KILL
	var/progress = clamp(elapsed / PLANET_CRASH_DESCENT_TIME, 0, 1)
	refresh_viewers()
	if(site && elapsed >= PLANET_CRASH_GROUND_AT)
		planet.refresh_actors(site.x, site.y, seconds_per_tick * (1 SECONDS))
	if(!clouds_started && elapsed >= PLANET_CRASH_CLOUDS_AT)
		clouds_started = TRUE
		loop_cloud(cloud_near)
		addtimer(CALLBACK(src, PROC_REF(loop_cloud), cloud_far), PLANET_CRASH_CLOUD_CYCLE / 2)
	if(!clouds_faded && elapsed >= PLANET_CRASH_CLOUDS_FADE_AT)
		clouds_faded = TRUE
		for(var/atom/movable/screen/planet_crash/cloud as anything in list(cloud_near, cloud_far))
			animate(cloud, alpha = 0, time = 2 SECONDS)
		animate(haze, alpha = 0, time = PLANET_CRASH_DESCENT_TIME - elapsed)
		for(var/obj/effect/planet_crash_heat/flame as anything in heat)
			animate(flame, alpha = 0, time = PLANET_CRASH_DESCENT_TIME - elapsed)
	for(var/mob/viewer as anything in viewers)
		shake_camera(viewer, 1 SECONDS, 1 + round(progress * 3))
	if(ticks % PLANET_CRASH_WIND_EVERY == 1)
		vessel.overmap_shuttle?.play_area_sound(pick('sound/effects/wind/wind_4_1.ogg', 'sound/effects/wind/wind_4_2.ogg', 'sound/effects/wind/wind_5_1.ogg'))

/datum/planet_sky/crash/proc/loop_cloud(atom/movable/screen/planet_crash/cloud)
	if(QDELETED(cloud) || clouds_faded)
		return
	var/matrix/far = matrix(PLANET_CRASH_CLOUD_FAR, 0, 0, 0, PLANET_CRASH_CLOUD_FAR, 0)
	var/matrix/near = matrix(PLANET_CRASH_CLOUD_NEAR, 0, 0, 0, PLANET_CRASH_CLOUD_NEAR, 0)
	cloud.transform = far
	cloud.alpha = 0
	animate(cloud, transform = near, alpha = 230, time = PLANET_CRASH_CLOUD_CYCLE / 2, loop = -1, easing = QUAD_EASING | EASE_IN)
	animate(transform = near, alpha = 0, time = PLANET_CRASH_CLOUD_CYCLE / 2)
	animate(transform = far, time = 0)

/datum/planet_sky/crash/proc/ignite_hull()
	var/obj/docking_port/mobile/shuttle = vessel.shuttle
	var/count = 0
	for(var/turf/spot as anything in shuttle.return_turfs())
		if(!(spot.loc in shuttle.shuttle_areas))
			continue
		for(var/direction in GLOB.cardinal)
			var/turf/outside = get_step(spot, direction)
			if(!outside || (outside.loc in shuttle.shuttle_areas))
				continue
			count++
			heat += new /obj/effect/planet_crash_heat(outside, REVERSE_DIR(direction), !(count % PLANET_CRASH_EMBER_SHARE))

/datum/planet_sky/crash/proc/impact()
	for(var/mob/viewer as anything in viewers.Copy())
		forget_viewer(viewer)
	QDEL_LIST(heat)
	var/obj/docking_port/mobile/shuttle = vessel.shuttle
	if(!site || QDELETED(shuttle) || !planet.outpost)
		bounce()
		return
	var/obj/docking_port/stationary/pad = crash_pad(shuttle)
	vessel.halted = FALSE
	shuttle.overmap_force_dock = TRUE
	var/failed = shuttle.dock(pad, force = TRUE)
	shuttle.overmap_force_dock = FALSE
	if(failed)
		bounce()
		return
	vessel.crash_grounded = TRUE
	shatter_hull(shuttle)
	vessel.announce_sensor_event("Крушение: [vessel.get_overmap_display_name()] → [planet.name]", "dock")
	qdel(src)

/datum/planet_sky/crash/proc/bounce()
	for(var/mob/living/crew in overmap_shuttle_crew(vessel))
		to_chat(crew, span_warning("Корабль отскакивает от плотных слоёв атмосферы обратно в космос!"))
	vessel.halted = FALSE
	planet.push_away(vessel, PLANET_CRASH_BOUNCE_SPEED)
	qdel(src)

/datum/planet_sky/crash/proc/crash_pad(obj/docking_port/mobile/shuttle)
	var/pad_id = "[shuttle.id]_overmap_crash"
	var/obj/docking_port/stationary/pad = SSshuttle.getDock(pad_id, warn = FALSE)
	if(!pad)
		pad = new
		pad.id = pad_id
		pad.name = "Место крушения"
		pad.register()
	pad.height = shuttle.height
	pad.width = shuttle.width
	pad.dheight = shuttle.dheight
	pad.dwidth = shuttle.dwidth
	pad.setDir(shuttle.dir)
	pad.forceMove(site)
	pad.turf_type = planet.surface_floor_type()
	pad.area_type = planet.surface_area_type
	pad.overmap_dock_mode = OVERMAP_DOCK_MANUAL
	pad.overmap_dock_label = "Место крушения"
	pad.overmap_host_uid = planet.outpost.UID()
	LAZYINITLIST(vessel.custom_docks)
	vessel.custom_docks[planet.outpost.UID()] = pad
	vessel.selected_dock_id = pad.id
	if(vessel.overmap_shuttle)
		vessel.overmap_shuttle.owned_docks_dirty = TRUE
	return pad

/datum/planet_sky/crash/proc/shatter_hull(obj/docking_port/mobile/shuttle)
	var/list/edges = list()
	var/list/outside = list()
	for(var/turf/spot as anything in shuttle.return_turfs())
		if(!(spot.loc in shuttle.shuttle_areas))
			continue
		for(var/direction in GLOB.cardinal)
			var/turf/neighbour = get_step(spot, direction)
			if(!neighbour || (neighbour.loc in shuttle.shuttle_areas))
				continue
			edges |= spot
			outside |= neighbour
	var/turf/middle = get_turf(shuttle)
	playsound(middle, 'sound/effects/meteorimpact.ogg', 100, TRUE, 20)
	playsound(middle, 'sound/effects/explosion_distant.ogg', 100, TRUE, 30)
	for(var/blast in 1 to min(PLANET_CRASH_BLASTS, length(edges)))
		explosion(pick_n_take(edges), 0, 1, 3, 4, cause = "planet crash of [shuttle.id]")
	for(var/puff in 1 to min(PLANET_CRASH_DUST_PUFFS, length(outside)))
		do_smoke(2, location = pick_n_take(outside))
	for(var/mob/witness in range(14, middle))
		shake_camera(witness, 2 SECONDS, 3)
	for(var/mob/living/crew in overmap_shuttle_crew(vessel))
		to_chat(crew, span_userdanger("Корабль с чудовищным грохотом врезается в поверхность!"))
		shake_camera(crew, 3 SECONDS, 5)
		var/share = crew.buckled ? 0.5 : 1
		crew.Weaken(crew.buckled ? PLANET_CRASH_BUCKLED_KNOCKDOWN : PLANET_CRASH_KNOCKDOWN)
		if(!ishuman(crew))
			crew.adjustBruteLoss(PLANET_CRASH_DAMAGE * share)
			continue
		var/mob/living/carbon/human/human_crew = crew
		for(var/hit in 1 to 3)
			human_crew.apply_damage(PLANET_CRASH_DAMAGE * share / 3, BRUTE, pick(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))

/atom/movable/screen/planet_crash
	icon = 'icons/effects/planet_descent.dmi'
	screen_loc = "CENTER"
	plane = PLANE_SPACE_PARALLAX
	layer = 41
	alpha = 0
	appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_TRANSFORM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/planet_crash/Initialize(mapload, datum/hud/hud_owner, state)
	. = ..()
	if(!state)
		return
	icon_state = state
	pixel_w = PLANET_CRASH_SKY_SHIFT
	pixel_z = PLANET_CRASH_SKY_SHIFT
	if(state == "haze")
		transform = matrix(PLANET_CRASH_HAZE_SCALE, 0, 0, 0, PLANET_CRASH_HAZE_SCALE, 0)
		layer = 42
	else
		layer = 43

/atom/movable/screen/planet_crash/ground
	icon = 'icons/effects/planet_descent_heat.dmi'
	icon_state = "blank"
	appearance_flags = PIXEL_SCALE | RESET_TRANSFORM
	var/chunk_key
	var/shown_at

/atom/movable/planet_ground_chunk
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER
	appearance_flags = PIXEL_SCALE
	var/painted_at

/atom/movable/planet_ground_chunk/proc/paint(min_x, min_y, surface_z)
	painted_at = world.time
	var/list/floor_looks = list()
	var/list/thing_looks = list()
	for(var/column in 0 to PLANET_GROUND_CHUNK - 1)
		for(var/row in 0 to PLANET_GROUND_CHUNK - 1)
			var/turf/spot = locate(min_x + column, min_y + row, surface_z)
			if(!spot?.icon)
				continue
			var/mutable_appearance/look = mutable_appearance(spot.icon, spot.icon_state)
			look.dir = spot.dir
			look.color = spot.color
			look.pixel_w = column * world.icon_size + spot.pixel_x + spot.pixel_w
			look.pixel_z = row * world.icon_size + spot.pixel_y + spot.pixel_z
			floor_looks += look
			for(var/obj/thing in spot)
				if(thing.invisibility || !thing.icon)
					continue
				var/mutable_appearance/thing_look = new(thing)
				thing_look.plane = FLOAT_PLANE
				thing_look.layer = FLOAT_LAYER
				thing_look.pixel_w = column * world.icon_size + thing.pixel_w
				thing_look.pixel_z = row * world.icon_size + thing.pixel_z
				thing_looks += thing_look
		CHECK_TICK
	overlays = floor_looks + thing_looks

/atom/movable/planet_ground_actor
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER
	var/last_w
	var/last_z

/atom/movable/planet_ground_actor/proc/mirror(atom/movable/target, time)
	var/target_w = (target.x - 1) * world.icon_size + target.pixel_w
	var/target_z = (target.y - 1) * world.icon_size + target.pixel_z
	var/from_w = isnull(last_w) ? target_w : last_w
	var/from_z = isnull(last_z) ? target_z : last_z
	appearance = target.appearance
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_w = from_w
	pixel_z = from_z
	last_w = target_w
	last_z = target_z
	animate(src, pixel_w = target_w, pixel_z = target_z, time = time)

/atom/movable/planet_cloud_tile
	icon = 'icons/effects/planet_descent.dmi'
	icon_state = "clouds_tile"
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER
	appearance_flags = PIXEL_SCALE

/obj/effect/planet_flyover_shadow
	layer = FLY_LAYER
	alpha = 0
	movement_type = FLYING
	animate_movement = NO_STEPS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/shift_x = 0
	var/shift_y = 0
	var/surface_z

/obj/effect/planet_flyover_shadow/Initialize(mapload, obj/docking_port/mobile/shuttle)
	. = ..()
	if(!shuttle)
		return
	var/list/hull = list()
	var/min_x = INFINITY
	var/min_y = INFINITY
	var/max_x = -INFINITY
	var/max_y = -INFINITY
	for(var/turf/spot as anything in shuttle.return_turfs())
		if(!(spot.loc in shuttle.shuttle_areas))
			continue
		hull += spot
		min_x = min(min_x, spot.x)
		min_y = min(min_y, spot.y)
		max_x = max(max_x, spot.x)
		max_y = max(max_y, spot.y)
	if(!length(hull))
		return
	var/icon/silhouette = icon('icons/effects/planet_descent_heat.dmi', "blank")
	silhouette.Crop(1, 1, (max_x - min_x + 1) * world.icon_size, (max_y - min_y + 1) * world.icon_size)
	for(var/turf/spot as anything in hull)
		silhouette.DrawBox(COLOR_BLACK, (spot.x - min_x) * world.icon_size + 1, (spot.y - min_y) * world.icon_size + 1, (spot.x - min_x + 1) * world.icon_size, (spot.y - min_y + 1) * world.icon_size)
	icon = silhouette
	shift_x = world.icon_size / 2 - silhouette.Width() / 2
	shift_y = world.icon_size / 2 - silhouette.Height() / 2
	add_filter("shadow_blur", 1, gauss_blur_filter(PLANET_SHADOW_BLUR))

/obj/effect/planet_flyover_shadow/proc/glide_to(target_x, target_y, angle, time)
	var/list/surface_levels = surface_z ? list(surface_z) : list()
	if(!icon || !length(surface_levels))
		return null
	var/turf/target = locate(round(target_x), round(target_y), surface_levels[1])
	if(!target)
		moveToNullspace()
		return null
	var/from_x = target_x
	var/from_y = target_y
	if(isturf(loc))
		from_x = x + (pixel_w - shift_x) / world.icon_size
		from_y = y + (pixel_z - shift_y) / world.icon_size
	else
		transform = matrix().Turn(angle)
	forceMove(target)
	pixel_w = shift_x + (from_x - target.x) * world.icon_size
	pixel_z = shift_y + (from_y - target.y) * world.icon_size
	animate(src, pixel_w = shift_x + (target_x - target.x) * world.icon_size, pixel_z = shift_y + (target_y - target.y) * world.icon_size, transform = matrix().Turn(angle), alpha = PLANET_SHADOW_ALPHA, time = time)
	return target

/obj/effect/planet_crash_heat
	icon = 'icons/effects/planet_descent_heat.dmi'
	icon_state = "heat_edge"
	plane = ABOVE_LIGHTING_PLANE
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/effect/planet_crash_heat/Initialize(mapload, toward_hull, embers)
	. = ..()
	setDir(toward_hull)
	animate(src, alpha = 255, time = PLANET_CRASH_CLOUDS_AT)
	if(!embers)
		return
	var/turf/away = get_step(src, REVERSE_DIR(toward_hull))
	var/away_x = away ? away.x - x : 0
	var/away_y = away ? away.y - y : 0
	var/particles/planet_crash_embers/sparks = new
	sparks.velocity = generator(GEN_BOX, list(away_x * 3 - 1, away_y * 3 - 1), list(away_x * 5 + 1, away_y * 5 + 1), UNIFORM_RAND)
	particles = sparks

/obj/effect/planet_crash_heat/Destroy()
	particles = null
	return ..()

/particles/planet_crash_embers
	icon = 'icons/effects/planet_descent_heat.dmi'
	icon_state = "ember"
	width = 160
	height = 160
	count = 24
	spawning = 1.5
	lifespan = 0.8 SECONDS
	fade = 0.4 SECONDS
	position = generator(GEN_BOX, list(-14, -14), list(14, 14), UNIFORM_RAND)
	friction = 0.05

#undef PLANET_CRASH_STALL_GRACE
#undef PLANET_CRASH_BOUNCE_SPEED
#undef PLANET_CRASH_DESCENT_TIME
#undef PLANET_CRASH_CLOUDS_AT
#undef PLANET_CRASH_GROUND_AT
#undef PLANET_CRASH_CLOUDS_FADE_AT
#undef PLANET_CRASH_CLOUD_CYCLE
#undef PLANET_CRASH_WIND_EVERY
#undef PLANET_CRASH_SITE_TRIES
#undef PLANET_CRASH_SITE_EDGE
#undef PLANET_CRASH_SITE_BAD_SHARE
#undef PLANET_CRASH_SITE_NEAR_TRIES
#undef PLANET_CRASH_SITE_NEAR_SPREAD
#undef PLANET_CRASH_HAZE_SCALE
#undef PLANET_CRASH_CLOUD_FAR
#undef PLANET_CRASH_CLOUD_NEAR
#undef PLANET_CRASH_SKY_SHIFT
#undef PLANET_CRASH_EMBER_SHARE
#undef PLANET_CRASH_BLASTS
#undef PLANET_CRASH_DUST_PUFFS
#undef PLANET_CRASH_DAMAGE
#undef PLANET_CRASH_KNOCKDOWN
#undef PLANET_CRASH_BUCKLED_KNOCKDOWN
#undef PLANET_FLYOVER_HAZE_ALPHA
#undef PLANET_FLYOVER_ENTRY_TIME
#undef PLANET_GROUND_CHUNK
#undef PLANET_GROUND_REACH
#undef PLANET_GROUND_REFRESH
#undef PLANET_SHADOW_ALPHA
#undef PLANET_SHADOW_BLUR
#undef PLANET_FLYOVER_ROAR_EVERY
#undef PLANET_FLYOVER_ROAR_RANGE
#undef PLANET_SURFACE_DROP_RANGE
#undef PLANET_GROUND_ACTOR_RANGE
#undef PLANET_CLOUD_TILE
#undef PLANET_CLOUD_PARALLAX
#undef PLANET_CLOUD_ALPHA
#undef PLANET_GROUND_GRADE
