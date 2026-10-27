/datum/unit_test/room_test/spawn_humans/Run()
	for(var/I in 1 to 5)
		allocate(/mob/living/carbon/human, pick(available_turfs))

	// There is a 5 second delay here so that all the items on the humans have time to initialize and spawn
	sleep(5 SECONDS)

/// Tests [/mob/living/carbon/human/proc/setup_organless_effects], specifically that they aren't applied when init is done
/datum/unit_test/room_test/human_default_traits

/datum/unit_test/room_test/human_default_traits/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!HAS_TRAIT_FROM(dummy, TRAIT_DEAF, NO_EARS), "Dummy is deaf on init, when it should've been removed by its default ears.")

/datum/unit_test/room_test/interrupted_get_up/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(attacker, EAST))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	bystander.shove_impact(victim, attacker)
	sleep(1.5 SECONDS)
	victim.Stun(1 SECONDS)
	sleep(0.5 SECONDS)
	TEST_ASSERT_EQUAL(victim.body_position, LYING_DOWN, "The victim stood up before the stun ended.")
	sleep(3 SECONDS)
	TEST_ASSERT(!victim.IsStunned(), "The victim's stun did not expire.")
	TEST_ASSERT_EQUAL(victim.body_position, STANDING_UP, "A stun interrupting get_up left the victim crawling.")
	TEST_ASSERT_EQUAL(bystander.body_position, STANDING_UP, "The bystander did not recover from the collision.")
	TEST_ASSERT_EQUAL(victim.usable_legs, 2, "The collision disabled the victim's legs.")

	victim.set_resting(TRUE, instant = TRUE)
	victim.Stun(1 SECONDS)
	sleep(3 SECONDS)
	TEST_ASSERT_EQUAL(victim.body_position, LYING_DOWN, "Recovering from a stun made a resting victim stand up.")
	victim.set_resting(FALSE, instant = TRUE)

	victim.Knockdown(4 SECONDS)
	victim.Stun(1 SECONDS)
	sleep(2 SECONDS)
	TEST_ASSERT_EQUAL(victim.body_position, LYING_DOWN, "Recovering from a stun bypassed an active knockdown.")
	sleep(4 SECONDS)
	TEST_ASSERT_EQUAL(victim.body_position, STANDING_UP, "The victim did not recover after all effects expired.")
