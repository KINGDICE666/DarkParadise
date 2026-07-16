/datum/config_entry/flag/voice_chat_enabled
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/string/voice_chat_relay_url
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/string/voice_chat_public_url
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/string/voice_chat_helper_download_url
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/string/voice_chat_api_key
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/string/voice_chat_uri_scheme
	default = "paradise-voice"
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/datum/config_entry/number/voice_chat_proximity_range
	default = 7
	min_val = 1
	max_val = 15
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN
