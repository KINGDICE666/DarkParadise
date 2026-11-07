#define HYDROGEN_IGNITION_TEMP 900
#define HYDROGEN_MIN_BURN 1
#define HYDROGEN_DETONATION_MOLES 20
#define HYDROGEN_DAMAGE_PER_MOLE 0.2
#define HYDROGEN_MAX_DAMAGE 25
#define ANTINOBLIUM_ANOMALY_CHANCE 15

// MARK: Gas Effects Registry

GLOBAL_LIST_INIT(reactor_coolant_effects, build_reactor_gas_effects(/datum/reactor_gas_effect/coolant))
GLOBAL_LIST_INIT(reactor_moderator_effects, build_reactor_gas_effects(/datum/reactor_gas_effect/moderator))

/proc/build_reactor_gas_effects(base_type)
	. = list()
	for(var/datum/reactor_gas_effect/effect as anything in valid_subtypesof(base_type))
		var/datum/reactor_gas_effect/instance = new effect()
		.[instance.gas_id] = instance

// MARK: Reactor Gas Effects Datum System

/datum/reactor_gas_effect
	abstract_type = /datum/reactor_gas_effect
	/// Gas id
	var/gas_id
	/// Effect description for UI
	var/desc = ""
	var/overheat_bonus = 0
	var/event_chance_mod = 0
	var/reactivity_bonus = 0
	/// Control rod efficiency modifier
	var/control_mod = 0
	/// Radiation multiplier
	var/radiation_mod = 0
	/// Heat transfer (permeability) modifier
	var/permeability_mod = 0
	/// Fuel rod depletion modifier
	var/depletion_mod = 0
	var/integrity_restore = 0

/datum/reactor_gas_effect/proc/apply(obj/machinery/atmospherics/fission_reactor/reactor, mole_fraction, mole_multiplier, moles_count)
	reactor.gas_overheat_bonus += overheat_bonus * mole_fraction * mole_multiplier
	reactor.gas_event_modifier += event_chance_mod * mole_fraction
	reactor.gas_reactivity_bonus += reactivity_bonus * mole_fraction * mole_multiplier
	reactor.gas_control_mod += control_mod * mole_fraction
	reactor.gas_radiation_mod += radiation_mod * mole_fraction
	reactor.gas_permeability_mod += permeability_mod * mole_fraction
	reactor.gas_depletion_mod += depletion_mod * mole_fraction
	if(integrity_restore)
		reactor.adjust_damage(-integrity_restore * mole_fraction)

/datum/reactor_gas_effect/proc/extra_effects(obj/machinery/atmospherics/fission_reactor/reactor, datum/gas_mixture/gas_mix, mole_fraction, moles_count)
	return

// MARK: Coolant Gases

/datum/reactor_gas_effect/coolant
	abstract_type = /datum/reactor_gas_effect/coolant

/datum/reactor_gas_effect/coolant/nitrogen
	gas_id = TLV_N2
	overheat_bonus = 600
	event_chance_mod = -20
	desc = "Повышает порог перегрева и снижает шанс аварий."

/datum/reactor_gas_effect/coolant/nitrous_oxide
	gas_id = TLV_N2O
	overheat_bonus = 300
	event_chance_mod = -20
	desc = "Повышает порог перегрева и снижает шанс аварий."

/datum/reactor_gas_effect/coolant/oxygen
	gas_id = TLV_O2
	reactivity_bonus = 0.8
	event_chance_mod = 50
	desc = "Увеличивает реактивность ценой повышенного шанса аварий. С водородом образует гремучую смесь."

/datum/reactor_gas_effect/coolant/plasma
	gas_id = TLV_PL
	reactivity_bonus = 0.2
	overheat_bonus = 200
	desc = "Повышает реактивность и порог перегрева."

/datum/reactor_gas_effect/coolant/carbon_dioxide
	gas_id = TLV_CO2
	event_chance_mod = -60
	desc = "Значительно снижает шанс аварийных событий."

