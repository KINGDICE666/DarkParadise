GLOBAL_LIST_INIT(antag_preference_names, list(
	ROLE_ABDUCTOR = "Абдуктор",
	ROLE_BLOB = "Блоб",
	ROLE_CHANGELING = "Генокрад",
	ROLE_BORER = "Мозговой червь",
	ROLE_CULTIST = "Культист",
	ROLE_CLOCKER = "Культист Ратвара",
	ROLE_DEMON = "Демон",
	ROLE_DEVIL = "Дьявол",
	ROLE_GLITCH = "Цифровой глитч",
	ROLE_GSPIDER = "Гигантский паук",
	ROLE_GUARDIAN = "Страж",
	ROLE_HERETIC = "Еретик",
	ROLE_ELITE = "Элита Лаваленда",
	ROLE_MALF_AI = "Сбойный ИИ",
	ROLE_ESCAPING_PRISONER = "Сбежавший заключённый",
	ROLE_MORPH = "Морф",
	ROLE_OPERATIVE = "Ядерный оперативник",
	ROLE_PAI = "пИИ",
	ROLE_POSIBRAIN = "Позитронный мозг",
	ROLE_REVENANT = "Ревенант",
	ROLE_REV = "Революционер",
	ROLE_SENTIENT = "Разумное животное",
	ROLE_SHADOWLING = "Тенелинг",
	ROLE_SPACE_DRAGON = "Космический дракон",
	ROLE_NINJA = "Космический ниндзя",
	ROLE_TERROR_SPIDER = "Паук Ужаса",
	ROLE_THIEF = "Вор",
	ROLE_THUNDERDOME = "Тандердом",
	ROLE_TRADER = "Торговец",
	ROLE_TRAITOR = "Предатель",
	ROLE_VAMPIRE = "Вампир",
	ROLE_VOX_RAIDER = "Рейдер воксов",
	ROLE_WIZARD = "Волшебник",
	ROLE_ALIEN = "Ксеноморф",
	ROLE_BINGLE = "Бингл",
))

GLOBAL_LIST_INIT(antag_preference_icons, list(
	ROLE_ABDUCTOR = /mob/living/simple_animal/hostile/abductor,
	ROLE_BLOB = /obj/structure/blob/normal,
	ROLE_CHANGELING = /obj/item/melee/changeling/arm_blade,
	ROLE_BORER = /mob/living/simple_animal/borer,
	ROLE_CULTIST = /obj/item/melee/cultblade,
	ROLE_CLOCKER = /mob/living/simple_animal/hostile/clockwork/marauder,
	ROLE_DEMON = /mob/living/simple_animal/demon/slaughter,
	ROLE_DEVIL = /mob/living/carbon/true_devil,
	ROLE_GLITCH = /mob/living/basic/netguardian,
	ROLE_GSPIDER = /mob/living/simple_animal/hostile/poison/giant_spider,
	ROLE_GUARDIAN = /mob/living/simple_animal/hostile/guardian,
	ROLE_HERETIC = /obj/item/codex_cicatrix,
	ROLE_ELITE = /mob/living/simple_animal/hostile/asteroid/elite/legionnaire,
	ROLE_MALF_AI = /obj/structure/AIcore,
	ROLE_ESCAPING_PRISONER = /obj/item/clothing/under/color/orange/prison,
	ROLE_MORPH = /mob/living/simple_animal/hostile/morph,
	ROLE_OPERATIVE = /obj/machinery/nuclearbomb,
	ROLE_PAI = /obj/item/paicard,
	ROLE_POSIBRAIN = /obj/item/mmi/robotic_brain/positronic,
	ROLE_REVENANT = /mob/living/simple_animal/revenant,
	ROLE_REV = /obj/item/flash,
	ROLE_SENTIENT = /mob/living/simple_animal/pet/dog/corgi,
	ROLE_SHADOWLING = /mob/living/simple_animal/ascendant_shadowling,
	ROLE_SPACE_DRAGON = /mob/living/simple_animal/hostile/space_dragon,
	ROLE_NINJA = /obj/item/clothing/mask/gas/space_ninja,
	ROLE_TERROR_SPIDER = /mob/living/simple_animal/hostile/poison/terror_spider/queen,
	ROLE_THIEF = /obj/item/clothing/gloves/color/black/thief,
	ROLE_THUNDERDOME = /obj/item/clothing/head/helmet/thunderdome,
	ROLE_TRADER = /obj/item/coin/gold,
	ROLE_TRAITOR = /obj/item/card/emag,
	ROLE_VAMPIRE = /mob/living/simple_animal/hostile/vampire/hound,
	ROLE_VOX_RAIDER = /obj/item/clothing/head/helmet/space/vox/carapace,
	ROLE_WIZARD = /obj/item/clothing/head/wizard,
	ROLE_ALIEN = /mob/living/carbon/alien/humanoid/hunter,
	ROLE_BINGLE = /mob/living/simple_animal/hostile/bingle,
))

