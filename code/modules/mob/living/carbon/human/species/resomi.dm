// ===================================================================
// RESOMI
// Ported from SierraBay12 (mods/resomi/). Bay -> Paradise conversion.
//
// Dropped in port (no Paradise equivalent / handled elsewhere):
//   - mob_size = MOB_SMALL / holder_type  (small "fold into container"
//     pickup mechanic; Paradise has no small-human support)
//   - Bay cultural_info (cultures/homeworlds/religions/factions)
//   - Bay descriptors (height/build), skills_from_age (Bay skill system)
//   - strength / breath_pressure / metabolism_mod / gluttonous /
//     light_sensitive / flash_mod  (no direct Paradise vars)
//   - tail (resomitail): needs a tail sprite spliced into
//     icons/effects/species.dmi + a BODY_ZONE_TAIL organ. TODO.
//   - body markings: Sierra uses per-limb marking states, Paradise uses
//     whole-body markings; needs dmi re-slice. TODO.
// ===================================================================

/datum/species/resomi
	name = SPECIES_RESOMI
	name_plural = "Resomii"
	language = LANGUAGE_RESOMI
	unarmed_type = /datum/unarmed_attack/claws

	blurb = "Раса пернатых хищников, развивавшихся на холодном мире почти за пределами зоны Златовласки. \
	Крайне хрупкие, они выработали охотничьи навыки, в которых особое внимание уделялось уничтожению добычи \
	без ущерба для себя. Это развитая культура, находящаяся в хороших отношениях со Скреллами и людьми."

	icobase = 'icons/mob/human_races/r_resomi.dmi'
	deform = 'icons/mob/human_races/r_def_resomi.dmi'
	damage_overlays = 'icons/mob/human_races/masks/dam_resomi.dmi'
	damage_mask = 'icons/mob/human_races/masks/dam_mask_resomi.dmi'
	blood_mask = 'icons/mob/human_races/masks/blood_resomi.dmi'

	// Fragile hunter: takes +30% of ANY damage (damage_resistance is a flat
	// "blocked" %, so negative = extra damage taken).
	total_health = 100
	damage_resistance = -30
	speed_mod = -0.2 // Small and nimble. (negative = faster; Paradise scale is small — most species are 0, unathi -0.5)

	// -40% blood. Paradise blood thresholds are absolute, so this is applied
	// as a scaling factor in SSblood (see blood.dm) rather than a raw number.
	blood_volume_mod = 0.6

	body_temperature = 314.15
	taste_sensitivity = TASTE_SENSITIVITY_SHARP
	hunger_drain_mod = 1.5

	// Cold-world hunter: strong cold tolerance, poor heat tolerance.
	coldmod = 0.5
	cold_level_1 = 180
	cold_level_2 = 130
	cold_level_3 = 70
	heat_level_1 = 320
	heat_level_2 = 370
	heat_level_3 = 600

	blood_species = "Resomi"
	blood_color = "#d514f7"
	flesh_color = "#5f7bb0"
	base_color = "#001144"
	// Resomi head sits low in the tile, so the eye overlay is shifted down to
	// line up (instead of floating above the head). Tune eye_offset_y in playtest.
	eyes = "eyes_s"
	eye_offset_y = 6

	reagent_tag = ORGANIC
	bodyflags = HAS_SKIN_COLOR
	clothing_flags = HAS_UNDERWEAR | HAS_UNDERSHIRT | HAS_SOCKS

	// Standard station clothing auto-shrinks to fit the small resomi frame,
	// so bespoke resomi-sized sprites aren't needed. Tune in playtest.
	worn_clothing_scale = 0.8
	worn_clothing_offset_y = -3

	default_hair = "Resomi Plumage"

	has_organ = list(
		INTERNAL_ORGAN_HEART = /obj/item/organ/internal/heart,
		INTERNAL_ORGAN_LUNGS = /obj/item/organ/internal/lungs,
		INTERNAL_ORGAN_LIVER = /obj/item/organ/internal/liver/resomi,
		INTERNAL_ORGAN_KIDNEYS = /obj/item/organ/internal/kidneys/resomi,
		INTERNAL_ORGAN_BRAIN = /obj/item/organ/internal/brain,
		INTERNAL_ORGAN_APPENDIX = /obj/item/organ/internal/appendix,
		INTERNAL_ORGAN_EYES = /obj/item/organ/internal/eyes/resomi,
		INTERNAL_ORGAN_EARS = /obj/item/organ/internal/ears,
	)

	meat_type = /obj/item/reagent_containers/food/snacks/meat/humanoid

	age_sheet = list(
		SPECIES_AGE_MIN = 15,
		SPECIES_AGE_MAX = 45,
		JOB_MIN_AGE_HIGH_ED = 18,
		JOB_MIN_AGE_COMMAND = 26,
	)

	// Resomi speak in a trilling chirp.
	speech_sounds = list('sound/voice/resomi/resomichirp.ogg')
	speech_chance = 20
	scream_verb = "верещ%(ит,ат)%"
	male_scream_sound = list('sound/voice/resomi/resomiscream.ogg')
	female_scream_sound = list('sound/voice/resomi/resomiscream.ogg')
	male_cough_sounds = list('sound/voice/resomi/resomicough.ogg')
	female_cough_sounds = list('sound/voice/resomi/resomicough.ogg')
	male_sneeze_sound = list('sound/voice/resomi/resomisneeze.ogg')
	female_sneeze_sound = list('sound/voice/resomi/resomisneeze.ogg')
	male_laugh_sound = list('sound/voice/resomi/resomilaugh.ogg', 'sound/voice/resomi/cackle.ogg')
	female_laugh_sound = list('sound/voice/resomi/resomilaugh.ogg', 'sound/voice/resomi/cackle.ogg')
	male_giggle_sound = list('sound/voice/resomi/resomilaugh.ogg')
	female_giggle_sound = list('sound/voice/resomi/resomilaugh.ogg')

	// Carnivore: dislikes vegetables, fruit and grain.
	disliked_food = VEGETABLES | FRUIT | GRAIN
	liked_food = MEAT | RAW

/datum/species/resomi/on_species_gain(mob/living/carbon/human/H)
	. = ..()
	// Small enough to be scooped into a hand or bag. (We keep mob_size HUMAN to
	// avoid unrelated small-mob side effects like being unable to strip others;
	// the holder itself is forced small in get_scooped so it still fits in bags.)
	H.holder_type = /obj/item/holder/resomi
	// Apply the -40% blood cap immediately.
	if(H.blood_volume > BLOOD_VOLUME_NORMAL * blood_volume_mod)
		H.setBlood(BLOOD_VOLUME_NORMAL * blood_volume_mod)
	// Grant the racial ability buttons.
	var/datum/action/resomi/listen_in/listen = new
	listen.Grant(H)
	var/datum/action/innate/resomi/toggle_agility/agility = new
	agility.Grant(H)

/datum/species/resomi/on_species_loss(mob/living/carbon/human/H)
	. = ..()
	H.holder_type = initial(H.holder_type)
	// Reset table-hopping in case it was toggled on.
	H.pass_flags &= ~PASSTABLE
	// Remove the racial ability buttons.
	var/datum/action/resomi/listen_in/listen = locate() in H.actions
	listen?.Remove(H)
	var/datum/action/innate/resomi/toggle_agility/agility = locate() in H.actions
	agility?.Remove(H)
