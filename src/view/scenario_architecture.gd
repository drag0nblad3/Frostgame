class_name ScenarioArchitecture
extends RefCounted
## Authored solid pieces; all details stay inside the logical rectangle and height.
## Open tops and actual gaps preserve figure readability and movement.

static func build(root: Node3D,p: TerrainPiece) -> void:
	var r:=p.rect
	var h:=p.kind.height
	var c:=r.get_center()
	var at:=TableSpace.to_world(c)
	var size:=Vector3(r.size.x,h,r.size.y)
	match p.kind.id:
		"tent_canvas":
			var cloth:=Color("75413a").lerp(Color("a16d49"),float(posmod(roundi(c.x*4+c.y*2),4))*0.12)
			MiniatureFactory.box(root,at+Vector3.UP*h*0.5,size,cloth)
			var long_x:=r.size.x>=r.size.y
			var length:=r.size.x if long_x else r.size.y
			for i in range(maxi(1,ceili(length/0.75))):
				var t:=(float(i)+0.5)/maxi(1,ceili(length/0.75))-0.5
				var offset:=Vector3(t*length,0,0) if long_x else Vector3(0,0,t*length)
				var beam:=Vector3(minf(0.10,r.size.x),h,minf(0.10,r.size.y))
				MiniatureFactory.box(root,at+offset+Vector3.UP*h*0.5,beam,Color("47342b"))
			MiniatureFactory.box(root,at+Vector3.UP*(h-0.10),Vector3(r.size.x,0.20,r.size.y),Color("b28b59"))
			MiniatureFactory.box(root,at+Vector3.UP*0.14,Vector3(r.size.x,0.28,r.size.y),Color("504037"))
		"library_gate","temple_gate":
			var stone:=Color("817d72") if p.kind.id=="library_gate" else Color("9c927c")
			MiniatureFactory.box(root,at+Vector3.UP*h*0.5,size,stone.darkened(0.18))
			for y: float in [0.15,h*0.32,h*0.66,h-0.15]:
				MiniatureFactory.box(root,at+Vector3.UP*y,Vector3(r.size.x,0.20,r.size.y),stone)
			var face:=Vector3(r.size.x*0.65,h*0.54,r.size.y*0.65)
			MiniatureFactory.box(root,at+Vector3.UP*h*0.5,face,stone.lightened(0.10))
		_:
			var basalt:=Color("353645")
			var trim:=Color("86719e") if p.kind.id=="alien_obelisk" else Color("647f83")
			MiniatureFactory.box(root,at+Vector3.UP*h*0.5,size,basalt)
			for y: float in [0.11,h*0.22,h*0.58,h-0.09]:
				MiniatureFactory.box(root,at+Vector3.UP*y,Vector3(r.size.x,0.16,r.size.y),trim)
			# Raised inlays are shallow strips within the solid envelope.
			for face in 4:
				var along:=r.size.x if face%2==0 else r.size.y
				var offset:=Vector3(0,0,(r.size.y*0.5-0.035)*(-1 if face==0 else 1)) if face%2==0 else Vector3((r.size.x*0.5-0.035)*(-1 if face==1 else 1),0,0)
				for i in range(maxi(1, floori(along/0.55))):
					var u:=(float(i)+0.5)/maxi(1,floori(along/0.55))-0.5
					var stripe:=Vector3(u*along,h*0.47,0) if face%2==0 else Vector3(0,h*0.47,u*along)
					var extent:=Vector3(0.08,h*0.37,0.07) if face%2==0 else Vector3(0.07,h*0.37,0.08)
					MiniatureFactory.box(root,at+offset+stripe,extent,trim.lightened(0.20))
	MiniatureBatch.bake(root)
