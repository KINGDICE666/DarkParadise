/datum/bounty/reagent
	var/required_volume = 10
	var/shipped_volume = 0
	var/datum/reagent/wanted_reagent

/datum/bounty/reagent/Destroy(force)
	QDEL_NULL(wanted_reagent)
	return ..()

/datum/bounty/reagent/can_claim()
	return shipped_volume >= required_volume

/datum/bounty/reagent/print_required()
	return "[shipped_volume]/[required_volume] ед."

/datum/bounty/reagent/applies_to(obj/shipped)
	if(!is_reagent_container(shipped))
		return FALSE
	if(!shipped.reagents?.has_reagent(wanted_reagent.type))
		return FALSE
	if(shipped.flags & HOLOGRAM)
		return FALSE
	return shipped_volume < required_volume

/datum/bounty/reagent/ship(obj/shipped)
	if(!applies_to(shipped))
		return FALSE
	shipped_volume = min(shipped_volume + shipped.reagents.get_reagent_amount(wanted_reagent.type), required_volume)
	return TRUE

/datum/bounty/reagent/contribution_amount(obj/shipped)
	return shipped.reagents.get_reagent_amount(wanted_reagent.type)

/datum/bounty/reagent/get_total()
	return shipped_volume

/datum/bounty/reagent/get_max()
	return required_volume

/datum/bounty/reagent/proc/pick_reagent(list/possible_reagents)
	var/reagent_type = pick(possible_reagents)
	wanted_reagent = new reagent_type
	name = wanted_reagent.name

/datum/bounty/reagent/simple_drink
	name = "Простой напиток"
	reward = CARGO_CRATE_VALUE * 3

/datum/bounty/reagent/simple_drink/New()
	pick_reagent(list(
		/datum/reagent/consumable/ethanol/antifreeze,
		/datum/reagent/consumable/ethanol/andalusia,
		/datum/reagent/consumable/ethanol/b52,
		/datum/reagent/consumable/ethanol/beepsky_smash,
		/datum/reagent/consumable/ethanol/bilk,
		/datum/reagent/consumable/ethanol/black_russian,
		/datum/reagent/consumable/ethanol/bloody_mary,
		/datum/reagent/consumable/ethanol/brave_bull,
		/datum/reagent/consumable/ethanol/martini,
		/datum/reagent/consumable/ethanol/cuba_libre,
		/datum/reagent/consumable/ethanol/eggnog,
		/datum/reagent/consumable/ethanol/erikasurprise,
		/datum/reagent/consumable/ethanol/ginfizz,
		/datum/reagent/consumable/ethanol/gintonic,
		/datum/reagent/consumable/ethanol/grog,
		/datum/reagent/consumable/ethanol/hooch,
		/datum/reagent/consumable/ethanol/iced_beer,
		/datum/reagent/consumable/ethanol/irishcarbomb,
		/datum/reagent/consumable/ethanol/manhattan,
		/datum/reagent/consumable/ethanol/margarita,
		/datum/reagent/consumable/ethanol/gargle_blaster,
		/datum/reagent/consumable/ethanol/screwdrivercocktail,
		/datum/reagent/consumable/ethanol/snowwhite,
		/datum/reagent/consumable/ethanol/syndicatebomb,
		/datum/reagent/consumable/ethanol/tequila_sunrise,
		/datum/reagent/consumable/ethanol/manly_dorf,
		/datum/reagent/consumable/ethanol/thirteenloko,
		/datum/reagent/consumable/ethanol/vodkamartini,
		/datum/reagent/consumable/ethanol/whiskeysoda,
		/datum/reagent/consumable/ethanol/demonsblood,
		/datum/reagent/consumable/ethanol/singulo,
		/datum/reagent/consumable/ethanol/sazerac,
		/datum/reagent/consumable/ethanol/daiquiri,
		/datum/reagent/consumable/ethanol/brandy_crusta,
	))
	description = "ЦК мучает жажда! Отправьте партию напитка \"[name]\", чтобы утолить жажду компании."
	reward += rand(0, 2) * 500

/datum/bounty/reagent/complex_drink
	name = "Сложный напиток"
	reward = CARGO_CRATE_VALUE * 8