/datum/reactor_gas_effect/coolant/hydrogen
	gas_id = TLV_H2
	reactivity_bonus = 0.3
	event_chance_mod = 20
	desc = "Побочный продукт деления. Слегка разгоняет реакцию, а с кислородом выше 900 K сгорает и может взорваться."

/datum/reactor_gas_effect/coolant/hydrogen/extra_effects(obj/machinery/atmospherics/fission_reactor/reactor, datum/gas_mixture/gas_mix, mole_fraction, moles_count)
	if(gas_mix.temperature() < HYDROGEN_IGNITION_TEMP)
		return
	var/burned = min(moles_count, gas_mix.oxygen() * 2)
	if(burned < HYDROGEN_MIN_BURN)
		return
	gas_mix.adjust_gas(TLV_H2, -burned)
	gas_mix.adjust_gas(TLV_O2, -burned / 2)
	gas_mix.adjust_gas(TLV_H2O, burned)
	if(burned < HYDROGEN_DETONATION_MOLES)
		return
	reactor.adjust_damage(min(burned * HYDROGEN_DAMAGE_PER_MOLE, HYDROGEN_MAX_DAMAGE))
	reactor.shake_animation(1)
	playsound(reactor, 'sound/effects/explosionfar.ogg', 80, TRUE)
	reactor.visible_message(span_danger("Внутри [reactor.declent_ru(GENITIVE)] глухо хлопает гремучая смесь!"))

/datum/reactor_gas_effect/coolant/water_vapor
	gas_id = TLV_H2O
	overheat_bonus = 400
	event_chance_mod = -10
	desc = "Пар хорошо уносит тепло и повышает порог перегрева. Образуется при сгорании водорода."

/datum/reactor_gas_effect/coolant/agent_b
	gas_id = TLV_AGENT_B
	reactivity_bonus = 0.6
	event_chance_mod = 30
	desc = "Катализатор: разгоняет реакцию и делает её менее предсказуемой."

/datum/reactor_gas_effect/coolant/tritium
	gas_id = TLV_TRITIUM
	reactivity_bonus = 1.2
	event_chance_mod = 40
	radiation_mod = 0.5
	desc = "Сам радиоактивен: сильно разгоняет реакцию и повышает радиационный фон."

/datum/reactor_gas_effect/coolant/bz
	gas_id = TLV_BZ
	reactivity_bonus = -0.5
	overheat_bonus = 100
	event_chance_mod = -10
	desc = "Поглощает нейтроны и гасит реактивность."

/datum/reactor_gas_effect/coolant/pluoxium
	gas_id = TLV_PLUOXIUM
	overheat_bonus = 800
	event_chance_mod = -30
	desc = "Сверхстабильный газ: заметно поднимает порог перегрева."

/datum/reactor_gas_effect/coolant/miasma
	gas_id = TLV_MIASMA
	event_chance_mod = 30
	depletion_mod = 0.5
	desc = "Органика оседает на стержнях и ускоряет их износ."

/datum/reactor_gas_effect/coolant/freon
	gas_id = TLV_FREON
	overheat_bonus = 1000
	reactivity_bonus = -0.8
	desc = "Хладагент: сильно поднимает порог перегрева, но душит реакцию."

/datum/reactor_gas_effect/coolant/nitrium
	gas_id = TLV_NITRIUM
	control_mod = 2
	event_chance_mod = 25
	desc = "Ускоряет приводы стержней управления, но расшатывает реакцию."

/datum/reactor_gas_effect/coolant/healium
	gas_id = TLV_HEALIUM
	integrity_restore = 0.3
	event_chance_mod = -40
	desc = "Медленно заращивает повреждения корпуса и снижает шанс аварий."

/datum/reactor_gas_effect/coolant/proto_nitrate
	gas_id = TLV_PROTO_NITRATE
	reactivity_bonus = 0.6
	radiation_mod = 0.4
	depletion_mod = 0.3
	desc = "Агрессивный окислитель: разгоняет реакцию и изнашивает стержни."

