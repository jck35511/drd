extends SceneTree
const Game=preload("res://main.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var g: Control=Game.new()
	g.persistence_enabled=false
	root.add_child(g)
	g.set_process(false)
	assert(g.sky_art.legendary_frames.size()==28)
	assert(g.sky_art.apparition_frames.size()==9)
	var seen: Dictionary={}
	for frame in g.sky_art.legendary_frames:
		var signature: int=hash(frame.get_image().get_data())
		assert(not seen.has(signature),"Attack frames must be distinct painted poses")
		seen[signature]=true
	assert(g.sky_art.legendary_frame_index(0.2)==1)
	assert(g.sky_art.legendary_frame_index(0.45)==2)
	assert(g.sky_art.legendary_frame_index(0.75)==3)
	assert(g.GameAudio.skill_sound("chain",44)=="element_thunder")
	assert(g.GameAudio.skill_sound("burn",47)=="element_explosion")
	assert(g.GameAudio.skill_sound("freeze",42)=="element_ice")
	assert(g._attack_sound(44)=="element_thunder")
	assert(g._attack_sound(47)=="element_explosion")
	for key in ["element_thunder","element_explosion","element_ice","element_abyss"]:
		assert(g.game_audio.sounds.has(key))
		assert(g.game_audio.sounds[key].get_length()>=1.0)
	assert(g.game_audio.voices.size()==12,"Cinematic sounds need protected playback voices")
	g.game_audio.set_level("music",0.0)
	g.game_audio.set_boss_mode(true)
	assert(g.game_audio.boss_mode and g.game_audio.music.stream==g.game_audio.music_tracks["boss_theme"])
	assert(g.game_audio.levels["music"]==0.0,"Music switching must respect intentional mute")
	g.game_audio.set_boss_mode(false)
	assert(not g.game_audio.boss_mode and g.game_audio.music.stream==g.game_audio.music_tracks["sky_theme"])
	g.queue_free()
	await process_frame
	quit()
