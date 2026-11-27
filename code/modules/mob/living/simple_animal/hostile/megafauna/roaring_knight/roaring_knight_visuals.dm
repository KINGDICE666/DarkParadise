/proc/fire_knight_bullet(bullet_type, turf/start, angle, atom/shooter, flight_range)
	if(!start)
		return
	var/obj/projectile/roaring_knight/bullet = new bullet_type(start)
	bullet.preparePixelProjectile(get_turf_in_angle(angle, start, 7) || start, start)
	if(ismob(shooter) && !QDELETED(shooter))
		bullet.firer = shooter
	if(flight_range)
		bullet.range = flight_range
	bullet.fire(angle)

/obj/projectile/roaring_knight
	name = "dark shard"
	icon = 'icons/mob/roaring_knight/bullets.dmi'
	icon_state = "starchild"
	pixel_w = -48
	pixel_z = -48
	plane = ABOVE_LIGHTING_PLANE
	damage = 8
	armour_penetration = 30
	speed = 1.5
	hitsound = 'sound/weapons/bladeslice.ogg'

/obj/projectile/roaring_knight/get_ru_names()
	return alist(
		NOMINATIVE = "тёмный осколок",
		GENITIVE = "тёмного осколка",
		DATIVE = "тёмному осколку",
		ACCUSATIVE = "тёмный осколок",
		INSTRUMENTAL = "тёмным осколком",
		PREPOSITIONAL = "тёмном осколке",
	)

/obj/projectile/roaring_knight/prehit(atom/target)
	nodamage = is_knight_ally(target)
	damage = nodamage ? 0 : initial(damage)
	return ..()

/obj/projectile/roaring_knight/tooth
	name = "dark tooth"
	icon_state = "tooth"
	damage = 10
	speed = 2

/obj/projectile/roaring_knight/tooth/get_ru_names()
	return alist(
		NOMINATIVE = "тёмный клык",
		GENITIVE = "тёмного клыка",
		DATIVE = "тёмному клыку",
		ACCUSATIVE = "тёмный клык",
		INSTRUMENTAL = "тёмным клыком",
		PREPOSITIONAL = "тёмном клыке",
	)

/obj/projectile/roaring_knight/sword
	name = "dark sword"
	icon_state = "sword"
	damage = 15
	speed = 1
	forcedodge = -1

/obj/projectile/roaring_knight/sword/get_ru_names()
	return alist(
		NOMINATIVE = "тёмный меч",
		GENITIVE = "тёмного меча",
		DATIVE = "тёмному мечу",
		ACCUSATIVE = "тёмный меч",
		INSTRUMENTAL = "тёмным мечом",
		PREPOSITIONAL = "тёмном мече",
	)

/obj/projectile/roaring_knight/star
	name = "dark star"
	icon_state = "star"
	damage = 20
	speed = 3

/obj/projectile/roaring_knight/star/get_ru_names()
	return alist(
		NOMINATIVE = "тёмная звезда",
		GENITIVE = "тёмной звезды",
		DATIVE = "тёмной звезде",
		ACCUSATIVE = "тёмную звезду",
		INSTRUMENTAL = "тёмной звездой",
		PREPOSITIONAL = "тёмной звезде",
	)

/obj/projectile/roaring_knight/star/on_hit(atom/target, blocked = 0, hit_zone)
	. = ..()
	new /obj/effect/temp_visual/roaring_knight/bullet/star_bloom(get_turf(src), firer)

/obj/projectile/roaring_knight/star/on_range()
	new /obj/effect/temp_visual/roaring_knight/bullet/star_bloom(get_turf(src), firer)
	return ..()

/obj/effect/temp_visual/roaring_knight
	icon = 'icons/mob/roaring_knight/vfx.dmi'
	icon_state = "red_slash"
	plane = ABOVE_LIGHTING_PLANE
	appearance_flags = PIXEL_SCALE
	randomdir = FALSE
	pixel_x = -144
	pixel_y = -144
	duration = 0.5 SECONDS

/obj/effect/temp_visual/roaring_knight/red_slash

/obj/effect/temp_visual/roaring_knight/red_slash/Initialize(mapload, angle = 0)
	. = ..()
	var/matrix/turned = matrix()
	turned.Turn(angle)
	transform = turned

/obj/effect/temp_visual/roaring_knight/red_slash_hit
	icon_state = "red_slash_hit"
	duration = 1.3 SECONDS

/obj/effect/temp_visual/roaring_knight/red_slash_hit/Initialize(mapload, angle = 0)
	. = ..()
	var/matrix/turned = matrix()
	turned.Turn(angle)
	transform = turned

