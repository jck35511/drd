extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var game = load("res://main.gd").new()
    root.add_child(game)
    assert(game.recipe_panel.position == Vector2(14, 82))
    assert(game.draw_info_panel.position == Vector2(14, 82))
    assert(game.recipe_panel.size == Vector2(692, 893))
    assert(game.draw_info_panel.size == Vector2(692, 893))
    assert(game.recipe_panel.position.y + game.recipe_panel.size.y <= 980)
    assert(game.draw_info_panel.position.y + game.draw_info_panel.size.y <= 980)
    assert(game.recipe_list != null and game.draw_info_list != null)
    game._toggle_recipes()
    assert(game.recipe_panel.visible)
    game._toggle_draw_info()
    assert(game.draw_info_panel.visible and not game.recipe_panel.visible)
    print("STEP23 FULL HEIGHT POPUP TEST RESULT: 0 failures")
    quit()
