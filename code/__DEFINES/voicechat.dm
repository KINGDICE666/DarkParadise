#define VOICECHAT_UPDATE_INTERVAL 3
#define VOICECHAT_USER_CODE_LENGTH 4
#define VOICECHAT_SPEAKING_ICON_ALPHA 200

// How long (in deciseconds) a speaking overlay survives without a fresh
// voice_activity:true before fire() auto-clears it. The browser re-sends
// active:true every ~500ms while speaking, so this must comfortably exceed one
// heartbeat to tolerate a couple of dropped Node->BYOND topics. If a "stopped
// speaking" (active:false) packet is lost, the overlay still vanishes within
// this window once the heartbeats stop arriving.
#define VOICECHAT_SPEAKING_TIMEOUT 15

#define VOICECHAT_ROOM_LIVING "living"
#define VOICECHAT_ROOM_GHOST "ghost"

#define VOICECHAT_CMD_REGISTER "register"
#define VOICECHAT_CMD_STOP_NODE "stop_node"
#define VOICECHAT_CMD_LOCATION "loc"
#define VOICECHAT_CMD_DISCONNECT "disconnect"
#define VOICECHAT_CMD_MUTE_MIC "mute_mic"
#define VOICECHAT_CMD_DEAFEN "deafen"

#define VOICECHAT_TOPIC_NODE_STARTED "node_started"
#define VOICECHAT_TOPIC_PONG "pong"
#define VOICECHAT_TOPIC_CONFIRMED "confirmed"
#define VOICECHAT_TOPIC_VOICE_ACTIVITY "voice_activity"
#define VOICECHAT_TOPIC_DISCONNECT "disconnect"
#define VOICECHAT_TOPIC_SHUTTING_DOWN "shutting_down"
