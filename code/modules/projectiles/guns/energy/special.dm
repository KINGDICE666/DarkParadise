/**
 * Random energy gun like objects, whick do not fit in other categories (and their own files)
 */

// MARK: Decloner
/obj/item/gun/energy/decloner
	name = "biological demolecularisor"
	desc = "A gun that discharges high amounts of controlled radiation to slowly break a target into component elements."
	icon_state = "decloner"
	origin_tech = "combat=4;materials=4;biotech=5;plasmatech=6"
	ammo_type = list(/obj/item/ammo_casing/energy/declone)
	ammo_x_offset = 1
	accuracy = GUN_ACCURACY_MINIMAL

/obj/item/gun/energy/decloner/update_icon_state()
	return

/obj/item/gun/energy/decloner/update_overlays()
	. = list()
	var/obj/item/ammo_casing/energy/shot = ammo_type[select]
	if(cell.charge > shot.e_cost)
		. += "decloner_spin"

// MARK: Flora Gun
/obj/item/gun/energy/floragun
	name = "floral somatoray"
	desc = "A tool that discharges controlled radiation which induces mutation in plant cells."
	icon_state = "flora"
	fire_sound = 'sound/effects/stealthoff.ogg'
	materials = list(MAT_GOLD = 2000, MAT_BLUESPACE = 1500, MAT_DIAMOND = 800, MAT_URANIUM = 500, MAT_GLASS = 500)
	origin_tech = "materials=5;biotech=6;powerstorage=6;engineering=5"
	ammo_type = list(/obj/item/ammo_casing/energy/flora/alpha, /obj/item/ammo_casing/energy/flora/beta, /obj/item/ammo_casing/energy/flora/gamma)
	modifystate = TRUE
	ammo_x_offset = 1
	can_charge = FALSE
	selfcharge = TRUE
	accuracy = GUN_ACCURACY_SNIPER

/obj/item/gun/energy/floragun/emag_act(mob/user)
	. = ..()

	if(emagged)
		return

	if(user)
		balloon_alert(user, "протоколы защиты сняты!")

	emagged = TRUE
	ammo_type = list(/obj/item/ammo_casing/energy/flora/alpha/emag, /obj/item/ammo_casing/energy/flora/beta, /obj/item/ammo_casing/energy/flora/gamma)
	update_ammo_types()

/obj/item/gun/energy/floragun/examine(mob/user)
	. = ..()
	. += span_notice("Mode: [ammo_type[select]]\nCharge: [cell.percent()]%")

// MARK: Meteor Gun
/obj/item/gun/energy/meteorgun
	name = "meteor gun"
	desc = "For the love of god, make sure you're aiming this the right way!"
	icon = 'icons/obj/weapons/projectile.dmi'
	icon_state = "riotgun"
	item_state = "c20r"
	fire_sound = 'sound/weapons/gunshots/gunshot_shotgun.ogg'
	w_class = WEIGHT_CLASS_BULKY
	ammo_type = list(/obj/item/ammo_casing/energy/meteor)
	cell_type = /obj/item/stock_parts/cell/potato
	clumsy_check = FALSE //Admin spawn only, might as well let clowns use it.
	selfcharge = TRUE
	accuracy = GUN_ACCURACY_RIFLE
	recoil = GUN_RECOIL_MEDIUM

/obj/item/gun/energy/meteorgun/pen
	name = "meteor pen"
	desc = "The pen is mightier than the sword."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "pen"
	item_state = "pen"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY

// MARK: Mind Flayer
/obj/item/gun/energy/mindflayer
	name = "Mind Flayer"
	desc = "A prototype weapon recovered from the ruins of Research-Station Epsilon."
	icon_state = "xray"
	item_state = null
	ammo_type = list(/obj/item/ammo_casing/energy/mindflayer)
	accuracy = GUN_ACCURACY_PISTOL

// MARK: Wormhole Projectors
/obj/item/gun/energy/wormhole_projector
	name = "bluespace wormhole projector"
	desc = "A projector that emits high density quantum-coupled bluespace beams."
	ammo_type = list(/obj/item/ammo_casing/energy/wormhole, /obj/item/ammo_casing/energy/wormhole/orange)
	item_state = "wormhole_projector1"
	icon_state = "wormhole_projector1"
	origin_tech = "combat=4;bluespace=6;plasmatech=4;engineering=4"
	charge_delay = 5
	selfcharge = TRUE
	var/obj/effect/portal/wormhole_projector/blue
	var/obj/effect/portal/wormhole_projector/orange
	accuracy = GUN_ACCURACY_DEFAULT

