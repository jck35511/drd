extends SceneTree
const Game = preload("res://main.gd")
var fails: int = 0
func check(ok: bool, text: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + text)
    if not ok:
        fails += 1
func _initialize() -> void:
    call_deferred("run_checks")
func run_checks() -> void:
    var game: Control = Game.new()
    check(Game.MYTHIC_DRAW_ITEM_IDS.size() == 4 and Game.MYTHIC_DRAW_ITEM_TICKETS == 1000, "four mythic items at exactly 1% each")
    check(Game.DRAW_ITEM_IDS.size() == 6 and Game.DRAW_ITEM_TICKETS == 3000, "beast gacha remains 3% each")
    var counts: Dictionary = {}
    for ticket in range(4000):
        var out: Dictionary = game._mythic_reward_for_roll(ticket, 1)
        var k: int = int(out.get("item", -1))
        counts[k] = int(counts.get(k, 0)) + 1
    var ok: bool = counts.size() == 4
    for k in Game.MYTHIC_DRAW_ITEM_IDS:
        ok = ok and int(counts.get(k, 0)) == 1000
    check(ok, "exactly 1000 tickets per mythic item")
    ok = true
    var cumulative: int = 0
    for multiplier in range(11):
        cumulative += int(Game.DRAW_GOLD_WEIGHTS[multiplier])
        var reward: Dictionary = game._mythic_reward_for_roll(99999, cumulative)
        ok = ok and reward.get("type") == "gold" and int(reward.get("multiplier", -1)) == multiplier and int(reward.get("gold", -1)) == multiplier * 50
    check(ok and cumulative == 2047, "remaining 96% gold supports 0x..10x decreasing")
    check(game._mythic_reward_for_roll(-1, 1).is_empty(), "invalid ticket rejected")
    game.gold = 49
    game._draw_mythic_gacha()
    check(game.gold == 49 and game.beast_items.is_empty(), "insufficient gold never consumes")
    game.gold = 100
    game.game_over = true
    game._draw_mythic_gacha()
    check(game.gold == 100, "game over blocks mythic draw")
    game.game_over = false
    game.rng.seed = 456
    game._draw_mythic_gacha()
    check(game.gold >= 50 and game.gold <= 550 or not game.beast_items.is_empty(), "mythic draw pays or grants item")
    game.free()
    var ui: Control = Game.new()
    get_root().add_child(ui)
    check(ui.mythic_draw_button != null and ui.draw_button != null, "beast and mythic draw buttons separate")
    ui._set_draw_info_category("신화")
    ui._set_draw_info_tab("확률표")
    check(ui.draw_info_list.get_child_count() >= 18, "mythic 1% and gold 96% probability table")
    ui._set_draw_info_tab("보유 아이템")
    check(ui.draw_info_list.get_child_count() >= 6, "four mythic items in inventory")
    ui.queue_free()
    print("MYTHIC GACHA RESULT: %d failures" % fails)
    quit(0 if fails == 0 else 1)
