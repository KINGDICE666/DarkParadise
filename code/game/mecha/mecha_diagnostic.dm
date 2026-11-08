/obj/item/mecha_diagnostic
	name = "mecha holodiagnostic"
	desc = "Голографический лист с уникальными данными о сборке меха и отличиях этого экземпляра от опубликованных схем."
	icon = 'icons/obj/mecha/mecha_diagnostic.dmi'
	icon_state = "holosheet"
	w_class = WEIGHT_CLASS_SMALL
	layer = ABOVE_MOB_LAYER
	light_system = OVERLAY_LIGHT
	light_range = 1
	light_power = 2
	light_color = "#79aeeb"
	var/mech_type
	var/mech_name

/obj/item/mecha_diagnostic/get_ru_names()
	return alist(
		NOMINATIVE = "голодиагностика меха",
		GENITIVE = "голодиагностики меха",
		DATIVE = "голодиагностике меха",
		ACCUSATIVE = "голодиагностику меха",
		INSTRUMENTAL = "голодиагностикой меха",
		PREPOSITIONAL = "голодиагностике меха",
	)

/obj/item/mecha_diagnostic/Initialize(mapload, obj/mecha/source_mech)
	. = ..()
	set_light_on(TRUE)
	if(!source_mech)
		return
	mech_type = source_mech.type
	mech_name = source_mech.name
	name = "mecha holodiagnostic ([mech_name])"
	set_ru_names_suffix(" ([mech_name])")

/obj/item/mecha_diagnostic/examine(mob/user)
	. = ..()
	if(mech_name)
		. += span_notice("Этот голографический лист содержит данные меха <b>[mech_name]</b>.")
