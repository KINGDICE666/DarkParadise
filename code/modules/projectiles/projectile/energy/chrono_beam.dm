/obj/projectile/energy/chrono_beam
	name = "eradication beam"
	icon_state = "chronobolt"
	range = CHRONO_BEAM_RANGE
	color = null
	nodamage = TRUE
	can_hit_turfs = TRUE
	var/full_charge = TRUE

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
	if(!full_charge)
		if(isliving(target) && blocked < 100)
			put_in_stasis(target)
		return
	if(isliving(target) && blocked < 100)
		new /obj/structure/chrono_field(impact_turf, target)
		add_attack_logs(firer, target, "erased from the timestream with [firer_source_atom]")
	temporal_blast(impact_turf)
	if(iswallturf(target))
		erase_wall(target)

/obj/projectile/energy/chrono_beam/proc/put_in_stasis(mob/living/victim)
	victim.Stun(CHRONO_STASIS_TIME)
	victim.apply_status_effect(/datum/status_effect/chrono_aura/stasis)
	add_attack_logs(firer, victim, "put in chrono stasis with [firer_source_atom]")

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

/datum/status_effect/chrono_aura/stasis
	id = "chrono_stasis"
	duration = CHRONO_STASIS_TIME
	status_type = STATUS_EFFECT_REFRESH
	aura_state = "chronofield"
	aura_blend_mode = BLEND_ADD
	aura_sound = 'sound/effects/empulse.ogg'
