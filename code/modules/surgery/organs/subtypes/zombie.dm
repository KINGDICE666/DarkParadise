/obj/item/organ/internal/zombietumor
	name = "necrotic tumor"
	desc = "Крошечное скопление зловонных грибов, питающихся мозговым веществом и управляющих им."
	icon = 'icons/obj/hydroponics/harvest.dmi'
	icon_state = "chanterelle"
	w_class = WEIGHT_CLASS_TINY
	parent_organ_zone = BODY_ZONE_HEAD
	slot = INTERNAL_ORGAN_BRAIN_TUMOR

/obj/item/organ/internal/zombietumor/get_ru_names()
	return alist(
		NOMINATIVE = "некротическая опухоль",
		GENITIVE = "некротической опухоли",
		DATIVE = "некротической опухоли",
		ACCUSATIVE = "некротическую опухоль",
		INSTRUMENTAL = "некротической опухолью",
		PREPOSITIONAL = "некротической опухоли",
	)

/obj/item/organ/internal/zombietumor/remove(mob/living/carbon/target, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(special == ORGAN_MANIPULATION_NOEFFECT || !ishuman(target))
		return
	for(var/datum/disease/virus/zombie/zombie_virus in target.diseases)
		zombie_virus.cure()
	var/mob/living/carbon/human/human = target
	for(var/obj/item/organ/external/limb as anything in human.bodyparts)
		if(!limb.is_robotic())
			limb.unnecrotize()
	human.update_body()
	qdel(src)
	return null
