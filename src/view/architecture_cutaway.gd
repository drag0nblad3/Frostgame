class_name ArchitectureCutaway
extends RefCounted
## Visual-only occlusion. Use the real shape where available. Keep distant
## landmarks in view and do not remove a figure's supporting floor.


static func blocks(camera_at: Vector3,focus: Vector3,bounds: AABB,prism: ArchitecturePrism=null) -> bool:
	if not bounds.grow(4.0).has_point(focus) or bounds.end.y<=focus.y-0.15:
		return false
	# A model inside its own wall volume is an illegal placement; never
	# disguise that by hiding the solid. Only actual intervening walls fade.
	if bounds.has_point(focus):
		if prism==null:
			return false
		var inside:=true
		for plane in prism.planes:
			if plane.distance_to(focus)>0.0:
				inside=false
				break
		if inside:
			return false
	# Aim slightly above the base, and stop before the focused miniature.
	var delta:=focus-camera_at
	if delta.length()<0.5:
		return false
	var end:=focus-delta.normalized()*0.1
	if prism!=null:
		return prism.intersects_ray(camera_at,end)
	return LayeredSight.intersects(camera_at,end,bounds)
