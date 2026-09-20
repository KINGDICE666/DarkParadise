/datum/unit_test/ntnet_responses
	var/list/saved_state

/datum/unit_test/ntnet_responses/Destroy()
	for(var/var_name in saved_state)
		SSntnet.vars[var_name] = saved_state[var_name]
	saved_state = null
	return ..()

/datum/unit_test/ntnet_responses/Run()
	var/datum/controller/subsystem/ntnet/network = SSntnet
	saved_state = list()
	for(var/var_name in list("sites", "catalog", "zones", "pages", "page_retry", "pending", "available", "index_pending"))
		saved_state[var_name] = network.vars[var_name]
	network.sites = list()
	network.catalog = list()
	network.pages = list()
	network.page_retry = list()
	network.pending = list()
	var/datum/http_response/response = allocate(/datum/http_response)
	response.status_code = 200
	var/list/site = list("id" = "test", "domain" = "test.ss13", "title" = "Test", "version" = "1", "pages" = list(list("slug" = "index", "title" = "Index")))
	response.body = json_encode(list("sites" = list(site), "zones" = list("ss13", "dp")))
	network.on_index(response)
	TEST_ASSERT(network.available, "Valid catalog was rejected")
	TEST_ASSERT_EQUAL(length(network.zones), 2, "Zone list was not cached")
	response.body = json_encode(list("sites" = list(site), "zones" = list(42)))
	network.on_index(response)
	TEST_ASSERT_NOT(network.available, "Malformed zone list was accepted")
	response.body = json_encode(list("sites" = list(site), "zones" = list("ss13", "dp")))
	network.on_index(response)
	TEST_ASSERT(network.has_page("test", "index"), "Catalog page is missing")
	TEST_ASSERT_NOT(network.has_page("test", "../secret"), "Unlisted page was accepted")
	TEST_ASSERT_NOT(network.has_page(list("test"), "index"), "Malformed site ID was accepted")
	var/cache_key = json_encode(list("test", "index"))
	response.body = json_encode(list("site_id" = "test", "slug" = "index", "version" = "1", "tree" = list("type" = "text", "text" = "hello")))
	network.on_page("test", "index", "1", response)
	TEST_ASSERT(network.pages[cache_key], "Valid page was not cached")
	var/list/cached_page = network.pages[cache_key]
	TEST_ASSERT_NULL(cached_page["interactive"], "Interactive page was accepted while disabled")
	var/address = "https://sandbox.wiki-ss13.space/i/0123456789abcdef0123456789abcdef/index"
	TEST_ASSERT(network.interactive_address(address), "Sandbox address was rejected")
	for(var/bad_address in list("http://sandbox.wiki-ss13.space/i/0123456789abcdef0123456789abcdef/index", 		"https://sandbox.wiki-ss13.space/i/short/index", "byond://?src=admin", 		"https://sandbox.wiki-ss13.space/i/0123456789abcdef0123456789abcdef/index?x=1", 		"javascript:alert(1)", "https://sandbox.wiki-ss13.space/other/path"))
		TEST_ASSERT_NOT(network.interactive_address(bad_address), "Bad interactive address was accepted: [bad_address]")
	response.errored = TRUE
	network.on_index(response)
	TEST_ASSERT_NOT(network.available, "Network failure was not reported")
	TEST_ASSERT(network.has_page("test", "index"), "Network failure discarded catalog")
	TEST_ASSERT(network.pages[cache_key], "Network failure discarded cached page")
	response.errored = FALSE
	response.body = "invalid json"
	network.on_index(response)
	TEST_ASSERT(network.has_page("test", "index"), "Malformed JSON discarded catalog")
	response.body = json_encode(list("sites" = list(42)))
	network.on_index(response)
	TEST_ASSERT(network.has_page("test", "index"), "Malformed entry discarded catalog")
	site["version"] = "2"
	response.body = json_encode(list("sites" = list(site)))
	network.on_index(response)
	TEST_ASSERT_NULL(network.pages[cache_key], "Updated site retained stale page")
	response.body = json_encode(list("site_id" = "test", "slug" = "index", "version" = "1", "tree" = list()))
	network.on_page("test", "index", "1", response)
	TEST_ASSERT_NULL(network.pages[cache_key], "Late response restored stale page")
	response.body = json_encode(list("sites" = list()))
	network.on_index(response)
	TEST_ASSERT_NOT(network.has_page("test", "index"), "Removed site remains accessible")

/datum/unit_test/ntnet_login_response/Run()
	var/datum/http_response/response = allocate(/datum/http_response)
	response.status_code = 201
	response.body = json_encode(list("code" = "ABCD-EFGH-JKLM", "expires_in" = 900))
	TEST_ASSERT_EQUAL(parse_ntnet_login_response(response), "ABCD-EFGH-JKLM", "Valid code rejected")
	response.status_code = 429
	TEST_ASSERT_NULL(parse_ntnet_login_response(response), "Rate-limited response accepted")
	response.status_code = 201
	response.errored = TRUE
	TEST_ASSERT_NULL(parse_ntnet_login_response(response), "Failed request accepted")
	response.errored = FALSE
	for(var/bad_body in list("not json", "null", "42", json_encode(list("code" = "ABCD-EFGH-JKLM", "expires_in" = 3600)), json_encode(list("code" = "<script>alert(1)</script>", "expires_in" = 900)), json_encode(list("code" = list("ABCD-EFGH-JKLM"), "expires_in" = 900))))
		response.body = bad_body
		TEST_ASSERT_NULL(parse_ntnet_login_response(response), "Malformed login response accepted")

/datum/unit_test/ntnet_opt_in
	var/saved_enabled
	var/saved_url
	var/saved_key

/datum/unit_test/ntnet_opt_in/Destroy()
	CONFIG_SET(flag/ntnet_enabled, saved_enabled)
	CONFIG_SET(string/ntnet_api_url, saved_url)
	CONFIG_SET(string/ntnet_server_key, saved_key)
	return ..()

/datum/unit_test/ntnet_opt_in/Run()
	saved_enabled = CONFIG_GET(flag/ntnet_enabled)
	saved_url = CONFIG_GET(string/ntnet_api_url)
	saved_key = CONFIG_GET(string/ntnet_server_key)
	CONFIG_SET(flag/ntnet_enabled, FALSE)
	var/obj/item/pda/disabled = allocate(/obj/item/pda)
	TEST_ASSERT_NULL(disabled.find_program(/datum/data/pda/app/ntnet), "Disabled app installed")
	CONFIG_SET(flag/ntnet_enabled, TRUE)
	CONFIG_SET(string/ntnet_api_url, "http://127.0.0.1:8091")
	CONFIG_SET(string/ntnet_server_key, "")
	var/obj/item/pda/unconfigured = allocate(/obj/item/pda)
	TEST_ASSERT_NULL(unconfigured.find_program(/datum/data/pda/app/ntnet), "App installed without a server key")
	CONFIG_SET(string/ntnet_server_key, "unit-test-key")
	var/obj/item/pda/enabled = allocate(/obj/item/pda)
	TEST_ASSERT_NOTNULL(enabled.find_program(/datum/data/pda/app/ntnet), "Enabled app was not installed")
