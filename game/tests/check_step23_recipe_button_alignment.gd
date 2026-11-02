extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var game = load("res://main.gd").new()
    root.add_child(game)
    var outer: VBoxContainer = game.recipe_panel.get_child(0)
    var grid: GridContainer = outer.get_node("RecipeFilterGrid")
    assert(grid.columns == 3)
    assert(grid.size_flags_horizontal == Control.SIZE_EXPAND_FILL)
    assert(grid.get_child_count() == 6)
    for button in grid.get_children():
        assert(button is Button)
        assert(button.custom_minimum_size.x == 0.0)
        assert(button.size_flags_horizontal == Control.SIZE_EXPAND_FILL)
        assert(button.size_flags_stretch_ratio == 1.0)
    assert(outer.get_node("RecipeContentGap").custom_minimum_size.y == 12.0)
    var draw_outer: VBoxContainer = game.draw_info_panel.get_child(0)
    assert(draw_outer.get_node("DrawContentGap").custom_minimum_size.y == 14.0)
    print("STEP23 RECIPE ALIGNMENT TEST RESULT: 0 failures")
    quit()
