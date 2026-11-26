class_name WizardLivery
extends RefCounted
## Warband-dyed woven cloth, separate from neutral tailoring and school relics.

static func color(faction: Color) -> Color:
	return faction.lerp(Color("686461"),0.23).darkened(0.10)


static func decorate(root: Node3D,school: String,dye: Color,apprentice: bool) -> void:
	# Visible at the back and front even when the base is hidden by terrain.
	var mantle := school in ["elementalist","necromancer","thaumaturge","witch"]
	var z := 0.30 if mantle else 0.25
	var length := 0.46 if apprentice else 0.66
	_banner(root,Vector3(0,1.09,z),length,dye)
	if school in ["enchanter","sigilist","chronomancer"]:
		# Belt sash on the scholarly and artisan coats.
		CreatureSculpt.limb(root,Vector3(-0.19,0.77,-0.18),Vector3(0.20,0.77,-0.18),0.050,dye,1.0)
		_banner(root,Vector3(0.13,0.72,-0.255),0.30 if apprentice else 0.41,dye)
	else:
		# Shoulder scarf: asymmetrical and wide enough to read at game zoom.
		CreatureSculpt.limb(root,Vector3(-0.19,1.16,-0.11),Vector3(-0.10,1.04,-0.20),0.069,dye,0.94)
		_banner(root,Vector3(-0.15,1.04,-0.245),0.33 if apprentice else 0.42,dye)
		WeaponSculpt.metal(MiniatureFactory.sphere(root,Vector3(-0.15,1.04,-0.28),Vector3.ONE*0.058,Color("c5ae7c")))


static func _banner(root: Node3D,top: Vector3,length: float,dye: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for row in 5:
		var t := float(row)/4.0
		for column in 5:
			var u := float(column)/4.0*2.0-1.0
			var w := lerpf(0.075,0.10,t)
			points.append(top+Vector3(u*w+0.035*sin(t*PI),-length*t+0.022*absf(u)*t,0.024*cos(u*PI*2.0)*t+signf(top.z)*0.11*t))
	for row in 4:
		for column in 4:
			var a := row*5+column
			for i: int in [a,a+1,a+5,a+1,a+6,a+5]:
				st.add_vertex(points[i])
	st.generate_normals()
	var node := MiniatureFactory.mesh(root,st.commit(),Vector3.ZERO,dye)
	var mat: StandardMaterial3D=node.material_override
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for i in 4:
		CreatureSculpt.limb(root,points[20+i],points[21+i],0.010,dye.lightened(0.32),1.0)
