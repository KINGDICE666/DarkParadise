#define LOBBY_WAIT_TIME 0.5 SECONDS
#define PLAYIND_WAIT_TIME 30 SECONDS
#define ROUND_DELAY "РАУНД ОТЛОЖЕН"
#define ROUND_STARTED "РАУНД НАЧАЛСЯ"
#define ROUND_UNKNOWN "НЕ ИЗВЕСТНО"

SUBSYSTEM_DEF(new_player_info)
	name = "New Players Info"
	wait = LOBBY_WAIT_TIME
	dependencies = list(
		/datum/controller/subsystem/ticker,
	)
	priority = FIRE_PRIORITY_NEW_PLAYERS_INFO
	ss_flags = SS_KEEP_TIMING
	runlevels = RUNLEVELS_DEFAULT | RUNLEVEL_LOBBY
	var/list/info_screens = list()
	var/time_remaining = ROUND_UNKNOWN
	var/players = 0
	var/total_players_ready = 0
	var/game_mode

/datum/controller/subsystem/new_player_info/Initialize()
	fire()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/new_player_info/fire(resumed)
	time_remaining = SSticker.pregame_timeleft
	if(time_remaining == -10 || (SSticker?.delay_end && SSticker.current_state < GAME_STATE_PLAYING) || !SSticker.ticker_going)
		time_remaining = ROUND_DELAY
	else if(SSticker?.current_state >= GAME_STATE_PLAYING)
		time_remaining = ROUND_STARTED
	else if(time_remaining > 0)
		time_remaining = deciseconds_to_time_stamp(time_remaining)
	else
		time_remaining = ROUND_UNKNOWN

	players = LAZYLEN(GLOB.clients)

	total_players_ready = 0
	if(time_remaining != ROUND_STARTED)
		for(var/mob/new_player/player as anything in GLOB.new_player_mobs)
			if(player.ready)
				total_players_ready++

	game_mode = SSticker.hide_mode ? "Скрыт" : (SSticker.current_state > GAME_STATE_SETTING_UP) ? SSticker.mode.name : GLOB.master_mode

	for(var/atom/movable/screen/lobby/new_player_info/info_screen as anything in info_screens)
		info_screen.update_text()

/datum/controller/subsystem/new_player_info/proc/get_info_text()
	var/list/lines = list(
		"Режим: [game_mode]",
		"<b>[time_remaining]</b>",
		"Игроков: [players]",
	)
	if(time_remaining != ROUND_STARTED)
		lines += "Готовы: [total_players_ready]"
	return jointext(lines, "<br>")

#undef LOBBY_WAIT_TIME
#undef PLAYIND_WAIT_TIME
#undef ROUND_DELAY
#undef ROUND_STARTED
#undef ROUND_UNKNOWN
