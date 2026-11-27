class_name MovementContact
extends RefCounted
## One policy for figures occupying a movement route. The geometry provider
## supplies the actual candidate height and surface, never just the highest deck.

static func blocks(mover: Figure,other: Figure,figures: Array[Figure],at: Vector2,height: float,running: bool,surface: String="") -> bool:
	if absf(other.elevation-height)>=0.5 or (mover!=null and other.ring_side!=mover.ring_side):
		return false
	var distance:=other.pos.distance_to(at)
	if distance<Contact.OVERLAP:
		return true
	if mover==null or other.side==mover.side:
		return false
	if running and distance<1.001:
		return true
	if not Contact.touches_position(other,at,height,surface):
		return false
	if WormRider.ignored(mover,other) or (not IllusionRules.visible_to(figures,mover,other) and not CreatureSenses.may_contact(mover,other)):
		return true
	return mover.battle_ref!=null and mover.battle_ref.get_ref()!=null and BeautyActions.blocked(mover.battle_ref.get_ref(),mover,other)


static func enemies_at(figures: Array[Figure],mover: Figure,at: Vector2,height: float,surface: String="") -> Array[Figure]:
	var out: Array[Figure]=[]
	for t in figures:
		if t.in_play() and t.ring_side==mover.ring_side and t.side!=mover.side and Contact.touches_position(t,at,height,surface):
			out.append(t)
	return out


static func run_clear(mover: Figure,others: Array[Figure],a: Vector2,b: Vector2,height: float) -> bool:
	if mover==null:
		return true
	for t in others:
		if t.side!=mover.side and t.ring_side==mover.ring_side and absf(t.elevation-height)<0.5 and Geometry2D.get_closest_point_to_segment(t.pos,a,b).distance_to(t.pos)<1.001:
			return false
	return true
