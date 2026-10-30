extends RefCounted
# Shared atlases: 49 independent hero illustrations, four regular enemies, eight bosses.
var atlases: Array[Texture2D] = []
var regions: Array[Texture2D] = []

func load_atlases() -> void:
	if not atlases.is_empty():
		return
	for sheet in range(8):
		var path := "res://assets/sky_atlas_%d.png" % sheet
		var texture: Texture2D = null
		if ResourceLoader.exists(path):
			texture = load(path) as Texture2D
		else:
			var image := Image.load_from_file(path)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
		atlases.append(texture)
		for slot in range(8):
			if texture == null:
				regions.append(null)
				continue
			var region := AtlasTexture.new()
			region.atlas = texture
			var dimensions := Vector2(float(texture.get_width()) / 4.0, float(texture.get_height()) / 2.0)
			region.region = Rect2(Vector2(slot % 4, int(slot / 4)) * dimensions, dimensions)
			region.filter_clip = true
			regions.append(region)

func unit_texture(kind: int) -> Texture2D:
	return regions[kind] if kind >= 0 and kind < 49 and regions.size() >= 49 else null

func enemy_texture(kind: int) -> Texture2D:
	var index: int = 49 + clampi(kind, 0, 11)
	return regions[index] if index < regions.size() else null

func draw_character(canvas: CanvasItem, texture: Texture2D, center: Vector2, height: float, tint: Color = Color.WHITE) -> void:
	if texture == null:
		canvas.draw_circle(center, height * 0.35, tint)
		return
	var ratio: float = float(texture.get_width()) / maxf(1.0, float(texture.get_height()))
	var dimensions := Vector2(height * ratio, height)
	canvas.draw_texture_rect(texture, Rect2(center - dimensions * 0.5, dimensions), false, tint)

