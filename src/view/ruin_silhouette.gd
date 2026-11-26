class_name RuinSilhouette
extends RefCounted
## Banded stonework and decorative pilasters, below all logical standing surfaces.


static func decorate(root: Node3D, p: TerrainPiece) -> void:
	var rect := p.rect
	var h := p.kind.height
	var decor := Node3D.new()
	root.add_child(decor)
	var stone := Color(0.32,0.39,0.44)
	var trim := Color(0.56,0.63,0.67)
	var bands: Array[float] = [0.15]
	if h > 1.5:
		bands.append(h-0.36)
	if h > 4.5:
		bands.append(h*0.5)
	for y in bands:
		for side: float in [-1.0,1.0]:
			MiniatureFactory.box(decor,Vector3(rect.get_center().x,y,rect.get_center().y+side*(rect.size.y*0.5-0.03)),Vector3(maxf(0.05,rect.size.x-0.06),0.14,0.07),trim)
			MiniatureFactory.box(decor,Vector3(rect.get_center().x+side*(rect.size.x*0.5-0.03),y,rect.get_center().y),Vector3(0.07,0.14,maxf(0.05,rect.size.y-0.06)),trim)
	if h >= 1.5 and minf(rect.size.x,rect.size.y)>0.8:
		for side: float in [-1.0,1.0]:
			_pilasters(decor,rect,h,side,false,stone,trim)
			_pilasters(decor,rect,h,side,true,stone,trim)
	MiniatureBatch.bake(decor)


static func _pilasters(root: Node3D, rect: Rect2, h: float, side: float, swapped: bool, stone: Color, trim: Color) -> void:
	var span := rect.size.y if swapped else rect.size.x
	var n := maxi(2,ceili(span/2.4))
	for i in n:
		var u := lerpf(0.13,span-0.13,float(i)/float(n-1))
		var pos := Vector3(rect.get_center().x+side*(rect.size.x*0.5-0.035),h*0.45,rect.position.y+u) if swapped else Vector3(rect.position.x+u,h*0.45,rect.get_center().y+side*(rect.size.y*0.5-0.035))
		var width := Vector3(0.08,h*0.72,0.20) if swapped else Vector3(0.20,h*0.72,0.08)
		MiniatureFactory.box(root,pos,width,stone)
		var cap := Vector3(0.10,0.15,0.28) if swapped else Vector3(0.28,0.15,0.10)
		MiniatureFactory.box(root,Vector3(pos.x,h*0.81,pos.z),cap,trim)
