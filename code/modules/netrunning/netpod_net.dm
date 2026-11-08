/obj/machinery/netpod/update_overlays()
	. = ..()
	if(!net_mode || !is_operational())
		return
	. += "netpod_net"
	. += emissive_appearance(icon, "netpod_net", src)

/obj/machinery/netpod/multitool_act(mob/living/user, obj/item/tool)
	. = TRUE
	if(occupant)
		balloon_alert(user, "капсула занята!")
		return
	if(!tool.use_tool(src, user, 0, volume = tool.tool_volume))
		return
	net_mode = !net_mode
	balloon_alert(user, net_mode ? "режим Сети" : "режим доменов")
	update_icon()

/obj/machinery/netpod/proc/enter_net()
	var/mob/living/carbon/human/pilot = occupant
	if(!ishuman(pilot) || pilot.stat != CONSCIOUS || isnull(pilot.mind))
		balloon_alert(pilot, "неподходящий пользователь")
		open_machine()
		return

	if(!pilot.get_organ_slot(INTERNAL_ORGAN_BRAIN_NEURO))
		balloon_alert(pilot, "нужен нейроинтерфейс!")
		open_machine()
		return

	balloon_alert(pilot, "подключение к Сети...")
	var/attempt_number = connection_attempt
	var/trait_source = "[UNIQUE_TRAIT_SOURCE(src)]_[attempt_number]"
	ADD_TRAIT(pilot, TRAIT_HANDS_BLOCKED, trait_source)
	var/connection_established = do_after(pilot, 2 SECONDS, src)
	REMOVE_TRAIT(pilot, TRAIT_HANDS_BLOCKED, trait_source)

	if(QDELETED(src) || connection_attempt != attempt_number || occupant != pilot || state_open)
		return

	if(!connection_established || !validate_entry(pilot, pilot))
		open_machine()
		return

	start_net_session(pilot)

/obj/machinery/netpod/proc/start_net_session(mob/living/carbon/human/pilot)
	add_healing(pilot)
	var/mob/living/basic/net_avatar/avatar = new(get_turf(src))
	avatar.AddComponent(/datum/component/net_connection, pilot, src)
	connected = TRUE
	update_icon()
