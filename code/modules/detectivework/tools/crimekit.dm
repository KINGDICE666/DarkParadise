//crime scene kit
/obj/item/storage/briefcase/crimekit
	name = "crime scene kit"
	desc = "A stainless steel-plated carrycase for all your forensic needs. Feels heavy."
	icon = 'icons/obj/forensics.dmi'
	icon_state = "case"
	item_state = "case"

/obj/item/storage/briefcase/crimekit/get_ru_names()
	return alist(
		NOMINATIVE = "набор криминалиста",
		GENITIVE = "набора криминалиста",
		DATIVE = "набору криминалиста",
		ACCUSATIVE = "набор криминалиста",
		INSTRUMENTAL = "набором криминалиста",
		PREPOSITIONAL = "наборе криминалиста",
	)

/obj/item/storage/briefcase/crimekit/populate_contents()
	new /obj/item/storage/box/swabs(src)
	new /obj/item/storage/box/fingerprints(src)
	new /obj/item/forensics/sample_kit(src)
	new /obj/item/forensics/sample_kit/powder(src)
	new /obj/item/detective_scanner(src)
