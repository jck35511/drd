extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func verify(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var g = Game.new()
	root.add_child(g)
	verify(g.WAVE_COMPLETION_REWARDS == [10,15,20,25,30,35,40,50], "wave reward brackets")
	verify(g.BOSS_REWARDS == [150,250,400,600,900,1200,1600,2000], "boss reward amounts")
	var total_wave := 0
	for w in range(1,81): total_wave += g._wave_completion_reward(w)
	verify(total_wave == 2250, "80 regular clear rewards total 2250G")
	verify(g._wave_completion_reward(0) == 0 and g._wave_completion_reward(81) == 0, "out of range wave safe")
	var total_boss := 0
	for n in range(1,9): total_boss += g._boss_kill_reward(n)
	verify(total_boss == 7100, "eight boss kill rewards total 7100G")
	verify(g._boss_kill_reward(0) == 0 and g._boss_kill_reward(9) == 0, "out of range boss safe")
	g.gold = 100
	verify(g._on_successful_fusion(3) == 0 and g.gold == 100, "medium dog no mission")
	verify(g._on_successful_fusion(6) == 0 and g.gold == 100, "large dog no mission")
	verify(g._on_successful_fusion(36) == 400 and g.gold == 500, "first beast grants 400")
	verify(g._on_successful_fusion(37) == 0 and g.gold == 500, "other beast does not repeat")
	verify(g._on_successful_fusion(42) == 1000 and g.gold == 1500, "first mythic grants 1000")
	verify(g._on_successful_fusion(45) == 0 and g.gold == 1500, "other mythic does not repeat")
	for kind in [46,47,48]:
		verify(g._on_successful_fusion(kind) == 2000, "first transcendent kind %d grants 2000" % kind)
	verify(g.gold == 7500, "five unique missions grant 7400G total")
	verify(g._on_successful_fusion(46) == 0 and g.gold == 7500, "repeat transcendent does not repeat")
	verify(g.mission_details != null and g.mission_button != null, "mission UI created")
	g._restart()
	verify(g.gold == 100 and not g.first_beast_claimed and not g.first_mythic_claimed and g.first_transcendent_claimed.is_empty(), "restart resets achievements and gold")
	verify(g._on_successful_fusion(36) == 400, "new run can earn again")
	print("ECONOMY TEST RESULT: %d failures" % failures)
	g.queue_free()
	quit(1 if failures > 0 else 0)
