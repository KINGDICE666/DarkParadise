#define FORENSIC_PANEL_CHARS_PER_LINE 36
#define FORENSIC_MAX_LISTED 3
#define FORENSIC_MAX_WEAPONS 4
#define FORENSIC_MAX_BULLET_RECORDS 6
#define FORENSIC_LABEL_COLOUR "#6FB7E6"
#define FORENSIC_DANGER_COLOUR "#FF8080"
#define FORENSIC_ITEM_COLOUR "#4FC8FF"
#define FORENSIC_BLOOD_COLOUR "#FF6464"
#define FORENSIC_SHOT_COLOUR "#FFD34F"
#define FORENSIC_BODY_COLOUR "#FFFFFF"

/datum/forensic_report
	var/title
	var/colour = FORENSIC_ITEM_COLOUR
	var/marked = TRUE
	var/list/lines = list()
	var/list/line_weights = list()
	var/list/dna_keys = list()
	var/list/print_keys = list()
	var/list/weapon_keys = list()
	var/list/events = list()
	var/list/trajectories = list()

/datum/forensic_report/New(title, colour = FORENSIC_ITEM_COLOUR, marked = TRUE)
	src.title = title
	src.colour = colour
	src.marked = marked

/datum/forensic_report/proc/add_line(label, value, danger = FALSE)
	var/shown_value = danger ? "<span style='color: [FORENSIC_DANGER_COLOUR]'>[value]</span>" : value
	lines += "<span style='color: [FORENSIC_LABEL_COLOUR]'>[label]:</span> [shown_value]"
	line_weights += forensic_line_weight(length_char(label) + length_char("[value]") + 2)

/datum/forensic_report/proc/add_time_line(label, event_time)
	add_line(label, "[station_time_timestamp("hh:mm:ss", event_time)] ([forensic_time_ago(event_time)])")

/datum/forensic_report/proc/add_listed_lines(label, list/values)
	var/shown = 0
	for(var/value in values)
		if(shown == FORENSIC_MAX_LISTED)
			add_line(label, "и ещё [length(values) - shown]")
			return
		add_line(label, value)
		shown++

/datum/forensic_report/proc/add_blood_lines(list/blood_samples)
	for(var/dna in blood_samples)
		add_line("ДНК", dna)
		add_line("Группа", blood_samples[dna])
		dna_keys |= dna

/datum/forensic_report/proc/add_event(event_time, text)
	events += list(list("time" = event_time, "text" = text))

/datum/forensic_report/proc/add_trajectory(turf/start, turf/end, event_time, weapon_name)
	if(!start || !end)
		return
	trajectories += list(list("start" = start, "end" = end, "time" = event_time, "weapon" = weapon_name))

/proc/forensic_line_weight(text_length)
	return CEILING(text_length / FORENSIC_PANEL_CHARS_PER_LINE, 1)

/proc/cmp_forensic_event(list/first, list/second)
	return first["time"] - second["time"]

/proc/forensic_time_ago(event_time)
	var/elapsed_seconds = round((world.time - event_time) / (1 SECONDS))
	if(elapsed_seconds < 60)
		return "[elapsed_seconds] сек. назад"
	return "[round(elapsed_seconds / 60)] мин. назад"

/proc/forensic_directions_text(directions)
	var/list/names = list()
	for(var/direction in GLOB.cardinal)
		if(directions & direction)
			names += dir2rustext(direction)
	return jointext(names, ", ")

/atom/proc/get_forensic_report()
	return null

/atom/proc/add_forensic_traces(datum/forensic_report/report)
	report.add_blood_lines(blood_DNA)
	report.add_listed_lines("Отпечатки", fingerprints)
	if(length(fingerprints))
		report.print_keys |= fingerprints
	report.add_listed_lines("Волокна", suit_fibers)

/obj/get_forensic_report()
	if(!length(blood_DNA) && !length(fingerprints) && !length(suit_fibers))
		return null
	var/datum/forensic_report/report = new(DECLENT_RU_CAP(src, NOMINATIVE), FORENSIC_ITEM_COLOUR, isitem(src) || length(blood_DNA))
	add_forensic_traces(report)
	return report

/obj/item/get_forensic_report()
	. = ..()
	if(!reagents?.total_volume)
		return
	var/datum/forensic_report/report = . || new /datum/forensic_report(DECLENT_RU_CAP(src, NOMINATIVE))
	var/list/reagent_names = list()
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		reagent_names += reagent.name
	report.add_listed_lines("Реагент", reagent_names)
	return report

/obj/item/clothing/get_forensic_report()
	. = ..()
	if(!spy_spider_attached)
		return
	var/datum/forensic_report/report = . || new /datum/forensic_report(DECLENT_RU_CAP(src, NOMINATIVE))
	report.add_line("Внимание", "шпионское устройство", danger = TRUE)
	return report

