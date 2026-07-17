/datum/keybinding/client/voice_chat_push_to_talk
	name = "Голосовой чат: говорить"
	category = KB_CATEGORY_COMMUNICATION
	keys = list("Space")

/datum/keybinding/client/voice_chat_push_to_talk/down(client/user)
	. = ..()
	if(.)
		return .
	user.voice_chat?.set_push_to_talk(TRUE)
	return TRUE

/datum/keybinding/client/voice_chat_push_to_talk/up(client/user)
	. = ..()
	if(.)
		return .
	user.voice_chat?.set_push_to_talk(FALSE)
	return TRUE

