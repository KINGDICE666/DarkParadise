#define MASTER_SPARK_RANGE 40
#define MASTER_SPARK_CHARGE_TIME (1 SECONDS)
#define MASTER_SPARK_MOB_DPS 60
#define MASTER_SPARK_OBJ_DPS 200
#define MASTER_SPARK_THEME_DELAY (0.3 SECONDS)
#define MASTER_SPARK_THEME_LENGTH (5.1 SECONDS)
#define MASTER_SPARK_DURATION (MASTER_SPARK_THEME_DELAY + MASTER_SPARK_THEME_LENGTH)
#define MASTER_SPARK_KNOCKDOWN_TIME (3 SECONDS)
#define MASTER_SPARK_KNOCKBACK_RANGE 5
#define MASTER_SPARK_SEGMENT 3
#define MASTER_SPARK_STUN_TIME (3 SECONDS)
#define MASTER_SPARK_COOLDOWN (30 SECONDS)
#define MASTER_SPARK_FIRE_DURATION (20 SECONDS)
#define MASTER_SPARK_FIRE_STACKS 3

#define MASTER_SPARK_TEX_SIZE 96
#define MASTER_SPARK_TEX_FRAMES 8
#define MASTER_SPARK_TEX_DELAY 0.2

GLOBAL_LIST_EMPTY(master_spark_textures)
GLOBAL_DATUM(master_spark_flare, /icon)

/obj/item/master_spark_card
	name = "спеллкарта «Final Master Spark»"
	desc = "Сияющая карта, исписанная звёздами и формулами. От неё пахнет озоном и грибами."
	gender = FEMALE
	icon = 'icons/obj/master_spark_spellcard.dmi'
	icon_state = "master_spark_spellcarde"
	item_state = "nothing"
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 4
	throw_range = 20
	pickup_sound = 'sound/items/handling/pickup/accessory_pickup.ogg'
	drop_sound = 'sound/items/handling/drop/accessory_drop.ogg'
	var/casting = FALSE
	COOLDOWN_DECLARE(spark_cooldown)

/obj/item/master_spark_card/get_ru_names()
	return alist(
		NOMINATIVE = "спеллкарта «Final Master Spark»",
		GENITIVE = "спеллкарты «Final Master Spark»",
		DATIVE = "спеллкарте «Final Master Spark»",
		ACCUSATIVE = "спеллкарту «Final Master Spark»",
		INSTRUMENTAL = "спеллкартой «Final Master Spark»",
		PREPOSITIONAL = "спеллкарте «Final Master Spark»",
	)

/obj/item/master_spark_card/attack_self(mob/living/user)
	if(!istype(user) || casting)
		return
	if(!COOLDOWN_FINISHED(src, spark_cooldown))
		to_chat(user, span_warning("Спеллкарта ещё не остыла. Осталось [DisplayTimeText(COOLDOWN_TIMELEFT(src, spark_cooldown))]."))
		return
	if(!isturf(user.loc))
		return

	casting = TRUE
	COOLDOWN_START(src, spark_cooldown, MASTER_SPARK_COOLDOWN)
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, UNIQUE_TRAIT_SOURCE(src))
	user.say("Магопушка: Final Master Spark!", forced = "master spark")
	playsound(user, 'sound/weapons/touhou-spellcard-warning-sfx.mp3', 100, FALSE, 10)
	get_master_spark_texture(user.dir)
	addtimer(CALLBACK(src, PROC_REF(fire_spark), user, user.dir), MASTER_SPARK_CHARGE_TIME)

/obj/item/master_spark_card/proc/fire_spark(mob/living/user, beam_dir)
	if(QDELETED(user) || user.stat == DEAD || !isturf(user.loc))
		spark_ended(user)
		return
	var/turf/start = get_step(user, beam_dir)
	if(!start)
		spark_ended(user)
		return
	playsound(user, 'sound/weapons/flashbang.ogg', 100, TRUE, 10)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), user, 'sound/weapons/touhou-8-master-spark.mp3', 100, FALSE, 15), MASTER_SPARK_THEME_DELAY)
	new /obj/effect/master_spark(start, user, beam_dir, CALLBACK(src, PROC_REF(spark_ended), user))

