extends SceneTree
const Game = preload("res://main.gd")
const Rules = preload("res://scripts/draw_rules.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var category: String = "신화"
	var total: int = 0
	var items: int = 0
	var last_gold: int = Rules.TOTAL
	for outcome in Rules.TABLES[category]:
		var n: int = int(outcome["tickets"])
		assert(Rules.resolve(category,total)==outcome)
		assert(Rules.resolve(category,total+n-1)==outcome)
		if outcome["type"]=="gold":
			assert(n<last_gold)
			last_gold=n
			assert(int(outcome["gold"])==int(outcome["multiplier"])*100)
			if int(outcome["multiplier"])==0: assert(n==700000)
		elif outcome["type"]=="hidden_ticket": assert(n==10)
		else:
			assert(n==1000)
			items+=1
		total+=n
	assert(total==1000000 and items==4)
	assert(Rules.resolve(category,-1).is_empty() and Rules.resolve(category,total).is_empty())
	var g: Control = Game.new()
	g.persistence_enabled=false
	g.gold=100-1
	g.features.draw(category)
	assert(g.gold==100-1 and g.draw_counts.is_empty())
	g.gold=100000
	g.rng.seed=987
	g.draw_counts[category]=99
	g.features.draw(category)
	assert(int(g.draw_counts[category])==100 and int(g.pity_tickets[category])==1)
	assert(g.draw_history[0]["pity"])
	for i in range(100): g.features.draw(category)
	assert(int(g.draw_counts[category])==200 and int(g.pity_tickets[category])==2)
	assert(g.draw_counts.size()==1)
	var id: int = 42
	var before: int = int(g.beast_items.get(id,0))
	assert(not g.features.choose_item(category,0))
	assert(g.features.choose_item(category,id))
	assert(int(g.beast_items[id])==before+1 and int(g.pity_tickets[category])==1)
	var snapshot: int = g.gold
	g.victory=true
	g.features.draw(category)
	assert(g.gold==snapshot and int(g.draw_counts[category])==200)
	g.victory=false
	g.game_over=true
	g.features.draw(category)
	assert(g.gold==snapshot)
	g.game_over=false
	g._restart()
	assert(g.draw_counts.is_empty() and g.pity_tickets.is_empty() and g.hidden_tickets==0)
	g.free()
	print("PASS: 신화 exact odds, boundaries, cost, repeating independent pity, choices and end guards")
	quit()
