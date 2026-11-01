GLOBAL_VAR_INIT(seeker_auth_ready, FALSE)

/proc/initialize_seeker_auth()
	var/socket_path = CONFIG_GET(string/seeker_auth_socket)
	if(!socket_path)
		return
	if(world.system_type != UNIX)
		log_world("Seeker authentication disabled: Linux BYOND 516.1682 is required")
		return
	if(!fexists("./libseekerauth.so"))
		log_world("Seeker authentication disabled: libseekerauth.so is missing")
		return
	var/result
	try
		result = CALL_EXT("./libseekerauth.so", "initialize")(socket_path)
	catch(var/exception/error)
		log_world("Seeker authentication disabled: [error.name]")
		return
	if(result != "ok")
		log_world("Seeker authentication disabled: [result]")
		return
	GLOB.seeker_auth_ready = TRUE

/proc/get_seeker_identity(key, address, computer_id, proof)
	if(!GLOB.seeker_auth_ready || !proof)
		return list()
	return params2list(CALL_EXT("./libseekerauth.so", "identity")(key, address, computer_id, proof))

/datum/world_topic_handler/seeker_auth
	topic_key = "seeker_auth"

/datum/world_topic_handler/seeker_auth/execute(list/input, key_valid)
	return json_encode(list("ready" = (GLOB.seeker_auth_ready && MC_RUNNING()), "version" = 2, "guests" = CONFIG_GET(flag/seeker_allow_guests)))