/obj/item/master_spark_card/proc/spark_ended(mob/living/user)
	casting = FALSE
	if(QDELETED(user))
		return
	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, UNIQUE_TRAIT_SOURCE(src))
	user.Weaken(MASTER_SPARK_STUN_TIME)
	to_chat(user, span_warning("Отдача заклинания сбивает вас с ног!"))

/obj/effect/master_spark
	name = "Master Spark"
	icon = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/list/turf/beam_turfs = list()
	var/list/turf/center_turfs = list()
	var/list/obj/effect/master_spark_segment/segments = list()
	var/list/mob/living/hit_mobs = list()
	var/mob/living/caster
	var/datum/callback/on_end
	var/end_time
	var/beam_dir

/obj/effect/master_spark/Initialize(mapload, mob/living/caster, beam_dir, datum/callback/on_end)
	. = ..()
	src.caster = caster
	src.beam_dir = beam_dir
	src.on_end = on_end

	var/side_a = turn(beam_dir, 90)
	var/side_b = turn(beam_dir, -90)
	var/list/turf/centers = list()
	var/turf/center = loc
	while(center && length(centers) < MASTER_SPARK_RANGE)
		centers += center
		center_turfs += center
		beam_turfs += center
		var/turf/side = get_step(center, side_a)
		if(side)
			beam_turfs += side
		side = get_step(center, side_b)
		if(side)
			beam_turfs += side
		center = get_step(center, beam_dir)

	var/list/tile_icons = get_master_spark_texture(beam_dir)
	var/beam_length = length(centers)
	for(var/first in 0 to beam_length - 1 step MASTER_SPARK_SEGMENT)
		var/last = min(first + MASTER_SPARK_SEGMENT - 1, beam_length - 1)
		var/anchor = min(first + 1, last)
		segments += new /obj/effect/master_spark_segment(centers[anchor + 1], beam_dir, tile_icons, first, last, anchor)

	for(var/mob/viewer in range(10, loc))
		shake_camera(viewer, 2 SECONDS, viewer == caster ? 2 : 1)

	end_time = world.time + MASTER_SPARK_DURATION
	START_PROCESSING(SSfastprocess, src)

/obj/effect/master_spark/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	QDEL_LIST(segments)
	beam_turfs = null
	center_turfs = null
	hit_mobs = null
	caster = null
	on_end = null
	return ..()

/obj/effect/master_spark/process(seconds_per_tick)
	if(world.time >= end_time)
		finish()
		return PROCESS_KILL
	for(var/turf/target as anything in beam_turfs)
		burn_turf(target, seconds_per_tick)

/obj/effect/master_spark/proc/burn_turf(turf/target, seconds_per_tick)
	if(iswallturf(target) && !istype(target, /turf/simulated/wall/indestructible))
		target.dismantle_wall(TRUE)
	else if(ismineralturf(target))
		var/turf/simulated/mineral/rock = target
		rock.gets_drilled(caster, TRUE)
	else if(isfloorturf(target) && !istype(target, /turf/simulated/floor/plating))
		var/turf/simulated/floor/floor = target
		floor.make_plating(FALSE)

	for(var/atom/movable/thing as anything in target.contents.Copy())
		if(thing == caster || QDELETED(thing))
			continue
		if(isliving(thing))
			var/mob/living/victim = thing
			victim.apply_damage(MASTER_SPARK_MOB_DPS * seconds_per_tick, BURN, spread_damage = TRUE)
			if(!(victim in hit_mobs))
				hit_mobs += victim
				on_first_hit(victim)
		else if(isstructure(thing) || ismachinery(thing))
			var/obj/structure_or_machine = thing
			structure_or_machine.take_damage(MASTER_SPARK_OBJ_DPS * seconds_per_tick, BURN, LASER, FALSE)

