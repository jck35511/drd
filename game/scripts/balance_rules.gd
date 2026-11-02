extends RefCounted
# v0.30 economy: preserve early kill income, reduce late cash bursts, make
# essential crafting attainable via deterministic milestones below Hell.
const WAVE_REWARDS := [10,12,14,16,18,20,22,25]
const BOSS_REWARDS := [150,200,250,300,350,450,550,700]
const BOSS_END_MULTIPLIERS := {"쉬움":6.0,"보통":6.0,"어려움":3.0,"지옥":1.6}
const FIRST_BEAST: int = 100
const FIRST_MYTHIC: int = 250
const FIRST_TRANSCENDENT: int = 500
const MILESTONES := {
	"쉬움":{"맹수":[10,20,30,40,50,60,70],"신화":[30,50,70],"초월":[60]},
	"보통":{"맹수":[20,30,40,50,60,70],"신화":[40,60,70],"초월":[70]},
	"어려움":{"맹수":[20,30,40,50,60,70],"신화":[40,60,70],"초월":[70]},
	"지옥":{"맹수":[20,40],"신화":[50],"초월":[]}
}
static func grant_milestone(g: Control, wave: int) -> String:
	var granted: Array[String] = []
	for category in MILESTONES[g.difficulty]:
		if MILESTONES[g.difficulty][category].has(wave):
			g.pity_tickets[category]=int(g.pity_tickets.get(category,0))+1
			granted.append(category+" 선택권 +1")
	if granted.is_empty(): return ""
	g.draw_info_signature=""
	return " · ".join(granted)
