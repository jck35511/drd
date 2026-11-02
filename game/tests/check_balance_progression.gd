extends SceneTree
const Game=preload("res://main.gd")
func _initialize() -> void:
	var totals: Dictionary={"쉬움":[13,5,1],"보통":[11,5,1],"어려움":[10,5,1],"지옥":[2,1,0]}
	for difficulty in totals:
		var g: Control=Game.new()
		g.persistence_enabled=false
		g.difficulty=difficulty
		g.difficulty_confirmed=true
		var start_gold: int=g.gold
		for wave in range(1,81):
			g.wave=wave
			g.wave_running=true
			g._complete_regular_wave()
			var before: int=g.gold
			var tickets: Dictionary=g.pity_tickets.duplicate()
			g._complete_regular_wave()
			assert(g.gold==before and g.pity_tickets==tickets,"No repeated wave payout")
		assert(g.gold-start_gold==1370)
		var i: int=0
		for category in ["맹수","신화","초월"]:
			assert(int(g.pity_tickets.get(category,0))==int(totals[difficulty][i]))
			i+=1
		assert(g.draw_counts.is_empty(),"Progression rewards do not alter paid-draw pity")
		g.free()
	assert(Game.KILL_REWARD==5 and Game.COST==20)
	assert(Game.FIRST_BEAST_REWARD+Game.FIRST_MYTHIC_REWARD+3*Game.FIRST_TRANSCENDENT_REWARD==1850)
	assert(Game.DrawRules.COSTS=={"맹수":50,"신화":100,"초월":200})
	print("PASS: fixed progression awards, no duplicate income, independent pity and reduced cash bursts")
	quit()
