class_name BattleSpace
extends RefCounted
## Shared spatial facade. Preserve scenario overrides and existing sight algorithms.


static func center(f: Figure) -> Vector3:
	return Vector3(f.pos.x,f.elevation,f.pos.y)


static func edge_distance(a: Figure,b: Figure) -> float:
	var special: Variant=RuleHooks.first("range",[a,b])
	if special!=null:
		return float(special)
	return maxf(0.0,center(a).distance_to(center(b))-2.0*Figure.BASE_RADIUS)


static func sight(board: Board,a: Figure,b: Figure) -> LineOfSight.Result:
	return LineOfSight.check_figures(board,a,b)


static func contact(a: Figure,b: Figure) -> bool:
	return Contact.figures_touch(a,b)


static func movement(c: GameController,mode: String="move") -> BattleMovementOptions:
	return c.movement_options(mode)
