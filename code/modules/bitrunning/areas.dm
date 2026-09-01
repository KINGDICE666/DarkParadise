/area/station/cargo/bitrunning
	name = "Bitrunning Den"
	icon_state = "quartoffice"

/area/virtual_domain
	name = "Virtual Domain"
	icon_state = "away"
	has_gravity = STANDARD_GRAVITY
	requires_power = FALSE
	area_flags = NONE
	holomap_should_draw = FALSE
	report_alerts = FALSE
	tele_proof = TRUE
	static_lighting = FALSE
	base_lighting_alpha = 255
	sound_environment = SOUND_ENVIRONMENT_ROOM

/area/virtual_domain/safehouse
	name = "Virtual Domain Safehouse"
	area_flags = VIRTUAL_SAFE_AREA
