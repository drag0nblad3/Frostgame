class_name CombatVfx
extends RefCounted
## Short-lived, deterministic tabletop effects. No gameplay RNG, no physics,
## no persistent effects attached to a figure and no full-screen flashes.
const SCHOOLS := {
	"chronomancer":"clock", "elementalist":"burst", "enchanter":"crystal",
	"illusionist":"veil", "necromancer":"bones", "sigilist":"runes",
	"soothsayer":"eye", "summoner":"portal", "thaumaturge":"halo", "witch":"swarm"
}
const SPECIAL := {
	"elemental_shield":"ward", "shield":"ward", "mind_lock":"ward",
	"circle_of_protection":"ward", "petrify":"crystal", "bones_of_the_earth":"bones",
	"plague_of_insects":"swarm", "heal":"halo", "glow":"halo", "blinding_light":"halo",
	"teleport":"portal", "blink":"portal", "transpose":"portal", "plane_walk":"veil",
	"fog":"veil", "mud":"swarm", "wall":"crystal", "bridge":"runes",
	"explosive_rune":"runes", "grenade":"burst", "planar_tear":"portal",
	"destructive_sphere":"burst", "call_storm":"burst", "scatter_shot":"burst"
}
static var _meshes := {}


static func motif(spell: String,school: String) -> String:
	return SPECIAL.get(spell,SCHOOLS.get(school,"runes"))


static func material(color: Color) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	m.albedo_color=color
	return m


static func _mesh(kind: String) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var m: PrimitiveMesh
	match kind:
		"ring":
			var ring:=TorusMesh.new()
			ring.inner_radius=0.91
			ring.outer_radius=1.0
			ring.rings=32
			ring.ring_segments=6
			m=ring
		"sphere":
			var sphere:=SphereMesh.new()
			sphere.radius=0.5
			sphere.height=1.0
			sphere.radial_segments=12
			sphere.rings=6
			m=sphere
		"shard":
			var shard:=CylinderMesh.new()
			shard.top_radius=0.0
			shard.bottom_radius=0.5
			shard.height=1.0
			shard.radial_segments=4
			m=shard
		_:
			var box:=BoxMesh.new()
			box.size=Vector3.ONE
			m=box
	_meshes[kind]=m
	return m


