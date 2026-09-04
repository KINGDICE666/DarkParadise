/turf/simulated/floor/indestructible/bitrunning_pad
	name = "circuit floor"
	desc = "Под ногами по плите бегут ручейки закодированных данных. Сюда складывают зашифрованный груз."
	icon_state = "gcircuit"

/turf/simulated/floor/indestructible/bitrunning_pad/get_ru_names()
	return alist(
		NOMINATIVE = "плита выдачи",
		GENITIVE = "плиты выдачи",
		DATIVE = "плите выдачи",
		ACCUSATIVE = "плиту выдачи",
		INSTRUMENTAL = "плитой выдачи",
		PREPOSITIONAL = "плите выдачи",
	)
