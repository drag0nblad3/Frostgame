class_name BoardLoader
extends RefCounted
## Builds a Board from data/boards/<id>.json:
## {"id", "name", "size": [w, h], "pieces": [{"kind", "rect": [x, y, w, h]}]}

const DIR := "res://data/boards/"


static func load_id(board_id: String, terrain: TerrainDb) -> Board:
	return from_dict(JsonFile.read(DIR + board_id + ".json"), terrain)


static func from_dict(d: Dictionary, terrain: TerrainDb) -> Board:
	var b := Board.new()
	b.id = d.get("id", "")
	b.name = d.get("name", b.id)
	var s: Array = d.get("size", [36, 36])
	b.size = Vector2(s[0], s[1])
	b.floor_layout = FloorAssembly.expand(d)
	var expanded:=TerrainAssembly.pieces(d)
	# Older flat boards can opt into the same physical floor graph without
	# reauthoring terrain. Uneven heightfields require explicit conversion.
	if b.floor_layout.is_empty() and (bool(d.get("shared_climbing",false)) or bool(d.get("shared_profiled_climbing",false))):
		var compatible:=true
		var profiles: Array=[]
		for p: Dictionary in expanded:
			var kind:=terrain.get_kind(p["kind"])
			if kind.ground_surface and bool(d.get("shared_profiled_climbing",false)):
				var profile: Dictionary=p.duplicate(true)
				profile["stairs"]=kind.stairs
				profile["level"]=float(p.get("level",kind.height))
				profiles.append(profile)
			elif kind.ground_surface or p.has("ramp"):
				compatible=false
				break
		if compatible:
			b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,b.size.x,b.size.y],"level":0,"ground_profiles":profiles}],"exit_surfaces":["street"],"spawn_surfaces":["street"],"auto_architecture_climbs":true}
	var ground: FloorSurface=null
	for entry: Dictionary in b.floor_layout.get("surfaces",[]):
		if entry.get("id","")=="street" and not entry.get("ground_profiles",[]).is_empty():
			ground=FloorSurface.from_dict(entry)
			break
	for region: Array in d.get("void_regions",[]):
		if region.size()==4:
			b.void_regions.append(Rect2(region[0],region[1],region[2],region[3]))
	for p: Dictionary in expanded:
		var r: Array = p["rect"]
		var piece := TerrainPiece.new(terrain.get_kind(p["kind"]), Rect2(r[0], r[1], r[2], r[3]))
		piece.circular = piece.kind.id in ["arcane_disc","red_king_portal","red_king_sinkhole_orb"]
		piece.entrance = str(p.get("entrance","north"))
		piece.level = p.get("level",null)
		var profile: Dictionary = p.get("ramp",{})
		if not profile.is_empty():
			piece.ramp = true
			piece.ramp_rotated = profile.get("axis","x") == "y"
			piece.ramp_start = float(profile.get("start",0.0))
			piece.ramp_end = float(profile.get("end",0.0))
		if not b.floor_layout.is_empty():
			piece.surface_id=str(p.get("surface","street"))
			piece.base_height=float(p.get("base_height",ground.height_at(piece.rect.get_center()) if ground!=null and piece.surface_id=="street" and not piece.kind.ground_surface else 0.0))
			if piece.kind.blocks_move and not piece.kind.ground_surface:
				piece.dynamic_surface=str(p.get("id","architecture:"+str(b.pieces.size())))
				var entries: Array=b.floor_layout.get("walls",[])
				entries.append({"id":piece.dynamic_surface,"support":piece.surface_id,"height":piece.base_height,"thickness":piece.kind.height,"walkable":piece.kind.walkable_top,"rect":r.duplicate(),"architectural":true,"circular":piece.circular,"climb_across":piece.kind.id in ["ruin","hut_wall","ruin_broken_wall","ruin_timber_wall","library_gate","temple_gate","alien_rib","alien_obelisk"]})
				b.floor_layout["walls"]=entries
		b.pieces.append(piece)
	# Destructible convex wall handles are ordinary serialized TerrainPieces,
	# but have no collision or artwork of their own.
	for entry: Dictionary in b.floor_layout.get("convex_solids",[]):
		var target:=ConvexCrumble.target(entry)
		if target!=null:
			b.pieces.append(target)
	var boundaries: Array[Dictionary]=[]
	for entry: Dictionary in d.get("boundaries",[]):
		var a: Array=entry.get("a",[])
		var z: Array=entry.get("b",[])
		if a.size()!=2 or z.size()!=2:
			continue
		var line := entry.duplicate(true)
		line["a"]=Vector2(a[0],a[1])
		line["b"]=Vector2(z[0],z[1])
		if line["a"]!=line["b"]:
			boundaries.append(line)
	b.set_boundaries(boundaries)
	return b
