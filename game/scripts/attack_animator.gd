extends RefCounted
# Separate authored keyframe clips. Rendering never moves a unit's logical cell.
const CLIPS := ["slash","pounce","bite","cast","cleave","shoot"]
static func clip_for(kind: int) -> String:
	if kind in [0,1,7,9,10,15,20,21,28,32,35,41,42,45,47]: return "cast"
	if kind in [2,6,24,38]: return "shoot"
	if kind in [37,39,40]: return "pounce"
	if kind in [4,5,12,13,18,19,23,29,31,33,48]: return "bite"
	if kind in [8,27,30,36,43,46]: return "cleave"
	return "slash"
static func duration_for(cooldown: float, speed: int) -> float:
	return clampf(cooldown / maxf(1.0,float(speed)) * 0.82,0.01,0.68)
static func sample(kind: int, aim: Vector2, phase: float) -> Dictionary:
	var p: float = clampf(phase,0.0,1.0)
	var clip: String = clip_for(kind)
	# Keyframes: idle, anticipation, full strike, impact hold, recoil, settled.
	var keys: Array[float] = [0.0,0.22,0.38,0.53,0.72,1.0]
	var moves: Array[float] = [0.0,-10.0,26.0,23.0,-5.0,0.0]
	var turns: Array[float] = [0.0,-0.26,0.30,0.25,-0.10,0.0]
	var rises: Array[float] = [0.0,3.0,-10.0,-7.0,2.0,0.0]
	if clip == "cast":
		moves = [0.0,-4.0,3.0,3.0,0.0,0.0]
		turns = [0.0,-0.18,0.12,0.08,-0.04,0.0]
		rises = [0.0,-9.0,-20.0,-17.0,-5.0,0.0]
	elif clip == "pounce":
		moves = [0.0,-14.0,34.0,30.0,-5.0,0.0]
		rises = [0.0,9.0,-17.0,-9.0,3.0,0.0]
	elif clip == "shoot":
		moves = [0.0,-7.0,-17.0,-12.0,3.0,0.0]
		turns = [0.0,-0.16,-0.30,-0.20,0.06,0.0]
	elif clip == "cleave":
		turns = [0.0,-0.45,0.48,0.42,-0.13,0.0]
	var segment: int = 0
	while segment < 4 and p > keys[segment+1]: segment += 1
	var t: float = inverse_lerp(keys[segment],keys[segment+1],p)
	t = t*t*(3.0-2.0*t)
	var travel: float = lerpf(moves[segment],moves[segment+1],t)
	var rise: float = lerpf(rises[segment],rises[segment+1],t)
	var facing: float = -1.0 if aim.x < -0.1 else 1.0
	var rotation: float = lerpf(turns[segment],turns[segment+1],t)*facing
	var squash: float = sin(p*PI)
	return {"offset":aim*travel+Vector2(0,rise),"rotation":rotation,"scale":Vector2(1.0+squash*0.14,1.0-squash*0.10),"clip":clip,"phase":p}
static func draw_weapon(canvas: CanvasItem, center: Vector2, aim: Vector2, pose: Dictionary, tint: Color) -> void:
	var p: float = float(pose["phase"])
	if p <= 0.0 or p >= 0.95: return
	var clip: String = pose["clip"]
	var angle: float = aim.angle()
	var impact: float = clampf((p-0.2)/0.33,0.0,1.0)
	var fade: float = minf(1.0,(1.0-p)*3.0)
	var color := Color(tint,fade)
	var white := Color(1,1,1,fade)
	var hand: Vector2 = center+aim*17.0+Vector2(0,5)
	if clip in ["slash","cleave"]:
		var sweep: float = angle + lerpf(-1.8,1.3,impact)
		var blade: Vector2 = Vector2.from_angle(sweep)
		var side := Vector2(-blade.y,blade.x)
		var length: float = 48.0 if clip == "cleave" else 36.0
		if p > 0.22:
			canvas.draw_arc(hand,length,sweep-1.25,sweep,24,Color(tint,fade*0.35),13.0,true)
			canvas.draw_arc(hand,length,sweep-0.8,sweep,20,white,3.0,true)
		canvas.draw_colored_polygon(PackedVector2Array([hand-side*4,hand+blade*length,hand+side*4,hand-blade*8]),white)
		canvas.draw_line(hand-blade*9,hand-blade*17,color,5.0,true)
		canvas.draw_line(hand-side*10,hand+side*10,color,4.0,true)
	elif clip == "bite":
		var mouth: Vector2 = center+aim*30
		for side in [-1,1]:
			var across: Vector2 = aim.orthogonal()*float(side)
			var opening: float = 4.0+sin(impact*PI)*15.0
			var teeth := PackedVector2Array([mouth-aim*14+across*opening,mouth-aim*6+across*3,mouth+across*opening,mouth+aim*9+across*3,mouth+aim*18+across*opening])
			canvas.draw_polyline(teeth,white,3.5,true)
	elif clip == "pounce":
		if p < 0.22: return
		for i in range(3):
			var shift: Vector2 = aim.orthogonal()*float(i-1)*9
			canvas.draw_line(center-aim*36+shift,center+aim*30+shift,color,5.0,true)
			canvas.draw_line(center+shift,center+aim*30+shift,white,2.0,true)
	elif clip == "cast":
		var orb: Vector2 = center+Vector2(0,-35)
		var charge: float = 8.0+minf(1.0,p/0.38)*13
		canvas.draw_circle(orb,charge+9,Color(tint,0.18*fade))
		canvas.draw_circle(orb,charge,color)
		canvas.draw_circle(orb,charge*0.4,white)
		canvas.draw_arc(orb,charge+12,angle+p*4,angle+p*4+TAU*0.85,32,color,2.5,true)
		if p>=0.38: canvas.draw_line(orb,orb+aim*44,white,6.0*(1.0-p),true)
	else:
		var bow: Vector2 = center+aim*24
		canvas.draw_arc(bow,23,angle-PI/2,angle+PI/2,24,color,3.0,true)
		canvas.draw_line(bow-aim.orthogonal()*23,bow+aim.orthogonal()*23,white,1.5,true)
		if p>=0.3:
			canvas.draw_line(bow+aim*8,bow+aim*(25+impact*30),white,4.0,true)
