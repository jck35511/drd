extends SceneTree
const Game = preload("res://main.gd")
const Animator = preload("res://scripts/attack_animator.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var g: Control = Game.new()
	g.persistence_enabled = false
	root.add_child(g)
	g.set_process(false)
	var aim := Vector2.RIGHT
	for kind in range(49):
		var idle: Dictionary = Animator.sample(kind,aim,0.0)
		var prep: Dictionary = Animator.sample(kind,aim,0.22)
		var hit: Dictionary = Animator.sample(kind,aim,0.38)
		var end: Dictionary = Animator.sample(kind,aim,1.0)
		assert(Vector2(prep["offset"]).distance_to(hit["offset"])>8.0)
		assert(Vector2(end["offset"]).length()<0.01 and absf(float(end["rotation"]))<0.01)
		for speed in [1,2,3]:
			assert(Animator.duration_for(g.COOLDOWN[kind],speed)<float(g.COOLDOWN[kind])/speed)
	for skill in g.SKILL_NAMES:
		assert(g.GameAudio.SKILL_SOUNDS.has(skill),"Missing semantic sound: "+skill)
		var sound_name: String = g.GameAudio.skill_sound(skill)
		assert(g.game_audio.sounds.has(sound_name))
		assert(g.game_audio.sounds[sound_name].get_length()>0.3)
	g.dogs.append({"kind":11,"cell":0,"cooldown":0.0})
	g.enemies.append({"progress":0.0,"hp":1000000.0,"max_hp":1000000.0,"armor":3.0,"effects":{},"enemy_type":"소형견"})
	g._emit_attack_visual(0,0)
	assert(g.attack_durations.has(0))
	g._emit_skill_visual(0,0,"crit")
	var fx: Dictionary = g.combat_fx.back()
	assert(fx["skill"]=="crit" and fx["sound"]=="skill_crit","Ordinary dog skills also need matched feedback")
	for i in range(100): g._emit_skill_visual(0,0,"bleed")
	var count: int = 0
	for effect in g.combat_fx:
		if not str(effect.get("skill","")).is_empty(): count+=1
	assert(count<=24 and g.combat_fx.size()<=96)
	g.queue_free()
	await process_frame
	quit()
