extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func verify(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok:
		failures += 1
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var g: Control = Game.new()
	verify(Game.ENDGAME_TIER_DAMAGE.size() == 6, "six tier scaling targets")
	for kind in [0, 3, 6, 36, 42, 46]:
		verify(is_equal_approx(g._tier_damage_scale(kind, 1), 1.0), "wave 1 original damage %d" % kind)
		verify(g._tier_damage_scale(kind, 80) > 1.0, "wave 80 boosted damage %d" % kind)
		verify(g._tier_damage_scale(kind, 40) > 1.0 and g._tier_damage_scale(kind, 40) < g._tier_damage_scale(kind, 80), "progressive damage %d" % kind)
	verify(g._tier_damage_scale(-1, 80) == 1.0, "invalid kind safe")
	verify(g._tier_damage_scale(46, 999) == g._tier_damage_scale(46, 80), "wave cap safe")
	verify(is_equal_approx(g._tier_damage_scale(46, 80), 11.0), "transcendent endgame damage 11x")
	var hp_before: float = 0.0
	for name in ["쉬움", "보통", "어려움", "지옥"]:
		g.difficulty = name
		var boss: Dictionary = g._boss_stats(8)
		var ordinary: Dictionary = g._regular_wave_stats(80)
		verify(is_equal_approx(float(boss["hp"]), float(ordinary["hp"]) * float(Game.BOSS_HP_BY_DIFFICULTY[name])), "boss HP profile " + name)
		verify(float(boss["hp"]) > hp_before, "boss toughness increases " + name)
		hp_before = float(boss["hp"])
	verify(Game.DRAW_ITEM_TICKETS == 3000 and Game.MYTHIC_DRAW_ITEM_TICKETS == 1000 and Game.TRANSCENDENT_DRAW_ITEM_TICKETS == 100, "original gacha probabilities unchanged")
	verify(Game.MATCHUP_BONUS == 1.20 and Game.MATCHUP_PENALTY == 0.90, "original matchups unchanged")
	verify(g._estimated_single_target_dps([42,43,44], 80) > g._estimated_single_target_dps([42,43,44], 1), "mythic DPS progression estimate")
	g.free()
	print("BALANCE TEST RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
