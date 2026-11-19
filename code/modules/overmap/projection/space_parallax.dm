#define SKY_VIEW_RANGE 3
#define SKY_SCREEN_REACH 300
#define SKY_SCREEN_CENTER 240
#define SKY_SPRITE_HALF 192
#define SKY_NEAR_SCALE 0.7
#define SKY_SCALE_MIN 0.3
#define SKY_SCALE_MAX 1.6
#define SKY_FADE_SHARE 0.25
#define SKY_MOVE_TIME (1 SECONDS)
#define SKY_PLANET_RADIUS 1.5
#define SKY_DEFAULT_LIGHT_ANGLE 60
#define SKY_SPRITE_LIGHT_ANGLE 90
#define SKY_MOTION_PARALLAX 0.12
#define SKY_LENS_TARGET "*overmap_lens"
#define SKY_LENS_FILTER "overmap_lens"
#define SKY_LENS_STRENGTH 28
#define SKY_LENS_NEUTRAL list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5)
#define SPACE_DUST_RATE 8
#define SPACE_STREAK_SPEED_MIN 12
#define SPACE_STREAK_SPEED_MAX 40

GLOBAL_LIST_EMPTY(overmap_sky_bodies)

/obj/overmap/proc/sky_state()
	return null

/obj/overmap/proc/sky_colour()
	return null

/obj/overmap/proc/sky_overlays()
	return null

/obj/overmap/proc/sky_light_angle()
	return null

/obj/overmap/proc/sky_center()
	return list(x, y)

/obj/overmap/proc/sky_radius()
	return 1

/obj/overmap/proc/sky_core()
	return 0

/obj/overmap/celestial/sky_radius()
	return gravity_radius

/obj/overmap/celestial/sky_core()
	return core_radius

/obj/overmap/celestial/star/sky_state()
	return "star_corona"

/obj/overmap/celestial/star/sky_colour()
	return map_color

/obj/overmap/celestial/star/sky_overlays()
	return list("star_core")

/obj/overmap/celestial/black_hole/sky_state()
	return "black_hole"

/obj/overmap/planet/sky_state()
	return SSmapping.lavaland_theme?.planet_icon_state || "planet"

/obj/overmap/planet/sky_center()
	return list(x + (footprint - 1) / 2, y + (footprint - 1) / 2)

/obj/overmap/planet/sky_radius()
	return footprint * SKY_PLANET_RADIUS

/obj/overmap/planet/sky_core()
	return footprint / 2

/obj/overmap/planet/sky_overlays()
	return list("planet_shadow", "planet_rim")

/obj/overmap/planet/sky_light_angle()
	var/list/center = sky_center()
	var/obj/overmap/celestial/star/nearest
	var/nearest_distance
	for(var/obj/overmap/celestial/star/star in GLOB.overmap_celestials)
		if(star.sector != sector || !isturf(star.loc))
			continue
		var/distance = (star.x - center[1]) ** 2 + (star.y - center[2]) ** 2
		if(!nearest || distance < nearest_distance)
			nearest = star
			nearest_distance = distance
	if(!nearest)
		return SKY_DEFAULT_LIGHT_ANGLE
	return round(delta_to_angle(nearest.x - center[1], nearest.y - center[2]))

/atom/movable/screen/parallax_layer/layer_2/proc/set_star_field(state)
	if(icon_state == state)
		return
	icon_state = state
	update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/parallax_layer/sky
	icon_state = "sky_pivot"
	blend_mode = BLEND_OVERLAY
	absolute = TRUE
	speed = SKY_MOTION_PARALLAX
	layer = 30
	environment_tinted = FALSE
	var/list/atom/movable/screen/parallax_body/shown = list()
	var/sky_heading = 0
	var/client/viewer
	var/atom/movable/screen/sky_lens/lens
	var/list/lens_point

/atom/movable/screen/parallax_layer/sky/Initialize(mapload, datum/hud/hud_owner, client/owner, template = FALSE)
	. = ..()
	viewer = owner

/atom/movable/screen/parallax_layer/sky/Destroy()
	QDEL_LIST_ASSOC_VAL(shown)
	lens_point = null
	refresh_lens()
	viewer = null
	return ..()

/atom/movable/screen/parallax_layer/sky/update_o(new_view)
	return

/atom/movable/screen/parallax_layer/sky/set_ship_facing(angle, time)
	if(angle == sky_heading)
		return
	sky_heading = angle
	animate(src, transform = matrix().Turn(-angle), time = time)
	refresh_lens(time)

