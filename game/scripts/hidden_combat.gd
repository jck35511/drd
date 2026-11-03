extends RefCounted
static func emit(g: Control, dog_index: int, point: Vector2, skill: String) -> void:
	if not g.visual_effects_enabled: return
	var kind: int = int(g.dogs[dog_index]["kind"])
	var cell: int = int(g.dogs[dog_index]["cell"])
	g.skill_flashes[cell] = g.presentation_clock
	g._sound(["element_hidden_star","element_hidden_void","element_hidden_dream"][kind-49])
	g._push_combat_fx({"from":g._cell_center(cell),"to":point,"style":["star","void","dream"][kind-49],"skill":skill,"kind":kind,"age":0.0,"duration":2.2,"apparition":false})
static func attack(g: Control, index: int, target: int, auras: Dictionary) -> void:
	var dog: Dictionary = g.dogs[index]
	var kind: int = int(dog["kind"])
	var damage: float = float(g.ATTACK[kind])*g._tier_damage_scale(kind)*(1.0+float(auras["damage"]))*(1.0+float(auras.get("magic",0.0)))
	var point: Vector2 = g._route_point(float(g.enemies[target]["progress"]))
	g._hit_enemy(target,damage,true)
	var charge: int = int(dog.get("hidden_charge",0))+1
	var required: int = [5,4,6][kind-49]
	dog["hidden_charge"] = charge % required
	if charge < required: return
	emit(g,index,point,["star_collapse","void_rift","dream_resonance"][kind-49])
	if kind == 49:
		var chain: int = 0
		for i in range(g.enemies.size()):
			if float(g.enemies[i]["hp"])<=0: continue
			var distance: float = point.distance_to(g._route_point(float(g.enemies[i]["progress"])))
			if distance <= 140.0: g._hit_enemy(i,damage*2.8,true)
			elif chain < 2:
				g._hit_enemy(i,damage*0.8,true)
				chain += 1
	elif kind == 50:
		g.hidden_zones.append({"progress":float(g.enemies[target]["progress"]),"time":3.0,"pulse":0.5,"damage":damage*0.35})
	else:
		var center: Vector2 = g._cell_center(int(dog["cell"]))
		for ally in g.dogs:
			if center.distance_to(g._cell_center(int(ally["cell"])))<=185:
				ally["dream_time"] = 4.0
		# Resonance pulse also damages enemies near the target.
		for i in range(g.enemies.size()):
			if point.distance_to(g._route_point(float(g.enemies[i]["progress"])))<=120:
				g._hit_enemy(i,damage*1.2,true)
static func tick(g: Control, delta: float) -> void:
	for dog in g.dogs:
		if dog.has("dream_time"): dog["dream_time"] = maxf(0.0,float(dog["dream_time"])-delta)
	for z in range(g.hidden_zones.size()-1,-1,-1):
		var zone: Dictionary = g.hidden_zones[z]
		var active: float = minf(delta,float(zone["time"]))
		zone["time"] = maxf(0.0,float(zone["time"])-delta)
		zone["pulse"] = float(zone["pulse"])-active
		while float(zone["pulse"])<=0.000001:
			zone["pulse"] = float(zone["pulse"])+0.5
			var point: Vector2 = g._route_point(float(zone["progress"]))
			for i in range(g.enemies.size()):
				if point.distance_to(g._route_point(float(g.enemies[i]["progress"])))>125: continue
				g._hit_enemy(i,float(zone["damage"]),true)
				g._apply_status(i,"slow",0.6,0.15 if bool(g.enemies[i].get("is_boss",false)) else 0.35)
		if float(zone["time"])<=0.0: g.hidden_zones.remove_at(z)
static func draw(canvas: CanvasItem, fx: Dictionary, g: Control) -> void:
	var p: float = clampf(float(fx["age"])/float(fx["duration"]),0,1)
	var alpha: float = minf(1.0,(1.0-p)*2.0)
	var point: Vector2 = fx["to"]
	var kind: int = int(fx["kind"])
	var color: Color = [Color("#8eeaff"),Color("#bb83ff"),Color("#ffb3de")][kind-49]
	var radius: float = 50.0+sin(p*PI)*100.0
	canvas.draw_circle(point,radius,Color(color,alpha*0.08))
	for ring in range(3):
		canvas.draw_arc(point,radius*(0.55+ring*0.22),p*5.0+ring,p*5.0+ring+TAU*0.85,64,Color(color,alpha*0.8),4.0-ring,true)
	var from: Vector2 = fx["from"]
	var pos: Vector2 = from.lerp(point,minf(1.0,p*2.5))
	g.sky_art.draw_character(canvas,g._dog_portrait(kind),pos,130.0+sin(p*PI)*70,Color(1,1,1,alpha*0.65))
	if kind == 49:
		for i in range(12):
			var ray := Vector2.from_angle(TAU*i/12.0+p*1.6)
			var end: Vector2 = point+ray*radius
			canvas.draw_line(point+ray*radius*0.35,end,Color(color,alpha),3.0,true)
			canvas.draw_circle(end,4,Color(1,1,1,alpha))
			canvas.draw_line(end-Vector2(9,0),end+Vector2(9,0),Color(color,alpha),2.0,true)
			canvas.draw_line(end-Vector2(0,9),end+Vector2(0,9),Color(color,alpha),2.0,true)
		canvas.draw_line(point+Vector2(0,-260),point,Color(color,alpha*0.2),34,true)
		canvas.draw_line(point+Vector2(0,-260),point,Color(1,1,1,alpha),7,true)
	elif kind == 50:
		canvas.draw_circle(point,radius*0.38,Color(0.06,0.02,0.15,alpha))
		for arm in range(5):
			var points := PackedVector2Array()
			for j in range(28):
				var t: float = float(j)/27
				points.append(point+Vector2.from_angle(arm*TAU/5+t*4-p*7)*radius*t)
			canvas.draw_polyline(points,Color(color,alpha),3.5,true)
	else:
		for i in range(18):
			var ray := Vector2.from_angle(i*TAU/18+p*2)
			var center: Vector2 = point+ray*radius
			var side: Vector2 = ray.orthogonal()*8
			canvas.draw_colored_polygon(PackedVector2Array([center-ray*15,center+side,center+ray*15,center-side]),Color(color,alpha))
		var origin: Vector2 = fx["from"]
		canvas.draw_arc(origin,185,0,TAU,80,Color(color,alpha*0.5),4,true)
