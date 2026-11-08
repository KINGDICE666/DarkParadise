/particles/sparkles
	icon = 'icons/effects/particles/generic_particles.dmi'
	icon_state = list("cross" = 3, "x" = 1)
	width = 64
	height = 64
	count = 40
	spawning = 0.6
	lifespan = generator(GEN_NUM, 0.8 SECONDS, 1.5 SECONDS, UNIFORM_RAND)
	fadein = 0.2 SECONDS
	fade = 0.6 SECONDS
	color = "#FFE680"
	position = generator(GEN_BOX, list(-16, -16), list(16, 20), UNIFORM_RAND)
	scale = generator(GEN_VECTOR, list(0.4, 0.4), list(0.9, 0.9), UNIFORM_RAND)
	spin = generator(GEN_NUM, -10, 10)

/particles/aura
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = "dot"
	width = 64
	height = 96
	count = 60
	spawning = 1
	lifespan = 1.5 SECONDS
	fadein = 0.3 SECONDS
	fade = 0.8 SECONDS
	gradient = list("#FFF7C2", "#FFB300")
	color = generator(GEN_NUM, 0, 1)
	position = generator(GEN_BOX, list(-12, -16), list(12, 4), UNIFORM_RAND)
	velocity = list(0, 0.6)
	drift = generator(GEN_VECTOR, list(-0.1, 0), list(0.1, 0.05), UNIFORM_RAND)
	scale = generator(GEN_VECTOR, list(0.5, 0.5), list(1, 1), UNIFORM_RAND)

/particles/aura/dark
	gradient = list("#4B0082", "#0D0015")

/particles/aura/blood
	icon_state = list("dot" = 3, "drop" = 1)
	gradient = list("#FF2A2A", "#5C0000")

/particles/aura/frost
	icon_state = list("dot" = 3, "cross" = 1)
	gradient = list("#FFFFFF", "#7FD4FF")
	velocity = list(0, 0.3)

/particles/aura/fire
	icon = 'icons/effects/particles/generic_particles.dmi'
	icon_state = "fire"
	spawning = 2
	lifespan = 1 SECONDS
	fade = 0.6 SECONDS
	gradient = list("#FFE16B", "#FF6A00", "#B31300")
	color = 0
	color_change = 0.1
	velocity = list(0, 1)

/particles/snowfall
	icon = 'icons/effects/particles/generic_particles.dmi'
	icon_state = "snow"
	width = 128
	height = 128
	count = 80
	spawning = 0.8
	lifespan = 3 SECONDS
	fadein = 0.3 SECONDS
	fade = 1 SECONDS
	position = generator(GEN_BOX, list(-48, 48), list(48, 56), UNIFORM_RAND)
	gravity = list(0, -0.3)
	friction = 0.2
	drift = generator(GEN_VECTOR, list(-0.2, 0), list(0.2, 0), UNIFORM_RAND)
	scale = generator(GEN_VECTOR, list(0.5, 0.5), list(1, 1), UNIFORM_RAND)
	spin = generator(GEN_NUM, -5, 5)

/particles/fireflies
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = "dot"
	width = 128
	height = 128
	count = 15
	spawning = 0.1
	lifespan = generator(GEN_NUM, 3 SECONDS, 5 SECONDS, UNIFORM_RAND)
	fadein = 1 SECONDS
	fade = 1.5 SECONDS
	color = "#D4FF5A"
	position = generator(GEN_CIRCLE, 8, 40, UNIFORM_RAND)
	drift = generator(GEN_SPHERE, 0, 0.15, NORMAL_RAND)
	friction = 0.1
	scale = generator(GEN_VECTOR, list(0.6, 0.6), list(1, 1), UNIFORM_RAND)

/particles/falling_leaves
	icon = 'icons/effects/particles/generic_particles.dmi'
	icon_state = "leaf"
	width = 128
	height = 128
	count = 20
	spawning = 0.2
	lifespan = 3 SECONDS
	fadein = 0.3 SECONDS
	fade = 1 SECONDS
	position = generator(GEN_BOX, list(-40, 40), list(40, 48), UNIFORM_RAND)
	gravity = list(0, -0.4)
	friction = 0.3
	drift = generator(GEN_VECTOR, list(-0.4, 0), list(0.4, 0), NORMAL_RAND)
	spin = generator(GEN_NUM, -15, 15)

/particles/electric
	icon = 'icons/effects/particles/generic_particles.dmi'
	icon_state = "spark"
	width = 64
	height = 64
	count = 20
	spawning = 0.8
	lifespan = 0.4 SECONDS
	fade = 0.2 SECONDS
	gradient = list("#FFFFFF", "#6EC8FF", "#2B5BFF")
	color = generator(GEN_NUM, 0, 2)
	position = generator(GEN_BOX, list(-14, -16), list(14, 16), UNIFORM_RAND)
	rotation = generator(GEN_NUM, 0, 360, UNIFORM_RAND)
	scale = generator(GEN_VECTOR, list(0.6, 0.6), list(1.2, 1.2), UNIFORM_RAND)

/particles/stink
	icon = 'icons/effects/particles/stink.dmi'
	icon_state = list("stink_1" = 1, "stink_2" = 1, "stink_3" = 1)
	width = 64
	height = 96
	count = 20
	spawning = 0.4
	lifespan = 2 SECONDS
	fadein = 0.3 SECONDS
	fade = 1 SECONDS
	position = generator(GEN_BOX, list(-10, -12), list(10, 8), UNIFORM_RAND)
	velocity = list(0, 0.4)
	drift = generator(GEN_VECTOR, list(-0.1, 0), list(0.1, 0), UNIFORM_RAND)

/particles/pollen
	icon = 'icons/effects/particles/pollen.dmi'
	icon_state = "pollen"
	width = 96
	height = 96
	count = 30
	spawning = 0.3
	lifespan = 3 SECONDS
	fadein = 0.5 SECONDS
	fade = 1 SECONDS
	position = generator(GEN_CIRCLE, 0, 24, UNIFORM_RAND)
	drift = generator(GEN_SPHERE, 0, 0.1, NORMAL_RAND)
	friction = 0.1