/atom/movable/screen/parallax_layer/sky/proc/refresh_lens(time = 0)
	var/atom/movable/screen/plane_master/parallax_plane = viewer?.mob?.hud_used?.get_plane_master(PLANE_SPACE_PARALLAX)
	if(!lens_point || !parallax_plane || QDELETED(src))
		parallax_plane?.remove_filter(SKY_LENS_FILTER)
		if(lens)
			viewer?.screen -= lens
			QDEL_NULL(lens)
		return
	var/scale = lens_point[3]
	var/matrix/lens_turn = matrix(scale, 0, 0, 0, scale, 0)
	lens_turn.Turn(-sky_heading)
	if(!lens)
		lens = new
		lens.transform = lens_turn
		viewer.screen += lens
	animate(lens, transform = lens_turn, time = time)
	var/turn_cos = cos(sky_heading)
	var/turn_sin = sin(sky_heading)
	var/lens_x = round(lens_point[1] * turn_cos - lens_point[2] * turn_sin + pixel_w)
	var/lens_y = round(lens_point[1] * turn_sin + lens_point[2] * turn_cos + pixel_z)
	var/lens_size = round(SKY_LENS_STRENGTH * scale)
	if(parallax_plane.get_filter(SKY_LENS_FILTER))
		parallax_plane.transition_filter(SKY_LENS_FILTER, list("x" = lens_x, "y" = lens_y, "size" = lens_size), time)
	else
		parallax_plane.add_filter(SKY_LENS_FILTER, 1, displacement_map_filter(render_source = SKY_LENS_TARGET, x = lens_x, y = lens_y, size = lens_size))

/atom/movable/screen/parallax_layer/sky/clear_ship_drift()
	return

/atom/movable/screen/parallax_layer/sky/proc/show_bodies(datum/overmap_sector/sector, list/point, heading)
	if(!isnull(heading))
		set_ship_facing(heading, 0)
	var/list/seen = list()
	var/list/new_lens
	if(sector && point)
		var/span = OVERMAP_TILE_SPAN * (sector.tile_travel || 1)
		for(var/obj/overmap/body as anything in GLOB.overmap_sky_bodies)
			if(body.sector != sector || !isturf(body.loc) || !body.sky_state())
				continue
			var/list/center = body.sky_center()
			var/radius = body.sky_radius()
			var/offset_x = center[1] - point[1] / span
			var/offset_y = center[2] - point[2] / span
			var/distance = sqrt(offset_x ** 2 + offset_y ** 2)
			var/view_range = radius * SKY_VIEW_RANGE
			if(distance >= view_range)
				continue
			var/reach = SKY_SCREEN_REACH / (distance + radius)
			var/screen_x = offset_x * reach
			var/screen_y = offset_y * reach
			var/scale = clamp(radius * SKY_NEAR_SCALE / max(distance, body.sky_core(), 0.1), SKY_SCALE_MIN, SKY_SCALE_MAX)
			var/fade = clamp((view_range - distance) / (view_range * SKY_FADE_SHARE), 0, 1)
			var/key = body.UID()
			var/atom/movable/screen/parallax_body/sprite = shown[key]
			if(!sprite)
				sprite = new
				shown[key] = sprite
				vis_contents += sprite
			sprite.refresh(body)
			sprite.place(screen_x, screen_y, scale, fade)
			seen[key] = TRUE
	for(var/key in shown)
		if(seen[key])
			continue
		var/atom/movable/screen/parallax_body/sprite = shown[key]
		shown -= key
		vis_contents -= sprite
		qdel(sprite)
	if(!(new_lens ~= lens_point))
		lens_point = new_lens
		refresh_lens()

/atom/movable/screen/parallax_body
	icon = 'icons/effects/parallax_bodies.dmi'
	plane = PLANE_SPACE_PARALLAX
	blend_mode = BLEND_OVERLAY
	appearance_flags = RESET_COLOR | NO_CLIENT_COLOR | PIXEL_SCALE | KEEP_TOGETHER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	var/list/overlay_states
	var/sun_angle
	var/list/placed

/atom/movable/screen/parallax_body/update_overlays()
	. = ..()
	for(var/state in overlay_states)
		var/mutable_appearance/layer_overlay = mutable_appearance(icon, state, appearance_flags = RESET_COLOR)
		if(!isnull(sun_angle))
			layer_overlay.transform = matrix().Turn(sun_angle - SKY_SPRITE_LIGHT_ANGLE)
		. += layer_overlay

/atom/movable/screen/parallax_body/proc/refresh(obj/overmap/body)
	var/state = body.sky_state()
	var/colour = body.sky_colour()
	var/list/overlays_wanted = body.sky_overlays()
	var/angle = body.sky_light_angle()
	if(state == icon_state && colour == color && overlays_wanted ~= overlay_states && angle == sun_angle)
		return
	icon_state = state
	color = colour
	overlay_states = overlays_wanted
	sun_angle = angle
	update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/parallax_body/proc/place(screen_x, screen_y, scale, fade)
	var/corner = SKY_SCREEN_CENTER - SKY_SPRITE_HALF
	var/list/target = list(round(corner + screen_x), round(corner + screen_y), round(scale, 0.01), round(255 * fade))
	if(placed ~= target)
		return
	placed = target
	animate(src, pixel_w = target[1], pixel_z = target[2], transform = matrix(target[3], 0, 0, 0, target[3], 0), alpha = target[4], time = SKY_MOVE_TIME)

