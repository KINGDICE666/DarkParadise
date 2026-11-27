/datum/element/atmos_sensitive
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY

/datum/element/atmos_sensitive/Attach(datum/target, mapload)
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	var/atom/to_track = target
	if(to_track.loc)
		to_track.RegisterSignal(to_track.loc, COMSIG_TURF_EXPOSE, TYPE_PROC_REF(/atom, check_atmos_process))
	RegisterSignal(to_track, COMSIG_MOVABLE_MOVED, PROC_REF(react_to_move))

	if(!mapload && isturf(to_track.loc))
		to_track.atmos_conditions_changed()

	return ..()

/datum/element/atmos_sensitive/Detach(atom/source)
	if(source.loc)
		source.UnregisterSignal(source.loc, COMSIG_TURF_EXPOSE)
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	if(source.flags & ATMOS_IS_PROCESSING)
		source.atmos_end()
		SSair.atom_process -= source
		source.flags &= ~ATMOS_IS_PROCESSING
	return ..()

/datum/element/atmos_sensitive/proc/react_to_move(atom/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER

	if(old_loc)
		source.UnregisterSignal(old_loc, COMSIG_TURF_EXPOSE)
	if(source.loc)
		source.RegisterSignal(source.loc, COMSIG_TURF_EXPOSE, TYPE_PROC_REF(/atom, check_atmos_process))
	source.atmos_conditions_changed()

/atom/proc/check_atmos_process(datum/source, datum/gas_mixture/air, exposed_temperature)
	SIGNAL_HANDLER
	if(should_atmos_process(air, exposed_temperature))
		if(flags & ATMOS_IS_PROCESSING)
			return
		SSair.atom_process += src
		flags |= ATMOS_IS_PROCESSING
	else if(flags & ATMOS_IS_PROCESSING)
		atmos_end()
		SSair.atom_process -= src
		flags &= ~ATMOS_IS_PROCESSING

/atom/proc/process_exposure()
	var/turf/spot = loc
	if(!isturf(spot) || spot.blocks_air)
		atmos_end()
		SSair.atom_process -= src
		flags &= ~ATMOS_IS_PROCESSING
		return
	var/datum/gas_mixture/air = spot.get_readonly_air()
	if(!should_atmos_process(air, air.temperature()))
		atmos_end()
		SSair.atom_process -= src
		flags &= ~ATMOS_IS_PROCESSING
		return
	atmos_expose(air, air.temperature())

/atom/proc/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return FALSE

/atom/proc/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	return

/atom/proc/atmos_end()
	return

/atom/proc/atmos_conditions_changed()
	return

/atom/movable/atmos_conditions_changed()
	var/turf/spot = loc
	if(!isturf(spot) || spot.blocks_air)
		return
	var/datum/gas_mixture/air = spot.get_readonly_air()
	check_atmos_process(spot, air, air.temperature())