/obj/effect/master_spark/proc/on_first_hit(mob/living/victim)
	to_chat(victim, span_userdanger("Вас поглощает ослепительный поток плазмы и отшвыривает прочь!"))
	victim.adjust_fire_stacks(MASTER_SPARK_FIRE_STACKS)
	victim.IgniteMob()
	var/turf/throw_target = get_ranged_target_turf(victim, beam_dir, MASTER_SPARK_KNOCKBACK_RANGE)
	if(throw_target && !victim.anchored)
		victim.throw_at(throw_target, MASTER_SPARK_KNOCKBACK_RANGE, 2, caster)
	victim.Knockdown(MASTER_SPARK_KNOCKDOWN_TIME)

/obj/effect/master_spark/proc/finish()
	STOP_PROCESSING(SSfastprocess, src)
	for(var/turf/target as anything in beam_turfs)
		if(!isspaceturf(target))
			new /obj/effect/temp_visual/master_spark_fire(target, (target in center_turfs))
	on_end?.Invoke()
	on_end = null
	for(var/obj/effect/master_spark_segment/segment as anything in segments)
		segment.fade_out()
	QDEL_IN(src, 5)

/obj/effect/master_spark_segment
	name = "Master Spark"
	icon = null
	layer = ABOVE_LIGHTING_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE
	light_range = 4
	light_power = 3
	light_color = "#7dd3fc"
	var/horizontal

/obj/effect/master_spark_segment/Initialize(mapload, beam_dir, list/tile_icons, first, last, anchor)
	. = ..()
	horizontal = (beam_dir & (EAST|WEST)) ? TRUE : FALSE
	SET_PLANE_EXPLICIT(src, ABOVE_LIGHTING_PLANE, loc)
	var/dx = (beam_dir & EAST) ? 1 : ((beam_dir & WEST) ? -1 : 0)
	var/dy = (beam_dir & NORTH) ? 1 : ((beam_dir & SOUTH) ? -1 : 0)

	var/list/new_overlays = list()
	for(var/i in first to last)
		var/along = horizontal ? dx * i : dy * i
		var/image/tile = image(tile_icons[(((along % 3) + 3) % 3) + 1])
		tile.pixel_x = dx * (i - anchor) * ICON_SIZE_X + (horizontal ? 0 : -ICON_SIZE_X)
		tile.pixel_y = dy * (i - anchor) * ICON_SIZE_Y + (horizontal ? -ICON_SIZE_Y : 0)
		new_overlays += tile

	if(first == 0)
		var/image/flare = image(get_master_spark_flare())
		flare.pixel_x = -ICON_SIZE_X - dx * (anchor * ICON_SIZE_X + ICON_SIZE_X / 2)
		flare.pixel_y = -ICON_SIZE_Y - dy * (anchor * ICON_SIZE_Y + ICON_SIZE_Y / 2)
		new_overlays += flare
	overlays = new_overlays

	add_filter("spark_glow", 1, drop_shadow_filter(x = 0, y = 0, size = 6, offset = 2, color = "#38bdf8aa"))

	var/matrix/thin = horizontal ? matrix(1, 0, 0, 0, 0.1, 0) : matrix(0.1, 0, 0, 0, 1, 0)
	var/matrix/wide = horizontal ? matrix(1, 0, 0, 0, 1.04, 0) : matrix(1.04, 0, 0, 0, 1, 0)
	var/matrix/narrow = horizontal ? matrix(1, 0, 0, 0, 0.94, 0) : matrix(0.94, 0, 0, 0, 1, 0)
	transform = thin
	alpha = 0
	animate(src, transform = wide, alpha = 255, time = 1, easing = CUBIC_EASING | EASE_OUT)
	for(var/pulse in 1 to MASTER_SPARK_DURATION)
		animate(transform = narrow, time = 0.5, easing = SINE_EASING)
		animate(transform = wide, time = 0.5, easing = SINE_EASING)

/obj/effect/master_spark_segment/proc/fade_out()
	set_light(0)
	var/matrix/thin = horizontal ? matrix(1, 0, 0, 0, 0, 0) : matrix(0, 0, 0, 0, 1, 0)
	animate(src, transform = thin, alpha = 0, time = 4, easing = CUBIC_EASING | EASE_IN)

