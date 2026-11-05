
//Enemy intelligence is valuable, believe it or not
/datum/export/documents
	cost = CARGO_INTEL_VALUE
	k_elasticity = 0
	unit_name = "разведданные противника"
	scannable = FALSE
	export_types = list(/obj/item/documents)
	var/needed_interest = INTEREST_NANOTRASEN

/datum/export/documents/applies_to(obj/exported_item, apply_elastic, export_markets)
	if(!..())
		return FALSE

	var/obj/item/documents/sold_int = exported_item
	if(needed_interest & sold_int.sell_interest)
		return TRUE
	return FALSE

/datum/export/documents/get_base_cost(obj/item/documents/papers)
	return cost * papers.sell_multiplier
