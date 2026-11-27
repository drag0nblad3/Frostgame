class_name BakedMapAssets
extends RefCounted
## Immutable art bundles. Exact terrain fingerprints prevent stale checkpoint
## geometry from being substituted for changed gameplay terrain.
const DIR := "res://assets/baked_maps/"
const VERSION := 1
const STATIC_KINDS := ["ruin","wall","rubble","platform","tower","museum_statue","dreams_well","library_shelf","haunted_floor","hut_wall","arcane_disc","null_annex","null_walk","null_lower","null_middle","null_upper","temple_column"]


static func city_path(board: Board,scenario: String,cinematic: bool) -> String:
	var key := str([VERSION,board.size,scenario,cinematic,GraphicsQuality.mode()]).sha256_text().substr(0,16)
	return DIR+"city_"+scenario+"_"+key+".scn"


static func terrain_path(board: Board,scenario: String) -> String:
	var keys: Array[String]=[]
	for p in board.pieces:
		keys.append(piece_key(p)+":"+str(p.cast_turn))
	var key := str([VERSION,board.id,board.size,scenario,GraphicsQuality.mode(),board.has_ground_profiles,board.void_regions,keys]).sha256_text().substr(0,16)
	return DIR+"terrain_"+scenario+"_"+key+".scn"


static func piece_key(p: TerrainPiece) -> String:
	return str([p.kind.id,p.kind.height,p.rect,p.circular,p.ramp,p.ramp_rotated,p.ramp_start,p.ramp_end,p.level])


static func static_piece(p: TerrainPiece) -> bool:
	return not p.kind.ground_surface and p.cast_turn<0 and p.kind.id in STATIC_KINDS


static func instance(path: String) -> Node3D:
	if not ResourceLoader.exists(path,"PackedScene"):
		return null
	var scene := ResourceLoader.load(path,"PackedScene") as PackedScene
	if scene==null:
		return null
	return scene.instantiate() as Node3D


static func take(parent: Node,child_name: String) -> Node3D:
	var node := parent.get_node_or_null(child_name) as Node3D
	if node!=null:
		parent.remove_child(node)
	return node