/atom/movable/screen/sky_lens
	icon = 'icons/effects/parallax_bodies.dmi'
	icon_state = "black_hole_lens"
	screen_loc = "CENTER"
	render_target = SKY_LENS_TARGET
	appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_TRANSFORM | KEEP_TOGETHER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/sky_lens/update_overlays()
	. = ..()
	var/mutable_appearance/hole = mutable_appearance(icon, "black_hole")
	hole.color = SKY_LENS_NEUTRAL
	. += hole

/atom/movable/screen/sky_lens/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/particles/space_dust
	icon = 'icons/effects/particles/space_dust.dmi'
	icon_state = "dust"
	width = 1200
	height = 1000
	count = 200
	spawning = 0
	lifespan = 4 SECONDS
	fade = 1.5 SECONDS
	fadein = 1 SECONDS
	position = generator(GEN_BOX, list(-100, -40), list(560, 500), UNIFORM_RAND)
	velocity = generator(GEN_CIRCLE, 0, 0.6, NORMAL_RAND)

/atom/movable/screen/parallax_layer/dust
	icon = null
	icon_state = null
	absolute = TRUE
	speed = 0
	layer = 25
	environment_tinted = FALSE

/atom/movable/screen/parallax_layer/dust/Initialize(mapload, datum/hud/hud_owner, client/owner, template = FALSE)
	. = ..()
	particles = new /particles/space_dust

/atom/movable/screen/parallax_layer/dust/Destroy()
	QDEL_NULL(particles)
	return ..()

/atom/movable/screen/parallax_layer/dust/update_o(new_view)
	return

/atom/movable/screen/parallax_layer/dust/proc/set_haze(colour, strength)
	particles.spawning = round(strength * SPACE_DUST_RATE, 0.1)
	if(colour)
		particles.color = colour

/atom/movable/screen/parallax_layer/streaks
	icon_state = "streaks"
	speed = 1.6
	layer = 4
	alpha = 0
	environment_tinted = FALSE
	var/streak_angle = 0

/atom/movable/screen/parallax_layer/streaks/set_ship_velocity(speed_x, speed_y)
	var/display_speed = OVERMAP_DISPLAY_SPEED(sqrt(speed_x ** 2 + speed_y ** 2))
	var/strength = clamp((display_speed - SPACE_STREAK_SPEED_MIN) / (SPACE_STREAK_SPEED_MAX - SPACE_STREAK_SPEED_MIN), 0, 1)
	if(strength)
		streak_angle = -arctan(speed_x, speed_y)
	var/target = round(255 * strength)
	if(alpha != target)
		alpha = target

/atom/movable/screen/parallax_layer/streaks/set_ship_drift(step_x, step_y, angle, time)
	var/next = drift_x - sqrt(step_x ** 2 + step_y ** 2) * speed
	if(abs(next) > PARALLAX_TILE_SIZE / 2)
		var/wrap = -sign(next) * PARALLAX_TILE_SIZE
		transform = streak_matrix(drift_x + wrap, angle)
		next += wrap
	drift_x = next
	drift_angle = angle
	animate(src, transform = streak_matrix(drift_x, angle), time = time)

/atom/movable/screen/parallax_layer/streaks/clear_ship_drift()
	. = ..()
	alpha = 0

/atom/movable/screen/parallax_layer/streaks/proc/streak_matrix(offset, angle)
	var/matrix/drifted = matrix()
	drifted.Translate(offset, 0)
	drifted.Turn(streak_angle - angle)
	return drifted

#undef SKY_VIEW_RANGE
#undef SKY_SCREEN_REACH
#undef SKY_SCREEN_CENTER
#undef SKY_SPRITE_HALF
#undef SKY_NEAR_SCALE
#undef SKY_SCALE_MIN
#undef SKY_SCALE_MAX
#undef SKY_FADE_SHARE
#undef SKY_MOVE_TIME
#undef SKY_PLANET_RADIUS
#undef SKY_DEFAULT_LIGHT_ANGLE
#undef SKY_SPRITE_LIGHT_ANGLE
#undef SKY_MOTION_PARALLAX
#undef SKY_LENS_TARGET
#undef SKY_LENS_FILTER
#undef SKY_LENS_STRENGTH
#undef SKY_LENS_NEUTRAL
#undef SPACE_DUST_RATE
#undef SPACE_STREAK_SPEED_MIN
#undef SPACE_STREAK_SPEED_MAX
