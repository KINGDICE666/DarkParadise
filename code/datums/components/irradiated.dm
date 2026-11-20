/// Предмет получил достаточно сильный импульс и загрязнился.
/// Облучает того, кто его несёт, сам остывает, смывается и светится, только если сильно заражён.
/datum/component/irradiated
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/contamination = 0
	var/glowing = FALSE

/datum/component/irradiated/Initialize()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE

	ADD_TRAIT(parent, TRAIT_IRRADIATED, UNIQUE_TRAIT_SOURCE(src))
	START_PROCESSING(SSobj, src)

/datum/component/irradiated/RegisterWithParent()
	RegisterSignal(parent, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_clean))
	RegisterSignal(parent, COMSIG_GEIGER_COUNTER_SCAN, PROC_REF(on_geiger_counter_scan))

/datum/component/irradiated/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_COMPONENT_CLEAN_ACT,
		COMSIG_GEIGER_COUNTER_SCAN,
	))

/datum/component/irradiated/Destroy(force)
	var/atom/movable/parent_movable = parent
	parent_movable.remove_filter("rad_glow")
	REMOVE_TRAIT(parent, TRAIT_IRRADIATED, UNIQUE_TRAIT_SOURCE(src))
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/component/irradiated/proc/adjust_contamination(amount)
	contamination = clamp(contamination + amount, 0, RAD_ITEM_MAXIMUM_CONTAMINATION)
	if(contamination < RAD_ITEM_MINIMUM_CONTAMINATION)
		qdel(src)
		return

	var/should_glow = contamination >= RAD_ITEM_GLOW_LEVEL
	if(should_glow == glowing)
		return

	glowing = should_glow
	var/atom/movable/parent_movable = parent
	if(!glowing)
		parent_movable.remove_filter("rad_glow")
		return

	create_radiation_glow(parent_movable)

/datum/component/irradiated/process(seconds_per_tick)
	var/atom/movable/item = parent
	if(!isturf(item.loc))
		var/mob/living/carbon/human/holder = get(item, /mob/living/carbon/human)
		holder?.adjust_radiation_dose(contamination * RAD_ITEM_HOLDER_DOSE_FACTOR * seconds_per_tick)

	adjust_contamination(-contamination * RAD_ITEM_DECAY_FACTOR * seconds_per_tick)

/datum/component/irradiated/proc/on_clean(datum/source, clean_types)
	SIGNAL_HANDLER

	if(!(clean_types & CLEAN_TYPE_RADIATION))
		return NONE

	qdel(src)
	return COMPONENT_CLEANED|COMPONENT_CLEANED_GAIN_XP

/datum/component/irradiated/proc/on_geiger_counter_scan(datum/source, mob/user, obj/item/geiger_counter/geiger_counter)
	SIGNAL_HANDLER

	to_chat(user, span_bolddanger("[icon2html(geiger_counter, user)] Обнаружено загрязнение: [round(contamination)] рад."))
	return COMSIG_GEIGER_COUNTER_SCAN_SUCCESSFUL

/// Зелёный контур всего, что настолько радиоактивно, что видно глазом
/proc/create_radiation_glow(atom/movable/target)
	target.add_filter("rad_glow", 2, list("type" = "outline", "color" = "#39ff1430", "size" = 2))
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(start_radiation_glow_loop), target), randfloat(0.1 SECONDS, 1.9 SECONDS))

/proc/start_radiation_glow_loop(atom/movable/target)
	var/filter = target.get_filter("rad_glow")
	if(!filter)
		return

	animate(filter, alpha = 110, time = 1.5 SECONDS, loop = -1)
	animate(alpha = 40, time = 2.5 SECONDS)
