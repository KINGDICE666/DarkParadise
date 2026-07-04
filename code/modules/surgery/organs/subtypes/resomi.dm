// ===================================================================
// RESOMI ORGANS
// Ported from SierraBay12 mods/resomi/code/body/organs.dm
// Bay quirk: resomi are tiny, so liver & kidneys sit in the chest
// rather than the groin. Eyes have superior darksight.
// ===================================================================

/obj/item/organ/internal/liver/resomi
	species_type = /datum/species/resomi
	name = "resomi liver"
	desc = "Орган, фильтрующий кровоток от вредных веществ. Этот принадлежал резоми и, как ни странно, располагался в грудной клетке."
	parent_organ_zone = BODY_ZONE_CHEST

/obj/item/organ/internal/liver/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "печень резоми",
		GENITIVE = "печени резоми",
		DATIVE = "печени резоми",
		ACCUSATIVE = "печень резоми",
		INSTRUMENTAL = "печенью резоми",
		PREPOSITIONAL = "печени резоми",
	)

/obj/item/organ/internal/kidneys/resomi
	species_type = /datum/species/resomi
	name = "resomi kidneys"
	desc = "Парный орган, выводящий из организма продукты обмена веществ. Эти принадлежали резоми и располагались в грудной клетке."
	parent_organ_zone = BODY_ZONE_CHEST

/obj/item/organ/internal/kidneys/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "почки резоми",
		GENITIVE = "почек резоми",
		DATIVE = "почкам резоми",
		ACCUSATIVE = "почки резоми",
		INSTRUMENTAL = "почками резоми",
		PREPOSITIONAL = "почках резоми",
	)

/obj/item/organ/internal/eyes/resomi
	species_type = /datum/species/resomi
	name = "resomi eyes"
	desc = "Парный орган, отвечающий за зрение. Эти принадлежали резоми — хищнику, приспособленному к сумеречной охоте."
	see_in_dark = 5 // Night vision. Paradise ties extra flash eye-damage to see_in_dark, so this also gives the "flashes hurt more" weakness.

/obj/item/organ/internal/eyes/resomi/get_ru_names()
	return alist(
		NOMINATIVE = "глаза резоми",
		GENITIVE = "глаз резоми",
		DATIVE = "глазам резоми",
		ACCUSATIVE = "глаза резоми",
		INSTRUMENTAL = "глазами резоми",
		PREPOSITIONAL = "глазах резоми",
	)
