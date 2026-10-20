/proc/random_hair_colour()
	var/list/base
	switch(pick("blonde", "black", "chestnut", "copper", "brown", "wheat", "old", "punk"))
		if("blonde")
			base = list(255, 255, 0)
		if("black")
			base = list(0, 0, 0)
		if("chestnut")
			base = list(153, 102, 51)
		if("copper")
			base = list(255, 153, 0)
		if("brown")
			base = list(102, 51, 0)
		if("wheat")
			base = list(255, 255, 153)
		if("old")
			var/grey = rand(100, 255)
			base = list(grey, grey, grey)
		if("punk")
			base = list(rand(0, 255), rand(0, 255), rand(0, 255))
	return jitter_colour(base)

/proc/random_natural_colour()
	var/list/base
	switch(pick("black", "grey", "brown", "chestnut", "blue", "lightblue", "green", "albino"))
		if("black")
			base = list(0, 0, 0)
		if("grey")
			var/grey = rand(100, 200)
			base = list(grey, grey, grey)
		if("brown")
			base = list(102, 51, 0)
		if("chestnut")
			base = list(153, 102, 0)
		if("blue")
			base = list(51, 102, 204)
		if("lightblue")
			base = list(102, 204, 255)
		if("green")
			base = list(0, 102, 0)
		if("albino")
			base = list(rand(200, 255), rand(0, 150), rand(0, 150))
	return jitter_colour(base)

/proc/jitter_colour(list/base)
	return rgb(clamp(base[1] + rand(-25, 25), 0, 255), clamp(base[2] + rand(-25, 25), 0, 255), clamp(base[3] + rand(-25, 25), 0, 255))

/datum/outfit/observer_preview
	name = "Observer (Preview only)"
	uniform = /obj/item/clothing/under/tourist_suit
	shoes = /obj/item/clothing/shoes/color/black

/datum/outfit/observer_preview/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	switch(H.backbag)
		if(GSATCHEL, DSATCHEL)
			back = /obj/item/storage/backpack/satchel_norm
		if(LSATCHEL)
			back = /obj/item/storage/backpack/satchel
		if(GDUFFLEBAG, DDUFFLEBAG)
			back = /obj/item/storage/backpack/duffel
		else
			back = /obj/item/storage/backpack

/datum/preferences/proc/get_preview_icon()
	var/mob/living/carbon/human/dummy/mannequin = new
	apply_prefs_to(mannequin)
	mannequin.equipOutfit(/datum/outfit/observer_preview, visualsOnly = TRUE)
	var/list/frames = list()
	for(var/direction in GLOB.cardinal)
		frames["[direction]"] = getFlatIcon(mannequin, direction)
	var/icon/preview = icon(frames[frames[1]])
	for(var/direction in GLOB.cardinal)
		preview.Insert(frames["[direction]"], dir = direction)
	qdel(mannequin)
	return preview