func draw_battle(game: Control, canvas: CanvasItem) -> void:
	var route: Array = game.ROUTE
	# Four-sided blue stone path and countable 6x6 ivory platform.
	for i in range(4):
		canvas.draw_line(route[i], route[(i + 1) % 4], Color("#d8b46c"), 55.0, true)
		canvas.draw_line(route[i], route[(i + 1) % 4], Color("#203f7c"), 48.0, true)
		canvas.draw_line(route[i], route[(i + 1) % 4], Color("#426fc0"), 36.0, true)
	var dimensions := Vector2(game.COLS * game.CELL, game.ROWS * game.CELL)
	canvas.draw_rect(Rect2(game.GRID_ORIGIN - Vector2(8, 8), dimensions + Vector2(11, 11)), Color("#e4c780"))
	canvas.draw_rect(Rect2(game.GRID_ORIGIN - Vector2(4, 4), dimensions + Vector2(3, 3)), Color("#6077a4"))
	for row in range(game.ROWS):
		for col in range(game.COLS):
			var cell: int = row * game.COLS + col
			var rect := Rect2(game.GRID_ORIGIN + Vector2(col, row) * game.CELL, Vector2.ONE * (game.CELL - 5.0))
			var support: bool = row in [2, 3] and col in [2, 3]
			var color := Color("#c8d4f1") if support else Color("#eff1fa") if (row + col) % 2 == 0 else Color("#e2e8f5")
			canvas.draw_rect(rect, color)
			canvas.draw_rect(rect.grow(-2.0), Color("#9eadd0"), false, 1.0)
			var center: Vector2 = game._cell_center(cell)
			if support:
				canvas.draw_arc(center, 12.0, 0.0, TAU, 16, Color("#8b99bf"), 1.0, true)
				canvas.draw_line(center + Vector2(-7, 0), center + Vector2(7, 0), Color("#8b99bf"), 1.0)
				canvas.draw_line(center + Vector2(0, -7), center + Vector2(0, 7), Color("#8b99bf"), 1.0)
			else:
				canvas.draw_polyline(PackedVector2Array([center + Vector2(0, -6), center + Vector2(6, 0), center + Vector2(0, 6), center + Vector2(-6, 0), center + Vector2(0, -6)]), Color("#c0c9df"), 1.0, true)
	# Selected range and reachable route segments underneath characters.
	if game.selected >= 0 and game.selected < game.dogs.size():
		var dog: Dictionary = game.dogs[game.selected]
		var origin: Vector2 = game._cell_center(int(dog["cell"]))
		var reach: float = float(game.RANGE[int(dog["kind"])])
		canvas.draw_circle(origin, reach, Color(0.25, 0.65, 1.0, 0.065))
		canvas.draw_arc(origin, reach, 0.0, TAU, 72, Color(0.25, 0.7, 1.0, 0.65), 2.0, true)
		for step in range(160):
			var a: Vector2 = game._route_point(float(step) / 40.0)
			var b: Vector2 = game._route_point(float(step + 1) / 40.0)
			if origin.distance_to((a + b) * 0.5) <= reach:
				canvas.draw_line(a, b, Color("#80e4ff"), 5.0, true)
	for i in range(game.dogs.size()):
		var dog: Dictionary = game.dogs[i]
		var kind: int = int(dog["kind"])
		var cell: int = int(dog["cell"])
		var center: Vector2 = game._cell_center(cell)
		var elapsed: float = game.presentation_clock - float(game.attack_flashes.get(cell, -10.0))
		var pulse: float = maxf(0.0, 1.0 - elapsed / 0.18)
		canvas.draw_circle(center + Vector2(0, 22), 22.0, Color(0.1, 0.15, 0.3, 0.18))
		if kind >= 36:
			var ring := Color("#e7be4c") if kind < 42 else Color("#56bfee") if kind < 46 else Color("#ba76f4")
			canvas.draw_arc(center, 29.0, 0.0, TAU, 36, ring, 1.5, true)
		draw_character(canvas, unit_texture(kind), center + Vector2(0, -pulse * 4.0), 65.0 + pulse * 3.0)
		if game.selected == i:
			canvas.draw_arc(center, 33.0, 0.0, TAU, 36, Color("#f7bd3e"), 3.0, true)
	for enemy in game.enemies:
		var point: Vector2 = game._route_point(float(enemy["progress"]))
		var is_boss: bool = bool(enemy.get("is_boss", false))
		var enemy_index: int = 4 + clampi(int(enemy.get("boss_round", 1)) - 1, 0, 7) if is_boss else maxi(0, game.REGULAR_ENEMY_TYPES.find(str(enemy.get("enemy_type", ""))))
		var bob: float = sin(game.presentation_clock * 9.0 + float(enemy["progress"]) * 2.0) * 1.5
		canvas.draw_circle(point + Vector2(0, 15), 21.0 if is_boss else 14.0, Color(0.05, 0.1, 0.2, 0.2))
		draw_character(canvas, enemy_texture(enemy_index), point + Vector2(0, bob), 68.0 if is_boss else 44.0)
		var statuses: Dictionary = enemy.get("effects", {})
		if statuses.has("freeze") or statuses.has("stun"):
			canvas.draw_arc(point, 25.0, 0.0, TAU, 24, Color("#8be8ff") if statuses.has("freeze") else Color("#ffe18a"), 2.5, true)
		elif statuses.has("slow"):
			canvas.draw_arc(point, 23.0, 0.0, TAU, 24, Color("#6995f3"), 1.5, true)
		for effect in ["bleed", "poison", "burn"]:
			if statuses.has(effect):
				var tint := Color("#e8678a") if effect == "bleed" else Color("#95e879") if effect == "poison" else Color("#ffbf65")
				canvas.draw_circle(point + Vector2(-12 + ["bleed", "poison", "burn"].find(effect) * 12, -22), 3.0, tint)
		var width: float = 48.0 if is_boss else 32.0
		var bar := Rect2(point + Vector2(-width * 0.5, -39 if is_boss else -27), Vector2(width, 4))
		canvas.draw_rect(bar, Color("#28314b"))
		canvas.draw_rect(Rect2(bar.position, Vector2(width * clampf(float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"])), 0.0, 1.0), 4)), Color("#f37b9f") if is_boss else Color("#f0a58a"))
	for fx in game.combat_fx:
		_draw_effect(canvas, fx)
	if game.paused:
		canvas.draw_rect(Rect2(65, 135, 590, 580), Color(0.08, 0.12, 0.25, 0.25))

func _draw_effect(canvas: CanvasItem, fx: Dictionary) -> void:
	var progress: float = clampf(float(fx["age"]) / float(fx["duration"]), 0.0, 1.0)
	var origin: Vector2 = fx["from"]
	var target: Vector2 = fx["to"]
	var style: String = fx["style"]
	var color := Color("#ffe3a0")
	if style == "ice": color = Color("#8be9ff")
	elif style == "lightning": color = Color("#87bdff")
	elif style == "hell": color = Color("#e68afe")
	elif style == "poison": color = Color("#abef89")
	elif style == "magic": color = Color("#c0b4ff")
	color.a = 1.0 - progress
	if style == "lightning":
		var points := PackedVector2Array()
		for i in range(7):
			var q: Vector2 = origin.lerp(target, float(i) / 6.0)
			if i > 0 and i < 6: q += Vector2(0, (1 if i % 2 == 0 else -1) * 8)
			points.append(q)
		canvas.draw_polyline(points, color, 2.5, true)
	elif style == "sun":
		canvas.draw_line(target + Vector2(0, -65), target, color, 4.0, true)
		canvas.draw_arc(target, 12 + progress * 30, 0.0, TAU, 32, color, 2.0, true)
	else:
		var shot: Vector2 = origin.lerp(target, minf(1.0, progress * 2.0))
		canvas.draw_circle(shot, 3.0 if style == "bolt" else 5.0, color)
		if progress > 0.45:
			for i in range(5):
				var angle: float = TAU * float(i) / 5.0
				var ray := Vector2(cos(angle), sin(angle))
				canvas.draw_line(target + ray * 6, target + ray * (9 + progress * 16), color, 2.0, true)
