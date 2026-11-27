/// Atoms with this component will play sounds depending on nearby radiation
/datum/component/geiger_sound
	var/datum/looping_sound/geiger/sound

/datum/component/geiger_sound/Initialize(...)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/geiger_sound/Destroy(force)
	QDEL_NULL(sound)
	return ..()

/datum/component/geiger_sound/RegisterWithParent()
	sound = new(parent)
	RegisterSignal(parent, COMSIG_RADIATION_DETECTED, PROC_REF(on_radiation_detected))
	SSradiation.add_listener(parent)

/datum/component/geiger_sound/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_RADIATION_DETECTED)
	SSradiation.remove_listener(parent)

/datum/component/geiger_sound/proc/on_radiation_detected(datum/source, rads, turf/source_turf)
	SIGNAL_HANDLER

	sound.last_danger = get_perceived_radiation_danger(rads)
	sound.start()

	addtimer(CALLBACK(sound, TYPE_PROC_REF(/datum/looping_sound, stop)), TIME_WITHOUT_RADIATION_BEFORE_RESET, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/looping_sound/geiger
	mid_sounds = list(
		list('sound/items/geiger/low1.ogg' = 1, 'sound/items/geiger/low2.ogg' = 1, 'sound/items/geiger/low3.ogg' = 1, 'sound/items/geiger/low4.ogg' = 1),
		list('sound/items/geiger/med1.ogg' = 1, 'sound/items/geiger/med2.ogg' = 1, 'sound/items/geiger/med3.ogg' = 1, 'sound/items/geiger/med4.ogg' = 1),
		list('sound/items/geiger/high1.ogg' = 1, 'sound/items/geiger/high2.ogg' = 1, 'sound/items/geiger/high3.ogg' = 1, 'sound/items/geiger/high4.ogg' = 1),
		list('sound/items/geiger/ext1.ogg' = 1, 'sound/items/geiger/ext2.ogg' = 1, 'sound/items/geiger/ext3.ogg' = 1, 'sound/items/geiger/ext4.ogg' = 1),
	)
	mid_length = 2
	volume = 25

	var/last_danger

/datum/looping_sound/geiger/get_sound()
	if(isnull(last_danger))
		return null

	return ..(mid_sounds[last_danger])

/datum/looping_sound/geiger/stop(null_parent = FALSE)
	. = ..()

	last_danger = null