/obj/item/gun/energy/wormhole_projector/update_icon_state()
	icon_state = "wormhole_projector[select]"
	item_state = icon_state

/obj/item/gun/energy/wormhole_projector/handle_chamber()
	..()
	select_fire(usr)

/obj/item/gun/energy/wormhole_projector/portal_destroyed(obj/effect/portal/wormhole_projector/portal)
	if(portal.is_orange)
		orange = null
		blue?.target = null
	else
		blue = null
		orange?.target = null

/obj/item/gun/energy/wormhole_projector/proc/create_portal(obj/projectile/beam/wormhole/wormhole_beam, turf/target)
	var/obj/effect/portal/wormhole_projector/new_portal = new(get_turf(wormhole_beam), null, src)
	if(wormhole_beam.is_orange)
		if(!QDELETED(orange))
			qdel(orange)
		orange = new_portal
		new_portal.is_orange = TRUE
		new_portal.update_icon(UPDATE_ICON_STATE)
		new_portal.set_light_color(COLOR_MOSTLY_PURE_ORANGE)
		new_portal.update_light()
	else
		if(!QDELETED(blue))
			qdel(blue)
		blue = new_portal

	if(orange && blue)
		blue.target = get_turf(orange)
		orange.target = get_turf(blue)

// MARK: Cyborg LMG
/obj/item/gun/energy/printer
	name = "cyborg lmg"
	desc = "A machinegun that fires 3d-printed flachettes slowly regenerated using a cyborg's internal power source."
	icon = 'icons/obj/weapons/guns_48x32.dmi'
	icon_state = "l6saw_cyborg"
	cell_type = /obj/item/stock_parts/cell/secborg
	ammo_type = list(/obj/item/ammo_casing/energy/c3dbullet)
	can_charge = FALSE
	accuracy = GUN_ACCURACY_DEFAULT

/obj/item/gun/energy/printer/update_overlays()
	return list()

/obj/item/gun/energy/printer/emp_act()
	return

// MARK: Instakill Lasers
/obj/item/gun/energy/laser/instakill
	name = "instakill rifle"
	icon_state = "instagib"
	item_state = "instagib"
	desc = "A specialized ASMD laser-rifle, capable of flat-out disintegrating most targets in a single hit."
	ammo_type = list(/obj/item/ammo_casing/energy/instakill)
	force = 60
	origin_tech = "combat=7;magnets=6"
	accuracy = GUN_ACCURACY_RIFLE
	attachable_allowed = GUN_MODULE_CLASS_NONE

/obj/item/gun/energy/laser/instakill/emp_act() //implying you could stop the instagib
	return

/obj/item/gun/energy/laser/instakill/red
	desc = "A specialized ASMD laser-rifle, capable of flat-out disintegrating most targets in a single hit. This one has a red design."
	icon_state = "instagibred"
	item_state = "instagibred"
	ammo_type = list(/obj/item/ammo_casing/energy/instakill/red)

/obj/item/gun/energy/laser/instakill/blue
	desc = "A specialized ASMD laser-rifle, capable of flat-out disintegrating most targets in a single hit. This one has a blue design."
	icon_state = "instagibblue"
	item_state = "instagibblue"
	ammo_type = list(/obj/item/ammo_casing/energy/instakill/blue)

// MARK: HONK Rifle
/obj/item/gun/energy/clown
	name = "HONK Rifle"
	desc = "Clown Planet's finest."
	icon_state = "honkrifle"
	item_state = null
	ammo_type = list(/obj/item/ammo_casing/energy/clown)
	clumsy_check = FALSE
	selfcharge = TRUE
	ammo_x_offset = 3
	accuracy = GUN_ACCURACY_MINIMAL

