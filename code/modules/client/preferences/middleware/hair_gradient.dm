#define HAIR_GRADIENT_PREVIEW_X1 8
#define HAIR_GRADIENT_PREVIEW_Y1 15
#define HAIR_GRADIENT_PREVIEW_X2 25
#define HAIR_GRADIENT_PREVIEW_Y2 32

/datum/preference_middleware/hair_gradient
	action_delegations = list(
		"set_hair_gradient_preview" = PROC_REF(set_hair_gradient_preview),
	)
	var/preview_open = FALSE
	var/list/previews
	var/datum/weakref/previewed_body

/datum/preference_middleware/hair_gradient/get_ui_data(mob/user)
	var/mob/living/carbon/human/dummy/body = preferences.character_preview_view?.body
	if(!preview_open || !body)
		return list()
	if(previewed_body?.resolve() != body)
		previewed_body = WEAKREF(body)
		previews = build_previews(body)
	return list("hair_gradient_previews" = previews)

/datum/preference_middleware/hair_gradient/proc/set_hair_gradient_preview(list/params, mob/user)
	preview_open = !!params["open"]
	return preview_open

/datum/preference_middleware/hair_gradient/proc/build_previews(mob/living/carbon/human/dummy/body)
	var/list/previews = list()
	var/obj/item/organ/external/head/head = body.get_organ(BODY_ZONE_HEAD)
	if(!head)
		return previews

	var/icon/head_icon = icon(head.get_icon(), dir = SOUTH)
	for(var/style in SSaccessories.hair_gradients_list)
		var/icon/preview = icon(head_icon)
		var/mutable_appearance/hair = head.build_hair_appearance(style)
		if(hair)
			preview.Blend(getFlatIcon(hair, SOUTH), ICON_OVERLAY)
		preview.Crop(HAIR_GRADIENT_PREVIEW_X1, HAIR_GRADIENT_PREVIEW_Y1, HAIR_GRADIENT_PREVIEW_X2, HAIR_GRADIENT_PREVIEW_Y2)
		previews[style] = icon2base64(preview)
	return previews

#undef HAIR_GRADIENT_PREVIEW_X1
#undef HAIR_GRADIENT_PREVIEW_Y1
#undef HAIR_GRADIENT_PREVIEW_X2
#undef HAIR_GRADIENT_PREVIEW_Y2
