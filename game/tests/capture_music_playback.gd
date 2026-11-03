extends SceneTree
const Audio=preload("res://scripts/game_audio.gd")
var player: Node
var recorder: AudioEffectRecord
func _initialize() -> void:
	call_deferred("run")
func record(path: String) -> void:
	recorder.set_recording_active(true)
	await create_timer(1.6).timeout
	recorder.set_recording_active(false)
	var wav: AudioStreamWAV=recorder.get_recording()
	assert(wav!=null and wav.data.size()>10000,"Runtime audio mixer produced no samples")
	assert(wav.save_to_wav(path)==OK)
func record_element(name: String) -> void:
	# Saturate ordinary voices while an elemental tail is still playing.
	for voice in player.voices: voice.stop()
	recorder.set_recording_active(true)
	player.play_effect("element_"+name)
	var protected_voice: AudioStreamPlayer=player.voices[8]
	assert(protected_voice.playing and protected_voice.stream==player.sounds["element_"+name])
	var ordinary: Array[String]=["attack_roar","attack_claw","attack_fang","attack_shadow","attack_wind","attack_spirit","attack_sun","attack_nature","skill_crit","skill_multi","skill_armor"]
	for sound in ordinary: player.play_effect(sound)
	await create_timer(0.35).timeout
	assert(protected_voice.playing and protected_voice.get_playback_position()>0.25,"Ordinary attacks cut off elemental sound")
	await create_timer(2.1).timeout
	recorder.set_recording_active(false)
	var wav: AudioStreamWAV=recorder.get_recording()
	assert(wav!=null and wav.data.size()>10000)
	assert(wav.save_to_wav("res://previews/mixer-"+name+".wav")==OK)
	print("ELEMENT_MIXER_PASS: "+name)
func run() -> void:
	player=Audio.new()
	player.persist_settings=false
	root.add_child(player)
	player.set_level("master",0.8)
	player.set_level("music",0.5)
	recorder=AudioEffectRecord.new()
	recorder.format=AudioStreamWAV.FORMAT_16_BITS
	var master: int=AudioServer.get_bus_index("Master")
	var effect_index: int=AudioServer.get_bus_effect_count(master)
	AudioServer.add_bus_effect(master,recorder)
	await record("res://previews/mixer-normal.wav")
	assert(player.music.playing and player.music.get_playback_position()>1.0)
	player.set_boss_mode(true)
	await record("res://previews/mixer-boss.wav")
	assert(player.music.playing and player.boss_mode and player.music.get_playback_position()>1.0)
	var pos: float=player.music.get_playback_position()
	var switches: int=player.music_switches
	for i in range(8): player.set_boss_mode(true)
	await create_timer(0.3).timeout
	assert(player.music.get_playback_position()>pos and player.music_switches==switches,"Repeated boss state must not restart music")
	player.music.stop()
	player.set_boss_mode(true)
	assert(player.music.playing,"Interrupted boss music must recover")
	player.set_backgrounded(true)
	assert(player.music.stream_paused)
	player.set_backgrounded(false)
	assert(not player.music.stream_paused and player.music.playing)
	player.set_boss_mode(false)
	assert(player.music.stream==player.music_tracks["sky_theme"])
	player.music.stop()
	await record_element("thunder")
	await record_element("explosion")
	AudioServer.remove_bus_effect(master,effect_index)
	recorder=null
	player.queue_free()
	await process_frame
	print("MUSIC_MIXER_PASS: normal, boss, repair, foreground, restoration")
	quit()
