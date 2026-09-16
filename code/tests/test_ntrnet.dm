/datum/unit_test/ntrnet_responses
	var/list/saved_state

/datum/unit_test/ntrnet_responses/Destroy()
	for(var/var_name in saved_state)
		SSntrnet.vars[var_name] = saved_state[var_name]
	saved_state = null
	return ..()

/datum/unit_test/ntrnet_responses/Run()
	var/datum/controller/subsystem/ntrnet/network = SSntrnet
	saved_state = list()
	for(var/var_name in list("sites", "catalog", "pages", "page_retry", "pending", "available", "index_pending"))
		saved_state[var_name] = network.vars[var_name]
	network.sites = list()
	network.catalog = list()
	network.pages = list()
	network.page_retry = list()
	network.pending = list()
	var/datum/http_response/response = allocate(/datum/http_response)
	response.status_code = 200
	var/list/site = list("id" = "test", "domain" = "test.ss13", "title" = "Test", "version" = "1", "pages" = list(list("slug" = "index", "title" = "Index")))
	response.body = json_encode(list("sites" = list(site)))
	network.on_index(response)
	TEST_ASSERT(network.available, "Valid catalog was rejected")
	TEST_ASSERT(network.has_page("test", "index"), "Catalog page is missing")
	TEST_ASSERT_NOT(network.has_page("test", "../secret"), "Unlisted page was accepted")
	TEST_ASSERT_NOT(network.has_page(list("test"), "index"), "Malformed site ID was accepted")
	var/cache_key = json_encode(list("test", "index"))
	response.body = json_encode(list("site_id" = "test", "slug" = "index", "version" = "1", "tree" = list("type" = "text", "text" = "hello")))
	network.on_page("test", "index", "1", response)
	TEST_ASSERT(network.pages[cache_key], "Valid page was not cached")
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
