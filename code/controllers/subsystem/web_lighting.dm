#define WEB_LIGHTING_MARGIN 3

SUBSYSTEM_DEF(web_lighting)
	name = "Web Lighting"
	ss_flags = SS_BACKGROUND | SS_NO_INIT
	priority = FIRE_PRIORITY_AMBIENCE
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 0.5 SECONDS

	var/list/views = list()

/datum/controller/subsystem/web_lighting/fire(resumed)
	for(var/client/viewer as anything in views)
		var/datum/web_lighting_view/view = views[viewer]
		view.refresh()

/datum/controller/subsystem/web_lighting/proc/add_viewer(client/viewer)
	if(views[viewer])
		return
	views[viewer] = new /datum/web_lighting_view(viewer)

/datum/controller/subsystem/web_lighting/proc/remove_viewer(client/viewer)
	var/datum/web_lighting_view/view = views[viewer]
	if(!view)
		return
	views -= viewer
	qdel(view)

/datum/controller/subsystem/web_lighting/proc/forget(atom/movable/lighting_object/light)
	for(var/client/viewer as anything in views)
		var/datum/web_lighting_view/view = views[viewer]
		view.forget(light)

/datum/web_lighting_view
	var/client/owner
	var/list/shown = list()
	var/atom/movable/screen/web_lighting_cutoff/cutoff_screen

/datum/web_lighting_view/New(client/owner)
	src.owner = owner
	cutoff_screen = new

/datum/web_lighting_view/Destroy()
	for(var/atom/movable/lighting_object/light as anything in shown)
		owner.images -= light.web_image
	owner.screen -= cutoff_screen
	QDEL_NULL(cutoff_screen)
	shown = null
	owner = null
	return ..()

/datum/web_lighting_view/proc/refresh()
	var/turf/center = get_turf(owner.eye)
	var/list/visible = list()
	if(center)
		var/list/view_size = getviewsize(owner.view)
		var/radius = ceil(max(view_size[1], view_size[2]) / 2) + WEB_LIGHTING_MARGIN
		for(var/turf/seen as anything in RANGE_TURFS(radius, center))
			if(seen.lighting_object)
				visible[seen.lighting_object] = TRUE
	for(var/atom/movable/lighting_object/light as anything in shown - visible)
		owner.images -= light.web_image
	for(var/atom/movable/lighting_object/light as anything in visible - shown)
		owner.images += light.get_web_image()
	shown = visible
	cutoff_screen.update_cutoff(owner.mob, center)
	if(!(cutoff_screen in owner.screen))
		owner.screen += cutoff_screen

/datum/web_lighting_view/proc/forget(atom/movable/lighting_object/light)
	if(!shown[light])
		return
	shown -= light
	owner.images -= light.web_image

/atom/movable/screen/web_lighting_cutoff
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = LIGHTING_ABOVE_ALL
	blend_mode = BLEND_ADD
	color = COLOR_BLACK
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/web_lighting_cutoff/proc/update_cutoff(mob/viewer, turf/center)
	var/list/color_cutoffs = viewer?.lighting_color_cutoffs || list(0, 0, 0)
	var/cutoff = viewer?.lighting_cutoff || 0
	var/new_color = rgb(
		clamp((cutoff + color_cutoffs[1]) / LIGHTING_CUTOFF_FULLBRIGHT, 0, 1) * 255,
		clamp((cutoff + color_cutoffs[2]) / LIGHTING_CUTOFF_FULLBRIGHT, 0, 1) * 255,
		clamp((cutoff + color_cutoffs[3]) / LIGHTING_CUTOFF_FULLBRIGHT, 0, 1) * 255,
	)
	if(color != new_color)
		color = new_color
	var/new_plane = GET_NEW_PLANE(LIGHTING_PLANE, GET_TURF_PLANE_OFFSET(center))
	if(plane != new_plane)
		plane = new_plane

#undef WEB_LIGHTING_MARGIN
