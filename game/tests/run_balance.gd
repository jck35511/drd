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
	for policy in ["basic", "skilled"]:
		for seed_value in [1,5,12,32,55,83,101,202]:
			var outcome: Dictionary = play(seed_value,policy)
			results.append(outcome)
			print("BALANCE_RESULT:" + JSON.stringify(outcome))
	for profile in ["easy_target","standard","expert"]:
		for seed_value in [1,5,12,32]:
			var stress: Dictionary = controlled(profile,seed_value)
			print("CONTROLLED_RESULT:" + JSON.stringify(stress))
			results.append(stress)
	DirAccess.make_dir_recursive_absolute("res://reports")
	var report := FileAccess.open("res://reports/balance-" + difficulty_name + ".json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"difficulty":difficulty_name,"method":"Legal-action heuristic; sample is not a human win-rate estimate","results":results}, "\t"))
	report.close()
	quit(0)
func counts(g: Control) -> Dictionary:
	var out: Dictionary = g.reserve_units.duplicate()
	for dog in g.dogs:
		var kind: int = int(dog["kind"])
		out[kind] = int(out.get(kind,0))+1
	return out


func has_materials(g: Control, recipe: Dictionary) -> bool:
	var stock: Dictionary = counts(g)
	for kind in recipe["materials"]:
		if int(stock.get(kind,0))<=0: return false
		stock[kind]=int(stock[kind])-1
	return true
func deploy_materials(g: Control, recipe: Dictionary) -> bool:
	var remaining: Array = recipe["materials"].duplicate()
	for dog in g.dogs:
		if remaining.has(int(dog["kind"])): remaining.erase(int(dog["kind"]))
	for kind in remaining:
		var free: int = free_cell(g)
		if free<0 or not g.features.deploy(int(kind),free): return false
	return true
func free_cell(g: Control) -> int:
	var used: Dictionary={}
	for dog in g.dogs: used[int(dog["cell"])]=true
	for cell in range(36):
		if not used.has(cell): return cell
	return -1
func fill_field(g: Control) -> void:
	while g.dogs.size()<32:
		var best: int=-1
		var score: float=-1
		for key in g.reserve_units:
			var kind: int=int(key)
			if int(g.reserve_units[key])<=0: continue
			var value: float=float(g.ATTACK[kind])/float(g.COOLDOWN[kind])
			if value>score:
				score=value
				best=kind
		if best<0: return
		if not g.features.deploy(best,free_cell(g)): return


func demand(kind: int, stock: Dictionary, wanted: Dictionary, order: Array[int]) -> void:
	if int(stock.get(kind,0)) > 0:
		stock[kind] = int(stock[kind]) - 1
		return
	wanted[kind] = int(wanted.get(kind,0)) + 1
	if recipes.has(kind):
		for material in recipes[kind]["materials"]: demand(int(material),stock,wanted,order)
		order.append(kind)
func manage(g: Control, stats: Dictionary) -> void:
	if g.hidden_tickets>0: g.features.choose_hidden(49)
	fill_field(g)
	var stock: Dictionary = counts(g)
	var goal: int = 45
	if g.first_mythic_claimed:
		goal=48
	if g.first_transcendent_claimed.has(48):
		goal=47 if difficulty_name!="쉬움" else 43
		if int(stock.get(goal,0))>0:
			goal=42 if int(stock.get(42,0))==0 else 44 if int(stock.get(44,0))==0 else 45
	var wanted: Dictionary={}
	var order: Array[int]=[]
	demand(goal,stock,wanted,order)
	for result in order:
		var recipe: Dictionary=recipes[result]
		if not has_materials(g,recipe): continue
		if result<36 and g.dogs.size()<12: continue
		if result>=36 and not g._recipe_item_ready(recipe):
			var category: String="초월" if result>=46 else "신화" if result>=42 else "맹수"
			if int(g.pity_tickets.get(category,0))>0:
				g.features.choose_item(category,result)
			else:
				var soon: bool=false
				for milestone in g.BalanceRules.MILESTONES[g.difficulty][category]:
					if int(milestone)>=g.wave and int(milestone)-g.wave<=10: soon=true
				if not soon and g.gold>=int(g.DrawRules.COSTS[category]) and g.dogs.size()>=16:
					g.features.draw(category)
					stats["draws"]+=1
				continue
		if g._recipe_item_ready(recipe) and deploy_materials(g,recipe):
			g._craft_recipe_from_catalog(result)
			stats["crafts"]+=1
			fill_field(g)
			place(g)
			return
	# Use duplicate stock for ordinary field compression; no free materials.
	if g.dogs.size()>=24:
		for recipe in g.RECIPES:
			if int(recipe["result"])>=36: continue
			var extra: Dictionary=stock.duplicate()
			var spare: bool=true
			for material in recipe["materials"]:
				if int(extra.get(material,0))<=0: spare=false
				else: extra[material]=int(extra[material])-1
			if spare and has_materials(g,recipe) and deploy_materials(g,recipe):
				g._craft_recipe_from_catalog(int(recipe["result"]))
				stats["crafts"]+=1
				fill_field(g)
				place(g)
				return
	if g.gold>=20:
		g._summon()
		stats["summons"]+=1
		fill_field(g)
		place(g)


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
			if not g.enemies.is_empty() and (g.boss_running or str(g.get_meta("policy","basic"))=="skilled"):
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
	g.set_meta("policy",policy)
	g.rng.seed = seed_value
	var stats: Dictionary = {"policy":policy,"seed":seed_value,"difficulty":difficulty_name,"draws":0,"summons":0,"crafts":0,"sales":0,"bosses":[]}
	for action in range(35): manage(g,stats)
	g._start_wave()
	var ticks: int = 0
	var peak: int = 0
	var previous_boss: int = 0
	var started: int = Time.get_ticks_msec()
	while not g.game_over and not g.victory and ticks < 230000:
		if ticks % 30 == 0: manage(g,stats)
		if policy=="skilled" and ticks % 120 == 0: place(g)
		g._simulation_step(1.0/60.0)
		peak = maxi(peak,g.enemies.size())
		if g.boss_round > previous_boss:
			previous_boss = g.boss_round
			stats["bosses"].append({"boss":previous_boss,"gold":g.gold,"units":counts(g)})
		ticks += 1
	stats.merge({"victory":g.victory,"wave":g.wave,"boss":g.boss_round,"gold":g.gold,"peak_enemies":peak,"units":counts(g),"items":g.beast_items.duplicate(),"game_seconds":float(ticks)/60.0,"wall_seconds":float(Time.get_ticks_msec()-started)/1000.0,"ended":g.game_over or g.victory,"reason":"victory" if g.victory else ("boss_timeout" if peak < g._field_limit() else "field_limit")})
	g.free()
	return stats

func controlled(profile: String, seed_value: int) -> Dictionary:
	# Controlled final-boss damage budget, not proof of obtaining the roster.
	var g: Control=Game.new()
	g.persistence_enabled=false
	g.visual_effects_enabled=false
	g._in_simulation=true
	g.difficulty_confirmed=true
	g.difficulty=difficulty_name
	g.rng.seed=seed_value
	var roster: Array=[47,42,43,45,38,27,28,29]
	if profile=="standard": roster=[47,48,42,43,44,45,38,41,27,28,29]
	if profile=="expert": roster=[46,47,48,42,43,44,45,38,41,27,28,29]
	for i in range(roster.size()): g.dogs.append({"kind":roster[i],"cell":i,"cooldown":0.0})
	g.wave=80
	g.boss_pending=true
	g._start_boss_round()
	place(g)
	var ticks: int=0
	while not g.game_over and not g.victory and ticks<4000:
		if ticks%120==0: place(g)
		g._simulation_step(1.0/60.0)
		ticks+=1
	var out: Dictionary={"policy":"controlled_final_boss_not_economy","profile":profile,"seed":seed_value,"difficulty":difficulty_name,"victory":g.victory,"seconds":float(ticks)/60.0,"boss_hp_left":float(g.enemies[0]["hp"]) if not g.enemies.is_empty() else 0.0}
	g.free()
	return out