// MARK: Toxin pistol
/obj/item/gun/energy/toxgun
	name = "toxin pistol"
	desc = "A specialized firearm designed to fire lethal bolts of toxins."
	icon_state = "toxgun"
	origin_tech = "combat=4;magnets=4;powerstorage=3"
	ammo_type = list(/obj/item/ammo_casing/energy/toxplasma)
	shaded_charge = TRUE
	accuracy = GUN_ACCURACY_RIFLE

// MARK: Mimic Gun
/obj/item/gun/energy/mimicgun
	name = "mimic gun"
	desc = "A self-defense weapon that exhausts organic targets, weakening them until they collapse. Why does this one have teeth?"
	icon_state = "disabler"
	ammo_type = list(/obj/item/ammo_casing/energy/mimic)
	clumsy_check = FALSE //Admin spawn only, might as well let clowns use it.
	selfcharge = TRUE
	ammo_x_offset = 3
	var/mimic_type = /obj/item/gun/projectile/automatic/pistol/stechkin //Setting this to the mimicgun type does exactly what you think it will.
	accuracy = GUN_ACCURACY_DEFAULT

/obj/item/gun/energy/mimicgun/newshot()
	var/obj/item/ammo_casing/energy/mimic/M = ammo_type[select]
	M.mimic_type = mimic_type
	..()

// MARK: Vortex shotgun
/obj/item/gun/energy/vortex_shotgun
	name = "reality vortex wrist mounted shotgun"
	desc = "Это оружие использует силу вихревой аномалии для локального разрушения ткани реальности."
	icon_state = "flayer" //Sorta wrist mounted? Sorta? Not really but we work with what we got.
	ammo_type = list(/obj/item/ammo_casing/energy/vortex_blast)
	fire_sound = 'sound/weapons/bladeslice.ogg'
	cell_type = /obj/item/stock_parts/cell/infinite

/obj/item/gun/energy/vortex_shotgun/get_ru_names()
	return alist(
		NOMINATIVE = "вортекс-дробовик",
		GENITIVE = "вортекс-дробовика",
		DATIVE = "вортекс-дробовику",
		ACCUSATIVE = "вортекс-дробовик",
		INSTRUMENTAL = "вортекс-дробовиком",
		PREPOSITIONAL = "вортекс-дробовике",
	)

/obj/effect/temp_visual/target_angled/muzzle_flash/vortex_blast
	invisibility = INVISIBILITY_ABSTRACT // visual is from effect

/obj/effect/temp_visual/target_angled/muzzle_flash/vortex_blast/Initialize(mapload, atom/target, duration_override)
	. = ..()
	if(target)
		new /obj/effect/warp_effect/vortex_blast(loc, target)

/obj/effect/warp_effect/vortex_blast
	icon = 'icons/effects/64x64.dmi'
	icon_state = "vortex_shotgun"

/obj/effect/warp_effect/vortex_blast/Initialize(mapload, target)
	. = ..()
	var/matrix/our_matrix = matrix() * 0.5
	our_matrix.Turn(get_angle(src, target) - 45)
	transform = our_matrix
	animate(src, transform = our_matrix * 10, time = 0.3 SECONDS, alpha = 0)
	QDEL_IN(src, 0.3 SECONDS)

#define PLASMA_CHARGE_USE_PER_SECOND 2.5
#define PLASMA_DISCHARGE_LIMIT 5

// MARK: Plasma pistol
/obj/item/gun/energy/plasma_pistol
	name = "plasma pistol"
	desc = "A specialized firearm designed to fire superheated bolts of plasma. Can be overloaded for a high damage, shield-breaking shot."
	icon_state = "plasmagun"
	item_state = "plasmagun"
	origin_tech = "combat=6;magnets=5;powerstorage=3"
	ammo_type = list(/obj/item/ammo_casing/energy/weak_plasma, /obj/item/ammo_casing/energy/charged_plasma)
	shaded_charge = TRUE
	atom_say_verb = list("бупает", "бипает")
	bubble_icon = "swarmer"
	light_color = "#89078E"
	light_power = 4
	accuracy = GUN_ACCURACY_PISTOL
	var/overloaded = FALSE
	var/warned = FALSE
	var/charging = FALSE
	var/charge_failure = FALSE
	var/mob/living/carbon/holder = null

/obj/item/gun/energy/plasma_pistol/examine(mob/user)
	. = ..()
	. += span_warning("Beware! Improper handling of [src] may release a cloud of highly flammable plasma gas!")

