extends Node
const SKILL_SOUNDS := ["crit","bleed","stun","slow","multi","armor","splash","heavy","area_stun","hp_percent","magic_splash","magic_res","freeze","chain","burn","vulnerable","poison","attack_aura","speed_aura","magic_aura","cooldown_aura"]
static func skill_sound(skill: String, kind: int=-1) -> String:
	if kind>=0:
		if skill=="chain" or kind==44 and skill=="stun": return "element_thunder"
		if skill=="burn" or kind==47 and skill=="magic_splash" or kind==48 and skill=="area_stun": return "element_explosion"
		if skill=="freeze" or kind==42 and skill=="magic_splash": return "element_ice"
		if kind==46 and skill in ["heavy","poison","hp_percent"]: return "element_abyss"
	return "skill_"+skill
const SETTINGS_PATH: String = "user://audio_settings.cfg"
var levels: Dictionary = {"master":0.8,"music":0.35,"sfx":0.7}
var music: AudioStreamPlayer
var music_tracks: Dictionary = {}
var boss_mode: bool = false
var backgrounded: bool = false
var normal_music_position: float = 0.0
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var last_played: Dictionary = {}
var persist_settings: bool = true
var _status_clock: float = 0.0
var music_switches: int = 0
var _last_music_position: float = 0.0
func _ready() -> void:
	for bus_name in ["Music","SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
	if persist_settings: load_settings()
	for channel in levels: apply_level(channel)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	for track in ["sky_theme","boss_theme"]:
		var path: String = "res://audio/" + track + ".wav"
		if ResourceLoader.exists(path):
			var stream: AudioStreamWAV = load(path)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length()*stream.mix_rate)
			music_tracks[track] = stream
	music.stream = music_tracks.get("sky_theme")
	add_child(music)
	if music.stream != null and DisplayServer.get_name() != "headless": music.play()
	for i in range(12):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)
	var names: Array[String] = ["ui","summon","attack","magic","craft","coin","wave","boss","victory","defeat"]
	for style in ["roar","claw","fang","shadow","wind","spirit","ice","sun","lightning","nature","abyss","heaven","hell"]:
		names.append("attack_"+style)
	for skill in SKILL_SOUNDS: names.append(skill_sound(skill))
	names.append_array(["element_thunder","element_explosion","element_ice","element_abyss"])
	for name in names:
		var path: String = "res://audio/" + name + ".wav"
		if ResourceLoader.exists(path): sounds[name] = load(path)
func apply_level(channel: String) -> void:
	var bus_name: String = {"master":"Master","music":"Music","sfx":"SFX"}[channel]
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0: return
	var value: float = float(levels[channel])
	AudioServer.set_bus_mute(index,value <= 0.0)
	AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001)))
func set_level(channel: String, value: float) -> void:
	if not levels.has(channel): return
	levels[channel] = clampf(value,0.0,1.0)
	apply_level(channel)
func save_settings() -> void:
	if not persist_settings: return
	var config := ConfigFile.new()
	for channel in levels: config.set_value("audio",channel,levels[channel])
	config.save(SETTINGS_PATH)
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK: return
	for channel in levels:
		var value: Variant = config.get_value("audio",channel,levels[channel])
		if value is float or value is int: levels[channel] = clampf(float(value),0.0,1.0)
func play_effect(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if not sounds.has(name) or voices.is_empty(): return
	if float(levels["master"]) <= 0.0 or float(levels["sfx"]) <= 0.0: return
	var now: int = Time.get_ticks_msec()
	var interval: int = 480 if name.begins_with("element_") else 180 if name.begins_with("attack_") else 120 if name.begins_with("skill_") else 130 if name in ["attack","magic"] else 80
	if now-int(last_played.get(name,-10000)) < interval: return
	last_played[name] = now
	var voice: AudioStreamPlayer = null
	var pool: Array[AudioStreamPlayer] = []
	for i in range(voices.size()):
		if (i>=8)==name.begins_with("element_"): pool.append(voices[i])
	for candidate in pool:
		if not candidate.playing:
			voice = candidate
			break
	var priority: int = 4 if name.begins_with("element_") else 3 if name in ["boss","victory","defeat"] else 2 if name.begins_with("skill_") else 1 if name.begins_with("attack_") else 0
	if voice == null:
		for candidate in pool:
			if int(candidate.get_meta("priority",0)) > priority: continue
			if voice == null or int(candidate.get_meta("started",0)) < int(voice.get_meta("started",0)):
				voice = candidate
		if voice == null: return
	voice.set_meta("priority",priority)
	voice.set_meta("started",now)
	voice.stream = sounds[name]
	voice.volume_db = -1.5 if name.begins_with("element_") else -9.0 if name in ["attack","magic"] else -6.0 if name.begins_with("attack_") else -3.0 if name.begins_with("skill_") else -5.0
	voice.play()
func set_backgrounded(value: bool) -> void:
	backgrounded = value
	if music != null: music.stream_paused = value
	if value:
		for voice in voices: voice.stop()
	else:
		set_boss_mode(boss_mode)
	_write_runtime_status()

func _exit_tree() -> void:
	if music != null:
		music.stop()
		music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	sounds.clear()
	music_tracks.clear()

func set_boss_mode(enabled: bool) -> void:
	if music==null: return
	var desired: AudioStream = music_tracks.get("boss_theme" if enabled else "sky_theme")
	if desired==null:
		push_error("Missing required battle music")
		return
	var changed: bool = boss_mode!=enabled or music.stream!=desired
	if not changed and (music.playing or backgrounded or DisplayServer.get_name()=="headless"): return
	if changed and enabled: normal_music_position=music.get_playback_position()
	var resume_at: float = 0.0 if enabled else normal_music_position
	if not changed: resume_at=_last_music_position
	boss_mode=enabled
	music.stop()
	music.stream=desired
	music.volume_db=1.5 if enabled else 0.0
	_last_music_position=resume_at
	music_switches+=1
	if DisplayServer.get_name()!="headless":
		music.play(fposmod(resume_at,maxf(1.0,music.stream.get_length())))
		music.stream_paused=backgrounded
	_write_runtime_status()
func track_label() -> String:
	var title: String = "천공 성채의 결전" if boss_mode else "천공의 산책"
	return title + (" · 음소거" if float(levels["music"])<=0.0 or float(levels["master"])<=0.0 else "")
func _process(delta: float) -> void:
	if music!=null and music.playing and not backgrounded: _last_music_position=music.get_playback_position()
	_status_clock+=delta
	if _status_clock>=1.0:
		_status_clock=0.0
		_write_runtime_status()
func _write_runtime_status() -> void:
	if not OS.is_debug_build() or not persist_settings or DisplayServer.get_name()=="headless" or music==null: return
	var status: Dictionary = {"boss_mode":boss_mode,"track":music.stream.resource_path if music.stream!=null else "","playing":music.playing,"paused":music.stream_paused,"position":music.get_playback_position(),"volume":levels,"backgrounded":backgrounded,"switches":music_switches}
	var file := FileAccess.open("user://audio_runtime.json",FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify(status))
		file.close()
