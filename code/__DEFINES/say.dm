// Don't set this very much higher then 1024 unless you like inviting people in to dos your server with message spam
#define MAX_MESSAGE_LEN 1024
#define MAX_PAPER_MESSAGE_LEN 4096
#define MAX_PAPER_FIELDS 50
#define MAX_BOOK_MESSAGE_LEN 9216
#define MAX_NAME_LEN 50 // diona names can get loooooooong

#define GOOD_HEARING_WHISPER_RANGE 3

// A link given to ghost alice to follow bob
#define FOLLOW_LINK(alice, bob) "<a href=byond://?src=[alice.UID()];follow=[bob.UID()]>(F)</a>"
#define FOLLOW_LINK_WITH_DISPLAY(alice, bob, display) "<a href=byond://?src=[alice.UID()];follow=[bob.UID()]>[display]</a>"
#define TURF_LINK(alice, turfy) "<a href=byond://?src=[alice.UID()];x=[turfy.x];y=[turfy.y];z=[turfy.z]>(T)</a>"
#define FOLLOW_OR_TURF_LINK(alice, bob, turfy) "<a href=byond://?src=[alice.UID()];follow=[bob.UID()];x=[turfy.x];y=[turfy.y];z=[turfy.z]>(F)</a>"

//These are the names of the commands, what you'd need to type to do the command (also used in winset)
#define VERB_SAY "Сказать"
#define VERB_WHISPER "Шепот"
#define VERB_ME "Эмоция"
//Gave this shit a shorter name so you only have to time out "ooc" rather than "ooc message" to use it --NeoFite
#define VERB_OOC "OOC"
#define VERB_LOOC "LOOC"
#define VERB_PRAY "Молиться"

#define RADIO_EXTENSION "department specific"
#define RADIO_KEY "department specific key"
#define RADIO_TRANSMITTED_FREQS "radio transmitted frequencies"
#define LANGUAGE_EXTENSION "language specific"
#define LANGUAGE_MUTUAL_BONUS "language mutual bonus"
#define SAY_MOD_VERB "say_mod_verb"
#define MODE_IGNORE_SPEECH_PROBLEMS "ignore speech problems"
#define MODE_IGNORE_ATMOSPHERICS "ignore atmospherics"
#define MODE_NO_TTS "no tts"
#define MODE_RADIO_GARBLED "radio garbled"

#define HEAR_HEARD (1<<0)
#define HEAR_UNDERSTOOD (1<<1)

#define MODE_HEADSET "headset"
#define WHISPER_MODE "the type of whisper"
#define MODE_WHISPER "whisper"
#define MODE_SPEAKER_NAME_OVERRIDE "speaker_name_override"

#define SPAN_ROBOT "robot"
#define SPAN_YELL "yell"
#define SPAN_ITALICS "italics"
#define SPAN_SANS "sans"
#define SPAN_COLOSSUS "colossus"
#define SPAN_SMALL_VOICE "small"

#define ITALICS (1<<0)
#define REDUCE_RANGE (1<<1)
#define NOPASS (1<<2)

#define MESSAGE_RANGE 7
#define WHISPER_RANGE 1
#define EAVESDROP_RANGE 1
#define MODE_RANGE_INTERCOM 1

#define MODE_BINARY "binary"
#define MODE_KEY_BINARY "b"
#define MODE_KEY_DRONE "d"
#define MODE_ALIEN "alientalk"
#define MODE_CHANGELING "changeling"

#define SAYMODE_MESSAGE_HANDLED (1<<0)
