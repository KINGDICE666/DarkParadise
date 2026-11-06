#define FOOD_EXPORT_NUTRIMENT_PRICE 2
#define FOOD_EXPORT_MAX_PRICE 60

/datum/export/food
	cost = 5
	k_hit_percentile = 0.02
	unit_name = "готовые блюда"
	export_types = list(/obj/item/reagent_containers/food/snacks)
	exclude_types = list(/obj/item/reagent_containers/food/snacks/grown)

/datum/export/food/get_base_cost(obj/item/reagent_containers/food/snacks/dish)
	var/nutriment = dish.reagents?.get_reagent_amount("nutriment") + dish.reagents?.get_reagent_amount("protein") + dish.reagents?.get_reagent_amount("vitamin")
	return min(cost + nutriment * FOOD_EXPORT_NUTRIMENT_PRICE, FOOD_EXPORT_MAX_PRICE)

/datum/export/produce
	cost = 3
	k_hit_percentile = 0.01
	unit_name = "урожай гидропоники"
	export_types = list(/obj/item/reagent_containers/food/snacks/grown)

/datum/export/produce/get_base_cost(obj/item/reagent_containers/food/snacks/grown/produce)
	return cost + round(produce.seed?.potency / 20)

#undef FOOD_EXPORT_NUTRIMENT_PRICE
#undef FOOD_EXPORT_MAX_PRICE
