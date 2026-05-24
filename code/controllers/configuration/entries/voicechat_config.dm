/datum/config_entry/flag/enable_voicechat

/datum/config_entry/number/port_voicechat
	min_val = 1024
	default = 3000
	max_val = 65535
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/string/domain_voicechat
	default = null
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN
