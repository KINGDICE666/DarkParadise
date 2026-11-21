#define AUTOPILOT_PORTAL_TTL (10 MINUTES)

/obj/item/disk/autopilot_upgrade
	name = "updated autopilot disk"
	desc = "Кристаллический носитель с прошивкой обновлённого автопилота. Вставьте в консоль штурвала: корабль сможет взлетать, гасить притяжение планет, а прошивка откроет варп-портал в Рубеж Альфа."
	icon_state = "datadisk3"
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/disk/autopilot_upgrade/get_ru_names()
	return alist(
		NOMINATIVE = "диск обновлённого автопилота",
		GENITIVE = "диска обновлённого автопилота",
		DATIVE = "диску обновлённого автопилота",
		ACCUSATIVE = "диск обновлённого автопилота",
		INSTRUMENTAL = "диском обновлённого автопилота",
		PREPOSITIONAL = "диске обновлённого автопилота",
	)

/obj/machinery/computer/helm/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/disk/autopilot_upgrade))
		return ..()
	link_vessel()
	if(!vessel)
		balloon_alert(user, "нет связи с судном")
		return ITEM_INTERACT_BLOCKING
	if(vessel.autopilot_upgraded)
		balloon_alert(user, "автопилот уже обновлён")
		return ITEM_INTERACT_BLOCKING
	if(!user.drop_transfer_item_to_loc(tool, src))
		return ITEM_INTERACT_BLOCKING
	qdel(tool)
	vessel.install_autopilot_upgrade()
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	to_chat(user, span_notice("Вы загружаете прошивку в [declent_ru(ACCUSATIVE)]. Автопилот обновлён."))
	return ITEM_INTERACT_SUCCESS

/obj/overmap/entity/proc/install_autopilot_upgrade()
	autopilot_upgraded = TRUE
	crash_grounded = FALSE
	QDEL_NULL(planet_crash)
	shuttle_visible_message(span_notice("Обновлённый автопилот компенсирует притяжение планет. Взлёт разрешён."))
	log_game("Vessel [name] installed the updated autopilot.")
	var/datum/overmap_sector/alpha = SSovermap.sectors[OVERMAP_SECTOR_ID_WILDERNESS_A]
	var/turf/here = get_overmap_turf()
	if(!alpha || !sector || !here || sector == alpha)
		return
	var/obj/overmap/portal/gate = new(here)
	gate.destination_sector = alpha
	gate.required_vessel_flags = NONE
	gate.ttl = AUTOPILOT_PORTAL_TTL
	QDEL_IN(gate, AUTOPILOT_PORTAL_TTL)
	sector.add_object(gate, here)
	add_sensor_journal("Открыт варп-портал в [alpha.name]", "appear", here, alpha.name, "good")
	shuttle_visible_message(span_notice("Прошивка открыла варп-портал в [alpha.name]. Подведите корабль и состыкуйтесь с порталом в течение 10 минут."))

#undef AUTOPILOT_PORTAL_TTL
