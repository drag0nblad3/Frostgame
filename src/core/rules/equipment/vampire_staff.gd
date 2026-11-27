class_name VampireStaff
extends RefCounted
const ITEM := "gear_rk_vampire_staff"
const DESERTED := "rk_vampire_deserted"


static func eligible(f: Figure) -> bool:
	return f!=null and f.in_play() and ActiveGear.has(f,ITEM) and not MagicEquipment.suppressed(f) and not f.destroyed_weapons.has("staff")


static func donors(s: GameState,f: Figure) -> Array[Figure]:
	var result: Array[Figure]=[]
	if not eligible(f):
		return result
	for t in s.figures:
		if t!=f and t.in_play() and t.side==f.side and not t.is_undead() and not t.def.traits.has("construct") and not IllusionRules.phantom(t) and t.ring_side==f.ring_side and Shooting.distance(f,t)<=1.001 and t.health>=3:
			result.append(t)
	return result


static func cap(c: GameController,p: Dictionary,cast: bool) -> int:
	if p.is_empty() or p.get("scroll",false) or (not cast and int(p["raw"]) in [1,20]):
		return 0
	var f := c.state.figure(p["caster"] if cast else p["id"])
	if cast and (PowerPool.words_only(f,str(p["id"])) or (p["id"]=="summon_demon" and int(p["raw"])==1)):
		return 0
	var donor := c.state.figure(int(p.get("vampire_donor",-1)))
	if not donors(c.state,f).has(donor):
		return 0
	var max_value := mini(4,floori(donor.health/3.0))
	if cast and p["id"]!="summon_demon":
		max_value=mini(max_value,maxi(0,18-int(p["total"])))
	return max_value


static func amount(c: GameController,p: Dictionary,cast: bool) -> int:
	return clampi(int(p.get("vampire_amount",0)),0,cap(c,p,cast))


static func cycle(c: GameController,p: Dictionary,cast: bool) -> bool:
	if p.is_empty():
		return false
	var f := c.state.figure(p["caster"] if cast else p["id"])
	var options: Array[int]=[-1]
	for t in donors(c.state,f):
		options.append(t.id)
	if options.size()==1:
		return false
	var index := options.find(int(p.get("vampire_donor",-1)))
	p["vampire_donor"]=options[(index+1)%options.size()]
	p["vampire_amount"]=0
	return true


static func adjust(c: GameController,p: Dictionary,cast: bool,delta: int) -> void:
	p["vampire_amount"]=clampi(amount(c,p,cast)+delta,0,cap(c,p,cast))


static func spend(c: GameController,f: Figure,p: Dictionary,count: int) -> void:
	if count<=0:
		return
	var donor := c.state.figure(int(p.get("vampire_donor",-1)))
	if not donors(c.state,f).has(donor):
		return
	c.emit("gear_used",{"id":f.id,"target":donor.id,"gear":ITEM,"amount":count})
	c._hurt(donor,count*3,f,false)
	if not donor.in_play():
		return
	donor.used_gear[DESERTED]=true
	for id in donor.carried_treasures():
		c._loot.lose(c.state.treasure(id))
	donor.items.clear()
	if donor.def.role=="creature" or donor.def.traits.has("animal"):
		donor.side=-1
		donor.controller_id=-1
		donor.control_spell=""
		c.emit("allegiance",{"id":donor.id,"side":-1})
	else:
		donor.exited=true
		c.emit("exit",{"id":donor.id})
		c._magic.summons.enforce_illusion_limit(donor)
