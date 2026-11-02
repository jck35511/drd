extends RefCounted
# Layered, skill-specific effects. Cosmetic geometry never enters combat calculations.
const COLORS := {"crit":"#fff19a","heavy":"#ffba6a","multi":"#d0f5ff","bleed":"#ff6385","armor":"#ffb466","slow":"#91c7ff","stun":"#ffe78b","area_stun":"#d8a3ff","hp_percent":"#ec73b6","splash":"#ffc375","magic_splash":"#d49cff","magic_res":"#a9a0ff","freeze":"#b1ffff","chain":"#b9ddff","burn":"#ff954b","vulnerable":"#ff77bb","poison":"#b4ff70","attack_aura":"#ffce68","speed_aura":"#71eaff","magic_aura":"#d5a0ff","cooldown_aura":"#8fffc1"}
static func glow(canvas: CanvasItem, center: Vector2, radius: float, color: Color, alpha: float) -> void:
	for layer in range(4,0,-1):
		var fraction: float = float(layer)/4.0
		canvas.draw_circle(center,radius*fraction,Color(color,alpha*(1.0-fraction*0.65)*0.22))
static func star(canvas: CanvasItem, center: Vector2, radius: float, color: Color, rotation: float=0.0, tips: int=5) -> void:
	var points := PackedVector2Array()
	for i in range(tips*2):
		var distance: float = radius if i%2==0 else radius*0.38
		points.append(center+Vector2.from_angle(rotation+TAU*float(i)/float(tips*2))*distance)
	canvas.draw_colored_polygon(points,color)
static func crack(canvas: CanvasItem, center: Vector2, radius: float, color: Color, p: float) -> void:
	for i in range(6):
		var ray := Vector2.from_angle(TAU*float(i)/6.0+0.25)
		var across := ray.orthogonal()
		var points := PackedVector2Array([center+ray*8,center+ray*radius*0.45+across*8,center+ray*radius*0.62-across*5,center+ray*radius])
		canvas.draw_polyline(points,Color(color,0.2*(1.0-p)),8.0,true)
		canvas.draw_polyline(points,color,2.5,true)
