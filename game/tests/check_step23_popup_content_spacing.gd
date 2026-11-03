extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var game = load("res://main.gd").new()
    root.add_child(game)
    var recipe_outer: VBoxContainer = game.recipe_panel.get_child(0)
    var draw_outer: VBoxContainer = game.draw_info_panel.get_child(0)
    var recipe_gap: Control = recipe_outer.get_node("RecipeContentGap")
    var draw_gap: Control = draw_outer.get_node("DrawContentGap")
    assert(recipe_gap.custom_minimum_size.y == 12.0)
    assert(draw_gap.custom_minimum_size.y == 14.0)
    assert(recipe_outer.get_child(recipe_gap.get_index() - 1) is GridContainer)
    assert(recipe_outer.get_child(recipe_gap.get_index() + 1) == game.recipe_feedback)
    assert(draw_outer.get_child(draw_gap.get_index() - 1).name == "DrawInfoTabRow")
    assert(draw_outer.get_child(draw_gap.get_index() + 1) is ScrollContainer)
    assert(game.recipe_panel.size == Vector2(692, 893))
    assert(game.draw_info_panel.size == Vector2(692, 893))
    print("STEP23 POPUP CONTENT SPACING TEST RESULT: 0 failures")
    quit()
