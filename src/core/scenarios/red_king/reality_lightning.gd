class_name RealityLightning
extends RefCounted
## Sequential environmental attacks, including optional post-roll protection.
static func begin(c: GameController,axis: int) -> void:
	var s := c.state
	var ids: Array[int]=[]
	var center := s.board.size*0.5
	for f in s.figures:
		if f.in_play() and absf(f.pos.x-center.x if axis==0 else f.pos.y-center.y)<=4.0+Figure.BASE_RADIUS:
			ids.append(f.id)
	s.scenario_data["rk_lightning_queue"]=ids
	c.emit("lightning_front",{"axis":axis})
	advance(c)


static func advance(c: GameController) -> void:
	var s := c.state
	var queue: Array=s.scenario_data.get("rk_lightning_queue",[])
	while not queue.is_empty():
		var f := s.figure(int(queue.pop_front()))
		if f==null or not f.in_play():
			continue
		var attack := c.dice.d20()+3
		var defence := c.dice.d20()+f.effective_fight()+f.roll_penalty()
		var damage := maxi(0,attack-f.effective_armour()-CreatureEffects.elemental_resistance(f)) if attack>defence else 0
		if damage>0 and f.side==s.reaction_side and ActiveGear.ready(f,RedKingElemental.AMULET):
			s.scenario_data["rk_lightning_absorb"]={"target":f.id,"damage":damage}
			c.emit("elemental_offer",{"id":f.id,"damage":damage,"spell":"lightning_front"})
			return
		_apply(c,f,damage)
	s.scenario_data.erase("rk_lightning_queue")


static func _apply(c: GameController,f: Figure,damage: int,choice: int=-1) -> void:
	var amount := RedKingElemental.reduce(c,f,damage,choice)
	c.emit("reality_attack",{"id":f.id,"power":3,"amount":amount})
	c._hurt(f,amount,f,true)


static func answer(c: GameController,use: bool) -> bool:
	var s := c.state
	var offer: Dictionary=s.scenario_data.get("rk_lightning_absorb",{})
	if offer.is_empty():
		return false
	var f := s.figure(int(offer["target"]))
	if f==null or f.side!=s.reaction_side:
		return false
	s.scenario_data.erase("rk_lightning_absorb")
	_apply(c,f,int(offer["damage"]),int(use))
	advance(c)
	if not s.scenario_data.has("rk_lightning_absorb"):
		c._flow.resume_priority()
	return true
