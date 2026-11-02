extends RefCounted
const Rules = preload("res://scripts/draw_rules.gd")
var g: Control
var start_panel: PanelContainer
var result_panel: PanelContainer
var reserve_panel: PanelContainer
var choice_panel: PanelContainer
var toast_panel: PanelContainer
var toast_label: Label
var toast_time: float = 0.0
var reserve_button: Button
var reserve_list: VBoxContainer
var last_result: String = ""
var restore_pause: bool = false
func _init(game: Control) -> void:
	g = game
func label(text: String, size: int = 24) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
func button(parent: Control, text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0, 62)
	node.add_theme_font_size_override("font_size", 24)
	node.pressed.connect(action)
	parent.add_child(node)
	return node
func panel(rect: Rect2, z: int) -> PanelContainer:
	var node := PanelContainer.new()
	node.position = rect.position
	node.size = rect.size
	node.z_index = z
	node.add_theme_stylebox_override("panel", g._panel_box(Color("#14213e"), Color("#dfb979"), 3, 18))
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	g.add_child(node)
	return node
func column(parent: Control) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	parent.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	return box
func build() -> void:
	start_panel = panel(Rect2(0, 0, 720, 1280), 310)
	var box := column(start_panel)
	box.add_spacer(false)
	var title := label("멍랜디\n천공 성채", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(label("소환하고, 선택하고, 배치하세요.\n80라운드와 8명의 보스에 도전합니다.", 26))
	button(box, "새 게임 · 난이도 선택", new_game)
	var resume := button(box, "이어하기", continue_game)
	resume.disabled = not FileAccess.file_exists(g.RunStorage.PATH)
	box.add_spacer(false)
	g.difficulty_panel.hide()
	reserve_button = g._make_button("소환 보관함 0", Vector2(478,1003), Vector2(219,74), open_reserve)
	reserve_button.add_theme_font_size_override("font_size",22)
	g.mission_button.hide()
	toast_panel = panel(Rect2(80, 755, 560, 94), 290)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label = label("",24)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)
	toast_panel.hide()
func toast(text: String) -> void:
	if toast_panel == null: return
	toast_label.text = text
	toast_time = 2.8
	toast_panel.modulate.a = 1.0
	toast_panel.show()
func tick(delta: float) -> void:
	if toast_time > 0.0:
		toast_time = maxf(0.0, toast_time-delta)
		toast_panel.modulate.a = minf(1.0,toast_time/0.45)
		if toast_time <= 0.0: toast_panel.hide()
func new_game() -> void:
	g._restart()
	start_panel.hide()
func continue_game() -> void:
	if g.RunStorage.restore(g):
		start_panel.hide()
		g._refresh()
	else:
		toast("저장된 게임을 불러올 수 없습니다.")
func reset() -> void:
	for node in [start_panel, result_panel, reserve_panel, choice_panel, toast_panel]:
		if is_instance_valid(node): node.hide()
	last_result = ""
	g.pending_deploy = -1
func refresh() -> void:
	if start_panel == null: return
	if reserve_button != null:
		var count: int = 0
		for value in g.reserve_units.values(): count += int(value)
		reserve_button.text = "소환 보관함 %d" % count
		reserve_button.disabled = not g.difficulty_confirmed or g.game_over or g.victory
	if not g.game_over and not g.victory: return
	var result: String = "승리" if g.victory else "패배"
	if last_result == result: return
	last_result = result
	g.pending_deploy = -1
	for node in [reserve_panel,choice_panel,g.recipe_panel,g.draw_info_panel,g.settings_panel]:
		if is_instance_valid(node): node.hide()
	if is_instance_valid(result_panel): result_panel.queue_free()
	result_panel = panel(Rect2(34, 230, 652, 700), 320)
	var box := column(result_panel)
	box.add_child(label("VICTORY" if g.victory else "DEFEAT",46))
	box.add_child(label("성채를 지켜냈습니다!" if g.victory else "다시 도전해 보세요.",30))
	box.add_child(label("난이도: %s\n일반 라운드: %d / 80\n진행 보스: %d / 8\n남은 골드: %dG" % [g.difficulty,g.wave,g.boss_round,g.gold]))
	box.add_spacer(false)
	button(box,"다시하기 · 난이도 선택부터",new_game)
func persist() -> void:
	if g.persistence_enabled: g.RunStorage.save(g)
func summon() -> void:
	if g.game_over or g.victory or g.gold < g.COST: return
	var kind: int = [0,1,2,10,11,12,13,14,15,16][g.rng.randi_range(0,9)]
	g.gold -= g.COST
	g.reserve_units[kind] = int(g.reserve_units.get(kind,0))+1
	g._sound("summon")
	toast("%s 소환! · 보관함에 추가되었습니다." % g.DOGS[kind])
	g._refresh()
	persist()
