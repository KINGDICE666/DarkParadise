/// All active /datum/atom_hud/alternate_appearance/basic/has_antagonist instances.
GLOBAL_LIST_EMPTY_TYPED(has_antagonist_huds, /datum/atom_hud/alternate_appearance/basic/has_antagonist)

/// An alternate appearance that only shows to mobs with the given antag datum or team.
/datum/atom_hud/alternate_appearance/basic/has_antagonist
	var/antag_datum_type
	var/datum/weakref/team_ref

/datum/atom_hud/alternate_appearance/basic/has_antagonist/New(key, image/hud, antag_datum_type, datum/weakref/team)
	if(antag_datum_type)
		src.antag_datum_type = antag_datum_type
	src.team_ref = team
	GLOB.has_antagonist_huds += src
	return ..(key, hud, NONE)

/datum/atom_hud/alternate_appearance/basic/has_antagonist/Destroy(force)
	GLOB.has_antagonist_huds -= src
	return ..()

/datum/atom_hud/alternate_appearance/basic/has_antagonist/mob_should_see(mob/viewer)
	if(add_ghost_version && isobserver(viewer))
		return FALSE

	var/datum/team/antag_team = team_ref?.resolve()
	if(!isnull(antag_team))
		return !!(viewer.mind in antag_team.members)

	return !!viewer.mind?.has_antag_datum(antag_datum_type)
