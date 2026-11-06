/datum/bounty/item/atmospherics
	reward = CARGO_CRATE_VALUE * 15
	wanted_types = list(/obj/item/tank = TRUE)
	var/moles_required = 20
	var/gas_type

/datum/bounty/item/atmospherics/applies_to(obj/applied_obj)
	if(!..())
		return FALSE
	return get_gas_moles(applied_obj) >= moles_required

/datum/bounty/item/atmospherics/contribution_amount(obj/shipped)
	return get_gas_moles(shipped)

/datum/bounty/item/atmospherics/proc/get_gas_moles(obj/item/tank/tank)
	var/datum/gas_mixture/tank_mix = tank.return_obj_air()
	return tank_mix?.get_interesting()[gas_type] || 0

/datum/bounty/item/atmospherics/pluox_tank
	name = "Полный баллон плюоксия"
	description = "Отдел исследований ЦК разрабатывает сверхкомпактные дыхательные системы. Отправьте баллон, полный плюоксия, и вас вознаградят. (20 молей)"
	gas_type = TLV_PLUOXIUM

/datum/bounty/item/atmospherics/nitrium_tank
	name = "Полный баллон нитрия"
	description = "Заключённых МегаСтанции 62 вызвали добровольцами для испытания стимуляторов. Отправьте им баллон, полный нитрия, чтобы они могли начать. (20 молей)"
	gas_type = TLV_NITRIUM

/datum/bounty/item/atmospherics/freon_tank
	name = "Полный баллон фреона"
	description = "Суперматерия станции 33 начала расслоение. Доставьте баллон фреона, чтобы помочь его остановить! (20 молей)"
	gas_type = TLV_FREON

/datum/bounty/item/atmospherics/tritium_tank
	name = "Полный баллон трития"
	description = "Станция 49 хочет запустить свою исследовательскую программу. Отправьте ей баллон, полный трития. (20 молей)"
	gas_type = TLV_TRITIUM

/datum/bounty/item/atmospherics/hydrogen_tank
	name = "Полный баллон водорода"
	description = "Наш отдел исследований разрабатывает более эффективные батареи с водородом в роли катализатора. Отправьте нам полный баллон. (20 молей)"
	gas_type = TLV_H2

/datum/bounty/item/atmospherics/zauker_tank
	name = "Полный баллон заукера"
	description = "Главная планета \[ОТРЕДАКТИРОВАНО\] выбрана полигоном для нового оружия на заукере. Отправьте нам полный баллон. (20 молей)"
	reward = CARGO_CRATE_VALUE * 20
	gas_type = TLV_ZAUKER