/obj/effect/temp_visual/roaring_knight/line
	icon_state = "slash_marker"
	var/sprite_length = 250

/obj/effect/temp_visual/roaring_knight/line/Initialize(mapload, angle = 0, tiles = 1)
	. = ..()
	var/matrix/stretched = matrix()
	stretched.Scale(tiles * 2 * ICON_SIZE_X / sprite_length, 1)
	stretched.Turn(angle - 90)
	transform = stretched

/obj/effect/temp_visual/roaring_knight/line/warning
	icon_state = "slash_marker_dark"
	duration = 0.45 SECONDS

/obj/effect/temp_visual/roaring_knight/line/slash
	icon_state = "quickslash"
	duration = 0.4 SECONDS

/obj/effect/temp_visual/roaring_knight/crescent
	icon_state = "crescent"
	duration = 0.4 SECONDS

/obj/effect/temp_visual/roaring_knight/crescent/Initialize(mapload, angle = 0)
	. = ..()
	var/matrix/turned = matrix()
	turned.Scale(1.5, 1.5)
	turned.Turn(angle - 45)
	transform = turned
	animate(src, alpha = 0, time = duration, easing = EASE_IN)

/obj/effect/temp_visual/roaring_knight/swipe
	icon_state = "swipe"
	duration = 1.1 SECONDS

/obj/effect/temp_visual/roaring_knight/sword_break_ring
	icon_state = "sword_break_ring"
	duration = 0.6 SECONDS

/obj/effect/temp_visual/roaring_knight/glint
	icon_state = "glint"
	duration = 0.3 SECONDS

/obj/effect/temp_visual/roaring_knight/bubble_blow
	icon_state = "bubble_blow"
	duration = 1.2 SECONDS

/obj/effect/temp_visual/roaring_knight/tile_warning
	icon = 'icons/mob/roaring_knight/effects.dmi'
	icon_state = "tile_warning"
	pixel_x = 0
	pixel_y = 0
	duration = 0.8 SECONDS

/obj/effect/temp_visual/roaring_knight/soul
	icon = 'icons/mob/roaring_knight/effects.dmi'
	icon_state = "soul"
	pixel_x = 0
	pixel_y = 0
	duration = 0.8 SECONDS

/obj/effect/temp_visual/roaring_knight/soul/Initialize(mapload, atom/destination)
	. = ..()
	if(!destination)
		return
	animate(src, pixel_x = (destination.x - x) * ICON_SIZE_X, pixel_y = (destination.y - y) * ICON_SIZE_Y, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/obj/effect/temp_visual/roaring_knight/bullet
	icon = 'icons/mob/roaring_knight/bullets.dmi'
	icon_state = "sword"
	pixel_x = -48
	pixel_y = -48

/obj/effect/temp_visual/roaring_knight/bullet/sword_ready/Initialize(mapload, angle = 0)
	. = ..()
	var/matrix/turned = matrix()
	turned.Turn(angle)
	transform = turned
	alpha = 0
	animate(src, alpha = 255, time = 0.25 SECONDS)

/obj/effect/temp_visual/roaring_knight/bullet/dark_fire
	icon_state = "dark_fire"
	duration = 0.6 SECONDS

/obj/effect/temp_visual/roaring_knight/bullet/awaken
	icon_state = "star_flash"
	duration = 0.3 SECONDS

/obj/effect/temp_visual/roaring_knight/bullet/planted_sword

/obj/effect/temp_visual/roaring_knight/bullet/planted_sword/Initialize(mapload)
	. = ..()
	var/matrix/turned = matrix()
	turned.Turn(180)
	transform = turned
	pixel_y += 96
	animate(src, pixel_y = pixel_y - 96, time = 0.2 SECONDS, easing = EASE_IN)

/obj/effect/temp_visual/roaring_knight/bullet/star_bloom
	icon_state = "star_split"
	duration = 0.7 SECONDS
	var/mob/shooter

/obj/effect/temp_visual/roaring_knight/bullet/star_bloom/Initialize(mapload, mob/shooter)
	. = ..()
	src.shooter = shooter
	addtimer(CALLBACK(src, PROC_REF(scatter)), 0.6 SECONDS)

/obj/effect/temp_visual/roaring_knight/bullet/star_bloom/Destroy()
	shooter = null
	return ..()

/obj/effect/temp_visual/roaring_knight/bullet/star_bloom/proc/scatter()
	icon_state = "star_flash"
	playsound(src, 'sound/magic/mm_hit.ogg', 50, TRUE)
	for(var/angle in 0 to 315 step 45)
		fire_knight_bullet(/obj/projectile/roaring_knight, get_turf(src), angle, shooter, 7)