static func part(root: Node3D,kind: String,at: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var n:=MeshInstance3D.new()
	n.mesh=_mesh(kind)
	n.material_override=mat
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.position=at
	n.scale=size
	root.add_child(n)
	return n


static func _effect(root: Node3D,at: Vector3) -> Node3D:
	var n:=Node3D.new()
	root.add_child(n)
	n.position=at
	return n


## Renderable motif factory, usable off-tree for tests. Each school has its
## own silhouette, not simply a recoloured copy of a universal effect.
static func motif_geometry(kind: String,color: Color) -> Node3D:
	var root:=Node3D.new()
	var mat:=material(color)
	var pale:=material(color.lightened(0.55))
	var count:=6 if GraphicsQuality.mode()==0 else 10
	match kind:
		"ward":
			part(root,"ring",Vector3(0,0.08,0),Vector3(0.83,0.16,0.83),mat)
			for i in (3 if GraphicsQuality.mode()==0 else 5):
				var angle:=PI*i/5.0
				var ring:=part(root,"ring",Vector3.UP*0.85,Vector3(0.87,0.12,0.87),pale)
				ring.rotation=Vector3(PI*0.5,angle,0)
		"clock":
			part(root,"ring",Vector3.ZERO,Vector3(1,0.13,1),mat)
			for i in 12:
				var a:=TAU*i/12.0
				var tick:=part(root,"box",Vector3(cos(a)*0.83,0.04,sin(a)*0.83),Vector3(0.045,0.025,0.18),pale)
				tick.rotation.y=-a+PI*0.5
			part(root,"box",Vector3(0,0.05,0.32),Vector3(0.05,0.025,0.64),pale)
			part(root,"box",Vector3(0.28,0.06,0),Vector3(0.56,0.025,0.05),mat)
		"portal","halo","veil","eye":
			var vertical:=kind in ["portal","eye"]
			for i in 3:
				var radius:=0.55+0.22*i
				var ring:=part(root,"ring",Vector3.UP*(0.9 if vertical else 0.15+0.38*i),Vector3(radius,0.13,radius),mat if i!=1 else pale)
				if vertical:
					ring.rotation=Vector3(PI*0.5,0.65*i,0)
			if kind=="eye":
				part(root,"sphere",Vector3.UP*0.9,Vector3(0.23,0.23,0.23),pale)
			for i in count:
				var a:=TAU*i/count
				part(root,"sphere",Vector3(cos(a)*0.78,0.3+float(i%4)*0.33,sin(a)*0.78),Vector3.ONE*0.10,pale)
		"crystal","bones","burst","swarm","runes":
			part(root,"ring",Vector3.ZERO,Vector3(0.94,0.12,0.94),mat)
			for i in count:
				var a:=TAU*i/count
				var h:=0.20+0.13*(i%3)
				var at:=Vector3(cos(a)*0.75,h,sin(a)*0.75)
				var shape: MeshInstance3D
				match kind:
					"crystal":
						shape=part(root,"shard",at,Vector3(0.20,0.55+h,0.20),pale)
					"bones":
						shape=part(root,"box",at,Vector3(0.10,0.46,0.10),pale)
						part(root,"sphere",at+Vector3.UP*0.24,Vector3.ONE*0.15,mat)
					"burst":
						shape=part(root,"shard",at,Vector3(0.14,0.72,0.14),pale)
					"swarm":
						shape=part(root,"sphere",at+Vector3.UP*(i%4)*0.27,Vector3(0.13,0.06,0.09),pale)
					_:
						shape=part(root,"box",at,Vector3(0.11,0.025,0.28),pale)
				shape.rotation=Vector3(0, -a, 0.42 if kind=="burst" else 0.0)
	return root


static func magic(root: Node3D,at: Vector3,kind: String,color: Color,radius: float=1.0,speed: float=1.0,reverse: bool=false) -> void:
	var n:=motif_geometry(kind,color)
	root.add_child(n)
	n.position=at
	n.scale=Vector3.ONE*(radius if reverse else 0.35*radius)
	var t:=n.create_tween().set_parallel(true).set_speed_scale(speed)
	t.tween_property(n,"scale",Vector3.ONE*(0.05 if reverse else radius),0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(n,"rotation:y",(-1.0 if reverse else 1.0)*PI*0.65,1.05)
	var mats: Dictionary={}
	for child in n.get_children():
		if child is MeshInstance3D:
			mats[child.material_override]=true
	for m: StandardMaterial3D in mats:
		t.tween_property(m,"albedo_color:a",0.0,0.4).set_delay(0.65)
	t.chain().tween_callback(n.queue_free)


## Tapered curved swipe or narrow straight thrust, in the attack's plane.
static func weapon_arc(weapon: String) -> ArrayMesh:
	var thrust:=weapon in ["dagger","staff","natural","unarmed"]
	var heavy:=weapon=="two_handed"
	var s:=SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments:=12
	for i in segments:
		var a:=float(i)/segments
		var b:=float(i+1)/segments
		var p:=_arc_point(a,thrust,heavy)
		var q:=_arc_point(b,thrust,heavy)
		var width_a:=sin(PI*a)*(0.18 if heavy else 0.10)
		var width_b:=sin(PI*b)*(0.18 if heavy else 0.10)
		for v: Vector3 in [p+Vector3.UP*width_a,p-Vector3.UP*width_a,q+Vector3.UP*width_b,q+Vector3.UP*width_b,p-Vector3.UP*width_a,q-Vector3.UP*width_b]:
			s.add_vertex(v)
	return s.commit()


static func _arc_point(t: float,thrust: bool,heavy: bool) -> Vector3:
	if thrust:
		return Vector3(0.0,0.10*sin(t*PI),lerpf(0.22,-0.95,t))
	var a:=lerpf(-1.15,1.15,t)
	var radius:=1.12 if heavy else 0.83
	return Vector3(sin(a)*radius,cos(a)*0.28,-cos(a)*radius)


static func strike(root: Node3D,at: Vector3,direction: Vector3,weapon: String,critical: bool,speed: float) -> void:
	var n:=_effect(root,at)
	if direction.length_squared()>0.001:
		n.look_at(at+direction.normalized())
	var mat:=material(Color("ffe0a1") if critical else Color("d4e1e8"))
	var slash:=MeshInstance3D.new()
	slash.mesh=weapon_arc(weapon)
	slash.material_override=mat
	slash.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(slash)
	var t:=n.create_tween().set_parallel(true).set_speed_scale(speed)
	t.tween_property(n,"scale",Vector3.ONE*1.28,0.32)
	t.tween_property(mat,"albedo_color:a",0.0,0.35)
	t.chain().tween_callback(n.queue_free)


static func sparks(root: Node3D,at: Vector3,color: Color,radius: float,speed: float,up: float=0.7) -> void:
	var n:=_effect(root,at)
	var mat:=material(color)
	var t:=n.create_tween().set_parallel(true).set_speed_scale(speed)
	var count:=5 if GraphicsQuality.mode()==0 else (10 if GraphicsQuality.mode()==1 else 15)
	for i in count:
		var a:=TAU*i/count
		var d:=Vector3(cos(a),up+float(i%3)*0.15,sin(a))
		var shard:=part(n,"shard",Vector3.ZERO,Vector3(0.07,0.25,0.07),mat)
		shard.quaternion=Quaternion(Vector3.UP,d.normalized())
		t.tween_property(shard,"position",d*radius,0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(shard,"scale",Vector3.ZERO,0.65)
	t.tween_property(mat,"albedo_color:a",0.0,0.35).set_delay(0.3)
	t.chain().tween_callback(n.queue_free)


static func flash(root: Node3D,at: Vector3,color: Color,radius: float,speed: float) -> void:
	var n:=_effect(root,at)
	var mat:=material(Color(color.r,color.g,color.b,0.65))
	var core:=part(n,"sphere",Vector3.ZERO,Vector3.ONE*0.18,mat)
	var t:=n.create_tween().set_parallel(true).set_speed_scale(speed)
	t.tween_property(core,"scale",Vector3.ONE*radius,0.22)
	t.tween_property(mat,"albedo_color:a",0.0,0.34)
	t.chain().tween_callback(n.queue_free)


static func shot_impact(root: Node3D,at: Vector3,color: Color,damaging: bool,magic_shot: bool,spell: String,speed: float) -> void:
	var tint:=color if damaging else Color("b3c9d6")
	flash(root,at,tint,0.7 if magic_shot else 0.35,speed)
	sparks(root,at,tint,1.2 if magic_shot else 0.65,speed)
	if magic_shot:
		magic(root,at,"burst" if spell=="elemental_ball" else "runes",tint,1.35 if spell=="elemental_ball" else 0.65,speed)
	elif not damaging:
		magic(root,at-Vector3.UP*0.35,"ward",tint,0.45,speed)
