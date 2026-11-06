// Radiation signals

/// От подсистемы радиации зарегистрированным слушателям, до которых дошёл импульс.
/// (rads, turf/source_turf)
#define COMSIG_RADIATION_DETECTED "radiation_detected"

/// Fired when scanning something with a geiger counter.
/// (mob/user, obj/item/geiger_counter/geiger_counter)
#define COMSIG_GEIGER_COUNTER_SCAN "geiger_counter_scan"
	/// If not flagged by any handler, will report the subject as being free of irradiation
	#define COMSIG_GEIGER_COUNTER_SCAN_SUCCESSFUL (1 << 0)

/// От компонента лучевой болезни во время обработки, до симптомов.
/// (seconds_per_tick, dose)
#define COMSIG_IRRADIATED_PROCESS "irradiated_process"
