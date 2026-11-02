extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var game = load("res://main.gd").new()
    root.add_child(game)
    var outer: VBoxContainer = game.draw_info_panel.get_child(0)
    var category_row: HBoxContainer = outer.get_node("DrawCategoryRow")
    var tab_row: HBoxContainer = outer.get_node("DrawInfoTabRow")
    assert(category_row.get_child_count() == 3)
    assert(tab_row.get_child_count() == 3)
    assert(category_row.size_flags_horizontal == Control.SIZE_EXPAND_FILL)
    assert(tab_row.size_flags_horizontal == Control.SIZE_EXPAND_FILL)
    for row in [category_row, tab_row]:
        for button in row.get_children():
            assert(button is Button)
            assert(button.size_flags_horizontal == Control.SIZE_EXPAND_FILL)
            assert(button.size_flags_stretch_ratio == 1.0)
            assert(button.custom_minimum_size.x == 0.0)
    print("STEP23 DRAW BUTTON ALIGNMENT TEST RESULT: 0 failures")
    quit()
