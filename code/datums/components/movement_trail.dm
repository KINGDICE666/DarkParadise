#define TRAIL_REMOVE "remove"
#define TRAIL_MAX_DURATION_SECONDS 10
#define TRAIL_DEFAULT_ALPHA 150

/datum/component/movement_trail
	var/trail_type
	var/duration
	var/trail_color
	var/trail_alpha
	var/emit_time = 0.3 SECONDS
	var/particles/particle_template

/datum/component/movement_trail/Initialize(trail_type = TRAIL_AFTERIMAGE, duration = 0.5 SECONDS, trail_color, trail_alpha = TRAIL_DEFAULT_ALPHA, particles/particle_template)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	if(trail_type == TRAIL_PARTICLES && !particle_template)
		return COMPONENT_INCOMPATIBLE

	src.trail_type = trail_type
	src.duration = duration
	src.trail_color = trail_color
	src.trail_alpha = trail_alpha
	src.particle_template = particle_template

/datum/component/movement_trail/Destroy(force)
	QDEL_NULL(particle_template)
	return ..()

/datum/component/movement_trail/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/component/movement_trail/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)

/datum/component/movement_trail/proc/on_moved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER

	if(!isturf(old_loc) || !isturf(source.loc))
		return

	switch(trail_type)
		if(TRAIL_AFTERIMAGE)
			new /obj/effect/temp_visual/trail_afterimage(old_loc, source, duration, trail_color, trail_alpha)
		if(TRAIL_PARTICLES)
			new /obj/effect/temp_visual/trail_particles(old_loc, particle_template, duration, emit_time)

/obj/effect/temp_visual/trail_afterimage
	randomdir = FALSE

/obj/effect/temp_visual/trail_afterimage/Initialize(mapload, atom/movable/copied, duration, trail_color, trail_alpha)
	src.duration = duration
	. = ..()
	appearance = copied.appearance
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	particles = null
	if(trail_color)
		color = trail_color
	alpha = trail_alpha
	animate(src, alpha = 0, time = duration)

/obj/effect/temp_visual/trail_particles
	randomdir = FALSE

/obj/effect/temp_visual/trail_particles/Initialize(mapload, particles/particle_template, duration, emit_time)
	src.duration = duration
	. = ..()
	particles = particle_template.clone()
	addtimer(VARSET_CALLBACK(particles, spawning, 0), emit_time)

/obj/effect/temp_visual/trail_particles/Destroy()
	QDEL_NULL(particles)
	return ..()

/client/proc/configure_movement_trail(atom/movable/target, particles/particle_template)
	var/trail_type = TRAIL_PARTICLES
	if(!particle_template)
		var/list/options = list("Послеобраз" = TRAIL_AFTERIMAGE, "Частицы" = TRAIL_PARTICLES)
		if(target.GetComponent(/datum/component/movement_trail))
			options["Убрать шлейф"] = TRAIL_REMOVE
		var/choice = tgui_input_list(mob, "Какой шлейф оставляет [target]?", "Шлейф", options)
		if(!choice || QDELETED(target))
			return
		trail_type = options[choice]

	if(trail_type == TRAIL_REMOVE)
		qdel(target.GetComponent(/datum/component/movement_trail))
		log_and_message_admins("removed the movement trail from [target].")
		return

	if(trail_type == TRAIL_PARTICLES && !particle_template)
		if(target.particles && tgui_alert(mob, "Использовать текущие частицы [target] для шлейфа?", "Шлейф", list("Да", "Нет")) == "Да")
			particle_template = target.particles.clone()
		else
			var/particle_path = pick_closest_path(/particles, make_types_fancy(typesof(/particles)))
			if(!particle_path)
				return
			particle_template = new particle_path

	var/default_duration = trail_type == TRAIL_PARTICLES ? 2 : 0.5
	var/duration = tgui_input_number(mob, "Сколько секунд живёт каждый след?", "Шлейф", default_duration, TRAIL_MAX_DURATION_SECONDS, 0.1, round_value = FALSE)
	if(!duration)
		return

	var/trail_color
	var/trail_alpha = TRAIL_DEFAULT_ALPHA
	if(trail_type == TRAIL_AFTERIMAGE)
		trail_color = tgui_input_color(mob, "Цвет послеобраза (белый — без изменений)", "Шлейф", COLOR_WHITE)
		if(!trail_color)
			return
		if(cmptext(trail_color, COLOR_WHITE))
			trail_color = null
		trail_alpha = tgui_input_number(mob, "Начальная непрозрачность (1-255)", "Шлейф", TRAIL_DEFAULT_ALPHA, 255, 1)
		if(!trail_alpha)
			return

	if(QDELETED(target))
		return
	target.AddComponent(/datum/component/movement_trail, trail_type, duration SECONDS, trail_color, trail_alpha, particle_template)
	log_and_message_admins("added a [trail_type] movement trail to [target].")

#undef TRAIL_REMOVE
#undef TRAIL_MAX_DURATION_SECONDS
#undef TRAIL_DEFAULT_ALPHA
