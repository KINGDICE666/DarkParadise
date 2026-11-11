/obj/item/organ/internal/cyberimp/brain/cyberlock
	name = "cyberware lock implant"
	desc = "Служебный блокиратор службы безопасности. Глушит всю кибернетику носителя: импланты остаются на месте, но не отвечают, пока стоит блокиратор. Сгорает от любого ЭМИ."
	implant_color = "#FF3C46"
	slot = INTERNAL_ORGAN_BRAIN_CYBERLOCK
	cyber_cost = 0
	origin_tech = "materials=4;programming=6;biotech=4"
	var/list/datum/weakref/locked_implants = list()

/obj/item/organ/internal/cyberimp/brain/cyberlock/get_ru_names()
	return alist(
		NOMINATIVE = "блокиратор кибернетики",
		GENITIVE = "блокиратора кибернетики",
		DATIVE = "блокиратору кибернетики",
		ACCUSATIVE = "блокиратор кибернетики",
		INSTRUMENTAL = "блокиратором кибернетики",
		PREPOSITIONAL = "блокираторе кибернетики",
	)

/obj/item/organ/internal/cyberimp/brain/cyberlock/insert(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(.)
		lock_all()

/obj/item/organ/internal/cyberimp/brain/cyberlock/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	release_all()
	return ..()

/obj/item/organ/internal/cyberimp/brain/cyberlock/on_life()
	. = ..()
	lock_all()

/obj/item/organ/internal/cyberimp/brain/cyberlock/emp_act(severity)
	if(!owner)
		return
	var/mob/living/carbon/host = owner
	host.visible_message(
		span_warning("Из затылка [host.declent_ru(GENITIVE)] сыплются искры."),
		span_warning("В затылке что-то щёлкает и пахнет горелым: блокиратор кибернетики сгорел."),
	)
	do_sparks(3, TRUE, host)
	remove(host)
	qdel(src)

/obj/item/organ/internal/cyberimp/brain/cyberlock/proc/lock_all()
	for(var/obj/item/organ/internal/cyberimp/implant in owner.internal_organs)
		if(implant == src || implant.blocked || !implant.is_robotic() || istype(implant, /obj/item/organ/internal/cyberimp/brain/neuro_interface))
			continue
		implant.set_blocked(TRUE)
		locked_implants += WEAKREF(implant)

/obj/item/organ/internal/cyberimp/brain/cyberlock/proc/release_all()
	for(var/datum/weakref/implant_ref as anything in locked_implants)
		var/obj/item/organ/internal/cyberimp/implant = implant_ref.resolve()
		if(implant?.owner == owner)
			implant.set_blocked(FALSE)
	locked_implants.Cut()

/obj/item/cyberlock_injector
	name = "cyberware lock injector"
	desc = "Одноразовый инъектор с блокиратором кибернетики. Вводится в затылок за пару секунд, если клиент не вырывается."
	icon = 'icons/obj/implants.dmi'
	icon_state = "implanter1"
	item_state = "syringe_0"
	w_class = WEIGHT_CLASS_SMALL
	var/obj/item/organ/internal/cyberimp/brain/cyberlock/lock

/obj/item/cyberlock_injector/get_ru_names()
	return alist(
		NOMINATIVE = "инъектор блокиратора",
		GENITIVE = "инъектора блокиратора",
		DATIVE = "инъектору блокиратора",
		ACCUSATIVE = "инъектор блокиратора",
		INSTRUMENTAL = "инъектором блокиратора",
		PREPOSITIONAL = "инъекторе блокиратора",
	)

/obj/item/cyberlock_injector/Initialize(mapload)
	. = ..()
	lock = new(src)

/obj/item/cyberlock_injector/Destroy()
	QDEL_NULL(lock)
	return ..()

/obj/item/cyberlock_injector/update_icon_state()
	icon_state = "implanter[lock ? "1" : "0"]"

/obj/item/cyberlock_injector/attack(mob/living/carbon/target, mob/living/user, params, def_zone, skip_attack_anim = FALSE)
	. = ATTACK_CHAIN_PROCEED
	if(!ishuman(target) || !lock)
		return .
	if(target.get_organ_slot(INTERNAL_ORGAN_BRAIN_CYBERLOCK))
		balloon_alert(user, "блокиратор уже стоит!")
		return .
	target.visible_message(span_warning("[DECLENT_RU_CAP(user, NOMINATIVE)] подносит инъектор к затылку [target.declent_ru(GENITIVE)]."))
	if(!do_after(user, 4 SECONDS, target) || !lock || QDELETED(target))
		return .
	if(!lock.insert(target, ORGAN_MANIPULATION_NOEFFECT))
		return .
	. |= ATTACK_CHAIN_SUCCESS
	lock = null
	update_icon(UPDATE_ICON_STATE)
	playsound(target, 'sound/machines/ripperdoc/glitch.ogg', 40, TRUE)
	target.visible_message(
		span_warning("[DECLENT_RU_CAP(user, NOMINATIVE)] вгоняет блокиратор в затылок [target.declent_ru(GENITIVE)]."),
		span_userdanger("Затылок обжигает холодом, и вся кибернетика разом замолкает."),
	)
	add_attack_logs(user, target, "installed a cyberware lock")

/obj/item/storage/box/netrunner_kit
	name = "security netrunner kit"
	desc = "Служебный набор нетраннера СБ: базовый кибердек, модуль доступа к имплантам и три инъектора блокиратора кибернетики."
	icon_state = "box_specter"
	item_state = "sec"

/obj/item/storage/box/netrunner_kit/get_ru_names()
	return alist(
		NOMINATIVE = "набор нетраннера СБ",
		GENITIVE = "набора нетраннера СБ",
		DATIVE = "набору нетраннера СБ",
		ACCUSATIVE = "набор нетраннера СБ",
		INSTRUMENTAL = "набором нетраннера СБ",
		PREPOSITIONAL = "наборе нетраннера СБ",
	)

/obj/item/storage/box/netrunner_kit/populate_contents()
	new /obj/item/cyberdeck(src)
	new /obj/item/cyberdeck_module/cyberware(src)
	for(var/i in 1 to 3)
		new /obj/item/cyberlock_injector(src)
