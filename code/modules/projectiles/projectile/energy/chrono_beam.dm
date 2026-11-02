/obj/projectile/energy/chrono_beam
	name = "eradication beam"
	icon_state = "chronobolt"
	range = CHRONO_BEAM_RANGE
	color = null
	nodamage = TRUE
	can_hit_turfs = TRUE

/obj/projectile/energy/chrono_beam/get_ru_names()
	return alist(
		NOMINATIVE = "луч стирания",
		GENITIVE = "луча стирания",
		DATIVE = "лучу стирания",
		ACCUSATIVE = "луч стирания",
		INSTRUMENTAL = "лучом стирания",
		PREPOSITIONAL = "луче стирания",
	)

/obj/projectile/energy/chrono_beam/on_hit(atom/target, blocked = 0, hit_zone)
	. = ..()
	var/turf/impact_turf = get_turf(target)
	if(!impact_turf)
		return
	if(isliving(target) && blocked < 100)
		erase_target(target)
	temporal_blast(impact_turf)
	if(iswallturf(target))
		erase_wall(target)

/obj/projectile/energy/chrono_beam/proc/erase_target(mob/living/victim)
	var/obj/item/gun/energy/chrono_gun/gun = firer_source_atom
	new /obj/structure/chrono_field(get_turf(victim), victim, istype(gun) ? gun.eraser : null)
	add_attack_logs(firer, victim, "erased from the timestream with [firer_source_atom]")

/obj/projectile/energy/chrono_beam/proc/temporal_blast(turf/impact_turf)
	playsound(impact_turf, 'sound/weapons/resonator_blast.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/chrono(impact_turf)
	for(var/turf/simulated/floor/floor in range(CHRONO_BLAST_RADIUS, impact_turf))
		floor.break_tile()
	for(var/obj/thing in range(CHRONO_BLAST_RADIUS, impact_turf))
		if(thing == src || iseffect(thing) || QDELETED(thing))
			continue
		thing.take_damage(CHRONO_BLAST_DAMAGE, BRUTE, ENERGY, FALSE)

/obj/projectile/energy/chrono_beam/proc/erase_wall(turf/simulated/wall/wall)
	wall.dismantle_wall(devastated = TRUE)
	if(iswallturf(wall))
		return
	for(var/direction in GLOB.cardinal)
		if(isspaceturf(get_step(wall, direction)))
			new /obj/structure/holosign/barrier/atmos/chrono(wall)
			return
