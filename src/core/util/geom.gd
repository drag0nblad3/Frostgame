class_name Geom
extends RefCounted
## 2D table geometry in inches: segments against axis-aligned terrain footprints.


## Parameter range [t0, t1] of segment a→b inside `r`, or empty if it misses.
## Liang–Barsky clipping.
static func clip(a: Vector2, b: Vector2, r: Rect2) -> PackedFloat32Array:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x - r.position.x, r.end.x - a.x, a.y - r.position.y, r.end.y - a.y]
	for i in 4:
		if is_zero_approx(p[i]):
			if q[i] < 0.0:
				return PackedFloat32Array()
			continue
		var t: float = q[i] / p[i]
		if p[i] < 0.0:
			t0 = maxf(t0, t)
		else:
			t1 = minf(t1, t)
		if t0 > t1:
			return PackedFloat32Array()
	return PackedFloat32Array([t0, t1])


static func crosses(a: Vector2, b: Vector2, r: Rect2) -> bool:
	var c := clip(a, b, r)
	return c.size() == 2 and c[1] - c[0] > 0.0001


## Length of segment a→b that lies inside `r`.
static func length_inside(a: Vector2, b: Vector2, r: Rect2) -> float:
	var c := clip(a, b, r)
	if c.size() != 2:
		return 0.0
	return (c[1] - c[0]) * a.distance_to(b)


## Distance from point to rectangle (0 when inside).
static func point_rect_distance(p: Vector2, r: Rect2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dy).length()


## Total length of a polyline path.
static func path_length(path: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total
