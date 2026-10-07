#define TITLE_SCREENS_LOCATION "config/title_screens/images/"

SUBSYSTEM_DEF(title)
	name = "Title Screen"
	ss_flags = SS_NO_FIRE
	init_stage = INITSTAGE_EARLY

	/// The list of image files available to be picked for title screen
	var/list/title_images_pool = list()
	var/icon/icon
	var/notice
	var/random_phrase = "О нет, моя фраза!"
	var/turf/simulated/wall/indestructible/splashscreen/splash_turf

/datum/controller/subsystem/title/Initialize()
	fill_title_images_pool()

	var/list/phrases = world.file2list("strings/lobby_phrases.txt")
	if(LAZYLEN(phrases))
		random_phrase = pick(phrases)

	splash_turf ||= locate(/turf/simulated/wall/indestructible/splashscreen)
	set_title_image()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/title/Recover()
	title_images_pool = SStitle.title_images_pool
	icon = SStitle.icon
	notice = SStitle.notice
	random_phrase = SStitle.random_phrase
	splash_turf = SStitle.splash_turf

/**
 * Iterates over all files in `TITLE_SCREENS_LOCATION` and loads all valid title screens to `title_screens` var.
 */
/datum/controller/subsystem/title/proc/fill_title_images_pool()
	for(var/file_name in flist(TITLE_SCREENS_LOCATION))
		if(validate_filename(file_name))
			var/file_path = "[TITLE_SCREENS_LOCATION][file_name]"
			title_images_pool += fcopy_rsc(file_path)

/**
 * Checks wheter passed title is valid
 * Currently validates extension and checks whether it's special image like default title screen etc.
 */
/datum/controller/subsystem/title/proc/validate_filename(filename)
	var/static/list/title_screens_to_ignore = list("blank.png")
	if(filename in title_screens_to_ignore)
		return FALSE

	var/static/list/supported_extensions = list("gif", "jpg", "jpeg", "png")
	var/extstart = findlasttext(filename, ".")
	if(!extstart)
		return FALSE

	var/extension = copytext(filename, extstart + 1)
	return (extension in supported_extensions)

/datum/controller/subsystem/title/proc/set_notice(new_notice)
	notice = new_notice ? sanitize_text(new_notice) : null
	SEND_SIGNAL(src, COMSIG_TITLE_NOTICE_CHANGED)

/datum/controller/subsystem/title/proc/set_title_image(desired_image_file)
	if(desired_image_file && !isfile(desired_image_file))
		CRASH("Not a file passed to `/datum/controller/subsystem/title/proc/set_title_image`")

	desired_image_file ||= pick_title_image()
	if(!desired_image_file)
		return

	icon = new(desired_image_file)
	splash_turf?.update_title_icon()

/datum/controller/subsystem/title/proc/pick_title_image()
	if(!length(title_images_pool))
		return
	return pick(title_images_pool)

#undef TITLE_SCREENS_LOCATION