func deploy(kind: int, cell: int) -> bool:
	if g.game_over or g.victory or not g.difficulty_confirmed: return false
	if kind < 0 or kind >= g.DOGS.size() or cell < 0 or cell >= 36: return false
	if int(g.reserve_units.get(kind,0)) <= 0: return false
	for dog in g.dogs:
		if int(dog["cell"]) == cell: return false
	g.reserve_units[kind] = int(g.reserve_units[kind])-1
	if int(g.reserve_units[kind]) == 0: g.reserve_units.erase(kind)
	g.dogs.append({"kind":kind,"cell":cell,"cooldown":0.0,"hidden_charge":0})
	g.pending_deploy = -1
	g.selected = g.dogs.size()-1
	g._sound("summon")
	g._refresh()
	persist()
	return true
func open_reserve() -> void:
	if g.game_over or g.victory or not g.difficulty_confirmed: return
	g.pending_deploy = -1
	restore_pause = g.paused
	g.paused = true
	if is_instance_valid(reserve_panel): reserve_panel.queue_free()
	reserve_panel = panel(Rect2(14,82,692,893),250)
	var box := column(reserve_panel)
	box.add_child(label("소환 보관함",32))
	box.add_child(label("유닛 선택 → 빈 필드 칸을 눌러 배치\n조합은 필드에 배치된 유닛으로 진행합니다.",21))
	button(box,"닫기",close_reserve)
	var scroll: ScrollContainer = g.TouchScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	reserve_list = VBoxContainer.new()
	reserve_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reserve_list.add_theme_constant_override("separation",12)
	scroll.add_child(reserve_list)
	var keys: Array = g.reserve_units.keys()
	keys.sort()
	if keys.is_empty(): reserve_list.add_child(label("아직 보관 중인 유닛이 없습니다."))
	for key in keys:
		var kind: int = int(key)
		var row := HBoxContainer.new()
		reserve_list.add_child(row)
		var portrait := TextureRect.new()
		portrait.texture = g._dog_portrait(kind)
		portrait.custom_minimum_size = Vector2(74,74)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)
		var pick := button(row,"%s ×%d · 배치" % [g.DOGS[kind],int(g.reserve_units[key])],select_reserve.bind(kind))
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.disabled = g.dogs.size() >= 36
	if g.dogs.size() >= 36: box.add_child(label("필드가 가득 찼습니다. 조합 또는 판매로 빈 칸을 만드세요.",21))
	button(box,"조합 미션 확인",show_missions)
func show_missions() -> void:
	close_reserve()
	g._toggle_missions()
func close_reserve() -> void:
	if is_instance_valid(reserve_panel): reserve_panel.hide()
	g.paused = restore_pause
func select_reserve(kind: int) -> void:
	close_reserve()
	g.selected = -1
	g.pending_deploy = kind
	toast("%s 배치: 빈 칸을 누르세요. 취소는 보관함." % g.DOGS[kind])
	g._refresh()
func draw(category: String) -> void:
	if g.game_over or g.victory or not Rules.COSTS.has(category): return
	var cost: int = int(Rules.COSTS[category])
	if g.gold < cost: return
	var reward: Dictionary = Rules.resolve(category,g.rng.randi_range(0,Rules.TOTAL-1))
	grant_draw(category,reward,cost)
func grant_draw(category: String, reward: Dictionary, cost: int) -> void:
	# Only called after resolving a valid paid draw. Pity is additional, never replaces it.
	g.gold -= cost
	if reward["type"] == "item":
		var item: int = int(reward["item"])
		g.beast_items[item] = int(g.beast_items.get(item,0))+1
	elif reward["type"] == "hidden_ticket":
		g.hidden_tickets += 1
	else:
		g.gold += int(reward["gold"])
	g.draw_counts[category] = int(g.draw_counts.get(category,0))+1
	var pity: bool = int(g.draw_counts[category]) % 100 == 0
	if pity: g.pity_tickets[category] = int(g.pity_tickets.get(category,0))+1
	var entry: Dictionary = reward.duplicate(true)
	entry["pity"] = pity
	g._record_draw(entry,category)
	var message: String = str(g.draw_history[0]["label"])
	if pity: message += "\n천장! "+category+" 조합 아이템 선택권 +1"
	if g.draw_feedback != null: g.draw_feedback.text = message.replace("\n"," · ")
	toast(message)
	g._refresh()
	persist()
func choose_item(category: String, kind: int) -> bool:
	if g.game_over or g.victory or int(g.pity_tickets.get(category,0)) <= 0: return false
	var valid: bool = false
	for outcome in Rules.TABLES.get(category,[]):
		if outcome["type"] == "item" and int(outcome["item"]) == kind: valid = true
	if not valid: return false
	g.pity_tickets[category] = int(g.pity_tickets[category])-1
	g.beast_items[kind] = int(g.beast_items.get(kind,0))+1
	g.draw_info_signature = ""
	persist()
	return true
func choose_hidden(kind: int) -> bool:
	if g.game_over or g.victory or g.hidden_tickets <= 0 or kind < 49 or kind > 51: return false
	g.hidden_tickets -= 1
	g.reserve_units[kind] = int(g.reserve_units.get(kind,0))+1
	g.draw_info_signature = ""
	persist()
	return true