/obj/item/gun/energy/plasma_pistol/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/item/gun/energy/plasma_pistol/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	holder = null
	return ..()

/obj/item/gun/energy/plasma_pistol/process()
	..()
	if(overloaded)
		cell.charge -= PLASMA_CHARGE_USE_PER_SECOND / 5 //2.5 per second, 25 every 10 seconds
		if(cell.charge <= PLASMA_CHARGE_USE_PER_SECOND * 10 && !warned)
			warned = TRUE
			playsound(loc, 'sound/weapons/smg_empty_alarm.ogg', 75, TRUE)
			atom_say("Caution, charge low. Forced discharge in under 10 seconds.", use_tts = FALSE)
		if(cell.charge <= PLASMA_DISCHARGE_LIMIT)
			discharge()

/obj/item/gun/energy/plasma_pistol/attack_self(mob/living/user)
	if(overloaded)
		to_chat(user, span_warning("[src] is already overloaded!"))
		return
	if(cell.charge <= 140) // at least 6 seconds of charge time
		to_chat(user, span_warning("[src] does not have enough charge to be overloaded."))
		return
	if(charging)
		to_chat(user, span_warning("[src] is already charging!"))
		return
	to_chat(user, span_notice("You begin to overload [src]."))
	charging = TRUE
	charge_failure = FALSE
	holder = user
	RegisterSignal(holder, COMSIG_MOB_SWAP_HANDS, PROC_REF(fail_charge))
	addtimer(CALLBACK(src, PROC_REF(overload)), 2.5 SECONDS)

/obj/item/gun/energy/plasma_pistol/proc/fail_charge()
	SIGNAL_HANDLER // COMSIG_MOB_SWAP_HANDS
	charge_failure = TRUE // No charging 2 guns at once.
	UnregisterSignal(holder, COMSIG_MOB_SWAP_HANDS)

/obj/item/gun/energy/plasma_pistol/proc/overload()
	UnregisterSignal(holder, COMSIG_MOB_SWAP_HANDS)
	if(ishuman(loc) && !charge_failure)
		var/mob/living/carbon/carbon = loc
		select_fire(carbon)
		overloaded = TRUE
		cell.use(125)
		playsound(carbon.loc, 'sound/machines/terminal_prompt_confirm.ogg', 75, TRUE)
		atom_say("Overloading success.", use_tts = FALSE)
		set_light(3) // extra visual effect to make it more noticable to user and victims alike
		holder = carbon
		RegisterSignal(holder, COMSIG_MOB_SWAP_HANDS, PROC_REF(discharge))
	else
		balloon_alert_to_viewers("overloading failure")
		playsound(loc, 'sound/machines/buzz-sigh.ogg', 75, TRUE)
	charging = FALSE
	charge_failure = FALSE

/obj/item/gun/energy/plasma_pistol/proc/reset_overloaded()
	select_fire()
	set_light(0)
	overloaded = FALSE
	warned = FALSE
	UnregisterSignal(holder, COMSIG_MOB_SWAP_HANDS)
	holder = null

/obj/item/gun/energy/plasma_pistol/process_fire(zone_override, secondary_fire = FALSE)
	if(charging)
		return
	return ..()

/obj/item/gun/energy/plasma_pistol/handle_chamber()
	if(overloaded)
		do_sparks(2, TRUE, src)
		reset_overloaded()
	..()
	update_icon()

/obj/item/gun/energy/plasma_pistol/emp_act(severity)
	..()
	charge_failure = TRUE
	if(prob(100 / severity) && overloaded)
		discharge()

/obj/item/gun/energy/plasma_pistol/dropped(mob/user)
	. = ..()
	charge_failure = TRUE
	if(overloaded)
		discharge()

/obj/item/gun/energy/plasma_pistol/equipped(mob/user, slot, initial)
	. = ..()
	charge_failure = TRUE
	if(overloaded)
		discharge()

//25% of the time, plasma leak. Otherwise, shoot at a random mob / turf nearby. If no proper mob is found when mob is picked, fire at a turf instead
/obj/item/gun/energy/plasma_pistol/proc/discharge()
	SIGNAL_HANDLER
	reset_overloaded()
	do_sparks(2, TRUE, src)
	update_icon()
	visible_message(span_danger("[src] vents heated plasma!"))
	var/turf/simulated/turf = get_turf(src)
	if(istype(turf))
		turf.atmos_spawn_air(LINDA_SPAWN_TOXINS, 15, T20C)

