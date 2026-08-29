/obj/effect/proc_holder/spell/night_vision
	name = "Toggle Nightvision"
	desc = "Toggle your nightvision mode."

	base_cooldown = 1 SECONDS
	clothes_req = FALSE
	human_req = FALSE

	message = span_notice_alt("You toggle your night vision!")

/obj/effect/proc_holder/spell/night_vision/create_new_targeting()
	return new /datum/spell_targeting/self

/obj/effect/proc_holder/spell/night_vision/cast(list/targets, mob/user = usr)
	for(var/mob/living/target in targets)
		switch(target.lighting_cutoff)
			if(LIGHTING_CUTOFF_VISIBLE)
				target.lighting_cutoff = LIGHTING_CUTOFF_MEDIUM
				name = "Toggle Nightvision \[More]"
			if(LIGHTING_CUTOFF_MEDIUM)
				target.lighting_cutoff = LIGHTING_CUTOFF_HIGH
				name = "Toggle Nightvision \[Full]"
			if(LIGHTING_CUTOFF_HIGH)
				target.lighting_cutoff = LIGHTING_CUTOFF_FULLBRIGHT
				name = "Toggle Nightvision \[OFF]"
			else
				target.lighting_cutoff = LIGHTING_CUTOFF_VISIBLE
				name = "Toggle Nightvision \[ON]"
		target.update_sight()

