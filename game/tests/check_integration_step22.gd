extends SceneTree
# Step22: cross-system integration tests using real game entry points.
const Game = preload("res://main.gd")
var failures: int = 0
func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures += 1
func _initialize() -> void:
    call_deferred("run")
func find_recipe(g: Control, kind: int) -> Dictionary:
    for r in g.RECIPES:
        if int(r["result"]) == kind:
            return r
    return {}
func supply_recipe(g: Control, kind: int) -> void:
    g.dogs.clear()
    var r: Dictionary = find_recipe(g, kind)
    for i in range(3):
        g.dogs.append({"cell": i, "kind": int(r["materials"][i]), "cooldown": 0.0})
    if r.has("item"):
        g.beast_items[kind] = 1
func run() -> void:
    var g: Control = Game.new()
    root.add_child(g)
    g._select_difficulty("보통")
    check(g.difficulty_confirmed, "difficulty confirmed and full UI initialized")
    # Catch rapid frame updates / low FPS: 18 spawns, not 1 per render frame.
    g._start_wave()
    # Isolate scheduling from leak/game-over mechanics in this large-delta test.
    g.lives = 1000
    g._simulation_step(6.1)
    check(g.spawn_left == 14 and g.enemies.size() == 4, "lag spike of 6.1s schedules four enemies")
    g._simulation_step(30.0)
    check(g.spawn_left == 0, "remaining 14 enemies spawn after large frame")
    g._simulation_step(4.0)
    check(not g.wave_running and g.last_completed_wave == 1, "wave timer completes without duplicate start")
    check(g.gold == 110, "regular wave completion rewards 10G once")
    # Test catalog crafting with legitimate materials and exclusive item.
    supply_recipe(g, 36)
    g._craft_recipe_from_catalog(36)
    check(g.dogs.size() == 1 and int(g.dogs[0]["kind"]) == 36, "catalog crafting produces beast")
    check(g.gold == 510 and g.first_beast_claimed, "first beast mission granted via catalog")
    supply_recipe(g, 37)
    g._craft_recipe_from_catalog(37)
    check(g.gold == 510, "different beast does not duplicate tier mission")
    # Selected-unit crafting must award the mythic mission once too.
    supply_recipe(g, 42)
    g.selected = 0
    g._fuse_selected()
    check(g.dogs.size() == 1 and int(g.dogs[0]["kind"]) == 42, "selected-unit crafting produces mythic")
    check(g.gold == 1510 and g.first_mythic_claimed, "mythic award through selected-unit fusion")
    for kind in [46,47,48]:
        supply_recipe(g, kind)
        g._craft_recipe_from_catalog(kind)
        check(g.gold == 1510 + 2000 * (kind-45), "first transcendent %d award" % kind)
        supply_recipe(g, kind)
        g._craft_recipe_from_catalog(kind)
        check(g.gold == 1510 + 2000 * (kind-45), "transcendent %d repeat blocked" % kind)
    check(g.gold == 7510 and g._mission_status_text().find("[완료]") >= 0, "mission UI and 7400G total")
    # Fresh run resets all one-off rewards and transient combat state.
    g._restart()
    check(g.gold == 100 and g.dogs.is_empty() and g.enemies.is_empty(), "restart resources and combat reset")
    check(not g.first_beast_claimed and not g.first_mythic_claimed and g.first_transcendent_claimed.is_empty(), "restart unlocks missions for next play")
    # Entire 80+8 progression: real _start_wave, completion, boss kill.
    g._select_difficulty("쉬움")
    var regular_income: int = 0
    var boss_income: int = 0
    for w in range(1,81):
        g._start_wave()
        check(g.wave == w and g.wave_running and not g.boss_running, "regular %d begins" % w)
        g._complete_regular_wave()
        regular_income += g._wave_completion_reward(w)
        check(g.gold == 100 + regular_income + boss_income, "regular %d exact payout" % w)
        if w % 10 == 0:
            g._start_wave()
            check(g.boss_running and g.boss_round == int(w/10) and g.enemies.size() == 1, "boss %d enters" % int(w/10))
            g.enemies[0]["hp"] = 0.0
            g._clear_defeated()
            boss_income += g._boss_kill_reward(int(w/10))
            check(g.gold == 100 + regular_income + boss_income, "boss %d exact kill payout" % int(w/10))
    check(regular_income == 2250 and boss_income == 7100, "economy end-to-end payout totals")
    check(g.victory and not g.game_over, "boss 8 leads to victory")
    g._start_wave()
    check(g.wave == 80 and g.enemies.is_empty(), "no more waves after victory")
    g.queue_free()
    print("STEP22 INTEGRATION TEST RESULT: %d failures" % failures)
    quit(1 if failures > 0 else 0)
