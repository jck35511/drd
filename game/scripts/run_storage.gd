extends RefCounted
const PATH: String = "user://sky_castle_save.json"
const VERSION: int = 1
const FIELDS: Array[String] = ["gold", "wave", "boss_round", "boss_pending", "boss_running", "wave_running", "auto_advance_pending", "wave_time_left", "spawn_left", "spawn_clock", "wave_enemy_type", "difficulty", "difficulty_confirmed", "dogs", "enemies", "beast_items", "first_beast_claimed", "first_mythic_claimed", "first_transcendent_claimed", "last_completed_wave", "game_speed", "game_over", "victory", "simulation_accumulator", "reserve_units", "draw_counts", "pity_tickets", "hidden_tickets", "draw_history", "hidden_zones", "reserve_states", "bosses_defeated"]

static func save(game: Control) -> bool:
	if game.game_over or game.victory:
		clear_save()
		return false
	if not game.difficulty_confirmed:
		return false
	var data: Dictionary = {"version": VERSION, "rng_state": str(game.rng.state)}
	for field in FIELDS:
		data[field] = game.get(field)
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.close()
	return DirAccess.rename_absolute(PATH + ".tmp", PATH) == OK

static func restore(game: Control) -> bool:
	if not FileAccess.file_exists(PATH): return false
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null: return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return false
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return false
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != VERSION: return false
	if not data.get("difficulty", "") in game.DIFFICULTY_STATS: return false
	if int(data.get("wave", -1)) < 0 or int(data.get("wave", 81)) > 80: return false
	if int(data.get("boss_round", -1)) < 0 or int(data.get("boss_round", 9)) > 8: return false
	if int(data.get("gold", -1)) < 0: return false
	if not int(data.get("game_speed", 0)) in [1, 2, 3]: return false
	if not data.get("beast_items", {}) is Dictionary: return false
	if not data.get("first_transcendent_claimed", {}) is Dictionary: return false
	for field in ["reserve_units","draw_counts","pity_tickets","reserve_states"]:
		if not data.get(field,{}) is Dictionary: return false
	for key in data.get("reserve_units",{}):
		if int(key)<0 or int(key)>=game.DOGS.size() or int(data["reserve_units"][key])<0: return false
	for key in data.get("reserve_states",{}):
		var states: Variant=data["reserve_states"][key]
		if not states is Array or states.size()>int(data.get("reserve_units",{}).get(key,0)): return false
		for state in states:
			if not state is Dictionary or int(state.get("kind",-1))!=int(key): return false
			if not state.get("cooldown",0.0) is float and not state.get("cooldown",0.0) is int: return false
	if int(data.get("hidden_tickets",0))<0: return false
	for field in ["draw_history","hidden_zones"]:
		if not data.get(field,[]) is Array: return false
	var saved_dogs: Variant = data.get("dogs", [])
	var saved_enemies: Variant = data.get("enemies", [])
	if not saved_dogs is Array or not saved_enemies is Array: return false
	if saved_dogs.size() > 36 or saved_enemies.size() > 100: return false
	var used: Dictionary = {}
	for dog in saved_dogs:
		if not dog is Dictionary: return false
		var cell: int = int(dog.get("cell", -1))
		var kind: int = int(dog.get("kind", -1))
		if cell < 0 or cell >= 36 or kind < 0 or kind >= game.DOGS.size() or used.has(cell): return false
		if not dog.has("cooldown") or not (dog["cooldown"] is float or dog["cooldown"] is int): return false
		used[cell] = true
	for enemy in saved_enemies:
		if not enemy is Dictionary: return false
		for field in ["hp", "max_hp", "progress"]:
			if not enemy.has(field): return false
	for field in FIELDS:
		if not data.has(field) or field in ["dogs", "enemies", "beast_items", "first_transcendent_claimed","reserve_units","draw_history","hidden_zones","draw_counts","pity_tickets","reserve_states"]: continue
		game.set(field, data[field])
	game.dogs.clear()
	for dog in saved_dogs: game.dogs.append(dog)
	game.enemies.clear()
	for enemy in saved_enemies: game.enemies.append(enemy)
	game.beast_items.clear()
	for key in data.get("beast_items", {}): game.beast_items[int(key)] = int(data["beast_items"][key])
	game.first_transcendent_claimed.clear()
	for key in data.get("first_transcendent_claimed", {}): game.first_transcendent_claimed[int(key)] = bool(data["first_transcendent_claimed"][key])
	for field in ["draw_counts","pity_tickets"]:
		var normalized: Dictionary = {}
		for key in data.get(field,{}): normalized[str(key)]=maxi(0,int(data[field][key]))
		game.set(field,normalized)
	game.reserve_units.clear()
	for key in data.get("reserve_units",{}): game.reserve_units[int(key)]=int(data["reserve_units"][key])
	game.draw_history.clear()
	for entry in data.get("draw_history",[]): game.draw_history.append(entry)
	game.hidden_zones.clear()
	for entry in data.get("hidden_zones",[]): game.hidden_zones.append(entry)
	game.reserve_states.clear()
	for key in data.get("reserve_states",{}): game.reserve_states[int(key)]=data["reserve_states"][key]
	game.bosses_defeated=int(data.get("bosses_defeated",maxi(0,int(game.boss_round)-(1 if game.boss_running else 0))))
	game.pending_deploy = -1
	if game.features.start_panel != null: game.features.start_panel.hide()
	game.rng.state = int(data.get("rng_state", "0"))
	game.selected = -1
	game.paused = true
	if game.difficulty_panel != null: game.difficulty_panel.visible = false
	return true

static func clear_save() -> void:
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(PATH)