static func draw(canvas: CanvasItem, fx: Dictionary, game: Control) -> void:
	var p: float = clampf(float(fx["age"])/maxf(0.01,float(fx["duration"])),0.0,1.0)
	var skill: String = fx["skill"]
	var origin: Vector2 = fx["from"]
	var target: Vector2 = fx["to"]
	var kind: int = int(fx.get("kind",36))
	var tier_scale: float = 1.25 if kind>=46 else 1.12 if kind>=42 else 1.0 if kind>=36 else 0.72
	var alpha: float = minf(1.0,(1.0-p)*2.4)
	var color := Color(COLORS.get(skill,"#e3bbff"))
	# Elemental characters tint their magic without losing the skill's visual identity.
	if skill=="magic_splash":
		if kind==42: color=Color("#a0ffff")
		elif kind==47: color=Color("#fff1b0")
	if skill=="burn" and kind==45: color=Color("#ff8ed8")
	var ink := Color(color,alpha)
	var white := Color(1,1,1,alpha)
	var radius: float = (26.0+sqrt(p)*52.0)*tier_scale
	var aura: bool = skill.ends_with("_aura")
	glow(canvas,target,radius*1.15,color,alpha)
	# Sparks and double shock rings give the initial hit volume and depth.
	if not aura:
		canvas.draw_arc(target,radius*0.8,0,TAU,40,Color(color,alpha*0.65),4.0,true)
		canvas.draw_arc(target,radius,0,TAU,40,Color(color,alpha*0.35),2.0,true)
		for i in range(12 if kind>=36 else 8):
			var angle: float = float(i)*2.399963
			var ray := Vector2.from_angle(angle)
			var distance: float = radius*(0.35+float(i%4)*0.19)
			var point: Vector2 = target+ray*distance+Vector2(0,p*p*18)
			canvas.draw_line(point-ray*10*tier_scale,point,ink,2.5,true)
			canvas.draw_circle(point,2.2,white)
	if skill in ["crit","heavy","hp_percent"]:
		var tilt: float = -0.7 if skill=="crit" else 0.2
		star(canvas,target,radius*0.72,Color(color,alpha*0.55),tilt,8)
		star(canvas,target,radius*0.42,white,tilt,4)
		crack(canvas,target,radius,ink,p)
		if skill=="heavy":
			canvas.draw_line(target-Vector2(0,100*tier_scale),target,Color(color,alpha*0.22),24,true)
			canvas.draw_line(target-Vector2(0,100*tier_scale),target,white,5,true)
		elif skill=="hp_percent":
			for i in range(6):
				var ray := Vector2.from_angle(TAU*i/6.0)
				canvas.draw_colored_polygon(PackedVector2Array([target+ray*radius,target+ray*radius*0.45+ray.orthogonal()*7,target+ray*radius*0.45-ray.orthogonal()*7]),ink)
	elif skill in ["bleed","multi"]:
		var count: int = 3 if skill=="bleed" else 5
		for i in range(count):
			var active: float = clampf(p*4-float(i)*0.25,0.0,1.0)
			if active<=0: continue
			var base: Vector2 = target+Vector2(float(i-count/2)*14,0)
			var vector := Vector2(0.65,-0.76) if i%2==0 or skill=="bleed" else Vector2(-0.7,-0.7)
			canvas.draw_line(base-vector*radius*0.65,base+vector*radius*0.65,Color(color,alpha*0.35),13,true)
			canvas.draw_line(base-vector*radius*0.65,base+vector*radius*0.65,white,3.5,true)
			if skill=="bleed":
				canvas.draw_circle(base+Vector2(0,20+p*42),5.0*(1.0-p),ink)
	elif skill in ["armor","magic_res"]:
		# Two broken shield halves and metal/mana fragments.
		for side in [-1,1]:
			var shift := Vector2(float(side)*(4+p*30),0)
			var shield := PackedVector2Array([target+shift+Vector2(0,-35),target+shift+Vector2(side*27,-24),target+shift+Vector2(side*23,12),target+shift+Vector2(0,38),target+shift+Vector2(side*5,5),target+shift+Vector2(side*-3,-8)])
			canvas.draw_colored_polygon(shield,Color(color,alpha*0.32))
			canvas.draw_polyline(shield,ink,3.5,true)
		crack(canvas,target,radius,white,p)
	elif skill in ["stun","area_stun"]:
		var count: int = 5 if skill=="area_stun" else 3
		for i in range(count):
			var angle: float = TAU*float(i)/float(count)+p*4
			var pos: Vector2 = target+Vector2(cos(angle)*radius*0.6,sin(angle)*radius*0.3-20)
			star(canvas,pos,11*tier_scale,ink,angle)
		if skill=="area_stun":
			for ring in range(3):
				canvas.draw_arc(target,radius*(0.4+ring*0.3),0,TAU,36,ink,3.0,true)
	elif skill in ["freeze","slow"]:
		var count: int = 8 if skill=="freeze" else 5
		for i in range(count):
			var ray := Vector2.from_angle(TAU*float(i)/float(count))
			var base: Vector2 = target+ray*radius*0.32
			var length: float = radius*(0.7 if skill=="freeze" else 0.45)
			var diamond := PackedVector2Array([base+ray*length,base+ray*length*0.4+ray.orthogonal()*10,base-ray*8,base+ray*length*0.4-ray.orthogonal()*10])
			canvas.draw_colored_polygon(diamond,Color(color,alpha*0.55))
			diamond.append(diamond[0])
			canvas.draw_polyline(diamond,white,2.0,true)
		if skill=="freeze": canvas.draw_circle(target,22,Color(color,alpha*0.25))
	elif skill=="chain":
		for fork in range(3):
			var destination: Vector2 = target+Vector2(float(fork-1)*24,float(abs(fork-1))*15)
			var points := PackedVector2Array()
			for i in range(11):
				var q: Vector2 = origin.lerp(destination,float(i)/10)
				if i>0 and i<10: q+=Vector2(sin(float(i)*17.0+floor(p*12))*16,cos(float(i)*11.0+fork)*8)
				points.append(q)
			canvas.draw_polyline(points,Color(color,alpha*0.24),14,true)
			canvas.draw_polyline(points,ink,5,true)
			canvas.draw_polyline(points,white,1.8,true)
		star(canvas,target,28*tier_scale,white,p,7)
	elif skill=="burn":
		for i in range(9):
			var phase: float = fposmod(p*1.7+float(i)*0.13,1.0)
			var base: Vector2 = target+Vector2(sin(float(i)*5)*radius*0.55,15)
			var height: float = (35+float(i%3)*16)*tier_scale*(1.0-phase*0.35)
			var flame := PackedVector2Array([base+Vector2(-13,0),base+Vector2(-9,-height*0.5),base+Vector2(sin(p*13+i)*8,-height),base+Vector2(10,-height*0.45),base+Vector2(13,0)])
			canvas.draw_colored_polygon(flame,Color(color,alpha*0.55))
			canvas.draw_line(base,base+Vector2(0,-height*0.5),Color(Color("#fff1ad"),alpha),4,true)
	elif skill=="poison":
		canvas.draw_circle(target,32*tier_scale,Color(color,alpha*0.2))
		for i in range(10):
			var phase: float = fposmod(p+float(i)*0.09,1.0)
			var bubble: Vector2 = target+Vector2(sin(float(i)*7)*radius*0.6,20-phase*80)
			var size: float = 4+float(i%4)*2
			canvas.draw_circle(bubble,size,Color(color,alpha*0.4))
			canvas.draw_arc(bubble,size,0,TAU,16,ink,1.5,true)
			canvas.draw_circle(bubble+Vector2(-2,-2),1.7,white)
	elif skill=="vulnerable":
		for i in range(4):
			var angle: float = TAU*i/4.0+p
			canvas.draw_arc(target,radius*0.65,angle,angle+0.8,12,ink,5,true)
		canvas.draw_line(target-Vector2(17,17),target+Vector2(17,17),white,5,true)
		canvas.draw_line(target-Vector2(-17,17),target+Vector2(-17,17),white,5,true)
	elif aura:
		for i in range(2):
			canvas.draw_arc(target,radius*(0.4+i*0.22),p*3+i*PI,p*3+i*PI+TAU*0.85,40,ink,3,true)
		for i in range(6):
			var pos: Vector2 = target+Vector2.from_angle(p*3+TAU*i/6.0)*radius*0.7
			star(canvas,pos,6,white,p,4)
	else: # Physical shockwave or elemental magical detonation.
		for i in range(3):
			var ring: float = maxf(1.0,radius*(1.0-float(i)*0.22))
			canvas.draw_arc(target,ring,0,TAU,40,Color(color,alpha*(0.75-i*0.15)),5.0-float(i),true)
		star(canvas,target,radius*0.5,Color(1,1,1,alpha*0.7),p,8)
		if skill=="magic_splash":
			canvas.draw_line(target-Vector2(0,120*tier_scale),target,Color(color,alpha*0.22),35*tier_scale,true)
			canvas.draw_line(target-Vector2(0,120*tier_scale),target,white,5*tier_scale,true)
	game.sky_art.draw_legendary_skill(canvas,fx)
	if p<0.8:
		var label: String = str(game.SKILL_NAMES.get(skill,skill))
		var font: Font = game.ui_theme.default_font
		var pos: Vector2 = target+Vector2(-36,-60-p*16)
		pos.x = clampf(pos.x,8,580)
		pos.y = maxf(104,pos.y)
		canvas.draw_string_outline(font,pos,label,HORIZONTAL_ALIGNMENT_LEFT,-1,22,5,Color(0.05,0.07,0.15,alpha))
		canvas.draw_string(font,pos,label,HORIZONTAL_ALIGNMENT_LEFT,-1,22,white)