// MARK: Emitter cannon
/obj/item/gun/energy/emittercannon
	name = "Emitter Cannon"
	desc = "Looks clean and very powerful."
	ammo_type = list(/obj/item/ammo_casing/energy/emittergunborg)
	icon_state = "emittercannon"
	var/charge_cost = 750

/obj/item/gun/energy/emittercannon/emp_act(severity)
	return

// MARK: Chrono gun
/obj/item/gun/energy/chrono_gun
	name = "T.E.D. Projection Apparatus"
	desc = "Проектор устройства T.E.D. Пока спуск зажат, оружие копит заряд. Полностью заряженный выстрел стирает цель из временного потока, а неполный заключает её в стазис."
	icon = 'icons/obj/chronos.dmi'
	icon_state = "chronogun"
	item_state = "chronogun"
	item_flags = DROPDEL
	ammo_type = list(/obj/item/ammo_casing/energy/chrono_beam)
	can_charge = FALSE
	accuracy = GUN_ACCURACY_SNIPER
	var/obj/item/chrono_eraser/eraser
	var/charge_started
	var/full_charge = FALSE
	var/datum/sound_token/charge_sound

/obj/item/gun/energy/chrono_gun/get_ru_names()
	return alist(
		NOMINATIVE = "проектор T.E.D.",
		GENITIVE = "проектора T.E.D.",
		DATIVE = "проектору T.E.D.",
		ACCUSATIVE = "проектор T.E.D.",
		INSTRUMENTAL = "проектором T.E.D.",
		PREPOSITIONAL = "проекторе T.E.D.",
	)

/obj/item/gun/energy/chrono_gun/Initialize(mapload, obj/item/chrono_eraser/eraser)
	. = ..()
	if(!istype(eraser))
		new /obj/item/chrono_eraser(drop_location())
		return INITIALIZE_HINT_QDEL
	src.eraser = eraser
	ADD_TRAIT(src, TRAIT_NODROP, INNATE_TRAIT)

/obj/item/gun/energy/chrono_gun/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	QDEL_NULL(charge_sound)
	if(eraser)
		eraser.projector = null
		eraser = null
	return ..()

/obj/item/gun/energy/chrono_gun/update_overlays()
	. = list()
	if(!charge_started)
		return
	var/progress = clamp((world.time - charge_started) / CHRONO_GUN_CHARGE_TIME, 0, 1)
	. += mutable_appearance('icons/effects/progressbar.dmi', "prog_bar_[round(progress * 100, 5)]")

/obj/item/gun/energy/chrono_gun/do_semiauto_fire()
	if(charge_started || !target)
		return
	charge_started = world.time
	charge_sound = playsoundtoken(src, 'sound/weapons/laser_charge_up.ogg', 60, 7, sound_length = CHRONO_GUN_CHARGE_TIME, frequency = CHRONO_GUN_CHARGE_SOUND_FREQUENCY)
	START_PROCESSING(SSfastprocess, src)
	update_icon(UPDATE_OVERLAYS)

/obj/item/gun/energy/chrono_gun/stop_fire()
	if(charge_started && world.time - charge_started >= CHRONO_GUN_MIN_CHARGE_TIME)
		INVOKE_ASYNC(src, PROC_REF(release_charge), FALSE)
	else
		stop_charging()
	return ..()

/obj/item/gun/energy/chrono_gun/process(seconds_per_tick)
	if(!gun_user || gun_user.get_active_hand() != src || gun_user.incapacitated())
		stop_charging()
		return
	if(world.time - charge_started < CHRONO_GUN_CHARGE_TIME)
		update_icon(UPDATE_OVERLAYS)
		return
	release_charge(TRUE)
	reset_fire()

/obj/item/gun/energy/chrono_gun/on_pre_process_fire(mob/living/user, atom/target)
	var/obj/projectile/energy/chrono_beam/beam = chambered.BB
	beam.full_charge = full_charge
	if(!full_charge)
		beam.color = COLOR_CYAN

