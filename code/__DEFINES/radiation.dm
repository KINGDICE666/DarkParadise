/*
Эти дефайны определяют баланс разных частей системы радиации.
Изменения здесь влияют на многое: проверяйте их как следует.

Импульс несёт рады: дозу, которую незащищённый человек получает в одном тайле от источника.
Доза падает с квадратом расстояния и умножается на изоляцию всего, что на пути.
*/

/// Дозы ниже этой игнорируются, этим же ограничена дальность импульса
#define RAD_MINIMUM_DOSE 0.1
/// Дальше этого не дойдёт ни один импульс, какой бы он ни был сильный
#define RAD_MAXIMUM_RANGE 24

#define RAD_NO_INSULATION 1.0 //! For things that shouldn't become irradiated for whatever reason
#define RAD_VERY_LIGHT_INSULATION 0.9 //! Как у балок
#define RAD_LIGHT_INSULATION 0.75 //! Как у шкафов
#define RAD_MEDIUM_INSULATION 0.5 //! Как у закрытых шлюзов
#define RAD_HEAVY_INSULATION 0.25 //! Как у обычных стен
#define RAD_EXTREME_INSULATION 0.1 //! Как у усиленных стен и радиационных ставней
#define RAD_FULL_INSULATION 0 //! Полностью останавливает радиацию

// Доля внешнего излучения, которую останавливает защитная одежда
#define RAD_PROTECTION_LIGHT 0.7
#define RAD_PROTECTION_STANDARD 0.85
#define RAD_PROTECTION_HEAVY 0.9
#define RAD_PROTECTION_FULL 0.95
/// С такой защитой человек считается полностью укрытым от шторма
#define RAD_PROTECTION_SEALED 0.75
/// Что остаётся от внешней дозы, пока усваивается радиопротектор
#define RAD_RESISTANCE_FACTOR 0.7

// Стадии лучевой болезни по поглощённой дозе
#define RADIATION_STAGE_NONE 0
#define RADIATION_STAGE_MILD 1
#define RADIATION_STAGE_MODERATE 2
#define RADIATION_STAGE_SEVERE 3
#define RADIATION_STAGE_FATAL 4

#define RADIATION_DOSE_MILD 100
#define RADIATION_DOSE_MODERATE 300
#define RADIATION_DOSE_SEVERE 600
#define RADIATION_DOSE_FATAL 1000
/// Предел дозы, чтобы пациента всегда можно было вылечить за разумное время
#define RADIATION_DOSE_MAXIMUM 1500

/// Возвращает стадию болезни для поглощённой дозы
#define RADIATION_STAGE_FOR_DOSE(dose) ((dose) >= RADIATION_DOSE_FATAL ? RADIATION_STAGE_FATAL : (dose) >= RADIATION_DOSE_SEVERE ? RADIATION_STAGE_SEVERE : (dose) >= RADIATION_DOSE_MODERATE ? RADIATION_STAGE_MODERATE : (dose) >= RADIATION_DOSE_MILD ? RADIATION_STAGE_MILD : RADIATION_STAGE_NONE)

/// Сколько симптомы новой стадии скрыты, если доза опережает их на одну стадию
#define RADIATION_LATENT_PERIOD (60 SECONDS)

// Заражение предметов
/// Столько предмет должен получить за один импульс, чтобы загрязниться
#define RAD_ITEM_MINIMUM_DOSE 5
/// С этого уровня загрязнённые предметы начинают светиться
#define RAD_ITEM_GLOW_LEVEL 150
#define RAD_ITEM_MAXIMUM_CONTAMINATION 1000
/// Дальше этого импульс не загрязняет предметы, чтобы не перебирать лишние тайлы
#define RAD_ITEM_MAXIMUM_RANGE 6
#define RAD_ITEM_MINIMUM_CONTAMINATION 1
/// Доля загрязнения, которую предмет передаёт владельцу в секунду
#define RAD_ITEM_HOLDER_DOSE_FACTOR 0.002
/// Доля загрязнения, которую предмет теряет в секунду
#define RAD_ITEM_DECAY_FACTOR 0.002

// Загрязнение кожи и одежды
#define RAD_SURFACE_MAXIMUM 200
/// Доза в секунду на единицу загрязнения кожи
#define RAD_SURFACE_DOSE_FACTOR 0.02
/// Доля загрязнения кожи, которая сама спадает в секунду
#define RAD_SURFACE_DECAY_FACTOR 0.005

// Возвращаемые значения [proc/get_perceived_radiation_danger]
// If you change these, update /datum/looping_sound/geiger as well.
#define PERCEIVED_RADIATION_DANGER_LOW 1
#define PERCEIVED_RADIATION_DANGER_MEDIUM 2
#define PERCEIVED_RADIATION_DANGER_HIGH 3
#define PERCEIVED_RADIATION_DANGER_EXTREME 4

// Рад за импульс, разделяющие уровни опасности
#define RAD_DANGER_DOSE_MEDIUM 1
#define RAD_DANGER_DOSE_HIGH 5
#define RAD_DANGER_DOSE_EXTREME 25

/// The time before geiger counters reset back to normal without any radiation pulses
#define TIME_WITHOUT_RADIATION_BEFORE_RESET (5 SECONDS)

// Сила частых источников в радах за импульс
#define RAD_PULSE_URANIUM_STRUCTURE 6
#define RAD_PULSE_URANIUM_FLOOR 2
#define RAD_PULSE_URANIUM_AIRLOCK 4
#define RAD_PULSE_URANIUM_ITEM 0.5
#define RAD_PULSE_RADIOACTIVE_GOO 4
#define RAD_PULSE_NUCLEAR_WASTE 15
#define RAD_PULSE_NUCLEAR_SLAG 25
#define RAD_PULSE_ATMOS_PER_RANGE 2
#define RAD_PULSE_SPILL_MAXIMUM 30
