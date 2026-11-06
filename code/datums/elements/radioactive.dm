#define DELAY_BETWEEN_RADIATION_PULSES (3 SECONDS)

/// This atom will regularly pulse radiation.
/datum/element/radioactive
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY | ELEMENT_BESPOKE
	argument_hash_start_idx = 2
	/// Сила импульсов
	var/rads

	var/list/radioactive_objects = list()

/datum/element/radioactive/New()
	START_PROCESSING(SSdcs, src)

/datum/element/radioactive/Attach(datum/target, rads = RAD_PULSE_URANIUM_ITEM)
	. = ..()

	radioactive_objects[target] = world.time

	src.rads = rads

/datum/element/radioactive/Detach(datum/source, ...)
	radioactive_objects -= source
	return ..()

/datum/element/radioactive/process(seconds_per_tick)
	for(var/radioactive_object in radioactive_objects)
		if(world.time - radioactive_objects[radioactive_object] < DELAY_BETWEEN_RADIATION_PULSES)
			continue

		radiation_pulse(radioactive_object, rads)

		radioactive_objects[radioactive_object] = world.time

#undef DELAY_BETWEEN_RADIATION_PULSES
