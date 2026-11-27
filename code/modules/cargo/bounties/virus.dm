/datum/bounty/virus
	reward = CARGO_CRATE_VALUE * 10
	var/shipped = FALSE
	var/stat_value = 0
	var/stat_name = ""
	var/stat_key = ""

/datum/bounty/virus/New()
	..()
	stat_value = rand(4, 11)
	if(rand(3) == 1)
		stat_value *= -1
	name = "Вирус ([stat_name]: [stat_value])"
	description = "\"Нанотрейзен\" интересуется вирусом, у которого параметр \"[stat_name]\" равен ровно [stat_value]. Центральное командование щедро заплатит за такой вирус."
	reward += rand(0, 4) * CARGO_CRATE_VALUE

/datum/bounty/virus/print_required()
	return "Не менее 1 ед."

/datum/bounty/virus/can_claim()
	return shipped

/datum/bounty/virus/applies_to(obj/export)
	if(shipped)
		return FALSE
	if(export.flags & HOLOGRAM)
		return FALSE
	if(!is_reagent_container(export) || !export.reagents)
		return FALSE
	for(var/datum/reagent/reagent as anything in export.reagents.reagent_list)
		for(var/datum/disease/virus/advance/virus in reagent.data?["diseases"])
			if(length(virus.symptoms) && virus.GenerateProperties()[stat_key] == stat_value)
				return TRUE
	return FALSE

/datum/bounty/virus/ship(obj/export)
	if(!applies_to(export))
		return FALSE
	shipped = TRUE
	return TRUE

/datum/bounty/virus/resistance
	stat_name = "сопротивляемость"
	stat_key = "resistance"

/datum/bounty/virus/stage_speed
	stat_name = "скорость развития"
	stat_key = "stage_speed"

/datum/bounty/virus/stealth
	stat_name = "скрытность"
	stat_key = "stealth"

/datum/bounty/virus/transmit
	stat_name = "заразность"
	stat_key = "transmittable"
