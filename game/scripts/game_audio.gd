extends Node
const SETTINGS_PATH: String = "user://audio_settings.cfg"
var levels: Dictionary = {"master":0.8,"music":0.35,"sfx":0.7}
var music: AudioStreamPlayer
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
	if ResourceLoader.exists("res://audio/sky_theme.wav"):
		music.stream = load("res://audio/sky_theme.wav")
		if music.stream is AudioStreamWAV:
			music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			music.stream.loop_begin = 0
			music.stream.loop_end = int(music.stream.get_length()*music.stream.mix_rate)
	add_child(music)
	if music.stream != null: music.play()
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)
	for name in ["ui","summon","attack","magic","craft","coin","wave","boss","victory","defeat"]:
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
	if not sounds.has(name) or voices.is_empty(): return
	if float(levels["master"]) <= 0.0 or float(levels["sfx"]) <= 0.0: return
	var now: int = Time.get_ticks_msec()
	var interval: int = 130 if name in ["attack","magic"] else 80
	if now-int(last_played.get(name,-10000)) < interval: return
	last_played[name] = now
	var voice: AudioStreamPlayer = null
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		if name in ["attack","magic","coin"]: return
		voice = voices[0]
	voice.stream = sounds[name]
	voice.volume_db = -12.0 if name in ["attack","magic"] else -5.0
	voice.play()
func set_backgrounded(value: bool) -> void:
	if music != null: music.stream_paused = value
	if value:
		for voice in voices: voice.stop()
