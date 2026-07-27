/datum/team/revolution
	name = "Революция"
	antag_datum_type = /datum/antagonist/rev
	var/check_counter = 0

/datum/team/revolution/proc/get_head_revolutionaries()
	var/list/leaders = list()
	for(var/datum/mind/member as anything in members)
		if(member.has_antag_datum(/datum/antagonist/rev/head))
			leaders += member
	return leaders

/datum/team/revolution/proc/check_latejoin()
	check_counter++
	if(check_counter < 5)
		return
	check_counter = 0

	var/list/leaders = get_head_revolutionaries()
	if(length(leaders) >= MAX_HEAD_REVOLUTIONARIES)
		return
	if(length(leaders) >= round(length(SSticker.mode.get_all_heads()) - ((8 - length(SSticker.mode.get_all_sec())) / 3)))
		return

	var/list/promotable_revs = list()
	for(var/datum/mind/khrushchev as anything in (members - leaders))
		if(!khrushchev.current?.client || khrushchev.current.stat == DEAD)
			continue
		if(ROLE_REV in khrushchev.current.client.prefs.be_special)
			promotable_revs += khrushchev

	if(!length(promotable_revs))
		return

	var/datum/mind/stalin = pick(promotable_revs)
	add_game_logs("has been promoted to a head rev", stalin.current)
	var/datum/antagonist/rev/rev = stalin.has_antag_datum(/datum/antagonist/rev)
	rev.promote()

/datum/team/revolution/declare_completion()
	var/list/leaders = get_head_revolutionaries()
	var/num_revs = 0
	var/num_survivors = 0
	for(var/mob/living/carbon/survivor in GLOB.alive_mob_list)
		if(!survivor.ckey)
			continue
		num_survivors++
		if(survivor.mind in members)
			num_revs++

	var/list/text = list()
	if(num_survivors)
		text += "[TAB]Command's Approval Rating: [span_bold("[100 - round((num_revs / num_survivors) * 100, 0.1)]%")]"

	text += span_bold(span_fontsize3("<br>The head revolutionaries were:</font>"))
	for(var/datum/mind/headrev as anything in leaders)
		text += printplayer(headrev, 1)

	text += span_bold(span_fontsize3("<br>The heads of staff were:"))
	for(var/datum/mind/head as anything in SSticker.mode.get_all_heads())
		text += printplayer(head, 1)
	text += "<br>"
	return text.Join("")

/datum/team/revolution/set_scoreboard_vars()
	var/datum/scoreboard/scoreboard = SSticker.score
	var/list/leaders = get_head_revolutionaries()

	for(var/datum/mind/leader as anything in leaders)
		if(!leader.current || leader.current.stat == DEAD)
			scoreboard.score_ops_killed++
		else if(HAS_TRAIT(leader, TRAIT_RESTRAINED))
			scoreboard.score_arrested++

	if(length(leaders) == scoreboard.score_arrested)
		scoreboard.all_arrested = TRUE

	for(var/datum/mind/head as anything in SSticker.mode.get_all_heads())
		if(head.current?.stat == DEAD)
			scoreboard.score_dead_command++

	if(scoreboard.score_greentext)
		scoreboard.crewscore -= 10000

	scoreboard.crewscore += scoreboard.score_arrested * 1000
	scoreboard.crewscore += scoreboard.score_ops_killed * 500
	scoreboard.crewscore -= scoreboard.score_dead_command * 500

/datum/team/revolution/get_scoreboard_stats()
	var/datum/scoreboard/scoreboard = SSticker.score
	var/list/leaders = get_head_revolutionaries()
	var/foecount = 0
	var/comcount = 0
	var/revcount = 0
	var/loycount = 0

	for(var/datum/mind/leader as anything in leaders)
		if(leader.current && leader.current.stat != DEAD)
			foecount++

	for(var/datum/mind/rebel as anything in (members - leaders))
		if(rebel.current && rebel.current.stat != DEAD)
			revcount++

	var/list/heads = SSticker.mode.get_all_heads()
	for(var/datum/mind/head as anything in heads)
		if(head.current && head.current.stat != DEAD)
			comcount++

	for(var/mob/living/carbon/human/player as anything in GLOB.human_list)
		if(!player.mind || (player.mind in heads) || (player.mind in members))
			continue
		loycount++

	for(var/mob/living/silicon/robot as anything in GLOB.silicon_mob_list)
		if(robot.stat != DEAD)
			loycount++

	var/list/dat = list("<b><u>Mode Statistics</u></b><br>")
	dat += "<b>Number of Surviving Revolution Heads:</b> [foecount]<br>"
	dat += "<b>Number of Surviving Command Staff:</b> [comcount]<br>"
	dat += "<b>Number of Surviving Revolutionaries:</b> [revcount]<br>"
	dat += "<b>Number of Surviving Loyal Crew:</b> [loycount]<br>"
	dat += "<br>"
	dat += "<b>Revolution Heads Arrested:</b> [scoreboard.score_arrested] ([scoreboard.score_arrested * 1000] Points)<br>"
	dat += "<b>All Revolution Heads Arrested:</b> [scoreboard.all_arrested ? "Yes" : "No"] (Score tripled)<br>"
	dat += "<b>Revolution Heads Slain:</b> [scoreboard.score_ops_killed] ([scoreboard.score_ops_killed * 500] Points)<br>"
	dat += "<b>Command Staff Slain:</b> [scoreboard.score_dead_command] (-[scoreboard.score_dead_command * 500] Points)<br>"
	dat += "<b>Revolution Successful:</b> [scoreboard.score_greentext ? "Yes" : "No"] (-[scoreboard.score_greentext * 10000] Points)<br>"
	dat += "<hr>"
	return dat.Join("")
