extends RefCounted
const PATH: String = "user://sky_castle_save.json"
const VERSION: int = 1
const FIELDS: Array[String] = ["gold", "wave", "boss_round", "boss_pending", "boss_running", "wave_running", "auto_advance_pending", "wave_time_left", "spawn_left", "spawn_clock", "wave_enemy_type", "difficulty", "difficulty_confirmed", "dogs", "enemies", "beast_items", "first_beast_claimed", "first_mythic_claimed", "first_transcendent_claimed", "last_completed_wave", "game_speed", "game_over", "victory", "simulation_accumulator"]

static func save(game: Control) -> bool:
	if not game.difficulty_confirmed or game.game_over or game.victory:
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
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return false
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != VERSION: return false
	if not data.get("difficulty", "") in game.DIFFICULTY_STATS: return false
	var saved_dogs: Variant = data.get("dogs", [])
	var saved_enemies: Variant = data.get("enemies", [])
	if not saved_dogs is Array or not saved_enemies is Array: return false
	if saved_dogs.size() > 36 or saved_enemies.size() > 100: return false
	var used: Dictionary = {}
	for dog in saved_dogs:
		if not dog is Dictionary: return false
		var cell: int = int(dog.get("cell", -1))
		var kind: int = int(dog.get("kind", -1))
		if cell < 0 or cell >= 36 or kind < 0 or kind >= 49 or used.has(cell): return false
		used[cell] = true
	for enemy in saved_enemies:
		if not enemy is Dictionary: return false
		for field in ["hp", "max_hp", "progress"]:
			if not enemy.has(field): return false
	for field in FIELDS:
		if not data.has(field) or field in ["dogs", "enemies", "beast_items", "first_transcendent_claimed"]: continue
		game.set(field, data[field])
	game.dogs.clear()
	for dog in saved_dogs: game.dogs.append(dog)
	game.enemies.clear()
	for enemy in saved_enemies: game.enemies.append(enemy)
	game.beast_items.clear()
	for key in data.get("beast_items", {}): game.beast_items[int(key)] = int(data["beast_items"][key])
	game.first_transcendent_claimed.clear()
	for key in data.get("first_transcendent_claimed", {}): game.first_transcendent_claimed[int(key)] = bool(data["first_transcendent_claimed"][key])
	game.rng.state = int(data.get("rng_state", "0"))
	game.selected = -1
	game.paused = true
	if game.difficulty_panel != null: game.difficulty_panel.visible = false
	return true

static func clear_save() -> void:
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(PATH)
