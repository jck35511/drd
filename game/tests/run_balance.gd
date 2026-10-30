extends SceneTree
const Game = preload("res://main.gd")
var recipes: Dictionary = {}
var results: Array[Dictionary] = []
var difficulty_name: String = "보통"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--difficulty="): difficulty_name = arg.trim_prefix("--difficulty=")
	for recipe in Game.RECIPES: recipes[int(recipe["result"])] = recipe
	for policy in ["summon_first", "gamble_first"]:
		for seed_value in [1, 5, 12, 32, 55, 83, 101, 202]:
			var outcome: Dictionary = play(seed_value,policy)
			results.append(outcome)
			print("BALANCE_RESULT:" + JSON.stringify(outcome))
	var stress: Dictionary = controlled()
	print("CONTROLLED_RESULT:" + JSON.stringify(stress))
	results.append(stress)
	DirAccess.make_dir_recursive_absolute("res://reports")
	var report := FileAccess.open("res://reports/balance-" + difficulty_name + ".json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"difficulty":difficulty_name,"method":"Legal-action heuristic; sample is not a human win-rate estimate","results":results}, "\t"))
	report.close()
	quit(0)
func counts(g: Control) -> Dictionary:
	var out: Dictionary = {}
	for dog in g.dogs:
		var kind: int = int(dog["kind"])
		out[kind] = int(out.get(kind,0)) + 1
	return out
func has_materials(g: Control, recipe: Dictionary) -> bool:
	return g._find_recipe_materials(recipe,false).size() == 3
# Allocate existing materials once, recursively preferring a complete mythic.
func demand(kind: int, stock: Dictionary, wanted: Dictionary, order: Array[int]) -> void:
	if int(stock.get(kind,0)) > 0:
		stock[kind] = int(stock[kind]) - 1
		return
	wanted[kind] = int(wanted.get(kind,0)) + 1
	if recipes.has(kind):
		for material in recipes[kind]["materials"]: demand(int(material),stock,wanted,order)
		order.append(kind)
func manage(g: Control, stats: Dictionary) -> void:
	var stock: Dictionary = counts(g)
	var goal: int = 45
	if g.first_mythic_claimed:
		goal = 47 if not g.first_transcendent_claimed.has(47) else (46 if not g.first_transcendent_claimed.has(46) else 48)
	var wanted: Dictionary = {}
	var order: Array[int] = []
	demand(goal,stock,wanted,order)
	var changed: bool = false
	for result in order:
		var recipe: Dictionary = recipes[result]
		if not has_materials(g,recipe): continue
		if result < 36 and g.dogs.size() < 12: continue
		if g._recipe_item_ready(recipe):
			g._craft_recipe_from_catalog(result)
			stats["crafts"] += 1
			changed = true
			break
		if g.gold >= 50:
			if result >= 46: g._draw_transcendent_gacha()
			elif result >= 42: g._draw_mythic_gacha()
			else: g._draw_gacha()
			stats["draws"] += 1
		return # Hold income for the missing item before spending on more summons.
	if g.gold >= 20 and g.dogs.size() < 35:
		g._summon()
		stats["summons"] += 1
		changed = true
	elif g.dogs.size() >= 35:
		var lowest: int = -1
		var value: float = INF
		for i in range(g.dogs.size()):
			var kind: int = int(g.dogs[i]["kind"])
			if int(stock.get(kind,0)) <= 0 or g._sell_value(kind) <= 0: continue
			var score: float = -float(stock.get(kind,0)) * 1000.0 + float(g.ATTACK[kind]) / float(g.COOLDOWN[kind])
			if score < value:
				lowest = i
				value = score
		if lowest >= 0:
			g.selected = lowest
			g._sell_selected()
			stats["sales"] += 1
			changed = true
	if changed: place(g)
func place(g: Control) -> void:
	# Move into free cells, just as touch input does; no overlaps or stat edits.
	var used: Dictionary = {}
	for dog in g.dogs: used[int(dog["cell"])] = true
	for dog in g.dogs:
		var current: int = int(dog["cell"])
		used.erase(current)
		var best: int = current
		var best_score: float = -INF
		for cell in range(36):
			if used.has(cell): continue
			var score: float = 0.0
			var center: Vector2 = g._cell_center(cell)
			var attack_range: float = float(g.RANGE[int(dog["kind"])])
			if g.boss_running and not g.enemies.is_empty():
				for dt in [0.0, 0.5, 1.0, 1.5]:
					var p: Vector2 = g._route_point(fposmod(float(g.enemies[0]["progress"]) + dt * 0.05,4.0))
					if center.distance_to(p) <= attack_range: score += 100.0
			else:
				for segment in range(32):
					if center.distance_to(g._route_point(float(segment)/8.0)) <= attack_range: score += 1.0
			if cell == current: score += 0.001
			if score > best_score:
				best_score = score
				best = cell
		dog["cell"] = best
		used[best] = true
func play(seed_value: int, policy: String) -> Dictionary:
	var g: Control = Game.new()
	g.persistence_enabled = false
	g.visual_effects_enabled = false
	g._in_simulation = true
	g.difficulty_confirmed = true
	g.difficulty = difficulty_name
	g.rng.seed = seed_value
	var stats: Dictionary = {"policy":policy,"seed":seed_value,"difficulty":difficulty_name,"draws":0,"summons":0,"crafts":0,"sales":0,"bosses":[]}
	# User's original pre-wave gambling is legal; stop at 500G or below 50G.
	for attempt in range(500):
		if policy == "summon_first" or g.gold >= 500 or g.gold < 50: break
		g._draw_transcendent_gacha()
		stats["draws"] += 1
	for action in range(35): manage(g,stats)
	g._start_wave()
	var ticks: int = 0
	var peak: int = 0
	var previous_boss: int = 0
	var started: int = Time.get_ticks_msec()
	while not g.game_over and not g.victory and ticks < 230000:
		if ticks % 30 == 0: manage(g,stats)
		if g.boss_running and ticks % 120 == 0: place(g)
		g._simulation_step(1.0/60.0)
		peak = maxi(peak,g.enemies.size())
		if g.boss_round > previous_boss:
			previous_boss = g.boss_round
			stats["bosses"].append({"boss":previous_boss,"gold":g.gold,"units":counts(g)})
		ticks += 1
	stats.merge({"victory":g.victory,"wave":g.wave,"boss":g.boss_round,"gold":g.gold,"peak_enemies":peak,"units":counts(g),"items":g.beast_items.duplicate(),"game_seconds":float(ticks)/60.0,"wall_seconds":float(Time.get_ticks_msec()-started)/1000.0,"ended":g.game_over or g.victory,"reason":"victory" if g.victory else ("boss_timeout" if peak < g._field_limit() else "field_limit")})
	g.free()
	return stats

func controlled() -> Dictionary:
	# Deliberately injected late-game roster: engine endurance, NOT obtainable-economy proof.
	var g: Control = Game.new()
	g.persistence_enabled = false
	g.visual_effects_enabled = false
	g._in_simulation = true
	g.difficulty_confirmed = true
	g.difficulty = difficulty_name
	g.rng.seed = 999
	for cell in range(36):
		if cell in [14,15,20,21]: continue
		g.dogs.append({"kind":46 + cell % 3,"cell":cell,"cooldown":0.0})
	g._start_wave()
	var ticks: int = 0
	var peak: int = 0
	while not g.game_over and not g.victory and ticks < 230000:
		g._simulation_step(1.0/60.0)
		peak = maxi(peak,g.enemies.size())
		ticks += 1
	var out: Dictionary = {"policy":"injected_roster_engine_endurance_not_economy","difficulty":difficulty_name,"victory":g.victory,"wave":g.wave,"boss":g.boss_round,"game_seconds":float(ticks)/60.0,"peak_enemies":peak}
	g.free()
	return out