/obj/effect/temp_visual/master_spark_fire
	name = "синее пламя"
	icon = 'icons/effects/fire.dmi'
	icon_state = "blue_1"
	layer = BELOW_MOB_LAYER
	randomdir = FALSE
	duration = MASTER_SPARK_FIRE_DURATION
	light_color = "#4f8cff"

/obj/effect/temp_visual/master_spark_fire/Initialize(mapload, emits_light = FALSE)
	icon_state = "blue_[rand(1, 3)]"
	. = ..()
	if(emits_light)
		set_light(3, 2)
	else
		set_light(2, 1.5)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, set_light), 0), duration - 2 SECONDS)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	animate(src, alpha = 255, time = duration - 2 SECONDS)
	animate(alpha = 0, time = 2 SECONDS)

/obj/effect/temp_visual/master_spark_fire/proc/on_entered(datum/source, mob/living/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(!isliving(arrived))
		return
	if(arrived.movement_type & MOVETYPES_NOT_TOUCHING_GROUND)
		return
	arrived.adjust_fire_stacks(MASTER_SPARK_FIRE_STACKS)
	arrived.IgniteMob()

/proc/get_master_spark_texture(beam_dir)
	var/key = "[beam_dir]"
	var/list/cached = GLOB.master_spark_textures[key]
	if(cached)
		return cached

	var/size = MASTER_SPARK_TEX_SIZE
	var/half = size / 2

	var/static/list/profile_stops = list(
		list(0, 255, 255, 255, 255),
		list(0.12, 224, 242, 254, 255),
		list(0.3, 125, 211, 252, 255),
		list(0.55, 56, 189, 248, 242),
		list(0.75, 37, 99, 235, 204),
		list(0.9, 30, 58, 138, 90),
		list(1, 30, 58, 138, 0),
	)
	var/icon/base = master_spark_blank(size, size)
	for(var/row in 1 to size)
		var/dist = abs(row - 0.5 - half) / half
		base.DrawBox(master_spark_gradient(profile_stops, dist), 1, row, size, row)

	var/icon/stripes = master_spark_blank(size, size)
	for(var/x in 0 to size - 1 step 12)
		var/wave = sin(360 * x / 48) * cos(360 * x / 96)
		var/stripe_half = round(max(0, wave) * 15)
		if(stripe_half > 1)
			stripes.DrawBox(rgb(240, 250, 255, 90), x + 1, half - stripe_half + 1, x + 4, half + stripe_half)
	base.Blend(stripes, ICON_OVERLAY)

	var/static/list/stream_colors = list(
		list(255, 255, 255),
		list(186, 230, 253),
		list(56, 189, 248),
		list(59, 130, 246),
		list(29, 78, 216),
	)
	var/static/list/stream_fade = list(0.2, 0.45, 0.7, 1)
	var/icon/streams = master_spark_blank(size, size)
	for(var/i in 1 to 40)
		var/start = rand(1, size)
		var/seg = max(1, round(rand(12, 48) / 4))
		var/across = round(half + (rand() * 2 - 1) * 38) + 1
		var/across_end = min(across + (prob(30) ? 1 : 0), size)
		var/list/stream_rgb = pick(stream_colors)
		var/intensity = 0.4 + rand() * 0.6
		for(var/s in 1 to length(stream_fade))
			var/color = rgb(stream_rgb[1], stream_rgb[2], stream_rgb[3], 255 * intensity * stream_fade[s])
			var/seg_start = ((start + (s - 1) * seg - 1) % size) + 1
			var/seg_end = seg_start + seg - 1
			streams.DrawBox(color, seg_start, across, min(seg_end, size), across_end)
			if(seg_end > size)
				streams.DrawBox(color, 1, across, seg_end - size, across_end)
	base.Blend(streams, ICON_OVERLAY)

	var/vertical = (beam_dir & (NORTH|SOUTH)) ? TRUE : FALSE
	switch(beam_dir)
		if(SOUTH)
			base.Turn(90)
		if(WEST)
			base.Turn(180)
		if(NORTH)
			base.Turn(270)

	var/list/tiles = list(new /icon, new /icon, new /icon)
	var/frame_shift = size / MASTER_SPARK_TEX_FRAMES
	for(var/frame in 1 to MASTER_SPARK_TEX_FRAMES)
		var/icon/frame_icon = icon(base)
		frame_icon.Shift(beam_dir, (frame - 1) * frame_shift, TRUE)
		for(var/t in 1 to 3)
			var/icon/piece = icon(frame_icon)
			var/offset = (t - 1) * ICON_SIZE_X
			if(vertical)
				piece.Crop(1, offset + 1, size, offset + ICON_SIZE_Y)
			else
				piece.Crop(offset + 1, 1, offset + ICON_SIZE_X, size)
			var/icon/tile = tiles[t]
			tile.Insert(piece, "", null, frame, FALSE, MASTER_SPARK_TEX_DELAY)

	GLOB.master_spark_textures[key] = tiles
	return tiles

/proc/get_master_spark_flare()
	if(GLOB.master_spark_flare)
		return GLOB.master_spark_flare
	var/static/list/flare_stops = list(
		list(0, 255, 255, 255, 255),
		list(0.25, 224, 242, 254, 255),
		list(0.55, 56, 189, 248, 200),
		list(0.8, 37, 99, 235, 90),
		list(1, 30, 58, 138, 0),
	)
	var/res = MASTER_SPARK_TEX_SIZE / 2
	var/icon/flare = master_spark_blank(res, res)
	for(var/y in 1 to res)
		for(var/x in 1 to res)
			var/dist = sqrt((x - 0.5 - res / 2) ** 2 + (y - 0.5 - res / 2) ** 2) / (res / 2)
			if(dist < 1)
				flare.DrawBox(master_spark_gradient(flare_stops, dist), x, y)
	flare.Scale(MASTER_SPARK_TEX_SIZE, MASTER_SPARK_TEX_SIZE)
	GLOB.master_spark_flare = flare
	return flare

/proc/master_spark_gradient(list/stops, position)
	for(var/i in 1 to length(stops) - 1)
		var/list/stop_from = stops[i]
		var/list/to_stop = stops[i + 1]
		if(position > to_stop[1])
			continue
		var/k = (position - stop_from[1]) / (to_stop[1] - stop_from[1])
		return rgb(
			stop_from[2] + (to_stop[2] - stop_from[2]) * k,
			stop_from[3] + (to_stop[3] - stop_from[3]) * k,
			stop_from[4] + (to_stop[4] - stop_from[4]) * k,
			stop_from[5] + (to_stop[5] - stop_from[5]) * k,
		)
	return rgb(0, 0, 0, 0)

/proc/master_spark_blank(width, height)
	var/icon/blank = icon('icons/effects/fire.dmi', "ash")
	blank.Scale(width, height)
	blank.DrawBox(null, 1, 1, width, height)
	return blank

#undef MASTER_SPARK_RANGE
#undef MASTER_SPARK_CHARGE_TIME
#undef MASTER_SPARK_DURATION
#undef MASTER_SPARK_MOB_DPS
#undef MASTER_SPARK_OBJ_DPS
#undef MASTER_SPARK_THEME_DELAY
#undef MASTER_SPARK_THEME_LENGTH
#undef MASTER_SPARK_KNOCKDOWN_TIME
#undef MASTER_SPARK_KNOCKBACK_RANGE
#undef MASTER_SPARK_SEGMENT
#undef MASTER_SPARK_STUN_TIME
#undef MASTER_SPARK_COOLDOWN
#undef MASTER_SPARK_FIRE_DURATION
#undef MASTER_SPARK_FIRE_STACKS
#undef MASTER_SPARK_TEX_SIZE
#undef MASTER_SPARK_TEX_FRAMES
#undef MASTER_SPARK_TEX_DELAY
