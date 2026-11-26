class_name ScenarioMarkers
extends Node3D
## Read-only public scenario landmarks, with no hidden treasure information.
var _signature := ""


func update_sites(s: GameState) -> void:
	var labels: Array[Dictionary] = []
	for p in s.board.pieces:
		var at := p.rect.get_center()
		var text := ""
		var color := Color(0.65, 0.92, 1.0)
		match p.kind.id:
			"haunted_floor":
				var searched := s.discovered_huts.has(p.rect.position)
				text = "Searched" if searched else "Unsearched"
				color = Color(0.68, 0.77, 0.74) if searched else Color(1.0, 0.85, 0.48)
			"arcane_disc": text = "Transport disc"
			"null_upper":
				text = "Null field"
				color = Color(0.88, 0.70, 1.0)
			"temple_column":
				text = "Guardian"
				color = Color(1.0, 0.85, 0.48)
			"dreams_well": text = "Enchanted well"
		if text != "":
			labels.append({"at": at, "height": maxf(s.board.height_at(at), p.kind.height) + 0.6, "text": text, "color": color})
	if s.scenario_special == "underground_library":
		var size := s.board.size
		for at: Vector2 in [Vector2(size.x * 0.5, 0.5), Vector2(size.x * 0.5, size.y - 0.5), Vector2(0.5, size.y * 0.5), Vector2(size.x - 0.5, size.y * 0.5)]:
			labels.append({"at": at, "height": 0.35, "text": "Exit", "color": Color(0.65, 1.0, 0.75)})
		var token := s.treasure(0)
		if token != null and token.frozen and token.on_ground():
			labels.append({"at": token.pos, "height": s.board.height_at(token.pos) + 0.9, "text": "Frozen · Fight TN 14", "color": Color(0.65, 0.92, 1.0)})
	var signature := str(labels)
	if signature == _signature:
		return
	_signature = signature
	for node in get_children():
		remove_child(node)
		node.queue_free()
	for entry in labels:
		var label := Label3D.new()
		label.text = entry["text"]
		label.modulate = entry["color"]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 48
		label.pixel_size = 0.008
		label.outline_size = 12
		label.position = TableSpace.to_world(entry["at"], entry["height"])
		add_child(label)


func reset() -> void:
	_signature = ""
	for node in get_children():
		remove_child(node)
		node.queue_free()