/obj/item/gun/energy/chrono_gun/proc/release_charge(full_charge)
	stop_charging()
	src.full_charge = full_charge
	process_fire()

/obj/item/gun/energy/chrono_gun/proc/stop_charging()
	if(!charge_started)
		return
	charge_started = null
	QDEL_NULL(charge_sound)
	STOP_PROCESSING(SSfastprocess, src)
	update_icon(UPDATE_OVERLAYS)

// MARK: Shuriken emitter
/obj/item/gun/energy/shuriken_emitter
	name = "shuriken emitter"
	desc = "Спрятанный в костюме Ниндзя девайс. Выпускает 3 энергетических сюрикена, которые замедляют и временно ослепляют цели."
	icon = 'icons/obj/ninjaobjects.dmi'
	icon_state = "shuriken_emitter"
	item_state = ""
	ninja_weapon = TRUE
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = NONE
	item_flags = DROPDEL|ABSTRACT|NOBLUDGEON
	ammo_type = list(/obj/item/ammo_casing/energy/shuriken)
	can_charge = FALSE
	burst_amount = 3
	var/cost = 100
	var/obj/item/clothing/suit/space/space_ninja/my_suit = null
	var/datum/action/item_action/advanced/ninja/toggle_shuriken_fire_mode/my_action = null

/obj/item/gun/energy/shuriken_emitter/get_ru_names()
	return alist(
		NOMINATIVE = "генератор энергетических сюрикенов",
		GENITIVE = "генератора энергетических сюрикенов",
		DATIVE = "генератору энергетических сюрикенов",
		ACCUSATIVE = "генератор энергетических сюрикенов",
		INSTRUMENTAL = "генератором энергетических сюрикенов",
		PREPOSITIONAL = "генераторе энергетических сюрикенов",
	)

/obj/item/gun/energy/shuriken_emitter/Destroy()
	. = ..()
	my_suit?.shuriken_emitter = null
	my_suit = null
	my_action?.action_ready = FALSE
	my_action?.use_action()
	my_action = null

/obj/item/gun/energy/shuriken_emitter/equip_to_best_slot(mob/user, force = FALSE, drop_on_fail = FALSE, qdel_on_fail = FALSE)
	qdel(src)

/obj/item/gun/energy/shuriken_emitter/run_drop_held_item(mob/user)
	qdel(src)

/obj/item/gun/energy/shuriken_emitter/can_shoot(mob/user)
	. = ..()
	return !my_suit.ninjacost(cost * burst_amount)

/obj/item/gun/energy/shuriken_emitter/borg
	name = "robotic shuriken emitter"
	desc = "A device sneakily hidden inside your robotic hand. Shoots 3 energy shurikens that slows and temporary blinds their targets"
	ammo_type = list(/obj/item/ammo_casing/energy/shuriken/borg)
	item_flags = ABSTRACT|NOBLUDGEON
	// These two values are not needed for borgs - they don't wear a ninja suit
	cost = null
	my_suit = null

/obj/item/gun/energy/shuriken_emitter/borg/equip_to_best_slot(mob/M)
	return

/obj/item/gun/energy/shuriken_emitter/borg/run_drop_held_item(mob/user)
	return

/obj/item/gun/energy/shuriken_emitter/borg/can_shoot(mob/user)
	. = ..()
	return TRUE

// MARK: Noise cannon
/obj/item/gun/energy/noisecannon
	name = "alien heavy cannon"
	desc = "It's some kind of enormous alien weapon, as long as a man is tall."
	icon_state = "noisecannon"
	item_state = "noisecannon"
	force = 10
	ammo_type = list(/obj/item/ammo_casing/energy/sonic)
	cell_type = /obj/item/stock_parts/cell/super
	restricted_species = list(/datum/species/vox/armalis)
	sprite_sheets_inhand = list(SPECIES_VOX_ARMALIS = 'icons/mob/clothing/species/armalis/held.dmi') //Big guns big birds.
	recoil = GUN_RECOIL_HIGH

/obj/item/gun/energy/noisecannon/update_icon_state()
	return

/obj/item/gun/energy/noisecannon/update_overlays()
	return list()

#undef PLASMA_CHARGE_USE_PER_SECOND
#undef PLASMA_DISCHARGE_LIMIT
