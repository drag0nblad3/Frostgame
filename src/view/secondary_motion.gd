class_name SecondaryMotion
extends RefCounted
## Absolute secondary joint poses; no cumulative drift or gameplay state.


static func _part(root: Node3D,id: String,angles: Vector3) -> void:
	var part := root.get_node_or_null(id) as Node3D
	if part!=null:
		part.rotation=angles


static func reset(root: Node3D) -> void:
	for id in ["Cape","CoatHem","Head","Tail","WingL","WingR"]:
		_part(root,id,Vector3.ZERO)
	for i in 9:
		_part(root,"Segment%d"%i,Vector3.ZERO)
		_part(root,"Tendril%d"%i,Vector3.ZERO)


static func arm_spread(root: Node3D,right: float,left: float) -> void:
	var r := root.get_node_or_null("RightArm") as Node3D
	var l := root.get_node_or_null("LeftArm") as Node3D
	if r!=null:
		r.rotation.z=right
	if l!=null:
		l.rotation.z=left


static func travel(root: Node3D,kind: String,phase: float,running: bool) -> void:
	var wave := sin(phase)
	var pace := 1.6 if running else 1.0
	_part(root,"Cape",Vector3(-0.11*pace-0.045*cos(phase-0.5),0.045*wave,0.06*wave))
	_part(root,"CoatHem",Vector3(-0.035*pace,0.045*sin(phase-0.7),0.025*wave))
	if kind not in ["trot","heavy"]:
		_part(root,"Head",Vector3(0.035*cos(phase),0.035*wave,-0.02*wave))
	if kind=="float":
		_wings(root,phase,0.25)
		_tendrils(root,phase,0.20)
	if kind=="slither":
		for i in 9:
			_part(root,"Segment%d"%i,Vector3(0.07*sin(phase-i*0.38),0.12*cos(phase-i*0.38),0.10*sin(phase-i*0.42)))


static func idle(root: Node3D,kind: String,phase: float,rest: float) -> void:
	var breath := sin(phase)
	root.position.y=rest+(0.055*breath if kind=="float" else 0.009*breath)
	root.rotation.x=0.015*breath
	root.rotation.z=0.012*cos(phase)
	_part(root,"Cape",Vector3(0.025*breath,0.02*cos(phase),0.025*breath))
	_part(root,"Head",Vector3(0.025*breath,0.075*sin(phase*0.63),0))
	_part(root,"Tail",Vector3(0.035*breath,0.11*cos(phase),0))
	if kind=="float":
		_wings(root,phase*1.8,0.16)
		_tendrils(root,phase,0.12)
	elif kind=="slither":
		for i in 9:
			_part(root,"Segment%d"%i,Vector3(0.045*sin(phase-i*0.3),0,0.055*cos(phase-i*0.3)))


static func action(root: Node3D,kind: String,act: String,t: float) -> void:
	_part(root,"Cape",Vector3(-0.14*t,0.08*t,0.055*t))
	_part(root,"CoatHem",Vector3(-0.055*t,0.04*t,0))
	_part(root,"Head",Vector3(0.08*t if act=="attack" else -0.07*t,0,0))
	if kind=="float":
		_wings(root,t*PI,0.35*absf(t))
		_tendrils(root,t*PI,0.28*absf(t))
	elif kind=="slither":
		for i in 9:
			_part(root,"Segment%d"%i,Vector3(-0.14*t*float(i)/8.0,0,0))
	elif kind=="hop" and act=="attack":
		MiniaturePose.legs(root,[-0.25*t,0.42*t,-0.25*t,0.42*t])


static func _wings(root: Node3D,phase: float,amp: float) -> void:
	var stroke := sin(phase)*amp
	_part(root,"WingL",Vector3(0,-stroke,stroke*0.45))
	_part(root,"WingR",Vector3(0,stroke,-stroke*0.45))


static func _tendrils(root: Node3D,phase: float,amp: float) -> void:
	for i in 7:
		_part(root,"Tendril%d"%i,Vector3(sin(phase+i*0.7)*amp,0,cos(phase+i*0.7)*amp))
