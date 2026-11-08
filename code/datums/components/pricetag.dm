/datum/component/pricetag
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/delete_on_unwrap = TRUE
	var/list/payees = list()

/datum/component/pricetag/Initialize(list/pay_to_account, profit_ratio = 1, delete_on_unwrap = TRUE)
	if(!isobj(parent))
		return COMPONENT_INCOMPATIBLE

	if(!length(pay_to_account))
		stack_trace("[type] component was created with an empty pay_to_account list!")
		return COMPONENT_INCOMPATIBLE

	add_payees(pay_to_account, profit_ratio)
	src.delete_on_unwrap = delete_on_unwrap

/datum/component/pricetag/Destroy(force)
	payees = null
	return ..()

/datum/component/pricetag/proc/add_payees(list/pay_to_account, profit_ratio)
	var/total_contribution = 0
	for(var/totaler in pay_to_account)
		if(!pay_to_account[totaler])
			pay_to_account[totaler] = 1
		total_contribution += pay_to_account[totaler]

	for(var/individual in pay_to_account)
		var/individual_cut = profit_ratio * (pay_to_account[individual] / total_contribution)
		if(!isnull(payees[individual]) && payees[individual] >= individual_cut)
			continue
		payees[individual] = individual_cut

/datum/component/pricetag/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_EXPORTED, PROC_REF(on_parent_sold))
	RegisterSignal(parent, COMSIG_ITEM_UNWRAPPED, PROC_REF(on_parent_unwrap))

/datum/component/pricetag/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ITEM_EXPORTED,
		COMSIG_ITEM_UNWRAPPED,
	))

/datum/component/pricetag/InheritComponent(datum/component/pricetag/new_comp, i_am_original, list/pay_to_account, profit_ratio = 1, delete_on_unwrap = TRUE)
	if(length(payees) == 1)
		add_payees(pay_to_account, profit_ratio)
	if(!delete_on_unwrap)
		src.delete_on_unwrap = delete_on_unwrap

/datum/component/pricetag/proc/on_parent_unwrap(obj/source)
	SIGNAL_HANDLER
	if(!delete_on_unwrap)
		return
	qdel(src)

/datum/component/pricetag/proc/on_parent_sold(obj/source, datum/export/export, datum/export_report/report, item_value)
	SIGNAL_HANDLER
	if(!isnum(item_value))
		return

	var/overall_item_price = item_value
	for(var/datum/money_account/payee as anything in payees)
		var/payee_cut = round(item_value * payees[payee])
		overall_item_price = max(0, overall_item_price - payee_cut)
		payee.credit(payee_cut, "Продажа: [source.declent_ru(NOMINATIVE)]", "Терминал Бизель №[rand(111,333)]", payee.owner_name)
		payee.notify_pda_owner("<b>Продажа </b>\"Продажа: [source.declent_ru(NOMINATIVE)]. На ваш счёт зачислено [payee_cut] кредит[DECL_0_A_OV(payee_cut)].\" (Невозможно Ответить)")

	report.total_value[export] += overall_item_price
	report.total_amount[export] += export.get_amount(source) * export.amount_report_multiplier
	return COMPONENT_STOP_EXPORT_REPORT
