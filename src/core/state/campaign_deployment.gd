class_name CampaignDeployment
extends RefCounted
## Find a legal non-overlapping position nearest a campaign roster's assigned starting point.
static func legal(s: GameState,at: Vector2,ring: int,source: Dictionary) -> bool:
	if not s.board.floor_layout.is_empty() and BattlePlacement.support(s,at,"street")==null:
		return false
	if not s.board.can_stand(at,Figure.BASE_RADIUS):
		return false
	for f in s.figures:
		if f.ring_side==ring and absf(f.elevation-s.board.height_at(at))<0.5 and f.pos.distance_to(at)<Contact.OVERLAP:
			return false
	for entry: Dictionary in source.get("creatures",[]):
		var p: Array=entry["at"]
		if int(entry.get("ring_side",0))==ring and Vector2(p[0],p[1]).distance_to(at)<Contact.OVERLAP:
			return false
	for p: Array in source.get("treasures",[]):
		if Vector2(p[0],p[1]).distance_to(at)<Contact.OVERLAP:
			return false
	return true

static func zone(s: GameState,side: int,at: Vector2) -> bool:
	if RedKingRingworld.active(s):
		return at.distance_to(Vector2(8 if side==0 else 22,18))<=4.0
	if RedKingBridge.active(s):
		return (at.x<=4.5 if side==0 else at.x>=s.board.size.x-4.5) and at.y<=4.5
	if RedKingFire.active(s) or RedKingHerded.active(s):
		return at.x<=5.0 if side==0 else at.x>=s.board.size.x-5.0
	if RedKingVeil.active(s) and side==0:
		return at.y<=4.0
	return at.y<=6.0 if side==0 else at.y>=s.board.size.y-6.0

static func find(s: GameState,preferred: Vector2,side: int,source: Dictionary) -> Variant:
	if zone(s,side,preferred) and legal(s,preferred,0,source):
		return preferred
	var best: Variant=null
	var score := INF
	for x in range(1,int(s.board.size.x*2)):
		for y in range(1,int(s.board.size.y*2)):
			var at := Vector2(x,y)*0.5
			var distance := at.distance_squared_to(preferred)
			if distance>=score or not zone(s,side,at) or not legal(s,at,0,source):
				continue
			score=distance
			best=at
	return best
