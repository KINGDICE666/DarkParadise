
/datum/export/seed
	cost = CARGO_CRATE_VALUE * 0.4 // Gets multiplied by potency
	k_elasticity = 0 //price inelastic/quantity elastic, only need to export a few samples
	unit_name = "образцы новых видов растений"
	export_types = list(/obj/item/seeds)
	/// Only for undiscovered species
	var/needs_discovery = FALSE
	/// Plants sold on this export
	var/static/list/discovered_plants = list()
	/// Highest rarity of the most valuable seed
	var/highest_rarity = 0

/datum/export/seed/New()
	. = ..()
	for(var/obj/item/seeds/seed as anything in subtypesof(/obj/item/seeds))
		if(seed::rarity > highest_rarity)
			highest_rarity = seed::rarity

/datum/export/seed/get_base_cost(obj/item/seeds/seed)
	var/discovered = discovered_plants[seed.type]
	if(!needs_discovery && discovered)
		return 0
	if(needs_discovery && !discovered)
		return 0
	return ..() * (seed.rarity / highest_rarity)

/datum/export/seed/sell_object(obj/item/seeds/seed, datum/export_report/report, dry_run, apply_elastic)
	. = ..()
	if(. && !dry_run)
		discovered_plants[seed.type] = seed.potency

/datum/export/seed/potency
	cost = CARGO_CRATE_VALUE * 0.0125 // Gets multiplied by potency and rarity.
	unit_name = "образцы улучшенных растений"
	needs_discovery = TRUE // Only for already discovered species

/datum/export/seed/potency/get_base_cost(obj/item/seeds/seed)
	return ..() * (seed.potency - discovered_plants[seed.type])
