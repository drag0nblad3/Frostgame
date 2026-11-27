class_name ExteriorMotifs
extends RefCounted
## Scenario silhouettes are assembled directly into each district's static
## batch. Keep each motif within a 4-inch horizontal envelope.

static func build(root: Node3D,kind: String,at: Vector3,tone: Color,side: int,seed: int) -> void:
	var stone:=tone.darkened(0.12)
	var trim:=tone.lightened(0.26)
	var wood:=Color("635044").lerp(tone,0.25)
	match kind:
		"tree":
			EnvironmentVegetation.tree(root,at,seed,seed%3!=0)
		"crate":
			EnvironmentProps.crate(root,at,0.86)
			EnvironmentProps.barrel(root,at+Vector3(1.1,0,0.4),0.9)
		"debris","ruin":
			ExteriorStructures.ruin(root,at,stone,trim,kind=="ruin",seed)
		"gate","hall","tower","tall_tower":
			var site:=Node3D.new()
			root.add_child(site)
			site.position=at
			site.rotation.y=side*PI*0.5
			if kind=="gate":
				SkylineLandmarks._gate(site,stone,trim)
			elif kind=="hall":
				SkylineLandmarks._hall(site,stone,trim)
			else:
				SkylineLandmarks._turret(site,stone,trim)
				if kind=="tall_tower":
					site.scale.y=1.45
		"wall","fortress","watchtower","palisade","fence":
			ExteriorStructures.defence(root,kind,at,stone,wood,side)
		"cabin","warehouse","tent","stall","market","windmill":
			ExteriorStructures.dwelling(root,kind,at,stone,wood,trim,side,seed)
		"crypt","mausoleum","colonnade","gallery","shrine","burned_shrine","archive":
			ExteriorStructures.monument(root,kind,at,stone,trim,side)
		"graveyard":
			for i in 4:
				var p:=at+Vector3((i-1.5)*0.85,0,0.32*sin(i+seed))
				MiniatureFactory.box(root,p+Vector3.UP*0.10,Vector3(0.63,0.20,0.95),stone.darkened(0.16))
				MiniatureFactory.box(root,p+Vector3(0,0.60,-0.34),Vector3(0.46,0.88,0.18),trim)
				MiniatureFactory.sphere(root,p+Vector3(0,1.02,-0.34),Vector3(0.46,0.36,0.18),trim)
		"statue","plinth","obelisk","pillar","basin","brazier":
			ExteriorStructures.ornament(root,kind,at,stone,trim)
		"shelf":
			ExteriorStructures.shelves(root,at,wood,side,seed)
		"quay","bridge":
			ExteriorLandforms.quay(root,kind,at,stone,trim,side)
		"ice","drift","ice_ridge":
			ExteriorLandforms.ice(root,kind,at,seed)
		"floating","shard","memory","pyramid","tether","broken_bridge","ring":
			ExteriorLandforms.realm(root,kind,at,stone,trim,seed,side)
		_:
			ExteriorStructures.ruin(root,at,stone,trim,false,seed)
