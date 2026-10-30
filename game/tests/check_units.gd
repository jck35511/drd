extends SceneTree

func _initialize() -> void:
    var game_script = load("res://main.gd")
    if game_script == null:
        push_error("FAIL: main.gd load")
        quit(1)
        return
    var types: Array = [game_script.DOGS, game_script.GRADES, game_script.ATTACK, game_script.RANGE, game_script.COOLDOWN, game_script.DOG_COLORS]
    var labels: Array[String] = ["DOGS", "GRADES", "ATTACK", "RANGE", "COOLDOWN", "DOG_COLORS"]
    for i in range(types.size()):
        if types[i].size() != 49:
            push_error("FAIL: %s has %d items, expected 49" % [labels[i], types[i].size()])
            quit(1)
            return
    if game_script.COLS != 6 or game_script.ROWS != 6:
        push_error("FAIL: board size")
        quit(1)
        return
    var grades: Dictionary = {"소형견": 0, "중형견": 0, "대형견": 0, "맹수": 0, "신화": 0, "초월": 0}
    for k in range(49):
        if not grades.has(game_script.GRADES[k]):
            push_error("FAIL: invalid grade for index %d" % k)
            quit(1)
            return
        grades[game_script.GRADES[k]] += 1
        if game_script.ATTACK[k] <= 0 or game_script.RANGE[k] <= 0 or game_script.COOLDOWN[k] <= 0:
            push_error("FAIL: invalid stats at index %d" % k)
            quit(1)
            return
    if grades["소형견"] != 10 or grades["중형견"] != 13 or grades["대형견"] != 13 or grades["맹수"] != 6 or grades["신화"] != 4 or grades["초월"] != 3:
        push_error("FAIL: grade count mismatch")
        quit(1)
        return
    print("PASS: 6x6 board, 49 units, 10/13/13/6/4/3 grades, six aligned data arrays")
    quit(0)
