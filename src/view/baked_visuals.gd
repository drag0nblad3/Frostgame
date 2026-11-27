class_name BakedVisuals
extends RefCounted
## Optional build-time PackedScenes. The procedural source remains authoritative.
const DIR := "res://assets/baked/"


static func load_scene(path: String) -> Node3D:
	if not ResourceLoader.exists(path,"PackedScene"):
		return null
	var scene := ResourceLoader.load(path,"PackedScene") as PackedScene
	if scene==null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance!=null:
		instance.set_meta("baked_visual",true)
		# Keep the resource alive only while an instance needs it, allowing
		# ResourceLoader to share immutable meshes without a global memory cache.
		instance.set_meta("_baked_source",scene)
	return instance