func open_choice(category: String) -> void:
	if g.game_over or g.victory: return
	if category == "히든" and g.hidden_tickets <= 0: return
	if category != "히든" and int(g.pity_tickets.get(category,0)) <= 0: return
	restore_pause = g.paused
	g.paused = true
	if is_instance_valid(choice_panel): choice_panel.queue_free()
	choice_panel = panel(Rect2(14,82,692,1000),270)
	var box := column(choice_panel)
	box.add_child(label(category+" 선택권 · 하나를 선택하세요",28))
	box.add_child(label("히든은 선택 후 소환 보관함에 지급됩니다." if category=="히든" else "선택한 조합 아이템 1개를 지급합니다.",21))
	button(box,"취소 · 선택권 유지",close_choice)
	var scroll: ScrollContainer = g.TouchScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",18)
	scroll.add_child(list)
	var kinds: Array = [49,50,51] if category=="히든" else g.TRANSCENDENT_DRAW_ITEM_IDS if category=="초월" else g.MYTHIC_DRAW_ITEM_IDS if category=="신화" else g.DRAW_ITEM_IDS
	for value in kinds:
		var kind: int = int(value)
		var row := HBoxContainer.new()
		list.add_child(row)
		var portrait := TextureRect.new()
		portrait.texture = g._dog_portrait(kind)
		portrait.custom_minimum_size = Vector2(116,116)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var description: String = str(g.BEAST_ITEMS.get(kind,""))
		if kind>=49:
			description = ["성핵 붕괴: 5회 공격마다 광역 마법 폭발과 별빛 연쇄","무음 균열: 4회 공격마다 3초간 균열 피해와 둔화","꿈결 공명: 6회 공격마다 주변 아군의 4초간 공격속도 강화"][kind-49]
		info.add_child(label(description,21))
		button(info,g.DOGS[kind]+" 선택",finish_choice.bind(category,kind))
func close_choice() -> void:
	if is_instance_valid(choice_panel): choice_panel.hide()
	g.paused = restore_pause
func finish_choice(category: String, kind: int) -> void:
	if not is_instance_valid(choice_panel) or not choice_panel.visible: return
	var granted: bool = choose_hidden(kind) if category=="히든" else choose_item(category,kind)
	if not granted: return
	close_choice()
	g._sound("element_hidden_star" if category=="히든" else "craft")
	toast(g.DOGS[kind]+(" · 소환 보관함에 지급!" if category=="히든" else " 조합 아이템 획득!"))
	g._refresh()
func draw_info() -> void:
	var category: String = g.draw_info_category
	var count: int = int(g.draw_counts.get(category,0))
	g._draw_info_line("1회 %dG · 천장 %d/100 · 누적 %d회" % [int(Rules.COSTS[category]),count%100,count],23)
	if g.draw_info_tab == "보유 아이템":
		button(g.draw_info_list,"히든 선택권 %d장 · 사용" % g.hidden_tickets,open_choice.bind("히든")).disabled = g.hidden_tickets<=0 or g.game_over or g.victory
		button(g.draw_info_list,"%s 조합 아이템 선택권 %d장 · 사용" % [category,int(g.pity_tickets.get(category,0))],open_choice.bind(category)).disabled = int(g.pity_tickets.get(category,0))<=0 or g.game_over or g.victory
		g._draw_info_line("선택권과 보관 유닛은 이번 게임에서 사용합니다.",19)
		var schedules: Dictionary = g.BalanceRules.MILESTONES[g.difficulty]
		g._draw_info_line("라운드 보상: "+str(schedules[category])+" · 각 선택권 1장",19)
		for outcome in Rules.TABLES[category]:
			if outcome["type"] == "item":
				var id: int = int(outcome["item"])
				g._draw_info_line("%s · %d개" % [g.BEAST_ITEMS[id],int(g.beast_items.get(id,0))])
	elif g.draw_info_tab == "최근 결과":
		var shown: int = 0
		for entry in g.draw_history:
			if entry["category"] != category: continue
			shown += 1
			g._draw_info_line("%d. %s%s" % [shown,entry["label"]," · 천장 선택권 +1" if entry.get("pity",false) else ""])
		if shown==0: g._draw_info_line("아직 뽑기 기록이 없습니다.")
	else:
		g._draw_info_line("전체 뽑기 기준 · 합계 100.0000%",23)
		for outcome in Rules.TABLES[category]:
			var text: String = ""
			match outcome["type"]:
				"gold": text = "골드 %d배 · %dG" % [int(outcome["multiplier"]),int(outcome["gold"])]
				"item": text = str(g.BEAST_ITEMS[int(outcome["item"])])
				"hidden_ticket": text = "히든 선택권 · 3종 중 1종 선택"
			g._draw_info_line("%s · %.4f%%" % [text,float(outcome["tickets"])/10000.0],21)
		g._draw_info_line("100회마다 해당 유형 조합 아이템 선택권 추가 지급.\n아이템 당첨으로 천장 횟수가 초기화되지 않습니다.",20)
