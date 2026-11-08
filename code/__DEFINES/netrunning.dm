#define isnetavatar(thing) istype(thing, /mob/living/basic/net_avatar)

#define NETRUNNING_TRAIT "netrunning"

#define NET_JACK_OUT_TIME (5 SECONDS)
#define NET_DOOR_HACK_TIME (3 SECONDS)
#define NET_CONDUIT_COOLDOWN (10 SECONDS)
#define NET_EMP_DAMAGE 20

#define NET_GRID_SCREEN "net_grid"

#define NET_AVATAR_GLOW "#FF2A6D"
#define NET_PARTICLE_COLOR "#FF4F8B"

#define MATRIX_NET_VISION list(\
	0.015, 0.21, 0.24, \
	0.03, 0.41, 0.47, \
	0.006, 0.08, 0.09, \
	0, 0.02, 0.04 \
)

#define MATRIX_NET_AVATAR list(\
	0.4, 0.05, 0.13, \
	0.75, 0.1, 0.25, \
	0.15, 0.02, 0.06, \
	0.12, 0, 0.04 \
)