/obj/effect/decal/cleanable/blood/get_forensic_report()
	var/datum/forensic_report/report = new(DECLENT_RU_CAP(src, NOMINATIVE), FORENSIC_BLOOD_COLOUR)
	report.add_line("Состояние", is_dry ? "засохла" : "свежая")
	if(created_at)
		report.add_time_line("Появилась", created_at)
		report.add_event(created_at, "Следы крови")
	else
		report.add_line("Появилась", "до начала смены")
	if(length(blood_DNA))
		report.add_blood_lines(blood_DNA)
	else
		report.add_line("ДНК", "образец не опознан")
	return report

/obj/effect/decal/cleanable/blood/footprints/get_forensic_report()
	. = ..()
	var/datum/forensic_report/report = .
	if(entered_dirs)
		report.add_line("Вошли", forensic_directions_text(entered_dirs))
	if(exited_dirs)
		report.add_line("Вышли", forensic_directions_text(exited_dirs))

/obj/effect/decal/cleanable/trail_holder/get_forensic_report()
	var/datum/forensic_report/report = new("След волочения", FORENSIC_BLOOD_COLOUR)
	report.add_blood_lines(blood_DNA)
	return report

/obj/item/ammo_casing/get_forensic_report()
	var/datum/forensic_report/report = new(BB ? "Патрон" : "Гильза", FORENSIC_SHOT_COLOUR)
	if(caliber)
		report.add_line("Калибр", caliber)
	if(BB)
		report.add_line("Состояние", "не стреляли")
	if(fire_time)
		var/weapon_name = fired_weapon_name || "неизвестно"
		report.add_line("Оружие", weapon_name)
		if(fired_weapon_name)
			report.weapon_keys |= fired_weapon_name
		report.add_time_line("Выстрел", fire_time)
		report.add_line("Направление", fire_direction ? dir2rustext(fire_direction) : "в упор")
		if(impact_target_name)
			report.add_line("Попадание", impact_target_name, danger = TRUE)
		report.add_event(fire_time, "Выстрел: [weapon_name]")
		for(var/turf/impact as anything in impact_turfs)
			report.add_trajectory(fire_origin, impact, fire_time, weapon_name)
	else if(!BB)
		report.add_line("Выстрел", "нет данных")
	add_forensic_traces(report)
	return report

/obj/item/ammo_casing/proc/record_impact(turf/impact)
	if(impact && LAZYLEN(impact_turfs) < FORENSIC_MAX_BULLET_RECORDS)
		LAZYADD(impact_turfs, impact)

/turf/simulated/wall/get_forensic_report()
	if(!LAZYLEN(bullet_traces))
		return null
	var/datum/forensic_report/report = new("След от пули", FORENSIC_SHOT_COLOUR)
	for(var/list/trace as anything in bullet_traces)
		var/weapon_name = trace["weapon"] || "неизвестно"
		report.add_line("Снаряд", trace["projectile"])
		report.add_line("Оружие", weapon_name)
		if(trace["weapon"])
			report.weapon_keys |= trace["weapon"]
		report.add_time_line("Попадание", trace["time"])
		report.add_line("Направление", trace["direction"] ? dir2rustext(trace["direction"]) : "неизвестно")
		report.add_event(trace["time"], "Пуля в стене: [weapon_name]")
		report.add_trajectory(trace["start"], src, trace["time"], weapon_name)
	return report

/turf/simulated/wall/proc/record_bullet_trace(obj/projectile/bullet)
	LAZYADD(bullet_traces, list(list(
		"projectile" = DECLENT_RU_CAP(bullet, NOMINATIVE),
		"weapon" = isgun(bullet.firer_source_atom) ? DECLENT_RU_CAP(bullet.firer_source_atom, NOMINATIVE) : null,
		"time" = world.time,
		"start" = bullet.starting,
		"direction" = bullet.starting ? get_dir(bullet.starting, src) : null,
	)))
	if(LAZYLEN(bullet_traces) > FORENSIC_MAX_LISTED)
		bullet_traces.Cut(1, 2)

/mob/living/get_forensic_report()
	if(stat != DEAD)
		return null
	var/datum/forensic_report/report = new("Труп", FORENSIC_BODY_COLOUR)
	report.add_line("Вид", DECLENT_RU_CAP(src, NOMINATIVE))
	if(timeofdeath)
		report.add_time_line("Смерть", timeofdeath)
		report.add_event(timeofdeath, "Смерть: [DECLENT_RU_CAP(src, NOMINATIVE)]")
	report.add_line("Урон", "мех. [round(getBruteLoss())], терм. [round(getFireLoss())], токс. [round(getToxLoss())], удуш. [round(getOxyLoss())]")
	return report

