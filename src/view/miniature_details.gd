class_name MiniatureDetails
extends RefCounted
## Shared finishing pass, independent of faction and gameplay. Geometry is baked with the sculpture.
const BONE := Color("d2c7ac")
const ICE := Color("b0ccd5")
const METAL := Color("a1a9ab")
const DARK := Color("3a3e42")


static func decorate(root: Node3D,f: Figure) -> void:
	var id := f.def.id
	if id in ["wolf","wild_dog","war_hound","giant_rat","snow_leopard","bear","boar"]:
		BeastDetails.decorate(root,id)
	elif id in ["wizard","apprentice"] or f.def.role=="soldier" or id=="vampire":
		_humanoid(root,f)
	elif f.def.traits.has("construct"):
		_construct(root,id)
	else:
		SupernaturalDetails.decorate(root,id)


static func _humanoid(root: Node3D,f: Figure) -> void:
	var id := f.def.id
	var caster := f.def.role in ["wizard","apprentice"]
	var heavy := id in ["knight","templar","man_at_arms","marksman"]
	var cloth := WizardSculpt.cloth(f)
	var trim := cloth.lightened(0.22)
	# Keep neutral garments; role-specific accessories rather than school-wide color.
	if heavy:
		for side: float in [-1.0,1.0]:
			for y: float in [0.86,0.93,1.00]:
				TabletopKit.rivet(root,Vector3(side*0.19,y,-0.235),METAL)
		TabletopKit.band(root,Vector3(-0.19,1.11,-0.195),Vector3(0.19,1.11,-0.195),METAL,0.027)
	else:
		TabletopKit.band(root,Vector3(-0.19,1.11,-0.14),Vector3(-0.09,0.82,-0.22),trim)
		TabletopKit.band(root,Vector3(0.19,1.11,-0.14),Vector3(0.09,0.82,-0.22),trim)
		if caster:
			TabletopKit.rivet(root,Vector3(-0.18,1.08,-0.17),TabletopKit.BRASS)
	TabletopKit.pouch(root,Vector3(-0.20,0.66,-0.13),Vector3(0.16,0.18,0.12))
	if id in ["thief","thug","treasure_hunter","barbarian","ranger","tracker"]:
		TabletopKit.band(root,Vector3(0.19,1.15,0.17),Vector3(-0.14,0.77,0.23),Color("695345"),0.043)
		TabletopKit.pouch(root,Vector3(0.20,0.68,0.13),Vector3(0.17,0.20,0.13))
	elif caster:
		# Scroll roll on rear belt, not a second staff or weapon.
		CreatureSculpt.limb(root,Vector3(-0.17,0.66,0.22),Vector3(0.15,0.72,0.22),0.053,BONE,1.0)
		TabletopKit.band(root,Vector3(-0.02,0.66,0.22),Vector3(-0.02,0.75,0.22),Color("6b5242"),0.033)
	elif id=="apothecary":
		TabletopKit.pouch(root,Vector3(-0.19,0.67,0.16),Vector3(0.18,0.20,0.13))


static func _construct(root: Node3D,id: String) -> void:
	var small := id=="small_construct"
	var large := id=="large_construct"
	var accent := Color("b89b64") if small else (ICE if large else Color("a2c9ba"))
	for side: float in [-1.0,1.0]:
		var a := Vector3(side*0.24,1.04,-0.18)
		TabletopKit.rivet(root,a,accent)
		TabletopKit.band(root,Vector3(side*0.22,0.91,-0.21),Vector3(side*0.22,0.76,-0.21),DARK,0.025)
		TabletopKit.band(root,Vector3(side*0.22,0.91,-0.23),Vector3(side*0.15,0.84,-0.23),accent,0.018)
		for y: float in [1.04,1.15]:
			TabletopKit.rivet(root,Vector3(side*0.16,y,0.205),accent)
	for i in 3:
		MiniatureFactory.box(root,Vector3(0,0.88+i*0.105,0.225),Vector3(0.24,0.045,0.035),accent.darkened(0.20))
	if large:
		TabletopKit.band(root,Vector3(-0.17,1.28,0.02),Vector3(0.17,1.28,0.02),METAL,0.04)
