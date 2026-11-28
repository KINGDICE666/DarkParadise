/obj/effect/vaultspawner
	var/maxX = 6
	var/maxY = 6
	var/minX = 2
	var/minY = 2

/obj/effect/vaultspawner/Initialize(mapload, lX = minX, uX = maxX, lY = minY, uY = maxY, vault_type)
	. = ..()
	if(!vault_type)
		vault_type = pick("sandstone", "rock", "alien")

	var/turf/location = get_turf(src)
	var/lowBoundX = location.x
	var/lowBoundY = location.y
	var/hiBoundX = location.x + rand(lX, uX)
	var/hiBoundY = location.y + rand(lY, uY)
	var/z = location.z

	for(var/i in (lowBoundX) to (hiBoundX))
		for(var/j in (lowBoundY) to (hiBoundY))
			var/turf/spot = locate(i, j, z)
			if(i == lowBoundX || i == hiBoundX || j == lowBoundY || j == hiBoundY)
				spot.ChangeTurf(/turf/simulated/wall/vault)
			else
				spot = spot.ChangeTurf(/turf/simulated/floor/vault)
				spot.icon_state = "[vault_type]vault"

	return INITIALIZE_HINT_QDEL
