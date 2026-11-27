class_name SnowBanks
extends RefCounted
## Bounded low-profile drifts at the foot of walls. No new terrain pieces.
## Surface samples reject ramps, voids, other structures and height changes.


static func decorate(root: Node3D,board: Board,scenario: String) -> void:
	var snow := float(VisualPalette.for_scenario(scenario).get("snow",0.86))
	if snow<0.38:
		return
	var budget := 18 if GraphicsQuality.mode()==1 else 30
	for p in board.pieces:
		if budget<=0:
			return
		if p.ramp or p.cast_turn>=0 or p.kind.ground_surface or not p.kind.blocks_move or p.kind.height<1.5:
			continue
		var rect := p.rect
		for side in 4:
			if budget<=0:
				return
			var along := 0.28+0.44*float(posmod(roundi(rect.position.x*11+rect.position.y*7)+side*13,19))/18.0
			var at := Vector2(lerpf(rect.position.x,rect.end.x,along),rect.position.y-0.44) if side==0 else (Vector2(rect.end.x+0.44,lerpf(rect.position.y,rect.end.y,along)) if side==1 else (Vector2(lerpf(rect.position.x,rect.end.x,along),rect.end.y+0.44) if side==2 else Vector2(rect.position.x-0.44,lerpf(rect.position.y,rect.end.y,along))))
			if not EnvironmentDressing.flat_ground(board,at,0.31):
				continue
			var y := board.ground_height_at(at)
			var tint := Color("c0d1dc").lerp(Color("e2ebef"),snow*0.55)
			# Flattened, irregular drift (maximum 0.10 high), not cover.
			var size := Vector3(0.58,0.09,0.34) if side%2==0 else Vector3(0.34,0.09,0.58)
			MiniatureFactory.sphere(root,Vector3(at.x,y+0.035,at.y),size,tint)
			MiniatureFactory.sphere(root,Vector3(at.x,y+0.016,at.y),size*Vector3(1.04,0.48,1.04),tint.darkened(0.07))
			budget-=1
