#define DIGITAL_AURA_FILTER "bitrunning_digital_aura"
#define DIGITAL_AURA_ALPHA 210

/datum/component/digital_aura
	var/previous_alpha
	var/previous_light_range
	var/previous_light_power
	var/previous_light_color
	var/previous_light_on

/datum/component/digital_aura/Initialize()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	var/atom/target = parent
	previous_alpha = target.alpha
	previous_light_range = target.light_range
	previous_light_power = target.light_power
	previous_light_color = target.light_color
	previous_light_on = target.light_on

	target.add_filter(DIGITAL_AURA_FILTER, 2, list("type" = "outline", "color" = LIGHT_COLOR_PURPLE, "size" = 1))
	target.alpha = DIGITAL_AURA_ALPHA
	target.set_light(l_range = 2, l_power = 1, l_color = LIGHT_COLOR_PURPLE, l_on = TRUE)

/datum/component/digital_aura/Destroy(force)
	var/atom/target = parent
	if(!QDELETED(target))
		target.remove_filter(DIGITAL_AURA_FILTER)
		target.alpha = previous_alpha
		target.set_light(l_range = previous_light_range, l_power = previous_light_power, l_color = previous_light_color, l_on = previous_light_on)
	return ..()

#undef DIGITAL_AURA_FILTER
#undef DIGITAL_AURA_ALPHA