/datum/reactor_gas_effect/coolant/zauker
	gas_id = TLV_ZAUKER
	integrity_restore = -0.5
	event_chance_mod = 100
	desc = "Разъедает корпус реактора и провоцирует аварии."

/datum/reactor_gas_effect/coolant/halon
	gas_id = TLV_HALON
	overheat_bonus = 200
	event_chance_mod = -80
	desc = "Огнегасящий газ: почти полностью подавляет аварии."

/datum/reactor_gas_effect/coolant/helium
	gas_id = TLV_HELIUM
	overheat_bonus = 700
	event_chance_mod = -20
	desc = "Классический теплоноситель газовых реакторов: инертен и отлично отводит тепло."

/datum/reactor_gas_effect/coolant/antinoblium
	gas_id = TLV_ANTINOBLIUM
	reactivity_bonus = 3
	overheat_bonus = -500
	event_chance_mod = 300
	radiation_mod = 1
	desc = "Разрушает стабильность ядра: реакция идёт вразнос, в активной зоне возникают аномалии."

/datum/reactor_gas_effect/coolant/antinoblium/extra_effects(obj/machinery/atmospherics/fission_reactor/reactor, datum/gas_mixture/gas_mix, mole_fraction, moles_count)
	if(prob(mole_fraction * ANTINOBLIUM_ANOMALY_CHANCE))
		reactor.core_anomaly()

/datum/reactor_gas_effect/coolant/hypernoblium
	gas_id = TLV_HYPERNOBLIUM
	reactivity_bonus = -2
	overheat_bonus = 300
	event_chance_mod = -90
	desc = "Замораживает реакцию: резко снижает реактивность и шанс аварий."

// MARK: Moderator Gases

/datum/reactor_gas_effect/moderator
	abstract_type = /datum/reactor_gas_effect/moderator
	var/power_per_mole = 0
	var/heat_per_mole = 0
	/// Power multiplier (catalyst)
	var/power_mod = 0

/datum/reactor_gas_effect/moderator/apply(obj/machinery/atmospherics/fission_reactor/reactor, mole_fraction, mole_multiplier, moles_count)
	. = ..()
	reactor.gas_fuel_heat += heat_per_mole * moles_count

	if(power_per_mole > 0)
		reactor.gas_fuel_power += moles_count * power_per_mole
		reactor.gas_fuel_moles += moles_count
		reactor.gas_is_fueled = TRUE

	if(power_mod * mole_fraction > reactor.gas_power_mod)
		reactor.gas_power_mod = power_mod * mole_fraction

/datum/reactor_gas_effect/moderator/nitrogen
	gas_id = TLV_N2
	control_mod = 4
	radiation_mod = 0.04
	desc = "Улучшает контроль над реакцией, но повышает радиационный фон."

/datum/reactor_gas_effect/moderator/pluoxium
	gas_id = TLV_PLUOXIUM
	control_mod = 6
	desc = "Значительно улучшает контроль без повышения радиации."

/datum/reactor_gas_effect/moderator/carbon_dioxide
	gas_id = TLV_CO2
	control_mod = 8
	radiation_mod = 0.08
	desc = "Максимальный контроль ценой экстремальной радиации."

/datum/reactor_gas_effect/moderator/bz
	gas_id = TLV_BZ
	permeability_mod = 0.2
	desc = "Улучшает поглощение тепла от стержней."

/datum/reactor_gas_effect/moderator/water_vapor
	gas_id = TLV_H2O
	permeability_mod = 0.4
	desc = "Значительно улучшает поглощение тепла от стержней."

/datum/reactor_gas_effect/moderator/hypernoblium
	gas_id = TLV_HYPERNOBLIUM
	permeability_mod = 2
	desc = "Экстремально улучшает поглощение тепла от стержней."

/datum/reactor_gas_effect/moderator/nitrous_oxide
	gas_id = TLV_N2O
	depletion_mod = 0.67
	desc = "Ускоряет износ топливных стержней."

/datum/reactor_gas_effect/moderator/nitrous_oxide/extra_effects(obj/machinery/atmospherics/fission_reactor/reactor, datum/gas_mixture/gas_mix, mole_fraction, moles_count)
	if(prob(5))
		playsound(reactor, SFX_SM_CALM, 100, TRUE)

