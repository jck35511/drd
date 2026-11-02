extends SceneTree
const Game = preload("res://main.gd")
var failures: int = 0
func ck(ok: bool, name: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + name)
    if not ok:
        failures += 1
func _initialize() -> void:
    call_deferred("go")
func go() -> void:
    var game: Control = Game.new()
    ck(Game.DRAW_COST == 50 and Game.TRANSCENDENT_DRAW_ITEM_IDS.size() == 3 and Game.TRANSCENDENT_DRAW_ITEM_TICKETS == 100, "50G, three 0.1% item pools")
    ck(Game.DRAW_ITEM_TICKETS == 3000 and Game.MYTHIC_DRAW_ITEM_TICKETS == 1000, "original 3% and 1% pools unchanged")
    var counts: Dictionary = {}
    for ticket in range(300):
        var reward: Dictionary = game._transcendent_reward_for_roll(ticket, 1)
        var id: int = int(reward.get("item", -1))
        counts[id] = int(counts.get(id, 0)) + 1
    var good: bool = counts.size() == 3
    for id in Game.TRANSCENDENT_DRAW_ITEM_IDS:
        good = good and int(counts.get(id, 0)) == 100
    ck(good, "each transcendent item has exactly 100 / 100000 tickets")
    var cumulative: int = 0
    var previous: int = 99999
    good = true
    for i in range(11):
        var weight: int = int(Game.DRAW_GOLD_WEIGHTS[i])
        good = good and weight < previous
        previous = weight
        cumulative += weight
        var outcome: Dictionary = game._transcendent_reward_for_roll(99999, cumulative)
        good = good and outcome.get("type", "") == "gold" and int(outcome.get("multiplier", -1)) == i and int(outcome.get("gold", -1)) == 50 * i
    ck(good and cumulative == 2047, "remaining 99.7% 0x to 10x strictly decreasing")
    ck(game._transcendent_reward_for_roll(-1, 1).is_empty() and game._transcendent_reward_for_roll(100000, 1).is_empty(), "invalid tickets rejected")
    game.gold = 49
    game._draw_transcendent_gacha()
    ck(game.gold == 49 and game.beast_items.is_empty(), "insufficient gold preserves resources")
    game.gold = 100
    game.game_over = true
    game._draw_transcendent_gacha()
    ck(game.gold == 100, "game over disallows draw")
    game.game_over = false
    game.rng.seed = 77
    game._draw_transcendent_gacha()
    ck(game.gold >= 50 and game.gold <= 550 or not game.beast_items.is_empty(), "transcendent draw issues a reward")
    game.free()
    var ui: Control = Game.new()
    get_root().add_child(ui)
    ck(ui.draw_button != null and ui.mythic_draw_button != null and ui.transcendent_draw_button != null, "three independent draw buttons")
    ui._set_draw_info_category("초월")
    ui._set_draw_info_tab("확률표")
    ck(ui.draw_info_list.get_child_count() >= 16, "transcendent probability panel includes three items and 11 gold outcomes")
    ui._set_draw_info_tab("보유 아이템")
    ck(ui.draw_info_list.get_child_count() >= 5, "three transcendent items in inventory")
    ui.queue_free()
    print("TRANSCENDENT GACHA RESULT: %d failures" % failures)
    quit(0 if failures == 0 else 1)
