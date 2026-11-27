class_name RuinedFacade
extends RefCounted
## Surface relief only: every new ornament is flush to a wall, below its top.
## Different building types remain mechanically identical to their original pieces.


static func style(p: TerrainPiece,scenario: String) -> int:
	if p.kind.id=="hut_wall" or scenario=="haunted_houses":
		return 2
	if p.kind.id.begins_with("null_") or p.kind.id=="tower" or scenario=="silent_tower":
		return 3
	if scenario in ["complex_temple","living_museum","mausoleum","red_king_back_into_fire"]:
		return 1
	return 0


static func decorate(root: Node3D,p: TerrainPiece,scenario: String) -> void:
	if GraphicsQuality.mode()==0 or p.ramp or p.kind.height<1.7 or p.level!=null:
		return
	var r := p.rect
	var h := p.kind.height
	var variant := style(p,scenario)
	var detail := Node3D.new()
	root.add_child(detail)
	var trim := Color("a4adb0") if variant!=1 else Color("b0a28c")
	var dark := Color("48545b") if variant!=2 else Color("655140")
	# Recessed-looking relief is sealed masonry, not an apparent doorway.
	for swap in [false,true]:
		var span := r.size.y if swap else r.size.x
		var depth := r.size.x if swap else r.size.y
		if span<1.7 or depth<0.14:
			continue
		var count := clampi(floori(span/2.8),1,3)
		for side: float in [-1.0,1.0]:
			for i in count:
				var along := (i+0.5)*span/count
				var pos := Vector3(r.get_center().x+side*(r.size.x*0.5-0.018),h*0.63,r.position.y+along) if swap else Vector3(r.position.x+along,h*0.63,r.get_center().y+side*(r.size.y*0.5-0.018))
				var width := minf(0.52,span/count*0.42)
				var plaque := Vector3(0.06,0.44,width) if swap else Vector3(width,0.44,0.06)
				if variant==1:
					MiniatureFactory.box(detail,pos,plaque,trim.darkened(0.12))
					MiniatureFactory.box(detail,pos+Vector3.UP*0.24,Vector3(0.07,0.08,width*1.25) if swap else Vector3(width*1.25,0.08,0.07),trim)
				elif variant==3:
					MiniatureFactory.box(detail,pos,plaque,dark)
					MiniatureFactory.box(detail,pos,Vector3(0.08,0.065,width*0.8) if swap else Vector3(width*0.8,0.065,0.08),trim)
				elif variant==2:
					var board := MiniatureFactory.box(detail,pos,Vector3(0.05,0.10,width*1.2) if swap else Vector3(width*1.2,0.10,0.05),dark)
					if swap:
						board.rotation.x=0.36
					else:
						board.rotation.z=0.36
				else:
					# Broken lintel fragments set into the existing face.
					MiniatureFactory.box(detail,pos,Vector3(0.06,0.16,width) if swap else Vector3(width,0.16,0.06),trim)
	MiniatureBatch.bake(detail)