/datum/preference_middleware/antags
	action_delegations = list(
		"toggle_antag" = PROC_REF(toggle_antag),
		"set_antags" = PROC_REF(set_antags),
		"toggle_skip_antag" = PROC_REF(toggle_skip_antag),
	)

/datum/preference_middleware/antags/get_ui_assets()
	return list(get_asset_datum(/datum/asset/spritesheet_batched/antagonists))

/datum/preference_middleware/antags/get_constant_data()
	var/list/antagonists = list()
	for(var/role in GLOB.special_roles)
		antagonists += list(list(
			"key" = role,
			"name" = GLOB.antag_preference_names[role] || capitalize(role),
			"icon" = GLOB.antag_preference_icons[role] ? sanitize_css_class_name(role) : null,
		))
	return list("antagonists" = antagonists)

/datum/preference_middleware/antags/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	var/list/locked = list()
	for(var/role in GLOB.special_roles)
		var/reason = get_lock_reason(user, role)
		if(reason)
			locked[role] = reason

	return list(
		"selected_antags" = preferences.be_special,
		"locked_antags" = locked,
		"skip_antag" = preferences.skip_antag,
	)

/datum/preference_middleware/antags/proc/get_lock_reason(mob/user, role)
	if(jobban_isbanned(user, ROLE_SYNDICATE) || jobban_isbanned(user, role))
		return "Заблокировано"
	if(player_old_enough_antag(user.client, role))
		return
	var/days = available_in_days_antag(user.client, role)
	if(days)
		return "Через [days] [declension_ru(days, "день", "дня", "дней")]"
	var/playtime = role_available_in_playtime(user.client, role)
	if(playtime)
		return "Через [get_exp_format(playtime)]"
	return "Недоступно"

/datum/preference_middleware/antags/proc/toggle_antag(list/params, mob/user)
	var/role = params["role"]
	if(!(role in GLOB.special_roles) || get_lock_reason(user, role))
		return FALSE
	preferences.be_special ^= role
	return TRUE

/datum/preference_middleware/antags/proc/set_antags(list/params, mob/user)
	var/enabled = !!params["enabled"]
	for(var/role in GLOB.special_roles)
		if(get_lock_reason(user, role))
			continue
		if(enabled)
			preferences.be_special |= role
		else
			preferences.be_special -= role
	return TRUE

/datum/preference_middleware/antags/proc/toggle_skip_antag(list/params, mob/user)
	preferences.skip_antag = !preferences.skip_antag
	return TRUE

/datum/asset/spritesheet_batched/antagonists
	name = "antagonists"

/datum/asset/spritesheet_batched/antagonists/create_spritesheets()
	for(var/role in GLOB.antag_preference_icons)
		var/icon_key = sanitize_css_class_name(role)
		if(icon_exists(ANTAGONIST_PREVIEW_ICON_FILE, icon_key))
			insert_icon(icon_key, uni_icon(ANTAGONIST_PREVIEW_ICON_FILE, icon_key))
			continue
		var/datum/universal_icon/icon = get_display_icon_for(GLOB.antag_preference_icons[role])
		if(!icon)
			continue
		icon.scale(ANTAGONIST_PREVIEW_ICON_SIZE, ANTAGONIST_PREVIEW_ICON_SIZE)
		insert_icon(icon_key, icon)
