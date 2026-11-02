extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func _check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1
func _initialize() -> void:
	call_deferred("_run_checks")
func _run_checks() -> void:
	var game: Control = Game.new()
	_check(Game.DRAW_COST == 50, "draw costs 50G")
	_check(Game.DRAW_ITEM_IDS.size() == 6 and Game.DRAW_ITEM_TICKETS == 3000, "six 3% exclusive items")
	var counts: Dictionary = {}
	var total: int = 0
	for n in Game.DRAW_GOLD_WEIGHTS:
		total += int(n)
	_check(total == Game.DRAW_GOLD_WEIGHT_TOTAL and total == 2047, "gold weighting totals 2047")
	var descending: bool = true
	for m in range(1, Game.DRAW_GOLD_WEIGHTS.size()):
		if int(Game.DRAW_GOLD_WEIGHTS[m - 1]) <= int(Game.DRAW_GOLD_WEIGHTS[m]):
			descending = false
	_check(descending and Game.DRAW_GOLD_WEIGHTS.size() == 11, "gold multiplier odds strictly decrease 0x to 10x")
	for ticket in range(18000):
		var out: Dictionary = game._draw_reward_for_roll(ticket, 1)
		if out.get("type", "") != "item":
			failures += 1
			break
		var k: int = int(out["item"])
		counts[k] = int(counts.get(k, 0)) + 1
	var valid: bool = counts.size() == 6
	for k in Game.DRAW_ITEM_IDS:
		valid = valid and int(counts.get(k, 0)) == 3000
	_check(valid, "exactly 3000 / 100000 tickets per exclusive item")
	var cumulative: int = 0
	var gold_ok: bool = true
	for multiplier in range(11):
		var start: int = cumulative + 1
		cumulative += int(Game.DRAW_GOLD_WEIGHTS[multiplier])
		var first: Dictionary = game._draw_reward_for_roll(18000, start)
		var last: Dictionary = game._draw_reward_for_roll(99999, cumulative)
		gold_ok = gold_ok and first.get("type", "") == "gold" and int(first.get("multiplier", -1)) == multiplier and int(first.get("gold", -1)) == multiplier * 50
		gold_ok = gold_ok and last.get("type", "") == "gold" and int(last.get("multiplier", -1)) == multiplier
	_check(gold_ok and cumulative == 2047, "82% gold result covers 0x..10x with correct payouts")
	_check(game._draw_reward_for_roll(-1, 1).is_empty() and game._draw_reward_for_roll(100000, 1).is_empty(), "invalid draw tickets rejected")
	# Real in-game action with controlled RNG, and no inventory mutation when gold is insufficient.
	game.gold = 49
	game._draw_gacha()
	_check(game.gold == 49 and game.beast_items.is_empty(), "insufficient gold blocks draw and preserves inventory")
	game.game_over = true
	game.gold = 100
	game._draw_gacha()
	_check(game.gold == 100 and game.beast_items.is_empty(), "game over blocks draw")
	game.game_over = false
	game.rng.seed = 123
	game._draw_gacha()
	_check(game.gold >= 50 and game.gold <= 550 or game.beast_items.size() == 1, "draw consumes 50G and awards a reward")
	game.beast_items[36] = 2
	game._restart()
	_check(game.gold == 100 and game.beast_items.is_empty(), "restart resets inventory and gold")
	game.free()
	print("GACHA TEST RESULT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