/datum/reactor_gas_effect/moderator/healium
	gas_id = TLV_HEALIUM
	integrity_restore = 1
	desc = "Восстанавливает целостность реактора."

/datum/reactor_gas_effect/moderator/plasma
	gas_id = TLV_PL
	power_per_mole = 10 WATTS
	heat_per_mole = 5
	desc = "Горит в активной зоне как топливо."

/datum/reactor_gas_effect/moderator/tritium
	gas_id = TLV_TRITIUM
	power_per_mole = 100 WATTS
	heat_per_mole = 50
	radiation_mod = 0.2
	desc = "Сверхэффективное топливо. Повышает радиационный фон."

/datum/reactor_gas_effect/moderator/oxygen
	gas_id = TLV_O2
	power_mod = 10
	desc = "Катализатор для газового топлива, умножает выход энергии."

/datum/reactor_gas_effect/moderator/hydrogen
	gas_id = TLV_H2
	power_per_mole = 30 WATTS
	heat_per_mole = 15
	desc = "Сгорает в активной зоне как топливо: втрое эффективнее плазмы."

/datum/reactor_gas_effect/moderator/agent_b
	gas_id = TLV_AGENT_B
	power_mod = 20
	desc = "Сильнейший катализатор газового топлива."

/datum/reactor_gas_effect/moderator/miasma
	gas_id = TLV_MIASMA
	depletion_mod = 1
	radiation_mod = 0.1
	desc = "Забивает каналы органикой: стержни изнашиваются быстрее."

/datum/reactor_gas_effect/moderator/freon
	gas_id = TLV_FREON
	permeability_mod = 1
	heat_per_mole = -10
	desc = "Поглощает тепло прямо в активной зоне."

/datum/reactor_gas_effect/moderator/nitrium
	gas_id = TLV_NITRIUM
	control_mod = 10
	depletion_mod = 0.3
	desc = "Резко ускоряет приводы стержней, но изнашивает топливо."

/datum/reactor_gas_effect/moderator/proto_nitrate
	gas_id = TLV_PROTO_NITRATE
	power_mod = 15
	radiation_mod = 0.3
	desc = "Катализатор газового топлива. Повышает радиационный фон."

/datum/reactor_gas_effect/moderator/zauker
	gas_id = TLV_ZAUKER
	power_per_mole = 200 WATTS
	heat_per_mole = 100
	integrity_restore = -2
	desc = "Чудовищно мощное топливо, которое разъедает активную зону."

/datum/reactor_gas_effect/moderator/halon
	gas_id = TLV_HALON
	control_mod = 5
	heat_per_mole = -5
	desc = "Улучшает контроль и слегка охлаждает активную зону."

/datum/reactor_gas_effect/moderator/helium
	gas_id = TLV_HELIUM
	control_mod = 3
	desc = "Инертный газ: улучшает контроль без побочных эффектов."

/datum/reactor_gas_effect/moderator/antinoblium
	gas_id = TLV_ANTINOBLIUM
	power_per_mole = 500 WATTS
	heat_per_mole = 300
	radiation_mod = 1
	integrity_restore = -1
	desc = "Нестабильнейшее топливо: огромная мощность ценой разрушения ядра и аномалий."

/datum/reactor_gas_effect/moderator/antinoblium/extra_effects(obj/machinery/atmospherics/fission_reactor/reactor, datum/gas_mixture/gas_mix, mole_fraction, moles_count)
	if(prob(mole_fraction * ANTINOBLIUM_ANOMALY_CHANCE))
		reactor.core_anomaly()

#undef HYDROGEN_IGNITION_TEMP
#undef HYDROGEN_MIN_BURN
#undef HYDROGEN_DETONATION_MOLES
#undef HYDROGEN_DAMAGE_PER_MOLE
#undef HYDROGEN_MAX_DAMAGE
#undef ANTINOBLIUM_ANOMALY_CHANCE
