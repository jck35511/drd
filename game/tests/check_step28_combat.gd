extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func verify(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition: failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var g: Control = Game.new()
	g.persistence_enabled = false
	g.visual_effects_enabled = false
	verify(g.COLS == 6 and g.ROWS == 6, "exact 6x6 board")
	verify(g.DRAW_ITEM_TICKETS == 3000 and g.MYTHIC_DRAW_ITEM_TICKETS == 1000 and g.TRANSCENDENT_DRAW_ITEM_TICKETS == 100, "all requested draw odds preserved")
	verify(g.DIFFICULTY_STATS["지옥"]["hp"] == 2.2 and g.BOSS_HP_BY_DIFFICULTY["지옥"] == 20.0, "hell difficulty values preserved")
	for effect in ["bleed", "poison", "burn"]:
		g.enemies.clear()
		g.enemies.append({"hp":1000.0,"max_hp":1000.0,"armor":100.0,"magic_res":0.25,"effects":{}})
		g._apply_status(0,effect,2.0,100.0)
		g._tick_enemy_effects(1.0)
		var expected: float = 925.0 if effect == "burn" else 950.0
		verify(is_equal_approx(float(g.enemies[0]["hp"]),expected), effect + " respects matching resistance")
	g.enemies.clear()
	g.enemies.append({"hp":1000.0,"max_hp":1000.0,"armor":100.0,"magic_res":0.0,"effects":{}})
	g._apply_status(0,"armor",3.0,0.5)
	g._hit_enemy(0,150.0)
	verify(is_equal_approx(float(g.enemies[0]["hp"]),900.0),"50 percent armor reduction gives 100 damage, no second bonus")
	g.enemies.clear()
	g.enemies.append({"hp":1000.0,"max_hp":1000.0,"is_boss":true,"effects":{}})
	g._apply_status(0,"stun",1.0)
	verify(is_equal_approx(float(g.enemies[0]["effects"]["stun"]["time"]),0.5),"boss control duration reduced")
	for recipe in g.RECIPES:
		var kind: int = int(recipe["result"])
		if kind >= 36: continue
		var material_dps: float = 0.0
		for material in recipe["materials"]: material_dps += float(g.ATTACK[material]) / float(g.COOLDOWN[material])
		verify(float(g.ATTACK[kind]) / float(g.COOLDOWN[kind]) + 0.001 >= material_dps, "ordinary fusion base DPS preserved: " + g.DOGS[kind])
	g.dogs.clear()
	g.gold=1000
	g.rng.seed=444
	for i in range(10):
		g._summon()
		var dog: Dictionary = g.dogs.back()
		verify(g._cell_reaches_path(int(dog["cell"]),float(g.RANGE[dog["kind"]])),"summon chooses reachable empty cell")
	g.free()
	# Compare attacks, enemy HP, progress, and timers under frame rate and speed changes.
	var states: Array[Dictionary] = []
	for profile in [{"fps":60,"speed":1},{"fps":15,"speed":1},{"fps":60,"speed":3},{"fps":15,"speed":3}]:
		var t: Control = Game.new()
		t.persistence_enabled=false
		t.visual_effects_enabled=false
		t.difficulty_confirmed=true
		t.wave=40
		t.wave_running=true
		t.wave_time_left=40.0
		t.spawn_left=0
		t.game_speed=int(profile["speed"])
		t.rng.seed=98765
		t.dogs.append({"kind":44,"cell":0,"cooldown":0.0})
		t.enemies.append({"hp":100000.0,"max_hp":100000.0,"armor":30.0,"magic_res":0.25,"progress":0.0,"move_speed":0.01,"effects":{}})
		var frames: int = int(6.0 * float(profile["fps"]) / float(profile["speed"]))
		for i in range(frames): t._process(1.0 / float(profile["fps"]))
		states.append({"hp":t.enemies[0]["hp"],"progress":t.enemies[0]["progress"],"time":t.wave_time_left})
		t.free()
	for i in range(1,states.size()):
		for key in states[0]:
			verify(absf(float(states[i][key])-float(states[0][key])) < 0.0001,"same game time across FPS/speed: " + str(i) + " " + str(key))
	print("STEP28 COMBAT RESULT: %d failures" % failures)
	quit(1 if failures else 0)