/datum/bounty/reagent/complex_drink/New()
	pick_reagent(list(
		/datum/reagent/consumable/ethanol/atomicbomb,
		/datum/reagent/consumable/ethanol/bacchus_blessing,
		/datum/reagent/consumable/ethanol/booger,
		/datum/reagent/consumable/ethanol/hippies_delight,
		/datum/reagent/consumable/ethanol/drunkenblumpkin,
		/datum/reagent/consumable/ethanol/goldschlager,
		/datum/reagent/consumable/ethanol/manhattan_proj,
		/datum/reagent/consumable/ethanol/neurotoxin,
		/datum/reagent/consumable/ethanol/patron,
		/datum/reagent/consumable/ethanol/aloe,
	))
	description = "ЦК назначает награду талантливым барменам. Отправьте ёмкость с напитком \"[name]\", чтобы получить приз."
	reward += rand(0, 4) * 500

/datum/bounty/reagent/chemical_simple
	name = "Простой химикат"
	reward = CARGO_CRATE_VALUE * 8
	required_volume = 30

/datum/bounty/reagent/chemical_simple/New()
	pick_reagent(list(
		/datum/reagent/medicine/ephedrine,
		/datum/reagent/medicine/diphenhydramine,
		/datum/reagent/space_drugs,
		/datum/reagent/napalm,
		/datum/reagent/firefighting_foam,
		/datum/reagent/itching_powder,
		/datum/reagent/cyanide,
		/datum/reagent/heparin,
		/datum/reagent/medicine/pen_acid,
		/datum/reagent/medicine/atropine,
		/datum/reagent/aranesp,
		/datum/reagent/krokodil,
		/datum/reagent/methamphetamine,
		/datum/reagent/teslium,
		/datum/reagent/pax,
	))
	description = "ЦК отчаянно нуждается в химикате \"[name]\". Отправьте ёмкость с ним, и вас вознаградят."
	reward += rand(0, 4) * 500

/datum/bounty/reagent/chemical_complex
	name = "Редкий химикат"
	reward = CARGO_CRATE_VALUE * 12
	required_volume = 20

/datum/bounty/reagent/chemical_complex/New()
	pick_reagent(list(
		/datum/reagent/medicine/rezadone,
		/datum/reagent/bath_salts,
		/datum/reagent/hair_dye,
		/datum/reagent/consumable/honey,
		/datum/reagent/consumable/frostoil,
		/datum/reagent/slimejelly,
		/datum/reagent/medicine/strange_reagent,
		/datum/reagent/stable_mutagen,
	))
	description = "ЦК хорошо платит за химикат \"[name]\". Отправьте ёмкость с ним, и вас вознаградят."
	reward += rand(0, 5) * 750

/datum/bounty/pill
	var/required_ammount = 80
	var/shipped_ammount = 0
	var/datum/reagent/wanted_reagent
	var/wanted_vol = 30

/datum/bounty/pill/Destroy(force)
	QDEL_NULL(wanted_reagent)
	return ..()

/datum/bounty/pill/can_claim()
	return shipped_ammount >= required_ammount

/datum/bounty/pill/print_required()
	return "[shipped_ammount]/[required_ammount]"

/datum/bounty/pill/applies_to(obj/shipped)
	if(!ispill(shipped))
		return FALSE
	return shipped.reagents?.get_reagent_amount(wanted_reagent.type) >= wanted_vol

/datum/bounty/pill/ship(obj/shipped)
	if(!applies_to(shipped))
		return FALSE
	shipped_ammount = min(shipped_ammount + 1, required_ammount)
	return TRUE

/datum/bounty/pill/get_total()
	return shipped_ammount

/datum/bounty/pill/get_max()
	return required_ammount

/datum/bounty/pill/simple_pill
	name = "Простые таблетки"
	reward = CARGO_CRATE_VALUE * 20

/datum/bounty/pill/simple_pill/New()
	var/reagent_type = pick(list(
		/datum/reagent/medicine/spaceacillin,
		/datum/reagent/medicine/pen_acid,
		/datum/reagent/medicine/atropine,
		/datum/reagent/medicine/cryoxadone,
		/datum/reagent/medicine/salbutamol,
		/datum/reagent/medicine/charcoal,
		/datum/reagent/medicine/mannitol,
		/datum/reagent/pax,
		/datum/reagent/flash_powder,
		/datum/reagent/phlogiston,
	))
	wanted_reagent = new reagent_type
	name = "Таблетки: [wanted_reagent.name]"
	required_ammount += rand(1, 60)
	wanted_vol += rand(1, 20)
	description = "ЦК требуются таблетки с реагентом \"[wanted_reagent.name]\": [required_ammount] шт., не менее [wanted_vol] ед. в каждой. Отправьте их, и вас вознаградят."
	reward += rand(1, 5) * (CARGO_CRATE_VALUE * 6)
