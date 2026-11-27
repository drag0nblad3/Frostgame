class_name BeastDetails
extends RefCounted
## Bold species-specific details attached to neck or static body as appropriate.
const BONE := Color("c6bba3")


static func decorate(root: Node3D,id: String) -> void:
	var bear := id=="bear"
	var boar := id=="boar"
	var cat := id=="snow_leopard"
	var rat := id=="giant_rat"
	var dog := id in ["war_hound","wild_dog"]
	var fur := Color("777b7b") if id=="wolf" else (Color("c6c8c1") if cat else Color("665044"))
	if rat:
		fur=Color("676268")
	elif dog:
		fur=Color("987759") if id=="war_hound" else Color("796b5b")
	var bulk := 1.28 if bear else (1.10 if boar else (0.73 if rat else 1.0))
	var height := 0.54 if bear else (0.44 if boar or rat else 0.56)
	var width := 0.33 if bear or boar else (0.24 if cat else 0.22)
	# Larger overlapping tufts give the winter coat a layered silhouette.
	if MiniatureFactory.detail(root)>0 and not rat and not boar:
		for side: float in [-1.0,1.0]:
			for i in 5:
				var a := Vector3(side*width*0.74,height+0.20,-0.38+i*0.085)*bulk
				var b := a+Vector3(side*0.12,-0.12,0.13)*bulk
				CreatureSculpt.limb(root,a,b,0.077*bulk,fur.lightened(0.09-0.025*(i%3)),0.07)
	# A few sculpted fur planes along the shoulders rather than fine texture noise.
	for side: float in [-1.0,1.0]:
		for i in 3:
			var at := Vector3(side*width*0.83,height+0.13,-0.27+i*0.105)*bulk
			CreatureSculpt.limb(root,at,at+Vector3(side*0.075,-0.075,0.06)*bulk,0.063*bulk,fur.lightened(0.12),0.10)
		if bear or boar or id=="wolf":
			for i in 3:
				var at := Vector3(side*width*0.78,height+0.07,0.18+i*0.07)*bulk
				CreatureSculpt.limb(root,at,at+Vector3(side*0.06,-0.07,0.065)*bulk,0.056*bulk,fur.darkened(0.12),0.15)
	var head := Vector3(0,height+(0.10 if bear or dog else 0.045),-0.49)*bulk
	var pivot := root.get_node_or_null("Head") as Node3D
	var first := root.get_child_count()
	for side: float in [-1.0,1.0]:
		var brow := head+Vector3(side*0.12,0.09,-0.13)*bulk
		MiniatureFactory.sphere(root,brow,Vector3(0.11,0.045,0.085)*bulk,fur.darkened(0.18))
		if cat or id=="wolf" or dog:
			MiniatureFactory.sphere(root,head+Vector3(side*0.115,-0.08,-0.15)*bulk,Vector3(0.13,0.10,0.13)*bulk,fur.lightened(0.17))
			CreatureSculpt.limb(root,head+Vector3(side*0.08,-0.095,-0.31)*bulk,head+Vector3(side*0.08,-0.14,-0.31)*bulk,0.021*bulk,BONE,0.05)
	if rat:
		for side: float in [-1.0,1.0]:
			MiniatureFactory.box(root,head+Vector3(side*0.025,-0.095,-0.46)*bulk,Vector3(0.043,0.082,0.035)*bulk,BONE)
	if pivot!=null:
		MiniaturePose.attach(root,pivot,first)