/mob/living/carbon/human/get_forensic_report()
	if(stat != DEAD && !HAS_TRAIT(src, TRAIT_FAKEDEATH))
		return null
	var/datum/forensic_report/report = new("Труп", FORENSIC_BODY_COLOUR)
	report.add_line("Раса", capitalize(GET_RU_SPECIES_NAME(dna.species.name)))
	if(!HAS_TRAIT(src, TRAIT_NO_DNA))
		report.add_line("ДНК", dna.unique_enzymes)
		report.add_line("Группа", dna.blood_type)
		report.dna_keys |= dna.unique_enzymes
		if(!gloves)
			var/print = md5(dna.uni_identity)
			report.add_line("Отпечатки", print)
			report.print_keys |= print
	if(timeofdeath)
		report.add_time_line("Смерть", timeofdeath)
		report.add_event(timeofdeath, "Смерть: тело")
		if(world.time - timeofdeath < DEFIB_TIME_LIMIT && ghost_can_reenter())
			report.add_line("Реанимация", "ещё возможна")
	if(HAS_TRAIT(src, TRAIT_HUSK))
		report.add_line("Тело", "иссушено", danger = TRUE)
	report.add_line("Урон", "мех. [round(getBruteLoss())], терм. [round(getFireLoss())], токс. [round(getToxLoss())], удуш. [round(getOxyLoss())]")
	add_injury_lines(report)
	add_weapon_lines(report)
	for(var/list/hit as anything in forensic_bullet_hits)
		report.weapon_keys |= hit["weapon"]
		report.add_event(hit["time"], "Ранение: [hit["weapon"]]")
		report.add_trajectory(hit["start"], hit["end"], hit["time"], hit["weapon"])
	return report

/mob/living/carbon/human/proc/record_forensic_bullet_hit(obj/projectile/bullet)
	if(!bullet.damage || !isgun(bullet.firer_source_atom) || !bullet.starting)
		return
	LAZYADD(forensic_bullet_hits, list(list(
		"weapon" = DECLENT_RU_CAP(bullet.firer_source_atom, NOMINATIVE),
		"time" = world.time,
		"start" = bullet.starting,
		"end" = get_turf(src),
	)))
	if(LAZYLEN(forensic_bullet_hits) > FORENSIC_MAX_BULLET_RECORDS)
		forensic_bullet_hits.Cut(1, 2)

/mob/living/carbon/human/proc/add_injury_lines(datum/forensic_report/report)
	var/list/fractures = list()
	var/list/bleeding = list()
	var/list/internal_bleeding = list()
	var/list/infected = list()
	var/list/embedded = list()
	for(var/obj/item/organ/external/bodypart as anything in bodyparts)
		var/part_name = bodypart.get_ru_names_cached()[NOMINATIVE]
		if(bodypart.has_fracture())
			fractures += part_name
		if(bodypart.bleeding_amount > 0)
			bleeding += part_name
		if(bodypart.has_internal_bleeding())
			internal_bleeding += part_name
		if(bodypart.has_infected_wound())
			infected += part_name
		if(LAZYLEN(bodypart.embedded_objects))
			embedded += part_name
	if(length(fractures))
		report.add_line("Переломы", jointext(fractures, ", "), danger = TRUE)
	if(length(bleeding))
		report.add_line("Кровотечение", jointext(bleeding, ", "), danger = TRUE)
	if(length(internal_bleeding))
		report.add_line("Внутр. кровотечение", jointext(internal_bleeding, ", "), danger = TRUE)
	if(length(infected))
		report.add_line("Заражение", jointext(infected, ", "), danger = TRUE)
	if(length(embedded))
		report.add_line("Инородные тела", jointext(embedded, ", "), danger = TRUE)

/mob/living/carbon/human/proc/add_weapon_lines(datum/forensic_report/report)
	var/list/hits_by_weapon = list()
	var/list/damage_by_weapon = list()
	for(var/obj/item/organ/external/bodypart as anything in bodyparts)
		for(var/key in bodypart.autopsy_data)
			var/datum/autopsy_data/weapon_data = bodypart.autopsy_data[key]
			var/weapon_name = weapon_data.weapon || "неизвестно"
			hits_by_weapon[weapon_name] += weapon_data.hits
			damage_by_weapon[weapon_name] += weapon_data.damage
	sortTim(damage_by_weapon, GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	var/shown = 0
	for(var/weapon_name in damage_by_weapon)
		if(shown == FORENSIC_MAX_WEAPONS)
			report.add_line("Орудие", "и ещё [length(damage_by_weapon) - shown]")
			return
		var/hits = hits_by_weapon[weapon_name]
		report.add_line(capitalize(weapon_name), "[hits] [declension_ru(hits, "удар", "удара", "ударов")], [round(damage_by_weapon[weapon_name])] урона")
		shown++

#undef FORENSIC_PANEL_CHARS_PER_LINE
#undef FORENSIC_MAX_LISTED
#undef FORENSIC_MAX_WEAPONS
#undef FORENSIC_MAX_BULLET_RECORDS
#undef FORENSIC_LABEL_COLOUR
#undef FORENSIC_DANGER_COLOUR
#undef FORENSIC_ITEM_COLOUR
#undef FORENSIC_BLOOD_COLOUR
#undef FORENSIC_SHOT_COLOUR
#undef FORENSIC_BODY_COLOUR
