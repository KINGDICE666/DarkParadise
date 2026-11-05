#define MANIFEST_HANDLING_RATE 0.12
#define MANIFEST_CORRECT_RATE (MANIFEST_HANDLING_RATE * 2)
#define MANIFEST_ERRONEOUS_RATE (MANIFEST_HANDLING_RATE * 4)
#define MAX_HANDLING_CHARGE (CARGO_CRATE_VALUE * 0.6)
#define MAX_CORRECT_CHARGE (MAX_HANDLING_CHARGE * 2)
#define MAX_ERRONEOUS_CHARGE (MAX_HANDLING_CHARGE * 4)

/datum/export/manifest_correct
	k_elasticity = 0
	unit_name = "одобренные манифесты"
	export_types = list(/obj/item/paper/manifest)
	scannable = FALSE

/datum/export/manifest_correct/applies_to(obj/exported_item, apply_elastic, export_markets)
	if(!..())
		return FALSE

	var/obj/item/paper/manifest/paper = exported_item
	return paper.is_approved() && !paper.erroneous

/datum/export/manifest_correct/get_base_cost(obj/item/paper/manifest/paper)
	return min(paper.cost * MANIFEST_HANDLING_RATE, MAX_HANDLING_CHARGE)

/datum/export/manifest_error_denied
	k_elasticity = 0
	unit_name = "верно отклонённые манифесты"
	export_types = list(/obj/item/paper/manifest)
	scannable = FALSE

/datum/export/manifest_error_denied/applies_to(obj/exported_item, apply_elastic, export_markets)
	if(!..())
		return FALSE

	var/obj/item/paper/manifest/paper = exported_item
	return paper.is_denied() && paper.erroneous

/datum/export/manifest_error_denied/get_base_cost(obj/item/paper/manifest/paper)
	return paper.cost + min(paper.cost * MANIFEST_CORRECT_RATE, MAX_CORRECT_CHARGE)

/datum/export/manifest_error
	k_elasticity = 0
	unit_name = "ошибочно одобренные манифесты"
	export_types = list(/obj/item/paper/manifest)
	allow_negative_cost = TRUE
	scannable = FALSE

/datum/export/manifest_error/applies_to(obj/exported_item, apply_elastic, export_markets)
	if(!..())
		return FALSE

	var/obj/item/paper/manifest/paper = exported_item
	return paper.is_approved() && paper.erroneous

/datum/export/manifest_error/get_base_cost(obj/item/paper/manifest/paper)
	return -min(paper.cost * MANIFEST_ERRONEOUS_RATE, MAX_ERRONEOUS_CHARGE)

/datum/export/manifest_correct_denied
	k_elasticity = 0
	unit_name = "ошибочно отклонённые манифесты"
	export_types = list(/obj/item/paper/manifest)
	allow_negative_cost = TRUE
	scannable = FALSE

/datum/export/manifest_correct_denied/applies_to(obj/exported_item, apply_elastic, export_markets)
	if(!..())
		return FALSE

	var/obj/item/paper/manifest/paper = exported_item
	return paper.is_denied() && !paper.erroneous

/datum/export/manifest_correct_denied/get_base_cost(obj/item/paper/manifest/paper)
	return -min(paper.cost * MANIFEST_ERRONEOUS_RATE, MAX_ERRONEOUS_CHARGE)

#undef MANIFEST_HANDLING_RATE
#undef MANIFEST_CORRECT_RATE
#undef MANIFEST_ERRONEOUS_RATE
#undef MAX_HANDLING_CHARGE
#undef MAX_CORRECT_CHARGE
#undef MAX_ERRONEOUS_CHARGE
