class_name TableSpace
extends RefCounted
## Table inches ↔ world space. One inch is one world unit; table x → world x,
## table y → world z, height up.

const TABLE_TOP := 0.0


static func to_world(p: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(p.x, TABLE_TOP + height, p.y)


static func to_table(w: Vector3) -> Vector2:
	return Vector2(w.x, w.z)
