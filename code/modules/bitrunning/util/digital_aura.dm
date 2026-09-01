#define DIGITAL_AURA_FILTER "bitrunning_digital_aura"

/atom/proc/create_digital_aura()
	add_filter(DIGITAL_AURA_FILTER, 2, list("type" = "outline", "color" = LIGHT_COLOR_PURPLE, "size" = 1))
	alpha = 210
	set_light(2, 1, LIGHT_COLOR_PURPLE, l_on = TRUE)

/atom/proc/remove_digital_aura()
	remove_filter(DIGITAL_AURA_FILTER)
	alpha = 255
	set_light(l_on = FALSE)

#undef DIGITAL_AURA_FILTER
