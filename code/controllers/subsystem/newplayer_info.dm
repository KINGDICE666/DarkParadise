#define LOBBY_WAIT_TIME 0.5 SECONDS
#define PLAYIND_WAIT_TIME 30 SECONDS
#define ROUND_DELAY "ОТЛОЖЕН"
#define ROUND_SOON "СКОРО"

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
	var/players = 0
	var/total_players_ready = 0

/datum/controller/subsystem/new_player_info/Initialize()
	fire()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/new_player_info/fire(resumed)
	players = LAZYLEN(GLOB.clients)
	total_players_ready = 0
	for(var/mob/new_player/player as anything in GLOB.new_player_mobs)
		if(player.ready)
			total_players_ready++

	for(var/atom/movable/screen/lobby/new_player_info/info_screen as anything in info_screens)
		info_screen.update_text()

/datum/controller/subsystem/new_player_info/proc/time_remaining_str()
	var/time_remaining = SSticker.pregame_timeleft
	if(time_remaining == -10 || SSticker.delay_end || !SSticker.ticker_going)
		return ROUND_DELAY
	if(time_remaining > 0)
		return "[round(time_remaining / (1 SECONDS))] с"
	return ROUND_SOON

/datum/controller/subsystem/new_player_info/proc/get_info_text(is_admin)
	if(!MC_RUNNING())
		return "Старт через [time_remaining_str()]<br>Загрузка..."

	if(SSticker.current_state == GAME_STATE_FINISHED)
		return "Раунд окончен,<br>скоро рестарт"

	if(SSticker.current_state >= GAME_STATE_PLAYING)
		return "[SSmapping.map_datum.name]<br>Игроков: [players]<br>[round_timestamp()] в игре"

	if(is_admin)
		return "Старт через [time_remaining_str()]<br>Игроков: [players]<br>Готовы: [total_players_ready]"

	return "<span style='font-size: 13.5pt'>[time_remaining_str()]</span><br>Игроков: [players]"

#undef LOBBY_WAIT_TIME
#undef PLAYIND_WAIT_TIME
#undef ROUND_DELAY
#undef ROUND_SOON
