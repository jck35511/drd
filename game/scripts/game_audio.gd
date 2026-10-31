extends Node
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
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)
	var names: Array[String] = ["ui","summon","attack","magic","craft","coin","wave","boss","victory","defeat"]
	for style in ["roar","claw","fang","shadow","wind","spirit","ice","sun","lightning","nature","abyss","heaven","hell"]:
		names.append("attack_"+style)
		names.append("skill_"+style)
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
	var interval: int = 180 if name.begins_with("attack_") else 260 if name.begins_with("skill_") else 130 if name in ["attack","magic"] else 80
	if now-int(last_played.get(name,-10000)) < interval: return
	last_played[name] = now
	var voice: AudioStreamPlayer = null
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	var priority: int = 3 if name in ["boss","victory","defeat"] else 2 if name.begins_with("skill_") else 1 if name.begins_with("attack_") else 0
	if voice == null:
		for candidate in voices:
			if int(candidate.get_meta("priority",0)) > priority: continue
			if voice == null or int(candidate.get_meta("started",0)) < int(voice.get_meta("started",0)):
				voice = candidate
		if voice == null: return
	voice.set_meta("priority",priority)
	voice.set_meta("started",now)
	voice.stream = sounds[name]
	voice.volume_db = -12.0 if name in ["attack","magic"] else -6.0 if name.begins_with("attack_") else -2.0 if name.begins_with("skill_") else -5.0
	voice.play()
func set_backgrounded(value: bool) -> void:
	backgrounded = value
	if music != null: music.stream_paused = value
	if value:
		for voice in voices: voice.stop()

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
	if boss_mode == enabled or music == null: return
	boss_mode = enabled
	if enabled: normal_music_position = music.get_playback_position()
	music.stop()
	music.stream = music_tracks.get("boss_theme" if enabled else "sky_theme")
	if music.stream != null and DisplayServer.get_name() != "headless":
		music.play(0.0 if enabled else normal_music_position)
		music.stream_paused = backgrounded
